--[[--------------------------------------------------
Highlighting Paired Tags
Version: 1.0
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
2. Так и не придумал как заставить искать editor:findtext со всеми 4мя параметрами, но в прямом направлении (поэтому пришлось влепить 2 строки с editor:findtext вместо одной)
3. Процедуры для маркировки текста очевидно надо перебросить в COMMON.lua

Я был бы очень благодарен, если бы мне кто то помог разрешить первые 2 вопроса (3й проблем не вызывает :)
--]]----------------------------------------------------

local old_current_pos, current_pos

local function ClearMarks()
	scite.SendEditor(SCI_INDICATORCLEARRANGE, 0, editor.Length)
end

local function MarkText(start, length, color)
	scite.SendEditor(SCI_SETINDICATORCURRENT, color)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
end

local function MarkTags()
	ClearMarks()
	current_pos = editor.CurrentPos
	local style = editor.StyleAt[current_pos]
	local tag_start = editor:WordStartPosition(current_pos, true)
	local tag_end = editor:WordEndPosition(current_pos, true)
	local tag = editor:textrange(tag_start, tag_end)
	local tag_length = tag_end - tag_start
	local count = 1
	if (style == 1) and (tag_length > 0) then
		MarkText(tag_start, tag_length, 1)
		local tag_paired_start, tag_paired_end, dec
		if editor.CharAt[tag_start-1] == 47 then
			dec = -1 else dec = 1
		end

		-- Find paired tag
		local find_flags = SCFIND_WHOLEWORD and SCFIND_REGEXP
		local find_start = tag_start
		repeat
			if dec == 1 then
				tag_paired_start,tag_paired_end = editor:findtext("</*"..tag,find_flags,find_start)
			else
				tag_paired_start,tag_paired_end = editor:findtext("</*"..tag,find_flags,find_start,-1)
			end
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
			MarkText(tag_paired_start+((3+dec)/2), tag_paired_end-tag_paired_start-((3+dec)/2), 1)
		else
			ClearMarks()
			MarkText(tag_start, tag_length, 2)
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
				if MarkTags() then return true end
			end
		end
	end
	return result
end

local function InitMarkStyle()
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
	if InitMarkStyle() then return true end
	return result
end
