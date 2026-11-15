#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential
headers=/repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include
cp /repo/.omo/evidence/f10-linux-shared-host/libmruby_x64.so /output/
cp /repo/.omo/evidence/f08-linux-zlib/libmruby_zlib_ext_x64.so /output/
gcc -shared -fPIC -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" \
  -I /repo/mruby-ext/marshal/mruby-marshal-c/include \
  /repo/mruby-ext/marshal/mruby-marshal-c/src/*.c \
  -L /output -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs \
  -o /output/libmruby_marshal_c_ext_x64.so
gcc -shared -fPIC -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" \
  -I /repo/mruby-ext/glob/mruby-dir-glob/include \
  /repo/mruby-ext/glob/mruby-dir-glob/src/*.c \
  -L /output -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs \
  -o /output/libmruby_dir_glob_ext_x64.so
mapfile -t onig_sources < <(awk '/"Onigmo\/.*\.c"/{gsub(/.*"Onigmo\//,"/repo/mruby-ext/regexp/Onigmo/"); gsub(/".*/,""); print}' /repo/mruby-ext/regexp/xmake.lua)
gcc -shared -fPIC -DMRB_INT64 -DMRB_UTF8_STRING -DHAVE_ONIGMO_H \
  -I "$headers" -I /repo/mruby-ext/regexp/Onigmo -I /repo/mruby-ext/regexp/Onigmo/enc/unicode \
  /repo/mruby-ext/regexp/mruby-onig-regexp/src/*.c "${onig_sources[@]}" \
  -L /output -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs \
  -o /output/libmruby_onig_regexp_ext_x64.so
for library in /output/*_ext_x64.so; do
  nm -D --defined-only "$library" > "$library.exports.txt"
  ldd "$library" > "$library.dependencies.txt"
done
printf 'LINUX_FOUR_EXTENSIONS_BUILD_PASS\n'
