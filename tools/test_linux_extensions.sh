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
./extensions_probe /repo/RGSS/ext/onig_regexp.rb /repo/tools/defined-compiler/defined_yield_super_reference.rb
diff -u <(tr -d '\r' < /repo/tools/defined-compiler/defined_yield_super_original.tsv) defined_yield_super_reference.tsv
printf 'LINUX_DEFINED_ORIGINAL_PARITY_PASS:77\n'
./extensions_probe /repo/RGSS/ext/onig_regexp.rb /repo/tests/fixtures/marshal_io_reference.rb
printf 'LINUX_MARSHAL_IO_EXECUTED\n'
