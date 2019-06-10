unit Options;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI, Translates;

type
  TOptionsForm = class(TForm)
    Label1: TLabel;
    edPlayer: TEdit;
    btBrowse: TButton;
    Label2: TLabel;
    lbAdobe: TLabel;
    btOK: TButton;
    btCancel: TButton;
    OpenDialog1: TOpenDialog;
    cbUserPlayer: TCheckBox;
    cbAutoRefresh: TCheckBox;
    cbLinkFPR: TCheckBox;
    cbNoOptimize: TCheckBox;
    procedure lbAdobeClick(Sender: TObject);
    procedure btOKClick(Sender: TObject);
    procedure btBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Déclarations privées }
    FLinked: Boolean;
  public
    { Déclarations publiques }
  end;

var
  OptionsForm: TOptionsForm;

implementation

uses RegEdit, Global;

{$R *.dfm}

procedure TOptionsForm.lbAdobeClick(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://www.adobe.com/support/flashplayer/downloads.html', nil, nil, SW_SHOW);
end;

procedure TOptionsForm.btOKClick(Sender: TObject);
begin
  if (edPlayer.Text = '') or FileExists(edPlayer.Text) then
  begin
    if cbLinkFPR.Checked then
    begin
      if not FLinked then
        SetFileType('FPR', 'FlashPascal Project', Application.ExeName)
    end else begin
      if FLinked then
        UnsetFileType('FPR', 'FlashPascal Project', Application.ExeName);
    end;
    ModalResult := mrOK
  end else begin
    ShowMessage('Fichier ' + edPlayer.Text + ' introuvable');
    edPlayer.SetFocus;
  end;
end;

procedure TOptionsForm.btBrowseClick(Sender: TObject);
begin
  OpenDialog1.InitialDir := ExtractFilePath(edPlayer.Text);
  if OpenDialog1.Execute then
    edPlayer.Text := OpenDialog1.FileName;
end;

procedure TOptionsForm.FormCreate(Sender: TObject);
begin
  FLinked := IsFileType('FPR', Application.ExeName);
  cbLinkFPR.Checked := FLinked;
  cbNoOptimize.Checked := NoOptimize;
end;

end.
