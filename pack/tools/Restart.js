// SciTE Restarter
// Version: 1.1
// Autor: mozers™
// ------------------------------------------------
// Description:
//   Перезапускает SciTE (требуется SciTE.Helper)
// Подключение:
//    command.name.26.*=Restart SciTE
//    command.26.*=wscript "$(SciteDefaultHome)\tools\Restart.js"
//    command.mode.26.*=subsystem:windows,replaceselection:no,savebefore:no,quiet:yes
// ------------------------------------------------
var WshShell = new ActiveXObject("WScript.Shell");
try {
	var SciTE=new ActiveXObject("SciTE.Helper");
} catch(e) {
	WScript.Echo("Please install SciTE Helper before!");
	WScript.Quit(1);
}
var scite_path = '"'+SciTE.Props("SciteDefaultHome")+'\\SciTE.exe"';
SciTE.MenuCommand(140); //IDM_QUIT
WScript.Sleep(1500);
WshShell.Run(scite_path,1,false);
