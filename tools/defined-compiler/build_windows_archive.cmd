@echo off
setlocal
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0..\test_paths.ps1'; Get-TestPath 'vs_devcmd'"`) do set "VCVARS=%%I"
if not defined VCVARS exit /b 1
call "%VCVARS%"
if errorlevel 1 exit /b %errorlevel%
if "%~2"=="shared" goto shared
cd /d "%~1\mruby"
if errorlevel 1 exit /b %errorlevel%
call rake MRUBY_CONFIG=../build_config_windows_archive.rb all test
if errorlevel 1 exit /b %errorlevel%
:shared
cd /d "%~1\mruby-shared"
if errorlevel 1 exit /b %errorlevel%
call xmake f -p windows -a x64 -m release -y
if errorlevel 1 exit /b %errorlevel%
call xmake build
exit /b %errorlevel%
