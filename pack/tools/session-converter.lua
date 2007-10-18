--[[
SciTE Session file converter
Version: 2.0
Author: VladVRO
---------------------------------------------------
Description:
  конвертирует содержимое открытого в редакторе файла сессии SciTE из старого
  формата (до версии 1.74) в новый формат.

Для подключения добавьте в свой файл .properties следующие строки:
  command.name.125.*.ses=Преобразовать файл сессии
  command.125.*.ses=dofile $(SciteDefaultHome)\tools\session-converter.lua
  command.mode.125.*.ses=subsystem:lua,savebefore:no

---------------------------------------------------
]]

local text = editor:GetText().."\n"
local new = "# SciTE session file\n\n"
local n = 0

for str in string.gfind(text, "([^\n]*)\n") do
  for cur, pos, bm, name in string.gfind(str, "<pos=(%-*)([0-9]+)[ bm=]*([0-9,]*)> (.+)") do
    -- read next line
    n = n + 1
    new = new.."buffer."..n..".path="..name.."\n"
    new = new.."buffer."..n..".position="..pos.."\n"
    if cur == "-" then
      new = new.."buffer."..n..".current=1\n"
    end
    if bm ~= "" then
      new = new.."buffer."..n..".bookmarks="..bm.."\n"
    end
    new = new.."\n"
  end
end

props["1"] = props["FileName"]..".session"
if scite.ShowParametersDialog("Сохранить файл как:") then
  local path = string.sub(props["FilePath"], 1, string.len(props["FilePath"]) - string.len(props["FileNameExt"]))..props["1"]
  io.output(path)
  io.write(new)
  io.close()
  scite.MenuCommand("IDM_CLOSE")
  scite.Open(path)
else
  -- update text in editor
  editor:SelectAll()
  editor:ReplaceSel(new)
end
