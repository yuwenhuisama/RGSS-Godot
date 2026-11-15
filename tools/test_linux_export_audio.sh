#!/usr/bin/env bash
set -euo pipefail
mkdir -p /output/install/RMProject/Audio/BGM
cp /repo/tests/fixtures/audio/tone.wma /output/install/RMProject/Audio/BGM/export-tone.wma
cp /repo/tools/linux_export_audio_main.rb /output/install/RGSS/main.rb
mkdir -p /output/audio-empty-working-directory /tmp/rgss-audio-home
cd /output/audio-empty-working-directory
HOME=/tmp/rgss-audio-home XDG_DATA_HOME=/tmp/rgss-audio-home/data \
  /output/install/RGSS-Godot.x86_64 --headless --quit-after 60 2>&1 | tee /output/exported-wma-runtime.log
grep -q 'LINUX_EXPORTED_WMA_LOAD_PASS' /output/exported-wma-runtime.log
if grep -Eq 'AUDIO_WMA_.*(FAIL|ERR|NO_DECODER)|GEM_INIT_FAIL|MAIN_LOADED:FAIL|Exception:' /output/exported-wma-runtime.log; then exit 1; fi
find /tmp/rgss-audio-home -name '*.wav' -exec cp '{}' /output/exported-wma-cache.wav \;
test -s /output/exported-wma-cache.wav
cmp /repo/.omo/evidence/audio-decoder/linux/decoded.wav /output/exported-wma-cache.wav
printf 'LINUX_EXPORTED_WMA_CACHE_PASS\n'
