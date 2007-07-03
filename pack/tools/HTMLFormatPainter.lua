-- "Формат по образцу" для HTML
-- Т.е. сначала выделяем текст уже оформленный необходимыми тегами и выбираем "Запомнить теги".
-- Затем, выделяем неоформленный текст и используем "Оформить в этих тегах" какое угодно количество раз
-- mozers™
-----------------------------------------------------------------------

local function GetTags(sText)
	if string.len(sText) > 0 then
		local Tags = string.gsub(sText, ">.-<", "><")
		props["startTags"] = string.gsub(Tags, "</.->", "")
		props["endTags"] = string.gsub(Tags, "<[^/].->", "")
--~ 		print(props["startTags"].." | "..props["endTags"])
	end
end

local function InsertTags(sText)
	if (sText ~= '') then
		editor:ReplaceSel(props["startTags"]..sText..props["endTags"])
	end
end

local sText = props['CurrentSelection']
if f=="get" then GetTags(sText) end
if f=="ins" then InsertTags(sText) end
