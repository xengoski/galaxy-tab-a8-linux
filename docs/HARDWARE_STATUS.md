# Hardware Status & Peripheral Support Matrix

**Device:** Samsung Galaxy Tab A8 LTE (`SM-X205`, `UMS512`)  
**Kernel:** Linux `4.14.199-halium-gta8+` aarch64  
**Date Verified:** November 2026  

| Component | Hardware / Driver | Status | Notes & Implementation |
| :--- | :--- | :--- | :--- |
| **GPU / Display** | ARM Mali-G52 MP2 (Bifrost v3) | **Working** (60 FPS) | Uses Wayfire with `WLR_BACKENDS=hwcomposer` + `EGL_PLATFORM=hwcomposer`. `glmark2-es2-wayland` hits 57–63 FPS. |
| **Backlight Control** | SPRD Backlight sysfs (`sprd_backlight`) | **Working** | World-writable permissions via udev + `ExecStartPre` chmod. Smooth hardware slider in quick settings. |
| **Touchscreen** | Himax HX83102E (`himax-touchscreen`) | **Working** | Virtualized via `gta8-input-daemon` for kinetic scroll, right/middle click, and workspace gestures. |
| **Audio Output** | Unisoc VBC DAC0 + Stereo Speakers | **Working** | PulseAudio sink routed to hardware DAC0 with mixer initialization via `gta8-audio-init.sh`. |
| **Audio Input** | Internal Microphones | **Working** | Routed via PulseAudio ALSA source. |
| **USB-C Charging** | FSA9685 / Unisoc Battery Controller | **Working** | Auto-locks to sink power supply mode via `gta8-usb-debug.sh`, reporting battery percentage & status. |
| **Wi-Fi** | Unisoc SPRD 802.11ac dual-band | **Working** | Loaded via `gta8-load-wifi.sh` and managed seamlessly through NetworkManager (`nmcli` / GUI). |
| **Bluetooth** | Unisoc SPRD Bluetooth 5.0 (`hci0`) | **Working** | Managed by `bluebinder` + `bluez`. Verified `hci0 UP RUNNING` with device pairing & A2DP support. |
| **LTE Cellular** | Unisoc LTE Baseband Modem | **Working** | Managed via `ofono2mm` and `modem_control` wrapper. Status shown in top bar & quick settings. |
| **Sensors** | UMS512 SensorHub (Accelerometer/Gyro) | **Working** | Proxied through `sensorfwd` + `iio-sensor-proxy`. Wayfire auto-rotates display with accelerometer. |
| **Physical Buttons** | Power, Volume Up, Volume Down | **Working** | Mapped in Wayfire bindings to `pactl` volume adjustment and `gta8-power-toggle`. |
| **Storage (Ext SD)**| MicroSDXC slot (`/dev/mmcblk1p1`) | **Working** | Auto-mounted RW for droidian user at `/mnt/android-sdcard` and symlinked in home folder. |
| **Storage (Internal)**| UFS Internal Storage (`userdata`) | **Encrypted** | Block-encrypted by Knox/FBE (`MAGIC_0: 8a4d8052`); cleanly isolated from Linux rootfs. |
| **Camera** | Front & Rear Sensors | **Partial** | Hardware supported by Android AAL HAL (`droidian-camera`). GNOME Snapshot portal works, but kernel lacks V4L2 loopback for libcamera. |

---

## Detailed Component Notes

### 1. GPU Acceleration (Why No Panfrost?)
The Mali-G52 GPU belongs to the Bifrost v3 architecture (`G52 r1p0`). Upstream Linux support exists in the mainline **Panfrost** driver. However:
- Panfrost requires mainline DRM subsystem interfaces and device-tree bindings that are not present in legacy Android 4.14 vendor kernels.
- Attempting to backport Panfrost to a 4.14 kernel breaks the proprietary vendor power-management and display controller (`sprd_dpu`).
- **Solution:** By leveraging Halium's `hwcomposer` backend for `wlroots`, Wayfire runs native OpenGL ES 3.2 on the Mali-G52 GPU hardware using vendor blobs, completely avoiding CPU llvmpipe software rasterization and rendering desktop UI smoothly at 60 FPS.

### 2. Battery & Charging Sink Lock
On some Halium kernel boot iterations, the USB-C controller defaulted to host mode or suspended charging. The `gta8-usb-debug.sh` daemon forces the FSA9685 charger into sink mode and sets the charge current limit to the maximum negotiated adapter rating, ensuring reliable charging while running desktop Linux workloads.

### 3. LTE & RIL Modem Control
The Unisoc modem uses a proprietary RILD socket that required wrapper orchestration during early boot. A cold-boot helper (`/usr/local/sbin/modem_control`) ensures `sensorhub` and `l_modem` power rails initialize before `ofono` and `ModemManager` attach, providing working cellular data and SMS support.
