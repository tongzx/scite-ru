@ECHO OFF
SET SAVE_PATH=%PATH%

@ECHO Start building lualib
@ECHO _______________________________________

:check_upx
SET NO_UPX=0
IF EXIST C:\MinGW\upx300w GOTO check_mingw
SET NO_UPX=1
:check_mingw
IF EXIST C:\MinGW\bin GOTO clear_pre
:check_mingw_codeblocks
IF EXIST "C:\Program Files\CodeBlocks\bin" GOTO clear_pre
GOTO error_install

:clear_pre
DEL /S /Q scite.def scite.la resfile.o shell.dsw shell.plg
DEL /S /Q shell.ncb shell.opt shell.aps shell.positions shell.vskdb shell.vsksln
DEL /S /Q shell.res shell.bsc shell.exp shell.lib shell.obj shell.pch shell.sbr vc60.idb
RMDIR Release

:main
SET PATH=C:\MinGW\bin\;C:\Program Files\CodeBlocks\bin;C:\MinGW\upx300w\;%PATH%

:create_def_file
ECHO LIBRARY "SciTE.exe" >> scite.def
ECHO EXPORTS >> scite.def
ECHO luaL_addlstring >> scite.def
ECHO luaL_addstring >> scite.def
ECHO luaL_addvalue >> scite.def
ECHO luaL_argerror >> scite.def
ECHO luaL_buffinit >> scite.def
ECHO luaL_callmeta >> scite.def
ECHO luaL_checkany >> scite.def
ECHO luaL_checkinteger >> scite.def
ECHO luaL_checklstring >> scite.def
ECHO luaL_checknumber >> scite.def
ECHO luaL_checkoption >> scite.def
ECHO luaL_checkstack >> scite.def
ECHO luaL_checktype >> scite.def
ECHO luaL_checkudata >> scite.def
ECHO luaL_error >> scite.def
ECHO luaL_findtable >> scite.def
ECHO luaL_getmetafield >> scite.def
ECHO luaL_gsub >> scite.def
ECHO luaL_loadbuffer >> scite.def
ECHO luaL_loadfile >> scite.def
ECHO luaL_loadstring >> scite.def
ECHO luaL_newmetatable >> scite.def
ECHO luaL_newstate >> scite.def
ECHO luaL_openlib >> scite.def
ECHO luaL_openlibs >> scite.def
ECHO luaL_optinteger >> scite.def
ECHO luaL_optlstring >> scite.def
ECHO luaL_optnumber >> scite.def
ECHO luaL_prepbuffer >> scite.def
ECHO luaL_pushresult >> scite.def
ECHO luaL_ref >> scite.def
ECHO luaL_register >> scite.def
ECHO luaL_typerror >> scite.def
ECHO luaL_unref >> scite.def
ECHO luaL_where >> scite.def
ECHO lua_atpanic >> scite.def
ECHO lua_call >> scite.def
ECHO lua_checkstack >> scite.def
ECHO lua_close >> scite.def
ECHO ECHO lua_concat >> scite.def
ECHO lua_cpcall >> scite.def
ECHO lua_createtable >> scite.def
ECHO lua_dump >> scite.def
ECHO lua_equal >> scite.def
ECHO lua_error >> scite.def
ECHO lua_gc >> scite.def
ECHO lua_getallocf >> scite.def
ECHO lua_getfenv >> scite.def
ECHO lua_getfield >> scite.def
ECHO lua_gethook >> scite.def
ECHO lua_gethookcount >> scite.def
ECHO lua_gethookmask >> scite.def
ECHO lua_getinfo >> scite.def
ECHO lua_getlocal >> scite.def
ECHO lua_getmetatable >> scite.def
ECHO lua_getstack >> scite.def
ECHO lua_gettable >> scite.def
ECHO lua_gettop >> scite.def
ECHO lua_getupvalue >> scite.def
ECHO lua_insert >> scite.def
ECHO lua_iscfunction >> scite.def
ECHO lua_isnumber >> scite.def
ECHO lua_isstring >> scite.def
ECHO lua_isuserdata >> scite.def
ECHO lua_lessthan >> scite.def
ECHO lua_load >> scite.def
ECHO lua_newstate >> scite.def
ECHO lua_newthread >> scite.def
ECHO lua_newuserdata >> scite.def
ECHO lua_next >> scite.def
ECHO lua_objlen >> scite.def
ECHO lua_pcall >> scite.def
ECHO lua_pushboolean >> scite.def
ECHO lua_pushcclosure >> scite.def
ECHO lua_pushfstring >> scite.def
ECHO lua_pushinteger >> scite.def
ECHO lua_pushlightuserdata >> scite.def
ECHO lua_pushlstring >> scite.def
ECHO lua_pushnil >> scite.def
ECHO lua_pushnumber >> scite.def
ECHO lua_pushstring >> scite.def
ECHO lua_pushthread >> scite.def
ECHO lua_pushvalue >> scite.def
ECHO lua_pushvfstring >> scite.def
ECHO lua_rawequal >> scite.def
ECHO lua_rawget >> scite.def
ECHO lua_rawgeti >> scite.def
ECHO lua_rawset >> scite.def
ECHO lua_rawseti >> scite.def
ECHO lua_remove >> scite.def
ECHO lua_replace >> scite.def
ECHO lua_resume >> scite.def
ECHO lua_setallocf >> scite.def
ECHO lua_setfenv >> scite.def
ECHO lua_setfield >> scite.def
ECHO lua_sethook >> scite.def
ECHO lua_setlocal >> scite.def
ECHO lua_setmetatable >> scite.def
ECHO lua_settable >> scite.def
ECHO lua_settop >> scite.def
ECHO lua_setupvalue >> scite.def
ECHO lua_status >> scite.def
ECHO lua_toboolean >> scite.def
ECHO lua_tocfunction >> scite.def
ECHO lua_tointeger >> scite.def
ECHO lua_tolstring >> scite.def
ECHO lua_tonumber >> scite.def
ECHO lua_topointer >> scite.def
ECHO lua_tothread >> scite.def
ECHO lua_touserdata >> scite.def
ECHO lua_type >> scite.def
ECHO lua_typename >> scite.def
ECHO lua_xmove >> scite.def
ECHO lua_yield >> scite.def
ECHO luaopen_base >> scite.def
ECHO luaopen_debug >> scite.def
ECHO luaopen_io >> scite.def
ECHO luaopen_math >> scite.def
ECHO luaopen_os >> scite.def
ECHO luaopen_package >> scite.def
ECHO luaopen_string >> scite.def
ECHO luaopen_table >> scite.def
dlltool -d scite.def -l scite.la

