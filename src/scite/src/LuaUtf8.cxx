#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>

#include "Scintilla.h"
#include "GUI.h"

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

#define IO_INPUT	1
#define IO_OUTPUT	2

#if !defined(GTK)
#define remove			_wremove
#define rename			_wrename
#define system			_wsystem
#undef fopen
#define fopen			_wfopen
#define freopen			_wfreopen 
#define getenv			_wgetenv
#undef _popen
#define _popen			_wpopen			
#endif


// ======================================================


typedef struct LoadF {
  int extraline;
  FILE *f;
  char buff[LUAL_BUFFERSIZE];
} LoadF;


static const char *getF (lua_State *L, void *ud, size_t *size) {
  LoadF *lf = (LoadF *)ud;
  (void)L;
  if (lf->extraline) {
    lf->extraline = 0;
    *size = 1;
    return "\n";
  }
  if (feof(lf->f)) return NULL;
  *size = fread(lf->buff, 1, sizeof(lf->buff), lf->f);
  return (*size > 0) ? lf->buff : NULL;
}


static int errfile (lua_State *L, const char *what, int fnameindex) {
  const char *serr = strerror(errno);
  const char *filename = lua_tostring(L, fnameindex) + 1;
  lua_pushfstring(L, "cannot %s %s: %s", what, filename, serr);
  lua_remove(L, fnameindex);
  return LUA_ERRFILE;
}

LUALIB_API int utf8_luaL_loadfile (lua_State *L, const char *filename) {
  LoadF lf;
  int status, readstatus;
  int c;
  int fnameindex = lua_gettop(L) + 1;  /* index of filename on the stack */
  lf.extraline = 0;
  if (filename == NULL) {
    lua_pushliteral(L, "=stdin");
    lf.f = stdin;
  }
  else {
    lua_pushfstring(L, "@%s", filename);
	lf.f = fopen(GUI::StringFromUTF8(filename).c_str(), GUI_TEXT("r"));
    if (lf.f == NULL) return errfile(L, "open", fnameindex);
  }
  c = getc(lf.f);
  if (c == '#') {  /* Unix exec. file? */
    lf.extraline = 1;
    while ((c = getc(lf.f)) != EOF && c != '\n') ;  /* skip first line */
    if (c == '\n') c = getc(lf.f);
  }
  if (c == LUA_SIGNATURE[0] && filename) {  /* binary file? */
    lf.f = freopen(GUI::StringFromUTF8(filename).c_str(), GUI_TEXT("rb"), lf.f);  /* reopen in binary mode */
    if (lf.f == NULL) return errfile(L, "reopen", fnameindex);
    /* skip eventual `#!...' */
   while ((c = getc(lf.f)) != EOF && c != LUA_SIGNATURE[0]) ;
    lf.extraline = 0;
  }
  ungetc(c, lf.f);
  status = lua_load(L, getF, &lf, lua_tostring(L, -1));
  readstatus = ferror(lf.f);
  if (filename) fclose(lf.f);  /* close file (even in case of errors) */
  if (readstatus) {
    lua_settop(L, fnameindex);  /* ignore results from `lua_load' */
    return errfile(L, "read", fnameindex);
  }
  lua_remove(L, fnameindex);
  return status;
}

// ============ STRING ==================================
static int lua_string_from_utf8(lua_State *L) {
	if(lua_gettop(L) != 2) luaL_error(L, "Wrong arguments count for string.from_utf8");
	const char *s = luaL_checkstring(L, 1);
	int cp = 0;
	if(!lua_isnumber(L, 2))
		cp = GUI::CodePageFromName(lua_tostring(L, 2));
	else
		cp = lua_tointeger(L, 2);
	std::string ss = GUI::ConvertFromUTF8(s, cp);
	lua_pushstring(L, ss.c_str());
	return 1;
}

static int lua_string_to_utf8(lua_State *L) {
	if(lua_gettop(L) != 2) luaL_error(L, "Wrong arguments count for string.to_utf8");
	const char *s = luaL_checkstring(L, 1);
	int cp = 0;
	if(!lua_isnumber(L, 2))
		cp = GUI::CodePageFromName(lua_tostring(L, 2));
	else
		cp = lua_tointeger(L, 2);
	std::string ss = GUI::ConvertToUTF8(s, cp);
	lua_pushstring(L, ss.c_str());
	return 1;
}

