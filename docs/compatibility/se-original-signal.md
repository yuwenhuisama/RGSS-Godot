# Original RGSS300 SE signal probe (E08)

## Valid guest signal (2026-11-14)

The existing double-pitch fixture now runs on the logged-in Windows guest
through the already validated WASAPI endpoint. It exits 0 and captures actual
coexisting 440/660 Hz amplitudes 0.178038/0.145586, RMS 0.167323. After se_stop,
115,200 measured stereo frames have RMS and peak exactly 0. Initial silence
has no callbacks and is not treated as a measured clean-baseline interval.
Evidence: D:/VMs/original-se-capture.wav, its .chunks.tsv and
original-se-se_signal_events.tsv. Earlier failed virtual-bus captures below
are historical; they do not override this valid signal result.

E08 remains open for measured concurrency capacity. The current host uses
eight round-robin players; a separate original fixture measures 8/9/16/17
voices with unique pitches on a four-second repeated source before that
implementation limit is changed or accepted.

## Earlier host-route investigation

## Status

BLOCKED: no measurable original SE signal was captured for the mandated
`tests/fixtures/audio/tone.wav` 440 Hz fixture. The same capture bus and
detector did capture the original OGG BGM and a known WinMM 440 Hz control.
A reversible follow-up with `PlaySound=1` and `PlayMusic=1` also produced no
SE signal, so the F1 playback switches are not the cause. No original SE
coexistence/stop verdict is claimed.

The blocker is specific to the original SE path in the isolated fixture, not
to the capture bus: a 0.5 s known 440 Hz tone is captured at 0.249 amplitude,
and the original RTP `Theme1.ogg` BGM is captured at 0.181 peak / 0.0197 RMS,
while all tested SE forms remain at the noise floor.

## Environment

- Source game: `E:/Projects/RMProject` (read-only; no files written)
- Runtime: `System/RGSS300.dll`, version 3.0.0.1 (ASPack-packed)
- Player: `Game.exe`, version 3.0.0.1
- Tone: `E:/Projects/RGSS-Godot/tests/fixtures/audio/tone.wav`
  - 22050 Hz, mono, 16-bit, 0.5 s, 440 Hz
  - SHA256 `647c645b69d4758a90e6f3fefa0ef1e4ee9adc634c1e07c4c229848bdef6b608`
- Capture: `F:/Softwares/oopz/ffmpeg.exe` 2022-10-30 dshow build
- Device: `Voicemeeter Out B1 (VB-Audio Voicemeeter VAIO)`, stereo 48000 Hz
- Default render endpoint: `Voicemeeter Input`,
  `{0.0.0.00000000}.{726d0821-b2db-4d79-8797-20da2b49f410}`
- Analysis: Python 3.13, NumPy; 0.18 s Hann-window Goertzel scan at 440/660 Hz
- Isolated fixtures: `.omo/compatibility-run-tmp/e08-se-original/`

## Repro commands

Main bounded probe (prepares the fixture with the existing
`tools/prepare_original_fixture.rb`, captures B1, runs the original, analyzes):

```text
python tools/se-original-capture/capture_se_signal.py
```

The script removes only its owned `fixture/` directory before preparing a
fresh one, then writes:

```text
.omo/compatibility-run-tmp/e08-se-original/se_signal_capture.wav
.omo/compatibility-run-tmp/e08-se-original/se_signal_analysis.json
.omo/compatibility-run-tmp/e08-se-original/fixture/se_signal_events.tsv
```

Known-tone capture control:

```text
python .omo/compatibility-run-tmp/e08-se-original/capture_control.py
```

Original BGM capture control:

```text
python .omo/compatibility-run-tmp/e08-se-original/capture_bgm_control.py
```

Format/path diagnostic:

```text
python .omo/compatibility-run-tmp/e08-se-original/probe_se_formats.py
python .omo/compatibility-run-tmp/e08-se-original/probe_paths.py
```

## Main probe result

Fixture: `se_signal_reference.rb` writes wall-clock events, waits 30 frames,
re-triggers `Audio.se_play(tone.wav, 100, 100)` and
`Audio.se_play(tone.wav, 100, 150)` every 12 frames for 120 frames (2 s), then
calls `Audio.se_stop`, then waits 180 frames. Re-triggering keeps the 0.5 s
tone active across the original SE buffer/startup window.

```text
CAPTURE_OFFSETS: BEGIN=0.594, SE_START=1.128, SE_STOP=3.907, EXIT=6.910
ANALYSIS_BASELINE:      440=0.00000166  660=0.00000073  peak=0.000916
ANALYSIS_COEXISTENCE:   440=0.000485    660=0.000202    peak=0.031677
ANALYSIS_SILENCE:       440=0.00000650  660=0.00000114  peak=0.001083
ANALYSIS_LATE_SILENCE:  440=0.00000617  660=0.00000112  peak=0.000824
SE_SIGNAL_VERDICT: coexistence=FAIL 440=0.000485 660=0.000202
                   silence=FAIL post_peak=0.001083 baseline_clean=True
```

