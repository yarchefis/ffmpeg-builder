#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build-windows.sh: Build minimal FFmpeg for Windows (x86_64 / arm64)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

ARCH="${ARCH:-x86_64}"

if [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; then
    ARCH_NAME="arm64"
    FF_ARCH="aarch64"
    HOST="aarch64-w64-mingw32"
    CROSS_PREFIX="aarch64-w64-mingw32-"
else
    ARCH_NAME="x86_64"
    FF_ARCH="x86_64"
    HOST="x86_64-w64-mingw32"
    CROSS_PREFIX="x86_64-w64-mingw32-"
fi

PREFIX="${ROOT_DIR}/prefix/windows-${ARCH_NAME}"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${ROOT_DIR}/build/windows-${ARCH_NAME}"

export PREFIX
export DIST_DIR

# Determine available compiler
if command -v "${CROSS_PREFIX}clang" >/dev/null 2>&1; then
    CC="${CROSS_PREFIX}clang"
    CXX="${CROSS_PREFIX}clang++"
    AR="${CROSS_PREFIX}ar"
    RANLIB="${CROSS_PREFIX}ranlib"
    STRIP="${CROSS_PREFIX}strip"
else
    CC="${CROSS_PREFIX}gcc"
    CXX="${CROSS_PREFIX}g++"
    AR="${CROSS_PREFIX}ar"
    RANLIB="${CROSS_PREFIX}ranlib"
    STRIP="${CROSS_PREFIX}strip"
fi

export CC CXX AR RANLIB STRIP
export HOST
export EXTRA_CFLAGS="-static"
export EXTRA_LDFLAGS="-static -static-libgcc"

echo "=========================================================="
echo ">>> Building for Windows (${ARCH_NAME})"
echo "Host:         ${HOST}"
echo "CC:           ${CC}"
echo "=========================================================="

# 1. Build LAME
export BUILD_DIR="${BUILD_DIR}/lame"
bash "${SCRIPT_DIR}/build-lame.sh"

# 2. Build FFmpeg
export BUILD_DIR="${BUILD_DIR}/../ffmpeg"
export TARGET_OS="mingw32"
export ARCH="${FF_ARCH}"
export CROSS_PREFIX="${CROSS_PREFIX}"
export OUTPUT_NAME="ffmpeg-windows-${ARCH_NAME}.exe"
export EXTRA_CONF_ARGS=""

bash "${SCRIPT_DIR}/build-ffmpeg.sh"

# Create standard copy
if [ "${ARCH_NAME}" = "x86_64" ]; then
    cp -f "${DIST_DIR}/${OUTPUT_NAME}" "${DIST_DIR}/ffmpeg.exe" 2>/dev/null || true
fi

echo "=== Windows (${ARCH_NAME}) build finished: ${DIST_DIR}/${OUTPUT_NAME} ==="
