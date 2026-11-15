# D05 stock message window verification

D05 accepted for the versioned stock message/input fixture set on2026-11-14.
Final C# build exits0 (7existing warnings), Windows/Linux five window owners
exit0, Windows four original full-frame hashes are exact, independent visual
review is4/4PASS, and the final headless suite reports TEST_SUITE_PASS:22,exit0.
The shader-only and later contents-opacity checks are recorded separately
below; custom-skin precision and non-Windows font limits are not erased by
this bounded stock-flow acceptance.

## Current production result (2026-11-14)

Windows production source now matches all four original544x416 surfaces
byte-for-byte: text,choice,number,item each0different pixels,max channel delta0.
The existing message owner asserts the original RGBA SHA256 for these Windows
Arial/GDI frames, retains its360-row state hash and exercises real key input.
All complete at exit0. Window cursor shape, odd-width cursor tail, window
transparency/hidden arrows and activation owners also pass at exit0 in the
Windows guest. Logs: `.omo/evidence/d05-production-regression`.

The fixes address measured causes: stretched background interior coordinates
and8-bit interpolation, integer256-weight skin-layer composition, rounded
cursor alpha,32-pixel repeating frame edges instead of NinePatch stretching,
and Sprite-style integer pause-sign blending. The incremental raw probes and
rejected alternatives remain in `.omo/evidence/d05-window-background-layers`;
the exact four-frame candidate is in d05-pause-integer-experiment. Independent
image inspection st_01a1dab9 accepts all four original/current pairs, with
legible text and correct frame/cursor/pause geometry, no clipping or artifacts.

Linux first full-frame comparison isolates1156differences entirely to Arial
text x13..101/y311..331, with the remaining frame byte-exact. Existing non-Windows
Bitmap text drawing uses a different raster path; therefore Windows whole-frame
Arial hashes are explicitly platform-scoped. Linux same-owner functional and
window-contract replay now passes all five owners at exit0 (message, cursor
shape, cursor tail, transparency, activation); Windows-font equivalence on Linux is
not claimed. Custom high-frequency windowskin tie behavior also remains an
explicit precision limitation: new heights refute the proposed universal
strict-below rule, so no fitted precision constant is deployed. The contents
opacity mismatch is now fixed by the measured subtractive rule:
max(0,blink_brightness-(255-contents_opacity)), with a zero-result cursor hidden.
Original8-row inactive and30-row active sweeps prove this independently.
Existing activation owner now pins the8inactive values; Windows and Linux
pass at exit0 with the final managed assembly. Its initial test extension
omitted a black backdrop after the earlier fixture disposed its own; the77
clear-color failure is retained, and matching the original black backdrop
fixes the test precondition without changing expected values or production.
Logs: `.omo/evidence/d05-production-regression/contents-opacity`.
These limitations prevent broad window-API parity claims from this stock set.

## Residual pixel diagnosis (2026-11-14)

Final Windows versus original differing-pixel counts are text14254,
choice2730, number1412 and item15016, max channel deltas2/2/3/1. Differences
are confined to window regions and are equal across RGB at sampled maxima.
A reversible guest-only floor-for-round experiment in the background tile
blend passes the full functional owner but worsens counts to14630/3007/1646/
15868 and maxima2/3/3/2. Evidence `.omo/evidence/d05-floor-experiment`.
That hypothesis is rejected; production shader is unchanged and the guest
shader was restored in finally. A separate integer256 tile-composition probe
is active; no residual is waived and no unproven shader change is shipped.

Integer256 weighted-sum tile composition reduces text/item differing pixels
to9977/11024 but leaves choice/number2759/1375 and maxima1/3/3/2; it is not
accepted as the fix. Signed-delta truncation worsens text/item to20500/20826,
so that candidate is rejected too. Both guest shaders were restored. Separate
evidence directories are d05-tile-integer-experiment and
d05-tile-delta-experiment. The next shared original probe isolates actual
windowskin stretch-only, tile-only and combined layers before further changes.

The original isolated-layer fixture has completed and produced full RGBA.
Stretch-only already reproduces the relevant values (local x100/y50=54,
y100=18), so tile composition alone cannot explain the residual. Godot's
same-fixture run reports WINDOW_LAYERS_EXEC_PASS with empty stderr, but VIX
returns1; its RGBA collection and exit-status diagnosis are pending. This is
diagnostic evidence only, not a passed new owner or an accepted D05 fix.

