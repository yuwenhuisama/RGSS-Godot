# Tilemap verification

## D01 tile types and autotiles

Baseline: installed Windows RGSS300, original isolated fixtures prepared by
`tools/prepare_original_fixture.rb`. Source game files remain unchanged.

The shared `tests/fixtures/tilemap_reference.rb` builds nine synthetic tileset
images with coordinate-coded 16x16 quarters. It does not copy the renderer's
autotile tables into expected results.

```text
Godot --path . -s tests/run_render_reference.gd -- --tiles
Godot --path . -s tests/run_render_reference.gd -- --tiles --tile-animation
Godot --path . -s tests/run_render_reference.gd -- --tiles --tile-tables
Godot --path . -s tests/run_render_reference.gd -- --tiles --tile-render
Godot --path . -s tests/run_render_reference.gd -- --tiles --tile-tables --tile-render
```

Measured acceptance:

- All 7,296 IDs: B/C/D/E 0..1023, A5 1536..1663, and A1-A4 2048..8191.
  The four-quarter TSV matches the original exactly, including unused shapes.
  Its normalized SHA256 is
  `ef707ca84b82d76d7633ba72881e71f0b8f60b7514996429aba069042d39ceec`.
- All 34 complete 544x416 RGBA pages match the original byte for byte:
  905,216 bytes per page, zero differing bytes, maximum channel delta zero.
  Two contact sheets cover every page; independent visual inspection passed
  all 7,296 cells, with only tile 0 and the final page's expected remainder empty.
- All 16 A1 types across 100 updates match the original's 116-row output.
  Static types 2 and 3 remain static; water and waterfalls change on updates
  30, 60 and 90. The normalized reference SHA256 is
  `cd9527a383616bdf59013f00b4ede1d9261fce28416c033d1e6da57688b233f5`.
- All 1,536 A2 table-flag IDs match eight-height-point original samples.
  Their seven complete RGBA pages also match byte for byte. Independent visual
  inspection passed all seven pages and their expected eleven trailing cells.

Cause fixes were demonstrated by original differences and failing regressions:
six waterfall atlas origins selected the wrong columns; unused wall and
waterfall shapes must repeat the first source quarter; static A1 types wrongly
received animation offsets; rendering before the Ruby update delayed animation
boundaries by one frame. `Graphics.update` now synchronizes current drawing
state before yielding, without advancing effect clocks twice.

After the final production change, the complete 18-runner suite and the Graphics
brightness/snapshot regression passed. The animation reference digest passed
after its assertion was added. These results establish the local tile decoding
and animation scope; map occlusion, looping, scrolling and table edges crossing
map cells remain D02 work. Other platform exports remain F10 work.

Evidence: original raw pages are under the owned `d01-render` and
`d01-table-render` run directories. Contact sheets are retained under
`.omo/evidence/rmva-compatibility/godot/tilemap-contact-{0,1}.png` and
`tilemap-tables-contact-0.png`. Godot page filenames are shared between variants;
the table run replaced pages 0..6 after the static sheets had been made.

## D02 current evidence

`tilemap_scroll_reference.rb` covers thirteen scrolling origins, including
negative and tile-boundary coordinates, eight actor/star-flag occlusion states,
map and flag mutation, all sixteen shadow combinations, top-layer drawing over
shadow, flash-data mutation and forty updates of a complete flash cycle.

All 84 rows match the original exactly, with normalized SHA256
`70fa16fad024a75bbf69994727389a6a1886c86759a51c54505a6671697e2fb2`.
All 84 complete 544x416 frames also match byte for byte after both fixtures
explicitly draw the same black background. Raw capture size is 76,038,144 bytes.
Five contact sheets cover every state; their independent visual verdict is
pending. A separate 48-shape table-edge probe matches eight boundary samples
for each shape.

`map_camera_reference.rb` drives the real stock `Game_Map` with 10x8 and 40x30
maps, four loop modes, negative/fractional/large display positions, and scrolling
100 tiles in each direction. All 64 rows match the installed original, with
normalized SHA256
`342899eac911723a17f53e4c4aa1cc92948e1b38c81e371cee4eae2aea597f45`.
`test_map_camera.gd` asserts that complete reference and passed. The first
original fixture failed because cold-loaded stock scripts lacked `$data_system`;
its recorded error identified vehicle initialization, and the fixture now
supplies `RPG::System.new` when needed.

Two production causes were reproduced and repaired. Tilemap cache identity
checks missed in-place Table writes; map, flags and flash data now carry and
compare content revisions. Flash intensity was incorrectly halved; the original
40-frame cycle establishes full 120..240 additive intensity with a 32-update
period. Corrected regression assertions failed before each repair. After the
last production edit, all 18 unified runners passed. The independent full-frame
visual check passed all five sheets.

The 84-frame independent check passed all five sheets. Its observation that the
initial eight occlusion states all showed the actor led to a stronger probe
rather than accepting indistinguishable states as star-priority coverage.
`tilemap_occlusion_reference.rb` now tests all three map layers, flags 0/16 and
actor Z values -1/0/100/199/200/201: 36 rows match the original exactly, normalized
SHA256 `ae8433d5b199832ceaf763b80b7fb53dfc9129d5516e2cf3a8d2a7caa3a112f0`.
The original promotes star tiles only on layer 2. At equal Z, the later actor
wins; lower actors are hidden. The fixes restore semantic tile-layer Z before
each sort and use the owning Tilemap creation order instead of lazy layer-node
creation order. The complete suite passed 18 runners after the final change,
and the 84-state reference passed again. Independent inspection of the fresh
192x192 native-scale 6x6 occlusion grid passed: all 36 cells are filled and crisp,
with rows 0-4 red in column 0 and yellow in columns 1-5, and row 5 red in
columns 0-3 and yellow in columns 4-5. This checks the rendered color layout;
the original TSV comparison establishes its association with the logical states.
D02 is accepted against the installed original baseline.
