#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build-macos.sh: Build minimal FFmpeg for macOS (arm64, x86_64, Universal)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_ARCH="${ARCH:-universal}"
DIST_DIR="${ROOT_DIR}/dist"
MACOS_MIN_VER="11.0"

mkdir -p "${DIST_DIR}"

build_single_arch() {
    local ARCH="$1"
    echo "=========================================================="
    echo ">>> Building macOS for architecture: ${ARCH}"
    echo "=========================================================="
    
    local PREFIX="${ROOT_DIR}/prefix/macos-${ARCH}"
    local BUILD_DIR="${ROOT_DIR}/build/macos-${ARCH}"
    
    local HOST_TRIPLE=""
    if [ "${ARCH}" = "arm64" ]; then
        HOST_TRIPLE="aarch64-apple-darwin"
    else
        HOST_TRIPLE="x86_64-apple-darwin"
    fi
    
    # 1. Build LAME
    PREFIX="${PREFIX}" \
    BUILD_DIR="${BUILD_DIR}/lame" \
    HOST="${HOST_TRIPLE}" \
    EXTRA_CFLAGS="-arch ${ARCH} -mmacosx-version-min=${MACOS_MIN_VER}" \
    EXTRA_LDFLAGS="-arch ${ARCH} -mmacosx-version-min=${MACOS_MIN_VER}" \
    bash "${SCRIPT_DIR}/build-lame.sh"
    
    # 2. Build FFmpeg
    PREFIX="${PREFIX}" \
    DIST_DIR="${DIST_DIR}" \
    BUILD_DIR="${BUILD_DIR}/ffmpeg" \
    TARGET_OS="darwin" \
    ARCH="${ARCH}" \
    CC="clang" \
    OUTPUT_NAME="ffmpeg-macos-${ARCH}" \
    EXTRA_CFLAGS="-arch ${ARCH} -mmacosx-version-min=${MACOS_MIN_VER}" \
    EXTRA_LDFLAGS="-arch ${ARCH} -mmacosx-version-min=${MACOS_MIN_VER}" \
    EXTRA_CONF_ARGS="--target-os=darwin --arch=${ARCH} --cc=clang" \
    bash "${SCRIPT_DIR}/build-ffmpeg.sh"
}

if [ "${TARGET_ARCH}" = "universal" ]; then
    echo "Building Universal macOS binary (arm64 + x86_64)..."
    build_single_arch "arm64"
    build_single_arch "x86_64"
    
    echo "--> Combining architectures with lipo..."
    lipo -create \
        "${DIST_DIR}/ffmpeg-macos-arm64" \
        "${DIST_DIR}/ffmpeg-macos-x86_64" \
        -output "${DIST_DIR}/ffmpeg-macos-universal"
    
    cp -f "${DIST_DIR}/ffmpeg-macos-universal" "${DIST_DIR}/ffmpeg" 2>/dev/null || true
    
    echo "=========================================================="
    echo "Universal macOS binary created: ${DIST_DIR}/ffmpeg-macos-universal"
    lipo -info "${DIST_DIR}/ffmpeg-macos-universal"
    ls -lh "${DIST_DIR}/ffmpeg-macos-universal"
    echo "=========================================================="
else
    build_single_arch "${TARGET_ARCH}"
    cp -f "${DIST_DIR}/ffmpeg-macos-${TARGET_ARCH}" "${DIST_DIR}/ffmpeg" 2>/dev/null || true
fi
