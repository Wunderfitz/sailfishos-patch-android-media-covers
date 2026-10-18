#!/bin/sh
# Fetches the original files from a device into work/original and rebuilds
# work/patched from them and patch/unified_diff.patch, for editing.
# The originals are Jolla's: they stay in the git-ignored work/ directory.
#
#   tools/prepare.sh ["<sfdk device name>"]
set -e

DEVICE="${1:-Jolla Phone (2026)}"
SFDK="${SFDK:-$HOME/SailfishOS/bin/sfdk}"
cd "$(dirname "$0")/.."

FILES=$(sed -n 's|^+++ b/||p' patch/unified_diff.patch)

rm -rf work/original work/patched
for f in $FILES; do
    mkdir -p "work/original/$(dirname "$f")"
    "$SFDK" device exec "$DEVICE" -- cat "/$f" > "work/original/$f"
done
cp -a work/original work/patched
patch -p1 -d work/patched < patch/unified_diff.patch
