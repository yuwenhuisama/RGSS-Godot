# Stock event-command verification ledger

Source: E:/Projects/RMProject/Data/Scripts.rvdata2, Game_Interpreter, extracted 2026-11-13.
All 106 implemented command handlers are listed. Presence is not executable acceptance.
Continuation records (e.g.401/405/408/505/605/655) are consumed by parent handlers and need paired cases.

Fullroute probe first failed using Game_Character as a map event (no refresh),
then timedout because frame increment was missing. OwnedPID7216 verified and
stopped after7439repeat frame0rows; those are invalid acceptance evidence.
Fixture now uses realGame_Event and increments frame; fresh originalrun active.

Corrected original578rows exited0; Godot had3mismatches, exclusivelyroute23
which internally rand(2) chooses left/right90degrees. That code was mistakenly
classified deterministic. It nowjoins9/24 in32-trial invariant checks (23must
turnleft/right fromdown);42deterministic code traces remain exact comparisons.
No runtimechange for legitimate different PRNG draws. Neworiginalrunactive.

Finalfullroute575row reference
`fa360b4ddf34c0f7e6d8ec12b6f00526a6d4226c5f82c22d207339b45f813744`
passed originalexit0/EVENT_ROUTE_PASSexit0. All45operations executed (42exact,
3randominvariants); routeend is exercised by each deterministic case. Runner
registered in --events. Actor fixture nowadds include_equips true/false queries
and weapon/armor loss,71scenarios, originalunderway. This adds observable equip
slots/inventory counts so a no-op removal cannot pass.

Actor71scenario include_equips reference
`b78ce0adf38d7526e503bbbd2a1b9218a1b199ebcfd8ec37f16a75f189773679`
passed originalexit0/EVENT_ACTOR_PASSexit0. Fullroute fixture adds blocked
skippablefalse/true and repeattrue nonwaiting cases,24extra rows; original
running. Blocked non-skippable route deliberately remains waiting in bounded
trace, not claimed to finish; this is the stockcontract rather than a hang fix.

Route599row final reference5819a1c33dfbf8cc58709a125da5118a397e62aed492a382ba85d2fcc1bdc2a7
passed originalexit0/EVENT_ROUTE_PASSexit0. D05 realwindow interaction delegated
as a disjoint test unit; D04 remains active. Separate MarshalIO/depth7case
originalfixture now running to regress the nativeoptionalargs fix discovered
by cross-map save_data. F04 fullserialization acceptance remains open.

Color final comprehensive suite TEST_SUITE_PASS:34 exit0 after double-channel
fix, existingeffecthashPASS. Animation/balloon actual completion-wait cluster
event_effect_wait_reference.rb/test_event_effect_wait.gd:94original/Godot rows,
bothexit0, SHA256 `3cba653ec048dfd308626d22b933b7d9f30dc0a6feaeb59513fe49a5ed9d287c`.
Actual Sprite_Character updates clear animation/balloon IDs and resume waiting
Game_Interpreter; no fake ID clearing. Balloon clears atframe76 and interpreter
finishesframe77. This is timing/state proof, visible effects remain separate.

Battle scene restrictions36row reference
`aee68d97d33815d3ace2eeec578370db531727696c9a84a37b209116875b2f59`
passed originalexit0/EVENT_SCENE_PASSexit0. Message fixture nowextends13scenarios
with pre-existing busy text/choice and fast-scroll flagfalse. Original71row
capture running; UIinput remains separately owned byD05.

Message busy71frame reference
`ebc7e23b73e34734aa0c70225a3ef1c860265fa1dd22be02ac8a9218d35cdd04`
passed originalexit0/EVENT_MESSAGE_PASSexit0. Character fixture nowadds
nonwaiting route with frequency, walk/step animation, direction lock, transparency,
graphic/index, blend, switch and opacity changes; records actualroute completion
and interpreter early return. Original expanded capture running.

