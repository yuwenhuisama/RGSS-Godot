# ME and BGM handoff

## Latest verified MIDI lifecycle result

Final Windows shared-fixture signal agrees with the measured original:
explicit ME stop restores MIDI (RMS 0.006320), completed fade keeps it paused
(RMS 0), subsequent me_stop restores it (RMS 0.008640), and a BGM explicitly
stopped during ME does not return (RMS 0). Natural-end suppression/recovery
was separately measured with the original and red/green host recordings below.
Final streamed ME position/mixer regression also passes AUDIO_ME_PASS, exit 0,
after the fade-path correction. Earlier loop/SE owners passed before that
ME-only correction and are not redundantly rerun.

Reusable signal checker: `tools/audio-loopback/check_midi_lifecycle.ps1
-Prefix <recording-prefix>`. It requires measured callback clocks and valid
baseline/ME samples, then checks the stop/fade/no-resurrection windows. Actual
original-fade-stop and host-fade-stop recordings pass at exit 0; the retained
incorrect host-lifecycle recording fails specifically fade/released at
RMS 0.010692, exit 1. No inference from public MIDI bgm_pos (always 0) is used.
Linux current-source build and complete streamed-ME owner also pass at exit 0:
during 440/660 Hz amplitudes 0.000074/0.025002, after 0.024994/0.000162,
LINUX_CURRENT_MIDI_MANAGER_ME_PASS. The Ubuntu guest was stopped, so this
nonvisual mixer/position check used the retained actual Godot Linux container;
it is not desktop, graphics or performance evidence. Windows MIDI execution
remains the measured platform scope; Linux MIDI support is still a separate
platform gap. Raw original/red/green/lifecycle recordings, clocks, event ledgers
and Windows/Linux streamed-ME logs are archived under
`.omo/evidence/e07-midi-me-guest` with SHA256SUMS.txt.

The following paragraphs retain chronological red/green measurements; their
earlier active/pending wording is superseded by this latest result where scoped.

## VMware original MIDI signal measurement (2026-11-14)

After the user logs into the Windows desktop, the five-second known-tone
control captures 4.97 seconds of real PCM, RMS 0.082944 and peak 0.124985.
A fresh original MIDI/ME run then exits 0 with valid signal throughout its
event timeline. Callback-window C4 amplitudes are 0.008458 before ME,
0.001101 during the 110 Hz ME and 0.011200 after ME; ME-band amplitude is
0.000249 / 0.056474 / 0.000275 respectively. After explicit BGM stop,
RMS is 0.0000363. Evidence: D:/VMs/windows-unlocked-capture.wav,
its .chunks.tsv and windows-unlocked-midi_me_signal_events.tsv. This is the
first valid original MIDI suppression/recovery signal evidence; previous
partial/locked recordings remain invalid for that verdict. Finite callback
windows include spectral leakage, so no sample-exact silence is asserted.

Current source ME handoff pauses/resumes only bgmPlayer.StreamPaused;
GameMidiPlayer is independent. A matching host guest-signal reproduction is
required before adding the missing MIDI handoff wiring.

That host red signal now reproduces the gap in the same Windows guest:
C4 before/during/after ME is 0.012215 / 0.013271 / 0.007943, so MIDI continues
through ME. GameMidiPlayer now freezes its sequence clock and sends zero
channel volume while paused; ME completion/stop/fade restores the same
playback and volume. Starting a MIDI BGM while an ME is active also applies
that pause. Playback event/volume updates share a lock. Public MIDI bgm_pos
remains the independently measured constant 0.

The same green recording yields C4 0.012586 / 0.001996 / 0.008987 and 110 Hz
ME 0.000306 / 0.100043 / 0.000199. Red and green captures are preserved in
D:/VMs/host-midi-{red,green}-capture.wav with chunk clocks and event ledgers.
Thus suppression/recovery is observed, not inferred from private state;
finite-window ME leakage prevents interpreting C4 as exact silence. Current
Windows build exits 0 with seven existing warnings, and all three touched
C# files have no diagnostics. Streamed ME/loop/SE regression is running;
broader MIDI end/stop/fade lifecycle coverage remains pending.

