#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
BB=/usr/local/bin/busybox-static

proc_running() {
    grep -qa "$1" /proc/[0-9]*/cmdline 2>/dev/null
}

setup_rndis() {
    mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config 2>/dev/null || true
    UDC=$(ls /sys/class/udc 2>/dev/null | grep -v dummy | head -n 1)
    [ -z "$UDC" ] && return 1

    GDIR=/sys/kernel/config/usb_gadget/droidian
    if [ ! -e "$GDIR/functions/rndis.usb0" ]; then
        for u in /sys/kernel/config/usb_gadget/*/UDC; do
            [ -e "$u" ] && echo "" > "$u" 2>/dev/null || true
        done
        mkdir -p "$GDIR/strings/0x409" "$GDIR/functions/rndis.usb0" "$GDIR/configs/c.1/strings/0x409" 2>/dev/null || true
        echo "0x18d1" > "$GDIR/idVendor" 2>/dev/null || true
        echo "0xd001" > "$GDIR/idProduct" 2>/dev/null || true
        echo "0xEF" > "$GDIR/bDeviceClass" 2>/dev/null || true
        echo "0x02" > "$GDIR/bDeviceSubClass" 2>/dev/null || true
        echo "0x01" > "$GDIR/bDeviceProtocol" 2>/dev/null || true
        echo "SM-X205" > "$GDIR/strings/0x409/serialnumber" 2>/dev/null || true
        echo "Droidian" > "$GDIR/strings/0x409/manufacturer" 2>/dev/null || true
        echo "Tab A8 Debug RNDIS" > "$GDIR/strings/0x409/product" 2>/dev/null || true
        echo "rndis" > "$GDIR/configs/c.1/strings/0x409/configuration" 2>/dev/null || true
        ln -sf "$GDIR/functions/rndis.usb0" "$GDIR/configs/c.1/rndis.usb0" 2>/dev/null || true
    fi

    CUR_UDC=$(cat "$GDIR/UDC" 2>/dev/null || true)
    if [ "$CUR_UDC" != "$UDC" ]; then
        for u in /sys/kernel/config/usb_gadget/*/UDC; do
            [ -e "$u" ] && [ "$u" != "$GDIR/UDC" ] && echo "" > "$u" 2>/dev/null || true
        done
        echo "$UDC" > "$GDIR/UDC" 2>/dev/null || true
    fi

    IFACE=""
    for name in usb0 rndis0; do
        if [ -e "/sys/class/net/$name" ]; then
            IFACE="$name"
            break
        fi
    done
    [ -z "$IFACE" ] && return 1

    "$BB" ifconfig "$IFACE" 10.15.19.82 netmask 255.255.255.0 up 2>/dev/null || true

    if [ ! -f /run/udhcpd-debug.conf ] || ! grep -q "interface $IFACE" /run/udhcpd-debug.conf 2>/dev/null; then
        cat > /run/udhcpd-debug.conf <<EOF
start 10.15.19.100
end 10.15.19.150
interface $IFACE
lease_file /run/udhcpd-debug.leases
option subnet 255.255.255.0
EOF
    fi
    touch /run/udhcpd-debug.leases

    if ! proc_running "udhcpd-debug.conf"; then
        "$BB" udhcpd /run/udhcpd-debug.conf >/dev/null 2>&1 || true
    fi

    if ! proc_running "10.15.19.82:23"; then
        "$BB" telnetd -b 10.15.19.82:23 -l /bin/bash >/dev/null 2>&1 || true
    fi
}

dump_debug_log() {
    LOG=/var/log/gta8-boot.log
    {
        echo "===== $(date) ====="
        lsmod
        echo "--- /dev nodes ---"
        ls -la /dev/dri /dev/mali* /dev/gsp /dev/ion /dev/*binder* /mnt/vendor/socko 2>&1 || true
        echo "--- failed units ---"
        systemctl list-units --failed --no-pager 2>&1 || true
        echo "--- key services ---"
        systemctl status gta8-modules android-mount lxc@android android-service@hwcomposer android_boot_completed plasma-mobile-wf --no-pager 2>&1 || true
        echo "--- net ---"
        ip -br addr 2>&1 || true
        cat /sys/kernel/config/usb_gadget/droidian/UDC 2>&1 || true
        echo "--- lxc android ---"
        lxc-info -n android 2>&1 || true
        timeout 3 lxc-attach -n android -- logcat -d -t 80 2>&1 || true
        echo "--- journal tail ---"
        journalctl -b -n 120 --no-pager 2>&1 || true
        echo "--- dmesg tail ---"
        dmesg | tail -n 80 2>&1 || true
    } > "${LOG}.tmp" 2>&1 && mv "${LOG}.tmp" "$LOG"
}

fix_typec_sink() {
    # Prevent sc27xx-typec/sc27xx-pd DRP race from locking into OTG source mode (blocks charging)
    # whenever extcon2 (extcon-gpio) reports a non-host USB/charger cable (USB=1, USB-HOST=0).
    local ext2
    ext2=$(tr '\n' ' ' < /sys/class/extcon/extcon2/state 2>/dev/null || true)
    case "$ext2" in
        *"USB=1"*"USB-HOST=0"*|*"USB-HOST=0"*"USB=1"*)
            if grep -q '\[source\]' /sys/class/typec/port0/power_role 2>/dev/null || \
               grep -q '\[source\]' /sys/class/typec/port1/power_role 2>/dev/null || \
               grep -q '\[host\]' /sys/class/typec/port0/data_role 2>/dev/null || \
               grep -q '\[host\]' /sys/class/typec/port1/data_role 2>/dev/null || \
               grep -q '\[dual\]' /sys/class/typec/port1/port_type 2>/dev/null || \
               [ "$(cat /sys/class/power_supply/otg/online 2>/dev/null || echo 0)" = "1" ]; then
                echo sink > /sys/class/typec/port1/port_type 2>/dev/null || true
                echo sink > /sys/class/typec/port1/power_role 2>/dev/null || true
                echo sink > /sys/class/typec/port0/power_role 2>/dev/null || true
                echo device > /sys/class/typec/port1/data_role 2>/dev/null || true
                echo device > /sys/class/typec/port0/data_role 2>/dev/null || true
            fi
            ;;
        *)
            if grep -q '\[sink\]' /sys/class/typec/port1/port_type 2>/dev/null; then
                echo dual > /sys/class/typec/port1/port_type 2>/dev/null || true
            fi
            ;;
    esac
}

COUNT=0
while true; do
    fix_typec_sink || true
    setup_rndis || true
    if [ $((COUNT % 2)) -eq 0 ] && [ "$COUNT" -le 36 ]; then
        dump_debug_log || true
    fi
    COUNT=$((COUNT + 1))
    sleep 5
done
