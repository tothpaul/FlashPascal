program Install;

{$R 'InstallRes.res' 'InstallRes.rc'}

uses
  Forms,
  InstallForm in 'InstallForm.pas' {Form1},
  RegEdit in 'lib\RegEdit.pas',
  Links in 'lib\Links.pas',
  InstallData in 'InstallData.pas',
  Unzip in 'UNZIP.PAS';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Installation de FlashPascal 2';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
