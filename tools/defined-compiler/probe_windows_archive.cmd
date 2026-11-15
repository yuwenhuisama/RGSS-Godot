@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING /DMRB_USE_DEBUG_HOOK /I "%~1\mruby\build\host-dll\include" "%~dp0extended_host_probe.c" "%~1\mruby-shared\build\windows\x64\release\libmruby_x64.lib" /Fe:"%~2\extended_host_probe.exe" /Fo:"%~2\extended_host_probe.obj"
exit /b %errorlevel%
