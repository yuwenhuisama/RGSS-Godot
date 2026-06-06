# Assets/Resources/RGSS — RUBY-SIDE RGSS3 + RMVA DATA MODEL

Layer 1 (pure-Ruby wrappers) + bootstrap + RMVA data classes. Loaded as Unity `TextAsset`s via `Resources.Load("RGSS/<name>")` — NOT a filesystem `require`. Parent AGENTS.md covers the 3-layer architecture.

## BOOT FILES (load order matters)
| File | Role |
|------|------|
| `main.rb` | Entry. Sets `$rmva_project_base_path`/`$rtp_path`, `require`s built-ins, Marshal-loads `Scripts.rvdata2`, runs RMVA scripts, then `require 'patch_rmva'` + invokes `$rgss_main_callback` |
| `kernel.rb` | `rgss_main`, `load_data`/`save_data` (Marshal vs RMProject paths), `msgbox` → `Unity.msgbox` |
| `patch_rmva.rb` | **The compatibility core.** Monkey-patches `SceneManager.run` → Fiber loop; `Scene_Base#main` → `__yield_update` (Fiber.yield per frame); reroutes `Audio`/`Cache`/`DataManager` file paths to RMProject + RTP fallback |
| `rgss_error.rb`, `rgss_reset.rb` | RGSSError class; F12 reset handling |

## WRAPPER PATTERN (every built-in `*.rb` follows this)
```ruby
require 'type_check_util'
class Sprite
  include TypeCheckUtil
  attr_reader :__handler__
  def initialize(viewport = nil)
    @__handler__ = Unity::Sprite.new_with_viewport(viewport&.__handler__ || Viewport::DEFAULT_VIEWPORT.__handler__)
  end
  def bitmap=(bitmap)
    check_arguments([bitmap], [[Bitmap, NilClass]])   # type-guard BEFORE crossing to C#
    @__handler__.bitmap = bitmap&.__handler__
  end
  # bulk-define trivial accessors via metaprogramming:
  [:x, :y, :z, :ox, :oy].each do |p|
    define_method(p) { @__handler__.send(p) }
    define_method("#{p}=") { |v| @__handler__.send("#{p}=", v) }
  end
end
```
- `@__handler__` holds the `Unity::*` native object. Always pass `other.__handler__` across the boundary, never the wrapper.
- `type_check_util.rb` (`check_type`/`check_arguments`) guards args Ruby-side so C# bindings can assume valid types. RMVA passes a single accessor's value; arrays mean "any of these classes".

## SUBDIRECTORIES (loaded by `UnityModule.RunRmvaScripts` via `LoadAllScriptInResources`)
- `ext/` — Ruby shims for native gems: `dir_glob.rb`, `dir.rb`, `onig_regexp.rb` (loaded before rpg/).
- `rpg/` — ~40 `RPG::*` data classes (Actor/Map/Event/Troop/Skill/…), Marshal-compatible with RMVA's `.rvdata2`. Formulaic: `initialize` defaults + `attr_accessor`s + dotted filenames map nesting (`event.page.condition.rb` → `RPG::Event::Page::Condition`). Add new ones by copying a sibling.

## RULES
- New built-in `Foo`: create `foo.rb` here AND `RubyClasses/Foo.cs`, then add `require 'foo'` to `main.rb`'s begin block.
- `require 'x'` resolves to `Resources/RGSS/x.rb` through `Kernel.cs` (dedup set), NOT a real load path. Keep names lowercase matching the TextAsset.
- Inside a `rescue`, route to `Unity.on_top_exception` / `format_exc_string` — never raw `p`/`Debug.Log` (native stacktrace crash).
- Patches use `alias :old_x :x` then redefine — preserve this when extending `patch_rmva.rb`.
