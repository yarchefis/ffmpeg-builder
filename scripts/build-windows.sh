#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build-windows.sh: Build minimal FFmpeg for Windows x86_64 (MinGW)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PREFIX="${ROOT_DIR}/prefix/windows-x86_64"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${ROOT_DIR}/build/windows-x86_64"

export PREFIX
export DIST_DIR
export BUILD_DIR="${BUILD_DIR}/lame"
export HOST="x86_64-w64-mingw32"
export CC="x86_64-w64-mingw32-gcc"
export CXX="x86_64-w64-mingw32-g++"
export AR="x86_64-w64-mingw32-ar"
export RANLIB="x86_64-w64-mingw32-ranlib"
export STRIP="x86_64-w64-mingw32-strip"
export EXTRA_CFLAGS="-static"
export EXTRA_LDFLAGS="-static -static-libgcc"

echo "=========================================================="
echo ">>> Building for Windows (x86_64 MinGW)"
echo "=========================================================="

# 1. Build LAME
bash "${SCRIPT_DIR}/build-lame.sh"

# 2. Build FFmpeg
export BUILD_DIR="${BUILD_DIR}/../ffmpeg"
export TARGET_OS="mingw32"
export ARCH="x86_64"
export CROSS_PREFIX="x86_64-w64-mingw32-"
export OUTPUT_NAME="ffmpeg-windows-x86_64.exe"
export EXTRA_CONF_ARGS="--target-os=mingw32 --arch=x86_64"

bash "${SCRIPT_DIR}/build-ffmpeg.sh"

# Create standard copy
cp -f "${DIST_DIR}/${OUTPUT_NAME}" "${DIST_DIR}/ffmpeg.exe" 2>/dev/null || true

echo "=== Windows build finished: ${DIST_DIR}/${OUTPUT_NAME} ==="
