-- Показ текущей кодировки в статусной строке
-- author: VladVRO

-- Подключение:
-- В файл SciTEStartup.lua добавьте строку:
--   dofile ("codepage.lua")
-- включите code.page.name в статусную строку:
--   statusbar.text.1= [$(code.page.name)]
---------------------------------------------

local function UpdateCodePage(codepage)
	if codepage == SC_CP_UTF8 then
		props["code.page.name"]='UTF-8 ?'
	else
		if props["character.set"]=='255' then
			props["code.page.name"]='DOS-866'
		else
			props["code.page.name"]='WIN-1251'
		end
	end
	scite.UpdateStatusBar()
end

-- Добавляем свой обработчик события OnSwitchFile
local old_OnSwitchFile = OnSwitchFile
function OnSwitchFile(file)
	local result
	if old_OnSwitchFile then result = old_OnSwitchFile(file) end
	UpdateCodePage(editor.CodePage)
	return result
end

-- Добавляем свой обработчик события OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	UpdateCodePage(editor.CodePage)
	return result
end

-- Добавляем свой обработчик события OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand(cmd, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(cmd, source) end
	if cmd == 150 then -- IDM_ENCODING_DEFAULT
		UpdateCodePage(tonumber(props["code.page"]))
	elseif cmd == 151 then -- IDM_ENCODING_UCS2BE
		props["code.page.name"]='UCS-2 BE'
		scite.UpdateStatusBar()
	elseif cmd == 152 then -- IDM_ENCODING_UCS2LE
		props["code.page.name"]='UCS-2 LE'
		scite.UpdateStatusBar()
	elseif cmd == 153 then -- IDM_ENCODING_UTF8
		props["code.page.name"]='UTF-8 BOM'
		scite.UpdateStatusBar()
	elseif cmd == 154 then -- IDM_ENCODING_UCOOKIE
		props["code.page.name"]='UTF-8'
		scite.UpdateStatusBar()
	end
	return result
end
