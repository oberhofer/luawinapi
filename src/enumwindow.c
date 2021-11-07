//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
// wraps window enumeration callbacks
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>
#include <assert.h>

#include "luaaux.h"

#include "gen_abstractions.h"

#include "utfstrconvert.h"


BOOL CALLBACK EnumProc(HWND hwndChild, LPARAM lParam)
{
  BOOL result;

  lua_State* L = (lua_State*)lParam;

  lua_pushvalue(L, -1);           // push function
  lua_pushWindow(L, hwndChild);   // push window handle
  lua_call(L, 1, 1);              // call function

  // unmarshal return value
  result = lua_toboolean(L, -1);
  lua_pop(L, 1);

  return result;
}

#ifdef UNDER_CE
BOOL EnumChildWindows(HWND hWndParent,
                      WNDENUMPROC lpEnumFunc,
                      LPARAM lParam)
{
  BOOL result;
  HWND hFirst, hNext;

  result = 0;
  hFirst =
  hNext = GetWindow(hWndParent, GW_CHILD);
  while (hNext)
  {
    result = 1;

    if (FALSE == lpEnumFunc(hNext, lParam))
    {
      return result;
    }

    hNext = GetWindow(hNext, GW_HWNDNEXT);
    if (hNext == hFirst)
    {
      break;
    }
  }
  return result;
}

BOOL EnumThreadWindows(DWORD threadid,
                       WNDENUMPROC lpEnumFunc,
                       LPARAM lParam)
{
  BOOL result;
  HWND hFirst, hNext;

  result = 0;
  hFirst =
  hNext = GetWindow(NULL, GW_CHILD);
  while (hNext)
  {
    result = 1;

    if (threadid == GetWindowThreadProcessId(hNext, NULL))
    {
      if (FALSE == lpEnumFunc(hNext, lParam))
      {
        return result;
      }
    }
    
    hNext = GetWindow(hNext, GW_HWNDNEXT);
    if (hNext == hFirst)
    {
      break;
    }
  }
  return result;
}
#endif


int winapi_EnumChildWindows(lua_State* L)
{
  HWND hwndParent;

  LUASTACK_SET(L);

  hwndParent = lua_toWindow(L, 1);

  if (lua_isfunction(L, 2))
  {
    EnumChildWindows(hwndParent, EnumProc, (LPARAM)L);
  }
  else
  {
    const char *msg = lua_pushfstring(L, "function expected but got %s", luaL_typename(L, 2));
    luaL_argerror(L, 2, msg);
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}


int winapi_EnumThreadWindows(lua_State* L)
{
  DWORD threadId;

  LUASTACK_SET(L);

  threadId = (DWORD)lua_tonumber(L, 1);

  if (lua_isfunction(L, 2))
  {
    EnumThreadWindows(threadId, EnumProc, (LPARAM)L);
  }
  else
  {
    const char *msg = lua_pushfstring(L, "function expected but got %s", luaL_typename(L, 2));
    luaL_argerror(L, 2, msg);
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

int winapi_EnumWindows(lua_State* L)
{
  LUASTACK_SET(L);

  if (lua_isfunction(L, 2))
  {
    EnumWindows(EnumProc, (LPARAM)L);
  }
  else
  {
    const char *msg = lua_pushfstring(L, "function expected but got %s", luaL_typename(L, 2));
    luaL_argerror(L, 2, msg);
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

int winapi_GetWindowThreadProcessId(lua_State* L)
{
  HWND hwnd;
  DWORD threadId, processId;

  LUASTACK_SET(L);

  hwnd = lua_toWindow(L, 1);

  threadId = GetWindowThreadProcessId(hwnd, &processId);

  lua_pushnumber(L, threadId);
  lua_pushnumber(L, processId);

  LUASTACK_CLEAN(L, 2);
  return 2;
}

int winapi_GetClassNameW(lua_State* L)
{
  HWND hwnd;
  size_t size;
  WCHAR buffer[2048];
  LUASTACK_SET(L);

  hwnd = lua_toWindow(L, 1);

  size = GetClassNameW(hwnd, (LPWSTR)&buffer, ARRAYSIZE(buffer));
  if (size)
  {
    winapi_pushlwidestring_Z(L, buffer, size);

    LUASTACK_CLEAN(L, 1);
    return 1;
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

static const luaL_Reg methods[ ] = {
  { "GetClassNameW",       winapi_GetClassNameW},
  { "EnumWindows",         winapi_EnumWindows },
  { "EnumChildWindows",    winapi_EnumChildWindows },
  { "EnumThreadWindows",   winapi_EnumThreadWindows },
  { "GetWindowThreadProcessId",   winapi_GetWindowThreadProcessId },
  { NULL, NULL }
};


int register_EnumChildWindows(lua_State* L)
{
  LUASTACK_SET(L);

  // create method table
#if (LUA_VERSION_NUM > 501)
  luaL_setfuncs(L, methods, 0);
#else
  luaL_openlib(L, NULL, methods, 0);
#endif

  LUASTACK_CLEAN(L, 0);
  return 0;
}
