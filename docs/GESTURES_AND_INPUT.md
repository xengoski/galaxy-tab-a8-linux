# Gestures and Input Subsystem Architecture

## Overview

The Samsung Galaxy Tab A8 LTE (`SM-X205`) utilizes a **FocalTech/Goodix multi-touch capacitive digitizer** (`/dev/input/event2`) alongside physical GPIO buttons (`gpio-keys` for volume up/down, `sprd-eic-keys` for power).

In traditional Wayland desktop environments on mobile/tablet platforms, standard virtual keyboards (like Squeekboard, Maliit, or Onboard) encounter major architectural hurdles:
1. **Focus Stealing:** Wayland surfaces request keyboard focus to accept text, causing target windows (browsers, terminals, text editors) to lose active focus and close popups/inputs.
2. **Wayland Text-Input Protocol Incompatibility:** `zwp_text_input_v3` is inconsistently supported across Chromium, Firefox, GTK3/4, Qt5/6, and Electron applications.
3. **Mali G52 hwcomposer EGL Constraints:** Standard OSK overlays frequently crash or trigger buffer synchronization deadlocks when sharing the hardware composer layer with heavy GPU clients.

To resolve these challenges, this port implements a **universal virtual keyboard (`gta8-keyboard`) and gesture pipeline** built on top of `/dev/uinput` and GtkLayerShell.

---

## 1. Virtual Keyboard Architecture (`gta8-keyboard`)

`gta8-keyboard` is a native Wayland layer-shell application with custom uinput keystroke injection:

```
+-------------------------------------------------------------+
|                     Target Application                      |
|           (Firefox, Konsole, Discord, LibreOffice)          |
|                 [Holds Active Wayland Focus]                |
+-------------------------------------------------------------+
                               ^
                               | Kernel Input Events (/dev/input/eventX)
+------------------------------+------------------------------+
|              GTA8 Input Daemon (uinput device)              |
+-------------------------------------------------------------+
                               ^
                               | UNIX Datagram Socket (/run/gta8-vkbd.sock)
+------------------------------+------------------------------+
|         gta8-keyboard (GTK3 + GtkLayerShell Overlay)        |
|    - Layer: OVERLAY                                         |
|    - Keyboard Mode: NONE (Never steals Wayland focus!)      |
|    - Anchors: Bottom, Left, Right                           |
|    - Modifiers: Shift, Ctrl, Alt, Super, Arrow Keys         |
+-------------------------------------------------------------+
```

### Key Technical Details:
- **`GtkLayerShell.KeyboardMode.NONE`**: The virtual keyboard window never requests Wayland keyboard focus. Tapping keys keeps the active cursor in the underlying application.
- **Hardware Keystrokes via `/dev/uinput`**: Tapping a key sends the corresponding Linux `input-event-codes.h` keycode through `/run/gta8-vkbd.sock`. The background input daemon injects exact hardware `EV_KEY` events into the Linux kernel input subsystem.
- **Modifier Latching**: Shift, Ctrl, Alt, and Super keys can be toggled on/off to perform complex desktop combinations (`Ctrl+C`, `Alt+Tab`, `Super+A`, terminal signals).
- **Function Key Row**: Quick access to Esc, Tab, Arrow keys, Del, and modifier toggles.

---

## 2. Lockscreen & Display Management (`gta8-lockscreen` & `gta8-power-toggle`)

### Secure Wayland Lockscreen:
- Implemented using `ext-session-lock-v1` via `GtkLayerShell`.
- Native on-screen keyboard integrated directly into the lock screen window so the user can unlock without a physical USB keyboard.
- Authenticates directly against Linux PAM via `/sbin/unix_chkpwd` for secure password verification without exposing root credentials.
- Automatic screen blanking when idle.

### Power & Display Blanking (`gta8-power-toggle`):
- Operates via `wlopm` (Wayland Output Power Management) and `/sys/class/backlight/sprd_backlight/brightness`.
- On power key press (`sprd-eic-keys`), saves current brightness level and turns off the display (`wlopm --off "*"`).
- On subsequent press, wakes display (`wlopm --on "*"`) and restores previous backlight level.

---

## 3. Gestures & Touch Navigation

The tablet touchscreen uses `/usr/local/sbin/gta8-input-daemon` to listen directly to multi-touch slots (`ABS_MT_SLOT`, `ABS_MT_POSITION_X`, `ABS_MT_POSITION_Y`):
- **2-Finger Kinetic Scroll:** Smooth two-finger vertical/horizontal drag converted to smooth high-resolution mouse wheel events (`REL_WHEEL`).
- **Pinch-to-Zoom Filter:** Distinguishes pinch gestures from vertical scroll gestures by tracking Euclidean distance variance.
- **3-Finger Swipe:** Workspace switching (`Super+Left`, `Super+Right` injected directly into Wayfire compositor).
- **2-Finger Tap:** Emulates right-click (`BTN_RIGHT`).
- **3-Finger Tap:** Emulates middle-click (`BTN_MIDDLE`).

---

## 4. Hardware Button Shortcuts & Android-Style Screenshot

The hardware physical buttons (`KEY_POWER`, `KEY_VOLUMEDOWN`, `KEY_VOLUMEUP`) on `/dev/input/event4` (`gpio-keys`) are managed with low-latency chord detection inside `gta8-input-daemon`:

| Button / Combination | Action | Details |
|---|---|---|
| **Power (Short Tap)** | Display Toggle | Turns off/on backlight and outputs via `wlopm` & `gta8-power-toggle`. Touch when screen is off wakes instantly. |
| **Power (Hold > 1.0s)** | Quick Settings | Opens Quick Settings & status panel (`gta8-quick-settings`). |
| **Volume Up** | Volume +5% | Injects `KEY_VOLUMEUP` into Wayfire / PulseAudio sink. |
| **Volume Down** | Volume -5% | Injects `KEY_VOLUMEDOWN` into Wayfire / PulseAudio sink (with 150ms chord disambiguation window). |
| **Power + Volume Down** | **Android-Style Screenshot** | Intercepts chord, cancels screen blanking and volume change, executes `/usr/local/bin/gta8-screenshot`: captures full 1920×1200 Wayland PNG to `~/Pictures/Screenshots/`, displays desktop notification with thumbnail preview, and plays camera shutter sound (`pw-play`). |

