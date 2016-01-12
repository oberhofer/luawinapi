--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011-2016 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test file dialog
  
--]==]

local winapi = require("luawinapi")
local bit = require("bit32")

local bor = bit.bor

-- control IDs

ID_EDIT   = 1
ID_BUTTON = 2

-- commands
CMD_OPENFILE = 100
CMD_SAVEFILE = 101


-- start

print("-----------------GetModuleHandleW")

hInstance = winapi.GetModuleHandleW(nil)

clsname = toUCS2Z("GettingStarted")


handlers =
{
  [WM_CREATE] = function(hwnd, wParam, lParam)
    hEdit = winapi.CreateWindowExW(
        0,
          toUCS2Z("EDIT"),              -- window class name
          toUCS2Z("Getting Started"),   -- window caption
          bor(WS_VISIBLE, WS_CHILD, ES_MULTILINE),  -- window style
          CW_USEDEFAULT,                -- initial x position
          CW_USEDEFAULT,                -- initial y position
          CW_USEDEFAULT,                -- initial x size
          CW_USEDEFAULT,                -- initial y size
          hwnd,                         -- parent window handle
          0,                            -- window menu handle
          hInstance,                    -- program instance handle
          0)                            -- creation parameters
    winapi.Assert(hEdit);
    return 0
  end,
  [WM_WINDOWPOSCHANGED] = function(hwnd, wParam, lParam)
    local rc = winapi.RECT:new()
    winapi.GetClientRect(hwnd, rc)
    local x, y, w, h = rc.left, rc.top, rc.right-rc.left, rc.bottom-rc.top
    winapi.MoveWindow(hEdit, x, y, w, h, FALSE)
    return 0
  end,
  [WM_COMMAND] = function(hwnd, wParam, lParam)
    if (wParam == CMD_OPENFILE) then
      --
      print("Open file", hwnd)

      local buffer = string.rep("\0\0", 270)

      local ofn = winapi.OPENFILENAMEW:new()
      ofn.lStructSize = #ofn
      ofn.hwndOwner = hwnd.handle
      -- ofn.hInstance;
      -- ofn.lpstrFilter = _T("*.txt");
      -- ofn.lpstrCustomFilter
      -- ofn.nMaxCustFilter;
      -- ofn.nFilterIndex;
      ofn.lpstrFile = buffer
      ofn.nMaxFile = 260
      -- ofn.lpstrFileTitle;
      -- ofn.nMaxFileTitle;
      -- ofn.lpstrInitialDir;
      -- ofn.lpstrTitle;
      -- ofn.Flags;
      -- ofn.nFileOffset;
      -- ofn.nFileExtension;
      -- ofn.lpstrDefExt;
      -- ofn.lCustData;
      local result = winapi.GetOpenFileNameW(ofn)
      winapi.Assert(result);
      if (result ~= 0) then
        -- set filaname as caption text
        winapi.SendMessageW(hwnd.handle, WM_SETTEXT, 0, buffer)

        -- load filename
        local file = io.open(toASCII(buffer), "r")
        local content = file:read("*a")
        winapi.SendMessageW(hEdit.handle, WM_SETTEXT, 0, _T(content))
      end
    elseif (wParam == CMD_SAVEFILE) then
    
      local buffer = string.rep("\0\0", 270)
      
      --
      print("Save file")
      local ofn = winapi.OPENFILENAMEW:new()
      ofn.lStructSize = #ofn
      ofn.hwndOwner = hwnd.handle
      -- ofn.hInstance;
      ofn.lpstrFilter = _T("Text Files (*.txt)\0*.txt\0All Files (*.*)\0*.*\0");
      -- ofn.lpstrCustomFilter
      -- ofn.nMaxCustFilter;
      -- ofn.nFilterIndex;
      ofn.lpstrFile = buffer
      ofn.nMaxFile = 260
      ofn.lpstrFileTitle = _T("FileTitle");
      ofn.nMaxFileTitle = 9;
      -- ofn.lpstrInitialDir;
      ofn.lpstrTitle = _T("Title");
      ofn.Flags = bor(OFN_SHOWHELP, OFN_OVERWRITEPROMPT);
      -- ofn.nFileOffset;
      -- ofn.nFileExtension;
      -- ofn.lpstrDefExt = _T("txt");
      -- ofn.lCustData;
      local result = winapi.GetSaveFileNameW(ofn)
      winapi.Assert(result);
      if (result ~= 0) then
      end
    end
    return 0
  end,
  [WM_DESTROY] = function(hwnd, wParam, lParam)
    winapi.PostQuitMessage(0)
    return 0
  end
}

function WndProc(hwnd, msg, wParam, lParam)
  -- print(hwnd, MSG_CONSTANTS[msg], wParam, lParam)
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


local hmenu = winapi.CreateMenu();
local hSubMenu = winapi.CreateMenu();
winapi.AppendMenuW(hSubMenu, MF_STRING, CMD_OPENFILE, _T("OpenFile"));
winapi.AppendMenuW(hSubMenu, MF_STRING, CMD_SAVEFILE, _T("SaveFile"));

winapi.AppendMenuW(hmenu, MF_POPUP, hSubMenu, _T("File"));


print("---------------CreateWindowExW -------------------")
hMainWnd = winapi.CreateWindowExW(
    0,
      clsname,                          -- window class name
      toUCS2Z("Getting Started"),       -- window caption
      bor(WS_OVERLAPPEDWINDOW, WS_VISIBLE), -- window style
      CW_USEDEFAULT,                    -- initial x position
      CW_USEDEFAULT,                    -- initial y position
      CW_USEDEFAULT,                    -- initial x size
      CW_USEDEFAULT,                    -- initial y size
      0,                                -- parent window handle
      hmenu,                            -- window menu handle
      hInstance,                        -- program instance handle
      0)                                -- creation parameters


print("----------- hMainWnd ", hMainWnd)
if (0 == hMainWnd) then
    error(WinError())
end

print("---------------ShowWindow -------------------")
hMainWnd:ShowWindow(SW_SHOW)

print("---------------UpdateWindow -------------------")
hMainWnd:UpdateWindow()

print("---------------ProcessMessages -------------------")
return winapi.ProcessMessages()

-- print("---------------end  -------------------")

