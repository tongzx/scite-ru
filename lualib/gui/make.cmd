@ECHO OFF
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin
mingw32-make
if errorlevel 1 exit /b 1
mingw32-make clean
C:\MinGW\upx\upx.exe --best gui.dll
