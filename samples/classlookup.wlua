--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test window class lookup and bring window to front

--]==]

local winapi = require("luawinapi")

mainWndClass = "Notepad++"

result = {}

winapi.MessageBoxW(nil, "Please start Notepad++ and push it to the back", "Info", MB_OK)

local hwnd = winapi.FindWindowW(mainWndClass, nil)
if (hwnd) then

  local threadid = winapi.GetWindowThreadProcessId(hwnd)

  print("found", hwnd.handle, threadid)

  winapi.EnumThreadWindows(threadid,
    function(h)
      if (0 ~= winapi.IsWindowEnabled(h)) then
        print("Move window to the foreground", hwnd.handle, threadid)
        winapi.SetForegroundWindow(h)
        return false
      end
      return true
    end
  )
else
  winapi.MessageBoxW(nil, "Notepad++ not found ! Forget to start ?", "Error", MB_OK)
end