Existing Windows streamed ME, four-format loop/fade and SE mixer owners all
pass after the MIDI change, each exit 0. The shared
`midi_me_lifecycle_reference.rb` now measures original MIDI lifecycle signal:
explicit ME stop restores MIDI (after RMS 0.008672); ME fade(300) instead
leaves the MIDI silent in the sampled post-release interval (RMS 0.0000152),
as does explicitly stopping BGM during ME (RMS 0.0000149). Baselines are
0.0072..0.0076 and all ME intervals have valid RMS around 0.040. Do not assume
streamed-BGM fade recovery semantics apply to MIDI. Host comparison is active.
Evidence: D:/VMs/original-lifecycle-{capture.wav,capture.wav.chunks.tsv,
midi_me_signal_events.tsv}; source game remains untouched.

A discriminating original follow-up calls me_stop after the completed fade.
MIDI then returns (RMS 0.009292 versus 0.0000153 before that call), proving the
fade leaves MIDI paused rather than stopped. The first host lifecycle capture
incorrectly resumes after fade (RMS 0.010692); it correctly avoids resurrecting
an explicitly stopped BGM. The corrected ME fade completion now resumes only
streamed BGM, leaving MIDI paused until explicit me_stop or a later natural
ME end. No MIDI Stop shortcut implements the fade case. Current build exits 0
with the same seven warnings and clean changed-file diagnostics. Full shared
lifecycle replay, including fade-followed-by-stop, is active.

Fresh Windows guest defaults have no RGSS3 audio-disable registry entry.
WASAPI finds an active, unmuted High Definition Audio output. The original
MIDI/ME fixture exits 0 and produces its complete event ledger, but its first
120 Graphics.update calls take about 13 seconds. The initial fixed 16-second
recording therefore ends around ME start and cannot establish recovery.
Its 810,240 PCM bytes also represent only 2.11 seconds of float32 stereo
48 kHz audio: WASAPI omits callbacks when the endpoint is silent, so WAV
offsets cannot be treated as elapsed wall time. This is incomplete timing
evidence, not a silence or pause verdict.

The existing recorder now writes a sidecar .chunks.tsv containing each actual
callback's UTC timestamp, PCM byte offset and byte count. The self-contained
Windows tool publishes successfully at exit 0; no .txt language server is
configured. A separate 40-second recording uses the same original fixture in
a new guest directory, preserving the first recording and its ledger.
Timestamp rows describe callback delivery times, not sample-accurate device
timestamps; analysis must keep that buffer-duration uncertainty explicit.

The 40-second run exits 0 and covers the complete event timeline, but every
PCM sample is zero (3,348,480 data bytes, 48 kHz float32 stereo). Read-only
session inspection finds LogonUI in the same console session after the guest
was restarted; audio services run and the endpoint remains unmuted. This run
cannot support a MIDI suppression/recovery verdict. The earlier partial
recording has RMS 0.007854 and peak 0.053632, confirming it did contain signal.
Guest unlock and a valid control signal are required before another original
comparison. No runtime audio fix follows from the silent locked-session run.

Linux actual Godot4.6.1 .NET full ME owner now passes AUDIO_ME_PASS and
LINUX_AUDIO_ME_PASS, exit 0. Evidence:
`.omo/evidence/f10-linux-godot-base-suite/linux-audio-me-native-paths.log`.
It covers preserved BGM position while ME plays, natural/stop/fade endings,
no resurrection of explicitly stopped BGM and real mixer suppression/recovery.
During ME the440/660Hz amplitudes are0.000074/0.025002; after ME they are
0.025009/0.000121. Original MIDI handoff remains outside this result.

