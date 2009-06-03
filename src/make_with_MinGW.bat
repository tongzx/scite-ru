@echo off
REM for make debug version use: 
REM >make_with_MinGW.bat DEBUG

set PATH=C:\MinGW\bin;%PATH%;

set debugoldvalue=%DEBUG%
if "%1"=="DEBUG" set DEBUG=1

cd %~dp0\scintilla\win32
mingw32-make
if errorlevel 1 goto :end

cd %~dp0\scite\win32
mingw32-make
if errorlevel 1 goto :end

cd %~dp0\scite\bin
copy /Y SciTE.exe ..\..\..\pack\
copy /Y SciLexer.dll ..\..\..\pack\

:end
set DEBUG=%debugoldvalue%
set debugoldvalue=
cd %~dp0
