--[[--------------------------------------------------
Highlighting Paired Tags
Version: 1.2
Author: mozers™
------------------------------
Подсветка парных тегов в HTML
Если пара находится, то подсвечивается синим выделением, если нет - красным
------------------------------
Подключение:
Добавить в SciTEStartup.lua строку:
  dofile (props["SciteDefaultHome"].."\\tools\\highlighting_paired_tags.lua")
Добавить в файл настроек параметр:
  hypertext.highlighting.paired.tags=1
------------------------------
Код нуждается в доработке:
1. editor:findtext("<\(/*\)"... ничего не находит :( Почему ??? (Поэтому пришлось дополнительно анализировать найденную строку)
2. Так и не разобрался до конца как задать произвольный цвет для маркеров (существующую процедуру подглядел у Moon_aka_Sun)
3. Процедуры для маркировки текста очевидно надо перебросить в COMMON.lua

Я был бы очень благодарен, если бы кто то смог разрешить первые 2 вопроса (3й проблем не вызывает :)
--]]----------------------------------------------------

------[[ T E X T   M A R K S ]]-------------------------

local function MarkText(start, length, style_number)
	scite.SendEditor(SCI_SETINDICATORCURRENT, style_number)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
end

local function ClearMarks()
	scite.SendEditor(SCI_INDICATORCLEARRANGE, 0, editor.Length)
end

local function InitMarkStyles()
	editor.IndicStyle[0] = INDIC_ROUNDBOX
	editor.IndicStyle[1] = INDIC_ROUNDBOX
	editor.IndicStyle[2] = INDIC_ROUNDBOX
	editor.IndicFore[0] = 255*257   -- YELLOW
	editor.IndicFore[1] = 255*65536 -- BLUE
	editor.IndicFore[2] = 255       -- RED
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	if InitMarkStyles() then return true end
	return result
end

------[[ F I N D   P A I R E D   T A G S ]]-------------

local current_pos, old_current_pos

local function PairedTagsFinder()
	ClearMarks()
	local tag_start = editor:WordStartPosition(current_pos, true)
	local tag_end = editor:WordEndPosition(current_pos, true)
	local tag_length = tag_end - tag_start
	if tag_length > 0 then
		if editor.StyleAt[tag_start] == 1 then
			MarkText(tag_start, tag_length, 1) -- Start tag to paint in Blue
			local tag_paired_start, tag_paired_end, dec, find_end
			if editor.CharAt[tag_start-1] == 47 then
				dec = -1
				find_end = 0
			else
				dec = 1
				find_end = editor.Length
			end

			-- Find paired tag
			local tag = editor:textrange(tag_start, tag_end)
			local find_flags = SCFIND_WHOLEWORD and SCFIND_REGEXP
			local find_start = tag_start
			local count = 1
			repeat
				tag_paired_start, tag_paired_end = editor:findtext("</*"..tag, find_flags, find_start, find_end)
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
				MarkText(tag_paired_start+((3+dec)/2), tag_paired_end-tag_paired_start-((3+dec)/2), 1)
			else
				ClearMarks()
				MarkText(tag_start, tag_length, 2) -- Start tag to paint in Red
			end
		end
	end
	old_current_pos = current_pos
end

-- Add user event handler OnUpdateUI
local old_OnUpdateUI = OnUpdateUI
function OnUpdateUI ()
	local result
	if old_OnUpdateUI then result = old_OnUpdateUI() end
	if tonumber(props["hypertext.highlighting.paired.tags"]) == 1 then
		if editor.LexerLanguage == "hypertext" then
			current_pos = editor.CurrentPos
			if current_pos ~= old_current_pos then
				if PairedTagsFinder() then return true end
			end
		end
	end
	return result
end
