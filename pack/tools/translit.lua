-- Модуль translit.lua предназначен для транслитерации английских букв в русские
-- Version: 1.01
-- Autor: HSolo
-- Подключение можно сделать похожим образом:
---------------------------------------------------------------------------------
--~ command.name.84.*=Translitiration
--~ command.84.*=dofile $(SciteDefaultHome)\tools\translit.lua
--~ command.mode.84.*=subsystem:lua,savebefore:no
--~ command.shortcut.84.*=Alt+T
---------------------------------------------------
local translit = {['shh']="щ",
  ['jo']="ё", ['yo']="ё", ['zh']="ж", ['ii']="й", ['jj']="й", ['sh']="ш",
  ['ch']="ч", ['je']="э", ['ju']="ю", ['yu']="ю", ['ja']="я", ['ya']="я",
  ['a'] ="а", ['b'] ="б", ['v'] ="в", ['w'] ="в", ['g'] ="г",
  ['d'] ="д", ['e'] ="е", ['z'] ="з", ['i'] ="и", ['j'] ="й",
  ['k'] ="к", ['l'] ="л", ['m'] ="м", ['n'] ="н", ['o'] ="о", ['~']="ъ",
  ['p'] ="п", ['r'] ="р", ['s'] ="с", ['t'] ="т", ['u'] ="у", ['\"']="ъ",
  ['f'] ="ф", ['h'] ="х", ['x'] ="х", ['c'] ="ц", ['y'] ="ы", ['\'']="ь",
  ['Shh']="Щ",
  ['Jo']="Ё", ['Yo']="Ё", ['Zh']="Ж", ['Ii']="Й", ['Jj']="Й", ['Sh']="Ш",
  ['Ch']="Ч", ['Je']="Э", ['Ju']="Ю", ['Yu']="Ю", ['Ja']="Я", ['Ya']="Я",
  ['A'] ="А", ['B'] ="Б", ['V'] ="В", ['W'] ="В", ['G'] ="Г",
  ['D'] ="Д", ['E'] ="Е", ['Z'] ="З", ['I'] ="И", ['J'] ="Й",
  ['K'] ="К", ['L'] ="Л", ['M'] ="М", ['N'] ="Н", ['O'] ="О",
  ['P'] ="П", ['R'] ="Р", ['S'] ="С", ['T'] ="Т", ['U'] ="У",
  ['F'] ="Ф", ['H'] ="Х", ['X'] ="Х", ['C'] ="Ц", ['Y'] ="Ы"
  }

local function TranslitIT(s)
  local pos = 1
  local outstr = ""
  local res
  local toFind

  if string.len(s) == 0 then
    return outstr
  end

  while (pos <= string.len(s)) do
    for i = 3, 1, -1 do
      toFind = string.sub(s, pos, pos + i - 1)
      res = translit[toFind]
      if res ~= nil then
        outstr = outstr..res
        pos = pos + string.len(toFind)
        break
      end
    end
    if res == nil then
      outstr = outstr..toFind
      pos = pos + 1
    end
  end
  return outstr
end

local str = props['CurrentSelection']
if (str == '') then
    str = editor:GetSelText()
end
if (str == '') then
  str = editor:GetCurLine()
end

local result = TranslitIT(str)
editor:CharRight()
editor:LineEnd()
local sel_start = editor.SelectionStart + 1
local sel_end = sel_start + string.len(result)
editor:AddText('\n'..result)
editor:SetSel(sel_start, sel_end)
print(result)