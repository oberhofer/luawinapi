//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include <stdlib.h>
#include <string.h>

#include "luaaux.h"
#include "luacwrap.h"

#include "stdcallthunk.h"

#ifndef LUAWINAPI_API
#define LUAWINAPI_API __declspec(dllexport)
#endif

extern int register_winapi(lua_State *L);
extern int register_EnumChildWindows(lua_State* L);


//////////////////////////////////////////////////////////////////////////
/**

  registers structures as Lua types

  @param[in]  L  pointer lua state

*/////////////////////////////////////////////////////////////////////////
LUAWINAPI_API int luaopen_luawinapi(lua_State *L)
{
  LUASTACK_SET(L);

  // init stdcallthunk module
  stdcallthunk_initialize();
  atexit(stdcallthunk_finalize);

  // luacwrap = require("luacwrap")
  lua_getglobal(L, "require");
  lua_pushstring(L, "luacwrap");
  lua_call(L, 1, 1);
  // lua_setfield(L, LUA_ENVIRONINDEX, "luacwrap");

  // we do not need the package table
  lua_pop(L, 1);

  // create module table
  lua_newtable(L);

  // register package functionality
  register_winapi(L);

  register_EnumChildWindows(L);

  LUASTACK_CLEAN(L, 1);
  return 1;
}


