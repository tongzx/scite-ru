// Registry Jump
// Version: 1.0
// Autor: mozers™
// ------------------------------------------------
// Открывает выделенную ветвь в редакторе реестра
// Понимает записи вида:
//   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control
//   HKLM\SYSTEM\CurrentControlSet\Control
//   HKLM\\SYSTEM\\CurrentControlSet\\Control
// Подключение:
// command.name.78.*=Registry Jump
// command.78.*=wscript "$(SciteDefaultHome)\tools\RegJump.js"
// command.input.78.*=$(CurrentSelection)
// command.mode.78.*=subsystem:windows,replaceselection:no,savebefore:no,quiet:yes
// ------------------------------------------------

var key = WScript.StdIn.ReadAll();
if (key == "") {
    WScript.Quit();
}

key = key.replace(/^HKLM\\/,'HKEY_LOCAL_MACHINE\\');
key = key.replace(/^HKCR\\/,'HKEY_CLASSES_ROOT\\');
key = key.replace(/^HKCU\\/,'HKEY_CURRENT_USER\\');
key = key.replace(/\\\\/g,'\\');
key = "My Computer\\" + key

var WshShell = new ActiveXObject("WScript.Shell");
WshShell.RegWrite ('HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Lastkey',key,'REG_SZ');
WshShell.Run('regedit', 1, false);
