#!/usr/bin/env bash
set -euo pipefail
cd /tmp/linux-project
mkdir -p 'E:/Projects/RMProject'
ln -s /game-data 'E:/Projects/RMProject/Data'
godot=/output/godot/Godot_v4.6.1-stable_mono_linux_x86_64/Godot_v4.6.1-stable_mono_linux.x86_64
"$godot" --headless --path . -s tests/test_rpg_database.gd 2>&1 | tee /output/database-with-data.log
grep -q 'RPG_DATABASE_PASS' /output/database-with-data.log
printf 'LINUX_DATABASE_WITH_DATA_PASS\n'
