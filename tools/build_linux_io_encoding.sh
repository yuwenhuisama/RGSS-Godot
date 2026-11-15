#!/usr/bin/env bash
set -euo pipefail
headers=/repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include
gcc -shared -fPIC -DMRB_INT64 -DMRB_UTF8_STRING -I "$headers" \
  -I /repo/mruby-ext/marshal/mruby-marshal-c/include \
  /repo/mruby-ext/marshal/mruby-marshal-c/src/*.c \
  -L /repo/Plugins/linux -lmruby_x64 '-Wl,-rpath,$ORIGIN' -Wl,-z,defs \
  -o /output/libmruby_marshal_c_ext_x64.so
printf 'LINUX_IO_ENCODING_BUILD_PASS\n'