Godot layer output is collected. Tile-only is byte-exact; stretch-only at
local x100/y30,50,100 is69/55/19 versus original68/54/18. Opaque controls
then show source-stage values92/73/26 versus original91/72/25, establishing
that final opacity alone is not the cause. The original opaque gradient
matches pixel-centred linear interpolation followed by integer truncation
on101 of104 interior rows; nearest sampling in the current shader cannot
produce some observed original intermediate values. A guest-only linear-
stretch experiment now tests that mechanism with the existing tile formula.
The earlier VIX1 was the short-lived Start-Process exit-handle issue; retaining
the Process.Handle gives VIX0 on the opaque run. No runtime fallback added.

Linear-stretch full-message experiment yields11128/2885/1288/12285 differing
pixels and max2/2/2/1, still nonexact; no production change is accepted.
The artificial opaque source ramp (row y has gray4*y) confirms interpolation
but shows quantized-coordinate behavior: ordinary pixel-centred linear floor
misses10 interior rows by1. A quantized139/256 source step from local y2
matches all but one measured row, so it remains a diagnostic observation,
not an implementation constant. Independent numerical analysis is active to
identify a mechanism and discriminating next input. Original ramp raw data:
`D:/VMs/original-window_background_layers-gradient.rgba`.

Independent numerical analysis now narrows the next experiment. It measures
the opaque background extent at local x2..165/y2..117 for the168x120 window,
and the real-skin column matches interpolation over source span63 with116
destination rows. The synthetic ramp still differs at exact quarter/half
boundaries, so neither63/116 nor139/256 is accepted as an exact implementation.
The next prepared fixture uses alternating0/255 source rows to resolve the
fractional coordinate much more sharply than the4-level ramp. It is not run
while the Windows guest is offline. No production geometry or shader change
is made on this advisory result alone; a second window size will be needed to
distinguish a general rule from a single-size fit.

Both parity fixtures are now prepared independently at heights120 and124:
D:/VMs/original-window-layers-parity and original-window-layers-parity124.
The advisory task has finished; it reports no hung kernel and used only
Python standard-library numerical reads. Its quantization candidates remain
unproven until these stronger inputs run. Background VM recovery is initiated
with nogui, leaving the host desktop untouched; guest login readiness still
gates rendered execution.

Final Windows guest replay now passes D05_MESSAGE_PASS, the original 360-row
hash and all real input scenarios, exit 0. Evidence is preserved in
`.omo/evidence/d05-windows-guest-fixed`. Numerical comparison of the four
baseline PNGs to original RGBA gives maximum channel deltas text 2, choice 2,
number 3 and item 1; no pixel in any surface exceeds delta 3. The old localized
choice deltas 10..17 are gone. This is measured residual error, not byte-exact
whole-message parity and not a relaxed test tolerance. Independent final
Windows four-image visual inspection is pending.

That final independent Windows inspection now passes all four surfaces:
readable intact text, correct cursor/frame placement, both item icons and
counts, no clipping or overlap. Static visual acceptance is complete on both
guests. The measured 1..3-level original pixel residuals remain explicit;
they are not converted into exact whole-message parity by the visual PASS.

The first source-run attempt timed out before script startup because the clean
guest lacked .NET hostfxr/coreclr. A portable existing .NET 8.0.34 runtime in
C:/RGSS-Tools/dotnet, with process-only DOTNET_ROOT/PATH, enables the actual
test; no system SDK or host-desktop game run is required. The earlier attempts
and engine initialization errors remain in D:/VMs/windows-contract-godot.log.

Latest independent visual result: all four final Ubuntu message surfaces pass
static inspection (text, choice, number, item). Both item icons and quantities
are present; text is readable, windows/cursors are positioned correctly, and
no missing texture, clipping or overlapping columns is observed. Linux item
descenders touch the cursor bottom row but remain complete. These verdicts
apply to the final integer-background captures, whose pixels are identical to
the inspected versions. Motion and input are established by the separate
executable owner, not inferred from these images.

