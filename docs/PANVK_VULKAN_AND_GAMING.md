# PanVK Vulkan Acceleration & Gaming Optimization Guide

## Overview

The Samsung Galaxy Tab A8 LTE (`SM-X205` / `gta8lte`) features the **Unisoc Tiger T618 (`UMS512`)** SoC with an **ARM Mali-G52 MP2** GPU (Bifrost v3 / Gondul architecture).

While the standard downstream Android 4.14 kernel lacks upstream Linux DRM `panfrost.ko`, this port achieves **native open-source Vulkan 1.3 acceleration** by running Mesa's **PanVK driver directly on top of ARM's proprietary `mali_kbase` kernel driver (`/dev/mali0`)**.

---

## 1. Architecture: PanVK over `mali_kbase`

```
+------------------------------------------------------------------+
|          Vulkan Applications & Games (RetroArch, vkmark)         |
|                          Vulkan 1.3 / WSI                        |
+------------------------------------------------------------------+
                                 │
                                 ▼
+------------------------------------------------------------------+
|              Mesa PanVK (libvulkan_panfrost.so)                  |
|     - Architecture: Bifrost v7 / JM (Job Manager)                |
|     - Shader Compiler: Mesa NIR -> Bifrost ISA                   |
|     - WSI: Native Wayland Protocol (wl_surface, xdg_wm_base)     |
+------------------------------------------------------------------+
                                 │
                                 ▼
+------------------------------------------------------------------+
|           ARM mali_kbase Kernel Module (/dev/mali0)              |
|     - Driver Version: r34p0-01eac0 (UK version 11.38)            |
|     - Memory: ION System Heap with GROW_ON_GPF memory buffers    |
|     - Atoms: Bifrost JM atom stride 56 (base_jd_atom_v2)         |
+------------------------------------------------------------------+
                                 │
                                 ▼
+------------------------------------------------------------------+
|               ARM Mali-G52 MP2 Hardware (850 MHz)                |
+------------------------------------------------------------------+
```

---

## 2. Benchmark Verification

### `vkmark 2025.01` (Native Wayland Vulkan Benchmark)
```text
=======================================================
    vkmark 2025.01
=======================================================
    Vendor ID:      0x13B5 (ARM)
    Device ID:      0x74021000
    Device Name:    Mali-G52 r1 MC2
    Driver Version: 109060195 (Mesa PanVK 26.3.0-devel)
=======================================================
[vertex] device-local=true:  FPS: 191 FrameTime: 5.236 ms
[vertex] device-local=false: FPS: 187 FrameTime: 5.348 ms
=======================================================
               vkmark Score: 191
=======================================================
```

---

## 3. Hardware Clocks & Max Performance Mode (`gta8-performance-mode`)

By default, Samsung's conservative energy governor clocks the Mali-G52 GPU at **384 MHz** and heavily throttles CPU cores. The `gta8-performance.service` overrides these limits and locks the SoC at maximum throughput:

| Component | Default Governor | Max Performance Mode | Boost |
| :--- | :--- | :--- | :--- |
| **Mali-G52 MP2 GPU** | 384 MHz (simple_ondemand) | **850 MHz** (`60000000.gpu`) | **+121% Frequency Boost** |
| **2× Cortex-A75 (Big)** | 1.22 GHz (schedutil) | **2.002 GHz** (performance) | **+63% Single-Core Boost** |
| **6× Cortex-A55 (Little)** | 962 MHz (schedutil) | **2.002 GHz** (performance) | **+108% Multi-Core Boost** |
| **DPU Display Engine** | 153–307 MHz | **384 MHz** (`dpu-dvfs`) | Full 60 Hz 1920×1200 bandwidth |

### Controlling Performance Mode:
```bash
# Activate Max Performance Gaming Profile
sudo gta8-performance-mode on

# Check real-time clock frequencies
gta8-performance-mode status

# Restore balanced battery saving
sudo gta8-performance-mode off
```

---

## 4. Gaming Launcher: `panvk-run`

To launch any game, emulator, or 3D application with optimized Vulkan environment flags:
```bash
panvk-run <command> [args...]
```

### Examples:
- Launch RetroArch with native Vulkan video backend:
  ```bash
  panvk-run retroarch
  ```
- Run `vkmark` on Wayland:
  ```bash
  panvk-run vkmark --winsys wayland
  ```
- Run 3D games via Zink (OpenGL-on-Vulkan):
  ```bash
  panvk-run supertuxkart
  ```

---

## 5. Emulation & Gaming Setup

1. **RetroArch:**
   - Pre-configured with `video_driver = "vulkan"` and `menu_driver = "ozone"`.
   - Installed Cores: `libretro-beetle-psx` (PlayStation 1), `libretro-mgba` (Game Boy Advance), `libretro-nestopia` (NES).
   - GameMode integration installed for automatic thread priority elevation.
2. **PC Gaming via Box64 / DXVK:**
   - With Vulkan 1.3 PanVK active, `box64` can run x86_64 Windows games via Wine + DXVK (D3D9/D3D11 to Vulkan).
