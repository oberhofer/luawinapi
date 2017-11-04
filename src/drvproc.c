//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2017 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>
#include <mmsystem.h>
#include <assert.h>

#include "luaaux.h"

#include "stdcallthunk.h"
#include "drvproc.h"

#include "gen_abstractions.h"

//////////////////////////////////////////////////////////////////////////
/**

  WNDPROC wrapper object

*/////////////////////////////////////////////////////////////////////////
typedef struct
{
  lua_State* L;
  int        functionRef;
  int        errFuncRef; 
  PVOID      pThunk;
  DRIVERPROC prevProc;
} DrvProcThunk;

const char* DriverProc_Typename  = "DriverProc";


static int winapi_DriverProc_new(lua_State* L);

static int winapi_DriverProc_gc(lua_State* L);
static int winapi_DriverProc_index(lua_State* L);


static const luaL_Reg g_mtDriverProc[] = {
  { "__gc",    winapi_DriverProc_gc },
  { "__index", winapi_DriverProc_index },
  { NULL, NULL }
};

static const luaL_Reg g_DriverProc_methods[ ] = {
  { "new",     winapi_DriverProc_new },
  { NULL, NULL }
};


//////////////////////////////////////////////////////////////////////////
/**

  Handle errors occurred while handling driver callbacks

*/////////////////////////////////////////////////////////////////////////
static void raiseDriverProcError(DrvProcThunk* thunk, const char* errormsg, DWORD_PTR dwDriverId, HDRVR hdrvr, UINT msg, LONG lParam1, LONG lParam2)
{
  lua_State* L = thunk->L;
  
  LUASTACK_SET(L);

  if (lua_checkstack(L, 6))
  {
    lua_rawgeti(L, LUA_REGISTRYINDEX, thunk->errFuncRef);
    if (lua_isfunction(L, -1))
    {
      // push parameters and
      // call lua function
      lua_pushstring (L, errormsg);
      lua_pushinteger(L, dwDriverId);
      lua_pushlightuserdata(L, hdrvr);
      lua_pushinteger(L, msg);
      lua_pushinteger(L, lParam1);
      lua_pushinteger(L, lParam2);

      lua_pcall(L, 5, 0, 0);
    }
    else
    {
      CHAR buf[4069];
      sprintf(&buf, "Error in DriverProc.\n%s", errormsg);
      
      MessageBoxA(NULL, buf, "Error", MB_OK);

      PostQuitMessage(0);
    
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
static BOOL WINAPI staticDriverProc(DrvProcThunk* thunk, DWORD_PTR dwDriverId, HDRVR hdrvr, UINT msg, LONG lParam1, LONG lParam2)
{
  int     callPrevProc = 0;
  LRESULT result = 0;
  lua_State* L = thunk->L;

  LUASTACK_SET(L);

  if (NULL == thunk->pThunk)
  {
    raiseDriverProcError( thunk, "WndProc: Called already released thunk"
                        , dwDriverId, hdrvr, msg, lParam1, lParam2);
    result = DefDriverProc(dwDriverId, hdrvr, msg, lParam1, lParam2);
  }
  else
  {
    if (!lua_checkstack(L, 7))
    {
      // An error happened, print it and call default window proc
      raiseDriverProcError( thunk, "WndProc: Growing Lua stack failed\n"
                          , dwDriverId, hdrvr, msg, lParam1, lParam2);
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

      // printf("DriverProc %x %x %x\n", thunk, hdrvr, msg);
      if (lua_isfunction(L, -1))
      {
        int ret;

        // push parameters and
        // call lua function
        lua_pushinteger(L, dwDriverId);
        lua_pushlightuserdata(L, hdrvr);
        lua_pushinteger(L, msg);
        lua_pushinteger(L, lParam1);
        lua_pushinteger(L, lParam2);

        // push prevProc pointer
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
              sprintf(szError, "DriverProc: got unsupported value type '%s'\n", luaL_typename(L, -1));
              raiseDriverProcError( thunk, szError
                                  , dwDriverId, hdrvr, msg, lParam1, lParam2);
              callPrevProc = 1;
            }
            break;
          }

          // pop return value
          lua_pop(L, 1);
        }
        else
        {
          const char* errmsg = lua_tostring(L, -1);
          
          // An error happened, call raiseMsgProcError
          raiseDriverProcError( thunk, errmsg
                              , dwDriverId, hdrvr, msg, lParam1, lParam2);

          // pop error
          lua_pop(L, 1);

          callPrevProc = 1;
        }
      }
      else
      {
        // An error happened, call raiseMsgProcError
        raiseDriverProcError( thunk, "WndProc: could not get associated function\n"
                            , dwDriverId, hdrvr, msg, lParam1, lParam2);

        // pop function
        lua_pop(L, 1);

        callPrevProc = 1;
      }
   
      // pop debug.traceback trom the stack
      lua_pop(L, 1);
    }
  }

  LUASTACK_CLEAN(L, 0);

  if (callPrevProc && thunk->prevProc)
  {
    result = thunk->prevProc(dwDriverId, hdrvr, msg, lParam1, lParam2);
  }

  return result;
}

