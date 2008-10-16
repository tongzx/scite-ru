--[[--------------------------------------------------
 Rename.lua
 Version: 2.0.1
 Author: mozersЩ (иде€ codewarlock1101)
 ------------------------------------------------
 ѕереименовывает текущий файл
 ƒл€ подключени€ добавьте в свой файл .properties следующие строки: 
    command.name.31.*=Rename current file
    command.31.*=dofile $(SciteDefaultHome)\tools\rename.lua
    command.mode.31.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

function CheckFilename(char)
	return not char:match('[\\/:|*?"<>]')
end

local filename = props["FileNameExt"]
local filename_new = shell.inputbox("Rename", "Enter new file name:", filename, "CheckFilename")
if filename_new == nil then return end
if filename_new.len ~= 0 and filename_new ~= filename then
	local file_dir = props["FileDir"]
	filename_new = file_dir:gsub('\\','\\\\')..'\\\\'..filename_new
	scite.Perform("saveas:"..filename_new)
	os.remove(file_dir..'\\'..filename)
end
