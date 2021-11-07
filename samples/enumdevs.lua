--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  Test audio device enumeration

--]==]

local audio = require("luawinapi")


function enumWavDevices()

	local caps = audio.WAVEOUTCAPSW:new()

	for devid = 0, audio.waveOutGetNumDevs()-1 do

		print("Wave Device: ", devid)

		local res = audio.waveOutGetDevCapsW(devid, caps, #caps)
		print(res)

		-- print(caps)
		-- print(#caps.szPname)
		print(audio.utf8fromwidestring(caps.szPname))

	end

end


function enumMidiDevices()

	local caps = audio.MIDIOUTCAPSW:new()

	for devid = 0, audio.midiOutGetNumDevs()-1 do

		print("Midi Device: ", devid)

		local res = audio.midiOutGetDevCapsW(devid, caps, #caps)
		print(res)

		-- print(caps)
		-- print(#caps.szPname)
		print(audio.utf8fromwidestring(caps.szPname))

	end

end


function enumAuxDevices()

	local caps = audio.AUXCAPSW:new()

	for devid = 0, audio.auxGetNumDevs()-1 do

		print("Aux Device: ", devid, audio.auxGetNumDevs())

		local res = audio.auxGetDevCapsW(devid, caps, #caps)
		print(res)

		-- print(caps)
		-- print(#caps.szPname)
		print(audio.utf8fromwidestring(caps.szPname))

	end
end

function enumMixerDevices()

	local caps = audio.MIXERCAPSW:new()

	for devid = 0, audio.mixerGetNumDevs()-1 do

		print("Mixer Device: ", devid)

		local res = audio.mixerGetDevCapsW(devid, caps, #caps)
		print(res)

		-- print(caps)
		-- print(#caps.szPname)
		print(audio.utf8fromwidestring(caps.szPname))

	end
end

enumWavDevices()
enumMidiDevices()
enumAuxDevices()
enumMixerDevices()