static int lua_string_utf8_to_upper(lua_State *L) {
	const char *s = luaL_checkstring(L, 1);
	std::string ss = GUI::UTF8ToUpper(s);
	lua_pushstring(L, ss.c_str());
	return 1;
}

static int lua_string_utf8_to_lower(lua_State *L) {
	const char *s = luaL_checkstring(L, 1);
	std::string ss = GUI::UTF8ToLower(s);
	lua_pushstring(L, ss.c_str());
	return 1;
}

static int lua_string_utf8len(lua_State *L) {
	const char *str = luaL_checkstring(L, 1);
	GUI::gui_string wstr = GUI::StringFromUTF8(str);
	lua_pushinteger(L, wstr.length());
	return 1;
}

// ============ OS ==================================

static int os_pushresult (lua_State *L, int i, GUI::gui_string fn) {
  int en = errno;  /* calls to Lua API may change this value */
  if (i) {
    lua_pushboolean(L, 1);
    return 1;
  }
  else {
    lua_pushnil(L);
	lua_pushfstring(L, "%s: %s", GUI::UTF8FromString(fn).c_str(), strerror(en));
    lua_pushinteger(L, en);
    return 3;
  }
}

static int lua_os_utf8remove (lua_State *L) {
	GUI::gui_string fn = GUI::StringFromUTF8(luaL_checkstring(L, 1));
	return os_pushresult(L, remove(fn.c_str()) == 0, fn);
}

static int lua_os_utf8rename (lua_State *L) {
	GUI::gui_string fromname = GUI::StringFromUTF8(luaL_checkstring(L, 1));
	GUI::gui_string toname = GUI::StringFromUTF8(luaL_checkstring(L, 2));
	return os_pushresult(L, rename(fromname.c_str(), toname.c_str()) == 0, fromname);
}

static int lua_os_utf8execute (lua_State *L) {
	const char* cmd = luaL_optstring(L, 1, NULL);
	lua_pushinteger(L, system(GUI::StringFromUTF8(cmd).c_str()));
	return 1;
}


// ============ IO ==================================
static FILE **newfile (lua_State *L) {
	FILE **pf = (FILE **)lua_newuserdata(L, sizeof(FILE *));
	*pf = NULL;  /* file handle is currently `closed' */
	luaL_getmetatable(L, LUA_FILEHANDLE);
	lua_setmetatable(L, -2);
	return pf;
}

static int pushresult (lua_State *L, int i, const char* filename) {
	int en = errno;  /* calls to Lua API may change this value */
	if (i) {
		lua_pushboolean(L, 1);
		return 1;
	}
	else {
		lua_pushnil(L);
		if (filename)
			lua_pushfstring(L, "%s: %s",  filename,  strerror(en));
		else
			lua_pushfstring(L, "%s",  strerror(en));
		lua_pushinteger(L, en);
		return 3;
	}
}

static int lua_io_utf8open (lua_State *L) {
	const char *filename = luaL_checkstring(L, 1);
	const char *mode = luaL_optstring(L, 2, "r");
	FILE **pf = newfile(L);
	*pf = fopen(GUI::StringFromUTF8(filename).c_str(), GUI::StringFromUTF8(mode).c_str());
	return (*pf == NULL) ? pushresult(L, 0, filename) : 1;
}

#if defined(LUA_USE_POPEN)

#define lua_popen(L,c,m)	((void)L, fflush(NULL), popen(c,m))

#elif defined(LUA_WIN)

#define lua_popen(L,c,m)	((void)L, _popen(c,m))

#else

#define lua_popen(L,c,m)	((void)((void)c, m),  \
		luaL_error(L, LUA_QL("popen") " not supported"), (FILE*)0)

#endif

