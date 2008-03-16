@ECHO OFF
MODE CON COLS=120 LINES=2000

IF NOT EXIST C:\MinGW GOTO error_install
IF NOT EXIST C:\MinGW\upx300w GOTO error_install

IF NOT "%1"=="/rebuild" GOTO main

:clear
CD %~dp0\src\scintilla
CALL delbin.bat
CD %~dp0\src\scite
CALL delbin.bat

:main
SET PATH=C:\MinGW\bin\;C:\MinGW\upx300w\;%PATH%
CD %~dp0\src\scintilla\win32
TITLE SciTE-Ru make scintilla
mingw32-make
IF ERRORLEVEL 1 GOTO error

CD %~dp0\src\scite\win32
TITLE SciTE-Ru make scite
mingw32-make
IF ERRORLEVEL 1 GOTO error

CD ..\bin
IF NOT EXIST Sc1.exe PAUSE
TITLE SciTE-Ru packing
upx --best SciLexer.dll SciTE.exe
COPY SciTE.exe ..\..\..\Pack\
COPY SciLexer.dll ..\..\..\Pack\
IF ERRORLEVEL 1 GOTO error

CD %~dp0
TITLE SciTE-Ru completed
PAUSE

GOTO end

:error
ECHO __________________
ECHO Errors were found!
CD %~dp0
PAUSE

GOTO end

:error_install
ECHO Please install MinGW + UPX!
ECHO For more information visit http://code.google.com/p/scite-ru/
PAUSE

GOTO end

:end