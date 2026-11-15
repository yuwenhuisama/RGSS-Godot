# RGSS3 API Implementation Inventory

Official-surface inventory for the RGSS3 game library, checked against the current worktree source.
This document replaces the stale Unity-era `.omo/capability-census.md`; it is derived only from the
official reference pages and the current Godot/mruby source.

## Subsequent verified increments

The summary below is the initial inventory snapshot, not a live completion
percentage. Later accepted increments are recorded here without rewriting
unverified rows as proven:

- B01 Windows RGSS300 font measurement: 220 original-generated cases agree,
  covering two font families, five sizes, bold, Chinese/English/mixed/numeric
  input. Real width-constrained drawing matches all sampled original native
  average-width thresholds. Non-Windows measurement parity is still unverified.
- B02 font names preserve String versus Array, ordered fallback and real
  Font.exist? work, Chinese default matches installed nsimsun; Bitmap.font
  retains identity and styles on repeated reads. Default setters are tested.
- B03 Windows font styles: 35 original-generated transparent glyph alpha
  samples agree exactly, including normal/bold/italic/shadow/outline; fresh
  composed six-row same-background visual acceptance passes. Unified Windows
  font plus GPU suite passes nine runners. Non-Windows styles remain unverified.
- B04 Table resize preserves coordinates across dimensions, Color constructor
  and setter ranges follow original RGB-negative/alpha-clamp behavior, Tone
  constructor ranges corrected. Seven value-semantics tests and API 83 cases pass.
- B05 in progress: actual original probes require object-valued getters to
  preserve identity and disposed access to raise RGSSError. Sprite/Bitmap
  initial probe now agrees; expanded resource classes remain under verification.
- B05 accepted: six resource types preserve assigned/reference getter identity,
  repeat disposal and raise RGSSError for disposed public access; original
  lifecycle fixture and targeted/whole suite pass.
- B06 accepted on Windows: original F1 general/keyboard/gamepad pages compared,
  remapping/cancel/save/reload, display/audio switches and AltEnter verified.
  F2 titlebar FPS matches original; actual map F12 returns title with identical
  resource counts. Default Input alternatives and repeat/invalid-key behavior pass.
- B07 actual Theora playback, cooperative return, Esc skip and failure cleanup
  verified. Original wide-video observation establishes native centered sizing,
  and the port matches that framing. MIDI and WMA remain separate open work.

## Provenance and method

- Official surface: `docs/rgss-reference/rgss/g_*.md` (13 built-in classes, 4 modules, 6 built-in functions, 45 RPG data classes).
- Implementation: `RGSS/*.rb` (Ruby wrappers), `Scripts/RubyClasses/*.cs` (mruby bindings), `Scripts/Graphics.cs`, `Scripts/GameRenderManager.cs`, `Scripts/GameAudioManager.cs`, `RGSS/rpg/*.rb`.
- Worktree: commit `346e91e`, dirty (313 changed/untracked paths). Statuses describe this worktree, not a clean clone.
- Member counts are deduplicated per documented name (overloads such as `Bitmap.new(filename)` / `Bitmap.new(w,h)` count once).
  Overload coverage is called out in the Notes column.
- RPG data classes are inventoried **one row per class** listing every documented attribute/method, because all 45 class
  definitions were diffed against the official `定義` blocks and match exactly (see "RPG data classes" below).
  The 318 documented RPG members are therefore covered by 45 rows, not 318.

### Status vocabulary

| Status | Meaning |
|---|---|
| `implemented` | Ruby wrapper and native binding exist with real behavior; behavior asserted by a passing test where `RT`/`RS` is shown. |
| `partial` | Interface exists and is callable, but a documented behavior, default, or rendering effect is missing or wrong. |
| `missing` | Documented member has no working implementation (stub, no-op, or absent). |
| `unverified` | Interface exists but no static or runtime evidence establishes behavior either way. |

### Evidence vocabulary

| Tag | Meaning |
|---|---|
| `RT` | Runtime-tested: asserted by a passing GUT/SceneTree test in `tests/`. |
| `RS` | Runtime-smoke only: test calls it but asserts nothing about the documented behavior. |
| `ST` | Static only: wrapper + binding traced by reading source; no test exercises the documented behavior. |

Runtime evidence baseline (reported by the lead after the VM fix; not re-run in this task):
`tests/test_rgss_api.gd` 83/83, `tests/test_eval_damage_fix.gd` 5/5, `tests/test_stress_dispose.gd` STRESS_PASS,
`tests/test_graphics_snapshot.gd` and `tests/test_window_transparency.gd` rendered passes, `tools/run_tests.gd` six scripts exit 0.
This inventory does not claim any test result beyond what those files assert.

## Summary

| Scope | Documented members | Rows | implemented | partial | missing |
|---|---|---|---|---|---|
| Built-in classes (11) | 163 | 163 | 138 | 25 | 0 |
| Built-in modules (Graphics, Audio, Input) | 39 | 39 | 27 | 10 | 2 |
| Built-in functions (Kernel) | 6 | 6 | 2 | 4 | 0 |
| Exception classes (RGSSError, RGSSReset) | 2 | 2 | 0 | 1 | 1 |
| RPG data classes (45) | 318 | 45 | 45 (whole-class) | 0 | 0 |
| **Total** | **528** | **255** | **212** | **40** | **3** |

Unverified rows: 0. No coverage percentage is given because rows and members are different units
(see the RPG granularity note above).

## Built-in classes