static int lua_io_utf8popen (lua_State *L) {
  const char *filename = luaL_checkstring(L, 1);
  const char *mode = luaL_optstring(L, 2, "r");
  FILE **pf = newfile(L);
  *pf = lua_popen(L, GUI::StringFromUTF8(filename).c_str(), GUI::StringFromUTF8(mode).c_str());
  return (*pf == NULL) ? pushresult(L, 0, filename) : 1;
}

static void _fileerror (lua_State *L, int arg, const char* filename) {
	lua_pushfstring(L, "%s: %s", filename, strerror(errno));
	luaL_argerror(L, arg, lua_tostring(L, -1));
}

static FILE *_tofile (lua_State *L) {
  FILE **f = (FILE **)luaL_checkudata(L, 1, LUA_FILEHANDLE);
  if (*f == NULL)
    luaL_error(L, "attempt to use a closed file");
  return *f;
}

static int _g_iofile (lua_State *L, int f, const char* mode) {
	if (!lua_isnoneornil(L, 1)) {
		const char* filename = lua_tostring(L, 1);
		if (filename) {
			FILE **pf = newfile(L);
			*pf = fopen(GUI::StringFromUTF8(filename).c_str(), GUI::StringFromUTF8(mode).c_str());
			if (*pf == NULL)
				_fileerror(L, 1, filename);
		}
		else {
			_tofile(L);  /* check that it's a valid file handle */
			lua_pushvalue(L, 1);
		}
		lua_rawseti(L, LUA_ENVIRONINDEX, f);
	}
	/* return current value */
	lua_rawgeti(L, LUA_ENVIRONINDEX, f);
	return 1;
}

static int io_readline (lua_State *L);

static void aux_lines (lua_State *L, int idx, int toclose) {
  lua_pushvalue(L, idx);
  lua_pushboolean(L, toclose);  /* close/not close file when finished */
  lua_pushcclosure(L, io_readline, 2);
}

#define tofilep(L)	((FILE **)luaL_checkudata(L, 1, LUA_FILEHANDLE))

static FILE *tofile (lua_State *L) {
  FILE **f = tofilep(L);
  if (*f == NULL)
    luaL_error(L, "attempt to use a closed file");
  return *f;
}

static int f_lines (lua_State *L) {
  tofile(L);  /* check that it's a valid file handle */
  aux_lines(L, 1, 0);
  return 1;
}

static int lua_io_utf8input (lua_State *L) {
	return _g_iofile(L, 1, "r");
}


static int lua_io_utf8output (lua_State *L) {
	return _g_iofile(L, 2, "w");
}

static int lua_io_lines (lua_State *L) {
	if (lua_isnoneornil(L, 1)) {  /* no arguments? */
		/* will iterate over default input */
		lua_rawgeti(L, LUA_ENVIRONINDEX, IO_INPUT);
		return f_lines(L);
	}
	else {
		const char* filename = luaL_checkstring(L, 1);
		FILE **pf = newfile(L);
		*pf = fopen(GUI::StringFromUTF8(filename).c_str(), GUI_TEXT("r"));
		if (*pf == NULL)
			_fileerror(L, 1, filename);
		aux_lines(L, lua_gettop(L), 1);
		return 1;
	}
}

static int read_line (lua_State *L, FILE *f) {
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  for (;;) {
    size_t l;
    char *p = luaL_prepbuffer(&b);
    if (fgets(p, LUAL_BUFFERSIZE, f) == NULL) {  /* eof? */
      luaL_pushresult(&b);  /* close buffer */
      return (lua_objlen(L, -1) > 0);  /* check whether read something */
    }
    l = strlen(p);
    if (l == 0 || p[l-1] != '\n')
      luaL_addsize(&b, l);
    else {
      luaL_addsize(&b, l - 1);  /* do not include `eol' */
      luaL_pushresult(&b);  /* close buffer */
      return 1;  /* read at least an `eol' */
    }
  }
}

static int aux_close (lua_State *L) {
  lua_getfenv(L, 1);
  lua_getfield(L, -1, "__close");
  return (lua_tocfunction(L, -1))(L);
}