The coexistence window contains 127 windows and no 440/660 tone at the
expected level: the best joint values are 0.0027 and 0.0011 of the captured
BGM peak. Its 0.0317 peak is a transient click, not the fixture tone. The
post-stop window has no 440/660 energy; its 0.001083 peak is a transient at
the detector floor, not evidence of SE playback or stopping.

## Positive controls

Known 440 Hz WinMM control, same detector and capture route:

```text
Voicemeeter Out A1: best_440=0.00000020 peak=0.0000458
Voicemeeter Out B1: best_440=0.249316   peak=0.310501
```

Original OGG BGM control, same route and original runtime:

```text
LEDGER ogg: 2272, 5360, 8006 (advancing)
LEDGER ogg-stereo44100: 297684, 463064, 661520 (advancing)
BGM_AUDIO: duration=6.000 peak=0.180939 rms=0.019690
BGM_SEC 2.0: rms=0.048127 peak=0.180939 440=0.000095
```

This proves the B1 bus, ffmpeg capture, event timing, and detector are
functional for original audio. The title-screen control was near-silent
(`peak=0.003204`, `rms=0.000042`), and its RTP BGM resolution is inconclusive;
it is not used as the positive control.

The original `Game.exe` audio session was active on the default endpoint with
volume `1.0` and mute `0` during the title run. The live module list contained
`dsound.dll`, `MMDevApi.dll`, `AUDIOSES.DLL`, `avrt.dll`, `winmm.dll`, and
`ResampleDmo.DLL`; the runtime uses WASAPI-backed DirectSound.

## Format/path diagnostic

All calls used volume 100, pitch 100, a 0.5 s tone, and a 0.5 s analysis
window. `Audio.se_play` returned `nil` for every variant; this return is not
used as signal evidence.

| attempt | path | 440 | 660 | peak |
|---|---|---:|---:|---:|
| SE_OGG_ABS | absolute `tone.ogg` | 0.000004 | 0.000002 | 0.005447 |
| SE_OGG_REL | `Audio/SE/tone` | 0.000009 | 0.000004 | 0.011444 |
| SE_WAV_ABS | absolute `tone.wav` | 0.000000 | 0.000000 | 0.000046 |
| SE_WAV_REL | `Audio/SE/tone.wav` | 0.000004 | 0.000001 | 0.003937 |
| SE_WAV44_ABS | absolute 44.1 kHz stereo WAV | 0.000000 | 0.000000 | 0.000046 |
| SE_WAV44_REL | `Audio/SE/tone44.wav` | 0.000000 | 0.000000 | 0.000061 |
| BGM_OGG_ABS | absolute 0.5 s `tone.ogg` | 0.000000 | 0.000000 | 0.000061 |

The peaks are clicks/transients; none contains the 440 Hz fixture tone. A
long original RTP OGG BGM is captured, so the failure is specific to the SE
path or to short SE buffers, not to the capture chain.

## Reversible F1 settings test (follow-up)

The earlier probe did not vary the RGSS3 F1 switches. The complete
`HKCU\Software\Enterbrain\RGSS3` value set was snapshotted before the test:
`PlayMusic=0` (REG_DWORD), `PlaySound=0` (REG_DWORD),
`LaunchInFullScreen=0` (REG_DWORD), `WaitForVsync=0` (REG_DWORD), and a
29-byte `ButtonAssign` REG_BINARY value.

`run_settings_test.py` created a fresh uniquely named folder, prepared a fresh
fixture by invoking `tools/prepare_original_fixture.rb` directly (it did not
call the old destructive prepare wrapper), set only `PlaySound=1` and
`PlayMusic=1`, verified `LaunchInFullScreen=0` and all other values unchanged,
ran the same sustained 440/660 probe once, and restored the exact original
values and types in `finally`.

During the run:

```text
REGISTRY_DURING: PlayMusic=1 PlaySound=1 LaunchInFullScreen=0
ANALYSIS_BASELINE:      440=0.00000052 660=0.00000045 peak=0.0000458
ANALYSIS_COEXISTENCE:   440=0.00000050 660=0.00000048 peak=0.0000610
ANALYSIS_SILENCE:       440=0.00000043 660=0.00000044 peak=0.0000610
SETTINGS_TEST_VERDICT: coexistence=FAIL 440=0.000000 660=0.000000
                       silence=PASS post_peak=0.000061 baseline_peak=0.000046
```

The F1 switches are not the cause. The bands remain at the detector noise
floor; the silence PASS is trivial because no SE tone was present.

Restoration receipt:

```text
REGISTRY_AFTER: PlayMusic=0 PlaySound=0 LaunchInFullScreen=0
REGISTRY_RESTORED: True
```

