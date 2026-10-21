# RGSS-Godot

RPG Maker VX Ace's RGSS3 runtime, ported from Unity to **Godot 4.6 (.NET / C#)**.

The pure-Ruby RGSS layer runs on an embedded **mruby** VM (via `MRuby.Library` P/Invoke),
with the `Unity::*` bindings reimplemented on Godot nodes and the render layer rebuilt on
`SubViewport` compositing + `.gdshader` effects. Targets Windows, macOS, and Linux desktop.

## Requirements

- Godot 4.6.1 **mono** (.NET) build (`Godot_v4.6.1-stable_mono_win64_console.exe`)
- .NET 8 SDK (tested with .NET 10 host SDK targeting `net8.0`)
- Native mruby gems in `Plugins/<os>/` (Windows x64 DLLs bundled; macOS/Linux built in CI)

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

The latest local dirty-worktree check reached these markers but logged a null-texture
capture error, an audio load failure and an ObjectDB leak warning. This is not a clean
boot or proof that a fresh clone passes; see the development record.

## Tests

Run the GUT test runner:

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

GUT currently runs only the sample test. Run these three standalone `SceneTree`
scripts separately; they are not GUT tests:

```sh
godot --headless --path . -s tests/test_rgss_api.gd
godot --headless --path . -s tests/test_eval_damage_fix.gd
godot --headless --path . -s tests/test_stress_dispose.gd
```

## Documentation

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
| `tests/` | GUT test suite |
| `docs/` | Architecture specifications and progress tracking |
| `.github/workflows/` | macOS + Linux cross-platform CI |
