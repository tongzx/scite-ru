@ECHO OFF
MODE CON COLS=120 LINES=2000

:check_upx
SET NO_UPX=0
IF EXIST C:\MinGW\upx GOTO check_mingw
SET NO_UPX=1
:check_mingw
IF EXIST C:\MinGW GOTO clear_pre
:check_mingw_codeblocks
IF EXIST "C:\Program Files\CodeBlocks\bin" GOTO clear_pre
GOTO error_install

:clear_pre
IF "%1"=="/build" GOTO main

CD %~dp0\src\scintilla
CALL delbin.bat
CD %~dp0\src\scite
CALL delbin.bat
REM del /Q "%~dp0\src\scite\bin"\*.properties >NUL:

:main
SET PATH=C:\MinGW\bin\;C:\Program Files\CodeBlocks\bin;C:\MinGW\upx\;%PATH%
CD %~dp0\src\scintilla\win32
TITLE SciTE-Ru make scintilla
mingw32-make
IF ERRORLEVEL 1 GOTO error

CD %~dp0\src\scite\win32
TITLE SciTE-Ru make scite
mingw32-make
IF ERRORLEVEL 1 GOTO error

CD ..\bin
REM IF NOT EXIST Sc1.exe PAUSE

IF %NO_UPX%==1 GOTO copy_to_pack
TITLE SciTE-Ru packing
upx --best SciLexer.dll SciTE.exe

:copy_to_pack
COPY SciTE.exe ..\..\..\Pack\
COPY SciLexer.dll ..\..\..\Pack\
IF ERRORLEVEL 1 GOTO error

:clear_after
IF "%1"=="/build" GOTO completed

CD %~dp0\src\scintilla
CALL delbin.bat
CD %~dp0\src\scite
CALL delbin.bat
REM DEL /Q "%~dp0\src\scite\bin"\*.properties >NUL:

:winreg
CD %~dp0\lualib\winreg
CALL make.cmd
COPY winreg.dll ..\..\Pack\tools\LuaLib\
DEL /Q winreg.dll >NUL:

:laulib
CD %~dp0\lualib\shell
CALL make.cmd
COPY shell.dll ..\..\Pack\tools\LuaLib\
DEL /Q shell.dll >NUL:

:completed
ECHO __________________
ECHO Building SciTE-Ru successfully completed!
TITLE SciTE-Ru completed
GOTO end

:error
ECHO __________________
ECHO Errors were found!
GOTO end

:error_install
ECHO Please install MinGW + UPX!
ECHO For more information visit http://code.google.com/p/scite-ru/
GOTO end

:end
CD %~dp0
PAUSE
