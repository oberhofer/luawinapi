--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011-2016 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Simple test application for luawinapi under WindowsCE

--]==]

winapi = require("luawinapi")

-- should be set under WindowsCE
if (not UNDER_CE) then
  winapi.MessageBoxW(nil, _T("Sorry, no WindowsCE detected. Bye."), _T("Error"), MB_OK)
  return
end


-- global variables
g_hInstance        = winapi.GetModuleHandleW(nil)
-- g_uMsgMetricChange = winapi.RegisterWindowMessage(SH_UIMETRIC_CHANGE);

g_szClassName      = _T("{F5B17D44-C824-4891-8CE3-111C7071C703}")

function FindPrevInstance()
  local cTries = 0;

  -- Create a named event
  local hEvent = winapi.CreateEventW(nil, TRUE, FALSE, g_szClassName);
  if (hEvent ~= nil) then
    -- If the event already existed, that means there's another copy of our app
    -- already running
    if (winapi.GetLastError() == ERROR_ALREADY_EXISTS) then
      repeat
        -- Just in case the other window needs to finish initialization
        if (cTries) then
          Sleep(250);
        else
          Sleep(0);
        end

        -- Try to find the other application window
        local hwnd = winapi.FindWindow(g_szClassName, NULL);
        if (hwnd ~= NULL) then
          winapi.SetForegroundWindow(bor(hwnd, 0x01));
          winapi.CloseHandle(hEvent);
          return nil;
        end
        cTries = cTries + 1
      until (cTries == 2);  -- only try twice

      -- If we didn't find the window, the other application was probably
      -- shutting down, so we'll just continue
    end
  end
  return hEvent;
end

function CreateMainWindow(nShowCmd)

  WndProc_callback = winapi.WndProc.new(nil, MainWindowProc)

  -- Set up the window class description
  wndClass = winapi.WNDCLASSW:new()

  -- We want to redraw the window contents anytime we get resized. That way
  -- we'll respond appropriately when the user switches between portrait and
  -- landscape. If we had any child windows or controls, we'd need to
  -- reposition or resize them when we get a WM_SIZE message.
  wndClass.style          = CS_HREDRAW + CS_VREDRAW;
  wndClass.lpfnWndProc    = WndProc_callback.entrypoint
  wndClass.cbClsExtra     = 0
  wndClass.cbWndExtra     = 0
  wndClass.hInstance      = g_hInstance
  wndClass.hIcon          = 0  -- winapi.LoadIcon(NULL, IDI_APPLICATION);
  wndClass.hCursor        = winapi.LoadCursorW(NULL, IDC_ARROW);
  wndClass.hbrBackground  = COLOR_WINDOW + 1;
  wndClass.lpszMenuName   = 0
  wndClass.lpszClassName  = g_szClassName


  -- Register the window class
  local atom = winapi.RegisterClassW(wndClass);
  print("-----------------atom", atom)
  if (not atom) then
    error(WinError())
  end

  -- Create a window using the class we just registered. Note that the
  -- initial size and position don't matter, because we're going to make it
  -- fullscreen when we get WM_CREATE, before it's ever displayed.
  hwnd = winapi.CreateWindowExW(
        0,
        g_szClassName,                    -- window class name
        toUCS2Z("CeApp"),                 -- window caption
        WS_OVERLAPPEDWINDOW + WS_SYSMENU, -- window style
        CW_USEDEFAULT,                    -- initial x position
        CW_USEDEFAULT,                    -- initial y position
        CW_USEDEFAULT,                    -- initial x size
        CW_USEDEFAULT,                    -- initial y size
        0,                                -- parent window handle
        0,                                -- window menu handle
        g_hInstance,                      -- program instance handle
        0)                                -- creation parameters
  print("-----------------hwnd", hwnd)
  if (hwnd == nil) then
    error(WinError())
  end

  -- Make the window visible and paint before returning
  winapi.ShowWindow(hwnd, nShowCmd)
  winapi.UpdateWindow(hwnd)
  return hwnd
end


function main()
  -- Check to see if this application is already running
  local hEvent = FindPrevInstance();
  if (hEvent == nil) then
    -- We found another instance
    return -1;
  end

  -- create global SHACTIVATEINFO (needed within event loop)
  sai = winapi.SHACTIVATEINFO:new();

  -- Create our main application window
  hwnd = CreateMainWindow(SW_SHOW);
  if (hwnd == NULL) then
    -- Failed to initialize
    winapi.CloseHandle(hEvent);
    return GetLastError();
  end

  local result = winapi.ProcessMessages()

  -- This is the value we passed to PostQuitMessage()
