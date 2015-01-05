
local winapi = require("luawinapi")


print("UNDER_CE:", UNDER_CE)
print("WINVER:", string.format("0x%x", WINVER))
print("_WIN32_WINDOWS:", _WIN32_WINDOWS and string.format("0x%x", _WIN32_WINDOWS))
print("_WIN32_WINNT:", _WIN32_WINNT and string.format("0x%x", _WIN32_WINNT))

