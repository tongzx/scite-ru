' SpellCheck v5.1
' ����������� ������������ ������ ��� SciTE: mozers�
' ����� ������ Word 2003: Lex1
' ����������� ������� � ����������: ALeXkRU
' -----------------------------------------------------------------------
' �������� ���������� ����������� ������ � ������� ������� "Word.Application"
' �.�. ���������� ����� �� ������ ��� ���������� MS Word � ����������� "�������� ����������"
' 
' ��� ����������� �������� � ���� ���� .properties ��������� ������:
' command.name.22.*=�������� ����������
' command.22.*=wscript "$(SciteDefaultHome)\tools\SpellCheck.vbs"
' command.input.22.*=$(CurrentSelection)
' command.mode.22.*=subsystem:windows,replaceselection:auto,savebefore:no,quiet:yes
' -----------------------------------------------------------------------
' 
' ���� � ���� �������� ���������� ���������� (���������), �������� �������������. 
' �������� ���� "��������� ��� �������������". ���������� Decoding = 1 (�� ���������)
' � ������� �������� ���������, �� ��������� "Windows-1251".
' ��������� �������� ���������: koi8-r, ascii, utf-7, utf-8, Windows-1250, Windows-1251, Windows-1252
' 
' ���� �������� ���������� ����������� � ����!! (��� ����� SciTE). 
' ToDo: ���� �� ������� �����.
' ��������� �������: ��������������-�����������
' ��� ���������� ���������� �������� ShowExclamWin = 0
' -----------------------------------------------------------------------

Option Explicit
Dim objWord, exit_code, Text_In, Text_Out, TextRange, Text_Out1
Dim Decoding, DestCharset, SourceCharset, ShowExclamWin

' -------------
'  ��������� ��� ������������� � ���������� ������
' -------------
'  ���� ����� ������ ���������, ������ Decoding = 1, ����� 0
Decoding = 1
'  ������ �������� (����� ��������) � �������� (������ utf-8) ��������� ������������ ������
SourceCharset = "Windows-1251"    ' �������� ���������
'SourceCharset = "KOI8-R"
DestCharset = "utf-8"             ' �������� ��������� Unicode. �� ��������
'
'  ��� ���������� ���������� �������������� ������ ShowExclamWin = 0, ��� ������ 1
ShowExclamWin = 1

' -------------

Text_In = WScript.StdIn.ReadAll
If len(Text_In) > 1 then
	Set objWord = WScript.CreateObject("Word.Application")

	' ��� ���������� ���������, ������ ���� ShowExclamWin = 0
	If ShowExclamWin = 1 then		' ����� ��������������
		MsgBox "���� �������� ����������� � ���� (��� ����� SciTE)!" & vbNewLine & "�������� ���� ��������� ��� ������ � ���."  & vbNewLine & "���� ������ ������ ���������, �������� ������������� � ����� " & vbNewLine & "(SciteDefaultHome)\tools\SpellCheck.vbs", vbInformation, "�������� ����������"
	End If

	If Decoding = 1 then		' ����� ������ ���������
		On Error Resume Next: Err.Clear
		With CreateObject("ADODB.Stream")
			.Type = 2: .Mode = 3
			If Len(SourceCharset) Then .Charset = SourceCharset    ' ��������� �������� ���������
			.Open
			.WriteText Text_In
			.Position = 0
			.Charset = DestCharset    ' ��������� ����� ���������
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
		' ������� ������� ��, ����� ��� ������ �� �������� ������ ��������� ��������� ����� ����������
		Text_Out1 = objWord.ActiveDocument.Range.Select
		' � ��� ������ �������, �� ��� ���������� ������� (�������� ������� ������� CR)
		Text_Out = objWord.ActiveDocument.Range(0,objWord.Selection.End-1)

		If Text_Out <> Text_In Then
			WScript.StdOut.Write Text_Out
			exit_code = 0
		end if
	End If

	objWord.ActiveDocument.Close 0 'wdDoNotSaveChanges
	objWord.Quit True
	Set objWord = Nothing

	if exit_code = 1 Then MsgBox "����� �� �������� ������" & vbNewLine & "��� ���� ������� ""������""", vbInformation, "�������� ����������"
Else
	MsgBox "������� ���������� �������� ����������� �����!", vbExclamation, "�������� ����������"
End If
WScript.Quit (exit_code)