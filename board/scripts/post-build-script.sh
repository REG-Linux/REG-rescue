#!/bin/bash -e

# PWD = source dir
# BASE_DIR = build dir
# BUILD_DIR = base dir/build
# HOST_DIR = base dir/host
# BINARIES_DIR = images dir
# TARGET_DIR = target dir

RESCUE_TARGET=$(grep -E "^BR2_PACKAGE_RESCUE_TARGET_[A-Z_0-9]*=y$" "${BR2_CONFIG}" | sed -e s+'^BR2_PACKAGE_RESCUE_TARGET_\([A-Z_0-9]*\)=y$'+'\1'+)

# For the root user:
# 1. Use Bash instead of Dash for interactive use.
# 2. Set home directory to /userdata/system instead of /root.
sed -i "s|^root:x:.*$|root:x:0:0:root:/userdata/system:/bin/bash|g" "${TARGET_DIR}/etc/passwd" || exit 1

# use /userdata/system/iptables.conf for S35iptables
rm -f "${TARGET_DIR}/etc/iptables.conf" || exit 1
ln -sf "/userdata/system/iptables.conf" "${TARGET_DIR}/etc/iptables.conf" || exit 1

# we want an empty boot directory (grub installation copy some files in the target boot directory)
rm -rf "${TARGET_DIR}/boot/grub" || exit 1

# reorder the boot scripts for the network boot
if test -e "${TARGET_DIR}/etc/init.d/S10udev"
then
    mv "${TARGET_DIR}/etc/init.d/S10udev"    "${TARGET_DIR}/etc/init.d/S001udev"    || exit 1 # Plymouth depends on initialized udev.
fi
if test -e "${TARGET_DIR}/etc/init.d/S30dbus"
then
    mv "${TARGET_DIR}/etc/init.d/S30dbus"    "${TARGET_DIR}/etc/init.d/S01dbus"    || exit 1 # move really before for network (connman prerequisite) and pipewire
fi
if test -e "${TARGET_DIR}/etc/init.d/S45connman"
then
    if test -e "${TARGET_DIR}/etc/init.d/S08connman"
    then
        rm -f "${TARGET_DIR}/etc/init.d/S45connman" || exit 1
    else
        mv "${TARGET_DIR}/etc/init.d/S45connman" "${TARGET_DIR}/etc/init.d/S08connman" || exit 1 # move to make before share
    fi
fi

# make sure /etc/init.d scripts are executable
chmod 755 "${TARGET_DIR}/etc/init.d/S"*

# tmpfs or sysfs is mounted over theses directories
# clear these directories is required for the upgrade (otherwise, tar xf fails)
rm -rf "${TARGET_DIR}/"{var,run,sys,tmp} || exit 1
mkdir "${TARGET_DIR}/"{var,run,sys,tmp}  || exit 1

# make /etc/shadow a file generated from /boot/system-boot.conf for security
rm -f "${TARGET_DIR}/etc/shadow" || exit 1
touch "${TARGET_DIR}/run/reglinux.shadow"
(cd "${TARGET_DIR}/etc" && ln -sf "../run/reglinux.shadow" "shadow") || exit 1

# enable serial console
SYSTEM_GETTY_PORT=$(grep "BR2_TARGET_GENERIC_GETTY_PORT" "${BR2_CONFIG}" | sed 's/.*\"\(.*\)\"/\1/')
if [[ -n "${SYSTEM_GETTY_PORT}" ]]; then
    SYSTEM_GETTY_BAUDRATE=$(grep -E "^BR2_TARGET_GENERIC_GETTY_BAUDRATE_[0-9]*=y$" "${BR2_CONFIG}" | sed -e s+'^BR2_TARGET_GENERIC_GETTY_BAUDRATE_\([0-9]*\)=y$'+'\1'+)
    sed -i -e '/# GENERIC_SERIAL$/s~^.*#~S0::respawn:/sbin/getty -n -L -l /usr/bin/system-autologin '${SYSTEM_GETTY_PORT}' '${SYSTEM_GETTY_BAUDRATE}' vt100 #~' \
        ${TARGET_DIR}/etc/inittab
fi

# slim: tools and data a rescue system never uses
# - btrfs-progs extras (~3.5 MB): keep btrfs, mkfs.btrfs, fsck.btrfs/btrfsck
rm -f "${TARGET_DIR}/usr/bin/"btrfs-{convert,image,map-logical,find-root,select-super} \
      "${TARGET_DIR}/usr/bin/btrfstune"
# - command-line tools of the splash screen's libraries (pango, harfbuzz,
#   glib/gio, fontconfig, fribidi, pcre2, libevdev); the libraries stay
rm -f "${TARGET_DIR}/usr/bin/"{hb-info,hb-ot-shape-closure,hb-shape,hb-subset,hb-view} \
      "${TARGET_DIR}/usr/bin/"{pango-list,pango-segmentation,pango-view,fribidi} \
      "${TARGET_DIR}/usr/bin/"{gapplication,gdbus,gio,gio-querymodules,gresource,gsettings} \
      "${TARGET_DIR}/usr/bin/"{gi-compile-repository,gi-decompile-typelib,gi-inspect-typelib} \
      "${TARGET_DIR}/usr/bin/"{pcre2grep,pcre2test,mouse-dpi-tool,touchpad-edge-detector,libevdev-tweak-device} \
      "${TARGET_DIR}/usr/bin/"fc-*
# - libraries only those tools used
rm -f "${TARGET_DIR}/usr/lib/"lib{harfbuzz-subset,harfbuzz-cairo,girepository-2.0,cairo-gobject,gthread-2.0,pcre2-posix}.so*
# - Plymouth: keep the script plugin (our theme), text/details (no-graphics
#   fallback) and label-pango; drop the other splash plugins
rm -f "${TARGET_DIR}/usr/lib/plymouth/"{fade-throbber,space-flares,tribar,two-step,label-freetype}.so
# - fonts the theme does not use (it uses Sans and Sans Bold only)
rm -f "${TARGET_DIR}/usr/share/fonts/dejavu/"DejaVuSans-{Oblique,BoldOblique,ExtraLight}.ttf
# - xkeyboard-config layout catalogues (only for layout pickers; libxkbcommon
#   compiles keymaps from rules/evdev, keycodes and symbols)
rm -f "${TARGET_DIR}/usr/share/X11/xkb/rules/"*.xml "${TARGET_DIR}/usr/share/X11/xkb/rules/"*.lst

# aarch64: one image for 4K, 16K and 64K-page kernels (BR2_ARM64_PAGE_SIZE_64K)
# -- refuse to produce one that a larger-page kernel cannot load
if grep -q "^BR2_ARM64_PAGE_SIZE_64K=y$" "${BR2_CONFIG}"; then
    READELF=$(ls "${HOST_DIR}"/bin/*-readelf 2>/dev/null | head -n1)
    "${BR2_EXTERNAL_RESCUE_PATH}/board/scripts/check-elf-alignment.sh" "${READELF:-readelf}" "${TARGET_DIR}" 0x10000 || exit 1
fi
