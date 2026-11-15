# Native extension compatibility

Current2026-11-15 Mac arm64 acceptance completes F08 within measured scope:
owned host and four extensions build with matching headers;1696upstream,
65defined and callback/error/recovery probes pass. All22base owners pass
through21initial owners plus the corrected-input database rerun. Actual Release
relocation matches native/GzipIO/integrity/File original ledgers; all six real
File.symlink? cases pass on Mac. Dependencies are host@rpath and system
libSystem, with@loader_path extension resolution. LocalPlugins/macos hashes
match the actual tested package. Evidence and architecture limits:
macos-verification.md, .omo/evidence/macos-native-build and
.omo/evidence/macos-release-native-path. Intel Mac remains unverified; filename
_x64 is inherited and does not describe the arm64 Mach-O payload.

## Windows true symlink acceptance (2026-11-15)

With explicit user authorization, developer mode is enabled only in the Windows
test guest (AllowDevelopmentWithoutDevLicense readback 1). CreateSymbolicLink
with the unprivileged flag creates three real links: file, directory and dangling.
The existing combined Release package's production File.symlink? returns false
for the regular file/directory and missing path, and true for all three links.
All six cases pass, MAIN_LOADED:OK and actual game/harness exit 0. Evidence:
`.omo/evidence/windows-true-symlink/{console.log,runtime.log,receipt.json}` and
`.omo/evidence/windows-developer-mode/receipt.json`. The former Win32 1314
receipt remains historical evidence; no host privilege or policy was changed.
This closes the Windows true-link gap. macOS ABI/runtime remains on hold.

Six original Gzip integrity cases now complete at exit0 and match the Windows
actual native owner (NATIVE_EXTENSIONS_PASS, exit0) without an implementation
change. CRCError, LengthError and NoFooter occur on close after full read;
truncated deflate raises GzipFile::Error on read; trailing bytes do not alter
payload; early close after one byte succeeds. The existing native owner pins
these six rows in gzip_integrity_original.tsv. Original unused.inspect failure
is recorded separately in gzip_unused_diagnostic.txt and excluded from the
integrity comparison, not imitated or claimed compatible. Linux production-input
owner with the same six-row fixture also passes NATIVE_EXTENSIONS_PASS and
LINUX_GZIP_EXTENDED_HOST_PASS, exit0. Prior failed probes remain.

Gzip integrity measurement found an original-runtime limitation rather than a
decoder hang: trailing-data reader.unused.inspect raises NotImplementedError
(`hidden T_STRING object`), outside StandardError, opening an error dialog.
The diagnostic exception and stage are retained under f08-gzip-trailing-exception;
its owned process was stopped by the capture deadline. Independent short-body
and early-close cases exit0. The fixture now explicitly records that original
NotImplementedError for unused while retaining read/close assertions. A full
six-row classified original replay is active; no host integrity parity yet.

Latest reader-position fix passes Windows and Linux complete base suites,
TEST_SUITE_PASS:22, exit0, including all11 reader IO rows and14 extended
encoding rows. Five already measured Linux libraries are now deployed to
Plugins/linux (previously only audio existed there), with copy hashes matching
their evidence inputs. Current Zlib SHA256:
5024441854f46105a666fc4b190805ad287a67cb5d25c384eaf2246629643fe5.
The standalone host recipe now uses those production files. A direct
production-input native owner passes NATIVE_EXTENSIONS_PASS and
LINUX_GZIP_EXTENDED_HOST_PASS, exit0; no new platform-wide acceptance.

## Reader IO red baseline (2026-11-14)

Original eight-row file API fixture completes exit0: readpartial preserves its
output buffer identity, zero length clears it, EOF clears it then raises,
read(length)/read/read(0) EOF results differ, each_line returns an enumerator,
and readbyte at EOF raises EOFError. Host matches seven rows; after consuming
one byte and ungetc('XY'), original pos is4294967295 while host is-1. Three
additional cross-zero rewind cases are running on the original to confirm
the integer-width rule before changing the implementation. Other assertions
remain unchanged; no reader position fix is accepted yet.

Original additional rows confirm the unsigned32-bit rule: before-start two-byte
pushback gives4294967294, consuming X gives4294967295, then Y returns0;
three-byte pushback after one consumed byte gives4294967294; one-byte pushback
before start gives4294967295 then0. Eleven rows are pinned. The reader's public
pos/tell return now converts to uint32_t before creating the mruby Integer,
matching original architecture semantics without changing buffer accounting.
Windows native/managed builds and backup/deploy pass; Windows base suite and
Linux actual native owner are running. No green position claim yet.

