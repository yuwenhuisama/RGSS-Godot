@echo off
setlocal
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0..\test_paths.ps1'; Get-TestPath 'vs_devcmd'"`) do set "VCVARS=%%I"
if not defined VCVARS exit /b 1
call "%VCVARS%"
if errorlevel 1 exit /b %errorlevel%
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING /DMRB_USE_DEBUG_HOOK /I "%~1\mruby\build\host-dll\include" "%~dp0extended_host_probe.c" "%~1\mruby-shared\build\windows\x64\release\libmruby_x64.lib" /Fe:"%~2\extended_host_probe.exe" /Fo:"%~2\extended_host_probe.obj"
exit /b %errorlevel%
