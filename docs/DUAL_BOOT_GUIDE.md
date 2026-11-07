# Dual-Boot Guide: Android 11 + Droidian Linux

This guide details the dual-boot mechanism implemented for the Samsung Galaxy Tab A8 LTE (`SM-X205`), allowing independent co-existence of Samsung One UI (Android 11) and Droidian Linux.

---

## 1. Storage Layout & Partition Map

The Tab A8 UFS/eMMC layout contains standard Samsung partition tables:

- `/dev/block/by-name/boot`: Android stock boot image (kernel + Android ramdisk).
- `/dev/block/by-name/recovery`: Flashed with custom **Halium 11 Initramfs** containing Linux boot logic.
- `/dev/block/by-name/userdata` (`/dev/mmcblk0p56`): Android user storage, encrypted via Knox FBE.
- `/dev/block/by-name/cache`: Used to store secondary bootloader flags.
- `/dev/mmcblk1p1`: External MicroSD card (FAT32/exFAT/ext4), used for user storage transfer and Droidian rootfs image storage if configured.

---

## 2. Boot Flow Architecture

```
                    Power On / Normal Boot
                              │
                              ▼
                    Samsung Bootloader (S-Boot)
                              │
            ┌─────────────────┴─────────────────┐
            │ Boot Argument Check               │
            ▼                                   ▼
    [Normal Boot Argument]             [Recovery Boot Argument]
            │                                   │
            ▼                                   ▼
   /dev/block/by-name/boot            /dev/block/by-name/recovery
            │                                   │
            ▼                                   ▼
   Stock Samsung Android              Halium 11 Initramfs (init)
            │                                   │
            ▼                                   ▼
    Samsung One UI OS                 Mount Droidian Rootfs (ext4)
                                                │
                                                ▼
                                      Start Droidian Linux / Wayfire
```

---

## 3. Switching from Android to Linux (Magisk Module)

Inside Android (rooted with Magisk / KernelSU / APatch), the `DroidianSwitch` module provides an automated action:

1. Flash `DroidianSwitch.zip` in Magisk Manager.
2. The module registers an action button in Magisk app:
   ```bash
   #!/system/bin/sh
   # Triggers boot into recovery where Halium initramfs lives
   /system/bin/reboot recovery
   ```
3. Alternatively, run via Termux or ADB:
   ```bash
   su -c "/system/bin/reboot recovery"
   ```

---

## 4. Switching from Linux to Android

Inside Droidian Linux, switching back to Android is fully automated:

- **GUI Action:** Open the Sliding Quick Settings or App Grid and tap **"Reboot to Android"**.
- **CLI Helper:** Run `boot-android`:
  ```bash
  boot-android
  # Executes: systemctl reboot (normal reboot target without recovery argument)
  ```
- **Rebooting back into Linux:**
  ```bash
  reboot-droidian
  # Executes: systemctl reboot --reboot-argument=recovery
  ```

---

## 5. Halium Initramfs Details

The `dualboot/initramfs/init` script handles the early mount sequence:
1. Mounts pseudo-filesystems (`/proc`, `/sys`, `/dev`).
2. Probes block devices for the Droidian rootfs image (`droidian-rootfs.img`).
3. Sets up loopback device mappings via `losetup`.
4. Executes `mount-android.sh` to mount vendor Android partitions required for LXC HAL containers (`/vendor`, `/system`, `/odm`).
5. Switches root into pure Debian userspace via `switch_root`.
