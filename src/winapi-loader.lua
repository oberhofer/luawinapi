--[[--------------------------------------------------------------------------

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file
  
  Loads winapi wrapper module

--]]--------------------------------------------------------------------------


local shared_lib_name = "luawinapi.dll"
local shared_lib_init = "luaopen_luawinapi"

-- Lua-5.0 / Lua-5.1
local loadlib = loadlib or package.loadlib

local init, error = loadlib(shared_lib_name, shared_lib_init)

local api, ERR, TYPE, AUTH

if init then
  api, ERR, TYPE, AUTH = init()
end

function load_luawinapi()
  assert(init, error)
  return  api, ERR, TYPE, AUTH
end
