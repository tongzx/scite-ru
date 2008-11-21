require "iconv"

function Convert(text_in, code_in, code_out)
	local cd = iconv.open(code_in, code_out)
	assert(cd, "Failed to create a converter object.")
	local text_out, err = cd:iconv(text_in)

	if err == iconv.ERROR_INCOMPLETE then
		print("ERROR: Incomplete input.")
	elseif err == iconv.ERROR_INVALID then
		print("ERROR: Invalid input.")
	elseif err == iconv.ERROR_NO_MEMORY then
		print("ERROR: Failed to allocate memory.")
	elseif err == iconv.ERROR_UNKNOWN then
		print("ERROR: There was an unknown error.")
	end
	return text_out
end

local text0 = editor:GetSelText()
local text1 = Convert(text0, "cp866", "windows-1251")
-- editor:ReplaceSel(text1)
print(text1)

--[[-------------------------------------------------
strCaptionText - текст заголовка окна. Значение по-умолчанию равно "InputBox"
  strPrompt - текст приглашения над полем ввода. Значение по-умолчанию равно "Enter"
  strDefaultValue - исходное значение поля ввода. Значение по-умолчанию равно пустой строке ""
  funcCheckInput - функция для проверки вводимого текста. Получает текст в том виде, в каком он будет вместе с только что поступившим символом и возвращает либо true - принять этот символ, либо false - отклонить ввод. Значение по-умолчанию равно nil - ввод без каких-либо ограничений
  intMinWidth - минимальная ширина поля ввода в усреднённых символах (если strPrompt или strDefaultValue будут шире, то минимальная ширина автоматически подгоняется под большее из них). Значение по-умолчанию равно 20
--]]-------------------------------------------------
