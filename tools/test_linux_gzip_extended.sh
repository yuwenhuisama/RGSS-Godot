#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
cd /tmp/linux-project
if [[ ${1:-} == production ]]; then
  cp /repo/Plugins/linux/*.so Plugins/linux/
elif [[ ${1:-} == suite ]]; then
  cp /output/libmruby_zlib_ext_extended_x64.so Plugins/linux/libmruby_zlib_ext_x64.so
else
gcc -shared -fPIC -DMRB_INT64 -DMRB_UTF8_STRING -DHAVE_UNISTD_H \
  -I /repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include \
  -I /repo/mruby-ext/zlib/zlib-1.3.1 \
  /repo/mruby-ext/zlib/mruby-zlib/src/*.c /repo/mruby-ext/zlib/zlib-1.3.1/*.c \
  -L Plugins/linux -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs \
  -o Plugins/linux/libmruby_zlib_ext_x64.so
cp Plugins/linux/libmruby_zlib_ext_x64.so /output/libmruby_zlib_ext_extended_x64.so
fi
cp /repo/tests/test_native_extensions.gd tests/
cp /repo/tests/fixtures/gzip_encoding_extended_original.tsv tests/fixtures/
cp /repo/tests/fixtures/gzip_encoding_extended_reference.rb tests/fixtures/
cp /repo/tests/fixtures/gzip_reader_io_reference.rb /repo/tests/fixtures/gzip_reader_io_original.tsv tests/fixtures/
cp /repo/tests/fixtures/gzip_integrity_reference.rb /repo/tests/fixtures/gzip_integrity_original.tsv tests/fixtures/
dotnet build RGSS-Godot.csproj --no-restore 2>&1 | tee /output/gzip-extended-managed-build.log
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
if [[ ${1:-} == suite ]]; then
  game_project=/tmp/linux-project/RMProject
  mkdir -p "$game_project"
  ln -s /game-data "$game_project/Data"
  export RGSS_TEST_PATHS_FILE=/output/test-paths.local.json
  printf '{"game_project":"%s"}\n' "$game_project" > "$RGSS_TEST_PATHS_FILE"
  "$godot" --headless --path . -s tools/run_tests.gd 2>&1 | tee /output/linux-base-gzip-extended.log
  grep -q 'TEST_SUITE_PASS:22' /output/linux-base-gzip-extended.log
  printf 'LINUX_GZIP_EXTENDED_BASE_PASS\n'
  exit 0
fi
"$godot" --headless --path . -s tests/test_native_extensions.gd 2>&1 | tee /output/linux-native-gzip-extended.log
grep -q 'NATIVE_EXTENSIONS_PASS' /output/linux-native-gzip-extended.log
printf 'LINUX_GZIP_EXTENDED_HOST_PASS\n'
