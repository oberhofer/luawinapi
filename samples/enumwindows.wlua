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
  return buffer
end

winapi.EnumWindows(0, function(hwnd)

  windows[#windows+1] = { hwnd=hwnd, class=toASCII(winapi.GetClassNameW(hwnd)), title=toASCII(getText(hwnd)) }

  -- print(hwnd.handle, toASCII(winapi.GetClassNameW(hwnd)), toASCII(getText(hwnd)))
  return true
end)


for _, w in ipairs(windows) do

	if ( nil ~= string.find(w.title, "pad") ) then
		print(w.hwnd.handle, w.class, w.title)
	end

end


