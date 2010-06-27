@ECHO off
ECHO Copy TRUNK to destination (without .svn subdirs)
ECHO ------------------------------------------------------------------------------
ECHO.
CD /D %~dp0
SET /P dest=Enter destination [Default - C:\TEMP\scite-ru\]:
IF "%dest%"=="" SET dest=C:\TEMP\scite-ru\
ECHO \.svn\>exlist
ECHO exlist>>exlist
ECHO copy_svn.cmd>>exlist
XCOPY "%~dp0*.*" "%dest%" /S /H /K /EXCLUDE:exlist
DEL exlist
