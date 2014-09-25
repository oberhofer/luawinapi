--[==[

  string split function from http://lua-users.org/lists/lua-l/2006-12/msg00414.html
  
  usage:
  
    function ircsplit(cmd)
      local t = {}
      for word, colon, start in cmd:split("%s+(:?)()") do
        t[#t+1] = word
        if colon == ":" then
          t[#t+1] = cmd:sub(start)
          break
        end
      end
      return t
    end

--]==]

-------------------------------------------------------------------------------
function string:split(pat)
  local st, g = 1, self:gmatch("()("..pat..")")
  local function getter(self, segs, seps, sep, cap1, ...)
    st = sep and seps + #sep
    return self:sub(segs, (seps or 0) - 1), cap1 or sep, ...
  end
  local function splitter(self)
    if st then return getter(self, st, g()) end
  end
  return splitter, self
end

