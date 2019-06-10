unit InfoBulles;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ShellAPI, Math;

type
  TInfoBulle = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Timer : TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    FDelay: Integer;
    FClick: TNotifyEvent;
    procedure GoWeb;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public declarations }
    procedure Say(const s1, s2: string; Delay: Integer = 3000; Click: TNotifyEvent = nil);
  end;

var
  InfoBulle: TInfoBulle;

implementation

uses main;

{$R *.dfm}

procedure TInfoBulle.CreateParams(var Params:TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST or WS_EX_TOOLWINDOW;
  Params.WndParent := GetDesktopWindow;
end;

procedure TInfoBulle.FormCreate(Sender: TObject);
begin
  Top := Screen.WorkAreaHeight;
  Left := Screen.WorkAreaWidth-Width;
end;

procedure TInfoBulle.FormPaint(Sender: TObject);
begin
  Canvas.Rectangle(0, 0, Width, Height);
  Canvas.Draw(6, 6, Application.Icon);
end;

procedure TInfoBulle.Say(const s1, s2: string; Delay: Integer = 3000; Click: TNotifyEvent = nil);
begin
  Height := 0;
  FDelay := Delay;
  FClick := Click;
  Visible := True;
  Label1.Caption := s1;
  Label2.Caption := s2;
  Width := Max(Width, Label1.Left + Label1.Width) + 4;
  Label2.Width := Width - Label2.Left - 4;
  Left := Screen.WorkAreaWidth - Width;
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
  Timer.Tag := 0;
  Timer.Interval := 10;
  Timer.Enabled := True;
end;

procedure TInfoBulle.TimerTimer(Sender: TObject);
begin
  case Timer.Tag of
    0:
    begin
      Height := Height + 2;
      Top := Screen.WorkAreaHeight - Height;
      if ClientHeight >= 52 then
      begin
        Timer.Tag := 1;
        if FDelay < 0 then
          Timer.Enabled := False
        else
          Timer.Interval := FDelay;
      end;
      Invalidate;
    end;
    1:
    begin
      Timer.Tag := 2;
      Timer.Interval := 10;
    end;
    2:
    begin
      Height := Height - 2;
      Top := Screen.WorkAreaHeight - Height;
      if ClientHeight <= 0 then
      begin
        Timer.Enabled := False;
        Release;
      end else
        Invalidate;
    end;
  end;
end;

procedure TInfoBulle.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
  begin
    if Assigned(FClick) then
    begin
      try
        FClick(Self);
      except
        GoWeb;
      end;
    end else begin
      GoWeb;
    end;
  end;
  Timer.Tag := 2;
  Timer.Interval := 10;
  Timer.Enabled := True;
end;

procedure TInfoBulle.GoWeb;
begin
  ShellExecute(0, nil, 'http://flashpascal.execute.re', nil, nil, SW_SHOW);
end;

end.

