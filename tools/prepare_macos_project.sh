#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/RGSS-Godot-Verification"
mkdir project
tar -xf mac-project-input.tar.gz -C project
mkdir -p project/Plugins/macos/audio project/.omo/evidence
cp native/output/*.dylib project/Plugins/macos/
cp mac-audio-output/ffmpeg mac-audio-output/ffmpeg-8.1.3.tar.xz mac-audio-output/LICENSE.txt mac-audio-output/NOTICE.txt mac-audio-output/BUILD.txt project/Plugins/macos/audio/
chmod +x project/Plugins/macos/audio/ffmpeg
printf 'MACOS_PROJECT_INPUT_READY\n'
