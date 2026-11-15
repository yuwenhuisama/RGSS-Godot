# Reset and resource lifecycle

F06 accepted for the measured Windows baseline. Final cleanup build passes;
registered immediate-free actual map/menu owner exits0 with BitmapLive0 and
no resource warnings. Menu close notification and Ruby exit are also clean;
base21/render-font15 pass, with prior realF12 three-cycle counts2/3/1 stable,
file-close, dirty-bitmap, MIDI and audio reinitialization owners verified.
Temporary diagnostic probes removed. No GC forcing or quit delay was added.

Current ownership result: explicit resource Variant scopes for window tile
and transition frozen/mask, plus Shader load-wrapper scopes, remove the actual
Boot texture RID/unsafe warnings. Actual synchronous map/menu free, menu
WM_CLOSE and Ruby exit all completed clean at exit0; base21 and render/font15
contracts pass. Temporary managed/GDScript diagnostic probes and texture
clearing flags are removed. Final build passes; retained immediate-free owner
is now registered and its final post-cleanup run is active. Historical failed
experiments below remain evidence, not current outstanding implementations.

Managed minimal comparison now mirrors the clean GDScript window shader
probe with explicit Image/ImageTexture/ShaderMaterial owners. It separates
implicit texture-to-Variant conversion from a scoped/disposed Variant passed
to SetShaderParameter. Resource-valued implicit Variant lifetime is a candidate
for the exact GL31 material parameter; no production fix precedes this red/green
test. C# diagnostics are clean; probe build is active.

Single implicit-Variant managed probe exits GL clean. Production Window
rebinds tiled_texture every frame, so the minimal probe now repeats that exact
parameter operation for90 rendered frames before release, comparing scoped
and implicit Variant paths. Official Variant conversion takes ownership of a
disposable native value, but source alone is not a reproduced leak.

Repeated minimal implicit binding also exits clean, so it does not reproduce
the real Boot defect. A reversible actual-Boot experiment scopes the three
resource-valued texture Variants (window tile and transition frozen/mask)
explicitly, following their native ownership contract. Diagnostics clean and
build active; retain only if the real exit result changes. This is a hypothesis
test, not yet a shipping fix.

Actual Boot scoped-resource-Variant GL replay exits0 with BitmapLive0 and no
RID warnings, unlike the prior identical immediate-free GL31 residue. Default
RD counterpart is active before accepting the scope change as the common
cause. Minimal single/repeated C# controls were clean and remain informative:
the failure needed the actual Boot workload and allocation lifetime.

Default RD scoped-Variant run also has no texture RID residue, but reports
Transition/Viewport Shader unsafe wrappers. Real Ruby exit has no texture RID
warning, with one unnamed RefCounted warning. The four manager-owned Shader
load temporaries now use explicit scopes after assignment to material-native
owners; diagnostics clean and build active. No unnamed-object fix inferred.

Manager Shader scopes remove the reported Transition/Viewport warnings;
immediate-free replay now reports a WindowBackground Shader wrapper instead,
with no texture RID residue. Base21 regression passes exit0; rendered/font15
run is active. Remaining window Shader load temporaries are identified for
the next ownership edit after that run finishes.

Window Shader load temporaries are now scoped after native material assignment.
Diagnostics/build pass; actual Boot map/menu immediate-free replay exits0 with
BitmapLive0 and no texture RID, unsafe-reference or FATAL warnings. Updated
base21 and rendered/font15 regressions are active. Real notification/Ruby-exit
checks and temporary probe cleanup remain before final F06 acceptance.

New owned diagnostic compares synchronous Boot free plus immediate quit with
the already measured queued-free/render-drain boundary. It runs the real
third-party map/menu tree and checks live bitmaps without adding runtime waits
or changing production shutdown. Monitor active; RID output decides whether
queued node ownership explains the residual or GPU references survive tree free.