Linux glyph advances, antialiasing and descender depth differ from Windows;
this visual pass does not establish Windows original whole-message equality.
The border seam fix and Linux synthetic whole-window golden are verified,
while a fresh Windows message capture with the repaired shaders remains the
last original-font full-frame comparison. D05 stays open for that comparison;
the Linux guest functionality and four-surface visual gate are complete.
The current Windows managed project also builds successfully with
`dotnet build RGSS-Godot.csproj --no-restore`, exit 0 and the same seven
existing warnings. This compile check does not replace Windows guest rendering.

## VMware border seam and Linux resource follow-up (2026-11-14)

Offline numeric/source investigation locates the significant choice residual
at the border's first interior row, not glyph coverage: both contents captures
have alpha 0 there. A synthetic transparent skin with a red hidden up-arrow
reproduces 44 leaked interior pixels on the Ubuntu SVGA3D renderer. The border
shader now uses integer pixel coordinates for the normal-size interior discard,
removing the half-pixel misclassification. The same probe returns 0 leaked
pixels at exit 0. Existing window composition and activation owners both pass
at exit 0; the composition owner now retains the hidden-arrow regression.

The first full message replay then exposes a separate Linux resource defect:
stock scripts request Iconset.png while the unmodified RTP contains IconSet.png.
Bitmap loading and its existence probe now share case-insensitive component
resolution on non-Windows filesystems, preferring exact matches. No original
asset is renamed. The Bitmap owner exercises mixed-case directory/file/extension
lookup and passes on the actual Ubuntu guest. Linux build exits 0 with seven
existing warnings; C# diagnostics are clean.

Full actual-window message replay now passes all input cases and the original
360-row hash c5980e4baf11cc53966db0b1fd686e12cad02f89e2d6c26ec18af1f65a5a10bb,
with D05_MESSAGE_PASS and process exit 0. The runner reads its configured game
root instead of the prior host-specific absolute source path. Evidence:
`.omo/evidence/d05-linux-border-seam` (capture collection in progress).
The existing border, arrow and animation-render original contracts also pass
on the Ubuntu guest at exit 0. The whole-window original contract fails with
2,944 interior pixels in the tone case differing only in green by one level.
Replaying the untouched border shader from the original guest project archive
produces exactly the same failing SHA256 as the fixed shader:
71cd921706947fe1bc169789ad0ccb1fb7b592637b3290a777f2b038d4495d65.
Thus that Linux tone residual predates this border change; the original
7fa827f911e7196271f8fc5f752c046cfaf933fce482451b18e732b46c49d370
expectation remains unchanged. The fixed shader is restored after comparison.
Logs: D:/VMs/border-seam-border-matrix.log and
D:/VMs/border-seam-preexisting-comparison.log. The choice seam is now flat
83 at x478..487/y240 versus original 85; exact full-frame parity is not claimed.

Final full-frame comparison and independent visual inspection remain pending;
this section does not claim whole-frame equality or close D05 yet.

The Linux whole-window tone residual is now resolved at its actual owner:
WindowBackgroundShader's final normalized floating-point mix/floor yielded
green 101 instead of original 100. Performing that existing 256-weight blend
in integer byte space removes the backend rounding difference. The unchanged
whole-window golden now passes with exact original SHA256
7fa827f911e7196271f8fc5f752c046cfaf933fce482451b18e732b46c49d370,
exit 0 (`D:/VMs/border-seam-background-integer.log`). No tolerance or expected
pixel changed. A final message/opacity replay is active for this newer shader;
the earlier four-image visual inspection belongs to the pre-integer version.

Final post-integer replay passes WINDOW_TRANSPARENCY_PASS, the original
360-row hash and D05_MESSAGE_PASS, exit 0. Final captures and runtime log are
preserved under `.omo/evidence/d05-linux-integer-background`. Full RGBA
comparison of all four baseline PNGs against the pre-integer capture finds
zero changed channels for text, choice, number and item; the independent
inspection of those identical pixels therefore applies to the final captures.
Its result is still pending. Tone-specific whole-window equality above and
message screenshot equality across these two host versions are distinct
measurements, not a claim that Linux fonts equal the Windows original.

Post-change Linux base-owner coverage is complete: the first aggregate run
passes 20/22; the two failures are missing defined? tool inputs and a database
fixture's host-specific E: path. Copying the existing defined? fixture/golden
and resolving the database source from the configured project fixes those
test inputs. Only the two failed owners are rerun: DEFINED_RUNTIME_PASS:77
and RPG_DATABASE_PASS with 15 compared files, both exit 0. No assertion is
weakened and no aggregate TEST_SUITE_PASS:22 from a single run is claimed.
Ruby syntax passes; GDScript LSP is not configured and Ruby LSP is absent,
so actual parsing/execution supplies those checks. Logs:
D:/VMs/border-seam-base-suite-directory-fixed.log and
D:/VMs/border-seam-base-two-input-fixed.log.

