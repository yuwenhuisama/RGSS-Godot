#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include "mruby.h"
#include "mruby/class.h"
#include "mruby/compile.h"
#include "mruby/string.h"
#include "mruby/variable.h"

typedef void (*gem_init_fn)(mrb_state *);

static mrb_value
unity_file_symlink_p(mrb_state *mrb, mrb_value self)
{
  const char *path = NULL;
  mrb_get_args(mrb, "z", &path);
  int wlen = MultiByteToWideChar(CP_UTF8, 0, path, -1, NULL, 0);
  if (wlen <= 0) return mrb_false_value();
  WCHAR *wpath = (WCHAR *)malloc((size_t)wlen * sizeof(WCHAR));
  if (!wpath) return mrb_false_value();
  MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, wlen);
  WIN32_FIND_DATAW data;
  HANDLE h = FindFirstFileW(wpath, &data);
  free(wpath);
  if (h == INVALID_HANDLE_VALUE) return mrb_false_value();
  mrb_bool is_sym = ((data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0 &&
                     data.dwReserved0 == 0xA000000C);
  FindClose(h);
  return mrb_bool_value(is_sym);
}

static int
init_ext_dll(mrb_state *mrb, const char *dll_name, const char *sym_name)
{
  HMODULE mod = LoadLibraryA(dll_name);
  if (!mod) {
    fprintf(stderr, "EXT_LOAD_FAIL:%s:err=%lu\n", dll_name, GetLastError());
    return 0;
  }
  gem_init_fn fn = (gem_init_fn)GetProcAddress(mod, sym_name);
  if (!fn) {
    fprintf(stderr, "EXT_SYM_FAIL:%s:%s:err=%lu\n", dll_name, sym_name, GetLastError());
    return 0;
  }
  fn(mrb);
  if (mrb->exc) {
    mrb_print_error(mrb);
    return 0;
  }
  printf("EXT_INIT_OK:%s:%s\n", dll_name, sym_name);
  return 1;
}

static int
eval_file(mrb_state *mrb, const char *path)
{
  FILE *fp = fopen(path, "rb");
  if (!fp) {
    fprintf(stderr, "FILE_OPEN_FAIL:%s\n", path);
    return 0;
  }
  mrb_ccontext *cxt = mrb_ccontext_new(mrb);
  mrb_ccontext_filename(mrb, cxt, path);
  mrb_load_detect_file_cxt(mrb, fp, cxt);
  mrb_ccontext_free(mrb, cxt);
  fclose(fp);
  if (mrb->exc) {
    mrb_print_error(mrb);
    return 0;
  }
  return 1;
}

static int
eval_cstr_expect_true(mrb_state *mrb, const char *label, const char *code)
{
  mrb_ccontext *cxt = mrb_ccontext_new(mrb);
  mrb_ccontext_filename(mrb, cxt, label);
  mrb_value v = mrb_load_string_cxt(mrb, code, cxt);
  mrb_ccontext_free(mrb, cxt);
  if (mrb->exc) {
    fprintf(stderr, "HOST_CHECK_EXC:%s\n", label);
    mrb_print_error(mrb);
    return 0;
  }
  if (!mrb_test(v)) {
    fprintf(stderr, "HOST_CHECK_FALSE:%s\n", label);
    return 0;
  }
  printf("HOST_CHECK_OK:%s\n", label);
  return 1;
}

