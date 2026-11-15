# BGM and BGS finite-source loops

## Current fade repair measurement

The original volume50/one-second cross-check gives BGM normalized RMS
0.756/0.406/0.243/0.176 at 0.2/0.5/0.75/0.9 seconds, with BGS
0.742/0.418/0.251/0.184, then zero. Together with volumes20/100 this supports
the original requested-volume mapping -35..0 dB and a linear dB fade towards
-35 dB followed by stop, rather than a fixed -80 dB target.

Current streamed-player mapping implements that measured rule. The same
volume20/two-second host green recording has baseline RMS 0.003517/0.003519
(original 0.003559/0.003559). Normalized BGM values at the five documented
windows are 0.948/0.835/0.683/0.557/0.484; BGS
0.950/0.846/0.692/0.563/0.483, with zero after completion. Callback delivery
times and driver frame scheduling bound timing precision; sample-exact waveform
parity is not asserted. Current Windows/Linux loop/ME/SE regressions are active.
The shared MIDI sequencer volume is not changed by this streamed-player fix.

Final Windows guest and Linux container affected owners all pass at exit 0:
AUDIO_LOOP_PASS, AUDIO_ME_PASS, AUDIO_SE_PASS. Windows fade RMS baseline/
middle/end is BGM 0.003517/0.002375/0 and BGS 0.003521/0.002337/0;
Linux is 0.003522/0.002352/0 and 0.003523/0.002360/0. The enhanced existing
loop owner fails on the retained old assembly for both channels' excessive
fade attenuation (middle 0.000432/0.000464, AUDIO_LOOP_FAIL, exit 1).
A separate volume50/one-second host signal comparison remains active before
closing E06; no acceptance count is incremented from these narrower checks.

Both remaining host signal conditions now complete: volume50/one-second has
baseline 0.011784/0.011786 (original 0.011918/0.011923), midpoint ratios
0.423/0.424 (original 0.406/0.418), and zero after completion. Volume100/
two-second has midpoint ratios 0.154/0.160 (original 0.155/0.161), and zero
after completion. All three original/host conditions are archived under
`.omo/evidence/e06-original-fade-guest` with raw PCM, callback/event clocks,
affected owner logs and SHA256SUMS.txt.

The final replay owner exposed zero-duration fade stopping a playing stream;
the measured original continues, so Fade now leaves zero-duration requests
unchanged. Windows guest replay passes at exit 0. Linux short four-frame
position samples can remain within one mixer block even at 60 process FPS;
the fixture now permits 12 frames while retaining every advancement and
no-rewind assertion. Linux final replay now passes AUDIO_REPLAY_PASS, exit 0,
including both zero-fade advancement rows and replacement-advances=true.
Windows final shared fixture also passes AUDIO_REPLAY_PASS, exit 0. Both final
replay logs are archived with the three-condition signal evidence and refreshed
SHA256SUMS.txt. E06 is accepted for the measured RGSS300 streamed BGM/BGS
loop, replay, seek, fade and replacement contracts. Linux MIDI support and
macOS execution remain platform requirements, outside this acceptance.

## Original fade signal divergence (2026-11-14)

Logged-in Windows guest WASAPI capture of the shared
audio_fade_signal_reference.rb establishes real two-second BGM/BGS fade curves.
At volume20, original normalized RMS near t=0.2/0.5/1/1.5/1.875 seconds is
BGM 0.936/0.823/0.677/0.549/0.473 and BGS
0.937/0.826/0.673/0.550/0.473; both stop to measured zero afterwards.
Current host red is BGM 0.555/0.195/0.0325/0.00413/0.00123 and
BGS 0.610/0.184/0.0271/0.00410/0.00129. Thus the current tween to -80 dB
is demonstrably too steep, beyond callback-timestamp uncertainty. E06 remains
open; an original volume100 probe distinguishes whether the decay depends
on initial volume before selecting a replacement algorithm.
Raw evidence prefixes: D:/VMs/original-audio-fade- and host-fade-red-.

Original volume100/two-second follow-up gives normalized BGM RMS
0.752/0.434/0.155/0.0567/0.0259 and BGS
0.782/0.440/0.161/0.0585/0.0255 at the same windows, then zero.
Thus the slope depends on initial requested volume; a fixed final -80 dB
tween cannot represent both. Baseline RMS volume20/100 is 0.003559/0.088334,
also exposing a separate initial amplitude mapping discrepancy (current host
volume20 baseline 0.017671). No initial-volume fix is claimed. A third
volume50/one-second original probe tests the inferred slope before coding.

Linux actual Godot4.6.1 .NET mixer verification passes at exit 0 on
2026-11-14. WAV/OGG/MP3/WMA all remain active in both BGM and BGS beyond
the finite source end, with measured RMS respectively 0.035382, 0.035355,
0.033556 and 0.035184. BGM fade RMS is 0.017700/0.000409/0 and BGS is
0.017693/0.000661/0; the obsolete-fade replacement assertion also passes.
Markers AUDIO_LOOP_PASS / LINUX_AUDIO_LOOP_PASS. Evidence:
`.omo/evidence/f10-linux-godot-base-suite/linux-audio-loop.log`.
The Linux SE mixer owner separately passes simultaneous440/660Hz,
RTP-only effect PCM, explicit stop, finite ending and manager reinitialization:
`linux-audio-se.log`, AUDIO_SE_PASS, exit 0. These add Linux mixer coverage;
original MIDI/audio oracle and actual device output remain separate gaps.

