--[[--------------------------------------------------
AutocompleteObject.lua
mozers™
version 2.02
------------------------------------------------------
Ввод разделителя, заданного в autocomplete.[lexer].start.characters
вызывает список свойств и медодов объекта из соответствующего api файла
Ввод пробела или разделителя изменяют регистр символов в имени объекта в соответствии с записью в api файле
(например "ucase" при вводе автоматически заменяется на "UCase")
Внимание: В скрипте используется функция IsComment (обязательно подключение COMMON.lua)
props["APIPath"] доступно только в SciTE-Ru
------------------------------------------------------
Inputting of the symbol set in autocomplete.[lexer].start.characters causes the popup list of properties and methods of input_object. They undertake from corresponding api-file.
In the same case inputting of a space or a separator changes the case of symbols in input_object's name according to a api-file.
(for example "ucase" is automatically replaced on "UCase".)
Warning: This script needed function IsComment (COMMON.lua)
props["APIPath"] available only in SciTE-Ru
------------------------------------------------------
Подключение:
В файл SciTEStartup.lua добавьте строку:
  dofile (props["SciteDefaultHome"].."\\tools\\AutocompleteObject.lua")
задайте в файле .properties соответствующего языка
символ, после ввода которого, будет включатся автодополнение:
  autocomplete.lua.start.characters=.:
------------------------------------------------------
Connection:
In file SciTEStartup.lua add a line:
  dofile (props["SciteDefaultHome"].."\\tools\\AutocompleteObject.lua")
Set in a file .properties:
  autocomplete.lua.start.characters=.:
------------------------------------------------------
Для понимания алгоритма работы скрипта, условимся, что в записи
azimuth:left;list-style-|type:upper-roman
где курсор стоит в позиции, отмеченной знаком "|", часть
list-style  - будет называться "объект"
type        - будет называться "метод"
Все вышесказанное относится ко всем языкам программирования (css тут - только для примера)
Скрипт будет корректно работать только с "правильными" api файлами (см. описание формата в ActiveX.api)
------------------------------------------------------
Совет:
Если после ввода разделителя список свойств и методов не возник (хотя они описаны в api файле)
то, возможно, скрипт не смог распознать имя вашего объекта.
Помогите ему в этом, дописав такую строчку в редактируемый документ:
mydoc = document
где mydoc - имя Вашего объекта
document - имя этого же объекта, заданное в api файле
------------------------------------------------------
На что не хватило терпения:
1. Объединить функции CreateObjectsTable и CreateAliasTable в одну (чтобы обрабатывать api файлы за один проход)
2. Сделать вызов функций постоения таблиц более редким (сейчас они строются постоянно после ввода символа-разделителя)
3. Провести ревизию всех регулярных выражений (больше всего ошибок происходит из за них).
   Возможно паттерны стоит формировать динамически (сейчас функция fPattern не используется).
--]]----------------------------------------------------

local current_pos = 0    -- текущая позиция курсора
local sep_char = ''      -- введенный с клавиатуры символ (в нашем случае - один из разделителей ".:-")
local autocom_chars = '' -- паттерн, содержащий экранированные символы из параметра autocomplete.lexer.start.characters
local get_api = true     -- флаг, определяющий необходимость перезагрузки api файла
local api_table = {}     -- все строки api файла (очищенные от ненужной нам информации)
local objects_table = {} -- все "объекты", найденные в api файле
local alias_table = {}   -- сопоставления "синоним = объект"
local methods_table = {} -- все "методы" заданного "объекта", найденные в api файле
local object_names = {}  -- все имена имеющихся api файле "объектов", которым соответствует найденный в текущем файле "объект"

------------------------------------------------------

-- Тест для распечатки содержимого заданной таблицы
local function prnTable(name)
	print('> ________________')
	for i = 1, table.maxn(name) do
		print(name[i])
	end
	print('> ^^^^^^^^^^^^^^^')
end

