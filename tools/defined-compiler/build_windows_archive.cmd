@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
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
