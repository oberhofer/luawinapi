#------
# Load configuration
#
include ../config

#------
# Modules belonging to LuaWinAPI
#
LUAWINAPI_OBJS:= \
  enumwindow.o \
  gdihelpers.o \
  gen_abstractions.o \
  gen_structs.o \
  luaaux.o \
  stdcallthunk.o \
  winapi.o

#------
# all target
#
all: $(LUAWINAPI_LIBNAME)

#------
# creates luacwrap dynamic library
#
$(LUAWINAPI_LIBNAME): $(LUAWINAPI_OBJS)
	$(LD) $(LDFLAGS) -o $@ $(LUAWINAPI_OBJS) libwinapi.def lua5.1.dll luacwrap.dll

#------
# List of dependencies
#
enumwindow.o: enumwindow.c gen_abstractions.h luaaux.h
gdihelpers.o: gdihelpers.c gdihelpers.h
gen_abstractions.o: gen_abstractions.c gen_abstractions.h gen_structs.h
gen_structs.o: gen_structs.c gdihelpers.h gen_structs.h gen_abstractions.h
luaaux.o: luaaux.c luaaux.h
stdcallthunk.o: stdcallthunk.c stdcallthunk.h
winapi.o: winapi.c luaaux.h stdcallthunk.h

#------
# cleanup dynamic libraries and links
#
clean:
	rm -f $(LUAWINAPI_LIBNAME)
	rm -f $(LUAWINAPI_OBJS)

#------
# End of makefile configuration
#
