#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
payload="$base/mac-release-native-path/install/RGSS-Godot.app/Contents/Resources/data_RGSS-Godot_macos_arm64/Plugins/macos"
out="$base/mac-release-native-path/payload-audit.tsv"
printf 'relative_path\tsha256\n' > "$out"
for source in "$base/project/Plugins/macos/"*.dylib "$base/project/Plugins/macos/audio/"*; do
  relative=${source#"$base/project/Plugins/macos/"}
  cmp "$source" "$payload/$relative"
  hash=$(shasum -a 256 "$payload/$relative" | awk '{print $1}')
  printf '%s\t%s\n' "$relative" "$hash" >> "$out"
done
printf 'MACOS_RELEASE_PAYLOAD_PASS:10\n'
