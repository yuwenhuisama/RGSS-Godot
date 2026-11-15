# F11 clean-install verification

Final Mac local-distribution leg2026-11-15: actual Release original-game
installation, relative project/RTP, independent directory and new HOME,
empty cwd/system-only PATH and no developer/native overrides passes Metal
windowed startup and normal exit0. Native relocation four original ledgers,
bundled cache hash, ten-file audit and real WMA/MIDI stopped-output silence
pass separately. This is runtime isolation on the supplied M4 macOS host,
not a factory-reset operating system or notarized-download Gatekeeper test.
Intel execution is unverified. See macos-verification.md and
.omo/evidence/macos-release-native-path/game-install-runtime.log.

## Latest combined MIDI and binary-IO snapshot

`windows-midi-file-io-release-settled` now exports and assembles at exit zero.
Its executable, PCK and all217runtime data files are byte-identical to the
preceding combined package that passes the installed Windows guest's native,
nine-row File encoding and three MIDI contracts at exit zero under system-only
PATH and no external overrides. The editor ObjectDB warning remains recorded;
the actual runtime has no such warning. See that directory's
payload-comparison.json and `windows-midi-file-io-release/guest-*`.

Linux final combined snapshot `linux-file-io-nine-release` passes export,
offline relocation/byte-exact WMA, native/File and MIDI owners at exit zero.
Its archive SHA256 is
f2dd11363bd21b0da087f0a4d08026baa758e2323f18aef07e2f7335167c7e8a.
These are bounded installation/contracts, not a new long-run resource claim.

## Current audio-fix source export preparation

A separate current-source Windows Release export is running under
`.omo/evidence/windows-current-audio-release`, retaining the earlier relocated
package unchanged. This snapshot includes the measured MIDI/ME, SE busy-pool,
streamed-volume and fade repairs. Its independent guest launch will use an
installation-relative RTP path, empty working directory and system-only PATH
without DOTNET_ROOT, MRUBY_DIR or RGSS_FFMPEG_PATH. Export and guest execution
are pending; no earlier package PASS is attributed to this newer snapshot.

The first current-audio export reaches savepack DONE and creates exe/pck but
does not exit within300seconds despite --quit. The still-running owned export
process was identified by its exact command line and stopped; its directory
is retained as incomplete evidence. No successful export exit is inferred from
file presence. A new windows-current-audio-release-bounded run uses the finite
--quit-after2 editor-frame budget and remains pending. The underlying editor
shutdown cause is not yet established; this invocation change is a bounded
experiment, not a proven engine fix.

The bounded invocation completes at exit0 with CLEAN_WINDOWS_INSTALL_READY.
Its complete independent install contains the current Release managed assembly
and bundled Windows decoder/license/notices under the exported data directory.
Installation config now uses project_path='.' and rtp_path='./RTP'. Packaging
is active before the restricted-environment Windows guest execution; exported
file presence alone is not the guest acceptance result.

Archive D:/VMs/windows-current-audio-release.zip is317454407bytes,
SHA256174931e0a717333fb1d949de50d13bffdf04b6426e3e4bf53115029a1062c9d3.
Its decoder, LICENSE, NOTICE and BUILD files are byte-identical to current
production inputs. Guest execution did not start: vmrun reports the Windows
VM not powered on and the inventory contains zero running VMs. The guest was
not automatically restarted. Current-source clean-guest boot remains unverified;
earlier snapshot results below retain only their original scope.

Windows testing VM has now been resumed with vmrun nogui under the continuing
guest-test authorization. The current-package launcher is active and checks
for LogonUI before any game window; no password/input automation is attempted.
The earlier powered-off rejection remains a prerequisite result, not a package
failure. Final boot markers and exit status are still pending.

A parallel Linux current-audio Release build is now using
`tools/run_linux_release_export.ps1 -Name linux-current-audio-release`, retaining
the earlier f10-linux-release-export directory. This exercises the current
production source and native inputs, then the actual exported executable on an
offline runtime-only image with relocated installation and fresh user cache.
It is a headless dependency/export/WMA check, not guest graphics, device output
or performance acceptance. Its result remains pending.

Current Linux run completes at exit0: LINUX_EXPORTED_RUBY_PASS,
LINUX_EXPORTED_WMA_LOAD_PASS, byte-exact WMA cache, LINUX_RELEASE_EXPORT_PASS
and LINUX_CLEAN_EXPORTED_WMA_PASS after offline runtime-only relocation.
Package SHA256e167ec69ec1099c9bb5c8fc4d26a30b25294ada063f202bcc74fa81f17b7ed7e;
logs/archive are in `.omo/evidence/linux-current-audio-release`. This confirms
current-source package dependency/WMA wiring only; earlier real mixer tests
remain the evidence for volume/fade/SE behavior, not this load-and-stop probe.

Current Linux package audio payload also matches every production input byte:
ffmpeg2238816bytes SHA256b517ac10d4b15e2731bcdb0ab6c9eadc06a0f64aa5db10cd62c62de6a275844a,
source archive11732036bytes SHA2567138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3,
and BUILD/LICENSE/NOTICE all equal their production files. This is measured
package content, not merely an export-copy rule.

The same current archive also passes the existing offline native-contract
owner at exit0 (LINUX_RELEASE_CLEAN_NATIVE_PASS): original extension,
Gzip reader IO and integrity ledgers all compare exactly, plus exported
defined? and Marshal checks. Evidence:
`.omo/evidence/linux-current-audio-release-native/runtime.log`.
The runner now accepts PackageName so a new package can be verified without
overwriting or silently reading an older archive. macOS remains unexecuted.

## Installed Windows guest result (2026-11-14)

