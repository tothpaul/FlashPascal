unit HTTP;

interface

uses
  Windows, Winsock, SysUtils;

type
  TVersionCheck = class
  private
    FVer     : string;
    FHandle  : Integer;
    FMsg     : Integer;
    FThread  : THandle;
    FVersion : string;
    FSocket  : TSocket;
    Data     : string;
    s        : string;
    procedure ThreadProc;
  public
    constructor Create(Handle, Msg: Integer; const Ver: string);
    destructor Destroy; override;
    property Version: string read FVersion;
  end;

implementation

procedure WaitOrKill(var Thread:THandle; Time: Cardinal);
begin
  if Thread = 0 then
    Exit;
  if WaitForSingleObject(Thread, Time) = WAIT_TIMEOUT then
  begin
    TerminateThread(Thread, 0);
    CloseHandle(Thread);
    Thread := 0;
  end;
end;

function StartMe(Sender: TVersionCheck): Integer; stdcall;
begin
  try
    Sender.ThreadProc;
//    Result := 0;
  finally
    CloseHandle(Sender.FThread);
    Sender.FThread := 0;
    Result := SendMessage(Sender.FHandle, Sender.FMsg, Integer(Sender), 0);
  end;
end;

function INetAddr(const Host: string): Integer;
var
  pHost  : PChar;
  HostEnt: PHostEnt;
begin
  if Host = '' then
    Result := INADDR_NONE
  else begin
    pHost := PChar(Host);
    Result := inet_addr(pHost);
    if Result = INADDR_NONE then
    begin
      HostEnt := gethostbyname(pHost);
      if HostEnt <> nil then
        Result := Integer(Pointer(HostEnt^.h_addr^)^);
    end;
  end;
end;

constructor TVersionCheck.Create(Handle, Msg: Integer; const Ver: string);
var
  id: Cardinal;
begin
  FVer    := Ver;
  FHandle := Handle;
  FMsg    := Msg;
  FThread := CreateThread(nil, 0, @StartMe, Pointer(Self), 0, id);
end;

destructor TVersionCheck.Destroy;
begin
  WaitOrKill(FThread, 5000);
  inherited;
end;

procedure TVersionCheck.ThreadProc;
var
  Addr: TSockAddr;
//  Data: string;
  p: PChar;
  l,i: Integer;
//  s: string;
begin
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(80);
{-$IFDEF RELEASE}
  Addr.sin_addr.S_addr := INetAddr('flashpascal.execute.re');
{-$ELSE}
//  Addr.sin_addr.S_addr := INetAddr('127.0.0.1');
{-$ENDIF}
  if Addr.sin_addr.S_addr = INADDR_NONE then
    exit;

  FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if FSocket = INVALID_SOCKET then
    Exit;

  if connect(FSocket, Addr, SizeOf(Addr)) <> 0 then
    Exit;

// Send request
{-$IFDEF RELEASE}
  Data := 'POST /version.php HTTP/1.0'#13#10+
          'Host: flashpascal.execute.re'#13#10+
{-$ELSE}
//  Data := 'POST /flashpascal.execute.re/version.php HTTP/1.0'#13#10+
 //         'Host: 127.0.0.1'#13#10+
{-$ENDIF}
          'Content-Length: ' + IntToStr(Length(FVer) + 2) + #13#10 +
          'Content-Type: application/x-www-form-urlencoded'#13#10+
          #13#10+
          'V=' + FVer;

  p := @Data[1];
  l := Length(Data);
  while l > 0 do
  begin
    i := send(FSocket, p^, l, 0);
    if i <= 0 then
      Exit;
    Inc(p, i);
    Dec(l, i);
  end;
// Read reply
  Data := '';
  SetLength(s, 512);
  repeat
    i := recv(FSocket, s[1], 512, 0);
    if i > 0 then Data := Data + Copy(s, 1, i);
  until i <= 0;
// parse reply
  Val(Copy(Data, Pos(' ', Data), Pos(#13#10, Data)), i, l);
  if i <> 200 then
    Exit;
  i := Pos(#13#10#13#10, Data);
  if i = 0 then
    Exit;
 // AllocConsole;
 // WriteLn(Data);
  FVersion := Copy(Data, i + 4, MaxInt);
//  WriteLn(FVersion);
end;

procedure WSAStartup;
var
  wsa: TWSAData;
begin
  Winsock.WSAStartup($101, wsa);
end;

initialization
  WSAStartup;
end.