Current original-input result (2026-11-14): the subscribed foreground handshake
completed in the isolated project
`.omo/compatibility-run-tmp/d05-original-input-number-field`. All six actual
input cases passed: choice accept, choice cancel, number editing, item accept,
item cancel and text pauses. The run reports `D05_ORIGINAL_INPUT_PASS:6`, exit
0. The number probe reads the stock `@index` field with
`instance_variable_get`, as the existing baseline does; it retains the exact
value 89 and index 2 expectations. Earlier failed foreground attempts below
remain historical evidence, not the current input result. This closes the
original-input measurement gap only. Localized whole-frame pixel differences
remain recorded; D05 is still open pending the complete acceptance audit.
All further input execution is confined to VMware guests.

Current continuation reproduces the foreground limitation in two fresh owned
projects: expected PIDs270808 and210884, actual71864; SetForegroundWindow
returns false and neither run sends a key. D05 remains open for original
physical input and whole-frame pixel parity. The capture launcher now releases
its file event and owned Game.exe in finally on success or failure, so a failed
foreground handshake cannot leave the original window alive. Cleanup is checked
by `tools/check_message_capture_cleanup.ps1`. Desktop-control tool discovery
returned no available catalog tool; no alternate input delivery was attempted.

Original interaction follow-up: `message_original_input_reference.rb` reuses
the existing stock-window fixture and invokes Windows `keybd_event`, leaving
`Input.update` and all window/interpreter handlers intact. Each key action
checks that this owned original process is foreground, releases the key in
ensure, and fails if navigation, accepted result or fiber completion differs.
Six cases cover choice accept/cancel, number clamp/wrap/ignored cancel, item
accept/cancel and text page/escape pauses. This fills the original-input
measurement gap below; it is not yet an accepted result. Capture is active
through `tools/capture_original_message_input.ps1` in a fresh owned project.
Ruby LSP is unavailable on this host; syntax is checked with `ruby -c` and
behavior is checked in RGSS300. No language-server dependency was installed.

First original attempt fails safely before any key because launcher-time
activation does not remain foreground through initialization. No interaction
was counted. The fixture now calls SetForegroundWindow on its own initialized
active window after the initial frames, then retains the per-key process-ID
check; fresh owned rerun is active. It does not send keys to another process.

The second attempt fails before keys because GetActiveWindow on the Ruby
execution thread does not provide the native window. That approach is removed.
A ready-file event now lets the external launcher activate the exact process
only after fixture initialization, then acknowledges activation to the frame
loop. Every key still checks foreground PID. Third attempt is active; neither
earlier attempt establishes an input result.

Third attempt wrote the ready file but WaitForChanged missed its creation
before it subscribed; original correctly timed out without key delivery.
Launcher now registers the Created event before starting Game.exe, preserving
events until Wait-Event consumes them. Fresh subscribed run is active.

Subscribed handshake completes, but the original per-key foreground guard
still fails before input. Next probe records expected/actual PID and window
handles both outside the process and through the original Win32API wrapper.
This distinguishes real focus loss from an incorrect FFI observation before
changing activation again. Existing passed host checks are not rerun.

PID probe shows actual foreground71864 rather than owned original251428:
AppActivate's true return did not establish focus. The launcher now temporarily
attaches its input thread to the current foreground thread, activates the owned
main window and immediately detaches in finally. External PID must match before
acknowledgment; original still checks before each key. No global settings change.

Thread-attach attempt returns SetForegroundWindow=false; external foreground
is still71864 instead of original244588. Launcher stops before acknowledgment
and no keys are sent. Original physical-input parity remains unverified under
this desktop condition; host input and original no-input evidence remain valid.

Latest independent four-pair inspection visually accepts text, choice, number
and item surfaces after the cursor scalar-tail correction. It read all eight
actual544x416 images and found identical geometry/text component positions,
unclipped lists/icons and matching cursor shape. Pixel parity is not claimed:
choice retains nine localized pixels up to delta17, number up to3, other
surfaces mostly1-level fill differences. The original360-row state baseline
and all actual input scenarios pass; affected15 rendered/font contracts pass.
The measured cursor dual-background residual is exact after1890-row sweep
and both3529-row matrices. Whole D05 pixel equality remains separate from
this bounded visual acceptance.