Synchronous Boot free still leaves3 RendererRD texture allocations (and6
Texture RIDs) while live Bitmap count is0; exit0 and no unsafe/FATAL. Queued
tree deletion alone therefore does not explain the residual. Same scenario
is now running under GL compatibility to locate backend-specific ownership,
without changing production renderer or masking its exit warnings.

GL counterpart leaves one texture, GL ID31,21844 bytes, with live Bitmap0.
21844 equals a64x64 RGBA full mip chain, a size clue rather than an identified
owner. A read-only test inventory now records node/material texture RID and
dimensions immediately before synchronous free. The run is active; production
ownership remains unchanged until the residual resource is identified.

First inventory ran after Scene_Base teardown, found no attached texture
nodes, and unexpectedly exited without the GL warning. It does not identify
or fix the resource. Inventory is moved to the live menu boundary so actual
node/material owners are captured before scene termination; rerun active.

Live inventory identifies64x64 window background/border textures and a
64x64 tiled_texture material parameter, plus cursor32x32 and actual contents
sizes. That inspected GL run exits clean, so inspection itself can affect
resource lifetime and is not causal proof. A separate RD run now clears only
the tiled_texture parameter before menu termination to test material-binding
ownership while leaving production code unchanged.

Clearing only tiled_texture reduces RD residual3 to2 allocations (Texture
RIDs6 to4), BitmapLive0. This is a causal change in one binding, not a complete
fix. A separate owned run now clears all live-menu node/material texture
bindings before termination to test whether the remaining two share that
ownership mechanism. Production disposal has not changed.

Clearing all live-menu texture bindings also leaves2 RD allocations; remaining
two are not explained by those bindings. Single tiled binding is now tested
under GL to determine whether it explains the unique64x64 mipmapped residue.

GL remains at1 allocation/21844 bytes after either tiled-texture clearing or
all-material detach. Thus that unique GL residual is not explained by the
tested menu binding. RD's3-to2 change is narrower evidence only. No production
cleanup change is justified from these trials; backend resource report source
is now being inspected for the remaining ownership path.

Native-handle inventory identifies GL31 exactly as WindowBackground
tiled_texture64x64. Native querying also exposes two640x416 full-mip-chain
residuals, so it can alter realization/lifetime and is not passive proof of
the other two. Previous clearing occurred before Scene_Base transition;
the next SyncRenderState can rebind the parameter. New diagnostic clears it
and synchronously frees the live menu in the same turn, preventing rebind.

Same-turn tiled clear/free still reports GL31 and one640x416 texture, so
rebind alone is not a sufficient explanation. Next same-turn diagnostic clears
all node textures and detaches materials before free; it tests the ownership
boundary without a production wait or cleanup patch.

Same-turn all-texture-clear plus material-detach menu free exits GL clean,
BitmapLive0. This materially differs from clearing during earlier transition.
The next run isolates material-detach alone to determine whether textures,
material references or both must be released before the tree is destroyed.

Material-only same-turn leaves GL31; texture-binding-only leaves GL31 and
GL33. The combined clear+detach was clean, so neither single operation is
proven sufficient. A combined RD backend run is active before selecting a
production ownership change; backend-specific residue remains possible.

Combined same-turn clear/detach leaves1 RD allocation/2TextureRIDs, despite
its clean GL trial. It is not a complete cleanup fix. A minimal pure-GDScript
TextureRect using the actual WindowBackground shader and64x64 texture now
tests synchronous release, excluding mruby and managed data ownership.

Pure-GDScript actual window shader GL probe exits0 with no RID warnings.
The equivalent RD probe is active. This rules out a universal leak from simply
binding this shader/texture, but does not yet isolate C# release order from
the larger Boot render graph. Diagnostic probes remain outside suite acceptance.

Equivalent pure-GDScript RD probe also exits0 with no RID warnings. The actual
WindowBackground shader/64x64 texture by itself is clean on both backends;
the unresolved residue requires the managed ownership or larger Boot graph.
No frame wait, GC workaround or partially effective detach was shipped.

