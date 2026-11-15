#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/variable.h>
#include <stdio.h>

void mrb_mruby_zlib_gem_init(mrb_state *mrb);

int main(int argc, char **argv)
{
  if (argc != 2) return 2;
  mrb_state *mrb = mrb_open();
  if (!mrb || mrb->exc) return 1;
  mrb_mruby_zlib_gem_init(mrb);
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$gzip_reference_host"), mrb_true_value());
  FILE *file = fopen(argv[1], "rb");
  if (!file) { mrb_close(mrb); return 2; }
  mrb_load_file(mrb, file);
  fclose(file);
  int failed = mrb->exc != NULL;
  if (failed) mrb_print_error(mrb);
  mrb_close(mrb);
  if (failed) return 1;
  puts("LINUX_ZLIB_FIXTURE_EXECUTED");
  return 0;
}
