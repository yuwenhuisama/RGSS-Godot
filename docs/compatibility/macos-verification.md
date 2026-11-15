# macOS verification (2026-11-15)

Final measured acceptance: Mac F10/F11 complete for Apple Silicon local
distribution. The actual original-game Release copy runs from an independent
installation with relative project/RTP, empty working directory, fresh HOME,
system-only PATH and no SDK/native/decoder overrides. Windowed Metal startup
and normal 600-frame exit pass 0 with no runtime ERROR/Exception. Two existing
Tilemap occlusion/scroll pixel owners match their pinned RGSS300 hashes on
Metal, both exit 0; tables are in `macos-release-native-path`. Earlier Release
native/cache/relocation/audio checks and the 36,000-frame renderer resource
profile supply separate evidence; the soak uses the editor-loaded current
assembly, not the Release app. This is clean-directory/runtime isolation,
not a factory-reset macOS machine, Intel validation or notarized download
distribution. Remaining measured limits: dense FPS 55 to 58 with 34/30 low points,
unusable Metal texture memory counter (`INT64_MAX`) and seven existing C# warnings.
Failed earlier owners below remain historical and are not hidden.

Actual SSH host MacMini is macOS 27.0.1 build 26A434, Apple M4 arm64, with
huisama logged into the console. Work is isolated under
`~/RGSS-Godot-Verification`. Official .NET 8.0.428 arm64 SDK and Godot 4.6.1 .NET
universal editor match vendor SHA512 checksums; no system package manager was
installed. Native source is the fixed current mruby archive plus production
four-extension sources. Clang 17 builds all five arm64 libraries. Upstream
tests 1696 OK / 0 KO / 0 Crash / 9 Skip, defined semantics 65 PASS and the existing callback
exception/recovery probe pass. Current C# builds at exit 0 with seven existing
warnings retained.

Actual Godot base coverage is 21 passed owners in the first suite invocation,
plus the one failed RPG database owner passing after the missing authoritative
`RMProject/Data` inputs were supplied. All 15 canonical database hashes match.
The initial full-suite failure remains recorded; this is combined 22-owner
evidence, not a single green suite invocation.

The LGPL WMA decoder is built natively from the same verified FFmpeg source.
All five decoder checks pass. Its 20,558-byte WAV matches independent reference
SHA256 `58799fa81bf05ee654ba7e2d20ca9fc27391cd71cea79a820a24e7c1392fdc55`.
The audio format owner now covers the bundled decoder on Mac without its old
Windows-only skip; MIDI playback/shutdown owners pass.

Actual Release export uses the official universal template and contains two
.NET architecture directories. Native dependencies currently measured are
arm64 only: Intel execution is unverified. First actual package boot failed
because `RubyScriptManager` omitted `AppContext.BaseDirectory/Plugins/macos`.
The production resolver now checks that directory. Re-exported actual app
passes native/WMA at exit 0 with no SDK/native/decoder override, system-only
PATH and empty working directory; cache WAV hash is exact. All ten native/decoder/source/license/notice/build
files match the project payload byte for byte. Relocation to a new app path with relative
configuration passes four original native/GzipIO/integrity/File ledgers, including the 9 File rows.
Evidence: `.omo/evidence/macos-release-native-path` and `macos-decoder-native`.

Actual windowed Metal 4/M4 graphics snapshot and dense-map short owners pass.
An independent visual reader inspects the 544x416 dense-map image and finds
continuous water/ground tiles, intact dense character grid and no corruption
or blank output. That still does not prove motion or audio. The 36,000-frame
resource profile passes at exit 0 in 646,705 ms. All 96 event counters match and
resources restore from dense `(5, 107, 7)` to baseline `(5, 11, 7)`, with 358 nodes at
every sample. Managed memory varies 20.5 to 34.8 MB with GC; native static bytes
remain 134.0 to 134.4 MB. FPS samples are mostly 55 to 58 with 34 and 30 low points;
this is not a stable 60 FPS claim. Metal `texture_bytes` returns `INT64_MAX` in all
samples, so it is unusable as GPU memory evidence. Raw tables and screenshot:
`.omo/evidence/macos-dense-soak/resource-profile`.

## Audio Output Acceptance (Supersedes Prior Open Audio Status)

Actual output acceptance supersedes the earlier open audio status below:
a fixed bundle signing requirement plus normal user authorization restores
CoreAudio callbacks. Complete 40-second recording has 3749 callbacks / 15,355,904 bytes;
WMA 440 Hz and MIDI C4 signals are measured, with exact-zero middle and final
stop intervals. Both capture and normal Godot game exit 0. Source and raw
evidence: `.omo/evidence/macos-audio-signal/complete-measurement.md`.

### Historical Audio Capture Failures (Archived Before Fix)
Prior failed captures and forced-termination errors are preserved for reference:
a process-only CoreAudio tap initially recorded 5,758,976 bytes at 48 kHz stereo float32
while the Release WMA/stop/MIDI/stop sequence completed, but every sample was zero
(`.omo/evidence/macos-audio-signal`). Reading the system privacy database was denied;
no bypass or database write was attempted. A normally launched, signed local
app with fixed bundle identity reached tap-ready but produced no PCM and no
completion until normal authorization restored callbacks. System desktop screencapture
also failed; in-engine Metal pixels remain actual render evidence, with no screen-recording
or microphone permission assumed.
