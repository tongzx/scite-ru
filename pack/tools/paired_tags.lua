--[[--------------------------------------------------
Paired Tags (логическое продолжение скриптов highlighting_paired_tags.lua и HTMLFormatPainter.lua)
Version: 2.1
Author: mozers™, VladVRO
------------------------------
Подсветка парных и непарных тегов в HTML и XML
В файле настроек задается цвет подсветки парных и непарных тегов

Скрипт позволяет копировать и удалять (текущие подсвеченные) теги, а также
вставлять в нужное место ранее скопированные (обрамляя тегами выделенный текст)

Внимание:
В скрипте используются функции из COMMON.lua (EditorMarkText, EditorClearMarks)

------------------------------
Подключение:
Добавить в SciTEStartup.lua строку:
	dofile (props["SciteDefaultHome"].."\\tools\\paired_tags.lua")
Добавить в файл настроек параметр:
	hypertext.highlighting.paired.tags=1
Дополнительно можно задать стили используемых маркеров (1 и 2):
	find.mark.1=#0099FF
	find.mark.2=#FF0000 (если этот параметр не задан, то непарные теги не подсвечиваются)

Команды копирования, вставки, удаления тегов добавляются в меню Tools обычным порядком:
	tagfiles=$(file.patterns.html);$(file.patterns.xml)

	command.name.5.$(tagfiles)=Copy Tags
	command.5.$(tagfiles)=CopyTags
	command.mode.5.$(tagfiles)=subsystem:lua,savebefore:no
	command.shortcut.5.$(tagfiles)=Alt+C

	command.name.6.$(tagfiles)=Paste Tags
	command.6.$(tagfiles)=PasteTags
	command.mode.6.$(tagfiles)=subsystem:lua,savebefore:no
	command.shortcut.6.$(tagfiles)=Alt+P

	command.name.7.$(tagfiles)=Delete Tags
	command.7.$(tagfiles)=DeleteTags
	command.mode.7.$(tagfiles)=subsystem:lua,savebefore:no
	command.shortcut.7.$(tagfiles)=Alt+D

Для быстрого включения/отключения подсветки можно добавить команду:
	command.checked.8.$(tagfiles)=$(hypertext.highlighting.paired.tags)
	command.name.8.$(tagfiles)=Highlighting Paired Tags
	command.8.$(tagfiles)=highlighting_paired_tags_switch
	command.mode.8.$(tagfiles)=subsystem:lua,savebefore:no
--]]----------------------------------------------------

local tags = {}
local old_current_pos

function CopyTags()
	local tag = editor:textrange(tags.tag_start, tags.tag_end+1)
	if tags.paired_start~=nil then
		local paired = editor:textrange(tags.paired_start, tags.paired_end+1)
		if tags.tag_start < tags.paired_start then
			tags.begin = tag
			tags.finish = paired
		else
			tags.begin = paired
			tags.finish = tag
		end
	else
		tags.begin = tag
		tags.finish = nil
	end
end

function PasteTags()
	if tags.begin~=nil then
		if tags.finish~=nil then
			local sel_text = editor:GetSelText()
			editor:ReplaceSel(tags.begin..sel_text..tags.finish)
			if sel_text == '' then
				editor:GotoPos(editor.CurrentPos-#tags.finish)
			end
		else
			editor:ReplaceSel(tags.begin)
		end
	end
end

function DeleteTags()
	if tags.tag_start~=nil then
		editor:BeginUndoAction()
		if tags.paired_start~=nil then
			if tags.tag_start < tags.paired_start then
				editor:SetSel(tags.paired_start, tags.paired_end+1)
				editor:DeleteBack()
				editor:SetSel(tags.tag_start, tags.tag_end+1)
				editor:DeleteBack()
			else
				editor:SetSel(tags.tag_start, tags.tag_end+1)
				editor:DeleteBack()
				editor:SetSel(tags.paired_start, tags.paired_end+1)
				editor:DeleteBack()
			end
		else
			editor:SetSel(tags.tag_start, tags.tag_end+1)
			editor:DeleteBack()
		end
		editor:EndUndoAction()
	end
end

function highlighting_paired_tags_switch()
	local prop_name = 'hypertext.highlighting.paired.tags'
	props[prop_name] = 1 - tonumber(props[prop_name])
	EditorClearMarks(1)
	EditorClearMarks(2)
end

local function PairedTagsFinder()
	local current_pos = editor.CurrentPos
	if current_pos == old_current_pos then return end
	old_current_pos = current_pos
	local find_flags = SCFIND_REGEXP
	local tag_start = editor:findtext("[<>]", find_flags, current_pos, 0)
	local tag_end = editor:findtext("[<>]", find_flags, current_pos, editor.Length)
	local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
	EditorClearMarks(1)
	EditorClearMarks(2)
	tags.tag_start = nil
	tags.tag_end = nil
	tags.paired_start = nil
	tags.paired_end = nil
	if tag_start ~= nil and tag_end ~= nil then
		if editor.CharAt[tag_start] == 60 and editor.CharAt[tag_end] == 62 and editor.StyleAt[tag_start+1] == 1 then
			local tag_paired_start, tag_paired_end, dec, find_end
			if editor.CharAt[tag_start+1] == 47 then
				dec = -1
				find_end = 0
			else
				dec = 1
				find_end = editor.Length
			end
			EditorMarkText(tag_start+1, tag_end-tag_start-1, 1) -- Start tag to paint in Blue
			tags.tag_start = tag_start
			tags.tag_end = tag_end

			-- Find paired tag
			local tag = editor:textrange(editor:findtext("\\w+", find_flags, tag_start, tag_end))
			local find_start = tag_start+dec
			local count = 1
			repeat
				tag_paired_start, tag_paired_end = editor:findtext("</*"..tag.."[^>]*", find_flags, find_start, find_end)
				if tag_paired_start == nil then break end
				if editor.CharAt[tag_paired_start+1] == 47 then
					count = count - dec
				else
					count = count + dec
				end
				if count == 0 then break end
				find_start = tag_paired_start + dec
			until false

			if tag_paired_start ~= nil then
				-- Paired tag to paint in Blue
				EditorMarkText(tag_paired_start+1, tag_paired_end-tag_paired_start-1, 1)
				tags.paired_start = tag_paired_start
				tags.paired_end = tag_paired_end
			else
				EditorClearMarks(1)
				EditorClearMarks(2)
				if props["find.mark.2"] ~= '' then
					EditorMarkText(tag_start+1, tag_end-tag_start-1, 2) -- Start tag to paint in Red
				end
			end
		end
	end
	scite.SendEditor(SCI_SETINDICATORCURRENT, current_mark_number)
end

-- Add user event handler OnUpdateUI
local old_OnUpdateUI = OnUpdateUI
function OnUpdateUI ()
	local result
	if old_OnUpdateUI then result = old_OnUpdateUI() end
	if props['FileName'] ~= '' then
		if tonumber(props["hypertext.highlighting.paired.tags"]) == 1 then
			if editor.LexerLanguage == "hypertext" or editor.LexerLanguage == "xml" then
				PairedTagsFinder()
			end
		end
	end
	return result
end
