# Open acceptance ledger (2026-11-15)

## Current acceptance summary (57 / 57 measured)

See [current-status.md](current-status.md) for the concise current summary.

Final measured ledger: **57 / 57** accepted, execution **63 / 63**. Mac F08 true links/native,
B09/package decoder actual signals, F10 actual Release local installation/relocation
and pinned Tilemap Metal pixels, F11 independent installation and bounded 36,000-frame
resource owner are complete at their documented scope.
The Mac soak uses the current editor assembly; clean runtime owners use the actual
Release export. Apple Silicon only; Intel, notarization, factory-reset Mac, unlimited
leak freedom and stable 60 FPS are not established. Current Mac docs and evidence:
[macos-verification.md](macos-verification.md). All older open counts, missing-host notes,
and pending-execution tables below are **historical** snapshots preserved for auditability,
not current blockers. No commits or publication were performed.

## Historical milestones (Archived Chronology)

### Historical milestone: Mac audio acceptance (54 / 57 accepted, 60 / 63 execution)
B09 and the added three-platform package decoder item were accepted within report scope. Actual
Mac arm64 LGPL build, exact WAV hash, bundled format owner, Release cache,
ten-file payload audit and actual WMA 440 Hz / MIDI C4 process output with exact
post-stop silence passed. Complete game and recorder exited 0. Local `Plugins/macos`
contained the measured payload; failures remain archived. At that point, Mac F08/F10/F11 were
still open for their remaining platform scope. See [macos-verification.md](macos-verification.md) and
`.omo/evidence/macos-audio-signal/complete-measurement.md`.

### Historical milestone: C12 and non-macOS cleanup (52 / 57 accepted)
C12 was accepted: explicitly authorized host captures passed four exact pixel
checks and independent visual inspection; F1/focus/exit restored 144 Hz. The
requested 120 Hz invocation retained its no-mode FAIL. The separately authorized
60 Hz missing-phase owner passed at exit 0, restoring saved 60 Hz after focus,
toggle and exit, then original 144 Hz exactly with registry 144 Hz unchanged.
Evidence and limits: `fullscreen-mode-verification.md`.

Non-macOS acceptance and authorized cleanup completed within the documented
scope: seven original projects, 329 experimental directories / 3,438 files, and 26
tail files in two control directories/root were removed only after source and
archive SHA256 checks. All owners exited 0. Receipts: `authorized-fixture-cleanup`,
`remaining-fixtures-cleanup` and `cleanup-tail-removed` under `.omo/evidence`.
Only six explicitly retained source/toolchain/reparse directories remained;
root temporary files and active temporary processes were absent at cleanup.

## Historical execution order and open table (2026-11-15, superseded by 57 / 57 above)

*(Historical note: the table and constraints below document the 50 / 57 state prior to
C12, cleanup, and macOS Apple Silicon completion. They are retained solely as a
historical reference for non-macOS evidence paths and earlier constraints.)*

All 55 original items plus the two additions have a per-item runner/report index
in [checklist-evidence-index.md](checklist-evidence-index.md). At that historical snapshot, the
persisted checklist stood at 50 accepted / 7 open.

