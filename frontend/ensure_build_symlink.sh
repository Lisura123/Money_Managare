#!/bin/bash
# Ensures frontend/build symlinks to ~/.cache/mm_build (outside iCloud Drive)
# so Xcode CodeSign never fails due to com.apple.provenance xattrs.
#
# This runs automatically via Xcode build phases and can be called manually.

BUILD_LINK="$(cd "$(dirname "$0")" && pwd)/build"
BUILD_TARGET="$HOME/.cache/mm_build"

mkdir -p "$BUILD_TARGET"

if [ -L "$BUILD_LINK" ] && [ "$(readlink "$BUILD_LINK")" = "$BUILD_TARGET" ]; then
  exit 0  # Already correct
fi

# Remove whatever is there (real dir or wrong symlink)
rm -rf "$BUILD_LINK"
ln -s "$BUILD_TARGET" "$BUILD_LINK"
echo "[ensure_build_symlink] Fixed: build -> $BUILD_TARGET"
