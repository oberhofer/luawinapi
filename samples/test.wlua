--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Simple test application for luawinapi

--]==]
winapi = require("luawinapi")


-- control IDs

ID_EDIT   = 1
ID_BUTTON = 2


-- start

print("-----------------GetModuleHandleW")

hInstance = winapi.GetModuleHandleW(nil)

clsname = "GettingStarted"


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
  [WM_NCHITTEST] = function(hwnd, wParam, lParam)

	print("WM_NCHITTEST")

    local hit = winapi.DefWindowProcW(hwnd, WM_NCHITTEST, wParam, lParam);
    if (hit == HTCLIENT) then
      hit = HTCAPTION;
    end
    return hit
  end,
  [WM_CREATE] = function(hwnd, wParam, lParam)


    local icon = winapi.LoadImageW(NULL, "logo.ico", IMAGE_ICON, 0, 0, LR_LOADFROMFILE)
	winapi.setIcon(hwnd, ICON_SMALL, icon)
	winapi.setIcon(hwnd, ICON_LARGE, icon)

    return 0
  end,
  [WM_DESTROY] = function(hwnd, wParam, lParam)
    winapi.PostQuitMessage(0)
    return 0
  end
}


function WndProc(hwnd, msg, wParam, lParam)
  print(hwnd, MSG_CONSTANTS[msg] or msg, wParam, lParam)
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
wndClass.lpszClassName  = winapi.widestringfromutf8(clsname)

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
winapi.AppendMenuW(hSubMenu, MF_STRING, 1, "Item 1");
winapi.AppendMenuW(hSubMenu, MF_STRING, 1, "Item 2");
winapi.AppendMenuW(hSubMenu, MF_STRING, 1, "Item 3");

winapi.AppendMenuW(hmenu, MF_POPUP, hSubMenu, "TopItem");
--]==]

local hmenu = winapi.CreateMenu()
local hSubMenu = winapi.CreateMenu()

local mii  = winapi.MENUITEMINFOW:new()

mii.cbSize = #mii
mii.fMask = MIIM_ID + MIIM_STRING + MIIM_DATA;
mii.fType = MFT_STRING;
mii.dwTypeData = winapi.widestringfromutf8("Item 1");
winapi.InsertMenuItemW(hSubMenu, winapi.GetMenuItemCount(hSubMenu), TRUE, mii);
mii.dwTypeData = winapi.widestringfromutf8("Item 2");
winapi.InsertMenuItemW(hSubMenu, winapi.GetMenuItemCount(hSubMenu), TRUE, mii);
mii.dwTypeData = winapi.widestringfromutf8("Item 3");
winapi.InsertMenuItemW(hSubMenu, winapi.GetMenuItemCount(hSubMenu), TRUE, mii);


mii.fMask = MIIM_STRING + MIIM_DATA + MIIM_SUBMENU;
mii.fType = MFT_STRING;
mii.hSubMenu = hSubMenu;
mii.dwTypeData = winapi.widestringfromutf8("TopItem");
winapi.InsertMenuItemW(hmenu, winapi.GetMenuItemCount(hmenu), TRUE, mii);


print("---------------CreateWindowExW -------------------")
hWnd = winapi.CreateWindowExW(
      0,
      clsname,                          -- window class name
      "Getting Started",                -- window caption
      WS_OVERLAPPEDWINDOW + WS_VISIBLE, -- window style
      CW_USEDEFAULT,                    -- initial x position
      CW_USEDEFAULT,                    -- initial y position
      CW_USEDEFAULT,                    -- initial x size
      CW_USEDEFAULT,                    -- initial y size
      0,                                -- parent window handle
      hmenu,                            -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters
assert(hWnd);

hEdit = winapi.CreateWindowExW(
      0,
      "EDIT",                           -- window class name
      "Getting Started",                -- window caption
      WS_VISIBLE + WS_CHILD,            -- window style
      CW_USEDEFAULT,                    -- initial x position
      CW_USEDEFAULT,                    -- initial y position
      CW_USEDEFAULT,                    -- initial x size
      CW_USEDEFAULT,                    -- initial y size
      hWnd,                             -- parent window handle
      0,                                -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters
assert(hEdit);

hLabel = winapi.CreateWindowExW(
      0,
      "static",                         -- window class name
      "Getting Started",                -- window caption
      WS_VISIBLE + WS_CHILD,            -- window style
      200,                              -- initial x position
      200,                              -- initial y position
      100,                              -- initial x size
      100,                              -- initial y size
      hWnd,                             -- parent window handle
      0,                                -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters
assert(hLabel);

hBtn = winapi.CreateWindowExW(
      0,
      "BUTTON",                         -- window class name
      "mein button",                    -- window caption
      WS_VISIBLE + WS_CHILD,            -- window style
      20,                               -- initial x position
      320,                              -- initial y position
      100,                              -- initial x size
      20,                               -- initial y size
      hWnd,                             -- parent window handle
      0,                                -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters
assert(hBtn);


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
-- return winapi.ProcessMessages()

-- [[
-- this is possible, too

msg = winapi.MSG:new()
while (0 ~= winapi.GetMessageW(msg, NULL, 0, 0)) do
  winapi.TranslateMessage(msg);
  winapi.DispatchMessageW(msg);
end

print("---------------end  -------------------")

return msg.wParam
--]]

