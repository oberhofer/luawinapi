--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Generator for winapi bindings

--]==]

local templateengine = require("templateengine")
local lpeg = require("lpeg")

dofile("parse.lua")

-- basic type IDs
basic_types = {
  ["INT8"]       = "$i8",
  ["UINT8"]      = "$u8",
  ["INT16"]      = "$i16",
  ["UINT16"]     = "$u16",
  ["INT32"]      = "$i32",
  ["UINT32"]     = "$u32",

  ["INT"]        = "$int",
  ["UINT"]       = "$uint",
  ["ULONG"]      = "$ulong",
  ["LONG"]       = "$long",

  ["POINTER"]    = "$ptr",

  ["LPCSTR"]     = "$ptr",
  ["LPSTR"]      = "$ptr",

  ["LPCWSTR"]    = "$ptr",
  ["LPWSTR"]     = "$ptr",

  ["HANDLE"]     = "$ptr",

  ["HANDLE_OR_UINT"] = "$ptr",

  ["WNDPROC"]    = "$ptr",
  ["DLGPROC"]    = "$ptr",

  ["WPARAM"]     = "$u32",
  ["LPARAM"]     = "$u32",

  ["LUAREF"]     = "$ref",
}


type_aliases = {
  ["BYTE"]      = "UINT8",
  ["UCHAR"]     = "UINT8",

  ["SHORT"]     = "INT16",
  ["short"]     = "INT16",

  ["WORD"]      = "UINT16",
  ["USHORT"]    = "UINT16",
  
  ["WCHAR"]     = "UINT16",

  ["BOOL"]      = "INT32",
  ["LONG"]      = "INT32",
  ["int"]       = "INT32",
  ["INT"]       = "INT32",

  ["DWORD"]     = "UINT32",

  ["BOOL"]      = "INT",
  ["long"]      = "LONG",
  ["int"]       = "INT",

  ["HRESULT"]   = "ULONG",

  ["MMRESULT"]  = "UINT",
  ["MMVERSION"] = "UINT",

  ["LRESULT"]   = "ULONG",

  ["DWORD_PTR"] = "DWORD",
  ["UINT_PTR"]  = "POINTER",
  ["LONG_PTR"]  = "POINTER",
  ["ULONG_PTR"] = "POINTER",

-- ["LPCWSTR"]   = "POINTER",
-- ["LPWSTR"]    = "POINTER",

  ["LPDWORD"]   = "DWORD",

  ["PVOID"]     = "POINTER",
  ["LPVOID"]    = "POINTER",
  ["LPCVOID"]   = "POINTER",

  ["LPINT"]     = "POINTER",

  ["ATOM"]      = "UINT16",

-- ["HANDLE"]    = "POINTER",

  ["HINSTANCE"] = "HANDLE",
  ["HMODULE"]   = "HANDLE",
  ["HWND"]      = "HANDLE",
  ["HDC"]       = "HANDLE",
  ["HRSRC"]     = "HANDLE",
  ["HMENU"]     = "HANDLE",
  ["HICON"]     = "HANDLE",
  ["HCURSOR"]   = "HANDLE",
  ["HGDIOBJ"]   = "HANDLE",
  ["HBRUSH"]    = "HANDLE",
  ["HPEN"]      = "HANDLE",
  ["HBITMAP"]   = "HANDLE",
  ["HACCEL"]    = "HANDLE",
  ["HIMAGELIST"]= "HANDLE",
  ["HRGN"]      = "HANDLE",
  ["HPALETTE"]  = "HANDLE",
  ["HGLRC"]     = "HANDLE",
  ["HFONT"]     = "HANDLE",
  ["HINTERNET"] = "HANDLE",

  ["HGLOBAL"]   = "HANDLE",
  ["HLOCAL"]    = "HANDLE",

  ["HTREEITEM"] = "HANDLE",

  ["HMSGQUEUE"] = "HANDLE",

  ["HCERTSTORE"]= "HANDLE",

  ["HDRVR"]       = "HANDLE",
  ["HWAVEOUT"]    = "HANDLE",
  ["HWAVEIN"]     = "HANDLE",
  ["HMIDI"]       = "HANDLE",
  ["HMIDIOUT"]    = "HANDLE",

  ["HMIDIIN"]     = "HANDLE",
  ["HMIDISTRM"]   = "HANDLE",

  ["HMIXER"]      = "HANDLE",
  ["HMIXEROBJ"]   = "HANDLE",

  ["COLORREF"]  = "UINT32",

  ["PVOID_OR_UINT"] = "HANDLE_OR_UINT",

  ["INTERNET_PORT"] = "UINT16",
}

