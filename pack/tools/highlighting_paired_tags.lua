--[[--------------------------------------------------
Highlighting Paired Tags
Version: 1.4
Author: mozers™, VladVRO
------------------------------
Подсветка парных тегов в HTML и XML
В файле настроек задается цвет подсветки парных и непарных тегов
------------------------------
Подключение:
Добавить в SciTEStartup.lua строку:
  dofile (props["SciteDefaultHome"].."\\tools\\highlighting_paired_tags.lua")
Добавить в файл настроек параметр:
  hypertext.highlighting.paired.tags=1
Дополнительно можно задать в файле настроек:
  style.marker.pairtags=<цвет> (где <цвет> например #0099FF, по умолчанию #0000FF)
  style.marker.unpairedtag=<цвет> (если не задан, то непарные теги не подсвечиваются)
------------------------------
Код нуждается в доработке:
1. editor:findtext("<\(/*\)"... ничего не находит :( Почему ??? (Поэтому пришлось дополнительно анализировать найденную строку)
2. Процедуры для маркировки текста очевидно надо перебросить в COMMON.lua

Я был бы очень благодарен, если бы кто то смог разрешить первый вопрос (2й проблем не вызывает :)
--]]----------------------------------------------------

------[[ T E X T   M A R K S ]]-------------------------
-- Translate color from RGB to win
local function encodeRGB(color)
	if string.sub(color,1,1)=="#" and string.len(color)>6 then
		return tonumber(string.sub(color,6,7)..string.sub(color,4,5)..string.sub(color,2,3), 16)
	else
		return color
	end
end

local function MarkText(start, length, style_number)
	scite.SendEditor(SCI_SETINDICATORCURRENT, style_number)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
end

local function ClearMarks()
	scite.SendEditor(SCI_INDICATORCLEARRANGE, 0, editor.Length)
end

local color1, color2

local function InitMarkStyles()
	color1 = props['style.marker.pairtags']
	if color1 == '' then color1 = '#0000FF' end
	editor.IndicStyle[1] = INDIC_ROUNDBOX
	editor.IndicFore[1] = encodeRGB(color1)
	color2 = props['style.marker.unpairedtag']
	if color2 ~= '' then
		editor.IndicStyle[2] = INDIC_ROUNDBOX
		editor.IndicFore[2] = encodeRGB(color2)
	end
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	if InitMarkStyles() then return true end
	return result
end

-- Add user event handler OnSwitchFile
local old_OnSwitchFile = OnSwitchFile
function OnSwitchFile(file)
	local result
	if old_OnSwitchFile then result = old_OnSwitchFile(file) end
	if InitMarkStyles() then return true end
	return result
end

------[[ F I N D   P A I R E D   T A G S ]]-------------

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
	ClearMarks()
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
			MarkText(tag_start-dt, tag_length+dt, 1) -- Start tag to paint in Blue

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
				MarkText(tag_paired_start+1, tag_paired_end-tag_paired_start-1, 1)
			else
				ClearMarks()
				if color2 ~= '' then
					MarkText(tag_start-dt, tag_length+dt, 2) -- Start tag to paint in Red
				end
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
		if editor.LexerLanguage == "hypertext" or editor.LexerLanguage == "xml" then
			if PairedTagsFinder() then return true end
		end
	end
	return result
end