F06 remains open. The real windowed F12 runner passed one map-to-title
reset with Viewport/Sprite/Window counts (2,3,1) -> (2,3,1), exit0.
Godot reported one TextureStorage texture RID leak at process exit; this
is retained as an unclassified shutdown finding. It is not proof that
F12 leaks, nor grounds to claim all resources clean.

The existing runner now repeats the real F12 path three times, comparing
every returned title against the initial exact counts. That run is active.
Callback retry and disposed-resource headless owners already pass, but
continuous reset, exceptions and final shutdown remain separate acceptance.

The three-cycle runner passed at exit0: each cycle returned (2,3,1),
without resource count accumulation. This execution did not report the
single-run exit texture leak, so that earlier finding is intermittent and
remains unclassified. The real reset owner is now registered in the rendered
suite. No final F06 acceptance is claimed from scene counts alone.

F06 file ownership reproduction failed before fix: load_data returned its
value while its real File handle remained open. Kernel now uses File.open's
block, closing on success and exception. The first green attempt reached
the corrupt input but the test expected ArgumentError; actual invalid format
header raises TypeError, which is preserved. The corrected test catches that
specific error and checks the same real handle is closed. Replay is active.
Ruby LSP is unavailable, so runtime execution supplies validation evidence.

KERNEL_FILE_LIFECYCLE_PASS completed at exit0 for both successful and
invalid-format loads. The exact leaked-handle regression is now registered
headless. File IO now closes at its public ownership boundary; no retry,
GC forcing or error substitution was added.

Unified headless regression completed TEST_SUITE_PASS:18, exit0 after
the file ownership fix and new owner registration. Callback retry, disposed
resource contracts, Marshal IO/metadata/values, and kernel file closure all
pass. The intermittent exit texture RID finding remains open separately.

A close-path probe starts real Boot, plays BGM and SE, observes a deliberate
Ruby exception, then sends the real Node WM_CLOSE_REQUEST notification. This
drives notification disposal and following ExitTree disposal. Initial probe
used MainLoop's nonexistent constant and failed parsing; corrected owner is
active. No lifecycle production change before executable reproduction.

Corrected close owner passes GAME_CLOSE_EXCEPTION_OBSERVED and GAME_CLOSE_PASS,
exit0, with no native crash, invalid-node or leak diagnostics in this run.
It is registered in events. This clean shutdown does not explain or erase the
earlier intermittent texture RID finding, so F06 remains open.

Audio manager disposal keeps its SE list and channel fields after QueueFree.
The existing real-mixer SE owner now disposes/reinitializes the same manager
and requests a fresh tone to reproduce whether released pool nodes are reused.
This is a lifecycle check, separate from settled F12 scene-count evidence.

Reproduction fails: se_stop after reinitialization accesses a disposed SE node
and raises native ObjectDisposedException. Dispose now clears the owning SE
list/cursor, channel references, cached filenames and parent after queuing
nodes, so a subsequent Initialize starts with a fresh pool. Diagnostics clean;
build active before replay. No disposed-object guard hides the stale ownership.

Managed build and full SE mixer/reinitialization replay pass at exit0 after
the ownership correction. The previous disposed-node exception is absent;
concurrency, RTP PCM, stop and natural-end remain green. Real close-path replay
is active; intermittent texture RID shutdown evidence remains unclassified.

Real close-path replay also passes both exception-observed and close markers,
exit0, after the audio ownership fix. No new crash/invalid-node/leak message
appears. These checks settle the reproduced stale-pool defect; they do not
erase the earlier intermittent texture RID finding.

