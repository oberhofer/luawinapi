//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>
#include <assert.h>

#include "luaaux.h"

#include "stdcallthunk.h"
#include "wndproc.h"

#include "gen_abstractions.h"

//////////////////////////////////////////////////////////////////////////
/**

  WNDPROC wrapper object

*/////////////////////////////////////////////////////////////////////////
typedef struct
{
  lua_State* L;
  int        objectRef;
  int        functionRef;
  PVOID      pThunk;
  WNDPROC    prevProc;
} WndProcThunk;

const char* WndProc_Typename  = "WndProc";


static int winapi_WndProc_new(lua_State* L);
static int winapi_WndProc_subclass(lua_State* L);

static int winapi_WndProc_gc(lua_State* L);
static int winapi_WndProc_index(lua_State* L);


static const luaL_reg g_mtWndProc[] = {
  { "__gc",    winapi_WndProc_gc },
  { "__index", winapi_WndProc_index },
  { NULL, NULL }
};

static const luaL_reg g_WndProc_methods[ ] = {
  { "new",      winapi_WndProc_new },
  { "subclass", winapi_WndProc_subclass },
  { NULL, NULL }
};



static void printMsgProcError(lua_State* L, const char* errormsg, HWND hwnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
  LUASTACK_SET(L);

  if (lua_checkstack(L, 6))
  {
    lua_getglobal(L, "printMsgProcError");
    if (lua_isfunction(L, -1))
    {
      // push parameters and
      // call lua function
      lua_pushstring (L, errormsg);
      lua_pushWindow (L, hwnd);
      lua_pushinteger(L, Msg);
      lua_pushinteger(L, wParam);
      lua_pushinteger(L, lParam);

      lua_pcall(L, 5, 0, 0);
    }
    else
    {
      // pop function
      lua_pop(L, 1);
    }
  }

  LUASTACK_CLEAN(L, 0);
}

//////////////////////////////////////////////////////////////////////////
/**

  static entry point, calls the wrapped lua function with
    - object
    - hwnd wrapper
    - msg id
    - wParam
    - lParam
  as parameters

*/////////////////////////////////////////////////////////////////////////
static BOOL WINAPI staticWndProc(WndProcThunk* thunk, HWND hwnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
  int     callPrevProc = 0;
  LRESULT result = 0;
  lua_State* L = thunk->L;

  // DTRACE(_T("luawrap_WndProc %x %x %x %x %x\n"), Msg, wParam, lParam, thunk, thunk->L);

  LUASTACK_SET(L);

  if (NULL == thunk->pThunk)
  {
    printMsgProcError(L, "WndProc: Called already released thunk"
                       , hwnd, Msg, wParam, lParam);
    result = DefWindowProcW(hwnd, Msg, wParam, lParam);
  }
  else
  {
    if (!lua_checkstack(L, 7))
    {
      // An error happened, print it and call default window proc
      printMsgProcError(L, "WndProc: Growing Lua stack failed\n"
                         , hwnd, Msg, wParam, lParam);
      callPrevProc = 1;
    }
    else
    {
      // push traceback function
      lua_getglobal(L, "debug");
      lua_getfield(L, -1, "traceback");
      lua_replace(L, -2);
    
      // determine registered lua function
      // get table with registered WndProcs stored at env[address]
      lua_rawgeti(L, LUA_REGISTRYINDEX, thunk->functionRef);

      // printf("luawrap_WndProc %x %x %x\n", thunk, hwnd, Msg);
      if (lua_isfunction(L, -1))
      {
        int ret;

        // push parameters and
        // call lua function
        lua_pushWindow(L, hwnd);
        lua_pushinteger(L, Msg);
        lua_pushinteger(L, wParam);
        lua_pushinteger(L, lParam);

        // push objectref
        lua_rawgeti(L, LUA_REGISTRYINDEX, thunk->objectRef);

        // push precProc pointer
        lua_pushlightuserdata(L, thunk->prevProc);
     
        ret = lua_pcall(L, 6, 1, -8);
        if (ret == 0)
        {
          switch (lua_type(L, -1)) 
          {
            case LUA_TNIL:            callPrevProc = 1; break;
            case LUA_TNUMBER:         result = (LRESULT)lua_tonumber(L, -1); break;
            case LUA_TLIGHTUSERDATA: 
            case LUA_TUSERDATA:       result = (LRESULT)lua_touserdata(L, -1); break;
            default:
            {
              char szError[1024];
              sprintf(szError, "WndProc: got unsupported value type '%s'\n", luaL_typename(L, -1));
              printMsgProcError(L, szError
                                 , hwnd, Msg, wParam, lParam);
              callPrevProc = 1;
            }
            break;
          }

          // pop return value
          lua_pop(L, 1);
        }
        else
        {
          // An error happened, print it and call default window proc
          printMsgProcError(L, lua_tostring(L, -1)
                             , hwnd, Msg, wParam, lParam);

          // pop error
          lua_pop(L, 1);

          result = CallWindowProcW(thunk->prevProc, hwnd, Msg, wParam, lParam);
        }
      }
      else
      {
        // An error happened, print it and call default window proc
        printMsgProcError(L, "WndProc: could not get associated function\n"
                           , hwnd, Msg, wParam, lParam);

        // pop function
        lua_pop(L, 1);

        callPrevProc = 1;
      }
   
      // pop debug.traceback trom the stack
      lua_pop(L, 1);
    }
  }

  LUASTACK_CLEAN(L, 0);

  if (callPrevProc)
  {
    result = CallWindowProcW(thunk->prevProc, hwnd, Msg, wParam, lParam);
  }

  return result;
}

