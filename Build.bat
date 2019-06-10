@echo off

set delphi=C:\Borland\Delphi6\Bin

if exist Install.exe del Install.exe
if exist Install.zip del Install.zip
if exist FlashPascal2.zip del FlashPascal2.zip
if exist bin\FlashPascal2.exe del bin\FlashPascal2.exe
if exist bin\Remove.exe del bin\Remove.exe
if exist src\zip\ProgramFiles.zip del src\zip\ProgramFiles.zip
if exist src\zip\CommonDocs.zip del src\zip\CommonDocs.zip

if not exist dcu\. md dcu
if not exist bin\. md bin

echo FlashPascal2.exe
cd src
"%delphi%\dcc32.exe" -B -N"..\dcu" -E"..\bin" -USynEdit -DRELEASE -Q FlashPascal2.dpr
echo.
cd ..
if exist bin\FlashPascal2.exe goto _Remove
echo Compilation error
goto _End

:_Remove
echo Remove.exe
cd src
"%delphi%\dcc32.exe" -B -N"..\dcu" -E"..\bin" -Usrc -Q Remove.dpr
echo.
cd ..
if exist bin\Remove.exe goto _Zip
echo Compilation error
goto _End
:_Zip

if not exist src\zip md src\zip
zip src\zip\ProgramFiles.zip bin\FlashPascal2.exe bin\FlashPascal2.??_?? bin\remove.exe > zip.txt
zip src\zip\CommonDocs.zip units\Flash8.pas Exemples\*.fpr Exemples\*.jpg Exemples\*.flv Exemples\*.mp3 Exemples\FLADE\*.fpr Exemples\FLADE\FLADE.pas >> zip.txt

echo Install.exe
cd src
"%delphi%\brcc32.exe" InstallRes.rc
"%delphi%\dcc32.exe" -B -N"..\dcu" -E".." -Usrc -Q Install.dpr
echo.
cd ..

echo Install.zip
zip Install.zip Install.exe README.txt > null
echo FlashPascal2.zip
zip FlashPascal2.zip bin\FlashPascal2.exe bin\FlashPascal2.??_?? units\Flash8.pas README.txt Exemples\*.fpr Exemples\*.jpg Exemples\*.flv Exemples\*.mp3 > null

del bin\Remove.exe
del src\zip\ProgramFiles.zip
del src\zip\CommonDocs.zip
echo OK.
:_End
pause