Three real windowed F12 cycles after the audio ownership correction pass at
exit0, returning exact title counts2/3/1 each time. No RID warning appears in
this run. Reading the shutdown owner also finds DirtyBitmapDataSet is static
and not cleared by Dispose; a newly dirtied unattached bitmap could remain
rooted across VM shutdown. This is an untested candidate for a separate
reproduction, not an explanation of the earlier intermittent leak yet.

A minimal shutdown owner allocates/dirties one unattached16x16 bitmap, then
closes renderer and VM before another render synchronization. A read-only
test-driver counter records pending bitmap ownership before/after shutdown.
Bridge diagnostics and build pass; baseline runtime is active. It catches
retained dead-VM ownership independently of fluctuating scene counts.

Baseline fails SHUTDOWN_BITMAPS:1->1 at exit1: renderer's static pending set
retains the bitmap after Ruby.Close. Dispose now clears its synchronization
queue at its ownership boundary. It does not mutate bitmap disposal state
while the VM is still closing. Diagnostics clean; build active before replay.
This proven retained root is separate from the earlier unclassified RID case.

Build and exact shutdown reproduction pass at exit0 with1->0 after correction.
The owner is registered headless; the already-running regression has19 entries
because it started before that registration. Its result remains pending.

The19-entry regression completes TEST_SUITE_PASS:19, exit0; the newly
registered shutdown owner separately passed. Real Boot exception/close replay
also passes at exit0 with no RID/leak diagnostic. Both reproduced ownership
defects are fixed. The original one-off RID finding still lacks a captured
object identity and is retained as unresolved, rather than attributed to these
fixes without evidence.

Expanded real WM_CLOSE test with a normal map/menu workload passes exit0 and
no unsafe-reference diagnostic. Thus the third-party direct process-quit
errors are not reproduced by the normal close path. A separate same-plugin
640x416 WM_CLOSE variant is active to distinguish resolution/plugin load from
process teardown order before a production shutdown change.

The same-plugin Ruby exit reliably logs unsafe references while WM_CLOSE does
not. GameManager now owns a shared QuitGame cleanup sequence, used by close
and deferred from Unity.exit_game after the native Ruby callback returns.
Build/diagnostics clean; real640x416 Ruby-exit replay is clean at exit0.
Shared normal-menu close replay is active. The resumed aggregate separately
records a close-owner access-violation exit and must not be marked green;
its process may have loaded an earlier assembly while the in-flight build
updated disk, so direct current-library verification is recorded separately.

Resumed aggregate completes33 entries with two failures (damage and default
close). Damage is independently reproduced/fixed as nondeterministic test input
and passes its owner. Default close current-version replay is active; aggregate
access violation remains an unresolved observation until that result.

Current-version default close replay passes exit0 without crash diagnostics;
the aggregate one-off access violation still lacks a cause. It remains recorded
and is not erased by the clean rerun. Shared menu WM_CLOSE also passes after
the QuitGame refactoring.

Reading Destroy reveals UnityModule.UpdateFiber remains a static RbValue after
Ruby.Close. The existing shutdown owner now registers a real yielding update
Fiber and observes whether that root remains after VM closure. This isolates
another lifetime contract; it is not yet assigned as the cause of the earlier
one-off access violation. Test bridge build is active before reproduction.

Baseline fails: pending bitmap is cleared1->0, but registered UpdateFiber
still remains after VM shutdown. Destroy now unregisters and clears that
Fiber before Ruby.Close, reusing the same owner as explicit unregister.
Diagnostics clean; build active. This fixes a proven dangling VM root without
claiming the untraced access violation has been explained.

The registered-Fiber shutdown owner passes after correction, and three real
F12 cycles return2/3/1 resources each at exit0. The unified runner now rejects
native FATAL/unsafe-reference diagnostics even when a child prints its PASS
marker and exits0. This closes the observed verdict gap from third-party
shutdown runs; intentional Ruby exception tests retain their own contracts.

