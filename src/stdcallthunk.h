//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#pragma once

#include <windows.h>

int   __cdecl stdcallthunk_initialize(void);
void  __cdecl stdcallthunk_finalize(void);

PVOID stdcallthunk_create (PVOID procptr, PVOID pThis);
VOID  stdcallthunk_destroy(PVOID pThunk);


