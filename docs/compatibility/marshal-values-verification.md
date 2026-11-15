# Marshal numeric and custom-state values

Acceptance on 2026-11-13: F04's measured serialization and encoding
contracts pass. The final 20-row values fixture matches original output,
including positive/negative 2^100, Struct self-reference, and Hash
self/default-reference identity. Links (8 rows), metadata/copy (10 rows),
frozen encoding (3 rows), and IO/depth (7 rows) pass in the new-DLL
headless suite. Original/host payload reads pass both ways, as do actual
RPG save interchange and windowed save/load UI. Original binary goldens
are permanent files under tests/fixtures. This acceptance covers these
contracts; broader Ruby String and Encoding operations belong to F05.

F04 original14-row value probe completed exit0: signed32-bit boundary and
2^40 integers roundtrip exactly, signed zero and infinities remain, Hash default7
survives, repeated marshal_dump/marshal_load object preserves value42 and
identity. Goldens are in tests/fixtures/marshal_values_original.tsv; host same
fixture comparison is active. These rules supplement links/encoding/IO contracts.

Headless unified16-entry suite passed after prior encoding changes. Full
rendered/event suite is active for the default Sprite/creation-order correction;
F03 has one unresolved intermittent resource count failure despite the latest
matching counts and independent list images passing. No failure is hidden.

Host probe failed before fix: 2147483648 became -2147483648,
-2147483649 became 2147483647, and 2^40 became 0. Float rows passed.
Hash.new(7) then raised TypeError: can't dump hash with default.
Windows long is 32-bit while host mrb_int is 64-bit. The writer forced all
integers through FIXNUM, and both Hash default branches rejected the value.

The writer now uses the original 30-bit FIXNUM range and little-endian
16-bit BIGNUM words for larger host integers. The reader checks the signed
host range and enters BIGNUM values in the object table. Hash default values
are serialized and restored through the public API. Native build exited 0.
clangd is unavailable; no C LSP result is claimed. The new DLL has not yet
replaced the shared DLL while the full suite is running.

Expanded isolated original probe passed 17 rows at exit 0, including
signed int64 minimum/maximum and repeated BIGNUM payload followed by strings.
Original binary is preserved in the int64 fixture directory. Host replay of
the rebuilt DLL remains pending until the full rendering suite exits.

The full rendering/event regression suite completed TEST_SUITE_PASS:65,
exit 0, including default draw order and actual save/load UI. This checks
the Sprite Z and creation sequence changes; it used the previous Marshal DLL.
The newly built Marshal extension has now been copied to Plugins/windows.
The host build is active to copy it to the Godot output before value replay.

Host build exited 0, but the deployed replay still showed the old integer
truncation and failed. Build output, Plugins DLL, and Godot output DLL had
the same SHA-256 96dccaa77c26cbce973571ee6799aa9bdf006d1112120e538eb4935f604a18cd.
The reported native build success therefore does not establish that the
changed C sources were compiled. Actual xmake input/output remains to be
diagnosed. F04 is not accepted.

The verbose rebuild identified the deployment cause: xmake linked to
`../build/windows/x64/release/` relative to mruby-ext, meaning the project
root `build/` directory. The previously copied `mruby-ext/build/` DLL was
old. Actual new DLL SHA-256 is
`cfc47e486ad41078e3d4971f27bc96126dcd7f8bcdf1219832c307f194f798dd`.
The compiler transcript names both changed dump.c and load.c, and build
exited 0. The actual new artifact is now deployed; host copy build is active.

Actual new DLL replay now preserves all seven initial integers, including
2^40. It then fails at int64 maximum with TypeError: can't dump Integer.
Host word boxing has both immediate FIXNUM and heap INTEGER representations;
`mrb_fixnum_p` includes only the first, while `mrb_integer_p` includes both.
The writer now tests `mrb_integer_p` before calling `mrb_integer`. Native
rebuild is active for this separately reproduced boundary failure.

Heap INTEGER fix allowed int64 maximum. The negative minimum literal is
represented as MRB_TT_BIGINT by this host, and still failed the writer type
dispatch. Public `mrb_as_int` uses the host's checked Bigint conversion;
the writer now recognizes that representation too. Values outside signed
host range remain an explicit RangeError rather than being truncated.
The build script now pins the project-root build directory to prevent
copying a stale similarly named artifact again.

The `-P` invocation also resolved build paths relative to its caller when
configured from the project root. The final build entry now changes working
directory to mruby-ext before configuring `-o build` and invoking build.
The observed link output is `build/windows/x64/release` within mruby-ext,
matching the documented deployment path. Both source compilation and link
completed at exit 0; this actual output is deployed for the next replay.

Public host Bigint-to-int conversion also rejected the negative minimum
with RangeError. The attempt is superseded: BIGINT dump now obtains the
integer's hexadecimal digits through its public API and writes 16-bit words
without narrowing. BIGNUM load converts those digits through String#to_i(16),
which uses the host's arbitrary-precision integer implementation. Immediate
and heap machine integers keep the direct numeric path. This removes the
unproven signed-host-range restriction rather than adding a minimum-value
special case. Build and unchanged original comparison remain pending.

Final actual-DLL replay completed MARSHAL_VALUES_PASS, exit 0: all 17
original rows match, including both int64 extremes, Hash default7,
marshal_dump/marshal_load identity and BIGNUM links. Host reads the original
payload, and the original reciprocal run reads the host payload and completes
the same 17 rows at exit 0. The new DLL also passes the unified headless
suite TEST_SUITE_PASS:17, exit 0, including links, encoding metadata and IO.
Actual RPG save-interchange regression is active in windowed mode. These
measured contracts do not claim the complete Ruby Encoding API.

Actual RPG save replay completed SAVE_INTERCHANGE_PASS at exit 0, and the
original read the new host Save1.rvdata2 at exit 0. Windowed save/load UI
also completed SAVE_SLOTS_PASS, resources (5,11,7) -> (5,11,7).
The original BIGNUM payload is now preserved as
tests/fixtures/marshal_values_original.hex, following the existing link
fixture convention. Its independent replay is active; future suite runs
will not require the temporary original fixture directory.
