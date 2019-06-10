unit NewProject;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Translates;

type
  TProjectForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    edWidth: TEdit;
    Label3: TLabel;
    edHeight: TEdit;
    Label4: TLabel;
    shColor: TShape;
    Label5: TLabel;
    Button1: TButton;
    Button2: TButton;
    edFrameRate: TEdit;
    ColorDialog: TColorDialog;
    edColor: TEdit;
    procedure shColorMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
    procedure edColorChange(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  ProjectForm: TProjectForm;

implementation

{$R *.dfm}

resourcestring
  sFrameSizeError = 'Les dimensions de l''animation doivent être comprises entre 1 et 2880 pixels.';
  sFrameRateError = 'La fréquence d''affichage doit être comprise entre 1 et 120 images par secondes.';
  sColorError     = 'Veuillez indiquer une couleur RGB en hexadécimal ou cliquer sur le rectangle coloré pour en choisir une.';

function BGR2RGB(Color: Integer): Integer;
begin
  Result := Integer(Color and $FF00FF00) or ((Color and $FF) shl 16) or ((Color shr 16) and $FF);
end;

procedure TProjectForm.shColorMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ColorDialog.Color := shColor.Brush.Color;
  if ColorDialog.Execute then
  begin
    shColor.Brush.Color := ColorDialog.Color;
    edColor.Text := IntToHex(BGR2RGB(ColorDialog.Color), 6);
  end;
end;

procedure TProjectForm.Button1Click(Sender: TObject);
var
  i, e: Integer;
begin
  Val(edWidth.Text, i, e);
  if (e > 0) or (i < 1) or (i > 2880) then
  begin
    ShowMessage(sFrameSizeError);
    edWidth.SetFocus;
    Exit;
  end;
  Val(edHeight.Text, i, e);
  if (e > 0) or (i < 1) or (i > 2880) then
  begin
    ShowMessage(sFrameSizeError);
    edHeight.SetFocus;
    Exit;
  end;

  Val('$' + edColor.Text, i, e);
  if (e > 0) or (BGR2RGB(i) <> shColor.Brush.Color) then
  begin
    ShowMessage(sColorError);
    edColor.SetFocus;
    Exit;
  end;

  Val(edFrameRate.Text, i, e);
  if (e > 0) or (i < 1) or (i > 120) then
  begin
    ShowMessage(sFrameSizeError);
    edFrameRate.SetFocus;
    Exit;
  end;

  ModalResult := mrOK;
end;

procedure TProjectForm.edColorChange(Sender: TObject);
var
  i, e: Integer;
begin
  Val('$' + edColor.Text, i, e);
  if e = 0 then
    shColor.Brush.Color := BGR2RGB(i);
end;

end.
