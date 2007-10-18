-- Zoom.lua
-- Version: 1.1
-- Author: Дмитрий Маслов
---------------------------------------------------
-- Обработка стандартной команды Zoom
-- Вместе с отображаемыми шрифтами, масштабируется и выводимый на принтер шрифт
-- Изменяет значение пользовательской переменной font.current.size, используемой для отображения текщего размера шрифта в строке состояния
---------------------------------------------------
-- Для подключения добавьте в файл .properties:
--   statusbar.text.1=$(font.current.size)px
-- в файл SciTEStartup.lua:
--   dofile (props["SciteDefaultHome"].."\\tools\\Zoom.lua")
---------------------------------------------------

local function ChangeFontSize(zoom)
	props["magnification"] = zoom
	props["print.magnification"] = zoom
	props["output.magnification"] = zoom -- правильней было бы менять по SCI_SETZOOM в окне консоли, но как отловить это событие?
	local _, _, font_current_size = string.find(props["style.*.32"], "size:(%d+)")
	props["font.current.size"] = font_current_size + zoom -- Used in statusbar
	scite.UpdateStatusBar()
end

-- Добавляем свой обработчик события OnSendEditor
local old_OnSendEditor = OnSendEditor
function OnSendEditor(id_msg, wp, lp)
	local result
	if old_OnSendEditor then result = old_OnSendEditor(id_msg, wp, lp) end
	if id_msg == SCI_SETZOOM then
		if ChangeFontSize(lp) then return true end
	end
	return result
end