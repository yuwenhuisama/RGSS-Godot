#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential xz-utils ca-certificates
printf '%s  %s\n' '7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3' /repo/Plugins/windows/audio/ffmpeg-8.1.3.tar.xz | sha256sum -c -
BUILD_JOBS=8 bash /repo/tools/build_audio_decoder.sh /repo/Plugins/windows/audio/ffmpeg-8.1.3.tar.xz linux /output
/output/ffmpeg -hide_banner -loglevel error -y -i /repo/tests/fixtures/audio/tone.wma -vn -acodec pcm_s16le /output/decoded.wav
/output/ffmpeg -hide_banner -loglevel error -y -i /output/decoded.wav -acodec pcm_s16le /output/redecoded.wav
ldd /output/ffmpeg > /output/runtime-libraries.txt
printf 'LINUX_PRODUCTION_DECODE_PASS\n'
