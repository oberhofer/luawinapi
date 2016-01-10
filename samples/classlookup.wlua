--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test window class lookup and bring window to front

--]==]

local winapi = require("luawinapi")

mainWndClass = _T("Notepad2")

result = {}

winapi.MessageBoxW(nil, _T"Please start notepad2.exe and push it to the back", _T"Info", MB_OK)

local hwnd = winapi.FindWindowW(mainWndClass)
if (hwnd) then

  local threadid = winapi.GetWindowThreadProcessId(hwnd)

  print("found", hwnd.handle, threadid)

  winapi.EnumThreadWindows(threadid,
    function(h)
      if (0 ~= winapi.IsWindowEnabled(h)) then
        -- print(h.handle)
        winapi.SetForegroundWindow(h)
        return false
      end
      return true
    end
  )
else
  winapi.MessageBoxW(nil, _T"Notepad2 not found ! Forget to start ?", _T"Error", MB_OK)
end
