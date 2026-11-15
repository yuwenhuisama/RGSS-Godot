#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/test_paths.sh"
cd /tmp/linux-project
game_project=/tmp/linux-project/RMProject
mkdir -p "$game_project"
ln -s /game-data "$game_project/Data"
export RGSS_TEST_PATHS_FILE=/output/test-paths.local.json
printf '{"game_project":"%s"}\n' "$game_project" > "$RGSS_TEST_PATHS_FILE"
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --headless --path . -s tests/test_rpg_database.gd 2>&1 | tee /output/database-with-data.log
grep -q 'RPG_DATABASE_PASS' /output/database-with-data.log
printf 'LINUX_DATABASE_WITH_DATA_PASS\n'