int
main(int argc, char **argv)
{
  const char *rgss_dir = (argc > 1) ? argv[1] : "E:/Projects/RGSS-Godot/RGSS";
  const char *out_dir  = (argc > 2) ? argv[2] : ".";
  const char *ys_ref   = (argc > 3) ? argv[3] : NULL;
  const char *rt_ref   = (argc > 4) ? argv[4] : NULL;
  const char *ext_ref  = (argc > 5) ? argv[5] : NULL;
  const char *zlib_ref = (argc > 6) ? argv[6] : NULL;

  mrb_state *mrb = mrb_open();
  if (!mrb) {
    fprintf(stderr, "MRB_OPEN_NULL\n");
    return 1;
  }

  /* 1. Verify exact mrb_state ABI offsets with MRB_USE_DEBUG_HOOK */
  struct RClass *expected_se = mrb_class_get(mrb, "StandardError");
  size_t header_off = offsetof(mrb_state, eStandardError_class);
  int se_matches = (mrb->eStandardError_class == expected_se);
  size_t actual_off = (size_t)-1;
  for (size_t off = 0; off <= header_off + 64; off += sizeof(void *)) {
    if (*(void **)((char *)mrb + off) == expected_se) {
      actual_off = off;
      break;
    }
  }
  int obj_ok = (mrb->object_class == mrb_class_get(mrb, "Object"));
  int cls_ok = (mrb->class_class == mrb_class_get(mrb, "Class"));
  int str_ok = (mrb->string_class == mrb_class_get(mrb, "String"));
  int exc_ok = (mrb->eException_class == mrb_class_get(mrb, "Exception"));

  printf("ABI_STANDARD_ERROR:header_offset=%zu:field_matches=%d\n", header_off, se_matches);
  printf("ABI_STANDARD_ERROR_ACTUAL_OFFSET:%zu\n", actual_off);
  printf("ABI_METHOD_CACHE_SIZE:%d\n", MRB_METHOD_CACHE_SIZE);
  printf("ABI_CLASS_FIELDS:Object=%d:Class=%d:String=%d:Exception=%d\n", obj_ok, cls_ok, str_ok, exc_ok);
  printf("ABI_OFFSET_DELTAS:gc=%zu:cache=%zu:exception=%zu:state=%zu\n",
      offsetof(mrb_state, gc), offsetof(mrb_state, cache), offsetof(mrb_state, eException_class), sizeof(mrb_state));

  if (header_off != 18800 || actual_off != 18800 || !se_matches || !obj_ok || !cls_ok || !str_ok || !exc_ok) {
    fprintf(stderr, "ABI_MISMATCH_FAILURE\n");
    mrb_close(mrb);
    return 2;
  }

  /* 2. Load and initialize all 4 rebuilt Windows native extension DLLs */
  if (!init_ext_dll(mrb, "libmruby_marshal_c_ext_x64.dll", "mrb_mruby_marshal_c_gem_init") ||
      !init_ext_dll(mrb, "libmruby_onig_regexp_ext_x64.dll", "mrb_mruby_onig_regexp_gem_init") ||
      !init_ext_dll(mrb, "libmruby_dir_glob_ext_x64.dll", "mrb_mruby_dir_glob_gem_init") ||
      !init_ext_dll(mrb, "libmruby_zlib_ext_x64.dll", "mrb_mruby_zlib_gem_init")) {
    mrb_close(mrb);
    return 3;
  }

  /* 3. Register Unity.file_symlink? and load RGSS/ext Ruby shims used by the Godot runtime */
  struct RClass *unity_mod = mrb_define_module(mrb, "Unity");
  mrb_define_class_method(mrb, unity_mod, "file_symlink?", unity_file_symlink_p, MRB_ARGS_REQ(1));

  char shim_path[1024];
  snprintf(shim_path, sizeof(shim_path), "%s/ext/onig_regexp.rb", rgss_dir);
  if (!eval_file(mrb, shim_path)) { mrb_close(mrb); return 4; }
  snprintf(shim_path, sizeof(shim_path), "%s/ext/dir_glob.rb", rgss_dir);
  if (!eval_file(mrb, shim_path)) { mrb_close(mrb); return 4; }
  snprintf(shim_path, sizeof(shim_path), "%s/ext/dir.rb", rgss_dir);
  if (!eval_file(mrb, shim_path)) { mrb_close(mrb); return 4; }

  /* 4. Exercise Marshal, Onigmo Regexp, Dir.glob, Zlib, and defined? together */
  const char *combined_check =
    "$ext_side = 0\n"
    "payload = Marshal.load(Marshal.dump({ :k => [1, 'two', :three] }))\n"
    "comp = Zlib::Inflate.inflate(Zlib::Deflate.deflate('rgss-abi-ok'))\n"
    "rx = /(?<=ab)cd/.match('abcd')[0]\n"
    "defined?(Marshal) == 'constant' &&\n"
    "defined?(Zlib::Deflate) == 'constant' &&\n"
    "defined?(OnigRegexp) == 'constant' &&\n"
    "defined?(Zlib::NoSuchConst) == nil &&\n"
    "payload[:k][1] == 'two' &&\n"
    "comp == 'rgss-abi-ok' &&\n"
    "rx == 'cd' &&\n"
    "Zlib::BufError < StandardError &&\n"
    "defined?(yield($ext_side += 1)) == nil &&\n"
    "defined?(super($ext_side += 1)) == nil &&\n"
    "$ext_side == 0\n";
  if (!eval_cstr_expect_true(mrb, "combined_extensions_and_defined", combined_check)) {
    mrb_close(mrb);
    return 5;
  }

  /* 5. Run optional shared fixtures inside the extended host DLL VM */
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$ruby_runtime_host"), mrb_true_value());
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$native_extensions_host"), mrb_true_value());
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$zlib_stream_host"), mrb_true_value());
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$rgss_compat_output"), mrb_str_new_cstr(mrb, out_dir));
  if (!eval_cstr_expect_true(mrb, "kernel_eval_modfunc", "module Kernel; module_function :eval; end; true")) {
    mrb_close(mrb);
    return 5;
  }

  if (ys_ref && strlen(ys_ref) > 0) {
    mrb_gv_set(mrb, mrb_intern_lit(mrb, "$~"), mrb_nil_value());
    if (!eval_file(mrb, ys_ref)) { mrb_close(mrb); return 6; }
    printf("HOST_FIXTURE_OK:defined_yield_super_reference\n");
  }
  if (rt_ref && strlen(rt_ref) > 0) {
    /* Provide UTF-8 / ASCII-8BIT force_encoding compatibility shim matching RGSS runtime prelude */
    const char *enc_prelude =
      "class String\n"
      "  unless method_defined?(:force_encoding)\n"
      "    def force_encoding(enc)\n"
      "      @__enc__ = enc.to_s.upcase\n"
      "      self\n"
      "    end\n"
      "    alias __orig_len__ length\n"
      "    def length\n"
      "      (@__enc__ == 'ASCII-8BIT' || @__enc__ == 'BINARY') ? bytesize : __orig_len__\n"
      "    end\n"
      "  end\n"
      "end\n"
      "module Enumerable\n"
      "  alias __orig_sort__ sort if method_defined?(:sort)\n"
      "end\n"
      "class Array\n"
      "  alias __orig_ary_sort__ sort\n"
      "  def sort(&blk)\n"
      "    return __orig_ary_sort__ unless blk\n"
      "    __orig_ary_sort__ { |a, b| r = blk.call(a, b); r < 0 ? -1 : (r > 0 ? 1 : 0) }\n"
      "  end\n"
      "end\n";
    if (!eval_cstr_expect_true(mrb, "rt_prelude", enc_prelude) && mrb->exc) {
      mrb_close(mrb);
      return 7;
    }
    if (!eval_file(mrb, rt_ref)) { mrb_close(mrb); return 7; }
    printf("HOST_FIXTURE_OK:ruby_runtime_reference\n");
  }
  if (ext_ref && strlen(ext_ref) > 0) {
    if (!eval_file(mrb, ext_ref)) { mrb_close(mrb); return 8; }
    printf("HOST_FIXTURE_OK:native_extensions_reference\n");
  }
  if (zlib_ref && strlen(zlib_ref) > 0) {
    if (!eval_file(mrb, zlib_ref)) { mrb_close(mrb); return 9; }
    printf("HOST_FIXTURE_OK:zlib_stream_reference\n");
  }

  mrb_close(mrb);
  printf("EXTENDED_HOST_PROBE_PASS\n");
  return 0;
}
