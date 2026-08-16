#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build-ffmpeg.sh: Minimal audio-only FFmpeg build for LosslessRobot Desktop
# ==============================================================================

FFMPEG_VERSION="${FFMPEG_VERSION:-7.1}"
PREFIX="${PREFIX:-$(pwd)/prefix}"
DIST_DIR="${DIST_DIR:-$(pwd)/dist}"
BUILD_DIR="${BUILD_DIR:-$(pwd)/build/ffmpeg}"
TARGET_OS="${TARGET_OS:-}"
ARCH="${ARCH:-}"
CROSS_PREFIX="${CROSS_PREFIX:-}"
CC="${CC:-}"
CXX="${CXX:-}"
AR="${AR:-}"
RANLIB="${RANLIB:-}"
STRIP="${STRIP:-}"
EXTRA_CFLAGS="${EXTRA_CFLAGS:-}"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS:-}"
EXTRA_CONF_ARGS="${EXTRA_CONF_ARGS:-}"

JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo "=== Building Minimal FFmpeg v${FFMPEG_VERSION} ==="
echo "Target OS:    ${TARGET_OS:-native}"
echo "Arch:         ${ARCH:-native}"
echo "Cross Prefix: ${CROSS_PREFIX:-none}"
echo "Deps Prefix:  ${PREFIX}"
echo "Dist Dir:     ${DIST_DIR}"
echo "Jobs:         ${JOBS}"

mkdir -p "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"

TARBALL_NAME="ffmpeg-${FFMPEG_VERSION}.tar.xz"
DOWNLOAD_URL="https://ffmpeg.org/releases/${TARBALL_NAME}"

cd "${BUILD_DIR}"

if [ ! -f "${TARBALL_NAME}" ]; then
    echo "--> Downloading FFmpeg ${FFMPEG_VERSION}..."
    curl -fsSL "${DOWNLOAD_URL}" -o "${TARBALL_NAME}" || \
    curl -fsSL "https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n${FFMPEG_VERSION}.tar.gz" -o "${TARBALL_NAME}"
fi

SRC_DIR="ffmpeg-${FFMPEG_VERSION}"
if [ ! -d "${SRC_DIR}" ]; then
    echo "--> Extracting ${TARBALL_NAME}..."
    mkdir -p "${SRC_DIR}"
    tar -xf "${TARBALL_NAME}" --strip-components=1 -C "${SRC_DIR}"
fi

cd "${SRC_DIR}"

# Clean previous build if configured
if [ -f Makefile ]; then
    make distclean || true
fi

# Set PKG_CONFIG_PATH for finding libmp3lame
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

CONF_FLAGS=(
    "--prefix=${DIST_DIR}/temp_install"
    "--disable-everything"
    "--disable-programs"
    "--enable-ffmpeg"
    "--disable-ffprobe"
    "--disable-ffplay"
    "--disable-doc"
    "--disable-debug"
    "--disable-network"
    "--disable-autodetect"
    "--disable-hwaccels"
    "--disable-videotoolbox"
    "--disable-audiotoolbox"
    "--disable-iconv"
    "--disable-symver"
    "--enable-pthreads"
    "--enable-small"
    "--enable-static"
    "--disable-shared"
    "--pkg-config-flags=--static"
    
    # Protocols
    "--enable-protocol=file"
    "--enable-protocol=pipe"
    
    # Demuxers
    "--enable-demuxer=mov"
    "--enable-demuxer=flac"
    "--enable-demuxer=mp3"
    "--enable-demuxer=aac"
    "--enable-demuxer=ogg"
    "--enable-demuxer=wav"
    "--enable-demuxer=ac3"
    "--enable-demuxer=eac3"
    
    # Muxers
    "--enable-muxer=flac"
    "--enable-muxer=mp4"
    "--enable-muxer=mp3"
    "--enable-muxer=wav"
    "--enable-muxer=ogg"
    "--enable-muxer=adts"
    
    # Decoders
    "--enable-decoder=eac3"
    "--enable-decoder=ac3"
    "--enable-decoder=aac"
    "--enable-decoder=aac_latm"
    "--enable-decoder=flac"
    "--enable-decoder=mp3"
    "--enable-decoder=mp3float"
    "--enable-decoder=alac"
    "--enable-decoder=opus"
    "--enable-decoder=vorbis"
    "--enable-decoder=pcm_s16le"
    "--enable-decoder=pcm_s24le"
    "--enable-decoder=pcm_s32le"
    "--enable-decoder=pcm_f32le"
    
    # Encoders
    "--enable-encoder=flac"
    "--enable-encoder=libmp3lame"
    "--enable-libmp3lame"
    "--enable-encoder=pcm_s16le"
    "--enable-encoder=pcm_s24le"
    
    # Parsers
    "--enable-parser=aac"
    "--enable-parser=aac_latm"
    "--enable-parser=ac3"
    "--enable-parser=flac"
    "--enable-parser=mpegaudio"
    "--enable-parser=vorbis"
    "--enable-parser=opus"
    
    # Filters & Libs
    "--enable-filter=aresample"
    "--enable-filter=aformat"
    "--enable-filter=anull"
    "--enable-swresample"
    "--enable-avcodec"
    "--enable-avformat"
    "--enable-avfilter"
    "--enable-avutil"
)