abstractiondefs = {
  Window = {
    handle = "HWND"
  },
  DC = {
    handle = "HDC"
  },
  Region = {
    handle = "HRGN"
  },
  Icon = {
    handle = "HICON"
  },
  MsgQueue = {
    handle = "HMSGQUEUE",
    attribs = { { name="MsgQueue" } }
  },
  Driver = {
    handle = "HDRVR"
  },
  WaveOut = {
    handle = "HWAVEOUT"
  },
  WaveIn = {
    handle = "HWAVEIN"
  },
  Midi = {
    handle = "HMIDI"
  },
  MidiOut = {
    handle = "HMIDIOUT"
  },
  MidiIn = {
    handle = "HMIDIIN"
  },
  MidiStream = {
    handle = "HMIDISTRM"
  },
  Mixer = {
    handle = "HMIXER"
  },
  MixerObject = {
    handle = "HMIXEROBJ"
  },
}

marshall_fragments =
{
  ["INT8"] = {
    ["in"]  = "$name = lua_tointeger(L, $index);",
    ["out"] = "lua_pushinteger(L, $name); ++numret;"
  },
  ["UINT8"] = {
    ["in"]  = "$name = (BYTE)lua_tointeger(L, $index);",
    ["out"] = "lua_pushinteger(L, $name); ++numret;"
  },
  ["INT16"] = {

    ["in"]  = "$name = lua_tointeger(L, $index);",
    ["out"] = "lua_pushinteger(L, $name); ++numret;"
  },
  ["UINT16"] = {

    ["in"]  = "$name = (WORD)lua_tointeger(L, $index);",
    ["out"] = "lua_pushinteger(L, $name); ++numret;"
  },
  ["INT32"] = {

    ["in"]  = "$name = lua_tointeger(L, $index);",
    ["out"] = "lua_pushinteger(L, $name); ++numret;"
  },
  ["UINT32"] = {

    ["in"]  = "$name = ($type)lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["INT"] = {

    ["in"]  = "$name = ($type)lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["UINT"] = {

    ["in"]  = "$name = ($type)lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["LONG"] = {

    ["in"]  = "$name = ($type)lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["ULONG"] = {

    ["in"]  = "$name = ($type)lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["INT_PTR"] = {

    ["in"]  = "$name = ($type)lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["DOUBLE"] = {

    ["in"]  = "$name = lua_tonumber(L, $index);",
    ["out"] = "lua_pushnumber(L, $name); ++numret;"
  },
  ["POINTER"] = {

    ["in"]  = "$name = ($type)lua_touserdata(L, $index);",
    ["out"] = [[if (0 == $name)
  {
    lua_pushnil(L);
  }
  else
  {
    lua_pushlightuserdata(L, (PVOID)$name);
  }
  ++numret;]]
  },
  ["HANDLE"] = {

    ["in"]  = "$name = ($type)winapi_tohandle(L, $index);",
    ["out"] = "lua_pushlightuserdata(L, (PVOID)$name); ++numret;"
  },
  ["WNDPROC"] = {

    ["in"]  = "$name = ($type)winapi_tohandle(L, $index);",
    ["out"] = "lua_pushlightuserdata(L, $name); ++numret;"
  },
  ["DLGPROC"] = {

    ["in"]  = "$name = ($type)winapi_tohandle(L, $index);",
    ["out"] = "lua_pushlightuserdata(L, $name); ++numret;"
  },
  ["LPCSTR"] = {

    ["in"]  = "$name = ($type)lua_tostring(L, $index);",
    ["out"] = "lua_pushstring(L, $name); ++numret;"
  },
  ["LPCWSTR"] = {

    ["in"]  = "$name = winapi_towidestring_Z(L, $index);",
    ["out"] = "lua_pushwidestring(L, $name); ++numret;"
  },
  ["LPCWSTR_OR_ATOM"] = {

    ["declare"] = "LPCWSTR $name$defval;",
    ["in"]  = "$name = winapi_towidestring_or_atom_Z(L, $index);",
    ["out"] = "-- LPCWSTR_OR_ATOM could not be used as out param --"
  },
  ["LPSTR"] = {

    ["in"]  = "$name = ($type)lua_tostring(L, $index);",
    ["out"] = "lua_pushstring(L, $name); ++numret;"
  },
  -- creates a modifiable local copy (used only by CreateProcessW)
  ["LPWSTR_LOCALCOPY"] = {
    ["declare"] = "LPWSTR $name$defval;",
    -- make a writeable copy of the given parameter
	  ["in"]    = [[size_t sourcelen;
    LPCWSTR source = winapi_widestringfromutf8_Z(L, $index, &sourcelen);
    
    size_t buflen = sizeof(WCHAR) * sourcelen;
    $name = (LPWSTR)malloc(buflen);
    if (NULL == $name)
    {
      luaL_error(L, "internal malloc error");
    }
    else
    {
      memcpy($name, source, buflen);
    }]],
    ["incall"]  = "$name",
    ["out"] = [[free($name);]],
  },
  -- WCHAR buffer - used together with a size parameter
  ["LPWSTR"] = {
    ["declare"] = "LPWSTR $name$defval;",
	  ["init"]    = [[{
    size_t buflen = sizeof(WCHAR) * $sizeparam;
    $name = (LPWSTR)malloc(buflen);
    if (NULL == $name)
    {
      luaL_error(L, "internal malloc error");
    }
  }]],
    ["incall"]  = "$name",
    ["out"] = [[winapi_pushlwidestring_Z(L, $name, $sizeparam); ++numret;
  free($name);]],
  },
  ["RESOURCEREF"] = {

    ["declare"] = "LPCWSTR $name$defval;",
    ["in"]  = "$name = (LPCWSTR)winapi_toresourceref(L, $index);",
    ["out"] = "-- resourceref could not be used as out param --"
  },
  ["HANDLE_OR_UINT"] = {

    ["declare"] = "UINT_PTR $name$defval;",
    ["in"]  = "$name = (UINT_PTR)winapi_tohandle(L, $index);",
    ["out"] = "-- HANDLE_OR_UINT could not be used as out param --"
  },
  ["WPARAM"] = {

    ["in"]  = "$name = ($type)winapi_tolwparam(L, $index);",
    ["out"] = "lua_pushlightuserdata(L, (void*)$name); ++numret;"
  },
  ["LPARAM"] = {

    ["in"]  = "$name = ($type)winapi_tolwparam(L, $index);",
    ["out"] = "lua_pushlightuserdata(L, (void*)$name); ++numret;"
  },
  -- special marshaller for wrapped structs
  ["struct"] = {
    ["declare"] = "$type* $name$defval;",
    ["in"]      = "$name = ($type*)g_luacwrapiface->checktype(L, $index, &regType_$type.hdr);",
--    ["out"] = "luawrap_push(L, $name); ++numret;"
  },
  ["LUAREF"] = {
    ["in"]  = "$name = ($type)g_luacwrapiface->createreference(L, $index);",
    ["out"] = "g_luacwrapiface->pushreference(L, (int)$name); ++numret;",
  },
}

