#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential ruby rake bison gperf unzip
archive=/repo/tools/defined-compiler/source/mruby-current-source.zip
printf '%s  %s\n' 354d38673ef8775a1f0bda4e2525cfd11321b0279e4d5a04565669cfd6a02783 "$archive" | sha256sum -c -
mkdir /tmp/current-mruby-source
unzip -q "$archive" -d /tmp/current-mruby-source
cd /tmp/current-mruby-source/mruby
cp /repo/tools/defined-compiler/build_config_linux.rb /tmp/build_config_linux.rb
rake MRUBY_CONFIG=/tmp/build_config_linux.rb all test 2>&1 | tee /output/build-test.log
build/linux-current/bin/mruby /repo/tools/defined-compiler/test_defined_semantics.rb 2>&1 | tee /output/defined-semantics.log
cp -R build/linux-current /output/build
printf 'LINUX_CURRENT_MRUBY_PASS\n'
