add_rules("mode.debug", "mode.releasedbg")

local os_name = os.host()
local mruby_dir = os.getenv("MRUBY_DIR") or "E:/Projects/mruby-for-dotnet/mruby"
local ext_base_name = "mruby_onig_regexp"
local gem_name = "mruby-onig-regexp"

-- Inline the vendored Onigmo regex engine sources (mirrors how the zlib gem
-- inlines zlib-1.3.1). On Linux/macOS we compile Onigmo INTO the gem so the
-- engine automatically follows xmake's per-arch flags (x86_64 + arm64) and the
-- macOS universal lipo just works -- no Homebrew, no external universal archive.
-- File list is the authoritative libonigmo_la_SOURCES from Onigmo/Makefile.am
-- (NOT enc/*.c: that would wrongly pull in mktable.c generator + Ruby-only
-- encodings gb2312.c/gbk.c/cp949.c/emacs_mule.c/us_ascii.c).
function add_onigmo_sources()
    add_includedirs("Onigmo")
    add_includedirs("Onigmo/enc/unicode")

    add_files(
        "Onigmo/regerror.c",
        "Onigmo/regparse.c",
        "Onigmo/regext.c",
        "Onigmo/regcomp.c",
        "Onigmo/regexec.c",
        "Onigmo/reggnu.c",
        "Onigmo/regenc.c",
        "Onigmo/regsyntax.c",
        "Onigmo/regtrav.c",
        "Onigmo/regversion.c",
        "Onigmo/st.c",
        "Onigmo/regposix.c",
        "Onigmo/regposerr.c",

        "Onigmo/enc/unicode.c",
        "Onigmo/enc/ascii.c",
        "Onigmo/enc/utf_8.c",
        "Onigmo/enc/utf_16be.c",
        "Onigmo/enc/utf_16le.c",
        "Onigmo/enc/utf_32be.c",
        "Onigmo/enc/utf_32le.c",
        "Onigmo/enc/euc_jp.c",
        "Onigmo/enc/shift_jis.c",
        "Onigmo/enc/windows_31j.c",

        "Onigmo/enc/iso_8859_1.c",
        "Onigmo/enc/iso_8859_2.c",
        "Onigmo/enc/iso_8859_3.c",
        "Onigmo/enc/iso_8859_4.c",
        "Onigmo/enc/iso_8859_5.c",
        "Onigmo/enc/iso_8859_6.c",
        "Onigmo/enc/iso_8859_7.c",
        "Onigmo/enc/iso_8859_8.c",
        "Onigmo/enc/iso_8859_9.c",
        "Onigmo/enc/iso_8859_10.c",
        "Onigmo/enc/iso_8859_11.c",
        "Onigmo/enc/iso_8859_13.c",
        "Onigmo/enc/iso_8859_14.c",
        "Onigmo/enc/iso_8859_15.c",
        "Onigmo/enc/iso_8859_16.c",

        "Onigmo/enc/euc_tw.c",
        "Onigmo/enc/euc_kr.c",
        "Onigmo/enc/big5.c",
        "Onigmo/enc/gb18030.c",
        "Onigmo/enc/koi8_r.c",
        "Onigmo/enc/koi8_u.c",
        "Onigmo/enc/windows_1250.c",
        "Onigmo/enc/windows_1251.c",
        "Onigmo/enc/windows_1252.c",
        "Onigmo/enc/windows_1253.c",
        "Onigmo/enc/windows_1254.c",
        "Onigmo/enc/windows_1257.c"
    )
end

function common_settings()
    set_arch("x64")
    set_kind("shared")

    add_includedirs(mruby_dir .. "/build/host/include/")
    add_includedirs("Onigmo/")
    add_files(gem_name .. "/src/*.c")

    add_defines("MRB_INT64", "MRB_NO_PRESYM", "MRB_UTF8_STRING")
    add_defines("HAVE_ONIGMO_H")

    add_host_mruby_link()
end

-- Link the prebuilt host mruby library. On Linux/macOS the gem .so/.dylib has a
-- transitive NEEDED dependency on libmruby_x64; link it by NAME (not by path) so
-- the recorded dependency is the bare soname, and embed an $ORIGIN/@loader_path
-- rpath so the loader finds the host lib sitting next to the gem in Plugins/<os>/.
-- Windows keeps the prebuilt .lib import (PATH-based dependency lookup). On
-- Linux/macOS Onigmo is inlined (add_onigmo_sources), so no onig lib is linked.
function add_host_mruby_link()
    if is_plat("windows") then
        add_links("lib/libmruby_x64.lib")
        add_links("lib/onigmo_s.lib")
    elseif is_plat("linux") then
        add_linkdirs(path.join(os.projectdir(), "lib"))
        add_links("mruby_x64")
        add_rpathdirs("$ORIGIN")
    elseif is_plat("macosx") then
        add_linkdirs(path.join(os.projectdir(), "lib"))
        add_links("mruby_x64")
        add_rpathdirs("@loader_path")
    end
end

function after_build_macos(target)
    local mode = is_mode("debug") and "debug" or "release"
    local output_dir = path.join(os.projectdir(), string.format("build/macosx/universal/%s/", mode))
    os.exec("mkdir -p %s", output_dir)
    os.exec("lipo -create -output %s %s %s", 
            path.join(output_dir, "lib" .. ext_base_name .. "_ext_x64.dylib"), 
            path.join(os.projectdir(), string.format("build/macosx/arm64/%s/lib" .. ext_base_name.. "_ext_arm64.dylib", mode)), 
            path.join(os.projectdir(), string.format("build/macosx/x86_64/%s/lib".. ext_base_name .. "_ext_x86_64.dylib", mode)))
end

target(ext_base_name .. "_ext_x64")
    if os_name == "windows" then
        common_settings()

        -- Windows keeps the known-good prebuilt onigmo_s.lib (build_nmake +
        -- win32/config.h). Do NOT inline Onigmo here without ONIG_EXTERN=extern.
        add_files("export.def")
        set_basename("lib" .. ext_base_name .. "_ext_x64")
    elseif os_name == "linux" then
        common_settings()
        add_onigmo_sources()

        set_basename(ext_base_name .. "_ext_x64")
    elseif os_name == "macosx" then
        -- On macOS the public _ext_x64 target is only an alias for the universal
        -- dylib build; without this it defaults to a binary target and fails to
        -- link (no _main). Make it a phony that depends on the universal target.
        set_kind("phony")
        add_deps(ext_base_name .. "_ext_universal")

        -- Build for x86_64
        target(ext_base_name .. "_ext_x86_64")
            common_settings()
            add_onigmo_sources()

            set_basename(ext_base_name .. "_ext_x86_64")
            set_arch("x86_64")

        target(ext_base_name .. "_ext_arm64")
            common_settings()
            add_onigmo_sources()

            set_basename(ext_base_name .. "_ext_arm64")
            set_arch("arm64")

            -- Combine into a universal binary
        target(ext_base_name .. "_ext_universal")
            set_kind("phony")
            add_deps(ext_base_name .. "_ext_x86_64", ext_base_name .. "_ext_arm64")
            after_build(after_build_macos)
    else
        -- error: not support platform
        print("unsupported platform")
    end
