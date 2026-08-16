#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# verify.sh: Verify enabled codecs and basic transcoding in minimal FFmpeg
# ==============================================================================

FFMPEG_BIN="${1:-./dist/ffmpeg}"

if [ ! -f "${FFMPEG_BIN}" ]; then
    echo "ERROR: FFmpeg binary not found at: ${FFMPEG_BIN}"
    exit 1
fi

chmod +x "${FFMPEG_BIN}" 2>/dev/null || true

echo "=== Verifying FFmpeg binary: ${FFMPEG_BIN} ==="
"${FFMPEG_BIN}" -version

echo ""
echo "--> Checking Decoders..."
DECODERS=$("${FFMPEG_BIN}" -decoders 2>/dev/null || true)
REQUIRED_DECODERS=("eac3" "ac3" "aac" "flac" "mp3" "alac" "opus" "vorbis" "pcm_s16le" "pcm_s24le" "pcm_s32le")

for dec in "${REQUIRED_DECODERS[@]}"; do
    if echo "${DECODERS}" | grep -q -E "\b${dec}\b"; then
        echo "  [OK] Decoder: ${dec}"
    else
        echo "  [FAIL] Missing decoder: ${dec}"
        exit 1
    fi
done

echo ""
echo "--> Checking Encoders..."
ENCODERS=$("${FFMPEG_BIN}" -encoders 2>/dev/null || true)
REQUIRED_ENCODERS=("flac" "libmp3lame" "pcm_s16le" "pcm_s24le")

for enc in "${REQUIRED_ENCODERS[@]}"; do
    if echo "${ENCODERS}" | grep -q -E "\b${enc}\b"; then
        echo "  [OK] Encoder: ${enc}"
    else
        echo "  [FAIL] Missing encoder: ${enc}"
        exit 1
    fi
done

echo ""
echo "--> Checking Demuxers & Muxers..."
DEMUXERS=$("${FFMPEG_BIN}" -demuxers 2>/dev/null || true)
MUXERS=$("${FFMPEG_BIN}" -muxers 2>/dev/null || true)

for dm in "mov" "flac" "mp3" "aac" "ogg" "wav"; do
    if echo "${DEMUXERS}" | grep -q -E "\b${dm}\b"; then
        echo "  [OK] Demuxer: ${dm}"
    else
        echo "  [FAIL] Missing demuxer: ${dm}"
        exit 1
    fi
done

for mx in "flac" "mp4" "mp3" "wav" "ogg"; do
    if echo "${MUXERS}" | grep -q -E "\b${mx}\b"; then
        echo "  [OK] Muxer: ${mx}"
    else
        echo "  [FAIL] Missing muxer: ${mx}"
        exit 1
    fi
done

echo ""
echo "--> Testing Audio Transcoding Pipeline..."
TMP_DIR=$(mktemp -d 2>/dev/null || echo "./build/test_tmp")
mkdir -p "${TMP_DIR}"
trap 'rm -rf "${TMP_DIR}"' EXIT

# Generate 1-second raw PCM audio via python or /dev/urandom
TEST_RAW="${TMP_DIR}/test.raw"
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import struct, math; [open('${TEST_RAW}','wb').write(b''.join(struct.pack('<h', int(math.sin(2*math.pi*440*i/44100)*32767)) for i in range(44100)))]"
else
    head -c 88200 /dev/urandom > "${TEST_RAW}"
fi

# Convert raw PCM to WAV
"${FFMPEG_BIN}" -y -f s16le -ar 44100 -ac 1 -i "${TEST_RAW}" "${TMP_DIR}/test.wav" >/dev/null 2>&1
echo "  [OK] Raw PCM -> WAV"

# Convert WAV to FLAC 24-bit
"${FFMPEG_BIN}" -y -i "${TMP_DIR}/test.wav" -c:a flac -sample_fmt s32 "${TMP_DIR}/test.flac" >/dev/null 2>&1
echo "  [OK] WAV -> FLAC (24-bit s32)"

# Convert WAV to MP3 320k via libmp3lame
"${FFMPEG_BIN}" -y -i "${TMP_DIR}/test.wav" -c:a libmp3lame -b:a 320k "${TMP_DIR}/test.mp3" >/dev/null 2>&1
echo "  [OK] WAV -> MP3 (libmp3lame 320k)"

# Remux to MP4 (m4a container)
"${FFMPEG_BIN}" -y -i "${TMP_DIR}/test.mp3" -c:a copy -f mp4 "${TMP_DIR}/test.m4a" >/dev/null 2>&1
echo "  [OK] MP3 -> MP4 remux (.m4a)"

echo ""
echo "=========================================================="
echo "ALL VERIFICATION TESTS PASSED SUCCESSFULLY!"
echo "=========================================================="
