#!/usr/bin/env bash
set -euo pipefail
cd /tmp/linux-project
cp /repo/RGSS-Godot.sln .
printf '%s  %s\n' '9fe29b74e140a69b0b29884519050dffab0bef8d34046133c7d1613824331b3043d4cd1668bb7f2be0acb5ae43636eadac508fe7191df6d107490c23320e90a3' /output/export_templates-host.tpz | sha512sum -c -
unzip -tq /output/export_templates-host.tpz
mkdir -p /tmp/templates /root/.local/share/godot/export_templates/4.6.1.stable.mono /output/install
unzip -q /output/export_templates-host.tpz -d /tmp/templates
cp /tmp/templates/templates/linux_* /root/.local/share/godot/export_templates/4.6.1.stable.mono/
cp /repo/tools/linux_export_presets.cfg export_presets.cfg
for artifact in ffmpeg ffmpeg-8.1.3.tar.xz LICENSE.txt NOTICE.txt BUILD.txt; do
  cp "/repo/Plugins/linux/audio/$artifact" Plugins/linux/audio/
done
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --headless --path . --export-debug Linux /output/install/RGSS-Godot.x86_64 2>&1 | tee /output/linux-export-with-solution.log
# Godot's .NET content export copies this executable with mode 0644.
chmod 755 /output/install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/linux/audio/ffmpeg
cp -R RGSS /output/install/
cp /repo/tools/linux_export_main.rb /output/install/RGSS/main.rb
cp /repo/tools/linux_export_config.json /output/install/rm_conf.json
mkdir -p /output/install/RMProject
mkdir -p /output/empty-working-directory
cd /output/empty-working-directory
/output/install/RGSS-Godot.x86_64 --headless --quit-after 60 2>&1 | tee /output/exported-runtime.log
grep -q 'LINUX_EXPORTED_RUBY_PASS' /output/exported-runtime.log
if grep -Eq 'GEM_INIT_FAIL|MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL|Exception:' /output/exported-runtime.log; then exit 1; fi
printf 'LINUX_EXPORTED_HOST_PASS\n'
bash /repo/tools/test_linux_export_audio.sh
