-- SciTE Abbreviation in UserList
-- Version: 1.0
-- Autor: Dmitry Maslov
---------------------------------------------------
-- При вводе слова, если это сокращение то вызывается список аббривиатур
-- Работу со списками подсмотрел в AutocompleteObject.lua (автор: mozers)
-- Примечание:
-- 1. Использует выподающий список № 11
-- 2. Полностью автономен (нужно подключить в SciTEStartup.lua)
---------------------------------------------------

local function GetWordLeft()
	editor:WordLeftExtend()
	-- обрабатываем # в cpp
	if editor.LexerLanguage == 'cpp' and editor.CharAt[editor.SelectionStart-1] == 35 then
		editor:CharLeftExtend()
	end
	local sel_text = editor:GetSelText()
	editor:CharRight()
	return sel_text
end

local function InsertProp(sel_value)
	editor:WordLeftExtend()
	-- обрабатываем # в cpp
	if editor.LexerLanguage == 'cpp' and editor.CharAt[editor.SelectionStart-1] == 35 then
		editor:CharLeftExtend()
	end
	editor:DeleteBack()
	scite.InsertAbbreviation(sel_value)
	return true
end

local function Abbrev()

	local abb_file = io.open(props["SciteDefaultHome"].."\\abbrev\\"..editor.LexerLanguage..".abbrev")
	if not abb_file then
		abb_file = io.open(props["SciteDefaultHome"].."\\home\\abbrev.properties")
		if not abb_file then
			return false
		end
	end

	local currword = GetWordLeft()
	local len_currword = string.len(currword)
	if len_currword < 1 then
		return false
	end
	
	local user_list = {}
	for line in abb_file:lines() do
		local abbrev_word = string.sub(line,1,len_currword)
		if string.sub(line,len_currword+1,len_currword+1)=='=' and 
						string.upper(abbrev_word) == string.upper(currword) then
			local str_method = string.sub(line,len_currword+2)
			table.insert (user_list,str_method)
		end
	end
	abb_file:close()
	local list_count = table.getn(user_list)
	if list_count > 0 then
		local s = table.concat(user_list, '•')
		if s ~= '' then
			local sep = editor.AutoCSeparator
			editor.AutoCSeparator = string.byte('•')
			editor:UserListShow(11, s)
			editor.AutoCSeparator = sep
			return true
		end
	end
	return false
end

-- Добавляем свой обработчик события OnChar
local old_OnChar = OnChar
function OnChar(char)
	if old_OnChar and old_OnChar(char) then 
		return true
	end
	if char ~= ' ' and Abbrev() then return true end
	return false
end

-- Add user event handler OnUserListSelection
local old_OnUserListSelection = OnUserListSelection
function OnUserListSelection(tp,sel_value)
	local result
	if old_OnUserListSelection then result = old_OnUserListSelection(tp,sel_value) end
	if tp == 11 then
		if InsertProp(sel_value) then return true end
	end
	return result
end
