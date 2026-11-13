#include <wayfire/plugin.hpp>
#include <wayfire/output.hpp>
#include <wayfire/opengl.hpp>
#include <wayfire/render-manager.hpp>
#include <wayfire/core.hpp>
#include <wayfire/output-layout.hpp>
#include <wayfire/plugins/common/shared-core-data.hpp>
#include <wayfire/plugins/ipc/ipc-method-repository.hpp>
#include <wayfire/plugins/ipc/ipc-helpers.hpp>

#include <zlib.h>
#include <cstdlib>
#include <cstring>

static unsigned char *fast_zlib_compress(unsigned char *data, int data_len, int *out_len, int quality)
{
    uLongf dest_len = compressBound(data_len);
    unsigned char *dest = (unsigned char *)malloc(dest_len);
    if (!dest) return nullptr;

    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    int lvl = (quality <= 0) ? 1 : (quality > 9 ? 9 : quality);
    if (deflateInit(&stream, lvl) != Z_OK)
    {
        free(dest);
        return nullptr;
    }

    stream.next_in = data;
    stream.avail_in = data_len;
    stream.next_out = dest;
    stream.avail_out = dest_len;

    deflate(&stream, Z_FINISH);
    deflateEnd(&stream);

    *out_len = (int)stream.total_out;
    return dest;
}
#define STBIW_ZLIB_COMPRESS fast_zlib_compress

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <vector>
#include <string>
#include <fstream>
#include <thread>
#include <unistd.h>

static const char *vertex_shader =
    "#version 100\n"
    "attribute mediump vec2 position;\n"
    "attribute highp vec2 uvPosition;\n"
    "varying highp vec2 uvpos;\n"
    "void main() {\n"
    "    gl_Position = vec4(position.xy, 0.0, 1.0);\n"
    "    uvpos = uvPosition;\n"
    "}\n";

static const char *fragment_shader =
    "#version 100\n"
    "varying highp vec2 uvpos;\n"
    "uniform sampler2D smp;\n"
    "void main() {\n"
    "    gl_FragColor = texture2D(smp, uvpos);\n"
    "}\n";

class wayfire_gta8_screenshot : public wf::plugin_interface_t
{
    wf::shared_data::ref_ptr_t<wf::ipc::method_repository_t> method_repository;
    OpenGL::program_t program;
    wf::post_hook_t post_hook;

    bool hook_attached = false;
    bool pending_capture = false;
    std::string target_path = "/tmp/screenshot.png";
    wf::output_t *bound_output = nullptr;

public:
    void init() override
    {
        OpenGL::render_begin();
        program.set_simple(OpenGL::compile_program(vertex_shader, fragment_shader));
        OpenGL::render_end();

        post_hook = [this] (const wf::framebuffer_t& source, const wf::framebuffer_t& destination)
        {
            render_pass(source, destination);
        };

        method_repository->register_method("gta8/screenshot", on_ipc_screenshot);
    }

    void fini() override
    {
        method_repository->unregister_method("gta8/screenshot");

        if (bound_output && hook_attached)
        {
            bound_output->render->rem_post(&post_hook);
            hook_attached = false;
            bound_output = nullptr;
        }

        OpenGL::render_begin();
        program.free_resources();
        OpenGL::render_end();
    }

    void render_pass(const wf::framebuffer_t& source, const wf::framebuffer_t& destination)
    {
        // 1. Pass through source to destination so display presents unmodified frame
        static const float vertexData[] = {
            -1.0f, -1.0f,
             1.0f, -1.0f,
             1.0f,  1.0f,
            -1.0f,  1.0f
        };
        static const float coordData[] = {
            0.0f, 0.0f,
            1.0f, 0.0f,
            1.0f, 1.0f,
            0.0f, 1.0f
        };

        OpenGL::render_begin(destination);
        program.use(wf::TEXTURE_TYPE_RGBA);
        GL_CALL(glBindTexture(GL_TEXTURE_2D, source.tex));
        GL_CALL(glActiveTexture(GL_TEXTURE0));
        program.attrib_pointer("position", 2, 0, vertexData);
        program.attrib_pointer("uvPosition", 2, 0, coordData);
        GL_CALL(glDisable(GL_BLEND));
        GL_CALL(glDrawArrays(GL_TRIANGLE_FAN, 0, 4));
        GL_CALL(glBindTexture(GL_TEXTURE_2D, 0));
        program.deactivate();
        OpenGL::render_end();

        // 2. Perform screenshot readback if requested
        if (pending_capture)
        {
            pending_capture = false;
            int w = source.viewport_width;
            int h = source.viewport_height;
            std::string save_file = target_path;
            bool is_landscape = false;
            if (bound_output)
            {
                auto sz = bound_output->get_screen_size();
                is_landscape = (sz.width > sz.height);
            }

            if (w > 0 && h > 0)
            {
                std::vector<uint8_t> pixels(w * h * 4);
                OpenGL::render_begin(source);
                GL_CALL(glPixelStorei(GL_PACK_ALIGNMENT, 1));
                GL_CALL(glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data()));
                OpenGL::render_end();

                // Detach post hook immediately so next frame has zero hook overhead
                if (bound_output && hook_attached)
                {
                    bound_output->render->rem_post(&post_hook);
                    hook_attached = false;
                    bound_output = nullptr;
                }

                // Compress & write asynchronously in worker thread
                std::thread([pixels = std::move(pixels), save_file, w, h, is_landscape]() mutable {
                    stbi_write_force_png_filter = 0;
                    stbi_write_png_compression_level = 1;
                    int ok = 0;

                    if (is_landscape && w < h)
                    {
                        // Rotate 90 degrees CCW to match landscape orientation (1920x1200)
                        std::vector<uint32_t> rot(w * h);
                        const uint32_t *src = reinterpret_cast<const uint32_t *>(pixels.data());
                        for (int y = 0; y < h; ++y)
                        {
                            for (int x = 0; x < w; ++x)
                            {
                                rot[(w - 1 - x) * h + (h - 1 - y)] = src[y * w + x];
                            }
                        }
                        stbi_flip_vertically_on_write(0);
                        ok = stbi_write_png(save_file.c_str(), h, w, 4, rot.data(), h * 4);
                    }
                    else
                    {
                        stbi_flip_vertically_on_write(1);
                        ok = stbi_write_png(save_file.c_str(), w, h, 4, pixels.data(), w * 4);
                    }

                    std::ofstream token("/tmp/gta8-screenshot-done");
                    token << (ok ? "OK" : "ERROR") << "\n";
                    token.close();
                }).detach();
            }
            else
            {
                if (bound_output && hook_attached)
                {
                    bound_output->render->rem_post(&post_hook);
                    hook_attached = false;
                    bound_output = nullptr;
                }
            }
        }
    }

    wf::ipc::method_callback on_ipc_screenshot = [this] (nlohmann::json data)
    {
        std::string path = data.value("path", "/tmp/screenshot.png");
        auto outputs = wf::get_core().output_layout->get_outputs();
        if (outputs.empty())
        {
            return nlohmann::json{{"result", "error"}, {"error", "no output"}};
        }

        wf::output_t *output = outputs[0];
        target_path = path;
        pending_capture = true;
        unlink("/tmp/gta8-screenshot-done");

        if (!hook_attached)
        {
            bound_output = output;
            output->render->add_post(&post_hook);
            hook_attached = true;
        }

        output->render->damage_whole();
        output->render->schedule_redraw();

        return nlohmann::json{{"result", "ok"}, {"target", path}};
    };
};

DECLARE_WAYFIRE_PLUGIN(wayfire_gta8_screenshot);