| Open item | Established evidence | Missing acceptance / next action | Entry and evidence |
|---|---|---|---|
| B09 WMA and original formats | Windows bundled LGPL decoder, exported Ruby WMA load, Linux source build and byte-exact decode; current Linux Release offline relocation passes | macOS decoder build, actual decode and package execution require a macOS host. Physical output acceptance is separate from loading | `tools/build_audio_decoder.sh`; `audio-decoder-distribution.md`; `.omo/evidence/f10-linux-release-export` |
| C12 resolution, scaling, fullscreen | Guest physical captures pass geometry/pixel checks and independent inspection; F1/focus/exit restore pass. Earlier host logs separately prove non-registry refresh restoration | Guest activation watermark overlays captures; guest driver lacks alternate refresh at the same resolution. Both overall harness failures remain recorded; no clean-overlay or guest alternate-refresh PASS | `tools/test_original_fullscreen.ps1`; `fullscreen-mode-verification.md`; `.omo/evidence/c12-windows-guest` |
| F08 native extension scope | Windows/Linux native owners and base 22 pass; Linux Release clean-container 24 extension + 11 IO + 6 integrity rows pass; Linux and Windows true-link six cases pass. Authorized guest developer mode enables three real links; production package exit0 | macOS ABI/runtime remains on hold. The old Windows1314 failure is preserved as historical evidence | `tools/run_linux_release_native.ps1`; `tools/test_linux_symlink.sh`; `native-extension-verification.md`; `.omo/evidence/windows-true-symlink` |
| F10 desktop exports/native libraries | Latest Windows combined export exits zero; EXE/PCK and all 217 runtime data files match the guest-verified native/File/MIDI package. Final Windows base coverage is 21 passing suite owners plus the corrected-fixture defined owner passing separately. Linux final Release passes offline WMA, nine RGSS300 File rows, native contracts and MIDI without leaks | macOS native build/export/runtime remains unverified. Software MIDI has different bank timbres and supports GM reset SysEx only. Windows editor ObjectDB warning remains distinct from the clean installed runtime | `software-midi-verification.md`, `file-binary-encoding-verification.md`; `.omo/evidence/windows-midi-file-io-release-settled`, `.omo/evidence/linux-file-io-nine-release` |
| F11 clean install, performance, long-run resources | Current Windows audio-fix Release passes clean-guest restricted-path boot and actual process/harness exit0. Current Linux audio-fix Release passes offline runtime-only relocation. Linux VMware DX12/Xorg 36,000-frame owner passes with exact teardown and memory collection; earlier Windows 36,000-frame owner restores 5/11/7 | macOS acceptance remains absent. Current Windows boot uses Dummy audio, so does not replace prior real-signal evidence. Dense Linux workload measures 24-29 FPS, distinct from stock-map 59 FPS | `installation-resource-verification.md`, `clean-install-verification.md`; `.omo/evidence/windows-current-audio-release-bounded/guest`; `.omo/evidence/linux-current-audio-release` |
| Clean owned fixture projects and temporary resources | Probe processes use bounded lifetimes and owned cleanup; failed-run evidence retained | Inventory owned temporary artifacts after pending captures finish; preserve raw evidence and source game/RTP. Do not delete shared or unclassified files | `.omo/compatibility-run-tmp`, `.omo/evidence`; `tools/check_message_capture_cleanup.ps1` |
| WMA decoder in each platform package | Windows and Linux shipped binary/source/license/notices measured; Linux Release cache is byte-exact after offline relocation | macOS decoder and exported package still require actual build/execution. Workflow configuration is not workflow execution | `Plugins/audio-decoder-README.md`; `audio-decoder-distribution.md` |

## Historical execution constraints and notes (Archived)

On 2026-11-15 the user explicitly authorized guest developer mode and removal
of seven named archived fixture projects. Developer-mode readback is 1 and the
production package passes all six true-link cases at exit 0. The seven original
projects (33 files) are now removed after verifying sources and ZIP entries
against their recorded SHA256; archives remain. Receipts are under
`.omo/evidence/windows-developer-mode`, `windows-true-symlink` and
`authorized-fixture-cleanup`. This is bounded cleanup; other build/fixture
trees remain outside that deletion authorization. Earlier pending-permission
statements below describe historical state, not current authorization.

Final Windows/Linux combined package audit finds 33 native/audio/bank/source/
license files byte-identical to production. See
`.omo/evidence/final-audio-native-package-audit.json`. The user restored the
Windows guest on 2026-11-15. The latest combined package fresh-cache WMA owner
now exits 0 with `WINDOWS_COMBINED_WMA_PASS`/`MAIN_LOADED:OK`; its 20,558-byte WAV
matches reference SHA256 `58799fa81bf05ee654ba7e2d20ca9fc27391cd71cea79a820a24e7c1392fdc55`.
Evidence: `.omo/evidence/windows-combined-wma-diagnostic`. Native guest-path
collection recovered the completed run after a forward-slash VIX path error;
no duplicate game execution was needed. This is Dummy-audio decode evidence.

