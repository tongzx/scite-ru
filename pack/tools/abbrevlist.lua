--[[--------------------------------------------------
abbrevlist.lua
Authors: Dmitry Maslov, frs, mozers™, Tymur Gubayev
version 3.4.2
------------------------------------------------------
  Если при вставке расшифровки аббревиатуры (Ctrl+B) не нашлось точного соответствия,
  то выводится список соответствий начинающихся с этой комбинации символов.
  Возможен автоматический режим работы (появление списка без нажатия на Ctrl+B).
  Он включается параметром abbrev.lexer.auto=3,
        где lexer - имя соответствующего лексера,
              а 3 - min длина введенной строки при которой она будет анализироваться как аббревиатура

  Если в расшифровке аббревиатуры задано несколько курсорных меток, то после вставки расшифровки курсор устанавливается на первую из них.
  На все остальные устанавливаются невидимые метки, переход по которым осуществляется клавишей Tab.
  При установке параметра abbrev.multitab.clear.manual=1 скрипт не очищает метки табуляторов после перемещения на них по Tab. Их пользователь удаляет вручную комбинацией Ctrl+Tab.
  Параметр abbrev.multitab.indic.style=#FF6600,diagonal позволяет показывать метки табуляторов заданным стилем (значения задаются так же как в параметрах indic.style.number)
  Установка параметра abbrev.lexer.ignore.comment=1 разрешает скрипту игнорировать символ комментария в файлах аббревиатур для указанных лексеров (т.е. все закомментированные строки будут восприниматься как обычные аббревиатуры с начальным символом #)
  Параметром abbrev.list.width можно задать максимальную ширину раскрывающегося списка расшифровок аббревиатур (в символах)

  Предупреждение:
  Встроенные функции SciTE (Ctrl+B, Ctrl+Shift+R), которые заменяет скрипт, работают совершенно иначе!
  Поэтому файлы сокращений от оригинального SciTE подлежат внимательному пересмотру.

  Подключение:
    В файл SciTEStartup.lua добавьте строку:
    dofile (props["SciteDefaultHome"].."\\tools\\abbrevlist.lua")
------------------------------------------------------
History:
2.1 (mozers)
	* при вводе символов ? * возникал список всех имеющихся расшифровок
	* теперь при показе списка скрипт игнорирует регистр введенной аббревиатуры
	* исправлено регулярное выражение для идентификации аббревиатуры (т.к. символы пробела и # недопустимы только в ее начале)
	* параметр abbrev.lexer.auto теперь задает min длину введенной строки при котором она будет анализироваться как аббревиатура
3.2 (Tymur, mozers)
	+ добавлена возможность обходить заданные в аббревиатуре места по TAB (Issue 240)
	+ добавлено несколько дополнительных опций
3.3 (mozers)
	* благодаря доработке r1610 (автор:Neo) исправлена ошибка со вставкой "некорректных" (для UserList) аббревиатур
3.4 (mozers, Tymur)
	* аббревиатурой считается текст от пробельного символа или открывающей скобки(т.е. `(`,`[` или `{`) и до начала выделения (или до каретки).
	- поправлен баг с удалением лишних символов слева от начала аббревиатуры.
	+ добавлена новая настройка `abbrev.list.width` для указания максимальной ширины раскрывающегося списка расшифровок аббревиатур.
--]]--------------------------------------------------

local table_abbr_exp = {}     -- полный список аббревиатур и расшифровок к ним
local table_user_list = {}    -- список подходящих к текущему тексту аббревиатур и расшифровок к ним
local get_abbrev = true       -- признак того, что этот список надо пересоздать
local chars_count_min = 0     -- min длина введенной строки при которой она будет анализироваться
local sep = '•'               -- разделитель для строки раскрывающегося списка
local typeUserList = 11       -- идентификатор раскрывающегося списка
local smart_tab = 0           -- кол-во дополнительных позиций табуляции (невидимых маркеров)
local cr = string.char(1)     -- символ для временной подмены метки курсора |
local clearmanual = tonumber(props['abbrev.multitab.clear.manual']) == 1
local abbrev_length = 0       -- длина аббревиатуры

-- Возвращает номер свободного маркера и присваивает ему атрибут "невидимый"
local function SetHiddenMarker()
	for indic_number = 0, 31 do
		local mark = props["indic.style."..indic_number]
		if mark == "" then
			local indic_style = props["abbrev.multitab.indic.style"]
			if indic_style == '' then
				props["indic.style."..indic_number] = "hidden"
			else
				props["indic.style."..indic_number] = indic_style
			end
			return indic_number
		end
	end
end
local num_hidden_indic = SetHiddenMarker()   -- номер маркера позиций курсора (для обхода по TAB)

-- Чтение всех подключенных abbrev-файлов в таблицу table_abbr_exp
local function CreateExpansionList()
	-- Чтение одного из abbrev-файлов
	local function ReadAbbrevFile(file)
		local abbrev_file = io.open(file)
		if abbrev_file then
			local ignorecomment = tonumber(props['abbrev.'..props['Language']..'.ignore.comment'])==1
			for line in abbrev_file:lines() do
				if line ~= '' and (ignorecomment or line:sub(1,1) ~= '#' ) then
					local _abr, _exp = line:match('^(.-)=(.+)')
					if _abr then
						table_abbr_exp[#table_abbr_exp+1] = {_abr:upper(), _exp}
					else
						local import_file = line:match('^import%s+(.+)')
						-- если обнаружена запись import то рекурсивно вызываем эту же функцию
						if import_file then
							ReadAbbrevFile(file:match('.+\\')..import_file)
						end
					end
				end
			end
			abbrev_file:close()
		end
	end

	table_abbr_exp = {}
	local abbrev_filename = props["AbbrevPath"]
	if abbrev_filename == '' then return end
	ReadAbbrevFile(abbrev_filename)
end

-- Вставка расшифровки, из раскрывающегося списка
local function InsertExpansion(expansion, abbrev_length)
	if not abbrev_length then abbrev_length = 0 end
	editor:BeginUndoAction()
	-- удаление введенной аббревиатуры с сохранением выделения
	local sel_start, sel_end = editor.SelectionStart - abbrev_length, editor.SelectionEnd - abbrev_length
	if abbrev_length > 0 then
		editor:remove(sel_start, editor.SelectionStart)
		editor:SetSel(sel_start, sel_end)
		abbrev_length = 0
	end
	-- вставка расшифровки c заменой всех меток курсора | (кроме первой) на символ cr
	expansion = expansion:gsub("|", cr):gsub(cr..cr, "|"):gsub(cr, "|", 1)
	local _, tab_count = expansion:gsub(cr, cr) -- определяем кол-во дополнительных меток курсора
	local before_length = editor.Length
	scite.InsertAbbreviation(expansion)
	--------------------------------------------------
	if tab_count>0 then -- если есть дополнительные метки курсора
		local start_pos = editor.CurrentPos
		local end_pos = sel_end + editor.Length - before_length
		if clearmanual then
			EditorMarkText(start_pos-1, 1, num_hidden_indic)
		else
			EditorClearMarks(num_hidden_indic) -- если от предыдущей вставки остались маркеры (пользователь заполнил не все поля) то удаляем их
		end

		repeat -- убираем символы # из расшифровки, ставя вместо них невидимые маркеры
			local tab_start = editor:findtext(cr, 0, end_pos, start_pos)
			if not tab_start then break end
			editor:GotoPos(tab_start+1)  editor:DeleteBack()
			EditorMarkText(tab_start-1, 1, num_hidden_indic)
			end_pos = tab_start-1
		until false

		editor:GotoPos(start_pos)
		smart_tab = tab_count -- разрешаем особую обработку нажатия на TAB (по событию OnKey)
	end
	--------------------------------------------------
	editor:EndUndoAction()
end
-- export global
scite_InsertAbbreviation = InsertExpansion

-- Показ списка из расшифровок, соответствующих введенной аббревиатуре
local function ShowExpansionList(event_IDM_ABBREV)
	local sel_start = editor.SelectionStart
	local line_start_pos = editor:PositionFromLine(editor:LineFromPosition(sel_start))
	-- ищем начало сокращения - первый пробельный символ
	local abbrev_start = editor:findtext('[\\s\\(\\[\\{\\<]', SCFIND_REGEXP, sel_start, line_start_pos)
	abbrev_start = abbrev_start and abbrev_start+1 or line_start_pos
	-- в html нарушаем общие правила и включаем в аббревиатуру ведущий символ-разделитель < или (
	-- (не думаю что подобную практику стоит распостранять на другие языки)
	if props['Language'] == 'hypertext' then
		local prev_char = editor:textrange(abbrev_start-1, abbrev_start)
		if prev_char == '(' or prev_char == '<' then abbrev_start = abbrev_start - 1 end
	end
	local abbrev = editor:textrange(abbrev_start, sel_start)
	abbrev_length = #abbrev
	if abbrev_length == 0 then return event_IDM_ABBREV end
	-- если длина вероятной аббревиатуры меньше заданного кол-ва символов то выходим
	if not event_IDM_ABBREV and abbrev_length < chars_count_min then return true end

	-- если мы переключились на другой файл, то строим таблицу table_abbr_exp заново
	if get_abbrev then
		CreateExpansionList()
		get_abbrev = false
	end

	if #table_abbr_exp == 0 then return event_IDM_ABBREV end
	abbrev = abbrev:upper()
	table_user_list = {}
	 -- выбираем из table_abbr_exp только записи соответствующие этой аббревиатуре
	for i = 1, #table_abbr_exp do
		if table_abbr_exp[i][1]:find(abbrev, 1, true) == 1 then
			table_user_list[#table_user_list+1] = {table_abbr_exp[i][1], table_abbr_exp[i][2]}
		end
	end
	if #table_user_list == 0 then return event_IDM_ABBREV end
	-- если мы используем Ctrl+B (а не автоматическое срабатывание)
	if (event_IDM_ABBREV)
		-- и если найден единственный вариант расшифровки
		and (#table_user_list == 1)
		-- и аббревиатура полностью соотвествует введенной
		and (abbrev == table_user_list[1][1])
			-- то вставку производим немедленно
			then
				InsertExpansion(table_user_list[1][2], abbrev_length)
				return true
	end

	-- показываем раскрывающийся список из расшифровок, соответствующих введенной аббревиатуре
	local tmp = {}
	local list_width = tonumber(props['abbrev.list.width']) or -1
	for i = 1, #table_user_list do
		tmp[#tmp+1] = table_user_list[i][2]:sub(1, list_width)
	end
	local table_user_list_string = table.concat(tmp, sep):gsub('%?', ' ')
	local sep_tmp = editor.AutoCSeparator
	editor.AutoCSeparator = string.byte(sep)
	editor:UserListShow(typeUserList, table_user_list_string)
	editor.AutoCSeparator = sep_tmp
	return true
end

------------------------------------------------------
AddEventHandler("OnMenuCommand", function(msg)
	if msg == IDM_ABBREV then
		return ShowExpansionList(true)
	end
end)

AddEventHandler("OnChar", function()
	chars_count_min = tonumber(props['abbrev.'..props['Language']..'.auto']) or tonumber(props['abbrev.*.auto']) or 0
	if chars_count_min ~= 0 then
		return ShowExpansionList(false)
	end
end)

AddEventHandler("OnKey", function(key, shift, ctrl, alt)
	if editor.Focus and smart_tab > 0 and key == 9 then -- TAB=9
		if not (shift or ctrl or alt) then
			for i = editor.CurrentPos, editor.Length do
				if editor:IndicatorValueAt(num_hidden_indic, i)==1 then
					editor:GotoPos(i+1)
					if not clearmanual then
						EditorClearMarks(num_hidden_indic, i, 1) -- после перехода на позицию заданную маркером, этот маркер удаляем
						smart_tab = smart_tab - 1
					end
					return true
				end
			end
		elseif ctrl and not (shift or alt) then
			EditorClearMarks(num_hidden_indic)
			smart_tab = 0
			return true
		end
	end
end)

AddEventHandler("OnUserListSelection", function(tp, sel_value, sel_item_id)
	if tp == typeUserList then
		InsertExpansion(table_user_list[sel_item_id][2], abbrev_length)
	end
end)

AddEventHandler("OnSwitchFile", function()
	get_abbrev = true
end)

AddEventHandler("OnOpen", function()
	get_abbrev = true
end)
