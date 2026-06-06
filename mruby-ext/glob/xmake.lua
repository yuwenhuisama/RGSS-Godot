add_rules("mode.debug", "mode.releasedbg")

local os_name = os.host()
local mruby_dir = os.getenv("MRUBY_DIR") or "E:/Projects/mruby-for-dotnet/mruby"
local ext_base_name = "mruby_dir_glob"
local gem_name = "mruby-dir-glob"

function common_settings()
    set_arch("x64")
    set_kind("shared")

    add_includedirs(gem_name .. "/include/")
    add_includedirs(mruby_dir .. "/build/host/include/")
    add_files(gem_name .. "/src/*.c")

    add_defines("MRB_INT64", "MRB_NO_PRESYM", "MRB_UTF8_STRING")

    add_host_mruby_link()
end

-- Link the prebuilt host mruby library. On Linux/macOS the gem .so/.dylib has a
-- transitive NEEDED dependency on libmruby_x64; link it by NAME (not by path) so
-- the recorded dependency is the bare soname, and embed an $ORIGIN/@loader_path
-- rpath so the loader finds the host lib sitting next to the gem in Plugins/<os>/.
-- Windows keeps the prebuilt .lib import (PATH-based dependency lookup).
function add_host_mruby_link()
    if is_plat("windows") then
        add_links("lib/libmruby_x64.lib")
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

        add_files("export.def")
        set_basename("lib" .. ext_base_name .. "_ext_x64")
    elseif os_name == "linux" then
        common_settings()

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

            set_basename(ext_base_name .. "_ext_x86_64")
            set_arch("x86_64")

        target(ext_base_name .. "_ext_arm64")
            common_settings()

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