#!/bin/bash
# ==============================================================================
# Samsung Galaxy Tab A8 LTE (SM-X205) Linux Port Deployment Script
# Author: xengoski <harih.dev@proton.me>
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo " Deploying Samsung Galaxy Tab A8 LTE (SM-X205) Linux Configuration"
echo "=================================================================="

if [ "$(id -u)" -ne 0 ]; then
    echo "[-] Error: This script must be run as root (or with sudo)."
    exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="droidian"
TARGET_HOME="/home/${TARGET_USER}"

echo "[+] 1. Installing udev rules..."
install -m 644 "${BASE_DIR}/configs/udev/70-gta8lte.rules" /etc/udev/rules.d/
install -m 644 "${BASE_DIR}/configs/udev/90-touchscreen.rules" /etc/udev/rules.d/
udevadm control --reload-rules && udevadm trigger

echo "[+] 2. Installing system scripts..."
install -m 755 "${BASE_DIR}/scripts/gta8-usb-debug.sh" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-audio-init.sh" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-load-modules.sh" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-load-wifi.sh" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-brightness" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-cellular-status" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-power-toggle" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-dock" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-app-grid" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-quick-settings" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-calendar-notifs" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-keyboard" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-lockscreen" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-wayfire-ipc" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/startgnome-wf" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/startwayfire-gnome" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/reboot-droidian" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/boot-android" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/helium-wayland" /usr/local/bin/
install -m 755 "${BASE_DIR}/scripts/gta8-input-daemon" /usr/local/sbin/

echo "[+] 3. Installing systemd units..."
install -m 644 "${BASE_DIR}/configs/systemd/system/"*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable gta8-usb-debug.service
systemctl enable gta8-modules.service
systemctl enable gta8-wifi.service
systemctl enable gta8-input-daemon.service

echo "[+] 4. Installing desktop environment and shell configs..."
mkdir -p /etc/gta8-gnome
install -m 644 "${BASE_DIR}/configs/wayfire/wayfire.ini" /etc/gta8-gnome/wayfire.ini

mkdir -p /etc/profile.d
install -m 644 "${BASE_DIR}/configs/profile.d/"*.sh /etc/profile.d/

mkdir -p /etc/xdg/xdg-desktop-portal
install -m 644 "${BASE_DIR}/configs/portals/"*.conf /etc/xdg/xdg-desktop-portal/

if [ -d "/usr/lib/firefox/defaults/pref" ]; then
    install -m 644 "${BASE_DIR}/configs/firefox/zzz-mali-hw.js" /usr/lib/firefox/defaults/pref/
fi

echo "[+] 5. Installing user configurations for ${TARGET_USER}..."
if [ -d "${TARGET_HOME}" ]; then
    mkdir -p "${TARGET_HOME}/.config/wayfire"
    mkdir -p "${TARGET_HOME}/.config/waybar"
    mkdir -p "${TARGET_HOME}/.config/nwg-bar"
    mkdir -p "${TARGET_HOME}/.config/mako"
    mkdir -p "${TARGET_HOME}/.config/gtklock"
    mkdir -p "${TARGET_HOME}/.config/gtk-3.0"
    mkdir -p "${TARGET_HOME}/.config/gtk-4.0"

    install -m 644 "${BASE_DIR}/configs/wayfire/wayfire.ini" "${TARGET_HOME}/.config/wayfire/wayfire.ini"
    install -m 644 "${BASE_DIR}/configs/waybar/config" "${TARGET_HOME}/.config/waybar/config"
    install -m 644 "${BASE_DIR}/configs/waybar/style.css" "${TARGET_HOME}/.config/waybar/style.css"
    install -m 644 "${BASE_DIR}/configs/nwg-bar/bar.json" "${TARGET_HOME}/.config/nwg-bar/bar.json"
    install -m 644 "${BASE_DIR}/configs/nwg-bar/style.css" "${TARGET_HOME}/.config/nwg-bar/style.css"
    install -m 644 "${BASE_DIR}/configs/mako/config" "${TARGET_HOME}/.config/mako/config"
    install -m 644 "${BASE_DIR}/configs/gtklock/style.css" "${TARGET_HOME}/.config/gtklock/style.css"
    install -m 644 "${BASE_DIR}/configs/gtk-3.0/settings.ini" "${TARGET_HOME}/.config/gtk-3.0/settings.ini"
    install -m 644 "${BASE_DIR}/configs/gtk-4.0/settings.ini" "${TARGET_HOME}/.config/gtk-4.0/settings.ini"

    chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config"
fi

echo "[+] 6. Installing application desktop launchers..."
mkdir -p /usr/local/share/applications
install -m 644 "${BASE_DIR}/configs/desktop/"*.desktop /usr/local/share/applications/
update-desktop-database /usr/local/share/applications 2>/dev/null || true

echo "=================================================================="
echo " Deployment Complete! Please reboot the device or restart the session."
echo "=================================================================="
