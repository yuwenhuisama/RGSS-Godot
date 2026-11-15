#!/usr/bin/env bash
set -euo pipefail
base="$HOME/RGSS-Godot-Verification"
tar -xf "$base/mac-game-assets.tar.gz" -C "$base/project"
printf '{"project_path":"%s","rtp_path":"%s","legacy_mode":true,"legacy_mode_width":544,"legacy_mode_height":416,"cn_ver_rmva":true}\n' "$base/project" "$base/project/RTP" > "$base/project/rm_conf.json"
export DOTNET_ROOT="$base/dotnet"
export PATH="$DOTNET_ROOT:$PATH"
cd "$base/project"
dotnet build RGSS-Godot.csproj --no-restore > "$base/managed-native-path-build.log" 2>&1
godot="$base/godot/Godot_mono.app/Contents/MacOS/Godot"
"$godot" --windowed --max-fps 60 --path . -s tests/test_dense_map_runtime.gd > "$base/dense-short.log" 2>&1
grep -q 'DENSE_MAP_RUNTIME_PASS' "$base/dense-short.log"
printf 'MACOS_DENSE_SHORT_PASS\n'
