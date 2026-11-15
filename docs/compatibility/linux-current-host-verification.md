# F10 current compiler Linux execution

## Current status (2026-11-14)

Actual Release graphical capture now exits 0 using Xvfb and Mesa llvmpipe
OpenGL 4.5 Compatibility (Mesa 25.2.8), without the headless dummy renderer.
`tools/run_linux_release_render.ps1 -EvidenceName f10-linux-release-render-bootstrap`
produces 12 PNG frames at 544x416, MAIN_LOADED:OK and
LINUX_RELEASE_RENDER_CAPTURE_PASS. Independent inspection (st_01a1d82a) of
frames 6 and 11 passes: all three 128x128 squares have exact bounds/colors,
background is opaque (24,32,48), both text lines are readable and centered,
no content is clipped, and both frames are byte-identical in pixel content.
The PNGs use RGBA with alpha 255 throughout; this is consistent with the
opaque-color requirement, which did not require RGB-only file encoding.
This uses a package copy with a deterministic RGB-square/text
bootstrap and a registered RGSS update Fiber; it does not exercise a complete
game, physical display, hardware GPU or device audio. The first attempt failed
on missing Ruby wrapper requires and remains in f10-linux-release-render.
The successful run records an Xvfb V-Sync unsupported warning; no warning is
suppressed. Actual images/log are in f10-linux-release-render-bootstrap.

The same Release archive also passes the native-extension owner in an offline
runtime-only container: LINUX_RELEASE_CLEAN_NATIVE_PASS, MAIN_LOADED:OK,
LINUX_RELEASE_CLEAN_NATIVE_EXIT:0. Entry: tools/run_linux_release_native.ps1
-EvidenceName f10-linux-release-native-eval. It extracts an isolated copy,
replaces only the probe bootstrap and compares the existing original 24-row
native-extension, 11-row Gzip IO and 6-row Gzip integrity tables. Marshal bigint
round-trip and defined? are asserted too. This exercises all four extension
libraries through the exported Release host without a compiler or system decoder.
The source archive remains unchanged. Evidence:
`.omo/evidence/f10-linux-release-native-eval/runtime.log`.
The first attempt's log remains in f10-linux-release-native: its probe used
unsupported Kernel#load and failed before the tables ran. The corrected probe
uses the existing eval(File.read(...)) path. No runtime fix was needed.

A separate current-source Release export through
`tools/run_linux_release_export.ps1` now reaches LINUX_RELEASE_EXPORT_PASS.
It refreshes the measured build image's project from production sources and
Plugins/linux, uses `--export-release`, and compares all five exported native
libraries to their production inputs. Actual exported Ruby bootstrap and WMA
cache comparison pass (LINUX_EXPORTED_RUBY_PASS, MAIN_LOADED:OK,
LINUX_EXPORTED_WMA_LOAD_PASS, LINUX_EXPORTED_WMA_CACHE_PASS).
Archive SHA256: ebe7ffda522c693fc2333c7a88099ac9e46311ac794e2f75698f16977e894efa.
The archive also passes offline relocated runtime-only execution:
LINUX_CLEAN_EXPORTED_WMA_PASS and LINUX_RELEASE_CLEAN_EXIT:0, including
byte-exact decoded cache comparison. The fresh container has no SDK, compiler
or system ffmpeg, and starts from an empty working directory with a fresh
user cache. Evidence is isolated in `.omo/evidence/f10-linux-release-export`;
existing Debug archives remain unchanged. No graphical, MIDI or macOS
acceptance follows from this run.

Current Gzip encoding implementation is now verified in an assembled Linux
package using the previously exported managed host and the newly built Zlib
SO. Offline runtime-only execution passes all14 original encoding rows plus
WMA loading and byte-exact cache comparison, MAIN_LOADED:OK, overall exit 0.
Log: current-gzip-package-runtime.log. New package SHA256:
9a86c89abfff2d813af0d2eb31e2a0020e4e3a09a69c9a953d56ff9d9984e6b0.
This is package assembly with a current native library, not a second Godot
export or graphical full-game acceptance. Prior archive remains preserved.