# Cross compilation flags
if [ -n "${TARGET_OS}" ]; then
    CONF_FLAGS+=("--enable-cross-compile" "--target-os=${TARGET_OS}")
fi

if [ -n "${ARCH}" ]; then
    CONF_FLAGS+=("--arch=${ARCH}")
fi

if [ -n "${CROSS_PREFIX}" ]; then
    CONF_FLAGS+=("--cross-prefix=${CROSS_PREFIX}")
fi

if [ -n "${CC}" ]; then
    CONF_FLAGS+=("--cc=${CC}")
fi

if [ -n "${CXX}" ]; then
    CONF_FLAGS+=("--cxx=${CXX}")
fi

if [ -n "${AR}" ]; then
    CONF_FLAGS+=("--ar=${AR}")
fi

if [ -n "${RANLIB}" ]; then
    CONF_FLAGS+=("--ranlib=${RANLIB}")
fi

# Extra compiler and linker flags
CFLAGS="-O3 -I${PREFIX}/include ${EXTRA_CFLAGS}"
LDFLAGS="-L${PREFIX}/lib ${EXTRA_LDFLAGS}"

CONF_FLAGS+=("--extra-cflags=${CFLAGS}")
CONF_FLAGS+=("--extra-ldflags=${LDFLAGS}")

if [ -n "${EXTRA_CONF_ARGS}" ]; then
    # Add words from EXTRA_CONF_ARGS
    read -r -a EXTRA_ARRAY <<< "${EXTRA_CONF_ARGS}"
    CONF_FLAGS+=("${EXTRA_ARRAY[@]}")
fi

echo "--> Running FFmpeg configure..."
echo "Configuration options: ${CONF_FLAGS[*]}"
./configure "${CONF_FLAGS[@]}"

echo "--> Compiling FFmpeg..."
make -j"${JOBS}"

# Detect output binary name
BIN_EXT=""
if [[ "${TARGET_OS}" == *"mingw"* ]] || [[ "${TARGET_OS}" == *"win"* ]]; then
    BIN_EXT=".exe"
fi

FFMPEG_BIN="ffmpeg${BIN_EXT}"

if [ ! -f "${FFMPEG_BIN}" ]; then
    echo "ERROR: ${FFMPEG_BIN} was not built!"
    exit 1
fi

echo "--> Stripping binary symbols..."
STRIP_TOOL="${STRIP:-${CROSS_PREFIX}strip}"
"${STRIP_TOOL}" -s "${FFMPEG_BIN}" 2>/dev/null || "${STRIP_TOOL}" "${FFMPEG_BIN}" 2>/dev/null || true

# Copy final binary to dist
OUTPUT_NAME="${OUTPUT_NAME:-ffmpeg${BIN_EXT}}"
cp -f "${FFMPEG_BIN}" "${DIST_DIR}/${OUTPUT_NAME}"

echo "========================================================"
echo "FFmpeg build complete!"
echo "Binary location: ${DIST_DIR}/${OUTPUT_NAME}"
ls -lh "${DIST_DIR}/${OUTPUT_NAME}"
echo "========================================================"