### Bitmap
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new(filename) / new(width, height)` | partial | RT (size/file) | `RGSS/bitmap.rb:initialize`; `Bitmap.cs:NewWithFileName/NewWithWidthAndHeight` | Real 16x12 PNG constructor and rect dimensions pass; zero/negative dimensions raise rescueable RGSSError like original. Encrypted archive lookup remains a project-loading gap. |
| `dispose` | implemented | RT | `RGSS/bitmap.rb:78`; `Bitmap.cs:69-80` | Idempotent double dispose asserted. |
| `disposed?` | implemented | RT | `Bitmap.cs:82-90` | Safe after dispose; asserted. |
| `width` | implemented | RT | `Bitmap.cs:92-94` |  |
| `height` | implemented | RT | `Bitmap.cs:96-98` |  |
| `rect` | implemented | RT | `RGSS/bitmap.rb:158-165`; `Bitmap.cs:113-120` |  |
| `blt` | implemented | RT (pixel) | `RGSS/bitmap.rb:32-35`; `Bitmap.cs:124-137` | Pixel copy + bounds asserted. |
| `stretch_blt` | implemented | RT (original pixel/render) | `RGSS/bitmap.rb:stretch_blt`; `Bitmap.cs:StretchBlendImage` | Original enlargement/shrinking coordinate probes pass with fixed-point nearest sampling. Actual rendered edge max delta 1; independent visual pass. |
| `fill_rect` | implemented | RT (pixel) | `RGSS/bitmap.rb:42-56`; `Bitmap.cs:153-165` | Both documented overloads asserted. |
| `gradient_fill_rect` | implemented | RT (original pixel/render) | `RGSS/bitmap.rb:gradient_fill_rect`; `Bitmap.cs:GradientFillRect` | Numeric optional argument presence selects vertical, Rect overload follows boolean; original false/true/nil and omitted probes verified. Integer delta truncation and requested clipping length match. |
| `clear` | implemented | RT (pixel) | `RGSS/bitmap.rb:78`; `Bitmap.cs:181-188` |  |
| `clear_rect` | implemented | RT (pixel) | `RGSS/bitmap.rb:86-100`; `Bitmap.cs:167-179` | Both overloads asserted. |
| `get_pixel` | implemented | RT (pixel) | `RGSS/bitmap.rb:102-106`; `Bitmap.cs:190-202` | Out-of-range returns transparent. |
| `set_pixel` | implemented | RT (pixel) | `RGSS/bitmap.rb:108-112`; `Bitmap.cs:204-218` |  |
| `hue_change` | implemented | RT (original pixel/render) | `RGSS/bitmap.rb:hue_change`; `Bitmap.cs:HueChange` | Integer HSL matches seven complete original palettes and nine extra probes; fixed reference rgss300-hue-reference.tsv and independent visual pass. |
| `blur` | implemented | RT (original pixel/render) | `RGSS/bitmap.rb:blur`; `Bitmap.cs:Blur` | Complete colored/transparent impulse kernel and grayscale samples match original; fixed reference rgss300-blur-reference.tsv and independent visual pass. |
| `radial_blur` | implemented | RT (original pixel/render) | `RGSS/bitmap.rb:radial_blur`; `Bitmap.cs:RadialBlur` | Full original impulse/corner/low/uniform/colored coordinate references match; symmetric D taps and mirrored borders. Rendered max delta 1; independent visual pass. |
| `draw_text` | implemented (Windows) | RT (original pixel/render) | `RGSS/bitmap.rb:draw_text`; `Bitmap.cs:DrawNativeText`; `FontMetrics.cs:Rasterize` | Original font styles, twelve layout alpha captures and nineteen compression widths match. Compatible-DC compression mechanism traced directly; nine rendered layouts pass independent visual review. Other platforms remain F10. |
| `text_size` | implemented (Windows) | RT (original metrics) | `RGSS/bitmap.rb:text_size`; `FontMetrics.cs:Measure` | 220 original font/name/size/bold variants match; outline/italic excluded as required. Rendering uses glyph advance separately for control characters. Other platforms remain F10. |
| `font` | implemented | RT | `RGSS/bitmap.rb:167-174`; `Bitmap.cs:100-111` | Getter returns Font; setter wires BitmapData.FontData. |

### Color
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new(r,g,b[,a]) / new` | implemented | RT | `RGSS/color.rb:9-27`; `Scripts/RubyClasses/Color.cs:46-64` | 0..255 round-trip and alpha default asserted. |
| `set(r,g,b[,a]) / set(color)` | implemented | RT | `RGSS/color.rb:29-48`; `Color.cs:66-83` | Both overloads asserted; normalization regression covered. |
| `red` | implemented | RT | `RGSS/color.rb:66-75`; `Color.cs:85-98` | Clamped 0..255. |
| `green` | implemented | RT | `Color.cs:101-114` |  |
| `blue` | implemented | RT | `Color.cs:117-130` |  |
| `alpha` | implemented | RT | `Color.cs:133-147` |  |

### Tone
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new(r,g,b[,gray]) / new` | implemented | RT | `RGSS/tone.rb:9-27`; `Scripts/RubyClasses/Tone.cs:55-65` | Gray default asserted. |
| `set(r,g,b[,gray]) / set(tone)` | implemented | RT | `RGSS/tone.rb:29-47`; `Tone.cs:67-81` | Both overloads asserted. |
| `red` | implemented | RT | `RGSS/tone.rb:73-81`; `Tone.cs:83-96` | Clamped -255..255. |
| `green` | implemented | RT | `Tone.cs:99-112` |  |
| `blue` | implemented | RT | `Tone.cs:115-128` |  |
| `gray` | implemented | RT | `Tone.cs:131-145` | Clamped 0..255. |

### Rect
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new(x,y,w,h) / new` | implemented | RT | `RGSS/rect.rb:9-23`; `Scripts/RubyClasses/Rect.cs:36-46` | No-arg form asserted. |
| `set(x,y,w,h) / set(rect)` | implemented | RT | `RGSS/rect.rb:25-38`; `Rect.cs:48-62` | Both overloads asserted. |
| `empty` | implemented | RT | `RGSS/rect.rb:40-42` | Zeroes all four fields; asserted. |
| `x` | implemented | RT | `RGSS/rect.rb:70-81`; `Rect.cs:64-78` |  |
| `y` | implemented | RT | `Rect.cs:80-94` |  |
| `width` | implemented | RT | `Rect.cs:96-110` | `w`/`w=` aliases also present (`rect.rb:76-79`). |
| `height` | implemented | RT | `Rect.cs:112-126` | `h`/`h=` aliases also present. |

