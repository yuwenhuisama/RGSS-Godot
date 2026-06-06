# RGSS-Godot

RPG Maker VX Ace's RGSS3 runtime, ported from Unity to **Godot 4.6 (.NET / C#)**.

The pure-Ruby RGSS layer runs on an embedded **mruby** VM (via `MRuby.Library` P/Invoke),
with the `Unity::*` bindings reimplemented on Godot nodes and the render layer rebuilt on
`SubViewport` compositing + `.gdshader` effects. Targets Windows, macOS, and Linux desktop.

## Requirements

- Godot 4.6.1 **mono** (.NET) build
- .NET 8 SDK
- Native mruby gems in `Plugins/<os>/` (Windows x64 DLLs bundled; macOS/Linux built in CI)

## Run (headless boot check)

```sh
godot --headless --path . --quit-after 30
```

Expected markers: `SCRIPTS_LOADED:OK` -> `MAIN_LOADED:OK` -> `Running RGSS3 main loop...`

## Tests (GUT 9.6.0)

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

## Layout

| Path | Purpose |
|------|---------|
| `Scripts/` | C# engine: VM lifecycle, render manager, bindings |
| `RGSS/` | Reused pure-Ruby RGSS3 layer |
| `Shaders/` | `.gdshader` effect ports |
| `Plugins/` | Native mruby gem libraries per OS |
| `tests/` | GUT test suite |
| `.github/workflows/` | macOS + Linux cross-platform CI |
