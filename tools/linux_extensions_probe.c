#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <stdio.h>

void mrb_mruby_zlib_gem_init(mrb_state *mrb);
void mrb_mruby_marshal_c_gem_init(mrb_state *mrb);
void mrb_mruby_dir_glob_gem_init(mrb_state *mrb);
void mrb_mruby_onig_regexp_gem_init(mrb_state *mrb);

static int load_file(mrb_state *mrb, const char *path)
{
  FILE *file = fopen(path, "rb");
  if (!file) return 0;
  mrb_load_file(mrb, file);
  fclose(file);
  if (mrb->exc) { mrb_print_error(mrb); return 0; }
  return 1;
}

int main(int argc, char **argv)
{
  if (argc != 3) return 2;
  mrb_state *mrb = mrb_open();
  if (!mrb || mrb->exc) return 1;
  mrb_mruby_marshal_c_gem_init(mrb);
  mrb_mruby_zlib_gem_init(mrb);
  mrb_mruby_dir_glob_gem_init(mrb);
  mrb_mruby_onig_regexp_gem_init(mrb);
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$rgss_compat_output"), mrb_str_new_cstr(mrb, "."));
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$ruby_runtime_host"), mrb_true_value());
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$marshal_values_host"), mrb_true_value());
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$zlib_stream_host"), mrb_true_value());
  int ok = load_file(mrb, argv[1]);
  if (ok) {
    mrb_load_string(mrb, "module Kernel; module_function :eval; end");
    ok = mrb->exc == NULL && load_file(mrb, argv[2]);
  }
  mrb_close(mrb);
  if (!ok) return 1;
  puts("LINUX_FOUR_EXTENSIONS_FIXTURE_EXECUTED");
  return 0;
}
