@ECHO OFF
::-----------------------------------------
:: Путь к MinGW (выбирается один из заданных)
SET MINGW=C:\MinGW\bin
SET MINGW_ALT=%ProgramFiles%\CodeBlocks\bin
:: Путь к исходникам Lua
SET INC=..\src\scite\lua\include
:: Путь к upx (если отсутствует не менять)
SET UPX3=C:\MinGW\upx300w\upx.exe
::-----------------------------------------
ECHO Start building lualib ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CD /D "%~dp0"

IF NOT EXIST "%INC%" (
	ECHO Error : Dir "%INC%" not exist!
	GOTO error
)
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
::----------------------------------------------

windres -o resfile.o shell.rc
IF ERRORLEVEL 1 GOTO error
gcc -s -shared -o shell.dll -I%INC% shell.cpp resfile.o scite.la -lshlwapi -lstdc++
IF ERRORLEVEL 1 GOTO error

IF EXIST "%UPX3%" (
	"%UPX3%" --best shell.dll
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