The verified headless package was archived as tar and extracted at a
different absolute path in another offline runtime-only container. This tests
distribution permission preservation and relocation, beyond direct bind-mount
execution. Its SHA256 and separate archived-package-runtime.log are retained;
the result passes LINUX_ARCHIVED_PACKAGE_EXIT:0, including the byte-exact WMA
cache comparison. Archive SHA256 is
26991703f6e2a0b96c4acc0d2e6a104ffa5f51c5e17c73bb28d0c20b2b8e40cc.
The actual log resolves RMPROJECT_PATH to /tmp/relocated-install. The archive
uses an owned WMA bootstrap, not a game.

Source inspection also confirms GameMidiPlayer.Initialize explicitly supports
Windows only and throws PlatformNotSupportedException on Linux/macOS. Linux
WMA/PCM/OGG/MP3 acceptance therefore does not imply MIDI platform support;
the MIDI-inclusive seek owner cannot be counted green on Linux by filtering
its MIDI rows. That platform implementation gap remains open.

Offline clean-runtime package execution now passes at exit 0:
LINUX_EXPORTED_WMA_LOAD_PASS, MAIN_LOADED:OK,
LINUX_CLEAN_EXPORTED_WMA_PASS. The complete log is
`.omo/evidence/f10-linux-godot-base-suite/clean-runtime-with-libraries.log`.
It loads the read-only installation at /install from an empty working
directory with a fresh user cache. The generated WAV matches the independent
reference byte for byte. The runtime image has only Ubuntu 24.04 plus
fontconfig/ICU and their dependencies; no SDK, compiler or system decoder.
The run has networking disabled. This closes the measured Linux headless
package-dependency gap, not graphical desktop, audible playback or macOS.

WMA-only rerun now passes LINUX_EXPORTED_WMA_LOAD_PASS,
LINUX_EXPORTED_WMA_CACHE_PASS and MAIN_LOADED:OK at exit 0. Its produced WAV
is byte-exact with the independent decoder reference. A first offline plain
Ubuntu 24.04 container then fails at startup: missing dynamically loaded
fontconfig and .NET ICU, exit 134. ldd of the main executable lists only
base-system libraries and cannot detect those runtime loads. A clean runtime
image with only libfontconfig1 and libicu74 added subsequently built and
passed the offline run above; no SDK, compiler or system decoder is installed.

Standalone export now succeeds and executes LINUX_EXPORTED_RUBY_PASS and
MAIN_LOADED:OK from an empty working directory. Its first WMA run fails with
Permission denied starting the bundled decoder. A direct stat comparison
finds source ffmpeg 0755, exported main executable 0755, exported ffmpeg 0644.
The export assembly script now restores 0755 on that specific executable
after Godot export; no runtime retry or system decoder fallback is added.
The failed WMA log is preserved as exported-wma-before-mode-fix.log.
The subsequent WMA-only rerun passed the byte-exact decoded WAV comparison;
clean-container execution remains pending.

Official template SHA512 and ZIP integrity both passed. The first export
then exited 134 because the isolated project input omitted RGSS-Godot.sln.
The source project has that solution; dotnet build of the csproj had not
needed it, but Godot's export plugin does. Both the project-copy recipe and
the retained-image export entry now copy the actual solution. The failed
export log remains linux-export.log; the new log is
linux-export-with-solution.log. The latter export and standalone Ruby checks pass.

Both export shell scripts pass bash -n in the retained Linux image, exit 0.
The first syntax command did not execute because MSYS rewrote /repo to a
Windows path; invoking Docker through PowerShell fixed argument delivery.
Official template SHA512 was read from the release's SHA512-SUMS.txt:
9fe29b74e140a69b0b29884519050dffab0bef8d34046133c7d1613824331b3043d4cd1668bb7f2be0acb5ae43636eadac508fe7191df6d107490c23320e90a3.
Export requires both that digest and ZIP integrity before extraction. WMA
cache acceptance requires exact equality with the separately decoded fixture.

All 22 Linux base owners have passed on the same build across the initial
21-pass run and the database-only rerun with its required input. The first
aggregate remains a recorded failure; its missing data was supplied rather
than its assertion changed. Windows base regression is also green.

The earlier template download stopped with curl exit 56 (TLS bad record MAC).
Windows curl subsequently downloaded the same official artifact, passing its
SHA512 and ZIP checks with TLS verification retained. The failed container
and partial download remain preserved. No Linux rendered game, audible output,
macOS or clean desktop installation acceptance is implied.

Clean runtime reproduction, after export assembly:

```powershell
powershell -NoProfile -File tools/build_linux_clean_runtime.ps1
powershell -NoProfile -File tools/run_linux_clean_export.ps1
```

