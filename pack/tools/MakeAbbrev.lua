-- MakeAbbrev.lua
-- Version: 1.1
-- Autor: frs
-- http://forum.ru-board.com/topic.cgi?forum=5&topic=3215&start=1940#15
---------------------------------------------------
-- add selected text to SciTE Abbreviation, enter the abbreviature in a dialog
-- добавляем выделенный текст в аббревиатуры данного языка, задать аббревиатуру можно в диалоговом окне
---------------------------------------------------
-- Для подключения добавьте в свой файл .properties следующие строки:
--  command.parent.96=9
--  command.name.96.*=Add to Abbreviation
--  command.96.*=dofile $(SciteDefaultHome)\tools\MakeAbbrev.lua
--  command.mode.96.*=subsystem:lua,savebefore:no
---------------------------------------------------
-- Важное замечание:
-- Файл аббревиатуры создается с именем текущего лексера и расширением .abbrev в подкаталоге \abbrev.
-- Для работы с ним его необходимо корректно подключить. Например, так:
--   abbreviations.*.html;*.htm;*.asp;*.shtml=$(SciteDefaultHome)\abbrev\hypertext.abbrev
---------------------------------------------------
local function MakeAbbrev()
    local sel_text = editor:GetSelText()
    if string.len(sel_text)>=10 then --ограничим минимум длины строки для аббревиатуры
        local x1,x2=string.find(sel_text,"%w+%S")
        if x1 and x2 then
            local key=string.sub(sel_text,x1,x2)
            props["1"] = key
            if scite.ShowParametersDialog("Enter abbr for code:") then
                key=props["1"]
           else
                return
            end
            sel_text=string.gsub(sel_text,"\\","\\\\")
            --~ sel_text=string.gsub(sel_text,"\r\n","\\r\\n")
            sel_text=string.gsub(sel_text,"\n","\\n")
            sel_text=string.gsub(sel_text,"\r","\\r")
            sel_text=string.gsub(sel_text,"\t","\\t")
            local file=(props["SciteDefaultHome"].."\\abbrev\\"..editor.LexerLanguage..".abbrev")
            local abb_file =io.open(file)
            if abb_file~=nil then
                abb_file:close()
                io.input(file)
                t=io.read('*a').."\r\n"
            end
            io.output(file)
            if t==nil then t="" end
            io.write(t..key.."="..sel_text)
            io.close()
        end
    end
end

MakeAbbrev()