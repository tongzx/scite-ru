-- SciTE Abbreviation in UserList
-- Version: 1.2
-- Author: Dmitry Maslov, frs
---------------------------------------------------
-- При вводе слова, если это сокращение то вызывается список аббревиатур
-- Подключение:
-- В файл SciTEStartup.lua добавьте строку:
--   dofile (props["SciteDefaultHome"].."\\tools\\abbrevlist.lua")
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
	ind = string.rep(" ",editor.Column[editor.CurrentPos])
		scite.InsertAbbreviation(string.gsub(sel_value,'\\n','\\n'..ind))
	return true
end

local function Abbrev()
	local abb_file = io.open(props["AbbrevPath"])
	if not abb_file then return false end

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
	if props['macro-recording'] ~= '1' and char ~= ' ' and Abbrev() then return true end
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
