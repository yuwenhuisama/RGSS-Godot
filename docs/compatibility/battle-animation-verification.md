# Battle animation and log

E05 is accepted with the executable and independent evidence below. A shared original fixture creates a two-frame RPG animation
and drives Sprite_Base.update, recording active state, remaining duration and
animation sprite count for ten updates. It also uses actual Window_BattleLog
add_text/back_one/clear, recording line stack behavior. Original execution is
active. Numeric frame/log acceptance will not replace independent rendered
inspection of real animation cells and the battle log surface.

Original first run timed out after durations9..1. The probe dereferenced
@ani_sprites after animation disposal, when stock legitimately sets it nil.
The observation now reports0 for the disposed array and the launcher captures
actual exceptions to a file rather than leaving an original error dialog open.
The partial nine rows are preserved; corrected run is active.

Corrected animation completed all ten rows, then failed constructing the
real BattleLog because the isolated fixture lacked Graphics/System/Window.
The RTP Window skin is now copied into the owned original project. Error
records are preserved with unique names; no original game resource changed.

Window construction then required Game_System.window_tone; initializing
the original game objects completed the setup. The original13-row fixture
passed at exit0: animation durations9..1 then disposed0,16 cell sprites
then0, log add2/back1/clear0. Permanent TSV is captured and the windowed
host comparison is active. No animation production defect has been shown
by the earlier setup failures.

Windowed host BATTLE_ANIMATION_PASS completed at exit0 for all13 original
rows. The owner is registered in events. Actual animation-cell pixels,
timings/flash and rendered battle log remain open E05 work.

The same fixture now records one real cell's visible state, mirrored/nonmirrored
position, Z, origin, zoom, angle, mirror flag, opacity and blend type. Its
numeric frame data is independent of an empty animation; original execution
is active before the corresponding golden is extended.

Actual cell rows matched on host: nonmirror(128,128)/angle30 and
mirror(104,128)/angle330, both Z340, origin96, zoom0.75, opacity80 and
additive blend1. BATTLE_ANIMATION_PASS15 rows completed at exit0.
Rendered animation pixels remain separate from these correct cell properties.

Actual pixel fixture now uses two asymmetric synthetic192x192 animation
cells and captures160x160 crops at the first/second frames, normal and
mirrored. Original completed four frames409600 RGBA bytes, exit0, SHA256
af3f6284edd7f05f0cb6d282ca4739ae55a224d63ade4a87c5a018d4c2134f46.
Windowed host exact-byte comparison is active and produces PNGs for independent
visual inspection. The synthetic sheet supplies texture data to the real
Sprite_Base cell pipeline; it does not replace that pipeline's transforms.

First host comparison failed57600 RGB components per frame, all outside
the animated color block: original background24,24,24 versus host title
background164,199,235. The low-Z fixture background was covered by the
Boot title sprites. Runner now enters empty Scene_Base and waits for its
real transition before starting the same pixel fixture. No renderer changed;
the identical four-frame comparison is active again.

Empty-scene replay passed exact409600 RGBA bytes, BATTLE_ANIMATION_PIXELS_PASS,
exit0. Four PNG crops went to independent QA task st_01a1d5af. The runner now
pins the measured original hash permanently and is registered in events;
its permanent-hash replay is active. Full battle log and flash/timing remain
open, and static crops do not establish playback smoothness.

The first permanent-hash runner did not parse because PackedByteArray has
no sha256_text method. It now uses HashingContext over raw bytes and compares
hex output to the same original SHA256. This is a runner API correction;
the exact-byte animation replay was already green. Corrected run is active.

Permanent-hash replay passed exit0. Independent four-image/mirror QA
st_01a1d5af found clear cells, preserved mirrored geometry, clean backgrounds
and no clipping/overlap. This establishes static frame quality only.
The numeric owner now probes animation Timing flash scopes1/2/3 on actual
Sprite/Viewport flash methods, recording target and duration while still
calling the real native flash. Original scope/duration execution is active.

All three timing rows match original (sprite color12, viewport color12,
sprite hide12); host BATTLE_ANIMATION_PASS18 rows completed at exit0.
The remaining E05 surface is actual battle-log rendering and integrated
playback inspection, rather than these now-settled numeric/static contracts.

The pixel owner now adds a real two-line BattleLog capture (544x96).
Original completed208896 bytes at exit0, SHA256
fa9568e62ea6f0cc92442baac1974b60deb776c347beeaff6d211275c20b4488.
Windowed host exact comparison is active, with battle-log.png produced for
independent visual inspection. No log text replacement or renderer patch is
introduced before the comparison result.

