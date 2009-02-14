--[[--------------------------------------------------
SortText.lua
Authors: Tugarinov Sergey & mozersЩ
version 2.0
------------------------------------------------------
Sorting selected lines_tbl alphabetically and vice versa
—ортировка выделенных строк по алфавиту и наоборот

Connection:
	Set in a file .properties:
		command.name.37.*=Sorting of lines_tbl AЕ z / zЕ A
		command.37.*=dofile $(SciteDefaultHome)\tools\SortText.lua
		command.mode.37.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

local lines_tbl = {} -- “аблица со строками нашего текста
local sort_direction_decreasing = false -- ќбратный пор€док сортировки

-- сравниваем две строки
local function CompareTwoLines(line1, line2)
	line1 = line1:gsub('^%s*', '')
	line2 = line2:gsub('^%s*', '')
	if sort_direction_decreasing then
		return (line1:lower() > line2:lower())
	else
		return (line1:lower() < line2:lower())
	end
end

-- автоматически определ€ем направление сортировки сравнива€ две первые неравные строки
local function GetSortDirection()
	local prev_line = lines_tbl[1]
	for _, current_line in pairs(lines_tbl) do
		if current_line:gsub('^%s*', '') ~= prev_line:gsub('^%s*', '') then
			return not CompareTwoLines(current_line, prev_line)
		end
	end
end

local sel_text = editor:GetSelText()
local sel_start = editor.SelectionStart
local sel_end = editor.SelectionEnd
if sel_text ~= '' then
	local current_line = ''
	-- раздел€ем на строки и загон€ем их в таблицу
	for current_line in sel_text:gmatch('[^\n]+') do
		lines_tbl[#lines_tbl+1] = current_line
	end
	if #lines_tbl > 2 then
		sort_direction_decreasing = GetSortDirection()
		-- сортируем строки в таблице
		table.sort(lines_tbl, CompareTwoLines)
		-- соедин€ем все строки из таблицы вместе
		local out_text = table.concat(lines_tbl, '\n')..'\n'
		editor:ReplaceSel(out_text)
	end
end
-- восстанавливаем выделение
editor:SetSel(sel_start, sel_end)