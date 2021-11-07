//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include "utfstrconvert.h"
#include <malloc.h>

#include "luacwrap.h"

extern luacwrap_cinterface* g_luacwrapiface;

//////////////////////////////////////////////////////////////////////////
/**

  Push wide string as UTF-8 string

*/////////////////////////////////////////////////////////////////////////
int winapi_pushlwidestring_Z(lua_State* L, LPCWSTR source, size_t sourcelen)
{
  // convert UCS2 text to UTF-8
  int destsize = WideCharToMultiByte(CP_UTF8, 0, source, sourcelen, 0, 0, NULL, NULL) + 1;
  LPSTR dest = (LPSTR)_alloca(destsize * sizeof(CHAR));
  WideCharToMultiByte(CP_UTF8, 0, source, sourcelen, dest, destsize, NULL, NULL);
  dest[destsize-1] = L'\0';

  lua_pushlstring(L, dest, destsize);

  return 1;
}

//////////////////////////////////////////////////////////////////////////
/**

  Convert UTF-8 encoded string to UCS2 encoded string.
  The function accepts a lua string type as input.
  The input is interpreted as an UTF-8 encoded string and converts it into a
  UCS2 encoded lua string.

*/////////////////////////////////////////////////////////////////////////
LPCWSTR winapi_widestringfromutf8_Z(lua_State* L, int idx, size_t* destlen)
{
  size_t sourcelen = 0;
  LPCSTR source = luaL_checklstring(L, idx, &sourcelen);

  // convert UTF-8 text to UTF-16
  int destsize = MultiByteToWideChar(CP_UTF8, 0, source, sourcelen, 0, 0) + 1;
  LPWSTR dest = (LPWSTR)_alloca(destsize * sizeof(WCHAR));
  MultiByteToWideChar(CP_UTF8, 0, source, sourcelen, dest, destsize);
  dest[destsize-1] = L'\0';

  lua_pushlstring(L, (const char*)dest, destsize * sizeof(WCHAR));

  if (destlen)
  {
    *destlen = destsize;
  }

  return (LPCWSTR)(lua_tostring(L, -1));
}

