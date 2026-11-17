#!/bin/bash
# Fail if any ELF in a directory has a PT_LOAD segment aligned below <min>.
#
#   check-elf-alignment.sh <readelf> <dir> <min, e.g. 0x10000>
#
# The aarch64 rescue image must load on 4K, 16K (Apple Silicon) and 64K
# kernels, so every ELF needs 64 KiB-aligned segments. A prebuilt toolchain or
# library linked for 4 KiB pages would make /sbin/init unloadable on a 16K
# kernel, and the first boot of a fresh REG install goes through rescue.
set -u
READELF=$1
DIR=$2
MIN=$(( $3 ))
bad=0
while IFS= read -r -d '' f; do
	# ELF magic only
	[ "$(head -c 4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ] || continue
	align=$("$READELF" -lW "$f" 2>/dev/null | awk '$1 == "LOAD" { print $NF }' | sort -u | head -n1)
	[ -n "$align" ] || continue
	if [ $(( align )) -lt "$MIN" ]; then
		echo "ELF segment alignment $align < $3: ${f#"$DIR"/}" >&2
		bad=$((bad + 1))
	fi
done < <(find "$DIR" -type f -print0)
if [ "$bad" -gt 0 ]; then
	echo "ERROR: $bad ELF file(s) would not load on a kernel with larger pages" >&2
	exit 1
fi
exit 0
