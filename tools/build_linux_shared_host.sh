#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential unzip
archive=/repo/tools/defined-compiler/source/mruby-current-source.zip
printf '%s  %s\n' 354d38673ef8775a1f0bda4e2525cfd11321b0279e4d5a04565669cfd6a02783 "$archive" | sha256sum -c -
mkdir /tmp/shared-host-source
unzip -q "$archive" 'mruby-shared/*' -d /tmp/shared-host-source
input=/repo/.omo/evidence/f10-linux-current-mruby-config-fix/build
gcc -shared -fPIC -DMRB_CORE -DMRB_LIB -DMRB_INT64 -DMRB_UTF8_STRING \
  -I "$input/include" -I /tmp/shared-host-source/mruby-shared/src \
  /tmp/shared-host-source/mruby-shared/src/main.c \
  -Wl,--whole-archive "$input/lib/libmruby.a" -Wl,--no-whole-archive \
  -Wl,-z,defs -Wl,-soname,libmruby_x64.so -lm -o /output/libmruby_x64.so
nm -D --defined-only /output/libmruby_x64.so > /output/exports.txt
ldd /output/libmruby_x64.so > /output/dependencies.txt
printf 'LINUX_SHARED_HOST_BUILD_PASS\n'
