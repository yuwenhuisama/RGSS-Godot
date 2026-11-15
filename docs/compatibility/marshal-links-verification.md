# Marshal links and string bytes

F04 remains open. Shared `marshal_links_reference.rb` measures shared-array
identity, a self-reference cycle, repeated custom _dump/_load object identity,
UTF8 and arbitrary binary bytes, the same links through File IO and two invalid
Marshal inputs. Original run is active. Existing seven-row IO/depth contract
has already passed, but it does not establish these object-link behaviors.

Original completed8 rows exit0: shared array, cycle, repeated custom object
and file links preserve identity; UTF8 e4b8ade69687 and binary00ff80 survive;
both invalid streams raise ArgumentError. Normalized SHA256
03218f85c239ab7af9296e4b58f8b4a18470095571422cb45f7aa43f0c8f032b.
Host same-fixture comparison is active; no production Marshal edit yet.

Host MARSHAL_LINKS_PASS exit0: all8 original link/string/error rows match.
Registered headless. Cross-engine reading of emitted payloads, symbol/hash
links and string encoding metadata remain separate F04/F02 verification;
this result does not claim complete Marshal compatibility.

Cross-engine payload reads completed in both directions: original exit0 reads
host payload and confirms shared-array/cycle/custom identity plus exact UTF8
and binary bytes; host MARSHAL_LINKS_PASS exit0 reads the original payload and
the same five rows match. These temporary payloads need permanent fixture
capture before cleanup. A separate original metadata probe is active for
symbol/hash identity and UTF8/ASCII-8BIT/Windows-31J encoding preservation.

Original metadata first timed out after UTF8 and ASCII-8BIT rows. Exception
capture identified ArgumentError unknown encoding name Windows-31J in this
RGSS300 baseline. Revised fixture records that unsupported name explicitly;
original run completed exit0. Symbol/hash links and the two supported encoding
names/bytes passed. Host metadata comparison is active; no encoding shim added.

Host metadata exited1: symbol/hash identity passed, but all three encoding
operations returned NoMethodError. No String#force_encoding/encoding layer
exists under RGSS. Native marshal dump/load sources contain commented encoding
handling; their behavior needs inspection before adding methods, because a
method-only shim would leave encoded Marshal interchange wrong. F04 remains
open on this measured runtime/serialization gap; no placeholder shim shipped.

Native implementation now records string encoding in one internal string ivar.
Dump writes UTF8 E=true, US-ASCII E=false, and unwrapped ASCII-8BIT; load
retains the marker and defaults unwrapped strings to ASCII-8BIT. String
force_encoding/encoding and Encoding#name use that same state for the measured
names. Unknown names raise ArgumentError. This is metadata preservation, not
transcoding or a complete Encoding API. Native build is active; no deployed
binary or green verification yet. clangd is unavailable locally, so compiler
output remains the required native diagnostic evidence.

Initial xmake invocation failed to locate cc outside the Visual Studio
environment. The installed VS2026 vcvars64 environment is now used through
tools/build_marshal_encoding.cmd; no new compiler was installed. A cmd launch
with forward-slash path failed before execution and was replaced with a quoted
Windows path. Native build result is still pending, not counted as success.

Actual compile reached all three C units, but link failed because xmake
autodetected Git's MinGW platform while using MSVC tools, omitting the Windows
host-library branch and emitting an invalid machine option. Build script now
pins -p windows -a x64 --toolchain=msvc along with cl/link. Correct-platform
build is active; all link errors from the failed attempt remain recorded.

Build succeeded but initial deployment used a stale DLL from mruby-ext/build.
Actual current xmake output is root build/windows/x64/release,64000 bytes,
SHA25665d1c1f3222ef3b67a9f4b473446e2c7994187ed1a3eb14527098a9d6890c003,
and contains force_encoding. Stale62464-byte library produced the same missing
method red result; it was not a failed encoding implementation verdict.
Correct output deployment is active, followed by host-copy and same tests.

Correct DLL execution failed with cannot set instance variable: mruby String
has no ivar storage. The ivar approach was withdrawn. Host RString already
provides MRB_STR_BINARY, used by UTF8 character/byte traversal; encoding
methods and Marshal now use that existing flag for UTF8/ASCII-8BIT, with no
global strong-reference table. US-ASCII is not claimed by this two-state
implementation and needs independent handling if required. Build is active.

Binary-flag implementation MARSHAL_METADATA_PASS exit0 for the six original
rows. It emitted real UTF8/ASCII-8BIT payloads; original cross-read is active.
Loaded15 database canonical regression also passed exit0 after the new DLL.
This verifies the measured two encoding states, not Encoding identity,
transcoding, US-ASCII metadata or all string operations.

Original US-ASCII follow-up completed exit0 and preserved nameUS-ASCII plus
bytes616263. The two-state binary flag implementation cannot satisfy that
third encoding state. Host flags include a single-byte optimization cache,
which cannot safely double as a US-ASCII marker; further state design must
also preserve encoding through String copy operations. F04 remains open.

Original copy rows confirm all three names/bytes survive dup. The extension
now keeps explicit encoding on the string's own singleton class, which has
ivar storage and follows the object's lifetime, rather than a global table or
unreserved RString flag. Standard E true/false/absent wire markers map to
UTF8/US-ASCII/ASCII-8BIT. initialize_copy delegates to the original copy then
copies encoding state. This implementation is being compiled and remains
unverified for runtime, copying and frozen-string behavior.

Three encoding states plus dup completed all10 original rows,
MARSHAL_METADATA_PASS exit0. Link/interchange regression passed again exit0.
Original reads all three new encoding payloads with correct names/bytes and
measures frozen-queryUTF8, frozen-changeRuntimeError, frozen binary roundtrip
ASCII-8BIT. Host frozen-boundary replay is active before this approach is
accepted. No transcoding or broader Encoding API claim is made.

Frozen host replay differed only at error class: host FrozenError versus
original RuntimeError. The force_encoding boundary now raises RuntimeError
on frozen strings, preserving host global freeze behavior elsewhere. Query
and binary roundtrip already matched. Native build is active for that correction.
