#!/usr/bin/env bash
set -euo pipefail
root=${1:?repository root required}
headers=${2:?matching host include directory required}
host=${3:?matching host library directory required}
output=${4:?output library path required}
sources=()
while IFS= read -r source; do sources+=("$root/$source"); done < <(awk '/"Onigmo\/.*\.c"/{gsub(/.*"Onigmo\//,"mruby-ext/regexp/Onigmo/"); gsub(/".*/,""); print}' "$root/mruby-ext/regexp/xmake.lua")
flags=(-DMRB_INT64 -DMRB_UTF8_STRING -DHAVE_ONIGMO_H -I "$headers" -I "$root/mruby-ext/regexp/Onigmo" -I "$root/mruby-ext/regexp/Onigmo/enc/unicode")
if [[ $(uname -s) == Darwin ]]; then
  clang -dynamiclib "${flags[@]}" "$root/mruby-ext/regexp/mruby-onig-regexp/src/"*.c "${sources[@]}" -L "$host" -lmruby_x64 -Wl,-rpath,@loader_path -o "$output"
else
  gcc -shared -fPIC "${flags[@]}" "$root/mruby-ext/regexp/mruby-onig-regexp/src/"*.c "${sources[@]}" -L "$host" -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs -o "$output"
fi
printf 'REGEXP_BOUNDARY_BUILD_PASS\n'
