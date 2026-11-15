# Ruby runtime language and stock script differences

Latest owned compiler milestone has been reviewed from actual logs: managed
MRuby.Library0.2.0 host initializes all four extensions and matches the36-row
yield/super fixture; native ABI matches StandardError offset18800 and all
fundamental/exception class fields. The source patch now implements genuine
yield/super lookup rather than the earlier nil stubs. Production DLL remains
unchanged. README still documents array-element definedness, rebound escaped
super and match-global edge gaps. The same child is continuing those measured
edges in the owned tree before lead integration, also checking the latest
43-row streaming Zlib owner against the candidate.

F05 is open. Earlier shop/name probing observed `defined?` evaluated as an
undefined method under the embedded host; fixture initialization was adjusted
then, but no runtime fix was claimed. A shared language fixture now probes
constant/method/global definition, assignment without side effects, integer
division/modulo, UTF-8/binary length, float comparators, formatting, regexp
captures, blocks and symbol hashes on original RGSS300. Original execution
is active. A separate read-only investigation traces compiler configuration
for defined?; production code has not been changed for this gap.

Original 15 rows completed at exit 0. Host reproduces defined? as a method
call, including assignment side effect count1 versus original0. Other rows
match except binary string length2 versus original6. The encoding setter
already sets MRB_STR_BINARY, but host utf8_strlen checks only
MRB_STR_SINGLE_BYTE. Character index conversion checks both. The setter
now synchronizes both flags for byte encodings and clears both for UTF-8,
allowing the host to recompute its UTF-8 cache. Native build is active;
defined? remains a separate compiler gap.

Post-fix host replay now returns binary-length6 and UTF8-length2, matching
original. The overall runtime fixture still correctly fails on defined?
and side-effect count1. Headless regressions for the new encoding flags
are active; no broader F05 success is claimed.

The encoding switch-back row also matches original6,2 and the new native
flags pass TEST_SUITE_PASS:17, exit0. defined? compiler investigation is
still active. Independently, the existing real F12 runner is now executing
in windowed mode for F06's scene/resource contract. Cross-platform WMA
conditions were rechecked: Docker Linux daemon is unavailable and the only
WSL distro docker-desktop is stopped; Windows bundle evidence remains valid,
but these probes do not provide Linux or macOS release evidence.

Read-only compiler investigation completed: the pinned classic parser lacks
the defined? keyword/production, so it compiles a normal call and evaluates
arguments. NODE_DEFINED exists but its unreachable codegen is a nil stub.
No build-time flag repairs it. The host repository prohibits direct edits
to the vendored mruby submodule. An owned copied-source experiment and
maintained compiler patch are now being implemented under
tools/defined-compiler and .omo/compatibility-run-tmp/f05-defined-compiler.
No production host DLL is replaced before executable patch validation.

Owned compiler experiment returned: genuine16-row runtime fixture exact parity,
44 extended semantic cases pass, upstream mrbtest1661 OK/0 KO/0 Crash/28 skips.
Artifacts are in tools/defined-compiler. It remains undeployed: the patch
explicitly emits unconditional nil for defined?(yield)/defined?(super), and
does not synthesize regexp capture globals. Those are known incomplete
semantics, so native experiment success is not F05 runtime acceptance.
