-- Переключатель кодировки текущего ввода и отображения win1251/dos866
-- Одновременно переключается кодировка окна консоли
-- Автор: YuriNB <http://forum.ru-board.com/profile.cgi?action=show&member=yurinb>
-- Источник: <http://forum.ru-board.com/topic.cgi?forum=5&topic=3215&start=280#15>
-- Доработка: mozers, VladVRO
-------------------------------------------------
-- win1251 to cp866 keyboard mapper
-- 2005-10-27 (c) icq=2614215
-------------------------------------------------
function change_codepage_ru()
	scite.MenuCommand(IDM_ENCODING_DEFAULT)
	if props["character.set"]=='255' then
		props["character.set"]='204'
		props["code.page.name"]='WIN-1251'
--~ 		print("Текущая кодировка: Win1251")
	else
		props["character.set"]='255'
		props["code.page.name"]='DOS-866'
--~ 		print("’ҐЄгй п Є®¤Ёа®ўЄ : dos866")
	end
	scite.UpdateStatusBar()
end

local charset1251to866 =
{
[168]=240, --Ё
[184]=241, --ё
[185]=252, --№
[192]=128,[193]=129,[194]=130,[195]=131,[196]=132,
[197]=133,[198]=134,[199]=135,[200]=136,[201]=137,
[202]=138,[203]=139,[204]=140,[205]=141,[206]=142,
[207]=143,[208]=144,[209]=145,[210]=146,[211]=147,
[212]=148,[213]=149,[214]=150,[215]=151,[216]=152,
[217]=153,[218]=154,[219]=155,[220]=156,[221]=157,
[222]=158,[223]=159,[224]=160,[225]=161,[226]=162,
[227]=163,[228]=164,[229]=165,[230]=166,[231]=167,
[232]=168,[233]=169,[234]=170,[235]=171,[236]=172,
[237]=173,[238]=174,[239]=175,[240]=224,[241]=225,
[242]=226,[243]=227,[244]=228,[245]=229,[246]=230,
[247]=231,[248]=232,[249]=233,[250]=234,[251]=235,
[252]=236,[253]=237,[254]=238,[255]=239
}

local function Win2DOS(charAdded)
	local a1=string.byte(charAdded)
	if charset1251to866[a1] ~= nil then
		local pos = editor.CurrentPos
		editor:SetSel(pos, pos - 1)
		editor:ReplaceSel( string.char( charset1251to866[a1] ) )
	end
end

-- Добавляем свой обработчик события OnChar
local old_OnChar = OnChar
function OnChar(char)
	local result
	if old_OnChar then result = old_OnChar(char) end
	if props["character.set"]=='255' then
		Win2DOS(char)
	end
	return result
end
