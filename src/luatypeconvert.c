//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include "luatypeconvert.h"
#include "utfstrconvert.h"


//////////////////////////////////////////////////////////////////////////
/**

  convert value to LPARAM/WPARAM

*/////////////////////////////////////////////////////////////////////////
UINT_PTR winapi_tolwparam( lua_State *L, int idx )
{
  UINT_PTR v = 0;
  switch (lua_type(L, idx))
  {
    case LUA_TLIGHTUSERDATA:
    case LUA_TUSERDATA:
    {
      v = (UINT_PTR)lua_touserdata(L, idx);
    }
    break;
    case LUA_TSTRING:
    {
      v = (UINT_PTR)lua_tostring(L, idx);
    }
    break;
    case LUA_TNUMBER:
    {
      v = (UINT_PTR)lua_tointeger(L, idx);
    }
    break;
    case LUA_TNONE:
    case LUA_TNIL:
      // accept none and nil
    break;
    default:
    {
      const char *msg = lua_pushfstring(L, "LPARAM or WPARAM expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    } 
    break;
  }
  return v;
} 


//////////////////////////////////////////////////////////////////////////
/**

  convert value to HANDLE

*/////////////////////////////////////////////////////////////////////////
HANDLE winapi_tohandle( lua_State *L, int idx )
{
  HANDLE v = 0;
  switch (lua_type(L, idx))
  {
    case LUA_TLIGHTUSERDATA:
    case LUA_TUSERDATA:
    {
      v = (HANDLE)lua_touserdata(L, idx);
    }
    break;
    case LUA_TNUMBER:
    {
      v = (HANDLE)lua_tointeger(L, idx);
    }
    break;
    case LUA_TNONE:
    case LUA_TNIL:
      // accept none and nil
    break;
    default:
    {
      const char *msg = lua_pushfstring(L, "HANDLE (number or userdata) expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    } 
    break;
  }
  return v;
} 

//////////////////////////////////////////////////////////////////////////
/**

  convert value to resource reference

*/////////////////////////////////////////////////////////////////////////
LPCWSTR winapi_toresourceref( lua_State *L, int idx )
{
  LPCWSTR v = 0;
  switch (lua_type(L, idx))
  {
    case LUA_TSTRING:
    {
      v = winapi_widestringfromutf8_Z(L, idx, NULL);
    }
    break;
    case LUA_TNUMBER:
    {
      v = (LPCWSTR)lua_tointeger(L, idx);
    }
    break;
    case LUA_TNONE:
    case LUA_TNIL:
      // accept none and nil
    break;
    default:
    {
      const char *msg = lua_pushfstring(L, "RESOURCEREF (number or string) expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    } 
    break;
  }
  return v;
} 

