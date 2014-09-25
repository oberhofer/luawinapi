--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Simple test application for luawinapi

--]==]

winapi = require("winapi")


-- debugging: define assertion callback for internal window proc
function outputAssert(hwnd, msg, wParam, lParam, expect, ud)

  print("wndProc assertion:", hwnd, MSG_CONSTANTS[msg] or msg, wParam, lParam, expect, ud)

end


-- start

print("-----------------GetModuleHandleW")

-- printtable("winapi", winapi)

-- printtable("winapi.WNDCLASSW", winapi.WNDCLASSW.mts.man.__members)

hInstance = winapi.GetModuleHandleW(nil)

clsname = toUCS2Z("Getting Started")


handlers =
{
  [WM_PAINT] = function(hwnd, wParam, lParam)
    ps = winapi.PAINTSTRUCT:new()
      hdc = winapi.BeginPaint(hwnd, ps);

    pen = winapi.CreatePen(PS_SOLID, 1, RGB(0xFF,0,0));
    oldPen = winapi.SelectObject(hdc, pen);

    winapi.SelectObject(hdc, pen);
    -- winapi.SelectObject(hdc, winapi.GetStockObject(BLACK_BRUSH))

    winapi.MoveToEx(hdc, 0, 0, nil)
    winapi.LineTo(hdc, 200, 100)
    winapi.MoveToEx(hdc, 0, 100, nil)
    winapi.LineTo(hdc, 200, 0)
    winapi.MoveToEx(hdc, 100, 100, nil)
    winapi.Ellipse(hdc, 50, 50, 0, 100)


    winapi.EndPaint(hwnd, ps);
      return 0;
  end,
  [WM_DESTROY] = function(hwnd, wParam, lParam)
    winapi.PostQuitMessage(0)
    return 0
  end
}


function WndProc(hwnd, msg, wParam, lParam)
  -- print("WndProc", MSG_CONSTANTS[msg] or msg, wParam, lParam)
  local handler = handlers[msg]
  if (handler) then
    return handler(hwnd, wParam, lParam)
  end
  -- call default window proc
  return nil
end

print("-----------------CreateWndProcThunk")

WndProc_callback = winapi.WndProc.new(nil, WndProc)


wndClass = winapi.WNDCLASSW:new()

-- print("wndClass", wndClass);

-- printtable("wndClass", getmetatable(wndClass).__members)

wndClass.style          = CS_HREDRAW + CS_VREDRAW;
wndClass.lpfnWndProc    = WndProc_callback.entrypoint
wndClass.cbClsExtra     = 0
wndClass.cbWndExtra     = 0
wndClass.hInstance      = hInstance
wndClass.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
wndClass.hCursor        = winapi.LoadCursorW(NULL, IDC_ARROW);
wndClass.hbrBackground  = winapi.GetStockObject(WHITE_BRUSH);
wndClass.lpszMenuName   = 0
wndClass.lpszClassName  = clsname

print("-----------------RegisterClassW")

atom = winapi.RegisterClassW(wndClass);
print("-----------------atom", atom)
if (not atom) then
  error(WinError())
end

print("---------------CreateWindowExW -------------------")
hWnd = winapi.CreateWindowExW(
    0,
      clsname,                      -- window class name
      toUCS2Z("Getting Started"),        -- window caption
      WS_VISIBLE, -- window style
      CW_USEDEFAULT,                -- initial x position
      CW_USEDEFAULT,                -- initial y position
      CW_USEDEFAULT,                -- initial x size
      CW_USEDEFAULT,                -- initial y size
      0,                           -- parent window handle
      0,                           -- window menu handle
      hInstance,                    -- program instance handle
      0);                          -- creation parameters


print("hwnd", hWnd,  hWnd.handle)

--[==[
hEdit = winapi.CreateWindowExW(
    0,
      toUCS2Z("EDIT"),                    -- window class name
      toUCS2Z("Getting Started"),        -- window caption
      WS_CHILD + WS_VISIBLE + WS_BORDER,-- window style
      20,                      -- initial x position
      200,                      -- initial y position
      100,                      -- initial x size
      100,                      -- initial y size
      hWnd,                         -- parent window handle
      0,                           -- window menu handle
      hInstance,                    -- program instance handle
      0);                         -- creation parameters
]==]

    print("----------- hwnd ", hWnd)
if (0 == hWnd) then
    error(WinError())
end

print("ShowWindow")
hWnd:ShowWindow(SW_SHOW)
-- alternative:
-- winapi.ShowWindow(hWnd, SW_SHOW)

print("UpdateWindow")
hWnd:UpdateWindow()

print("winapi.ProcessMessages")

--[==[
msg = winapi.MSG:new()
while (winapi.GetMessageW(msg, NULL, 0, 0)) do
  winapi.TranslateMessage(msg);
  winapi.DispatchMessageW(msg);
end
return msg.wParam
--]==]

-- this is possible, too
return winapi.ProcessMessages()



