--[[--------------------------------------------------
CIViewer (Color Image Viewer) v1.0
Автор: mozers™

* Preview of color or image under mouse cursor
* Предпросмотр цвета, заданного значением в виде "#6495ED" или "red" или рисунка по его URL
* Данный скрипт служит для обеспечения работоспособности основного приложения CIViewer.hta
-----------------------------------------------
Для подключения добавьте в свой файл .properties следующие строки:
    command.parent.112.*=9
    command.name.112.*=Color Image Viewer
    command.112.*="$(SciteDefaultHome)\tools\CIViewer\CIViewer.hta"
    command.mode.112.*=subsystem:shellexec

Добавьте в SciTEStartup.lua строку
    dofile (props["SciteDefaultHome"].."\\tools\\CIViewer\\CIViewer.lua")
--]]----------------------------------------------------

local function FileExist(path)
	if (os.rename (path,path)) then
		return true
	else
		return false
	end
end

-- Определяем слово под курсором мыши
local function GetWText(pos, word)
	if pos==0 then return end

	-- Проверка, не является ли слово под курсором частью URL
	local url = ""
	if string.len(word) > 4 then
		local cur_line = editor:LineFromPosition(pos)
		local line_start_pos = editor:PositionFromLine(cur_line)
		local line_end_pos = editor:PositionFromLine(cur_line + 1) - 2
		local s, e
		repeat
			s, e = editor:findtext ('[^"|= ]+', SCFIND_REGEXP, line_start_pos, line_end_pos)
			if s == nil then break end
			line_start_pos = e + 1
		until (pos >= s and pos < e)
		if s ~= nil then
			url = props["FileDir"].."\\"..editor:textrange(s, e)
			if not FileExist(url) then
				url = ""
			end
		end
	end

	-- Сохраняем найденное значение в переменной
	-- (CIViewer.hta будет периодически проверять это значение)
	if url ~= "" then
		props["civiewer.value"] = "@"..url
	else
		props["civiewer.value"] = word
	end
end

-- Add user event handler OnDwellStart
local old_OnDwellStart = OnDwellStart
function OnDwellStart(pos, word)
	local result
	if old_OnDwellStart then result = old_OnDwellStart(pos, word) end
	if GetWText(pos, word) then return true end
	return result
end
