#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential ruby rake bison gperf unzip
mkdir /tmp/archived-source
unzip -q /archive.zip -d /tmp/archived-source
cd /tmp/archived-source/mruby
cp /checks/build_config_linux.rb /tmp/archived-source/build_config_linux.rb
rake MRUBY_CONFIG=/tmp/archived-source/build_config_linux.rb all test 2>&1 | tee /output/build-test.log
build/linux-current/bin/mruby /checks/test_defined_semantics.rb 2>&1 | tee /output/defined-semantics.log
gcc -shared -fPIC -DMRB_CORE -DMRB_LIB -DMRB_INT64 -DMRB_UTF8_STRING \
  -I build/linux-current/include -I ../mruby-shared/src \
  ../mruby-shared/src/main.c \
  -Wl,--whole-archive build/linux-current/lib/libmruby.a -Wl,--no-whole-archive \
  -Wl,-z,defs -Wl,-soname,libmruby_x64.so -lm -o /output/libmruby_x64.so
gcc -DMRB_INT64 -DMRB_UTF8_STRING -I build/linux-current/include \
  -I ../mruby-shared/src /checks/linux_shared_host_probe.c \
  -L /output -lmruby_x64 '-Wl,-rpath,$ORIGIN' -o /output/shared_host_probe
/output/shared_host_probe | tee /output/callback.log
printf 'ARCHIVED_MRUBY_SOURCE_REBUILD_PASS\n'
