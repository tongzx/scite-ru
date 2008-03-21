@ECHO OFF
SET cur_path=%~dp0
SET RAR="%ProgramFiles%\WinRAR\WinRAR.exe"
SET name=SciTE_Setup_eng
CD %cur_path%

PUSHD ..\pack
%RAR% a -r -rr -s -m5 "%cur_path%%name%"
IF ERRORLEVEL 1 GOTO error
POPD

%RAR% d %name% locale.properties
IF ERRORLEVEL 1 GOTO error

%RAR% SSciTE.sfx %name%.rar -Ztext_eng.html -ISciBall.ico
IF ERRORLEVEL 1 GOTO error

DEL %name%.rar

GOTO end

:error
ECHO Error create SFX file!
PAUSE

:end
