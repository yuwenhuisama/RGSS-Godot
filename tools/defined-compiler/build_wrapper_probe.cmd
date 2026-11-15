@echo off
setlocal
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0..\test_paths.ps1'; Get-TestPath 'vs_devcmd'"`) do set "VCVARS=%%I"
if not defined VCVARS exit /b 1
call "%VCVARS%"
if errorlevel 1 exit /b %errorlevel%
cd /d "%~dp0..\.."
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING /DMRB_USE_DEBUG_HOOK /I ".omo/compatibility-run-tmp/f05-defined-compiler/mruby/build/host-dll/include" "tools/defined-compiler/extended_host_probe.c" ".omo/compatibility-run-tmp/f05-defined-compiler/mruby-shared/build/windows/x64/release/libmruby_x64.lib" /Fe:".omo/compatibility-run-tmp/f05-defined-compiler/extended-host-stage/extended_host_probe.exe" /Fo:".omo/compatibility-run-tmp/f05-defined-compiler/extended-host-stage/extended_host_probe.obj"
exit /b %errorlevel%
