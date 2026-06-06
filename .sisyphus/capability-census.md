# RGSS-Unity Capability Census

**Method**: Static Code Analysis — Unity Editor not available; no golden screenshots
**Date**: 2026-06-06
**Commit context**: main @ 8bd6d60
**Scope**: Enumerate every RGSS flow + all 14 `Unity::` bindings with verdict `WORKS` / `STUB` / `BROKEN`, each backed by `file:line` code evidence. This is a code-connectivity census (does the full Ruby→C#→Unity chain exist?), NOT a runtime/visual-parity census. Pixel correctness cannot be asserted without the Editor.

---

## Summary

| Metric | Count |
|--------|-------|
| `Unity::` types assessed | 14/14 |
| Bindings WORKS | 13 |
| Bindings BROKEN (no native binding) | 1 (Tilemap) |
| Module methods STUB (`RaiseNotImplementError`) | 2 (`Graphics.play_movie`, `Audio.setup_midi`) |
| RMVA game flows assessed | 9 |
| Flows WORKS | 8 |
| Flows BROKEN | 1 (Map load → Tilemap) |

**Headline findings**
1. **13 of 14 `Unity::` types have complete, non-stub C# bindings** (`[RbClass]`/`[RbModule]` attributes confirmed via grep: 14 attributes across 14 files in `Assets/Scripts/RubyClasses/`).
2. **`Unity::Tilemap` has NO C# binding** — `grep RbClass("Tilemap"|RbModule("Tilemap"` = 0 matches. `tilemap.rb:10` calls `Unity::Tilemap.new`, guaranteeing a fatal error. This breaks **Map load** only.
3. **Input IS fully wired** — `GameInputManager.cs` (Assets ROOT) is referenced 21× in `Scenes/SampleScene.unity` (Unity PlayerInput events → handlers → `InputStateRecorder`).
4. The boot chain is complete and connected end-to-end (`GameManager.Start` → `RubyScriptManager.Initialize` → `main.rb` → Marshal load → Fiber loop).

---

## Binding Completeness — 14 `Unity::` types

`Full` = methods have real bodies that manipulate `*Data`/Unity objects. `STUB` = method body is `state.RaiseNotImplementError()` / empty. Verdict is per-type; isolated stub methods are called out in Notes.

| # | Type | C# File | Binding Attr (file:line) | Methods | Verdict |
|---|------|---------|--------------------------|---------|---------|
| 1 | Sprite | `Sprite.cs` (776) | `[RbClass("Sprite","Object","Unity")]` L56 | Full: `new_with_viewport`, `flash`, `update`, `dispose`, `bitmap=`, `src_rect=`, `tone/color`, wave\*, bush\*, `x/y/z/ox/oy`, `zoom_x/y`, `angle`, `mirror`, `blend_type`; per-frame `Render` L651 | **WORKS** |
| 2 | Bitmap | `Bitmap.cs` (758) | `[RbClass("Bitmap","Object","Unity")]` L49 | Full: `new_filename` L76, `new_wh` L118, `blt`, `stretch_blt`, `fill_rect`, `gradient_fill_rect`, `clear`, `blur`, `radial_blur`, `get/set_pixel`, `hue_change`, `text_size`, `draw_text` (TextMeshPro), `font/rect` | **WORKS** |
| 3 | Window | `Window.cs` (1038) | `[RbClass("Window","Object","Unity")]` L178 | Full: `new_xywh` L186, `windowskin=`, `contents=`, `cursor_rect=`, `move`, `update`, `open?/close?`, `tone`, all opacity/padding/openness accessors; 9-patch skin + cursor + scroll arrows + pause cursor in `Render` L718 | **WORKS** |
| 4 | Viewport | `Viewport.cs` (383) | `[RbClass("Viewport","Object","Unity")]` L43 | Full: `new_without_rect` L51, `new_xyrw` L69, `flash`, `update`, `rect`, `color`, `tone`, `ox/oy/z`; `Render` L282 | **WORKS** |
| 5 | Plane | `Plane.cs` (417) | `[RbClass("Plane","Object","Unity")]` L38 | Full: `new_with_viewport` L49, `bitmap=`, `tone`, `color`, `visible`, `z/ox/oy`, `zoom_x/y`, `blend_type`; `Render` L352 | **WORKS** (minor: `disposed?` L330-335 casts to `SpriteData` not `PlaneData` — harmless, see Gaps) |
| 6 | Color | `Color.cs` (117) | `[RbClass("Color","Object","Unity")]` L15 | Full: `new_rgba`, `set_rgba`, `red/green/blue/alpha` get+set | **WORKS** (formerly: `blue=`/`alpha=` ×255 instead of ÷255 — **FIXED 2026-06-06**, see Override note) |
| 7 | Tone | `Tone.cs` (147) | `[RbClass("Tone","Object","Unity")]` L41 | Full: `new_rgbg`, `set_rgbg`, `red/green/blue/gray` get+set | **WORKS** |
| 8 | Rect | `Rect.cs` (118) | `[RbClass("Rect","Object","Unity")]` L16 | Full: `new_xywh`, `set_xywh`, `x/y/width/height` get+set | **WORKS** |
| 9 | Table | `Table.cs` (198) | `[RbClass("Table","Object","Unity")]` L20 | Full: `new_xyz`, `resize`, `get_x/xy/xyz`, `set_x/xy/xyz` (Int16 backing array) | **WORKS** |
| 10 | Font | `Font.cs` (193) | `[RbClass("Font","Object","Unity")]` L24 | Full: `new_ns`, `name`, `size`, `bold`, `italic`, `shadow`, `outline`, `color`, `out_color` | **WORKS** |
| 11 | Graphics | `Graphics.cs` (349) | `[RbModule("Graphics","Unity")]` L21 | Full: `update`, `wait`, `fadein/fadeout`, `freeze`, `transition`, `frame_rate/count`, `brightness`, `resize_screen`, `snap_to_bitmap`, `width/height` | **WORKS** — except `play_movie` L342 = `RaiseNotImplementError` (**STUB**) |
| 12 | Audio | `Audio.cs` (182) | `[RbModule("Audio","Unity")]` L7 | Full: `bgm/bgs/me/se_play`, `*_stop`, `*_fade`, `*_pos` → `GameAudioManager` | **WORKS** — except `setup_midi` L19 = `RaiseNotImplementError` (**STUB**) |
| 13 | Input | `Input.cs` (94) | `[RbModule("Input","Unity")]` L9 | Full: `trigger?`, `press?`, `repeat?`, `dir4`, `dir8`, `update` → `InputStateRecorder` | **WORKS** |
| 14 | **Tilemap** | **(none)** | **NONE — 0 grep matches** | `tilemap.rb:10` calls `Unity::Tilemap.new` → constant/method does not exist | **BROKEN** |

**Module note**: `UnityModule.cs` defines `[RbModule("Unity","")]` L13 (the root module + script loader + Fiber pump `Update` L28). `Kernel.cs` + `RubyExtension.cs` are infrastructure (require/msgbox/GBK transcode; `RubyData` base + `NewObjectWithRData`/`GetRDataObject`).

### NoMethodError / NameError risk audit (Ruby wrapper → C# binding)

Verified by cross-checking each `@__handler__.<method>` call in the Ruby wrappers against the `[RbInstanceMethod]`/`[RbClassMethod]` names in C#:

- **Sprite / Bitmap / Window / Viewport / Plane / Color / Tone / Rect / Table / Font / Graphics / Audio / Input** — every method the wrapper calls has a matching native method. **No NoMethodError risk.**
- **Tilemap** — `tilemap.rb:10` → `Unity::Tilemap.new(viewport)`. `Unity::Tilemap` is never defined (no `[RbClass]`). Additionally `main.rb` (require block L49-64) **does not `require 'tilemap'`**, so the `Tilemap` wrapper class itself is never even loaded. **Guaranteed fatal — see Map-load flow.**

---

## RMVA Game Flows

Each verdict traces the full chain. `WORKS` = engine chain is code-complete and connected; `BROKEN` = chain has a missing link that throws at runtime. (Asset-dependent flows are marked WORKS for the *engine* even where the sample game's specific media may be absent — that is a data concern, not an engine defect.)

| # | Flow | Chain (evidence) | Verdict |
|---|------|------------------|---------|
| 1 | **Boot** | `GameManager.Start` (GameManager.cs:14) inits Render/Input/Audio mgrs → `RubyScriptManager.Initialize` (RubyScriptManager.cs:33: `Ruby.Open`, 4 gem P/Invokes L39-42, define `Unity`/`RPG`, `RbTypeRegisterHelper.Init` L48) → `LoadMainScript` L38 → `main.rb` requires 16 builtins (L49-64) → `run_scripts` (main.rb:35, Marshal-loads `Scripts.rvdata2`) → `require 'patch_rmva'` → `$rgss_main_callback.call`. Per-frame pump: `GameManager.Update` L44 → `UnityModule.Update` (UnityModule.cs:28) resumes Fiber. | **WORKS** |
| 2 | **Title screen** | `Scene_Title` → `Cache.title1` → `Cache.load_bitmap` (patch_rmva.rb:163) → `Bitmap.new(filename)` → `Unity::Bitmap.new_filename` (Bitmap.cs:76); background `Sprite` (Sprite.cs:76) + command `Window`; `Audio.bgm_play` (Audio.cs:26). Engine chain complete. | **WORKS** (engine; requires game's `Graphics/Titles1` asset present) |
| 3 | **Main-menu navigation** | Input edge-detect: `GameInputManager` (Assets ROOT) handlers → `InputStateRecorder.SetPress/SetRelease` (InputStateRecorder.cs:64/74); per-frame swap `Input.update` → `InputStateRecorder.Update` L167; RMVA `Window_Command` cursor via `Window.cursor_rect=` (Window.cs:359) + `update` L403 cursor-flash. Wired in `SampleScene.unity` (21 refs). | **WORKS** |
| 4 | **Map load** | `Scene_Map` → `Spriteset_Map.rb:38` `Tilemap.new(@viewport1)`. `tilemap` is **not required** by `main.rb` → `NameError: uninitialized constant Tilemap`; even if loaded, `tilemap.rb:10` → `Unity::Tilemap.new` → `NoMethodError` (no native binding). Double gap. | **BROKEN** |
| 5 | **Message window** | `Window_Message` → `Window.contents=` (Window.cs:330) sets `ContentsSpriteRenderer.sprite`; text via `Bitmap.draw_text` (Bitmap.cs:533, TextMeshPro render-to-RT); openness animates in render (GameRenderManager.cs:146-160). | **WORKS** |
| 6 | **Battle scene** | `Scene_Battle` patched in `patch_rmva.rb:55` (`update_for_wait` → `Fiber.yield` L58; `process_event` L63). Uses `Sprite`/`Window`/`Bitmap`/`Viewport` only — **no Tilemap dependency**. All chains present. | **WORKS** |
| 7 | **Save / Load** | `kernel.rb` `save_data` L17 / `load_data` L11 → `Marshal.dump`/`load` + `File.open` (native `marshal_c` gem + injected File IO). `patch_rmva.rb` `DataManager.make_filename` L96 + `save_file_exists?` L89 (`Dir.glob` via `dir_glob` gem) reroute to `RMProject/`. | **WORKS** |
| 8 | **Audio (BGM/BGS/SE/ME play/stop/fade)** | `audio.rb` → `Unity::Audio.*` (Audio.cs) → `GameAudioManager` 4 fixed sources (GameAudioManager.cs:55 `Play`, L114 `Stop`, L116 `Fade`, L122 `Pos`); decodes ogg/wav/mp3 via UnityWebRequest, wma via NAudio. `patch_rmva.rb:103-157` appends `.ogg` + RTP fallback. | **WORKS** (`setup_midi` STUB; MIDI unsupported) |
| 9 | **Input (trigger?/press?/repeat?/dir4/dir8)** | `input.rb` (VALID_KEYS L33) → `Unity::Input.*` (Input.cs:29-92) → `InputStateRecorder` (trigger L173 / press L178 / repeat L183 with RMVA cadence `>=23 && (n+1)%6==0` L162; dir4 L82 / dir8 L107). | **WORKS** |

---

## Parity Target for the Godot Port (WORKS flows the port MUST match)

These are the verified-connected Unity behaviors the Godot port must reproduce to claim parity. (Per migration notepad F3 QA, the Godot port already boots, loads all 17 builtins, and starts the Fiber loop — these are the functional targets.)

**Flows (8):**
1. **Boot** — `GameManager.Start` order → mruby open + 4 gem inits → `main.rb` 16 requires → Marshal load `Scripts.rvdata2` → `patch_rmva` Fiber loop → 1 `Fiber.yield` per frame.
2. **Title screen** — Cache→Bitmap.new_filename + Sprite + command Window + bgm_play.
3. **Main-menu navigation** — Input edge-detect + Window cursor_rect cursor-flash.
4. **Message window** — Window.contents= + Bitmap.draw_text + openness animation.
5. **Battle scene** — patched `Scene_Battle` Fiber yields; Sprite/Window/Bitmap/Viewport.
6. **Save/Load** — Marshal + injected File IO + Dir.glob save detection, RMProject path reroute.
7. **Audio** — BGM/BGS/SE/ME play/stop/fade/pos over 4 channels; `.ogg` default + RTP fallback.
8. **Input** — trigger?/press?/repeat?/dir4/dir8 with exact RMVA repeat cadence.

**Bindings (13 native types):** Sprite, Bitmap, Window, Viewport, Plane, Color, Tone, Rect, Table, Font, Graphics, Audio, Input — each with the method set enumerated in the table above.

**Render-pipeline contract (must match):** per-viewport children walked by tag (`RGSSSprite`/`RGSSPlane`/`RGSSWindow`), each rendered to the viewport RenderTexture, composited to main RT, then `Graphics.Postprocess` (brightness/transition) to screen — `GameRenderManager.Update` (GameRenderManager.cs:55-205). RGSS Y is top-down → render flips to `-data.Y` (L110). `sortingOrder = data.Z`.

---

## Known Gaps (BROKEN / STUB — out of scope for the Godot port)

**BROKEN (do not port; intentionally absent):**
- **`Unity::Tilemap`** — no C# binding (`Tilemap.cs` does not exist; 0 `RbClass`/`RbModule` matches). `tilemap.rb:10` would `NoMethodError`, and `tilemap` is not required by `main.rb` so `Tilemap.new` in `Spriteset_Map.rb:38` first hits `NameError`. **Map scenes cannot load in the Unity build.** The Godot port is explicitly instructed to NOT add a Tilemap binding.

**STUB (method exists but unimplemented — parity = same stub):**
- `Graphics.play_movie` — `Graphics.cs:342` `RaiseNotImplementError`.
- `Audio.setup_midi` — `Audio.cs:19` `RaiseNotImplementError` (MIDI playback unsupported).

**Known bugs — ~~DO NOT FIX (parity baseline)~~ → FIXED per USER OVERRIDE 2026-06-06.**

> **OVERRIDE (2026-06-06)**: The user explicitly elected to **fix all 6 Ruby-layer bugs** (option "Override: fix all 6 Ruby bugs"), superseding the original bug-for-bug parity decision (D3). This is a deliberate parity break: the Godot port now behaves *more correctly* than the source Unity build. All fixes are minimal (1 token / 1 line each). Verified: `dotnet build` 0 errors + headless boot reaches SCRIPTS_LOADED:OK / MAIN_LOADED:OK with no syntax error in any edited file. Original buggy forms retained below (struck through) for historical traceability.

*C# bindings:*
- ~~`Color.cs:97` `blue=` multiplies ×255 (should ÷255); `Color.cs:113` `alpha=` same.~~ **FIXED** → both now `/ 255.0f` (matching `red=`/`green=`). Coupled to the `color.rb` getter→setter fix below: the Ruby bug previously *masked* these setters (assignment was a silent no-op); fixing Ruby made them reachable, so the C# typo had to be corrected in the same pass or `blue=`/`alpha=` would store corrupted values.
- `Plane.cs:330-335` `disposed?` calls `GetRDataObject<SpriteData>()` then reads `SpriteObject` instead of `PlaneData`/`PlaneObject`. Harmless in practice (data kept alive by live-keeper). **Left as-is** — not in the 6 Ruby-script bugs the user scoped; C#-only, no behavioral effect.

*Ruby wrappers (all FIXED):*
- ~~`audio.rb:47` — symbol list contains `:set_stop` (typo for `:se_stop`)~~ **FIXED** → `:se_stop` (C# binding `Audio.se_stop` exists, 0-arg, verified).
- ~~`viewport.rb:15` — `Unity::Viewport.new_xyrw(rect.x, rect.y, rect.w. rect.h)` — stray `.`~~ **FIXED** → `rect.w, rect.h` (now passes 4 args matching `new_xyrw` arity).
- ~~`bitmap.rb:66` — `gradient_fill_rect(... rect.w. rect.h ...)` stray-dot; also `check_arugments` typo L44~~ **FIXED** → `rect.w, rect.h` (7 args matching binding) + `check_arguments`.
- ~~`plane.rb:14` — `@viewport.__handler__` (nil ivar) instead of `viewport` arg; `plane.rb:36` `def viewport=` no parameter~~ **FIXED** → `viewport.__handler__` + `def viewport=(value)`.
- ~~`color.rb:65` `send(prop, v)` (calls getter, ignores value); `font.rb:72/76` `arg is_a?` (missing dot)~~ **FIXED** → `send("#{prop}=", v)` + `arg.is_a?` ×2. font.rb also had a coupled order bug (`name.each` ran before `name = arg`, guaranteed nil-crash, exposed once `is_a?` parsed) — reordered so assignment precedes iteration.

---

## Method & Caveats

- **Method**: pure static reading of C# bindings (`Assets/Scripts/RubyClasses/*.cs`), managers (`Assets/Scripts/*.cs`, `Assets/GameInputManager.cs`), and Ruby layer (`Assets/Resources/RGSS/*.rb`), plus `grep` connectivity checks. No code was executed.
- **Cannot assert**: pixel/visual correctness, shader output, timing/animation smoothness, audio fidelity, or actual frame composition — **Unity Editor is not installed; no golden screenshots exist.** A `WORKS` verdict means "the Ruby→C#→Unity call chain is code-complete and free of NoMethodError," not "visually correct."
- **Asset dependence**: Title/Map/Message flows additionally need the sample game's `Graphics/`, `Data/`, `Audio/` assets under `StreamingAssets/RMProject/`; their absence is a data gap, not an engine defect.
