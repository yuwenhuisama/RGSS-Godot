#!/usr/bin/env bash
set -euo pipefail
cd /tmp/linux-project
# Refresh the image's measured project with current production inputs.
tar -C /repo -cf - project.godot RGSS-Godot.csproj RGSS-Godot.sln Scenes Scripts Shaders RGSS Plugins/linux Plugins/midi | tar -xf -
cp /repo/tools/linux_export_presets.cfg export_presets.cfg
printf '%s  %s\n' '9fe29b74e140a69b0b29884519050dffab0bef8d34046133c7d1613824331b3043d4cd1668bb7f2be0acb5ae43636eadac508fe7191df6d107490c23320e90a3' /baseline/export_templates-host.tpz | sha512sum -c -
mkdir -p /tmp/release-templates /root/.local/share/godot/export_templates/4.6.1.stable.mono /output/install
unzip -q /baseline/export_templates-host.tpz -d /tmp/release-templates
cp /tmp/release-templates/templates/linux_* /root/.local/share/godot/export_templates/4.6.1.stable.mono/
godot=/baseline/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
dotnet restore RGSS-Godot.csproj 2>&1 | tee /output/restore.log
"$godot" --headless --path . --editor --import --quit 2>&1 | tee /output/import.log
"$godot" --headless --path . --export-release Linux /output/install/RGSS-Godot.x86_64 2>&1 | tee /output/export-release.log
mkdir -p /output/msbuild-logs
cp -R /root/.local/share/godot/mono/build_logs/. /output/msbuild-logs/
if grep -q 'Failed to build project' /output/export-release.log; then
  find /output/msbuild-logs -name msbuild_log.txt -exec tail -n 40 '{}' \;
  exit 1
fi
chmod 755 /output/install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/linux/audio/ffmpeg
for library in /repo/Plugins/linux/*.so; do
  cmp "$library" "/output/install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/linux/$(basename "$library")"
done
cp -R RGSS /output/install/
cp /repo/tools/linux_export_main.rb /output/install/RGSS/main.rb
cp /repo/tools/linux_export_config.json /output/install/rm_conf.json
mkdir -p /output/install/RMProject /output/empty-working-directory
cd /output/empty-working-directory
/output/install/RGSS-Godot.x86_64 --headless --quit-after 60 2>&1 | tee /output/exported-runtime.log
grep -q 'LINUX_EXPORTED_RUBY_PASS' /output/exported-runtime.log
if grep -Eq 'GEM_INIT_FAIL|MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL|Exception:' /output/exported-runtime.log; then exit 1; fi
bash /repo/tools/test_linux_export_audio.sh
tar -C /output/install -cf /output/linux-headless-verified.tar .
sha256sum /output/linux-headless-verified.tar | tee /output/linux-headless-verified.sha256
printf 'LINUX_RELEASE_EXPORT_PASS\n'