-- Преобразовывает стринг в паттерн для поиска
local function fPattern(str)
	local str_out = ''
	for i = 1, string.len(str) do
		str_out = '%'..string.sub(str, i, i+1)
	end
	return str_out
end

-- Сортирует таблицу по алфавиту и удаляет дубликаты
local function TableSort(table_name)
	table.sort(table_name, function(a, b) return string.upper(a) < string.upper(b) end)
	-- remove duplicates
	for i = table.maxn(table_name)-1, 0, -1 do
		if table_name[i] == table_name[i+1] then
			table.remove (table_name, i+1)
		end
	end
	return table_name
end

------------------------------------------------------

-- Извлечение из api-файла реальных имен объектов, которые соответствуют введенному
-- т.е. введен "объект" wShort, а методы будем искать для WshShortcut и WshURLShortcut
local function GetObjectNames(text)
	local obj_names = {}
	-- Поиск по таблице имен "объектов"
	for i = 1, table.maxn(objects_table) do
		if string.upper(text) == string.upper(objects_table[i]) then
			table.insert(obj_names, objects_table[i])
			return obj_names -- если успешен, то завершаем поиск
		end
	end
	-- Поиск по таблице сопоставлений "объект - синоним"
	for i = 1, table.maxn(alias_table), 2 do
		if string.upper(text) == string.upper(alias_table[i+1]) then
			table.insert(obj_names, alias_table[i])
		end
	end
	return obj_names
end

-- Поиск деклараций присвоения пользовательской переменной реального объекта
-- т.е. в текущем файле ищем конструкции вида "синоним = объект"
local function FindDeclaration()
	local text_all = editor:GetText()
	local _start, _end, sVar, sRightString
	local pattern = '([%w%.%:%-%_]+)%s*=%s*([^%c]+)'
	_start = 1
	while true do
		_start, _end, sVar, sRightString = string.find(text_all, pattern, _start)
		if _start == nil then break end
		if sRightString ~= '' then
			-- анализируем текст справа от знака "=" (проверяем, объект ли там содержится)
			for sValue in string.gmatch(sRightString, "[%w%.%:%-%_]+") do
				local objects = GetObjectNames(sValue)
				for i = 1, table.maxn(objects) do
					if objects[i] ~= '' then
						-- если действительно, такой "объект" существует, то добавляем его в таблицу сопоставлений "объект - синоним"
						table.insert(alias_table, objects[i])
						table.insert(alias_table, sVar)
					end
				end
			end
		end
		_start = _end + 1
	end
end

-- Чтение api файла в таблицу api_table (чтобы потом не опрашивать диск, а все тащить из нее)
local function CreateAPITable()
	api_table = {}
	for api_filename in string.gmatch(props["APIPath"], "[^;]+") do
		if api_filename ~= '' then
			local api_file = io.open(api_filename)
			if api_file then
				for line in api_file:lines() do
					line = string.gsub(line,'[%s(].+$','') -- обрезаем комментарии
					if line ~= '' then
						table.insert(api_table, line)
					end
				end
				api_file:close()
			else
				api_table = {}
			end
		end
	end
	get_api = false
	return false
end

-- Создание таблицы, содержащей все имена "объектов" описанных в api файле
local function CreateObjectsTable()
	objects_table = {}
	for i = 1, table.maxn(api_table) do
		local line = api_table[i]
		local _start, _end, sObj = string.find(line, '^([^#].+)[%'..sep_char..']', 1)
		if _start ~= nil then
			table.insert(objects_table, sObj)
		end
	end
	objects_table = TableSort(objects_table)
end

-- Создание таблицы, содержащей все сопоставления "синоним = объект" описанные в api файле
local function CreateAliasTable()
	alias_table = {}
	local sVar_old
	for i = 1, table.maxn(api_table) do
		local line = api_table[i]
		local _start, _end, sVar, sValue = string.find(line, '^#(%w+)=([^%s]+)$', 1)
		if _start ~= nil then
			if sVar ~= sVar_old then
				table.insert(alias_table, sVar)
				table.insert(alias_table, sValue)
			end
			sVar_old = sVar
		end
	end
