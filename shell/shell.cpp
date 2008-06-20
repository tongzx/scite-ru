//build@ gcc -shared -o shell.dll -I shell.cpp scite.la -lstdc++

#include <windows.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

#pragma warning(push)
#pragma warning(disable: 4710)

template < class T, int defSize >
class CMemBuffer
{
public:
	CMemBuffer()
	 : m_iSize( defSize )
	 , m_pData( NULL )
	{
		SetLength( defSize );
	}

	~CMemBuffer()
	{
		SetLength( 0 );
	}

	BOOL IsBufferEmpty()
	{
		return m_pData == NULL;
	}

	T* GetBuffer()
	{
		return m_pData;
	}

	T& operator [] ( int nItem )
	{
		return m_pData[ nItem ];
	}

	int GetBufferLength()
	{
		return m_iSize;
	}

	// установить длинну буфера точно
	// 0 - очищает буфер
	BOOL SetLength( int lenNew )
	{
		if ( lenNew > 0 )
		{
			T* sNew = (T*)malloc( lenNew * sizeof(T) );
//			T* sNew = (T*)::VirtualAlloc( NULL, lenNew * sizeof(T), MEM_COMMIT, PAGE_READWRITE );
			if ( sNew != NULL )
			{
				if ( !IsBufferEmpty() )
				{
					memcpy( sNew,
							m_pData,
							lenNew > m_iSize ? m_iSize * sizeof(T) : lenNew * sizeof(T) );
//					::VirtualFree( m_pData, 0, MEM_RELEASE );
					free( m_pData );
					m_pData = NULL;
				}
				m_pData = sNew;
				m_iSize = lenNew;
			}
			else
			{
				return FALSE;
			}
		}
		else
		{
			if ( !IsBufferEmpty() )
			{
//				::VirtualFree( m_pData, 0, MEM_RELEASE );
				free( m_pData );
				m_pData = NULL;
			}
			m_iSize = 0;
		}
		return TRUE;
	}

private:
	T* m_pData;
	int m_iSize;
};

class CSimpleString
{
public:
	CSimpleString()
	 : m_iLen( 0 )
	{
	}

	const char* GetString()
	{
		return ( m_iLen == 0 || m_sData.IsBufferEmpty() ) ? "" : m_sData.GetBuffer();
	}

	int GetLenght()
	{
		return m_iLen;
	}

	void Empty()
	{
		m_sData.SetLength( 0 );
		m_iLen = 0;
	}

	void Append( const char *str )
	{
		if ( str != NULL )
		{
			int len = lstrlenA( str );
			int newLength = m_iLen + len;
			if ( m_sData.SetLength( newLength + 1 ) )
			{
				m_sData[ m_iLen ] = '\0';
				lstrcatA( m_sData.GetBuffer(), str );
				m_iLen = newLength;
			}
		}
	}

private:
	CMemBuffer< char, 128 > m_sData;
	int m_iLen;
};

//!-start-[os.run]
static void lua_pushlasterr( lua_State* L, const char* lpszFunction )
{
	char* lpMsgBuf;
	DWORD dw = ::GetLastError();
	::FormatMessageA( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
					  NULL,
					  dw,
					  MAKELANGID( LANG_NEUTRAL, SUBLANG_DEFAULT ),
					  (LPSTR)&lpMsgBuf,
					  0,
					  NULL );

	UINT uBytes = ( lstrlenA( lpMsgBuf ) + lstrlenA( lpszFunction ) + 40 ) * sizeof(char);
	char* lpDisplayBuf = (char*)::LocalAlloc( LMEM_ZEROINIT, uBytes );
	sprintf( lpDisplayBuf, "%s failed with error %d: %s", lpszFunction, dw, lpMsgBuf );
	lua_pushstring( L, lpDisplayBuf );
	::LocalFree( lpMsgBuf );
	::LocalFree( lpDisplayBuf );
}

