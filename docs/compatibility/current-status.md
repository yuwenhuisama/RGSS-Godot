# Current Compatibility Status (2026-11-15)

The acceptance ledger records **57 of 57** items (and **63 of 63** execution checks) as accepted within their documented, versioned scopes. This is not a blanket claim of universal RGSS3 compatibility, unlimited runtime stability, or unverified platform support.

## Platform Measured Scopes

### macOS (Apple Silicon Only)
Measured on an Apple M4 arm64 host (macOS 27.0.1, build 26A434) under `~/RGSS-Godot-Verification`:
- **Independent Release installation:** The original-game Release export runs from an independent install path with relative project/RTP paths, an empty working directory, a fresh `HOME`, a system-only `PATH`, and no SDK, native, or decoder overrides. Windowed Metal startup, a 600-frame exit, and two pinned RGSS300 Tilemap occlusion/scroll hashes pass with exit 0.
- **Native libraries and audio:** Clang 17 builds all five arm64 mruby libraries (`1696 OK / 0 KO / 0 Crash / 9 Skip`, 65 defined semantics cases pass) and the native LGPL WMA decoder. All 10 native/decoder/source/license/notice/build files match the project payload byte for byte. A 40-second CoreAudio capture records 440 Hz WMA and MIDI C4 signals with exact silence after stop.
- **Base suite:** Combined 22-owner coverage (21 passed in the first invocation, plus the RPG database owner passing once `RMProject/Data` inputs were supplied).
- **Editor soak vs. Release app:** The 36,000-frame dense-map resource profile ran against the **editor-loaded current assembly**, not the Release app. Resources restore from `(5, 107, 7)` to `(5, 11, 7)` with 358 nodes. FPS samples sit mostly at 55 to 58 with lows of 34 and 30 (not a stable 60 FPS claim). Metal `texture_bytes` returns `INT64_MAX` in all samples and is unusable as GPU memory evidence.
- **Build warnings:** Current C# builds exit 0 with **7 existing warnings** retained.
- **Not claimed:** Intel Mac execution, Apple notarization for downloaded distribution, and factory-reset macOS testing remain unverified.

### Windows (x64)
Measured in an isolated Windows guest and controlled host runs:
- **Release package:** Combined export (EXE, PCK, and 217 runtime files) passes restricted-path boot, fresh-cache WMA decode (exact 20,558-byte reference WAV SHA256), WASAPI 440 Hz WMA output, File/IO, Windows MIDI Mapper playback, and 6 true-symlink cases (with guest developer mode enabled).
- **Contracts and soak:** Combined 22-owner base suite coverage passes, alongside E06 fade, E07 ME/BGM handoff, E08 SE capacity, D05 message window, C12 fullscreen/refresh restoration, and 36,000-frame resource restoration `(5, 11, 7)`.

### Linux (x86-64)
Measured in an Ubuntu 24.04.5 x86-64 VMware guest (DX12/Xorg and PipeWire):
- **Release package:** Passes offline WMA decode/relocation, 9 RGSS300 File rows, 24 extension + 11 IO + 6 integrity rows, true symlinks, and PipeWire 440 Hz WMA capture.
- **Soak:** 36,000-frame DX12/Xorg dense-map soak restores `(5, 11, 7)` at 24 to 29 FPS; stock-map short runs measure 58.45 to 59.36 FPS.

## Navigation
- Full item index: [checklist-evidence-index.md](checklist-evidence-index.md)
- Ledger and historical notes: [open-acceptance-ledger.md](open-acceptance-ledger.md)
- macOS verification details: [macos-verification.md](macos-verification.md)
