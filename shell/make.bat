ECHO OFF

:: ÍÀÑÒÐÎÉÊÈ ÁÀÒÍÈÊÀ
::-----------------------------------------
:: Ïóòü ê MinGW
SET mingw=C:\MinGW\bin
:: Ïóòü èñõîäíèêàì Lua
SET inc=..\src\scite\lua\include
:: Ïóòü ê upx (åñëè îòñóòñòâóåò íå ìåíÿòü)
SET upx300w=C:\MinGW\upx300w
::-----------------------------------------

ECHO Start building lualib
ECHO _______________________________________

:check_upx
SET NO_UPX=0
IF EXIST "%upx300w%" GOTO check_mingw
SET NO_UPX=1
:check_mingw
IF EXIST "%mingw%" GOTO clear_pre
:check_mingw_codeblocks
IF EXIST "C:\Program Files\CodeBlocks\bin" GOTO clear_pre
GOTO error_install

:clear_pre
DEL /S /Q resfile.o shell.dsw shell.plg >NUL:
DEL /S /Q shell.ncb shell.opt shell.aps shell.positions shell.vskdb shell.vsksln >NUL:
DEL /S /Q shell.res shell.bsc shell.exp shell.lib shell.obj shell.pch shell.sbr vc60.idb >NUL:
RMDIR Release >NUL:

:main
SET SAVE_PATH=%PATH%
SET PATH=%mingw%;%upx300w%;C:\Program Files\CodeBlocks\bin;%PATH%
windres -o resfile.o shell.rc
gcc -shared -o shell.dll -I%inc% shell.cpp resfile.o scite.la -lstdc++
IF ERRORLEVEL 1 GOTO error

:upx
IF %NO_UPX%==1 GOTO clear_after
upx --best shell.dll

:clear_after
DEL /S /Q resfile.o shell.dsw shell.plg >NUL:
DEL /S /Q shell.ncb shell.opt shell.aps shell.positions shell.vskdb shell.vsksln >NUL:
DEL /S /Q shell.res shell.bsc shell.exp shell.lib shell.obj shell.pch shell.sbr vc60.idb >NUL:
RMDIR Release >NUL:

:completed
ECHO _______________________________________
ECHO Building lualib successfully completed!
GOTO end

:error
ECHO _______________________________________
ECHO Errors were found (lualib)!
GOTO end

:error_install
ECHO _______________________________________
ECHO Please install MinGW + UPX!
ECHO For more information visit http://code.google.com/p/scite-ru/
GOTO end

:end
SET PATH=%SAVE_PATH%
SET NO_UPX=
SET SAVE_PATH=
SET mingw=
SET inc=
SET upx300w=
REM PAUSE