static int run( lua_State* L )
{
	static const int MAX_CMD = 1024;

	int top = lua_gettop( L );
	if ( top == 0 )
	{
		lua_pushnil( L );
		lua_pushstring( L, "No parameters!" );
		return 2;
	}

	if ( top > 0 )
	{
		if( !lua_isstring( L, 1 ) )
		{
			lua_pushnil( L );
			lua_pushstring( L, "First param must be a string!" );
			return 2;
		}
	}

	// считываем STARTUPINFO
	STARTUPINFO si = { sizeof(si) };
	if ( top > 1 )
	{
		if ( !lua_isnumber( L, 2 ) )
		{
			lua_pushnil( L );
			lua_pushstring( L, "Second param must be a number!" );
			return 2;
		}
		si.dwFlags = STARTF_USESHOWWINDOW;
		si.wShowWindow = (WORD)lua_tonumber( L, 2 );
	}

	// считываем флаг ожидания процесса
	BOOL bDoWait = FALSE;
	if ( top > 2 )
	{
		if ( !lua_isboolean( L, 3 ) )
		{
			lua_pushnil( L );
			lua_pushstring( L, "Thrid param must be a boolean!" );
			return 2;
		}
		bDoWait = lua_toboolean( L, 3 );
	}

	// устанавливаем именованные каналы на потоки ввода/вывода
	BOOL bUsePipes = FALSE;
	HANDLE FWritePipe = NULL;
	HANDLE FReadPipe = NULL;
	SECURITY_ATTRIBUTES pa = { sizeof(pa), NULL, TRUE };
	if ( bDoWait != FALSE && si.wShowWindow == 0 )
	{
		bUsePipes = ::CreatePipe( &FReadPipe, &FWritePipe, &pa, 0 );
 		if ( bUsePipes != FALSE )
 		{
 			si.hStdOutput = FWritePipe;
 			si.hStdInput = FReadPipe;
 			si.hStdError = FWritePipe;
 			si.dwFlags = STARTF_USESTDHANDLES | si.dwFlags;
 		}
	}

	// запускаем процесс
	CMemBuffer< char, MAX_CMD > bufCmdLine; // строковой буфер длиной MAX_CMD
	// эта функция дописывает нули сама, нет смысла делать ZeroMemory
	strncpy( bufCmdLine.GetBuffer(), luaL_checkstring( L, 1 ), MAX_CMD - 1 );
	PROCESS_INFORMATION pi = { 0 };
	BOOL RetCode = ::CreateProcess( NULL, // No module name, use command line
									bufCmdLine.GetBuffer(), // Command line
									NULL, // Process handle not inheritable
									NULL, // Thread handle not inheritable
									TRUE, // Set handle inheritance to FALSE
									0, // No creation flags
									NULL, // Use parent's environment block
									NULL, // Use parent's starting directory
									&si, // Pointer to STARTUPINFO structure
									&pi ); // Pointer to PROCESS_INFORMATION structure

	// если провалили запуск сообщаем об ошибке
	if ( RetCode == 0 )
	{
		lua_pushnil( L );
		lua_pushlasterr( L, "run" );
		if ( bUsePipes != FALSE )
		{
			::CloseHandle( FReadPipe );
			::CloseHandle( FWritePipe );
		}
		return 2;
	}

	// закрываем описатель потока, в нем нет необходимости 
	::CloseHandle( pi.hThread );

	// ожидаем завершение работы процесса
	CSimpleString strOut;
	if ( bDoWait != FALSE )
	{
		if ( bUsePipes != FALSE )
		{
			DWORD BytesToRead = 0;
			DWORD BytesRead = 0;
			DWORD TotalBytesAvail = 0;
			DWORD PipeReaded = 0;
			DWORD exit_code = 0;
			CMemBuffer< char, MAX_CMD > bufStr; // строковой буфер длиной MAX_CMD
			while ( ::PeekNamedPipe( FReadPipe, NULL, 0, &BytesRead, &TotalBytesAvail, NULL ) )
			{
				if ( TotalBytesAvail == 0 )
				{
					if ( ::GetExitCodeProcess( pi.hProcess, &exit_code ) == FALSE ||
						 exit_code != STILL_ACTIVE )
					{
						break;
					}
					else
					{
						continue;
					}
				}
				else
				{
					while ( TotalBytesAvail > BytesRead )
					{
						if ( TotalBytesAvail - BytesRead > MAX_CMD - 1 )
						{
							BytesToRead = MAX_CMD - 1;
						}
						else
						{
							BytesToRead = TotalBytesAvail - BytesRead;
						}
						if ( ::ReadFile( FReadPipe,
										 bufCmdLine.GetBuffer(),
										 BytesToRead,
										 &PipeReaded,
										 NULL ) == FALSE )
						{
							break;
						}
						if ( PipeReaded <= 0 ) continue;
						BytesRead += PipeReaded;
						bufCmdLine[ PipeReaded ] = '\0';
						::OemToAnsi( bufCmdLine.GetBuffer(), bufStr.GetBuffer() );
						strOut.Append( bufStr.GetBuffer() );
					}
				}
			}
		}
		else
		{
			// ждем пока процесс не завершится
			::WaitForSingleObject( pi.hProcess, INFINITE );
		}
	}

	// Код завершения процесса
	DWORD exit_code = 0;
	::GetExitCodeProcess( pi.hProcess, &exit_code );
	::CloseHandle( pi.hProcess );
	lua_pushnumber( L, exit_code );

	if ( bUsePipes  != FALSE )
	{
		::CloseHandle( FReadPipe );
		::CloseHandle( FWritePipe );
		lua_pushstring( L, strOut.GetString() );
		return 2;
	}
	return 1;
}
//!-end-[os.run]

