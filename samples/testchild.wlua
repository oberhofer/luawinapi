--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test child windows
  
--]==]

winapi = require("winapi")


-- start
print("-----------------GetModuleHandleW")

hInstance = winapi.GetModuleHandleW(nil)

clsFirst  = toUCS2Z("ClassFirst")
clsSecond = toUCS2Z("ClassSecond")

function RunModal(parent, child)
  assert(parent)
  assert(child)

  if(parent) then
--    winapi.EnableWindow(parent, FALSE);
--    winapi.ShowWindow(parent, SW_HIDE);
  end

  winapi.BringWindowToTop(child);
  winapi.ShowWindow(child, SW_SHOW);
  winapi.UpdateWindow(child);

  print(">>RunModal")
  local msg  = winapi.MSG:new()

  print("start loop")
  while (winapi.GetMessageW(msg, NULL, 0, 0) > 0) do

    if (WM_CLOSE == msg.message) then
      print("break loop")
      break;
    end

    winapi.TranslateMessage(msg)
    winapi.DispatchMessageW(msg)
  end

  print("end loop")
  print("<<RunModal")

  winapi.ShowWindow(child, SW_HIDE);

  if(parent) then
    winapi.EnableWindow(parent, TRUE);
    winapi.ShowWindow(parent, SW_SHOW);
    winapi.SetForegroundWindow(parent);
    winapi.UpdateWindow(parent);
  end
end


function CreateWndProc(handlers)

  local function WndProc(hwnd, msg, wParam, lParam)
    -- print(hwnd, msg, wParam, lParam)
    local handler = handlers[msg]
    if (handler) then
      return handler(hwnd, wParam, lParam)
    else
      return winapi.DefWindowProcW(hwnd, msg, wParam, lParam)
    end
  end

  return WndProc
end

WndProcFirst = CreateWndProc{
  [WM_DESTROY] = function(hwnd, wParam, lParam)
    winapi.PostQuitMessage(0)
    return 0
  end,
  [WM_COMMAND] = function(hwnd, wParam, lParam)
    if (BN_CLICKED == HIWORD(wParam)) then
      RunModal(hFirst, hSecond);
    end
    return 0
  end
}

WndProcSecond = CreateWndProc{
  [WM_CLOSE] = function(hwnd, wParam, lParam)
    winapi.PostQuitMessage(0)
    return 0
  end,
  [WM_DESTROY] = function(hwnd, wParam, lParam)
    return 0
  end,
  [WM_COMMAND] = function(hwnd, wParam, lParam)
    if (BN_CLICKED == HIWORD(wParam)) then
      winapi.PostQuitMessage(0)
    end
    return 0
  end
}

callbackFirst  = winapi.WndProc.new(nil, WndProcFirst)
callbackSecond = winapi.WndProc.new(nil, WndProcSecond)

wcFirst = winapi.WNDCLASSW:new()
wcFirst.style          = CS_HREDRAW + CS_VREDRAW;
wcFirst.lpfnWndProc    = callbackFirst.entrypoint
wcFirst.cbClsExtra     = 0
wcFirst.cbWndExtra     = 0
wcFirst.hInstance      = hInstance
wcFirst.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
wcFirst.hCursor        = winapi.LoadCursorW(NULL, IDC_ARROW);
wcFirst.hbrBackground  = winapi.GetStockObject(WHITE_BRUSH);
wcFirst.lpszMenuName   = 0
wcFirst.lpszClassName  = clsFirst

wcSecond = winapi.WNDCLASSW:new()
wcSecond.style          = CS_HREDRAW + CS_VREDRAW;
wcSecond.lpfnWndProc    = callbackSecond.entrypoint
wcSecond.cbClsExtra     = 0
wcSecond.cbWndExtra     = 0
wcSecond.hInstance      = hInstance
wcSecond.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
wcSecond.hCursor        = winapi.LoadCursorW(NULL, IDC_ARROW);
wcSecond.hbrBackground  = winapi.GetStockObject(WHITE_BRUSH);
wcSecond.lpszMenuName   = 0
wcSecond.lpszClassName  = clsSecond

print("-----------------RegisterClassW")

atom1 = winapi.RegisterClassW(wcFirst);
print("-----------------atom", atom1)
if (not atom1) then
  error(WinError())
end

atom2 = winapi.RegisterClassW(wcSecond);
print("-----------------atom", atom2)
if (not atom2) then
  error(WinError())
end

print("---------------CreateWindowExW -------------------")
hFirst = winapi.CreateWindowExW(
    0,
      clsFirst,                     -- window class name
      toUCS2Z("First Window"),      -- window caption
      WS_CAPTION + WS_SYSMENU,      -- window style
      0,                            -- initial x position
      0,                            -- initial y position
      200,                          -- initial x size
      200,                          -- initial y size
      0,                            -- parent window handle
      0,                            -- window menu handle
      hInstance,                    -- program instance handle
      0);                           -- creation parameters
      print("----------- hFirst ", hFirst)
if (0 == hFirst) then
    error(WinError())
end

button = winapi.CreateWindowExW(
      0,
      toUCS2Z("BUTTON"),            -- window class name
      toUCS2Z("Open Modal"),        -- window caption
      WS_CHILD + WS_VISIBLE,        -- window style
      20,                           -- initial x position
      20,                           -- initial y position
      100,                          -- initial x size
      100,                          -- initial y size
      hFirst,                       -- parent window handle
      0,                            -- window menu handle
      hInstance,                    -- program instance handle
      0);                           -- creation parameters


hSecond = winapi.CreateWindowExW(
    0,
      clsSecond,                    -- window class name
      toUCS2Z("Second Window"),     -- window caption
      WS_CAPTION + WS_SYSMENU,      -- window style
      0,                            -- initial x position
      0,                            -- initial y position
      200,                          -- initial x size
      200,                          -- initial y size
      0,                            -- parent window handle
      0,                            -- window menu handle
      hInstance,                    -- program instance handle
      0);                           -- creation parameters

button = winapi.CreateWindowExW(
      0,
      toUCS2Z("BUTTON"),            -- window class name
      toUCS2Z("Close"),             -- window caption
      WS_CHILD + WS_VISIBLE,        -- window style
      20,                           -- initial x position
      20,                           -- initial y position
      100,                          -- initial x size
      100,                          -- initial y size
      hSecond,                      -- parent window handle
      0,                            -- window menu handle
      hInstance,                    -- program instance handle
      0);                           -- creation parameters

print("---------------ShowWindow -------------------")

-- hFirst:ShowWindow(SW_SHOW)
-- alternative:
print("hFirst.handle", hFirst.handle)
winapi.ShowWindow(hFirst, SW_SHOW)

print("---------------UpdateWindow -------------------")

hFirst:UpdateWindow()

print("---------------ProcessMessages -------------------")

msg = winapi.MSG:new()
while (winapi.GetMessageW(msg, NULL, 0, 0) > 0) do
  winapi.TranslateMessage(msg)
  winapi.DispatchMessageW(msg)
end
return msg.wParam

-- alternative:
-- return winapi.ProcessMessages()




