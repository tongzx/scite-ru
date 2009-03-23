@ECHO OFF
SETLOCAL
::-----------------------------------------
:: Путь к MinGW (выбирается один из заданных)
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin
::-----------------------------------------

CALL :check "gcc.exe"
IF ERRORLEVEL 1 (
	ECHO Error : Please install MinGW!
	ECHO - For more information visit: http://scite.net.ru
	GOTO error
)

ECHO Start building ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CD /D "%~dp0"
windres -o resfile.o toolbar.rc
IF ERRORLEVEL 1 GOTO error
gcc -s -shared -nostdlib -o cool.dll resfile.o
IF ERRORLEVEL 1 GOTO error

DEL resfile.o
MOVE /Y cool.dll ..\..\pack\home\

ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Building successfully completed!
EXIT 0

:check
FOR /f %%i IN (%1) DO IF "%%~$PATH:i"=="" EXIT /b 1
EXIT /b 0

:error
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Compile errors were found!
EXIT 1
