#include "main.h"
#include <mruby/compile.h>
#include <stdio.h>
#include <string.h>

static uint64_t
dispatch(mrb_state *mrb, uint64_t self, int64_t id, int64_t argc,
    const uint64_t *argv, mrb_bool *raise, char *message, int32_t size)
{
  (void)self;
  if (id == 2) {
    *raise = TRUE;
    snprintf(message, (size_t)size, "linux callback error");
    return mrb_nil_value().w;
  }
  if (id != 1 || argc != 1) {
    *raise = TRUE;
    snprintf(message, (size_t)size, "unexpected callback arguments");
    return mrb_nil_value().w;
  }
  mrb_value value;
  value.w = argv[0];
  return mrb_int_value(mrb, mrb_as_int(mrb, value) + 1).w;
}

int main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb || mrb_open_failure_p(mrb)) return 1;
  mrbdotnet_set_dispatcher(dispatch);
  struct RClass *klass = mrb_define_class(mrb, "LinuxCallbackProbe", mrb->object_class);
  mrbdotnet_define_class_method_id(mrb, klass, mrb_intern_lit(mrb, "increment"), 1, MRB_ARGS_REQ(1));
  mrbdotnet_define_class_method_id(mrb, klass, mrb_intern_lit(mrb, "fail"), 2, MRB_ARGS_NONE());
  mrb_value result = mrb_load_string(mrb,
    "raise 'defined mismatch' unless defined?(Object) == 'constant'; "
    "raise 'callback result' unless LinuxCallbackProbe.increment(41) == 42; "
    "begin; LinuxCallbackProbe.fail; raise 'missing error'; "
    "rescue RuntimeError => e; raise 'wrong error' unless e.message == 'linux callback error'; end; "
    "raise 'recovery' unless LinuxCallbackProbe.increment(2) == 3; true");
  int failed = mrb->exc != NULL || !mrb_test(result);
  if (mrb->exc) mrb_print_error(mrb);
  mrb_close(mrb);
  if (failed) return 1;
  puts("LINUX_SHARED_CALLBACK_PASS");
  return 0;
}