Latest result: Window ox/oy Ruby boundary now accepts Integer/Float, matching
original truncation and existing native conversion. Full360no-input baseline
hash c5980e4baf11cc53966db0b1fd686e12cad02f89e2d6c26ec18af1f65a5a10bb
matches original (including80scroll rows); D05_MESSAGE_BASELINE_PASS:360 and
D05_MESSAGE_PASSexit0 after allreal input scenarios. Independent four-pair
window visual comparison running; D05 not yet accepted as complete.

Follow-up: all 90 short-line font cases now match original; see
`font-short-layout-verification.md`. Default window 360-row state and all real
inputs passed again. Cursor brightness was traced to an actual inactive-phase
reset contract, not capture timing; `window-activation-verification.md` records
the original 67-frame red probe and pending fix verification.

The 67-row cursor activation comparison and existing 273-row window-animation
comparison now pass after the separate cursor clock correction. Default
window 360-row baseline and all real inputs passed again. The unified suite
completed `TEST_SUITE_PASS:41`, exit 0. Fresh automated image comparison found
only 4/29/6/92 pixels above channel delta 8 in text/choice/number/item respectively;
most remaining differences are 1-2 channel levels. Independent final visual
inspection confirms text and numeric placement, but flags the choice-window
pause triangle brightness for further checking. D05 remains open.

After the full 43-member suite passed, coordinate decomposition corrected that
visual hypothesis: significant choice differences were cursor nine-patch
corners, glyph-edge pixels and outer background corners, not the pause sign.
The new 3529-pixel original cursor matrix now passes after fixed margins and
separate edge/center sampling. Remaining large corner deltas are the four
target background corner pixels, absent in original despite an opaque source
background. Background corner clipping is now tested against the existing
whole-window golden and default message-input runner. No image tolerance was
weakened.

Background target-corner clipping passed the whole-window reference and the
default input runner. Fresh paired bytes now have maximum deltas text 2,
number 3, item 2; choice retains three glyph-edge pixels at delta 10-17.
A direct original/Godot Window_ChoiceList.contents RGBA capture is running
at the same 40-update baseline to distinguish font pixels from final composite.
The full 43-member suite passed before this corner change; related whole-window
and input regressions passed afterward.

Both contents captures completed successfully. At the three significant screen
differences, original contents pixels have white RGB with alpha 0 while Godot
has black RGB with alpha 0. Visible contents differ only by one RGB level at
74 pixels; alpha agrees. Original transparent text-color coverage occupies
the interior of each draw_text rectangle (excluding its one-pixel boundary),
including the doubled-width per-character rectangles used by draw_text_ex.
The renderer now retains text RGB in zero-alpha interior pixels after drawing;
build and corresponding regression are pending. This addresses source texels
sampled by the existing contents renderer, rather than adding screen offsets.

That hypothesis did not change the three significant screen differences even
though fresh contents confirmed transparent RGB was written. The modification
was withdrawn. Existing font styles and input remained passing, but this is
not evidence for retaining an ineffective change. The same cursor matrix now
has an Alpha-gradient variant to measure semi-transparent center interpolation;
original capture is running. Choice differences will not be waived as timing.

Unified gate passed `TEST_SUITE_PASS:39`, exit 0. Automated full RGBA comparisons
still found differing bytes: text 45,351 (maximum channel difference 247),
choice 11,463 (252), number 5,913 (246), item 59,142 (247). Each capture is
544 x 416 with 905,216 RGBA bytes. These differences are not explained yet;
360-row state agreement and real input success do not establish pixel parity.

Measured locally on 2026-11-13 with Godot 4.6.1 .NET and the Chinese RMVA 1.00
RGSS300 baseline. This local contract is registered in the unified event suite;
release/platform parity remains unverified. The runner owns an isolated VM and does
not start the configured game's title or map loop.

`tests/fixtures/message_window_reference.rb` constructs real `Window_Message`,
`Window_ChoiceList`, `Window_NumberInput`, `Window_KeyItem`, and
`Window_ScrollText` instances. It drives `Game_Interpreter.update`,
`Window_Message.update` (including every subwindow), and
`Window_ScrollText.update` once per recorded frame. No window method, drawing
method, handler, or `Input` method is mocked. The GDScript runner injects key
presses/releases with `Input.parse_input_event`; the shared fixture polls them
through stock `Input.update`.

