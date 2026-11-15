#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
out="$base/mac-game-install"
mkdir "$out"
cp -R "$base/mac-release-native-path/install/RGSS-Godot.app" "$out/"
app="$out/RGSS-Godot.app/Contents/MacOS"
cp "$base/project/RGSS/main.rb" "$app/RGSS/main.rb"
cp -R "$base/project/RMProject" "$app/"
cp -R "$base/project/RTP" "$app/"
mkdir "$out/profile" "$out/empty-cwd"
printf '{"project_path":".","rtp_path":"RTP","legacy_mode":true,"legacy_mode_width":544,"legacy_mode_height":416,"cn_ver_rmva":true}\n' > "$app/rm_conf.json"
cd "$out/empty-cwd"
env -u DOTNET_ROOT -u MRUBY_DIR -u RGSS_FFMPEG_PATH PATH=/usr/bin:/bin HOME="$out/profile" "$app/RGSS-Godot" --windowed --max-fps 60 --quit-after 600 > "$out/runtime.log" 2>&1
grep -q MAIN_LOADED:OK "$out/runtime.log"
grep -q 'Metal 4.0' "$out/runtime.log"
if grep -Eq 'Exception:|MAIN_LOADED:FAIL|GEM_INIT_FAIL|ERROR:' "$out/runtime.log"; then cat "$out/runtime.log"; exit 1; fi
printf 'MACOS_GAME_INSTALL_PASS\n'
