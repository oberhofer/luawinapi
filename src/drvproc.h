//////////////////////////////////////////////////////////////////////////
//
// luawiinapi - winapi wrapper for Lua
// Copyright (C) 2017 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#pragma once

#ifdef __cplusplus
extern "C" {
#endif
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#ifdef __cplusplus
}
#endif


int winapi_RegisterDriverProc(lua_State* L);

