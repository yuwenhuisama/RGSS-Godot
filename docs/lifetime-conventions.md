# Lifetime Conventions

These rules apply to every binding task in this codebase.

1. Node disposal happens only in the mruby RData release callback.
   - The callback runs on the main thread via mruby GC.
   - Never dispose nodes from C# finalizers.
   - Never call `QueueFree()` from an off-thread path.

2. `GC.KeepAlive(func)` is mandatory after every `State.Protect(..., out var func)` call.
   - Omitting it can trigger a CFI crash.

3. Every native method registered with `DefineModuleMethod` or `DefineMethod` must be pinned.
   - Use `RbNativeObjectLiveKeeper.GetOrCreateKeeper(state).Keep(func)`.
   - This prevents the delegate from being collected while mruby may still call it.

4. Release pinned delegates during teardown.
   - Call `RbNativeObjectLiveKeeper.ReleaseKeeper(state)` in both `_ExitTree` and `WM_CLOSE_REQUEST`.

5. Use `RGSSLogger.Log` / `RGSSLogger.LogError` inside Ruby `rescue` paths.
   - Do not call `GD.Print` / `GD.PrintErr` directly there.
   - The queue is defense-in-depth and keeps the path portable and safe.

6. Treat frame identity as one `Fiber.yield` equals one frame.
   - Do not use `Time.delta` for game-logic timing.
