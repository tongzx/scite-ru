--[[----------------------------------------------------------------------------
UTF8_check.lua
Author: VladVRO, Tymur Gubayev
version 2.0

Автоматическое переключение кодировки в UTF-8
для файлов содержащих символы русского алфавита в UTF-8 кодировке

Подключение:
В файл SciTEStartup.lua добавить строку:
	dofile ("UTF8_check.lua")
В файле настроек добавить:
	utf8.check=1
--]]----------------------------------------------------------------------------

-- Author: VladVRO (менее точен, но не требует внешних библиотек)
local function utf8_check ()
	-- by russian alphabet
	if editor:findtext("[\208\209][\128-\191][\208\209][\128-\191]", SCFIND_REGEXP, 0) then
		scite.MenuCommand(IDM_ENCODING_UCOOKIE)
	end
end

-- Author: Tymur Gubayev
local function IsUTF()
	require 'lpeg'
	local text = editor:GetText()
	local cont = lpeg.R("\128\191")   -- continuation byte
	local utf8 = lpeg.R("\0\127")^1
			+ (lpeg.R("\194\223") * cont)^1
			+ (lpeg.R("\224\239") * cont * cont)^1
			+ (lpeg.R("\240\244") * cont * cont * cont)^1
	local latin = lpeg.R("\0\127")^1
	local searchpatt = latin^0 * utf8 ^1 * -1
	if searchpatt:match(text) then
		scite.MenuCommand(IDM_ENCODING_UCOOKIE)
	end
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen (filename)
	local result
	if old_OnOpen then result = old_OnOpen(filename) end
	if props["utf8.check"] == "1" then
		if editor.CodePage ~= SC_CP_UTF8 then
			-- utf8_check()
			IsUTF()
		end
	end
	return result
end
