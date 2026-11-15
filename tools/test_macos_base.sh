#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
base=$(test_path mac_workspace)
export DOTNET_ROOT="$base/dotnet"
export PATH="$DOTNET_ROOT:$PATH"
cd "$base/project"
godot="$base/godot/Godot_mono.app/Contents/MacOS/Godot"
"$godot" --headless --path . --editor --import --quit 2>&1 | tee ../import.log
"$godot" --headless --path . -s tools/run_tests.gd 2>&1 | tee ../base-suite.log
grep -q 'TEST_SUITE_PASS:22' ../base-suite.log
printf 'MACOS_BASE_SUITE_PASS\n'