D05 accepted for the stock fixture set: 360 original state rows and real-key
scenarios pass, four Windows full-frame RGBA hashes are exact, independent
four-pair visual review passes, Windows/Linux five window owners exit 0, final
base suite `TEST_SUITE_PASS:22` exits 0. Contents-opacity subtractive cursor rule
is also proven by 38 original sweep rows. Non-Windows Arial raster and custom
high-frequency skin precision remain documented window-platform limitations,
not evidence of unrestricted visual parity. See `message-window-verification.md`.

Owned current audio fixture inventory is preserved in
`.omo/evidence/owned-audio-fixture-inventory.json`: five explicitly created
SE/fade original projects under D:/VMs, with file counts, sizes and archived
evidence correspondence. Tests contain no literal dependency on those temporary
project paths. No directory has been deleted: preparation scripts still reuse
the long-tone input, and fixture/source archival needs auditing before removal.
This inventory advances cleanup preparation, not cleanup acceptance.

Seven owned temporary original projects are now fully archived under
`.omo/evidence/owned-fixture-project-archives-verified`: all33files match their
uncompressed ZIP entries by SHA256, owner exit0. The fade preparation script
reads the separately archived long-tone input rather than another temporary
project, and Ruby syntax passes. No project directory has been deleted;
this is verified archival progress, not complete repository cleanup.

Cleanup dependency audit additionally finds that
`.omo/compatibility-run-tmp/f05-defined-compiler/mruby` and `mruby-shared`
are active source inputs for the verified host build, not disposable fixture
executables. The initial754-file archive omitted two nested build-system files;
its independent rebuild fails and remains recorded. The corrected756-file
archive under `.omo/evidence/owned-compiler-source-archive-complete` passes
independent build/test at exit0 with no original tree mounted:1696OK/0KO/0Crash/
9Skip upstream cases,65defined semantics and shared-host callback probe pass.
This proves recovery of the archived source set, not bit-identical binaries.
The fixed source archive now lives at `tools/defined-compiler/source`, and both
Linux build recipes read it; the migrated shared-host recipe builds at exit0.
Windows reconstruction also passes: 1661 upstream OK, 0 KO, 0 crash, 28 skips,
65 defined semantics cases and the Windows/x64 shared DLL build, recorded in
`.omo/evidence/windows-archived-mruby-zipapi`. No reconstructed DLL is deployed;
its Godot runtime remains untested. The subsequent archive DLL ABI probe exits
0 with offset18800/state18864, all four production extension initializers and
the existing combined Marshal/Regexp/Zlib/defined smoke check passing under
`.omo/evidence/windows-archived-mruby-abi`. This does not close F08's macOS or
positive true-symlink requirements.
These trees must not be deleted on the strength of the
seven small original-project archives or any general fixture cleanup approval.

E06 accepted: original three-condition real-device fade curves (volumes20/50/100,
durations1/2seconds) and host green support -35..0dB requested-volume mapping
and fade to -35dB then stop. Old -80dB fade is rejected by the enhanced loop
owner. Windows/Linux loop/ME/SE and final replay owners pass exit0; zero fade
now preserves playback as original. Loop formats, full-source loop-tag behavior,
seek units, same-file volume/pitch replay and fade replacement remain covered
by their existing owners. Evidence `.omo/evidence/e06-original-fade-guest`.

E08 accepted: valid original guest 440/660 coexistence and stop silence, plus
8/9/16/17-voice frequency retention. Fixed the host eight-player replacement
policy by reusing idle players and growing the busy pool. Original host red
loses early frequencies; final guest green retains all, and the enhanced
existing SE mixer owner fails on the old assembly then passes Windows/Linux,
including RTP, finite ending and reinitialization. Raw evidence and checksums:
`.omo/evidence/e08-se-capacity-guest`; se-playback-verification.md.

