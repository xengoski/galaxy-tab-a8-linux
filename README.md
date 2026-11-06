# Samsung Galaxy Tab A8 LTE (`SM-X205`) Linux Port

[![Platform](https://img.shields.io/badge/Platform-Droidian%20Linux%20(Debian)-E95420?logo=debian)](https://droidian.org)
[![Device](https://img.shields.io/badge/Device-Samsung%20Galaxy%20Tab%20A8%20LTE-0c4da2?logo=samsung)](https://www.samsung.com)
[![Compositor](https://img.shields.io/badge/Compositor-Wayfire%200.9.0%20(Mali--G52)-blue)](https://wayfire.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A fully optimized, hardware-accelerated **GNOME Tablet Desktop** setup running bare-metal **Droidian Linux** on the **Samsung Galaxy Tab A8 LTE (`SM-X205` / `gta8lte`)** with the **Unisoc Tiger T618 (`UMS512`)** SoC.

Dual-boots with Samsung Android without overwriting Android user data, featuring 60 FPS Mali-G52 GPU compositing, multi-touch trackpad gestures, universal on-screen keyboard, sliding quick control center, BigSur dark styling, and Compiz wobbly window physics.

---

## Key Highlights

- **Hardware Accelerated Desktop (Mali-G52 MP2):** Wayfire 0.9.0 running on native Android `hwcomposer` with OpenGL ES 3.2 acceleration (57–63 FPS in `glmark2-es2-wayland`), eliminating CPU llvmpipe rendering.
- **GNOME Tablet Experience on Layer-Shell:**
  - **Dynamic Dash Dock (`gta8-dock`):** Floating macOS/GNOME-style dock with running app indicators, active window focus, minimize-to-pill mode, and fast app launching.
  - **Top Status Bar (`waybar`):** Stock GNOME 48 style top bar with activities indicator, workspace dots, calendar clock, battery, volume, cellular WWAN status, and quick settings toggles.
  - **Sliding Quick Settings (`gta8-quick-settings`):** Full tablet control center featuring Wi-Fi, Bluetooth, Cellular LTE, Auto-Rotate lock, smooth brightness and volume sliders, and power options.
  - **Notification Center (`gta8-calendar-notifs`):** Integrated GTK calendar with mako notification history and Do-Not-Disturb toggle.
  - **Kinetic App Drawer (`gta8-app-grid`):** Smooth touch-scrollable fullscreen app grid with search filtering, automatic portrait (4 cols) and landscape (6 cols) layout adaptation, and clean filter of CLI clutter.
- **Multi-Touch Trackpad & Screen Gestures (`gta8-input-daemon`):**
  - **2-Finger Parallel Scroll:** High-resolution kinetic scroll wheel emulation with smooth velocity tracking.
  - **2-Finger Opposing Pinch:** Automatic disambiguation allowing pinch-to-zoom in web browsers and image viewers without accidental scroll jumping.
  - **2-Finger Tap:** Emulates mouse Right-Click (`BTN_RIGHT`).
  - **3-Finger Tap:** Emulates mouse Middle-Click (`BTN_MIDDLE`).
  - **3-Finger Horizontal Swipe:** Switches workspaces left/right (`Super+Alt+Left/Right`).
  - **3-Finger Vertical Swipe:** Toggles Overview / Scale mode or reveals on-screen keyboard.
  - **4-Finger Swipe:** Toggles the App Drawer or hides the dock.
- **Universal Touch Virtual Keyboard (`gta8-keyboard`):**
  - High-performance `/dev/uinput` touch keyboard daemon accessible globally on top of any Wayland or XWayland application.
  - Integrated `ext-session-lock-v1` secure lockscreen with embedded virtual keyboard.
- **Modern BigSur Dark Theme & Visual Effects:**
  - `WhiteSur-Dark` GTK3 & GTK4 / Libadwaita styling + bold `WhiteSur-dark` icons.
  - Frosted translucent Kawase glass blur (`libblur.so`) on dock, bar, and popups.
  - Compiz wobbly window physics (`libwobbly.so`) with natural spring constants.
  - Drop shadows (`wayfire-plugin-winshadows`) and squeezimize window minimize animations.
- **Hardware Integration:**
  - Auto-locking USB-C sink charging via FSA9685 controller (`gta8-usb-debug.sh`).
  - SensorHub auto-rotation via `iio-sensor-proxy` + `sensorfwd`.
  - Unisoc LTE Baseband data connection via `ofono2mm` + `modem_control`.
  - PulseAudio routing to internal speakers via Unisoc VBC DAC0.
  - Bluetooth 5.0 (`hci0`) with bluebinder.
  - MicroSD card auto-mounting at `/mnt/android-sdcard` (`~/Android-SDCard`).

---

## Hardware Specifications

| Attribute | Specification |
| :--- | :--- |
| **Model** | Samsung Galaxy Tab A8 LTE (`SM-X205` / `gta8lte`) |
| **SoC** | Unisoc Tiger T618 (`UMS512`) |
| **CPU** | 2× Cortex-A75 @ 2.0 GHz + 6× Cortex-A55 @ 2.0 GHz |
| **GPU** | ARM Mali-G52 MP2 (Bifrost v3, G52 r1p0) |
| **RAM** | 3.4 GiB usable LPDDR4x |
| **Internal Storage** | 32 GB / 64 GB eMMC 5.1 (Android userdata encrypted) |
| **External Storage** | MicroSD slot (formatted vfat/ext4, mounted RW) |
| **Display** | 10.5" 1920×1200 WUXGA TFT, 60 Hz |
| **Touchscreen** | Himax HX83102E capacitive multi-touch |
| **Kernel** | `4.14.199-halium-gta8+` aarch64 |

---

## Documentation Index

- [Architecture & Design Details](docs/ARCHITECTURE.md)
- [Hardware Support Matrix](docs/HARDWARE_STATUS.md)
- [Dual-Boot Setup & Magisk Module](docs/DUAL_BOOT_GUIDE.md)
- [Input Daemon & Gesture Engine](docs/GESTURES_AND_INPUT.md)
- [Themes, Blur & Window Effects](docs/THEMES_AND_EFFECTS.md)
- [Applications & Web Optimization](docs/APPS_AND_OPTIMIZATIONS.md)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
