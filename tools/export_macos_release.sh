#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
release_name=${1:-mac-release}
export DOTNET_ROOT="$base/dotnet"
export PATH="$DOTNET_ROOT:$PATH"
templates="$HOME/Library/Application Support/Godot/export_templates/4.6.1.stable.mono"
mkdir -p "$templates" "$base/$release_name"
cp "$base/downloads/macos.zip" "$templates/macos.zip"
cp "$base/downloads/version.txt" "$templates/version.txt"
cd "$base/project"
cp "$base/macos_export_presets.cfg" export_presets.cfg
godot="$base/godot/Godot_mono.app/Contents/MacOS/Godot"
"$godot" --headless --max-fps 60 --path . --export-release macOS "$base/$release_name/RGSS-Godot.zip" 2>&1 | tee "$base/$release_name/export.log"
if grep -q 'Failed to build project' "$base/$release_name/export.log"; then exit 1; fi
unzip -q "$base/$release_name/RGSS-Godot.zip" -d "$base/$release_name/install"
find "$base/$release_name/install" -name '*.dylib' -o -name ffmpeg
printf 'MACOS_RELEASE_EXPORT_READY\n'
