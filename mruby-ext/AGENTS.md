# mruby-ext — NATIVE mruby GEM BUILD

xmake build for the 4 native mruby gems P/Invoked by `RubyScriptManager.cs`. Output DLLs are copied to `Assets/Plugins/windows/`. Touch this ONLY when changing native gem behavior — normal engine work never builds here.

## THE 4 GEMS → DLLs
| Dir | Gem (git submodule) | Produces | P/Invoke entry |
|-----|--------------------|----------|----------------|
| `marshal/` | mruby-marshal-c | `libmruby_marshal_c_ext_x64.dll` | `mrb_mruby_marshal_c_gem_init` |
| `glob/` | mruby-dir-glob | `libmruby_dir_glob_ext_x64.dll` | `mrb_mruby_dir_glob_gem_init` |
| `regexp/` | mruby-onig-regexp | `libmruby_onig_regexp_ext_x64.dll` | `mrb_mruby_onig_regexp_gem_init` |
| `zlib/` | mruby-zlib (+ zlib-1.3.1) | `libmruby_zlib_ext_x64.dll` | `mrb_mruby_zlib_gem_init` |

Submodules in `.gitmodules`; `git submodule update --init` before first build.

## BUILD
```
xmake          # root mruby-ext/ — xmake.lua just includes the 4 subdir targets
# then copy build/windows/x64/<mode>/lib*_ext_x64.dll → Assets/Plugins/windows/
```

## CONVENTIONS (per-gem xmake.lua)
- `set_arch("x64") set_kind("shared")`; defines `MRB_INT64 MRB_UTF8_STRING` — **must match how host mruby was built** or symbols mismatch at load. (mruby 4.0.0 removed `MRB_NO_PRESYM`; out-of-tree gems use runtime `mrb_intern_lit` instead of the compile-time `MRB_SYM(x)` presym macro.)
- Links the prebuilt host mruby: Windows `lib/libmruby_x64.lib` (+ `onigmo_s.lib` for regexp), via Windows `export.def`.
- `mruby_dir` is **hardcoded** to `E:/Projects/mruby-for-dotnet/mruby` (the mruby-for-dotnet checkout's build/host headers). Update this path on a new machine.
- macOS/linux branches exist (universal `lipo`) but only Windows x64 DLLs are shipped/committed.

## GOTCHAS
- DLL basename + the `[DllImport("libmruby_*_x64")]` string + `export.def` exported symbol must all agree.
- `lib/`, `build/`, `.xmake/` are gitignored build inputs/outputs; the host `.lib` files are prebuilt, not produced here.
