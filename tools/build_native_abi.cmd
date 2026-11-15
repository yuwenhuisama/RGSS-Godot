@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d E:\Projects\RGSS-Godot\mruby-ext
if errorlevel 1 exit /b %errorlevel%
xmake f -o build -p windows -a x64 --toolchain=msvc --cc=cl --cxx=cl --ld=link --sh=link
if errorlevel 1 exit /b %errorlevel%
xmake build -r -vD
exit /b %errorlevel%
