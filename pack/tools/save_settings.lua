--[[--------------------------------------------------
 Save SciTE Settings
 Version: 1.6
 Author: mozers™, Dmitry Maslov
---------------------------------------------------
 Save current settings on SciTE close.
 Сохраняет текущие установки при закрытии SciTE (в файле SciTE.session)
---------------------------------------------------
Connection:
In file SciTEStartup.lua add a line:
  dofile (props["SciteDefaultHome"].."\\tools\\save_settings.lua")
Set in a file .properties:
  save.settings=1
  import home\SciTE.session
--]]----------------------------------------------------

-- установить в text текущее значение проперти key
local function SaveKey(text, key)
	local value = props[key]
	local regex = '([^%w.]'..key..'=)%-?%d+'
	local find = string.find(text, regex)
	if find == nil then
		return text..'\n'..key..'='..value
	end
	return string.gsub(text, regex, "%1"..value)
end

function SaveSetting()
	local file = props["scite.userhome"]..'\\SciTE.session'
	io.input(file)
	local text = io.read('*a')
	text = SaveKey(text, 'toolbar.visible')
	text = SaveKey(text, 'tabbar.visible')
	text = SaveKey(text, 'statusbar.visible')
	text = SaveKey(text, 'view.whitespace')
	text = SaveKey(text, 'view.eol')
	text = SaveKey(text, 'view.indentation.guides')
	text = SaveKey(text, 'line.margin.visible')
	text = SaveKey(text, 'split.vertical')
	text = SaveKey(text, 'wrap')
	text = SaveKey(text, 'output.wrap')
	text = SaveKey(text, 'magnification') -- параметр изменяется в Zoom.lua
	text = SaveKey(text, 'output.magnification') -- параметр изменяется в Zoom.lua
	text = SaveKey(text, 'print.magnification') -- параметр изменяется в Zoom.lua
	text = SaveKey(text, 'sidebar.show') -- параметр изменяется в SideBar.lua
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
	elseif cmd == IDM_SPLITVERTICAL then
		props['split.vertical'] = fNOT(props['split.vertical'])
	elseif cmd == IDM_WRAP then
		props['wrap'] = fNOT(props['wrap'])
	elseif cmd == IDM_WRAPOUTPUT then
		props['output.wrap'] = fNOT(props['output.wrap'])
	end
	return result
end

-- Добавляем свой обработчик события OnFinalise
-- Сохранение настроек при закрытии SciTE
local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
	if props['FileName'] ~= '' then
		if tonumber(props['save.settings']) == 1 then
			SaveSetting()
		end
	end
	return result
end