//////////////////////////////////////////////////////////////////////////
/**

  implements WndProc.new(object, func)

*/////////////////////////////////////////////////////////////////////////
static int winapi_WndProc_new(lua_State* L)
{
  LUASTACK_SET(L);

  if (lua_isfunction(L, 2))
  {
    WndProcThunk* thunk = (WndProcThunk*)lua_newuserdata(L, sizeof(WndProcThunk));
    if (thunk)
    {
      // set metatable
      luaL_getmetatable(L, WndProc_Typename);
      lua_setmetatable(L, -2);

      // register lua object in registry
      lua_pushvalue(L, 1);
      thunk->objectRef    = luaL_ref(L, LUA_REGISTRYINDEX);
      // register lua function in registry
      lua_pushvalue(L, 2);
      thunk->functionRef  = luaL_ref(L, LUA_REGISTRYINDEX);
      thunk->L            = L;
      thunk->pThunk       = stdcallthunk_create(&staticWndProc, thunk);
      thunk->prevProc     = &DefWindowProcW;

      LUASTACK_CLEAN(L, 1);
      return 1;
    }
  }
  else
  {
    luaL_typerror(L, 2, lua_typename(L, LUA_TFUNCTION));
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
/**

  implements WndProc.subclass(hwnd, object, func)

*/////////////////////////////////////////////////////////////////////////
static int winapi_WndProc_subclass(lua_State* L)
{
  HWND hwnd;
  WndProcThunk* thunk;

  LUASTACK_SET(L);

  if (lua_isfunction(L, 3))
  {
    hwnd = lua_toWindow(L, 1);
    if (!IsWindow(hwnd))
    {
      luaL_typerror(L, 1, "Window (handle)");
    }

    thunk = (WndProcThunk*)lua_newuserdata(L, sizeof(WndProcThunk));
    if (thunk)
    {
      // set metatable
      luaL_getmetatable(L, WndProc_Typename);
      lua_setmetatable(L, -2);

      // register lua object in registry
      lua_pushvalue(L, 2);
      thunk->objectRef    = luaL_ref(L, LUA_REGISTRYINDEX);
      // register lua function in registry
      lua_pushvalue(L, 3);
      thunk->functionRef  = luaL_ref(L, LUA_REGISTRYINDEX);
      thunk->L            = L;
      thunk->pThunk       = stdcallthunk_create(&staticWndProc, thunk);
      thunk->prevProc     = (WNDPROC)GetWindowLong(hwnd, GWL_WNDPROC);

      // subclass
      SetWindowLong(hwnd, GWL_WNDPROC, (LONG)thunk->pThunk);

      LUASTACK_CLEAN(L, 1);
      return 1;
    }
  }
  else
  {
    luaL_typerror(L, 3, lua_typename(L, LUA_TFUNCTION));
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
/**

  cleanup a wrapper instance

*/////////////////////////////////////////////////////////////////////////
static int winapi_WndProc_gc(lua_State *L)
{
  WndProcThunk* thunk;

  LUASTACK_SET(L);

  thunk = (WndProcThunk*)luaL_checkudata(L, 1, WndProc_Typename);
  if (thunk)
  {
    // thunk->L            = 0;
    thunk->pThunk       = 0;

    // destroy thunk
    stdcallthunk_destroy(thunk->pThunk);

    // remove registered lua object and function
    luaL_unref(L, LUA_REGISTRYINDEX, thunk->objectRef);
    thunk->functionRef = LUA_REFNIL;
    luaL_unref(L, LUA_REGISTRYINDEX, thunk->functionRef);
    thunk->functionRef = LUA_REFNIL;
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
/**

  implements __index

*/////////////////////////////////////////////////////////////////////////
static int winapi_WndProc_index(lua_State* L)
{
  WndProcThunk* thunk;

  LUASTACK_SET(L);

  thunk = (WndProcThunk*)luaL_checkudata(L, 1, WndProc_Typename);
  if (thunk)
  {
    const char* index = lua_tostring(L, 2);
    if (0 == strcmp(index, "entrypoint"))
    {
      lua_pushlightuserdata(L, thunk->pThunk);

      LUASTACK_CLEAN(L, 1);
      return 1;
    }
    else if (0 == strcmp(index, "prevproc"))
    {
      lua_pushlightuserdata(L, thunk->prevProc);

      LUASTACK_CLEAN(L, 1);
      return 1;
    }
    else
    {
      luaL_error(L, "cannot get member '%s'", index);
    }
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}



//////////////////////////////////////////////////////////////////////////
/**

  register WndProc metatable and methods

*/////////////////////////////////////////////////////////////////////////
int winapi_RegisterWndProc(lua_State* L)
{
  LUASTACK_SET(L);

  // create metatable for WndProc objects and store it in registry
  luaL_newmetatable(L, WndProc_Typename);
  luaL_register(L, NULL, g_mtWndProc);
  lua_pop(L, 1);

  // create method table
  lua_newtable(L);
  luaL_register(L, NULL, g_WndProc_methods);

  // store
  lua_setfield(L, -2, WndProc_Typename);

  LUASTACK_CLEAN(L, 0);
  return 0;
}

