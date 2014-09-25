--[==[

  Template engine with borrowed code from 
  
  http://lua-users.org/wiki/SlightlyLessSimpleLuaPreprocessor

--]==]

-- satisfy module loader 
local modname = ...
local templateengine = {}
_G[modname] = templateengine
package.loaded[modname] = templateengine


-------------------------------------------------------------------------------
local function parseDollarParen(pieces, chunk, s, e)
  local s = 1
  for term, executed, e in string.gfind(chunk, "()$(%b())()") do
      table.insert(pieces, string.format("%q..(%s or '')..",
        string.sub(chunk, s, term - 1), executed))
      s = e
  end
  table.insert(pieces, string.format("%q", string.sub(chunk, s)))
end

-------------------------------------------------------------------------------
local function parseHashLines(chunk)
  local pieces, s, args = string.find(chunk, "^\n*\/\/\#ARGS%s*(%b())[ \t]*\n")
  if not args or string.find(args, "^%(%s*%)$") then
    pieces, s = {"return function(_put) ", n = 1}, s or 1
   else
    pieces = {"return function(_put, ", string.sub(args, 2), n = 2}
  end
  while true do
    local ss, e, lua = string.find(chunk, "^\/\/\#+([^\n]*\n?)", s)
    if not e then
      ss, e, lua = string.find(chunk, "\n\/\/\#+([^\n]*\n?)", s)
      table.insert(pieces, "_put(")
      parseDollarParen(pieces, string.sub(chunk, s, ss))
      table.insert(pieces, ")")
      if not e then break end
    end
    table.insert(pieces, lua)
    s = e + 1
  end
  table.insert(pieces, " end")
  return table.concat(pieces)
end

-------------------------------------------------------------------------------
function templateengine.preprocess(chunk, name, putfunc)
  local result = parseHashLines(chunk)

  -- local targetfile = io.open("result.lua", "w+")
  -- targetfile:write(result)

  return assert(loadstring(result))()
end

