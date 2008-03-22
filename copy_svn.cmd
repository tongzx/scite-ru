@ECHO off
ECHO Копирование каталога TRUNK в указанное место (без служебных подкаталогов .svn)
ECHO ------------------------------------------------------------------------------
ECHO .
CD /D %~dp0
SET /P dest=Куда скопировать? [По умолчанию - в C:\TEMP\TRUNK\]:
IF "%dest%"=="" SET dest=C:\TEMP\TRUNK\
ECHO \.svn\>exlist
ECHO exlist>>exlist
ECHO copy_svn.cmd>>exlist
XCOPY %~dp0*.* %dest% /S /H /K /EXCLUDE:exlist
DEL exlist

