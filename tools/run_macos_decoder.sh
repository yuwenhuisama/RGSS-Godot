#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
cd "$base"
printf '%s  %s\n' 7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3 mac-audio-input/ffmpeg-8.1.3.tar.xz | shasum -a 256 -c -
BUILD_JOBS=4 bash mac-audio-input/build_audio_decoder.sh mac-audio-input/ffmpeg-8.1.3.tar.xz macos mac-audio-output
mac-audio-output/ffmpeg -nostdin -i mac-audio-input/tone.wma -vn -acodec pcm_s16le mac-audio-output/decoded.wav
printf '%s  %s\n' 58799fa81bf05ee654ba7e2d20ca9fc27391cd71cea79a820a24e7c1392fdc55 mac-audio-output/decoded.wav | shasum -a 256 -c -
file mac-audio-output/ffmpeg
otool -L mac-audio-output/ffmpeg
printf 'MACOS_DECODER_RUNTIME_PASS\n'
