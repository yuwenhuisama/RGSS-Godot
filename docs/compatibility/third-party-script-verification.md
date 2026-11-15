# Third-party script coverage

F07 is accepted for the versioned corpus and executable test entry below. Read-only inventory of the actual local RMProject script
archive contains126 entries: stock Vocab through Scene_Gameover, section
separators, one plugin insertion slot named `(please add here)` in the Chinese
editor, and Main. Names alone do not establish third-party content or exact
stock authenticity; the plugin-slot payload and archive fingerprint are being
read separately.

Do not count stock-script battle/map/menu fixtures as third-party compatibility.
The initial local project had no versioned third-party corpus; the Yanfly
entry below supplies the first executable sample. Further entries must record source, version/hash, order,
dependencies, original result and host result rather than a generic supported
claim.

The inspected archive fingerprint is
b04ad4f98f61a93fe67dc597845db210d1e9f4b7e053050a14b015ffd112399c.
Of126 entries,111 have nonempty text. The only plugin slot contains a block
comment with standard Chinese editor instructions and no executable plugin.
The available project therefore supplies no third-party sample. This is an
observed corpus gap, not a failing third-party implementation verdict.

A real third-party sample is now sourced from the author's official page:
https://yanflychannel.wordpress.com/rmvxa/core-scripts/ace-core-engine/
which links https://github.com/Archeia/YEARepo/blob/master/Core/Ace_Core_Engine.rb.
Unmodified Ace Core Engine v1.09, dated2012.02.19, is stored under
tests/fixtures/third_party/Ace_Core_Engine.rb. Downloaded UTF-8 SHA256:
71b90cbe19d18089a9829a80b1289c8a36b68bd30acc7a6babdf0ca660fdd6e2.
Its default640x416 resize, digit grouping, animation-rate override and font
configuration are probed on an isolated original stock-script project first.
This establishes a versioned corpus entry; it is not accepted until execution.

Original execution completes eight rows at exit0: import true,640x416,
four digit-group values, animation rate3/duration7, font24,false,false and
disabled opacity160. Permanent TSV is captured; same unmodified plugin is
now executing on the actual Boot host. No third-party source is rewritten.

Host eight-row comparison passes. Actual640x416 map/menu run also prints the
same PASS but shutdown logs unsafe RefCounted references and FATAL condition;
overall acceptance is withheld. Independent map/menu QA st_01a1d5fe is active.
Runner now lets the actual SceneManager transition to Scene_Base and terminate
the menu before quitting, to separate direct test shutdown from live resources.

Normal scene termination still logs unsafe references, so direct test quit
is not sufficient explanation. Independent map/menu QA passes visible framing
but only sees command window; status/gauges/gold absent and unverified. Runner
now records real Window objects' geometry/visibility/openness/Z to distinguish
creation failure from renderer ordering. No third-party acceptance is claimed.

Detailed probe reveals Scene_Menu.start stops after command construction:
Window_MenuCommand.select_last reads unset @@last_command_symbol. Existing
menu contract initializes this through init_command_position when directly
jumping scenes; the third-party runner omitted that precondition. It now
initializes command state and asserts actual status/gold windows before capture,
so a partial menu can no longer produce an accepted UI marker. This fixes the
test setup; no plugin or renderer workaround is introduced.

Full menu/status/gold creation now passes, but unsafe exit references persist.
Runner now frees Boot while the SceneTree is still running and drains six
frames of queued node destruction before process quit; this tests teardown
timing rather than pretending an exit0 clears diagnostics. Independent full
menu QA st_01a1d602 is active.

Freeing Boot during the live tree and draining queued destruction passes
THIRD_PARTY_CORE_PASS at exit0 without unsafe-reference/FATAL diagnostics.
This establishes a clean test teardown; it does not silently change runtime
quit behavior or erase prior process-shutdown failures. Versioned plugin
numeric evidence is green; full-menu visual result remains pending.

Independent full-menu QA st_01a1d602 finds complete commands, actor status,
HP/MP gauges and gold with no clipping/overlap at640x416. One actor is visible;
the current fixture's party size still needs an executable count. A minor
top/left frame hairline asymmetry is observed but lacks original comparison.
Actual same-plugin WM_CLOSE is clean. Ruby exit variant and resumed aggregate
are active; F07 remains open on bounded sample coverage rather than blanket
plugin compatibility.

The shared plugin fixture adds gauge-overflow pixel bounds, actual party count,
and forced-action restoration of the exact saved Game_Action identity. These
exercise the plugin's UI/battle overrides beyond successful loading. Original
execution is active before updating the versioned ledger.

Original and host expanded11-row comparison pass at exit0 with complete
map/menu and clean live-tree teardown. Party count1 explains the single actor
seen by independent QA. Gauge cap255/0 and exact cloned action restoration
match original. F07 now has one real versioned tested sample; broader plugin
corpus and interaction coverage remain explicitly unverified. The requested
version/test-set deliverable is established by this real sample, permanent
11-row original ledger, registered UI owner and independent full-menu QA.
Acceptance does not claim that every third-party plugin is compatible.
