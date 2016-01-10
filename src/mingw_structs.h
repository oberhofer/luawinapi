//////////////////////////////////////////////////////////////////////////
//
// luawinapi - winapi wrapper for Lua
// Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
// LICENSE file
//
//////////////////////////////////////////////////////////////////////////

#include <windows.h>

#if defined(__GNUC__) 

// define winapi struct types not provided by mingw32 and/or mingw64

#if (_WIN32_WINNT >= 0x501)
typedef struct _LVGROUP {
    UINT cbSize;
    UINT mask;
    LPWSTR pszHeader;
    int cchHeader;
    LPWSTR pszFooter;
    int cchFooter;
    int iGroupId;
    UINT stateMask;
    UINT state;
    UINT uAlign;
#if (_WIN32_WINNT >= 0x0600)
    LPWSTR pszSubtitle;
    UINT cchSubtitle;
    LPWSTR pszTask;
    UINT cchTask;
    LPWSTR pszDescriptionTop;
    UINT cchDescriptionTop;
    LPWSTR pszDescriptionBottom;
    UINT cchDescriptionBottom;
    int iTitleImage;
    int iExtendedImage;
    int iFirstItem;
    UINT cItems;
    LPWSTR pszSubsetTitle;
    UINT cchSubsetTitle;
#endif /* _WIN32_WINNT >= 0x0600 */
} LVGROUP, FAR *PLVGROUP;

typedef struct _LVGROUPMETRICS {
    UINT cbSize;
    UINT mask;
    UINT Left;
    UINT Top;
    UINT Right;
    UINT Bottom;
    COLORREF crLeft;
    COLORREF crTop;
    COLORREF crRight;
    COLORREF crBottom;
    COLORREF crHeader;
    COLORREF crFooter;
} LVGROUPMETRICS, FAR *PLVGROUPMETRICS;


#endif


#endif
