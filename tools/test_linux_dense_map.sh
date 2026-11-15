#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends xvfb xauth libgl1-mesa-dri
cd /tmp/linux-project
tar -C /repo -cf - project.godot RGSS-Godot.csproj RGSS-Godot.sln Scenes Scripts Shaders RGSS tests Plugins/linux | tar -xf -
cp /repo/tools/linux_dense_map_config.json rm_conf.json
dotnet build RGSS-Godot.csproj --no-restore 2>&1 | tee /output/build.log
godot=/baseline/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --headless --path . --editor --import --quit 2>&1 | tee /output/import.log
mkdir -p /tmp/dense-home .omo/evidence/rmva-compatibility/godot/dense-map
ln -s /output/profile .omo/evidence/rmva-compatibility/godot/dense-map/soak
HOME=/tmp/dense-home XDG_DATA_HOME=/tmp/dense-home/data LIBGL_ALWAYS_SOFTWARE=1 \
  xvfb-run -a -s '-screen 0 1280x1024x24' "$godot" --path . \
  --windowed --rendering-method gl_compatibility --audio-driver Dummy \
  -s tests/test_dense_map_runtime.gd -- --resource-profile 2>&1 | tee /output/runtime.log
grep -q 'DENSE_MAP_RUNTIME_PASS' /output/runtime.log
printf 'LINUX_RENDERED_DENSE_MAP_PASS\n'
