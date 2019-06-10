unit HTML;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Translates;

type
  THTMLForm = class(TForm)
    mmHTML: TMemo;
    btnCopy: TButton;
    bntClose: TButton;
    SaveDialog1: TSaveDialog;
    btnSave: TButton;
    cbHTMLHeader: TCheckBox;
    procedure btnCopyClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cbHTMLHeaderClick(Sender: TObject);
  private
    { Déclarations privées }
    FFile: string;
    procedure DoCode;
  public
    { Déclarations publiques }
    procedure Show(const AFileName: string);
  end;

var
  HTMLForm: THTMLForm;

implementation

uses Compiler;

{$R *.dfm}

procedure THTMLForm.Show(const AFileName: string);
begin
  FFile := ExtractFileName(AFileName);
  SaveDialog1.InitialDir := ExtractFilePath(AFileName);
  SaveDialog1.FileName := ChangeFileExt(FFile, '.htm');
  DoCode;
  ShowModal;
end;

procedure THTMLForm.btnCopyClick(Sender: TObject);
begin
  mmHTML.SelectAll;
  mmHTML.CopyToClipboard;
end;

procedure THTMLForm.btnSaveClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    mmHTML.Lines.SaveToFile(SaveDialog1.FileName);
end;

procedure THTMLForm.cbHTMLHeaderClick(Sender: TObject);
begin
  DoCode;
end;

procedure THTMLForm.DoCode;
begin
  if cbHTMLHeader.Checked then
    mmHTML.Text :=
      '<!DOCTYPE html>'#13#10+
      '<html>'#13#10+
      '  <head>'#13#10+
      '   <title>FlashPascal</title>'#13#10+
      '  </head>'#13#10+
      '  <body bgcolor="#8B8B8B">'#13#10+
      '  <center>'#13#10+
      '    <embed type="application/x-shockwave-flash" src="' + FFile + '" width="' + IntToStr(FrameWidth) + '" height="' + IntToStr(FrameHeight) + '"/>'#13#10+
      '  </center>'#13#10+
      '  </body>'#13#10+
      '</html>'
  else
    mmHTML.Text :=
      '<embed type="application/x-shockwave-flash" src="' + FFile + '" width="' + IntToStr(FrameWidth) + '" height="' + IntToStr(FrameHeight) + '"/>';
end;

end.