Nonwaitingroute114frame reference23ecc0b0bb2ccb230feaccc471b8ddf58f10b34798b372ee1cdab18d09321a8a
passed originalexit0/EVENT_CHARACTER_PASSexit0. Transfer fixture nowadds real
Map002.rvdata2 Marshal write/load in owned output world and cross-map event201;
mapID/dimensions included in observations. Original cross-map run underway;
Godot paths are isolated under user://event_transfer_fixture, source untouched.

Cross-map80frame originalexit0, hash97632ee87a916bb8123d9e0536a86b5e12008cf4a862ba59af5bb914f99ec4db.
Godot failed before output: save_data calls Marshal.dump(obj,file), but native
Marshal binding registered MRB_ARGS_REQ(1) despite its existing o|oi parser
and IOwriter implementation. VM rejected the second argument before dispatch.
Registration now MRB_ARGS_ARG(1,2); scoped nativeMarshal rebuild running.
No save_data fallback was added. Full Marshal option/format verification also
belongs to F04; cross-map test is the red proof for this missing IOcall wiring.

Scoped nativeMarshal buildexit0; rebuilt61,952byte plugin SHA256
`489b8e283288b790ede99730da3153eceaefcc12e6fd94d18991f89012f107c5`
copied to Plugins/windows after retaining oldbinary under owned temporary root.
Managedbuildexit0 copied it to runtime output. Same80frame cross-map regression
EVENT_TRANSFER_PASSexit0 now writes/loads Map002 and returns mapID2,30x25,
player6,7. Newplugin comprehensive35runner suite running; optionaldepth/IO
contract remains F04 broader coverage, no nativecommit created.

Battle event fixture nowadds encounter-selected troop operand2 with one real
encounter entry and battle-state reentry rejection,21protocolrows expected.
Original running; ongoing35suite battle entry will use the expanded fixture,
so its oldhash can fail until new completed originalreference is pinned. No
production behavior changed in this protocol extension.

Original21battle rows eaa06ea65706a22b7847641acf36c2357405e8a6fbc8e04c9d61e3e9964cec19
and corrected EVENT_BATTLE_PASSexit0. Comprehensive35run exit1/FAIL1 because
the fixture changed midrun before its reference update; allother34entriesPASS.
Single changedbattleentry subsequently passed; no failures hidden or tests
weakened. Transfer nowadds battle refusal and message-visible waiting; original
expanded15scenario reference running. Avoid fixture changes during future suites.

Transfer90frame reference f09f51f085d0149eee3a7d25d1c748acf1c39f06876847ed1f901296ceca400e
passed originalexit0/EVENT_TRANSFER_PASSexit0. Separate fullroute fixture now
executes all45 movement-code operations:43 deterministic codes through real
command205 and route termination, random9/24 with32 invariant trials each.
Random traces are not compared across different runtime PRNGs. Original run
underway; no fullroute acceptance until all cases complete.

Scheduling cluster event_schedule_reference.rb/test_event_schedule.gd:
24original map.update(true) frames exit0, normalized SHA256
`46c22fd6f1e12d0bdd7f79ae50744e98efcb8e673df1f3334c621b64d744fd8a`.
Reserved common event runs before manually started map event, then mapautorun;
parallel map/common events continue during blocking waits. Self-switch turns
autorun page off; common-event switch toggles refresh activity. Godot comparison
running. Player action/touch triggers, page-condition combinations and command
operand sweeps remain additional D04 requirements.

Godot scheduling comparison EVENT_SCHEDULE_PASS exit0, exact24frame hash.

Unified --events run TEST_SUITE_PASS:25 exit0. Control laterexpanded45scenario
hash `12fad83c90883e0176aaf975695d01e90e89a61bb0253979f2a21facc5b1b9b7`
passed EVENT_CONTROL_PASSexit0 separately after its change. Actor fixture now
expanded36scenarios with all/variable targets, death/revive, level minimum,
reinitialization and actor condition branches; originalrun pending.

Actor36scenario reference c69cfaa42309c9ef786798da9d60b08d62517af406919af6ea90320bdf0fc8f8
passed EVENT_ACTOR_PASSexit0. Same fixture now adds12actor game-data fields,
missing actor and valid/missing party indexes, total51scenarios; originalpending.

