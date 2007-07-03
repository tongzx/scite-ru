-- Insert a copy of the Bookmarked line(s) by Jos van der Zande (JdeB)
-- shortcut Ctrl+Shift+B Insert Copy of Bookmark(s)
editor:Home()                     -- goto beginning of the line
local ml = 0
local s_text = ""
local sel_start = editor.CurrentPos
while true do
    ml = editor:MarkerNext(ml, 2)            -- Find next bookmarked line
    if (ml == -1) then break end
    s_text = s_text .. editor:GetLine(ml)    -- Add text to var
    ml = ml + 1
--~     _ALERT("Inserted bookmarked line: " .. ml)
end
editor:AddText(s_text)            -- Add found text to Script
local sel_end = editor.CurrentPos
editor:SetSel(sel_start, sel_end)
