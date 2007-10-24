-- FuncProcList.lua
-- Version: 1.2.1
-- mozers™ , Maximka (выполняя пожелание ALeXkRU при активном тестировании mimir)
-- Использованы идеи: Grisper и gansA
---------------------------------------------------
-- Вывод списка функций / процедур, имеющихся в коде
-- Для подключения добавьте в свой файл .properties следующие строки:
--   command.name.17.*=List of Functions / Procedures
--   command.17.*=dofile $(SciteDefaultHome)\tools\FuncProcList.lua 
--   command.mode.17.*=subsystem:lua,savebefore:no
--   command.shortcut.17.*=Alt+Shift+F
-- Внимание: В скрипте используется функция IsComment (обязательно подключение COMMON.lua)
---------------------------------------------------

-- паттерны для разных языков программирования (корректируйте, дополняйте)
-- шлите ваши варианты на <mozers@mail.ru>
local findRegExp = {
--~ 	['cxx']="\n[^,.<>=\n]-([^%s,.<>=\n]+[(][^.<>=\n)]-[)])%s-%b{}",
	['cxx']="([^.,<>=\n]-[ :][^.,<>=\n%s]+[(][^.<>=)]-[)])[%s\/}]-%b{}",
	  ['h']="([^.,<>=\n]-[ :][^.,<>=\n%s]+[(][^.<>=)]-[)])[%s\/}]-%b{}",
	['js']="(\n[^,<>\n]-function[^(]-%b())[^{]-%b{}",
	['vbs']="(\n[SsFf][Uu][BbNn][^\r]-)\r",
	['css']="([%w.#-_]+)[%s}]-%b{}",
	['pas']="\nprocedure[^ ]* ([^(]*%b());"
}
local findPattern = findRegExp [props["FileExt"]]
if findPattern == nil then
-- универсальный паттерн для всех остальных языков программирования
	findPattern = "\n[local ]*[SsFf][Uu][BbNn][^ ]* ([^(]*%b())"
end

-- дальше - банальный поиск заданнго паттерна по всему тексту
--~ editor:MarkerDeleteAll(1)
local textAll = editor:GetText()
local startPos, endPos, findString
local count = 0
startPos = 1
print("> Список функций / процедур:")
while true do
	startPos, endPos, findString = string.find(textAll, findPattern, startPos)
	if startPos == nil then break end
	-- убираем переводы строк и лишние пробелы
	findString = string.gsub (findString, "\r\n", "")
	findString = string.gsub (findString, "%s+", " ")
	-- если функция не закомментирована, то выводим ее в список
	if not IsComment(startPos) then
		local line = editor:LineFromPosition(startPos)
		--~ editor:MarkerAdd(line,1)
		print(props['FileNameExt']..':'..(line+1)..':\t'..findString) 
		count = count + 1
	end
	startPos = endPos + 1
end
if count > 0 then
	trace("> Найдено: "..count.." функций / процедур\nДвойной щелчок на строке с результатом установит курсор на оригинальную строку")
else
	trace("> Функций / процедур не найдено!")
end
