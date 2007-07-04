-- SciTE Smart comment
-- Version: 2.5
-- Autor: Dmitry Maslov
---------------------------------------------------
-- Веделяем текст нажимаем на клавиатуре символ 
-- с которого начинается комментарий и строка комментируется
-- пример: выделить строку в cpp, нажать на клавишу * или /
---------------------------------------------------
-- Версия 2.5
-- Добавлена совместимость автозакрытия скобок с всплывающей подсказкой
---------------------------------------------------
-- Версия 2.4
-- Поправлена обработка { в cpp
---------------------------------------------------
-- Версия 2.3
-- Скрипт сделан полностью автономным
---------------------------------------------------
-- Версия 2.2
-- Исправлен баг, если нажали не печатный символ
-- то скрипт вел себя не предсказуемо
---------------------------------------------------
-- Версия 2.1
-- Закрытие блочным комментирием во всех языках по первому 
-- символу блочного комментария во как загнул ;) 
-- Благодарность mozers за подсказку в реализации.
---------------------------------------------------
-- Версия 2.0
-- Автозакрытие скобок и текста в скобки
-- Работает, если braces.autoclose=1 
-- (параметр в файле SciTEGlobal.properties)
-- Особая обработка { и } в cpp
---------------------------------------------------
-- Версия 1.0
-- Обработка комментариев в cpp * и / (/**/ и //~ )
-- Обработка коментариев в lua - ( -- )
-- Обработка скобок в lua [ ( [[...]] )
-- Обработка комментария в props # ( #~ )
---------------------------------------------------

-- позиция это начало строки (учитывая отступ)
local function IsLineStartPos(pos)
	return (editor.LineIndentPosition[editor:LineFromPosition(pos)] == pos)
end

-- Получить номер текущей строки
local function GetCurrLineNumber()
	return editor:LineFromPosition(editor.CurrentPos);
end

-- Получить отступ в строке
local function GetLineIndentation(num_line)
	if num_line<0 then num_line=0 end
	if num_line>=editor.LineCount then num_line=editor.LineCount-1 end
	return editor.LineIndentation[num_line]/editor.Indent
end

-- Возвращает текущий символ перевода строки
local function GetEOL()
	local eol = "\r\n"
	if editor.EOLMode == SC_EOL_CR then
		eol = "\r"
	elseif editor.EOLMode == SC_EOL_LF then
		eol = "\n"
	end
	return eol
end

-- сделать текст шаблоном для поиска
-- (фактически экранирование служебных символов)
local function makefind(text)
	local strres=''
	local simbol
	for i=1, string.len(text), 1 do
		simbol = string.format('%c', string.byte(text,i))
		if ((simbol=="(")or(simbol=="[")or(simbol==".")or(simbol=="%")or
				(simbol=="*")or(simbol=="/")or(simbol=="-")or(simbol==")")or
					(simbol=="]")or(simbol=="?")or(simbol=="+")) then
			simbol=string.format("%%%s",simbol)
		end
		strres = strres..simbol
	end
	return strres
end

-- последний в строке ?
local function IsInLineEnd(num_line, text)
	local endpos = editor.LineEndPosition[num_line];
	if endpos>=string.len(text) and 
		string.find(editor:textrange(endpos-string.len(text), endpos), makefind(text)) then
		return true
	end
	return false
end

-- предыдущий символ позиции конец строки?
local function prevIsEOL(pos)
	if (string.find(editor:textrange(pos-string.len(GetEOL()), pos),GetEOL())) then
		return true
	end
	return false
end

-- следующий символ позиции конец строки?
local function nextIsEOL(pos)
	if (string.find(editor:textrange(pos, pos+string.len(GetEOL())),GetEOL())) then
		return true
	end
	return false
end

-- последний символ в строке - конец строки?
local function IsEOLlast(text)
	-- в луа конец строки всегда один символ
	if string.find(text,GetEOL(),string.len(text)-1) then
		return true
	end
	return false
end

local function StrimComment(commentbegin, commentend)
	local text, lenght = editor:GetSelText()
	local selbegin = editor.SelectionStart
	local selend = editor.SelectionEnd
	local b,e = string.find(text,makefind(commentbegin))
	if (e and (string.byte(text, e+1) == 10 or string.byte(text, e+1) == 13)) then 
		e=e+1 
	end
	if (e and (string.byte(text, e+1) == 10 or string.byte(text, e+1) == 13)) then 
		e=e+1 
	end
	local b2,e2
	if IsEOLlast(text) then
		b2,e2 = string.find(text,makefind(commentend), 
			string.len(text)-string.len(commentend)-string.len(GetEOL()))
	else
		b2,e2 = string.find(text,makefind(commentend), 
			string.len(text)-string.len(commentend))
	end
	if (b2 and (string.byte(text, b2-1) == 10 or string.byte(text, b2-1) == 13)) then 
		b2=b2-1 
	end
	if (b2 and (string.byte(text, b2-1) == 10 or string.byte(text, b2-1) == 13)) then 
		b2=b2-1 
	end
	editor:BeginUndoAction()
	if (b and b2) then
		local add=''
		if (string.find(text,GetEOL(),string.len(text)-string.len(GetEOL()))) then
			add = GetEOL()
		end
		text = string.sub(text,e+1,b2-1)
		editor:ReplaceSel(text..add)
		editor:SetSel(selbegin, selbegin+string.len(text..add))
	else
		if (editor:LineFromPosition(selend)==editor:LineFromPosition(selbegin)) then
			editor:insert(selend, commentend)
			editor:insert(selbegin, commentbegin)
			editor:SetSel(selbegin, selend+string.len(commentbegin)+string.len(commentend))
		else
			local eolcount = 0
			if (prevIsEOL(selend)) then
				editor:insert(selend, commentend..GetEOL())
				eolcount = eolcount + 1
			else
				editor:insert(selend, commentend)
			end
			if (prevIsEOL(selbegin)) then
				editor:insert(selbegin, commentbegin..GetEOL())
				eolcount = eolcount + 1
			else
				editor:insert(selbegin, commentbegin)
			end
			editor:SetSel(selbegin, selend+string.len(commentbegin)+string.len(commentend)+string.len(GetEOL())*eolcount)
		end
	end
	editor:EndUndoAction()
	return true
end

local function BlockComment()
	local selbegin = editor.SelectionStart
	editor:BeginUndoAction()
	if (string.find(editor:textrange(selbegin-string.len(GetEOL()), selbegin),GetEOL())) then
		scite.MenuCommand("IDM_BLOCK_COMMENT")
		editor:SetSel(selbegin, editor.SelectionEnd)
	else
		scite.MenuCommand("IDM_BLOCK_COMMENT")
		editor:SetSel(editor.SelectionStart, editor.SelectionEnd)
	end
	editor:EndUndoAction()
	return true
end

local function BlockBraces(bracebegin, braceend)
	local text, lenght = editor:GetSelText()
	local selbegin = editor.SelectionStart
	local selend = editor.SelectionEnd
	local b,e = string.find(text,makefind(bracebegin))
	local b2,e2
	local add=''
	if IsEOLlast(text) then
		b2,e2 = string.find(text,makefind(braceend), 
			string.len(text)-string.len(braceend..GetEOL()))
		add = GetEOL()
	else
		b2,e2 = string.find(text,makefind(braceend), 
			string.len(text)-string.len(braceend))
	end
	editor:BeginUndoAction()
	if (b and b2) then
		text = string.sub(text,e+1,b2-1)
		editor:ReplaceSel(text..add)
		editor:SetSel(selbegin, selbegin+string.len(text..add))
	else
		editor:insert(selend - string.len(add), braceend)
		editor:insert(selbegin, bracebegin)
		editor:SetSel(selbegin, selend+string.len(bracebegin..braceend))
	end
	editor:EndUndoAction()
	return true
end

local function GetIndexFindCharInProps(value, findchar)
	if findchar then
		local resIndex = string.find(props[value], makefind(findchar), 1)
		if (resIndex~=nil) and (string.sub(props[value],resIndex,resIndex) == findchar) then
			return resIndex
		end
	end
	return nil
end

local function GetCharInProps(value, index)
	return string.sub(props[value],index,index)
end

local function SmartComment(char)
	if (editor.SelectionStart~=editor.SelectionEnd) then
		-- делаем проверку на блочный комментарий
		if GetIndexFindCharInProps('comment.block.'..editor.LexerLanguage, char) == 1 then
			return BlockComment()
		end
		-- делаем индивидуальную обработку по лексерам
		if (editor.LexerLanguage == 'cpp') then
			if (char == '*' ) then return StrimComment('/*', '*/') end
		end
		if (editor.LexerLanguage == 'lua') then
			if (char == '[') then return BlockBraces('[[',']]') end
		end
		-- делаем обработку по автозакрытию текста скобками
		if (props['braces.autoclose']=='1') then
			local brIdx = GetIndexFindCharInProps('braces.open', char)
			if (brIdx~=nil) then
				local brClose = GetCharInProps('braces.close', brIdx)
				if (brClose~=nil) then
					return BlockBraces(char, brClose)
				end
			end
		end
	-- автозакрытие скобок
	elseif (props['braces.autoclose']=='1') then
		-- если следующий символ закрывающаяся скобка
		-- и мы ее вводим, то ввод проглатываем
		local nextSimbol = string.format("%c",editor.CharAt[editor.CurrentPos])
		local endBr = GetIndexFindCharInProps('braces.close',nextSimbol)
		if (endBr~=nil) and (nextSimbol==char) then 
			editor:CharRight()
			return true
		end
		-- если следующий символ конец строки
		-- и мы ставим открывающуюся скобку
		-- то сразу вставляем закрывающуюся скобку
		if (editor.CurrentPos==editor.Length) or nextIsEOL(editor.CurrentPos) then
			local brIdx = GetIndexFindCharInProps('braces.open', char)
			if (brIdx~=nil) then
				editor:BeginUndoAction()
				-- по волшебному обрабатываем скобку { в cpp
				if (char == '{') and (editor.LexerLanguage == 'cpp') then
					local ln = GetCurrLineNumber()
					if ln>0 and GetLineIndentation(ln)>GetLineIndentation(ln-1) then
						if IsLineStartPos(editor.CurrentPos) and not IsInLineEnd(ln-1, '{') then
							editor:BackTab()
						end
					end
					editor:AddText('{')
					editor:NewLine()
					if GetLineIndentation(ln)==GetLineIndentation(ln+1) then
						editor:Tab()
					end
					local pos = editor.CurrentPos
					editor:NewLine()
					if GetLineIndentation(ln+2)==GetLineIndentation(ln+1) then
						editor:BackTab()
					end
					editor:AddText('}')
					editor:GotoPos(pos)
					editor:EndUndoAction()
					return true
				-- по волшебному обрабатываем скобку } в cpp
				elseif (char == '}') and (editor.LexerLanguage == 'cpp') then
					editor:BackTab()
				-- вставляем закрывающуюся скобку
				else
					local symE = GetCharInProps('braces.close',brIdx)
					if (symE==nil) then symE='' end
					editor:InsertText(editor.CurrentPos, symE)
				end
				editor:EndUndoAction()
				return false
			end
		end
	end
	return false
end

-- Add user event handler OnKey
local old_OnKey = OnKey
function OnKey(key, shift, ctrl, alt, char)
	if old_OnKey and old_OnKey(key, shift, ctrl, alt, char) then
		return true
	end
	if editor.Focus and char~='' and SmartComment(char) then
		return true
	end
	return false
end
