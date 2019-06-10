unit About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ShellAPI, Translates;

type
  TAboutBox = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    lbVersion: TLabel;
    Logo: TImage;
    Bevel1: TBevel;
    Image1: TImage;
    Label3: TLabel;
    Label4: TLabel;
    Edit1: TEdit;
    Label5: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  AboutBox: TAboutBox;

function GetVersion(var A, B, C, D: Word): Boolean;

implementation

{$R *.dfm}

function GetVersion(var A, B, C, D: Word): Boolean;
var
  Mem : TMemoryStream;
  Res : TResourceStream;
  Ver : PVSFIXEDFILEINFO;
  Len : Cardinal;
begin
  Mem := TMemoryStream.Create;
  try

    Res := TResourceStream.CreateFromID(HInstance, 1, RT_VERSION);
    try
      Mem.CopyFrom(Res, Res.Size);
    finally
      Res.Free;
    end;

    if VerQueryValue(Mem.Memory, '\', Pointer(Ver), Len) then
    begin
      A := Ver.dwFileVersionMS shr 16;
      B := Word(Ver.dwFileVersionMS);
      C := Ver.dwProductVersionLS shr 16;
      D := Word(Ver.dwFileVersionLS);
      Result := True;
    end else
      Result := False;
  finally
    Mem.Free;
  end;
end;

procedure TAboutBox.FormCreate(Sender: TObject);
var
  Icon: TIcon;
begin
  lbVersion.Caption := Application.Title;
  Icon := TIcon.Create;
  try
    Icon.Handle := LoadImage(hInstance, 'MAINICON', IMAGE_ICON, 128, 128, 0);
    Logo.Picture.Assign(Icon);
  finally
    Icon.Free;
  end;
end;

procedure TAboutBox.Label2Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://flashpascal.execute.re', nil, nil, SW_SHOW);
end;

procedure TAboutBox.Image1Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://flashpascal.execute.re/paypal.php', nil, nil, SW_SHOW);
end;

procedure TAboutBox.Label3Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'mailto:contact@execute.re', nil, nil, SW_SHOW);
end;

end.
