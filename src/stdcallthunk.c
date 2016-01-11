//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>

// correct value is determined within stdcallthunk_initialize()
size_t PAGE_SIZE = 4096;

/////////////////////////////////////////////////////////////////////////////
// Thunks for __stdcall member functions

#if defined(_M_IX86)

#pragma pack(push,1)
#ifndef _winapi_WCE

// StdWndProcThunk:
//   0000: 58                 pop         eax
//   0001: 68 00 00 00 80     push        80000000h
//   0006: 50                 push        eax
//   0007: E9 00 00 00 00     jmp         distance
//   000C: 00 00              add         byte ptr [eax],al
//   000E: 00 00              add         byte ptr [eax],al

typedef struct 
{
  UINT16 Reserved1;  //+00 reserved, do not use
  PVOID  pvContext;  //+02 pointer to the context data
  UINT16 Reserved2;  //+06 reserved, do not use
  UINT32 dwDistance; //+08 distance to procedure
  PVOID  pThunkNext; //+12 pointer to next thunk
} STDCALLTHUNK, *PSTDCALLTHUNK;


BOOL StdCallThunk_Init(PSTDCALLTHUNK pThunk, PVOID proc, void* pContext)
{
  static BYTE thunkBytes[] = { 0x58,                            // 0000:    pop         eax
                               0x68, 0x00, 0x00, 0x00, 0x80,    // 0001:    push        80000000h
                               0x50,                            // 0006:    push        eax
                               0xE9, 0x00, 0x00, 0x00, 0x00,    // 0007:    jmp         distance
                               0x00, 0x00, 0x00, 0x00 };        // 000c:    dd   0                ; pointer to next thunk

  memcpy(pThunk, thunkBytes, sizeof(STDCALLTHUNK));
  pThunk->pvContext   = pContext;
  pThunk->dwDistance  = (UINT32) proc
                      - ((UINT32) &pThunk->dwDistance + 4);

  // write block from data cache and
  //  flush from instruction cache
  FlushInstructionCache(GetCurrentProcess(), pThunk, sizeof(STDCALLTHUNK));
  return TRUE;
}

#else // _winapi_WCE

#error TODO

#endif // _winapi_WCE

#pragma pack(pop)

#elif defined(_M_AMD64)

PVOID StdCallThunk_Alloc(VOID);
VOID  StdCallThunk_Free(PVOID);

#pragma pack(push,1)

// StdWndProcThunk:
//   00: 48 83 EC 38        sub         rsp,38h
//   04: 4C 89 4C 24 20     mov         qword ptr [rsp+20h],r9
//   09: 4D 8B C8           mov         r9,r8
//   0C: 4C 8B C2           mov         r8,rdx
//   0F: 48 8B D1           mov         rdx,rcx
//   12: 48 B8 00 00 00 00  mov         rax,offset InvWndProc
//       00 00 00 00
//   1C: 48 B9 0D F0 AD 0B  mov         rcx,0BADF00D0BADF00Dh
//       0D F0 AD 0B
//   26: FF D0              call        rax
//   28: 48 83 C4 38        add         rsp,38h
//   2C: C3                 ret
//   2D: 66 66 90           xchg        ax,ax
//   30: 00 00              add         byte ptr [rax],al
//   32: 00 00              add         byte ptr [rax],al
//   34: 00 00              add         byte ptr [rax],al
//   36: 00 00              add         byte ptr [rax],al

typedef struct 
{
  UINT8  Reserved1[20]; //+00 reserved, do not use
  PVOID  pvRoutine;     //+20 pointer to procedure
  UINT16 Reserved2;     //+28 reserved, do not use
  PVOID  pvContext;     //+30 pointer to the context data
  UINT8  Reserved3[10]; //+38 reserved, do not use
  PVOID  pThunkNext;    //+48 pointer to next thunk
} STDCALLTHUNK, *PSTDCALLTHUNK;

