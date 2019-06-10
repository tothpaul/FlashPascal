unit Preview;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, ShockwaveFlashObjects_TLB, Compiler, ActiveX;

type
  TSWFForm = class(TForm)
  private
    { Déclarations privées }
    Player: TShockWaveFlash;
  public
    { Déclarations publiques }
    procedure Play(const AFileName: string);
  end;

var
  SWFForm: TSWFForm;

implementation

{$R *.dfm}

{ TSWFForm }

procedure TSWFForm.Play(const AFileName: string);
const
  IID_IPersistStreamInit : TGUID = '{7FD52380-4E07-101B-AE2D-08002B2EC713}';
var
//  MEM: TMemoryStream;
//  FIL: file;
//  siz: Integer;
  SWF: TShockWaveFlash;
//  STM: TStreamAdapter;
//  UNK: OleVariant;
//  PSI: IPersistStreamInit;
//  PTR: PCardinal;
//  i  : Integer;
begin
  ClientWidth := FrameWidth;
  ClientHeight := FrameHeight;
  SWF := TShockWaveFlash.Create(Self);
  try
    SWF.Parent := Self;
    SWF.SetBounds(0, 0, FrameWidth, FrameHeight);
   {$IFDEF STREAM}
    AssignFile(FIL, AFileName);
    Reset(FIL, 1);
    siz := FileSize(FIL);
    MEM := TMemoryStream.Create;
    MEM.Size := siz + 8;
    PTR := MEM.Memory;
    PTR^ := $55665566;
    Inc(PTR);
    PTR^ := siz;
    Inc(PTR);
    BlockRead(FIL, PTR^, Siz);
    CloseFile(FIL);
    IUnknown(SWF.OleObject).QueryInterface(IID_IPersistStreamInit, PSI);
    STM := TStreamAdapter.Create(MEM);
    PSI.Load(STM);
   {$ELSE}
    SWF.Movie := AFileName;
   {$ENDIF}
    //SWF.Play;
    SWF.Invalidate;
    Player.Free;
    Player := SWF;
  except
    SWF.Free;
  end;
end;

end.
