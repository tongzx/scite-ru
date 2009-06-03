@echo off
REM for make debug version use: 
REM >make_with_VC.bat DEBUG

set VC7=%ProgramFiles%\Microsoft Visual Studio .NET
set VC71=%ProgramFiles%\Microsoft Visual Studio .NET 2003
set VC8=%ProgramFiles%\Microsoft Visual Studio 8
set Tools=Common7\Tools
set path=%VC8%\%Tools%;%VC71%\%Tools%;%VC7%\%Tools%;%path%
call vsvars32.bat

if "%1"=="DEBUG" set parameter1=DEBUG=1

cd %~dp0\scintilla\win32
nmake %parameter1% -f scintilla.mak
if errorlevel 1 goto :end

cd %~dp0\scite\win32
nmake %parameter1% -f scite.mak
if errorlevel 1 goto :end

cd %~dp0\scite\bin
copy /Y SciTE.exe ..\..\..\pack\
copy /Y SciLexer.dll ..\..\..\pack\

:end
set parameter1=
cd %~dp0