### Font
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new([name[,size]])` | implemented | RT | `RGSS/font.rb:62-103`; `Scripts/RubyClasses/Font.cs:34-60` | Defaults applied from class defaults; asserted. |
| `exist?` | partial | ST | `RGSS/font.rb:173-176` | Always returns true (deliberate permissive stub); documented system-font probe not implemented. |
| `name` | partial | RT | `RGSS/font.rb:123-137`; `Font.cs:62-76` | Getter returns an Array, not the documented String; test pins Array (`tests/test_rgss_api.gd:283-287`). Name is also not used by draw_text (`Bitmap.cs:345`). |
| `size` | implemented | RT | `Font.cs:79-91` | Used as draw_text font size. |
| `bold` | partial | RT | `Font.cs:94-106` | State round-trips but DrawTextToImage has no bold parameter (`Bitmap.cs:342-360`). |
| `italic` | partial | RT | `Font.cs:109-121` | State round-trips but not rendered; same missing parameter. |
| `outline` | implemented | RT | `Font.cs:139-151` | Passed to DrawTextToImage (`Bitmap.cs:330-331`). |
| `shadow` | partial | RT | `Font.cs:124-136` | State round-trips but not rendered; no shadow pass in `Bitmap.cs:342-360`. |
| `color` | implemented | RT | `RGSS/font.rb:105-112`; `Font.cs:154-180` | Used as glyph color. |
| `out_color` | implemented | RT | `RGSS/font.rb:114-121`; `Font.cs:183-207` | Used as outline color. |
| `default_name` | partial | ST | `RGSS/font.rb:20-32,45` | Default is `["Arial"]`; reference default is "VL Gothic" (`gc_font.md:38`). |
| `default_size` | implemented | RT | `RGSS/font.rb:46` | 24 matches reference. |
| `default_bold` | implemented | RT | `RGSS/font.rb:47` | false matches. |
| `default_italic` | implemented | RT | `RGSS/font.rb:48` | false matches. |
| `default_shadow` | implemented | RT | `RGSS/font.rb:49` | false matches. |
| `default_outline` | implemented | RT | `RGSS/font.rb:50` | true matches. |
| `default_color` | implemented | RT | `RGSS/font.rb:51` | White matches. |
| `default_out_color` | implemented | RT | `RGSS/font.rb:52` | (0,0,0,128) matches. |

### Plane
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new([viewport])` | implemented | RT | `RGSS/plane.rb:9-16`; `Scripts/RubyClasses/Plane.cs:10-31` | Default viewport path asserted. |
| `dispose` | implemented | RT | `RGSS/plane.rb:18`; `Plane.cs:33-46` |  |
| `disposed?` | implemented | ST | `Plane.cs:48-50` |  |
| `bitmap` | implemented | RT | `RGSS/plane.rb:20-28`; `Plane.cs:52-62` | nil accepted; asserted. |
| `viewport` | implemented | ST | `RGSS/plane.rb:30-40`; `Plane.cs:64-75` | Returns nil for default viewport. |
| `visible` | implemented | RT | `RGSS/plane.rb:72-82`; `Plane.cs:133-141` |  |
| `z` | implemented | RT | `Plane.cs:144-152` |  |
| `ox` | implemented | RT | `Plane.cs:155-163` |  |
| `oy` | implemented | RT | `Plane.cs:166-174` |  |
| `zoom_x` | implemented | RT | `Plane.cs:177-185` |  |
| `zoom_y` | implemented | RT | `Plane.cs:188-196` |  |
| `opacity` | implemented | RT | `Plane.cs:199-207` | Clamped 0..255. |
| `blend_type` | implemented | RT | `Plane.cs:210-221`; `GameRenderManager.cs:1230-1250` | 0/1/2 map to mix/add/sub shader variants. |
| `color` | implemented | RT | `RGSS/plane.rb:42-49`; `Plane.cs:105-131` | Applied as `mix_color` (`GameRenderManager.cs:665`). |
| `tone` | implemented | RT | `RGSS/plane.rb:51-58`; `Plane.cs:77-103` | Applied to plane shader. |

### Viewport
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new(x,y,w,h) / new(rect) / new` | implemented | RT (4-arg) / ST (overloads) | `RGSS/viewport.rb:9-25`; `Scripts/RubyClasses/Viewport.cs:12-28` | 4-arg asserted; Rect and no-arg forms source-traced. |
| `dispose` | implemented | RT | `RGSS/viewport.rb:46`; `Viewport.cs:31-39` | Children are unregistered (`GameRenderManager.cs:292-340`). |
| `disposed?` | implemented | ST | `Viewport.cs:41-43` |  |
| `flash` | partial | RS | `RGSS/viewport.rb:28-35`; `Viewport.cs:171-185` | Stores FlashColor/FlashRemain and update() decrements, but the render loop never applies viewport flash (`GameRenderManager.cs:209-243`); `Shaders/ViewportShader.gdshader` is unreferenced. |
| `update` | implemented | ST | `Viewport.cs:187-200` | Advances flash countdown; no visual consumer (see flash). |
| `rect` | implemented | RT | `RGSS/viewport.rb:70-77`; `Viewport.cs:45-71` | Geometry applied to SubViewport (`GameRenderManager.cs:214-231`). |
| `visible` | implemented | RT | `RGSS/viewport.rb:37-44`; `Viewport.cs:73-82` |  |
| `z` | implemented | RT | `RGSS/viewport.rb:90-97`; `Viewport.cs:106-115` | Sorts viewport layers (`GameRenderManager.cs:205-207`). |
| `ox` | implemented | RT | `Viewport.cs:84-93` | Scrolls SubViewport root. |
| `oy` | implemented | RT | `Viewport.cs:95-104` |  |
| `color` | partial | ST | `RGSS/viewport.rb:52-59`; `Viewport.cs:144-169` | Stored as FlashColor but never blended by the renderer; same unused shader path. |
| `tone` | partial | ST | `RGSS/viewport.rb:61-68`; `Viewport.cs:117-142` | Stored but never applied; render loop ignores ViewportData.Tone. |

### Sprite
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new([viewport])` | implemented | RT | `RGSS/sprite.rb:9-15`; `Scripts/RubyClasses/Sprite.cs:10-34` | Default and explicit viewport asserted. |
| `dispose` | implemented | RT | `RGSS/sprite.rb:26`; `Sprite.cs:36-49` |  |
| `disposed?` | implemented | RT | `Sprite.cs:51-53` |  |
| `flash` | partial | RS | `RGSS/sprite.rb:17-24`; `Sprite.cs:55-63` | Color flash rendered via `_PackedC` (`GameRenderManager.cs:1506-1511`); documented `flash(nil,duration)` erase is not implemented (null color yields zero alpha). |
| `update` | implemented | RS | `Sprite.cs:65-88` | Advances flash countdown and wave phase; wave phase is not consumed by the shader. |
| `width` | implemented | RT | `Sprite.cs:90-95` | src_rect width, else bitmap width. |
| `height` | implemented | RT | `Sprite.cs:97-102` |  |
| `bitmap` | implemented | RT | `RGSS/sprite.rb:30-42`; `Sprite.cs:104-134` | nil accepted; asserted. |
| `src_rect` | implemented | RT | `RGSS/sprite.rb:44-51`; `Sprite.cs:136-182` | In-place mutation kept live. |
| `viewport` | implemented | RT | `RGSS/sprite.rb:53-67`; `Sprite.cs:184-195` | nil resets to default; asserted. |
| `visible` | implemented | RT | `RGSS/sprite.rb:143-146`; `Sprite.cs:253-261` |  |
| `x` | implemented | RT | `Sprite.cs:263-271` |  |
| `y` | implemented | RT | `Sprite.cs:273-281` |  |
| `z` | implemented | RT | `Sprite.cs:283-291`; `GameRenderManager.cs:602` | ZIndex only; documented Y/creation-order tie-break not implemented. |
| `ox` | implemented | RT | `Sprite.cs:293-301` |  |
| `oy` | implemented | RT | `Sprite.cs:303-311` |  |
| `zoom_x` | implemented | RT | `Sprite.cs:313-321` |  |
| `zoom_y` | implemented | RT | `Sprite.cs:323-331` |  |
| `angle` | implemented | RT | `Sprite.cs:333-341`; `GameRenderManager.cs:604` |  |
| `wave_amp` | partial | ST | `Sprite.cs:393-401`; `GameRenderManager.cs:617`; `Shaders/SpriteShader.gdshader:38` | Pixel amplitude is passed as a 0..1 blend factor (`clamp(_PackedA.x,0,1)`), so amplitudes >=1 all render identically. |
| `wave_length` | implemented | ST | `Sprite.cs:403-411`; `SpriteShader.gdshader:25` | Used as wave period. |
| `wave_speed` | implemented | ST | `Sprite.cs:413-421`; `SpriteShader.gdshader:24` | Used in phase advance. |
| `wave_phase` | partial | ST | `Sprite.cs:423-431`; `SpriteShader.gdshader:24` | Stored and advanced by update, but never uploaded; shader derives phase from TIME. |
| `mirror` | partial | ST | `Sprite.cs:343-351`; `GameRenderManager.cs:605`; `SpriteShader.gdshader:35` | Applied twice (FlipH and shader UV flip), so the two flips cancel. |
| `bush_depth` | partial | ST | `Sprite.cs:373-381`; `GameRenderManager.cs:625`; `SpriteShader.gdshader:51` | Documented pixels are divided by 255 and compared to UV (0..1), not divided by texture height. |
| `bush_opacity` | partial | ST | `Sprite.cs:383-391`; `SpriteData.cs:30`; `SpriteShader.gdshader:52` | Effect works, but default is 255; reference default is 128 (`gc_sprite.md:177`). |
| `opacity` | implemented | RT | `Sprite.cs:353-361` | Clamped 0..255; asserted. |
| `blend_type` | partial | RT | `RGSS/sprite.rb:96-108`; `Sprite.cs:363-372` | State validates/clamps, but SpriteShader is fixed `blend_mix` and RenderSprite selects no variant (`SpriteShader.gdshader:2`, `GameRenderManager.cs:590-627`). |
| `color` | implemented | RT | `RGSS/sprite.rb:69-76`; `Sprite.cs:225-251` | Applied as `mix_color`. |
| `tone` | implemented | RT | `RGSS/sprite.rb:78-85`; `Sprite.cs:197-223` | Applied via `_PackedB`. |

