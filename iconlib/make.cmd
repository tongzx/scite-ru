@ECHO OFF
::-----------------------------------------
:: Путь к MinGW (выбирается один из заданных)
SET MINGW=C:\MinGW\bin
SET MINGW_ALT=%ProgramFiles%\CodeBlocks\bin
::-----------------------------------------

IF NOT EXIST "%MINGW%" (
	IF EXIST "%MINGW_ALT%" (
		SET MINGW=%MINGW_ALT%
	) ELSE (
		ECHO Please install MinGW!
		ECHO For more information visit: http://code.google.com/p/scite-ru/
		GOTO error
	)
)
SET PATH=%MINGW%;%PATH%

ECHO Start building toolbar.dll ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CD /D "%~dp0"
windres -o resfile.o toolbar.rc
IF ERRORLEVEL 1 GOTO error
gcc -s -shared -nostdlib -o toolbar.dll resfile.o
IF ERRORLEVEL 1 GOTO error

DEL resfile.o

ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Building toolbar.dll successfully completed!
EXIT /B

:error
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Compile errors were found!