## Extended encoding red baseline (2026-11-14)

Original RGSS300 completes ten additional reader-option rows at exit 0 in
the isolated f08-gzip-extended-encoding fixture. Host reproduces two differences:
UTF-16LE raises ArgumentError instead of returning e381, and empty external
encoding raises TypeError instead of ArgumentError. The other eight rows match.
Raw original rows are pinned in gzip_encoding_extended_original.tsv and checked
by the existing native owner. The implementation's boolean UTF8/byte switch
cannot represent UTF-16LE; splitting an empty name also yields no first element
and accidentally type-checks nil. A character mode and explicit empty-name
classification are now implemented and verified below.

Windows rebuild/deploy/managed build now pass, the same native owner completes
NATIVE_EXTENSIONS_PASS, and the full base suite completes TEST_SUITE_PASS:22,
all exit 0. Old DLL and candidate are preserved under
`.omo/evidence/gzip-extended-encoding/`. Linux shared-source rebuild and actual
Godot native owner also pass LINUX_GZIP_EXTENDED_HOST_PASS, exit 0. This proves
the ten measured rows on both platforms; it does not claim complete encoding-family
compatibility. A fresh original fixture adds four UTF16 boundary rows: paired
surrogates read as four bytes, odd final byte is returned, and isolated high/low
surrogates read as two bytes. Original exits 0 with14 rows; the same native owner
now checks those four measured expectations as well. Windows and Linux actual
native owners both pass all14 rows, exit 0. Shared source lives in
tests/fixtures/gzip_encoding_extended_reference.rb so isolated projects that
copy tests do not depend on copying an unrelated tools tree. The earlier Linux
export/archive predates this Gzip change and remains evidence for its own build.

Current Linux full base suite also passes TEST_SUITE_PASS:22 and
LINUX_GZIP_EXTENDED_BASE_PASS, exit 0. Tested Zlib SHA256:
Windows c4de9d1f47dc1ddb4c7e80e8f5618fdcd8f857f30acb0297930b3b0f06164bd9;
Linux 001dc008892ee4c0090f073d4df7b468751d44c8075b5c6664043447c1809ec3.
The fourteen-row golden SHA256 is
90d2855e2d199ecfb3a09efe6b0673b06a12118aff491bc38a57a0ee7020d206.

Current native-library package assembly also passes on both platforms. Linux
offline runtime-only execution reports LINUX_CURRENT_EXPORTED_GZIP_PASS:14,
WMA load and exact cache comparison, exit 0. Windows existing exported host
with the current DLL reports WINDOWS_CURRENT_EXPORTED_GZIP_PASS:14 and
MAIN_LOADED:OK, CLEAN_INSTALL_RUNTIME_EXIT:0, from an isolated install with
system-only PATH. These are current-library assembly checks, not new managed
exports or clean Windows machine evidence. Logs are under
f10-linux-godot-base-suite/current-gzip-package-runtime.log and
windows-current-gzip-package/runtime.log.console.txt in .omo/evidence.

## Current Linux link evidence (2026-11-14)

The actual Godot 4.6.1 .NET Linux host passes six File.symlink? cases through
the production Ruby wrapper and Unity handler: ordinary file false, ordinary
directory false, file link true, directory link true, dangling link true,
missing path false. Fixture objects are created with Linux ln -s inside a
disposable container. Marker LINUX_MANAGED_SYMLINK_PASS:6, exit 0; evidence:
`.omo/evidence/f10-linux-godot-base-suite/linux-symlink.log`.
Run `tools/test_linux_symlink.sh` in the retained Linux host image with the
repository read-only and the existing Godot output directory mounted.

This establishes Linux link behavior. The Windows true-symlink positive row
remains unverified because unprivileged creation returned Win32 1314; junction
and ordinary/missing Windows cases were measured separately. No macOS link or
ABI evidence is implied. Older entries below are chronological run notes.

Fixed Gzip oracle passes exit0 with mtime946684800 and all eight rows. Host
shared fixture reproduces NameError Zlib::GzipWriter in the existing native
extension owner. A separate native Gzip implementation track st_01a1d72d owns
only new gzip source/header files and isolated evidence; parent owns wiring,
tests and production deployment. No implementation is accepted yet and the
native owner remains red until the real family is delivered.

