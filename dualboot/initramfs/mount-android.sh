#!/bin/bash

# On systems with A/B partition layout, current slot is provided via cmdline parameter.
if [ -e /proc/bootconfig ]; then
    ab_slot_suffix=$(grep -o 'androidboot\.slot_suffix = ".."' /proc/bootconfig | cut -d '"' -f2)
fi

if [ -z "$ab_slot_suffix" ]; then
    ab_slot_suffix=$(grep -o 'androidboot\.slot_suffix=..' /proc/cmdline |  cut -d "=" -f2)
fi

[ ! -z "$ab_slot_suffix" ] && echo "A/B slot system detected! Slot suffix is $ab_slot_suffix"

find_partition_path() {
    label=$1
    path="/dev/$label"
    for dir in by-partlabel by-name by-label by-path by-uuid by-partuuid by-id; do
        if [ -e "/dev/disk/$dir/$label$ab_slot_suffix" ]; then
            path="/dev/disk/$dir/$label$ab_slot_suffix"
            break
        elif [ -e "/dev/disk/$dir/$label" ]; then
            path="/dev/disk/$dir/$label"
            break
        fi
    done
    echo $path
}

parse_mount_flags() {
    org_options="$1"
    options=""
    for i in $(echo $org_options | tr "," "\n"); do
        [[ "$i" =~ context|trusted|nomblk_io_submit ]] && continue
        options+=$i","
    done
    options=${options%?}
    echo $options
}

if [ -n "${BIND_MOUNT_PATH}" ] && ! mountpoint -q -- "${BIND_MOUNT_PATH}"; then
    android_images="/userdata/android-rootfs.img /var/lib/lxc/android/android-rootfs.img"
    for image in ${android_images}; do
        if [ -f "${image}" ]; then
            mount "${image}" "${BIND_MOUNT_PATH}"
            break
        fi
    done
fi

if [ -e "/dev/disk/by-partlabel/super" ]; then
    echo "mapping super partition"
    dmsetup create --concise "$(parse-android-dynparts /dev/disk/by-partlabel/super)"
fi

if [ ! -e "/vendor/build.prop" ]; then
    echo "checking for vendor mount point"
    vendor_images="/userdata/vendor.img /var/lib/lxc/android/vendor.img /dev/disk/by-partlabel/vendor${ab_slot_suffix} /dev/disk/by-partlabel/vendor_a /dev/disk/by-partlabel/vendor_b /dev/mapper/dynpart-vendor /dev/mapper/dynpart-vendor${ab_slot_suffix} /dev/mapper/dynpart-vendor_a /dev/mapper/dynpart-vendor_b"
    for image in $vendor_images; do
        if [ -e $image ]; then
            echo "mounting vendor from $image"
            mount $image /vendor -o ro

            if [ -e "/vendor/build.prop" ]; then
                echo "found valid vendor partition: $image"
                break
            else
                echo "$image is not a valid vendor partition"
                umount /vendor
            fi
        fi
    done
fi

if [ ! -e "/vendor_dlkm/etc/build.prop" ]; then
    echo "checking for vendor_dlkm mount point"
    vendor_dlkm_images="/dev/mapper/dynpart-vendor_dlkm /dev/mapper/dynpart-vendor_dlkm${ab_slot_suffix} /dev/mapper/dynpart-vendor_dlkm_a /dev/mapper/dynpart-vendor_dlkm_b"
    for image in $vendor_dlkm_images; do
        if [ -e $image ]; then
            echo "mounting vendor_dlkm from $image"
            mount $image /vendor_dlkm -o ro

            if [ -e "/vendor_dlkm/etc/build.prop" ]; then
                echo "found valid vendor_dlkm partition: $image"
                break
            else
                echo "$image is not a valid vendor_dlkm partition"
                umount /vendor_dlkm
            fi
        fi
    done
fi

sys_vendor="/sys/firmware/devicetree/base/firmware/android/fstab/vendor"
if [ -e $sys_vendor ] && ! mountpoint -q -- /vendor; then
    label=$(cat $sys_vendor/dev | awk -F/ '{print $NF}')
    path=$(find_partition_path $label)
    [ ! -e "$path" ] && echo "Error vendor not found" && exit
    type=$(cat $sys_vendor/type)
    options=$(parse_mount_flags $(cat $sys_vendor/mnt_flags))
    echo "mounting $path as /vendor"
    mount $path /vendor -t $type -o $options
fi

