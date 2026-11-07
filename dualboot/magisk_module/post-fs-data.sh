#!/system/bin/sh
MODDIR=${0%/*}
if [ -f /vendor/bin/install-recovery.sh ] && [ -f "$MODDIR/noop.sh" ]; then
    mount -o bind "$MODDIR/noop.sh" /vendor/bin/install-recovery.sh
fi
