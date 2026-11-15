#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
out="$base/mac-relocated-native"
mkdir "$out"
cp -R "$base/mac-release-native-path/install/RGSS-Godot.app" "$out/"
app="$out/RGSS-Godot.app/Contents/MacOS"
mkdir "$app/probes" "$app/results" "$out/empty-cwd" "$out/profile"
for name in native_extensions gzip_reader_io gzip_integrity file_binary; do
 cp "$base/project/tests/fixtures/${name}_reference.rb" "$base/project/tests/fixtures/${name}_original.tsv" "$app/probes/"
done
cp "$base/macos_release_native_main.rb" "$app/RGSS/main.rb"
printf '{"project_path":".","rtp_path":"","legacy_mode":true,"legacy_mode_width":544,"legacy_mode_height":416,"cn_ver_rmva":true}\n' > "$app/rm_conf.json"
cd "$out/empty-cwd"
env -u DOTNET_ROOT -u MRUBY_DIR -u RGSS_FFMPEG_PATH PATH=/usr/bin:/bin HOME="$out/profile" "$app/RGSS-Godot" --headless --audio-driver Dummy --max-fps 60 --quit-after 60 > "$out/runtime.log" 2>&1
grep -q MACOS_RELEASE_ORIGINAL_NATIVE_PASS "$out/runtime.log"
grep -q MAIN_LOADED:OK "$out/runtime.log"
printf 'MACOS_RELOCATED_NATIVE_PASS\n'
