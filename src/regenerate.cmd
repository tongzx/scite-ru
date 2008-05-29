@ECHO OFF
SET python=C:\MiniPy25\python.exe

IF NOT EXIST "%python%" GOTO error_install

:: LexGen.py
CD %~dp0\scintilla\src
"%python%" LexGen.py
IF ERRORLEVEL 1 GOTO error

:: HFacer.py
CD %~dp0\scintilla\include
"%python%" HFacer.py
IF ERRORLEVEL 1 GOTO error

:: IFaceTableGen.py
CD %~dp0\scite\scripts
"%python%" IFaceTableGen.py
IF ERRORLEVEL 1 GOTO error

:completed
ECHO __________________
ECHO Generation successfully completed!
GOTO end

:error
ECHO __________________
ECHO Errors were found!
GOTO end

:error_install
ECHO Please install Python!
ECHO For more information visit http://code.google.com/p/scite-ru/
GOTO end

:end
CD %~dp0
PAUSE
