@echo off

set DevEnvDir=c:\Program Files\Microsoft Visual Studio .NET 2003\Common7\IDE
SET VC=c:\Program Files\Microsoft Visual Studio .NET 2003
set MSVCDir=%VC%\VC7

set PATH=%DevEnvDir%;%MSVCDir%\BIN;%VC%\Common7\Tools;%VC%\Common7\Tools\bin\prerelease;%VC%\Common7\Tools\bin;%PATH%;
set INCLUDE=%MSVCDir%\ATLMFC\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\PlatformSDK\include\prerelease;%MSVCDir%\PlatformSDK\include;
set LIB=%MSVCDir%\ATLMFC\LIB;%MSVCDir%\LIB;%MSVCDir%\PlatformSDK\lib\prerelease;%MSVCDir%\PlatformSDK\lib;

cd scintilla\win32
nmake -f scintilla.mak
cd ..\..
cd scite\win32
nmake -f scite.mak
