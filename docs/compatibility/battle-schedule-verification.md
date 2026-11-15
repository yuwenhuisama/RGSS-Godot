# Battle events and forced action scheduling

E04 remains open. `fixtures/battle_schedule_reference.rb` measures battle-event
span0/1/2 execution across a turn boundary with exact variable counts and
interpreter state. It also measures a forced actor action preserving last target,
the forcing flag, removal from the normal action queue and force-clear state.
The isolated original RGSS300 run is active. Actual forced-action execution in
Scene_Battle and broader condition/order branches remain required.

No production code changed; synthetic troops and condition variables are
memory-only. This is finite execution evidence, not a claim of all permutations.

Original20rowssucceededexit0hash
`71fa45775eea9e0906662672c426dd268c812aea8671ba71e9fcf3bbac34f8a5`.
Host comparison BATTLE_SCHEDULE_PASS follows the same rows. The actual
attack-turn owner now adds --force: choose Guard with real keys, a turn1 troop
page invokes command339 for one actor attack, then sets variable23 only after
forced action completion. Exact enemy HP loss10 catches duplicate execution
from the normal queue; flag/interpreter and map/resources are checked. Run active.

Actual forced event completed BATTLE_FORCE_PASS, exit 0: enemy HP decreased
exactly10, variable23 ran after force completion, forced flag and interpreter
cleared, map/resource counts restored. Registered as --force. The shared
original now adds event-page positive/negative conditions: no-condition page,
exact/periodic turns, enemy/actor HP49/50/51%, missing enemy, switch off/on and
turn-ending off/on. This original extension is active.

Original18page-condition rows completed exit0; host combined38row comparison
passed BATTLE_SCHEDULE_PASS, exit0. Exact/periodic turn gates and HP thresholds
are inclusive at50%; missing enemy and unset-condition page refuse execution.
Action-speed/order and enemy/dead forced-action branches remain unmeasured,
so E04 is not accepted yet.

Original action-order extension completed exit0: actor2 with speed+1000 acts
before actor1; command339 on dead actor produces no forced action and finishes
the interpreter; enemy forced action keeps forcing=true and last target0.
The host combined41row comparison is active against the pinned three rows.
Actual enemy forced-action execution remains narrower than the actor scene
probe and is not yet claimed.

Enemy forced scene first failed its damage assertion. The assertion assumed
the selected Guard command had already applied a guard state, but troop events
are processed before normal actions. A diagnostic run now records actual HP,
guard flag, target HP, variable23 and force/interpreter state. No production
ordering defect is claimed until that state is observed.

Observed enemy force state: HP562->552, guard=false, enemy100->100,
variable23, force=false, interpreter=false. This matches stock priority of
process_event/process_forced_action before the normal Guard action. The expected
damage now uses the unguarded physical rate; the corrected full run is active.
No production change was needed for this fixture assumption.

Corrected enemy forced-action run completed BATTLE_FORCE_PASS, exit0, with
actual priority/once-only damage, tail command23, force/interpreter clear and
map/resource recovery. It is registered as --enemy-force. Expanded unified
suite remains unrun; E04 acceptance stays pending that gate and declared limits.

Current unified --events run reported battle-schedule PASS exit0. Its map-screen
entry failed the old random-particle bound, now independently repaired and
passed with original lifetime evidence. The suite's final result is pending;
individual scheduling evidence is settled and does not require another replay.

E04 local finite acceptance is complete:41 original rows match; actual actor
and enemy command339 execute once, wait for completion and restore map/resources.
Unified suite finished with48 passes and one erroneous weather-bound failure;
that unrelated owner was repaired from original edge evidence and passed its
targeted replay. This is not a claim of every RNG ordering permutation or
other runtime/platform versions. No production scheduling change was required.
