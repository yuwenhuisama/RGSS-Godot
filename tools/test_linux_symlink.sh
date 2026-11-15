#!/usr/bin/env bash
set -euo pipefail
TEST_REPO_ROOT=/tmp/linux-project
links="$TEST_REPO_ROOT/.omo/compatibility-run-tmp/symlink"
test ! -e "$links"
mkdir -p "$links/target-dir"
printf 'link target\n' > "$links/target.txt"
ln -s target.txt "$links/file-link"
ln -s target-dir "$links/dir-link"
ln -s absent "$links/dangling-link"
cp /repo/tools/linux_symlink_probe.gd /repo/tools/test_paths.gd "$TEST_REPO_ROOT/tools/"
cd "$TEST_REPO_ROOT"
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --headless --path . -s tools/linux_symlink_probe.gd 2>&1 | tee /output/linux-symlink.log
grep -q 'LINUX_MANAGED_SYMLINK_PASS:6' /output/linux-symlink.log
