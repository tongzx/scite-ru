@echo off
set VC7=%ProgramFiles%\Microsoft Visual Studio .NET
set VC71=%ProgramFiles%\Microsoft Visual Studio .NET 2003
set VC8=%ProgramFiles%\Microsoft Visual Studio 8
set Tools=Common7\Tools
set path=%VC8%\%Tools%;%VC71%\%Tools%;%VC7%\%Tools%
call vsvars32.bat

nmake -nologo -f makefile.vc
if errorlevel 1 exit /b 1
nmake -nologo -f makefile.vc clean

SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;C:\MinGW\upx;%PATH%
upx.exe --best -f gui.dll
MOVE gui.dll ..\..\Pack\tools\LuaLib\