//////////////////////////////////////////////////////////////////////////
/**

  Convert value to UTF-16 encoded string.
  Include terminating "\0".

*/////////////////////////////////////////////////////////////////////////
LPCWSTR winapi_towidestring_Z(lua_State* L, int idx)
{
  LPCWSTR v = 0;
  switch (lua_type(L, idx))
  {
    case LUA_TLIGHTUSERDATA:
    {
      // Not so happy with this, as interpreting the light user data pointer
      // as a pointer to a null terminated string could be wrong 
      // and therefore is not a safe operation.
      LPCWSTR source = (LPCWSTR)lua_touserdata(L, idx);
      winapi_pushlwidestring_Z(L, source, -1);
      v = winapi_widestringfromutf8_Z(L, -1, NULL);
      lua_remove(L, -2);
    }
    break;
    case LUA_TUSERDATA:
    {
      // if this is a user data we check for luacwrap types and
      // decide what to do
      luacwrap_Type* desc = g_luacwrapiface->getdescriptor(L, idx);
      switch (desc->typeclass)
      {
        // for arrays we check the element size and
        // decide to interpret it as an UTF-8 or UCS2 string
        case LUACWRAP_TC_ARRAY:
        {
          luacwrap_ArrayType* arrdesc = (luacwrap_ArrayType*)desc;

          if (sizeof(UINT16) == arrdesc->elemsize)
          {
            // interpret as widestring
            LPCWSTR source = (LPCWSTR)lua_touserdata(L, idx);
            winapi_pushlwidestring_Z(L, source, arrdesc->elemcount);
            v = winapi_widestringfromutf8_Z(L, -1, NULL);
            lua_remove(L, -2);
          }
          else if (sizeof(UINT8) == arrdesc->elemsize)
          {
            // interpret as UTF8 encoded string
            LPCSTR source = (LPCSTR)lua_touserdata(L, idx);
            lua_pushlstring(L, source, arrdesc->elemcount);
            v = winapi_widestringfromutf8_Z(L, -1, NULL);
            lua_remove(L, -2);
          }
        }
        break;

        // for buffers interpret it as an UTF-8 string
        case LUACWRAP_TC_BUFFER:
        {
          luacwrap_BufferType* bufdesc = (luacwrap_BufferType*)desc;

          // interpret as UTF8 encoded string
          LPCSTR source = (LPCSTR)lua_touserdata(L, idx);
          lua_pushlstring(L, source, bufdesc->size);
          v = winapi_widestringfromutf8_Z(L, -1, NULL);
          lua_remove(L, -2);
        }
        break;

        default:
        {
          // assert(0);
          luaL_argerror(L, idx, "called winapi_towidestring_Z on unsupported luacwrap type");
        }
        break;
      }
    }
    break;
    case LUA_TSTRING:
    {
      v = winapi_widestringfromutf8_Z(L, idx, NULL);
    }
    break;
    default:
    {
      const char* msg = lua_pushfstring(L, "string or userdata expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    }
    break;
  }
  return v;
}

//////////////////////////////////////////////////////////////////////////
/**

  convert value to UTF-16 encoded string

*/////////////////////////////////////////////////////////////////////////
LPCWSTR winapi_towidestring_or_atom(lua_State* L, int idx)
{
  LPCWSTR v = 0;
  switch (lua_type(L, idx))
  {
    // case LUA_TLIGHTUSERDATA:
    // case LUA_TUSERDATA:
    // {
    //   v = (LPCWSTR)lua_touserdata(L, idx);
    // }
    // break;
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
    default:
    {
      const char* msg = lua_pushfstring(L, "LPCWSTR or ATOM expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    }
    break;
  }
  return v;
}

//////////////////////////////////////////////////////////////////////////
/**

  convert value to UTF-16 encoded string

*/////////////////////////////////////////////////////////////////////////
LPCWSTR winapi_towidestring_or_atom_Z(lua_State* L, int idx)
{
  LPCWSTR v = 0;
  switch (lua_type(L, idx))
  {
    // case LUA_TLIGHTUSERDATA:
    // case LUA_TUSERDATA:
    // {
    //   v = (LPCWSTR)lua_touserdata(L, idx);
    // }
    // break;
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
    default:
    {
      const char* msg = lua_pushfstring(L, "LPCWSTR or ATOM expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    }
    break;
  }
  return v;
}

//////////////////////////////////////////////////////////////////////////
/**

  Convert UCS2 encoded string to UTF-8 encoded string.
  The function accepts a lua string type as input. 
  The input is interpreted as a UCS2 encoded string and converts it into a
  UTF-8 encoded lua string.

*/////////////////////////////////////////////////////////////////////////
LPCSTR winapi_utf8fromwidestring_Z(lua_State* L, int idx, size_t* destlen)
{
  LPCSTR v = 0;
  switch (lua_type(L, idx))
  {
    case LUA_TLIGHTUSERDATA:
    {
      // Not so happy with this, as interpreting the light user data pointer
      // as a pointer to a null terminated string could be wrong 
      // and therefore is not a safe operation.
      LPCWSTR source = (LPCWSTR)g_luacwrapiface->mobjgetbaseptr(L, idx);
      winapi_pushlwidestring_Z(L, source, -1);
      v = lua_tostring(L, -1);
    }
    break;
    case LUA_TUSERDATA:
    {
      // if this is a user data we check for luacwrap types and
      // decide what to do
      luacwrap_Type* desc = g_luacwrapiface->getdescriptor(L, idx);
      switch (desc->typeclass)
      {
        // for arrays we check the element size and
        // decide to interpret it as an UTF-8 or UCS2 string
        case LUACWRAP_TC_ARRAY:
        {
          luacwrap_ArrayType* arrdesc = (luacwrap_ArrayType*)desc;

          if (sizeof(UINT16) == arrdesc->elemsize)
          {
            // interpret as widestring
            LPCWSTR source = (LPCWSTR)g_luacwrapiface->mobjgetbaseptr(L, idx);
            winapi_pushlwidestring_Z(L, source, arrdesc->elemcount);
            v = lua_tostring(L, -1);
          }
          else if (sizeof(UINT8) == arrdesc->elemsize)
          {
            // interpret as UTF8 encoded string
            LPCSTR source = (LPCSTR)g_luacwrapiface->mobjgetbaseptr(L, idx);
            lua_pushlstring(L, source, arrdesc->elemcount);
            v = lua_tostring(L, -1);
          }
        }
        break;

        // for buffers interpret it as an UTF-8 string
        case LUACWRAP_TC_BUFFER:
        {
          luacwrap_BufferType* bufdesc = (luacwrap_BufferType*)desc;

          // interpret as UTF8 encoded string
          LPCSTR source = (LPCSTR)g_luacwrapiface->mobjgetbaseptr(L, idx);
          lua_pushlstring(L, source, bufdesc->size);
          v = lua_tostring(L, -1);
        }
        break;

        default:
        {
          // assert(0);
          luaL_argerror(L, idx, "called winapi_towidestring_Z on unsupported luacwrap type");
        }
        break;
      }
    }
    break;
    case LUA_TSTRING:
    {
      size_t sourcelen;

      // convert 
      LPCWSTR source = (LPCWSTR)lua_tolstring(L, idx, &sourcelen);
      winapi_pushlwidestring_Z(L, source, sourcelen);
      v = lua_tostring(L, -1);
    }
    break;
    default:
    {
      const char* msg = lua_pushfstring(L, "string or userdata expected but got %s", luaL_typename(L, idx));
      luaL_argerror(L, idx, msg);
    }
    break;
  }
  return v;
}
