@ECHO off
FOR /R %~dp0 %%d IN (.svn\) DO RMDIR /S /Q %%d

