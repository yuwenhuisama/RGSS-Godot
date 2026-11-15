# Battle damage rules

The resumed full suite exposed one nondeterministic hit endpoint: physical
hit100 uses actor HIT0.85, so Kernel.rand can produce missed instead of the
intended evade1 branch. The fixture now controls target.rand: no-argument
probability draw0.5, bounded integer variance draw0. Production unchanged.
First control used0.5 for integer variance too and incorrectly added1 damage;
that test error was corrected. Original and host replays are active before
updating any golden. All other measured clusters match their existing goldens.

Corrected original hit ledger matches the existing golden exactly; host full
123-row owner passes BATTLE_DAMAGE_PASS, exit0. The nondeterministic probe
failure is fixed at its random-input boundary without changing battle rules.

E02 acceptance on 2026-11-13: final123-row original/host comparison
passes at exit0:72 damage/drain cases,7 hit/probability endpoints,27
state/death/regeneration/walking cases and17 cap/element/action/variance/
confusion boundary rows. Actual ordinary attack/target-confirm/victory
passes on the current host; actual counter and reflection flows previously
passed with exact attacker/target HP and map/resource restoration. Effect
classes and forced action order are owned by accepted E03/E04; rendered
animation/log/signal checks remain E05. Random sequences are not required
to match across engines; probability formulas and endpoint branches do.

E02 is in progress and unaccepted. `fixtures/battle_damage_reference.rb` defines
72 deterministic cases: six HP/MP damage/recovery/drain types, three hit types,
critical on/off and guarding on/off. Element, physical/magical and recovery
rates are distinct fractions, formula 81.5 and variance zero. It records both
result damage/drain fields and target/user HP/MP after actual damage execution.
The isolated original RGSS300 run is active. No production fix is claimed.

This finite matrix does not cover hit/miss/evade RNG, counter/reflection,
state/buff timing, regeneration, death/revival rules or all effect classes.
Those remain E02/E03/E04 work. Installed game data is not modified.

Original completed all 72 rows, exit 0. Normalized SHA256:
`2a4ca1c7c70eef25b7c76a501e41d865b1db7518e52e71b08006134fbfa8eebf`.
`tests/test_battle_damage.gd` executes the same fixture and pins that independent
hash; its first run is active. Sample element-reduced HP damage is 40 normally,
20 guarded, 122 critical and 61 critical+guarded.

Godot comparison completed BATTLE_DAMAGE_PASS, exit 0, with all 72 original
rows matching. The runner is registered in --events. The already-running
48-entry suite started before that registration, so it does not include this
new entry and is not evidence of a 49-entry pass. E02 remains open on the
uncovered rule families listed above.

The same original fixture now adds three hit-type probability rows (hit, evade,
counter, reflection and critical) with distinct fractional traits, plus four
item_apply endpoint cases: guaranteed miss, guaranteed physical/magical evade
and certain hit. This compares deterministic formulas and boundary outcomes,
not random sequences or distribution equivalence. The extended original run
is active. Mid-probability RNG and actual counter/reflection scene execution
remain open.

The extended 79-row host comparison completed BATTLE_DAMAGE_PASS, exit 0.
The next shared original probe adds fixed-duration action/turn/battle-end states,
buff saturation and shorter-duration overwrite, opposite buff cancellation,
death clearing and revival, HP slip-death disabled/enabled and MP/TP regeneration.
The original run is active; no state-timing acceptance is claimed yet.

Original emitted 15 state/death/regeneration rows, exit 0. Combined host
comparison completed BATTLE_DAMAGE_PASS, exit 0: all 94 independent rows match.
At turn 2 the turn-end state expires first, then the action-end state and buff;
death clears buffs, removing death revives at HP1; slip death off/on yields
HP1/HP0, with MP70 and TP10 after regeneration. E02 stays open for the remaining
counter/reflection scene wiring and additional state/trait branches.

Original seven additional state rows and the host combined 101-row comparison
passed exit 0. Actual counter/reflection scenarios now extend the existing
attack-turn runner with real Fight/Attack/enemy-confirm input. Enemy counter or
reflection trait is 1, evasion is cancelled explicitly, and assertions check
exact attacker HP loss, unchanged enemy HP, no premature battle callback and
clean map/resource restoration after abort. Both rendered runs are active;
no reaction-path pass is claimed before their results.

Both actual reaction runs completed BATTLE_TURN_PASS, exit 0: counter and
reflection dealt the exact expected attacker damage, preserved target HP and
returned to the map with live resources restored. They are registered as
--counter/--reflection variants. The ordinary attack variant is now being
checked after the shared test extension; no broad E02 completion is claimed.

The existing state fixture now adds reapply countdown reset without duplicate
result IDs, dead-target rejection, refresh after gaining state immunity, and
two-step walking removal on a real Game_Actor. These five rows exercise
remaining state/actor branches rather than repeating the existing turn-end
matrix. Original execution is active; host expectations are not inferred
from the stock source alone. No battle production code changed.

Original new five rows completed at exit0: reapply resets duration2 and
records one result ID; dead target rejects state; gaining immunity removes
the state on refresh; walking leaves one step then removes at zero. The
windowed combined damage/hit/state runner completed BATTLE_DAMAGE_PASS,
exit0, preserving all prior cases (106 total measured rows).

Four further boundary rows now use actual execute_damage for HP/MP drain
limited by target resources, and compare attack-element maximum rate versus
explicit element rate. Original run is active. Existing deterministic damage
matrix remains unchanged; this catches cap/trait selection branches it did
not exercise.

Original edge probe first used nonexistent Game_Actor#actor_id. Its two
drain rows completed before that fixture error; the error file is preserved
with a unique suffix. Corrected probe uses Game_Actor#actor and passes all
four rows: HP drain7, MP drain3, attack-element maximum1.5, explicit rate0.5.
Host 110-row combined comparison is active. No production correction was
needed for this fixture API mismatch.

The four edge rows and full110-row comparison passed exit0. Ordinary
Fight/Attack/target-confirm/victory live runner also passed exit0 on the
current windowed host. The same edge fixture now adds deterministic action
probability endpoints, controlled variance extremes and confusion levels1-4.
Original execution is active before extending its golden rows. The variance
probe controls the random draw on its test battler and executes the real
apply_variance algorithm, including positive/negative damage and zero variance.

Seven action/variance/confusion rows matched in the windowed117-row owner,
exit0. The final confusion-target routing probe controls the two random
branches on a real Game_Action and distinct opponent/friend pools, testing
levels1/2/3 without copying the action's routing algorithm. Original six-row
execution is active. Existing counter/reflection live-flow evidence remains
separate from the numeric rate tests.
