@ECHO OFF
IF "%1"=="" GOTO noparam
"c:\Program Files\WinRAR\WinRAR.exe" SciTE.sfx %1 -Ztext.html -ISciBall3.ico
IF NOT ERRORLELEL 1 goto error
GOTO end

:noparam
ECHO Not parameter! (RAR file)
PAUSE
GOTO end

:error
ECHO Error create SFX file!
PAUSE

:end
