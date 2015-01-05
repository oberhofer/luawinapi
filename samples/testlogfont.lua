local winapi = require("luawinapi")

-- get system font
local hsysfont = winapi.GetStockObject(SYSTEM_FONT)
print(hsysfont)

-- create logfont structure
local lf = winapi.LOGFONTW:new()

-- get LOGFONT info from font handle
winapi.GetObjectW(hsysfont, #lf, lf)


print(toASCII(tostring(lf.lfFaceName)))

print(lf)


lf.lfFaceName = toUCS2Z("Arial")

print(lf)

hfont = winapi.CreateFontIndirectW(lf)

print("hfont", hfont)

assert(hfont and (0 ~= hfont))
