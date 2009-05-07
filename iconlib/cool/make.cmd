@ECHO OFF
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin

CD /D "%~dp0"
windres -o resfile.o toolbar.rc
IF ERRORLEVEL 1 EXIT

ld --nmagic --strip-all --entry=0 --dll -o cool.dll resfile.o
IF ERRORLEVEL 1 EXIT

DEL resfile.o

