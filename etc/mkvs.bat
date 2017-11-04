@rem Script to build LuaWinAPI under "Visual Studio .NET Command Prompt".
@rem Do not run from this directory; run it from the toplevel: etc\mkvs.bat.
@rem It creates LuaWinAPI.dll in src.

@setlocal

set LUAWINAPIROOT=%CD%

@set LUAROOT=c:/Lua/5.1
@set LUAINCLUDE=%LUAROOT%/include
@set LUALIB=%LUAROOT%/lib

@set LUACWRAPROOT=%LUAWINAPIROOT%/../luacwrap
@set LUACWRAPINCLUDE=%LUACWRAPROOT%/include
@set LUACWRAPLIB=%LUACWRAPROOT%/src

@set MYCOMPILE=cl /nologo /MD /O2 /W3 /c /GS- /D_CRT_SECURE_NO_DEPRECATE /DLUAWINAPI_API="" /I%LUAINCLUDE% /I%LUACWRAPINCLUDE%
@set MYLINK=link /nologo /LIBPATH:%LUALIB% /LIBPATH:%LUACWRAPLIB%
@set MYMT=mt /nologo

cd src

@rem create luawinapi.dll
%MYCOMPILE% enumwindow.c gdihelpers.c gen_abstractions.c gen_structs.c stdcallthunk.c luawinapi.c wndproc.c drvproc.c luaaux.c
%MYLINK% /DLL /MACHINE:X86 /MANIFEST /MANIFESTFILE:"luawinapi.dll.manifest" /MANIFESTUAC:"level='asInvoker' uiAccess='false'" /out:luawinapi.dll /DEF:luawinapi.def enumwindow.obj gdihelpers.obj gen_abstractions.obj gen_structs.obj stdcallthunk.obj luawinapi.obj wndproc.obj drvproc.obj luaaux.obj lua5.1.lib luacwrap.lib kernel32.lib user32.lib gdi32.lib comctl32.lib comdlg32.lib shell32.lib winmm.lib Msimg32.lib
if exist luawinapi.dll.manifest^
  %MYMT% -manifest luawinapi.dll.manifest -outputresource:luawinapi.dll;2

rem copy luawinapi.dll c:\Lua\5.1\clibs
rem mkdir c:\Lua\5.1\lua\winapi
rem copy *.lua c:\Lua\5.1\lua\winapi

@rem cleanup
del *.obj *.manifest
cd ..
