@echo off

rem VC 7
rem set vcvarsbat=%ProgramFiles%\Microsoft Visual Studio .NET\Common7\Tools\vsvars32.bat

rem VC 71
set vcvarsbat=%ProgramFiles%\Microsoft Visual Studio .NET 2003\Common7\Tools\vsvars32.bat

rem VC 8
rem set vcvarsbat=%ProgramFiles%\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat

call "%vcvarsbat%"

nmake -nologo -f makefile.vc
if errorlevel 1 exit /b 1
nmake -nologo -f makefile.vc clean

set path=c:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%path%;
c:\MinGW\upx\upx.exe --best -f gui.dll

pause
