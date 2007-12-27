-- OpenFindFiles.lua
-- Version: 1.0
-- Author: mozers™
---------------------------------------------------
-- После выполнения команды "Найти в файлах..."
-- создает пункт в контекстном меню консоли - "Открыть найденные файлы"
-- Подключение:
-- В файл SciTEStartup.lua добавьте строку:
--   dofile (props["SciteDefaultHome"].."\\tools\\OpenFindFiles.lua")
---------------------------------------------------
local command_name = "Открыть найденные файлы"
-- local command_name = "Оpen Find Files"
local user_outputcontext_menu = props["user.outputcontext.menu"]
local clear_before_execute = props["clear.before.execute"]
local command_num = 0

--------------------------------------------------
-- Открытие файлов, перечисленных в консоли
function OpenFindFiles()
	output_text = output:GetText()
	local _, e, str = string.find (output_text, '"(.-)"')
	local _, e, path = string.find (output_text, '"([^\r\n]+)\\', e+1)
	local filename_old = ""
	repeat
		e = e + 1
		local _, e, filename = string.find (output_text, '%.(\\.-):%d+:', e)
		if filename ~= nil then
			if filename ~= filename_old then
				local path_filename = string.gsub(path..filename,'\\','\\\\')
				local cmd = '"'..props["SciteDefaultHome"]..'\\scite.exe" -check.if.already.open=1 "-open:'..path_filename..'" "-find:'..str..'"'
				os.run (cmd)
				filename_old = filename 
			end
		end
	until e == nil
	-- Восстанавливаем исходные значения всех измененных параметров
	props["clear.before.execute"] = clear_before_execute
	props["user.outputcontext.menu"] = user_outputcontext_menu
	props["command."..command_num..".*"] = ""
end

--------------------------------------------------
-- Поиск незанятого пункта меню Tools
local function command_number()
	for i = 20, 299 do
		if props["command."..i..".*"] == "" then return i end
	end
end

--------------------------------------------------
-- Создание команды в меню Tools и вставка ее в контекстное меню консоли
local function CreateMenu()
	command_num = command_number()
	props["command."..command_num..".*"] = "OpenFindFiles"
	props["command.mode."..command_num..".*"] = "subsystem:lua,savebefore:no"
	props["user.outputcontext.menu"] = command_name.."|"..(9000+command_num).."|||"..user_outputcontext_menu
end

--------------------------------------------------
local function MenuCommand(msg)
	if msg == IDM_FINDINFILES then
		props["clear.before.execute"] = 0
		CreateMenu()
	end
end

--------------------------------------------------
-- Add user event handler OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	MenuCommand(msg)
	return result
end
