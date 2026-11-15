@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d E:\Projects\RGSS-Godot
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING %* /I E:\Projects\mruby-for-dotnet\mruby\build\host\include tools\native-abi-probe.c mruby-ext\lib\libmruby_x64.lib /Fe:.omo\compatibility-run-tmp\native-abi-probe.exe /Fo:.omo\compatibility-run-tmp\native-abi-probe.obj
if errorlevel 1 exit /b %errorlevel%
copy /y Plugins\windows\libmruby_x64.dll .omo\compatibility-run-tmp\libmruby_x64.dll
if errorlevel 1 exit /b %errorlevel%
.omo\compatibility-run-tmp\native-abi-probe.exe
exit /b %errorlevel%
