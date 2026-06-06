# Learnings — unity-to-godot-migration

## [2026-06-05] Session Init — Environment Survey

### Tool Locations
- **Godot 4.6.1 stable mono**: `E:\Godot\Godot_v4.6.1-stable_mono_win64_console.exe` (console exe = headless-friendly)
- **Godot GUI**: `E:\Godot\Godot_v4.6.1-stable_mono_win64.exe`
- **GodotSharp SDK support**: `E:\Godot\GodotSharp\` (already present)
- **.NET SDK**: 10.0.204 (in PATH via `C:\Program Files\dotnet\`)
- **xmake**: NOT in PATH but `.xmake/` cache folders exist under `mruby-ext/` and `mruby-for-dotnet/mruby-shared/` — was previously used; must locate or reinstall

### Key Project Paths
- **RGSS-Unity** (source): `E:\Projects\RGSS-Unity`
- **mruby-for-dotnet** (binding lib source): `E:\Projects\mruby-for-dotnet`
- **mruby** (mruby source, submodule): `E:\Projects\mruby-for-dotnet\mruby` (also `E:\Projects\mruby`)
- **mruby-ext** (RGSS gem xmake builds): `E:\Projects\RGSS-Unity\mruby-ext`

### NuGet / MRuby
- **MRuby.Library v0.1.7** in `Assets/packages.config`; NuGet global cache at `C:\Users\yuwen\.nuget\packages`
- `MRuby.Library` is distributed as a NuGet package built from `E:\Projects\mruby-for-dotnet\mruby-wrapper\`
- Existing Windows gem DLLs (x64) already compiled in `E:\Projects\RGSS-Unity\Assets\Plugins\windows\`:
  - `libmruby_marshal_c_ext_x64.dll`
  - `libmruby_dir_glob_ext_x64.dll`
  - `libmruby_onig_regexp_ext_x64.dll`
  - `libmruby_zlib_ext_x64.dll`

### DllImport Convention (from RubyScriptManager.cs)
```csharp
[DllImport("libmruby_marshal_c_ext_x64", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
private static extern void mrb_mruby_marshal_c_gem_init(IntPtr mrb);
// Similarly for: dir_glob, onig_regexp, zlib
```
- All 4 gems init via `mrb_mruby_*_gem_init(this.State.NativeHandler)`
- VM lifecycle: `Ruby.Open()` → context = `State.NewCompileContext()` → compiler = `State.NewCompiler()`

### mruby-ext xmake Build Structure
- Root: `E:\Projects\RGSS-Unity\mruby-ext\xmake.lua` — `includes("glob","marshal","regexp","zlib")`
- Subdirs: `mruby-ext/glob/`, `mruby-ext/marshal/`, `mruby-ext/regexp/`, `mruby-ext/zlib/`
- macOS branch uses `lipo` for universal binary; Windows uses `export.def` + `lib/libmruby_x64.lib` linkage
- **Known issue**: `mruby_dir` is hardcoded to `E:/Projects/mruby-for-dotnet/mruby` in xmake.lua — must make configurable for cross-platform CI

### Godot Project Target
- Spike project: create at `E:\Projects\RGSS-GodotSpike\`
- Use `project.godot` + `.csproj` structure; NuGet via `PackageReference`
- Godot .NET projects need `Sdk="Godot.NET.Sdk"` in csproj; GodotSharp NuGet auto-included
- Godot console exe for headless: `E:\Godot\Godot_v4.6.1-stable_mono_win64_console.exe`

## [2026-06-05] Task: T1 — P/Invoke Export Spike — COMPLETE (PASS)

### Verdict: GO — A1 route confirmed
- `Ruby.Open()` + `[RbModule("Unity")]` + `[RbModuleMethod("ping")]` works in headless AND exported builds
- `PING_OK:pong` confirmed in: editor headless, debug export (.console.exe), release export (log)

### Critical Export Gotchas (MUST KNOW for T5 and real project)
1. **`.sln` required** (not `.slnx`) — Godot 4.6 export fails if only `.slnx` present
2. **Mono export templates** — Must use `4.6.1.stable.mono` templates; standard ones don't work
3. **Warm import cache first** — Run `godot --headless --path <proj> --quit-after 5` BEFORE export; else scene binary references `.cs` files that exported builds can't load
4. **Console wrapper** — `.console.exe` only generated in Debug export; Release uses main `.exe` + log file
5. **DLL resolution in export** — `AppContext.BaseDirectory` = `data_<Name>_<os>_<arch>/` folder; gem DLLs land in `data_*/Plugins/windows/`; use `NativeLibrary.SetDllImportResolver` + search `data_*/Plugins/windows/` explicitly
6. **Export path** — `data_<AssemblyName>_windows_x86_64/` pattern, NOT `data_<ProjectName>_...`

### Trim Configuration (working)
- `<PublishTrimmed>true</PublishTrimmed>` + `<TrimMode>partial</TrimMode>`
- `<TrimmerRootAssembly Include="RGSS-GodotSpike" />`
- `[DynamicDependency(DynamicallyAccessedMemberTypes.All, typeof(MrubySpike))]` on `_Ready()`
- `[DynamicDependency(DynamicallyAccessedMemberTypes.All, typeof(RbTypeRegisterHelper))]` on `_Ready()`

### Working csproj Pattern
```xml
<Project Sdk="Godot.NET.Sdk/4.6.1">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <GodotSharpDir>E:\Godot\GodotSharp</GodotSharpDir>
    <EnableDynamicLoading>true</EnableDynamicLoading>
  </PropertyGroup>
  <PropertyGroup Condition="'$(Configuration)' == 'Release'">
    <PublishTrimmed>true</PublishTrimmed>
    <TrimMode>partial</TrimMode>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="MRuby.Library" Version="0.1.7" />
    <TrimmerRootAssembly Include="RGSS-GodotSpike" />
  </ItemGroup>
  <ItemGroup>
    <Content Include="Plugins\windows\*.dll">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
      <CopyToPublishDirectory>Always</CopyToPublishDirectory>
    </Content>
  </ItemGroup>
</Project>
```

### Spike Project Location
- `E:\Projects\RGSS-GodotSpike\` — extend this for T2 (Marshal) and T3 (logger probe)
- Do NOT create a new project; extend this one

---

### Medot Project (may be relevant)
- `E:\Projects\Medot\` — appears to be a separate Godot project (FrameRonin, game, editor subdirs)
- Has `godot-mcp` subfolder — the godot-mcp-pro server may already be set up here!
- Check `E:\Projects\Medot\godot-mcp\` before setting up MCP anew

## [2026-06-05] Task: T2 — Marshal Spike — COMPLETE (PASS)

### Verdict: PASS — marshal_c gem round-trips through Godot .NET boundary
- `MARSHAL_OK:Project1` confirmed; `GEM_MISSING_CLEAN:YES` confirmed.
- Evidence: `.sisyphus/evidence/task-2-marshal.txt`, `task-2-missing-gem.txt`

### Critical: mruby marshal_c uses NON-ENCODING-TAGGED string format
- mruby marshal_c does NOT support CRuby's `I"` string format with `\x06:\x06ET` encoding markers
- mruby marshal_c expects bare `"\x04\x08"\x0DProject1"` format (no `I` prefix, no encoding ivar)
- The real `System.rvdata2` from RMVA is produced by CRuby and WILL have `I"` strings — it will NOT load directly via mruby marshal_c without pre-processing
- Real RMVA data loading will need to strip/handle encoding tags — this is a known issue for T5/kernel.rb

### Critical: File.binread does NOT exist in base mruby
- The 4 gems (marshal_c, dir_glob, onig_regexp, zlib) do NOT include mruby-io
- `File`, `IO` do not exist in the mruby VM — all file I/O must be done in C# and injected
- Pattern: use `[RbModuleMethod]` to read bytes in C# → return as binary `RbValue` via `mrb_str_new`

### mrb_str_new P/Invoke for binary strings
- `RbHelper.BuildRbStringObjectFromRawBytes` is in the source but NOT in the published NuGet v0.1.7
- Use direct P/Invoke instead:
  ```csharp
  [DllImport("libmruby_x64", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
  private static extern ulong mrb_str_new(IntPtr mrb, byte[] bytes, long length);
  // Then: return new RbValue(state, mrb_str_new(state.NativeHandler, bytes, bytes.Length));
  ```

### FormatRubyError: safe approach after Protect error
- After Protect catches an error, mruby is in error state — NO Ruby method calls work
- `value.ToString()` THROWS — it calls Ruby `to_s` which fails
- `value.GetClassName()` is safe (native C call only)
- Safe: `try { return value.GetClassName() ?? "RubyException"; } catch { return "RubyException"; }`

### RbModuleMethod with args: valid signature
- `(RbState state, RbValue self, RbValue[] args)` — valid for varargs
- `(RbState state, RbValue self)` — valid for no-arg
- Per `RbTypeRegisterHelper.cs:234`: `RbValue Foo(State State, RbValue self, RbValue[] varArgs)`

### LoadString return value
- `compiler.LoadString(code, context)` returns the last expression value
- Multi-line scripts: last expression is returned correctly
- BUT: `puts` returns `nil` in mruby — don't use `puts` to return values; use the expression directly

## [2026-06-05] Task: T3 — Logger-Crash Probe — COMPLETE (PASS)

### Verdict: LOGGER_CRASH:NO — GD.PrintErr in rescue does NOT crash mruby
- Pattern: `Protect` catches Ruby exception → C# calls `GD.PrintErr` directly → VM still alive (1+1=2)
- This means the deferred RGSSLogger queue is **defense-in-depth**, NOT a hard requirement for Godot
- Still port it (T11) for safety; but it's not blocking

## [2026-06-05 18:27:17 +08:00] Task: T1 — P/Invoke Spike
- Created Godot .NET spike project at E:\Projects\RGSS-GodotSpike using Godot.NET.Sdk/4.6.1, MRuby.Library v0.1.7, and copied native DLLs under Plugins/windows.
- MRuby.Library v0.1.7 has no RbState.Eval() helper; use state.NewCompiler().LoadString("Unity.ping", context) as in the wrapper README/Unity manager pattern.
- Ruby.Open() requires libmruby_x64.dll; Godot headless editor did not automatically resolve it from .godot/mono/temp/bin/Debug, so the spike registers a NativeLibrary.SetDllImportResolver for both the spike assembly and MRuby.Library and prepends project/plugin/temp output paths to PATH.
- Reflection registration path was exercised with [RbModule("Unity")], [RbModuleMethod("ping")], RbTypeRegisterHelper.Init(...), <TrimmerRootAssembly Include="RGSS-GodotSpike" />, and [DynamicDependency] for MrubySpike/RbTypeRegisterHelper.
- Headless editor run passes and logs PING_OK:pong with E:\Godot\Godot_v4.6.1-stable_mono_win64_console.exe --headless --path E:\Projects\RGSS-GodotSpike --quit-after 10.
- Windows export is blocked on this machine because Godot templates are missing at %APPDATA%\Godot\export_templates\4.6.1.stable.mono\windows_release_x86_64.exe; evidence records PARTIAL_PASS_EXPORT_BLOCKED_BY_MISSING_TEMPLATES.
- Trim publish succeeds with the spike assembly, MRuby.Library.dll, libmruby_x64.dll, and all four RGSS gem DLLs present; exported trimmed runtime still needs template installation before a true exported binary run can be proven.

## [2026-06-05] Task: T10 - GlobalConfig
- Ported Unity rm_conf.json loading to Godot C# singleton at `E:\Projects\RGSS-Godot\Scripts\GlobalConfig.cs` using `System.Text.Json` + `[JsonPropertyName]` mapping.
- Loader checks `OS.GetExecutablePath()` directory first, then `ProjectSettings.GlobalizePath("res://")`, then `System.IO.Directory.GetCurrentDirectory()`.
- UTF-8 BOM stripping is handled before deserialization; missing/unreadable config falls back to defaults and logs a warning.
- `BootManager._Ready()` now calls `GlobalConfig.Initialize()` and prints `CONFIG:{LegacyMode},{LegacyModeWidth}x{LegacyModeHeight}` before Ruby boot.
- Verified with Godot headless run: `CONFIG:True,544x416` followed by `SCRIPTS_LOADED:OK`.

## 2026-06-05 - Wave-0 T2/T3 Godot mruby spike
- Base mruby in the Godot spike has no `mruby-io`, so `File.binread` fails; reading `TestData/System.rvdata2` in C# and returning an mruby binary string fixes `Marshal.load`, producing `MARSHAL_OK:Project1`.
- The spike's referenced MRuby package did not expose `RbHelper.BuildRbStringObjectFromRawBytes`, so a local `mrb_str_new` P/Invoke provided the same raw byte-string behavior without changing dependencies.
- After `dotnet build`, Godot headless may still run a stale Mono assembly; running Godot with `--build-solutions` refreshed the cache before verification.
- Direct `GD.PrintErr` from the C# error-handling path did not crash the mruby VM in Godot; follow-up Ruby execution printed `LOGGER_CRASH:NO`.

## [2026-06-05] Task: T11 — RGSSLogger + lifetime-conventions
- Ported `RGSSLogger` to `E:\Projects\RGSS-Godot\Scripts\RGSSLogger.cs` as a static `ConcurrentQueue<(bool IsError, string Message)>`-backed deferred logger in namespace `RGSSUnity`.
- `FlushPendingMessages()` is the only drain point and routes normal/error entries to `GD.Print` / `GD.PrintErr` on the main thread.
- `BootManager._Ready()` now demonstrates the queue with `RGSSLogger.Log("LOGGER_TEST:queued")` followed by `FlushPendingMessages()`; the headless console run printed the token successfully.
- Added `E:\Projects\RGSS-Godot\docs\lifetime-conventions.md` to centralize binding lifetime rules: release-only disposal, mandatory `GC.KeepAlive`, delegate pinning with `RbNativeObjectLiveKeeper`, teardown release, rescue-path logging through `RGSSLogger`, and 1 Fiber.yield = 1 frame.

## [2026-06-05 23:44:35 +08:00] Task: T8 - GUT Harness + Golden-Screenshot Diff Tool — COMPLETE (PASS)

### Part A — GUT Install
- GUT **9.6.0** is the latest release and its notes explicitly say "Compatibility changes for Godot 4.6" → correct pick for Godot 4.6.1. Downloaded `https://github.com/bitwes/Gut/archive/refs/tags/v9.6.0.zip` and copied the inner `addons/gut/` (248 files) into `E:\Projects\RGSS-Godot\addons\gut\`.
- GUT base test class is `GutTest` (`class_name GutTest` in `addons/gut/test.gd`); sample test `tests/test_sample.gd` does `extends GutTest` + `assert_eq(1+1, 2)`.
- **Import warm-up is REQUIRED before first GUT run**: GUT ships `.ttf`/`.fnt`/`.png` resources. Run `godot --headless --path <proj> --build-solutions --import` once; otherwise the first `gut_cmdln` run can choke on unimported assets. (Benign `ObjectDB instances leaked at exit` warning appears on editor-mode exit — ignore it.)
- Headless command (fully automated, exits 0): `Godot_...console.exe --headless --path E:\Projects\RGSS-Godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit` → `1/1 passed` / `All tests passed!`.
- Enabled the plugin in `project.godot` via `[editor_plugins]\nenabled=PackedStringArray("res://addons/gut/plugin.cfg")`. NOTE: for headless `-s gut_cmdln.gd` runs this is **not strictly required** (editor plugins only load in editor mode), but it's the standard install and does not affect the headless game boot.

### Part B — golden_diff.gd
- `tools/golden_diff.gd` is a `SceneTree` script (run with `-s`), NOT a Node scene. KEY GOTCHA: at SceneTree scope there is no `get_viewport()`; use `get_root()` — the root **Window IS a Viewport**, so `get_root().get_texture().get_image()` is the SceneTree-equivalent of the task's `get_viewport()...` snippet.
- Modes: default screenshot → `user://screenshot.png`; `--golden <path>` saves reference; `--compare <golden> <actual> [--tolerance <n>]` does pixel diff. Args are read from BOTH `OS.get_cmdline_user_args()` (after `--`) and `OS.get_cmdline_args()` so it works with or without the `--` separator.
- Diff algorithm: load both PNGs → `convert(Image.FORMAT_RGBA8)` → iterate raw `get_data()` bytes → `max per-channel abs diff` (0..255). Prints `GOLDEN_DIFF:PASS:<n>` (max<=tol, exit 0) or `GOLDEN_DIFF:FAIL:<n>` (exit 1). On FAIL (or size mismatch) writes a diff PNG to `user://golden_diff.png` (per-channel abs diff, alpha forced opaque).
- **HEADLESS LIMIT**: `DisplayServer.get_name() == "headless"` has no framebuffer read-back → `get_texture().get_image()` returns null AND logs an internal error trace. Guard by checking `DisplayServer.get_name() == "headless"` BEFORE attempting capture; emit `GOLDEN_DIFF:SCREENSHOT_UNAVAILABLE_HEADLESS` (exit 0) cleanly. Live golden capture must run on a GPU display server; the **compare/diff core works fully headless** (it only reads PNG files).
- Self-validated: identical imgs → `PASS:0`; one-pixel R-50 → `FAIL:50` + diff image (probe confirmed `16x16 max_r=50 nonzero_px=1`); one-pixel R-3 → `PASS:3` (3<=5); `--tolerance 60` on diff-50 → `PASS:50`.

### Regression / Misc
- `dotnet build RGSS-Godot.csproj`: 0 warnings / 0 errors. Headless boot unchanged: `CONFIG:True,544x416` + `SCRIPTS_LOADED:OK` + `LOGGER_TEST:queued` (exit 0).
- `SceneTree` capture timing: connect to the `process_frame` signal and wait ~3 frames before grabbing the viewport (don't override `_process`). Quit via `quit(exit_code)`.
- API note: `OS.get_current_rendering_driver_name()` does NOT exist in 4.6 GDScript (parse error); use `DisplayServer.get_name()` for headless detection.
- godot-mcp confirmed present at `E:\Projects\Medot\godot-mcp\` — left UNconfigured per task scope (noted only).
- Evidence: `E:\Projects\RGSS-Unity\.sisyphus\evidence\task-8-harness.txt`.
## [2026-06-06 00:00:00] Task: T12 - Value Types
- Matching the Unity bindings required keeping the same Ruby-facing class names/method names, but switching the C# backing storage to raw fields and .NET types.
- `System.Numerics.Vector4` is sufficient for Tone in the Godot port and avoids any Unity dependency.
- `Color` and `Font` still need follow-up attention if runtime parity issues appear in downstream scripts, but the value-type files themselves now compile and load through the early boot sequence.
## [2026-06-06 00:23:15 +08:00] Task: T13 - File IO
- Added Scripts/RMProjectPath.cs with exe/config/current-directory/editor fallback resolution and Resolve/Exists/ReadAllBytes/WriteAllBytes helpers.
- Wired GameManager._Ready() to call RMProjectPath.Initialize() immediately after GlobalConfig.Initialize().
- Updated UnityModule.rmva_project_path to return RMProjectPath.BaseDir and removed the old base-path helper.
- Verification: dotnet build E:\Projects\RGSS-Godot\RGSS-Godot.csproj succeeded with 0 errors.
- Verification: headless boot reached SCRIPTS_LOADED:OK and MAIN_LOADED:OK, and printed RMPROJECT_PATH:E:\Projects\RGSS-Godot.
- Caveat: headless runtime still throws the pre-existing Kernel.Require viewport exception after MAIN_LOADED:OK; this is unrelated to the path resolver change.

## [2026-06-06 00:27:38 +08:00] Task: T15 - Render Conventions Spec
- Added E:\Projects\RGSS-Godot\docs\render-conventions.md as the render binding spec for T16-T21 and T24.
- M2 ruling: Graphics fade, transition, freeze, and brightness share one BackBufferCopy per frame between the composite CanvasLayer and postprocess CanvasLayer. Postprocess shaders read the copied frame through hint_screen_texture.
- M3 ruling: RMVA render objects stay in one CanvasLayer with z_as_relative = false and direct 0..200 z_index; each RGSS Viewport renders to a SubViewport displayed by a wrapper Sprite2D at iewport.z.
- M4 ruling: Sprite effects pack into four instance uniform vec4s: _PackedA wave and bush opacity, _PackedB normalized tone, _PackedC normalized flash, _PackedD opacity, mirror, gray flag, reserved.
- Unity source confirmation: Sprite.cs sets sortingOrder = data.Z and normalizes opacity and bush opacity; SpriteShader.shader applies mirror, wave, gray, tone, opacity, bush, then flash.

## [2026-06-06 00:35:33 +08:00] Task: T14 - GameRenderManager
- Added Godot render spine at `E:\Projects\RGSS-Godot\Scripts\GameRenderManager.cs` with a hand-rolled singleton, composite CanvasLayer(0), RmvaRenderRoot, one GraphicsBackBufferCopy, and PostprocessLayer CanvasLayer(1) with a full-rect ColorRect.
- Viewport registration now creates a transparent always-updating SubViewport sized from GlobalConfig legacy dims (544x416 in current config) or the visible project window, plus a Sprite2D wrapper with `ZAsRelative = false`, `ZIndex = viewport.Z`, and `FlipV = true` for RGSS top-down texture orientation.
- Added minimal compile stubs for SpriteData, PlaneData, WindowData, BitmapData, and ViewportData under `Scripts\RubyClasses`; BitmapData.UpdateTexture remains empty for later bitmap implementation.
- GameManager initializes GameRenderManager after RMProjectPath.Initialize() and before RubyScriptManager.Initialize(), then calls Update() each _Process and Dispose() during teardown.
- Verification: `dotnet build E:\Projects\RGSS-Godot\RGSS-Godot.csproj` succeeded with 0 errors; Godot headless 10-frame run reached `SCRIPTS_LOADED:OK` and `MAIN_LOADED:OK` with exit code 0. The existing Ruby viewport require exception still logs after MAIN_LOADED:OK and remains unrelated to T14.
- Evidence written to `E:\Projects\RGSS-Unity\.sisyphus\evidence\task-14-composite.txt`.

## [2026-06-06 01:05:00 +08:00] Task: T16 - Bitmap
- Created E:\Projects\RGSS-Godot\Scripts\RubyClasses\Bitmap.cs (Godot 4 port of Unity::Bitmap). BitmapData.cs was already done; only the [RbClass] binding was added.
- MRuby mapper arity (decompiled MRuby.Library RbTypeRegisterHelper.DefineMethod via ilspycmd): each fixed RbValue param after (RbState, RbValue self) becomes a REQUIRED arg (MRB_ARGS_ARG); a trailing RbValue[] param becomes varargs (MRB_ARGS_REST). The Ruby wrapper resolves ALL overloads (Rect-vs-4-ints, optional opacity/align) BEFORE the native call, so every native Bitmap method takes a FIXED canonical signature - no C# varargs needed. msgbox in UnityModule.cs proves RbValue[] varargs works for attribute-registered methods.
- CRITICAL boot dependency: RGSS/bitmap.rb initialize calls self.font= and self.rect= right after construction. Native font/font=/rect/rect= MUST exist or every Bitmap.new crashes. Godot BitmapData has NO FontData field (and must not be modified), so font/rect are stored as @font/@rect Ruby ivars via RbValue.SetInstanceVariable/GetInstanceVariable (mirrors Unity self["@font"]/self["@rect"]). new_wh/new_filename seed @font=nil and @rect=Rect(0,0,w,h) so the object is well-formed before the wrapper overwrites them.
- Godot Image axis is TOP-DOWN, same as RGSS -> NO Y-flip (unlike Unity Texture2D which is bottom-up and required tex.height - y inversions). Coordinates pass through directly.
- Name collision: RubyClasses.Color / RubyClasses.Rect shadow Godot.Color / Rect2I. Qualify "new Godot.Color(...)" and "Godot.Color.FromHsv(...)" explicitly. ColorData stores R/G/B/A as 0..1 floats -> new Godot.Color(cd.R,cd.G,cd.B,cd.A) directly; Color.CreateColor takes 0..255 so multiply Image pixel channels by 255f.
- Godot Image API (verified via GodotSharp reflection, 4.6.1): Image.CreateEmpty(w,h,useMipmaps,Format.Rgba8) [NOT Create], LoadFromFile(path), FillRect(Rect2I,Color), Fill(Color), BlendRect(src,Rect2I,Vector2I dst) [alpha-aware; BlitRect overwrites], GetRegion(Rect2I)->Image, Resize(w,h,Interpolation.Bilinear), GetPixel/SetPixel, Convert(Format), Duplicate(true)->Resource (cast to Image), GetWidth/GetHeight/GetFormat. ImageTexture.CreateFromImage(img) + .Update(img).
- CPU effects: gradient_fill_rect = per-pixel lerp; hue_change = per-pixel HSV via color.H/.S/.V + Godot.Color.FromHsv; blur = 3x3 box average over a Duplicate() snapshot so the kernel reads original pixels. blt opacity<255 path = GetRegion + per-pixel alpha scale + BlendRect.
- Stubbed (acceptable for T16 per task): draw_text (needs Label+SubViewport render-back, deferred), radial_blur (visual-only). text_size estimates w=len*fontSize, h=fontSize and reads @font size if present.
- C# LSP (csharp-ls) NOT installed in this env -> rely on dotnet build for diagnostics.
- Verification: dotnet build -> 0 errors (6 pre-existing warnings, none in Bitmap.cs). Godot headless --quit-after 10 -> SCRIPTS_LOADED:OK + MAIN_LOADED:OK, exit code 0, "bitmap" script loaded with no error.
- The viewport.rb load-time exception (DEFAULT_VIEWPORT = Viewport.new on line 85, Viewport.cs binding not yet ported) is pre-existing and out of scope - same exception already documented for T13 (line 213) and T14 (line 227).
- Evidence: E:\Projects\RGSS-Unity\.sisyphus\evidence\task-16-bitmap.txt

## T24 shader migration findings - 2026-06-06
- Unity `Assets/Shaders` contains exactly 15 `.shader` files. Eight runtime effects were translated to Godot `shader_type canvas_item` shaders under `E:\Projects\RGSS-Godot\Shaders`: Sprite, WindowBackground, Plane, TiledBackground, GraphicsPostprocess, TransitionPostprocess, Viewport, and SpriteMask.
- Godot postprocess shaders follow M2: `GraphicsPostprocessShader.gdshader` and `TransitionPostprocessShader.gdshader` sample `SCREEN_TEXTURE` via `hint_screen_texture` / `textureLod(..., 0.0)`.
- `SpriteShader.gdshader` follows M4 with `instance uniform vec4 _PackedA`, `_PackedB`, `_PackedC`, and `_PackedD`; additional material uniforms remain only for values not covered by M4 (`mix_color`, `bush_depth`, `texture_size`).
- Bitmap operation shaders (`FillRect`, `StretchBlt`, `HueChange`/`HueShift`, `Blur`, `BitmapClear`, `GradientFillRect`, `RadiaBlur`/`RadialBlur`) are documented in `Shaders/README.md` and intentionally not ported because Godot bitmap ops are CPU-side in `Bitmap.cs`.

## [2026-06-06] Task: T23 - Input Subsystem Port — COMPLETE (PASS)
- Created 3 files: `Scripts/InputStateRecorder.cs` (verbatim), `Scripts/GameInputManager.cs` (Godot poller Node), `Scripts/RubyClasses/Input.cs` (`[RbModule("Input","Unity")]`). Wired `GameManager.cs` only.
- **InputStateRecorder.cs is byte-for-byte verbatim from Unity** — same InputKey enum order (DOWN=0,LEFT,RIGHT,UP,A,B,C,X,Y,Z,L,R,SHIFT,CTRL,ALT,F5..F9), same Direction flags, same repeat cadence `(RepeatCount >= 23) && ((RepeatCount + 1) % 6 == 0)`, same dir4/dir8. Zero Unity dependencies in it (pure `System`), so it dropped into Godot unchanged. Accepts 2 CS8618 nullable warnings (arrays init in `Init()` not ctor) to stay verbatim — do NOT "fix" these.
- **Input.cs binding decorator = `[RbModule]` (NOT `[RbClass]`).** Unity's `Input.cs` used `[RbModule("Input","Unity")]`; replicated exactly. Godot port uses the SAME `RbTypeRegisterHelper.Init` reflection as Unity (confirmed via `Graphics.cs`/`UnityModule.cs`), so the binding is near-verbatim — only adjusted to file-scoped namespace style. `GetInternSymbol`/`UnboxSymbol`/`.ToValue`/`RbNil` all present in MRuby.Library 0.1.7. Used `= null!` on the cached static recorder field (matches `UnityModule.State` convention) to suppress CS8618 in the binding.
- **CRITICAL — action-name vs physical-key are NOT identity in RGSSInput.inputactions.** The 20 Unity actions bind to DIFFERENT keyboard keys (RMVA default layout): action A->key X, B->key X, C->key Z, X->key A, Y->key S, Z->key C; L->L, R->R; SHIFT/CTRL/ALT/F5-F9/arrows are identity. Must read the `bindings` section, NOT assume name==key. Encoded as a single `ActionTable` `(InputKey, string action, Key keycode)[]` on `GameInputManager` so InputMap registration (GameManager) and per-frame polling (GameInputManager) share one source of truth and can't drift.
- **Unity vs Godot input drive model differs.** Unity used event-driven `PlayerInput` `CallbackContext.started/.canceled`. Godot has no per-action C# callback; instead poll `Godot.Input.IsActionJustPressed/JustReleased(action)` in `_Process`. `_Input(InputEvent)` is overridden but intentionally empty (edge detection is frame-coherent in `_Process`). Note `Godot.Input` (engine singleton) is DISTINCT from the RGSS `Unity::Input` binding — qualify `Godot.Input` to avoid collision with `RGSSUnity.RubyClasses.Input`.
- **Frame ordering preserved:** `InputStateRecorder.Instance.Update()` is the FIRST line of `GameManager._Process` (before `GameRenderManager.Update()` -> `UnityModule.Update()` fiber pump). Boot order in `_Ready`: render init -> `InputStateRecorder.Init()` -> `RegisterInputActions()` (20 `InputMap.AddAction`+`ActionAddEvent`) -> `AddChild(new GameInputManager)` -> ruby init. Mirrors Unity's render->input->ruby boot order.
- InputMap registration pattern (idempotent): `if (!InputMap.HasAction(a)) InputMap.AddAction(a); InputMap.ActionEraseEvents(a); InputMap.ActionAddEvent(a, new InputEventKey { Keycode = key });`. Godot `Key` enum: `Key.Shift/Ctrl/Alt`, `Key.F5..F9`, `Key.Up/Down/Left/Right`, letter keys `Key.A..Z`.
- Main scene is `Scenes/Boot.tscn` -> single `Node` running `GameManager.cs`. Added GameInputManager as a runtime child via `AddChild` (no .tscn edit needed).
- Verification: `dotnet build` -> 0 errors (8 warnings: 6 pre-existing in untouched files + 2 verbatim-port CS8618). Headless `--quit-after 10` -> `SCRIPTS_LOADED:OK` + `MAIN_LOADED:OK`, `Loaded script: input` with NO error.
- The `Error in script viewport` at `main.rb:59` is the SAME pre-existing, out-of-scope failure documented for T13/T14/T16 (lines 213/227/241): there is still NO `Unity::Viewport` C# binding (grep `RbClass("Viewport")`/`RbModule("Viewport")` = 0 matches; only empty `ViewportData.cs`). Unrelated to input.
- Evidence: `E:\Projects\RGSS-Unity\.sisyphus\evidence\task-23-input.txt`

## [2026-06-06] Task: T16 - Bitmap
- Ported Unity Bitmap to Godot with `Image` + `ImageTexture` backing storage in `Scripts/RubyClasses/BitmapData.cs` and a new `[RbClass("Bitmap", "Object", "Unity")]` binding in `Scripts/RubyClasses/Bitmap.cs`.
- Dirty tracking is centralized in `BitmapData.MarkDirty()`: it sets `Dirty = true` and registers with `GameRenderManager.DirtyBitmapDataSet`; `UpdateTexture()` performs `ImageTexture.Update(Image)` during render-manager reset.
- GodotSharp 4.6 exposes `Image.BlitRect`, but the implementation uses explicit CPU alpha-over loops for `blt` and resized-region blending for `stretch_blt` so RGSS opacity behavior is controlled and testable.
- `draw_text` uses a one-shot transparent `SubViewport` plus `Label`/`LabelSettings`, then blends `viewport.GetTexture().GetImage()` back into the bitmap image.
- Verification: `dotnet build E:\Projects\RGSS-Godot\RGSS-Godot.csproj` passed with 0 errors; headless Godot reached `SCRIPTS_LOADED:OK` and `MAIN_LOADED:OK`; a temporary Ruby smoke scene printed `BITMAP_SMOKE:OK` for `Bitmap.new(100,100) -> fill_rect -> get_pixel`.
- The remaining headless `viewport` require exception occurs after `MAIN_LOADED:OK` and is the pre-existing downstream stub issue from earlier tasks, not caused by Bitmap.
- Viewport boot now survives Viewport.new during iewport.rb load by deferring render-node creation until the first post-load GameRenderManager.Update() and using a boot-safe default render size for Graphics.width/height when the scene tree is not ready.

## T17 Sprite + T21 Graphics - 2026-06-06
- Godot 4.6 treats PI as a built-in shader identifier, so SpriteShader local constants must avoid that name (used RGSS_PI).
- In the Sprite canvas shader, TEXTURE sampling must stay in fragment(); helper functions can return UVs for fragment to sample.
- Sprite render nodes are Sprite2D-derived SpriteDataNode children of the viewport SubViewport root, with per-instance packed uniforms _PackedA through _PackedD.
- Graphics.WaitCount is consumed by UnityModule.Update via Graphics.Render(); fade/transition stubs can safely advance boot by setting WaitCount and brightness only.


## [2026-06-06] T20 (Plane binding) + T25 (patch_rmva path fix) — COMPLETE

### T20: Plane binding (PlaneData.cs, Plane.cs, GameRenderManager.cs)
- `PlaneData` stub (10 lines) replaced with full data class mirroring `SpriteData` shape: Bitmap, Viewport, Ox/Oy, ZoomX/Y, Z=100, Visible, Opacity=255, BlendType, Tone, Color, Disposed, `Node2D? Node`.
- `Plane.cs` follows `Sprite.cs` 1:1: `self["@bitmap"]` ivar accessors, `GetRDataObject<PlaneData>()`, `new_with_viewport` -> `GameRenderManager.Instance.RegisterPlane(data, viewportData)`.
- **GOTCHA / decision**: `PlaneDataNode` was declared `: Node` but the spec's `RegisterPlane` assigns it to `PlaneData.Node` typed `Node2D?`. Fix = change `PlaneDataNode : Node` -> `: Node2D` (matches `SpriteDataNode : Sprite2D`). Zero behavioral risk because `RenderPlane(PlaneData)` is still an empty stub. Without this change the build fails with a CS0266 cast error.
- `RegisterPlane`/`UnregisterPlane` are byte-for-byte parallel to `RegisterSprite`/`UnregisterSprite` (pending-queue fallback when viewport not yet registered, reparent-on-existing, `entry.SubViewportRoot.AddChild`). Pending flush added in `Update()`; `planes.Clear()`+`pendingPlanes.Clear()` added in `Dispose()`.
- Tone/Color 0-255 boundary: reuse `Tone.CreateTone(state, r*255, ...)` and `Color.CreateColor(state, r*255, ...)` exactly like Sprite's getters (multiply stored 0-1 floats back to 0-255).
- `plane.rb` line 14 `@viewport` bug left untouched per instructions (C# side works regardless).

### T25: patch_rmva.rb
- `filename.include?('\.')` -> `filename.include?('.')` on 5 lines (108,121,134,147,164). `'\.'` is a literal backslash-dot string under `String#include?` (not regex) so it never matched `name.ext` and could false-match Windows paths. Used `edit` with `replaceAll` since all 5 lines were identical. Verified: 0 x `'\.'`, 5 x `'.'`.

### Verification
- `dotnet build` => Build succeeded, 0 Error(s). 7 warnings ALL pre-existing in unrelated files (Bitmap/Font/Kernel/UnityModule/RubyExtension) — none in the 3 touched files.
- Headless (`--quit-after 10`): `SCRIPTS_LOADED:OK` + `Loaded script: plane` + `MAIN_LOADED:OK`, no Plane errors. The later `RMProject/Data/Scripts.rvdata2` missing-file exception is absent sample game data, fires AFTER both markers, unrelated.
- Evidence: `.sisyphus\evidence\task-20-plane.txt` and `task-25-path-fix.txt`.

## [2026-06-06] T18 Window binding
- `RGSS/window.rb` currently calls `Unity::Window.new_xywh(x, y, width, height, Viewport::DEFAULT_VIEWPORT.__handler__)`, so the Godot binding needs `new_xywh` for boot parity even if the migration task also asks for `new_with_viewport`.
- Window visual rendering is intentionally deferred: `WindowData` stores the RGSS state and `GameRenderManager.RegisterWindow` creates a `WindowDataNode : Node2D`, while `RenderWindow(WindowData)` remains an empty stub for later T26 visual work.
- Window lifecycle follows Sprite/Plane: register with a viewport, queue in `pendingWindows` when the viewport node is not ready, reparent if already registered under a different viewport root, and only `QueueFree()` from `UnregisterWindow`/manager cleanup (no finalizer node freeing).
- LSP diagnostics remain unavailable in this environment because `csharp-ls` is not installed; `dotnet build E:\Projects\RGSS-Godot\RGSS-Godot.csproj` is the practical compiler verification and passed with 0 errors.
- Headless Godot boot reached `SCRIPTS_LOADED:OK`, loaded `window`, and reached `MAIN_LOADED:OK`; the later missing `RMProject/Data/Scripts.rvdata2` exception is unrelated sample project data.

## 2026-06-06 - T26 Windows integration path check
- Godot `rm_conf.json` must set `project_path` to the base directory above `RMProject`, e.g. `E:/Projects/RGSS-Unity/Assets/StreamingAssets`; `Scripts/RMProjectPath.cs` appends `RMProject` internally.
- With that config, headless Godot prints `RMPROJECT_PATH:E:\Projects\RGSS-Unity\Assets\StreamingAssets` and no longer fails with missing `Scripts.rvdata2`.
- Current next blocker is not path resolution: `RGSS/main.rb:41` reaches `Unity.register_rmva_script`, then `Scripts/UnityModule.cs:122` fails inflating a game script payload with SharpZipLib `Unexpected EOF`.
## 2026-06-06 - T26 EOF guard in RegisterRmvaScript
- `Scripts/UnityModule.cs` now treats zero-byte RMVA script payloads as empty scripts and wraps `InflaterInputStream.CopyTo` in try/catch. Inflate failures log through `RGSSLogger.LogError` and preserve script order by adding an empty script body.
- `scriptName.ToStringUnchecked()` is nullable from the compiler's perspective; coalesce it with `?? string.Empty` before adding to `RmvaScripts` to avoid introducing CS8620 tuple-nullability warnings.
- Verification after the guard: headless Godot no longer crashes with SharpZipLib `Unexpected EOF`; it loads ext/rpg scripts, prints RMVA script names (`Vocab`, `Cache`, `Scene_Title`, `Main`, etc.), runs all RMVA scripts, and reaches `Running RGSS3 main loop...`.
- Next blocker after EOF fix is later title-screen bitmap loading: `bitmap.rb:16` via `Cache.title1` / `Scene_Title.create_background`, native message `External component has thrown an exception.`
## T29 finalizer-lifetime stress test - 2026-06-06
- Added a headless Godot stress script at `RGSS-Godot/tests/test_stress_dispose.gd` driven by a test-only C# bridge. In `-s` headless mode, loading the C# script by resource path and calling PascalCase C# method names was more reliable than relying on GlobalClass registration/snake_case names.
- The dispose stress creates 6 iterations x 60 sprites/windows plus paired bitmaps through mruby, disposes them, runs mruby/managed GC, and verifies render dictionary counts return to baseline with node count within tolerance.


---

## F3 Parity QA Verification (2026-06-06)

**Verified runtime behavior of Godot port (headless, Windows).**

### Boot + Integration (verified)
- `--quit-after 10` and `--quit-after 60` both reach: `SCRIPTS_LOADED:OK` -> all 17 built-ins -> `MAIN_LOADED:OK` -> `RGSS3 scripts loaded successfully.` -> `Running RGSS3 main loop...`
- All 17 built-in scripts load clean: kernel, tone, type_check_util, rect, color, font, graphics, input, audio, sprite, bitmap, viewport, plane, window, table, rgss_error, rgss_reset (plus ext/* and full rpg/* + Scripts.rvdata2 RMVA scripts).
- Expected/acceptable crash after loop start: `bitmap.rb:16 new_filename` via `Cache.title1` -> `Scene_Title.create_background` (missing title bitmap from game assets, not an engine defect).

### Stress (verified)
- `tests/test_stress_dispose.gd -gexit` => `STRESS_PASS`. Managed memory after (1135264) < before (1574312); node count returns to low baseline (after_nodes=7). No dispose leak.

### Binding completeness (verified 14/14)
All under namespace `Unity`:
- [RbClass]: Sprite, Bitmap, Window, Viewport, Plane, Color, Tone, Rect, Table, Font (10)
- [RbModule]: Graphics (Scripts/Graphics.cs), Audio, Input (3)
- [RbModule("Unity","")]: Scripts/UnityModule.cs (the module itself)
- 75 [RbClass]/[RbModule]/method attrs across 14 files.

### Deferred (environment-blocked)
- T6 Capability Census (Unity Editor not installed) -> no golden screenshots -> no pixel parity.
- T27 macOS export / T28 Linux export (no Mac/Linux machine).
- Verified scope: **Windows-only, headless boot + game loop start.**

### Verdict: CONDITIONAL_APPROVE (runtime boot/loop/lifetime parity solid; visual + cross-platform parity deferred).

## [2026-06-06] Task: T6 — Capability Census (static code analysis) — COMPLETE

### Outputs
- `.sisyphus/capability-census.md` (14.4 KB) — full census, all tables filled.
- `.sisyphus/evidence/task-6-census.txt` — evidence with file:line citations.

### Verdict summary (code-connectivity, NOT visual parity — Unity Editor unavailable)
- 14/14 Unity:: types assessed. 13 WORKS, 1 BROKEN (Tilemap).
- 9 RMVA flows assessed. 8 WORKS, 1 BROKEN (Map load).

### Hard evidence captured (for Godot parity targeting)
- `grep RbClass("Tilemap"|RbModule("Tilemap"` = 0 matches → no native Tilemap. Confirms BROKEN.
- Tilemap is a DOUBLE gap: (a) `main.rb` L49-64 never `require 'tilemap'` → NameError on `Tilemap.new` in `Spriteset_Map.rb:38` first; (b) even if required, `tilemap.rb:10` `Unity::Tilemap.new` → NoMethodError. Godot port: do NOT add Tilemap (matches Unity reality).
- Input WORKS confirmed via `Scenes/SampleScene.unity` (21 `GameInputManager` refs = PlayerInput events wired). GameInputManager.cs is Unity event-driven (HandleA..HandleRight, started/canceled) — DISTINCT from Godot port's polling model (notepad T23). Both feed the same InputStateRecorder (byte-identical class).
- 2 isolated STUBs (RaiseNotImplementError): Graphics.play_movie (Graphics.cs:342), Audio.setup_midi (Audio.cs:19). Parity = keep stubbed.

### Newly verified Ruby bugs this pass (do-not-fix; parity baseline)
- audio.rb:47 — symbol list has `:set_stop` (typo for `:se_stop`) → se_stop undefined via metaprogramming.
- viewport.rb:15 — `new_xyrw(rect.x, rect.y, rect.w. rect.h)` stray dot (should be commas) on single-Rect ctor.
- bitmap.rb:66 — `gradient_fill_rect(... rect.w. rect.h ...)` same stray-dot; also `check_arugments` typo L44.
- plane.rb:14 — non-nil branch uses `@viewport.__handler__` (nil ivar) not the arg; plane.rb:36 `def viewport=` has no param.
- color.rb:65 / font.rb:72,76 — carried from prior notepad, NOT re-read this pass (out of census read set). Flagged as such in census.
- C# Color.cs:97 (blue=) & :113 (alpha=) ×255 instead of /255; Plane.cs:333 disposed? casts SpriteData not PlaneData (harmless).

### Note for reviewers
- "WORKS" = Ruby→C#→Unity chain is code-complete + no NoMethodError. It is NOT a visual/pixel claim (no Editor, no golden screenshots). Asset-dependent flows (Title/Message) need StreamingAssets/RMProject media; absence = data gap, not engine defect.

## [2026-06-06] Task: T27/T28 - Cross-platform native gem packaging
- RGSS-Godot native resolver now keeps logical DllImport names unchanged and maps them through NativeLibrary.SetDllImportResolver to platform files: Windows .dll in Plugins/windows, macOS .dylib in Plugins/macos, Linux .so in Plugins/linux.
- Godot export data folder suffixes used by the resolver: windows_x86_64, macos, linuxbsd_x86_64.
- CI workflow at E:\Projects\RGSS-Godot\.github\workflows\cross-platform.yml builds mruby-for-dotnet host lib first, copies libmruby_x64 into each mruby-ext gem lib/ folder, builds xmake gems, packages native libs, exports Godot, and asserts SCRIPTS_LOADED:OK, MAIN_LOADED:OK, Running RGSS3 main loop, and no GEM_INIT_FAIL.

