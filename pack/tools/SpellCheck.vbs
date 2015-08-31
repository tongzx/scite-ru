' SpellCheck v5.1
' Адаптировал классический скрипт для SciTE: mozers™
' Обход ошибки Word 2003: Lex1
' Исправление проблем с кодировкой: ALeXkRU
' -----------------------------------------------------------------------
' Проверка орфографии выделенного текста с помощью объекта "Word.Application"
' т.е. необходимо чтобы на машине был установлен MS Word с компонентом "Проверка орфографии"
' 
' Для подключения добавьте в свой файл .properties следующие строки:
' command.name.22.*=Проверка орфографии
' command.22.*=wscript "$(SciteDefaultHome)\tools\SpellCheck.vbs"
' command.input.22.*=$(CurrentSelection)
' command.mode.22.*=subsystem:windows,replaceselection:auto,savebefore:no,quiet:yes
' -----------------------------------------------------------------------
' 
' Если в окне проверки орфографии кракозяблы (закорючки), включите декодирование. 
' Смотрите ниже "Параметры для перекодировки". Установите Decoding = 1 (по умолчанию)
' и укажите исходную кодировку, по умолчанию "Windows-1251".
' Доступные исходные кодировки: koi8-r, ascii, utf-7, utf-8, Windows-1250, Windows-1251, Windows-1252
' 
' Окно проверки орфографии открывается в фоне!! (под окном SciTE). 
' ToDo: Надо бы вынести вперёд.
' Временное решение: Предупреждение-напоминание
' Для отключения установить параметр ShowExclamWin = 0
' -----------------------------------------------------------------------

Option Explicit
Dim objWord, exit_code, Text_In, Text_Out, TextRange, Text_Out1
Dim Decoding, DestCharset, SourceCharset, ShowExclamWin

' -------------
'  Параметры для перекодировки и стартового экрана
' -------------
'  Если нужно менять кодировку, задать Decoding = 1, иначе 0
Decoding = 1
'  задать исходную (может меняться) и конечную (всегда utf-8) кодировки проверяемого текста
SourceCharset = "Windows-1251"    ' исходная кодировка
'SourceCharset = "KOI8-R"
DestCharset = "utf-8"             ' конечная кодировка Unicode. Не меняется
'
'  Для отключения начального предупреждения задать ShowExclamWin = 0, для показа 1
ShowExclamWin = 1

' -------------

Text_In = WScript.StdIn.ReadAll
If len(Text_In) > 1 then
	Set objWord = WScript.CreateObject("Word.Application")

	' Для отключения сообщения, задать выше ShowExclamWin = 0
	If ShowExclamWin = 1 then		' будет предупреждение
		MsgBox "Окно проверки открывается в фоне (под окном SciTE)!" & vbNewLine & "Сдвиньте окно редактора для работы с ним."  & vbNewLine & "Если вместо текста закорючки, включите перекодировку в файле " & vbNewLine & "(SciteDefaultHome)\tools\SpellCheck.vbs", vbInformation, "Проверка орфографии"
	End If

	If Decoding = 1 then		' нужно менять кодировку
		On Error Resume Next: Err.Clear
		With CreateObject("ADODB.Stream")
			.Type = 2: .Mode = 3
			If Len(SourceCharset) Then .Charset = SourceCharset    ' указываем исходную кодировку
			.Open
			.WriteText Text_In
			.Position = 0
			.Charset = DestCharset    ' назначаем новую кодировку
			Text_In = .ReadText
			.Close
		End With
	End If

	objWord.WindowState = 2 'wdWindowStateMinimize
	objWord.Visible = False
	objWord.Documents.Add
	objWord.Selection = Text_In
	exit_code = 1

	On Error Resume Next
	Set TextRange = objWord.ActiveDocument.Range(0,objWord.Selection.End)

	If Not objWord.CheckSpelling(TextRange) Or Not objWord.CheckGrammar(TextRange) Then
		If Err.Number = 0 Then
			objWord.ActiveDocument.CheckGrammar
		Else
			objWord.ActiveDocument.CheckSpelling
		End If
'		Text_Out = objWord.ActiveDocument.Range(0,objWord.Selection.End)
		' сначала выделим всё, иначе при отказе от проверки только последнее выбранное слово возвращает
		Text_Out1 = objWord.ActiveDocument.Range.Select
		' а вот теперь выделим, но без последнего символа (выкинуть перевод каретки CR)
		Text_Out = objWord.ActiveDocument.Range(0,objWord.Selection.End-1)

		If Text_Out <> Text_In Then
			WScript.StdOut.Write Text_Out
			exit_code = 0
		end if
	End If

	objWord.ActiveDocument.Close 0 'wdDoNotSaveChanges
	objWord.Quit True
	Set objWord = Nothing

	if exit_code = 1 Then MsgBox "Текст не содержит ошибок" & vbNewLine & "или была выбрана ""Отмена""", vbInformation, "Проверка орфографии"
Else
	MsgBox "Сначала необходимо выделить проверяемый текст!", vbExclamation, "Проверка орфографии"
End If
WScript.Quit (exit_code)