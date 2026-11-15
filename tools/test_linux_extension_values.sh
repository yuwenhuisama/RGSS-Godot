#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential
gcc -DMRB_INT64 -DMRB_UTF8_STRING \
  -I /repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include \
  /repo/tools/linux_extensions_probe.c -L /output -lmruby_marshal_c_ext_x64 \
  -lmruby_zlib_ext_x64 -lmruby_dir_glob_ext_x64 -lmruby_onig_regexp_ext_x64 \
  -lmruby_x64 '-Wl,-rpath,$ORIGIN' -o /output/extensions_probe
cd /output
./extensions_probe /repo/RGSS/ext/onig_regexp.rb /repo/tests/fixtures/marshal_values_reference.rb
diff -u <(tr -d '\r' < /repo/tests/fixtures/marshal_values_original.tsv) marshal_values_reference.tsv
printf 'LINUX_MARSHAL_VALUES_PARITY_PASS:20\n'
./extensions_probe /repo/RGSS/ext/onig_regexp.rb /repo/tests/fixtures/zlib_stream_reference.rb
diff -u <(tr -d '\r' < /repo/tests/fixtures/zlib_stream_original.tsv) zlib_stream_reference.tsv
printf 'LINUX_ZLIB_STREAM_PARITY_PASS:43\n'
