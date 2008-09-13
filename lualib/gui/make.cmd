@ECHO OFF
SET PATH=C:\MinGW\bin;

mingw32-make
mingw32-make clean

IF ERRORLEVEL 1 EXIT /B 1
C:\MinGW\upx\upx.exe --best gui.dll