BOOL StdCallThunk_Init(PSTDCALLTHUNK pThunk, PVOID proc, void* pContext)
{
  static BYTE thunkBytes[] = {0x48, 0x83, 0xEC, 0x38,             //   00:   sub         rsp,38h
                              0x4C, 0x89, 0x4C, 0x24, 0x20,       //   04:   mov         qword ptr [rsp+20h],r9
                              0x4D, 0x8B, 0xC8,                   //   09:   mov         r9,r8
                              0x4C, 0x8B, 0xC2,                   //   0C:   mov         r8,rdx
                              0x48, 0x8B, 0xD1,                   //   0F:   mov         rdx,rcx
                              0x48, 0xB8, 0x00, 0x00, 0x00, 0x00, 
                              0x00, 0x00, 0x00, 0x00,             //   12:   mov         rax,offset InvWndProc
                              0x48, 0xB9, 0x0D, 0xF0, 0xAD, 0x0B, 
                              0x0D, 0xF0, 0xAD, 0x0B,             //   1C:   mov         rcx,0BADF00D0BADF00Dh
                              0xFF, 0xD0,                         //   26:   call        rax
                              0x48, 0x83, 0xC4, 0x38,             //   28:   add         rsp,38h
                              0xC3,                               //   2C:   ret
                              0x66, 0x66, 0x90,                   //   2D:   xchg        ax,ax
                                                                  //         ALIGN 8
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                              0x00, 0x00                          //   30:   dq   0000000000000000H     ; pointer to next thunk
  };
  memcpy(pThunk, thunkBytes, sizeof(STDCALLTHUNK));
  pThunk->pvContext = pContext;
  pThunk->pvRoutine = proc;

  FlushInstructionCache(GetCurrentProcess(), pThunk, sizeof(STDCALLTHUNK));
  return TRUE;
}

#pragma pack(pop)

#elif defined(_M_ARM) && !defined(_M_THUMB)
#pragma pack(push,4)

// WndProcThunk:
//   00: E92D4000 stmdb       sp!, {lr}
//   04: E24DD004 sub         sp, sp, #4
//   08: E58D3000 str         r3, [sp]
//   0C: E1A03002 mov         r3, r2
//   10: E1A02001 mov         r2, r1
//   14: E1A01000 mov         r1, r0
//   18: E59F000C ldr         r0, [pc, #0xC]
//   1C: E1A0E00F mov         lr, pc
//   20: E59FF008 ldr         pc, [pc, #8]
//   24: E28DD004 add         sp, sp, #4
//   28: E8BD8000 ldmia       sp!, {pc}
// _o:
//   2C: 12345678 eornes      r5, r4, #0x78, 12
// _p:
//   30: 00000000 andeq       r0, r0, r0
// _n:
//   34: 00000000 andeq       r0, r0, r0


typedef struct STDCALLTHUNK
{
  UINT32 Reserved[11]; //+00 reserved, do not use
  PVOID  pvContext;    //+44 pointer to the context data
  PVOID  pvRoutine;    //+48 pointer to procedure
  struct STDCALLTHUNK*  pThunkNext;   //+52 pointer to next thunk
} STDCALLTHUNK, *PSTDCALLTHUNK;

// const bool __checkStdCallSize = assert(16 == sizeof(STDCALLTHUNK));

BOOL StdCallThunk_Init(PSTDCALLTHUNK pThunk, PVOID proc, void* pContext)
{
  static BYTE thunkBytes[] = {0x00, 0x40, 0x2D, 0xE9,   //   00: stmdb       sp!, {lr}
                              0x04, 0xD0, 0x4D, 0xE2,   //   04: sub         sp, sp, #4
                              0x00, 0x30, 0x8D, 0xE5,   //   08: str         r3, [sp]
                              0x02, 0x30, 0xA0, 0xE1,   //   0C: mov         r3, r2
                              0x01, 0x20, 0xA0, 0xE1,   //   10: mov         r2, r1
                              0x00, 0x10, 0xA0, 0xE1,   //   14: mov         r1, r0
                              0x0C, 0x00, 0x9F, 0xE5,   //   18: ldr         r0, [pc, #0xC]
                              0x0F, 0xE0, 0xA0, 0xE1,   //   1C: mov         lr, pc
                              0x08, 0xF0, 0x9F, 0xE5,   //   20: ldr         pc, [pc, #8]
                              0x04, 0xD0, 0x8D, 0xE2,   //   24: add         sp, sp, #4
                              0x00, 0x80, 0xBD, 0xE8,   //   28: ldmia       sp!, {pc}
                                                        // pvContext:
                              0x78, 0x56, 0x34, 0x12,   //   2C: eornes      r5, r4, #0x78, 12
                                                        // pvRoutine:
                              0x00, 0x00, 0x00, 0x00,   //   30: andeq       r0, r0, r0
                                                        // pThunkNext:
                              0x00, 0x00, 0x00, 0x00    //   34: andeq       r0, r0, r0

  };
  memcpy(pThunk, thunkBytes, sizeof(STDCALLTHUNK));
  pThunk->pvContext = pContext;
  pThunk->pvRoutine = proc;

  // write block from data cache and
  //  flush from instruction cache
  FlushInstructionCache(GetCurrentProcess(), pThunk, sizeof(STDCALLTHUNK));
  return TRUE;
}