:building
REM -lsupc++ - опци€ компил€тора нужна, когда компилим с++ файл и не подключаем -lstdc++
REM если используе что нить из стандартной библиотеки, то нужно подключать при компил€ции -lstdc++
windres -o resfile.o shell.rc
gcc -shared -o shell.dll -I..\src\scite\lua\include shell.cpp resfile.o scite.la -lsupc++
IF ERRORLEVEL 1 GOTO error

:upx
IF %NO_UPX%==1 GOTO copy_to_pack
upx --best shell.dll

:copy_to_pack
MKDIR ..\pack\tools\LuaLib
COPY /Y shell.dll ..\pack\tools\LuaLib\shell.dll
REM IF ERRORLEVEL 1 GOTO error

:clear_after
DEL /S /Q shell.dll scite.def scite.la resfile.o shell.dsw shell.plg
DEL /S /Q shell.ncb shell.opt shell.aps shell.positions shell.vskdb shell.vsksln
DEL /S /Q shell.res shell.bsc shell.exp shell.lib shell.obj shell.pch shell.sbr vc60.idb
RMDIR Release

:completed
@ECHO _______________________________________
@ECHO Building lualib successfully completed!
GOTO end

:error
@ECHO _______________________________________
@ECHO Errors were found (lualib)!
GOTO end

:error_install
@ECHO _______________________________________
@ECHO Please install MinGW + UPX!
@ECHO For more information visit http://code.google.com/p/scite-ru/
GOTO end

:end
SET PATH=%SAVE_PATH%
SET NO_UPX=
SET SAVE_PATH=
REM PAUSE
