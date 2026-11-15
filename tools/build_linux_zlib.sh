#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential
host=/repo/.omo/evidence/f10-linux-shared-host
headers=/repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include
cp "$host/libmruby_x64.so" /output/
gcc -shared -fPIC -DMRB_INT64 -DMRB_UTF8_STRING -DHAVE_UNISTD_H \
  -I "$headers" -I /repo/mruby-ext/zlib/zlib-1.3.1 \
  /repo/mruby-ext/zlib/mruby-zlib/src/*.c /repo/mruby-ext/zlib/zlib-1.3.1/*.c \
  -L /output -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs \
  -o /output/libmruby_zlib_ext_x64.so
gcc -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" /repo/tools/linux_zlib_probe.c \
  -L /output -lmruby_zlib_ext_x64 -lmruby_x64 '-Wl,-rpath,$ORIGIN' \
  -o /output/zlib_probe
cd /output
./zlib_probe /repo/tests/fixtures/gzip_reference.rb
diff -u /repo/tests/fixtures/gzip_original.tsv gzip_reference.tsv
./zlib_probe /repo/tests/fixtures/gzip_encoding_reference.rb
diff -u /repo/tests/fixtures/gzip_encoding_original.tsv gzip_encoding_reference.tsv
ldd libmruby_zlib_ext_x64.so > dependencies.txt
printf 'LINUX_ZLIB_GZIP_PARITY_PASS:17\n'