#pragma pack(pop)
#else
#error Only ARM, AMD64 and X86 supported
#endif


// number of thunks per page
#define NUMTHUNKS ((PAGE_SIZE-sizeof(PVOID))/sizeof(STDCALLTHUNK))

#pragma pack(push,1)

//------------------------------------------------------------------------
// header for a procedure thunk block
// concats blocks of thunks
typedef struct _THUNKBLOCK
{
  struct _THUNKBLOCK* pNext;              // pointer to the next thunk block
  STDCALLTHUNK        Thunks[0];          // thunk table must fit within one page
} THUNKBLOCK, *PTHUNKBLOCK;

#pragma pack(pop)

// module globals
static CRITICAL_SECTION g_CritThunkLock;          // critical section
static PTHUNKBLOCK      g_pThunkBlockList = NULL; // pointer to block list
static PSTDCALLTHUNK    g_pFreeThunksList = NULL; // pointer to free thunk


PVOID stdcallthunk_create(PVOID proc, PVOID pContext)
{
  int idx;
  PSTDCALLTHUNK pThunk;

  EnterCriticalSection(&g_CritThunkLock);

  if (g_pFreeThunksList == NULL)
  {
    PTHUNKBLOCK pBlock;

    pBlock = (PTHUNKBLOCK)
      VirtualAlloc(NULL, PAGE_SIZE, MEM_COMMIT, PAGE_EXECUTE_READWRITE);

    if (pBlock == NULL)
    {
      LeaveCriticalSection(&g_CritThunkLock);
      return(NULL);
    }

    // chain in thunks within block
    pThunk = pBlock->Thunks;

    for (idx = 0; idx < NUMTHUNKS; idx++)
    {
      // chain thunks together
      pThunk[idx].pThunkNext = g_pFreeThunksList;
      g_pFreeThunksList = &pThunk[idx];
    }

    // chain in block
    pBlock->pNext = g_pThunkBlockList;
    g_pThunkBlockList = pBlock;
  }

  // chain out one chunk and
  pThunk = g_pFreeThunksList;
  g_pFreeThunksList = g_pFreeThunksList->pThunkNext;

  // initialize it
  StdCallThunk_Init(pThunk, proc, pContext);

  LeaveCriticalSection(&g_CritThunkLock);

  return pThunk;
}

VOID stdcallthunk_destroy(PVOID pThunk)
{
  EnterCriticalSection(&g_CritThunkLock);

  if (pThunk != NULL)
  {
    // StdCallThunk_Init(pThunk, &InvalidThunkProc, 0xdeadbeef)

    // chain in thunk
    *((PVOID*)pThunk) = g_pFreeThunksList;
    g_pFreeThunksList = (PSTDCALLTHUNK)pThunk;
  }

  LeaveCriticalSection(&g_CritThunkLock);
}

//////////////////////////////////////////////////////////////////////////
/**

  initialize module

*/////////////////////////////////////////////////////////////////////////
int stdcallthunk_initialize(void)
{
  SYSTEM_INFO sSysInfo;
  int err = 0;

  InitializeCriticalSection(&g_CritThunkLock);

  GetSystemInfo(&sSysInfo);     // populate the system information structure
  PAGE_SIZE = sSysInfo.dwPageSize;

  return( err == 0 );
}

//////////////////////////////////////////////////////////////////////////
/**

  finalize module

*/////////////////////////////////////////////////////////////////////////
void stdcallthunk_finalize(void)
{
  PTHUNKBLOCK pBlock;

  EnterCriticalSection(&g_CritThunkLock);

  while (g_pThunkBlockList)
  {
    pBlock = g_pThunkBlockList;
    g_pThunkBlockList = (PTHUNKBLOCK) pBlock->pNext;
    VirtualFree(pBlock, 0, MEM_RELEASE);
  }

  LeaveCriticalSection(&g_CritThunkLock);
  DeleteCriticalSection(&g_CritThunkLock);
}

