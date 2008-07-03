@ECHO OFF
:: -------------------------------------------
SET sfx_filename=SciTE_Setup
SET distrib_path=..\pack
SET RAR="%ProgramFiles%\WinRAR\WinRAR.exe"
:: -------------------------------------------

SET cur_path=%~dp0
CD /D "%cur_path%"

PUSHD "%distrib_path%"
%RAR% a -r -rr -s -m5 "%cur_path%%sfx_filename%"
IF ERRORLEVEL 1 GOTO error
POPD

%RAR% SSciTE.sfx %sfx_filename%.rar -Ztext.html -iiconc:SciBall.ico
IF ERRORLEVEL 1 GOTO error

DEL %sfx_filename%.rar
GOTO :EOF

:error
ECHO Error create SFX file!
PAUSE
