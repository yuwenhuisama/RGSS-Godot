# RPG data default fields

F01 is open. `rpg_defaults_reference.rb` constructs45 RPG classes including
nested frame/timing/condition/effect/vehicle types, records their instance
fields, normalized default values, getter and setter availability. Map3x2 and
Event1,2 use their required constructors. Tables include dimensions; collections
are normalized without object-address inspect strings. Original RGSS300 run
is active. Loaded database values and cross-runtime serialization remain to be
verified separately; the manifest alone is not an implementation pass.

First run timed out after31 rows at Animation::Timing. Exception-capture
rerun diagnosed TypeError: can't convert TrueClass into Color, from the
fixture's generic value==true classification. The descriptor now checks
TrueClass/FalseClass by type and records Color channels explicitly. This is a
fixture correction, not a production fix. Revised original run is active.

Revised original completed45 classes/418 rows exit0, normalized SHA256
2fc84c88c692213cd627c5d7c292628f873f36275ad88d6888aa8a3fcb71b987.
`test_rpg_defaults.gd` loads all shipped RPG class files and compares the same
field/value/accessor output. Its first headless host run is active. F01 is
not accepted before this comparison and loaded-data verification.

Host produced418 rows but failed exact comparison. Differences: Map initialized
battleback_floor_name/wall_name instead of public battleback1_name/2_name;
Table missing dimensions report0 versus original1 for Animation::Frame,
Class params and Tileset flags. Map initializer names are corrected at cause.
Existing value-semantics test asserts two-dimensional zsize0, conflicting with
this original evidence. A separate original Table constructor/resize/index/
Marshal-header probe is active before changing Table semantics or its owner.

Table probe first failed because original enforces index argument dimensionality:
ArgumentError wrong number of arguments(1 for2). The probe now records those
expected ArgumentErrors per requested index count, alongside valid values and
the native _dump(0) header using unpack(C*) for the original Ruby API. No Table
implementation change has been made before reading the complete contract.

Original Table probe completed12 rows exit0. Omitted dimensions are1, explicit
zeros stay0, index arity equals constructor/resize dimensionality, and the
Marshal header records dimension1/2/3. Table wrapper now preserves arity and
defaults to1; storage allocates the actual dimensional product, including0.
Dump/load preserve dimension count. The old 2D test actually created3D with
z=0 and wrote2D indices; it was corrected to a true2D table with original
zsize1, preserved cells and an ArgumentError check for3D access. The independent
12-row hash is6fe80f02baba72c7fd437dfcc4a0cb63ca73155b0f0229478773794e44ab0e8b.
Build exit0; Table and RPG defaults green comparisons are active.

Host TABLE_DIMENSIONS_PASS and RPG_DEFAULTS_PASS, both exit0: all12 Table
rows and418 RPG default-field rows match original. These owners are now
registered headless. Existing API/resize regression is active. F01 remains open
for loaded database fields; default parity alone does not prove load/save data.

Value-semantics7 checks passed. API first replay failed one old assertion
expecting1D ysize0; the independently measured original requiresysize1/zsize1,
so the owner assertion was corrected with both values. The prior compound
PowerShell command's exit0 is invalid evidence (shell expanded LASTEXITCODE);
its failure output was retained. API is now running directly for reliable exit.

Direct API regression completed83/83, RGSS_API_TESTS_PASS exit0. The changed
Table contracts now have original12-row parity plus existing value/API coverage;
45 RPG default types/fields remain exact. Loaded game database and full-scene
impact remain the next F01 checks, not implied by these headless results.

Original loaded-data probe completed exit0 for15 actual files: actors,
animations, armors, classes, common events, enemies, items, Map001, MapInfos,
skills, states, system, tilesets, troops and weapons. It recursively records
every instance field, primitive, raw string bytes and complete Table dump;
reads source files only and writes canonical artifacts into its isolated
project. Host same-fixture byte comparison is active. This is one source-game
database, not a third-party or full-game acceptance claim.

Host loaded15 database files exactly, RPG_DATABASE_PASS exit0. Initial isolated
test missed the Regexp dependency used by Dir.glob; full extension bootstrap
resolved that test setup gap. Real Boot/map regression completed21 scenarios,
EVENT_MAP_PASS exit0 after Table changes. Database owner is registered headless;
its original canonical artifacts still reside in the owned fixture directory
and must be made permanent before temporary fixture cleanup.

Original15 canonical outputs are now pinned by name, exact byte length and
SHA256 in tests/fixtures/rpg_database_original_hashes.tsv. The owner no longer
depends on temporary original project files; replay of this permanent ledger
is active. Source-game contents are the measured baseline and changes to that
source require a new authorized capture rather than changing hashes silently.

F01 local finite acceptance complete:45 classes/418 defaults+accessors,
12 Table dimension/index/dump rows,15 complete loaded database artifacts and
21 real-map scenarios passed. Permanent database ledger replay passed exit0.
Map field names and Table omitted-dimension/arity/storage/header causes were
fixed; API83 and value-semantics7 passed. Other game data sets, custom subclasses,
save interchange and platform coverage remain F02/F04/F07/F09/F10 scopes.
