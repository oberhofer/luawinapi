--[==[

  luawinapi - winapi wrapper for Lua
  Copyright (C) 2011 Klaus Oberhofer. See copyright notice in
  LICENSE file

  parser for winapi declaration files
  
--]==]

local lpeg = require 'lpeg'

---------------------------------------------------------------------------
-- shortcuts
--
local locale                         = lpeg.locale();
local P, R, S, C, V                  = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V
local C, Cb, Cc, Cg, Cs, Ct, Cf, Cmt = lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Ct, lpeg.Cf, lpeg.Cmt

---------------------------------------------------------------------------
-- lexical elements
--

local whitespace = S' \t\v\n\f'
local WS = whitespace^0

local digit = R'09'
local letter = R('az', 'AZ') + P'_'
local alphanum = letter + digit
local hex = R('af', 'AF', '09')
local exp = S'eE' * S'+-'^-1 * digit^1
local fs = S'fFlL'
local is = S'uUlL'^0

local hexnum = P'0' * S'xX' * hex^1 * is^-1
local octnum = P'0' * digit^1 * is^-1
local decnum = digit^1 * is^-1
local numlit = (hexnum + octnum + decnum) * WS / tonumber

local stringlit = (P'L'^-1 * P'"' * (P'\\' * P(1) + (1 - S'\\"'))^0 * P'"') * WS

local literal = numlit + stringlit
        -- / function(...) print('LITERAL', ...) end

local keyword = P"typedef"

local identifier = (letter * alphanum^0 - keyword * (-alphanum))
        -- / function(...) print('ID',...) end

local endline = (S'\n' + -P(1))
local comment = (P'#' * (1 - endline)^0 * endline)


---------------------------------------------------------------------------
-- helper functions
--
function indexattribs(...)
  result = {}
  for _, v in ipairs({...}) do
    result[v] = true
  end
  return result
end

---------------------------------------------------------------------------
-- syntax for function declarations
--
local functions = P{"declOrComment";

  attributes    = (P'[' * WS * C(identifier^0) * WS * (',' * WS * C(identifier) * WS)^0 * P']') / indexattribs * WS;

  attribs_opt   = Cg(V"attributes", "attribs")^-1;

  parameter     = Ct(V"attribs_opt" * WS * Cg(identifier, "typ")) * WS;

  parameterlist = Ct(P'(' * WS * V"parameter"^0 * (',' *  WS * V"parameter")^0 * P')');

  -- [notCE] WINUSERAPI BOOL WINAPI IsMenu(HMENU);
  functiondeclaration = Ct(V"attribs_opt" * WS * identifier * WS *
                        Cg(identifier, "rettype") * WS *
                        identifier * WS *
                        Cg(identifier, "name") * WS *
                        Cg(V"parameterlist", "params") * WS * P';' * WS);

  declOrComment = Ct((comment + V"functiondeclaration")^0);
}


funcgrammar = WS * functions * -1

---------------------------------------------------------------------------
-- syntax for struct declarations
--
local structs = P{"structdeclarations";

  attributes    = (P'[' * WS * C(identifier^0) * WS * (',' * WS * C(identifier) * WS)^0 * P']') / indexattribs * WS;

  attribs_opt   = Cg(V"attributes", "attribs")^-1;

  arraypostfix  = P'[' * WS * Cg((numlit + identifier), "len") * WS * P']' * WS;

  simple_member = Cg(identifier, "typ") * WS * Cg(identifier, "name");

  struct_member = (P"union" + P"struct") * WS * identifier^-1 * WS * P'{' * WS
                    * Cg(V"memberlist", "members")
                    * P'}' * WS * Cg(identifier, "name");


  member        = Ct(V"attribs_opt" * WS
					* (V"struct_member" + V"simple_member") * WS
					* V"arraypostfix"^-1) * P';' * WS;

  memberlist    = Ct(V"member"^0);

  -- [notCE]  typedef struct tagName {
  --            UINT mask;
  --          } NAME;
  structdeclaration = Ct(V"attribs_opt" * WS * P"typedef" * WS * P"struct" * WS * identifier^-1 * WS *
                         P'{' * WS * Cg(V"memberlist", "members") * P'}' * WS * Cg(identifier, "name") * WS * P';') * WS;

  structdeclarations = Ct( (V"structdeclaration" * WS)^0 );
}


structgrammar = WS * structs * -1