Host log capture first failed because mruby rejected a208896-element array.
The exporter now packs/writes one scanline at a time, producing identical
RGBA order with bounded array size. This is an output buffering limit, not a
log-render verdict. Same original byte comparison is running again.

Bounded exporter completed but log exact comparison differed1727 pixels
within text bounds16..302,15..59, with first differences host grayscale+1.
WindowContents shader still used hardware float alpha blend while the already
verified Sprite shader uses RGSS integer-alpha flooring. Contents now samples
the preceding screen using its own BackBufferCopy and applies that same integer
blend formula. C# diagnostics clean; build active, then exact log and window
regressions. Independent log visibility task st_01a1d5b8 is still separate.

Integer contents blending reduces the screen residual from1727 to499 pixels;
window transparency regression passes exit0. Residual includes both+1 and-1,
so the blend change alone is not a complete fix. Source log.contents RGBA is
now exported on both engines to separate font/bitmap construction from final
screen compositing before another production change.

Source contents alpha matches exactly, but449 nontransparent RGB pixels
are brighter on host. BlendTextPixel truncates destination alpha contribution
for the result alpha but used untruncated float weights for RGB, producing
inconsistent premultiplied values. It now uses the same integer retained-alpha
weight for RGB and result alpha with byte-floor division. Diagnostics clean;
build is active. This root correction will be checked against log and prior
font contracts; no pixel-specific adjustment is introduced.

Consistent-weight experiment did not reduce source residual (451 versus449),
so it was withdrawn. Existing Bitmap AlphaOver already implements a measured
RGSS integer normalized-source-weight formula used by blt. Text had a separate
float alpha path. BlendTextPixel now reuses that existing owner; build exited0,
and exact log replay is active before this approach is accepted.

AlphaOver reuse makes every nontransparent source contents pixel match original;
screen residual drops to159. Final short-font layout and C# diagnostics pass.
Byte-domain shader arithmetic did not change those159, so its explanation as
mere floating-point precision was unproven. The fixture now hides contents
temporarily and samples the actual backdrop beneath the residual pixels on
both engines before another blend adjustment.

Actual backdrop samples match17 on both engines. A full alpha ramp probe
was added to normal window contents to measure blending independently of
glyph construction. Bare Window setup crashed original before emitting rows;
it is replaced with standard Window_Base and its valid padded contents,
keeping the same ramp. Original control rerun is active; no new production
formula is accepted from the crash.

The first standard-window ramp was covered by BattleLog's z199 back sprite;
moving only the test window to z300 removed that interference. The1024-value
original ramp then establishes WindowContents RGB formula exactly:
floor((sourceByte*(alphaByte+1)+backgroundByte*(256-alphaByte))/256).
The source and destination integer weights are independently biased, unlike
the Sprite formula. It predicts all5271 nontransparent log pixels with zero
residual, including the prior159. Shader now follows this measured window
rule; exact log replay is active. No empirical per-pixel correction is used.

Final log exact comparison and permanent-hash replay both pass at exit0,
and final window transparency regression passes. BattleLog's208896-byte hash
and the four animation-frame409600-byte hash are now permanent acceptance
values. Independent final log QA st_01a1d5c7 is active. CPU source glyph
composition reuses AlphaOver; short-font layout and diagnostics are clean.

Final independent log QA st_01a1d5c7 passes two readable lines, consistent
placement, no clipping/overlap and clean backdrop. A --record-playback variant
now captures16 successive real rendered animation frames at the normal host
60Hz. This extends evidence from selected static frames to actual frame
cadence; its capture run is active. Existing exact hashes remain unchanged.

Capture run passed at exit0 and all16 frames are now under independent
temporal sequence QA st_01a1d5ca. Final text-composition change also passes
the unified headless suite TEST_SUITE_PASS:18, exit0, including bitmap
compositing, value/resource contracts and Marshal owners. No E05 closure
before the continuous-frame verdict.

Independent temporal QA st_01a1d5ca passes all16 actual rendered frames:
00-03 normal green/red,04-07 normal blue/yellow,08-11 mirrored red/green,
12-15 mirrored yellow/blue. Every group holds exactly four frames; all frames
share80x80 bounds and6400 colored pixels, with no blanks, tearing, displacement
or stray transition frames. This is individually inspected consecutive-frame
evidence, not watched video. Together with18 original numeric rows, exact
four-frame and two-line log hashes, and independent log QA, it closes E05.