### Table
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new(xsize[,ysize[,zsize]])` | implemented | RT | `RGSS/table.rb:9-12`; `Scripts/RubyClasses/Table.cs:23-41` | 1D/2D/3D asserted. |
| `resize` | partial | RT (1D) | `RGSS/table.rb:14-17`; `Table.cs:55-85` | Uses flat `Array.Resize`; 2D/3D overlap semantics not implemented or tested. |
| `xsize` | implemented | RT | `RGSS/table.rb:106-108`; `Table.cs:43-45` |  |
| `ysize` | implemented | RT | `Table.cs:47-49` |  |
| `zsize` | implemented | RT | `Table.cs:51-53` |  |
| `self[*x*]` | implemented | RT | `RGSS/table.rb:19-28`; `Table.cs:87-98` | Out-of-range nil asserted. |
| `self[*x*, *y*]` | implemented | RT | `RGSS/table.rb:29-33`; `Table.cs:100-119` | Per-axis bounds asserted. |
| `self[*x*, *y*, *z*]` | implemented | RT | `RGSS/table.rb:34-38`; `Table.cs:121-143` | 3D get/set and dump/load asserted. |

### Tilemap
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new([viewport])` | implemented | RT | `RGSS/tilemap.rb:9-17`; `Scripts/RubyClasses/Tilemap.cs:10-28` |  |
| `dispose` | implemented | RT | `RGSS/tilemap.rb:19`; `Tilemap.cs:30-47` |  |
| `disposed?` | implemented | RT | `Tilemap.cs:49-51` |  |
| `update` | implemented | ST | `Tilemap.cs:53-63` | Advances autotile/flash ticks read by `GameRenderManager.cs:1049-1056`. |
| `bitmaps[*index*]` | implemented | RT | `RGSS/tilemap.rb:23-25,88-102`; `Tilemap.cs:65-84` | Proxy assignment and getter asserted. |
| `map_data` | implemented | RT | `RGSS/tilemap.rb:27-35`; `Tilemap.cs:86-102` |  |
| `flash_data` | implemented | ST | `RGSS/tilemap.rb:37-45`; `Tilemap.cs:104-113` | Consumed by flash compositing (`GameRenderManager.cs:1104,1139`); no test. |
| `flags` | implemented | RT | `RGSS/tilemap.rb:47-55`; `Tilemap.cs:115-126` | Over-player/table flags read at `GameRenderManager.cs:1179-1197`. |
| `viewport` | partial | ST | `RGSS/tilemap.rb:57-65`; `Tilemap.cs:128-139` | Getter returns `@viewport`, which `initialize` never assigns (`tilemap.rb:9-17`), so it is always nil even for an explicit viewport. |
| `visible` | implemented | RT | `RGSS/tilemap.rb:78-81`; `Tilemap.cs:164-171` |  |
| `ox` | implemented | RT | `Tilemap.cs:142-151` | Sub-tile scroll applied at `GameRenderManager.cs:1085-1090`. |
| `oy` | implemented | RT | `Tilemap.cs:153-162` |  |

### Window
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `new([x,y,width,height])` | implemented | RT | `RGSS/window.rb:9-16`; `Scripts/RubyClasses/Window.cs:17-22` | Defaults padding 12 and contents bitmap. |
| `dispose` | implemented | RT | `RGSS/window.rb:143`; `Window.cs:24-39` |  |
| `disposed?` | implemented | RT | `Window.cs:42-44` |  |
| `update` | implemented | ST | `Window.cs:46-53` | AnimationTick drives cursor blink/pause (`GameRenderManager.cs:771,811`). |
| `move` | implemented | RT | `RGSS/window.rb:18-21`; `Window.cs:63-72` |  |
| `open?` | implemented | RT | `Window.cs:55-57` | openness == 255. |
| `close?` | implemented | RT | `Window.cs:59-61` | openness == 0. |
| `windowskin` | partial | ST | `RGSS/window.rb:23-30`; `Window.cs:85-94` | Getter calls `Bitmap.new(nil)` when no skin is set, which raises TypeError (`bitmap.rb:9-19`); documented property should return nil. |
| `contents` | implemented | RT | `RGSS/window.rb:32-39`; `Window.cs:74-83` |  |
| `cursor_rect` | implemented | RT | `RGSS/window.rb:41-48`; `Window.cs:96-105` |  |
| `viewport` | implemented | RT | `RGSS/window.rb:50-61`; `Window.cs:107-118` | nil for default viewport. |
| `active` | implemented | RT | `Window.cs:200-208` | Cursor blink dims when inactive. |
| `visible` | implemented | RT | `Window.cs:190-198` |  |
| `arrows_visible` | implemented | RT | `Window.cs:220-228` |  |
| `pause` | implemented | RT | `Window.cs:210-218` | Pause sign animated at `GameRenderManager.cs:806-824`. |
| `x` | implemented | RT | `Window.cs:120-128` |  |
| `y` | implemented | RT | `Window.cs:130-138` |  |
| `width` | implemented | RT | `RGSS/window.rb:110-120`; `Window.cs:150-158` | Negative rejected in Ruby. |
| `height` | implemented | RT | `RGSS/window.rb:122-132`; `Window.cs:160-168` | Negative rejected in Ruby. |
| `z` | implemented | RT | `Window.cs:140-148` | Default 100 (`WindowData.cs:16`) matches reference. |
| `ox` | implemented | RT | `Window.cs:170-178` | Scrolls contents and cursor. |
| `oy` | implemented | RT | `Window.cs:180-188` |  |
| `padding` | implemented | RT | `Window.cs:270-280`; `GameRenderManager.cs:735-740` | Also sets padding_bottom, matching reference. |
| `padding_bottom` | implemented | RT | `Window.cs:282-290` |  |
| `opacity` | implemented | RT | `RGSS/window.rb:74-81`; `Window.cs:230-238` | Clamped. |
| `back_opacity` | implemented | RT | `RGSS/window.rb:83-90`; `Window.cs:240-248` | Default 192 matches. |
| `contents_opacity` | implemented | RT | `RGSS/window.rb:92-99`; `Window.cs:250-258` | Applied independently of opacity (`GameRenderManager.cs:748`). |
| `openness` | implemented | RT | `RGSS/window.rb:101-108`; `Window.cs:260-268` | Contents hidden below 255 (`GameRenderManager.cs:738`). |
| `tone` | implemented | RT | `RGSS/window.rb:134-141`; `Window.cs:292-322` | Applied to background shaders (`GameRenderManager.cs:723-729`). |


