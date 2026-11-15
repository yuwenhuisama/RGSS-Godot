@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d E:/Projects/RGSS-Godot
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING /DMRB_USE_DEBUG_HOOK /I ".omo/compatibility-run-tmp/f05-defined-compiler/mruby/build/host-dll/include" "tools/defined-compiler/extended_host_probe.c" ".omo/compatibility-run-tmp/f05-defined-compiler/mruby-shared/build/windows/x64/release/libmruby_x64.lib" /Fe:".omo/compatibility-run-tmp/f05-defined-compiler/extended-host-stage/extended_host_probe.exe" /Fo:".omo/compatibility-run-tmp/f05-defined-compiler/extended-host-stage/extended_host_probe.obj"
exit /b %errorlevel%