The runner reads the source game's `Data/Scripts.rvdata2` through Marshal and
the host's Zlib registration, excluding `Main`. Original fixtures use
`tools/prepare_original_fixture.rb --stock-scripts` to inflate the same table
host-side. The five window sources were independently extracted with Ruby
Marshal/Zlib into `.omo/tmp/d05-message-stock`. The fixture uses in-memory RPG
system, actor/class, party, variable, and two key-item data. A living party
member is required because this source `Window_KeyItem` inherits
`Window_ItemList.enable?`, which delegates to `$game_party.usable?`. An initial
empty-party fixture could navigate but correctly could not accept an item;
adding real actor/class data corrected that fixture failure.

Real Window/IconSet graphics come from the installed RTP at
`F:/Softwares/RPG Maker VX Ace/RTP`. The original fixture redirects only Cache
resource paths into that RTP. It generates no artwork. The opaque black
backdrop is a plain fixture bitmap.

Run from `E:/Projects/RGSS-Godot`:

```powershell
E:/Godot/Godot_v4.6.1-stable_mono_win64_console.exe --rendering-method gl_compatibility --path E:/Projects/RGSS-Godot -s tests/test_message_window.gd --log-file E:/Projects/RGSS-Godot/.omo/evidence/d05-message/d05-message-godot-result.log
ruby tools/prepare_original_fixture.rb E:/Projects/RMProject E:/Projects/RGSS-Godot/.omo/compatibility-run-tmp/d05-message-original-final tests/fixtures/message_window_reference.rb --stock-scripts
powershell -NoProfile -File .omo/tmp/d05-message-run-original-final.ps1
```

The prepare tool rejects an existing destination. Use a fresh owned directory
when recapturing; update the owned launch script accordingly. Long runs were
launched through `monitor`, and comparisons require actual original process
exit zero plus `d05-message-original-complete.txt`.

Observed real-key coverage:

| Contract | Evidence |
| --- | --- |
| Text page pause, Enter page advance, escape `\!` pause, Escape resume, `\>` fast line and `\^` pause skip | PASS; interpreter blocks before acknowledgment and completes afterward |
| Confirm-triggered fast text | PASS; `@show_fast` and `@pause_skip` true after real Enter |
| Choice cursor, accept, cancel branch | PASS; Down selects Blue, Enter writes 22, Escape cancel writes 33 |
| Number clamp, digit arithmetic, cursor wrap, ignored cancel, acceptance | PASS; 9876 clamps to 999; Up/Right/Down/Left/Left gives 089 at index 2; Escape retains pending input; Enter writes 89 |
| Key-item navigation, accept and cancel | PASS after correcting party data; Right selects item ID 2, Enter writes 2, Escape writes 0 |
| Interpreter and window fibers after each successful interaction | PASS; trailing command writes variable 9 = 77, interpreter ends, message fiber is nil, subwindows deactivate |
| Scroll completion and Shift acceleration/prohibition | PASS after accepting float window origins; both modes finish and resume the interpreter |

The initial scroll failure was at `RGSS/window.rb:165`: `TYPE_CHECK_MAP[:oy]` permitted only
Integer. Stock `Window_ScrollText#scroll_speed` multiplies by `0.5`/`1.0`, so
`update_message` supplies Float to `self.oy`. The initial rendered Godot run
recorded `TypeError: Expected Integer, but got Float` at `window.rb:175`, called
by `Window_ScrollText.rmvascript:70`. Original RGSS300 accepts the same update:
scroll position advances from -416 to -412.000, while the public `oy` getter
returns integer -412. The lead corrected the Ruby numeric boundary to accept
Integer/Float for ox/oy. The existing native binding truncates toward zero.
Both scroll modes and their completion checks now pass.

The original has no supported deterministic input injection surface available
in this session. Its fixture deliberately captures 40 no-input frames for each
of nine cases (360 rows), including real window geometry, active state,
openness, choice/item cursor, numeric digits, pause/fast flags, scroll origin,
interpreter blocking and variables. It never substitutes scripted results for
native `Input.*`. Original accept/cancel/navigation parity therefore remains
unverified even though the corresponding real Godot key checks pass.

