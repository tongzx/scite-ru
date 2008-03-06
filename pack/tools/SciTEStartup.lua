-- Этот файл стартует при загрузке SciTE
-- Чтобы не забивать его его огромным количеством используемых скриптов, поскольку это затрудняет работу редактора, большинство из них хранятся в обособленных файлах и грузятся только при выборе соответствующего пункта меню Tools.
-- Здесь (с помощью dofile) грузятся только скрипты, обрабатывающие события редактора.

----[[ C O M M O N ]]-------------------------------------------------------

-- Подключение файла с общими функциями, использующимися во многих скриптах
dofile (props["SciteDefaultHome"].."\\tools\\COMMON.lua")

-- Поддержка записи и воспроизведения макросов
dofile (props["SciteDefaultHome"].."\\tools\\macro_support.lua")

----[[ К О Д И Р О В К А ]]-------------------------------------------------

-- Автоматическое переключение кодировки в UTF-8
dofile (props["SciteDefaultHome"].."\\tools\\UTF8_check.lua")

-- Смена кодировки Win1251/DOS866
dofile (props["SciteDefaultHome"].."\\tools\\win2dos.lua")

----[[ С Т А Т У С Н А Я   С Т Р О К А ]]-----------------------------------

-- Индикация текущей кодировки в строке состояния
dofile (props["SciteDefaultHome"].."\\tools\\codepage.lua")

-- Показ имени текущего лексера в статусной строке
dofile (props["SciteDefaultHome"].."\\tools\\lexer_name.lua")

----[[ Ш Р И Ф Т Ы ]]-------------------------------------------------------

-- Смена текущих шрифтов (Ctrl+F11)
-- dofile (props["SciteDefaultHome"].."\\tools\\FontChanger.lua")

-- При изменении текущего размера шрифта (Ctrl+-), масштабируется и выводимый на принтер шрифт и показатель в строке состояния
dofile (props["SciteDefaultHome"].."\\tools\\Zoom.lua")

----[[ С О Х Р А Н Е Н И Е ]]--------------------------------------------------

-- Сохранение параметров настройки SciTE, измененных через меню
dofile (props["SciteDefaultHome"].."\\tools\\save_settings.lua")

-- Автоматическое создание резервных копий редактируемых файлов
dofile (props["SciteDefaultHome"].."\\tools\\auto_backup.lua")

-- Показ модифицированного диалога сохранения текущей сессиии при закрытии SciTE
-- (если в SciTEGlobal.properties установлены параметры session.manager=1 и save.session.manager.on.quit=1)
dofile (props["SciteDefaultHome"].."\\tools\\SessionManager\\SessionManager.lua")

----[[ R E A D   O N L Y ]]-------------------------------------------------

-- Замена стандартной команды "Read-Only"
-- Красит фон закладки не доступной для редактирования и показывает сотояние в статусной строке
dofile (props["SciteDefaultHome"].."\\tools\\ReadOnly.lua")

-- При открытии ReadOnly, Hidden, System файлов включает режим ReadOnly в SciTE
dofile (props["SciteDefaultHome"].."\\tools\\ROCheck.lua")

-- Поддержка сохранения RO файлов
dofile (props["SciteDefaultHome"].."\\tools\\ROWrite.lua")

----[[ С К О Б К И   К О М М Е Н Т А Р И И ]]-------------------------------

-- Автозакрытие скобок
--~ dofile (props["SciteDefaultHome"].."\\tools\\braces_autoclose.lua")

-- Автозакрытие скобок
dofile (props["SciteDefaultHome"].."\\tools\\smartbraces.lua")

-- Автозакрытие HTML тегов
dofile (props["SciteDefaultHome"].."\\tools\\html_tags_autoclose.lua")

-- Универсальное комментирование и снятие комментариев (по Ctrl+Q)
dofile (props["SciteDefaultHome"].."\\tools\\xComment.lua")

----[[ О Т К Р Ы Т Ь  Ф А Й Л ]]----------------------------------------------

-- Замена стандартной команды SciTE "Открыть выделенный файл"
dofile (props["SciteDefaultHome"].."\\tools\\Open_Selected_Filename.lua")

-- Расширение стандартной команды SciTE "Открыть выделенный файл" (открывает без предварительного выделения)
-- А также возможность открыть файл по клику мыши на его имени при нажатой клавише Ctrl.
dofile (props["SciteDefaultHome"].."\\tools\\Select_And_Open_Filename.lua")

----[[ А В Т О М А Т И З А Ц И Я ]]-------------------------------------------

-- Заменяет стандартную команду SciTE "File|New" (Ctrl+N). Создает новый буфер в текущем каталоге с расширением текущего файла
dofile (props["SciteDefaultHome"].."\\tools\\new_file.lua")

-- Включает HTML подсветку для файлов без расширения, открываемых из меню "просмотр HTML-кода" Internet Explorer
dofile (props["SciteDefaultHome"].."\\tools\\set_html.lua")

-- Автоматическое сворачивание всех секций при открытии файлов заданного типа
dofile (props["SciteDefaultHome"].."\\tools\\ToggleFoldAll.lua")

-- Автодополнение объектов их методами и свойствами
dofile (props["SciteDefaultHome"].."\\tools\\AutocompleteObject.lua")

-- При вводе слова, если это сокращение то вызывается список аббревиатур
--~ dofile (props["SciteDefaultHome"].."\\tools\\abbrevlist.lua")

-- Подсветка парных тегов в HTML
dofile (props["SciteDefaultHome"].."\\tools\\highlighting_paired_tags.lua")

----[[ Д О П О Л Н И Т Е Л Ь Н Ы Е  М Е Н Ю ]]--------------------------------

-- После выполнения команды "Найти в файлах..." создает пункт в контекстном меню консоли - "Открыть найденные файлы"
dofile (props["SciteDefaultHome"].."\\tools\\OpenFindFiles.lua")

-- Создает в контекстном меню таба (закладки) подменю для команд SVN
--~ dofile (props["SciteDefaultHome"].."\\tools\\svn_menu.lua")

----[[ У Т И Л И Т Ы  И  И Н С Т Р У М Е Н Т Ы ]]-----------------------------

-- SciTE_HexEdit: A Self-Contained Primitive Hex Editor for SciTE
dofile (props["SciteDefaultHome"].."\\tools\\HexEdit\\SciTEHexEdit.lua")

-- SciTE Calculator
dofile (props["SciteDefaultHome"].."\\tools\\Calculator\\SciTECalculatorPD.lua")

-- Вставка спецсимволов (©,®,§,±,…) из раскрывающегося списка (для HTML вставляются их обозначения)
dofile (props["SciteDefaultHome"].."\\tools\\InsertSpecialChar.lua")

-- Установка / снятие закладок на строку (Bookmark) (то же что и Ctrl+F2)
-- с помощью клика мыши при нажатой клавише Ctrl
--~ dofile (props["SciteDefaultHome"].."\\tools\\MarkerToggle.lua")

----[[ Н А С Т Р О Й К И   И Н Т Е Р Ф Е Й С А ]]-----------------------------

-- Установка размера символа табуляции в окне консоли
local tab_width = tonumber(props['output.tabsize'])
if tab_width ~= nil then
	scite.SendOutput(SCI_SETTABWIDTH, tab_width)
end

----------------------------------------------------------------------------