static int io_readline (lua_State *L) {
  FILE *f = *(FILE **)lua_touserdata(L, lua_upvalueindex(1));
  int sucess;
  if (f == NULL)  /* file is already closed? */
    luaL_error(L, "file is already closed");
  sucess = read_line(L, f);
  if (ferror(f))
    return luaL_error(L, "%s", strerror(errno));
  if (sucess) return 1;
  else {  /* EOF */
    if (lua_toboolean(L, lua_upvalueindex(2))) {  /* generator created file? */
      lua_settop(L, 0);
      lua_pushvalue(L, lua_upvalueindex(1));
      aux_close(L);  /* close it */
    }
    return 0;
  }
}

// ======================================================

/* prefix for open functions in C libraries */
#define LUA_POF		"luaopen_"

/* separator for open functions in C libraries */
#define LUA_OFSEP	"_"


#define LIBPREFIX	"LOADLIB: "

#define POF		LUA_POF
#define LIB_FAIL	"open"

/* error codes for ll_loadfunc */
#define ERRLIB		1
#define ERRFUNC		2

#if defined(LUA_DL_DLOPEN)
/*
** {========================================================================
** This is an implementation of loadlib based on the dlfcn interface.
** The dlfcn interface is available in Linux, SunOS, Solaris, IRIX, FreeBSD,
** NetBSD, AIX 4.2, HPUX 11, and  probably most other Unix flavors, at least
** as an emulation layer on top of native functions.
** =========================================================================
*/

#include <dlfcn.h>

static void ll_unloadlib (void *lib) {
  dlclose(lib);
}


static void *ll_load (lua_State *L, const char *path) {
  void *lib = dlopen(path, RTLD_NOW);
  if (lib == NULL) lua_pushstring(L, dlerror());
  return lib;
}


static lua_CFunction ll_sym (lua_State *L, void *lib, const char *sym) {
  lua_CFunction f = (lua_CFunction)(long)dlsym(lib, sym);
  if (f == NULL) lua_pushstring(L, dlerror());
  return f;
}

/* }====================================================== */



#elif defined(LUA_DL_DLL)
#include "windows.h"

#undef setprogdir

static void setprogdir (lua_State *L) {
  wchar_t buff[MAX_PATH + 1];
  wchar_t *lb;
  DWORD nsize = sizeof(buff)/sizeof(wchar_t);
  DWORD n = GetModuleFileName(NULL, buff, nsize);
  if (n == 0 || n == nsize || (lb = wcsrchr(buff, '\\')) == NULL)
    luaL_error(L, "unable to get ModuleFileName");
  else {
    *lb = '\0';
	luaL_gsub(L, lua_tostring(L, -1), LUA_EXECDIR, GUI::UTF8FromString(buff).c_str());
    lua_remove(L, -2);  /* remove original string */
  }
}
static void pusherror (lua_State *L) {
  int error = GetLastError();
  char buffer[128];
  if (FormatMessageA(FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM,
      NULL, error, 0, buffer, sizeof(buffer), NULL))
    lua_pushstring(L, buffer);
  else
    lua_pushfstring(L, "system error %d\n", error);
}

static void *ll_load (lua_State *L, const char *path) {
	HINSTANCE lib = LoadLibrary(GUI::StringFromUTF8(path).c_str());
	if (lib == NULL) pusherror(L);
	return lib;
}


static lua_CFunction ll_sym (lua_State *L, void *lib, const char *sym) {
	lua_CFunction f = (lua_CFunction)GetProcAddress((HINSTANCE)lib, sym);
	if (f == NULL) pusherror(L);
	return f;
}
#elif defined(LUA_DL_DYLD)
/*
** {======================================================================
** Native Mac OS X / Darwin Implementation
** =======================================================================
*/

#include <mach-o/dyld.h>


/* Mac appends a `_' before C function names */
#undef POF
#define POF	"_" LUA_POF


static void pusherror (lua_State *L) {
  const char *err_str;
  const char *err_file;
  NSLinkEditErrors err;
  int err_num;
  NSLinkEditError(&err, &err_num, &err_file, &err_str);
  lua_pushstring(L, err_str);
}


