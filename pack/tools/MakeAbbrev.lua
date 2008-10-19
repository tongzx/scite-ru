--[[-------------------------------------------------
MakeAbbrev.lua
Version: 1.4
Author: frs
-------------------------------------------------
add selected text to SciTE Abbreviation, enter the abbreviature in a dialog
добавляем выделенный текст в аббревиатуры данного языка, задать аббревиатуру можно в диалоговом окне
-------------------------------------------------
Для подключения добавьте в свой файл .properties следующие строки:
 command.parent.96=9
 command.name.96.*=Add to Abbreviation
 command.96.*=dofile $(SciteDefaultHome)\tools\MakeAbbrev.lua
 command.mode.96.*=subsystem:lua,savebefore:no
--]]-------------------------------------------------

local sel_text = editor:GetSelText()
if #sel_text < 10 then return end --ограничим минимум длины строки для аббревиатуры

local title = scite.GetTranslation("Abbreviation")
local text = scite.GetTranslation("Enter abbreviation for code:")

local key = sel_text:match("%w+")
key = shell.inputbox(title, text, key, function(name) return name:match('^[^# \t][^=]+$') end)
if key == nil then return end

local abbrev_file_text = ''
local abbrev_file = io.input(props["AbbrevPath"])
if abbrev_file ~= nil then
	abbrev_file_text = io.read('*a').."\r\n"
end

io.output(props["AbbrevPath"])
io.write(abbrev_file_text..key.."="..sel_text:gsub("\\","\\\\"):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t"))
io.close()
