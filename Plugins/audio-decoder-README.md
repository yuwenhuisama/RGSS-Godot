# Audio decoder distribution

WMA decoding uses the platform executable at
`Plugins/<windows|macos|linux>/audio/ffmpeg[.exe]`. An explicit
`RGSS_FFMPEG_PATH` overrides the bundled path.

Build a minimal decoder from the verified source archive:

```sh
bash tools/build_audio_decoder.sh verified-ffmpeg-8.1.3.tar.xz linux output
```

The current Windows and Linux builds report LGPL version 2.1 or later. Ship
ffmpeg, its corresponding source archive, LICENSE.txt, NOTICE.txt and BUILD.txt
together. The old Windows GPL candidate is preserved only as historical evidence.
See docs/compatibility/audio-decoder-distribution.md for source verification,
build flags and measured platform coverage.

Linux package assembly must preserve executable mode 0755 on ffmpeg after
Godot's .NET content export (which produced 0644 in the measured run). Tar
packaging and offline relocated headless execution have passed. Windows local
export loading also passed. Installed Ubuntu guest WMA output has additionally
been captured through a guest-only PipeWire sink; see the distribution report
for that measured scope. Current-source Linux Release passes offline runtime-only
relocation and byte-exact decode. The Windows audio-fix Release additionally
passes clean-guest boot and actual WMA mixer capture; the latest combined
MIDI/File-IO runtime passes its isolated guest contracts. Those snapshots and
the retained editor warning are documented in the compatibility reports.
macOS build/runtime remains unverified. Missing decoder is an explicit unsupported WMA result, never counted
as a successful decode. Cache files are regenerable and are not release assets.