E07 is accepted for the measured RGSS300 handoff contract: streamed BGM
position/suppression/recovery passes on Windows and Linux; Windows original
and host real-device MIDI signals cover natural end, explicit stop, fade
remaining paused, explicit stop after fade restoring MIDI, and no resurrection
of stopped BGM. The retained incorrect fade recording fails the reusable signal
checker while original/final recordings pass. See audio-me-verification.md and
`.omo/evidence/e07-midi-me-guest`. This does not close F10 Linux MIDI support
or any macOS platform requirement.

Ubuntu DX12/Xorg 36,000-frame resource-profile owner completed exit 0:
`D:/VMs/dense-soak.log`, raw samples and capture in
`D:/VMs/dense-soak-evidence.tar`. Parallel phase takes 1,353,949 ms. Every
parallel event runs exactly 1125 times; all other event groups match their
exact counts. Drawable counts remain 5/107/7 throughout, with nodes 358,
objects 2170 and texture memory 15,294,779 bytes. Managed memory rises from
30,838,536 at frame 3600 to 75,719,624 at 28,800, then falls to 31,746,080 at
32,400; final value is 39,884,744. Static memory similarly falls from
51,330,254 to 48,159,662 at collection. Scene recreation preserves 5/107/7;
teardown returns to 5/11/7. This run establishes the existing Linux rendered
resource contract, with sampled dense-workload FPS 24-29; it is not a claim
of 60 FPS for dense maps or proof for unlimited runtimes/other platforms.
Independent inspection of the final 544x416 `dense-map-live.png` in that
archive found the expected water/ground and densely overlapping character
sprites, with no missing textures, corrupted tiles, frame-edge clipping or
error overlay. Sprite counts come from the runtime ledger, not the visual
estimate of overlapping sprites. The still frame does not establish animation
quality; timings come from the recorded frame counter.
The logs and raw archive are also preserved under
`.omo/evidence/f11-linux-vmware-dx12-xorg`; archive SHA256 is
`6a3a71d607e0547ea7562c7094f770b92402dd52bc8fb99616c0881b05ee8b9d`.

Ubuntu dense-map short owner now passes under DX12/Xorg, exit 0:
`D:/VMs/dense-short-xorg.log`. All 64 parallel events run exactly 20 times;
the other four groups each contain eight events running exactly once. Resource
counts are baseline 5/11/7, dense and recreated 5/107/7, restored 5/11/7.
The 620-frame parallel phase takes 23,705 ms (about 26 FPS); the stock-map
minute result below is not representative of this denser workload. The
unchanged 36,000-frame resource-profile owner is now running in the guest,
with a 45-minute hard limit. Its pending result is not acceptance evidence.
Current guest desktop is Xorg, with `/run/user/1000/gdm/Xauthority`.

One midpoint capture (`D:/VMs/dense-soak-midpoint.tsv`) reaches 14,400 frames
in 546,141 ms. Viewports/sprites/windows remain 5/107/7, nodes 358, objects
2170 and texture memory 15,294,779 bytes in every sample. After the first
sample, managed bytes rise from 30,838,536 at frame 3600 to 49,862,392 at frame
14,400; static bytes rise from 48,218,438 to 49,542,638. These are retained
observations, not a leak-free verdict: final samples, teardown and collection
behavior are still pending. Dense-workload sampled FPS is 24-28 after startup.

