# Compatibility change summary (2026-11-15)

This increment carries the measured A01-F11 implementation, its original
RGSS300 fixtures and the matching native/audio payload. Current acceptance
and limitations are in [current-status.md](current-status.md); detailed topic
reports retain earlier failed experiments as historical evidence.

## Runtime changes

- Ruby script loads now report compilation failures, use independent compile
  contexts and release the rooted update fiber during shutdown. The owned
  mruby compiler implements unevaluated `defined?` and lexical match globals.
- Ruby wrappers preserve resource/property identity and reject disposed
  access. Color/Tone doubles, Table dimensions/resize/Marshal, RPG defaults
  and binary File IO follow the measured original semantics.
- Ordered screen drawables and clipped viewport segments replace the former
  isolated SubViewport composition. Bitmap mixing/text, sprite sampling,
  rotation/wave, plane tiling, windowskin/cursor/pause, tilemap revisions and
  transitions have original pixel/temporal contracts.
- Input defaults, F1 properties, F2 FPS and F12 reset are wired. Windows
  fullscreen uses explicit mode save/restore and physical pixel presentation;
  ordinary tests stay windowed.
- Audio adds bundled WMA decoding/cache, Windows MIDI Mapper and Linux/Mac
  software MIDI, stream loop/seek/fade, ME pause/resume and growing busy SE
  capacity. Movies use Theora playback with cooperative frame updates.
- Native Marshal, Onigmo, glob and Zlib fixes use matching host ABI settings.
  Windows x64, Linux x86-64 and Mac arm64 binaries ship with decoder/bank
  licenses and corresponding source archives.

## Verification and packaging

The unified runner requires each subprocess exit code and PASS marker. It
contains 22 headless, 10 rendered, 5 Windows-font and 52 event entries.
Original fixtures and goldens are tracked under `tests/fixtures`; build,
capture and packaging recipes are under `tools`. The pinned compiler archive
under `tools/defined-compiler/source` preserves rebuild inputs.

For this submission, `dotnet build RGSS-Godot.csproj --no-restore` and the
22-owner headless suite both exit 0. Platform package, audio signal, pixel and
36,000-frame evidence from the preceding acceptance run remains recorded in
the topic reports. Raw logs/captures under `.omo/evidence` stay local and are
not part of source control. Some original/game contracts require separately
installed licensed game data and RTP; those assets are not distributed here.

Local machine configuration, agent session state, dependency caches and UI
captures are preserved outside the submitted project increment. No remote
push is included. Native submodule commits must accompany the parent pointer
updates when this work is later published or transferred.

Submission review additionally reproduces `String#=~` with a String parameter
as `SystemStackError` in the old native entry. The fix raises TypeError at
that boundary; Windows, Linux and Mac pass the regression and the existing
77-row original match/defined fixture. All three regexp payloads are rebuilt.
Native DLL copies in the managed output must be refreshed after replacement.
Workstation harness inputs and portability limits are in `tools/README.md`.

The cross-platform workflow now consumes the matching bundled native host
rather than replacing it with the unmodified upstream compiler. It runs six
data-independent existing owners and retains actual Release export/install
native/WMA probes. The full 22-owner suite still includes the licensed RPG
database owner and is the local acceptance entry. Workflow YAML and scripts
are checked locally; remote GitHub execution is not claimed by this submission.