if [ -n "${BIND_MOUNT_PATH}" ] && mountpoint -q -- /vendor; then
    mount -o bind /vendor "${BIND_MOUNT_PATH}/vendor"
fi

sys_persist="/sys/firmware/devicetree/base/firmware/android/fstab/persist"
if [ -e $sys_persist ]; then
    label=$(cat $sys_persist/dev | awk -F/ '{print $NF}')
    path=$(find_partition_path $label)
    type=$(cat $sys_persist/type)
    options=$(parse_mount_flags $(cat $sys_persist/mnt_flags))
    echo "mounting $path as /mnt/vendor/persist"
    mount $path /mnt/vendor/persist -t $type -o $options
fi

echo "checking if system overlay exists"
if [ -d "/usr/lib/droid-system-overlay" ]; then
    echo "mounting android's system overlay"
    if [ $(uname -r | cut -d "." -f 1) -ge "4" ]; then
        mount -t overlay overlay -o lowerdir=/usr/lib/droid-system-overlay:/var/lib/lxc/android/rootfs/system /var/lib/lxc/android/rootfs/system
    else
        mount -t overlay overlay -o lowerdir=/var/lib/lxc/android/rootfs/system,upperdir=/usr/lib/droid-system-overlay,workdir=/var/lib/lxc/android/ /var/lib/lxc/android/rootfs/system
    fi
fi

echo "checking if vendor overlay exists"
if [ -d "/usr/lib/droid-vendor-overlay" ]; then
    echo "mounting android's vendor overlay"
    if [ $(uname -r | cut -d "." -f 1) -ge "4" ]; then
        mount -t overlay overlay -o lowerdir=/usr/lib/droid-vendor-overlay:/var/lib/lxc/android/rootfs/vendor /var/lib/lxc/android/rootfs/vendor
    else
        mount -t overlay overlay -o lowerdir=/var/lib/lxc/android/rootfs/vendor,upperdir=/usr/lib/droid-vendor-overlay,workdir=/var/lib/lxc/android/ /var/lib/lxc/android/rootfs/vendor
    fi
fi

# Samsung Tab A8 (gta8lte) has multiple fstab.* files; pick fstab.ums512_25c10 first
# so prodnv doesn't overwrite /mnt/vendor/socko later in the loop.
if [ -f /vendor/etc/fstab.ums512_25c10 ]; then
    fstab="/vendor/etc/fstab.ums512_25c10"
else
    fstab=$(ls /vendor/etc/fstab* | head -n 1)
fi
[ -z "$fstab" ] && echo "fstab not found" && exit

echo "checking fstab $fstab for additional mount points"

cat ${fstab} ${EXTRA_FSTAB} | while read line; do
    set -- $line

    echo $1 | egrep -q "^#endhalium" && break
    echo $1 | egrep -q "^#" && continue
    ([ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]) && continue
    ([ "$2" = "/system" ] || [ "$2" = "/data" ] || [ "$2" = "/" ] \
    || [ "$2" = "auto" ] || [ "$2" = "/vendor" ] || [ "$2" = "none" ] \
    || [ "$2" = "/misc" ] || [ "$2" = "/system_ext" ] || [ "$2" = "/product" ]) && continue
    ([ "$3" = "emmc" ] || [ "$3" = "swap" ] || [ "$3" = "mtd" ]) && continue

    label=$(echo $1 | awk -F/ '{print $NF}')
    [ -z "$label" ] && continue

    mountpoint -q -- "$2" && continue

    echo "checking mount label $label"
    path=$(find_partition_path $label)
    [ ! -e "$path" ] && continue

    mkdir -p $2
    echo "mounting $path as $2"
    mount $path $2 -t $3 -o $(parse_mount_flags $4)

    if [ -n "${BIND_MOUNT_PATH}" ] && [[ ${2} != /mnt/* ]]; then
        mount -o bind ${2} "${BIND_MOUNT_PATH}/${2}"
    fi
done

# Ensure Unisoc kernel module partitions are mounted under /mnt/vendor
for extra_part in socko odmko; do
    if ! mountpoint -q -- "/mnt/vendor/$extra_part"; then
        epath=$(find_partition_path "$extra_part")
        if [ -e "$epath" ]; then
            mkdir -p "/mnt/vendor/$extra_part"
            echo "mounting $epath as /mnt/vendor/$extra_part"
            mount -t ext4 -o ro,noatime,nosuid,nodev,noauto_da_alloc "$epath" "/mnt/vendor/$extra_part" || true
        fi
    fi
done
