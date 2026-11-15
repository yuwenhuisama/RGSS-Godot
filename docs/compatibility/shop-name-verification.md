# Shop and name input verification

The actual stock Scene_Shop and Scene_Name run through the live Boot/Scene_Map
fiber. `tests/test_shop_name_operations.gd` injects real key events rather than
calling buy, sell or name-confirm handlers directly. The first run completed
SHOP_NAME_OPERATIONS_PASS, exit 0. Cancelled quantity and empty-name restoration
have since been added; the extended run also completed
SHOP_NAME_OPERATIONS_PASS, exit 0. The runner is registered in the --events
group; the expanded unified suite has not yet run.

Measured cases in this runner:
- Shop entry, buy two test items at 40 gold each from 200, then sell one at 20.
- Zero-gold purchase refusal and purchase-only disabling of the sell command.
- Cancel navigation back to the actual map from both shop modes.
- Name backspace, adding characters, the three-character maximum, Shift jump
  to confirmation and committing the name by Enter.
- Party gold/item/name restoration and live resource counts after returning.
- Cancelling a changed purchase quantity preserves gold and inventory.
- Confirming an empty edit restores the default name and stays in Scene_Name;
  a second confirmation commits it and returns to the map.

Synthetic goods are in memory only. No save file or installed game data is
modified. Full-frame captures are written under the owned evidence directory
`godot/shop-name`; independent visual inspection is active. Original numeric
parity and further branches remain required before D08 acceptance.

Independent inspection passed all three 544x416 captures: buy-two shows
200 gold, quantity 2, total 80 and owned 0; sell-one shows 120 gold,
quantity 1, total 20 and owned 2. Name input shows AAA and the complete grid.
No clipping, overlap, missing windows or glyphs were observed. Empty help text
and low-contrast icons belong to the synthetic item's empty/default fields;
this check does not establish original pixel parity.

`fixtures/shop_name_reference.rb` now measures original purchasing limits at
0/39/40/80/40000 gold, buying/selling, odd-price floor, inventory capacity and
name editing/default restoration. The isolated RGSS300 run is active under
`tools/run_original_shop_name.ps1`. No new production fix was needed for the
actual input cases. Ruby LSP is unavailable locally; no install was attempted.

The initial original run hung at name-edit creation after eight shop rows:
the probe had not called setup_starting_members, so it had no actor. That owned
process was stopped and its partial output preserved. With the initial party
set up, original RGSS300 completed all 14 rows, exit 0. A normal SystemExit was
recorded by the first exception wrapper; no product exception occurred.
The reproducible launcher now separates SystemExit from actual errors.
`shop_name_original.tsv` pins the observed rows, including max_buy 0/0/1/2/99,
120 gold after buying two, 140 after selling one at floor(41/2), capacity zero
and all name boundaries. The combined Godot comparison/input run is active.

The first combined Godot run failed before emitting rows: embedded mruby
reported `undefined method 'defined?' for Object`. The shared fixture now uses
an explicit host-injected global to choose initialization; the original numeric
body is unchanged. This runtime-language gap belongs to F05 and is not counted
as fixed by that test-fixture adjustment. The corrected combined run is active.

The corrected combined comparison completed SHOP_NAME_OPERATIONS_PASS, exit 0:
all 14 pinned original rows match. Actual weapon and armor purchases at zero
price have now been added through the same Enter workflow, with individual
inventory/gold assertions and cleanup; this final category extension is active.

The zero-price weapon extension failed its first inventory assertion, followed
by cascading wrong-scene errors. No production cause is established yet.
The runner now records command/buy/number stages, actual item, enabled state,
inventory and gold, stopping at that first failure. A diagnostic run is active;
the earlier item/name and 14-row passes remain valid but D08 remains open.

The first failure was traced to stock Window_ShopStatus using a fractional y
(`line_height * (i * 2.4)`) for actor text. Original RGSS300 accepts fractional
draw_text positions and sizes in three direct probes; the host wrapper rejected
them. It now accepts Numeric coordinates and converts toward zero before the
native integer boundary. The same scenario then exposed the equivalent blt
restriction when drawing equipment icons; an extended original blt probe is
active. The draw_text change alone did not fix D08 and is not reported as green.

All six original text/blt fractional-coordinate probes completed exit 0 and
accepted the parameters. After both wrappers converted Numeric positions
toward zero, the complete three-category shop/name runner passed exit 0.
The 45-group unified suite is now running. Equipment-status captures are added
to that run for independent inspection of the surface that previously crashed.

Final local acceptance passed: TEST_SUITE_PASS:45, exit 0, including the complete
shop/name runner. Independent weapon/shield status captures show a legible
actor/equipped-item row and populated zero-price purchase list, with no clipping
or overlap. The controlled party has one actor, so this does not claim every
party-size layout or original whole-screen pixel parity. D08's stock shop/name
operation coverage is accepted on this Windows RGSS300 baseline.
