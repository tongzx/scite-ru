-- Этот файл стартует при загрузке SciTE
-- Чтобы не забивать его его огромным количеством используемых скриптов, поскольку это затрудняет работу редактора, большинство из них хранятся в обособленных файлах и грузятся только при выборе соответствующего пункта меню Tools.
-- Здесь (с помощью dofile) грузятся только скрипты, обрабатывающие события редактора.
----------------------------------------------------------------------------
-- Подключение файла с общими функциями, использующимися во многих скриптах
dofile (props["SciteDefaultHome"].."\\tools\\COMMON.lua")

-- Поддержка записи и воспроизведения макросов
dofile (props["SciteDefaultHome"].."\\tools\\macro_support.lua")

-- Автоматическое сворачивание всех секций при открытии файлов заданного типа
dofile (props["SciteDefaultHome"].."\\tools\\ToggleFoldAll.lua")

-- Включает HTML подсветку для файлов без расширения, открываемых из меню "просмотр HTML-кода" Internet Explorer
dofile (props["SciteDefaultHome"].."\\tools\\set_html.lua")

-- Автозакрытие скобок
--~ dofile (props["SciteDefaultHome"].."\\tools\\braces_autoclose.lua")

-- Автоматическое создание резервных копий редактируемых файлов
dofile (props["SciteDefaultHome"].."\\tools\\auto_backup.lua")

-- Установка / снятие закладок на строку (Bookmark) (то же что и Ctrl+F2)
-- с помощью двойного клика мыши при нажатой клавише Ctrl
dofile (props["SciteDefaultHome"].."\\tools\\MarkerToggle.lua")

-- Показ имени текущего лексера в статусной строке
dofile (props["SciteDefaultHome"].."\\tools\\lexer_name.lua")

-- Замена стандартной команды "Read-Only"
-- Красит фон закладки не доступной для редактирования и показывает сотояние в статусной строке
dofile (props["SciteDefaultHome"].."\\tools\\ReadOnly.lua")

-- Замена стандартной команды SciTE "Открыть выделенный файл"
dofile (props["SciteDefaultHome"].."\\tools\\Open_Selected_Filename.lua")

-- Смена кодировки Win1251/DOS866
dofile (props["SciteDefaultHome"].."\\tools\\win2dos.lua")

-- Индикация текущей кодировки в строке состояния
dofile (props["SciteDefaultHome"].."\\tools\\codepage.lua")

-- При открытии ReadOnly, Hidden, System файлов включает режим ReadOnly в SciTE
dofile (props["SciteDefaultHome"].."\\tools\\ROCheck.lua")

-- Поддержка сохранения RO файлов
dofile (props["SciteDefaultHome"].."\\tools\\ROWrite.lua")

-- Автозакрытие HTML тегов
dofile (props["SciteDefaultHome"].."\\tools\\html_tags_autoclose.lua")

-- Смена текущих шрифтов (Ctrl+F11)
dofile (props["SciteDefaultHome"].."\\tools\\FontChanger.lua")

-- Вставка спецсимволов (©,®,§,±,…) из раскрывающегося списка (для HTML вставляются их обозначения)
dofile (props["SciteDefaultHome"].."\\tools\\InsertSpecialChar.lua")

-- SciTE_HexEdit: A Self-Contained Primitive Hex Editor for SciTE
dofile (props["SciteDefaultHome"].."\\tools\\HexEdit\\SciTEHexEdit.lua")

-- SciTE Calculator
dofile (props["SciteDefaultHome"].."\\tools\\Calculator\\SciTECalculatorPD.lua")

-- Автодополнение объектов их методами и свойствами
dofile (props["SciteDefaultHome"].."\\tools\\AutocompleteObject.lua")

-- Показ модифицированного диалога сохранения текущей сессиии при закрытии SciTE
-- (если в SciTEGlobal.properties установлены параметры session.manager=1 и save.session.manager.on.quit=1)
dofile (props["SciteDefaultHome"].."\\tools\\SessionManager\\SessionManager.lua")

-- При изменении текущего размера шрифта, масштабируется и выводимый на принтер шрифт и показатель в строке состояния
dofile (props["SciteDefaultHome"].."\\tools\\Zoom.lua")

-- Быстрое комментирование выделенного кода, автозакрытие скобок
dofile (props["SciteDefaultHome"].."\\tools\\smartcomment.lua")

-- При вводе слова, если это сокращение то вызывается список аббревиатур
--~ dofile (props["SciteDefaultHome"].."\\tools\\abbrevlist.lua")

-- Сохранение параметров настройки SciTE, измененных через меню
dofile (props["SciteDefaultHome"].."\\tools\\save_settings.lua")

-- Создает в контекстном меню таба (закладки) подменю для команд SVN
--~ dofile (props["SciteDefaultHome"].."\\tools\\svn_menu.lua")

-- Установка размера символа табуляции в окне консоли
local tab_width = tonumber(props['output.tabsize'])
if tab_width ~= nil then
	scite.SendOutput(SCI_SETTABWIDTH, tab_width)
end
