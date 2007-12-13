--[[----------------------------------------------------------------------------
UTF8_check.lua
Author: VladVRO
version 1.0

Автоматическое переключение кодировки в UTF-8
для html файлов содержащих "Content-Type: text/html; charset=UTF-8"
и для файлов содержащих символы русского алфавита в UTF-8 кодировке

Подключение:
В файл SciTEStartup.lua добавить строку:
	dofile ("UTF8_check.lua")
В файле настроек добавить:
	utf8.check=1

Дополнительно:
есть возможность ограничить зону поиска в файле начальным блоком задав в настройках:
	utf8.check.max=<кол-во байт>
это позволит быстрее открывать большие по размеру файлы, но снизит вероятность
правильного определения кодировки.
--]]----------------------------------------------------------------------------

local function utf8_check ()
	if props["utf8.check"] == "1" then
		local maxpos = tonumber(props["utf8.check.max"])
		if not maxpos then maxpos = editor.Length end
		-- html content-type
		if string.find(props["file.patterns.html"], props["FileExt"]) ~= nil then
			if editor:findtext("Content-Type: text/html; charset=UTF-8", SCFIND_POSIX, 0, maxpos) then
				scite.MenuCommand(IDM_ENCODING_UCOOKIE)
				return
			end
		end
		-- by russian alphabet
		local pattern = "[РС]"
		local pos = editor:findtext(pattern, SCFIND_REGEXP, 0)
		while pos do
			local c0 = editor.CharAt[pos]
			if c0 < 0 then c0 = c0 + 256 end
			local c1 = editor.CharAt[pos+1]
			if c1 < 0 then c1 = c1 + 256 end
			if (c0 == 208 and c1 >= 144 and c1 <= 175) or
				 (c0 == 209 and c1 >= 128 and c1 <= 145)
			then
				scite.MenuCommand(IDM_ENCODING_UCOOKIE)
				return
			end
			pos = editor:findtext(pattern, SCFIND_REGEXP, pos+1, maxpos)
		end
	end
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen (filename)
	local result
	if old_OnOpen then result = old_OnOpen(filename) end
	
	utf8_check()
	
	return result
end
