--[[--------------------------------------------------
FindText v6.8
Авторы: mozers™, mimir, Алексей, codewarlock1101

* Если текст выделен - ищется выделенная подстрока
* Если текст не выделен - ищется текущее слово
* Поиск возможен как в окне редактирования, так и в окне консоли
* Строки, содержащие результаты поиска, выводятся в консоль
* Перемещение по вхождениям - F3 (вперед), Shift+F3 (назад)
* Каждый новый поиск оставляет маркеры своего цвета
* Очистка от маркеров поиска - Ctrl+Alt+C

Внимание:
В скрипте используются функции из COMMON.lua (EditorMarkText, EditorClearMarks)
-----------------------------------------------
Для подключения добавьте в свой файл .properties следующие строки:
    command.name.130.*=Find String/Word
    command.130.*=dofile $(SciteDefaultHome)\tools\FindText.lua
    command.mode.130.*=subsystem:lua,savebefore:no
    command.shortcut.130.*=Ctrl+Alt+F

    command.name.131.*=Clear All Marks
    command.131.*=dostring EditorClearMarks() scite.SendEditor(SCI_SETINDICATORCURRENT, 27)
    command.mode.131.*=subsystem:lua,savebefore:no
    command.shortcut.131.*=Ctrl+Alt+C

Дополнительно необходимо задать в файле настроек стили используемых маркеров (в этом скрипте используется 5 маркеров):
    find.mark.27=#CC00FF
    find.mark.28=#0000FF
    find.mark.29=#00CC66
    find.mark.30=#CCCC00
    find.mark.31=#336600
--]]----------------------------------------------------

local sText = props['CurrentSelection']
local flag = 0
if (sText == '') then
	sText = props['CurrentWord']
	flag = SCFIND_WHOLEWORD
end
local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
if current_mark_number < 27 then current_mark_number = 27 end
if string.len(sText) > 0 then
	if flag == SCFIND_WHOLEWORD then
		props['lexer.errorlist.findtitle.begin'] = '> Поиск текущего слова: "'
		props['lexer.errorlist.findtitle.end'] = '"'
		print('> Поиск текущего слова: "'..sText..'"')
	else
		props['lexer.errorlist.findtitle.begin'] = '> Поиск выделенного текста: "'
		props['lexer.errorlist.findtitle.end'] = '"'
		print('> Поиск выделенного текста: "'..sText..'"')
	end
	local s,e = editor:findtext(sText,flag,1)
	local count = 0
	if(s~=nil)then
		local m = editor:LineFromPosition(s) - 1
		while s do
			local l = editor:LineFromPosition(s)
			EditorMarkText(s, e-s, current_mark_number)
			count = count + 1
			if l ~= m then
				local str = string.gsub(' '..editor:GetLine(l),'%s+',' ')
				print(props['FileNameExt']..':'..(l + 1)..':\t'..str)
				m = l
			end
			s,e = editor:findtext(sText,flag,e+1)
		end
		print('> Найдено: '..count..' вхождений\nF3 (Shift+F3) - Переход по маркерам\nF4 (Shift+F4) - Переход по строкам\nCtrl+Alt+C - очистка всех маркеров')
	else
		print('> Вхождений ['..sText..'] не найдено!')
	end
	current_mark_number = current_mark_number + 1
	if current_mark_number > 31 then current_mark_number = 27 end
	scite.SendEditor(SCI_SETINDICATORCURRENT, current_mark_number)
		-- обеспечиваем возможность перехода по вхождениям с помощью F3 (Shift+F3)
		if flag == SCFIND_WHOLEWORD then
			editor:GotoPos(editor:WordStartPosition(editor.CurrentPos))
		else
			editor:GotoPos(editor.SelectionStart)
		end
		scite.Perform('find:'..sText)
else
	EditorClearMarks()
	scite.SendEditor(SCI_SETINDICATORCURRENT, 27)
	print('> Сначала выделите в редакторе текст, который необходимо найти! (поиск текста)\n> Можно просто установить курсор на нужное слово (поиск слова)\n> Так же можно выделить текст в окне консоли')
end
--~ editor:CharRight() editor:CharLeft() --Снимает выделение с исходного текста
