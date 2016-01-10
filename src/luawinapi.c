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

// luacwrap c interface
luacwrap_cinterface* g_luacwrapiface;

//////////////////////////////////////////////////////////////////////////
/**

  registers structures as Lua types

  @param[in]  L  pointer lua state

*/////////////////////////////////////////////////////////////////////////
LUAWINAPI_API int luaopen_luawinapi_core(lua_State *L)
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

  // get c interface
  lua_getfield(L, -1, LUACWARP_CINTERFACE_NAME);
  g_luacwrapiface = (luacwrap_cinterface*)lua_touserdata(L, -1);
  
  // check for C interface
  if (NULL == g_luacwrapiface)
  {
    luaL_error(L, "Could not load luacwrap: No C interface available.");
  }

  // check interface version
  if (LUACWARP_CINTERFACE_VERSION != g_luacwrapiface->version)
  {
    luaL_error(L, "Could not load luacwrap: Incompatiple C interface version. Expected %i got %i.", LUACWARP_CINTERFACE_VERSION, g_luacwrapiface->version);
  }
  
  // drop C interface and drop package table
  lua_pop(L, 2);

  // create module table
  lua_newtable(L);

  // set info fields
  lua_pushstring(L, "Klaus Oberhofer");
  lua_setfield(L, -2, "_AUTHOR");

  lua_pushstring(L, "1.2.0-1");
  lua_setfield(L, -2, "_VERSION");

  lua_pushstring(L, "MIT license: See LICENSE for details.");
  lua_setfield(L, -2, "_LICENSE");

  lua_pushstring(L, "https://github.com/oberhofer/luawinapi");
  lua_setfield(L, -2, "_URL");
  
  // register package functionality
  register_winapi(L);

  register_EnumChildWindows(L);

  LUASTACK_CLEAN(L, 1);
  return 1;
}