Actor51scenarios completed originalexit0 and EVENT_ACTOR_PASSexit0, normalized
SHA256 `6b5d20360efa584ded7c06201dbfbc90271b18834981a17ffb67ce51345f7fe3`.
Enemy fixture nowadds death/nochange/revive and all10game-data fields plus
missing target; original expanded matrix running. No extra production changes.

Expanded enemy32row hasha52211690c8e3bab62339b8726ef8ac72a100787c71ad1257c5c9ddebdfc27be
passed originalexit0 and EVENT_ENEMY_PASSexit0. Inventory/system fixture now
expanded43scenarios covering inventory/system variable-data operands and
money/item/weapon/armor conditions. Original matrix running; earlier21scenario
pass remains historical, not a verification of the later fixture change.

Inventory43scenario reference
`ce12de31638a37813881e3d8deee2a666919631b087d70ae5991e35cdf1d2ddc`
passed originalexit0 and EVENT_INVENTORY_PASSexit0. Page trigger fixture now
adds counter reach, event-to-player touch, wrong positions, nonnormal priority
and jumping suppression, total80rows. New original reference running.

Page80row reference8c93121eeba15180c992cc0c70597d5e9b0d07c0314bee3637e7a79f9a91d454
and character100row referenceb3aee08c5ae43c3297dce7fc34f9e1db233b48ca5e3cde5cc33a83d5e3bd1295
passed originalexit0/GodotPASS. Enemy37row condition reference
a96d784e88d280fa3f900424f0ce71c13e2bc9e9263e64c5f8f29e0c387aa381
passed originalexit0/GodotPASS. Player vehicle-condition extension200rows
original running, includes boat/ship/airship conditions and post-dismount false.

Player200row reference866d50687bc266d387d7b8e0f6cf4532102498439d956207fdcf30e3a9da2a71
passed originalexit0/EVENT_PLAYER_PASSexit0. Actor condition fixture nowadds
true skill/state/armor cases and false party/name/class cases,63scenarios;
previous cases had false-only skill/state observations, so the positive paths
needed distinct inputs. Original run underway; new armor slot recorded.

Actor63scenario positive/negative condition reference
`3bb50375defdaafb3d3ee1581611f6c6ded9ef1e99f29fd4f331cf0f0e3887dc`
passed originalexit0/EVENT_ACTOR_PASSexit0. Screen fixture expanded22scenarios
for no-wait/zero-duration/third-weather-type branches, originalpending. Control
runner additionally injects Shift into command111 input-condition branch;
Godot actual input check running. These checks add no production test seams.

Screen expanded22scenarios/224frames originalexit0, normalized hash
`9b507a15cc34e3bc0040c6f12cc709cf00fea82d65fbadc605b7b7024bc425e4`.
Godot failed2fractionalflashalpha rows:66.666666667 versus66.666664124,
33.333333333 versus33.333332062. ColorData normalizedfloat storage caused
the same precision loss as Tone. Rawdouble color channels with normalizedfloat
render properties are now implemented; build and fixed224frame regression
pending. ActualShift condition command111 regression passed exit0.

Color buildexit0, same224frame EVENT_SCREEN_PASSexit0, existing originaleffect
RENDER_REFERENCE_PASSexit0. Comprehensive --rendered --windows-fonts --events
34runner suite running after the final production data change. Fractionalalpha
expectations were not relaxed or rounded to hide the defect.

Page/trigger cluster:64six-condition combinations and4positive triggers
matched original68row hash167e097c45e3048861bc342ad5e40d58177d0b131216d5c8a2bb4b35b129693e,
EVENT_PAGE_PASSexit0. Four wrong-trigger negative controls are now being
captured on original; initial positive-only trigger coverage was insufficient.
The sixteen event runners are registered behind `tools/run_tests.gd -- --events`;
this option requires a real renderer and configured stock game data. It does not
change default headless suite membership or imply fullD04 acceptance.