The runtime image starts from Ubuntu 24.04, adds libfontconfig1 and libicu74
plus their package dependencies, and copies only a CA certificate bundle from
the build image to use HTTPS package sources. The execution container has no
network, SDK, compiler or system ffmpeg, mounts the installation read-only,
and uses a fresh user cache. This is a headless package dependency check.

## Execution history (newest first)

The only failed base owner now passes with its real input mounted read-only:
RPG_DATABASE_COMPARED:15, RPG_DATABASE_PASS, exit0. Together with the original
21 passes this covers all22 base owners on the same Linux build, in two runs;
there is no single TEST_SUITE_PASS:22 claim for that first failed aggregate.

Current Linux debug export and actual standalone execution are now running
from the retained environment. The owned exported bootstrap checks defined?,
Marshal BigInt/object values and a real Gzip file roundtrip from an empty
working directory. It does not claim a rendered full game or audio playback.
Template download, export and standalone execution remain pending.

Linux full base run completes21/22 passes. Only test_rpg_database fails:
its shared fixture hard-codes E:/Projects/RMProject/Data, absent inside the
Linux container, and emits no canonical files for its15 expected database
files. No implementation failure is assigned before supplying that input.
The completed SDK/project container is retained as a local image; the failed
owner alone will run with the licensed local Data directory mounted read-only
and a container-only relative-path link matching the existing fixture path.
Passing21 owners are settled and will not be rerun for this data-only change.

Actual Godot4.6.1 .NET Linux replay now passes managed build,
DEFINED_RUNTIME_PASS:77 and NATIVE_EXTENSIONS_PASS, overall exit0, in
f10-linux-godot-glob-https. Renaming the extension matcher removes the
reproduced hidden-file inversion without altering expected rows, confirming
the global fnmatch symbol collision at the real host boundary. Windows native
owner and22-owner suite also pass after the shared-source rename.

The full22-owner Linux base suite is now running. Its container is retained
for subsequent export work rather than discarded with the installed SDK.
No macOS, rendered Linux scene or full exported-game verdict is claimed.

Windows real native owner passes NATIVE_EXTENSIONS_PASS, exit0 after the
private matcher rename; the22-owner base regression completes
TEST_SUITE_PASS:22, exit0. The Linux
actual-host replay remains independent and pending. Passing Windows behavior
does not prove Linux symbol binding or close the observed Linux glob failure.

Glob rename compiles on Windows, exit0, and is deployed with prior DLL
preserved under glob-private-match; managed build is active. The Linux replay
did not reach build: apt rejects the downloaded .NET SDK package with Hash Sum
mismatch, exit100. Package integrity checks remain enabled; a new container
uses HTTPS Ubuntu package sources rather than the failing HTTP transport.
Its actual Godot glob replay remains pending, so symbol-preemption causality
is still a hypothesis awaiting the corrected real-surface comparison.

First actual Godot Linux run builds successfully and passes
DEFINED_RUNTIME_PASS:77, but native-extension owner fails on glob filtering:
default includes dot files and . / .., while FNM_DOTMATCH excludes dot files.
The extension exports/calls a global fnmatch symbol also provided by libc;
its Ruby-compatible bit4 enables dot matches, while libc bit4 is FNM_PERIOD,
the opposite contract. The local matcher is now named rgss_fnmatch in its
declaration, implementation and single caller. Actual Godot replay is running
to confirm the symbol-preemption cause. No fallback or platform-specific
expected table is introduced. Original failure output is retained.

Actual Godot Linux managed build now succeeds with0 errors. The first source
copy included unrelated shared-workspace folders and took extra time; no
source-copy change was applied while its script was locked. A later exact
process snapshot confirms copying finished and Godot entered editor import.
Runtime owners are still pending. No duplicate test run was launched.

While official Godot download is pending, the existing Linux native witness
is extended to execute20 original Marshal value/identity rows and43 original
Zlib stream/error rows. These include BigInt and cyclic Struct/Hash graphs,
so the Linux LP64 build cannot inherit Windows numeric acceptance by assumption.
Only these new fixture paths run; the settled77-row and Gzip checks are not
rerun. Both complete at exit0 under f08-linux-all-extensions:
LINUX_MARSHAL_VALUES_PARITY_PASS:20 and LINUX_ZLIB_STREAM_PARITY_PASS:43.
The20-row comparison includes integer class preservation, int64 boundaries,
BigInt, custom marshal_load and cyclic Struct/Hash identity. The43-row comparison
retains the original stream error classes and state transitions. Actual
Godot/.NET execution is still pending on the independent download/build run.

