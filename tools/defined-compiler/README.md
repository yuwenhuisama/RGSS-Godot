# Bounded `defined?` Compiler Compatibility Unit (mruby 4.0.0)

## Current recoverable source input

`source/mruby-current-source.zip` preserves the current modified compiler and
shared-host source, including upstream licenses and generated parser sources.
Its fixed SHA256 is documented beside it. An isolated Linux rebuild from only
that archive passes1696upstream tests (0failures,0crashes,9environment skips),
65defined semantics cases and the existing shared-host callback probe.
Linux build recipes now read this archive instead of the temporary source tree;
the migrated shared-host recipe also builds successfully at exit0 in
`.omo/evidence/stable-linux-host-source`. The two migrated shell scripts pass
`bash -n`. This source recovery result does not assert identical compiler bytes.

The older Windows experimental scripts below retain their original temporary
paths and historical assumptions, including the former74/77wrapper comparison.
They are not a current one-command fresh Windows rebuild. Final runtime
acceptance uses the77-row actual Godot owner, as documented in
`docs/compatibility/ruby-compiler-verification.md`. Do not delete the original
Windows build trees until their remaining build dependencies are preserved.

The current archive build entry is `run_windows_archive.ps1 -Name <new-name>`.
It uses the installed Visual Studio 18 Community, Ruby/rake and xmake, fixes
xmake to Windows/x64, and leaves production DLLs untouched. Its recorded run
under `.omo/evidence/windows-archived-mruby-zipapi` passes 1661 upstream cases
with 0 failures, 0 crashes and 28 platform/debug skips, builds the shared DLL,
and passes all 65 defined semantics cases. The successful stages span the
initial static build and a shared-only continuation; older logs are retained.
The rebuilt DLL subsequently passes `probe_windows_archive.ps1` at exit 0:
StandardError offset 18800, state size 18864, all four production extension
initializers, and the existing combined Marshal/Regexp/Zlib/defined check.
Evidence is `.omo/evidence/windows-archived-mruby-abi/probe.log`.
The reconstructed DLL has not run Godot guest owners and is not deployed.

## Target & Base Commit
- Shared host mruby commit (unmodified): `831da26b9021de0369d17b71b5667e2941a1a32d` (`mruby 4.0.0 (2026-04-20)`)
- Pinned host ABI defines: `MRB_CORE`, `MRB_INT64`, `MRB_UTF8_STRING`, `MRB_USE_DEBUG_HOOK`, `MRB_LIB` (`visualcpp` x64, `/MD`)
- Verified `mrb_state` ABI layout: `offsetof(mrb_state, eStandardError_class) == 18800`, `sizeof(mrb_state) == 18864`, `MRB_METHOD_CACHE_SIZE == 256`, matching `Object` / `Class` / `String` / `Exception` / `StandardError` fields and all four Windows native extension DLLs (`libmruby_marshal_c_ext_x64.dll`, `libmruby_onig_regexp_ext_x64.dll`, `libmruby_dir_glob_ext_x64.dll`, `libmruby_zlib_ext_x64.dll`).

