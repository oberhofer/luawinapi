--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Simple test application for luawinapi
  
--]==]
winapi = require("winapi")


-- control IDs

ID_EDIT   = 1
ID_BUTTON = 2


-- start

print("-----------------GetModuleHandleW")

hInstance = winapi.GetModuleHandleW(nil)

clsname = toUCS2Z("GettingStarted")


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
  -- print(hwnd, msg, wParam, lParam)
  local handler = handlers[msg]
  if (handler) then
    return handler(hwnd, wParam, lParam)
  else
  return winapi.DefWindowProcW(hwnd, msg, wParam, lParam)
  end
end

print("-----------------CreateWndProcThunk")

WndProc_callback = winapi.WndProc.new(nil, WndProc)


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
wndClass.lpszClassName  = clsname

print("-----------------RegisterClassW")

atom = winapi.RegisterClassW(wndClass);
print("-----------------atom", atom)
if (not atom) then
  error(WinError())
end

print("---------------CreateMenu-------------------------")

--[==[
-- alternative code

local hmenu = winapi.CreateMenu();
local hSubMenu = winapi.CreateMenu();
winapi.AppendMenuW(hSubMenu, MF_STRING, 1, _T("Item 1"));
winapi.AppendMenuW(hSubMenu, MF_STRING, 1, _T("Item 2"));
winapi.AppendMenuW(hSubMenu, MF_STRING, 1, _T("Item 3"));

winapi.AppendMenuW(hmenu, MF_POPUP, hSubMenu, _T("TopItem"));
--]==]

local hmenu = winapi.CreateMenu()
local hSubMenu = winapi.CreateMenu()

local mii  = winapi.MENUITEMINFOW:new()

mii.cbSize = #mii
mii.fMask = MIIM_ID + MIIM_STRING + MIIM_DATA;
mii.fType = MFT_STRING;
mii.dwTypeData = _T("Item 1");
winapi.InsertMenuItemW(hSubMenu, winapi.GetMenuItemCount(hSubMenu), TRUE, mii);
mii.dwTypeData = _T("Item 2");
winapi.InsertMenuItemW(hSubMenu, winapi.GetMenuItemCount(hSubMenu), TRUE, mii);
mii.dwTypeData = _T("Item 3");
winapi.InsertMenuItemW(hSubMenu, winapi.GetMenuItemCount(hSubMenu), TRUE, mii);


mii.fMask = MIIM_STRING + MIIM_DATA + MIIM_SUBMENU;
mii.fType = MFT_STRING;
mii.hSubMenu = hSubMenu;
mii.dwTypeData = _T("TopItem");
winapi.InsertMenuItemW(hmenu, winapi.GetMenuItemCount(hmenu), TRUE, mii);


print("---------------CreateWindowExW -------------------")
hWnd = winapi.CreateWindowExW(
      0,
      clsname,                          -- window class name
      toUCS2Z("Getting Started"),       -- window caption
      WS_OVERLAPPEDWINDOW + WS_VISIBLE, -- window style
      CW_USEDEFAULT,                    -- initial x position
      CW_USEDEFAULT,                    -- initial y position
      CW_USEDEFAULT,                    -- initial x size
      CW_USEDEFAULT,                    -- initial y size
      0,                                -- parent window handle
      hmenu,                            -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters

hEdit = winapi.CreateWindowExW(
      0,
      toUCS2Z("EDIT"),                  -- window class name
      toUCS2Z("Getting Started"),       -- window caption
      WS_VISIBLE + WS_CHILD,            -- window style
      CW_USEDEFAULT,                    -- initial x position
      CW_USEDEFAULT,                    -- initial y position
      CW_USEDEFAULT,                    -- initial x size
      CW_USEDEFAULT,                    -- initial y size
      hWnd,                             -- parent window handle
      0,                                -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters


hLabel = winapi.CreateWindowExW(
      0,
      toUCS2Z("static"),                -- window class name
      toUCS2Z("Getting Started"),       -- window caption
      WS_VISIBLE + WS_CHILD,            -- window style
      200,                              -- initial x position
      200,                              -- initial y position
      100,                              -- initial x size
      100,                              -- initial y size
      hWnd,                             -- parent window handle
      0,                                -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters


hBtn = winapi.CreateWindowExW(
      0,
      toUCS2Z("BUTTON"),                -- window class name
      toUCS2Z("mein button"),           -- window caption
      WS_VISIBLE + WS_CHILD,            -- window style
      20,                               -- initial x position
      320,                              -- initial y position
      100,                              -- initial x size
      20,                               -- initial y size
      hWnd,                             -- parent window handle
      0,                                -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters


print("----------- hwnd ", hWnd)
if (0 == hWnd) then
  error(WinError())
end

print("---------------ShowWindow -------------------")
hWnd:ShowWindow(SW_SHOW)
-- alternative:
-- winapi.ShowWindow(hWnd, SW_SHOW)

print("---------------UpdateWindow -------------------")
hWnd:UpdateWindow()

print("---------------ProcessMessages -------------------")
return winapi.ProcessMessages()

-- print("---------------end  -------------------")

--[[
-- this is possible, too

msg = winapi.MSG:new()
while (GetMessage(msg.__ptr, NULL, 0, 0)) do
  TranslateMessage(msg.__ptr);
  DispatchMessage(msg.__ptr);
end
return msg.wParam
]]


