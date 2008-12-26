-- OpenFindFiles.lua
-- Version: 1.2
-- Author: mozers™
---------------------------------------------------
-- После выполнения команды "Найти в файлах..."
-- создает пункт в контекстном меню консоли - "Открыть найденные файлы"
-- Подключение:
-- В файл SciTEStartup.lua добавьте строку:
--   dofile (props["SciteDefaultHome"].."\\tools\\OpenFindFiles.lua")
---------------------------------------------------
local user_outputcontext_menu = props["user.outputcontext.menu.*"] -- исходное контекстное меню консоли
local clear_before_execute = props["clear.before.execute"]         -- исходное значение параметра clear.before.execute
local outputcontextmenu_changed = false -- признак модификации контекстного меню
local command_num                       -- номер команды "OpenFindFiles" в меню Tools

--------------------------------------------------
-- Поиск незанятого пункта меню Tools
local function GetFreeCommandNumber()
	local IDM_TOOLS = 9000
	for i = 20, 299 do
		if props["command."..i..".*"] == "" then return IDM_TOOLS+i end
	end
end

--------------------------------------------------
-- Создание команды в меню Tools и вставка ее в контекстное меню консоли
local function CreateMenu()
	command_num = GetFreeCommandNumber()
	props["command."..command_num..".*"] = "OpenFindFiles"
	props["command.mode."..command_num..".*"] = "subsystem:lua,savebefore:no"

	local command_name = scite.GetTranslation("Open Find Files")
	props["user.outputcontext.menu.*"] = command_name.."|"..command_num.."|||"..user_outputcontext_menu

	outputcontextmenu_changed = true
	props["clear.before.execute"] = 0
end

--------------------------------------------------
-- Удаление команды из меню Tools и восстановление исходного контекстного меню консоли
local function RemoveMenu()
	props["clear.before.execute"] = clear_before_execute
	props["user.outputcontext.menu.*"] = user_outputcontext_menu
	props["command."..command_num..".*"] = ""
	outputcontextmenu_changed = false
end

--------------------------------------------------
-- Открытие файлов, перечисленных в консоли
function OpenFindFiles()
	local output_text = editor:GetText()
	local str = output_text:match('"(.-)"')
	local filename_prev = ''
	for filename in output_text:gmatch('([^\r\n]+):%d+:') do
		if filename ~= filename_prev then
			scite.Open(filename)
			editor:GotoPos(editor:findtext(str))
			filename_prev = filename
		end
	end
	RemoveMenu()
end

--------------------------------------------------
-- Add user event handler OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	if msg == IDM_FINDINFILES then
		CreateMenu()
	elseif outputcontextmenu_changed and msg ~= command_num then
		RemoveMenu()
	end
	return result
end
