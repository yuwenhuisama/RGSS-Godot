#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
cd "$base/native"
printf '%s  %s\n' 354d38673ef8775a1f0bda4e2525cfd11321b0279e4d5a04565669cfd6a02783 tools/defined-compiler/source/mruby-current-source.zip | shasum -a 256 -c -
mkdir source output
unzip -q tools/defined-compiler/source/mruby-current-source.zip -d source
cp tools/defined-compiler/build_config_macos.rb source/build_config_macos.rb
cd source/mruby
rake MRUBY_CONFIG=../build_config_macos.rb all test 2>&1 | tee ../../output/mruby-build-test.log
build/macos-current/bin/mruby ../../tools/defined-compiler/test_defined_semantics.rb | tee ../../output/defined-semantics.log
cd ../..
headers=source/mruby/build/macos-current/include
lib=source/mruby/build/macos-current/lib/libmruby.a
clang -dynamiclib -DMRB_CORE -DMRB_LIB -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" -I source/mruby-shared/src source/mruby-shared/src/main.c -Wl,-force_load,"$lib" -Wl,-install_name,@rpath/libmruby_x64.dylib -o output/libmruby_x64.dylib
for gem in marshal glob; do
  case "$gem" in marshal) name=mruby-marshal-c; output_name=mruby_marshal_c;; glob) name=mruby-dir-glob; output_name=mruby_dir_glob;; esac
  clang -dynamiclib -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" -I "mruby-ext/$gem/$name/include" mruby-ext/"$gem"/"$name"/src/*.c -L output -lmruby_x64 -Wl,-rpath,@loader_path -o "output/lib${output_name}_ext_x64.dylib"
done
onig_sources=()
while IFS= read -r file; do onig_sources+=("$file"); done < <(awk '/"Onigmo\/.*\.c"/{gsub(/.*"Onigmo\//,"mruby-ext/regexp/Onigmo/"); gsub(/".*/,""); print}' mruby-ext/regexp/xmake.lua)
clang -dynamiclib -DMRB_INT64 -DMRB_UTF8_STRING -DHAVE_ONIGMO_H -I "$headers" -I mruby-ext/regexp/Onigmo -I mruby-ext/regexp/Onigmo/enc/unicode mruby-ext/regexp/mruby-onig-regexp/src/*.c "${onig_sources[@]}" -L output -lmruby_x64 -Wl,-rpath,@loader_path -o output/libmruby_onig_regexp_ext_x64.dylib
clang -dynamiclib -DMRB_INT64 -DMRB_UTF8_STRING -DHAVE_UNISTD_H -I "$headers" -I mruby-ext/zlib/zlib-1.3.1 mruby-ext/zlib/mruby-zlib/src/*.c mruby-ext/zlib/zlib-1.3.1/*.c -L output -lmruby_x64 -Wl,-rpath,@loader_path -o output/libmruby_zlib_ext_x64.dylib
for library in output/*.dylib; do
  file "$library"
  otool -L "$library" > "$library.dependencies.txt"
  nm -gU "$library" > "$library.exports.txt"
done
printf 'MACOS_NATIVE_BUILD_PASS\n'