## Built-in modules

### Graphics
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `update` | implemented | RT (boot) | `RGSS/graphics.rb:123-127`; `Scripts/Graphics.cs:20-26` | Calls C# frame counter then Fiber.yield; excluded from the bare API suite by design. |
| `wait` | implemented | RT (original timing/render loop) | `RGSS/graphics.rb:wait`; `tests/test_frame_loop.gd` | Original durations 0/1/4/-1 agree; thirty loop iterations and four waiting frames advance exactly one update per rendered frame. |
| `fadeout` | implemented | ST | `RGSS/graphics.rb:57-62`; `Graphics.cs:79-88` | Starts brightness ramp and waits. |
| `fadein` | implemented | ST | `RGSS/graphics.rb:64-69`; `Graphics.cs:90-97` |  |
| `freeze` | partial | ST | `RGSS/graphics.rb:129-133`; `Graphics.cs:99-105` | Captures the frozen texture, but the `Freezing` flag is never read, so the documented "no rewrites until transition" is not enforced. |
| `transition` | implemented (local images) | RT (original pixels and dynamic surface) | `RGSS/graphics.rb:transition`; `Graphics.cs:Transition`; `TransitionPostprocessShader.gdshader` | Masked transition reveals the live scene; unmasked transition crossfades from the frozen scene. Original end pixels agree. Full-resolution 120-frame capture and original window video show matching center, radius, softness and uniform fade. Apparent mask modulation difference was traced to lossy reference encoding; Godot follows raw mask bytes exactly. Archive image lookup remains a separate project-loading gap. |
| `snap_to_bitmap` | implemented | RT (rendered) | `RGSS/graphics.rb:106-108`; `Graphics.cs:163-177` | Rendered pixel test in `tests/test_graphics_snapshot.gd:39-56`. |
| `frame_reset` | implemented | RT (original) | `Graphics.cs:FrameReset`; `tests/test_rgss_api.gd` | Preserves script-visible frame_count (original 123 remains 123); prior erroneous clear reproduced, then removed. Eleven original timing rows are pinned in rgss300-graphics-frame-reference.tsv. |
| `width` | implemented | RT | `Graphics.cs:155-157` |  |
| `height` | implemented | RT | `Graphics.cs:159-161` |  |
| `resize_screen` | partial | ST | `RGSS/graphics.rb:101-104`; `Graphics.cs:148-153` | Calls `DisplayServer.WindowSetSize` only; render target/viewport size is unchanged and the documented 640x480 cap is not enforced. |
| `play_movie` | missing | ST | `RGSS/graphics.rb:71-74`; `Graphics.cs:179-182` | Binding returns nil; no playback path. |
| `frame_rate` | partial | RT | `RGSS/graphics.rb:25-32`; `Graphics.cs:39-48` | Round-trips, but only clamps to >=1; documented 10..120 auto-correction is absent. |
| `frame_count` | implemented | RT | `RGSS/graphics.rb:34-41`; `Graphics.cs:50-59` |  |
| `brightness` | implemented | RT | `RGSS/graphics.rb:43-50`; `Graphics.cs:68-77` | 0..255 round-trip asserted. |

### Audio
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `setup_midi` | missing | ST | `RGSS/audio.rb:48-51`; `Scripts/RubyClasses/Audio.cs:17-22` | Raises NotImplementedError. |
| `bgm_play` | implemented | ST | `RGSS/audio.rb:12-15`; `Audio.cs:24-39` | RTP/extension fallback via `patch_rmva.rb:65-81`. |
| `bgm_stop` | implemented | ST | `RGSS/audio.rb:48-51`; `Audio.cs:41-46` |  |
| `bgm_fade` | implemented | ST | `RGSS/audio.rb:17-20`; `Audio.cs:52-57` | Millisecond tween in `GameAudioManager.cs:80-90`. |
| `bgm_pos` | implemented | ST | `RGSS/audio.rb:48-51`; `Audio.cs:48-50` |  |
| `bgs_play` | implemented | ST | `RGSS/audio.rb:22-25`; `Audio.cs:59-74` |  |
| `bgs_stop` | implemented | ST | `Audio.cs:76-81` |  |
| `bgs_fade` | implemented | ST | `Audio.cs:87-92` |  |
| `bgs_pos` | implemented | ST | `Audio.cs:83-85` |  |
| `me_play` | partial | ST | `RGSS/audio.rb:32-35`; `Audio.cs:94-108`; `GameAudioManager.cs:55-70,174-178` | BGM file/volume/pitch are remembered for resume, but the BGM player is not paused when ME starts, so ME plays over BGM. |
| `me_stop` | implemented | ST | `Audio.cs:110-115` |  |
| `me_fade` | implemented | ST | `Audio.cs:117-122` |  |
| `se_play` | partial | ST | `RGSS/audio.rb:42-45`; `Audio.cs:124-138`; `GameAudioManager.cs:160-170` | Round-robins 8 players; documented same-SE throttling is not implemented. |
| `se_stop` | implemented | ST | `Audio.cs:140-145` | Stops all pool players. |

