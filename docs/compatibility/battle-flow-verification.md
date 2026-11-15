# Real battle flow verification

E01 remains open. The existing EVENT_BATTLE_PASS fixture measures event request
and callback protocols; it does not execute the full Scene_Battle lifecycle.

`tests/test_battle_flow.gd` now boots the actual map and enters stock Scene_Battle
with an in-memory troop using installed enemy 1. It attempts real-key escape,
abort and allowed-defeat paths, checking callbacks, battle count, map return,
party battle flags, revival and live viewport/sprite/window restoration.
The first rendered run is active. No production fix or acceptance is claimed.

The first run completed BATTLE_FLOW_FAIL, exit 1. Its first failure was the
test calling nonexistent Game_Party#in_battle?; stock Game_Unit exposes the
in_battle reader. The runner now uses that actual interface and confirms
opening messages only while Game_Message remains busy, avoiding excess Enter
events that can advance into actor commands. It then asserts the real party
command window is active before selecting Escape. The corrected run is active.

The corrected three-ending run completed BATTLE_FLOW_PASS, exit 0: escape,
abort and allowed-defeat all returned to the map with expected callback result,
revived party and matching live resources. Victory now joins the same runner:
dead enemy state triggers the real Scene_Battle judgment and message chain,
with exact troop gold and per-actor experience-rate reward assertions. This
extended four-ending run is active; combat actions and original baseline remain
separate outstanding work rather than implied by setting enemy HP to zero.

Original RGSS300 manager baseline completed six rows, exit 0, after the isolated
fixture received its missing RTP Run sound. `battle_end_original.tsv` records
escape success/failure, abort, allowed defeat, gameover and victory. Victory
awards 10 gold and 6 experience for troop1. The host victory scenario already
returned map with matching resource counts; its reward assertion was wrong
because it read gold_total before death. Stock Game_Troop aggregates dead_members
only. The corrected after-death expected reward run is active. No production
battle defect has been proven by these fixture failures.

The corrected four-ending real scene run completed BATTLE_FLOW_PASS, exit 0:
escape, abort, allowed defeat and victory return to the map with exact callback
results and live resource restoration. Victory gold/experience match the dead
troop totals and actor rates. The same shared six-row manager fixture is now
running on Godot via `--manager` against the pinned original TSV. Full E01
acceptance still requires actual failed escape/disabled escape and gameover
surface checks, encounter initiative branches and original comparison result.

Godot `--manager` completed BATTLE_END_REFERENCE_PASS, exit 0: all six original
rows match. The real scene runner now adds failed escape (negative ratio,
no callback and ratio increment), disabled escape (command stays active), and
non-allowed defeat (actual Scene_Gameover, party remains dead). Those cases
then restore the actual map and check live resources. The seven-ending run
is active; initiative and actual turn/action wiring remain outstanding.

Seven-ending extension reached failed escape: no callback/scene exit and the
escape ratio increment both passed. Its cleanup abort was requested before the
failure message finished; stock command_escape subsequently enters turn_start
and overwrote that phase. The runner now acknowledges the failure message before
requesting abort. The first actual attack-turn runner is also active: real Fight,
Attack, enemy selection and confirmation, deterministic skill damage and
victory/resource assertions. No full combat-rule coverage is implied by one turn.

The first actual attack-turn run completed BATTLE_TURN_PASS, exit 0. Independent
attack-target image inspection passed scene integrity/enemy cursor/text, with
the limitation that this sparse target layout does not show HP/MP or all commands.
Seven-ending cleanup next returned to the map and restored resources but its
callback differed after failed escape. The fixture had inherited 1 HP from the
allowed-defeat case; every case now recovers battle members before setup and
acknowledges failure messages only while busy. The next run records actual
callback/HP alongside each case, separating legitimate enemy-turn defeat from
abort handling. E01 remains open until those paths are proven.

Seven independent real ending cases now completed BATTLE_FLOW_PASS, exit 0:
escape1, abort1, allowed-defeat2, victory0, failed-escape then abort1,
disabled-escape then abort1 and Gameover2. Failed escape lost 10 HP to the real
enemy turn (562 -> 552) and then returned normally; its previous callback
difference was inherited near-dead fixture state. Gameover retained HP0 until
explicit test recovery. Every map return restored live resource counts.
Independent three-image checks are active, and the original shared manager
fixture now records normal/preemptive/surprise input/order categories.

The complete nine-row original comparison passed BATTLE_END_REFERENCE_PASS,
exit 0. Normal input accepts the party and includes 1 actor/2 enemies; preemptive
includes 1 actor/0 enemies; surprise rejects actor input and includes 0 actors/2
enemies. Independent battle and disabled-escape frames passed; the Gameover
frame passed integrity with its lower stripe being checked against the asset.
Three runners are now registered under --events (real endings, manager baseline,
actual attack turn). The expanded 48-member suite has not run yet. Broader
damage/effects/action order and original full-frame parity remain E02-E05 work.

Victory, failed/disabled escape, non-allowed defeat/gameover, initiative variants
and original numeric baseline are now measured above. The final expanded suite
is running. Battle rule/effect/animation coverage stays in E02-E05.
Synthetic troop/database changes are in memory only;
no installed game files or saves are modified.

Independent source inspection resolved the Gameover stripe: no game override
exists, and the captured 544x416 frame is pixel-identical to the RTP GameOver.png
(0/226304 differing pixels). The stripe is source artwork. The 48-entry unified
suite is active; no final suite pass is claimed before it completes.

Final E01 local flow acceptance: TEST_SUITE_PASS:48, exit 0, includes seven
real endings, original nine-row manager/initiative comparison and the real
attack-selection turn. All return-resource assertions and independent battle/
Gameover checks passed. E01 is accepted on this Windows RGSS300 baseline.
Detailed combat rules, action scheduling and full animation parity remain
explicit E02-E05 tasks; no cross-platform/full-game coverage is inferred.
