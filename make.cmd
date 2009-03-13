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
upx --best --compress-icons=0 SciLexer.dll SciTE.exe

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

:shell
CD %~dp0\lualib\shell
CALL make.cmd

:gui
CD %~dp0\lualib\gui
CALL make.cmd

:lpeg
CD %~dp0\lualib\lpeg
CALL make.cmd

REM :cool
REM CD %~dp0\iconlib\cool\
REM CALL make.cmd

REM :gnome
REM CD %~dp0\iconlib\gnome\
REM CALL make.cmd

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
ECHO For more information visit http://scite.net.ru
GOTO end

:end
CD %~dp0
PAUSE
