--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test custom control
  
--]==]

winapi = require("luawinapi")


-- start


hInstance = winapi.GetModuleHandleW(nil)


WC_CONTROL = _T("MyControlClass")


mtControl =
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


function ControlWndProc(hwnd, msg, wParam, lParam)
  -- print("WndProc", MSG_CONSTANTS[msg] or msg, wParam, lParam)
  local handler = mtControl[msg]
  if (handler) then
    return handler(hwnd, wParam, lParam)
  else
  return winapi.DefWindowProcW(hwnd, msg, wParam, lParam)
  end
end


function RegisterControl()

  -- store this in a global
  WndProc_callback = winapi.CreateWndProcThunk(WndProc)

  wndClass = winapi.WNDCLASSW:new()
  wndClass.style          = CS_HREDRAW + CS_VREDRAW;
  wndClass.lpfnWndProc    = WndProc_callback.entrypoint
  wndClass.cbClsExtra     = 0
  wndClass.cbWndExtra     = 0
  wndClass.hInstance      = hInstance
  wndClass.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
  wndClass.hCursor        = winapi.LoadCursorW(NULL, IDC_ARROW);
  wndClass.hbrBackground  = winapi.GetStockObject(WHITE_BRUSH);
  wndClass.lpszMenuName   = 0
  wndClass.lpszClassName  = WC_CONTROL

  atom = winapi.RegisterClassW(wndClass);
  print("-----------------atom", atom)
  if (not atom) then
    error(WinError())
  end
end


function RegisterControl()

  -- store this in a global
  control_WndProc_callback = winapi.WndProc.new(nil, WndProc)

  wndClass = winapi.WNDCLASSW:new()
  wndClass.style          = CS_HREDRAW + CS_VREDRAW;
  wndClass.lpfnWndProc    = control_WndProc_callback.entrypoint
  wndClass.cbClsExtra     = 0
  wndClass.cbWndExtra     = 0
  wndClass.hInstance      = hInstance
  wndClass.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
  wndClass.hCursor        = winapi.LoadCursorW(NULL, IDC_ARROW);
  wndClass.hbrBackground  = winapi.GetStockObject(WHITE_BRUSH);
  wndClass.lpszMenuName   = 0
  wndClass.lpszClassName  = WC_CONTROL

  atom = winapi.RegisterClassW(wndClass);
  print("-----------------atom", atom)
  if (not atom) then
    error(WinError())
  end
end


function WndProc(hwnd, msg, wParam, lParam)
  if (WM_DESTROY == msg) then
    winapi.PostQuitMessage(0)
    return 0
  end

  return winapi.DefWindowProcW(hwnd, msg, wParam, lParam)
end

WC_MAINWND = _T("MyMainWndClass")

function RegisterMainWndClass()

  -- store this in a global
  WndProc_callback = winapi.WndProc.new(nil, WndProc)

  wndClass = winapi.WNDCLASSW:new()
  wndClass.style          = CS_HREDRAW + CS_VREDRAW;
  wndClass.lpfnWndProc    = WndProc_callback.entrypoint
  wndClass.cbClsExtra     = 0
  wndClass.cbWndExtra     = 0
  wndClass.hInstance      = hInstance
  wndClass.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
  wndClass.hCursor        = 0  -- winapi.LoadCursor(NULL, IDC_ARROW);
  wndClass.hbrBackground  = winapi.GetStockObject(WHITE_BRUSH);
  wndClass.lpszMenuName   = 0
  wndClass.lpszClassName  = WC_MAINWND

  atom = winapi.RegisterClassW(wndClass);
  print("-----------------atom", atom)
  if (not atom) then
    error(WinError())
  end

end


RegisterControl()
RegisterMainWndClass()

print("---------------CreateWindowExW -------------------")
hWnd = winapi.CreateWindowExW(
    0,
      WC_MAINWND,                   -- window class name
      _T("Getting Started"),        -- window caption
      WS_SYSMENU + WS_VISIBLE,      -- window style
      CW_USEDEFAULT,                -- initial x position
      CW_USEDEFAULT,                -- initial y position
      CW_USEDEFAULT,                -- initial x size
      CW_USEDEFAULT,                -- initial y size
      0,                            -- parent window handle
      0,                            -- window menu handle
      hInstance,                    -- program instance handle
      0);                           -- creation parameters


print("hwnd", hWnd,  hWnd.handle)

hControl = winapi.CreateWindowExW(
    0,
      WC_CONTROL,                   -- window class name
      toUCS2Z("Getting Started"),   -- window caption
      WS_CHILD + WS_VISIBLE + WS_BORDER,  -- window style
      20,                           -- initial x position
      200,                          -- initial y position
      100,                          -- initial x size
      100,                          -- initial y size
      hWnd,                         -- parent window handle
      0,                            -- window menu handle
      hInstance,                    -- program instance handle
      0);                           -- creation parameters

print("----------- hwnd ", hControl)
if (0 == hControl) then
    error(WinError())
end

-- print("ShowWindow")
hWnd:ShowWindow(SW_SHOW)
-- alternative:
-- winapi.ShowWindow(hWnd, SW_SHOW)

-- print("UpdateWindow")

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