The first headless replay after fixing the draw wait reported zero positions:
Windows paths in the shared fixture were relative inputs to Linux's audio
resolver. Container cwd symlinks did not change that project-relative contract.
The Godot owner now passes native absolute paths from configuration and
ProjectSettings; the shared fixture keeps its original defaults. All audio
assertions remain. Windows headless regression for these test-input changes
also passes AUDIO_ME_PASS, exit 0, with during440/660Hz0.000074/0.025002
and after0.024994/0.000087. Neither run changes the original MIDI gap.

Linux actual-host replay initially hangs before the first ledger row under
headless: the owner awaits frame_post_draw after its first process frame, but
the dummy renderer produces no draw completion. At timeout the process is
alive and its ledger contains zero lines. The owned container was stopped.
The owner now waits for draw completion only on a real display; process-frame
waits, position checks and mixer assertions remain. The corrected replay passes
as recorded above. GDScript LSP is unavailable; actual Godot parsing and
execution provide diagnostics.

MIDI signal owner now runs the original windowed engine with the existing
MIDI C4 fixture and a pitch25 OGG ME, recording the configured loopback device.
Timestamped start/ME/end markers accompany raw stereo48000Hz PCM; analysis
must distinguish C4 MIDI energy from110Hz ME and require a valid audible
baseline before judging suppression/recovery. Original capture is active;
no MIDI pause implementation has been added from the always-zero public pos.

First capture contains15.989s valid PCM but every second is only RMS0.0000127
noise, with neither MIDI nor ME band present; it cannot establish suppression.
The command's false failure also came from stale Process ExitCode state after
WaitForExit. Harness now refreshes process state and tries the existing A1
loopback route in a separate owned fixture, preserving B1 recording evidence.

A1 also records only RMS0.0000109/peak0.0000458. Neither route has a valid
audible control. Process ExitCode needs the process handle retained before
exit; harness now does so. Instead of another blind original run, a B2
known-tone system-playback control is active to validate the capture chain.

B2 known-tone capture exits0 but has the same noise-only signal, RMS0.0000109.
Thus virtual-input routing is not a valid observation of current system output.
Existing Python soundcard/sounddevice/pyaudiowpatch/pyaudio modules and local
NAudio package are absent. Next capture must use the actual default WASAPI
render endpoint rather than infer silence from these disconnected routes.
Raw recordings and original event ledgers are preserved; E07 remains open.

Independent NAudio2.2.1 WASAPI tool builds exit0 and captures the default
render endpoint. Known-tone control is valid: float32 stereo48000Hz,4.98s,
RMS0.078508/peak0.124989, unlike disconnected virtual inputs. Original same
MIDI/ME fixture is now recording through this validated endpoint. Tool project
is separate from the RGSS runtime; no game dependency was added.

Validated-endpoint original run exits0 and captures15.97s, but actual samples
are all0, including MIDI and ME intervals. Known system-tone control remains
valid, so the question is original process routing/session mute or focus, not
MIDI pause semantics. The isolated tool now enumerates output devices and app
session mute/volume read-only; build active before a live original inspection.

Static output enumeration succeeds with unmuted sessions, but the original
had already exited, so it cannot establish that process's routing. The capture
harness now uses the MIDI-start file event to enumerate device/session state
while the exact owned original PID is playing. Live inspection is active.

Live original PID463364 is active/unmuted/volume1 on Voicemeeter Input
endpoint726d0821-b2db-4d79-8797-20da2b49f410. The default capture endpoint
therefore did not observe this application's output. Tool now accepts exact
render-device ID for direct WASAPI capture without changing user routing.
Build active; previous recordings retained as invalid-route controls.

Directed actual-endpoint capture completes exit0 but PCM remains all0. An
active unmuted session does not prove sound delivery. Next original control
waits for its native window input-idle event then explicitly activates that
window, testing focus as a cause while preserving routing/settings. No MIDI
pause conclusion is drawn from the zero signal.

Explicit activation succeeds but16.02s PCM remains entirely0; focus hypothesis
does not explain this recording. A known system-tone control is now run through
the same explicitly selected endpoint to validate that device-ID capture
configuration before attributing zero output to the original runtime.

