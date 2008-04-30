@ECHO OFF
::-----------------------------------------
:: Путь к MinGW
SET MINGW=C:\MinGW\bin
:: Путь к исходникам Lua
SET INC=..\src\scite\lua\include
:: Путь к upx (если отсутствует не менять)
SET UPX3=C:\MinGW\upx300w
::-----------------------------------------

ECHO Start building lualib ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

IF NOT EXIST "%INC%" (
	ECHO Error : Dir "%INC%" not exist!
	GOTO error
)

IF NOT EXIST "%MINGW%" IF NOT EXIST "C:\Program Files\CodeBlocks\bin" (
	ECHO Please install MinGW + UPX!
	ECHO For more information visit: http://code.google.com/p/scite-ru/
	GOTO error
)

SET PATH=%MINGW%;C:\Program Files\CodeBlocks\bin;%PATH%

CD /D "%~dp0"
windres -o resfile.o shell.rc
IF ERRORLEVEL 1 GOTO error
gcc -shared -o shell.dll -I%INC% shell.cpp resfile.o scite.la -lstdc++
IF ERRORLEVEL 1 GOTO error

IF EXIST "%UPX3%\upx.exe" (
	"%UPX3%\upx.exe" --best shell.dll
) ELSE (
	ECHO  Warning: UPX not found! File shell.dll not packed.
)

DEL resfile.o

ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Building lualib successfully completed!
GOTO :EOF

:error
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Compile errors were found!