prerequisites = {
  ["onlyCE"] = {
    ["expression"]  = "(defined(UNDER_CE))",
  },
  ["notCE"] = {
    ["expression"]  = "(!defined(UNDER_CE))",
  },
  ["AYGShell"] = {
    ["expression"]  = "(defined(USE_AYGSHELL))",
  },
  ["CommandBar"] = {
    ["expression"]  = "(defined(USE_COMMANDBAR))",
  },
  ["OpenGL"] = {
    ["expression"]  = "(defined(USE_OPENGL))",
  },
  ["MsgQueue"] = {
    ["expression"]  = "(defined(USE_MSGQUEUE))",
  },
}

generatedbymessage = "!!! This file is generated by genwrap.lua  !!!"

function prerequisite_begin(item, _put)
  for _, attr in pairs(item.attribs or {}) do
    if (prerequisites[attr.name]) then
      _put("#if " .. prerequisites[attr.name].expression .. "\n")
    end
  end
end

function prerequisite_end(item, _put)
  for _, attr in pairs(item.attribs or {}) do
    if (prerequisites[attr.name]) then
      _put("#endif\n")
    end
  end
end

function attribs_contains(item, name)
  for _, attr in pairs(item.attribs or {}) do
    if (attr.name == name) then
		return true
    end
  end
  return false
end

function attribs_value(item, name)
  for _, attr in pairs(item.attribs or {}) do
    if (attr.name == name) then
		return attr.value
    end
  end
  return nil
end


structdefs = { }       -- struct definitions
funcdefs   = { }       -- function signatures

function expand (text, subst)
    return (string.gsub(text, "$(%w+)", function (n)
        return tostring(subst[n])
    end))
