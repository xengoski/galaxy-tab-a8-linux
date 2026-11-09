# Wayfire 3D Desktop Compositor on Mali-G52 hwcomposer

This document details the configuration and optimization of the **Wayfire 0.9.0** 3D Wayland compositor on the Samsung Galaxy Tab A8 LTE (`SM-X205`), running on the ARM Mali-G52 MP2 GPU via Android `hwcomposer`.

---

## 1. Why Wayfire?

On Android devices running Halium kernels (such as the Unisoc Tiger T618 running Linux 4.14), full desktop compositors face a fundamental roadblock:

| Compositor | Backend Requirements | Status on SM-X205 | Result |
| :--- | :--- | :--- | :--- |
| **Mutter (GNOME Shell)** | Direct KMS/DRM nodes (`/dev/dri/card0`) | **Unsupported** | Fails to start without DRM master nodes. |
| **KWin (Plasma Mobile)** | DRM backend or wlroots wrapper | **Unstable** | High RAM overhead (~2.3 GB), erratic crash loops on 4.14. |
| **Wayfire (wlroots)** | Native `hwcomposer` backend (`libhybris`) | **Fully Functional** | Smooth 60 FPS hardware OpenGL ES 3.2 compositing. |

Wayfire enables standard `gtk-layer-shell` clients to render a complete GNOME desktop shell without depending on `mutter`.

---

## 2. EGL Platform & Environment Configuration

Starting Wayfire with Mali-G52 acceleration requires strict environment coordination:

```bash
# /etc/systemd/system/gta8-gnome.service
Environment=WLR_BACKENDS=hwcomposer,libinput
Environment=EGL_PLATFORM=hwcomposer
Environment=WLR_HWC_SKIP_VERSION_CHECK=1
Environment=HYBRIS_PATCH_TLS=1
Environment=LD_PRELOAD=libglesshadercache.so:/usr/local/lib/libhwc64fix.so
ExecStart=/usr/local/bin/startwayfire-gnome
```

### Critical Environment Variables

- `WLR_BACKENDS=hwcomposer,libinput`: Directs wlroots to output to Android's `android.hardware.graphics.composer@2.1` HAL while reading input from `libinput`.
- `EGL_PLATFORM=hwcomposer`: Instructs Mesa and libhybris to bind the EGL display to Android's hardware composer native display.
- `HYBRIS_PATCH_TLS=1`: Fixes thread-local storage (TLS) padding mismatches between Bionic Android libc and GNU libc.
- `libhwc64fix.so`: Intercepts 64-bit Gralloc buffer dimensions to prevent stride corruption on the 1920×1200 panel.
- `libglesshadercache.so`: Persists compiled OpenGL ES 3.2 shaders, preventing startup stuttering.

---

## 3. Wayfire Plugins Stack

In `/home/droidian/.config/gta8-gnome/wayfire.ini`, the active plugin pipeline is configured as:

```ini
[core]
plugins = ipc ipc-rules stipc session-lock input-method-v1 animate autostart command foreign-toplevel place resize scale expo vswipe vswitch extra-gestures window-rules wm-actions autorotate-iio idle grid xdg-activation wobbly blur winshadows
```

- **`wobbly`:** Compiz-style spring-physics window wobble on drag and resize.
- **`blur`:** Dual Kawase background blur on translucent windows and desktop layer-shell panels.
- **`winshadows`:** Client-side Gaussian drop shadows behind floating windows.
- **`scale`:** Interactive Exposé window overview triggered by 3-finger swipe up or the Activities button.
- **`vswipe` / `vswitch`:** Horizontal workspace carousel transitions.
- **`session-lock`:** Support for `ext-session-lock-v1` secure lockscreens.
- **`input-method-v1`:** Wayland virtual keyboard protocol support for text-input.

---

## 4. Hardware Benchmarks

Testing Mali-G52 MP2 acceleration under Wayfire Wayland:

```text
$ glmark2-es2-wayland
=======================================================
    glmark2 2023.01
=======================================================
    OpenGL Information
    GL_VENDOR:      ARM
    GL_RENDERER:    Mali-G52
    GL_VERSION:     OpenGL ES 3.2 v1.r26p0-01rel0
=======================================================
[build] use-vbo=false: FPS: 61 FrameTime: 16.393 ms
[build] use-vbo=true: FPS: 63 FrameTime: 15.873 ms
[texture] texture-filter=nearest: FPS: 60 FrameTime: 16.667 ms
[texture] texture-filter=linear: FPS: 59 FrameTime: 16.949 ms
=======================================================
                                  glmark2 Score: 61
=======================================================
```
