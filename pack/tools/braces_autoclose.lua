-- Автозакрытие скобок
-- Авторы: gansA, mimir, Midas
-- Работает, если braces.autoclose=1 (параметр в файле SciTEGlobal.properties)
-----------------------------------------------

local function BracesAutoClose(charAdded)
	local pos = editor.CurrentPos
	local brIdx = string.byte(props['PrevIdx'])
	local f=charAdded

	if(brIdx~=nil)and(brIdx>0)then
		local symE
		symE = string.sub(props['braces.close'],brIdx,brIdx)
		if (charAdded ~= symE) then
			editor:InsertText(pos,symE)
		else
			props['PrevIdx'] = string.char(0)
		end
	end

	if(charAdded=="(")or(charAdded=="[")or(charAdded==".")then
		f=string.format("%%%s",charAdded)
	end
	if f~='%' then
		brIdx =string.find(props['braces.open'],f,1)
	end
	if(brIdx~=nil)then
		props['PrevIdx'] = string.char(brIdx)
	else
		props['PrevIdx'] = string.char(0)
	end
end

-- Добавляем свой обработчик события OnChar
local old_OnChar = OnChar
function OnChar(char)
	local result
	if old_OnChar then result = old_OnChar(char) end
	if(props['braces.autoclose']=='1')then
		if BracesAutoClose(char) then return true end
	end
	return result
end
