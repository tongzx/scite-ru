/*
** $Id: loslib.c,v 1.1 2007/06/15 00:37:58 nyamatongwe Exp $
** Standard Operating System library
** See Copyright Notice in lua.h
*/


#include <errno.h>
#include <locale.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <windows.h> //!-add-[MsgBox][FileAttr]

#define loslib_c
#define LUA_LIB

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"


static int os_pushresult (lua_State *L, int i, const char *filename) {
  int en = errno;  /* calls to Lua API may change this value */
  if (i) {
    lua_pushboolean(L, 1);
    return 1;
  }
  else {
    lua_pushnil(L);
    lua_pushfstring(L, "%s: %s", filename, strerror(en));
    lua_pushinteger(L, en);
    return 3;
  }
}


static int os_execute (lua_State *L) {
  lua_pushinteger(L, system(luaL_optstring(L, 1, NULL)));
  return 1;
}

//!-start-[os.run]
void push_lasterr(lua_State *L, LPTSTR lpszFunction) {
	LPVOID lpMsgBuf;
	LPVOID lpDisplayBuf;
	DWORD dw = GetLastError();

	FormatMessage(
		FORMAT_MESSAGE_ALLOCATE_BUFFER |
		FORMAT_MESSAGE_FROM_SYSTEM,
		NULL,
		dw,
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		(LPTSTR) &lpMsgBuf,
		0, NULL );

	lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT,
		(lstrlen((LPCTSTR)lpMsgBuf)+lstrlen((LPCTSTR)lpszFunction)+40)*sizeof(TCHAR));
	sprintf (
		(char*) lpDisplayBuf,
		"%s failed with error %d: %s",
		lpszFunction, (int)dw, (char*)lpMsgBuf	);
	lua_pushstring(L,(LPTSTR)lpDisplayBuf);
	LocalFree(lpMsgBuf);
	LocalFree(lpDisplayBuf);
}

static int os_run(lua_State *L){
	static const int MAX_CMD = 1024;
	BOOL RetCode = 0;
	int DoWait = 0;
	int top = lua_gettop(L);
	char *CmdLine = 0;
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	DWORD exit_code = 0; /* Код завершения процесса */

	ZeroMemory( &si, sizeof(si) );
	si.cb = sizeof(si);
	ZeroMemory( &pi, sizeof(pi) );

	if(top == 0){
		lua_pushnil(L);
		lua_pushstring(L,"No parameters!");
		return 2;
	}

	if( !lua_isstring(L,1) ){
		lua_pushnil(L);
		lua_pushstring(L,"First param must be a string!");
		return 2;
	}
	if( top > 1 ){
		if( !lua_isnumber(L,2) ){
			lua_pushnil(L);
			lua_pushstring(L,"Second param must be a number!");
			return 2;
		}
		si.dwFlags = STARTF_USESHOWWINDOW;
		si.wShowWindow = (unsigned short)lua_tonumber(L, 2);
	}
	if( top > 2 ){
		if( !lua_isboolean(L,3) ){
			lua_pushnil(L);
			lua_pushstring(L,"Thrid param must be a boolean!");
			return 2;
		}
		DoWait = lua_toboolean(L, 3);
	}

	CmdLine = malloc(MAX_CMD * sizeof(char));
	ZeroMemory( CmdLine , sizeof(MAX_CMD * sizeof(char)) );
	strncpy(CmdLine,luaL_checkstring(L,1),MAX_CMD-1);
	
	/* Start the child process. */
	RetCode = CreateProcess(
		NULL,           /* No module name (use command line) */
		CmdLine,        /* Command line */
		NULL,           /* Process handle not inheritable */
		NULL,           /* Thread handle not inheritable */
		FALSE,          /* Set handle inheritance to FALSE */
		0,              /* No creation flags */
		NULL,           /* Use parent's environment block */
		NULL,           /* Use parent's starting directory */
		&si,            /* Pointer to STARTUPINFO structure */
		&pi             /* Pointer to PROCESS_INFORMATION structure */
	);

	if( ! RetCode ){
		lua_pushnil(L);
		push_lasterr(L,"\"CreateProcess\"");
		free(CmdLine);
		return 2;
	}
	CloseHandle( pi.hThread );
	if(DoWait){
		/* Wait until child process exits. */
		WaitForSingleObject( pi.hProcess, INFINITE );
	}
	free(CmdLine);

	GetExitCodeProcess(pi.hProcess,&exit_code);
	/* Close process and thread handles. */
	CloseHandle( pi.hProcess );

	lua_pushnumber( L, exit_code );
	return 1;
}
//!-end-[os.run]