TSV columns, in order: case, frame, interpreter running, message busy, variable
9, message x/y/width/height/openness/pause/show-fast/line-fast/pause-skip,
choice active/index/x/y/width/height/openness, number
active/value/index/x/y/width/height/openness, item
active/index/item-ID/y/openness, scroll visible/oy/contents-height/internal
position, variables 1/2/3. Floats use three decimal places. Rows flush each
frame so red runs retain their last observable state.

Godot's seven non-scroll no-input cases contain 280 rows with normalized
SHA-256 `3321a3274d327d49f421f26af1ed78846d911e5933b488c825f7028734f4912e`.
The earlier pre-normalization original run exited 0 with 360 rows and hash
`a64cea4de2877042158dc57c15aad90b5d9eb8525b6d4ade0f751c4b3297bf73`;
that first capture had a cross-case visible-state carryover, corrected by
creating a fresh `Game_Message` per case. It is historical evidence, not the
final baseline.

Final original capture exited 0, emitted its explicit completion file, and
contains 360 rows with normalized SHA-256
`c5980e4baf11cc53966db0b1fd686e12cad02f89e2d6c26ec18af1f65a5a10bb`.
All 360 no-input rows now match Godot, including 80 scroll rows, and the full
hash is pinned in the runner. The earlier red Godot run contained 535 rows and
ended in `D05_MESSAGE_FAIL`, exit 1; it established the numeric boundary defect.
The corrected run emitted `D05_MESSAGE_BASELINE_PASS:360` and
`D05_MESSAGE_PASS`, exit 0, after all real input checks.

Original source provenance printed after exit:

| Source file | Version | Bytes | Last write UTC |
| --- | --- | ---: | --- |
| `E:/Projects/RMProject/Game.exe` | 3.0.0.1 | 141312 | 2024-09-05T10:02:31.1135899Z |
| `E:/Projects/RMProject/System/RGSS300.dll` | 3.0.0.1 | 1192960 | 2012-01-09T09:10:06Z |
| `E:/Projects/RMProject/Data/Scripts.rvdata2` | source stock table | 148792 | 2026-06-07T16:53:05.0872515Z |

Rendered Godot logs and captures are under `.omo/evidence/d05-message/`.
The corrected-party execution exited 1 with `D05_MESSAGE_FAIL`, seven
completed non-scroll interaction scenarios, and the scroll TypeError. A
fail-fast follow-up preserves the first error instead of overwriting it with a
dependent assertion. Earlier default-renderer launch crashed with signal 11
before the banner while its log parent did not exist; the explicit real OpenGL
compatibility run with a valid log parent produced the measurements above.
No C# builds or production edits were made by this unit.

Screenshots ready for separate multimodal inspection, never viewed by the
implementing agent:

- Godot `godot/d05-message-baseline-{text,choice,number,item}.png`.
- Godot `godot/d05-message-text-second-page.png`,
  `godot/d05-message-choice-blue.png`, `godot/d05-message-number-089.png`,
  `godot/d05-message-item-silver.png`.
- Original `original/d05-message-baseline-{text,choice,number,item}.rgba` and
  corresponding size text and `original/d05-message-baseline-{text,choice,number,item}.png`.

Original RGBA captures are 544 x 416, 905216 bytes each, converted using
`tools/rgba_to_png.gd` with four `RGBA_PNG_PASS` markers and process exit 0.
Each PNG is paired with the corresponding Godot baseline PNG above.
The implementing agent did not view any of these images. Ruby/GDScript LSP
diagnostics were unavailable (rubocop missing; no `.gd` server configured);
no dependencies were installed. Godot parsed and executed the runner, and
the final fixture also executed in RGSS300. `ruby -c` reports `Syntax OK` and
`git diff --check` reports no whitespace errors in the three owned paths.

Numeric agreement, exact pixel agreement, and independent visual acceptance
are separate verdicts. Pixel parity and visual acceptance are not claimed.
Only RGSS300 is measured; RGSS301 and other operating systems are gaps. This
runner was registered by the lead in `tools/run_tests.gd` under `--events`.
Final temporary-project cleanup remains a separate goal task; retain owned
`.omo/compatibility-run-tmp/d05-message-*` projects and their copied player/DLLs;
retain evidence and the documented provenance.
