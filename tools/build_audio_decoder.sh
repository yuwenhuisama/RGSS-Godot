#!/usr/bin/env bash
set -euo pipefail
# Source and detached signature must already be verified by the invoking build.
source_archive=${1:?Usage: build_audio_decoder.sh verified-source.tar.xz platform output-dir}
platform=${2:?platform is windows, macos or linux}
destination=${3:?output directory required}
case "$platform" in windows|macos|linux) ;; *) echo 'Unsupported platform' >&2; exit 1 ;; esac
source_archive=$(cd "$(dirname "$source_archive")" && pwd)/$(basename "$source_archive")
mkdir -p "$destination"
destination=$(cd "$destination" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -xf "$source_archive" -C "$work" --strip-components=1
cd "$work"
flags=(--disable-everything --disable-autodetect --disable-network --disable-doc
  --disable-ffplay --disable-ffprobe --disable-avdevice --disable-swscale
  --disable-debug --disable-iconv --disable-x86asm --enable-ffmpeg
  --enable-decoder=wmav1,wmav2,wmapro,wmalossless,wmavoice
  --enable-demuxer=asf,wav --enable-muxer=wav --enable-encoder=pcm_s16le
  --enable-protocol=file --enable-filter=aresample,aformat,anull,atrim)
# The verification step re-opens the decoded WAV, so its PCM decoder is required.
flags+=(--enable-decoder=pcm_s16le)
# A Windows release artifact must not depend on MinGW runtime DLLs beside it.
if [[ $platform == windows ]]; then flags+=(--extra-ldflags=-static); fi
./configure "${flags[@]}" 2>&1 | tee "$destination/configure.log"
make -j"${BUILD_JOBS:-4}" 2>&1 | tee "$destination/make.log"
binary=ffmpeg
if [[ $platform == windows ]]; then binary=ffmpeg.exe; fi
./"$binary" -L 2>&1 | tee "$destination/license-banner.txt"
grep -q 'version 2.1 of the License' "$destination/license-banner.txt"
./"$binary" -decoders > "$destination/decoders.txt" 2>&1
for decoder in wmav1 wmav2 wmapro wmalossless wmavoice; do
  grep -Eq "[[:space:]]${decoder}[[:space:]]" "$destination/decoders.txt"
done
cp "$binary" "$destination/$binary"
cp COPYING.LGPLv2.1 "$destination/LICENSE.txt"
cp "$source_archive" "$destination/$(basename "$source_archive")"
compiler=${CC:-cc}
command -v "$compiler" > /dev/null 2>&1 || compiler=gcc
{ printf 'Platform: %s\nConfigure:' "$platform"; printf ' %q' "${flags[@]}"; printf '\n'; "$compiler" --version; } > "$destination/BUILD.txt"
printf 'This software uses FFmpeg under the GNU LGPL version 2.1 or later.\nThis software is based in part on the work of the Independent JPEG Group.\nUnmodified corresponding source is included beside the executable.\n' > "$destination/NOTICE.txt"
printf 'AUDIO_DECODER_BUILD_PASS:%s\n' "$platform"
