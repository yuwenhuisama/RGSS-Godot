/*
 * config.h for Onigmo on Unix-like 64-bit platforms (Linux + macOS x86_64/arm64).
 *
 * Onigmo's autotools build normally generates this via ./configure. For the
 * vendored cross-platform xmake build we compile Onigmo's sources INLINE into
 * the mruby_onig_regexp gem (mirroring how the zlib gem inlines zlib-1.3.1),
 * so we ship a minimal hand-written config.h instead of running ./configure.
 *
 * Valid for LP64 Unix targets (Linux x86_64, macOS x86_64 and arm64).
 * Windows uses win32/config.h via build_nmake (unchanged).
 */
#ifndef ONIGMO_CONFIG_H
#define ONIGMO_CONFIG_H

#define PACKAGE "onigmo"
#define PACKAGE_NAME "onigmo"
#define PACKAGE_VERSION "6.2.0"
#define PACKAGE_STRING "onigmo 6.2.0"
#define PACKAGE_TARNAME "onigmo"
#define VERSION "6.2.0"

#define STDC_HEADERS 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_MEMORY_H 1
#define HAVE_STRINGS_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_UNISTD_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TIMES_H 1
#define TIME_WITH_SYS_TIME 1
#define HAVE_ALLOCA 1

#define SIZEOF_INT 4
#define SIZEOF_SHORT 2
#define SIZEOF_LONG 8
#define SIZEOF_LONG_LONG 8
#define SIZEOF_VOIDP 8

#endif /* ONIGMO_CONFIG_H */
