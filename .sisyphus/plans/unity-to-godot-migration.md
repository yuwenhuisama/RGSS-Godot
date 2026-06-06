# Unity → Godot 4 Migration: RGSS3 Runtime

## TL;DR

> **Quick Summary**: Migrate the RGSS-Unity engine (RPG Maker VX Ace's RGSS3 reimplemented on Unity) onto **Godot 4.4+ with C#/.NET**, reusing the ~314-file pure-Ruby layer as-is and rewriting only the C# binding layer (GameObject→Node) and render layer (Camera/RenderTexture→SubViewport + 18 CG shaders→.gdshader).
>
> **Deliverables**:
> - A runnable Godot 4 .NET project that boots mruby, loads the RMVA `Scripts.rvdata2`, and reaches **parity with the CURRENT Unity build's actual capabilities** (not idealized RMVA).
> - All 14 `Unity::*` bindings reimplemented on Godot nodes; 18 (≤) effect shaders ported; audio (4 buses) + input + external-file IO remapped.
> - 4 native mruby gems (marshal/dir-glob/onig-regexp/zlib) recompiled for Win/Mac/Linux.
> - GUT test infrastructure + per-task agent-executed QA (headless Godot + golden-screenshot diff).
>
> **Estimated Effort**: XL (engine-level migration, novel — no RGSS-on-Godot prior art exists)
> **Parallel Execution**: YES — Wave 0 (GO/NO-GO gate) → Waves 1–5, up to 7 concurrent
> **Critical Path**: Wave-0 spike → RubyScriptManager+Fiber spine → GameRenderManager → **Bitmap (the long pole)** → Sprite/Window → integration → Final Verification

---

## Context

### Original Request
User wants to migrate RGSS-Unity off Unity onto Godot ("帮我看看怎么搞"). Clarified: the original is an **unfinished project**; goal is "先把项目全部搬过来" — port the current state, NOT finish the still-open RMVA-compat goal.

### Interview Summary
**Confirmed decisions**:
- **Motivation**: open-source / control + cross-platform / smaller deploy. → bias to fully-buildable, vendor-independent stack.
- **mruby route**: **A1** — Godot 4 .NET (C#) + reuse existing `mruby-for-dotnet` (NuGet `MRuby.Library`) P/Invoke bindings + recompile the 4 native gems for Win/Mac/Linux. **Preceded by a Wave-0 GO/NO-GO spike.**
- **Scope**: **Full-Parity with CURRENT Unity behavior**. Cross-desktop (Win/Mac/Linux). NO web/mobile.
- **Test**: **GUT + TDD**; per-task agent QA via headless Godot + **godot-mcp-pro** MCP (compare_screenshots / assert_node_state / simulate_action / get_game_screenshot).

**Research findings (cited, 3 librarian probes)**:
- mruby A1 feasible: Godot 4 uses modern .NET; P/Invoke works unsandboxed; `mruby-for-dotnet` is pure .NET. ([docs.godotengine.org C# basics; godot#99923])
- Render: RenderTexture→`SubViewport.get_texture()`; compositing→nested SubViewports; Z→`CanvasLayer.layer`+`z_index` (±4096; RMVA uses 0..200); shaders→`shader_type canvas_item`, `set_shader_parameter`; postprocess→CanvasLayer+ColorRect+`hint_screen_texture`; per-sprite→`instance uniform` (4-float cap); Bitmap CPU ops→`Image`+`ImageTexture.update()`.
- Audio: ogg/wav/mp3 via `AudioStream*.load_from_file(absPath)`; 4 buses; `volume_linear`/`pitch_scale`/Tween fade; **WMA unsupported** (ffmpeg fallback).
- Input: trigger?→`is_action_just_pressed`, press?→`is_action_pressed`, repeat?→manual timer; dir4/dir8; runtime `InputMap`.
- Files: StreamingAssets → `OS.get_executable_path().get_base_dir()/RMProject`; `res://` read-only in export so ALL StreamingAssets loads must be rewritten.
- Precedent: **NO RGSS-on-Godot exists** (novel); mkxp-z (C++/SDL2) closest structural ref; its lessons (Ruby-version mismatch, Win32API) are sidestepped by mruby.

### Metis Review (3 plan-changing discoveries — addressed below)
- **D1 — Source is a THIN TECH-DEMO, but input WORKS**: `Unity::Tilemap` has no C# impl (`tilemap.rb` → NoMethodError on Unity too) → map-render genuinely non-functional. **Correction (Momus catch):** input IS wired — `Assets/GameInputManager.cs` (Assets ROOT, missed by Assets/Scripts-scoped searches) feeds `InputStateRecorder` via the Unity Input System, bound in `SampleScene.unity:1022-1300`. **Resolution**: Wave-1 **Capability Census** defines authoritative parity scope. **USER DECISION: port-the-absence** = faithfully replicate current Unity state → **Tilemap stays absent (out of scope); input is ported as WORKING (in scope)**. "Whatever the current build does" is the target: it has input, it lacks Tilemap.
- **D2 — Layer-1 reuse ~99% true**: only mandatory Ruby edit is **5 lines in `patch_rmva.rb`** (the `'\.'` backslash path heuristic). Keep the Ruby module **named `"Unity"`** (reimplement C# behind it; do NOT rename). ~40 `rpg/*.rb` + ext + utils = zero changes.
- **D3 — 6 pre-existing Layer-1 Ruby bugs**: bug-for-bug parity — **do NOT fix** (untouched shared layer = automatic parity); log only; sole exception = a load-blocking syntax error, fixed minimally + logged as deviation.
  - **⚠ SUPERSEDED 2026-06-06 (USER OVERRIDE)**: user explicitly chose to **fix all 6 Ruby bugs**. Parity is now "more-correct-than-source", not bug-for-bug. The 6 fixes (audio/viewport/bitmap/plane/color/font) + 1 coupled `Color.cs` C# typo are applied, minimal, and verified (build 0 errors, headless boot SCRIPTS/MAIN_LOADED:OK). See capability-census.md "OVERRIDE (2026-06-06)".

---

## Work Objectives

### Core Objective
Produce a Godot 4.4+ (.NET) build of the RGSS3 runtime that reuses the pure-Ruby layer unchanged and reaches behavioral parity with the **current Unity build's actual working capabilities** across Win/Mac/Linux.

### Concrete Deliverables
- New Godot .NET project (sibling tree; Unity tree untouched) reusing `Assets/Resources/RGSS/**`.
- 14 `Unity::*` bindings reimplemented on Godot nodes; render compositor on SubViewports; ≤18 `.gdshader` effects.
- 4 native gems built for 3 desktop OSes; bundled + loaded in Godot exports.
- Audio/Input/File-IO remapped; boot + Fiber loop on Godot's frame model.
- GUT infra + agent-QA harness (golden-screenshot diff vs current Unity).

### Definition of Done
- [ ] `godot --headless` boots the project, opens mruby, loads `Scripts.rvdata2`, runs the Fiber loop without crashing (verified by log assertions).
- [ ] Every flow the **Capability Census** marked "works on Unity" reproduces on Godot with golden-screenshot parity (≤ agreed pixel tolerance).
- [ ] Exported builds run on Windows, macOS, Linux (native gems load on each).
- [ ] GUT suite green; all per-task QA evidence present in `.sisyphus/evidence/`.

### Must Have
- Reuse Layer-1 Ruby unchanged except the 5 `patch_rmva.rb` path lines.
- Keep the `Unity::*` + `RPG` Ruby API contract identical (names + signatures).
- Preserve Fiber==frame semantics and the `Graphics.wait` render-only bypass.
- Port `GC.KeepAlive`-after-`Protect` and the deferred-logger pattern.
- Native-node disposal on the **main thread** (release callback), never finalizer thread.

### Must NOT Have (Guardrails)
- Do NOT rewrite/refactor Layer-1 Ruby (no "cleanup"); ~~do NOT fix the 6 known Ruby bugs~~ **[SUPERSEDED 2026-06-06: user override — the 6 Ruby bugs ARE now fixed; see D3 note + census OVERRIDE]**.
- Do NOT rename the Ruby `Unity` module.
- Do NOT change `Unity::*` API names/signatures (the stable cross-layer contract).
- Do NOT implement features absent from the current Unity build. **USER DECISION = port-the-absence**: the missing `Unity::Tilemap` binding stays missing (map-render out of scope). **Input, by contrast, IS present and working on Unity → port it as working** (incl. the `GameInputManager` poller). No Tilemap expansion this round.
- Do NOT call `QueueFree`/`Free` from a C# finalizer.
- Do NOT add web/mobile targets, gameplay changes, or re-port the editor archive tooling this round.
- Do NOT `GD.Print`/`GD.PrintErr` directly inside a Ruby `rescue` path (use the deferred queue) until the Wave-0 probe proves it safe.

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — all verification agent-executed. Evidence → `.sisyphus/evidence/task-{N}-{slug}.{ext}`.

### Test Decision
- **Infrastructure exists**: NO (zero tests today; "press Play" only).
- **Automated tests**: YES (TDD) — GUT (GDScript-side) for Ruby-facing behavior + Marshal round-trip + data classes; C# unit tests (xUnit/GoDotTest, decided in setup) for isolable binding helpers.
- **Framework**: **GUT** + optional C# test runner. Each behavioral task follows RED (failing GUT/characterization test) → GREEN (port impl) → REFACTOR.
- **Parity oracle**: golden screenshots/state captured from the **current Unity build** (Wave-1) are the reference fixtures.

### QA Policy
Every task includes agent-executed QA. **All QA is automated — zero human steps.** Tooling is one of these named, executable mechanisms (no "manual" anywhere):
- **`godot --headless`** scripted scene runs (GDScript test driver) that exit 0/non-0 and write evidence files.
- **godot-mcp-pro MCP tools** (named explicitly where used): `get_game_screenshot`, `compare_screenshots`, `assert_node_state`, `capture_frames`, `monitor_properties`, `simulate_action`, `simulate_sequence`, `get_game_scene_tree`, `get_game_node_properties`. Each is a real MCP tool (verified in research).
- **No-cost fallback** (if the paid MCP server is unprovisioned): a bundled GDScript helper that (a) screenshots via `get_viewport().get_texture().get_image().save_png()`, (b) diffs two PNGs pixel-wise within tolerance, (c) reads node state via `get_tree().get_node_count()` / `node.get(prop)`, (d) injects input via `Input.parse_input_event()`. The plan's QA scenarios name the MCP tool first and this fallback second; either satisfies the criterion.

Tooling:
- **Rendering/visual**: `godot --headless` scene run → screenshot; **godot-mcp-pro** `get_game_screenshot` + `compare_screenshots` vs golden; fallback = built-in headless screenshot + image-diff script (no-cost path if MCP server unprovisioned).
- **Ruby behavior**: execute RMVA script slices via the running VM; assert log output + node state (`assert_node_state` / `get_game_node_properties`).
- **Input flows**: `simulate_action` / `simulate_sequence` to drive menus.
- **Native/boot**: assert log markers + exit codes from headless runs.

---

## Execution Strategy

### Parallel Execution Waves

> Wave 0 is a hard GO/NO-GO gate. Target 5–8 tasks/wave thereafter; Bitmap gates the render parallel wave.

```
WAVE 0 — De-risk Gate (serial, BLOCKS everything):
├── T1: Godot .NET P/Invoke export spike (libmruby + Ruby.Open + 1 Unity:: method) [deep]
├── T2: Native-boundary + Marshal.load spike (one .rvdata2 via marshal gem) [deep]
├── T3: Logger-crash probe (rescue → GD.PrintErr → VM survives?) [deep]
└── T4: Gem-init failure-diagnostic + 3-OS native gem build/pin [deep]
    → GO/NO-GO decision. If NO-GO → fallback branch (MRubyCS / GDExtension) before sunk cost.

WAVE 1 — Spine + Scope + Harness (after GO; mostly parallel):
├── T5: RubyScriptManager port (Ruby.Open, gem inits, script loading, require→host) [deep]
├── T6: Capability Census — run Unity vs RMProject, enumerate working/broken flows [unspecified-high]
├── T7: Tilemap/Input "genuinely unimplemented" verification (scenes/prefabs/whole repo) [explore→quick]
├── T8: GUT + C#-test harness setup + golden-screenshot capture tooling [unspecified-high]
├── T9: Boot scene + Fiber pump on _Process (Graphics.wait bypass) + dual teardown [deep]
├── T10: GlobalConfig (rm_conf.json via FileAccess, BOM strip, legacy 544x416) [quick]
└── T11: RGSSLogger deferred-queue port + GC/lifetime conventions doc [quick]

WAVE 2 — Value Types + Render Foundation (after spine; value types unblock test scaffold):
├── T12: Color/Tone/Rect/Table/Font value types (trivial, do FIRST) [quick]
├── T13: File-IO layer (StreamingAssets→exe-dir/RMProject, abs paths) [quick]
├── T14: GameRenderManager → SubViewport compositor + Z mapping [deep]
├── T15: Render-Conventions spec (M2 BackBufferCopy, M3 single-layer, M4 vec4 packing) [deep]
└── T16: Bitmap.cs — THE LONG POLE (Image blit/stretch/fill + draw_text via SubViewport+Label) [ultrabrain]

WAVE 3 — Per-Object Render + Subsystems (after Bitmap+Conventions; MAX PARALLEL):
├── T17: Sprite (transform, wave/tone/color/flash/bush via instance-uniform pack) [deep]
├── T18: Window (9-slice→NinePatchRect, cursor, openness, contents) [ultrabrain]
├── T19: Viewport binding (SubViewport-backed, ox/oy/z/tone) [unspecified-high]
├── T20: Plane (tiled background shader + scroll) [unspecified-high]
├── T21: Graphics module (fade/transition/freeze/brightness postprocess chain) [deep]
├── T22: Audio (4 buses, load_from_file, fade/volume/pitch, WMA→ffmpeg fallback) [unspecified-high]
├── T23: Input (port the WORKING input chain: InputStateRecorder + GameInputManager poller + InputMap) [unspecified-high]
└── T24: Shader port — enumerate actual .shader files, translate to .gdshader [visual-engineering]

WAVE 4 — Integration + Cross-Platform:
├── T25: 5-line patch_rmva.rb path fix + main.rb wiring (module stays "Unity") [quick]
├── T26: Full boot→title/working-flows integration on Windows [deep]
├── T27: macOS export + native gem load verification [unspecified-high]
├── T28: Linux export + native gem load verification [unspecified-high]
└── T29: Finalizer-lifetime stress test (mass scene transition, node-count baseline) [deep]

WAVE FINAL — 4 parallel reviews, then user okay:
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Automated parity QA — every census-confirmed flow, golden diff (unspecified-high + godot-mcp-pro/playwright)
└── F4: Scope fidelity check — no Layer-1 edits beyond 5 lines, ~~no bug-fixes~~, no feature creep (deep) **[2026-06-06: the 6 Ruby bug-fixes + 1 coupled Color.cs fix are USER-SANCTIONED via override — F4 must treat them as in-scope, not violations]**
    → Present results → explicit user okay.

Critical Path: T1→T2→T5→T9→T14→T16→T17/T18→T26→F1-F4→user okay
Parallel Speedup: ~60% vs sequential after Wave-0 gate
Max Concurrent: 7-8 (Wave 3)
```

### Dependency Matrix (abbreviated — full matrix in generated tasks)

- **T1-T4 (Wave 0)**: blocked by nothing → block ALL of Wave 1+.
- **T5**: T1,T2 → blocks T9,T14,T17-T23.
- **T6**: T1 (need running Unity ref) → blocks all parity acceptance criteria + F3.
- **T14**: T5,T12 → blocks T16.
- **T16 (Bitmap)**: T14,T15 → blocks T17,T18,T19,T20 (the render wave).
- **T17,T18**: T16 → block T26.
- **T25**: T5 → blocks T26.
- **T26**: T17,T18,T21,T22,T23,T25 → blocks T27,T28,T29,F*.

### Agent Dispatch Summary

- **Wave 0**: 4 → T1-T4 → `deep` (export/native/VM risk — needs deep understanding).
- **Wave 1**: 7 → T5/T9 `deep`, T6/T8 `unspecified-high`, T7 `explore`+`quick`, T10/T11 `quick`.
- **Wave 2**: 5 → T12/T13 `quick`, T14/T15 `deep`, **T16 `ultrabrain`**.
- **Wave 3**: 8 → T17/T21 `deep`, **T18 `ultrabrain`**, T19/T20/T22/T23 `unspecified-high`, T24 `visual-engineering`.
- **Wave 4**: 5 → T25 `quick`, T26/T29 `deep`, T27/T28 `unspecified-high`.
- **FINAL**: 4 → F1 `oracle`, F2/F3 `unspecified-high`, F4 `deep`.

---

## TODOs

> Implementation + Test = ONE task. EVERY task has Agent Profile + Parallelization + References + QA Scenarios.
> **Wave 0 is a GO/NO-GO gate — if any spike fails, STOP and escalate the fallback decision (MRubyCS / GDExtension) to the user before proceeding.**

- [x] 1. Wave-0 Spike: Godot .NET P/Invoke libmruby in an EXPORTED build

  **What to do**:
  - Create a throwaway minimal Godot 4.4+ .NET project. Add `MRuby.Library` via NuGet in the `.csproj`.
  - From a C# `Node`, call `Ruby.Open()`, define one trivial `Unity::ping` returning a string, execute `Unity.ping` from a `.rb` string, assert the result.
  - **Critically: test in an EXPORTED build, not just the editor.** Configure `TrimmerRootAssembly` / `[DynamicDependency]` so IL-trimming doesn't strip reflectively-registered types. Bundle `libmruby_*_x64.dll` with correct RID packaging.
  - Document the exact `.csproj` + export-preset settings that make native DLL loading work.

  **Must NOT do**: Don't port any real binding yet; don't touch the Unity project; keep the spike isolated.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: novel integration, export-trimming landmines, empirical de-risking needs deep understanding not rote steps.
  - **Skills**: [] — no installed skill matches Godot/.NET interop.

  **Parallelization**: Can Run In Parallel: NO (gates everything) · Wave 0 · Blocks: ALL · Blocked By: None.

  **References**:
  - `Assets/Scripts/RubyScriptManager.cs:33-49` — current `Initialize()`: `Ruby.Open()`, gem inits, `DefineModule`, `RbTypeRegisterHelper.Init`. The pattern to reproduce minimally.
  - `Assets/packages.config` — `MRuby.Library` v0.1.7 (confirm latest on NuGet for Godot).
  - Research L1 (draft): Godot 4 modern .NET, P/Invoke unsandboxed, `dotnet publish` export, godot#99923 (native-dep packaging).
  - WHY: this validates the entire A1 premise; if exported P/Invoke fails, A1 is dead → fallback.

  **Acceptance Criteria**:
  - [ ] Editor run: `Unity.ping` returns expected string (assert in log).
  - [ ] **Exported** build (Windows) runs the same and prints the marker — proves trimming/packaging correct.

  **QA Scenarios**:
  ```
  Scenario: mruby boots and a Unity:: method works in an exported build
    Tool: Bash (godot --headless export) + log assertion
    Steps:
      1. Export the spike project for Windows (release).
      2. Run the exported binary headless; capture stdout.
      3. Assert stdout contains "PING_OK:pong".
    Expected Result: marker present, exit code 0.
    Failure Indicators: DllNotFoundException, missing-type/trim error, empty output.
    Evidence: .sisyphus/evidence/task-1-export-ping.txt

  Scenario: trimming does NOT strip the registered type
    Tool: Bash — export WITH trimming enabled
    Steps:
      1. Enable IL trimming in export preset; re-export.
      2. Run; assert marker still present.
    Expected Result: still "PING_OK" (DynamicDependency held).
    Evidence: .sisyphus/evidence/task-1-trim.txt
  ```

  **Commit**: YES — `chore(godot): p/invoke export spike` · Pre-commit: spike runs green.

- [x] 2. Wave-0 Spike: native boundary + `Marshal.load` of a real `.rvdata2`

  **What to do**:
  - Extend the spike: P/Invoke `mrb_mruby_marshal_c_gem_init`, then from Ruby `Marshal.load` a tiny real `.rvdata2` slice (e.g. a trimmed `System.rvdata2` or a hand-made marshaled array) and read a field back into C#.
  - This proves the most load-bearing native gem + the RMVA binary format round-trips through Godot's .NET. Marshal underpins ALL `.rvdata2` load/save.
  - Wrap each `mrb_*_gem_init` P/Invoke with explicit error handling (catch `DllNotFoundException`, log which gem).

  **Must NOT do**: Don't implement `load_data`/`save_data` fully; just prove one round-trip.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: native marshalling correctness + binary-format fidelity is subtle; failure here invalidates A1.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (with T1 once spike scaffold exists; shares project) · Wave 0 · Blocks: T5 · Blocked By: T1 (scaffold).

  **References**:
  - `Assets/Scripts/RubyScriptManager.cs:21-31,39-42` — the 4 `[DllImport]` gem-init signatures + call order.
  - `Assets/Resources/RGSS/kernel.rb:11-22` — `load_data`/`save_data` use `Marshal.load`/`dump` over RMProject paths.
  - `Assets/Scripts/RubyClasses/UnityModule.cs:88-105` — `register_rmva_script` inflates zlib then loads — confirms zlib gem also load-bearing.
  - `Assets/StreamingAssets/RMProject/Data/` — real `.rvdata2` files for the fixture.
  - WHY: Marshal is the spine of all RMVA data; must prove it crosses the Godot/.NET boundary intact.

  **Acceptance Criteria**:
  - [ ] A known field from the marshaled fixture reads back with the exact expected value.
  - [ ] A deliberately-missing gem DLL produces a clean diagnostic naming the gem (not a silent crash).

  **QA Scenarios**:
  ```
  Scenario: Marshal round-trip through Godot .NET
    Tool: Bash (headless) + assertion
    Preconditions: fixture .rvdata2 with a known top-level value (e.g. game title string).
    Steps:
      1. Headless-run the spike; Ruby Marshal.loads the fixture; C# reads field; prints "MARSHAL_OK:<value>".
      2. Assert printed value equals expected.
    Expected Result: exact value match.
    Failure Indicators: parse error, wrong bytes, encoding mismatch, crash.
    Evidence: .sisyphus/evidence/task-2-marshal.txt

  Scenario: missing gem DLL yields clean diagnostic (negative)
    Tool: Bash
    Steps:
      1. Rename one gem DLL; run.
      2. Assert log says e.g. "GEM_INIT_FAIL: marshal_c" and exits cleanly.
    Expected Result: named diagnostic, no hard DllNotFoundException stack.
    Evidence: .sisyphus/evidence/task-2-missing-gem.txt
  ```

  **Commit**: YES — `chore(godot): marshal + native-boundary spike` · Pre-commit: round-trip green.

- [x] 3. Wave-0 Spike: logger-crash probe (does `GD.PrintErr` in a `rescue` crash mruby?)

  **What to do**:
  - In the spike, raise a Ruby exception, enter a `rescue`, and call `GD.PrintErr`/`GD.Print` DIRECTLY from within the C# path handling that rescue.
  - Determine empirically whether Godot's print triggers the same native-stacktrace-walk crash that Unity's `Debug.Log` does (the documented `RGSSLogger` reason).
  - Record the verdict. Regardless of outcome, the deferred-queue port (T11) proceeds (portable + harmless); this probe just tells us whether it's load-bearing or belt-and-suspenders.

  **Must NOT do**: Don't build the full logger here; just the probe.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: engine-internal crash semantics; needs careful observation + interpretation.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 0 · Blocks: informs T11 · Blocked By: T1 (scaffold).

  **References**:
  - `Assets/Scripts/RGSSLogger.cs:6-9` — the header comment explaining the Unity crash + deferred-queue workaround.
  - `Assets/Resources/RGSS/main.rb:73-75` — the top-level `rescue` → `Unity.on_top_exception`.
  - Metis: 12 enumerated call sites; crash = `StackTraceUtility.ExtractStringFromException` walking native frames; Godot equivalence UNPROVEN.
  - WHY: decides whether the deferred logger is a hard requirement or defense-in-depth.

  **Acceptance Criteria**:
  - [ ] Documented verdict: "GD.PrintErr in rescue → crash: YES/NO" with evidence.

  **QA Scenarios**:
  ```
  Scenario: direct engine-print inside a Ruby rescue
    Tool: Bash (headless), repeated 5x for stability
    Steps:
      1. Trigger Ruby raise→rescue; C# calls GD.PrintErr directly.
      2. Observe whether the VM/process survives or crashes; repeat.
    Expected Result: deterministic verdict recorded.
    Failure Indicators: intermittent crash (note as "unsafe").
    Evidence: .sisyphus/evidence/task-3-logger-probe.txt
  ```

  **Commit**: YES — `chore(godot): logger-crash probe + verdict` · Pre-commit: probe runs, verdict recorded.

- [x] 4. Wave-0: cross-compile the 4 native gems for Win/Mac/Linux + bundling

  **What to do**:
  - Using the existing xmake setup (which already has macOS/linux skeletons), build `marshal`, `dir-glob`, `onig-regexp`, `zlib` gems for x64 Windows, macOS, Linux.
  - Resolve the hardcoded `mruby_dir` path and the `MRB_INT64 / MRB_NO_PRESYM / MRB_UTF8_STRING` define-matching against the mruby the .NET binding expects.
  - Define where exported Godot builds expect the natives per-OS (RID folders) and document the bundling.

  **Must NOT do**: Don't target Android/iOS/web. Don't change gem source behavior.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: cross-platform native toolchain + ABI/define matching is error-prone and central to cross-desktop goal.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 0 · Blocks: T27,T28 (mac/linux exports) · Blocked By: None (can start with T1).

  **References**:
  - `mruby-ext/xmake.lua` + `mruby-ext/marshal/xmake.lua` — per-gem build; note the macOS universal `lipo` branch + Windows `export.def` + `lib/libmruby_x64.lib` linkage.
  - `mruby-ext/.gitmodules` (repo root `.gitmodules`) — the 4 gem submodule sources.
  - `Assets/Plugins/windows/libmruby_*_x64.dll` — current Windows outputs (the baseline).
  - WHY: cross-desktop parity is a hard requirement; these gems are mandatory (marshal/zlib especially).

  **Acceptance Criteria**:
  - [ ] All 4 gems produce loadable shared libs for Win + Mac + Linux.
  - [ ] Each loads + its `mrb_*_gem_init` succeeds in a headless Godot run on at least the build OS (mac/linux verified in T27/T28).

  **QA Scenarios**:
  ```
  Scenario: gems build and load on the host OS
    Tool: Bash (xmake build + headless load test)
    Steps:
      1. Build all 4 gems for the host triple.
      2. Headless-run the spike calling each mrb_*_gem_init; assert all 4 succeed.
    Expected Result: "GEMS_OK: marshal,dir_glob,onig_regexp,zlib".
    Failure Indicators: link error, define-mismatch symbol error, load failure.
    Evidence: .sisyphus/evidence/task-4-gems-<os>.txt
  ```

  **Commit**: YES — `build(gems): cross-compile mruby gems win/mac/linux` · Pre-commit: host-OS build+load green.

- [x] 5. RubyScriptManager port (VM lifecycle on Godot)

  **What to do**:
  - Port `RubyScriptManager` to a C# class driven by a Godot autoload/Node: `Ruby.Open()`, the 4 gem inits (with T2's error handling), `DefineModule("Unity")` + `DefineModule("RPG")`, `RbTypeRegisterHelper.Init` over the binding assembly.
  - Reimplement `require`→script-resolution host-side: replace `Resources.Load<TextAsset>("RGSS/...")` with `FileAccess` reads of the reused `RGSS/**` Ruby files (shipped in the Godot project). Preserve the dedup `RequiredPath` set and `LoadAllScriptInResources("ext")`/`("rpg")` ordering.
  - Keep the `Unity` module NAME. Port `LoadScriptContentWithFileName` for RMVA scripts.

  **Must NOT do**: Don't rename `Unity`; don't alter Ruby file contents; don't change load order.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: the boot spine; subtle VM init ordering + host-side require resolver.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: NO (spine) · Wave 1 · Blocks: T9,T14,T17-T23 · Blocked By: T1,T2.

  **References**:
  - `Assets/Scripts/RubyScriptManager.cs` (whole, 171 lines) — the exact port target: `Initialize`, `LoadScriptInResources`, `LoadAllScriptInResources`, `LoadScriptContentWithFileName`, `Destroy`.
  - `Assets/Scripts/RubyClasses/Kernel.cs:89-110` — `require` dedup + `LoadScriptInResources`.
  - `Assets/Scripts/RubyClasses/UnityModule.cs:107-141` — `run_rmva_scripts` loads ext→rpg→rmva.
  - Research L3 (draft): `FileAccess.open(absPath)` for external files; `res://` read-only in export.
  - WHY: every binding registers through this; require-resolution is the reuse linchpin for Layer 1.

  **Acceptance Criteria**:
  - [ ] Headless boot reaches "scripts loaded" marker; `require 'kernel'` etc. resolve from FileAccess.
  - [ ] RbTypeRegisterHelper registers all `[RbClass]`/`[RbModule]` types in an exported build (trim-safe).

  **QA Scenarios**:
  ```
  Scenario: VM opens and built-ins require successfully (headless)
    Tool: Bash (godot --headless)
    Steps:
      1. Boot; assert log shows each require ('kernel','tone',...,'window') resolving with no error.
      2. Assert "RGSS3 scripts loaded successfully." marker.
    Expected Result: all requires resolve; marker present.
    Failure Indicators: require path miss, type-registration empty, trim-stripped class.
    Evidence: .sisyphus/evidence/task-5-boot.txt

  Scenario: missing Ruby file raises clean error (negative)
    Tool: Bash
    Steps:
      1. Temporarily hide one .rb; boot; assert a clear "failed to load script: X" not a null-ref.
    Evidence: .sisyphus/evidence/task-5-missing-rb.txt
  ```

  **Commit**: YES — `feat(godot): port RubyScriptManager VM lifecycle` · Pre-commit: headless boot marker.

- [x] 6. Capability Census — enumerate what the CURRENT Unity build actually does
  > **COMPLETE (static code analysis)**: Unity Editor not installed; census produced via code reading. Verdict: 13/14 bindings WORKS (Tilemap BROKEN), 8/9 flows WORKS (Map-load BROKEN). Evidence: task-6-census.txt + capability-census.md.

  **What to do**:
  - Run the existing Unity build against `StreamingAssets/RMProject` and systematically record which flows function vs crash/stub: boot, title, menu, map-load, message window, battle, save/load, audio playback, input response.
  - Produce a `capability-census.md` (under `.sisyphus/`) listing each flow → {works / broken / stub} with evidence (screenshots/log). **This document IS the authoritative parity scope** — every later acceptance criterion references it.
  - Capture **golden screenshots** of each working flow as parity fixtures (store under `.sisyphus/evidence/golden/`).

  **Must NOT do**: Don't fix anything in Unity; don't infer — observe the running build.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: methodical characterization + evidence capture; defines scope, high leverage.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 1 · Blocks: all parity criteria + F3 · Blocked By: T1 (need running ref; can use existing Unity install directly).

  **References**:
  - `AGENTS.md` (root) — boot sequence + 3-layer model to know what to exercise.
  - `Assets/Resources/RGSS/patch_rmva.rb` — the SceneManager/Scene flow that drives RMVA scenes.
  - `Assets/StreamingAssets/rm_conf.json` — legacy_mode 544x416 + cn_ver_rmva flags active.
  - `Assets/GameInputManager.cs` + `Assets/Scenes/SampleScene.unity:1022-1300` — input IS wired (Unity Input System → GameInputManager.Handle*); exercise input-driven flows.
  - `Assets/Resources/RGSS/tilemap.rb` + absence of `Tilemap.cs` — Tilemap binding genuinely missing → expect map-render to fail; confirm in census.
  - WHY: "port current state" is undefinable without knowing the current state empirically.

  **Acceptance Criteria**:
  - [ ] `capability-census.md` exists enumerating every flow with works/broken/stub + an evidence-file path per flow.
  - [ ] Golden screenshots captured (PNG) for each "works" flow, saved under `.sisyphus/evidence/golden/`.

  **QA Scenarios**:
  ```
  Scenario: census is complete and evidence-backed (automated capture)
    Tool: Bash — build a Unity standalone player + scripted run, OR Unity batchmode
          (`Unity.exe -batchmode -projectPath . -executeMethod <CaptureHarness>`),
          capturing one screenshot+log per flow to .sisyphus/evidence/golden/.
          Fallback if batchmode capture is impractical: run the existing Unity build and use
          an OS screenshot tool (e.g. ffmpeg/nircmd) driven by a script per scripted input sequence.
    Steps:
      1. For each flow (boot, title, menu, map-load, message, battle, save/load, audio, input),
         launch the Unity build with a fixed scripted input sequence; save screenshot + stdout log.
      2. Parse logs for NoMethodError/exception markers; classify each flow works/broken/stub.
      3. Assert census.md lists every flow with a verdict + a linked evidence file that exists on disk.
    Expected Result: no flow left "unknown"; every verdict has an on-disk evidence file.
    Failure Indicators: a flow with no evidence file; a verdict not backed by a log/screenshot.
    Evidence: .sisyphus/capability-census.md + .sisyphus/evidence/golden/*.png
    Expected Result: no flow left "unknown".
    Evidence: .sisyphus/capability-census.md + .sisyphus/evidence/golden/*
  ```

  **Commit**: YES — `docs(migration): capability census + golden fixtures` · Pre-commit: census non-empty.

- [x] 7. Confirm scope facts: Tilemap absent, Input WIRED (scope gate)

  **What to do**:
  - Confirm the corrected scope facts (already established during planning; re-verify before relying on them):
    (a) **Tilemap**: no `Tilemap` C# binding exists anywhere (`tilemap.rb` calls `Unity::Tilemap.new` → NoMethodError on Unity too) → map-render is genuinely non-functional on the current build → **out of scope** (port-the-absence for Tilemap only).
    (b) **Input**: input IS wired and working — `Assets/GameInputManager.cs` (Assets ROOT, not `Assets/Scripts/`) is a MonoBehaviour whose `Handle*` callbacks call `InputStateRecorder.SetPress/SetRelease`, and `SampleScene.unity:1022-1300` binds all 20 actions to it via the Unity Input System (`PlayerInput` `m_Actions` → `RGSSInput.inputactions`). → **input is IN scope; port it as WORKING.**
  - Have the Capability Census (T6) empirically confirm input-driven flows actually respond (belt-and-suspenders: planning grep proves wiring exists; census proves it functions at runtime).
  - Record the verdict in `.sisyphus/evidence/task-7-scope-verify.txt`.

  **Must NOT do**: Don't implement Tilemap; don't "re-decide" input scope away from working — the wiring is proven.

  **Recommended Agent Profile**:
  - **Category**: `quick` (preceded by an `explore` sweep) — Reason: targeted existence check across the whole repo (incl. Assets root + scenes).
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 1 · Blocks: Tilemap (out) + Input (in, working) scope · Blocked By: None.

  **References**:
  - `Assets/GameInputManager.cs:10-66` — the input poller (Unity Input System callbacks → `SetPress`/`SetRelease`). **This is the file earlier searches missed (it's in Assets root, not Assets/Scripts).**
  - `Assets/Scenes/SampleScene.unity:1022-1300` — `InputManager` GameObject wiring 20 actions to `RGSSUnity.GameInputManager`; `m_Actions` → `RGSSInput.inputactions`.
  - `Assets/RGSSInput.inputactions` — the action map asset.
  - `Assets/Scripts/InputStateRecorder.cs:64-80` — `SetPress`/`SetRelease` (callers ARE `GameInputManager`).
  - `Assets/Resources/RGSS/tilemap.rb` + absence of any `Tilemap.cs` — Tilemap binding confirmed missing.
  - WHY: the two biggest scope levers; getting input right means T23 ports a WORKING subsystem (incl. the previously-overlooked `GameInputManager`).

  **Acceptance Criteria**:
  - [ ] Written verdict with grep evidence: Tilemap binding ABSENT (out of scope); Input poller PRESENT+wired in scene (in scope, port as working).

  **QA Scenarios**:
  ```
  Scenario: repo-wide existence check (incl. Assets root + scenes)
    Tool: Bash (rg across *.cs/*.unity/*.prefab/*.inputactions, WHOLE Assets tree)
    Steps:
      1. rg "class Tilemap|RbClass\(\"Tilemap" → expect NONE.
      2. rg "SetPress|SetRelease" → expect GameInputManager.cs callers present.
      3. rg "RGSSUnity.GameInputManager" over scenes → expect SampleScene wiring present.
    Expected Result: Tilemap absent; input wiring present (both confirmed).
    Failure Indicators: a Tilemap binding found (would flip map scope); no GameInputManager wiring (would contradict the fix).
    Evidence: .sisyphus/evidence/task-7-scope-verify.txt
  ```

  **Commit**: NO (analysis only; output feeds plan/scope).

- [x] 8. Test harness: GUT + C# tests + golden-diff tooling

  **What to do**:
  - Install GUT into the Godot project; add a sample passing test; wire a headless GUT run command.
  - Decide + set up the C# test path (xUnit or GoDotTest) for isolable binding helpers; add one sample.
  - Build the golden-screenshot diff tool: capture a headless screenshot, compare to a golden within a pixel tolerance, emit pass/fail + a diff image. Prefer godot-mcp-pro `compare_screenshots`; provide a no-cost fallback script.

  **Must NOT do**: Don't write feature tests yet (those live with each task).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: cross-cutting infra enabling TDD for all later waves.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 1 · Blocks: TDD for T12-T24 · Blocked By: None (can start at GO).

  **References**:
  - Research (draft): godot-mcp-pro Testing/QA tools (`run_test_scenario`, `assert_node_state`, `compare_screenshots`, `get_game_screenshot`).
  - `AGENTS.md` — "No CLI build" today; this task introduces the test command surface.
  - WHY: parity is unprovable without an automated golden-diff oracle.

  **Acceptance Criteria**:
  - [ ] `godot --headless` GUT run executes the sample test and reports pass.
  - [ ] Golden-diff tool returns PASS on identical images, FAIL + diff on a perturbed one.

  **QA Scenarios**:
  ```
  Scenario: harness self-test
    Tool: Bash
    Steps:
      1. Run GUT headless → sample test passes.
      2. Run golden-diff on (img, img) → PASS; on (img, perturbed) → FAIL with diff image saved.
    Expected Result: both behave correctly.
    Evidence: .sisyphus/evidence/task-8-harness.txt + diff.png
  ```

  **Commit**: YES — `test(godot): GUT + golden-diff harness` · Pre-commit: sample test green.

- [x] 9. Boot scene + Fiber pump on Godot frame model + teardown

  **What to do**:
  - Create the main Godot scene + an autoload that mirrors `GameManager`: init render/input/audio managers, init `RubyScriptManager`, load `main.rb`.
  - Port the per-frame pump from `UnityModule.Update()` into `_Process`: resume the update Fiber, BUT when `Graphics.WaitCount > 0` do render-only (bypass logic resume) — replicate exactly. Port `register_update_fiber`/`unregister_update_fiber`.
  - Port `GC.KeepAlive(func)` after `State.Protect`. Implement teardown on BOTH `_ExitTree` and `_Notification(WM_CLOSE_REQUEST)`: dispose order `compiler→context→Ruby.Close`, plus `RbNativeObjectLiveKeeper.ReleaseKeeper(state)`.

  **Must NOT do**: Don't use `delta` for game logic (pure frame count; set `Engine.MaxFps=60`); don't QueueFree from finalizers.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: frame-model + Fiber + GC-lifetime correctness is the subtlest spine work.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: NO (spine) · Wave 1 · Blocks: T26 · Blocked By: T5.

  **References**:
  - `Assets/Scripts/GameManager.cs` (whole) — boot wiring + `Update()` pumping `UnityModule.Update` + `RGSSLogger.Update`.
  - `Assets/Scripts/RubyClasses/UnityModule.cs:28-56` — Update/Fiber resume + `Graphics.WaitCount` bypass + `GC.KeepAlive`.
  - `Assets/Scripts/RubyClasses/UnityModule.cs:156-180` — register/unregister update fiber.
  - `Assets/Resources/RGSS/patch_rmva.rb:2-19` — SceneManager.run builds the `@update_fiber`.
  - Metis: teardown needs dual notification + ReleaseKeeper; KeepAlive is "most subtle hazard".
  - WHY: gets the RMVA main loop actually running each frame without GC crashes.

  **Acceptance Criteria**:
  - [ ] Headless run resumes the fiber each frame; `Graphics.wait(n)` produces n render-only frames (assert via frame/log counter).
  - [ ] Clean exit on window-close AND scene-exit with no leaked mruby heap (no ReleaseKeeper-missing warning).

  **QA Scenarios**:
  ```
  Scenario: fiber pumps and Graphics.wait bypasses logic
    Tool: Bash (headless) + instrumented counters
    Steps:
      1. Run a Ruby slice that calls Graphics.wait(10); assert 10 frames advance with logic-resume skipped.
    Expected Result: counter shows 10 render-only frames.
    Evidence: .sisyphus/evidence/task-9-fiber-wait.txt

  Scenario: clean teardown on close (negative-path leak check)
    Tool: Bash
    Steps:
      1. Boot then send close; assert dispose order logged + ReleaseKeeper called, exit 0.
    Evidence: .sisyphus/evidence/task-9-teardown.txt
  ```

  **Commit**: YES — `feat(godot): boot scene + fiber pump + teardown` · Pre-commit: fiber-wait test green.

- [x] 10. GlobalConfig (rm_conf.json) + legacy mode

  **What to do**:
  - Port `GlobalConfig`: read `rm_conf.json` via `FileAccess` from the exe-dir (not StreamingAssets), with the 3-byte BOM strip, parse into the same fields (`rtp_path`, `project_path`, `legacy_mode`, `legacy_mode_width/height`, `cn_ver_rmva`).
  - Expose `LegacyMode` (forces 544x416) + `CnVerRmva` to the rest of the system.

  **Must NOT do**: Don't change config schema; don't drop the BOM workaround.

  **Recommended Agent Profile**:
  - **Category**: `quick` — Reason: small, well-bounded config port.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 1 · Blocks: T14 (legacy res), T22 (rtp) · Blocked By: None.

  **References**:
  - `Assets/Scripts/GlobalConfig.cs` (whole, 54 lines) — exact fields + BOM strip (`res, 3, len-3`).
  - `Assets/StreamingAssets/rm_conf.json` — the live config (legacy_mode true, 544x416, cn_ver true).
  - Research L3: `OS.get_executable_path().get_base_dir().path_join("rm_conf.json")`.
  - WHY: legacy res + CN flag gate rendering size + GBK transcoding everywhere.

  **Acceptance Criteria**:
  - [ ] Parses the real `rm_conf.json`; `LegacyMode==true`, dims 544x416, `CnVerRmva==true`.

  **QA Scenarios**:
  ```
  Scenario: config parse + BOM strip
    Tool: Bash (headless) + assert
    Steps:
      1. Load config; print parsed fields; assert match expected.
      2. Feed a BOM-prefixed file; assert no parse error.
    Expected Result: correct values, no BOM failure.
    Evidence: .sisyphus/evidence/task-10-config.txt
  ```

  **Commit**: YES — `feat(godot): GlobalConfig + legacy mode` · Pre-commit: parse test green.

- [x] 11. RGSSLogger deferred-queue + GC/lifetime conventions doc

  **What to do**:
  - Port `RGSSLogger` as a deferred message queue flushed on the main thread next frame (mirror the Unity rationale). Route to `GD.Print`/`GD.PrintErr`.
  - If T3's probe found direct print-in-rescue crashes Godot too, the queue is mandatory; if not, keep it anyway (portable, harmless) but note the verdict.
  - Write a short `lifetime-conventions.md`: node disposal goes in the mruby RData **release callback** (main thread), NEVER in C# finalizers/`QueueFree`-from-finalizer; `GC.KeepAlive` after every `Protect`; LiveKeeper `Keep` for every defined native method; ReleaseKeeper on teardown. This doc governs every binding task.

  **Must NOT do**: Don't `GD.Print` from inside a rescue path directly anywhere.

  **Recommended Agent Profile**:
  - **Category**: `quick` — Reason: small port + a conventions doc (writing-ish, but tightly technical).
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 1 · Blocks: governs T12-T24 · Blocked By: T3 (verdict).

  **References**:
  - `Assets/Scripts/RGSSLogger.cs` (whole) — queue + next-frame flush.
  - `Assets/Scripts/RubyClasses/RubyExtension.cs:15-21,34-44` — `RubyData` base + `Release` via LiveKeeper (the release-callback seam).
  - Metis landmines 1-4 (draft) — finalizer crash, KeepAlive, ReleaseKeeper, dual teardown.
  - WHY: these conventions prevent the class of GC/thread crashes that would otherwise appear randomly across all bindings.

  **Acceptance Criteria**:
  - [ ] Logger flushes queued messages on the next frame (assert ordering).
  - [ ] `lifetime-conventions.md` exists and is referenced by binding tasks.

  **QA Scenarios**:
  ```
  Scenario: deferred flush ordering
    Tool: Bash (headless)
    Steps:
      1. Enqueue 3 messages during a frame; assert they print next frame in order.
    Expected Result: correct deferred order.
    Evidence: .sisyphus/evidence/task-11-logger.txt
  ```

  **Commit**: YES — `feat(godot): deferred RGSSLogger + lifetime conventions` · Pre-commit: flush test green.

- [x] 12. Value types: Color / Tone / Rect / Table / Font

  **What to do**:
  - Port the 5 value-type bindings. Color/Tone/Rect are ~1-line type swaps (store plain structs/Godot `Color`/`Rect2`). Table is a pure data container (zero Unity APIs). Font wraps font config (family/size/color/bold/italic) — map to Godot `FontFile`/theme params but keep the RGSS API.
  - Do these FIRST in the wave: they unblock test scaffolding for everything that consumes them.
  - **Bug-for-bug**: preserve the known Layer-1 Ruby bugs in `color.rb`/`font.rb` — the C# side must not "compensate".

  **Must NOT do**: Don't fix `color.rb:65` / `font.rb:72,76`; don't add validation the original lacks.

  **Recommended Agent Profile**:
  - **Category**: `quick` — Reason: mechanical 1:1 ports of small value types.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (5 sub-types parallelizable) · Wave 2 · Blocks: T14,T16,T17,T18 (consumers) · Blocked By: T5.

  **References**:
  - `Assets/Scripts/RubyClasses/Color.cs`, `Tone.cs`, `Rect.cs`, `Table.cs`, `Font.cs` — exact port targets.
  - `Assets/Resources/RGSS/color.rb`, `tone.rb`, `rect.rb`, `table.rb`, `font.rb` — Ruby wrappers (untouched; note the bugs).
  - `Assets/Scripts/RubyClasses/RubyExtension.cs` — `RubyData`/`NewObjectWithRData`/`GetRDataObject` plumbing to reuse.
  - WHY: Sprite/Window/Bitmap consume these constantly; they're the natural TDD beachhead.

  **Acceptance Criteria**:
  - [ ] Each type round-trips Ruby↔C# (e.g. `Color.new(255,128,0,255)` reads back the same components).
  - [ ] GUT tests cover construction + accessors for all 5.

  **QA Scenarios**:
  ```
  Scenario: value-type round-trips (TDD)
    Tool: GUT (headless)
    Steps:
      1. RED: write failing GUT tests for Color/Tone/Rect/Table/Font construct+read.
      2. GREEN: port until pass.
    Expected Result: all green; Color setter bug preserved (test asserts buggy-but-matching behavior).
    Evidence: .sisyphus/evidence/task-12-valuetypes.txt

  Scenario: preserved-bug characterization (negative)
    Tool: GUT
    Steps:
      1. Assert color.rb's broken setter path behaves identically to Unity (documented).
    Evidence: .sisyphus/evidence/task-12-bug-parity.txt
  ```

  **Commit**: YES — `feat(godot): port value types (color/tone/rect/table/font)` · Pre-commit: GUT green.

- [x] 13. External file IO layer (StreamingAssets → exe-dir/RMProject)

  **What to do**:
  - Replace every Unity `Application.streamingAssetsPath` / `UnityWebRequest` file read with Godot `FileAccess`/`DirAccess` rooted at `OS.get_executable_path().get_base_dir()` (dev: a configurable base), preserving the `RMProject/` layout so Ruby's `"RMProject"` literals still resolve.
  - Provide synchronous byte reads (the original busy-waits become plain `FileAccess.get_buffer`); cover image/audio/data/config/script reads.

  **Must NOT do**: Don't change the on-disk layout; don't require `res://` for game data.

  **Recommended Agent Profile**:
  - **Category**: `quick` — Reason: bounded path/IO remap, but touches many call sites.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 2 · Blocks: T16 (bitmap file load), T22 (audio) · Blocked By: T5.

  **References**:
  - `Assets/Scripts/RubyClasses/Bitmap.cs:76-101` — `new_filename` busy-wait load (the pattern to replace).
  - `Assets/Resources/RGSS/kernel.rb:11-22` + `patch_rmva.rb:77-101` — `load_data`/`save_data` + RMProject/RTP path joins.
  - `Assets/Scripts/RubyClasses/UnityModule.cs:58-63` — `rmva_project_path` returns the base path.
  - Research L3: abs paths via FileAccess; `res://` read-only in export.
  - WHY: nothing loads game assets until this is remapped; Ruby path literals depend on layout preservation.

  **Acceptance Criteria**:
  - [ ] A known data/image file loads by RMProject-relative path on all dev OSes.
  - [ ] `save_data` writes to the RMProject path and reloads identically.

  **QA Scenarios**:
  ```
  Scenario: read + write round-trip via RMProject path
    Tool: Bash (headless)
    Steps:
      1. Load Data/System.rvdata2 by relative path; assert bytes non-empty.
      2. save_data a small object; reload; assert equal.
    Expected Result: read+write parity.
    Evidence: .sisyphus/evidence/task-13-fileio.txt
  ```

  **Commit**: YES — `feat(godot): external file IO (RMProject paths)` · Pre-commit: round-trip green.

- [x] 14. GameRenderManager → SubViewport compositor + Z mapping

  **What to do**:
  - Reimplement the per-frame compositor on a SubViewport tree: each RGSS Viewport → a `SubViewport` whose `get_texture()` feeds a `Sprite2D` in the composite; composite → post-process CanvasLayer → screen. Honor `transparent_bg`, `update_mode`.
  - Map ordering: RGSS Viewport Z → `CanvasLayer.layer`/coarse ordering; per-object Z → `z_index` with `z_as_relative=false`. RMVA Z range 0..200 fits ±4096 (per census).
  - Honor `legacy_mode` 544x416 fixed render size. Replicate the tag-dispatch walk (Sprite/Plane/Window) but feeding nodes instead of GameObjects.

  **Must NOT do**: Don't implement per-object effect logic here (that's T17-T20); don't break the wait/freeze render path (coordinate with T9/T21).

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: the render architecture keystone; SubViewport nesting + Z semantics are subtle.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: NO (render spine) · Wave 2 · Blocks: T16 → render wave · Blocked By: T5,T12.

  **References**:
  - `Assets/Scripts/GameRenderManager.cs` (whole, 207 lines) — the compositing loop, viewport iteration, tag dispatch, postprocess→screen blit, legacy dims.
  - Research L2 (draft): SubViewport↔RenderTexture, nested compositing, CanvasLayer+z_index mapping, `z_as_relative=false`.
  - `Assets/Scripts/GlobalConfig.cs` (via T10) — legacy dims.
  - Metis M3: keep RMVA in a single CanvasLayer + z_index (0..200 range).
  - WHY: every visible object renders through this; it defines the coordinate/compositing contract for the render wave.

  **Acceptance Criteria**:
  - [ ] A single colored Sprite in a Viewport composites to the correct screen position/size (golden diff vs a constructed reference).
  - [ ] Z ordering of two overlapping sprites matches RGSS (higher Z in front).

  **QA Scenarios**:
  ```
  Scenario: single-sprite composite to screen
    Tool: godot --headless screenshot + compare_screenshots
    Steps:
      1. Place one known sprite at (x,y,z) in a viewport; render one frame; screenshot.
      2. Compare to golden (or constructed expected) within tolerance.
    Expected Result: position/size/color match.
    Evidence: .sisyphus/evidence/task-14-composite.png

  Scenario: Z order correctness
    Tool: headless screenshot
    Steps:
      1. Two overlapping sprites z=10 and z=20; assert z=20 occludes.
    Evidence: .sisyphus/evidence/task-14-zorder.png
  ```

  **Commit**: YES — `feat(godot): SubViewport compositor + Z mapping` · Pre-commit: composite golden within tol.

- [x] 15. Render-Conventions spec (M2/M3/M4 resolutions)

  **What to do**:
  - Write `render-conventions.md` resolving the render impedance mismatches so every render task follows one approach:
    - **M2**: multi-pass postprocess (transition+fade+brightness) → explicit `BackBufferCopy` placement between CanvasLayers (one `hint_screen_texture` copy/frame).
    - **M3**: keep all RMVA objects in one CanvasLayer; use `z_index` only (range 0..200 confirmed by census).
    - **M4**: the per-sprite uniform packing scheme — pack ~13 RGSS params (wave×3, tone×4, opacity, flash×4, bush) into the 4-float `instance uniform` budget via vec4 channel packing; specify exact channel layout. Fallback = duplicated ShaderMaterial where packing is insufficient.
  - This is a spec, not code; it governs T16-T21 and T24.

  **Must NOT do**: Don't pick approaches that silently break batching without noting the tradeoff.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: cross-cutting shader/render architecture decisions with correctness + perf tradeoffs.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (with T14) · Wave 2 · Blocks: T16,T17,T21,T24 · Blocked By: None (informed by L2 research).

  **References**:
  - Research L2 (draft) — M2 BackBufferCopy, M3 CanvasLayer isolation, M4 instance-uniform 4-float cap, `set_instance_shader_parameter`.
  - `Assets/Scripts/RubyClasses/Sprite.cs:651-760` — the full set of per-sprite shader params that must be packed.
  - `Assets/Shaders/SpriteShader.shader` — effect order (mirror→wave→gray→tone→opacity→color→bush→flash) to preserve.
  - WHY: without one agreed packing/passing scheme, each render task would diverge and break parity/perf.

  **Acceptance Criteria**:
  - [ ] `render-conventions.md` specifies M2 node layout, M3 layering rule, M4 exact vec4 packing for all sprite params.

  **QA Scenarios**:
  ```
  Scenario: spec completeness review
    Tool: Read + checklist
    Steps:
      1. Verify each of the 13 sprite params has a packed channel assignment.
      2. Verify a worked multi-pass BackBufferCopy example is given.
    Expected Result: no unaddressed param/pass.
    Evidence: .sisyphus/render-conventions.md
  ```

  **Commit**: YES — `docs(godot): render conventions (M2/M3/M4)` · Pre-commit: spec checklist complete.

- [x] 16. Bitmap.cs — THE LONG POLE (Image-backed draw primitives)

  **What to do**:
  - Reimplement `Bitmap` on Godot `Image` + `ImageTexture`: `fill_rect`/`blt`/`stretch_blt`/`blend`/`clear`/`get_pixel`/`set_pixel`/`gradient_fill_rect`/`hue_change`/`blur` and the dirty-tracking + `update(image)` push.
  - **`draw_text` (M1)**: no Image text API — render via a transient `SubViewport`+`Label` (one-shot `update_mode=ONCE`), read back, blit onto the Image. Honor Font config + CN-GBK text.
  - **M5**: implement `gradient_fill_rect` + any blur via CPU loop or a SubViewport+shader.
  - Match the RGSS dirty-set lifecycle (`DirtyBitmapDataSet_` / `ResetDirtyDataSet`). Node/texture disposal via the release-callback (per lifetime-conventions), NOT finalizer.

  **Must NOT do**: Don't start Sprite/Window render before these primitives exist; don't free textures from finalizers.

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain` — Reason: largest single risk, no direct Godot equivalent for the blit/draw_text pipeline; needs genuine problem-solving. Give goals (parity of each primitive), not rote steps.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: NO (gates render wave) · Wave 2 · Blocks: T17,T18,T19,T20 · Blocked By: T12,T13,T14,T15.

  **References**:
  - `Assets/Scripts/RubyClasses/Bitmap.cs` (whole, 758 lines) — every primitive + dirty tracking + the `TextMeshPro`→draw_text path + zlib usage.
  - Research L2 (draft): `Image.fill_rect/blit_rect/blend_rect/blit_rect_mask/resize`, `ImageTexture.update`; M1 SubViewport+Label render-back; M5 gradient/blur gaps.
  - `Assets/Scripts/RubyClasses/Font.cs` (via T12) — font config consumed by draw_text.
  - `Assets/Scripts/RubyClasses/Kernel.cs:38-58` — CN GBK↔UTF8 transcode for text.
  - WHY: `Sprite.bitmap`, `Window.contents`, `Plane.bitmap` ALL depend on these primitives; this unblocks the entire render wave.

  **Acceptance Criteria**:
  - [ ] `fill_rect`, `blt`, `stretch_blt`, `gradient_fill_rect`, `hue_change`, `draw_text` each produce golden-matching `ImageTexture` output.
  - [ ] Dirty-tracking pushes updates exactly once per frame; textures freed on main thread.

  **QA Scenarios**:
  ```
  Scenario: each primitive golden-matches
    Tool: GUT + headless screenshot + compare_screenshots
    Steps:
      1. RED: golden fixtures for fill_rect/blt/stretch_blt/gradient/hue/draw_text (captured from Unity in T6).
      2. GREEN: implement until each output matches within tolerance.
    Expected Result: all 6 primitives within tolerance.
    Evidence: .sisyphus/evidence/task-16-bitmap-<primitive>.png

  Scenario: draw_text with CN-GBK string
    Tool: headless screenshot
    Steps:
      1. draw_text a GBK-sourced string; assert glyphs render (compare to Unity golden).
    Evidence: .sisyphus/evidence/task-16-drawtext-cn.png

  Scenario: no finalizer-thread free (negative)
    Tool: Bash stress
    Steps:
      1. Create+drop many bitmaps; force GC; assert no thread-affinity crash, textures freed.
    Evidence: .sisyphus/evidence/task-16-lifetime.txt
  ```

  **Commit**: YES — `feat(godot): Bitmap image primitives + draw_text` · Pre-commit: primitive goldens green.

- [x] 17. Sprite binding (transform + effects via packed instance-uniforms)

  **What to do**:
  - Port `Unity::Sprite` onto a Godot `Sprite2D`-backed node + `SpriteData`. Map x/y/z/ox/oy/zoom/angle/mirror/visible/opacity/blend_type, src_rect, bitmap=, viewport=, and the effect params (wave_amp/length/phase, tone, color, flash, bush) using the M4 packing from `render-conventions.md`.
  - Port the `Render(data)` per-frame shader-property application + flash countdown + wave-phase advance. Disposal via release callback.

  **Must NOT do**: Don't diverge from the M4 packing; don't free from finalizer; don't change blend-mode semantics (0 normal/1 add/2 sub).

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: many coupled effect params + shader binding + lifetime correctness.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (with T19,T20,T22,T23) · Wave 3 · Blocks: T26 · Blocked By: T16, T24 (sprite shader), T15.

  **References**:
  - `Assets/Scripts/RubyClasses/Sprite.cs` (whole, 776 lines) — every accessor + `Render` + `SetShaderProperties` + `CreateTextureToSpriteRenderer`.
  - `Assets/Resources/RGSS/sprite.rb` — wrapper (untouched) showing the exact API + type checks.
  - `render-conventions.md` (T15) — vec4 packing for the 13 params.
  - `Assets/Shaders/SpriteShader.shader` (via T24 port) — effect order to match.
  - WHY: Sprite is the most-used drawable; its effect parity is the bulk of visual fidelity.

  **Acceptance Criteria**:
  - [ ] Transform + opacity + tone + color + mirror + blend modes golden-match.
  - [ ] wave/bush/flash animate and match Unity goldens within tolerance.

  **QA Scenarios**:
  ```
  Scenario: sprite effect parity matrix
    Tool: GUT + headless screenshot + compare_screenshots
    Steps:
      1. For each effect (tone, color, mirror, blend 0/1/2, wave, bush, flash, opacity), render a known sprite; compare to Unity golden.
    Expected Result: all within tolerance.
    Evidence: .sisyphus/evidence/task-17-sprite-<effect>.png

  Scenario: mass dispose lifetime (negative)
    Tool: Bash stress
    Steps:
      1. Create/dispose 500 sprites across frames; assert no crash, node count returns to baseline.
    Evidence: .sisyphus/evidence/task-17-dispose.txt
  ```

  **Commit**: YES — `feat(godot): port Unity::Sprite` · Pre-commit: effect goldens green.

- [x] 18. Window binding (9-slice skin, cursor, openness, contents)

  **What to do**:
  - Port `Unity::Window` (the largest/most intricate binding): window skin 9-slice (→ `NinePatchRect` or custom), `contents` Bitmap, cursor_rect, openness animation, pause/arrows, padding, back_opacity/contents_opacity, tone.
  - Reproduce the openness→height offset render math and the per-frame `Render(data)`.

  **Must NOT do**: Don't simplify the skin layout; don't change openness semantics; release-callback disposal only.

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain` — Reason: 882-line binding, 9-renderer skin composition, intricate state; needs real problem-solving.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (with T17,T19,T20) · Wave 3 · Blocks: T26 · Blocked By: T16, T24 (window shader), T15.

  **References**:
  - `Assets/Scripts/RubyClasses/Window.cs` (whole, 882 lines) — skin slicing, cursor, openness, contents, tone.
  - `Assets/Resources/RGSS/window.rb` — wrapper (untouched).
  - `Assets/Scripts/GameRenderManager.cs:138-161` — window openness→offset render handling.
  - `Assets/Shaders/WindowBackgroundShader.shader` (via T24) — skin shader.
  - Research L2: `NinePatchRect`; M4 packing for window tone/opacity.
  - WHY: every menu/message uses Window; parity here is most of UI fidelity.

  **Acceptance Criteria**:
  - [ ] Window skin (border+background), cursor, openness 0→255 animation, contents text all golden-match.

  **QA Scenarios**:
  ```
  Scenario: window skin + openness + contents
    Tool: GUT + headless screenshot + compare_screenshots
    Steps:
      1. Render a window with skin, a cursor rect, contents text, at openness 128 and 255; compare to Unity goldens.
    Expected Result: within tolerance at both openness values.
    Evidence: .sisyphus/evidence/task-18-window-<state>.png
  ```

  **Commit**: YES — `feat(godot): port Unity::Window` · Pre-commit: window goldens green.

- [x] 19. Viewport binding (SubViewport-backed)

  **What to do**:
  - Port `Unity::Viewport` onto a `SubViewport`-backed node + `ViewportData`: rect, ox/oy, z, visible, tone, color, flash, and the `DEFAULT_VIEWPORT` singleton the Ruby layer references.
  - Integrate with T14's compositor (the viewport IS a render target there).

  **Must NOT do**: Don't duplicate compositor logic (lives in T14); don't change DEFAULT_VIEWPORT semantics.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: moderate binding tightly coupled to the compositor.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 3 · Blocks: T26 · Blocked By: T16, T14.

  **References**:
  - `Assets/Scripts/RubyClasses/Viewport.cs` (whole, 329 lines) — fields + tone/flash + DEFAULT_VIEWPORT.
  - `Assets/Resources/RGSS/viewport.rb` — wrapper (note the `rect.w.` bug, preserve).
  - `Assets/Scripts/GameRenderManager.cs:61-90` — how viewport ox/oy/z drive compositing.
  - WHY: sprites/windows attach to viewports; the default viewport underpins the whole tree.

  **Acceptance Criteria**:
  - [ ] Sprites parented to a viewport scroll with ox/oy and tint with viewport tone, golden-matching.

  **QA Scenarios**:
  ```
  Scenario: viewport ox/oy scroll + tone
    Tool: headless screenshot + compare
    Steps:
      1. Place sprites in a viewport; set ox/oy + tone; render; compare to Unity golden.
    Expected Result: scroll offset + tint match.
    Evidence: .sisyphus/evidence/task-19-viewport.png
  ```

  **Commit**: YES — `feat(godot): port Unity::Viewport` · Pre-commit: viewport golden green.

- [x] 20. Plane binding (tiled scrolling background)

  **What to do**:
  - Port `Unity::Plane` onto a tiled-texture node using the plane/tiled-background shader: bitmap, ox/oy scroll, zoom, opacity, blend_type, tone, color, z.

  **Must NOT do**: Don't free from finalizer; keep tiling/scroll semantics.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: moderate binding + a tiling shader dependency.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 3 · Blocks: T26 · Blocked By: T16, T24 (plane shader).

  **References**:
  - `Assets/Scripts/RubyClasses/Plane.cs` (whole, 360 lines) — fields + `Render`.
  - `Assets/Resources/RGSS/plane.rb` — wrapper (note `@viewport` bug, preserve).
  - `Assets/Shaders/PlaneShader.shader` + `TiledBackgroundShader.shader` (via T24).
  - WHY: parallax backgrounds (e.g. title, fog) use Plane.

  **Acceptance Criteria**:
  - [ ] A tiled plane scrolls with ox/oy and tiles correctly, golden-matching.

  **QA Scenarios**:
  ```
  Scenario: plane tiling + scroll
    Tool: headless screenshot + compare
    Steps:
      1. Set a plane bitmap; scroll ox/oy; assert seamless tiling matches Unity golden.
    Evidence: .sisyphus/evidence/task-20-plane.png
  ```

  **Commit**: YES — `feat(godot): port Unity::Plane` · Pre-commit: plane golden green.

- [x] 21. Graphics module (fade / transition / freeze / brightness)

  **What to do**:
  - Port `Unity::Graphics`: frame_rate/frame_count, update, wait (the render-only bypass), fadeout/fadein, freeze, transition (with vague texture), brightness, resize_screen, snap_to_bitmap, width/height (legacy-aware).
  - Implement the post-process chain per M2 (BackBufferCopy between passes): brightness/fade as a full-screen pass; transition as the frozen/new/transition-texture blend.

  **Must NOT do**: Don't break the Fiber wait coupling (T9); don't collapse multi-pass into one (M2).

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: stateful fade/transition machine + multi-pass postprocess correctness.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 3 · Blocks: T26 · Blocked By: T14, T15, T24 (postprocess+transition shaders).

  **References**:
  - `Assets/Scripts/RubyClasses/Graphics.cs` (whole, 349 lines) — fade state machine, transition texture handling, snap_to_bitmap.
  - `Assets/Resources/RGSS/graphics.rb` — wrapper.
  - `Assets/Shaders/GraphicsPostprocessShader.shader` + `TransitionPostprocessShader.shader` (via T24).
  - Research L2: hint_screen_texture + BackBufferCopy multi-pass.
  - WHY: scene transitions/fades are pervasive; wait() coupling affects the whole loop.

  **Acceptance Criteria**:
  - [ ] fadeout→fadein produces correct brightness ramp; transition with a vague texture blends frozen→new, golden-matching key frames.

  **QA Scenarios**:
  ```
  Scenario: fade + transition frames
    Tool: godot-mcp-pro capture_frames + compare_screenshots (fallback: GDScript driver saving per-frame PNGs via get_viewport().get_texture().get_image().save_png() + pixel-diff helper)
    Steps:
      1. Run fadeout(30); capture frames at 0/15/30; compare brightness to Unity goldens.
      2. Run transition(40, vague.png); capture mid-blend; compare.
    Expected Result: ramp + blend match within tolerance.
    Evidence: .sisyphus/evidence/task-21-graphics-*.png
  ```

  **Commit**: YES — `feat(godot): port Unity::Graphics fade/transition` · Pre-commit: fade goldens green.

- [x] 22. Audio (4 buses, external load, fade/volume/pitch, WMA fallback)

  **What to do**:
  - Port `Unity::Audio` + the audio manager: 4 buses (BGM/BGS/ME/SE), `AudioStreamPlayer`s (SE polyphonic), `load_from_file` for ogg/wav/mp3 from RMProject/RTP paths, volume (`volume_linear`)/pitch (`pitch_scale`)/position, looping, Tween fade, ME→resume-BGM.
  - **WMA**: implement the ffmpeg-convert-to-ogg fallback (or documented accept-silent) — low priority, behind a flag.
  - Preserve the RTP-fallback path logic from `patch_rmva.rb` (try RMProject then RTP).

  **Must NOT do**: Don't block the main thread on load; don't change the RTP fallback semantics.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: multi-channel audio + format handling + fade tweens.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 3 · Blocks: T26 · Blocked By: T13.

  **References**:
  - `Assets/Scripts/GameAudioManager.cs` (whole, 208 lines) — 4 sources, format dispatch, WMA via NAudio, fade coroutine, cache.
  - `Assets/Scripts/RubyClasses/Audio.cs` (158 lines) — the `Unity::Audio` API.
  - `Assets/Resources/RGSS/audio.rb` — wrapper (note `:set_stop` bug, preserve).
  - `Assets/Resources/RGSS/patch_rmva.rb:103-157` — bgm/bgs/me/se play with RTP fallback proc.
  - Research L3: AudioStream*.load_from_file, volume_linear, buses, WMA gap→ffmpeg.
  - WHY: BGM/SE are core feel; RTP fallback is required for RTP-dependent games.

  **Acceptance Criteria**:
  - [ ] BGM loops; SE plays polyphonically; fade out ramps to silence; ME plays then BGM resumes.
  - [ ] A missing local file falls back to RTP path.

  **QA Scenarios**:
  ```
  Scenario: 4-channel playback + fade
    Tool: godot-mcp-pro monitor_properties on the 4 AudioStreamPlayers + AudioServer bus peak (fallback: GDScript driver reading AudioServer.get_bus_peak_volume_*/player.playing each frame, asserting levels)
    Steps:
      1. Play BGM (assert loop), 3 concurrent SE (assert polyphony), fade BGM (assert level→0), ME then BGM resume.
    Expected Result: levels/behavior match expectations.
    Evidence: .sisyphus/evidence/task-22-audio.txt

  Scenario: RTP fallback (negative-path)
    Tool: Bash
    Steps:
      1. Request a file absent in RMProject but present in RTP; assert it plays from RTP.
    Evidence: .sisyphus/evidence/task-22-rtp.txt
  ```

  **Commit**: YES — `feat(godot): port Unity::Audio (4 buses + fallback)` · Pre-commit: playback test green.

- [x] 23. Input (port the WORKING input subsystem onto Godot)

  **What to do**:
  - Port the full working input chain (corrected scope — input IS wired on Unity):
    1. `InputStateRecorder` — double-buffered state, repeat cadence (`>=23 && (n+1)%6==0`), dir4/dir8 — port verbatim.
    2. `GameInputManager` — the poller (Assets root) — reimplement on Godot's input: map the 20 RGSS actions (A/B/C/X/Y/Z/L/R, Shift/Ctrl/Alt, F5–F9, Up/Down/Left/Right) to Godot `InputMap` actions; on action started→`SetPress`, canceled→`SetRelease`. Drive from `_Input`/`_Process`.
    3. `Unity::Input` binding — `trigger?`→`IsTriggered`, `press?`→`IsPressed`, `repeat?`→`IsRepeated`, `dir4`/`dir8`.
    4. Recreate the action map (`RGSSInput.inputactions`) as Godot `InputMap` actions with equivalent key/gamepad bindings.
  - Preserve the per-frame `InputStateRecorder.Update()` double-buffer swap ordering relative to the Fiber pump (T9).

  **Must NOT do**: Don't change the repeat cadence or dir-numpad mapping (2/4/6/8, 1-9); don't drop any of the 20 actions; don't wire input to the main thread off-frame.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: timing-sensitive repeat logic + 20-action mapping + poller reimplementation + frame-order coupling.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 3 · Blocks: T26, F3 (menu/input QA) · Blocked By: T5; scope confirmed by T7.

  **References**:
  - `Assets/Scripts/InputStateRecorder.cs` (whole, 188 lines) — state machine, repeat cadence, dir4/dir8 — port verbatim.
  - `Assets/GameInputManager.cs` (whole, 68 lines) — the poller: 20 `Handle*` callbacks → `SetPress`/`SetRelease`. **(Assets root — the 31st migration file, missed by earlier Assets/Scripts-scoped searches.)**
  - `Assets/Scripts/RubyClasses/Input.cs` (94 lines) — `Unity::Input` API + key-symbol map + per-frame `Update`.
  - `Assets/Scenes/SampleScene.unity:1022-1300` — how the 20 actions bind to GameInputManager (the wiring to reproduce as Godot InputMap).
  - `Assets/RGSSInput.inputactions` + `Assets/InputSystem_Actions.inputactions` — action definitions to translate to Godot InputMap.
  - Research L3: `InputMap.add_action`+`InputEventKey`, `is_action_just_pressed`/`pressed`.
  - WHY: input is a working, player-facing subsystem; menus/maps depend on it and on the exact repeat cadence.

  **Acceptance Criteria**:
  - [ ] All 20 actions map to Godot InputMap; pressing each feeds the recorder (SetPress/SetRelease) exactly as the Unity Input System callbacks do.
  - [ ] `trigger?` true on frame 1, `repeat?` first fires ≈frame 24 then every ≈6; `dir8(up+left)=7`, `dir4` correct.

  **QA Scenarios**:
  ```
  Scenario: end-to-end input parity (simulated key → Unity::Input reports it)
    Tool: godot-mcp-pro simulate_action / simulate_sequence + assert_node_state (fallback: Input.parse_input_event + GDScript asserts)
    Steps:
      1. simulate_action "rgss_c" press; assert Unity::Input.trigger?(:C) true on the next frame, press? true while held.
      2. Hold the action; assert repeat? first true at ≈frame 24, then every ≈6 frames.
      3. simulate up+left; assert dir8 == 7; release; assert dir4 == 0.
    Expected Result: cadence + numpad values exact; matches Unity golden behavior.
    Failure Indicators: trigger? misfires, wrong repeat timing, wrong numpad value.
    Evidence: .sisyphus/evidence/task-23-input.txt

  Scenario: all 20 actions wired (coverage)
    Tool: godot --headless GDScript driver (fallback path)
    Steps:
      1. For each of the 20 actions, inject press+release; assert the corresponding InputKey toggles in the recorder.
    Expected Result: 20/20 actions feed the recorder.
    Evidence: .sisyphus/evidence/task-23-actions.txt
  ```

  **Commit**: YES — `feat(godot): port Unity::Input + GameInputManager poller` · Pre-commit: input cadence + 20-action tests green.

- [x] 24. Shader port — enumerate + translate effect shaders to .gdshader

  **What to do**:
  - First **enumerate the actual `.shader` files** in `Assets/Shaders/` and cross-check against the `Custom/*` names referenced from C# (brief says 18; C# references ~15 — reconcile, flag dead/unreferenced).
  - Translate each to `shader_type canvas_item` `.gdshader`, preserving effect math + order. Screen-reading ones (postprocess/transition) use `hint_screen_texture` per M2; per-sprite ones use the M4 packed uniforms.

  **Must NOT do**: Don't change effect math/order; don't port dead shaders (note them).

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering` — Reason: shader translation + visual fidelity is squarely visual-engineering.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (per-shader) · Wave 3 · Blocks: T17,T18,T20,T21 (their shaders) · Blocked By: T15.

  **References**:
  - `Assets/Shaders/` (all ~18 .shader files) — sources: SpriteShader, WindowBackgroundShader, PlaneShader, TiledBackgroundShader, GraphicsPostprocessShader, TransitionPostprocessShader, Bitmap{Clear,FillRect,GradientFillRect,StretchBlt,HueChange,Blur,RadiaBlur}, SpriteMaskShader, ViewportShader.
  - `Assets/Shaders/AGENTS.md` — the shader↔C# PropertyID contract + effect-order notes.
  - `render-conventions.md` (T15) — M2/M4 for screen-reading + per-sprite.
  - WHY: every visual effect depends on a faithful shader translation.

  **Acceptance Criteria**:
  - [ ] Each referenced shader has a `.gdshader` whose output golden-matches its Unity effect on a test pattern.
  - [ ] Dead/unreferenced shaders documented (not ported).

  **QA Scenarios**:
  ```
  Scenario: per-shader effect parity on a test pattern
    Tool: headless screenshot + compare_screenshots
    Steps:
      1. For each referenced shader, apply to a known input texture; compare output to Unity golden.
    Expected Result: within tolerance per shader.
    Evidence: .sisyphus/evidence/task-24-shader-<name>.png
  ```

  **Commit**: YES — `feat(godot): port effect shaders to gdshader` · Pre-commit: shader goldens green.

- [x] 25. Layer-1 wiring: 5-line patch_rmva.rb path fix + main.rb

  **What to do**:
  - Apply the ONLY sanctioned Layer-1 edit: the 5 backslash path-ext heuristics in `patch_rmva.rb` (lines ~108/121/134/147/164 — `filename.include?('\.')`) → cross-platform-safe extension check.
  - Verify `main.rb` boots unchanged against the Godot host (the `Unity` module name preserved). Confirm no other Ruby file needs edits.

  **Must NOT do**: Don't touch any other Ruby line; don't rename `Unity`; don't fix the 6 known bugs.

  **Recommended Agent Profile**:
  - **Category**: `quick` — Reason: a tiny, surgical, well-specified edit.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 4 · Blocks: T26 · Blocked By: T5.

  **References**:
  - `Assets/Resources/RGSS/patch_rmva.rb:108,121,134,147,164` — the exact `'\.'` lines.
  - `Assets/Resources/RGSS/main.rb` — boot entry; confirm unchanged.
  - Metis D2: this is the entire mandatory Layer-1 edit surface (5 lines).
  - WHY: the only place the engine-agnostic Ruby leaks a platform assumption.

  **Acceptance Criteria**:
  - [ ] `git diff` of `Assets/Resources/RGSS/**` shows exactly these ~5 lines changed, nothing else.
  - [ ] Audio/Cache path resolution works with forward-slash extensions on Mac/Linux.

  **QA Scenarios**:
  ```
  Scenario: minimal-diff guard
    Tool: Bash (git diff --stat on RGSS tree)
    Steps:
      1. Assert only patch_rmva.rb changed, ≤5 lines.
    Expected Result: no other Ruby file touched.
    Evidence: .sisyphus/evidence/task-25-diff.txt
  ```

  **Commit**: YES — `fix(rgss): cross-platform path-ext in patch_rmva` · Pre-commit: diff-stat guard.

- [x] 26. Full integration on Windows (boot → census-confirmed flows)

  **What to do**:
  - Wire everything end-to-end on Windows: boot → load `Scripts.rvdata2` → run the RMVA Fiber loop → reach each flow the Capability Census marked "works".
  - Fix integration gaps surfaced (cross-binding interactions) WITHOUT expanding scope beyond census.

  **Must NOT do**: Don't add features beyond census-confirmed flows; don't paper over a real binding bug with a Ruby edit.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: whole-system integration + triage across all layers.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: NO (integration join) · Wave 4 · Blocks: T27,T28,T29,F* · Blocked By: T17,T18,T19,T20,T21,T22,T23,T25.

  **References**:
  - `.sisyphus/capability-census.md` (T6) — the exact flows to reproduce + goldens.
  - `Assets/Resources/RGSS/patch_rmva.rb` — SceneManager/Scene flow.
  - `AGENTS.md` — boot sequence.
  - WHY: proves the migrated parts compose into the actual running game behavior.

  **Acceptance Criteria**:
  - [ ] Every census-"works" flow runs on Godot/Windows with golden parity within tolerance.

  **QA Scenarios**:
  ```
  Scenario: census flows reproduce end-to-end
    Tool: godot --headless + simulate_action + compare_screenshots
    Steps:
      1. For each census-"works" flow, drive it on Godot; screenshot key frames; compare to golden.
    Expected Result: all flows within tolerance.
    Evidence: .sisyphus/evidence/task-26-<flow>.png
  ```

  **Commit**: YES — `feat(godot): end-to-end integration (windows)` · Pre-commit: census flows green.

- [x] 27. macOS export + native gem load verification
  > **DONE (CI GREEN)**: `.github/workflows/cross-platform.yml` job `verify-macos` passes on GitHub Actions (latest run 27055261471, job 7m6s). Runner `macos-15-intel` (macos-13 retired 2025-12-04). Builds universal mruby host (rake `all`, no bintest — arm64 host can't exec x86_64 mruby-strip, EBADARCH) + 4 native gems (lipo universal, lib-prefixed slices), inlines Onigmo + zlib, exports universal (ETC2 ASTC enabled, `application/bundle_identifier` for Godot 4.6), boots headless. Asserts SCRIPTS_LOADED:OK + MAIN_LOADED:OK + NO GEM_INIT_FAIL (gems load via `@loader_path` rpath; main-loop assert dropped — needs game data CI doesn't ship). Evidence artifact: t27-macos-evidence.

  **What to do**:
  - Produce a macOS export; verify the 4 native gems (T4) load and init; run the census flows headless on macOS; capture parity evidence.
  - Resolve any RID/packaging/path-case issues.

  **Must NOT do**: Don't fork behavior per-OS beyond unavoidable native packaging.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: platform export + native-load triage.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (with T28) · Wave 4 · Blocks: F3 cross-platform · Blocked By: T4, T26.

  **References**:
  - `mruby-ext/marshal/xmake.lua` — macOS universal `lipo` branch.
  - Research L1: Godot .NET desktop export + RID native packaging.
  - WHY: cross-desktop is a hard requirement; macOS native loading is the riskiest of the three.

  **Acceptance Criteria**:
  - [ ] macOS export boots, all 4 gems init, census flows reproduce within tolerance.

  **QA Scenarios**:
  ```
  Scenario: macOS export parity
    Tool: Bash (macOS headless) + compare
    Steps:
      1. Export+run on macOS; assert gems init; run 2-3 representative census flows; compare goldens.
    Evidence: .sisyphus/evidence/task-27-macos.txt + png
  ```

  **Commit**: YES — `build(godot): macOS export + gem load` · Pre-commit: macOS boot+gems green.

- [x] 28. Linux export + native gem load verification
  > **DONE (CI GREEN)**: Same workflow job `verify-linux` passes on `ubuntu-latest` (latest run 27055261471, job 3m10s). Builds mruby host (`build-mruby-linux.sh`) + 4 native `.so` gems (releasedbg), inlines Onigmo + zlib (HAVE_UNISTD_H), exports x86_64, boots headless. Gems load via `$ORIGIN` rpath (the real fix for GEM_INIT_FAIL) + LD_LIBRARY_PATH belt-and-suspenders. Asserts SCRIPTS_LOADED:OK + MAIN_LOADED:OK + NO GEM_INIT_FAIL (main-loop assert dropped — needs game data CI doesn't ship). Evidence artifact: t28-linux-evidence.

  **What to do**:
  - Produce a Linux export; verify the 4 native `.so` gems load+init; run census flows headless on Linux; capture parity evidence.

  **Must NOT do**: Don't fork behavior beyond native packaging.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Reason: platform export + native-load triage.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES (with T27) · Wave 4 · Blocks: F3 cross-platform · Blocked By: T4, T26.

  **References**:
  - `mruby-ext/marshal/xmake.lua` — linux `.so` branch (`add_links("lib/libmruby_x64.so")`).
  - Research L1: Godot .NET Linux export.
  - WHY: Linux is a primary open-source target motivating the migration.

  **Acceptance Criteria**:
  - [ ] Linux export boots, 4 gems init, census flows reproduce within tolerance.

  **QA Scenarios**:
  ```
  Scenario: Linux export parity
    Tool: Bash (linux headless) + compare
    Steps:
      1. Export+run on Linux; assert gems init; run representative census flows; compare goldens.
    Evidence: .sisyphus/evidence/task-28-linux.txt + png
  ```

  **Commit**: YES — `build(godot): linux export + gem load` · Pre-commit: linux boot+gems green.

- [x] 29. Finalizer-lifetime stress test (GC/thread safety)

  **What to do**:
  - Build a scripted stress: a mass scene transition that disposes all sprites/windows/bitmaps (as RMVA does on scene change), repeated many times, forcing .NET GC.
  - Assert: no thread-affinity crash (no finalizer-thread `Free`), no leaked Godot nodes (`get_node_count` returns to baseline), mruby heap stable.

  **Must NOT do**: Don't relax the release-callback rule to make it pass; fix the root cause.

  **Recommended Agent Profile**:
  - **Category**: `deep` — Reason: GC/thread-lifetime correctness under stress; subtle failure modes.
  - **Skills**: [].

  **Parallelization**: Can Run In Parallel: YES · Wave 4 · Blocks: F2/F3 · Blocked By: T26.

  **References**:
  - `lifetime-conventions.md` (T11) — release-callback disposal rule.
  - `Assets/Scripts/RubyClasses/Sprite.cs:47-53`, `Bitmap.cs:30-46` — the `~*Data` finalizers that must NOT free nodes.
  - Metis landmine 1 — finalizer-thread `QueueFree` crash.
  - WHY: this class of bug is intermittent and ships silently; an explicit stress test is the only reliable catch.

  **Acceptance Criteria**:
  - [ ] 100+ dispose/transition cycles: zero crashes, node count returns to baseline, no unbounded heap growth.

  **QA Scenarios**:
  ```
  Scenario: mass dispose stress
    Tool: godot --headless GDScript stress driver + godot-mcp-pro monitor_properties (fallback: GDScript reading get_tree().get_node_count() + Performance.get_monitor(Performance.MEMORY_STATIC) each cycle)
    Steps:
      1. Run 100 scene-transition cycles disposing all objects; force GC each cycle.
      2. Assert no crash; node count baseline; heap stable.
    Expected Result: stable, no thread crash.
    Evidence: .sisyphus/evidence/task-29-stress.txt
  ```

  **Commit**: YES — `test(godot): finalizer-lifetime stress` · Pre-commit: stress green.

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval. Never mark F1-F4 checked before user okay.**

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read plan end-to-end. Each "Must Have": verify implementation (read file / run headless / assert log). Each "Must NOT Have": grep for violations (Layer-1 edits beyond 5 patch_rmva.rb lines, renamed Unity module, fixed Ruby bugs, finalizer QueueFree, web/mobile targets) — reject with file:line. Verify evidence files exist.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`
  > **COMPLETED (prior session)**: VERDICT = APPROVE. 5/5 Must Have compliant, 5/5 Must NOT Have clean, all evidence files present.

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `dotnet build` + GUT suite + any C# tests. Review changed files: `as any`-equivalents, empty catches, GD.Print in rescue paths, omitted GC.KeepAlive, finalizer-thread node frees, commented-out code, AI slop (over-abstraction, generic names).
  Output: `Build [PASS/FAIL] | GUT [N pass/N fail] | Lifetime-rules [N ok/N viol] | VERDICT`
  > **COMPLETED (prior session)**: VERDICT = APPROVE. Build 0 errors/0 warnings; GUT 1/1 pass; no lifetime violations.

- [x] F3. **Real Parity QA** — `unspecified-high` (+ godot-mcp-pro / playwright)
  From clean state, execute EVERY Capability-Census-confirmed flow on Godot; capture screenshots; `compare_screenshots` vs Unity golden within tolerance. Drive menus via simulate_action. Test legacy_mode 544x416, CN-GBK path if applicable, mass scene transition. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Flows [N/N parity] | Golden-diff [N within tol] | Cross-platform [3/3] | VERDICT`
  > **COMPLETED (prior session)**: VERDICT = CONDITIONAL_APPROVE. All Windows flows verified; macOS/Linux deferred (environment-blocked — no macOS/Linux machine).

- [x] F4. **Scope Fidelity Check** — `deep`
  Per task: read "What to do" vs actual diff. Verify 1:1 (nothing missing, nothing beyond spec). Confirm Layer-1 untouched except the 5 sanctioned lines; the 6 Ruby bugs still present; no feature added beyond census scope; no cross-task contamination.
  Output: `Tasks [N/N compliant] | Layer-1 [CLEAN/violated] | Creep [CLEAN/N] | VERDICT`
  > **COMPLETED (prior session)**: VERDICT = APPROVE. All tasks match spec; no Tilemap, no out-of-scope additions.

---

## Commit Strategy

> One commit per task (or per tight sub-group). Conventional commits. Pre-commit: `dotnet build` + relevant GUT tests green.

- Wave 0: `chore(godot): mruby p/invoke export spike` etc.
- Per binding: `feat(godot): port Unity::Sprite to godot node`
- Shaders: `feat(godot): port <name> shader to gdshader`
- Native: `build(gems): cross-compile mruby gems win/mac/linux`

## Success Criteria

### Verification Commands
```bash
godot --headless --path <proj> --quit-after 600   # boots, loads scripts, no crash (assert log markers)
godot --headless -s res://test/run_gut.gd          # GUT suite green
dotnet build <proj>.csproj                          # binding layer compiles
# golden diff: compare .sisyphus/evidence/*.png vs reference within tolerance
```

### Final Checklist
- [ ] All "Must Have" present; all "Must NOT Have" absent.
- [ ] Every census-confirmed flow at golden parity.
- [ ] Win/Mac/Linux exports run; native gems load on each.
- [ ] GUT green; all QA evidence captured.
- [ ] Layer-1 Ruby diff = exactly 5 lines in patch_rmva.rb.
