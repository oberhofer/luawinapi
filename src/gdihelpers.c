//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
// GDI helper functions
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>

#include "gdihelpers.h"

void WINAPI DrawXorBar(HDC hdc, int x1, int y1, int width, int height)
{
  static WORD _dotPatternBmp[8] = 
  { 
    0x00aa, 0x0055, 0x00aa, 0x0055, 
    0x00aa, 0x0055, 0x00aa, 0x0055
  };

  HBITMAP hbm;
  HBRUSH  hbr, hbrushOld;

  hbm = CreateBitmap(8, 8, 1, 1, _dotPatternBmp);
  hbr = CreatePatternBrush(hbm);
  
  SetBrushOrgEx(hdc, x1, y1, 0);
  hbrushOld = (HBRUSH)SelectObject(hdc, hbr);
  
  PatBlt(hdc, x1, y1, width, height, PATINVERT);
  
  SelectObject(hdc, hbrushOld);
  
  DeleteObject(hbr);
  DeleteObject(hbm);
}