### Input
| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `update` | implemented | ST | `RGSS/input.rb:48`; `Scripts/RubyClasses/Input.cs:68-72` |  |
| `press?` | implemented | ST | `RGSS/input.rb:35-38`; `Input.cs:28-30` |  |
| `trigger?` | implemented | ST | `RGSS/input.rb:40-43`; `Input.cs:24-26` |  |
| `repeat?` | implemented | ST | `RGSS/input.rb:45-48`; `Input.cs:32-34` | 23-frame delay, 6-frame interval (`InputStateRecorder.cs:8-10`). |
| `dir4` | implemented | ST | `RGSS/input.rb:48`; `Input.cs:36-48` |  |
| `dir8` | implemented | ST | `RGSS/input.rb:48`; `Input.cs:50-66` |  |
| `DOWN LEFT RIGHT UP` | partial | ST | `RGSS/input.rb:4-7` | Defined on Kernel, so `Input::DOWN` raises NameError; bare `DOWN` works. |
| `A B C X Y Z L R` | partial | ST | `RGSS/input.rb:9-16` | Same namespace divergence. |
| `SHIFT CTRL ALT` | partial | ST | `RGSS/input.rb:18-20` | Same namespace divergence. |
| `F5 F6 F7 F8 F9` | partial | ST | `RGSS/input.rb:22-26` | Same namespace divergence. |


## Built-in functions

Documented on `docs/rgss-reference/rgss/g_functions.md`. All are defined on `Kernel` in `RGSS/kernel.rb`.

| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `rgss_main { ... }` | partial | ST | `RGSS/kernel.rb:3-5`; `RGSS/main.rb:85` | Stores and invokes the block, but does not capture F12 reset/restart (`g_functions.md:13`). |
| `rgss_stop` | implemented | ST | `RGSS/kernel.rb:7-13` | `loop { Graphics.update }` matches the documented equivalent. |
| `load_data(filename)` | partial | ST | `RGSS/kernel.rb:15-19` | RMProject-relative only; no encrypted-archive lookup (`g_functions.md:59`). |
| `save_data(obj, filename)` | implemented | ST | `RGSS/kernel.rb:21-26` | Marshal dump to RMProject path. |
| `msgbox(arg, ...)` | partial | ST | `RGSS/kernel.rb:28-30`; `Scripts/UnityModule.cs:81-91` | Writes to the console log, not a message box. |
| `msgbox_p(obj, ...)` | partial | ST | `RGSS/kernel.rb:32-34` | Delegates to msgbox without `inspect`/newlines (`g_functions.md:97-101`). |

## Exceptions

| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `RGSSError` (class) | partial | ST | `RGSS/rgss_error.rb:2`; `Scripts/RubyClasses/Bitmap.cs:541-548` | Class exists and is raised for image-load failures, but disposed-object access throws `ObjectDisposedException`, not RGSSError (`gc_rgsserror.md:5`). |
| `RGSSReset` (class) | missing | ST | `RGSS/rgss_reset.rb:2` | Class exists but nothing raises it; no F12 handler in `Scripts/` or `RGSS/` (`gc_rgssreset.md:5`). |

## RPG data classes

All 45 documented `RPG::*` classes were extracted from the official `定義` code blocks, normalized
(BOM/CRLF/blank lines/`require` lines removed), and diffed against `RGSS/rpg/*.rb`. Result: **45/45 identical**.
Every listed attribute and method therefore matches the official definition text; the status column reflects that
definition-level match, and runtime evidence is marked per class where a test exists.

