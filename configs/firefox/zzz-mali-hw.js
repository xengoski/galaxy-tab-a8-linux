// Re-enable hardware WebRender & WebGL on Mali-G52 now that HYBRIS_PATCH_TLS=1 prevents libGLES_mali TLS SIGSEGV
pref("layers.acceleration.disabled", false);
pref("gfx.webrender.all", true);
pref("gfx.webrender.allow-partial-present-buffer-age", false);
pref("webgl.force-enabled", true);
