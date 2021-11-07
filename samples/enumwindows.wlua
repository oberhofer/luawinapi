--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test window enumeration

--]==]

local winapi = require("luawinapi")

local windows = { }


function getText(hwnd)
  local textLength = winapi.SendMessageW(hwnd, WM_GETTEXTLENGTH) + 1
  local buffer   = string.rep("\0\0", textLength)
  winapi.SendMessageW(hwnd, WM_GETTEXT, textLength, buffer)
  return winapi.utf8fromwidestring(buffer)
end

winapi.EnumWindows(0, function(hwnd)
  windows[#windows+1] = { hwnd=hwnd, class=winapi.GetClassNameW(hwnd), title=getText(hwnd) }
  print(hwnd.handle, winapi.GetClassNameW(hwnd), getText(hwnd))
  return true
end)

for _, w in ipairs(windows) do
	if ( nil ~= string.find(w.title, "pad") ) then
		print(w.hwnd.handle, w.class, w.title)
	end
end


