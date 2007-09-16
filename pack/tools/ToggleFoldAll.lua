-- Скрипт для автоматического сворачивания всех секций при открытии файлов заданного типа
-- Подключение:
--   Добавьте в SciTEStartup.lua строку
--     dofile (props["SciteDefaultHome"].."\\tools\\ToggleFoldAll.lua")
--   Задайте расширеня файлов в файле .properties
--     fold.on.open.ext=properties,ini
-- mozers™
-----------------------------------------------
local function CheckExt()
	local toggle_foldall_ext = string.upper(props['fold.on.open.ext'])
	local file_ext = '('..string.upper(props['FileExt'])..')'
	if string.find(toggle_foldall_ext, file_ext) ~= nil then
		props["fold.on.open"]=1
	else
		props["fold.on.open"]=0
	end
end

-- Добавляем свой обработчик события OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	if CheckExt() then return true end
	return result
end
