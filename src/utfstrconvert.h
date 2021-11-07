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

// UCS2/UTF-8 conversion
extern LPCWSTR winapi_widestringfromutf8_Z(lua_State* L, int idx, size_t* destlen);
extern LPCSTR  winapi_utf8fromwidestring_Z(lua_State* L, int idx, size_t* destlen);

// push widestring as UTF-8 Lua string
extern int winapi_pushlwidestring_Z(lua_State* L, LPCWSTR source, size_t sourcelen);

// Lua type -> widestring with terminating "\0"
extern LPCWSTR winapi_towidestring_Z(lua_State* L, int idx);
extern LPCWSTR winapi_towidestring_or_atom_Z(lua_State* L, int idx);
