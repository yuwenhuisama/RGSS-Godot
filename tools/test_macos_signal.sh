#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
out="$base/${1:-mac-audio-signal}"
mkdir "$out"
cp -R "$base/mac-release-native-path/install/RGSS-Godot.app" "$out/"
app="$out/RGSS-Godot.app/Contents/MacOS"
cp "$base/macos_audio_signal.rb" "$app/RGSS/main.rb"
cp "$base/project/tests/fixtures/midi-reference.mid" "$app/"
printf '{"project_path":"%s","rtp_path":"","legacy_mode":true,"legacy_mode_width":544,"legacy_mode_height":416,"cn_ver_rmva":true}\n' "$app" > "$app/rm_conf.json"
capture_app="$base/RGSS Audio Probe.app"
mkdir -p "$capture_app/Contents/MacOS"
cp "$base/macos_audio_capture.plist" "$capture_app/Contents/Info.plist"
clang -fobjc-arc -framework Foundation -framework AppKit -framework CoreAudio "$base/macos_process_audio.m" -o "$capture_app/Contents/MacOS/capture"
codesign --force --sign - --requirements '=designated => identifier "org.rgssgodot.audio-probe"' "$capture_app"
"$app/RGSS-Godot" --windowed --max-fps 60 --quit-after 3000 > "$out/game.log" 2>&1 &
game=$!
trap 'kill "$game" 2>/dev/null || true' EXIT
for ((i=0;i<300;i++)); do
  if test -f "$app/audio-ready"; then break; fi
  if ! kill -0 "$game" 2>/dev/null; then cat "$out/game.log"; exit 1; fi
  sleep 0.1
done
test -f "$app/audio-ready"
open -n "$capture_app" --args "$game" 40 "$out/signal.pcm" "$out/capture.log"
for ((i=0;i<1200;i++)); do
  if test -f "$out/capture.log" && grep -q TAP_RECORDING_READY "$out/capture.log"; then touch "$app/capture-start"; break; fi
  if test -f "$out/capture.log" && grep -q FAIL "$out/capture.log"; then cat "$out/capture.log"; exit 1; fi
  sleep 0.1
done
test -f "$app/capture-start"
for ((i=0;i<600;i++)); do
  if grep -q TAP_RECORDING_END "$out/capture.log"; then break; fi
  sleep 0.1
done
grep -q 'TAP_RECORDING_END:status=0' "$out/capture.log"
test -f "$app/sequence-finished"
touch "$app/capture-finished"
wait "$game"
grep -q MACOS_AUDIO_SIGNAL_SEQUENCE_PASS "$out/game.log"
cat "$out/capture.log"
printf 'MACOS_SIGNAL_CAPTURE_COMPLETE\n'