end

-- Создание таблицы "методов" заданного "объекта"
local function CreateMethodsTable(obj)
	for i = 1, table.maxn(api_table) do
		local line = api_table[i]
		-- ищем строки, которые начинаются с заданного "объекта"
		local _, _end = string.find(line, obj..sep_char, 1, 1)
		if _end ~= nil then
			local _start, _end, str_method = string.find(line, '([^%s%.%:%-]+)', _end)
			if _start ~= nil then
				table.insert (methods_table, str_method)
			end
		end
	end
end

-- Показываем раскрывающийся список "методов"
local function ShowUserList()
-- prnTable(methods_table)
	local list_count = table.getn(methods_table)
	if list_count > 0 then
		methods_table = TableSort(methods_table)
		local s = table.concat(methods_table, " ")
		if s ~= '' then
			editor:UserListShow(7, s)
			return true
		else
			return false
		end
	else
		return false
	end
end

-- Вставляет выбранный из раскрывающегося списка метод в редактируемую строку
local function InsertMethod(str)
	editor:SetSel(current_pos, editor.CurrentPos)
	editor:ReplaceSel(str)
end

-- ОСНОВНАЯ ПРОЦЕДУРА (обрабатываем нажатия на клавиши)
local function AutocompleteObject(char)
	if IsComment(editor.CurrentPos-2) then return false end  -- Если строка закомментирована, то выходим

	local autocomplete_start_characters = props["autocomplete."..editor.LexerLanguage..".start.characters"]
	-- Если введенного символа нет в параметре autocomplete.lexer.start.characters, то выходим
	if autocomplete_start_characters == '' then return false end
	if string.find(autocomplete_start_characters, char, 1, 1) == nil then return false end

	-- Наконец то мы поняли что введенный символ - именно тот разделитель!
	sep_char = char
	autocom_chars = fPattern(autocomplete_start_characters)

	if get_api == true then
		CreateAPITable()
	end
	if table.maxn(api_table) == 0 then return false end
	CreateObjectsTable()
	CreateAliasTable()
	FindDeclaration()
	-- prnTable(objects_table)
	-- prnTable(alias_table)

	current_pos = editor.CurrentPos
	local input_object = editor:textrange(editor:WordStartPosition(current_pos-1),current_pos-1) -- Берем в качестве объекта слово слева от курсора
	local object_len = string.len(input_object)
	if object_len < 1 then return '' end
	-- Если слева от курсора отсутствует слово, которое можно истолковать как имя объекта, то выходим
	object_names = GetObjectNames(input_object)
	-- prnTable(object_names)
	if table.maxn(object_names) == 0 then return false end
	methods_table = {}
	for i = 1, table.maxn(object_names) do
		CreateMethodsTable(object_names[i])
	end
	return ShowUserList()
end

------------------------------------------------------

-- Add user event handler OnChar
local old_OnChar = OnChar
function OnChar(char)
	local result
	if old_OnChar then result = old_OnChar(char) end
	if props['macro-recording'] ~= '1' and AutocompleteObject(char) then return true end
	return result
end

-- Add user event handler OnUserListSelection
local old_OnUserListSelection = OnUserListSelection
function OnUserListSelection(tp,sel_value)
	local result
	if old_OnUserListSelection then result = old_OnUserListSelection(tp,sel_value) end
	if tp == 7 then
		if InsertMethod(sel_value) then return true end
	end
	return result
end

-- Add user event handler OnSwitchFile
local old_OnSwitchFile = OnSwitchFile
function OnSwitchFile(file)
	local result
	if old_OnSwitchFile then result = old_OnSwitchFile(file) end
	get_api = true
	return result
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	get_api = true
	return result
end

-- Add user event handler OnBeforeSave
local old_OnBeforeSave = OnBeforeSave
function OnBeforeSave(file)
	local result
	if old_OnBeforeSave then result = old_OnBeforeSave(file) end
	get_api = true
	return result
end