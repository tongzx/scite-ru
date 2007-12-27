-- Save SciTE Settings
-- Version: 1.4
-- Author: mozers™, Dmitry Maslov
---------------------------------------------------
-- Сохраняет текущие установки SciTE
-- Подключение:
--   Добавьте в SciTEStartup.lua строку
--     dofile (props["SciteDefaultHome"].."\\tools\\save_settings.lua")
--   Для сохранения настроек через меню:
--     command.name.196.*=Save Current Settings
--     command.196.*=SaveSetting()
--     command.mode.196.*=subsystem:lua,savebefore:no
--     command.shortcut.196.*=Ctrl+Alt+S
--   При установке position.autosave=1 скрипт автоматически сохраняет заданные настройки при закрытии SciTE через меню или по щорткату.
---------------------------------------------------

-- установить в text текущее значение проперти key
local function SaveKey(text, key)
	local value = props[key]
	local regex = '([^%w.]'..key..'=)%d+'
	local find = string.find(text, regex)
	if find == nil then
		return text..'\n'..key..'='..value
	end
	return string.gsub(text, regex, "%1"..value)
end

function SaveSetting()
	local file = props["save.settings.path"]
	io.input(file)
	local text = io.read('*a')
	text = SaveKey(text, 'toolbar.visible')
	text = SaveKey(text, 'tabbar.visible')
	text = SaveKey(text, 'statusbar.visible')
	text = SaveKey(text, 'view.whitespace')
	text = SaveKey(text, 'view.eol')
	text = SaveKey(text, 'view.indentation.guides')
	text = SaveKey(text, 'line.margin.visible')
	text = SaveKey(text, 'check.if.already.open')
	text = SaveKey(text, 'split.vertical')
	text = SaveKey(text, 'wrap')
	text = SaveKey(text, 'output.wrap')
	text = SaveKey(text, 'magnification') -- параметр изменяется в Zoom.lua
	text = SaveKey(text, 'output.magnification') -- параметр изменяется в Zoom.lua
	text = SaveKey(text, 'print.magnification') -- параметр изменяется в Zoom.lua
	io.output(file)
	io.write(text)
	io.close()
end

local function fNOT (val)
	if val=='0' then
		return '1'
	elseif val=='1' then
		return '0'
	end
end

-- Добавляем свой обработчик события OnMenuCommand
-- При изменении параметров через меню, меняются и соответствующие значения props[]
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand(cmd, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(cmd, source) end
	if cmd == IDM_VIEWTOOLBAR then
		props['toolbar.visible'] = fNOT(props['toolbar.visible'])
	elseif cmd == IDM_VIEWTABBAR then
		props['tabbar.visible'] = fNOT(props['tabbar.visible'])
	elseif cmd == IDM_VIEWSTATUSBAR then
		props['statusbar.visible'] = fNOT(props['statusbar.visible'])
	elseif cmd == IDM_VIEWSPACE then
		props['view.whitespace'] = fNOT(props['view.whitespace'])
	elseif cmd == IDM_VIEWEOL then
		props['view.eol'] = fNOT(props['view.eol'])
	elseif cmd == IDM_VIEWGUIDES then
		props['view.indentation.guides'] = fNOT(props['view.indentation.guides'])
	elseif cmd == IDM_LINENUMBERMARGIN then
		props['line.margin.visible'] = fNOT(props['line.margin.visible'])
	elseif cmd == IDM_OPENFILESHERE then
		props['check.if.already.open'] = fNOT(props['check.if.already.open'])
	elseif cmd == IDM_SPLITVERTICAL then
		props['split.vertical'] = fNOT(props['split.vertical'])
	elseif cmd == IDM_WRAP then
		props['wrap'] = fNOT(props['wrap'])
	elseif cmd == IDM_WRAPOUTPUT then
		props['output.wrap'] = fNOT(props['output.wrap'])
	end
	return result
end

-- Добавляем свой обработчик события OnMenuCommand
-- Сохранение настроек при закрытии SciTE
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	if props['save.settings.path']~=nil then
		if msg == IDM_QUIT then
			SaveSetting()
		end
	end
	return result
end
