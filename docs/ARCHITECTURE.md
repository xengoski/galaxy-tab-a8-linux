# Hardware Architecture & System Design

**Target Device:** Samsung Galaxy Tab A8 LTE (2021/2022)  
**Model Identifier:** `SM-X205` (`gta8lte`)  
**SoC:** Unisoc Tiger T618 (`UMS512`)  
**CPU:** Octa-Core (2× 2.0 GHz ARM Cortex-A75 + 6× 2.0 GHz ARM Cortex-A55)  
**GPU:** ARM Mali-G52 MP2 (Bifrost v3 architecture, Bifrost G52 r1p0)  
**RAM:** 3.4 GiB (4.0 GB physical LPDDR4x)  
**Display:** 10.5" WUXGA TFT LCD, 1920×1200 native resolution, 60 Hz  
**Touch Digitizer:** Himax HX83102E multi-touch panel (`himax-touchscreen`)  
**Base Kernel:** `4.14.199-halium-gta8+` (Android 11 BSP baseline)  
**Base Distribution:** Droidian Linux (Debian Trixie / Testing rootfs, arm64)  
**Compositor:** Wayfire 3D Wayland Compositor (v0.9.0) on Mali-G52 `hwcomposer` backend  

---

## Architecture Overview

The system architecture bridges vendor Android 11 hardware abstraction layers (HALs) running inside an unprivileged LXC container with a modern 64-bit pure Debian Linux desktop userspace via Halium and libhybris.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       GNOME Tablet Desktop Shell                            │
│  ┌───────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ │
│  │ Waybar Status │ │   GTA8 Dock    │ │ Quick Settings │ │ Calendar/Notifs│ │
│  └───────┬───────┘ └───────┬────────┘ └───────┬────────┘ └───────┬────────┘ │
│          │                 │                  │                  │          │
│          └─────────────────┴────────┬─────────┴──────────────────┘          │
│                                     │ Layer-Shell / Wayland IPC             │
│                                     ▼                                       │
│                         Wayfire 0.9.0 (Compositor)                          │
│               [wobbly] [blur (Kawase)] [winshadows] [scale]                 │
│                                     │                                       │
│                                     ▼                                       │
│                       wlroots (Hardware Backend)                            │
│                                     │                                       │
│                                     ▼                                       │
│                        libhybris libEGL_hybris                              │
│                                     │                                       │
│                                     ▼                                       │
│                   Android hwcomposer 2.1 (UMS512 HAL)                       │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │ IPC / Binder
┌─────────────────────────────────────▼───────────────────────────────────────┐
│                       LXC Android Container (Halium)                        │
│   android.hardware.graphics.composer@2.1   android.hardware.camera.provider │
│   sprd_backlight kernel sysfs              modem_control / rild             │
│   sensorfwd (SensorHub)                    bluebinder (Bluetooth)           │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│                    Linux Kernel (4.14.199-halium-gta8+)                     │
│   Mali Bifrost driver (kbase)              Himax HX83102E touch digitizer   │
│   Unisoc audio ALSA SoC (VBC DAC0)         Unisoc SPRD Wi-Fi & BT modules   │
│   FSA9685 USB-C sink charging controller   UMS512 SensorHub IIO subsystem   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Core System Subsystems

### 1. Graphics & Display Pipeline
- **Why Wayfire instead of Mutter (GNOME Shell):**  
  Stock `gnome-shell` requires `mutter`, which demands KMS/DRM nodes (`/dev/dri/card0` / `/dev/dri/renderD128`) and does not implement the Android `hwcomposer` / `android_wlegl` wlroots extension. On the 4.14 Halium kernel, the Mali Bifrost kernel module (`mali_kbase.ko`) communicates exclusively through the Android graphics HAL (`/vendor/lib64/hw/gralloc.ums512.so` and `hwcomposer.ums512.so`). Wayfire 0.9.0 with `wlroots` native `hwcomposer` backend allows full Mali-G52 hardware rendering at 60 FPS while enabling full desktop GNOME look-and-feel via `gtk-layer-shell`.
- **EGL Shims & TLS Compatibility:**
  - `libhwc64fix.so`: Intercepts 64-bit Gralloc buffer dimensions to prevent stride corruption on the 1920×1200 panel.
  - `libtls-padding.so` (`HYBRIS_PATCH_TLS=1`): Pads thread-local storage headers to prevent bionic/glibc TLS collision crashes.
  - `libglesshadercache.so`: Persists compiled OpenGL ES 3.2 shaders, preventing startup stuttering.

### 2. Multi-Touch Input Engine
- Raw hardware events originate from the Himax HX83102E capacitive touch panel on `/dev/input/event2`.
- Rather than exposing the raw multi-touch device directly to applications (which leads to erratic gesture collisions between single-finger pans and multi-finger zoom), the `gta8-input-daemon` grabs the raw device via `libevdev` and splits traffic into:
  - A clean `/dev/uinput` touch digitizer (`gta8-touch`).
  - A high-resolution mouse pointer / wheel device (`gta8-mouse`).
  - A hardware virtual keyboard (`gta8-vkbd`).
- The daemon tracks multi-finger centroids, velocity dot-products, and finger divergence to reliably separate parallel two-finger scrolling from opposing-finger pinch gestures.

### 3. Dual-Boot & Recovery Partition Booting
- The device maintains intact Samsung Android stock firmware on `/dev/mmcblk0p56` (`userdata`), which is block-encrypted with Knox Keymaster encryption.
- Droidian Linux lives on a secondary ext4 image mounted via Halium initramfs.
- The dual-boot mechanism flashes a custom Halium initrd into the `recovery` partition (`/dev/block/by-name/recovery`).
- A custom Magisk module (`DroidianSwitch`) in Android enables rebooting into Linux with `reboot recovery`, while Linux reboot helpers (`reboot-droidian` and `boot-android`) control standard vs recovery boot arguments using `systemctl reboot`.