static const char *errorfromcode (NSObjectFileImageReturnCode ret) {
  switch (ret) {
    case NSObjectFileImageInappropriateFile:
      return "file is not a bundle";
    case NSObjectFileImageArch:
      return "library is for wrong CPU type";
    case NSObjectFileImageFormat:
      return "bad format";
    case NSObjectFileImageAccess:
      return "cannot access file";
    case NSObjectFileImageFailure:
    default:
      return "unable to load library";
  }
}


static void ll_unloadlib (void *lib) {
  NSUnLinkModule((NSModule)lib, NSUNLINKMODULE_OPTION_RESET_LAZY_REFERENCES);
}


static void *ll_load (lua_State *L, const char *path) {
  NSObjectFileImage img;
  NSObjectFileImageReturnCode ret;
  /* this would be a rare case, but prevents crashing if it happens */
  if(!_dyld_present()) {
    lua_pushliteral(L, "dyld not present");
    return NULL;
  }
  ret = NSCreateObjectFileImageFromFile(path, &img);
  if (ret == NSObjectFileImageSuccess) {
    NSModule mod = NSLinkModule(img, path, NSLINKMODULE_OPTION_PRIVATE |
                       NSLINKMODULE_OPTION_RETURN_ON_ERROR);
    NSDestroyObjectFileImage(img);
    if (mod == NULL) pusherror(L);
    return mod;
  }
  lua_pushstring(L, errorfromcode(ret));
  return NULL;
}


static lua_CFunction ll_sym (lua_State *L, void *lib, const char *sym) {
  NSSymbol nss = NSLookupSymbolInModule((NSModule)lib, sym);
  if (nss == NULL) {
    lua_pushfstring(L, "symbol " LUA_QS " not found", sym);
    return NULL;
  }
  return (lua_CFunction)NSAddressOfSymbol(nss);
}

/* }====================================================== */



#else
/*
** {======================================================
** Fallback for other systems
** =======================================================
*/

#undef LIB_FAIL
#define LIB_FAIL	"absent"


#define DLMSG	"dynamic libraries not enabled; check your Lua installation"


static void ll_unloadlib (void *lib) {
  (void)lib;  /* to avoid warnings */
}


static void *ll_load (lua_State *L, const char *path) {
  (void)path;  /* to avoid warnings */
  lua_pushliteral(L, DLMSG);
  return NULL;
}


static lua_CFunction ll_sym (lua_State *L, void *lib, const char *sym) {
  (void)lib; (void)sym;  /* to avoid warnings */
  lua_pushliteral(L, DLMSG);
  return NULL;
}

/* }====================================================== */
#endif

static void **ll_register (lua_State *L, const char *path) {
  void **plib;
  lua_pushfstring(L, "%s%s", LIBPREFIX, path);
  lua_gettable(L, LUA_REGISTRYINDEX);  /* check library in registry? */
  if (!lua_isnil(L, -1))  /* is there an entry? */
    plib = (void **)lua_touserdata(L, -1);
  else {  /* no entry yet; create one */
    lua_pop(L, 1);
    plib = (void **)lua_newuserdata(L, sizeof(const void *));
    *plib = NULL;
    luaL_getmetatable(L, "_LOADLIB");
    lua_setmetatable(L, -2);
    lua_pushfstring(L, "%s%s", LIBPREFIX, path);
    lua_pushvalue(L, -2);
    lua_settable(L, LUA_REGISTRYINDEX);
  }
  return plib;
}

static int ll_loadfunc (lua_State *L, const char *path, const char *sym) {
  void **reg = ll_register(L, path);
  if (*reg == NULL) *reg = ll_load(L, path);
  if (*reg == NULL)
    return ERRLIB;  /* unable to load library */
  else {
    lua_CFunction f = ll_sym(L, *reg, sym);
    if (f == NULL)
      return ERRFUNC;  /* unable to find function */
    lua_pushcfunction(L, f);
    return 0;  /* return function */
  }
}

static int readable (const char *filename) {
	FILE *f = fopen(GUI::StringFromUTF8(filename).c_str(), GUI_TEXT("r"));  /* try to open file */
	if (f == NULL) return 0;  /* open failed */
	fclose(f);
	return 1;
}


