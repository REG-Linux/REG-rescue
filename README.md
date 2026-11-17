## :video_game::penguin: REG Rescue :video_game::penguin:
REG-Rescue is a rescue/update rootfs for [REG-Linux](https://github.com/REG-Linux/) 

The small system REG-Linux boots to apply upgrades (update mode) or when
something went wrong (rescue mode: `/boot/REG_RESCUE`).

### Rescue mode

The console opens the rescue menu (`reg-rescue`): disk and system
information, disk check and repair, reset of the system overlay or of REG
settings (moved aside, not deleted), saving logs to `/boot/logs`, reading
the last update log, retrying an interrupted upgrade, USB mode, a shell,
reboot and power off.

Devices without a keyboard: rescue mode starts ADB on the USB port, so from
a PC run `adb shell reg-rescue` (or `adb shell` for a root shell, `adb pull`
for logs). Set `system.usb.gadget.adb=0` in `/boot/system-boot.conf` to keep
MTP instead, or `system.usb.gadget=0` to turn USB gadgets off.