//////////////////////////////////////////////////////////////////////////
/**

  implements DriverProc.new(object, func)

*/////////////////////////////////////////////////////////////////////////
static int winapi_DriverProc_new(lua_State* L)
{
  LUASTACK_SET(L);

  if (lua_isfunction(L, 2))
  {
    int errfuncspecified = !lua_isnoneornil(L, 3);
  
    DrvProcThunk* thunk = (DrvProcThunk*)lua_newuserdata(L, sizeof(DrvProcThunk));
    if (thunk)
    {
      // set metatable
      luaL_getmetatable(L, DriverProc_Typename);
      lua_setmetatable(L, -2);

      // register lua function in registry
      luaL_checktype(L, 1, LUA_TFUNCTION); 
      lua_pushvalue(L, 1);
      thunk->functionRef  = luaL_ref(L, LUA_REGISTRYINDEX);

      // register error function in registry
      thunk->errFuncRef   = LUA_REFNIL;
      if (errfuncspecified)
      { 
        luaL_checktype(L, 2, LUA_TFUNCTION); 
        
        lua_pushvalue(L, 2);
        thunk->errFuncRef   = luaL_ref(L, LUA_REGISTRYINDEX);
      }

      thunk->L            = L;
      thunk->pThunk       = stdcallthunk_create(&staticDriverProc, thunk);
      thunk->prevProc     = &DefDriverProc;
      
      LUASTACK_CLEAN(L, 1);
      return 1;
    }
  }
  else
  {
    const char *msg = lua_pushfstring(L, "function expected but got %s", luaL_typename(L, 2));
    luaL_argerror(L, 2, msg);
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
/**

  cleanup a wrapper instance

*/////////////////////////////////////////////////////////////////////////
static int winapi_DriverProc_gc(lua_State *L)
{
  DrvProcThunk* thunk;

  LUASTACK_SET(L);

  thunk = (DrvProcThunk*)luaL_checkudata(L, 1, DriverProc_Typename);
  if (thunk)
  {
    // thunk->L            = 0;
    thunk->pThunk       = 0;

    // destroy thunk
    stdcallthunk_destroy(thunk->pThunk);

    // remove registered lua object and function
    luaL_unref(L, LUA_REGISTRYINDEX, thunk->functionRef);
    thunk->functionRef = LUA_REFNIL;
    luaL_unref(L, LUA_REGISTRYINDEX, thunk->errFuncRef);
    thunk->errFuncRef = LUA_REFNIL;
  }

  LUASTACK_CLEAN(L, 0);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
/**

  implements __index

*/////////////////////////////////////////////////////////////////////////
static int winapi_DriverProc_index(lua_State* L)
{
  DrvProcThunk* thunk;

  LUASTACK_SET(L);

  thunk = (DrvProcThunk*)luaL_checkudata(L, 1, DriverProc_Typename);
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

  register DriverProc metatable and methods

*/////////////////////////////////////////////////////////////////////////
int winapi_RegisterDriverProc(lua_State* L)
{
  LUASTACK_SET(L);

  // create metatable for DriverProc objects and store it in registry
  luaL_newmetatable(L, DriverProc_Typename);
#if (LUA_VERSION_NUM > 501)
  luaL_setfuncs(L, g_mtDriverProc, 0);
#else
  luaL_openlib(L, NULL, g_mtDriverProc, 0);
#endif
  lua_pop(L, 1);

  // create method table
  lua_newtable(L);
#if (LUA_VERSION_NUM > 501)
  luaL_setfuncs(L, g_DriverProc_methods, 0);
#else
  luaL_openlib(L, NULL, g_DriverProc_methods, 0);
#endif

  // store
  lua_setfield(L, -2, DriverProc_Typename);

  LUASTACK_CLEAN(L, 0);
  return 0;
}

