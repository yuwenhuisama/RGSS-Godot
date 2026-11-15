#!/usr/bin/env bash
set -euo pipefail
base="$HOME/RGSS-Godot-Verification"
test ! -e /tmp/rgss-symlink
mkdir -p /tmp/rgss-symlink/target-dir
printf 'link target\n' > /tmp/rgss-symlink/target.txt
ln -s target.txt /tmp/rgss-symlink/file-link
ln -s target-dir /tmp/rgss-symlink/dir-link
ln -s absent /tmp/rgss-symlink/dangling-link
cp "$base/linux_symlink_probe.gd" "$base/project/tools/"
cd "$base/project"
"$base/godot/Godot_mono.app/Contents/MacOS/Godot" --headless --path . -s tools/linux_symlink_probe.gd > "$base/macos-symlink.log" 2>&1
grep -q LINUX_MANAGED_SYMLINK_PASS:6 "$base/macos-symlink.log"
printf 'MACOS_MANAGED_SYMLINK_PASS:6\n'