//!-start-[MsgBox]
static int os_msgbox(lua_State *L) {
	int options;
	const char *text = luaL_checkstring(L, 1);
	const char *title = "SciTE"; /* Default text for title */
	options = 0;
	if (lua_gettop(L) > 1) {
		title = luaL_checkstring(L, 2);
		if (lua_gettop(L) > 2) {
			options = (int)lua_tonumber(L, 3);
		};
	};
	options = options + 8192; /* Task Modal*/
	lua_pushnumber(L, MessageBox(0, text, title, options));
	return 1;                   /* number of results */
}
//!-end-[MsgBox]

//!-start-[FileAttr]
static int os_getfileattr (lua_State *L) {
  const char*FN = luaL_checkstring(L,-1);
  WIN32_FILE_ATTRIBUTE_DATA fad;
  if(0==GetFileAttributesEx(FN,GetFileExInfoStandard ,&fad)){
    lua_pushnil(L);
    push_lasterr(L,"\"getfileattr\"");
    return 2;
  }
  lua_pushnumber(L, fad.dwFileAttributes);
	return 1;
}

static int os_setfileattr (lua_State *L) {
  const char *FN = luaL_checkstring(L,-2);
  DWORD attr = luaL_checkint(L,-1);
  if(0 == SetFileAttributes(FN, attr)){
    lua_pushnil(L);
    push_lasterr(L,"\"setfileattr\"");
    return 2;
  }
  lua_pushnumber(L, 1);  
	return 1;
}
//!-end-[FileAttr]

static int os_remove (lua_State *L) {
  const char *filename = luaL_checkstring(L, 1);
  return os_pushresult(L, remove(filename) == 0, filename);
}


static int os_rename (lua_State *L) {
  const char *fromname = luaL_checkstring(L, 1);
  const char *toname = luaL_checkstring(L, 2);
  return os_pushresult(L, rename(fromname, toname) == 0, fromname);
}


static int os_tmpname (lua_State *L) {
  char buff[LUA_TMPNAMBUFSIZE];
  int err;
  lua_tmpnam(buff, err);
  if (err)
    return luaL_error(L, "unable to generate a unique filename");
  lua_pushstring(L, buff);
  return 1;
}


static int os_getenv (lua_State *L) {
  lua_pushstring(L, getenv(luaL_checkstring(L, 1)));  /* if NULL push nil */
  return 1;
}


static int os_clock (lua_State *L) {
  lua_pushnumber(L, ((lua_Number)clock())/(lua_Number)CLOCKS_PER_SEC);
  return 1;
}


/*
** {======================================================
** Time/Date operations
** { year=%Y, month=%m, day=%d, hour=%H, min=%M, sec=%S,
**   wday=%w+1, yday=%j, isdst=? }
** =======================================================
*/

static void setfield (lua_State *L, const char *key, int value) {
  lua_pushinteger(L, value);
  lua_setfield(L, -2, key);
}

static void setboolfield (lua_State *L, const char *key, int value) {
  if (value < 0)  /* undefined? */
    return;  /* does not set field */
  lua_pushboolean(L, value);
  lua_setfield(L, -2, key);
}

static int getboolfield (lua_State *L, const char *key) {
  int res;
  lua_getfield(L, -1, key);
  res = lua_isnil(L, -1) ? -1 : lua_toboolean(L, -1);
  lua_pop(L, 1);
  return res;
}


static int getfield (lua_State *L, const char *key, int d) {
  int res;
  lua_getfield(L, -1, key);
  if (lua_isnumber(L, -1))
    res = (int)lua_tointeger(L, -1);
  else {
    if (d < 0)
      return luaL_error(L, "field " LUA_QS " missing in date table", key);
    res = d;
  }
  lua_pop(L, 1);
  return res;
}