Unified20-owner headless regression passes exit0. The same shutdown owner
now registers one old-VM script, closes/reinitializes the VM and queries actual
run_rmva_scripts output. Source keeps a static script list across Init; this
reproduction determines whether stale script inputs survive the lifecycle.

Reinitialization first fails before script replay: NativeLibrary resolver is
registered again for the same assembly, throwing InvalidOperationException.
Resolver setup now occurs once per process/assembly, retaining its existing
resolved directories rather than resetting an immutable CLR registration.
Diagnostics clean; build active before resumed lifecycle reproduction.

Resolver fix allows VM reinitialization and exposes the next red: old-vm
registered script survives in run_rmva_scripts. Unity Init now clears the
static script queue and reset-request state before binding the new VM. This
separates process-wide resolver ownership from VM-local script input ownership.
Diagnostics clean; build active before the same lifecycle owner replay.

MIDI build and actual shutdown owner pass at exit0, true->false. Owner joins
events; public Ruby-exit replay is active after this new shutdown wiring.
Earlier intermittent ObjectDB/access-violation observations remain separately
unresolved instead of attributed to the MIDI fix without captured evidence.

Ruby-exit replay after MIDI close wiring again reports unsafe references and
FATAL despite exit0. Thus earlier clean Ruby-exit runs did not settle the
shutdown issue. Temporary QuitGame begin/end receipts now test whether the
deferred cleanup actually executes before engine teardown; no new delay/guard
is added from this unproven cause.

QuitGame begin/end receipts prove deferred cleanup executes fully before the
unsafe-reference diagnostics. Disposal queues Godot nodes, then Quit stops the
loop in the same deferred flush; the previously clean live-tree teardown drains
queued node destruction before stopping. QuitGame now awaits the next real
ProcessFrame after cleanup before Quit, and temporary receipts are removed.
This is a lifecycle barrier on QueueFree completion, not a timed retry. Build
active before reproducing the actual Ruby-exit and close paths.

Actual640x416 Ruby exit and normal-map/menu WM_CLOSE both pass at exit0
after the frame barrier, without unsafe-reference or FATAL diagnostics.
The real Ruby-exit variant now joins events with the full map/menu workload,
so future regressions exercise this shutdown boundary and strict verdict gate.
Earlier one-off ObjectDB/RID and access-violation observations remain recorded.

The exact single-argument registered Ruby-exit variant still emits unsafe/FATAL
diagnostics. The one-frame barrier did not fix the cause and is withdrawn;
shared synchronous cleanup and deferred VM-safe invocation remain. Independent
read-only architecture diagnosis st_01a1d63a investigates resource ownership
and Godot shutdown semantics before another production change. No further
delay or forced-GC workaround is stacked onto the unresolved issue.

Architecture child could not run because provider credentials were rejected.
Direct Godot4.6 source inspection shows shutdown DisposablesTracker enumerates
weak references and disposes only TryGetTarget objects, while Bitmap release
only nulls Image/Texture references. Those wrappers can become unreachable
before tracking teardown while native unsafe roots remain pending finalization.
Bitmap ReleaseResources now explicitly disposes its owned texture/image before
dropping references; build active. This ownership hypothesis will be checked
against Ruby-exit residual object types and existing bitmap contracts.

Explicit bitmap release removes ImageTexture residuals, and20 headless
contracts pass. Remaining unsafe objects are mostly private window/sprite
ShaderMaterials plus two Images. Those materials are allocated per node,
but node ExitTree drops their native reference without explicit managed release.
Sprite and Window ExitTree now detach/dispose their owned materials. Build
active before residual comparison; remaining Images are not yet explained.

Node material release removes most window/sprite residuals, leaving manager
materials, Plane material and Images. Manager now disposes its own base/
postprocess/transition materials; Plane detaches/disposes private child
materials; CaptureFrozenTextureNow uses scoped Image disposal after texture
creation. Diagnostics clean; build active. Two GDScript-captured PNG Images
are also visible in the test source, separate from production resources.