static const char *pushnexttemplate (lua_State *L, const char *path) {
  const char *l;
  while (*path == *LUA_PATHSEP) path++;  /* skip separators */
  if (*path == '\0') return NULL;  /* no more templates */
  l = strchr(path, *LUA_PATHSEP);  /* find next separator */
  if (l == NULL) l = path + strlen(path);
  lua_pushlstring(L, path, l - path);  /* template */
  return l;
}


static const char *findfile (lua_State *L, const char *name,
                                           const char *pname) {
  const char *path;
  name = luaL_gsub(L, name, ".", LUA_DIRSEP);
  lua_getfield(L, LUA_GLOBALSINDEX, "package");
  lua_getfield(L, -1, pname);
  lua_remove(L, -2);
  //lua_getfield(L, LUA_ENVIRONINDEX, pname);
  path = lua_tostring(L, -1);
  if (path == NULL)
    luaL_error(L, LUA_QL("package.%s") " must be a string", pname);
  lua_pushliteral(L, "");  /* error accumulator */
  while ((path = pushnexttemplate(L, path)) != NULL) {
    const char *filename;
    filename = luaL_gsub(L, lua_tostring(L, -1), LUA_PATH_MARK, name);
    lua_remove(L, -2);  /* remove path template */
    if (readable(filename))  /* does file exist and is readable? */
      return filename;  /* return that file name */
    lua_pushfstring(L, "\n\tno file " LUA_QS, filename);
    lua_remove(L, -2);  /* remove file name */
    lua_concat(L, 2);  /* add entry to possible error message */
  }
  return NULL;  /* not found */
}


static void loaderror (lua_State *L, const char *filename) {
  luaL_error(L, "error loading module " LUA_QS " from file " LUA_QS ":\n\t%s",
                lua_tostring(L, 1), filename, lua_tostring(L, -1));
}


static int utf8_loader_Lua (lua_State *L) {
  const char *filename;
  const char *name = luaL_checkstring(L, 1);
  filename = findfile(L, name, "path");
  if (filename == NULL) return 1;  /* library not found in this path */
  if (utf8_luaL_loadfile(L, filename) != 0)
    loaderror(L, filename);
  return 1;  /* library loaded successfully */
}


static const char *mkfuncname (lua_State *L, const char *modname) {
  const char *funcname;
  const char *mark = strchr(modname, *LUA_IGMARK);
  if (mark) modname = mark + 1;
  funcname = luaL_gsub(L, modname, ".", LUA_OFSEP);
  funcname = lua_pushfstring(L, POF"%s", funcname);
  lua_remove(L, -2);  /* remove 'gsub' result */
  return funcname;
}


static int utf8_loader_C (lua_State *L) {
  const char *funcname;
  const char *name = luaL_checkstring(L, 1);
  const char *filename = findfile(L, name, "cpath");
  if (filename == NULL) return 1;  /* library not found in this path */
  funcname = mkfuncname(L, name);
  if (ll_loadfunc(L, filename, funcname) != 0)
    loaderror(L, filename);
  return 1;  /* library loaded successfully */
}


static int utf8_loader_Croot (lua_State *L) {
  const char *funcname;
  const char *filename;
  const char *name = luaL_checkstring(L, 1);
  const char *p = strchr(name, '.');
  int stat;
  if (p == NULL) return 0;  /* is root */
  lua_pushlstring(L, name, p - name);
  filename = findfile(L, lua_tostring(L, -1), "cpath");
  if (filename == NULL) return 1;  /* root not found */
  funcname = mkfuncname(L, name);
  if ((stat = ll_loadfunc(L, filename, funcname)) != 0) {
    if (stat != ERRFUNC) loaderror(L, filename);  /* real error */
    lua_pushfstring(L, "\n\tno module " LUA_QS " in file " LUA_QS,
                       name, filename);
    return 1;  /* function not found */
  }
  return 1;
}

/* }====================================================== */

// ============ LOADLIB ==================================
/* auxiliary mark (for internal use) */
#define AUXMARK		"\1"

