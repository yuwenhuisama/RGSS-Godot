@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d E:/Projects/RGSS-Godot/mruby-ext
xmake build -r -vD mruby_dir_glob_ext_x64
exit /b %errorlevel%
