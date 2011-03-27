--[[--------------------------------------------------
Open_Selected_Filename.lua
Authors: mozers™, VladVRO
Version: 1.5.1
------------------------------------------------------
Замена команды "Открыть выделенный файл"
В отличии от встроенной команды SciTE, понимающей только явно заданный путь и относительные пути
обрабатывает переменные SciTE, переменные окружения, конструкции LUA, неполные пути
Если файл не найден, то выводится предложение о его создании.
-------------------------------------
Подключение:
Добавьте в SciTEStartup.lua строку
dofile (props["SciteDefaultHome"].."\\tools\\Open_Selected_Filename.lua")
Параметром open.selected.filename.minlength можно задать минимальную длину выделенной строки, которая будет анализироваться как возможное имя файла.
По умолчанию open.selected.filename.minlength=4
-------------------------------------
Connection:
In file SciTEStartup.lua add a line:
dofile (props["SciteDefaultHome"].."\\tools\\Open_Selected_Filename.lua")
--]]--------------------------------------------------
require 'shell'
require 'gui'
------------------------------------------------------
local open_selected_filename_minlength = tonumber(props['open.selected.filename.minlength']) or 4

-- Ищет файл в текущем и дочерних каталогах
local function FindFileDown(filename)
	local findfile
	local function DIR(path)
		local files = gui.files(path..'\\'..filename)
		if files then
			for _, file in pairs(files) do
				if filename:find('\\') then file = filename:gsub('[^\\]*$','')..file end
				findfile = path..'\\'..file
				return
			end
		end
		local folders = gui.files(path..'\\*', true)
		if folders then
			for _, folder in pairs(folders) do
				DIR(path..'\\'..folder)
			end
		end
	end
	DIR(props['FileDir'])
	return findfile
end

-- Ищет файл в родительских каталогах
local function FindFileUp(filename)
	local path = props['FileDir']
	repeat
		path = path:gsub('\\[^\\]+$', '')
		filepath = path..'\\'..filename
		if shell.fileexists(filepath) then return filepath end
	until #path < 3
end

local function GetOpenFilePath(text)
	-- Example: $(SciteDefaultHome)\tools\RestoreRecent.js
	local pattern_sci = '^$[(](.-)[)]'
	local _, _, scite_var = string.find(text,pattern_sci)
	if scite_var then
		return string.gsub(text, pattern_sci, props[scite_var])
	end

	-- Example: %APPDATA%\Opera\Opera\profile\opera6.ini
	local pattern_env = '^[%%](.-)[%%]'
	local _, _, os_env = string.find(text, pattern_env)
	if os_env then
		return string.gsub(text, pattern_env, os.getenv(os_env))
	end

	-- Example: props["SciteDefaultHome"].."\\tools\\Zoom.lua"
	local pattern_props = '^props%[%p(.-)%p%]%.%.%p(.*)%p'
	local _, _, scite_prop1, scite_prop2 = string.find(text, pattern_props)
	if scite_prop1 then
		return props[scite_prop1]..scite_prop2
	end

	-- Example: ..LuaLib\re.lua
	local files = FindFileDown(text)
	if files then
		return files
	end

	-- Example: ..\languages\css.properties
	local filepath = FindFileUp(text)
	if filepath then
		return filepath
	end
end

local function GetSelText()
	local pane = editor.Focus and editor or output
	local text = pane:GetSelText()
	text = string.gsub(text, '/', '\\')
	return text:to_utf8(pane:codepage())
end

local function OpenSelectedFilename()
	local text = GetSelText()
	if #text < open_selected_filename_minlength then return end
	local filename = GetOpenFilePath(text)
	if not filename then
		local alert = scite.GetTranslation('File')..' "'..text..'" '..scite.GetTranslation('does not exist\nYou want to create a file with that name?')
		if shell.msgbox(alert, "New File", 4+256) == 6 then
			filename = props['FileDir']..'\\'..string.gsub(text, '\\\\', '\\')
			local warning_couldnotopenfile_disable = props['warning.couldnotopenfile.disable']
			props['warning.couldnotopenfile.disable'] = 1
			scite.Open(filename)
			props['warning.couldnotopenfile.disable'] = warning_couldnotopenfile_disable
		end
		return true
	end
	filename = string.gsub(filename, '\\\\', '\\')
	scite.Open (filename)
	return true
end

AddEventHandler("OnMenuCommand", function(msg, source)
	if msg == IDM_OPENSELECTED then
		return OpenSelectedFilename()
	end
end)