static int os_date (lua_State *L) {
  const char *s = luaL_optstring(L, 1, "%c");
  time_t t = luaL_opt(L, (time_t)luaL_checknumber, 2, time(NULL));
  struct tm *stm;
  if (*s == '!') {  /* UTC? */
    stm = gmtime(&t);
    s++;  /* skip `!' */
  }
  else
    stm = localtime(&t);
  if (stm == NULL)  /* invalid date? */
    lua_pushnil(L);
  else if (strcmp(s, "*t") == 0) {
    lua_createtable(L, 0, 9);  /* 9 = number of fields */
    setfield(L, "sec", stm->tm_sec);
    setfield(L, "min", stm->tm_min);
    setfield(L, "hour", stm->tm_hour);
    setfield(L, "day", stm->tm_mday);
    setfield(L, "month", stm->tm_mon+1);
    setfield(L, "year", stm->tm_year+1900);
    setfield(L, "wday", stm->tm_wday+1);
    setfield(L, "yday", stm->tm_yday+1);
    setboolfield(L, "isdst", stm->tm_isdst);
  }
  else {
    char cc[3];
    luaL_Buffer b;
    cc[0] = '%'; cc[2] = '\0';
    luaL_buffinit(L, &b);
    for (; *s; s++) {
      if (*s != '%' || *(s + 1) == '\0')  /* no conversion specifier? */
        luaL_addchar(&b, *s);
      else {
        size_t reslen;
        char buff[200];  /* should be big enough for any conversion result */
        cc[1] = *(++s);
        reslen = strftime(buff, sizeof(buff), cc, stm);
        luaL_addlstring(&b, buff, reslen);
      }
    }
    luaL_pushresult(&b);
  }
  return 1;
}


static int os_time (lua_State *L) {
  time_t t;
  if (lua_isnoneornil(L, 1))  /* called without args? */
    t = time(NULL);  /* get current time */
  else {
    struct tm ts;
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_settop(L, 1);  /* make sure table is at the top */
    ts.tm_sec = getfield(L, "sec", 0);
    ts.tm_min = getfield(L, "min", 0);
    ts.tm_hour = getfield(L, "hour", 12);
    ts.tm_mday = getfield(L, "day", -1);
    ts.tm_mon = getfield(L, "month", -1) - 1;
    ts.tm_year = getfield(L, "year", -1) - 1900;
    ts.tm_isdst = getboolfield(L, "isdst");
    t = mktime(&ts);
  }
  if (t == (time_t)(-1))
    lua_pushnil(L);
  else
    lua_pushnumber(L, (lua_Number)t);
  return 1;
}


static int os_difftime (lua_State *L) {
  lua_pushnumber(L, difftime((time_t)(luaL_checknumber(L, 1)),
                             (time_t)(luaL_optnumber(L, 2, 0))));
  return 1;
}

/* }====================================================== */


static int os_setlocale (lua_State *L) {
  static const int cat[] = {LC_ALL, LC_COLLATE, LC_CTYPE, LC_MONETARY,
                      LC_NUMERIC, LC_TIME};
  static const char *const catnames[] = {"all", "collate", "ctype", "monetary",
     "numeric", "time", NULL};
  const char *l = luaL_optstring(L, 1, NULL);
  int op = luaL_checkoption(L, 2, "all", catnames);
  lua_pushstring(L, setlocale(cat[op], l));
  return 1;
}


static int os_exit (lua_State *L) {
  exit(luaL_optint(L, 1, EXIT_SUCCESS));
  return 0;  /* to avoid warnings */
}

static const luaL_Reg syslib[] = {
  {"clock",     os_clock},
  {"date",      os_date},
  {"difftime",  os_difftime},
  {"execute",   os_execute},
  {"run",       os_run}, //!-add-[os.run]
  {"msgbox",     os_msgbox}, //!-add-[MsgBox]
  {"getfileattr",os_getfileattr}, //!-add-[FileAttr]
  {"setfileattr",os_setfileattr}, //!-add-[FileAttr]
  {"exit",      os_exit},
  {"getenv",    os_getenv},
  {"remove",    os_remove},
  {"rename",    os_rename},
  {"setlocale", os_setlocale},
  {"time",      os_time},
  {"tmpname",   os_tmpname},
  {NULL, NULL}
};

/* }====================================================== */



LUALIB_API int luaopen_os (lua_State *L) {
  luaL_register(L, LUA_OSLIBNAME, syslib);
  return 1;
}

