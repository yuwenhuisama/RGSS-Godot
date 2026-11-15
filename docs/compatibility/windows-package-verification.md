# Windows package verification

Local release export uses `export_presets.cfg`, installed Godot 4.6.1 .NET
Windows x86_64 templates and an owned output at
`.omo/evidence/windows-export/`. This is a workstation export, not a published
release or cross-platform result.

The first export exited 0 but logged `Cannot set object script` while exporting
GUT editor/test resources. It is not accepted as clean export evidence.
The preset now excludes `addons/gut/*` along with test/tool/documentation and
owned temporary trees. The second export exited 0 without that error, and
filesystem resource packaging returned WINDOWS_FILESYSTEM_PACKAGE_PASS.

RGSS Ruby files are loaded with filesystem reads rather than Godot resource
reads. `tools/package_windows.ps1 -Destination <export-directory>` copies that
runtime directory and local config beside an already exported executable.
Native libraries and the Windows LGPL decoder/source/notices are copied into
the .NET export data directory by the existing project content rules.
The copied config remains machine-specific; this run does not prove clean
installation or asset portability.

Runtime boot and a fresh-source WMA decode from the export remain pending.
The first launch command used a bare executable name in Bash and returned
command-not-found (127); the corrected absolute-path launch is running.

Corrected export boot exited 0 with CONFIG/SCRIPTS_LOADED/MAIN_LOADED and the
real game main loop. Two null-texture errors arose from freeze/transition under
the headless renderer; rendered export boot remains unverified. The release
template ignored an external `-s` test runner and started the game instead;
that run was stopped and is not WMA evidence. A dedicated Ruby main entry in
the owned export copy now calls the actual Audio.bgm_play path and records
success/failure. The source RGSS/main.rb is unchanged.

That exported Ruby audio run exited 0 and wrote `EXPORTED_WMA_PASS`; no
RGSS_FFMPEG_PATH was set. The previous failed external script run removed the
owned fresh-source cache before starting the game, so this result does not
reuse a pre-existing decode. Exported source main was restored afterward.
Actual rendered game boot is now running separately. This verifies Windows
bundle loading; macOS/Linux and fresh-machine installation remain open.

Rendered export boot completed exit 0 with CONFIG/SCRIPTS_LOADED/MAIN_LOADED
and the real RGSS3 main loop, without the headless null-texture errors. No
independent screenshot inspection was performed for this export run, so this
receipt proves rendered startup and native loading, not whole-game visual
acceptance or clean installation.
The source-project WMA loader already passed `AUDIO_FORMATS_PASS`, exit 0,
without an environment override or an old cache. macOS/Linux exports remain
unexecuted.

The 43-member source suite was interrupted with exit 127 after event-battle
success, without a TEST_SUITE result. No assertion failure was reported before
interruption; no complete pass is claimed. Earlier 41-member suite passed.
