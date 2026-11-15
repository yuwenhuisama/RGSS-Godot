#!/usr/bin/env bash
set -euo pipefail
mkdir -p /tmp/rgss-symlink/target-dir
printf 'link target\n' > /tmp/rgss-symlink/target.txt
ln -s target.txt /tmp/rgss-symlink/file-link
ln -s target-dir /tmp/rgss-symlink/dir-link
ln -s absent /tmp/rgss-symlink/dangling-link
cp /repo/tools/linux_symlink_probe.gd /tmp/linux-project/tools/
cd /tmp/linux-project
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --headless --path . -s tools/linux_symlink_probe.gd 2>&1 | tee /output/linux-symlink.log
grep -q 'LINUX_MANAGED_SYMLINK_PASS:6' /output/linux-symlink.log
