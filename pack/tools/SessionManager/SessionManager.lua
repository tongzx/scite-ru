-- SessionManager
-- Автор: mozers™
-- Version: 0.97
-----------------------------------------------
local function LoadSession()
	shell.exec('mshta "'..props['SciteDefaultHome']..'\\tools\\SessionManager\\SessionManager.hta"', nil, true, false)
end

local function SaveSession()
	shell.exec('mshta "'..props['SciteDefaultHome']..'\\tools\\SessionManager\\SessionManager.hta" '..props['FileName'], nil, true, false)
end

local function SaveSessionOnQuit()
	props['save.session']=1
	shell.exec('mshta "'..props['SciteDefaultHome']..'\\tools\\SessionManager\\SessionManager.hta" '..'QUIT '..props['FileName'], nil, true, false)
end

-- ==============================================================
-- Функция копирования os_copy2(source_path,dest_path)
-- Автор z00n <http://www.lua.ru/forum/posts/list/15/89.page>
--// "библиотечная" функция
local function unwind_protect(thunk,cleanup)
	local ok,res = pcall(thunk)
	if cleanup then cleanup() end
	if not ok then error(res,0) else return res end
end

--// общая функция для работы с открытыми файлами
local function with_open_file(name,mode)
	return function(body)
	local f = assert(io.open(name,mode))
	return unwind_protect(function()return body(f) end,
		function()return f and f:close() end)
	end
end

--// собственно os-copy --
local function os_copy(source_path,dest_path)
	return with_open_file(source_path,"rb") (function(source)
		return with_open_file(dest_path,"wb") (function(dest)
			assert(dest:write(assert(source:read("*a"))))
			return true
		end)
	end)
end
-- ==============================================================

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
	os_copy (session_file, path)
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
