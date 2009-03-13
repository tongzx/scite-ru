@ECHO OFF
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;C:\MinGW\upx;%PATH%

mingw32-make
if errorlevel 1 exit /b 1
mingw32-make clean
upx.exe --best gui.dll
MOVE gui.dll ..\..\Pack\tools\LuaLib\
