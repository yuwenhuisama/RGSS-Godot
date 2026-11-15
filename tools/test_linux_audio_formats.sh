#!/usr/bin/env bash
set -euo pipefail
cd /tmp/linux-project
cp /repo/tools/linux_audio_test_config.json rm_conf.json
mkdir -p /tmp/linux-audio-project/RMProject/Audio
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
if [[ ${1:-} == me ]]; then

  cp /repo/tests/test_audio_me.gd tests/test_audio_me.gd
  cp /repo/tests/fixtures/audio_me_reference.rb tests/fixtures/audio_me_reference.rb
  "$godot" --headless --path . -s tests/test_audio_me.gd 2>&1 | tee /output/linux-audio-me-native-paths.log
  grep -q 'AUDIO_ME_PASS' /output/linux-audio-me-native-paths.log
  printf 'LINUX_AUDIO_ME_PASS\n'
  exit 0
fi
if [[ ${1:-} == loop ]]; then
  "$godot" --headless --path . -s tests/test_audio_loop.gd 2>&1 | tee /output/linux-audio-loop.log
  grep -q 'AUDIO_LOOP_PASS' /output/linux-audio-loop.log
  printf 'LINUX_AUDIO_LOOP_PASS\n'
  exit 0
fi
if [[ ${1:-} == se ]]; then
  "$godot" --headless --path . -s tests/test_audio_se.gd 2>&1 | tee /output/linux-audio-se.log
  grep -q 'AUDIO_SE_PASS' /output/linux-audio-se.log
  printf 'LINUX_AUDIO_SE_PASS\n'
  exit 0
fi
RGSS_TEST_FFMPEG=/tmp/linux-project/Plugins/linux/audio/ffmpeg \
  "$godot" --headless --path . -s tests/test_audio_formats.gd 2>&1 | tee /output/linux-audio-formats.log
grep -q 'AUDIO_FORMATS_PASS' /output/linux-audio-formats.log
if grep -q 'AUDIO_FORMATS_SKIP:' /output/linux-audio-formats.log; then exit 1; fi
printf 'LINUX_AUDIO_FORMATS_NO_SKIP_PASS\n'
