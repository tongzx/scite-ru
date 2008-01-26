-- Code Poster 2
-- Version: 2.0
-- Author: mozers™  (Идея и первая реализация: VladVRO)
---------------------------------------------------
-- Description:
-- конвертирует выделенный текст или весь файл в форматированный текст форума,
-- в точном соответствии с заданными в редакторе стилями (color, bold, italics)

-- Для подключения добавьте в свой файл .properties следующие строки:
--  command.name.125.*=Преобразовать в код для форума
--  command.125.*=dofile $(SciteDefaultHome)\tools\code-poster2.lua
--  command.mode.125.*=subsystem:lua,savebefore:no

-- ремарки по использованию:
--  в скрипте используются функции editor.LexerLanguage и os.msgbox
--  (сборка Ru-Board, http://code.google.com/p/scite-ru)
---------------------------------------------------

local function GetStyleString(pos)
	local style = editor.StyleAt[pos]
	local lang = editor.LexerLanguage
	return props["style."..lang.."."..style]
end

local function GetColor(style_string)
	local fore
	for w in string.gmatch(style_string, "fore: *(#%x%x%x%x%x%x)") do
		fore = w
	end
	return fore
end

local function GetAttr(style_string, attr)
	if string.find(style_string, attr) then
		return true
	else
		return false
	end
end

-----------------------------------

local sel_start = editor.SelectionStart
local sel_end = editor.SelectionEnd
local line_start = editor:LineFromPosition(sel_start)+1
-- Если ничего не выделено, то берем весь текст
if sel_start == sel_end then
	line_start = 0
	sel_start = 0
	sel_end = editor:PositionFromLine(editor.LineCount)
end

local fore
local fore_old = nil
local italics
local italics_old = false
local bold
local bold_old = false
local forum_text =""
-----------------------------------
for i = sel_start, sel_end-1 do
	local char = editor:textrange(i,i+1)
	if char == "\t" then char = string.rep(" ", props["tabsize"]) end
	if not string.find(char,"%s") then
		local style_string = GetStyleString(i)
		--------------------------------------------
		italics = GetAttr(style_string, "italics")
		if italics ~= italics_old then
			if italics then
				forum_text = forum_text.."[i]"
			else
				forum_text = forum_text.."[/i]"
			end
			italics_old = italics
		end
		--------------------------------------------
		bold = GetAttr(style_string, "bold")
		if bold ~= bold_old then
			if bold then
				forum_text = forum_text.."[b]"
			else
				forum_text = forum_text.."[/b]"
			end
			bold_old = bold
		end
		--------------------------------------------
		fore = GetColor(style_string)
		if fore ~= fore_old and fore_old ~= nil then
			forum_text = forum_text.."[/color]"
		end
		if fore ~= fore_old and fore ~= nil then
			forum_text = forum_text.."[color="..fore.."]"
		end
		fore_old = fore
	end
	forum_text = forum_text..char
end
-----------------------------------
if fore ~= nil then
	forum_text = forum_text.."[/color]"
end
if italics then
	forum_text = forum_text.."[/i]"
end
if bold then
	forum_text = forum_text.."[/b]"
end
-----------------------------------

local header = "[b][color=Blue]"..props["FileNameExt"].."[/color][/b]"
if line_start ~= 0 then
	header = header.." [s][[b]строка "..line_start.."[/b]][/s]"
end
forum_text = header.." : [code]"..forum_text.."[/code]"
editor:CopyText(forum_text)
os.msgbox ("Код для форума успешно сформирован\n и помещен в буфер обмена", "Формирование кода для форума")