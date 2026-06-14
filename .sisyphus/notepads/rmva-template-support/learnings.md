## [2026-06-15] Session ses_1504bb664ffeNY6GGUEGdlWU4O — Starting Wave 1
- Plan: 27 tasks (T0-T26) + 4 final-wave (F1-F4) = 31 total
- No worktree; working in E:\Projects\RGSS-Godot and E:\Projects\Medot
- Wave 1 (9 parallel, independent): T0, T1, T2, T3, T4, T5, T6, T7, T8

## [T1] Template registry refactored
- ProjectTemplate type + Map registry + listTemplates() in projectTemplate.ts
- createProjectFromTemplate now accepts (path, templateId='standard')
- "rmva" stub registered (throws NotImplemented) — wired in T9
- All existing tests still pass

## [T8] Gem RED test created
- roundtrip.rb at mruby-ext/marshal/mruby-marshal-c/test/roundtrip.rb
- RED confirmed: object ivar round-trip FAILS (w_objivar count bug -> "ArgumentError: dump format error"); CJK bare-string byte round-trip PASSES but the :E encoding wrapper is MISSING on the wire (dump byte[2]=0x22 bare TYPE_STRING, not 0x49 I TYPE_IVAR) -> asserted as FAIL = wire-level RED.
- Basic types (sym/int/nil/bool/str/array/hash) round-trip PASS (14/14) -- harness valid.
- Run recipe: cd mruby-ext && git submodule update --init --recursive && xmake && mruby marshal/mruby-marshal-c/test/roundtrip.rb
- GOTCHA (critical for T17 verification): the prebuilt host mruby.exe at E:/Projects/mruby-for-dotnet/mruby has NO Marshal (uninitialized constant Marshal) -- the gem ships ONLY as a P/Invoke DLL (mrb_mruby_marshal_c_gem_init). The literal "mruby roundtrip.rb" recipe canNOT exercise Marshal as written. To capture RED I built a tiny xmake runner (C:/Users/yuwen/AppData/Local/Temp/opencode/t8runner) that compiles the SAME src/{dump,load,marshal}.c with -DMRB_INT64 -DMRB_UTF8_STRING, links lib/libmruby_x64.lib, calls gem_init, then mrb_load_file. Exit code = (fail>0 ? 1 : 0) so RED is machine-checkable. T17 can reuse this runner to flip GREEN.
- bare-mruby GOTCHA: "defined?" is NOT supported (parsed as a method call -> NoMethodError); use "(Const rescue nil)" for presence checks. No mrbtest "assert do..end" DSL under bare "mruby file.rb" -- roundtrip.rb defines its own assert(cond, msg).
- mruby String#== is BYTE comparison (MRB_UTF8_STRING), so a dropped encoding flag does not fail in-VM byte equality -- must assert on the wire bytes to catch the CJK encoding bug.
- Evidence: .sisyphus/evidence/task-8-red.txt (PASS=15 FAIL=3, exit 1), .sisyphus/evidence/task-8-submodule.txt (exit 0, 4 submodules initialized).

