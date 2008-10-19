--[[--------------------------------------------------
ColorSet.lua
Authors: mozers™
version 1.0
------------------------------------------------------
  Connection:
   Set in a file .properties:
     command.name.6.*=Choice Color
     command.6.*=dofile $(SciteDefaultHome)\tools\ColorSet.lua
     command.mode.6.*=subsystem:lua,savebefore:no

  Note: Needed gui.dll <http://scite-ru.googlecode.com/svn/trunk/lualib/gui/>
--]]--------------------------------------------------

local colour = props["CurrentWord"]
local change = true
if not colour:match("[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]") then
	colour = "#FFFFFF"
	change = false
else
	colour = "#"..colour
end
colour = gui.colour_dlg(colour)
if colour ~= nil then
	if change then
		local pos = editor.CurrentPos
		local word_start = editor:WordStartPosition (pos, true)
		local word_end = editor:WordEndPosition (pos, true)
		if editor:textrange(word_start-1, word_start) == '#' then word_start = word_start-1 end
		editor:SetSel(word_start, word_end)
	end
	editor:ReplaceSel(colour)
end
