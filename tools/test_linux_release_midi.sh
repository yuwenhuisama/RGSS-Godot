#!/usr/bin/env bash
set -euo pipefail
if command -v dotnet || command -v gcc || command -v ffmpeg; then
  printf 'Unexpected development dependency\n' >&2
  exit 1
fi
mkdir -p /tmp/midi-install /tmp/midi-empty /tmp/midi-home
tar -xf /package.tar -C /tmp/midi-install
cp /repo/tools/linux_release_midi_main.rb /tmp/midi-install/RGSS/main.rb
mkdir -p /tmp/midi-install/probes
cp /repo/tests/fixtures/midi-reference*.mid /tmp/midi-install/probes/
bank=/tmp/midi-install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/midi
for name in TimGM6mb.sf2 GPL-2.0.txt MeltySynth-LICENSE.txt TimGM6mb-COPYRIGHT.txt NOTICE.txt timgm6mb-soundfont_1.3.orig.tar.gz; do
  cmp "/repo/Plugins/midi/$name" "$bank/$name"
done
cd /tmp/midi-empty
HOME=/tmp/midi-home XDG_DATA_HOME=/tmp/midi-home/data \
  /tmp/midi-install/RGSS-Godot.x86_64 --verbose --headless --max-fps 60 --quit-after 150 2>&1 | tee /evidence/midi-runtime.log
grep -q LINUX_RELEASE_MIDI_PASS /evidence/midi-runtime.log
if grep -Eq 'GEM_INIT_FAIL|MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL|Exception:|ObjectDB instances leaked' /evidence/midi-runtime.log; then exit 1; fi
printf 'LINUX_CLEAN_RELEASE_MIDI_PASS\n'
