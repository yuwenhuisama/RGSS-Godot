# Binary File IO encoding

The Linux guest base suite exposed a timestamp-sensitive Gzip fixture failure:
CRC corruption raised DataError during read, and length corruption raised
CRCError at close. Production native libraries and the fixture had identical
hashes to the clean Release that passed. The difference was binary File input:
37 gzip bytes returned UTF-8 with String.size 36 and bytesize 37. The mtime
header contained a UTF-8 pair, shifting byte offsets derived from String.size.
The checksum classification goldens were not changed.

A fixed `c3a900ff` regression in `test_kernel_file_lifecycle.gd` fails before
the repair with `binary read encoding changed`. The same shared Ruby fixture
was then measured on RGSS300 in the Windows guest:

- `rb` full read: ASCII-8BIT, size/bytesize 4.
- `r` full read: UTF-8, size 3 and bytesize 4.
- Explicit lengths 4 and 0 without an output buffer: ASCII-8BIT in both modes.
- `rb.read(4, buffer)` preserves the supplied UTF-8 buffer and its identity.
- `rb.sysread(4)`: ASCII-8BIT, size/bytesize 4.
- Integer `File::RDONLY | File::BINARY` full read: UTF-8, size 3 and bytesize 4.
  This was measured separately on RGSS300 after a review suggested the opposite.
  The original result governs this compatibility implementation.

The eight original rows are `tests/fixtures/file_binary_original.tsv`.
The shared fixture is `file_binary_reference.rb`, owned by the existing file
lifecycle runner. The repair lives beside the existing String encoding support
in the Marshal native extension: IO initialization retains binary mode, while
read/sysread tag returned strings according to the measured mode, length and
buffer contract. Underlying IO and byte transfer remain the existing methods.

The Linux candidate passes all eight original rows, the previously failing
Gzip integrity owner, and the complete 22-owner base suite at exit zero.
Evidence: `.omo/evidence/file-binary-native/`. The Windows candidate builds
successfully with the existing MRB_USE_DEBUG_HOOK ABI definition. Both Windows
guest owners pass with explicit process exit zero: KERNEL_FILE_LIFECYCLE_PASS
and NATIVE_EXTENSIONS_PASS. Both verified native binaries are deployed to
production; prior binaries are retained in the evidence directory.

Linux SO SHA-256:
`946349608f29773f187de295902dea319bb34b217641e3866188b8f518003183`.
Windows DLL SHA-256:
`6f5528cb27c6d26249f8525db06b1f7082de5d88d491c4dd5991d9f5cde2c44c`.
The first current-source export `linux-midi-binary-io-release` fails in Godot's
MSBuild publish stage; the export subsequently stores a PCK but lacks the .NET
payload. This is not a usable package. The exporter now preserves the private
MSBuild logs and fails at that stage explicitly. The fresh export under
`linux-file-io-nine-release` completes at exit zero and passes offline WMA
decode/relocation. The same package passes the native owner, including all nine
File encoding rows, Gzip integrity, extensions and Marshal, at exit zero in
`linux-file-io-nine-release-native`. It also passes all three MIDI fixtures,
bank/license equality and exit without ObjectDB leak warnings in
`linux-file-io-nine-release-midi`. Archive SHA-256:
`f2dd11363bd21b0da087f0a4d08026baa758e2323f18aef07e2f7335167c7e8a`.
macOS execution remains unverified.

Latest Windows combined Release runtime also passes in the installed guest,
under a system-only PATH, no DOTNET_ROOT/MRUBY_DIR/decoder override and an empty
working directory. Native/File and all three MIDI markers complete with actual
process exit zero; no runtime ObjectDB warning is present. Evidence:
`windows-midi-file-io-release/guest-{receipt.json,console.log,runtime.log}`.
That package's editor export completed publishing/storage but hung during exit
and was stopped (wrapper exit -1); this remains a failed export-exit verdict,
separate from the successful installed runtime. Its measured native payload
matches production. A no-export editor control with two frames exits zero but
retains a SceneTreeTimer; GUT's _enter_tree waits one second. A 120-frame/60 FPS
control exits zero without ObjectDB warnings. The actual export with that frame
budget now also exits zero and completes installation assembly in
`windows-midi-file-io-release-settled`. It still reports an editor ObjectDB
warning, so that warning is not claimed fixed and is distinct from the clean
runtime. The executable, PCK and all 217 data-directory files are byte-identical
to the previously guest-verified package. No runtime replay is needed for those
identical inputs. The result establishes a successful export exit under the
revised invocation, not a fully diagnosed fix for every editor-exit issue.

Follow-up review found the initial integer-mode branch incorrectly assumed the
operating system O_BINARY flag defined Ruby encoding. The ninth original row
above rejects that assumption. The branch is removed; the final candidate
passes the Linux nine-row comparison and all 22 base owners at exit zero.
Windows nine-row and native-extension owners also pass at explicit exit zero;
the final DLL is deployed. Final logs are under `file-binary-original-mode-native`.
The final Windows base-suite replay passes21owners and fails only the defined?
owner because its two `tools/defined-compiler` fixture files were absent from
the copied guest project. The exact failing log is retained as
`windows-base22-before-defined-sync.log`. After synchronizing the production
77-row fixture, only that owner is replayed and passes DEFINED_RUNTIME_PASS:77
at exit zero (`windows-defined-after-sync.log`). Together the two logs cover
all22owners on the final Windows library. The initial suite failure remains
visible; no single all-green suite invocation is fabricated.
The initially built intermediate File::BINARY-based
candidate is retained as a rejected experiment and was not deployed.
