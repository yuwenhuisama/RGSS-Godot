#include <stdio.h>
#include <stddef.h>
#include "mruby.h"
#include "mruby/class.h"

int main(void)
{
  mrb_state *mrb = mrb_open();
  struct RClass *expected = mrb_class_get(mrb, "StandardError");
  printf("ABI_STANDARD_ERROR:header_offset=%zu:field_matches=%d\n",
      offsetof(mrb_state, eStandardError_class), mrb->eStandardError_class == expected);
  size_t found = (size_t)-1;
  for (size_t offset = 0; offset <= offsetof(mrb_state, eStandardError_class); offset += sizeof(void *)) {
    if (*(void **)((char *)mrb + offset) == expected) {
      found = offset;
      break;
    }
  }
  printf("ABI_STANDARD_ERROR_ACTUAL_OFFSET:%zu\n", found);
  printf("ABI_METHOD_CACHE_SIZE:%d\n", MRB_METHOD_CACHE_SIZE);
  printf("ABI_CLASS_FIELDS:Object=%d:Class=%d:String=%d:Exception=%d\n",
      mrb->object_class == mrb_class_get(mrb, "Object"),
      mrb->class_class == mrb_class_get(mrb, "Class"),
      mrb->string_class == mrb_class_get(mrb, "String"),
      mrb->eException_class == mrb_class_get(mrb, "Exception"));
  printf("ABI_OFFSET_DELTAS:gc=%zu:cache=%zu:exception=%zu:state=%zu\n",
      offsetof(mrb_state,gc),offsetof(mrb_state,cache),offsetof(mrb_state,eException_class),sizeof(mrb_state));
  mrb_close(mrb);
  return 0;
}
