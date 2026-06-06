#include "mruby.h"
#include "mruby/value.h"
#include "mruby/string.h"

#include <stdlib.h>
#include <stdint.h>
#include <zlib.h>

#define WINDOW_BITS_DEFLATE 15
#define WINDOW_BITS_GZIP    (15 + 16)
#define WINDOW_BITS_AUTO    (15 + 16 + 16)

static void
mrb_zlib_raise(mrb_state *mrb, z_streamp strm, int err, int (*strmEnd)(z_streamp))
{
  char msg[256];

  snprintf(msg, sizeof(msg), "zlib error (%d): %s", err, strm->msg);
  if (strmEnd) {
    strmEnd(strm);
  }
  mrb_raise(mrb, E_RUNTIME_ERROR, msg);
}

static mrb_value
mrb_zlib_compress(mrb_state *mrb, mrb_value self, int windowbits)
{
  mrb_value data, arg;
  z_stream strm;
  int ret;

  strm.zalloc = Z_NULL;
  strm.zfree  = Z_NULL;
  strm.opaque = Z_NULL;

  mrb_get_args(mrb, "S", &arg);

  ret = deflateInit2(&strm, Z_DEFAULT_COMPRESSION,
      Z_DEFLATED, windowbits, 8, Z_DEFAULT_STRATEGY);
  if (ret != Z_OK){
    mrb_zlib_raise(mrb, &strm, ret, NULL);
  }

  data = mrb_str_buf_new(mrb, deflateBound(&strm, RSTRING_LEN(arg)));

  strm.next_in = (Bytef *) RSTRING_PTR(arg);
  strm.avail_in = RSTRING_LEN(arg);
  strm.next_out = (Bytef *) RSTRING_PTR(data);
  strm.avail_out = RSTRING_CAPA(data);

  while (1) {
    ret = deflate(&strm, Z_FINISH);
    if (ret == Z_OK) {
      data = mrb_str_resize(mrb, data, RSTRING_CAPA(data) * 2);
      strm.next_out = (Bytef *) RSTRING_PTR(data) + strm.total_out;
      strm.avail_out = RSTRING_CAPA(data) - strm.total_out;
    } else if (ret == Z_STREAM_END) {
      data = mrb_str_resize(mrb, data, strm.total_out);
      ret = deflateEnd(&strm);
      if (ret != Z_OK) {
        mrb_zlib_raise(mrb, &strm, ret, NULL);
      }
      break;
    } else {
      mrb_zlib_raise(mrb, &strm, ret, deflateEnd);
    }
  }

  return data;
}

static mrb_value
mrb_zlib_deflate(mrb_state *mrb, mrb_value self)
{
  return mrb_zlib_compress(mrb, self, WINDOW_BITS_DEFLATE);
}

static mrb_value
mrb_zlib_gzip(mrb_state *mrb, mrb_value self)
{
  return mrb_zlib_compress(mrb, self, WINDOW_BITS_GZIP);
}

static mrb_value
mrb_zlib_inflate(mrb_state *mrb, mrb_value self)
{
  mrb_value data, arg;
  z_stream strm;
  int ret;

  strm.zalloc = Z_NULL;
  strm.zfree  = Z_NULL;
  strm.opaque = Z_NULL;

  mrb_get_args(mrb, "S", &arg);

  strm.next_in = (Bytef *) RSTRING_PTR(arg);
  strm.avail_in = RSTRING_LEN(arg);

  ret = inflateInit2(&strm, WINDOW_BITS_AUTO);
  if (ret != Z_OK) {
    mrb_zlib_raise(mrb, &strm, ret, NULL);
  }

  data = mrb_str_buf_new(mrb, RSTRING_LEN(arg) * 2);
  strm.next_out = (Bytef *) RSTRING_PTR(data);
  strm.avail_out = RSTRING_CAPA(data);

  while (1) {
    ret = inflate(&strm, Z_NO_FLUSH);
    if (ret == Z_OK) {
      data = mrb_str_resize(mrb, data, RSTRING_CAPA(data) * 2);
      strm.next_out = (Bytef *) RSTRING_PTR(data) + strm.total_out;
      strm.avail_out = RSTRING_CAPA(data) - strm.total_out;
    } else if (ret == Z_STREAM_END) {
      data = mrb_str_resize(mrb, data, strm.total_out);
      ret = inflateEnd(&strm);
      if (ret != Z_OK) {
        mrb_zlib_raise(mrb, &strm, ret, NULL);
      }
      break;
    } else {
      mrb_zlib_raise(mrb, &strm, ret, inflateEnd);
    }
  }

  return data;
}

static mrb_value
mrb_zlib_crc32(mrb_state *mrb, mrb_value self)
{
  mrb_value data;
  mrb_value strcrc = mrb_nil_value();
  mrb_value strcrc_new;
  uLong crc = 0L;
  uint8_t *ptr = NULL;
  int nargs;

  nargs = mrb_get_args(mrb, "S|S", &data, &strcrc);
  if (nargs < 2) {
    crc = crc32(0L, Z_NULL, 0);
  } else {
    if (RSTRING_LEN(strcrc) != 4) {
      mrb_raise(mrb, E_RUNTIME_ERROR, "crc.size must be 4");
    } else {
      ptr = (uint8_t *) RSTRING_PTR(strcrc);
      crc = (ptr[0] << 24) |
            (ptr[1] << 16) |
            (ptr[2] << 8) |
            (ptr[3]);
    }
  }

  crc = crc32(crc, (Bytef *) RSTRING_PTR(data), (uInt) RSTRING_LEN(data));
  strcrc_new = mrb_str_new(mrb, "\0\0\0\0", 4);
  ptr = (uint8_t *) RSTRING_PTR(strcrc_new);
  ptr[0] = (crc & 0xff000000) >> 24;
  ptr[1] = (crc & 0x00ff0000) >> 16;
  ptr[2] = (crc & 0x0000ff00) >> 8;
  ptr[3] = (crc & 0x000000ff);
  return strcrc_new;
}

void
mrb_mruby_zlib_gem_init(mrb_state *mrb)
{
  struct RClass *zlib;

  zlib = mrb_define_module(mrb, "Zlib");
  mrb_define_module_function(mrb, zlib, "deflate", mrb_zlib_deflate, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, zlib, "gzip", mrb_zlib_gzip, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, zlib, "inflate", mrb_zlib_inflate, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, zlib, "crc32", mrb_zlib_crc32, MRB_ARGS_REQ(1));
}

void
mrb_mruby_zlib_gem_final(mrb_state *mrb)
{
}
