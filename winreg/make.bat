@ECHO OFF
SET PATH=C:\MinGW\bin;%PATH%;

mingw32-make all

REM COPY winreg.dll ..\Pack\tools\LuaLib\

REM mingw32-make clean