The current audio-fix Release snapshot now also boots in that guest from
`C:/RGSS-Current-Audio-Release/install`, with installation-relative RTP,
an empty working directory and system-only PATH. DOTNET_ROOT, MRUBY_DIR and
RGSS_FFMPEG_PATH are removed. A separate bounded launch records actual process
exit0, SCRIPTS_LOADED:OK and MAIN_LOADED:OK between
2026-11-14T14:32:06.7643671Z and 14:32:12.3272394Z; the VIX harness also exits0.
Receipt and full runtime/stdout/stderr are archived under
`.omo/evidence/windows-current-audio-release-bounded/guest`.
This uses windowed Compatibility rendering and Dummy audio: it proves current
package startup/dependency resolution, not audible output or new visual parity.

The preceding install-and-600-frame invocation did finish its guest script
with CURRENT_RELEASE_BOOT_PASS:0, but its VIX runProgramInGuest call did not
return before the monitor deadline. That tool-level timeout is retained and
is not counted as a passing invocation. The subsequent explicit-exit harness
above provides the independently completed process and harness receipts without
reinstalling or changing the package. The precise earlier VIX return failure
remains unclassified; no runtime source fix is claimed.

The existing relative-RTP relocated package now runs in the newly installed
Windows 11 Pro x64 VMware guest (10.0.26300, GPT virtual disk, Tools running,
TPM ready and Secure Boot enabled). The interactive desktop run uses VMware
SVGA3D OpenGL 4.3, explicit Compatibility rendering and redirected output;
its actual process exit code is 0. Existing exported probes report
EXPORTED_DEFINED_PASS:3, EXPORTED_GZIP_PASS and EXPORTED_TITLE_WMA_PASS.
Guest-internal event-synchronized capture shows the actual unobscured
544x416 Project1 title and three complete Chinese menu entries, independently
inspected without missing textures, clipping or text corruption. Evidence is
currently in D:/VMs/windows-{verification.json,interactive-confirmed-runtime.log,
interactive-confirmed-stdout.txt,title-capture.png,title-capture.log}.

The first noninteractive VIX run fell back to llvmpipe and its package probe's
puts raised Bad file descriptor/syswrite. The interactive launch with valid
stdout/stderr removes that failure; no runtime source fix is claimed. A first
Start-Process check also returned a null ExitCode; direct Diagnostics.Process
retains the handle and records explicit 0. The host-window screenshot showing
Ubuntu is invalid Windows evidence and was replaced by the guest capture.

This verifies the named existing package snapshot and title/WMA-loading/native
probe scope on a fresh Windows system. It does not establish current-source
full-suite parity, actual audio signal output or macOS acceptance.

## Earlier host-only records

Independent title image inspection st_01a1d73c passes all six scene/nonblank/
text/texture/clipping/overlap checks: Project1 and the three Chinese New Game,
Continue,Exit labels appear correctly. This is one exported title surface,
not gameplay/audio or clean-machine dependency evidence. Next isolated decoder
check invokes only the shipped FFmpeg with production arguments, copied fresh
WMA input and system-only PATH; WAV sample metadata still needs inspection.

Shipped isolated decoder completes exit0. Actual WAV format1,mono22050Hz,
16-bit,20480 PCM bytes/10240frames matches the production fixture contract.
This proves the copied Windows decoder executable can run with system-only
PATH using its bundled release dependencies. Runtime cache/audio binding,
clean-machine libraries and pending native candidates remain separate scope.

Second preparation completes CLEAN_WINDOWS_INSTALL_READY, exit0 with explicit
--quit. Current release is now running from an empty working directory with
PATH limited to Windows system directories and no RGSS_FFMPEG_PATH/MRUBY_DIR.
The launch has an explicit180-frame windowed bound and records runtime.log;
no native-load or title acceptance is implied before output is read.

Uninstrumented isolated release boot completes exit0: RMPROJECT_PATH resolves
to the copied install directory, CONFIG True544x416, SCRIPTS_LOADED/MAIN_LOADED
OK and no gem-init/exception marker. It does not yet prove a visible title.
Only the owned install's Ruby entry now adds a60-update Scene_Title observer,
asserts active commands and captures actual snap_to_bitmap RGBA. Source runtime
entry is untouched. This second surface run is active; its evidence will be
distinguished from the preceding unmodified-package boot.

Surface run completes CLEAN_INSTALL_TITLE_CAPTURED and runtimeexit0. Captured
dimensions544x416/905216bytes. Exported Godot changes its working directory to
the executable directory, so relative captures are in install/, not the empty
launch directory. First conversion used the wrong path and failed; corrected
path conversion is active. Launch still proves it does not require the caller's
working directory, but no claim of retaining that directory is made.

Current local temporal map measurement passes36000frames/621015ms with eleven
stable drawable/node/texture samples and exact teardown. It is not a fresh
installation test. F11 remains open.

`tools/prepare_clean_windows_install.ps1` now exports the current Windows
release into a new owned install directory, copies Ruby wrappers, independent
RMProject data/assets and locally licensed RTP graphics/audio, and writes an
installation-local config. Project path is relative to the executable; RTP is
the copied install path. An empty working directory will be used for launch.
The source game and RTP remain untouched; this fixture is not a redistribution.

Preparation is active. The current export still uses the production compiler
and Zlib build before the pending compiler/Gzip candidates. Evidence must name
that exact snapshot. This workstation already has development software, so a
successful isolated run cannot establish clean-machine runtime dependencies.
Actual exported title/map surface, source-path independence and loaded native
libraries still require execution after preparation completes.

First preparation reaches exported exe/pck/managed files but the Godot export
process does not return before300s, so no runtime data/config copy occurs.
That incomplete directory is preserved and is not accepted. Script now passes
explicit --quit and a dedicated export log; a new owned directory is running
with a600s bound to capture the actual exit and subsequent copy phase.
