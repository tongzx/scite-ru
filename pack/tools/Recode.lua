--[[--------------------------------------------------
ScriptName.lua
Authors: mozers
Version: 2.1.0
------------------------------------------------------
Description: Преобразует кодировку открытого файла к указанной
Работоспособен только в комплекте со скриптом CodePage.lua
------------------------------------------------------
Connection:
 Set in a file .properties:
	command.name.23.*=Convert to DOS-866
	command.23.*=dostring cp_out="cp866" dofile(props["SciteDefaultHome"].."\\tools\\Recode.lua")
	command.mode.23.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

require "iconv"
require "shell"

local function iConvert(text_in, code_in, code_out)
	local cd = iconv.open(code_in, code_out)
	assert(cd, "Error iconv: Failed to create a converter object!")
	local text_out, err = cd:iconv(text_in)

	if err == iconv.ERROR_INCOMPLETE then
		print("Error iconv: Incomplete input!")
		return
	elseif err == iconv.ERROR_INVALID then
		print("Error iconv: Invalid input!")
		return
	elseif err == iconv.ERROR_NO_MEMORY then
		print("Error iconv: Failed to allocate memory!")
		return
	elseif err == iconv.ERROR_UNKNOWN then
		print("Error iconv: There was an unknown error!")
		return
	end
	return text_out
end

local function recode(cp_in, cp_out)
	editor.TargetStart = 0
	editor.TargetEnd = editor.Length
	local txt_in = editor:GetText()
	local txt_out
	if cp_in=="windows-1251" and cp_out=="utf-8" then
		txt_out = shell.to_utf8(txt_in)
	elseif cp_in=="utf-8" and cp_out=="windows-1251" then
		txt_out = shell.from_utf8(txt_in)
	else
		txt_out = iConvert(txt_in, cp_in, cp_out)
	end
	if txt_out == nil then return end
	editor:ReplaceTarget(txt_out)

	if cp_out=="utf-8" then
		scite.MenuCommand(IDM_ENCODING_UCOOKIE)
		return
	end
	if (cp_in=="cp866") or (cp_out=="cp866") then
		change_codepage_ru() -- public function of CodePage.lua
		return
	end
	if cp_out=="windows-1251" then
		scite.MenuCommand(IDM_ENCODING_DEFAULT)
		return
	end
end

local cp_in = props["cp.iconv"] -- значение cp.iconv задается скриптом CodePage.lua
if (cp_in ~= "?") and (cp_in ~= cp_out) then
	-- print(cp_in..' -> '..cp_out)
	recode(cp_in, cp_out)
end
