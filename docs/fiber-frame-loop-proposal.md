# Fiber Frame-Loop Compatibility Proposal

Status: Proposal (not yet implemented). Captures the analysis of the current
`patch_rmva.rb` Fiber pump and a recommended change to harden third-party RMVA
script compatibility. Extends `lifetime-conventions.md` rule 6
("one `Fiber.yield` equals one frame").

## 1. Current mechanism

RGSS3's native runtime drives the game from a blocking
`loop { Graphics.update }` on a dedicated game thread; each `Graphics.update`
call blocks until the next vsync, so it *is* the frame barrier. This port
replaces that with a cooperative Fiber pump driven by Godot's `_Process`.

Per real Godot frame:

```
GameManager._Process(delta)              [Scripts/GameManager.cs:40-49]
  ├─ GameRenderManager.Instance.Update() [Scripts/GameManager.cs:46]
  └─ UnityModule.Update()                [Scripts/GameManager.cs:47]
       ├─ if Graphics.WaitCount > 0:      [Scripts/UnityModule.cs:29-33]
       │     Graphics.Render()            -> --WaitCount, ++frameCount; fiber stays parked
       │     return
       └─ else:                           [Scripts/UnityModule.cs:35-46]
             State.FiberResume(UpdateFiber)  -> runs Ruby until the next Fiber.yield
```

The update Fiber is built and registered Ruby-side in `RGSS/patch_rmva.rb:8-18`
(`SceneManager.run`). The resume call is wrapped in `State.Protect` so a Ruby
exception surfaces as an `error` flag instead of crossing the C boundary as a
C# throw (`Scripts/UnityModule.cs:37-45`).

### Key fact: `Graphics.update` does NOT yield

`Unity::Graphics.update` is a pure synchronous counter bump that returns
immediately — it does not yield the Fiber:

```csharp
// Scripts/Graphics.cs:24-30
[RbModuleMethod("update")]
private static RbValue Update(RbState state, RbValue self)
{
    Freezing = false;
    Render();            // if (WaitCount > 0) --WaitCount; ++frameCount;
    return state.RbNil;  // returns to the Ruby caller, no Fiber.yield
}
```

The only two `Fiber.yield` call-sites in the entire codebase are inserted by
the patch at specific scene call-sites:

- `Scene_Base#__yield_update` — `RGSS/patch_rmva.rb:31-38`
- `Scene_Battle#update_for_wait` — `RGSS/patch_rmva.rb:58-61`

So the frame barrier is the explicit `Fiber.yield` in `__yield_update`, NOT
`Graphics.update`. The standard scene loop only works because
`Scene_Base#main` was rewritten to call `__yield_update` instead of `update`
(`RGSS/patch_rmva.rb:22-29`).

### `Graphics.wait` / `fadeout` / `fadein` / `transition`

These do not loop in Ruby. They set a C#-side `WaitCount` and return
immediately (`Scripts/Graphics.cs:32-37, 79-117`). While `WaitCount > 0`,
`UnityModule.Update()` skips the Fiber resume and only ticks the counter, so
the Fiber stays parked for that many Godot frames. Brightness ramps are advanced
independently every frame by `GameRenderManager.TickBrightnessFade()`
(`Scripts/GameRenderManager.cs:1283-1302`), which is explicitly designed to run
"including while the Ruby fiber is parked (WaitCount>0)"
(`Scripts/GameRenderManager.cs:1280-1282`). That part of the design is sound.

Crucially, the `WaitCount` mechanism is only correct when the caller is already
running inside a yieldable context (the normal `Scene_Base#main` loop). If a
caller never yields, `_Process` never re-enters, so `WaitCount` never drains.

## 2. The risk

The semantic of `Graphics.update` has silently changed from "wait for the next
frame" to "record that a frame logically passed." Third-party RMVA scripts
(custom title/intro/transition screens, loading bars, and battle systems such
as Yanfly/Victor) very commonly drive their own loops with `Graphics.update` as
the frame barrier:

```ruby
loop do
  do_something
  Graphics.update   # native RGSS3: blocks one frame
                    # this port: returns immediately, no yield
end
```

Under this port that loop runs entirely inside one `FiberResume` slice and
**never returns to `_Process`**, freezing the engine completely: brightness
fades stop ticking, input stops updating, the window goes unresponsive.

Variants of the same root cause:

1. Tight animation sub-loops (e.g. `100.times { sprite.x += 1; Graphics.update }`)
   complete in a single visible frame instead of animating over 100 frames.
2. `Graphics.wait(n)` / `fadeout(n)` called from a bare third-party loop sets
   `WaitCount` and returns, but since the Fiber never yields, `_Process` never
   runs and the wait never elapses — hang.
3. The existing `Scene_Battle#update_for_wait` patch (`RGSS/patch_rmva.rb:58-61`)
   exists precisely because that battle sub-loop needed a manually inserted
   `Fiber.yield`. This is "whack-a-mole": every loop that calls `Graphics.update`
   needs its own patch, and third-party loops cannot be patched ahead of time.
4. The `$rgss_stop_flag` branch in `__yield_update` (`RGSS/patch_rmva.rb:32-36`)
   plus `Kernel#rgss_stop` (`RGSS/kernel.rb:7-9`) is another symptom: native
   `rgss_stop` is literally `loop { Graphics.update }`, which only needs special
   handling here because `Graphics.update` does not yield.

This is not a re-entrancy problem. Godot `_Process` and mruby are both
single-threaded, so concurrent resume cannot happen and no guard is needed. The
risk is purely the frame-barrier semantic mismatch.