end


-- resolve alias type
function resolve_alias(name)
  local result = name
  while (type_aliases[result]) do
    result = type_aliases[result]
  end

  return result
end


-- determine descriptor id for a given type name
function get_descriptor_id(param)
  local result = "LUAREF"
  if (not attribs_contains(param, "luaref")) then
    result = resolve_alias(param.typ)
  end
  result = basic_types[result] or result
  return result
end

function get_marshall_type(name)
  local result
  if (structdefs[name]) then
    -- special handling for marshalling wrapped structs
    result = "struct"
  else
    result = resolve_alias(name)
  end
  return result
end


function declare_param(param, name)
  local default_decl = "$type $name$defval;"
  --
  local basetyp = get_marshall_type(param.typ)
  print("    ", param.typ, " ->  ", basetyp)

  local defaultvalue = ""
  if (attribs_contains(param, "nullisvalid")) then
    defaultvalue = " = 0"
  end

  local vars = { ["type"] = param.typ, ["name"] = name, ["defval"] = defaultvalue, ["len"]=param.len or "DEFAULTLEN" }

  -- find entry
  local entry = marshall_fragments[basetyp]
  if (entry) then
    if (entry.declare) then
      return expand(entry.declare, vars)
    else
      return expand(default_decl, vars)
    end
  end
end

-- init basic type
function init_param(param, dir, name, index)
  -- can be called either with param or type
  local typ     = param.typ or param
  local attribs = param.attribs or {}

  --
  local basetyp = get_marshall_type(typ)

  local vars = { 
    ["type"] = param.typ, ["name"] = name, ["index"] = index, ["defval"] = defaultvalue, ["len"]=param.len or "DEFAULTLEN", 
    ["sizeparam"]=attribs_value(param, "sizeparam") 
  }

  -- find entry
  local entry = marshall_fragments[basetyp]
  if (entry) then
    if (entry.init) then
      return expand(entry.init, vars)
    else
      return ""
    end
  end
end

-- use basic type in function call
function use_param(param, name)

  local typ     = param.typ or param
  local attribs = param.attribs or {}

  --
  local basetyp = get_marshall_type(typ)

  local vars = { 
    ["type"] = param.typ, ["name"] = name
  }
  
  -- find entry
  local entry = marshall_fragments[basetyp]
  if (entry) then
    if (entry.incall) then
      return expand(entry.incall, vars)
    end
  end
  
  local prefix = ""
  if (attribs_contains(param, "out")) then 
    prefix = "&" 
  elseif (attribs_contains(param, "deref")) then 
    prefix = "*"
  end
  return prefix .. name
end

-- marshall basic type
function marshal_param(param, dir, name, index)
  -- can be called either with param or type
  local typ     = param.typ or param

  --
  basetyp = get_marshall_type(typ)
  -- print(typ, basetyp)

  -- find entry
  local entry = marshall_fragments["LUAREF"]
  if (not attribs_contains(param, "luaref")) then
    entry = marshall_fragments[basetyp]
  end
  if (entry) then
    -- check direction
    if (entry[dir]) then
      local res = expand(entry[dir], { ["type"] = typ, ["name"] = name, ["index"] = index, ["sizeparam"]=attribs_value(param, "sizeparam") } )
      if (attribs_contains(param, "nullisvalid")) then
        res = "if (!lua_isnil(L, " .. index .. "))\n  {\n    " .. res .."\n  }"
      end
      if (attribs_contains(param, "notnil")) then
        res = [[
if (lua_isnil(L, ]] .. index .. [[))  {
    luaL_error(L, "nil is not allowed for parameter #]] .. index .. [[");
  }
  ]] .. res
      end
      return res
    end
  else
      -- unknown type
    -- print(basetyp, struct)
  end
  return ""
end



function parseStructDefs(fname, result)
  local file = assert(io.open(fname, "r"))
  local text = file:read("*all")
  file:close()

  -- remove comment/preprocessor lines
  text = string.gsub(text, "#[^\n]*\n", "")

  -- parse all function declarations
  local structs = lpeg.match(structgrammar, text)

  for _, v in ipairs(structs) do
    if (result[v.name]) then
        error("struct defined twice: " .. v.name)
    else
        result[v.name] = v
    end
  end
  return result
end


