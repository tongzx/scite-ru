-- Обработка стандартной команды Zoom
-- Вместе с отображаемыми шрифтами, масштабируется и выводимый на принтер шрифт
-- Изменяет значение пользовательской переменной font.current.size, используемой для отображения текщего размера шрифта в строке состояния
-- Автор: Дмитрий Маслов
-------------------------------------------------------------------------
-- Для подключения добавьте в файл .properties:
--   statusbar.text.1=$(font.current.size)px
-- в файл SciTEStartup.lua:
--   dofile (props["SciteDefaultHome"].."\\tools\\Zoom.lua")
-------------------------------------------------------------------------

function ChangeFontSize(zoom)
	props["print.magnification"] = zoom
	props["font.current.size"] = editor.StyleSize[STYLE_DEFAULT] + zoom -- Used in statusbar
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