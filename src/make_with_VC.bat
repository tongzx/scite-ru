@echo off
set VC7=%ProgramFiles%\Microsoft Visual Studio .NET
set VC71=%ProgramFiles%\Microsoft Visual Studio .NET 2003
set VC8=%ProgramFiles%\Microsoft Visual Studio 8
set Tools=Common7\Tools
set path=%VC8%\%Tools%;%VC71%\%Tools%;%VC7%\%Tools%
call vsvars32.bat

cd scintilla\win32
nmake -f scintilla.mak
cd ..\..
cd scite\win32
nmake -f scite.mak
