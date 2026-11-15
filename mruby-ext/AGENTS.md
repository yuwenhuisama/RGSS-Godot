# NATIVE MRUBY GEM BUILD

## OVERVIEW
Four xmake extension targets sharing the host mruby ABI; score 1 excluding vendored sources, retained because existing native-domain guidance needs correction.

## WHERE TO LOOK
| Directory | Windows DLL | Init export |
|-----------|-------------|-------------|
| `marshal/` | `libmruby_marshal_c_ext_x64.dll` | `mrb_mruby_marshal_c_gem_init` |
| `glob/` | `libmruby_dir_glob_ext_x64.dll` | `mrb_mruby_dir_glob_gem_init` |
| `regexp/` | `libmruby_onig_regexp_ext_x64.dll` | `mrb_mruby_onig_regexp_gem_init` |
| `zlib/` | `libmruby_zlib_ext_x64.dll` | `mrb_mruby_zlib_gem_init` |

## CONVENTIONS
- Root `xmake.lua` includes the four gem directories; each owns an `xmake.lua` and Windows `export.def`.
- Submodule paths and fork branches live in root `.gitmodules`; initialize them before a native build.
- Each target uses `MRUBY_DIR` when set, otherwise `E:/Projects/mruby-for-dotnet/mruby`.
- Headers come from that checkout's `build/host/include`; an override changes the header source, not prebuilt import libraries.
- `MRB_INT64` and `MRB_UTF8_STRING` must match the host build and the managed MRuby.Library ABI.
- The current bundled Windows host also enables `MRB_USE_DEBUG_HOOK`; all four Windows extension targets must use it. `tools/run_native_abi_probe.cmd /DMRB_USE_DEBUG_HOOK` prints diagnostic offsets and class-field matches; its exit code alone is not an ABI assertion. The asserted combined probe is `tools/defined-compiler/probe_windows_archive.ps1`. Other platforms require their own measured configuration.
- Windows links root `lib/libmruby_x64.lib`; regexp additionally links `lib/onigmo_s.lib`.
- Linux links `mruby_x64` by name with `$ORIGIN`; macOS uses `@loader_path`.
- macOS has x86_64 and arm64 targets combined by a phony universal target and `lipo`.
- Non-debug lipo lookup uses a `release` output directory; follow the CI's release-mode invocation.
- Linux/macOS regexp compiles the explicit Onigmo source list; zlib compiles the bundled `zlib-1.3.1` sources.
- Off-Windows zlib defines `HAVE_UNISTD_H` because its inline build bypasses configure.
- Host libraries in `lib/` are prebuilt inputs; this tree does not produce them.
- Out-of-tree extensions must resolve exception symbols dynamically when host presym tables change. The defined? host candidate shifted ArgumentError from1245 to1248 despite matching state layout; Marshal's shared header overrides MRB_ERROR_SYM with mrb_intern_lit so E_ARGUMENT_ERROR cannot resolve an unrelated class.

## BUILD
```sh
git submodule update --init --recursive
cd mruby-ext
# Set MRUBY_DIR in the shell before building on another machine.
xmake
```
- Copy the Windows gem DLLs from `build/windows/x64/<mode>/` to root `Plugins/windows/` beside the matching host DLL.
- Actual Linux x86-64 and macOS arm64 host/extension builds and runtime contracts are measured in `docs/compatibility/current-status.md`. The CI recipes remain separate from those local runs; macOS universal/Intel execution is unverified.

## ANTI-PATTERNS
- Do not inline Onigmo on Windows without `ONIG_EXTERN=extern`; the target deliberately keeps the prebuilt archive.
- Keep actual DLL basenames, C# DllImport strings in `Scripts/RubyScriptManager.cs`, and exported init symbols aligned.
- `export.def` LIBRARY labels omit parts of current basenames; the EXPORTS symbols and xmake basenames are load-bearing.
- Preserve each gem's `_gem_final` export alongside `_gem_init`, even though current C# initialization imports only init.
- Mirror shared platform/ABI changes across all four target files; regexp has additional engine-specific requirements.