Checksum failed-owner replay completes NATIVE_EXTENSIONS_PASS, exit0 after
CRLF normalization; all six measured values match, and20 other base owners
were already passing. Gzip original basic oracle now returns write13/pos13,
closed flags true, metadata name/comment, gets first-line/lineno1/pos6,
remaining second-line/eoftrue, rewindpos0/fullpayload and corrupt
Zlib::GzipFile::Error. Original mtime=0 is replaced with current time; the
fixture now uses fixed946684800 for deterministic metadata acceptance.
Fresh original replay will pin that timestamp before a host implementation.

Combination build/deploy and managed-copy build pass. Full21-owner run has
one failure: new checksum comparison used raw CRLF against LF expectations.
All six actual values already match their measured references. The owner now
normalizes CRLF like the existing native/stream TSV checks; only that failed
owner is rerunning. Twenty remaining owners passed, no failed assertion was
waived. Original combine parity and Gzip family remain unverified.

CRC table/version increment verified after native and managed builds exit0:
host reports256,0,1996959894,755167117 and true version format, matching the
original. Existing43-row stream owner passes ZLIB_STREAM_PASS. The native
extension owner still fails four combine rows with NoMethodError; the shell
sequence's final exit0 belongs to the stream owner, not to the failing native
owner. No suite pass is claimed. Original zero-length combine cases are now
isolated to distinguish the length-dependent hang from method-wide failure.

Installed standalone Ruby control returns crc32_combine(1,2,5)=1029712306,
CRC1234+56789=3421780262 and AdlerWiki+pedia=300286872. This establishes an
independent standard-zlib reference but not RGSS300 parity; the original
zero-length probe is still pending. Do not replace its hang with this control
and count the original requirement complete.

Original zero-length crc32_combine also exceeds30s, so this local RGSS300
does not provide a usable combine return oracle. Standard Ruby zero-length
controls return2615402659/64618901. Missing host combination methods are now
implemented by the linked zlib primitives with a six-value regression labeled
by reference authority: table/version from RGSS300, combine from standalone
Ruby. Native build active. This supplies functional methods while F08 original
combine parity remains explicitly unverified; no original hang is imitated.

F08 remaining-family discovery now uses `zlib_family_reference.rb` on the
original to record module methods/constants and GzipFile/Reader/Writer direct
methods. This is a measured interface denominator only, not a passing behavior
test. Existing43-row stream results are settled. Original capture is active in
a fresh owned project; no Gzip implementation or support claim is added yet.

Original family discovery completes exit0: six module methods include missing
adler32_combine,crc32_combine,crc_table,zlib_version. Original GzipFile has12,
GzipReader28 and GzipWriter12 direct methods. Current native registration has
no Gzip classes and onlycrc32/adler32 among those six module methods, so full
F08 cannot be accepted from the stream ledger. A six-case original checksum
combine/table/version-format probe is active before implementation; Gzip
requires a separate bounded unit, not an implied capability from Zlib.gzip.

Original crc32_combine hangs before producing a row for both real CRC inputs
and low integers1,2,length5. No return-value contract is inferred. The remaining
five methods/cases now run independently, with a30-second owned-process
deadline that terminates only that fixture on timeout. Prior copied projects
and progress files remain evidence. F08 is open; host missing-method red remains
visible and is not suppressed to make the suite pass.

Independent table/version original run passes exit0: crc_table has256 entries
with samples0,1996959894,755167117 and zlib_version matches numeric three-part
format. Those two methods now delegate to the linked zlib's get_crc_table and
zlibVersion; native build active. Both combination methods remain unresolved:
their original calls hang, while host owner correctly reports NoMethodError.
Prior two surviving original processes were identified by exact owned paths
and terminated; all measurement files were retained.

Current measured result: 43 original/host streaming rows and the registered
21-owner base suite pass exit0 after native/managed builds and deployment.
This covers the discovered ZStream/Deflate/Inflate direct interfaces, including
positive sync, dictionary, buffers, params and lifecycle boundaries. F08 stays
open for broader native support and cross-platform/release evidence. Historical
investigation entries below retain the failed and pending-at-that-time steps.

