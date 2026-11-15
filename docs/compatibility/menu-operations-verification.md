# Menu operations verification (D07)

Local measurement of the stock RGSS3 menu scenes driven by real keyboard events
on the Godot host, plus an isolated original RGSS300 run of the shared data and
no-input scene baseline. It extends C09, which covered menu creation, backdrop
and six subscene round trips; D07 is about the default UI operations inside
those scenes.

## What runs

- `tests/test_menu_operations.gd` boots the configured source game, loads
  `tests/fixtures/menu_operations_reference.rb`, and drives the stock
  `Scene_Menu`, `Scene_Item`, `Scene_Skill`, `Scene_Equip` and `Scene_Status`
  handlers with `InputEventKey` events through the real `Input.parse_input_event`
  path. Windows, input and handlers are unmocked.
- The fixture is shared with the original runtime. The original branch has no
  synthetic key injection, so it records only data operations and no-input scene
  states; those rows are pinned in the runner and compared on both sides.
- The controlled party is the installed project's actors 1-4 with the stock
  class/equip/skill data, plus three recovery items, one axe upgrade and one
  armor upgrade. Actor 4 learns skill 26 (`治愈`, 4 MP, scope 7) and that skill's
  damage variance is temporarily set to 0 so the heal value is deterministic;
  it is restored at the end.

Commands:

```sh
godot --headless --path . -s tests/test_menu_operations.gd
godot --path . -s tests/test_menu_operations.gd
```

The runner is registered in `tools/run_tests.gd` under --events. The expanded
unified suite has not yet run. Independent seven-capture inspection is active.

## Covered operations (actual key events)

| Operation | Keys | Asserted outcome |
|-----------|------|------------------|
| Open menu | X on map | `Scene_Menu`, command cursor 0 active |
| Item use | Z, Z, Z, Z | HP 100 -> max, item count 3 -> 2, `last_item` = item 1 |
| Item target sub-window | Z then Esc | actor window hides, item window active again |
| Item cancel/return | Esc, Esc | category window active, then `Scene_Menu` command 0 |
| Skill command | Down, Z, Down x3, Z | personal target actor 4, `Scene_Skill`, 2 skill types |
| Skill use | Down, Z, Z, Down, Z | MP 98 -> 94, target 2 HP 100 -> 367, `last_skill` = 26, `target_actor` = 2 |
| Skill return | Esc, Esc, Esc | command window active, `Scene_Menu` command 1 |
| Equip item | Down x2, Z, Up x3, Z, Z, Z | equips `[2,46,0,1,0]`, inventory `[1,0,0,1,0]` |
| Equip optimize | Right, Z | equips `[2,46,0,2,0]`, inventory `[1,0,1,0,0]` |
| Equip clear | Right, Z | equips `[0,0,0,0,0]`, inventory `[1,1,1,1,1]` |
| Equip return | Esc | `Scene_Menu` command 2 |
| Formation | Down x4, Z, Z, Down, Z | party `[2,1,3,4]`, pending index reset to -1 |
| Formation cancel | Esc, Esc | command window active, then map |
| Status | Down x3, Z, Z | `Scene_Status` actor 1 |
| Status actor switch | PageDown, PageUp | actor 3, then actor 1 |
| Status return | Esc | `Scene_Menu` command 3, then map |
| Resource restoration | - | viewport/sprite/window counts `(5,11,7)` before and after |

Data rows pinned from the original runtime (byte-identical on both sides):

```text
data.item_use	100,562,3,2,1
data.skill_use	98,94,100,367,2,26
data.equip_change	2,46,0,1,0,1,0,0,1,0
data.equip_optimize	2,46,0,2,0,1,0,1,0,0
data.equip_clear	0,0,0,0,0,1,1,1,1,1
data.formation_swap	1,2,3,4,1,3,2,4
data.actor_nav	1,2,3,2
```

No-input scene rows pinned from the original runtime:

```text
scene.menu	0,1,1,7,item,-1,0,1,4
scene.item	0,1,item,-1,0,1,0
scene.skill	0,1,2,skill,-1,0,0
scene.equip	0,1,3,equip,-1,0,5,-1,0,1
scene.status	1,1,-1
```

## Evidence

- Headless and rendered runs both print `D07_MENU_PASS` with exit 0.
- Data rows hash `cb798966bf28ac89eb4b7eb8cd61f0e0fb04cbfcc0fcebdd6af878b8db0cbfd6`;
  scene rows hash `7745a61361973dc81212a34cd8a22e3f39504b9d85978cc1a7b3898f691625f8`.
  The isolated original fixture (`Game.exe` exit 0) produced the same two files
  byte for byte.
- Captures (not visually reviewed here): `.omo/evidence/rmva-compatibility/godot/menu-operations/d07-menu-*.png`
  for menu, item target, skill target, equip item, formation pending, status
  actor 1 and status actor 3.
- Mutation checks: changing one recorded data value made the pinned row
  comparison fail; removing the confirm key from the item-use sequence made
  `item-used` fail. Both mutations were reverted byte for byte.
- Live resource counts return to the pre-operation baseline `(5,11,7)`.

## Gaps and non-claims

- Original input parity is not claimed. The original branch cannot inject
  synthetic keys, so the key-driven outcomes above are Godot-host evidence only;
  the original side contributes the data and no-input scene baselines.
- Item/skill use was exercised for one recovery item and one single-target heal.
  Attack/opponent scopes, all-target and all-ally scopes, state removal, common
  event effects, and battle-only occasions are not covered.
- Equip coverage is one weapon slot for actor 1 plus optimize/clear. Dual-wield
  slot layouts, sealed/fixed equipment types, and other actors' equip lists are
  not covered.
- Formation covers a single adjacent swap and its cancel path; no multi-swap
  sequence or party-size boundary.
- Status covers actor switching with PageDown/PageUp; it does not assert the
  drawn contents beyond the actor id.
- Save/End/Game End menus, the F1 settings dialog, and shop/name-input scenes are
  separate gates (D08 and later), not part of D07.
- Captures were produced but not visually reviewed in this unit; the lead owns
  visual acceptance and packaging.
- Only the installed Chinese RMVA 1.00 runtime is a baseline. RGSS301 and
  non-Windows behavior remain unverified.

Final D07 local operation acceptance: the seven captures received independent
PASS verdicts for populated windows, readable text, actor/item/equipment state
and framing. Skill help truncation occurs at the stock narrowed 160-pixel
viewport; no original capture comparison of that truncation is claimed.
The unified 45-entry suite completed TEST_SUITE_PASS:45, exit 0, including
D07_MENU_PASS. Covered stock menu operations are accepted on this baseline;
the effect-rule and project/save concerns above retain their separate E/F gates.