The72-row negative-control page reference is
`5220393ccb78026bddcd34ea50f13a91ec9d431c03922950da3893d4548c2702`:
allfour correct triggers true, allfour wrong-trigger paths false. Unified
9base+16event regression is running. Control fixture is being widened from19
to45scenarios: six variable comparisons at below/equal/above values, timer
comparisons, fixed random range and modulo-zero. Its new original matrix is
running separately; the earlier unified control entry already passed before
this later fixture change, so the changed control entry must be rerun.

Audio protocol final EVENT_AUDIO_PASSexit0 matches12original rows. Strongest
claim here is event dispatch plus audio-object memory; playback verification
still belongs to E06-E08. Video event original after System dependency fix
exited0 and wrote empty/movie before=true, after=false; realOGV played.
Godot firstrunEVENT_MOVIE_PASS; finalsharedfixture rerunpending. Full command
entry coverage alone is not fullD04: alternative operands, waits, event trigger
scheduling and linked real surfaces must be accounted for before acceptance.

Audio event cluster:12original rows exit0, shared event_audio_reference.rb uses
real tone.ogg under allfour buses, normalized SHA256
`74ff72c205bd0c33137b56e998ac41a97f17c3fbeb33cc5b16ca0295c348a6ba`.
BGM play/save/replace/replay/fade and BGS play/fade, ME/SE/stop enter actual
Audio bindings. Recorded output is RPG audio-object state only; duration,
fade completion, loop and audible playback are E06-E08. Godot comparison running.

Scene-call24frame original/Godot comparison passed EVENT_SCENE_PASS exit0,
SHA256 `7d4261af0f11cab66661fc3d81ab5dcd7422c5f1f2654c1d280fc9e6cb9b38c5`.
Menu/save/gameover/title/shop/name calls and continuation goods are measured;
actual windows remain separate acceptance. D04 now88/106handlers partially
covered. Battle callback protocol fixture is running next; no full battle
completion claim follows from protocol acknowledgment alone.

Battle teardown repaired using stock init_members; originalexit0 and final
EVENT_BATTLE_PASSexit0, unchanged15rowhash. Five handlers nowprotocolPASS;
D04 coverage93/106partialentries. Player event fixture then added136/206:
4scenarios100rows, final originalexit0 and normalized SHA256
`8b1c63843a7e96bd506670ecb3c390b3fac7e683462de1929ef5f42cab2c3733`.
Early fixtures omitted followers.update and provided no walkable land, leaving
boarding unfinished then dismount rejected; these input-world gaps were corrected
using real follower updates and land tiles. Final original returns normal walk.
Godot player-event comparison running; encounter randomness is not asserted.

Battle callback fixture produced all15rows (four result/operand cases plus
abort) but the original remained alive after the output, monitor timedout.
Owned PID221296 path verified and stopped. Complete protocol SHA256
`3a2ab31846c46bfdc3b0fe0eebc925d9df9af6cd90b309758a38fa2f47830369`;
no originalexit0 or fullbattle verdict is claimed. Godot comparison running;
original teardown remains unresolved before this cluster can close its entries.

Godot protocol comparison passed EVENT_BATTLE_PASS exit0. Original diagnostic
run exited8192063 and reached 'restore manager' but not 'restore complete',
locating failure in the fixture's BattleManager instance-variable cleanup,
after all15rows. Per-variable cleanup logging is running to identify the
specific operation. This is not classified as an event-command divergence yet.

Per-variable log stopped at remove_instance_variable(:@phase); this unnecessary
fixture cleanup was replaced with stock BattleManager.init_members and prior
value restoration. Original then exited0, reached restore complete and retained
the identical15row hash. Godot final teardown comparison running. The isolated
remove_instance_variable failure is recorded as a runtime probe limitation,
not a defect in command301/340 execution.

