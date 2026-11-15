#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends xvfb xauth libgl1-mesa-dri
mkdir -p /tmp/release-install /tmp/empty-cwd /tmp/render-home /evidence/frames
tar -xf /package.tar -C /tmp/release-install
cp /repo/tools/linux_release_render_main.rb /tmp/release-install/RGSS/main.rb
cd /tmp/empty-cwd
HOME=/tmp/render-home XDG_DATA_HOME=/tmp/render-home/data LIBGL_ALWAYS_SOFTWARE=1 \
  xvfb-run -a -s '-screen 0 1280x1024x24' /tmp/release-install/RGSS-Godot.x86_64 \
  --rendering-method gl_compatibility --audio-driver Dummy --windowed \
  --write-movie /evidence/frames/render.png --fixed-fps 60 --quit-after 12 \
  2>&1 | tee /evidence/runtime.log
grep -q 'LINUX_RELEASE_RENDER_READY' /evidence/runtime.log
grep -q 'OpenGL' /evidence/runtime.log
if grep -Eq 'MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL|GEM_INIT_FAIL' /evidence/runtime.log; then exit 1; fi
find /evidence/frames -name '*.png' -print
printf 'LINUX_RELEASE_RENDER_CAPTURE_PASS\n'