Actual-map follow-up: the initial VMware Vulkan backend stalled after the
first map frame (bounded runs timed out). The identical scene passed headless
at about 60 FPS and software OpenGL at about 16.7 FPS. Disabling only
`mks.enableVulkanRenderer` in the powered-off Ubuntu VM selected RTX 4090
DX12Renderer, verified in the host logs. With that backend the real stock
Scene_Map minute-long run exits 0, with cumulative 600-3000-frame averages
58.45-59.36 FPS (`D:/VMs/map-short-dx12.log`). Independent inspection of the
1280x800 `D:/VMs/ubuntu-map-dx12.png` confirms a real 544x416 map, water/ground
tiles and two character sprites, without missing textures, clipping or errors.
This establishes the stock-map short run, not the 96-event contract or soak.
The Vulkan failure logs remain separate; no runtime source fix is claimed.

Updated guest execution state: Ubuntu 24.04.5 x86-64 is installed in
`D:/VMs/RGSS-Ubuntu.vmx`; the ISO was disconnected before the verified first
disk boot (`/dev/sda2`, ext4). Tools 13.0.10, NAT networking, the dedicated
desktop session and PipeWire are operational. The Release RGB/text short run
exited 0 in 63 seconds with measured cumulative averages of 58.27-59.23 FPS.
Independent screenshot inspection found the expected squares and text, with
no error or onboarding obstruction. Guest OpenGL is SVGA3D 4.3; its
`Accelerated: no` report is retained alongside the host log selecting the RTX
4090 Vulkan device. These results establish the bounded fixture, not dense-map
performance or long-run stability. Logs are `D:/VMs/render-short.log` and
`D:/VMs/desktop-check.txt`.

The installed guest also passed the existing exported WMA load owner. Its
cache SHA256 is
`58799fa81bf05ee654ba7e2d20ca9fc27391cd71cea79a820a24e7c1392fdc55`, exactly
matching the reference decoded WAV. A guest-only PipeWire sink captured the
real Godot PulseAudio output without sending test sound to the host:
`D:/VMs/wma-signal.wav` is stereo 48 kHz PCM16; full playback seconds have RMS
about 1119 and 443-444 positive zero crossings, consistent with the known
440 Hz fixture. This is mixer signal evidence, not human listening acceptance.
Windows ISO and guest setup remain pending. All further desktop, input,
fullscreen and audio execution belongs in the guests; the historical host
unlock constraints below do not authorize resuming host tests.

- A direct input-desktop query returns Default even while foreground PID
  71864 is LockApp. Neither LogonUI existence nor Default alone establishes
  interactivity. Fresh D05 activation fails with that exact foreground PID and
  sends no keys. `tools/check_input_desktop.ps1` now requires Default plus a
  nonzero foreground window owned by neither LockApp nor LogonUI. Current
  refusal is verified (exit 1). Persistent monitor `mon_4N47H74D7A2JJMKM`
  waits for this combined condition; the old LogonUI-only watch was stopped.
- Original `HKCU/Software/Enterbrain/RGSS3` PlayMusic/PlaySound were measured
  disabled. No permission to change them is inferred from goal continuations;
  original silence is not signal evidence.
- Read-only PATH discovery found no WindowsSandbox.exe, vmrun.exe,
  VBoxManage.exe or qemu-system-x86_64.exe. This does not prove that no VM or
  remote machine exists. No clean Windows runtime was executed.
- No macOS host execution has been demonstrated. No external workflow was
  dispatched, no system feature enabled, and no privilege elevation performed.
- The Linux visual check is Mesa llvmpipe/Xvfb output of a deterministic
  bootstrap, not complete-game, physical-display or hardware-GPU acceptance.

## Historical Linux Release artifact (Archived)

Archive SHA256:
`ebe7ffda522c693fc2333c7a88099ac9e46311ac794e2f75698f16977e894efa`.
The original archive remains unchanged. Export and offline WMA evidence:
`.omo/evidence/f10-linux-release-export`. Clean native-owner execution:
`.omo/evidence/f10-linux-release-native-eval`. Software OpenGL images/log:
`.omo/evidence/f10-linux-release-render-bootstrap`; independent image reader
task `st_01a1d82a` passed frames 6 and 11. Earlier failed harness runs remain
separate and are not represented as runtime defects or accepted runs.