//!-start-[MsgBox]
static int msgbox( lua_State* L )
{
	const char* text = luaL_checkstring( L, 1 );
	const char* title = lua_tostring( L, 2 );
	int options = (int)lua_tonumber( L, 3 ) | MB_TASKMODAL;
	int retCode = ::MessageBox( NULL, text, title == NULL ? "SciTE" : title, options );
	lua_pushnumber( L, retCode );
	return 1;
}
//!-end-[MsgBox]

//!-start-[FileAttr]
static int getfileattr( lua_State *L )
{
	const char* FN = luaL_checkstring( L, -1 );
	WIN32_FILE_ATTRIBUTE_DATA fad;
	if ( ::GetFileAttributesEx( FN, GetFileExInfoStandard, &fad ) == FALSE )
	{
		lua_pushnil( L );
		lua_pushlasterr( L,"getfileattr" );
		return 2;
	}
	lua_pushnumber( L, fad.dwFileAttributes );
	return 1;
}

static int setfileattr( lua_State* L )
{
	const char* FN = luaL_checkstring( L, -2 );
	DWORD attr = luaL_checkint( L, -1 );
	if ( ::SetFileAttributes( FN, attr ) == FALSE )
	{
		lua_pushnil( L );
		lua_pushlasterr( L, "setfileattr" );
		return 2;
	}
	lua_pushnumber( L, 1 );
	return 1;
}
//!-end-[FileAttr]

static int exec( lua_State* L )
{
	const char* file = lua_tostring( L, 1 );
	const char* parms = lua_tostring( L, 2 );
	int noshow = lua_toboolean( L, 3 );
	const char* verb = lua_tostring( L, 4 );
	HINSTANCE hInst = ::ShellExecute( NULL,
									  verb,
									  file,
									  parms,
									  NULL,
									  noshow ? SW_HIDE : SW_SHOWNORMAL );
	lua_pushboolean( L, (int)hInst > 32 );
	return 1;
}

static int getclipboardtext( lua_State* L )
{
	CSimpleString clipText;
	if ( ::IsClipboardFormatAvailable( CF_TEXT ) )
	{
		if ( ::OpenClipboard( NULL ) )
		{
			HANDLE hData = ::GetClipboardData( CF_TEXT );
			if ( hData != NULL )
			{
				clipText.Append( (char*)::GlobalLock( hData ) );
				::GlobalUnlock( hData );
			}
			::CloseClipboard();
		}
	}
	lua_pushstring( L, clipText.GetString() );
	return 1;
}

