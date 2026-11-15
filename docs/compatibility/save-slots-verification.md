# Save slots and damaged files

F03 current local acceptance completed: original eight-row behavior, real
overwrite/corrupt/valid-load and six cancel returns, independent visible list
QA, plus headless21/event52 gates all pass. Historical unclassified count
failure remains recorded; no claim is made that its specific cause was fixed.

Latest same-process title/map/event/battle/save route completes exit0 with
TITLE_SAVE_FLOW_PASS/SAVE_SLOTS_PASS after a separately reproduced Marshal
identity fix. Actual save overwrite, corrupt load staying in Scene_Load,
valid load restoring444 and all six cancel returns preserve5/11/7 resources.
Independent current save/load images pass panel visibility, labels, sprite,
playtime and clipping checks. The earlier single count failure is still
unclassified; it is not attributed retroactively to the new Marshal defect.
Current original eight-row ledger, host UI behavior and lifecycle are verified;
expanded event integration gate is running before final F03 acceptance.

Expanded full windowed event suite completes TEST_SUITE_PASS:72, exit0,
including the overwrite/corrupt/valid-load and six same-VM cancel returns with
exact5/11/7 resource counts. No current resource failure reproduced. Historical
single failure remains unclassified rather than claimed fixed retrospectively.

Current windowed rerun passes SAVE_SLOTS_PASS with resources5/11/7 returning
to5/11/7 after overwrite/corrupt/valid-load flow. The historical one-off failure
still lacks its actual differing counts and cannot be called fixed by this
rerun. The owner now adds three same-VM Save/Load cancel cycles, checking scene,
saved variable and exact map resource counts after each return. That run is
active to test cumulative scene retention and the real cancel paths.

Expanded windowed owner passes exit0. Six same-VM cancel returns (three
Save/Load pairs) all restore5/11/7, retain variable444 and return Scene_Map.
Current overwrite/corrupt/valid load also restores5/11/7. Full windowed event
suite is active with the expanded owner. The old failure still has no recorded
actual resource delta; these current results establish bounded lifecycle
behavior, not a retrospectively proven cause for that historical failure.

F03 remains open. Shared save_slots_reference.rb executes stock DataManager
missing-file header/load, first save/header, overwrite and restored variable,
corrupt file, header-only truncation and deletion. All names point to owned
output files, preserving user saves. Original run is active. UI list selection,
overwrite confirmation flow and resumed scene behavior remain separate checks.

Original eight rows completed exit0. Missing/corrupt file yields nil header
and loadfalse; header-only file returns its valid header but loadfalse. All
failed reads retain variable222. Overwrite restores222, last index0;
deletion removes the owned file. Normalized SHA256
623738bdb543603ba172b1d9e0f0bf8fcbc2edefe9eb7cc395bf7f4ecf9483a2.
Host same-fixture comparison is active; no save handler changed.

Host eight-row comparison completed SAVE_SLOTS_PASS exit0. The owner now
adds --ui: actual16-slot Scene_Save, Enter overwrites slot0 with variable444,
Scene_Load selects corrupt slot1 via keys, Enter must keep the load scene and
variable555, then Up/Enter loads slot0 back to map with444. It captures save
list and failed-load list and verifies map resources return. UI run is active;
the stock save scene has no separate overwrite confirmation dialog.

UI scenario completed SAVE_SLOTS_PASS exit0:16 windows, correct selected
slots, real Enter overwrite, corrupt read retained Scene_Load/variable555,
valid read restored map/444 and resource counts. Registered as --ui in events;
independent two-image inspection st_01a1d52c is active. No slot handler changed.

Independent two-image QA failed: help windows appear, but all slot windows
are hidden below an unchanged map background. Numeric input success did not
establish visible list acceptance. Current SpriteData defaultZ=1 and savefile
Viewport defaultZ=0 can put the menu backdrop above its entire slot segment.
Original default-Z/overlap probe is active before changing render defaults;
no slot-specific z patch is introduced.

Original default-order probe exited0: both Sprite defaults and Viewport Z0;
overlap pixel is green from the later Viewport. SpriteData defaultZ1 is corrected
to0 at the common cause. Independent pixel/default owner added; C# diagnostics
clean, build active. Actual UI replay and new independent captures are pending.

After defaultZ fix, the independent overlap probe still failed: defaults0/0/0
but red background remained above later green Viewport. Renderer used Godot
node IDs as tie-breakers; pending registration creates nodes in a different
order than Ruby objects. RubyData now records stable construction sequence,
and Sprite/Tilemap/default-screen versus Viewport segment ties use that
sequence. Diagnostics clean; build active. DefaultZ fix alone is not presented
as sufficient, and new UI images are not accepted until overlap replay passes.

Stable-order pixel replay passed DEFAULT_DRAW_ORDER_PASS exit0, but actual
UI replay failed map resource restoration. No failure is waived. The owner
now prints baseline and returned counts; diagnostic rerun is active.
Independent list-image reread st_01a1d535 is active solely to check the visual
遮挡 fix, not resource acceptance.

Diagnostic UI rerun passed counts5/11/7->5/11/7. Independent reread
st_01a1d535 passed both images: all four visible slot panels, selected slot,
character and playtime appear without clipping. Prior resource failure remains
unclassified; a single green rerun is not its fix. Full rendered/event suite
is active to check the common ordering change and recapture any resource failure.