--  winapi.CloseHandle(hEvent);

  return result;
end


function OnCreateMainWindow(hwnd)
  if (UNDER_CE) then
--[[
-- Create our softkey bar
    local shmbi = winapi.SHMENUBARINFO:new()
    shmbi.cbSize = #shmbi
    print(hwnd, hwnd.handle)
    shmbi.hwndParent = hwnd.handle
    shmbi.dwFlags = SHCMBF_HMENU
    shmbi.nToolBarId = IDM_MAIN
    shmbi.hInstRes = g_hInstance
    if (not winapi.SHCreateMenuBar(shmbi)) then
    return FALSE;
    end
--]]

    -- Windows Mobile applications should always display their main window
    -- full-screen. We're going to let the OS do this for us by calling
    -- SHInitDialog, even though technically this window isn't a dialog window.
    shidi = winapi.SHINITDLGINFO:new()
    shidi.dwMask = SHIDIM_FLAGS
    shidi.hDlg = hwnd.handle
    shidi.dwFlags = SHIDIF_SIZEDLGFULLSCREEN + SHIDIF_SIPDOWN
    if (not winapi.SHInitDialog(shidi)) then
      return FALSE;
    end
  end
  -- Get the current user preference for text size
  -- SHGetUIMetrics(SHUIM_FONTSIZE_PIXEL, g_dwFontSize, sizeof(g_dwFontSize), NULL);

  -- Success
  return TRUE;
end

function PaintMainWindow(hwnd)
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
end


handlers =
{
  [WM_CREATE] = function(hwnd, wParam, lParam)
    -- Initialize the static window state information. The shell helper functions
    -- will use this buffer to store their state.
    sai.cbSize = #sai

    -- Initialize the window (if we fail, return -1)
    if OnCreateMainWindow(hwnd) then
      return 0
    end
    return -1
  end,


  [WM_ACTIVATE] = function(hwnd, wParam, lParam)
    -- Calling this function when we get WM_ACTIVATE ensures that our
    -- application will handle the SIP properly. This function does
    -- nothing when we're running on Smartphone.
    winapi.SHHandleWMActivate(hwnd, wp, lp, sai, 0);
  return 0
  end,

  [WM_SETTINGCHANGE] = function(hwnd, wParam, lParam)
    -- This helper function will resize our main application window when the SIP
    -- goes up and down. Try commenting out this function and see how it affects
    -- our drawing code. This function is optional, so choose whichever behavior
    -- you prefer. Again, this function does nothing on Smartphone.
    winapi.SHHandleWMSettingChange(hwnd, wp, lp, sai);
  return 0
  end,

--[[
  [WM_HIBERNATE] = function(hwnd, wParam, lParam)
    -- We get this message when the device is running low on memory. All
    -- applications should free any memory and resources that they can. We'll
    -- free our cached bitmap and font, since we can just re-create them the next
    -- time we need them.
    return TRUE
  end,
]]

  [WM_COMMAND] = function(hwnd, wParam, lParam)
    if (LOWORD(wp) == ID_SWITCH) then
      winapi.InvalidateRect(hwnd, NULL, TRUE);
    end
  return 0
  end,

  [WM_KEYDOWN] = function(hwnd, wParam, lParam)
    -- Allow Ctrl+Q to quit the application. Most users won't ever see
    -- this, but it's handy for debugging.
    if ((wParam == string.byte('Q')) and
      (winapi.GetKeyState(VK_CONTROL) < 0)) then
      winapi.SendMessageW(hwnd, WM_CLOSE, 0, 0)
    end
  return 0
  end,

  [WM_PAINT] = function(hwnd, wParam, lParam)
    -- PaintMainWindow(hwnd)
    return 0
  end,

  [WM_DESTROY] = function(hwnd, wParam, lParam)
    -- When this window is destroyed, it's time to quit the application
    winapi.PostQuitMessage(0);
    return 0
  end,

--  [g_uMsgMetricChange] = function(hwnd, wParam, lParam)
--  end,
}


function MainWindowProc(hwnd, msg, wParam, lParam)
  local handler = handlers[msg]
  if (handler) then
    return handler(hwnd, wParam, lParam)
  else
    return winapi.DefWindowProcW(hwnd, msg, wParam, lParam)
  end
end

local status, err = pcall(main)
if (not status) then
  local text = err .. "\n" .. debug.traceback()
  winapi.MessageBoxW(nil, _T(text), _T("Error"), MB_OK)
end
