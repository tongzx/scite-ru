--[[--------------------------------------------------
 Rename.lua
 Version: 2.1
 Author: mozersЩ (иде€ codewarlock1101)
 ------------------------------------------------
 ѕереименовывает текущий файл
 ƒл€ подключени€ добавьте в свой файл .properties следующие строки: 
    command.name.31.*=Rename current file
    command.31.*=dofile $(SciteDefaultHome)\tools\rename.lua
    command.mode.31.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

local function CheckFilename(str, char)
	return not char:match('[\\/:|*?"<>]')
end

local filename = props["FileNameExt"]
local filename_new = props["FileNameExt"]
local title = scite.GetTranslation("File Rename")
local msg1 = scite.GetTranslation("Please enter new file name:")
local msg2 = scite.GetTranslation("The file with such name already exists!\nPlease enter different file name.")
repeat
	filename_new = shell.inputbox(title, msg1, filename_new, CheckFilename)
	if filename_new == nil then return end
	if #filename_new == 0 then return end
	if filename_new == filename then return end
	if not shell.fileexists(filename_new) then break end
	shell.msgbox(msg2, title)
until false

local file_dir = props["FileDir"]
filename_new = file_dir:gsub('\\','\\\\')..'\\\\'..filename_new
scite.Perform("saveas:"..filename_new)
os.remove(file_dir..'\\'..filename)
