// HTML Help Context
// Version: 1.5
// Autor: mozers™
//  -----------------------------------------------------------------------
//  Вызывает справку (любой HTML файл) в окне без излишеств
//  Подсвечивает все вхождения выделенного в редакторе текста
//  Добавляет быстрый переход по всем вхождениям с помощью клавиши Enter

//  Подключение:
//  добавьте в свой файл .properties следующие строки:
//    SciTE.files=*.properties;*.lua;*.iface
//    command.help.$(SciTE.files)=wscript "$(SciteDefaultHome)\tools\HTML_help.js" "$(SciteDefaultHome)\doc\SciTEDoc.html" "$(CurrentSelection)"
//    command.help.subsystem.$(SciTE.files)=2
//
//    command.help.*.lua="$(SciteDefaultHome)\tools\HTML_help.js" "$(SciteDefaultHome)\help\lua5.htm" "$(CurrentSelection)"
//    command.help.subsystem.*.lua=2
//  -----------------------------------------------------------------------

var Args = WScript.Arguments;
var help_path = Args(0);
var text_find = Args(1);

// Открываем окно Internet Explorer и загружаем в него html файл справки
var objIE = new ActiveXObject('InternetExplorer.Application');
with (objIE) {
	MenuBar = 0;
	ToolBar = 0;
	StatusBar = 0;
	Navigate (help_path);
	Visible = 1;
}
while (objIE.Busy) {};


if (text_find) {
	// Ищем текст в теле документа и выделяем его
	var TextRange=objIE.document.body.createTextRange();
	for(var i=0;TextRange.findText(text_find);i++){
		TextRange.execCommand('BackColor','','yellow');
		TextRange.execCommand('CreateBookmark','','bmk'+i);
		TextRange.collapse(false);
	}
	var WSHShell = WScript.CreateObject('WScript.Shell');
	if (i==0){
		WSHShell.Popup('Текст  "' + Args(1) + '"  не найден!', 2, 'Документация SciTE', 64);
	} else {
		WSHShell.Popup('Найдено '+ i +' вхождений текста "' + Args(1) + '"\nИспользуйте ENTER для быстрого перемещения!', 2, 'Документация SciTE', 64);
		// Позиционируем справку на первое найденное вхождение
		objIE.document.location.href=objIE.document.location.href+'#bmk0';

		// Внедряем в тело документа скрипт для быстрого перехода по найденным вхождениям
		var oScript = objIE.document.createElement("SCRIPT");
		oScript.type = "text/javascript";
		oScript.text = 'TextRange=document.body.createTextRange(); document.onkeypress=function (){if (event.keyCode==13) {if (TextRange.findText(\"'+text_find+'\")){TextRange.select(); TextRange.collapse(false);}}}';
		objIE.document.getElementsByTagName("BODY")[0].appendChild(oScript);
	}
}
