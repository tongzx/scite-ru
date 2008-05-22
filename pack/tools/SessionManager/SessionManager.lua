-- SessionManager
-- Автор: mozers™
-- Version: 0.95
-----------------------------------------------
local function LoadSession()
	shell.run('mshta "'..props['SciteDefaultHome']..'\\tools\\SessionManager\\SessionManager.hta"',1,false)
end

local function SaveSession()
	shell.run('mshta "'..props['SciteDefaultHome']..'\\tools\\SessionManager\\SessionManager.hta" '..props['FileName'],1,false)
end

local function SaveSessionOnQuit()
	props['save.session']=1
	shell.run('mshta "'..props['SciteDefaultHome']..'\\tools\\SessionManager\\SessionManager.hta" '..'QUIT '..props['FileName'],1,false)
end

local function FileExist(path)
	if (os.rename (path,path)) then
		return true
	else
		return false
	end
end

local function SaveSessionOnQuitAuto()
	local path = ""
	local i = 0
	repeat
		local filename = props['FileName']..'_'..string.sub('0'..i, -2)
		filename = string.gsub(filename,' ','_')
		path = props['scite.userhome']..'\\'..filename..'.session'
		i = i + 1
	until not FileExist(path)
	local session_file = props['scite.userhome']..'\\SciTE.session'
	shell.run('CMD /C copy /y "'..session_file..'" "'..path..'"', 0, true)
end

-- Добавляем свой обработчик события OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	if tonumber(props['session.manager'])==1 then
		if msg == IDM_SAVESESSION then
			SaveSession()
			return true
		elseif msg == IDM_LOADSESSION then
			LoadSession()
			return true
		end
	end
	return result
end

-- Добавляем свой обработчик события OnFinalise
-- Сохранение текущей сессиии при закрытии SciTE
local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
	if props['FileName'] ~= '' then
		if tonumber(props['session.manager'])==1 then
			if tonumber(props['save.session.manager.on.quit'])==1 then
				if tonumber(props['save.session.on.quit.auto'])==1 then
					SaveSessionOnQuitAuto()
				else
					SaveSessionOnQuit()
				end
				return false
			end
		end
	end
	return result
end
