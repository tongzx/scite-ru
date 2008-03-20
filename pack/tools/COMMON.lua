-- COMMON.lua
-- Version: 1.1
---------------------------------------------------
-- Общие функции, использующиеся во многих скриптах
---------------------------------------------------

function IsComment(pos)
-- Определение соответствует ли стиль символа стилю комментария
	local style = editor.StyleAt[pos]
	local lexer = editor.LexerLanguage
	local comment = {
		abap = {1, 2},
		ada = {10},
		asm = {1, 11},
		au3 = {1, 2},
		baan = {1, 2},
		bullant = {1, 2, 3},
		caml = {12, 13, 14, 15},
		cpp = {1, 2, 3, 15, 17, 18},
		csound = {1, 9},
		css = {9},
		d = {1, 2, 3, 4, 15, 16, 17},
		escript = {1, 2, 3},
		flagship = {1, 2, 3, 4, 5, 6},
		forth = {1, 2, 3},
		gap = {9},
		hypertext = {9, 20, 29, 42, 43, 44, 57, 58, 59, 72, 82, 92, 107, 124, 125},
		xml = {9, 29},
		inno = {1, 7},
		latex = {4},
		lua = {1, 2, 3},
		mmixal = {1, 17},
		nsis = {1, 18},
		opal = {1, 2},
		pascal = {1, 2, 3},
		perl = {2},
		bash = {2},
		pov = {1, 2},
		ps = {1, 2, 3},
		python = {1, 12},
		rebol = {1, 2},
		ruby = {2},
		scriptol = {2, 3, 4, 5},
		smalltalk = {3},
		specman = {2, 3},
		spice = {8},
		sql = {1, 2, 3, 13, 15, 17, 18},
		tcl = {1, 2, 20, 21},
		verilog = {1, 2, 3},
		vhdl = {1, 2}
	}

	-- Для лексеров, перечисленных в массиве:
	for l,ts in pairs(comment) do
		if l == lexer then
			for _,s in pairs(ts) do
				if s == style then
					return true
				end
			end
			return false
		end
	end
	-- Для остальных лексеров:
	-- asn1, ave, blitzbasic, cmake, conf, eiffel, eiffelkw, erlang, euphoria, fortran, f77, freebasic, kix, lisp, lout, octave, matlab, metapost, nncrontab, props, batch, makefile, diff, purebasic, vb, yaml
	if style == 1 then return true end
	return false
end


------[[ T E X T   M A R K S ]]-------------------------

-- Выделение текста маркером определенного стиля
function EditorMarkText(start, length, style_number)
	scite.SendEditor(SCI_SETINDICATORCURRENT, style_number)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
end

-- Очистка текста от выделения
function EditorClearMarks(start, length)
	scite.SendEditor(SCI_INDICATORCLEARRANGE, start, length)
end

----------------------------------------------------------------------------
-- Задание стиля для маркеров (затем эти маркеры можно будет использовать в скриптах, вызывая их по номеру)

-- Translate color from RGB to win
local function encodeRGB2WIN(color)
	if string.sub(color,1,1)=="#" and string.len(color)>6 then
		return tonumber(string.sub(color,6,7)..string.sub(color,4,5)..string.sub(color,2,3), 16)
	else
		return color
	end
end

local function InitMarkStyle(style_number, indic_style, color)
	editor.IndicStyle[style_number] = indic_style
	editor.IndicFore[style_number] = encodeRGB2WIN(color)
end

local function style(mark_string)
	local mark_style_table = {
	plain    = INDIC_PLAIN,    squiggle = INDIC_SQUIGGLE,
	tt       = INDIC_TT,       diagonal = INDIC_DIAGONAL,
	strike   = INDIC_STRIKE,   hidden   = INDIC_HIDDEN,
	roundbox = INDIC_ROUNDBOX, box      = INDIC_BOX
	}
	for st,st_num in pairs(mark_style_table) do
		if string.match(mark_string, st) ~= nil then
			return st_num
		end
	end
end

local function EditorInitMarkStyles()
	for i = 0, 31 do
		local mark = props["find.mark."..i]
		if mark ~= "" then
			local mark_color = string.match(mark, "#%x%x%x%x%x%x")
			if mark_color == nil then mark_color = props["find.mark"] end
			if mark_color == "" then mark_color = "#0F0F0F" end
			local mark_style = style(mark)
			if mark_style == nil then mark_style = INDIC_ROUNDBOX end
			InitMarkStyle(i, mark_style, mark_color)
		end
	end
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
local OnOpenOne = true
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	if OnOpenOne then
		EditorInitMarkStyles()
		OnOpenOne = false
	end
	return result
end

----------------------------------------------------------------------------
-- Инвертирование состояния заданного параметра (используется для снятия/установки "галок" в меню)
function CheckChange(prop_name)
	if tonumber(props[prop_name]) == 1 then
		props[prop_name] = 0
	else
		props[prop_name] = 1
	end
end
