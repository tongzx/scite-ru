--[[--------------------------------------------------
new_file.lua
mozers™, VladVRO
version 3.1.3
----------------------------------------------
Заменяет стандартную команду SciTE "File|New" (Ctrl+N)
Создает новый буфер в текущем каталоге с расширением текущего файла
Благодаря этому, сразу же включаются все фичи лексера (подсветка, подсказки и пр.)
----------------------------------------------
Подключение:
В файл SciTEStartup.lua добавьте строку:
  dofile (props["SciteDefaultHome"].."\\tools\\new_file.lua")
----------------------------------------------
Replaces SciTE command "File|New" (Ctrl+N)
Creates new buffer in the current folder with current file extension
----------------------------------------------
Connection:
In file SciTEStartup.lua add a line:
  dofile (props["SciteDefaultHome"].."\\tools\\new_file.lua")
--]]----------------------------------------------------
require 'shell'

props["untitled.file.number"] = 0
local unsaved_files = {}

-- Создает новый буфер в текущем каталоге с расширением текущего файла
local function CreateUntitledFile()
	local file_ext = "."..props["FileExt"]
	if file_ext == "." then file_ext = props["default.file.ext"] end
	repeat
		local file_path = props["FileDir"].."\\Untitled"..props["untitled.file.number"]..file_ext
		props["untitled.file.number"] = tonumber(props["untitled.file.number"]) + 1
		if not shell.fileexists(file_path) then
			local warning_couldnotopenfile_disable = props['warning.couldnotopenfile.disable']
			props['warning.couldnotopenfile.disable'] = 1
			scite.Open(file_path)
			unsaved_files[file_path:upper()] = true --сохраняем путь к созданному буферу в таблице
			props['warning.couldnotopenfile.disable'] = warning_couldnotopenfile_disable
			return true
		end
	until false
end
AddEventHandler("OnMenuCommand", function(msg, source)
	if msg == IDM_NEW then
		return CreateUntitledFile()
	elseif msg == IDM_SAVEAS then
		unsaved_files[props["FilePath"]:upper()] = nil --удаляем запись о буфере из таблицы
	end
end)

-- Новый буфер, созданный функцией CreateUntitledFile имеет полное имя, поэтому при сохранении SciTE будет сохранять его молча по заданному пути (без вывода диалогового окна "SaveAs")
-- Обработчик события OnBeforeSave при сохранении такого буфера выводит диалоговое окно "SaveAs"
AddEventHandler("OnBeforeSave", function(file)
	if unsaved_files[file:upper()] then -- если это созданный нами несохраненный буфер
		scite.MenuCommand(IDM_SAVEAS)
		return true
	end
end)