Same explicit endpoint control passes with5.05s RMS0.078648/peak0.124989;
device-ID capture is valid. Next original control uses known RTP Theme1 and
Absorb1 plus ordinary pitch100 ME, separating MIDI fixture behavior from
general original-runtime audio delivery. No host MIDI implementation changed.

Original RTP BGM/SE and ordinary ME control also captures only zero samples.
The issue therefore affects all observed original audio, not specifically MIDI
handoff. Read-only original registry/F1 persistent audio-option inspection is
the next distinguishing probe; capture route already has a valid control.

Read-only registry identifies the external cause: HKCU/Software/Enterbrain/
RGSS3 has PlayMusic=0 and PlaySound=0. All original zero-audio runs used those
disabled options; they are not MIDI/ME behavior evidence. Windows/virtual
routing was separately validated. Restoring original audio requires changing
the user's original-runtime persistent settings, so no registry write was
performed. User decision is required for temporarily enabling/restoring them.

E07 is open. `tests/fixtures/audio_me_reference.rb` runs on the original
RGSS300 player and the embedded host. It plays RTP Theme1, measures position
after 60 frames, starts a 0.5-second OGG as ME, then records position through
completion. A second ME follows an explicit BGM stop to detect unintended
restart. Original execution is active; no timing or position-unit contract is
assumed before the original output is read.

Reading the current host shows that ME play does not pause the BGM player,
and its Finished handler starts the remembered BGM from position zero. This
is a candidate E07 implementation gap, still requiring executable comparison.

The expanded `--events` suite stopped with exit 127 after its 11 headless
entries passed; no event entry or final suite marker was produced. It is
incomplete evidence. The concurrent fullscreen worker was asked whether
display-mode/process changes interfered; no cause is assigned yet.

Original RGSS300 run exited0: before-ME position132304, unchanged through
the first1+10+20 frames, then231532 and396912 after recovery. After explicit
BGM stop followed by another ME, position remains396912. Position persistence
alone does not prove audible silence; a signal capture is still needed for
that assertion. These values are not seconds or milliseconds; the exact unit
must be characterized before changing the position conversion.

`tests/test_audio_me.gd` now runs the same fiber to completion and fails on
advancing BGM position during ME or second-sized positions. Host red-baseline
run is active. Production audio has not been changed.

Host red run exited1: position5.78177->5.80499->5.97333->6.30422 during ME,
then6.80635/7.81932, violating original frozen position. The fixture owner is
now isolated from Boot's gameplay fiber so Graphics.update has one caller.

The original position probe (`audio_position_reference.rb`) also exited0.
For known mono22050Hz OGG: positions1832/4918/8006, stopped11092,
seek4096 returns4096. Successive four-frame increments3086/3088 are consistent
with decoded PCM bytes (22050*2/60*4≈2940, scheduling variation applies).
WAV and WMA returned0 for every position query and ignored seek4096. Thus a
single seconds/milliseconds conversion across formats would be incorrect.
OGG PCM-byte interpretation remains a hypothesis until the stereo/rate control;
ME pause/recovery defect itself is already executable red evidence.

The long stereo44100 control after60 load frames produced132304/132304/165380.
Its coarse increments prevent a precise byte-rate verdict from this short
control, so position conversion remains unchanged and unverified.

ME fix now pauses the existing BGM player and resumes that same playback on
ME completion or explicit ME stop. It removes remembered-file restart at zero;
a BGM started while ME is active is paused until ME finishes. C# diagnostics
reported none; build is active. `--pause-only` isolates the confirmed pause
regression while the default test continues to fail the open position contract.
ME fade, MIDI handoff and audible signal capture remain open E07 scope.

Shared build was unblocked by the C12 worker (safe byte[] marshaling), build
exit0 with seven existing warnings. It confirmed its broad Godot process-name
cleanup caused the interrupted suite exit127; all C12 jobs are now quiescent.

First isolated pause run showed1.004263 frozen for10 frames, then1.02458 at
the short ME's completion edge. Initial pre-ME position0.992653 differs from
the paused position by one audio mix. The probe now uses pitch50 to keep ME
active throughout31 frames and compares against the first paused sample;
then waits60 frames for recovery. Both revised original and host runs are active.
The regression also checks increasing position after ME and no active BGM
after an explicit BGM stop followed by another ME.

