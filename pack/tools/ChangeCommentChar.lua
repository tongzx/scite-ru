--[[--------------------------------------------------
ChangeCommentChar.lua
Authors: VladVRO, mozers™
Version: 1.0.2
------------------------------------------------------
Подставляет адекватный символ комментария для файлов обрабатываемых лексером props
(*.properties;*.abbrev;*.session;*.ini;*.inf;*.reg;*.url;*.cfg;*.cnf;*.aut;*.m3u)
------------------------------------------------------
Connection:
 In file SciTEStartup.lua add a line:
    dofile (props["SciteDefaultHome"].."\\tools\\ChangeCommentChar.lua")
--]]--------------------------------------------------

local function ChangeCommentChar()
	function IsINI()
		local ini = {'ini', 'inf', 'reg'}
		local ext = props['FileExt']:lower()
		for _, x in pairs(ini) do
			if x == ext then return true end
		end
		return false
	end
	if editor:GetLexerLanguage() == 'props' then
		if IsINI() then
			props['comment.block.props']=';'
		else
			props['comment.block.props']='#'
		end
	end
end

-- Добавляем свой обработчик события OnSwitchFile
AddEventHandler("OnSwitchFile", ChangeCommentChar)

-- Добавляем свой обработчик события OnOpen
AddEventHandler("OnOpen", ChangeCommentChar)