## 3. Proposed solution

Make `Graphics.update` itself the single frame barrier (exactly as native
RGSS3), instead of bolting `Fiber.yield` onto individual scene methods. Move the
yield into the `Graphics.update` wrapper, Ruby-side:

```ruby
# RGSS/graphics.rb (or patch_rmva.rb) — pure Ruby layer
module Graphics
  class << self
    alias :__native_update :update
    def update
      __native_update   # Unity::Graphics.update (C# side, already returned)
      Fiber.yield       # the frame barrier — every caller now behaves correctly
    end
  end
end
```

Companion changes:

- Revert `Scene_Base#main` to the stock `update until scene_changing?`; delete
  `__yield_update` and its `$rgss_stop_flag` branch.
- Delete the `Scene_Title#close_command_window`, `Scene_End#close_command_window`,
  and `Scene_Battle#update_for_wait` yield patches (`RGSS/patch_rmva.rb:41-75`).
- Reimplement `Graphics.wait/fadeout/fadein/transition` Ruby-side in stock form
  (e.g. `wait` as `n.times { update }`), while the C# side keeps only the
  brightness-fade animation state. The `WaitCount` early-return hack in
  `UnityModule.Update()` and `Graphics.cs` can then be removed.
- `rgss_stop` reverts to native `loop { Graphics.update }`; `$rgss_stop_flag`
  is deleted.

### Why this is correct

- Zero per-script patching: `loop { ...; Graphics.update }`, custom Scenes, and
  `Graphics.wait` from any call-site all behave correctly and automatically.
- Frame advancement has exactly one source, matching the native RGSS3 mental
  model and `lifetime-conventions.md` rule 6.
- Feasibility is already proven by the current code: `__yield_update` today does
  "run the Ruby call stack (whose C# binding has already returned) then
  `Fiber.yield`". The proposal moves that same `Fiber.yield` into the
  `Graphics.update` wrapper. The yield happens on a pure-Ruby stack while
  `Unity::Graphics.update` has already returned across the boundary, so there is
  no cross-C-frame yield concern.

## 4. Migration plan (phased, each phase independently verifiable)

Phase 1 — low risk, additive:
- Add the `Graphics.update` yield wrapper.
- Remove the duplicate `Fiber.yield` from `__yield_update` (see caveat 2 below —
  double-yield must be avoided).
- Keep `WaitCount` as a temporary compatibility shim.
- Run the full boot + scene regression and confirm no double-speed / no hang.

Phase 2 — cleanup:
- Reimplement `wait/fadeout/fadein/transition` as native Ruby loops over
  `Graphics.update`, keeping the C# brightness-fade state.
- Remove the `WaitCount` early-return in `UnityModule.Update()` and `Graphics.cs`.
- Remove the `Scene_*` yield patches and `$rgss_stop_flag` / restore native
  `rgss_stop`.

## 5. Migration caveats (must verify on real hardware)

1. Phase shift: the yield point moves from "after the whole `update`" to "inside
   `update_basic` at the `Graphics.update` call". This changes the ordering of
   `Input.update` / `update_all_windows` relative to the yield. It is closer to
   native RGSS3 (barrier at `Graphics.update`) but requires regression testing of
   input feel and window animations.
2. No double-yield: the explicit `Fiber.yield` in `__yield_update` MUST be
   removed at the same time the wrapper is added, otherwise each frame yields
   twice and the game runs at half speed.
3. `wait/fadeout` rewrite must still drive the C# brightness-fade state
   (`StartBrightnessFade` + one `update` per frame).
4. F12 reset / `RGSSReset` path (`RGSS/rgss_reset.rb`, `RGSS/rgss_error.rb`) and
   its interaction with the new loop must be re-verified.
5. Recommend an Oracle review of the phase shift's impact on the battle and event
   interpreter loops before implementing.

## 6. Rejected alternative: dedicated OS thread

A faithful "real game thread + `Graphics.update` blocks on a semaphore signalled
by `_Process`" model is the closest to native RGSS3 but is not viable here:

- mruby is not thread-safe.
- Every `Unity::*` binding manipulates Godot nodes, which must be touched on the
  main thread.

Cross-thread resume would crash. The cooperative Fiber model is the correct
choice for this architecture; the only defect is the *location* of the yield
point, which this proposal fixes.

## 7. Reference map

| Concern | Location |
| --- | --- |
| Per-frame driver | `Scripts/GameManager.cs:40-49` |
| Fiber pump + `WaitCount` bypass + resume | `Scripts/UnityModule.cs:27-47` |
| Fiber registration / GC pin | `Scripts/UnityModule.cs:49-73` |
| `Graphics.update` (no yield) | `Scripts/Graphics.cs:24-30` |
| `wait/fadeout/fadein/transition` (set `WaitCount`) | `Scripts/Graphics.cs:32-37, 79-117` |
| Brightness fade ticks while parked | `Scripts/GameRenderManager.cs:1280-1302` |
| Fiber construction + registration | `RGSS/patch_rmva.rb:8-18` |
| `Scene_Base#main` / `__yield_update` | `RGSS/patch_rmva.rb:22-39` |
| `Scene_Battle#update_for_wait` yield patch | `RGSS/patch_rmva.rb:58-61` |
| `rgss_stop` / `$rgss_stop_flag` | `RGSS/kernel.rb:7-9`, `RGSS/main.rb:9` |
| Frame-identity convention | `docs/lifetime-conventions.md` rule 6 |