Residual run identifies four Viewport materials and Tilemap layer Images/
ImageTextures. Viewport unregister/manager Dispose now detach/dispose the
private wrapper material. Tile compositing scopes temporary Images; Tilemap
node exit detaches/disposes its generated layer textures.20 base contracts
already passed the preceding change; build active for this ownership increment.

Viewport/Tilemap release leaves only one test-capture Image and loaded Plane
Shader unsafe reference; no FATAL appears.20 base contracts pass. Plane material
factory now scopes its temporary managed Shader wrapper after the material
retains the native resource; GDScript screenshot locals are nulled after saving.
Build active for final residual check, with no resource timing workaround.

Final material changes pass20 base contracts and leave one Image even when
the exit-specific test captures no PNG, ruling out those GDScript captures.
Graphics.snap_to_bitmap replaces its root Image with a cropped Image when
resize leaves differing logical/backbuffer dimensions, dropping the original
without disposal. It now disposes the replaced original and any invalid
capture before returning. Build active; exact Ruby-exit residual replay next.

Snapshot regression passes, but cropping fix does not remove the final Image.
Reading the actual menu-background blur path finds GetRegion source clones
in Bitmap.blur/radial_blur never disposed. Both now use scoped Image ownership.
This is a concrete dropped temporary in the exercised blur path; build active
before checking whether the last exit Image disappears.

Blur ownership fix removes all unsafe-reference/FATAL messages, but Ruby exit
now identifies3 texture RID allocations/6 texture RIDs leaked. The static
RegionTextureCache owns extracted window textures and was never cleared at
manager shutdown. Dispose now releases/clears those textures; GetRegionTexture
scopes its temporary cropped Image, and Tilemap layer replacement releases
the replaced generated texture. Diagnostics clean; build active before RID
replay.20 base contracts passed the preceding blur increment.

Region cache cleanup does not reduce the3 RID residual. MRuby.Library source
shows plain NewObjectWithCSharpDataObject registrations have no release
callback: Ruby.Close drops data GCHandles, but cached/live BitmapData image
textures are never explicitly disposed unless Ruby called bitmap.dispose.
Bitmap now uses the library's existing release-callback overload with a
distinct data-type name, invoking ReleaseResources when the VM frees data.
Mask texture-copy temporary Image also uses scoped disposal. Diagnostics clean;
build active before real-exit and public bitmap contract verification.

Bitmap release-callback version passes20 base contracts but Ruby exit still
reports3 texture allocations/6 texture RIDs. That callback fixes missing explicit
Bitmap resource ownership, but does not establish this residual's cause.
Current-version ordinary map/menu WM_CLOSE comparison is active to separate
the remaining shutdown/render-buffer finding from RGSS-created objects.

Ordinary menu WM_CLOSE also leaks2 texture allocations/4 texture RIDs. Pure
GDScript screen-sampling minimal shutdown exits clean, so this is not proved
to be a general engine-only screen-texture issue.14 rendered/font contracts
pass after preceding ownership corrections. FinishTransition still stores
frozen_tex/transition_tex parameters after releasing managed textures; it now
clears those material parameters at transition ownership end. Build active
before checking residual RID counts; this candidate is not yet the proven cause.

Clearing transition material parameters does not reduce3 RID allocations and
is withdrawn. Snapshot contract passes. A second minimal probe initializes
only render/VM managers without game scenes, then disposes them, to separate
base renderer from RGSS map/menu resource creation. Actual runtime RID finding
remains open; no acceptance follows from fewer unsafe messages.

Minimal manager probes now pass clean with Sprite+freeze, Window+skin+text,
Tilemap layer and Plane. Explicit Viewport composition is next under the same
small probe. These results narrow the residual toward scene teardown/resize
or combined viewport lifetime rather than individual resource creation.

