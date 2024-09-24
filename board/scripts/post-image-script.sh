#!/bin/bash -e

# PWD = source dir
# BASE_DIR = build dir
# BUILD_DIR = base dir/build
# HOST_DIR = base dir/host
# BINARIES_DIR = images dir
# TARGET_DIR = target dir

RESCUE_TARGET=$(grep -E "^BR2_PACKAGE_RESCUE_TARGET_[A-Z_0-9]*=y$" "${BR2_CONFIG}" | sed -e s+'^BR2_PACKAGE_RESCUE_TARGET_\([A-Z_0-9]*\)=y$'+'\1'+)
SUFFIXVERSION=$(cat "${TARGET_DIR}/usr/share/reglinux/system.version" | sed -e s+'^\([0-9\.]*\).*$'+'\1'+) # xx.yy version
SUFFIXDATE=$(date +%Y%m%d)

# final filename
RESCUEIMG="${BINARIES_DIR}/REG-linux-rescue-${RESCUE_TARGET,,}"
echo "Final rescue image is ${RESCUEIMG}"
# delete if existing
if [ -f "${RESCUEIMG}" ]; then
    echo "${RESCUEIMG} exists, removing"
    rm "${RESCUEIMG}"
fi

# rename rootfs.squashfs to rescue
mv "${BINARIES_DIR}/rootfs.squashfs" "${BINARIES_DIR}/REG-linux-rescue-${RESCUE_TARGET,,}-${SUFFIXVERSION}-${SUFFIXDATE}"
