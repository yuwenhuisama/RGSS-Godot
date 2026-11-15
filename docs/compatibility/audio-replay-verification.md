# BGM and BGS replay behavior

E06 remains open. The shared `audio_replay_reference.rb` measures an OGG
BGM's position before and immediately after same-file volume change, then
after four frames; BGS starts alongside BGM and stops independently. It also
checks explicit seek4096 and position after a100ms BGM fade. Original RGSS300
run is active. These are API position observations, not audible mix acceptance.

Current streamed-ME fix and its fade callback are owned by E07. The unified
event suite is running on the previous build; the fade callback rebuild waits
until the suite exits to keep the same assembly throughout the run.

Original exited0: initial8006, same-file volume change8006 (no rewind),
four frames later11092. BGM and BGS independently report19912/7564;
after BGS stop BGM stays19912 and BGS retains8886. Seek4096 returns4096;
fade preserves4096 after stopping. Host replay currently always replaces the
stream and calls Play(pos); same-file rewind is a candidate defect requiring
host execution, not yet fixed. Position retention and format units remain open.

`test_audio_replay.gd` now owns same-file no-rewind behavior through the real
Ruby Audio API, checks continued playback and stopped BGM/BGS players, and
requires fixture fiber completion. Host reproduction is active on the current
assembly; no production replay logic has been changed.

Host reproduction exited1: initial0.17414966, same-file volume0.00580499,
later0.06965987. This confirms actual rewind when changing only volume. The
original fixture now adds same-file explicit seek4096 while active, to determine
whether replay must ignore all position arguments or only default0. Original
boundary run is active; production fix waits on this contract.

Original active same-file seek4096 retains10652 rather than seeking; explicit
seek after stop still returns4096. The playback owner now updates volume/pitch
in place for an active BGM/BGS whose requested filename matches, ignoring the
position parameter as original does. New file or stopped player still takes
the loader/start path. C# diagnostics are clean. Build/replay waits until the
current suite completes. That suite has now reported a map-screen failure:
snow particle x=-111 outside the asserted RGSS bounds; investigation pending.

Weather investigation found stock storm motion x-=3 with opacity-=12,
respawn only below64, and sprite reuse when switching weather types. A
particle startingx=-100/opacity160 can reachx=-124 atopacity64 before
respawn, so the suite's fixed-110 minimum is a candidate test-contract error.
An isolated original stock Weather probe is active to prove that reachable
state before changing the bound assertion. No weather production code changed.

Original edge probe exited0 and confirmed storm(-124,-152,64), unchanged
on switching to snow, then reborn at the next update. Weather assertion now
derives maximum age=floor((255-opacity)/12) from stock lifetime, using worst
inherited stormdx=-3/dy=6 rather than a guessed fixed range. Exact three-row
original edge is pinned and compared by the map-screen owner. Its147-row and
pixel-hash assertions are preserved. Targeted replay is active.

Targeted map-screen replay completed MAP_SCREEN_RENDER_PASS, exit0, including
the exact original lifetime edge,147 deterministic rows and preserved RGBA
hashes. Only the proven erroneous random-particle bounds were corrected.

The replay original now adds same-file pitch120 and BGS same-file volume/seek
to determine whether the no-rewind rule also applies to those inputs. This
boundary run is active; no additional production replay changes yet.

Original boundary exited0: same-file pitch change resets10652->0, while BGS
same-file volume/seek retains7500. The no-rewind fast path now requires
unchanged pitch as well as active same filename. Pitch changes still reload
and restart. The regression distinguishes both behaviors and BGS no-rewind;
C# diagnostics are clean. Build and host green remain pending suite completion.

Build completed exit0 with seven existing warnings. Host corrected replay
completed AUDIO_REPLAY_PASS exit0: volume retains0.1625396758, same-file seek
retains0.2263945639, pitch change restarts0.0058049886, BGS same-file retains
0.203174606. This closes the same-file replay defect; E06 remains open on
position units/retention, looping metadata and audible fade/mix acceptance.
