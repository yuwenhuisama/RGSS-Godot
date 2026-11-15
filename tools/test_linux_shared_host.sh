#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential
gcc -DMRB_INT64 -DMRB_UTF8_STRING \
  -I /repo/.omo/evidence/f10-linux-current-mruby-config-fix/build/include \
  -I /repo/.omo/compatibility-run-tmp/f05-defined-compiler/mruby-shared/src \
  /repo/tools/linux_shared_host_probe.c -L /output -lmruby_x64 \
  '-Wl,-rpath,$ORIGIN' -o /output/shared_host_probe
/output/shared_host_probe
