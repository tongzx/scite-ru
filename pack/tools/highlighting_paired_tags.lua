--[[--------------------------------------------------
Highlighting Paired Tags
Version: 1.7.1
Author: mozers™, VladVRO
------------------------------
Подсветка парных и непарных тегов в HTML и XML
В файле настроек задается цвет подсветки парных и непарных тегов
Внимание:
В скрипте используются функции из COMMON.lua (EditorMarkText, EditorClearMarks)
------------------------------
Подключение:
Добавить в SciTEStartup.lua строку:
  dofile (props["SciteDefaultHome"].."\\tools\\highlighting_paired_tags.lua")
Добавить в файл настроек параметр:
  hypertext.highlighting.paired.tags=1
Дополнительно можно задать в файле стили используемых маркеров (1 и 2):
  find.mark.1=#0099FF
  find.mark.2=#FF0000 (если этот параметр не задан, то непарные теги не подсвечиваются)
--]]----------------------------------------------------

local old_current_pos

local function PairedTagsFinder()
	local current_pos = editor.CurrentPos
	if current_pos == old_current_pos then return end
	old_current_pos = current_pos
	if editor.CharAt[current_pos] == 47 then
		current_pos = current_pos + 1
	end
	local tag_start = editor:WordStartPosition(current_pos, true)
	local tag_end = editor:WordEndPosition(current_pos, true)
	local tag_length = tag_end - tag_start
	local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
	EditorClearMarks(1)
	EditorClearMarks(2)
	if tag_length > 0 then
		if editor.StyleAt[tag_start] == 1 then
			local tag_paired_start, tag_paired_end, dec, find_end, dt
			if editor.CharAt[tag_start-1] == 47 then
				dec = -1
				find_end = 0
				dt = 1
			else
				dec = 1
				find_end = editor.Length
				dt = 0
			end
			EditorMarkText(tag_start-dt, tag_length+dt, 1) -- Start tag to paint in Blue

			-- Find paired tag
			local tag = editor:textrange(tag_start, tag_end)
			local find_flags = SCFIND_WHOLEWORD and SCFIND_REGEXP
			local find_start = tag_start
			local count = 1
			repeat
				tag_paired_start, tag_paired_end = editor:findtext("</*"..tag.."[ >]", find_flags, find_start, find_end)
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
				EditorMarkText(tag_paired_start+1, tag_paired_end-tag_paired_start-2, 1)
			else
				EditorClearMarks(1)
				EditorClearMarks(2)
				if props["find.mark.2"] ~= '' then
					EditorMarkText(tag_start-dt, tag_length+dt, 2) -- Start tag to paint in Red
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
	if tonumber(props["hypertext.highlighting.paired.tags"]) == 1 then
		if editor.LexerLanguage == "hypertext" or editor.LexerLanguage == "xml" then
			PairedTagsFinder()
		end
	end
	return result
end
