#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
links="$base/project/.omo/compatibility-run-tmp/symlink"
test ! -e "$links"
mkdir -p "$links/target-dir"
printf 'link target\n' > "$links/target.txt"
ln -s target.txt "$links/file-link"
ln -s target-dir "$links/dir-link"
ln -s absent "$links/dangling-link"
cp "$base/linux_symlink_probe.gd" "$script_dir/test_paths.gd" "$base/project/tools/"
cd "$base/project"
"$base/godot/Godot_mono.app/Contents/MacOS/Godot" --headless --path . -s tools/linux_symlink_probe.gd > "$base/macos-symlink.log" 2>&1
grep -q LINUX_MANAGED_SYMLINK_PASS:6 "$base/macos-symlink.log"
printf 'MACOS_MANAGED_SYMLINK_PASS:6\n'
