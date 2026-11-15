#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates
sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g; s|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources
apt-get update
apt-get install -y --no-install-recommends build-essential dotnet-sdk-8.0 curl unzip libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libgl1 libasound2t64
mkdir -p /tmp/linux-project /output/godot
cp /repo/.omo/evidence/f10-linux-godot-host-ubuntu/godot-linux.zip /output/godot-linux.zip
unzip -q /output/godot-linux.zip -d /output/godot
tar -C /repo -cf - project.godot RGSS-Godot.csproj RGSS-Godot.sln rm_conf.json Scenes Scripts Shaders RGSS tests tools/defined-compiler tools/run_tests.gd | tar -C /tmp/linux-project -xf -
mkdir -p /tmp/linux-project/Plugins/linux/audio
cp /repo/Plugins/linux/*.so /tmp/linux-project/Plugins/linux/
cp /repo/Plugins/linux/audio/ffmpeg /tmp/linux-project/Plugins/linux/audio/
cd /tmp/linux-project
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --version
dotnet build RGSS-Godot.csproj 2>&1 | tee /output/managed-build.log
"$godot" --headless --path . --editor --import --quit 2>&1 | tee /output/import.log
if [[ ${1:-} == suite ]]; then
  "$godot" --headless --path . -s tools/run_tests.gd 2>&1 | tee /output/base-suite.log
  grep -q 'TEST_SUITE_PASS:22' /output/base-suite.log
  printf 'LINUX_GODOT_BASE_SUITE_PASS\n'
  exit 0
fi
"$godot" --headless --path . -s tests/test_defined_runtime.gd 2>&1 | tee /output/defined-runtime.log
grep -q 'DEFINED_RUNTIME_PASS:77' /output/defined-runtime.log
"$godot" --headless --path . -s tests/test_native_extensions.gd 2>&1 | tee /output/native-extensions.log
grep -q 'NATIVE_EXTENSIONS_PASS' /output/native-extensions.log
printf 'LINUX_GODOT_HOST_PASS\n'
