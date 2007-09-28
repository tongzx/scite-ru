-- Exec.lua
-- Version: 1.2
-- Autor: HSolo, mozers™
---------------------------------------------------
-- Расчет выделенного текста как математического выражения
-- или открытие в браузере выделенного URL
-- http://forum.ru-board.com/topic.cgi?forum=5&topic=3215&start=2020#3
---------------------------------------------------

local function FormulaDetect(str)
  local PatternNum = "([\-\+\*\/%b()%s]*%d+[\.\,]*%d*[\)]*)"
  local startPos, endPos, Num, Formula
  startPos = 1
  Formula = ''
  while true do
      startPos, endPos, Num = string.find(str, PatternNum, startPos) -- Находим числа, знаки, скобки (т.е. все что можно принять за часть формулы)
      if startPos == nil then break end
      startPos = endPos + 1
--~ print(Num)
      Num = string.gsub (Num, '%s+', '')                           -- Убираем пробелы
      Num = string.gsub (Num, '^([\(%d]+)', '+%1')                 -- Там, где перед числом нет знака, ставим "+" (т.е. пробелы и переводы строк заменяются на "+")
      Num = string.gsub (Num, '^([\)]+)([%d]+)', '%1+%2')          -- Добавляем знак "+" (при его отсутствии) между числом и скобкой
      Formula = Formula..Num                                       -- Склеиваем вновь преобразованную строку
  end
  Formula = string.gsub (Formula, '^[\+]', '')                     -- В самом начале получился лишний "+" - убиваем его
  Formula = string.gsub(Formula,"[\,]+",'.')                       -- Не будем строги к символу - разделителю десятичных чисел :)
  Formula = string.gsub(Formula,"([\+])([\+]+)",'%1')              -- Удаляем сдвоенные знаки (++) = (+)
  Formula = string.gsub(Formula,"([\-])([\+]+)",'%1')              -- Удаляем сдвоенные знаки (-+) = (-)

  Formula = string.gsub(Formula,"([\+\-\*\/])([\*\/]+)",'%1')      -- Удаляем сдвоенные знаки перед * и / т.к. это явный косяк
  Formula = string.gsub(Formula,"([\+\-\*\/])([\*\/]+)",'%1')      -- Для успокоения совести проделаем дважды

  Formula = string.gsub(Formula,"([%d\)]+)([\+\*\/\-])",'%1 %2 ')  -- Разделяем группы пробелами

  return Formula
end

local str = ''
if editor.Focus then
  str = editor:GetSelText()
else
  str = props['CurrentSelection']
end

if (str == '') then
  str = editor:GetCurLine()
end

if (string.len(str) > 2) then
  if string.find(str,'http://(.*)') then
    local browser = ('explorer "' .. str .. '"')
    os.run (browser, 0, false)
    --~ os.execute (browser)
  else
    if string.find(str, "(math\.%w+)") then  -- В случае сложных математических выражений форматирование оставляем на пользователя
      str = string.gsub(str,"[=]",'')
    else
      str = FormulaDetect(str)
    end

    print('-> Расчет выражения: '..str)
    local res = assert(loadstring('return '..str),str)()
    editor:CharRight()
    editor:LineEnd()
    local sel_start = editor.SelectionStart + 1
    local sel_end = sel_start + string.len(res)
    editor:AddText('\n= '..res)
    editor:SetSel(sel_start, sel_end)
    print('>> Результат: '..res)
  end
end

-- Тесты типа :)
--~ 1/2 56/4 - 56 (8-6)*4  4,5*(1+2)    66
--~ 3/6 6.4/2 6  (7-6)*4  45/4.1 66

--~ dmfdmk v15*6dmd.ks skm4.37/3d(k)gm/sk+d skdmg(6,7+6)skdmgk

--~ Колбаса = 24.5кг. * 120руб./кг
--~ Бензин(ABC) = (2500км. / (11,5л./100км.)) * 18.4руб./л + Канистра =100руб.
--~ Штукатурка = 22.4 м2 /80руб./100 м2
