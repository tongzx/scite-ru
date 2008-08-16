@ECHO OFF

::-----------------------------------------
:: Путь к MinGW
SET MINGW=C:\MinGW\bin
:: Путь к upx (если отсутствует не менять)
SET UPX3=C:\MinGW\upx300w
::-----------------------------------------

ECHO Start building toolbar.dll ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CD /D "%~dp0"

IF NOT EXIST "%MINGW%" IF NOT EXIST "C:\Program Files\CodeBlocks\bin" (
	ECHO Please install MinGW + UPX!
	ECHO For more information visit: http://code.google.com/p/scite-ru/
	GOTO error
)

SET PATH=%MINGW%;C:\Program Files\CodeBlocks\bin;%PATH%

windres -o resfile.o toolbar.rc
IF ERRORLEVEL 1 GOTO error
gcc -s -shared -o toolbar.dll resfile.o
IF ERRORLEVEL 1 GOTO error

IF EXIST "%UPX3%\upx.exe" (
	"%UPX3%\upx.exe" --best toolbar.dll
) ELSE (
	ECHO  Warning: UPX not found! File toolbar.dll not packed.
)

DEL resfile.o

ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Building toolbar.dll successfully completed!
GOTO :EOF

:error
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Compile errors were found!