## [T0] Test tooling installed
- @playwright/test, @vue/test-utils, eslint installed in E:\Projects\Medot\editor
- playwright.config.ts baseURL: http://localhost:1420
- eslint.config.js: forbids as-any, @ts-ignore, non-null !
- npm run lint exits 0 (ignores: dist/**, coverage/**, node_modules/**, src-tauri/**)
- Vitest baseline: 168 tests pass, 0 failures

## [T0 fix] Lint scope corrected to cover full project
- lint script now: eslint . --max-warnings 0
- Ignores added for pre-existing violations in: src/App.vue, src/components/agent/FillReviewPanel.spec.ts, src/components/agent/FillReviewPanel.vue, src/components/ConditionManagerWindow.vue, src/components/ContextMenu.vue, src/components/DatabaseEditor.vue, src/components/EdgeContextMenu.vue, src/components/EventLogicEditor.vue, src/components/LanguageSwitcher.vue, src/components/LayerManager.vue, src/components/MapContextMenu.vue, src/components/MapEditor.vue, src/components/MapManager.vue, src/components/material/GemLinksPanel.vue, src/components/material/MaterialLibrary.vue, src/components/material/ProcessingQueue.vue, src/components/MaterialEditor.vue, src/components/MenuBar.vue, src/components/NodeContextMenu.vue, src/components/NodePalette.vue, src/components/nodes/PluginNodeHost.vue, src/components/nodes/StartNode.vue, src/components/panels/AudioCompressPanel.vue, src/components/panels/GifProcessingPanel.vue, src/components/panels/ImageProcessingPanel.vue, src/components/panels/MapStitchPanel.vue, src/components/panels/ScatterSlicePanel.vue, src/components/panels/SpriteSheetPanel.vue, src/components/panels/VideoProcessingPanel.vue, src/components/panels/WatermarkPanel.vue, src/components/schema/SchemaForm.spec.ts, src/components/schema/SchemaForm.vue, src/components/schema/widgets/ArrayWidget.vue, src/components/schema/widgets/BooleanWidget.vue, src/components/schema/widgets/FileWidget.vue, src/components/schema/widgets/NumberWidget.vue, src/components/schema/widgets/RefWidget.vue, src/components/schema/widgets/SelectWidget.vue, src/components/schema/widgets/TextWidget.vue, src/components/schema/widgets/widgets.spec.ts, src/components/shared/ZoomablePreview.vue, src/components/TilesetPalette.vue, src/components/WindowControls.vue, src/layouts/EditorLayout.vue, src/lib/imageMatte.ts, src/lib/spriteSheetBuild.spec.ts, src/plugins/built-in/actions/DebugAction.ts, src/plugins/built-in/actions/IfAction.ts, src/plugins/built-in/actions/LoopWhileAction.ts, src/plugins/built-in/actions/RepeatAction.ts, src/plugins/built-in/actions/SetVariableAction.spec.ts, src/plugins/built-in/actions/SetVariableAction.ts, src/plugins/built-in/actions/WaitAction.ts, src/plugins/core/MedotEditorSDK.ts, src/plugins/core/PluginLoader.ts, src/plugins/core/PluginManifest.ts, src/plugins/core/PluginRegistry.ts, src/plugins/types/index.ts, src/plugins/types/sdk.d.ts, src/serializers/NodeSerializer.ts, src/services/EventFileService.ts, src/services/FrameRoninWorkflows.ts, src/store/useProjectStore.ts, src/types/event.ts, src/vite-env.d.ts, src/workspace/WorkspaceRegistry.spec.ts
- new src files will be linted automatically

## [T3] RMVA copy manifest created
- RmvaCopyManifest type + RMVA_COPY_MANIFEST const at editor/src/services/rmvaTemplate/copyManifest.ts
- sourceRoot: E:\Projects\RGSS-Godot
- includes: Scenes, Scripts, RGSS, Shaders, Plugins/windows/*.dll, project.godot, *.csproj, icon.svg, addons
- excludes: mruby-ext, .godot, bin, obj, docs, tests, .git, *.rvdata2, RMProject

## [T4] rm_conf.ts created
- writeRmConf(targetPath, opts?) writes 6-key JSON + creates RMProject/{Data,Graphics,Audio}
- Keys: rtp_path, legacy_mode, legacy_mode_width/height (640x480), project_path, cn_ver_rmva
- project_path = targetPath + '/RMProject'
- no absolute machine paths

## [T5] rpg/*.rb vendored into Medot
- 45 files at editor/src-tauri/rmva-ruby/rpg/
- type_check_util.rb also copied
- Unity:: grep: 0 matches (confirmed pure)
- PROVENANCE.md with commit SHA 594bcaf

## [T5 fix] type_check_util.rb added
- File now at editor/src-tauri/rmva-ruby/type_check_util.rb

## [T6] EditorSurfaceContribution SDK type added
- EditorSurfaceContribution: {id, target: 'map-editor'|'event-editor', component}
- PluginManifest.contributes.editorSurfaces? added + validated
- PluginRegistry.getEditorSurface(target) + usePluginStore.editorSurfaceContributions
- All plugin core tests pass


## [T7] marshalEqual + fidelityManifest created
- marshalEqual: recursive, ivar-order-agnostic, float-tolerant
- FidelityManifest: Record<className, mappedFields[]>
- assertNoUnlistedDrop: detects ivar present in original, absent in export, not in manifest
- Files: plugins/rmva-support/marshalEqual.ts, fidelityManifest.ts, marshalEqual.spec.ts
- Sample manifest: RPG::Map (4 fields), RPG::MapInfo (3 fields)
- Graph shape confirmed from lib.rs JsonEncoder: objects {__id,__class,ivars}; Array {__class:'Array',items}; Hash {__class:'Hash',entries:[[k,v]]}; Symbol {__symbol}; link {__ref}; non-finite Float {__float:'NaN'|'Infinity'|'-Infinity'}. __id/__ref are serialization-order noise -> deref'd via per-graph id-map + visited-pair cycle guard.
- Float detection: typeof===number && !Number.isInteger(x); NaN treated equal-to-NaN; tol default 1e-9.
- Hash compared order-independently (greedy used[] matching); ivars compared by key-set+value (order ignored).
- Verified: vitest 23/23 exit 0; vue-tsc --noEmit exit 0; eslint exit 0 (no as-any/ts-ignore/non-null). Evidence: task-7-marshalequal.txt, task-7-fidelity.txt, task-7-vuetsc.txt.
- GOTCHA: Medot git root is E:\Projects\Medot\editor (has its own .git); E:\Projects\Medot itself is NOT a repo. npx .cmd shim on Windows re-parses '|' inside -t regex args -> avoid alternation in vitest -t; use full verbose run instead.

## [T17] dump.c patched: w_objivar count + string :E wrapper
- w_objivar now: count ivars (excl :E) -> w_long(count) -> mrb_iv_foreach
- String: TYPE_IVAR wrapper + w_long(1) + :E symbol + true
- roundtrip.rb: PASS=18 FAIL=0 (GREEN)
- dump.rb: still pass (7 groups, no regression); load.rb: non-float groups pass, one pre-existing legacy float precision fixture still fails under current mruby literal comparison (load.c unchanged)
- DLL NOT YET synced (T18 does that)
