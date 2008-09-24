--[[-------------------------------------------------
ToggleFoldAll.lua
Version: 1.4
Author: mozers™
-----------------------------------------------------
Скрипт для автоматического сворачивания всех секций при открытии файлов заданного типа
Подключение:
  Добавьте в SciTEStartup.lua строку
    dofile (props["SciteDefaultHome"].."\\tools\\ToggleFoldAll.lua")
  Задайте расширеня файлов в файле .properties
    fold.on.open.ext=properties,ini
--]]-------------------------------------------------

local function CheckSession()
	local filename = props['FilePath']
	for i = 1, props['buffers'] do
		local path = props['buffer.'..i..'.path']
		if path == '' then return true end
		if path == filename then return false end
	end
	return true
end

local function CheckExt()
	local toggle_foldall_ext = string.upper(props['fold.on.open.ext'])
	local file_ext = string.upper(props['FileExt'])
	if string.find(toggle_foldall_ext, file_ext) ~= nil then
		return true
	end
	return false
end

local function ToggleFoldAll()
	if CheckSession() and CheckExt() then
		scite.MenuCommand (IDM_TOGGLE_FOLDALL)
	end
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	if ToggleFoldAll() then return true end
	return result
end
