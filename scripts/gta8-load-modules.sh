#!/bin/sh
# Ensure Unisoc Android by-name symlinks exist for WCN/BT/Wi-Fi modem firmware loaders
if [ -d /dev/disk/by-partlabel ]; then
    mkdir -p /dev/block/platform/soc/soc:ap-apb/71400000.sdio
    ln -sfn /dev/disk/by-partlabel /dev/block/platform/soc/soc:ap-apb/71400000.sdio/by-name
    ln -sfn /dev/disk/by-partlabel /dev/block/by-name
fi
# Load Samsung/Unisoc proprietary modules needed by graphics, BT, and Wi-Fi
for mod in mali_gondul.ko sprdbt_tty.ko tcs3430.ko sprd_fm.ko; do
    if [ -f "/mnt/vendor/socko/$mod" ]; then
        insmod "/mnt/vendor/socko/$mod" 2>/dev/null || true
    fi
done
exit 0
