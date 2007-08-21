-- Изменение номера выделенных параметров меню Tools
-- version: 1.1
-- author: VladVRO

-- Подключение:
-- В файл *.properties добавьте строки:
--    command.name.111.*.properties=Move menu item Up
--    command.111.*.properties=dostring delta=-1 dofile(props["SciteDefaultHome"].."\\tools\\MoveMenuItem.lua")
--    command.mode.111.*.properties=subsystem:lua,savebefore:no
--    command.shortcut.111.*.properties=Alt+Shift+Up

--    command.name.112.*.properties=Move menu item Down
--    command.112.*.properties=dostring delta=1 dofile(props["SciteDefaultHome"].."\\tools\\MoveMenuItem.lua")
--    command.mode.112.*.properties=subsystem:lua,savebefore:no
--    command.shortcut.112.*.properties=Alt+Shift+Down
---------------------------------------------

local new = ""
local text = editor:GetSelText().."\n"
for str in string.gfind(text, "([^\n]*)\n") do
	str = string.gsub(str, "%.(%d+)", function (s) return "."..tonumber(s)+delta end, 1)
	if new ~= "" then new = new.."\n" end
	new = new..str
end
local ss = editor.SelectionStart
editor:ReplaceSel(new)
editor:SetSel(ss, ss+string.len(new))
