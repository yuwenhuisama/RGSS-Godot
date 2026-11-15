# D04 current acceptance status

Measured 2026-11-13 against installed Chinese RGSS300. D04 local event execution
acceptance is complete: all 106 dispatch entries have recorded original
fixture evidence, parameter-class/branch probes and real map integration.
Linked menu, battle, audio and broader project surfaces remain their separate
checklist items. This is finite measured coverage, not all Cartesian parameters.
`event-command-verification.md` lists all106 stock command handlers and actual
shared fixtures. Every handler has at least partial dispatch/state evidence;
this does not prove every parameter combination or linked user-visible surface.

Current gate: `godot --path . -s tools/run_tests.gd -- --rendered --windows-fonts --events`
completed TEST_SUITE_PASS:43 exit0 after the measured rendering corrections
and registration of real map-flow/message-window runners.
The subsequent Shift release/else addition was separately checked with
EVENT_CONTROL_PASS exit0; settled unrelated entries were not rerun.

Measured clusters include control/variable comparisons, inventory/system,
actor/enemy data and conditions, map info, same/cross-map transfer, scroll,
screen/picture/weather state, messages, scene/battle request callbacks, vehicles,
automatic/parallel/common-event scheduling, six-page-condition64combinations,
counter/touch triggers, animation/balloon real completion waits, all45move-route
operations and blocked/skippable/repeat behavior. Three random route operations
are checked by valid-outcome invariants, not cross-engine random-sequence equality.

Production defects fixed from red probes:
- Tone and Color keep rawdouble Ruby channel values; float normalization only
  at rendering read removes fractional tone/flash interpolation loss.
- Marshal.dump registration permits optionalIO/depth as already implemented;
  explicitnilIO now raises the originalTypeError. Real save_data and map-file
  loading run successfully through the corrected native plugin.

Linked acceptance work:
- Message/choice/number/item visible-window input is D05; actual menu/shop/name
  scenes are D07/D08; complete combat and audio timelines are E01-E08. Current
  event protocol acknowledgment is accurately narrower than those surfaces.
- Additional operand boundaries must be named per affected contract when real
  flow exposes them; arbitrary exhaustive Cartesian parameter sweeps are not
  claimed by these finite fixtures.

No new headless/GPU capture claim extends to macOS/Linux or fresh release builds.
No Git commit was created. Original failed fixture runs remain owned evidence
until the final cleanup task; original source game files were not changed.

`tests/test_event_map_flow.gd` now runs actual boot/title/newgame/Scene_Map,
injects Enter to start a nearby action event three times, checks12-frame wait
and no repeated execution after release, and restores original event/player
state. Actual rendered flow run is in progress; screenshot output is available
for independent visual inspection after it completes. It does not replace
original protocol fixtures or prove all default map flows.

First real map flow completed EVENT_MAP_FLOW_PASSexit0. Independent visual
inspection of full544x416 map found populated terrain/characters, no stuck
dialog or clipping/overlap; identifying which sprite is player is not established
by that still alone. Runner nowadds actualRight-key player-touch trigger and
release/no-repeat check; extended flow rerunpending. This capture remains
surface integrity evidence, not original pixel parity.

ActualRight-key touch flow passed, then actualevent collision route also passed.
Non-skippable collision legitimately retries/retriggers; after permitting route
completion, the interpreter finishes and no new event runs. EVENT_MAP_FLOW_PASS
exit0 covers allthree trigger forms in the real map loop. Independent earlier
map capture passed integrity. D05 window baseline/input is being verified
separately after floatoffset acceptance fix.

The subsequent real-map message scenario also passed EVENT_MAP_FLOW_PASS,
exit 0: Enter dispatches an event with stock Window_Message, interpreter remains
blocked and the trailing variable command does not execute before acknowledgment;
a second Enter clears the message and resumes the command. This is real map
input wiring in addition to the isolated D05 window contract. The unrelated
39-suite results remain settled; only the extended map runner was rerun.

Real animation/transfer integration also passed EVENT_MAP_FLOW_PASS, exit 0:
Enter starts command 212 with a 12-frame stock animation, transfer command 201
does not advance during the animation, actual Scene_Map performs the fade and
same-map transfer, the trailing variable command resumes, brightness returns
to 255, and live viewport/sprite/window counts match their baseline.
Cross-map loading remains covered by the separate 90-row original fixture;
this scenario deliberately measures the real scene transition at one map.

The real map runner now copies the installed Map001 into an owned isolated
base as Map001/Map002, then injects Enter to dispatch command 201 into map2.
It checks trailing command resumption and returns through actual Scene_Map
transfer to map1, restoring the original data path. This extended run is active;
the original game Data directory is not modified.

The extended real cross-map flow passed EVENT_MAP_FLOW_PASS, exit 0. A final
resource-count assertion after restoring map1 is now running, with independent
inspection of the returned-map screenshot. All 106 command entries retain
their original executable fixture evidence; D05/D07/D08 and E01-E08 linked
surfaces remain separate acceptance tasks rather than being claimed here.

Final cross-map resource check passed EVENT_MAP_FLOW_PASS, exit 0, after map1
event/player restoration. Live viewport/sprite/window counts equal the baseline.
Independent returned-map image check passed: full terrain, distinct sprites,
no stuck message, blank panel or duplicate overlap. The preceding 43-member
suite passed; only the extended map runner needed rerunning afterward.
