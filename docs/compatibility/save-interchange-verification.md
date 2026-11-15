# Original and host save interchange

F02 is open. The shared fixture uses stock DataManager to save the complete
game object graph after changing variable/switch/self-switch, gold/item count,
actor name and player position. It overrides only the save filename into an
owned output directory, preserving user saves. Original save generation is
active. A peer read will use the two-stream header/contents format and verify
state plus party/actor shared identity, then run resumed map behavior.

F04 permanent link payload and metadata/frozen goldens now replay successfully.
Save interchange is still a distinct contract and cannot be inferred from those
synthetic Marshal roundtrips.

Host read original full save successfully, SAVE_INTERCHANGE_PASS exit0:
variable31415, both switchestrue, gold123/item3, nameSave actor, shared party
actor identity, map1/player3,4. Original reverse read of host Save1 also
completed exit0 with matching values, then ran3 actual map/player/timer updates
and retained map1/variable31415/shared actor identity. Host same continuation
replay is active. This is one controlled save snapshot, not UI slot/corruption
coverage or long resumed gameplay.

Host continuation also passed exit0. Original8-row state ledger is now pinned
and compared by the registered --events owner; replay is active. Original full
save payload still resides in the owned fixture project and must be captured
permanently before cleanup. Longer rendered resumed-map acceptance remains open.

Original snapshot is now permanent tests/fixtures/save_interchange_original.rvdata2,
86535 bytes, SHA256b0fe8cc629a88d4c7b00bcfa4a466efe85de58352b0d158e8d5ada4230359779.
The owner uses this payload instead of the temporary project. Actual Scene_Map
resumed for180 rendered frames, state and shared identity remained correct;
SAVE_INTERCHANGE_PASS exit0. resumed-map.png is captured; independent visual
verdict is pending. This is finite resumed gameplay, not long-run save acceptance.

F02 local finite acceptance complete: controlled full saves load in both
directions, eight state/identity rows match, both update restored game objects,
and host resumes180 rendered Scene_Map frames. Independent image inspection
st_01a1d528 passed: populated terrain and intact characters, no placeholders,
unintended UI or clipping. Player deliberately moved to3,4 (water); that
fixture coordinate was preserved. Slot/corruption handling remains F03;
other games and long-run/runtime-platform coverage remain F09/F10/F11.
