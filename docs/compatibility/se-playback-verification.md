# SE playback and paths

## Accepted measured contract (2026-11-14)

The fixed pool now reuses idle players and adds a player when all are busy;
se_stop stops every owned voice and Dispose releases the complete pool.
It no longer replaces an active voice merely because eight are busy.
Original 8/9/16/17-voice recordings retain every requested frequency. Host red
loses the first voice at 9 and retains only the last eight at 16/17. Host green
retains exactly 8/9/16/17 requested bands, minimum amplitudes respectively
0.012100/0.012490/0.012246/0.012488 in the measured windows.

The existing test_audio_se.gd now asserts each of the 17 frequencies through
the public Ruby API at the mixer. It fails on the retained original Linux
eight-player assembly (missing early bands, AUDIO_SE_FAIL, exit 1), then passes
with the current Windows guest and Linux container assemblies (AUDIO_SE_PASS,
exit 0). Both retain the previous stop, RTP, finite end and reinitialization
checks. C# diagnostics are clean and both builds exit 0 with seven existing
warnings. Evidence is archived in `.omo/evidence/e08-se-capacity-guest` with
raw recordings, callback/event clocks, owner logs and SHA256SUMS.txt.

E08 is accepted for these measured concurrency/path/stop contracts. The probe
does not establish an unlimited original voice count or sample-identical
amplitude between the original Windows mixer and Godot. Earlier pending
statements below are chronological and superseded within this scope.

## Original guest signal and capacity (2026-11-14)

Original double-pitch SE signal is now valid: simultaneous 440/660 Hz
amplitudes 0.178038/0.145586, then exact zero samples after se_stop. The
separate original capacity fixture plays unique pitches at counts 8/9/16/17;
all requested frequencies remain present in every case, including all 17
at amplitudes 0.00331..0.00345. The current eight-player round-robin host pool
therefore has an incompatible capacity policy, not an accepted original limit.
Shared source: tests/fixtures/se_capacity_reference.rb; original recordings
and timestamp ledger: D:/VMs/original-se-capacity-*. Host signal red comparison
is active before changing allocation. No unlimited original capacity is
inferred from the measured 17-voice upper case.

E08 remains open for independent original signal comparison and concurrency
capacity characterization. The public Ruby Audio.se_play owner is now tested
at the real Godot mixer through AudioEffectCapture, without private pool
counts. Two simultaneous WAV voices at pitch100 and150 produce distinct
440Hz and660Hz components (0.021788 and0.021774 over8704 stereo frames).
Audio.se_stop makes the subsequent mixer signal silent. Initial owner run
passes AUDIO_SE_PASS, exit0.

The owner is extended with real RTP-only Absorb1 playback requested through
an absolute missing project path, and finite WAV natural-end silence. It joins
the events suite. Its expanded run is active. Existing audio-formats owner
already checks exact-extension precedence, sibling extensions and RTP loader
resolution, rather than relying solely on the new signal test.

The production SE pool is eight round-robin AudioStreamPlayers. This limit
has not been characterized against original and must not be called parity.

Expanded owner passes at exit0: simultaneous440/660 amplitudes0.023150/
0.023135, RTP-only Absorb1 mixer peak0.222778, and both explicit stop and
finite WAV ending yield silence. Original signal track st_01a1d5cf is active
in separately owned paths; E08 remains open pending its evidence.

GDScript LSP is not configured locally. Both actual Godot parsing and expanded
runtime execution pass; no static GDScript diagnostics are claimed.

The owner also catches F06 audio reuse: Dispose/reinitialize then SE playback
and stop originally raised ObjectDisposedException from retained old pool
nodes. GameAudioManager.Dispose now releases its owning list/references;
full mixer replay passes exit0, including the fresh post-initialize voice.

Original capture track returned no valid SE signal despite positive BGM and
WinMM capture controls. Lead then found HKCU/Software/Enterbrain/RGSS3
PlayMusic=0, PlaySound=0, fullscreen0. Independent music/sound switches were
not separated by that capture investigation. A fresh bounded settings-controlled
capture is now active, preserving/restoring exact registry values and old
evidence; no audio-device/backend change is taken. Zero values alone do not
prove the missing SE cause before that experiment.

Settings experiment failed the hypothesis: with PlaySound/Music1/1,440/660
remain at noise floor. Exact before/after registry snapshots match and values
are restored0/0 with fullscreen0. No SE coexistence or stop verdict follows
from that silent capture. Original signal cause remains unresolved.
