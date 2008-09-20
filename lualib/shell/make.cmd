@ECHO OFF
SETLOCAL
CD /D "%~dp0"

::-----------------------------------------
:: Путь к MinGW (выбирается один из заданных)
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin
:: Путь к исходникам Lua
SET INC=..\..\src\scite\lua\include
:: Путь к upx (если отсутствует не менять)
SET UPX3=C:\MinGW\upx\upx.exe
::-----------------------------------------

IF NOT EXIST "%INC%" (
	ECHO Error : Dir "%INC%" not exist!
	GOTO error
)

CALL :check "gcc.exe"
IF ERRORLEVEL 1 (
	ECHO Error : Please install MinGW!
	ECHO - For more information visit: http://code.google.com/p/scite-ru/
	GOTO error
)

ECHO Start building ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

windres -o resfile.o shell.rc
IF ERRORLEVEL 1 GOTO error
gcc -s -shared -o shell.dll -I%INC% shell.cpp resfile.o scite.la -lshlwapi -lstdc++
IF ERRORLEVEL 1 GOTO error

IF EXIST "%UPX3%" (
	"%UPX3%" --best shell.dll
) ELSE (
	ECHO Warning : UPX not found! File shell.dll not packed.
)

DEL resfile.o

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
