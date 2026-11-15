# Verification tools

`run_tests.gd` is the contract suite entry. Read `tests/AGENTS.md` and
`docs/compatibility/current-status.md` for platform and fixture requirements.
`check_submission.ps1` parses PowerShell and Bash tools without executing
their actions; it requires Windows PowerShell and the installed Git Bash.

Reusable source inputs include the compiler archive and build configurations
under `defined-compiler`, `build_audio_decoder.sh`, `build_regexp_boundary.sh`
and `prepare_original_fixture.rb`. Their checks and required parameters are
in the files. `audio-loopback/Program.cs.txt` is intentional C# source selected
explicitly by its separate csproj, not a generated capture.

Most `run_linux_*`, `prepare_macos_*`, capture/deploy and older per-gem build
scripts are recorded workstation harnesses. They deliberately retain the
original machine paths, container mount layout and evidence directory names
used for the measurements. They may require the local
`rgss-linux-godot-verified:local` image or prior `.omo/evidence` build outputs;
these are not standalone clean-clone build entrypoints. Read each script's
inputs before running it. They are retained so the recorded experiment can
be reproduced in its original environment, not as portable release tooling.

Original-capture scripts may replace versioned `tests/fixtures/*_original.tsv`
outputs, so regenerate them only as a deliberate original-runtime measurement.
Frida trace files are pinned to the recorded RGSS300.dll offsets; Python audio
analysis needs NumPy. Device-specific loopback recordings and raw logs are
separate evidence streams, not interchangeable generic audio tests.

The current compiler source archive is tracked for rebuild recovery. Raw
logs, captures, downloaded editors, temporary projects, licensed source game
and RTP remain outside source control. Do not delete them during submission.
