-- AutocompleteObject.lua
-- mozers™
-- version 1.5
------------------------------------------------
-- Ввод разделителя, заданного в autocomplete.[lexer].start.characters
-- вызывает список свойств и медодов объекта из соответствующего api файла
-- Ввод пробела или разделителя изменяют регистр символов в имени объекта в соответствии с записью в api файле
-- (например "ucase" при вводе автоматически заменяется на "UCase")
------------------------------------------------
-- Inputting of the symbol set in autocomplete.[lexer].start.characters causes the popup list of properties and methods of object. They undertake from corresponding api-file.
-- In the same case inputting of a space or a separator changes the case of symbols in object's name according to a api-file.
-- (for example "ucase" is automatically replaced on "UCase".)
------------------------------------------------
-- Подключение:
-- В файл SciTEStartup.lua добавьте строку:
--   dofile (props["SciteDefaultHome"].."\\tools\\AutocompleteObject.lua")
-- задайте в файле .properties соответствующего языка путь к API файлу
--   api.lua=$(SciteDefaultHome)\api\SciTELua.api
-- и символ, после ввода которого, будет включатся автодополнение:
--   autocomplete.lua.start.characters=.:
------------------------------------------------
-- Connection:
-- In file SciTEStartup.lua add a line:
--   dofile (props["SciteDefaultHome"].."\\tools\\AutocompleteObject.lua")
-- Set in a file .properties:
--   api.lua=$(SciteDefaultHome)\api\SciTELua.api
--   autocomplete.lua.start.characters=.:
------------------------------------------------
local function IsComment()
	local style = editor.StyleAt[editor.CurrentPos-2]
	local ext = props["FileExt"]
	if ext == 'css' then
		if style == 9 then return true end
	else
		if (style >= 1 and style <= 3) then return true end
	end
end

local function GetWordLeft()
	pos = editor.CurrentPos
	editor:CharLeft()
	editor:WordLeftExtend()
	local sel_text = editor:GetSelText()
	editor:CharRight()
	editor:CharRight()
	return sel_text
end

local function InsertProp(sel_value)
	local pos_new = editor.CurrentPos
	if pos_new ~= pos then
		editor:SetSel(pos, pos_new)
		editor:DeleteBack()
	end
	editor:InsertText(-1, sel_value)
	pos = pos + string.len(sel_value)
	editor.CurrentPos = pos
	editor:CharRight()
	return true
end

local function AutocompleteObject(char)
	if IsComment() then return false end

	if char ~= " " then
		if string.find(props["autocomplete."..editor.LexerLanguage..".start.characters"], char, 1, 1) == nil then
			return false
		end
	end

	-- Get api file
	local api_filename = props['api.'..editor.LexerLanguage]
	local api_file = io.open(api_filename)
	if not api_file then
		return false
	end

	-- Get object name
	local object = GetWordLeft()..char
	local len_obj = string.len(object)
	if len_obj < 2 then
		return false
	end

	-- Find methods and properties object's in api file (create UserList)
	local object_api = ''
	local user_list = {}
	for line in api_file:lines() do
		local api_object = string.sub(line,1,len_obj)
		if string.upper(api_object) == string.upper(object) then
			object_api = string.sub(api_object,1,len_obj)
			if not (char == " " or char == "(") then
				local str_method = string.sub(line,len_obj+1)
				local end_str = string.find(str_method,'[^a-zA-Z_]')
				if end_str ~= nil then
					str_method = string.sub(str_method, 1, end_str-1)
				end
				table.insert (user_list,str_method)
			end
		end
	end
	api_file:close()

	-- Correct register of symbols (sample: wscript -> WScript)
	if object_api ~= '' then
		local s = pos - len_obj
		editor:SetSel(s, pos)
		editor:ReplaceSel(object_api)
	end 

	-- Show UserList
	local list_count = table.getn(user_list)
	if list_count > 0 then
		table.sort(user_list)
		local s = table.concat(user_list, " ")
		if s ~= '' then
			editor:UserListShow(10, s)
			return true
		else
			return false
		end
	else
		return false
	end
end

-- Add user event handler OnChar
local old_OnChar = OnChar
function OnChar(char)
	local result
	if old_OnChar then result = old_OnChar(char) end
	if AutocompleteObject(char) then return true end
	return result
end

-- Add user event handler OnUserListSelection
local old_OnUserListSelection = OnUserListSelection
function OnUserListSelection(tp,sel_value)
	local result
	if old_OnUserListSelection then result = old_OnUserListSelection(tp,sel_value) end
	if tp == 10 then
		if InsertProp(sel_value) then return true end
	end
	return result
end
