--[[--------------------------------------------------
Highlighting Identical Text
Version: 1.1.1
Author: mozers™
------------------------------
Авто подсветка текста, который совпадает с текущим словом или выделением
В файле настроек задается стиль подсветки
Внимание:
В скрипте используются функции из COMMON.lua (EditorMarkText, EditorClearMarks, GetCurrentWord)
------------------------------
Подключение:
Добавить в SciTEStartup.lua строку:
	dofile (props["SciteDefaultHome"].."\\tools\\highlighting_identical_text.lua")

Добавить в файл настроек параметр:
	highlighting.identical.text=0
и переключатель в меню Tools:
	command.checked.139.*=$(highlighting.identical.text)
	command.name.139.*=Highlighting Identical Text
	command.139.*=highlighting_identical_text_switch
	command.mode.139.*=subsystem:lua,savebefore:no

Дополнительно можно задать стиль используемого маркера (4):
	find.mark.4=#FF66FF,box

============================================================================
Если бы функция editor:findtext не вешала редактор при работе с UTF текстами,
то код можно было бы значитально оптимизировать (см. версию 1.0 этого скрипта).
Теперь кода почти в 2 раза больше и поиск русских слов в UTF не работает (только выделенный текст) :(
============================================================================
--]]----------------------------------------------------

local table_limit = 50 -- max кол-во результатов поиска (не рекомендуется ставить много)
local store_pos    -- переменная для хранения передыдущей позиции курсора
local store_text   -- переменная для хранения передыдущего текста
local mark_num = 4 -- номер используемого маркера
local all_text     -- текст текущего документа
local chars_count  -- кол-во символов в текущем документе

-- Переключатель подсветки (вкл/выкл) срабатывает из меню Tools
function highlighting_identical_text_switch()
	local prop_name = 'highlighting.identical.text'
	props[prop_name] = 1 - tonumber(props[prop_name])
	EditorClearMarks(mark_num)
end

local function IdenticalTextFinder()
	local match_table = {}
	local word_pattern

	-- Поиск слов, идентичных текущему (если ничего не выделено)
	function WordsMatch(find_word) -- Функция загоняет все результаты поиска в таблицу match_table
		local find_start = 1
		repeat
			local ident_word_start, ident_word_end, ident_word = all_text:find(word_pattern, find_start)
			if ident_word_start == nil then return end
			if ident_word == find_word then
				match_table[#match_table+1] = {ident_word_start-1, ident_word_end}
				if #match_table > table_limit then -- если результатов больше, чем указанное число, то не показываем их
					match_table = {}
					return
				end
			end
			find_start = ident_word_end + 1
		until false
	end

	-- Поиск идентичного текста (если выделен текст)
	function TextMatch(find_text) -- Функция загоняет все результаты поиска в таблицу match_table
		local find_start = 1
		repeat
			local ident_text_start, ident_text_end = all_text:find(find_text, find_start, true)
			if ident_text_start == nil then return end
			match_table[#match_table+1] = {ident_text_start-1, ident_text_end}
			if #match_table > table_limit then -- если результатов больше, чем указанное число, то не показываем их
				match_table = {}
				return
			end
			find_start = ident_text_end + 1
		until false
	end

	----------------------------------------------------------
	local current_pos = editor.CurrentPos
	if current_pos == store_pos then return end
	store_pos = current_pos

	local wholeword = false
	local cur_text = editor:GetSelText()
	if cur_text == '' then
		cur_text = GetCurrentWord()
		wholeword = true
	end
	if cur_text == store_text then return end
	store_text = cur_text

	EditorClearMarks(mark_num)
	if wholeword then
		word_pattern = '([' .. editor.WordChars .. ']+)'
		WordsMatch(cur_text)
	else
		TextMatch(cur_text)
	end
	if #match_table > 1 then
		for i = 1, #match_table do
			-- Отмечаем все слова, беря данные из таблицы match_table
			EditorMarkText(match_table[i][1], match_table[i][2]-match_table[i][1], mark_num)
		end
	end

end

-- Add user event handler OnUpdateUI
local old_OnUpdateUI = OnUpdateUI
function OnUpdateUI ()
	local result
	if old_OnUpdateUI then result = old_OnUpdateUI() end
	if props['FileName'] ~= '' then
		if tonumber(props["highlighting.identical.text"]) == 1 then
			if editor.Length ~= chars_count then
				all_text = editor:GetText()
				chars_count = editor.Length
			end
			IdenticalTextFinder()
		end
	end
	return result
end