Latest cluster: event_enemy_reference.rb/test_event_enemy.gd,10scenario rows,
originalexit0 and EVENT_ENEMY_PASSexit0, normalized SHA256
`cc0f1403be359f26e4ecb9d4bbc393e56a0ea9af57a77a764d915a671c8f7404`.
Actual enemyHP/MP, nonlethalHP, state add/remove/recover, hidden enemy appear,
transform/name refresh and animation request IDs agree. Battle rendering and
forced actions are not covered. D04 now77/106handlers partially exercised.

Enemy fixture expanded with command339 direct-target and last-target force
requests:18original rows exit0, normalized SHA256
`b8265b5d715fa440c749d2c08fd17e50baf201e59824c4b07f723e24e23db1db`.
Actual Game_Action skill/target and BattleManager forced queue are recorded;
public clear_action_force acknowledges completion, guarding request/wait wiring
only. Full battle execution remains E04. Godot expanded comparison running.

Transfer cluster `event_transfer_reference.rb`/`test_event_transfer.gd`:
12scenarios,76 original frame rows, originalexit0, normalized SHA256
`e44bd95445000e98092b2e48fb82481306aa7c37080a2f6ce3a0dd061e46e8e1`.
Direct/variable same-map transfer executes real perform_transfer; four-direction
scroll and consecutive-scroll waiting execute update_scroll. Player transparency
and follower visibility/gather requests are recorded. No cross-map file loading,
Scene_Map fade rendering or follower arrival completion is claimed by this cluster.
Godot comparison running.

Transfer/scroll76frame comparison completed EVENT_TRANSFER_PASS exit0;
five further handlers partially exercised, D04 now82/106. Scene-call cluster
event_scene_reference.rb is running on original:8scenarios for menu/save/
gameover/title/shop/shop-purchase-only/name/missing actor. It records real
SceneManager scene/stack and preparation state without starting windows;
window interaction remains D07/D08/F03.

Initial executable cluster: `tests/fixtures/event_control_reference.rb` drives
Game_Interpreter.setup/update with13 real command lists. Completed original
exit0, thirteenTSV rows pin state and update counts, normalized SHA256
`a063e7237f5c534239eaa60eaabff90f3be1060a851d517210f3f6d0a62f4afa`.
Godot runner `tests/test_event_control.gd` is running against that independent
hash. Coverage is switch/variable operations, branches, self-switch, loop/break,
labels, common event, script continuation, comment continuation, wait, timer
and processing exit. Other handlers and alternative branches remain pending.

The initial13-scenario Godot comparison passed exit0. The fixture was then
expanded to19 scenarios with switch/variable else paths, self-switch-off else,
variable-reference comparison, script condition and divide-by-zero behavior.
Completed original exit0, all19rows, expanded normalized SHA256
`5004c67152633f83d2f11898eef28c4f6c2f9cceae05a865480e62d061a84053`.
Original command122 resets the target variable to0 on division by zero; this is
captured rather than invented as an error fallback. Godot expanded run passed
EVENT_CONTROL_PASS with exit0; all19scenarios match the original hash.

Second executable cluster: `event_inventory_reference.rb` drives21 actual
command lists for money/items/weapons/armor, save/menu/formation restrictions,
window tone and battle audio selection (selection only, not playback evidence).
Original exit0 with21rows, normalized SHA256
`3782e9e2edc3dcc6a2e8ce1d50f2713a234f7c8debe05d17ab2772101332a0a9`.
Original gold cap99999999 and item cap99 are recorded with lower-limit cases.
`tests/test_event_inventory.gd` is running against this independent hash.

Inventory/system comparison completed EVENT_INVENTORY_PASS exit0,21rows.
Third cluster `event_map_reference.rb`/`test_event_map.gd`: original21rows exit0,
normalized SHA256
`4fc87f6a3bed2e0f93c14e422d1c7ea603d6acc6f8e5d6d69f95d1213601b6b3`.
It covers name display, battleback/parallax data, vehicle direct/variable
location and all six location-information kinds with direct/variable operands.
Godot comparison running. The tileset-change case currently uses two default
Tileset objects with identical id0; that output cannot distinguish a broken
change and was not counted as coverage. The fixture now uses distinct IDs1/2;
original21rows exit0 confirm finalID2. Strengthened normalized SHA256
`872142a4fcc2070228ae363988dc35e635f931602a947521d49758a81123e1b1`.
Godot strengthened comparison EVENT_MAP_PASS exit0. Other map-data cases retain
their independent original coverage; parallax timing/rendering is outside this
state-only cluster.