E06 remains open. The public Ruby BGM/BGS owner now plays each0.5-second
WAV/OGG/MP3/WMA fixture for54 real60Hz frames and checks whether it remains
playing beyond its source end. Baseline: OGG loops, but both channels end for
WAV/MP3/WMA. SetLoop omits MP3 and enables WAV Forward without a valid loop
end; WMA decodes into the same WAV path.

SetLoop now sets MP3.Loop and initializes an absent WAV loop interval to the
full decoded sample length, preserving valid loaded loop points. Diagnostics
clean; build active before the real owner replay. Signal continuity and original
loop metadata remain separate evidence, so playing state alone is not full E06.

Build and four-format/two-channel replay pass at exit0; all eight BGM/BGS
streams remain playing beyond the finite source end. Owner is registered in
events. SE finite-end regression is active because the same SetLoop owns
nonlooping effects. Original metadata and actual continuous-loop PCM remain
unverified rather than inferred from Playing.

SE real-mixer regression passes at exit0 after loop changes, retaining both
tone frequencies, RTP fallback, explicit stop, finite natural ending and
audio manager disposal/reinitialization. Format seek-units regression is active.

Seek-units regression passes at exit0. Expanded post-source-end real mixer
owner also passes: RMS WAV0.035367, OGG0.035299, MP30.033585, WMA0.032464,
with both BGM/BGS remaining active. This proves actual loop playback beyond
the original finite source, not just stream assignment. Loop metadata and
cross-engine signal shape still remain open. Full ME owner replay is active.

Full ME original-position owner passes AUDIO_ME_PASS at exit0 after loop
changes, including natural finish, explicit stop/fade and no restart of an
explicitly stopped BGM. MIDI handoff and actual ME audio signal are still
separate unverified E07 requirements.

New replay boundary fails: start fade500ms, stop after six frames, replay BGM,
then the old tween callback stops the replacement player. The tween outlives
its playback owner and no cancellation exists at Play/Stop. A shared original
replay extension is active before accepting cancellation as the parity fix.

Original replacement-advances=true is captured. Audio manager now owns active
fade tweens by channel and kills/removes them when successful Play, Stop,
another Fade or Dispose transfers that playback ownership. Build/diagnostics
clean; actual loop replacement and shared original replay both pass exit0.
No callback epoch guard hides the old operation. Full ME regression is active
because ME also uses the same fade owner.

Full ME position regression passes at exit0 after fade cancellation. Its
existing owner now captures actual440Hz BGM and pitch150660Hz finite ME:
while ME plays440 must be suppressed, after natural ME finish440 must return
and660 disappear. This mixer proof is active; MIDI remains outside that signal.

ME real mixer proof passes exit0: during ME440=0.000141/660=0.024982;
after ME440=0.025033/660=0.000179. Actual BGM silence/resumption is established
for streamed audio. E06 next probes a2-second22050Hz OGG with LOOPSTART22050
and LOOPLENGTH22050 on original before implementing loop-tag interpretation.
Current loader has no RGSS loop-tag processing.

The first180-frame original sample lands near the loop boundary (BGM43286,
BGS42844 bytes), so it cannot establish the assumed44100..88200 region.
Host180-frame values are42360/44408. Probe now samples150 frames, away from
the boundary, to distinguish full-source0.5s position from tagged1.5s position.
No loop-tag production change is justified until original interpretation is
established; the first runner expectation is an unproven hypothesis.

At150 frames original returns21236 bytes on both channels, near0.5 seconds,
not1.5 seconds. This local RGSS300 ignores the supplied LOOPSTART/LOOPLENGTH
comments and loops the full source. The speculative tagged-region expectation
is withdrawn; runner now checks the measured full-source position band away
from the boundary. No RGSS tag-processing code is added contrary to evidence.

Host150-frame full-source loop contract passes AUDIO_LOOP_TAGS_PASS, exit0,
and joins events. Encoded bytes contain LOOPSTART=22050 and LOOPLENGTH=22050;
SHA256 bdca56b1786b5e81555026995def3088a88209b5117d4dc46c8ca4189a9c9fdf.
Optional ffprobe was absent; direct comment bytes provide tag-presence evidence.
This verdict covers only the local measured RGSS300 build.

Actual BGM/BGS fade PCM owner passes: full/mid/end RMS BGM0.017691/
0.000387/0, BGS0.017709/0.000385/0. Both players stop at completion.
This establishes audible amplitude reduction and silence, while original fade
curve shape is still unmeasured.

Original zero-millisecond fade probe reports advancing playback on both
BGM/BGS four frames later. Zero fade is therefore not an immediate stop on
this measured RGSS300 runtime. Shared replay owner now compares those two
values; host reproduction is active before any production change.

Zero-fade original shared replay passes on host at exit0. No immediate-stop
special case is added; the measured zero-duration behavior is preserved.