| Member | Status | Evidence class | Implementation | Notes |
|---|---|---|---|---|
| `nickname, class_id, initial_level, max_level, character_name, character_index, face_name, face_index, equips` | implemented | ST | `RGSS/rpg/actor.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `id, name, animation1_name, animation1_hue, animation2_name, animation2_hue, position, frame_max, frames, timings, to_screen?` | implemented | ST | `RGSS/rpg/animation.rb:1` | `to_screen?` returns `position == 3`; matches official. |
| `cell_max, cell_data` | implemented | ST | `RGSS/rpg/animation.frame.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `frame, se, flash_scope, flash_color, flash_duration` | implemented | ST | `RGSS/rpg/animation.timing.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `atype_id, performance` | implemented | ST | `RGSS/rpg/armor.rb:3` | `performance` formula matches official. |
| `name, volume, pitch` | implemented | ST | `RGSS/rpg/audio_file.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `id, name, icon_index, description, features, note` | implemented | ST | `RGSS/rpg/base_item.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `code, data_id, value` | implemented | ST | `RGSS/rpg/base_item.feature.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `RPG::BGM.last, RPG::BGM.stop, RPG::BGM.fade, play, replay` | implemented | ST | `RGSS/rpg/bgm.rb:3` | Delegates to Audio; `last` reads `Audio.bgm_pos`. ST. |
| `RPG::BGS.last, RPG::BGS.stop, RPG::BGS.fade, play, replay` | implemented | ST | `RGSS/rpg/bgs.rb:3` | Delegates to Audio; ST. |
| `exp_params, params, learnings, exp_for_level` | implemented | ST | `RGSS/rpg/class.rb:3` | `exp_for_level` formula matches official byte-for-byte. |
| `level, skill_id, note` | implemented | ST | `RGSS/rpg/class.learning.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `id, name, trigger, switch_id, list, autorun?, parallel?` | implemented | ST | `RGSS/rpg/common_event.rb:1` | `autorun?`/`parallel?` match official trigger codes. |
| `battler_name, battler_hue, params, exp, gold, drop_items, actions` | implemented | ST | `RGSS/rpg/enemy.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `skill_id, condition_type, condition_param1, condition_param2, rating` | implemented | ST | `RGSS/rpg/enemy.action.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `kind, data_id, denominator` | implemented | ST | `RGSS/rpg/enemy.drop_item.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `price, etype_id, params` | implemented | ST | `RGSS/rpg/equip_item.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `id, name, x, y, pages` | implemented | ST | `RGSS/rpg/event.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `condition, graphic, move_type, move_speed, move_frequency, move_route, walk_anime, step_anime, direction_fix, through, priority_type, trigger, list` | implemented | ST | `RGSS/rpg/event.page.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `switch1_valid, switch2_valid, variable_valid, self_switch_valid, item_valid, actor_valid, switch1_id, switch2_id, variable_id, variable_value, self_switch_ch, item_id, actor_id` | implemented | ST | `RGSS/rpg/event.page.condition.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `tile_id, character_name, character_index, direction, pattern` | implemented | ST | `RGSS/rpg/event.page.graphics.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `code, indent, parameters` | implemented | ST | `RGSS/rpg/event_command.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `itype_id, price, consumable, key_item?` | implemented | ST | `RGSS/rpg/item.rb:3` | `key_item?` matches official (`itype_id == 2`). |
| `display_name, tileset_id, width, height, scroll_type, specify_battleback, battleback1_name, battleback2_name, autoplay_bgm, bgm, autoplay_bgs, bgs, disable_dashing, encounter_list, encounter_step, parallax_name, parallax_loop_x, parallax_loop_y, parallax_sx, parallax_sy, parallax_show, note, data, events` | implemented | ST | `RGSS/rpg/map.rb:1` | Matches official exactly, including the official initializer/accessor naming quirk (`battleback_floor_name` set, `battleback1_name` exposed). |
| `troop_id, weight, region_set` | implemented | ST | `RGSS/rpg/map.encounter.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `name, parent_id, order, expanded, scroll_x, scroll_y` | implemented | ST | `RGSS/rpg/map_info.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `RPG::ME.stop, RPG::ME.fade, play` | implemented | ST | `RGSS/rpg/me.rb:3` | Delegates to Audio; ST. |
| `code, parameters` | implemented | ST | `RGSS/rpg/move_command.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `repeat, skippable, wait, list` | implemented | ST | `RGSS/rpg/move_route.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `RPG::SE.stop, play` | implemented | ST | `RGSS/rpg/se.rb:3` | Delegates to Audio; ST. |
| `stype_id, mp_cost, tp_cost, message1, message2, required_wtype_id1, required_wtype_id2` | implemented | ST | `RGSS/rpg/skill.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `restriction, priority, remove_at_battle_end, remove_by_restriction, auto_removal_timing, min_turns, max_turns, remove_by_damage, chance_by_damage, remove_by_walking, steps_to_remove, message1, message2, message3, message4` | implemented | ST | `RGSS/rpg/state.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `game_title, version_id, japanese, party_members, currency_unit, window_tone, elements, skill_types, weapon_types, armor_types, switches, variables, boat, ship, airship, title1_name, title2_name, opt_draw_title, opt_use_midi, opt_transparent, opt_followers, opt_slip_death, opt_floor_death, opt_display_tp, opt_extra_exp, title_bgm, battle_bgm, battle_end_me, gameover_me, sounds, start_map_id, start_x, start_y, terms, test_battlers, test_troop_id, battleback1_name, battleback2_name, battler_name, battler_hue, edit_map_id` | implemented | ST | `RGSS/rpg/system.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `basic, params, etypes, commands` | implemented | ST | `RGSS/rpg/system.terms.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `actor_id, level, equips` | implemented | ST | `RGSS/rpg/test_battle.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `character_name, character_index, bgm, start_map_id, start_x, start_y` | implemented | ST | `RGSS/rpg/system.vehicle.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `id, name, mode, tileset_names[*index*], flags, note` | implemented | ST | `RGSS/rpg/tileset.rb:1` | Default flags table matches official. |
| `id, name, members, pages` | implemented | ST | `RGSS/rpg/troop.rb:1` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `enemy_id, x, y, hidden` | implemented | ST | `RGSS/rpg/troop.member.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `condition, span, list` | implemented | ST | `RGSS/rpg/troop.page.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `turn_ending, turn_valid, enemy_valid, actor_valid, switch_valid, turn_a, turn_b, enemy_index, enemy_hp, actor_id, actor_hp, switch_id` | implemented | ST | `RGSS/rpg/troop.page.condition.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `scope, occasion, speed, success_rate, repeats, tp_gain, hit_type, animation_id, damage, effects, for_opponent?, for_friend?, for_dead_friend?, for_user?, for_one?, for_random?, number_of_targets, for_all?, need_selection?, battle_ok?, menu_ok?, certain?, physical?, magical?` | implemented | ST | `RGSS/rpg/usable_item.rb:3` | All 14 predicate bodies match official. |
| `type, element_id, formula, variance, critical, none?, to_hp?, to_mp?, recover?, drain?, sign, eval` | implemented | RT (eval) / ST | `RGSS/rpg/usable_item.damage.rb:3` | `eval` asserted by `tests/test_eval_damage_fix.gd` (5/5); other predicates ST. |
| `code, data_id, value1, value2` | implemented | ST | `RGSS/rpg/usable_item.effect.rb:3` | Definition matches the official `定義` block (normalized diff 0/45 classes). |
| `wtype_id, animation_id, performance` | implemented | ST | `RGSS/rpg/weapon.rb:3` | `performance` formula matches official. |

## Confirmed gaps (highest-impact first)

1. **Viewport `tone` / `color` / `flash` are stored but never rendered.** `ViewportData` carries `Tone`, `FlashColor`,
   `FlashDuration`, `FlashRemain` (`Scripts/RubyClasses/ViewportData.cs:21-24`), and the per-frame viewport loop
   (`Scripts/GameRenderManager.cs:209-243`) only applies geometry, visibility, and z-order. `Shaders/ViewportShader.gdshader`
   exists but is referenced nowhere in `Scripts/` (grep: 0 hits). Screen shake via `ox`/`oy` does work.
2. **Sprite `blend_type` has no rendering effect.** The setter clamps and stores (`Scripts/RubyClasses/Sprite.cs:363-372`),
   but sprites always use the fixed `blend_mix` `SpriteShader` (`Shaders/SpriteShader.gdshader:2`) and `RenderSprite`
   selects no variant (`Scripts/GameRenderManager.cs:590-627`). Only Plane implements 0/1/2 variants
   (`Scripts/GameRenderManager.cs:1230-1250`).
3. **Sprite `mirror` is applied twice and cancels.** `node.FlipH = data.Mirror` (`Scripts/GameRenderManager.cs:605`)
   plus the shader UV flip `uv.x = mix(uv.x, 1.0 - uv.x, step(0.5, _PackedD.y))` (`Shaders/SpriteShader.gdshader:35`)
   with `_PackedD.y` set from `data.Mirror` (`Scripts/GameRenderManager.cs:620`).
4. **`Graphics.play_movie` is a no-op.** Binding returns nil (`Scripts/Graphics.cs:179-182`); the Ruby wrapper
   (`RGSS/graphics.rb:71-74`) forwards to it.
5. **`Audio.setup_midi` raises NotImplementedError.** `Scripts/RubyClasses/Audio.cs:17-22`.
6. **`Audio.me_play` does not pause BGM.** `GameAudioManager.Play` records the BGM resume state
   (`Scripts/GameAudioManager.cs:55-66`) and `OnMeFinished` replays it (`Scripts/GameAudioManager.cs:174-178`),
   but the BGM player is never stopped/paused when ME starts, so ME overlaps BGM instead of the documented pause
   (`docs/rgss-reference/rgss/gm_audio.md:84`).
7. **`Audio.se_play` has no same-SE throttling.** It round-robins an 8-player pool
   (`Scripts/GameAudioManager.cs:160-170`); documented de-duplication (`gm_audio.md:106`) is absent.
8. **`Graphics.freeze` does not freeze.** `Graphics.Freezing` is set (`Scripts/Graphics.cs:99-105`) and cleared
   (`Scripts/Graphics.cs:20-26,107-110`) but never read anywhere else (grep: only those three sites).
9. **`Graphics.resize_screen` only resizes the OS window.** `Scripts/Graphics.cs:148-153` calls
   `DisplayServer.WindowSetSize`; the render target and `Graphics.width`/`height` derive from the root viewport
   (`Scripts/Graphics.cs:184-194`), and the documented 640x480 cap (`gm_graphics.md:111`) is not enforced.
10. **`Graphics.frame_rate` does not clamp to 10..120.** `Scripts/Graphics.cs:43-48` clamps only to >= 1
    (documented range: `gm_graphics.md:131`).
11. **`Bitmap.draw_text` ignores Font `name`, `bold`, `italic`, and `shadow`.** `DrawTextToImage` receives only
    size, color, align, outline, and outline color (`Scripts/RubyClasses/Bitmap.cs:322-331,342-360`). The documented
    60% width shrink (`gc_bitmap.md:162`) is also absent.
12. **`Bitmap.text_size` is an estimate, not a measurement.** Returns `len * size` by `size`
    (`Scripts/RubyClasses/Bitmap.cs:497-505`); it does not exclude outline/italic as documented
    (`gc_bitmap.md:172`).
13. **`Font.name` returns an Array, not a String.** Getter builds an array from `FontData.Names`
    (`Scripts/RubyClasses/Font.cs:62-67`); `RGSS/font.rb:123-125` returns `@name`, which the setter always normalizes
    to an Array (`RGSS/font.rb:127-137`). The API test pins this Array behavior (`tests/test_rgss_api.gd:283-287`).
14. **`Font.default_name` is `["Arial"]`, not "VL Gothic".** `RGSS/font.rb:45` vs `gc_font.md:38`.
15. **`Font.exist?` always returns true.** `RGSS/font.rb:173-176` (deliberate permissive stub).
16. **`Window#windowskin` raises when unset.** Getter calls `Bitmap.new @__handler__.windowskin`
    (`RGSS/window.rb:23-25`); the stored value is nil (`Scripts/RubyClasses/Window.cs:107-118`), and
    `Bitmap#initialize` raises TypeError for nil (`RGSS/bitmap.rb:9-19`).
