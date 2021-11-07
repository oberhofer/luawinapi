//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>

#include "luatypeconvert.h"
#include "utfstrconvert.h"

int winapi_GetModuleFileNameW( lua_State *L )
{
  int numret = 0;
  HMODULE hMod;
  
  WCHAR* buf    = NULL;
  DWORD  bufLen = 512;
  DWORD  retLen;

  hMod = (HMODULE)winapi_tohandle(L, 1);

  while (32768 >= bufLen)
  {
    if (!(buf = (WCHAR*)malloc(sizeof(WCHAR) * (size_t)bufLen)))
    {
      // Insufficient memory
      lua_pushnil(L); ++numret;
      lua_pushnumber(L, E_OUTOFMEMORY); ++numret;

      return numret;
    }

    if (!(retLen = GetModuleFileName(hMod, buf, bufLen)))
    {
        // GetModuleFileName failed
        free(buf);

        lua_pushnil(L); ++numret;
        lua_pushnumber(L, GetLastError()); ++numret;

        return numret;
    }
    else if (bufLen > retLen)
    {
      // Success
      // marshal retval
      winapi_pushlwidestring_Z(L, buf, retLen); ++numret;
        
      free(buf);
      return numret;
    }

    free(buf);
    bufLen <<= 1;
  }

  // Path too long
  
  lua_pushnil(L); ++numret;
  lua_pushnumber(L, ERROR_INSUFFICIENT_BUFFER); ++numret;
  
  return numret;
}