Four-extension single-VM replay passes LINUX_DEFINED_ORIGINAL_PARITY_PASS:77,
exit0 after line-ending normalization. Marshal IO produces seven rows whose
normalized SHA256 equals the original owner expectation
188be7f92851f02f5be75af296e1d39c321eab353c8662d3a9f88bef26ebcfa0.
These native results do not establish managed binding behavior.

Actual Godot4.6.1 .NET Linux host execution is now running in an isolated
.NET8 Ubuntu container. Current source and verified native libraries are copied
into container temporary storage; Windows project and production libraries are
not changed. The run builds the managed assembly and executes the existing
77-row and native-extension Godot owners. Download/build/runtime are pending,
so no Linux Godot PASS or export verdict is claimed yet.

First four-extension Linux load succeeds and emits77 rows. Raw diff exits1
because the original golden has CRLF while Linux output uses LF; parent
normalized comparison confirms77/77 exact values with zero differing rows.
The shell comparator now uses the same line-ending normalization as existing
Godot owners. Replay continues to the previously unexecuted Marshal IO fixture;
the failed raw-format comparison is not counted as a runtime incompatibility.

The Windows-verified owned mruby compiler source is being built with GCC in
an isolated Ubuntu24.04 container. The source repository is mounted read-only;
the source tree is copied without build artifacts into container temporary
storage. Linux configuration uses MRB_INT64, MRB_UTF8_STRING and PIC, matching
the existing Linux host build recipe. This is not yet a managed Godot-host or
export verdict.

First execution compiled and linked the native mruby CLI, then failed when
mruby attempted to write build_config_linux.rb.lock beside the read-only
configuration. The precise failure is Errno::EROFS and the original output
is preserved under `.omo/evidence/f10-linux-current-mruby/build-test.log`.
The configuration is now copied to writable container temporary storage;
the repeat runs upstream tests and the existing defined? semantics fixture.
Current repeat evidence is in f10-linux-current-mruby-config-fix and passes:
upstream total1705, OK1696, KO0, defined semantics65PASS; overall exit0.
The remaining nine upstream cases are not counted as executed passes.
No compiler compatibility defect is inferred from the read-only lock failure.

The current Linux archive is now linked with the real mruby-for-dotnet shared
glue under -Wl,-z,defs, rejecting unresolved symbols. Output goes only to the
owned f10-linux-shared-host evidence directory. Shared-host build and native
build passes at exit0, with only libc/libm/loader dependencies. GCC reports
one existing glue declaration warning for struct mrb_pool; it is retained,
not suppressed. Native callback execution is now running: real dispatcher
argument/result delivery, native RuntimeError propagation after callback return,
subsequent callback recovery and defined? are checked in the shared-library
process. This is a native callback witness, not actual .NET execution.
No production Linux library is deployed.

Current Linux Zlib/Gzip build and execution complete17/17 original rows
(eight file/metadata plus nine encoding), LINUX_ZLIB_GZIP_PARITY_PASS:17,
exit0. The output and shared libraries are in `.omo/evidence/f08-linux-zlib/`.
Marshal, Dir.glob and Regexp Linux builds are now running with the existing
xmake target macro/source contracts; outputs remain in an owned evidence
directory. All four shared-library builds are not yet actual Godot integration.

All four current native extensions now compile and link on Linux with
LINUX_FOUR_EXTENSIONS_BUILD_PASS, exit0. Regexp uses the exact Onigmo source
list extracted from its xmake target; no external regex engine is substituted.
The single-VM four-extension load,77-row original defined/Regexp comparison
and Marshal IO fixture are running. Evidence libraries remain outside
Plugins/linux, and no managed Godot result is inferred from successful linking.

Shared callback witness now passes LINUX_SHARED_CALLBACK_PASS and exits0,
covering argument/result delivery, native exception propagation and recovery.
Current Zlib/Gzip extension Linux compilation and17-row RGSS300 comparison
are running against this shared host. The container uses current source with
the Linux HAVE_UNISTD_H configuration from the xmake target and rejects
unresolved symbols. This is separate from Godot and managed callback execution.