Explicit Viewport plus640x416 resize also exits clean in the minimal probe.
Next the same fixture disposes Window/Sprite/Plane/Tilemap/Viewport before
shutdown to isolate unregister/scene-termination ownership from live-node
ownership. No unverified root cause is assigned from these negative probes.

Minimal all-resource disposal exits clean. Actual Yanfly map-only WM_CLOSE
also exits clean; the RID residual starts later than map construction. Actual
menu-still-open WM_CLOSE is now active to distinguish menu creation from
menu termination/return-to-empty-scene. This bounded bisection preserves full
game workload while narrowing the failing lifetime transition.

Menu-open exit leaks1 texture allocation; replacing its screenshot background
with a plain Bitmap still leaks2, so that substitution does not prove the
snapshot is the owner. The diagnostic override is removed. Verbose actual
Ruby-exit replay now collects surviving object identities/paths before further
changes; the remaining RID cause is still unproven.

Verbose replay gives3 texture RID allocations but no surviving ObjectDB
identity. A direct BitmapData creation/release count is added as a diagnostic:
it will measure whether VM close actually releases every bitmap before
investigating GPU queue ordering. ImageTexture destructor explicitly frees its
RID in Godot source. Diagnostic build is active; no runtime verdict change.

Live-tree Boot shutdown reports SHUTDOWN_LIVE_BITMAPS:0 and exits clean,
confirming every tracked Bitmap release callback executes. The same teardown
now drains exactly one process frame before Quit as a diagnostic to separate
queued node destruction from later render-server command release. Runtime
Ruby-exit still has the recorded RID finding; no barrier is shipped from this
experiment until the actual release boundary is measured.

One process frame gives BitmapLive0 but still3 RID leaks. RenderingServer.sync
exists in native source but is not script-exported, so that diagnostic fails
parsing and is removed. The probe now waits actual frame_post_draw after the
single frame to test render completion rather than an arbitrary frame count.

Measured shutdown boundary: after one process frame BitmapLive is0 but3
texture allocations remain; after one frame_post_draw1 remains; after the
next process_frame/frame_post_draw none remain and exit is clean. The test
variant is named --render-drain and now asserts BitmapLive0, in addition to
the existing11-row plugin ledger. This proves retained renderer work crosses
the first drawn frame after queued node destruction. It does not yet prove
why native renderer references persist, so no multi-frame runtime quit delay
is shipped as a substitute for that diagnosis. Runtime Ruby quit remains open.

Build and complete close/reinitialize owner pass at exit0: pending bitmap
1->0, no registered Fiber after close, no old registered scripts in the new
VM, and no resolver re-registration error. Unified20-owner regression also
passes exit0. Three real F12 cycles after this new VM-boundary change are
active; earlier intermittent texture/access-violation observations stay open.

Three F12 cycles pass exact2/3/1 counts at exit0, but this run emits ObjectDB
instances leaked at exit. A verbose replay is active to identify actual leaked
objects. Scene count parity does not close shutdown-resource acceptance.

Verbose F12 replay passes without reproducing ObjectDB warning; no leaked
object identity is obtained yet. New lifecycle reading finds GameMidiPlayer.Close
only in the test bridge, absent from actual GameManager teardown. A real Boot
MIDI playback/queue_free owner is active to reproduce retained playback after
shutdown. Bridge build/diagnostics clean; no production change before proof.

Baseline MIDI_SHUTDOWN:true->true fails at exit1: real Boot teardown leaves
MIDI playback active. GameManager ExitTree and shared QuitGame now call the
existing GameMidiPlayer.Close to cancel/join playback and close WinMM device.
Diagnostics clean; build active before the same lifecycle owner replay.

Same Yanfly640x416 WM_CLOSE variant passes exit0 with no unsafe references.
The public Unity.exit_game Ruby quit variant is now tested separately; direct
SceneTree.Quit previously showed diagnostics while live-tree Boot teardown did
not. This isolates the actual user-facing exit entry before a runtime change.
