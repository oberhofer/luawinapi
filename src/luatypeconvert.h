//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#pragma once

#include <Windows.h>

#ifdef __cplusplus
extern "C" {
#endif
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#ifdef __cplusplus
}
#endif

// typo conversion functions
extern UINT_PTR winapi_tolwparam      (lua_State *L, int idx);
extern HANDLE   winapi_tohandle       (lua_State *L, int idx);
extern LPCWSTR  winapi_toresourceref  (lua_State *L, int idx);
