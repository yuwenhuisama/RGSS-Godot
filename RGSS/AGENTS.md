# RUBY RGSS3 WRAPPERS AND RMVA DATA

## OVERVIEW
Ruby bootstrap, compatibility patches and Marshal data classes; score 9, an existing distinct domain retained and corrected.

## WHERE TO LOOK
| Task | Location | Contract |
|------|----------|----------|
| Entry and built-in load order | `main.rb` | Registers scripts, constructs the main fiber and invokes the callback |
| Callback and data IO | `kernel.rb` | `rgss_main`, reset retry, Marshal load/save |
| Frame barrier and waits | `graphics.rb` | Native update, reset check, then one `Fiber.yield` |
| Stock-script compatibility | `patch_rmva.rb` | SceneManager, path rerouting, MRI comparator semantics |
| Disposed resource guards | `resource_lifecycle.rb` | Wraps methods of six resource classes |
| Argument checks | `type_check_util.rb` | Ruby TypeError/ArgumentError before the native boundary |
| Native gem shims | `ext/` | Directory glob and Onigmo-backed String methods |
| Serialized RPG objects | `rpg/` | Defaults/accessors and dotted filenames for nested constants |

## CONVENTIONS
- `main.rb` republishes the existing `Kernel.eval` as a module function before loading any game code.
- Preserve that method entry: damage formulas need the caller's `a`, `b`, and `v` locals.
- `run_scripts` Marshal-loads `RMProject/Data/Scripts.rvdata2` and registers compressed RMVA scripts.
- Native `run_rmva_scripts` loads `ext/`, then `rpg/`, then returns game-script procs.
- `patch_rmva` loads after game scripts only when DataManager, Cache and SceneManager exist.
- Require names map to plain files under root `RGSS/`, or the executable's `RGSS/` directory, through the custom dedup loader.
- Wrappers store a native `Unity::*` object in `@__handler__`; pass other objects' handlers across the binding boundary.
- Lowercase wrapper filenames match require names; a new binding also needs its C# counterpart and bootstrap require.
- `TypeCheckUtil` arrays express accepted type alternatives; accessor loops use `define_method` for repetitive properties.
- `ResourceLifecycle.guard` applies to Bitmap, Plane, Sprite, Tilemap, Viewport and Window.
- Its exemptions include initialize, dispose, disposed?, handler access, hash and eql?; disposed property access raises `RGSSError`.
- `rpg/` classes preserve Marshal-compatible defaults; `event.page.condition.rb` maps to `RPG::Event::Page::Condition`.
- Callback reset retries preserve the default viewport; scene termination owns resource disposal.

## ANTI-PATTERNS
- Do not restore per-callsite yields in Scene_Base, title/end windows, fades or battle waits: `Graphics.update` now supplies the barrier.
- `tests/test_frame_loop.gd` checks direct update/wait cadence; `tests/test_reset_callback.gd` checks callback retry.
- Keep alias-then-redefine behavior in compatibility patches and String shims; callers rely on the preserved native methods.
- `Array#sort`/`sort!` normalize comparator results by sign; float differences in stock battle ordering must remain valid.
- Cache probes project/RTP bitmap existence before invoking the C# constructor: native callback exceptions cannot drive Ruby fallback.
- In rescue paths use `Unity.on_top_exception(format_exc_string(e))` to retain the Ruby backtrace in queued logging.
- Do not remove the live `Unity::` API name because of the Godot migration; it is the registered mruby module.