Revised original exited0:132304 remains frozen for31 ME frames, then198456
and363836 after recovery. Host --pause-only passed exit0:0.9839455485 frozen
for the same interval, then1.49478459 and2.50775504; explicitly stopped BGM
was not restarted. This closes the specific streamed-BGM pause/recovery defect,
not E07 as a whole. Original stopped position retains396912; host returns0,
so position persistence remains open alongside units, fade, MIDI and signal QA.
Full --events suite restarted after C12 worker stopped all owned processes.

The same fixture now covers explicit ME stop and ME fade100ms during a
pitch25 ME (long enough to remain active through each intervention). It records
paused BGM position and the position30 frames after the intervention. Both
original and host runs are active; the fade case specifically exercises the
Godot Stop path, which does not emit Finished.

Original stop resumes132304->198456 at30 frames; original fade remains132304.
Host likewise resumes after stop and remains frozen after fade. The initial
fade assertion expected resume prematurely; extended original observation is
active to establish whether this remains true after natural ME duration.
The host's frozen fade is not yet labelled a defect. MIDI currently has no
pause/resume entry point; its ME integration still requires its own original
measurement and executable reproduction before a change.

Extended original exited0: stop198456->363836->826900;
fade132304->231532->694596. Thus fade eventually resumes BGM. Earlier short
window stayed frozen, so the permanent contract uses the late sample rather
than requiring a specific30-frame response. Host extended run is active and
the owner assertion now requires fade-late position advancement.

Host extended run exited1: stop1.291610->1.805351->4.577234,
fade1.015873 remains frozen through the late sample. The confirmed mechanism
is Fade calling AudioStreamPlayer.Stop without the ME completion path;
Stop does not emit Finished. Fade's callback now invokes OnMeFinished for ME
after stopping the exact player captured by that fade. C# diagnostics are clean.
Build and green replay are pending the current unified suite, to avoid changing
the shared assembly between that suite's child processes.

The same original fixture now accepts a MIDI BGM override. Its -Midi run
writes into an isolated midi subdirectory, preserving the OGG measurements.
This measures actual original MIDI/ME behavior before changing the MIDI clock
or note scheduler. The unified suite continues with existing assembly bytes;
no mid-suite rebuild is running.

Original MIDI override exited0 and returned0 for every position, including
ME stop/fade and late samples. Public MIDI position is not an observation of
MIDI playback advancement on this original, so this numeric probe cannot prove
MIDI pause/recovery; signal recording remains required.

ME fade recovery green replay completed AUDIO_ME_PASS exit0: stop-late
1.004263->4.034467 and fade-late1.004263->4.054785. Natural completion,
active-window freeze, explicit stop, fade-late recovery and no stopped-BGM
resurrection all passed. E07 remains open for MIDI/signal and position contracts.

Existing audio-format loader/play/start/stop regression completed
AUDIO_FORMATS_PASS exit0 after the audio changes. The unified --events owner
now registers replay and the explicitly scoped ME --pause-only contract.
The default ME position-unit check remains failing/open and is not advertised
as covered by that suite variant. Expanded suite membership has not been run.

Long stereo44100 OGG position control exited0:297684,463064,661520 across
three60-frame intervals after initial load. Increments165380 and198456 bracket
the decoded16-bit stereo byte rate176400/s, with coarse original update chunks.
This supports PCM-byte units but does not yet establish exact seek conversion.
No position conversion was changed on this evidence alone.

The separate exact seek-unit contract now passes with PCM-byte conversion
derived from loaded Vorbis sample rate/channels and startup origin. Full
test_audio_me.gd completed AUDIO_ME_PASS at exit0 without --pause-only,
including its original-scale position check and both ME endings. The event
suite now registers the full owner. MIDI and audible signal evidence remain
unverified; E07 is not closed from public position observations alone.
