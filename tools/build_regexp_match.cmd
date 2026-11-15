@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d E:/Projects/RGSS-Godot/mruby-ext
if errorlevel 1 exit /b %errorlevel%
xmake build -r -vD mruby_onig_regexp_ext_x64
exit /b %errorlevel%
