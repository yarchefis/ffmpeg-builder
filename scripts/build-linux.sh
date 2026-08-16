#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build-linux.sh: Build static minimal FFmpeg for Linux (x86_64 / arm64)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

ARCH="${ARCH:-x86_64}"
PREFIX="${ROOT_DIR}/prefix/linux-${ARCH}"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${ROOT_DIR}/build/linux-${ARCH}"

export PREFIX
export DIST_DIR

echo "=========================================================="
echo ">>> Building for Linux (${ARCH})"
echo "=========================================================="

CROSS_PREFIX="${CROSS_PREFIX:-}"
if [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; then
    ARCH="aarch64"
    if [ -z "${CROSS_PREFIX}" ] && [ "$(uname -m)" != "aarch64" ]; then
        CROSS_PREFIX="aarch64-linux-gnu-"
        export HOST="aarch64-linux-gnu"
    fi
fi

if [ -n "${CROSS_PREFIX}" ]; then
    export CC="${CROSS_PREFIX}gcc"
    export CXX="${CROSS_PREFIX}g++"
    export AR="${CROSS_PREFIX}ar"
    export RANLIB="${CROSS_PREFIX}ranlib"
    export STRIP="${CROSS_PREFIX}strip"
fi

export EXTRA_CFLAGS="-fPIC"
export EXTRA_LDFLAGS="-static"

# 1. Build LAME
export BUILD_DIR="${BUILD_DIR}/lame"
bash "${SCRIPT_DIR}/build-lame.sh"

# 2. Build FFmpeg
export BUILD_DIR="${BUILD_DIR}/../ffmpeg"
export TARGET_OS="linux"
export ARCH="${ARCH}"
export CROSS_PREFIX="${CROSS_PREFIX}"
export OUTPUT_NAME="ffmpeg-linux-${ARCH}"
export EXTRA_CONF_ARGS="--target-os=linux --arch=${ARCH} --extra-ldflags=-static"

bash "${SCRIPT_DIR}/build-ffmpeg.sh"

# Create standard copy
cp -f "${DIST_DIR}/${OUTPUT_NAME}" "${DIST_DIR}/ffmpeg" 2>/dev/null || true

echo "=== Linux (${ARCH}) build finished: ${DIST_DIR}/${OUTPUT_NAME} ==="
