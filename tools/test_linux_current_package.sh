#!/usr/bin/env bash
set -euo pipefail
mkdir -p /tmp/current-install /tmp/empty-cwd /tmp/current-home
tar -xf /output/linux-headless-verified.tar -C /tmp/current-install
cp /output/libmruby_zlib_ext_extended_x64.so /tmp/current-install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/linux/libmruby_zlib_ext_x64.so
cp /repo/tools/linux_current_gzip_main.rb /tmp/current-install/RGSS/main.rb
cp /repo/tests/fixtures/gzip_encoding_extended_reference.rb /repo/tests/fixtures/gzip_encoding_extended_original.tsv /tmp/current-install/
tar -C /tmp/current-install -cf /output/linux-current-gzip-package.tar .
sha256sum /output/linux-current-gzip-package.tar | tee /output/linux-current-gzip-package.sha256
cd /tmp/empty-cwd
HOME=/tmp/current-home XDG_DATA_HOME=/tmp/current-home/data /tmp/current-install/RGSS-Godot.x86_64 --headless --quit-after 60 2>&1 | tee /output/current-gzip-package-runtime.log
grep -q 'LINUX_CURRENT_EXPORTED_GZIP_PASS:14' /output/current-gzip-package-runtime.log
grep -q 'LINUX_EXPORTED_WMA_LOAD_PASS' /output/current-gzip-package-runtime.log
grep -q 'MAIN_LOADED:OK' /output/current-gzip-package-runtime.log
find /tmp/current-home -name '*.wav' -exec cp '{}' /output/current-gzip-wma-cache.wav \;
cmp /repo/.omo/evidence/audio-decoder/linux/decoded.wav /output/current-gzip-wma-cache.wav
printf 'LINUX_CURRENT_GZIP_PACKAGE_PASS\n'
