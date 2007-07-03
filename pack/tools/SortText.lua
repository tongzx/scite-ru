-- —ортировка выделенных строк по алфавиту и наоборот
-- Tugarinov Sergey & mozersЩ

local sel_text = editor:GetSelText()
local sel_start = editor.SelectionStart
local sel_end = editor.SelectionEnd
local lines = {}
if sel_text ~= '' then
    local one_line = ''
    -- раздел€ем на строки и загон€ем их в таблицу
    for one_line in string.gfind(sel_text, "[^\n]+") do
        table.insert(lines, one_line)
    end
    if table.getn(lines) > 1 then
        -- определим в какую сторону сортировать
        local i = 0
        local ln = ''
        local ln_old = ''
        while (ln == ln_old or i == 1) do
            ln_old = ln
            i = i + 1
            ln = rawget (lines, i)
        end
        -- сортируем строки в таблице
        if ln ~= nil then
            if ln_old > ln then
                table.sort(lines)
            else
                table.sort(lines, function(a, b) return a > b end)
            end
        end
        -- соедин€ем все строки из таблицы вместе
        local out_text = table.concat(lines, "\n").."\n"
        editor:ReplaceSel(out_text)
    end
end
-- восстанавливаем выделение
editor:SetSel(sel_start, sel_end)