# F08 Gzip production integration

Expanded original reader-encoding oracle now contains nine rows. It accepts
lowercase utf-8, US-ASCII and UTF-8:ASCII-8BIT/internal ASCII-8BIT with measured
byte boundaries, but rejects the BINARY alias. The prior four-row implementation
fails five new rows on the production owner. Encoding-name normalization and
internal selection are corrected in source. Candidate build, deployment after
the F11 soak exited, and managed build pass. The actual Godot native owner
matches all nine original rows at exit0, retaining the allocation and eight
file/metadata checks. The updated unified base regression completes
TEST_SUITE_PASS:22, exit0.
The completed F11 soak used the preceding library version.

The Gzip unit is wired internally at the end of mrb_mruby_zlib_gem_init;
the existing source glob compiles gzip.c, gzip_reader.c and gzip_writer.c.
No extra exported entry point is required. Production native build and managed
copy build both exit0; prior Zlib DLL is retained under
`.omo/evidence/zlib-gzip-production/`.

The original eight-row ledger from
`.omo/compatibility-run-tmp/f08-gzip-fixed-original/gzip_reference.tsv`
is now pinned in tests/fixtures/gzip_original.tsv and compared by the existing
native-extension owner. It covers metadata, byte position, line/rest reads,
rewind, close and corrupt-header classification. Actual Godot replay completes
NATIVE_EXTENSIONS_PASS, exit0. The complete updated HEADLESS_TESTS set then
completes TEST_SUITE_PASS:22, exit0, including defined? and Marshal regressions.

The implementation unit independently passed 215 candidate checks and 26 host
Ruby checks in split and internally wired DLL candidates; detailed output is
in `.omo/compatibility-run-tmp/f08-gzip-worker/EVIDENCE.md`. These checks do not
establish another platform or replace the production-host run.

F08 remains open. Windows x64 is the only compiled platform; true symlink
positive coverage still needs an appropriate Windows execution environment.
The GzipFile.allocate discrepancy and measured reader encoding options are
now corrected. Wider encoding conversion remains unverified,
and original trailing/concatenated-member inspection crashed rather than
providing a stable parity oracle. The complete limitations are preserved in
the implementation-unit evidence and are not counted as passed contracts.

The allocate discrepancy has a concrete original oracle:
`original-edge/gzip_edge.tsv` row gzipfile-allocate reports
TypeError:allocator undefined for Zlib::GzipFile. Before correction the
implementation only raised from initialize, so inherited Class#allocate
bypassed it. This public class-allocation contract is now covered by the
passing native owner, separately from the file IO and streaming rows.

Production reproduction of the allocation row now fails in the native owner:
GzipFile.allocate accepted an abstract stream. The mruby allocator checks
MRB_UNDEF_ALLOCATOR_P before creating an object, so GzipFile registration now
sets the native MRB_UNDEF_ALLOCATOR flag. No replacement Class#allocate method
is added. The regression retains normal Reader/Writer allocation assertions.

The mruby class constructor explicitly inherits MRB_FL_UNDEF_ALLOCATE.
Reader/Writer registration therefore also uses MRB_DEFINE_ALLOCATOR to restore
their concrete class allocation, following the VM's native class contract.
The first base-only build was preserved separately and was not accepted as
production green. The corrected build and actual owner replay pass below.

The allocator replay completes NATIVE_EXTENSIONS_PASS, exit0, including the
abstract-base error and concrete Reader/Writer allocation. The next original
probe measures four reader encoding cases: default and UTF-8 return e38182,
Windows-31J raises ArgumentError, and ASCII-8BIT returns one byte e3. Production
initially rejects every option hash, reproducing two failures against this
oracle. Reader open/initialize now accept the options hash and getc uses byte
boundaries for binary mode; UTF-8 retains the existing character path.
The four original rows are pinned and compared by the native owner. Native
build and managed copy both pass. The actual Godot owner completes
NATIVE_EXTENSIONS_PASS, exit0, comparing all four encoding rows and retaining
the allocator and eight-row file checks. No encoding compatibility claim is
made beyond these measured rows.

The updated base regression completes TEST_SUITE_PASS:22, exit0 after both
allocator and reader-encoding fixes. These checks are settled for this build.
F08 true-symlink positive evidence remains separate: an owned Windows probe
now tries CREATE_SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE without elevation
or any system-setting change, to check whether this machine can supply it.

The unprivileged Windows create call fails with Win32 error1314
(ERROR_PRIVILEGE_NOT_HELD), exit1. No link was created. The positive symlink
contract still needs a host with the required existing privilege or developer
mode; neither elevation nor a settings change was attempted. The original
file/missing-path and junction-negative contracts remain valid and separate.
