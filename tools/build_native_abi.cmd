@echo off
setlocal
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command ". '%~dp0test_paths.ps1'; Get-TestPath 'mruby_source'"`) do set "MRUBY_DIR=%%I"
if not defined MRUBY_DIR exit /b 1
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0test_paths.ps1'; Get-TestPath 'vs_devcmd'"`) do set "VCVARS=%%I"
if not defined VCVARS exit /b 1
call "%VCVARS%"
if errorlevel 1 exit /b %errorlevel%
cd /d "%~dp0..\mruby-ext"
if errorlevel 1 exit /b %errorlevel%
xmake f -o build -p windows -a x64 --toolchain=msvc --cc=cl --cxx=cl --ld=link --sh=link
if errorlevel 1 exit /b %errorlevel%
xmake build -r -vD
exit /b %errorlevel%
