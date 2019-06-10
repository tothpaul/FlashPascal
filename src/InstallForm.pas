unit InstallForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ShellAPI, RegEdit;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Oui: TButton;
    Non: TButton;
    lbInstall: TLabel;
    lbRemove: TLabel;
    lbVersion: TLabel;
    procedure NonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OuiClick(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
  private
    { Déclarations privées }
    FInstalled: Boolean;
    FUpdate   : Integer;
    procedure DeleteVirtualStoreFiles;
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

uses Links, InstallData, Unzip, SHFolder;

{$R *.dfm}
{$R lib\WinXP.res}

procedure TForm1.NonClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Ver: string;
begin
  lbVersion.Caption := Format(lbVersion.Caption, [Version]);
  FInstalled := ReadRegString(HKEY_LOCAL_MACHINE, WINKEY, 'DisplayName', '') = DisplayName;
  if FInstalled then
  begin
    ver := ReadRegString(HKEY_LOCAL_MACHINE, WINKEY, 'DisplayVersion', '');
    if (ver = '12.06.13')
    or (ver = '12.06.14')
    or (ver = '12.06.15')
    or (ver = '12.06.16')
    or (ver = '12.06.17')
    or (ver = '12.06.21')
    or (ver = '12.06.25')
    or (ver = '12.07.02')
    or (ver = '12.07.07')
    or (ver = '13.01.02')
    or (ver = '13.03.16')
    or (ver = '13.04.29')
    or (ver = '13.05.04')
    or (ver = '13.06.02')
    or (ver = '13.06.05')
    or (ver = '13.07.03')
    or (ver = '13.10.25')
    or (ver = '13.11.10')
    or (ver = '14.03.01')
    or (ver = '14.03.15') then
      FUpdate := 1
    else
    if ver <> Version then
    begin
      ShowMessage('Ce programme est obsolète, veuillez utiliser la version ' + ver + ' ou supérieure');
      Application.Terminate;
      Exit;
    end;
    FInstalled := (FUpdate = 0) and FileExists(InstallPath + 'bin\Remove.exe');
  end;
  lbInstall.Visible := FInstalled = False;
  lbRemove.Visible := FInstalled = True;
end;

procedure TForm1.OuiClick(Sender: TObject);
var
  P: string;
  L: string;
begin
  if FInstalled then
  begin

    if ShellExecute(Handle, nil, PChar(InstallPath + 'bin\Remove.exe'), '/delete', nil, 0) <= 32 then
      ShowMessage('Erreur inattendue, merci de contacter le support Execute à l''adresse <contact@execute.re>')
    else
      Application.Terminate;
    Exit;

  end else begin

    if FUpdate = 1 then
      DeleteVirtualStoreFiles;

    if UnZipAllFromResName('PRG', InstallPath ) = False then
    begin
      if FUpdate > 0 then
        ShowMessage('Impossible de mettre à jour le programme, assurez vous qu''il n''est pas ouvert')
      else
        ShowMessage('Impossible d''installer l''application');
      Exit;
    end;

    P := InstallPath + 'bin\Remove.exe';

    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'DisplayName', DisplayName);
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'DisplayIcon', P + ',0');
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'DisplayVersion', Version);
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'InstallLocation', InstallPath);
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'Publisher', 'Execute SARL');
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'HelpLink', 'http://flashpascal.execute.re');
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'URLInfoAbout', 'http://www.execute.re');
    WriteRegString(HKEY_LOCAL_MACHINE, WinKey, 'UninstallString', P);
    WriteRegDWord(HKEY_LOCAL_MACHINE, WinKey, 'NoModify', 1);
    WriteRegDWord(HKEY_LOCAL_MACHINE, WinKey, 'NoRepair', 1);
    WriteRegDWord(HKEY_LOCAL_MACHINE, WinKey, 'EstimatedSize', (1298003 + 512) div 1024); // Ko

    P := InstallPath + 'bin\FlashPascal2.exe';
    if FUpdate = 0 then
      SetFileType(FileExt, FileType, P);

    L := ReadRegString(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','Desktop','C:\Users\Default\Desktop');
    CreateLink(L + '\' + LinkName + '.lnk', P, '');

    UnZipAllFromResName('DOC', CommonPath + '\');

    ShellExecute(0, nil, PChar(P), nil, nil, SW_SHOW);
  end;
  Application.Terminate;
end;

procedure TForm1.Label2Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://www.execute.re', nil, nil, SW_SHOW);
end;

procedure TForm1.Label3Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'mailto:contact@execute.re', nil, nil, SW_SHOW);
end;

procedure TForm1.DeleteVirtualStoreFiles;
var
  TempPath : array[0..MAX_PATH] of Char;
  Path: string;
begin
// C:\Users\Execute\AppData\Local\VirtualStore\Program Files (x86)\Execute SARL\FlashPascal2\units
  SHGetFolderPath(Application.Handle, CSIDL_LOCAL_APPDATA, 0, 0, TempPath);
  Path := TempPath + '\VirtualStore' + Copy(InstallPath, 3, MaxInt) + 'units\';
  if FileExists(Path + 'Flash8.pas') then
  begin
    DeleteFile(Path + 'Flash8.pas');
    RemoveDirectory(PChar(Path));
    SetLength(Path, Length(Path) - 6); //units
    RemoveDirectory(PChar(Path));
    SetLength(Path, Length(Path) - 13); //FlashPascal2
    RemoveDirectory(PChar(Path));
    SetLength(Path, Length(Path) - 13); //Execute SARL
    RemoveDirectory(PChar(Path));
  end;
  if FileExists(InstallPath + 'units\Flash8.pas') then
  begin
    Deletefile(InstallPath + 'units\Flash8.pas');
    RemoveDirectory(PChar(InstallPath + 'units'));
  end;
end;

end.