Original runtime interface discovery completed: ZStream exposes 17 direct
instance methods, Deflate five and Inflate five. The observed remaining names
include buffer/capacity getters, flush_next_in/out, end/ended?/stream_end?
aliases, params and inflate sync/sync_point?. This inventory determines what
still needs behavioral evidence; its presence alone is not acceptance.
The shared thirty-row original run now measures the state/buffer cluster.

Original state cluster: ended?/stream_end? distinguish closed and finished;
initial avail_in/out=0/0 and data_type=2; flush_next_out drains append output;
flush_next_in is empty even when finish retains tail. Host returns NoMethodError
for all five new rows. Capacity consumption after setting 128 is being measured
before implementing its setter, so it cannot merely report an unused value.

Capacity replay pins 0,128,0 around compression. Native processing now uses
the requested output chunk capacity and consumes it on a call; aliases expose
existing finish/close state, getters expose native values, and flush_next_out
drains the owned append buffer. Native build active before thirty-row replay.

Native/managed build and deployment pass; thirty-row original state/buffer
comparison passes exit0. Aliases, initial type, buffer drain and capacity
consumption match. Base21 regression is active. Deflate.params and Inflate
sync/sync_point? remain the discovered direct-method gaps to measure next.

Final state/buffer TEST_SUITE_PASS:21 completes exit0. Original35-row
measurement is active for params success/error and inflate sync point,
missing marker and recovery across a FULL_FLUSH marker. No unmeasured sync
implementation is shipped before these outcomes are read.

First original params call raises StreamError despite a valid level; output
capacity was zero after a draining call. The probe now supplies capacity before
changing parameters. Sync recovery's final checksum raises DataError because
discarding the prefix changes Adler; its sync return and emitted payload are
now recorded separately rather than mistaking checksum failure for no recovery.

Original36 rows pin params success with capacity1024, StreamError without
capacity or invalid level; sync_point? false initially, missing marker false,
FULL_FLUSH marker true followed by checksum DataError. Host lacks all three
direct APIs. Native params now uses requested output space and retains any
generated bytes; sync/sync_point? delegate to persistent native state. Build
active before original36-row replay.

