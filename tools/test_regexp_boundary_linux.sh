#!/usr/bin/env bash
set -euo pipefail
headers=/repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include
for library in /repo/Plugins/linux/*.so; do
  name=$(basename "$library")
  if [[ $name != libmruby_onig_regexp_ext_x64.so ]]; then cp "$library" /output/; fi
done
gcc -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" /repo/tools/linux_extensions_probe.c \
  -L /output -lmruby_marshal_c_ext_x64 -lmruby_zlib_ext_x64 -lmruby_dir_glob_ext_x64 \
  -lmruby_onig_regexp_ext_x64 -lmruby_x64 '-Wl,-rpath,$ORIGIN' -o /output/probe
cd /output
printf "begin; 'abc' =~ 'b'; raise 'String pattern accepted'; rescue TypeError; end\nputs 'REGEXP_STRING_BOUNDARY_PASS'\n" > boundary.rb
./probe /repo/RGSS/ext/onig_regexp.rb boundary.rb
./probe /repo/RGSS/ext/onig_regexp.rb /repo/tools/defined-compiler/defined_yield_super_reference.rb
diff -u <(tr -d '\r' < /repo/tools/defined-compiler/defined_yield_super_original.tsv) defined_yield_super_reference.tsv
printf 'LINUX_REGEXP_BOUNDARY_PASS:77\n'
