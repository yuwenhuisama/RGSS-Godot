# macOS native payload

The five dylibs are arm64 builds of the owned mruby host and its four
extensions. The inherited `_x64` filename is a binding contract; it does not
describe these Mach-O architectures. Rebuild on macOS with
`tools/build_macos_native.sh` and the fixed compiler source archive.

Actual Godot 4.6.1 .NET Release execution on Apple M4 passes original native,
Gzip and File ledgers. The official export template is universal, but these
custom libraries currently support Apple Silicon only; Intel execution has
not been verified. See `docs/compatibility/macos-verification.md` for evidence
and current audio output limitations.

`audio/` includes the minimal LGPL FFmpeg decoder, source archive and its
license, notice and build record. Keep all five files together when packaging.
