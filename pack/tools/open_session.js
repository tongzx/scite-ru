var scite = "c:\\Program Files\\SciTE\\SciTE.exe";
var WshShell = new ActiveXObject("WScript.Shell");
var filename = WScript.Arguments(0);
var opt = '"-loadsession:' + filename.replace(/\\/g,"\\\\") + '"';
var cmd = '"' + scite + '" ' + opt;
WshShell.Run(cmd, 0, false);

