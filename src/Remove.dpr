program Remove;

uses
  Windows, SHFolder,
  SysUtils,
  RegEdit in 'lib\RegEdit.pas',
  InstallData in 'InstallData.pas';

{$R *.RES}

procedure ShowMessage(const Msg: string);
begin
  MessageBox(0, PChar(Msg), 'FlashPascal 2', 0);
end;

var
  Desktop: string;
  Str    : string;

procedure DeleteExemples(Names: array of string);
var
  i: Integer;
begin
  for i := Low(Names) to High(Names) do
  begin
    DeleteFile(CommonPath + '\Exemples\' + Names[i] + '.fpr');
    DeleteFile(CommonPath + '\Exemples\' + Names[i] + '.swf');
  end;
end;

begin
  if ParamStr(1) <> '/delete' then
    if MessageBox(0, 'Voulez-vous désinstaller FlashPascal 2 ?', 'FlashPascal 2', MB_YESNO or MB_ICONQUESTION) <> idYes then
      Exit;

  Desktop := ReadRegString(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','Desktop','C:\Users\Default\Desktop');

  Str := InstallPath + 'bin\FlashPascal2.exe';
  if not DeleteFile(Str) then
  begin
      ShowMessage('Impossible de supprimer l''application.'#13'Assurez vous qu''elle n''est pas en cours d''utilisation.');
      Exit;
  end;
  UnsetFileType(FileExt, FileType, Str);
  DeleteFile(InstallPath + 'bin\FlashPascal2.en_US');
  {
  DeleteFile(InstallPath + 'units\Flash8.pas');
  RemoveDir(InstallPath + 'units');
  }
  Str := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA) + '\Execute SARL';
  DeleteFile(Str + '\FlashPascal2\FlashPascal2.ini');
  RemoveDir(Str + '\FlashPascal2');
  RemoveDir(Str);

  DeleteExemples([
    'Barycentre', 'Calc', 'DragPoly', 'Etoile', 'FlashMine',
    'Sudoku', 'ZoneFlash', 'voeux2012', 'HelloWord', 'HelloWorld', 'Curseur',
    'Police', 'SpotLight', 'Wood',
    'Events', 'Video',
    'SoundPlayer',
    'VariantDemo',
    'WithAndSet',
    'MouseWheel', 'Cube',
    'CubeMan3D',
    'SystemCapabilities',
    'FLADE\Car',           
    'FLADE\Mesh'
  ]);
  DeleteFile(CommonPath + '\Exemples\FLADE\FLADE.pas');
  DeleteFile(CommonPath + '\Exemples\Execute.re.flv');
  DeleteFile(CommonPath + '\Exemples\voeux2012.jpg');
  DeleteFile(CommonPath + '\Exemples\son.mp3');
  DeleteFile(CommonPath + '\units\Flash8.pas');
  if RemoveDir(CommonPath + '\Exemples\FLADE')
  and RemoveDir(CommonPath + '\Exemples')
  and RemoveDir(CommonPath + '\units') then
    RemoveDir(CommonPath)
  else
  begin
    ShowMessage('Impossible de supprimer le répertoire commun');
    WinExec(PChar('explorer.exe "' + CommonPath + '"'), SW_SHOW);
  end;

  DeleteFile(Desktop + '\' + LinkName + '.lnk');

  RegDeleteKey(HKEY_LOCAL_MACHINE, PChar(WinKey));
  RegDeleteKey(HKEY_CURRENT_USER, '\Software\Execute-SARL\FlashPascal2');

  Str := GetTempFileName('.bat');
  AssignFile(Output, Str);
  Rewrite(Output);
  WriteLn('@echo off');
  WriteLn(':retry');
  WriteLn('del "', InstallPath, 'bin\Remove.exe"');
  WriteLn('if exist "', InstallPath, 'bin\Remove.exe" goto retry');
  WriteLn('rd "', InstallPath, 'bin"');
  WriteLn('rd "', InstallPath, '"');
  WriteLn('rd "', ExecutePath, '"');
  WriteLn('if exist "', InstallPath, '" explorer.exe "', InstallPath, '"');
  WriteLn('REM del "', Str, '"');
  CloseFile(Output);
  WinExec(PChar(Str), SW_HIDE);
end.
