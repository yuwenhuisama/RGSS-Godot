#!/usr/bin/env bash
set -euo pipefail
if command -v dotnet || command -v gcc || command -v ffmpeg; then
  printf 'Unexpected development or system decoder dependency\n' >&2
  exit 1
fi
mkdir -p /tmp/release-install /tmp/empty-cwd /tmp/release-home
tar -xf /package.tar -C /tmp/release-install
cp /repo/tools/linux_release_native_main.rb /tmp/release-install/RGSS/main.rb
mkdir -p /tmp/release-install/probes
for name in native_extensions gzip_reader_io gzip_integrity file_binary; do
  cp "/repo/tests/fixtures/${name}_reference.rb" "/repo/tests/fixtures/${name}_original.tsv" /tmp/release-install/probes/
done
cd /tmp/empty-cwd
HOME=/tmp/release-home XDG_DATA_HOME=/tmp/release-home/data \
  /tmp/release-install/RGSS-Godot.x86_64 --headless --quit-after 60 2>&1 | tee /evidence/runtime.log
grep -q 'LINUX_RELEASE_CLEAN_NATIVE_PASS' /evidence/runtime.log
if grep -Eq 'GEM_INIT_FAIL|MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL|Exception:' /evidence/runtime.log; then exit 1; fi
