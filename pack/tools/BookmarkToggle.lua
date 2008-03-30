-- BookmarkToggle.lua
-- Version: 1.0
-- Author: mozers™, mimir
---------------------------------------------------
-- Установка / снятие меток на строку (Bookmark) (то же что и Ctrl+F2)
-- с помощью клика мыши при нажатой клавише Ctrl
---------------------------------------------------

local function BookmarkToggle(shift, ctrl, alt)
	if (ctrl) then
		local i = editor:LineFromPosition(editor.CurrentPos)
		if editor:MarkerGet(i) == 0 then
			editor:MarkerAdd(i,1)
		else
			editor:MarkerDelete(i,1)
		end
	end
	return false
end

-- Добавляем свой обработчик события OnClick
local old_OnClick = OnClick
function OnClick(shift, ctrl, alt)
	local result
	if old_OnClick then result = old_OnClick(shift, ctrl, alt) end
	if BookmarkToggle(shift, ctrl, alt) then return true end
	return result
end
