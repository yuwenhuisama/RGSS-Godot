# Skill and item effects

E03 remains open. `fixtures/battle_effect_reference.rb` exercises all 13 stock
effect codes against actual Game_Actor instances and records HP/MP/TP deltas,
damage/result fields, state/buff changes, permanent growth, learned skill and
reserved common event. The isolated original run is active. No no-op dispatch
or copied handler inventory is accepted as execution evidence.

The first pass is one deterministic positive case per code. Probability
negative controls, scope/occasion/target selection, item consumption, skill
cost, and actual reserved common-event execution remain to be measured.
Synthetic states are memory-only; installed game data is unchanged.

Original completed all 13 rows, exit 0, normalized SHA256
`27a46fc4d4816bab56e09483f05fdfcced74eed53eb89662cefab9c5d9fe9f43`.
HP recovery is 61, MP recovery 9, TP effect truncates 7.9 to 7, permanent ATK
growth truncates to 7, learn-skill changes the skill set, and common-event code
reserves the actual event without claiming target damage success. The host
same-fixture comparison is active.

Host comparison completed BATTLE_EFFECTS_PASS, exit 0; all 13 original rows
match. The runner is registered in --events. This proves effect-code dispatch
and these parameter cases only. Actual scope/occasion/consumption/cost and
reserved-event execution still keep E03 open.

The next original 24-row limit/event trace and host 37-row combined comparison
passed BATTLE_EFFECTS_PASS, exit 0. Consumable count falls 2->1; non-consumable
stays1, all four menu/battle occasions match, MP/TP costs leave1/3. A skill's
reserved common event is consumed by the actual Game_Troop interpreter: variable
7 remains through the three-frame wait, then becomes12 and execution ends.
Scope/target and real skill/item UI execution still keep E03 open.

The shared original probe now exercises scope0..11 through Game_Action.make_targets,
recording exact actor/enemy identity sets, selection requirement and dead-friend
flag. The party contains one dead and two live actors; enemy random selection
has exactly one live candidate. Thus random scope tests validate repeat-count
and unit choice without comparing unrelated PRNG streams. Original run is active.

Original scope rows completed exit 0 and the combined 49-row host comparison
passed BATTLE_EFFECTS_PASS, exit 0. The actual attack-turn owner now adds --item:
real item command, item list, enemy confirm, damage10, count2->1, last_item
memory and the item's reserved common event setting variable17 through the
live troop interpreter. Its first rendered run is active; no UI pass yet.

Actual --item run completed BATTLE_TURN_PASS, exit 0, with all damage,
consumption, memory, event and cleanup assertions green; registered in --events.
The same owner now adds --skill: real command/list navigation, enemy confirm,
two repeated hits, MP/TP charged once and last_skill memory. That run is active.

Actual --skill run completed BATTLE_TURN_PASS, exit 0: enemy lost20 from two
hits, MP fell by the computed cost3 and TP10->8, skill memory and return-resource
checks passed. Registered as --skill; independent four-window image check is
active. The expanded unified suite has not run after these variants were added.

E03 local finite acceptance is complete. All49 original effect/occasion/cost/
scope rows match; actual skill/item input paths verify cost, repeats,
consumption, remembered selection, common-event execution and resource return.
Unified suite reported battle-effects and its skill/item variants PASS exit0.
Independent inspection st_01a1d495 read all four native544x416 captures:
item-window, item-target, skill-window and skill-target all PASS, with populated
lists, correct counts/costs and expected enemy-target viewport layout.
Limits: one enemy, empty fixture descriptions, still-frame visual consistency;
no original full-frame parity or animation/blink acceptance is claimed here.