//!-start-[find]
static CMemBuffer< HANDLE, 4 > st_buf_hFind;
static CMemBuffer< WIN32_FIND_DATA, 4 > st_buf_FindData;
static int st_iStartsFind = 0;

static int beginfindfile( lua_State* L )
{
	const char *findfilename = luaL_checkstring( L, 1 );

	if ( st_buf_hFind.GetBufferLength() < st_iStartsFind + 1 )
	{
		st_buf_hFind.SetLength( st_iStartsFind + 1 );
		st_buf_FindData.SetLength( st_iStartsFind + 1 );
	}

	st_buf_hFind[ st_iStartsFind ] = ::FindFirstFile( findfilename,
													  &st_buf_FindData[ st_iStartsFind ] );
	lua_pushboolean( L, st_buf_hFind[ st_iStartsFind ] != INVALID_HANDLE_VALUE );
	st_iStartsFind++;
	return 1;
}

static int nextfindfile( lua_State* L )
{
	if ( st_iStartsFind > 0 && st_buf_hFind.GetBufferLength() >= st_iStartsFind )
	{
		if ( st_buf_hFind[ st_iStartsFind - 1 ] != INVALID_HANDLE_VALUE )
		{
			WIN32_FIND_DATA last_find_data = st_buf_FindData[ st_iStartsFind - 1 ];

			if ( ::FindNextFile( st_buf_hFind[ st_iStartsFind - 1 ],
								 &st_buf_FindData[ st_iStartsFind - 1 ] ) == FALSE )
			{
				lua_pushboolean( L, FALSE );
				st_buf_hFind[ st_iStartsFind - 1 ] = INVALID_HANDLE_VALUE;
			}
			else
			{
				lua_pushboolean( L, TRUE );
			}

			lua_pushstring( L, last_find_data.cFileName );
			lua_pushnumber( L, last_find_data.dwFileAttributes );

			lua_Number filesize = last_find_data.nFileSizeHigh;
			lua_Number mulnamber = MAXDWORD;
			mulnamber += 1;
			filesize *= mulnamber;
			filesize += last_find_data.nFileSizeLow;
			lua_pushnumber( L, filesize );

			return 4;
		}
		lua_pushboolean( L, FALSE );
		return 1;
	}

	::SetLastError( ERROR_INVALID_HANDLE );
	lua_pushlasterr( L, "endfindfile" );
	return 1;
}

static int endfindfile( lua_State* L )
{
	if ( st_iStartsFind > 0 && st_buf_hFind.GetBufferLength() >= st_iStartsFind )
	{
		st_iStartsFind--;
		if ( st_buf_hFind[ st_iStartsFind ] != INVALID_HANDLE_VALUE )
		{
			::FindClose( st_buf_hFind[ st_iStartsFind ] );
			st_buf_hFind[ st_iStartsFind ] = INVALID_HANDLE_VALUE;
		}
		return 0;
	}

	::SetLastError( ERROR_INVALID_HANDLE );
	lua_pushlasterr( L, "endfindfile" );
	return 1;
}
//!-end-[find]

static int fileexists( lua_State* L )
{
	LPCTSTR filename = luaL_checkstring( L, 1 );
	if ( ::GetFileAttributes(filename) != DWORD(-1) ) {
		lua_pushboolean( L, TRUE );
		return 1;
	}
	lua_pushboolean( L, FALSE );
	return 1;
}

#pragma warning(pop)

static const struct luaL_reg shell[] = 
{
	{ "exec", exec },
	{ "run", run },
	{ "msgbox", msgbox },
	{ "getfileattr", getfileattr },
	{ "setfileattr", setfileattr },
	{ "getclipboardtext", getclipboardtext },
	{ "beginfindfile", beginfindfile },
	{ "nextfindfile", nextfindfile },
	{ "endfindfile", endfindfile },
	{ "fileexists", fileexists },
	{ NULL, NULL }
};

extern "C" __declspec(dllexport) int luaopen_shell( lua_State* L )
{
	luaL_register( L, "shell", shell );
	return 1;
}
