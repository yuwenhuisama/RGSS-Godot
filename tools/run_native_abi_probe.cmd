@echo off
setlocal
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0test_paths.ps1'; Get-TestPath 'vs_devcmd'"`) do set "VCVARS=%%I"
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0test_paths.ps1'; Get-TestPath 'mruby_source'"`) do set "MRUBY_SOURCE=%%I"
if not defined VCVARS exit /b 1
if not defined MRUBY_SOURCE exit /b 1
call "%VCVARS%"
if errorlevel 1 exit /b %errorlevel%
cd /d "%~dp0.."
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING %* /I "%MRUBY_SOURCE%\build\host\include" tools\native-abi-probe.c mruby-ext\lib\libmruby_x64.lib /Fe:.omo\compatibility-run-tmp\native-abi-probe.exe /Fo:.omo\compatibility-run-tmp\native-abi-probe.obj
if errorlevel 1 exit /b %errorlevel%
copy /y Plugins\windows\libmruby_x64.dll .omo\compatibility-run-tmp\libmruby_x64.dll
if errorlevel 1 exit /b %errorlevel%
.omo\compatibility-run-tmp\native-abi-probe.exe
exit /b %errorlevel%
