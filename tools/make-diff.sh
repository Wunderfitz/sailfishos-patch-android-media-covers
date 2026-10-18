#!/bin/sh
# Writes patch/unified_diff.patch from work/original and work/patched, with the
# a/ and b/ prefixes Patchmanager strips with -p1 at the root of the file system.
cd "$(dirname "$0")/.."

(cd work && diff -urN original patched) \
    | sed -e 's|^--- original/\([^\t]*\).*|--- a/\1|' \
          -e 's|^+++ patched/\([^\t]*\).*|+++ b/\1|' \
          -e '/^diff -urN /d' \
    > patch/unified_diff.patch
