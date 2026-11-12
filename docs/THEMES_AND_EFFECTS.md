# Themes, Visual Effects, and Memory Optimization

## 1. Visual Aesthetics: macOS Big Sur / WhiteSur Dark

To provide a modern, polished tablet experience, the environment incorporates the **WhiteSur-Dark** GTK theme and icon pack:

- **GTK Theme:** `WhiteSur-Dark` (configured in both `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`).
- **Icon Theme:** `WhiteSur-dark` with Apple-style rounded squircle icons.
- **Font:** Cantarell 11pt with subpixel antialiasing.
- **Window Decorations:** macOS left-aligned window controls (`close,minimize,maximize:`).

### Installation Reference:
```bash
# WhiteSur GTK theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
./WhiteSur-gtk-theme/install.sh -t all -N glassy -s 220

# WhiteSur Icon theme
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
./WhiteSur-icon-theme/install.sh -t default
```

---

## 2. Compiz Wobbly Windows & Kawase Blur (Wayfire)

Wayfire includes hardware-accelerated OpenGL ES shaders for Compiz window physics and multi-pass blur.

### Compiz Wobbly Window Physics (`[wobbly]` in `wayfire.ini`):
```ini
[wobbly]
friction = 3.000000
grid_resolution = 6
spring_k = 8.000000
```
- Real-time spring-mass simulation grid calculated on the Mali-G52 GPU.
- Windows deform naturally when dragged by finger or mouse and snap back smoothly.

### Dual-Kawase Glass Blur (`[blur]` in `wayfire.ini`):
```ini
[blur]
method = kawase
num_passes = 2
offset = 2.000000
blur_by_default = all
```
- Applies smooth Gaussian-like background blur underneath translucent layer surfaces (Waybar, Dock, Quick Settings, App Grid, Lockscreen).
- Multi-pass Kawase algorithm runs efficiently in Mali fragment shaders without frame drops.

---

## 3. Desktop Memory Optimization: Purging KDE Plasma

### The Problem:
Running full KDE Plasma Desktop or Plasma Bigscreen on top of Halium/Droidian consumed **~2.3 GB of RAM** at idle. In addition to high memory consumption, KWin Wayland continuously struggled with buffer synchronization on the Mali-G52 `hwcomposer` backend, resulting in random shell restarts and dropped frames.

### The Solution:
1. Replaced `kwin_wayland` and `plasmashell` with lightweight **Wayfire 0.9.0 + custom Layer-Shell panels** (`gta8-dock`, `gta8-quick-settings`, `waybar`).
2. Retained user-favorite KDE apps (`konsole`, `dolphin`) while removing background KDE Daemons (`kded5`, `baloo_file`, `drkonqi`, `krunner`).
3. **Result:** Idle memory usage dropped from **2.3 GB down to ~550 MB**, freeing up over 1.7 GB of RAM for web browsing, multitasking, and heavy workloads.
