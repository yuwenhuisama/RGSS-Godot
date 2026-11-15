#!/usr/bin/env bash
set -euo pipefail
base="$HOME/RGSS-Godot-Verification"
release_name=${1:-mac-release}
app="$base/$release_name/install/RGSS-Godot.app"
mkdir -p "$app/Contents/MacOS/RGSS" "$base/$release_name/empty-cwd" "$base/$release_name/profile"
cp -R "$base/project/RGSS/." "$app/Contents/MacOS/RGSS/"
cp "$base/macos_release_probe.rb" "$app/Contents/MacOS/RGSS/main.rb"
cp "$base/mac-audio-input/tone.wma" "$app/Contents/MacOS/tone.wma"
printf '{"project_path":"%s","rtp_path":"","legacy_mode":true,"legacy_mode_width":544,"legacy_mode_height":416,"cn_ver_rmva":true}\n' "$app/Contents/MacOS" > "$app/Contents/MacOS/rm_conf.json"
cd "$base/$release_name/empty-cwd"
env -u DOTNET_ROOT -u MRUBY_DIR -u RGSS_FFMPEG_PATH PATH=/usr/bin:/bin HOME="$base/$release_name/profile" "$app/Contents/MacOS/RGSS-Godot" --headless --audio-driver Dummy --max-fps 60 --quit-after 60 > "$base/$release_name/runtime.log" 2>&1
grep -q 'MACOS_RELEASE_NATIVE_WMA_PASS' "$base/$release_name/runtime.log"
grep -q 'MAIN_LOADED:OK' "$base/$release_name/runtime.log"
printf 'MACOS_RELEASE_RUNTIME_PASS\n'
