//  ColorSet v.3.2
//  mozers™ (при активном участии dB6)
//  -----------------------------------------------------------------------
//  Вызывает системный диалог выбора цвета
//  Результат выбора заменяет выделенное в редакторе значение цвета
//  Для подключения добавьте в свой файл .properties следующие строки:
//    command.name.6.*=Выбор цвета
//    command.6.*=wscript "$(SciteDefaultHome)\tools\ColorSet.js"
//    command.input.6.*=$(CurrentSelection)
//    command.mode.6.*=subsystem:windows,replaceselection:auto,savebefore:no,quiet:yes
//  Примечание:
//    Для работы необходимо наличие в системе COMDLG32.OCX (на большинстве машин уже присутствует)
//  -----------------------------------------------------------------------

var defColor = "FFFFFF";

// Читаем аргументы ком.строки
var cmd = WScript.StdIn.ReadAll();
var strInput;
if (cmd == "") {
	strInput = defColor;
} else {
	strInput = cmd;
}

// Ищем, есть ли параметры цвета в считанном тексте
var regEx = /[0-9|A-F]{6}/i;
var FindColors = regEx.exec(strInput);

// Если у вас отсутствует лицензия на COMDLG32.OCX, то раскомментируйте эти две строчки.
//~ var WshShell = new ActiveXObject("WScript.Shell");
//~ WshShell.RegWrite('HKCR\\Licenses\\4D553650-6ABE-11cf-8ADB-00AA00C00905\\', 'gfjmrfkfifkmkfffrlmmgmhmnlulkmfmqkqj');

// Вызываем системный диалог выбора цвета
try {
	var objDialog = new ActiveXObject("MSComDlg.CommonDialog");
} catch(e) {
	WScript.Echo("Please register COMDLG32.OCX before!");
	WScript.Quit(1);
}

objDialog.CancelError = 1;
objDialog.Flags = 1 + 2;
if (FindColors) {
	objDialog.Color = "&H" + BGR2RGB(FindColors[0]);
} else {
	strInput = defColor;
	objDialog.Color = "&H" + BGR2RGB(defColor);
}

// Открытие диалогового окна выбора цвета
try {objDialog.ShowColor();
	// Если нажали "OK"
	var B = Dec2Hex((objDialog.Color & 0xFF0000) >>> 16);
	var G = Dec2Hex((objDialog.Color & 0xFF00) >>> 8 );
	var R = Dec2Hex(objDialog.Color & 0xFF);
	var resultColor = R + G + B;
	strOut = strInput.replace(regEx, resultColor);
	WScript.StdOut.Write (strOut);
	err_code = 0;
} catch(e) {
	err_code = 1;
}

WScript.Quit (err_code);

// ---------------------------------------------------
// Функция преобразования значения цвета
function BGR2RGB(colorBGR){
	var colorRGB = colorBGR.replace(/(.{2})(.{2})(.{2})/,'$3$2$1');
	return colorRGB;
}

// ---------------------------------------------------
function Dec2Hex (Dec) {
	var hexChars = '0123456789ABCDEF';
	var a = Dec % 16;
	var b = (Dec - a) / 16;
	var hex = '' + hexChars.charAt(b) + hexChars.charAt(a);
	return hex;
}
