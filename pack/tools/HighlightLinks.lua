--[[----------------------------------------------------------------------------
HighlightLinks v1.0
Автор: VladVRO

Подсветка линков в тексте и открытие их в броузере при клике с зажатым Ctrl

Внимание:
Скрипт работает только в версии SciTE-Ru.
В скрипте используются функции из COMMON.lua (EditorMarkText, EditorClearMarks)
и внешней библиотеки shell (shell.run)
-----------------------------------------------

Подключение:
Добавить в SciTEStartup.lua строку:
  dofile (props["SciteDefaultHome"].."\\tools\\HighlightLinks.lua")
Настройка:
Создать пункт меню:
  command.name.137.*=Highlight Links
  command.137.*=HighlightLinks
  command.mode.137.*=subsystem:lua,savebefore:no
Задать стиль маркера для подсветки линка:
  find.mark.3=#0000FF,plain
Задать список имен лексеров через запятую (для файлов без лексера имя null)
для которых при открытии файла будет автоматически выполняться подсветка:
  highlight.links.lexers=null
--]]----------------------------------------------------------------------------

local mark_number = 3
local link_mask = "https*://[^ \t\r\n\"\']+"
-- local link_mask = "https?://[%w_&%%%?%.%-%$%+%*]+"

function HighlightLinks()
	EditorClearMarks(mark_number)
	local flag = SCFIND_REGEXP
	local s,e = editor:findtext(link_mask, flag, 1)
	while s do
		EditorMarkText(s, e-s, mark_number)
		s,e = editor:findtext(link_mask, flag, e+1)
	end
end

local browser
local function select_highlighted_link()
	local p = editor.CurrentPos
	if scite.SendEditor(SCI_INDICATORVALUEAT, mark_number, p) == 1 then
		local s = scite.SendEditor(SCI_INDICATORSTART, mark_number, p)
		local e = scite.SendEditor(SCI_INDICATOREND, mark_number, p)
		if s and e then
			editor:SetSel(s,e)
			browser = ('explorer "'..editor:GetSelText()..'"')
			return true
		end
	end
end

local function launch_browse()
	if browser then
		shell.run(browser, 0, false)
		browser = nil
	end
end

-- Add user event handler OnClick
local old_OnClick = OnClick
function OnClick(shift, ctrl, alt)
	local result
	if ctrl and editor.Focus then
		if select_highlighted_link() then return true end
	end
	if old_OnClick then result = old_OnClick(shift, ctrl, alt) end
	return result
end

-- Add user event handler OnMouseButtonUp
local old_OnMouseButtonUp = OnMouseButtonUp
function OnMouseButtonUp()
	local result
	if old_OnMouseButtonUp then result = old_OnMouseButtonUp() end
	launch_browse()
	return result
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	local list = props['highlight.links.lexers']
	if list ~= '' and string.find(','..list..',', ','..editor.LexerLanguage..',') then
		HighlightLinks()
	end
	if old_OnOpen then result = old_OnOpen(file) end
	return result
end