function parseFunctionDefs(fname, result)
  local file = assert(io.open(fname, "r"))
  local text = file:read("*all")
  file:close()

  -- remove comment/preprocessor lines
  text = string.gsub(text, "#[^\n]*\n", "")

  -- parse all function declarations
  local funcs = lpeg.match(funcgrammar, text)

  for _, v in ipairs(funcs) do
    -- print(v.name, v.rettype)
    result[#result+1] = v
  end
  return result
end

--
-- Loop over all struct/union members and create types
-- for embedded structs
-- Anonymous structs are not supported.
--
function processStructMembers(types)
    local result = { }
    print("processStructMembers")

	local function handleMembers(root, base, name)
		for _, member in pairs(base.members or {}) do

		  local curbase = name .. member.name;
			local curname = curbase:gsub("%.", "_")

			if (nil == member.typ) then
				-- no type available -> create one

				-- print(root.name, curbase, member.name, member.typ)

				local typname = root.name .. "_" .. curname

				-- create a new type
				result[#result+1] = {
				  root = root.name;

  				  name = typname;
				  base = curbase;

				  -- typ  = curname;
				  members = member.members;
				}

				-- store reference to the new type
				member.typ = typname
			end

			handleMembers(root ,member, curname .. ".")
		end
	end

  for _, struct in pairs(types) do
		handleMembers(struct, struct, "")
	end

	return result
end

--
-- Loop over all struct/union members and create types
-- for embedded arrays
--
function processArrayTypes(types)
    local result = { }
    print("ProcessArrayTypes")
    for _, struct in pairs(types) do
        for _, member in pairs(struct.members) do
            if (member.len) then

        -- map to alias type

        local basic_alias = resolve_alias(member.typ)
        local basic_type = basic_types[basic_alias] or basic_alias

        local newtyp = basic_alias .. "_" .. member.len

                -- replace through new array type
                if (not result[newtyp]) then
                    -- create new type descriptor if necessary
                    result[newtyp] = {
                        ["alias"]  = basic_alias,
                        ["typ"]    = basic_type,
                        ["len"]    = member.len
                    }
                end
                member.typ = newtyp
            end
        end
    end
    return result
end


function collectAbstractionMethods()
  for abstname, abst in pairs(abstractiondefs) do
    print(abstname, abst.methods)
    local methods = {}
    for funcidx, func in ipairs(funcdefs) do
      -- recognize abstract methods:
      --  1) their first parameter has the same type as the abstraction handle type
      --  2) except methods where the value of the first parameter could be null
      if ((#func.params > 0) and
        (func.params[1].typ == abst.handle) and
        (not (attribs_contains(func.params[1], "nullisvalid")))) then
        print("  " .. func.name)
        table.insert(methods, func)

        -- remove function from list of global function definitions
--        funcdefs[funcidx] = nil
      end
    end
    abst.methods = methods

    -- define abstraction as separate type
    type_aliases[abst.handle] = nil
    basic_types[abst.handle] = "$ptr"

    -- define marshalling code
    marshall_fragments[abst.handle] = {
         ["in"]  = "$name = lua_to" .. abstname .. "(L, $index);",
         ["out"] = "numret += lua_push" .. abstname .. "(L, $name);"
    }
  end
end


function createTarget(templname, targetname)
  -- load template files
  local file = assert(io.open(templname, "r"))
  local structtemplate = file:read("*all")
  file:close()

  --open output file
  local targetfile = io.open(targetname, "w+")
  local writefunc = function(str)
    targetfile:write(str)
  end

  -- fill in the template with values in table functions
  local func = templateengine.preprocess(structtemplate, "")
  func(writefunc)

  targetfile:close()
end

-- parse definitions
structdefs = {}
parseStructDefs("struct.def", structdefs)
parseStructDefs("winmmstruct.def", structdefs)

--funcdefs   = {}
parseFunctionDefs("functions.def", funcdefs)
parseFunctionDefs("winmmfuncs.def", funcdefs)

-- process struct/union members and create new types
embedded_structdefs = processStructMembers(structdefs)

-- append res to structdefs
-- for _, item in pairs(res) do
--    structdefs[item.name] = item
--end


-- process Array types
arraydefs  = processArrayTypes(structdefs)

-- collect abstraction methods from functions
collectAbstractionMethods()


print("createAbstraction")

local outputdir = "../src/"

createTarget("abstractions_h.template", outputdir .. "gen_abstractions.h")
createTarget("abstractions_c.template", outputdir .. "gen_abstractions.c")

print("createTarget")

createTarget("struct_c.template", outputdir .. "gen_structs.c")
createTarget("struct_h.template", outputdir .. "gen_structs.h")