`registry_restore_receipt.json` confirms the complete five-value key snapshot
before and after is identical, including `WaitForVsync=0`, the 29-byte
`ButtonAssign` binary, and `LaunchInFullScreen=0`. An independent read-only
probe after the run returned the same values and types.

New artifacts, all under
`.omo/compatibility-run-tmp/e08-se-original/settings-test-20261114-020600-692674df/`:

```text
se_settings_capture.wav      1315210 bytes sha256 ccaa22174a18ebba44e73422378e404f993bcfcf712c3e518e3915fceffc7e25
se_settings_analysis.json       2547 bytes sha256 fbcfbc22420e377f12d52b82530129ca0068079c59b2fea87331064d272f1a93
se_settings_events.tsv           104 bytes sha256 694b24c4fef73323f90a3b6d23a35042ad2a4ab976a01b7fcacc10231d0a6b32
registry_before.json             349 bytes sha256 a404e08bcf8a95d91d18721c71d59d9475887bb1e064a16e515ed2461e525d80
registry_during.json             349 bytes sha256 2d03d1d5d71651ca012f32d3f07565869854ba97d706cf3175df6f876f7fb1a2
registry_after.json              349 bytes sha256 a404e08bcf8a95d91d18721c71d59d9475887bb1e064a16e515ed2461e525d80
registry_restore_receipt.json    969 bytes sha256 831b9648462e7b0750535cdfb30b08242d37065f4bfba1a8a984e53e42d52826
```

No device route, backend, fullscreen switch, or other registry value was
changed. The bounded settings test stops here because the hypothesis failed.

## Interpretation and limitations

- No evidence supports original SE coexistence of pitch100 and pitch150 for
  the mandated 0.5 s WAV. No evidence supports a post-`Audio.se_stop` silence
  verdict because no SE signal was present to stop.
- The exact cause is unresolved. Candidates not separated here: SE pool
  initialization in a custom single-script fixture, SE path/extension
  resolution, or short-buffer behavior in the packed original runtime.
- The F1 `PlaySound` and `PlayMusic` switches were ruled out: both were set to
  1 for one isolated run, the same probe still measured no tone, and the
  complete key snapshot was restored exactly.
- Only the Voicemeeter B1 loopback was used. No in-process DirectSound hook,
  WASAPI loopback of another endpoint, default-device change, or stock-game
  menu SE interaction was attempted; those are outside this bounded probe.
- This is local evidence for the Chinese RGSS300 3.0.0.1 build. It is not
  RGSS301, export, or cross-platform evidence.
- `.omo/compatibility-run-tmp/e08-se-original/` preserves the capture WAVs,
  event ledgers, analysis JSON, logs, and diagnostic scripts.

## Artifacts

```text
se_signal_capture.wav      1363210 bytes  sha256 8f4f4e6038fae1332dc20e0ec64baacdfc6f117999ee351754f7ccaac56eaa7d
se_signal_analysis.json       1827 bytes  sha256 323462f30934f217300e098b14f815231380821798125691fa84df34c7e62a26
fixture/se_signal_events.tsv   104 bytes  sha256 e1a760227ffcbe1be1b1bfe738811983a78e386d583d627ee72e1e00eb2c1c94
control_1.wav               572046 bytes  sha256 c14a48219121d6713540c6ca236ebbae0b929c158c82ba88523d2d125d06cf8e
bgm_capture.wav            1152010 bytes  sha256 4e6ef123cc6262c3db6b7a873ec0b99204b9a83d87522150756c7dba3131cde0
se_format_capture.wav      1632010 bytes  sha256 c9a29a7a9a9b8e1b2ced564529ecaf3486c0ff339067db8728029f19e435cb79
se_path_capture.wav        1324810 bytes  sha256 f05c8aa1bc27f671e2cf17c40ebc0104bdfbeb90e62da0ee0510dbed518c5b9f
title_capture.wav          1420810 bytes  sha256 ebb498ed772a02876c0e6af4170b3bc48a41643b149a6a766d31b582f8e66c14
tone44.wav                   88278 bytes  sha256 b07b103e4b072dde7eccd171a02f1e0821028982564e6d9d52de947d6db134a8
```

## Edit paths

```text
tools/se-original-capture/se_signal_reference.rb
tools/se-original-capture/capture_se_signal.py
tools/se-original-capture/se_path_probe.rb          (diagnostic)
tools/se-original-capture/se_format_probe.rb        (diagnostic)
docs/compatibility/se-original-signal.md
.omo/compatibility-run-tmp/e08-se-original/         (fixtures, captures, analysis, diagnostics)
.omo/compatibility-run-tmp/e08-se-original/run_settings_test.py
.omo/compatibility-run-tmp/e08-se-original/settings-test-20261114-020600-692674df/
```

No shared runtime, test, fixture, or RMProject source file was edited.
