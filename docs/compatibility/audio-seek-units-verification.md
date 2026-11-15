# Audio seek and stopped position

E06/E07 remain open on position units and persistence. Earlier OGG rate
controls support decoded 16-bit PCM byte positions, but coarse frame samples
alone do not prove conversion. A new silent original fixture records exact
immediate positions after4096/8192 seek, whether position advances over four
frames, and whether stop retains the last position, separately for OGG/WAV/WMA.
Original execution is active. No audio production conversion has changed.

Original immediate OGG queries return the exact requested4096/8192.
After four frames they report5928/10024; stop reports7250/11346 because
one final mix block elapses between query and stop. The contract therefore
requires retained position >= last query, not equality of two non-atomic
queries. WAV and WMA ignore these seek positions and report0 throughout.
Host same-fixture red comparison is active with these explicit format rules.

Host red completed AUDIO_SEEK_UNITS_FAIL: OGG request4096/8192 was passed
as seconds, returned small positions after wrapping, and stop reset position0.
WAV/WMA exposed fractional seconds despite original's constant0 contract.
Godot's loaded Vorbis packet sequence exposes sample rate and raw packet data;
the first identification packet carries channel count. Metadata read is being
verified before implementing PCM-byte conversion. No speculative constant
sample rate or channel count is added.

Loaded tone Vorbis metadata measured22050Hz and1channel. Audio manager
now derives decoded16-bit PCM bytes/second from packet sample rate and
identification-header channels, converts OGG seek to seconds at the player
boundary, and converts queries back to bytes. Non-OGG streams use the measured
zero position/ignored seek behavior. Explicit stop and fade retain the last
observed position before stopping. C# diagnostics clean; build active.
Exact immediate seek equality and existing replay/ME regression remain pending.

Initial build rejected an unnecessary AsGodotArray conversion because
PacketData already returns typed Array entries. The direct typed access
compiles; dotnet build exited0. Same-fixture windowed replay is active.

Replay now matches WAV/WMA constant0 and stopped position retention.
OGG requested4096 returns4350;8192 returns8446, consistently254 bytes
above the exact original immediate result. A Godot mix block is already
counted by GetPlaybackPosition immediately after Play. The strict immediate
contract remains failing; it is not relaxed. Existing same-file replay
regression is active while this remaining clock-origin discrepancy is traced.

Godot4.6 source identifies the prefill mechanism: Vorbis start calls
begin_resample, which decodes INTERNAL_BUFFER_LEN=128 source frames before
playback. Vorbis get_playback_position reports frames_mixed, including this
prefill. The adapter now measures each actual post-start decoded position
as its origin and reports displacement from it plus the requested RGSS
byte position. No fixed254-byte adjustment is used. Wrapped positions use
the loaded stream length. C# diagnostics clean; build and strict seek replay
are active/pending. Same-file replay previously passed after unit conversion.

Post-origin replay gives exact immediate4096/8192 and correct stopped values,
but the second four-frame interval did not advance. The isolated bridge had
not applied GameManager's Engine.MaxFps60; high-refresh process frames can
finish before another audio mix. The runner now explicitly uses the same60Hz
as original Graphics.frame_rate60. The advancement criterion is unchanged.

Final replay AUDIO_SEEK_UNITS_PASS, exit0: exact OGG4096/8192, advancement
over four60Hz frames, retained stopped positions, and WAV/WMA zero positions
with ignored seek. The owner is registered in events. This closes the measured
seek-unit/stop-position block, not looping metadata or audible/MIDI acceptance.
The full ME owner is active without its earlier --pause-only limitation.

After the final origin change, same-file replay and the full ME owner both
pass at exit0. Actual format loading/extension/RTP/WMA regression also
completed AUDIO_FORMATS_PASS, exit0. No audible signal or cross-platform
release acceptance is inferred from these API checks.

MIDI extension of the same fixture: original4096/8192 seek both return0
immediately and later. Host reproduced4096.001/8192 and fractional elapsed
seconds. Public MIDI BgmPlay now ignores seek and BgmPos returns0 while
MIDI plays, preserving the internal scheduling clock. Existing MIDI test
assertions requiring public positive positions contradict this measured
contract and must be replaced by real playback/signal assertions. Native
schedule success is separate from the public position rule. Build is active.

The first MIDI-inclusive eight-row host replay passed at exit0. The public
query now remembers the last BGM format as well, so a stopped/faded MIDI
does not expose a previously retained OGG position. An OGG->MIDI transition
was added to the same fixture; original completed at exit0, and host replay
is active. Old test_midi_playback positive-position assertions are recorded
as incompatible and remain to be replaced by playback signal evidence.

OGG->MIDI host replay completed AUDIO_SEEK_UNITS_PASS, exit0. All eight
format rows preserve the observed original position rules. The updated
headless suite is active for the public binding change; this does not run
the known-incompatible standalone MIDI-positive-position test.
