@ECHO OFF
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%;

mingw32-make all
if errorlevel 1 exit /b 1
mingw32-make clean
C:\MinGW\upx\upx.exe --best shell.dll
