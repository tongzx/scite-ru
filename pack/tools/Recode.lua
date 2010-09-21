--[[--------------------------------------------------
ScriptName.lua
Authors: mozers
Version: 2.0
------------------------------------------------------
Description: Преобразует кодировку открытого файла к указанной
Работоспособен в комплекте со скриптом CodePage.lua
------------------------------------------------------
Connection:
 Set in a file .properties:
	command.name.23.*=Convert to DOS-866
	command.23.*=dostring cp_out="cp866" dofile(props["SciteDefaultHome"].."\\tools\\Recode.lua")
	command.mode.23.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

require "iconv"

local function recode(cp_in, cp_out)
	function Convert(text_in, code_in, code_out)
		local cd = iconv.open(code_in, code_out)
		assert(cd, "Failed to create a converter object.")
		local text_out, err = cd:iconv(text_in)

		if err == iconv.ERROR_INCOMPLETE then
			print("ERROR: Incomplete input.")
		elseif err == iconv.ERROR_INVALID then
			print("ERROR: Invalid input.")
		elseif err == iconv.ERROR_NO_MEMORY then
			print("ERROR: Failed to allocate memory.")
		elseif err == iconv.ERROR_UNKNOWN then
			print("ERROR: There was an unknown error.")
		end
		return text_out
	end

	editor.TargetStart = 0
	editor.TargetEnd = editor.Length
	editor:ReplaceTarget(Convert(editor:GetText(), cp_in, cp_out))

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

local cp_in = props["cp.iconv"] -- set pros in CodePage.lua
if (cp_in ~= "?") and (cp_in ~= cp_out) then
	print(cp_in..' -> '..cp_out)
	recode(cp_in, cp_out)
end
