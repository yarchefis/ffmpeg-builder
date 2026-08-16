#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build-lame.sh: Build static libmp3lame for FFmpeg
# ==============================================================================

LAME_VERSION="${LAME_VERSION:-3.100}"
PREFIX="${PREFIX:-$(pwd)/prefix}"
BUILD_DIR="${BUILD_DIR:-$(pwd)/build/lame}"
HOST="${HOST:-}"
EXTRA_CFLAGS="${EXTRA_CFLAGS:-}"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS:-}"

JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo "=== Building LAME v${LAME_VERSION} ==="
echo "Target Prefix: ${PREFIX}"
echo "Host:          ${HOST:-native}"
echo "Jobs:          ${JOBS}"

mkdir -p "${BUILD_DIR}"
mkdir -p "${PREFIX}/include" "${PREFIX}/lib" "${PREFIX}/lib/pkgconfig"

TARBALL_NAME="lame-${LAME_VERSION}.tar.gz"
DOWNLOAD_URL="https://downloads.sourceforge.net/project/lame/lame/${LAME_VERSION}/${TARBALL_NAME}"

cd "${BUILD_DIR}"

if [ ! -f "${TARBALL_NAME}" ]; then
    echo "--> Downloading LAME ${LAME_VERSION}..."
    curl -fsSL "${DOWNLOAD_URL}" -o "${TARBALL_NAME}" || \
    curl -fsSL "https://sourceforge.net/projects/lame/files/lame/${LAME_VERSION}/${TARBALL_NAME}/download" -o "${TARBALL_NAME}" || \
    curl -fsSL "https://src.fedoraproject.org/repo/pkgs/lame/${TARBALL_NAME}/sha512/03e48817a001ee661c9ae37be8084a441e8c9dc756e18f8b809a47dd64293f0b2f56cc447a13d7cd4bdfcb82b9dc34ccbb5562dfd8e7529d499de02cfcc6b840/${TARBALL_NAME}" -o "${TARBALL_NAME}"
fi

if [ ! -d "lame-${LAME_VERSION}" ]; then
    echo "--> Unpacking ${TARBALL_NAME}..."
    tar -xzf "${TARBALL_NAME}"
fi

cd "lame-${LAME_VERSION}"

# Clean previous build if configured
if [ -f Makefile ]; then
    make distclean || true
fi

CONF_ARGS=(
    "--prefix=${PREFIX}"
    "--disable-shared"
    "--enable-static"
    "--disable-frontend"
    "--disable-decoder"
)

if [ -n "${HOST}" ]; then
    CONF_ARGS+=("--host=${HOST}")
fi

echo "--> Configuring LAME with: ${CONF_ARGS[*]}"
CFLAGS="-O3 ${EXTRA_CFLAGS}" LDFLAGS="${EXTRA_LDFLAGS}" ./configure "${CONF_ARGS[@]}"

echo "--> Compiling LAME..."
make -j"${JOBS}"

echo "--> Installing LAME to ${PREFIX}..."
make install

# Generate pkg-config file if missing
PC_FILE="${PREFIX}/lib/pkgconfig/lame.pc"
if [ ! -f "${PC_FILE}" ]; then
    cat <<EOF > "${PC_FILE}"
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: lame
Description: MP3 encoding library
Version: ${LAME_VERSION}
Libs: -L\${libdir} -lmp3lame
Cflags: -I\${includedir}
EOF
fi

# Also create mp3lame.pc alias for ffmpeg
cp -f "${PC_FILE}" "${PREFIX}/lib/pkgconfig/mp3lame.pc" 2>/dev/null || true

echo "=== LAME build complete: ${PREFIX}/lib/libmp3lame.a ==="