Fourth cluster `event_screen_reference.rb`/`test_event_screen.gd`:16 command
scenarios,176 original frame rows, original exit0, normalized SHA256
`1831765ffabca2ab5b473d3b6a41fc4a8afe3d2bb2eb6e988e4b190a89060d02`.
It measures fade/brightness, tone, flash, shake, picture direct/variable position,
move wait/non-wait, rotation, tone, erase and weather transitions. This is event
parameter/state/timing evidence; rendered picture/weather quality is D06.
Godot comparison running.

Seventh cluster `event_actor_reference.rb`/`test_event_actor.gd`:22 original
scenario rows, original exit0, normalized SHA256
`c2f0d27b8fd04291c4f266622e96909e12a6bb766954dd7400c654badf0fc984`.
It drives actual actor/party command lists for party add/remove, HP/MP,
nonlethalHP, state/recovery, EXP/level/parameter, skills, equipment, name/class,
graphics/nickname and missing actor. Godot comparison pending. Battle death,
all-target/variable-target variants and experience-message UI are not covered.

The screen cluster failed on4/176 rows, only fractional Tone values:
original46.666666667 versus port46.666667938; picture tone3.333333333 versus
3.333333254. Other fields and wait/update counts matched. Root cause: ToneData
stored normalized System.Numerics.Vector4 float channels and Ruby getters
multiplied them back by255, accumulating float quantization during interpolation.
Tone now stores original double values and converts to normalized floats only
through rendering properties. Build and the same independent176-row regression
are required before this repair is accepted.

Build exit0 and corrected EVENT_SCREEN_PASS exit0: all176 original frame rows
now match exactly, including fractional screen and picture Tone interpolation.
The unified18-runner suite and pre-existing original sprite-effect render hash
are running after the production change. No tolerance or expected value was
weakened; the same independently captured hash now passes.

Tone change final checks: unified TEST_SUITE_PASS:18 exit0 and original
sprite-effect rendered hash RENDER_REFERENCE_PASS exit0.
Fifth cluster `event_character_reference.rb`/`test_event_character.gd`:8scenarios,
60 original frame rows, original exit0, normalized SHA256
`418250ccb9476ff10cd573ac8191e917c9ae505166b959aa63b31d2af8c9f792`.
Position direct/variable/swap/missing targets, forced route speed/move/jump/wait/
switch/opacity/script, non-wait animation/balloon IDs and erase are covered.
The first original attempt failed in map refresh because the cold fixture
lacked common_events; the empty list is now supplied. Godot comparison pending.
Animation/balloon completion and visible playback remain unverified here.

Event-character60frame comparison completed EVENT_CHARACTER_PASS exit0.
Sixth cluster `event_message_reference.rb`/`test_event_message.gd`:10scenarios,
50 original protocol rows, original exit0, normalized SHA256
`1f34621b954a75efc39389c67387cd8d64a55f10415dba3c3e927ba9dc582eb8`.
Text/scroll continuation records, standalone and text-attached choices/number/
item requests, choice branches and cancel paths, busy-wait/resume are measured.
The fixture acknowledges public Game_Message requests directly; this guards
event protocol only, not the actual message-window input owned by D05.
Godot comparison running.

