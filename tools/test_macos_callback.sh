#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/RGSS-Godot-Verification/native"
clang -DMRB_INT64 -DMRB_UTF8_STRING -I source/mruby/build/macos-current/include -I source/mruby-shared/src tools/linux_shared_host_probe.c -L output -lmruby_x64 -Wl,-rpath,@loader_path -o output/callback-probe
output/callback-probe | tee output/callback.log
printf 'MACOS_SHARED_CALLBACK_PASS\n'
