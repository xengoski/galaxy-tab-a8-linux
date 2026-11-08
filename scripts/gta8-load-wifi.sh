#!/bin/sh
# Load Unisoc Wi-Fi module once WCN service inside Android LXC container is up
if ! grep -q '^sprdwl_ng ' /proc/modules; then
    [ -f /mnt/vendor/socko/sprdwl_ng.ko ] && insmod /mnt/vendor/socko/sprdwl_ng.ko 2>/dev/null || true
fi
exit 0