static void setpath (lua_State *L, const char *fieldname, const char *envname,
                                   const char *def) {
  const GUI::gui_char* p = getenv(GUI::StringFromUTF8(envname).c_str());
  if (p == NULL)  /* no environment variable? */
    lua_pushstring(L, def);  /* use default */
  else {
    /* replace ";;" by ";AUXMARK;" and then AUXMARK by default path */
	const char* path = GUI::UTF8FromString(p).c_str();
    path = luaL_gsub(L, path, LUA_PATHSEP LUA_PATHSEP,
                              LUA_PATHSEP AUXMARK LUA_PATHSEP);
    luaL_gsub(L, path, AUXMARK, def);
    lua_remove(L, -2);
  }
  setprogdir(L);
  lua_setfield(L, -2, fieldname);
}

static int lua_base_utf8dofile (lua_State *L) {
  const char *fname = luaL_optstring(L, 1, NULL);
  int n = lua_gettop(L);
  if (utf8_luaL_loadfile(L, fname) != 0) lua_error(L);
  lua_call(L, 0, LUA_MULTRET);
  return lua_gettop(L) - n;
}

static int lua_base_utf8loadfile (lua_State *L) {
  const char *fname = luaL_optstring(L, 1, NULL);
  int status = utf8_luaL_loadfile(L, fname);
  if (status == 0)  /* OK? */
    return 1;
  else {
    lua_pushnil(L);
    lua_insert(L, -2);  /* put before error message */
    return 2;  /* return nil plus error message */
  }
}

static const luaL_Reg utf8_string_funcs[] = {
	{"to_utf8", lua_string_to_utf8},
	{"from_utf8", lua_string_from_utf8},
	{"utf8upper", lua_string_utf8_to_upper},
	{"utf8lower", lua_string_utf8_to_lower},
	{"utf8len", lua_string_utf8len},
	{NULL, NULL}
};

static const luaL_Reg utf8_os_funcs[] = {
	{"utf8rename", lua_os_utf8rename},
	{"utf8remove", lua_os_utf8remove},
	{"utf8execute", lua_os_utf8execute},
	{NULL, NULL}
};

static const luaL_Reg utf8_io_funcs[] = {
	{"utf8open", lua_io_utf8open},
	{"utf8input", lua_io_utf8input},
	{"utf8lines", lua_io_lines},
	{"utf8output", lua_io_utf8output},
	{"utf8popen", lua_io_utf8popen},
	{NULL, NULL}
};

static const luaL_Reg utf8_base_funcs[] = {
	{"utf8dofile", lua_base_utf8dofile},
	{"utf8loadfile", lua_base_utf8loadfile},
	{NULL, NULL}
};

static const lua_CFunction utf8_loaders[] =
  {utf8_loader_Lua, utf8_loader_C, utf8_loader_Croot, NULL};

void lua_utf8_register_libs (lua_State *L) {
	luaL_openlibs(L); // register standard libs
	luaL_register(L, "_G", utf8_base_funcs);
	luaL_register(L, LUA_STRLIBNAME, utf8_string_funcs);
	luaL_register(L, LUA_OSLIBNAME, utf8_os_funcs);
	luaL_register(L, LUA_IOLIBNAME, utf8_io_funcs);

	// ************ REGISTER OUR UTF-8 LOADERS ****************************
	lua_getfield(L, LUA_GLOBALSINDEX, "package");
	lua_getfield(L, -1, "loaders");
	lua_remove(L, -2);
	int i = lua_objlen(L, -1);
	for (int k=0; utf8_loaders[k] != NULL; k++) {
		lua_pushcfunction(L, utf8_loaders[k]);
		lua_rawseti(L, -2, i++);
	}
	lua_pop(L, 1);
	// ====================================================================
	// Rewrite "path" and "cpath" in UTF-8
	lua_getglobal(L, LUA_LOADLIBNAME);
	setpath(L, "path", LUA_PATH, LUA_PATH_DEFAULT);  /* set field `path' */
	setpath(L, "cpath", LUA_CPATH, LUA_CPATH_DEFAULT); /* set field `cpath' */
	lua_pop(L, 1);
}