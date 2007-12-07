-- FindText v6.0
-- Автор: неизвесен <http://forum.ruteam.ru/index.php?action=vthread&forum=22&topic=175>
-- Корректировки: mozers™, mimir, Алексей
-- Поиск выделенного в окне редактора (или консоли) текста с выводом содержащих его строк в консоль

-- Для подключения добавьте в свой файл .properties следующие строки:
--    command.name.22.*=Поиск текста
--    command.22.*=dofile $(SciteDefaultHome)\tools\FindText.lua
--    command.mode.22.*=subsystem:lua,savebefore:no
-----------------------------------------------

local function RemoveFindMarks()
	scite.SendEditor(SCI_SETINDICATORCURRENT, INDIC_CONTAINER)
	scite.SendEditor(SCI_INDICATORCLEARRANGE, 0, editor.Length)
end

local function MarkText(start, length)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
end

local sText = props['CurrentSelection']
local flag = 0
if (sText == '') then
	sText = props['CurrentWord']
	flag = SCFIND_WHOLEWORD
end
if string.len(sText) > 0 then
	editor:MarkerDeleteAll(1)
	RemoveFindMarks()
	if flag == SCFIND_WHOLEWORD then
		print('> Поиск слова: "'..sText..'"')
	else
		print('> Поиск текста: "'..sText..'"')
	end
	local s,e = editor:findtext(sText,flag,0)
	local count = 0
	if(s~=nil)then
		local m = editor:LineFromPosition(s) - 1
		while s do
			local l = editor:LineFromPosition(s)
			MarkText(s, e-s)
			count = count + 1
			if l ~= m then
				local str = string.gsub(' '..editor:GetLine(l),'%s+',' ')
				editor:MarkerAdd(l,1)
				print(props['FileNameExt']..':'..(l + 1)..':\t'..str)
				m = l
			end
			s,e = editor:findtext(sText,flag,e+1)
		end
		print('> Найдено: '..count..' вхождений\nДвойной щелчок на строке с результатом установит курсор на оригинальную строку')
	else
		print('> Вхождений ['..sText..'] не найдено!')
	end
else
	editor:MarkerDeleteAll(1)
	RemoveFindMarks()
	print('> Сначала выделите в редакторе текст, который необходимо найти! (поиск текста)\n> Можно просто установить курсор на нужное слово (поиск слова)\n> Так же можно выделить текст в окне консоли')
end
--~ editor:CharRight() editor:CharLeft() --Снимает выделение с исходного текста