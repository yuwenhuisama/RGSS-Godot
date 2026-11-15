# RGSS-Godot

RPG Maker VX Ace's RGSS3 runtime, ported from Unity to **Godot 4.6 (.NET / C#)**.

The pure-Ruby RGSS layer runs on an embedded **mruby** VM (via `MRuby.Library` P/Invoke),
with the `Unity::*` bindings reimplemented on Godot nodes and the render layer rebuilt on
clipped viewport layers, ordered screen drawables and `.gdshader` effects.
Measured desktop builds cover Windows x64, Linux x86-64 and macOS arm64.

## Requirements

- Godot 4.6.1 **mono** (.NET) build (`Godot_v4.6.1-stable_mono_win64_console.exe`)
- .NET 8 SDK (tested with .NET 10 host SDK targeting `net8.0`)
- Matching native mruby host and four gems in `Plugins/<os>/` (measured binaries bundled)

## Build

Build the Godot C# project with dotnet:

```sh
dotnet restore RGSS-Godot.csproj
dotnet build RGSS-Godot.csproj --no-restore
```

## Run (Headless Boot Check)

Run a 30-frame headless boot verification:

```sh
godot --headless --path . --quit-after 30
```

Boot markers: `SCRIPTS_LOADED:OK` -> `MAIN_LOADED:OK` -> `Running RGSS3 main loop...`.

Set `project_path` and `rtp_path` in `rm_conf.json` to your locally installed game
and licensed RTP. Game assets are not included. Current isolated package boot and
measured compatibility results are in [current status](docs/compatibility/current-status.md);
older failures remain in the topic reports as historical evidence.

## Tests

Run the unified contract suite (each standalone runner executes in its own VM):

```sh
godot --headless --path . -s tools/run_tests.gd
godot --path . -s tools/run_tests.gd -- --rendered
godot --path . -s tools/run_tests.gd -- --rendered --windows-fonts
godot --path . -s tools/run_tests.gd -- --events --rendered
```

The headless command runs all **22** core contract runners (shutdown bitmaps, native extensions, zlib streams, Ruby errors, defined runtime, RGSS API cases, damage formulas, stress disposal, value semantics, table dimensions, RPG defaults/database, resource lifecycle, input mapping, reset callback, kernel file lifecycle, bitmap compositing, cursor cache, and Marshal IO/links/metadata/values).

The `--rendered` flag adds **10** GPU snapshot, frame loop, draw order, window transparency/activation/cursor, movie playback, and game settings/reset checks. `--windows-fonts` adds **5** Windows-only font metric and primitive layout checks (other platforms fail those baseline checks by design). `--events` adds **52** event, battle, audio, save, and dense-map contracts and requires the configured game's rendered `Boot` scene.

Every subprocess must exit 0 and emit its pass marker. Do not run rendered or event contracts with `--headless`. Keep ordinary tests and guest runs windowed (`user://rgss_settings.cfg` `fullscreen = false`) so desktop focus and guest captures are not interrupted; run `tests/test_original_fullscreen.gd` only for dedicated fullscreen acceptance.

Run the GUT test runner:

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

GUT currently runs only `test_sample.gd`. Run standalone `SceneTree` scripts directly when targeting individual contracts:

```sh
godot --headless --path . -s tests/test_rgss_api.gd
godot --headless --path . -s tests/test_eval_damage_fix.gd
godot --headless --path . -s tests/test_stress_dispose.gd
```

## Documentation

- Code change summary: [docs/compatibility/change-summary.md](docs/compatibility/change-summary.md)
- Current compatibility status (57/57 measured scope): [docs/compatibility/current-status.md](docs/compatibility/current-status.md)
- Open acceptance ledger and historical notes: [docs/compatibility/open-acceptance-ledger.md](docs/compatibility/open-acceptance-ledger.md)
- Per-item evidence index: [docs/compatibility/checklist-evidence-index.md](docs/compatibility/checklist-evidence-index.md)
- Development status and verified progress: [docs/development.md](docs/development.md)
- Cross-machine handoff notes: [docs/cross-machine-handoff.md](docs/cross-machine-handoff.md)
- Architecture roadmap: [.sisyphus/plans/editor-evolution-roadmap.md](.sisyphus/plans/editor-evolution-roadmap.md)

## Layout

| Path | Purpose |
|------|---------|
| `Scripts/` | C# engine: VM lifecycle, render manager, bindings |
| `RGSS/` | Reused pure-Ruby RGSS3 layer |
| `Shaders/` | `.gdshader` effect ports |
| `Plugins/` | Native mruby gem libraries per OS |
| `tests/` | SceneTree contracts, original-runtime fixtures and the GUT sample |
| `docs/` | Architecture specifications and progress tracking |
| `.github/workflows/` | macOS + Linux cross-platform CI |