First host replay differs on zero-capacity params (succeeds) and sync recovery
(accepts payload without checksum error). Vendored zlib1.3.1 inflateSync
explicitly disables wrapper/check validation; upstream1.2.5 retains it
(https://raw.githubusercontent.com/madler/zlib/v1.2.5/inflate.c). The compatibility
sync path now retains wrapper validation, while params enforces the measured
output-space prerequisite. Native rebuild active. Prior21-owner run failed only
this new stream owner; twenty existing owners passed.

Corrected36-row replay now passes exit0: params without capacity raises
StreamError and recovered wrapped stream raises the original DataError.
Native/managed builds and deployment are green; final21-owner run active.
Vendored modification is identified in zlib-1.3.1/RGSS-COMPATIBILITY.md.

Final TEST_SUITE_PASS:21 exits0 after the36-row sync correction. Runtime
discovery confirms every original direct stream method is now callable via
its native class or base class. This is interface coverage only; positive
sync_point/raw recovery and reset capacity now extend the shared original
fixture to39 rows before claiming those branches.

Original39 rows exit0: raw marker recovery returns true,payload,true; reset
clears assigned output capacity to0. The supposed positive sync-point case
instead raises DataError on this runtime, so it does not prove the true branch.
Host comparison is active; the original exception remains part of the ledger.

Host39 rows red: reset retains128 (fixed at reset owner), while partial raw
SYNC_FLUSH returns payload,true where original raises DataError. Raw marker
recovery already matches. Before changing raw inflate, original compressed
bytes are being captured to separate compressor output from decoder semantics.

Raw compressed-byte probe also raises DataError in its ensure close, showing
the apparent sync failure may be unfinished-deflate cleanup rather than decode.
The corrected probe finishes the compressor before close and adds a separate
unfinished-close row. This retains the original failing close contract while
measuring the actual sync-point outcome independently; original run active.

Corrected original41 rows pass: raw bytes are2a48acccc94f4c01000000ffff,
actual sync point returns payload,true, and unfinished deflate close raises
DataError. Native close previously discarded deflateEnd's error status; now
it marks released state and propagates that status. Reset clears output
capacity. Build active before corrected41-row replay.

Corrected host matches new raw/sync/close/reset cases but zero-capacity params
row becomes DataError during ensure close, whereas original row was StreamError.
The fixture now records parameter error and subsequent close error separately
to determine original stream state after failed params rather than suppressing
cleanup errors. Original boundary run active; base suite fails only this owner.

Separated original row: params raises StreamError, subsequent close succeeds.
The inspected Ruby1.9.2 wrapper has unfinished-stream reset-on-close, but the
raw-close fixture contradicts applying that universally. New original probes
therefore compare wrapped close and continuing after failed params before
changing state semantics. No blanket error suppression/reset shipped.

Original43 rows establish wrapped unfinished close succeeds, raw unfinished
close raises DataError, and failed params can continue to native payload.
The host now remembers constructor window mode and resets unfinished wrapped
deflate before end, preserving raw error propagation and failed-params state.
Native build active before full43-row replay.

Corrected43-row host replay passes exit0, including failed params then continue,
wrapped/raw close distinctions, true sync point, raw recovery and all prior
dictionary/buffer/tail cases. Native/managed builds/deployment are green;
final21-owner regression active. Every measured original direct method now has
an executable path, while wider Zlib families/platform scope remain unverified.

Streaming dictionary extension: the original eighteen-row fixture now pins
set_dictionary return/bytes/adler, NeedDict recovery after the six-byte header,
wrong-dictionary DataError, and partial output under SYNC_FLUSH. Original
exits 0; the host red run is active. Existing fourteen rows remain unchanged.

The unchanged host returns NoMethodError for the three dictionary rows while
SYNC_FLUSH already matches. Native z_stream now exposes set_dictionary/adler,
and Z_NEED_DICT maps to the original NeedDict subclass so callers can supply
the measured dictionary and continue. Native build is active before deployment.

Native/managed builds, deployment and eighteen-row dictionary replay pass at
exit 0. The shared fixture now probes complete-input NeedDict recovery, trailing
input returned by finish, and the flush method itself. The current processing
path frees unconsumed input after a call, so its behavior must be measured on
these cases before claiming general dictionary recovery. Original run active.

Original 21 rows exit 0: after complete-input NeedDict, supplying the dictionary
then inflating an empty string returns empty and unfinished. The original does
not retain that compressed remainder in this case, so no speculative input
retention is added. Trailing bytes instead are returned by finish (payload,tail),
and flush(SYNC_FLUSH) exposes partial output. Host red replay is active.

Host red replay confirms two defects: finish loses tail bytes and flush is
missing. NeedDict remainder behavior already matches. Stream end now stores
unused trailing bytes as a rooted Ruby string and finish drains it; reset
clears that state. Deflate.flush feeds the existing native processing path
with the requested flush mode. Native build is active before actual replay.

Native build/deployment, managed-copy build and the full 21-row stream replay
now pass exit 0, including dictionary compressed bytes/checksum, NeedDict
recovery, wrong dictionary, flush and tail output. The 21-owner base suite is
active. These cases do not establish block constructors, append buffering,
later input after stream end or every ZStream method; F08 remains open.

The final base regression completes TEST_SUITE_PASS:21 exit 0. A new original
25-row run measures append-buffer ownership, input supplied after stream end,
and block-open return/automatic close before implementing those missing paths.

Original 25 rows exit 0. Append returns the same stream and finish drains
buffered compressed/decompressed output. Later input after completed inflate
appends to its tail (firstsecond). Deflate.open itself raises NoMethodError on
the local RGSS300, so no unmeasured block-open API is added. Host red replay
is active for the supported append and tail paths.

Host red replay confirms both append methods absent and later tail replacing
first with second. Native append now retains produced output in a rooted
buffer until a draining call; completed inflate collects further tail bytes
without re-entering zlib's ended stream. Finish drains both output/tail and
reset clears them. Native build active; original open NoMethodError preserved.

Native and managed builds, deployment, and full 25-row stream replay now pass
exit 0. Both append-return identity and buffered output match, later tail is
firstsecond, and the original missing open API remains missing. Final base
regression is active. This closes the measured defects, not all native support
or cross-platform delivery requirements.

Final TEST_SUITE_PASS:21 completes exit 0 with the expanded 25-row stream
owner and existing native extension/Marshal contracts. clangd remains unavailable;
actual native compiler and runtime checks passed. No repository commit created.

The shared `zlib_stream_reference.rb` now pins seven original streaming
contracts: chunked deflate/inflate, explicit finish, truncated finish BufError,
reset, closed state, and use after close Error. Original execution exits 0;
the unchanged host returns NoMethodError for all seven. Stream objects had no
native initialization or per-instance state, so class-only functions could
not support these callers. The implementation now owns a persistent z_stream
through mruby Data, with close/GC cleanup and the measured state methods.
Native build and actual comparison are pending; this is not full Zlib API
acceptance. Ruby/GDScript/clangd diagnostics are unavailable locally.

The native and managed builds, DLL deployment, and actual seven-row host
comparison now pass at exit 0. The new stream owner joins the headless suite.
All seven unchanged-host NoMethodError rows now match the original values and
error classes. Broader stream methods (dictionary, flush, append, trailing input
and block constructors) still need their own original measurements; F08 stays
open. The registered 21-owner regression is the next check.

The registered seven-case regression completed TEST_SUITE_PASS:21, exit 0.
The shared fixture then expanded to fourteen original rows: 28,000-byte
multi-buffer output, nil finish, complete inflate finish, inflate reset,
double-close Error and both invalid initialization StreamErrors. The original
fourteen-row run exits 0 and is pinned; its host comparison is active. The
separate owned original directories preserve both baseline runs.

The host fourteen-row comparison passes ZLIB_STREAM_PASS, exit 0, including
all new large-output and lifecycle error boundaries. No production changes
were needed after the seven-case implementation. The final 21-owner run with
the expanded fixture is active. F08 is still open for unmeasured stream APIs
and cross-platform dependencies; this evidence establishes these fourteen
public contracts only.

Final expanded TEST_SUITE_PASS:21 completes at exit 0. Native and managed
builds, fourteen original stream rows and the existing 26-row native extension
owner are green in that run. No repository commit was created.

F08 remains open. The local host loads Marshal, Dir/Glob, Onigmo Regexp and
Zlib extensions. Marshal has separate accepted F04 owners. A shared nine-row
RGSS300/host fixture now measures Zlib roundtrip/CRC32/Adler32 and Regexp
lookbehind, capture arrays, replacement backreferences, scan, match position
and ignore-case. Original isolated execution is active before host comparison.

This tests the bundled public Ruby capabilities, not arbitrary MRI C extensions
or ABI compatibility with every third-party gem. Cross-platform native builds
and release dependency evidence remain F10. Ruby LSP dependencies and GDScript
LSP are unavailable locally; runtime parsing will provide the executed checks.

Original nine rows complete at exit0 and are pinned in a permanent TSV.
Initial host returns NameError for MRI Zlib::Deflate/Inflate classes,
four-byte binary string for crc32 instead of3421780262, and NoMethodError
for adler32. Source confirms bundled gem exports lowercase deflate/inflate
and binary crc32 only. Regexp initial NameError was a probe bootstrap omission;
the actual ext/onig_regexp wrapper is now explicitly required before replay.
No native API replacement is made before separating that setup error.

After the wrapper loads, all six Regexp rows match original; the three Zlib
rows still fail. Source-level correction now exposes class deflate/inflate
methods using existing native implementations, changes crc32 to the original
integer checksum with optional integer seed, and adds native adler32. No
current internal caller uses binary crc32. Native build is active; unavailable
clangd is recorded rather than suppressing diagnostics. Full stream-instance
Zlib APIs and compression-level options are not claimed by this correction.

Original incremental CRC32/Adler32 rows also match the whole-string reference
checksums, expanding the permanent ledger to11 rows. The Windows cmd path
attempt opened an idle shell instead of executing the script; it was stopped
and the script is now called explicitly through PowerShell. No successful
native build or deployment is claimed from that idle session.

PowerShell script invocation completed native build at exit0. The verified
134144-byte release Zlib DLL was copied to Plugins/windows at exit0; managed
build is active to refresh the Godot output copy before11-row replay.

Managed build and actual11-row host comparison both pass at exit0. Native
CRC32/Adler32 whole/incremental values now match original exactly, class
roundtrip and six Regexp cases pass. Owner joins the headless suite. The
pre-registration18-owner native regression run remains active. F08 stays
open for Dir/Glob and the wider documented extension support boundary.

The pre-registration18-owner native regression passes at exit0. The shared
fixture now includes four real filesystem Glob cases (star, recursive txt,
brace alternatives, dotmatch), expanding the permanent original ledger to15.
Original completes exit0; host with actual dir_glob/dir wrappers is active.

Host star/brace/dotmatch match original but recursive Glob raises NoMethodError.
The fixture now records the exact message/backtrace separately, retaining the
15-row comparison failure; source recursion depends on File.lstat and stat
directory predicates. No replacement before the missing method is confirmed.

Exact exception confirms File.lstat is unavailable at ext/dir_glob.rb:88.
This is a shim dependency gap, not broken pattern matching. Direct directory
and symlink predicate availability is being measured before removing the
lstat dependency while preserving recursion's non-following link behavior.

Runtime confirms File.directory? and File.symlink? exist, File.stat does not.
Both recursive paths now use directory? && !symlink? instead of nonexistent
lstat.directory?, retaining the traversal's link exclusion. Start recursion
also consistently respects its existing dotmatch flag at deeper levels. Shared
15-row replay is active; no native rebuild is needed for this Ruby shim fix.

The predicate replay exposes a second platform gap: File.symlink? exists but
raises NotImplementedError on Windows. A real filesystem binding now queries
FileAttributes.ReparsePoint, returning false for missing paths, and the loaded
Dir wrapper supplies File.symlink? through that binding. This handles link
classification at its platform boundary instead of catching and ignoring link
errors in the traversal. C# diagnostics clean, managed build active.

Managed build and15-row original comparison pass at exit0 after the file
predicate correction. Unified19-owner headless regression is active. F08
remains open: actual link traversal, fuller Zlib stream/option APIs and release
dependency scope are not established by these15 cases.

Unified headless TEST_SUITE_PASS:19 completes exit0. The shared fixture adds
ordinary/missing symlink? values and relative-start recursive Glob to exercise
the second recursive implementation; original baseline run is active.

Original and host18-row ledgers pass at exit0, including regular/missing
file symlink? false and relative recursive Glob a.txt,nested/c.txt. Actual
reparse-point traversal remains unverified; ReparsePoint may include Windows
junctions in addition to symbolic links, so this boundary is not yet accepted
as full File.symlink? parity.

Actual isolated Windows junction probe reports original symlink? false and
traversal junction-probe/c.txt. Therefore the broad ReparsePoint classification
was incorrect. Windows now reads the actual find-data reparse tag and reports
only IO_REPARSE_TAG_SYMLINK, closing its find handle in finally. Diagnostics
clean; build active. A PowerShell entry creates the owned junction and runs
the extra two rows; the normal portable owner retains18 rows when absent.

Managed tag-query build completes exit0. First conditional-junction fixture
had its array closing bracket after the new if block and failed parsing; that
fixture syntax error is corrected and20-row replay is active. Production
classification remains unchanged during this test correction.

Real-junction20-row comparison passes NATIVE_EXTENSIONS_PASS, exit0. The
Windows query distinguishes junction from symlink exactly like original for
the measured junction and traversal. Final19-owner regression is active.
Actual symbolic-link positive case and broader extension APIs still remain
unverified, so F08 is not marked complete.

The shared Zlib ledger is extending to truncated/corrupt compressed data and
invalid compression level. Current native inflate breaks on truncated input
and returns partial output instead of a terminal stream status; original error
types are being measured before changing that behavior.

Original truncated/corrupt/invalid-level cases raise Zlib::BufError/DataError/
StreamError. Host returns the full decoded payload for a truncated stream and
generic RuntimeError for the other two. Native inflate now frees its buffers
and raises BufError on unfinished terminal stream; Zlib Error subclasses map
native statuses to original exception classes. Build active before deployment.

First replay returns TypeError allocation failure of each Zlib subclass.
New native exception classes require MRB_TT_EXCEPTION instance tags; simply
subclassing StandardError through the C API did not set the required type.
Those tags are now explicit, matching host exception initialization. Native
build active; the unified20-owner run only fails this new owner,19 others pass.

After instance-tag correction, BufError is raised but rescue StandardError
does not catch it. The fixture now records actual class ancestors and the
StandardError subclass relation before the failing row, to distinguish wrong
native superclass from a rescue implementation issue. No test rescue scope is
broadened to conceal this failure.

Actual ancestry is BufError,Error,Object,Kernel,BasicObject: native
E_STANDARD_ERROR field access produced Object under the loaded host ABI.
Error now obtains StandardError through exported mrb_class_get rather than
direct mrb_state layout access. This fixes the observed wrong superclass;
native build active. Wider host-header ABI consistency remains an F08 finding.

Correct public StandardError query yields original BufError/DataError/StreamError
and the26-row comparison passes exit0. Native/managed builds and deployment
are green.20-owner regression is active. Direct-field cause remains a host
ABI/configuration mismatch candidate; the observed wrong ancestry is proven,
but the exact layout delta is not yet established.

Final unified TEST_SUITE_PASS:20 completes exit0. The26 original rows,
including corruption/truncation/invalid-level failure classes, are settled.
Full streaming-instance APIs and host-header ABI provenance remain unverified,
so F08 is still open.

Read-only provenance check: bundled host DLL embeds mruby4.0.0 and SHA256
8a0058cc1e0a9fc3433c47ed4f0d918fd442c4c7404ed37f2d375edbf00cd0bd;
local extension headers also declare4.0.0. Same version alone cannot prove
mrb_state layout compatibility. Config fields before eStandardError include
method-cache and optional symbol/debug layout; exact loaded build flags still
need an executable ABI probe rather than version inference.

Native probe using actual bundled DLL confirms header eStandardError offset18784
does not equal the class from public API; the expected pointer is absent in
the scanned earlier region. Header method cache is256; source/build headers
are byte-identical. Probe now compares Object/Class/String/Exception fields to
locate the layout divergence before selecting a host-header/build correction.

Object/Class/String field checks match; Exception/StandardError do not. The
layout divergence is after fundamental class fields, before error classes.
GC gray-stack and method-cache arrays occupy this region. A configurable
owned ABI probe is testing one explicit gray-stack-size hypothesis; production
defines are unchanged while its runtime pointer match is unproven.

The widened probe locates actual StandardError at18800,16 bytes later than
the unconfigured header. Gray-stack2048 is not a match. Two optional debug-hook
function pointers explain exactly16 bytes; a debug-hook-configured probe is
active to confirm pointer equality. No production define changed before proof.

Debug-hook probe passes: header/actual StandardError18800 match, Object/
Class/String/Exception all match. Actual Windows host therefore has the two
debug-hook fields, absent in extension builds. All four xmake targets now add
MRB_USE_DEBUG_HOOK on Windows only; other unmeasured platform defines are
unchanged. Full native ABI rebuild is active. Lua/clangd diagnostics unavailable;
actual compiler and runtime acceptance will provide the checked evidence.

All four native rebuilds, deployment and managed-copy build pass exit0;
26-row original Zlib/Regexp/Glob owner passes after ABI alignment. Unified
20-owner regression is active, including Marshal original values/links owners.
The16-byte direct-error-class divergence is now explained by the proven debug
hook configuration, rather than treated as an unexplained header version issue.

Final TEST_SUITE_PASS:20 completes exit0 after all four Windows ABI-aligned
DLLs are deployed. Compiler experiment track is informed that any replacement
host must preserve MRB_USE_DEBUG_HOOK; full Zlib streaming-instance APIs and
other-platform ABI/release coverage remain outside these measured owners.

Final headless suite completes TEST_SUITE_PASS:19, exit0. Creating a true
symbolic-link positive fixture fails with Administrator privilege required
under this session. The attempted setup is withdrawn; no elevation is taken
and no unmeasured positive-link expectation is retained. Ordinary files,
missing files and real junction classification/traversal are verified; actual
symbolic links remain an external permission gap.

Original Zlib empty roundtrip and level0/9 compressed bytes are captured,
extending the base ledger to21 rows (23 with junction). Current native class
method accepts only one argument, so host level-param reproduction is active
before extending the existing deflate implementation.

Host empty roundtrip passes but level0/9 both raise ArgumentError. Existing
native compression now parses an optional integer level and passes it directly
to deflateInit2; the class-method arity permits that argument. Native build is
active before deployment and exact original compressed-byte comparison.

Native level build and plugin DLL deployment complete at exit0. Managed build
is active to copy the updated library into the actual host output directory.

Managed build and23-row original comparison pass at exit0, including exact
level0/9 compressed bytes and empty roundtrip. Final19-owner regression is
active. F08 remains open for broader Zlib stream instances, other native
support boundaries and true symbolic-link positive evidence.

Final TEST_SUITE_PASS:19 completes exit0 after the optional-level library
update. All23 measured original rows are settled. Compiler and original-SE
signal children remain running; no new result is inferred from their status.