| Code | Stock description | Executable original/Godot evidence |
|---|---|---|
| 101 | 显示文字 | 50-frame message protocol cluster PASS; window input is D05 |
| 102 | 显示选项 | 50-frame message protocol cluster PASS; window input is D05 |
| 402 | [**] 的时候 | 50-frame message protocol cluster PASS; window input is D05 |
| 403 | 取消的时候 | 50-frame message protocol cluster PASS; window input is D05 |
| 103 | 数值输入的处理 | 50-frame message protocol cluster PASS; window input is D05 |
| 104 | 物品选择的处理 | 50-frame message protocol cluster PASS; window input is D05 |
| 105 | 显示滚动文字 | 50-frame message protocol cluster PASS; window input is D05 |
| 108 | 添加注释 | 13-scenario cluster PASS; other branches pending |
| 111 | 条件分歧 | 13-scenario cluster PASS; other branches pending |
| 411 | 除此之外 | 13-scenario cluster PASS; other branches pending |
| 112 | 循环 | 13-scenario cluster PASS; other branches pending |
| 413 | 重复 | 13-scenario cluster PASS; other branches pending |
| 113 | 跳出循环 | 13-scenario cluster PASS; other branches pending |
| 115 | 中止事件处理 | 13-scenario cluster PASS; other branches pending |
| 117 | 公共事件 | 13-scenario cluster PASS; other branches pending |
| 118 | 添加标签 | 13-scenario cluster PASS; other branches pending |
| 119 | 转至标签 | 13-scenario cluster PASS; other branches pending |
| 121 | 操作开关 | 13-scenario cluster PASS; other branches pending |
| 122 | 变量操作 | 13-scenario cluster PASS; other branches pending |
| 123 | 操作独立开关 | 13-scenario cluster PASS; other branches pending |
| 124 | 操作计时器 | 13-scenario cluster PASS; other branches pending |
| 125 | 增减持有金钱 | 21-scenario inventory/system cluster PASS; other branches pending |
| 126 | 增减物品 | 21-scenario inventory/system cluster PASS; other branches pending |
| 127 | 增减武器 | 21-scenario inventory/system cluster PASS; other branches pending |
| 128 | 增减护甲 | 21-scenario inventory/system cluster PASS; other branches pending |
| 129 | 队伍管理 | 22-scenario actor/party cluster PASS; other branches pending |
| 132 | 更改战斗 BGM | 21-scenario inventory/system cluster PASS; other branches pending |
| 133 | 更改战斗结束 ME | 21-scenario inventory/system cluster PASS; other branches pending |
| 134 | 设置禁用存档 | 21-scenario inventory/system cluster PASS; other branches pending |
| 135 | 设置禁用菜单 | 21-scenario inventory/system cluster PASS; other branches pending |
| 136 | 设置禁用遇敌 | 100-frame player event PASS; other vehicle/encounter variants pending |
| 137 | 设置禁用整队 | 21-scenario inventory/system cluster PASS; other branches pending |
| 138 | 更改窗口色调 | 21-scenario inventory/system cluster PASS; other branches pending |
| 201 | 场所移动 | 76-frame transfer/scroll cluster PASS; remaining branches pending |
| 202 | 设置载具位置 | 21-scenario map-data cluster PASS; other branches pending |
| 203 | 设置事件的位置 | 60-frame event-character cluster PASS; other branches pending |
| 204 | 地图卷动 | 76-frame transfer/scroll cluster PASS; remaining branches pending |
| 205 | 设置移动路径 | 60-frame event-character cluster PASS; other branches pending |
| 206 | 载具的乘降 | 100-frame player event PASS; other vehicle/encounter variants pending |
| 211 | 更改透明状态 | 76-frame transfer/scroll cluster PASS; remaining branches pending |
| 212 | 显示动画 | 60-frame event-character cluster PASS; other branches pending |
| 213 | 显示心情图标 | 60-frame event-character cluster PASS; other branches pending |
| 214 | 暂时消除事件 | 60-frame event-character cluster PASS; other branches pending |
| 216 | 更改队列前进 | 76-frame transfer/scroll cluster PASS; remaining branches pending |
| 217 | 集合队伍成员 | 76-frame transfer/scroll cluster PASS; remaining branches pending |
| 221 | 淡出画面 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 222 | 淡入画面 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 223 | 更改画面的色调 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 224 | 画面闪烁 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 225 | 画面震动 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 230 | 等待 | 13-scenario cluster PASS; other branches pending |
| 231 | 显示图片 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 232 | 移动图片 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 233 | 旋转图片 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 234 | 更改图片的色调 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 235 | 消除图片 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 236 | 设置天气 | 176-frame screen/picture/weather cluster PASS; other branches pending |
| 241 | 播放 BGM | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 242 | 淡出 BGM | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 243 | 记忆 BGM | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 244 | 恢复 BGM | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 245 | 播放 BGS | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 246 | 淡出 BGS | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 249 | 播放 ME | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 250 | 播放 SE | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 251 | 停止 SE | Audio event cluster executed; object protocol PASS, playback E06-E08 |
| 261 | 播放影像 | Empty/real OGV event returns; original exit0 and EVENT_MOVIE_PASS |
| 281 | 更改地图名称显示 | 21-scenario map-data cluster PASS; other branches pending |
| 282 | 更改图块组 | Distinct ID1/2 original map-data cluster PASS |
| 283 | 更改战场背景 | 21-scenario map-data cluster PASS; other branches pending |
| 284 | 更改远景 | 21-scenario map-data cluster PASS; other branches pending |
| 285 | 获取指定位置的信息 | 21-scenario map-data cluster PASS; other branches pending |
| 301 | 战斗的处理 | 15-frame battle callback protocol PASS; full battle pending |
| 601 | 胜利的时候 | 15-frame battle callback protocol PASS; full battle pending |
| 602 | 撤退的时候 | 15-frame battle callback protocol PASS; full battle pending |
| 603 | 全灭的时候 | 15-frame battle callback protocol PASS; full battle pending |
| 302 | 商店的处理 | 24-frame scene protocol PASS; actual window flow pending |
| 303 | 名字输入的处理 | 24-frame scene protocol PASS; actual window flow pending |
| 311 | 增减 HP | 22-scenario actor/party cluster PASS; other branches pending |
| 312 | 增减 MP | 22-scenario actor/party cluster PASS; other branches pending |
| 313 | 更改状态 | 22-scenario actor/party cluster PASS; other branches pending |
| 314 | 完全恢复 | 22-scenario actor/party cluster PASS; other branches pending |
| 315 | 增减经验值 | 22-scenario actor/party cluster PASS; other branches pending |
| 316 | 增减等级 | 22-scenario actor/party cluster PASS; other branches pending |
| 317 | 增减能力值 | 22-scenario actor/party cluster PASS; other branches pending |
| 318 | 增减技能 | 22-scenario actor/party cluster PASS; other branches pending |
| 319 | 更换装备 | 22-scenario actor/party cluster PASS; other branches pending |
| 320 | 更改名字 | 22-scenario actor/party cluster PASS; other branches pending |
| 321 | 更改职业 | 22-scenario actor/party cluster PASS; other branches pending |
| 322 | 更改角色图像 | 22-scenario actor/party cluster PASS; other branches pending |
| 323 | 更改载具的图像 | 22-scenario actor/party cluster PASS; other branches pending |
| 324 | 更改称号 | 22-scenario actor/party cluster PASS; other branches pending |
| 331 | 增减敌人的 HP | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 332 | 增减敌人的 MP | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 333 | 更改敌人的状态 | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 334 | 敌人完全恢复 | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 335 | 敌人出现 | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 336 | 敌人变身 | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 337 | 显示战斗动画 | 10-scenario enemy cluster PASS; battle playback/other branches pending |
| 339 | 强制战斗行动 | 18-row enemy/forced queue protocol PASS; battle execution pending |
| 340 | 中止战斗 | 15-frame battle callback protocol PASS; full battle pending |
| 351 | 打开菜单画面 | 24-frame scene protocol PASS; actual window flow pending |
| 352 | 打开存档画面 | 24-frame scene protocol PASS; actual window flow pending |
| 353 | 游戏结束 | 24-frame scene protocol PASS; actual window flow pending |
| 354 | 返回标题画面 | 24-frame scene protocol PASS; actual window flow pending |
| 355 | 脚本 | 13-scenario cluster PASS; other branches pending |
