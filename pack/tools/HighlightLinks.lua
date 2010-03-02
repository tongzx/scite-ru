--[[----------------------------------------------------------------------------
HighlightLinks v1.4.2
Автор: VladVRO

Подсветка линков в тексте, выделение всего линка при двойном клике на нем и
открытие линка в броузере при двойном клике с зажатой клавишей Ctrl.

Внимание:
Скрипт работает только в версии SciTE-Ru.
В скрипте используются функции из COMMON.lua (EditorMarkText, EditorClearMarks)
и внешней библиотеки shell (shell.exec)
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
Задать файлы для которых при открытии и при сохранении файла будет автоматически
выполняться подсветка:
в виде списка имен лексеров через запятую (для файлов без лексера имя null)
  highlight.links.lexers=null
или списка расширений файлов через запятую:
  highlight.links.exts=txt,htm

Дополнительный параметр, позволяющий менять маску поиска линков:
  highlight.links.mask=https*://[\w_&%?.-$+=*~/]+
--]]----------------------------------------------------------------------------

local mark_number = 3
local default_link_mask = "https*://[^ \t\r\n\"\']+"

function HighlightLinks()
	local link_mask = props['highlight.links.mask']
	if link_mask == '' then link_mask = default_link_mask end
	EditorClearMarks(mark_number)
	local flag = SCFIND_REGEXP
	local s,e = editor:findtext(link_mask, flag, 0)
	while s do
		EditorMarkText(s, e-s, mark_number)
		s,e = editor:findtext(link_mask, flag, e+1)
	end
end

local browser
local function select_highlighted_link(is_browse)
	local p = editor.CurrentPos
	if scite.SendEditor(SCI_INDICATORVALUEAT, mark_number, p) == 1 then
		local s = scite.SendEditor(SCI_INDICATORSTART, mark_number, p)
		local e = scite.SendEditor(SCI_INDICATOREND, mark_number, p)
		if s and e then
			editor:SetSel(s,e)
			if is_browse then
				browser = editor:GetSelText()
			end
			return true
		end
	end
end
AddEventHandler("OnDoubleClick", function(shift, ctrl, alt)
	if editor.Focus then
		if ctrl then
			return select_highlighted_link(true)
		else
			select_highlighted_link(false)
		end
	end
end)

local function launch_browse()
	if browser then
		local cmd = browser
		browser = nil
		shell.exec(cmd)
	end
end
AddEventHandler("OnMouseButtonUp", launch_browse)

local function auto_highlight()
	local list_lexers = props['highlight.links.lexers']
	local list_exts = props['highlight.links.exts']
	if (list_lexers ~= '' and string.find(','..list_lexers..',', ','..editor:GetLexerLanguage()..',')) or
	   (list_exts ~= '' and string.find(','..list_exts..',', ','..props['FileExt']..','))
	then
		HighlightLinks()
	end
end
AddEventHandler("OnOpen", auto_highlight)
AddEventHandler("OnSave", auto_highlight)
