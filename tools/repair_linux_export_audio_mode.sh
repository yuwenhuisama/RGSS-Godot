#!/usr/bin/env bash
set -euo pipefail
cp /output/exported-wma-runtime.log /output/exported-wma-before-mode-fix.log
chmod 755 /output/install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/linux/audio/ffmpeg
bash /repo/tools/test_linux_export_audio.sh
