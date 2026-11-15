#!/usr/bin/env bash
set -euo pipefail
if command -v dotnet || command -v gcc || command -v ffmpeg; then
  printf 'Unexpected development or system decoder dependency\n' >&2
  exit 1
fi
mkdir -p /tmp/empty-working-directory /tmp/rgss-clean-home
installation=/install
log=/evidence/clean-runtime-with-libraries.log
if [[ -f /package.tar ]]; then
  installation=/tmp/relocated-install
  log=/evidence/archived-package-runtime.log
  mkdir -p "$installation"
  tar -xf /package.tar -C "$installation"
fi
cd /tmp/empty-working-directory
HOME=/tmp/rgss-clean-home XDG_DATA_HOME=/tmp/rgss-clean-home/data \
  "$installation/RGSS-Godot.x86_64" --headless --quit-after 60 2>&1 | tee "$log"
grep -q 'LINUX_EXPORTED_WMA_LOAD_PASS' "$log"
if grep -Eq 'AUDIO_WMA_.*(FAIL|ERR|NO_DECODER)|GEM_INIT_FAIL|MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL|Exception:' "$log"; then exit 1; fi
find /tmp/rgss-clean-home -name '*.wav' -exec cp '{}' /evidence/clean-export-cache.wav \;
cmp /reference.wav /evidence/clean-export-cache.wav
printf 'LINUX_CLEAN_EXPORTED_WMA_PASS\n'