## Artifacts in `tools/defined-compiler/`
- `mruby-4.0.0-defined-compiler.source.patch` — reviewable 10-file source-only diff against `831da26b9021de0369d17b71b5667e2941a1a32d` (excludes generated `lex.def` and `y.tab.c`).
- `mruby-4.0.0-defined-compiler.full.patch` — complete 12-file buildable diff including regenerated `lex.def` (GNU `gperf 3.3`) and `y.tab.c` (bundled `lrama 0.7.0`, 0 new conflicts).
- `defined_yield_super_reference.rb` — 77-row shared RGSS300 + mruby reference fixture covering unevaluated `defined?(yield)`, `defined?(super)`, recursive array literal definedness (`NODE_ARRAY` / `NODE_ZARRAY` / `NODE_SPLAT`), escaped `super` closures rebound via `instance_exec` / `instance_eval` / `class_exec` across class/singleton/module methods, and `OnigRegexp` match globals (`$~`, `$&`, `` $` ``, `$'`, `$+`, `$1..$11`, lexical/method/define_method/closure scoping, and `$~ =` validation).
- `defined_yield_super_original.tsv` — authoritative 77-row TSV output produced by original `RGSS300.dll` (`Game.exe`, Ruby 1.9.2) on `defined_yield_super_reference.rb`.
- `test_defined_semantics.rb` — 65-case unevaluated semantics and side-effect contract suite.
- `extended_host_probe.c` — native C host harness linking the owned `libmruby_x64.dll`, asserting ABI offset `18800`, loading all 4 Windows extension DLLs, and running `defined_yield_super_reference.rb`, `tests/fixtures/ruby_runtime_reference.rb` (16/16), and `tests/fixtures/zlib_stream_reference.rb` (43/43).
- `build_and_verify.ps1` — reproducible end-to-end build & verification script operating strictly inside `.omo/compatibility-run-tmp/f05-defined-compiler/` (no production DLL deployment).

Preserved Milestone-1 and Milestone-2 baseline artifacts remain intact under `.omo/compatibility-run-tmp/f05-defined-compiler/milestone-1/` and `.omo/compatibility-run-tmp/f05-defined-compiler/milestone-2/`.

## Semantics Implemented
1. **Lexer & Grammar (`keywords`, `parse.y`)**
   - `defined?` registered in `keywords` as `{keyword_defined, keyword_defined}, EXPR_ARG` and included in `reswords` so `def defined?` and `:defined?` remain valid.
   - Precedence `%nonassoc keyword_defined` placed between `keyword_not` and `'=' tOP_ASGN` so `defined? $x += 1` parses as `defined?($x += 1)` and `defined? Object ? 1 : 2` parses as `(defined? Object) ? 1 : 2`.
   - Productions: `arg : keyword_defined opt_nl arg` and `primary : keyword_defined opt_nl '(' expr rparen'`, emitting `NODE_DEFINED`.

2. **Unevaluated Codegen & `OP_DEFINED` (`codegen.c`, `ops.h`, `vm.c`, `variable.c`, `state.c`, `kernel.c`, `codedump.c`, `internal.h`)**
   - Constants (`NODE_CONST`, `NODE_COLON3`, `NODE_COLON2`): lexical + inheritance lookup without triggering `const_missing` or `NameError`; returns `"constant"` even when value is `nil` or `false`, or `nil` when missing or when `NODE_COLON2` base raises / is not a Module/Class.
   - Methods (`NODE_CALL`): argument expressions are never evaluated; `FCALL` checks self's method table (including private/protected), `CALL` evaluates receiver once inside a rescue handler, checks public/protected visibility (`MRB_METHOD_PRIVATE_FL` / `MRB_METHOD_PROTECTED_FL` + `mrb_obj_is_kind_of`), falls back to `respond_to_missing?(sym, false)`, and handles `&.`.
   - Array literals (`NODE_ZARRAY`, `NODE_ARRAY` -> `codegen_defined_array`): recursively checks element definedness left-to-right without evaluating element values (`0` side effects), short-circuiting to `nil` on the first undefined element and short-circuiting immediately to `"expression"` upon encountering a splat element (`NODE_SPLAT`), matching Ruby 1.9.2 / RGSS300 (`14/14` rows).
   - Globals & lexical Regexp match globals (`NODE_GVAR`, `NODE_NTH_REF`, `NODE_BACK_REF` in `variable.c` + `vm.c` + `state.c`):
     - Ordinary globals check `mrb->globals` presence (distinguishing unset from `= nil`) -> `"global-variable"` or `nil`.
     - `$~` is tracked per lexical Ruby scope (`(mrb_context*, ci_idx)` for active `def` / `define_method` / class / top frames, promoted on `cipop` to `REnv*` when captured by closures, GC-marked in `mrb_gc_mark_gv`, and cleaned in `mrb_free_context` / `fiber_terminate` / `mrb_gc_free_gv`) with zero change to `sizeof(mrb_state)` (`18864`), `offsetof(mrb_state, eStandardError_class)` (`18800`), or `sizeof(struct REnv)`.
     - `defined?($~)` is always `"global-variable"` (even before any regex match or after `$~ = nil`). `$~ = val` validates `nil` or `OnigMatchData`/`MatchData` (raising `TypeError` otherwise) and syncs `OnigRegexp.@last_match`.
     - `$&`, `` $` ``, `$'`, `$+` (highest-indexed non-nil capture group `1..size-1`), and `$1..$N` (including `$10+`) derive both their values and `defined?` status dynamically from lexical `$~`, returning `"global-variable"` iff matched (non-nil) and `nil` on mismatch, unmatched optional group, or out-of-range index.
   - Instance / class / local variables (`NODE_IVAR`, `NODE_CVAR`, `NODE_LVAR`/`NODE_DVAR`/`NODE_NVAR`): `"instance-variable"`, `"class variable"`, `"local-variable"` without raising on unset `@@cvar`.
   - Assignments (`NODE_ASGN`, `NODE_OP_ASGN`, `NODE_MASGN`): RHS is never evaluated (`$runtime_defined_side_effect` stays `0`); variable/constant/op/multiple assignments return `"assignment"`; attribute/index assignments (`obj.attr = rhs`, `obj[k] = rhs`) check setter method existence (`attr=`, `[]=`) without evaluating index or RHS, returning `"method"` or `nil`.
   - `defined?(yield)` (`NODE_YIELD` -> `MRB_DEFINED_YIELD`): arguments are never evaluated (`$defined_ys_side_effects == 0`); inspects lexical `def` method scope (`MRB_PROC_SCOPE && MRB_PROC_STRICT && !MRB_PROC_ENVSET`) across direct calls, blocks, escaped closures (`env->stack[bidx]`), `eval`, and `define_method`.
   - `defined?(super)` (`NODE_SUPER`, `NODE_ZSUPER` -> `MRB_DEFINED_SUPER`): arguments are never evaluated (`$defined_ys_side_effects == 0`); resolves the lexical method ID (`mid`) and defining class/module (`CI_TARGET_CLASS` / `REnv`). For normal class (`MRB_TT_CLASS`) and singleton class (`MRB_TT_SCLASS`) methods, searches `target_class->super` directly even when an escaped closure is rebound via `instance_exec` / `instance_eval` / `class_exec` onto an unrelated receiver (`Unrel.new` or `123`). For module methods (`MRB_TT_ICLASS` / `MRB_TT_MODULE`), walks `mrb_class(mrb, self)`'s ancestor chain to locate the matching module `mt` and searches from `cl->super` (returning `nil` if `self` does not include that module or no ancestor defines `mid`), matching Ruby 1.9.2 / RGSS300 `vm_search_normal_superclass` (`14/14` rebound rows).

## Historical `RGSS/ext/onig_regexp.rb` Wrapper Gap

The current native String/Regexp entry points and Ruby aliases resolve this
earlier three-row gap. The actual `tests/test_defined_runtime.gd` owner passes
all 77 original rows. The diagnostic below describes the preserved pre-fix
wrapper state, not a current blocker.
- When loading unmodified `RGSS/ext/onig_regexp.rb`, **3 of the 77 rows** in `defined_yield_super_reference.rb` (`ROW 69: match-str-eqtilde`, `ROW 71: match-str-slice-bang`, `ROW 72: match-str-index`) differ from original RGSS300 because those `String` methods (`String#=~`, `OnigRegexp#=~`, `String#slice!`, `String#index`, `String#[]`, `String#[]=`) are pure-Ruby wrapper methods in `RGSS/ext/onig_regexp.rb` rather than C primitives:
  - Calling `OnigRegexp#match` inside a Ruby wrapper method writes `$~` to that wrapper method's Ruby `def` frame, which is popped when the wrapper returns, leaving the caller's lexical `$~` untouched.
  - By contrast, C-implemented `OnigRegexp#match` and `String#sub`/`gsub`/`scan` have no Ruby `def` frame and match RGSS300 directly (`ROW 65–68`, `ROW 70`, `ROW 73–76` all pass; executable comparison saved in `.omo/compatibility-run-tmp/f05-defined-compiler/output/wrapper-evidence/wrapper_gap_evidence.log`).
  - Additionally, `OnigRegexp.last_match` in `RGSS/ext/onig_regexp.rb:14` (`def self.last_match; @last_match; end`) has arity `0` (does not accept `Regexp.last_match(n)`) and reads class ivar `@last_match` rather than lexical `$~`.

## Remaining Architectural Notes
- **Bytecode `.mrb` wire format**: `OP_DEFINED` is inserted before `OP_DEBUG` in `include/mruby/ops.h`; precompiled `.mrb` blobs would require recompilation if deployed (RGSS-Godot compiles Ruby source from disk/Marshal at runtime and ships no `.mrb` files).