17. **`Tilemap#viewport` is always nil.** `initialize` never assigns `@viewport` (`RGSS/tilemap.rb:9-17`) while the
    getter returns it (`RGSS/tilemap.rb:57-59`).
18. **`Sprite#bush_opacity` default is 255, not 128.** `Scripts/RubyClasses/SpriteData.cs:30` vs `gc_sprite.md:177`.
19. **Sprite wave amplitude is used as a 0..1 blend factor.** `_PackedA.x` holds pixel amplitude
    (`Scripts/GameRenderManager.cs:617`) but the shader clamps it to 0..1 as a mix weight
    (`Shaders/SpriteShader.gdshader:38`), so any amplitude >= 1 renders identically.
20. **Sprite `wave_phase` is never uploaded.** Stored and advanced (`Scripts/RubyClasses/Sprite.cs:65-88,423-431`),
    but the shader derives phase from `TIME` (`Shaders/SpriteShader.gdshader:24`).
21. **Sprite bush depth mixes pixel and UV units.** `data.BushDepth / 255.0f` is compared against `uv.y`
    (`Scripts/GameRenderManager.cs:625`, `Shaders/SpriteShader.gdshader:51`).
22. **`Sprite#flash(nil, duration)` does not erase the sprite.** Null color sets `FlashColor = null`
    (`Scripts/RubyClasses/Sprite.cs:55-63`), which yields zero flash alpha
    (`Scripts/GameRenderManager.cs:1506-1511`); documented behavior is a full erase for the duration
    (`gc_sprite.md:44`).
23. **`Table#resize` has flat, not 2D/3D, semantics.** `Array.Resize` on the flat buffer
    (`Scripts/RubyClasses/Table.cs:55-85`); only the 1D overlap case is tested.
24. **`Input` constants live on `Kernel`, not `Input`.** `RGSS/input.rb:4-26` opens `module Kernel`; `Input::DOWN`
    therefore raises NameError while bare `DOWN` works. Stock RMVA uses bare symbols, so this is latent.
25. **`msgbox` / `msgbox_p` write to the log, not a message box.** `Scripts/UnityModule.cs:81-91`;
    `msgbox_p` does not `inspect` or add newlines (`RGSS/kernel.rb:32-34`, `g_functions.md:97-101`).
26. **`rgss_main` does not capture F12.** `RGSS/kernel.rb:3-5` only stores the block; `RGSS/main.rb:85` invokes it.
    No F12 handler exists in `Scripts/` or `RGSS/` (grep: 0 hits).
27. **`RGSSReset` is never raised.** Class defined at `RGSS/rgss_reset.rb:2`; no raiser anywhere.
28. **`RGSSError` is not raised for disposed-object access.** Disposed Bitmap access throws
    `ObjectDisposedException` (`Scripts/RubyClasses/Bitmap.cs:541-548`), whereas the reference says RGSSError
    (`gc_rgsserror.md:5`). Image-load failures do raise RGSSError (`Bitmap.cs:39,46`).
29. **Encrypted archive (`Game.rgss3a`) is unsupported.** `load_data`, `Bitmap.new`, and `Graphics.transition`
    resolve only through `RMProjectPath`/RTP (`RGSS/kernel.rb:15-19`, `Scripts/RubyClasses/Bitmap.cs:24-53`,
    `RGSS/graphics.rb:87-99`); grep for `rgss3a`/`archive` in `Scripts/` and `RGSS/` returns 0 hits
    (reference: `rgss.md:136-138`).
30. **`Sprite#z` ordering locally verified (C03).** Viewport roots enable y sorting;
    original same-z overlaps, creation ties, differing z and later y changes are
    captured by `sprite_sort_reference.rb`. Pivot/scale/mirror/source-rectangle
    semantics and rotation sampling now have original rendered evidence. The
    eight-transform and six-angle checkerboard captures match RGSS300 pixel-exactly;
    bitmap edits and changing angle/rectangle/position refresh the cached raster.

## Incomplete / unverified scope

The following are explicitly **not** established by this inventory and are left for the lead:

- **No original-engine comparison.** Every status is source inspection plus the repo's own tests. Pixel-level parity for
  `draw_text`, `hue_change`, `blur`, `radial_blur`, `Graphics.transition` masks, and window skin 9-patch layout is unproven.
- **No runtime exercise of Audio.** `Audio.*` rows are `ST` only; the boot log currently reports
  `AUDIO_LOAD_FAIL` for the sample project's BGM (`docs/development.md:60`), so playback paths are untested here.
- **No runtime exercise of Input.** `Input.*` rows are `ST` only; no test drives `InputStateRecorder`.
- **No runtime exercise of Graphics frame flow.** `update`/`wait`/`fadeout`/`fadein`/`freeze`/`transition` are excluded
  from the bare API suite by design (`tests/test_rgss_api.gd:739-741`) because they need the Fiber pump.
- **RPG data classes are definition-verified, not behavior-verified.** The 45/45 diff proves the class text matches the
  official `定義` block; it does not prove Marshal compatibility with real `.rvdata2` files beyond what the boot path exercises.
- **`docs/rgss-reference/rgss/sc_*.md` and `sm_*.md` (Ruby core/stdlib) are out of scope** for this inventory; only the
  RGSS game library (`g_*`) was requested.
- **`Graphics.play_movie`** is counted `missing`; if the lead wants a documented "not supported on this platform" verdict
  instead, that is a policy call, not a source finding.
