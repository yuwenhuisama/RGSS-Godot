# Software MIDI verification

Linux uses MeltySynth 2.4.1 through the existing MIDI event parser and scheduler,
with a Godot AudioStreamGenerator output. Windows retains WinMM. The bundled
unmodified TimGM6mb SoundFont supplies 128 melodic programs and eight drum kits.
It does not reproduce the Windows Mapper's exact timbres. SysEx support on the
software backend is limited to universal GM reset; other messages raise an
explicit NotSupportedException. macOS execution remains unverified.

The bank, original archive, full GPL-2 text, copyright provenance and the synth's
MIT notice are in `Plugins/midi/`. `NOTICE.txt` records fixed download URLs and
SHA-256 hashes. No installed system synth or sound bank is required.

Evidence is in `.omo/evidence/f10-linux-midi/`:

- The pre-change Linux Boot owner fails because MIDI Mapper requires Windows.
- Playback covers volume/pitch replay, fade, GM reset and SMPTE timing, with
  original public position zero and ignored seek. Boot shutdown records active
  playback changing from true to false. Both exit zero.
- Actual guest PipeWire recording has a C4 component of 0.01305847 at 261.63 Hz;
  the last 1.9 seconds after stop are exactly zero PCM.
- The shared original ME fixture records explicit-stop recovery RMS 0.008500,
  fade-complete pause zero, later explicit-stop recovery 0.008436, and no revival
  of a stopped BGM (zero). The raw recording and event timeline are archived.
  Capture start is not wall-clock stamped, so this is not subframe latency data.
- Windows guest playback and Boot shutdown regressions both pass, exit zero,
  after introducing the software backend and fixing absolute path forwarding.

The first current-source trimmed Linux Release loads all three MIDI fixtures
offline and verifies the six bank/source/license files byte-for-byte, but its
exit retains a final AudioStreamGeneratorPlayback reference. That run remains
failed in `linux-midi-release-clean` and `linux-midi-release-clean-verbose`.
The output previously restarted a silent generator on every Stop; the final
revision starts output only for Play and retires it on Stop/fade completion.
Its playback regression now passes with no ObjectDB leak. The final-code ME
signal replay also passes: explicit-stop recovery RMS 0.00844643, fade pause
zero, later explicit-stop recovery 0.00843969, stopped BGM zero. These raw files
are preserved separately under `f10-linux-midi/final-stop-stream/`.
The new Release export and offline relocation pass at exit zero, including
byte-exact WMA decode. The same trimmed package passes the offline MIDI owner
at exit zero without ObjectDB leak warnings; all six bank/source/license files
compare byte-for-byte. Evidence: `linux-midi-stop-release` and
`linux-midi-stop-release-clean`. Archive SHA-256:
`70f1cd06613643bf98a6bfd3b31d56e854695725a0da30136e606c9bf16e0858`.
Final-code Boot shutdown also passes. The same Release passes the existing
native extension/Gzip integrity owner offline at exit zero in
`linux-midi-stop-release-native`.

The guest base suite exposed one Gzip integrity failure. All candidate zlib,
mruby host and Marshal libraries match production hashes; the fixture also
matches. A direct guest diagnostic confirms binary File IO returns UTF-8:
37 gzip bytes have String.size 36 and bytesize 37. The current mtime header
contains a valid UTF-8 pair, so the fixture's byte-corruption offset calculated
from String.size targets the wrong byte. This exposes a File binary-encoding
contract gap, not evidence that the CRC/length goldens should change. The shared
IO repair now matches eight actual RGSS300 rows on Windows/Linux, and the Linux
base suite passes all 22 owners. Both verified native libraries are deployed;
see file-binary-encoding-verification.md. A fresh Release including this native
revision now passes export, offline WMA, native/File encoding owners and MIDI
at exit zero. The final package evidence is `linux-file-io-nine-release`,
`linux-file-io-nine-release-native` and `linux-file-io-nine-release-midi`.
Archive SHA-256 is
`f2dd11363bd21b0da087f0a4d08026baa758e2323f18aef07e2f7335167c7e8a`.
Earlier package evidence retains its exact snapshot scope.

The latest Windows combined installation also passes the native/File owner
and three WinMM MIDI fixtures at actual exit zero in the guest with system-only
PATH and no external overrides. See `windows-midi-file-io-release/guest-*`.
This verifies the current runtime package, but its editor export-exit failure
is retained separately in that directory's audit record.
The follow-up `windows-midi-file-io-release-settled` export exits zero with a
120-frame/60 FPS budget. All 217 runtime data files, executable and PCK are
byte-identical to the guest-verified package. Its editor ObjectDB warning remains
recorded; the actual installed runtime is clean. See payload-comparison.json
and file-binary-encoding-verification.md for the exact invocation scope.

Release reproduction uses `tools/run_linux_release_export.ps1` with a fresh
evidence name, then `tools/run_linux_release_midi.ps1 -PackageName <name>` with
another fresh evidence name. The latter runs without network, SDK, compiler or
system decoder in the runtime-only container. Its owner rejects runtime errors
and ObjectDB leak warnings rather than treating a success marker alone as pass.
