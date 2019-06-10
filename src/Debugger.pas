unit Debugger;

interface

uses
  Windows, Messages, Winsock, SysUtils, Debug;

type
  TThread = class
    Thread : THandle;
    Msg    : string;
    function ThreadProc: Integer; virtual; abstract;
    procedure Error(const AMsg: string);
  end;

  TDebugger = class(TThread)
    Handle    : TSocket;
    Terminated: Boolean;
    constructor Create;
    destructor Destroy; override;
    function ThreadProc: Integer; override;
  end;

  TDebugMessage = record
    Len  : Cardinal;
    ID   : Cardinal;
    Data : array[Word] of Char;
  end;

  TVersion = record
    ID          : Cardinal; // $1A
    Len         : Cardinal; //   5
    majorVersion: Cardinal;
    db          : Byte;     // 4
  end;
  PVersion = ^TVersion;

  TAttr = record
    Name : string;
    Value: string;
  end;

  TField = record
    id    : Cardinal;
    Name  : string;
    Value : string;
  end;

  TPlace = record
    id   : Cardinal;
    Path : string;
  end;

  TClient = class(TThread)
    Handle: TSocket;
    Msg   : TDebugMessage;
    Form  : TDebugForm;
    constructor Create(AHandle: TSocket);
    function ThreadProc: Integer; override;
    function GetAttr: TAttr;
    function GetVersion: PVersion;
    function GetID: Cardinal;
    function GetField: TField;
    function GetPlace: TPlace;
    function GetString(id: Cardinal): string;
  end;

implementation

uses Main;

function StartMe(Sender: TThread): Integer; stdcall;
begin
  Result := Sender.ThreadProc;
end;

{ TThread }

procedure TThread.Error(const AMsg: string);
begin
  Msg := AMsg;
  SendMessage(MainForm.Handle, WM_USER, 99, Integer(Self));
end;


{ TDebugger }

constructor TDebugger.Create;
var
  wsa : TWSAData;
  Addr: TSockAddr;
  id  : Cardinal;
begin
  WSAStartup($202, wsa);
  Handle := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Handle = INVALID_SOCKET then
    raise Exception.Create('Socket error');
  FillChar(Addr, SizeOf(Addr), 0);

  Addr.sin_family := AF_INET;
  Addr.sin_port := swap(7935);
  if bind(Handle, Addr, SizeOf(Addr)) <> 0 then
    raise Exception.Create('Bind error');

  IsMultiThread := True;
  Thread := CreateThread(nil, 0, @StartMe, Self, 0, id);
end;

destructor TDebugger.Destroy;
begin
  Terminated := True;
  CloseSocket(Handle);
  inherited;
end;

function TDebugger.ThreadProc: Integer;
var
  Player: TSocket;
  Addr  : TSockAddr;
  Len   : Integer;
begin
  if listen(Handle, 0) <> 0 then
    Error('listen');
  repeat
    FillChar(Addr, SizeOf(Addr), 0);
    Addr.sin_family := AF_INET;
    Len := SizeOf(Addr);
    Player := accept(Handle, @Addr, @Len);
    if Player = INVALID_SOCKET then
    begin
      SendMessage(MainForm.Handle, WM_USER, -1, Integer(Self));
      Break;
    end;
    TClient.Create(Player);
  until Terminated;
  //SendMessage(MainForm.Handle, WM_USER, 90, Integer(Self));
  Result := 0;
end;

{ TClient }

constructor TClient.Create(AHandle: TSocket);
var
  id: Cardinal;
begin
  Handle := AHandle;
  Thread := CreateThread(nil, 0, @StartMe, Self, 0, id);
end;

function TClient.GetAttr: TAttr;
var
  P: PChar;
  L1, L2: Cardinal;
begin
  Assert(Msg.ID = $0C);
  P := @Msg.Data;
  L1 := 0;
  while (L1 <= Msg.Len) and (Msg.Data[L1] <> #0) do
    Inc(L1);
  SetString(Result.Name, P, L1);
  Inc(L1);
  Inc(P, L1);
  L2 := L1;
  while (L2 <= Msg.Len) and (Msg.Data[L2] <> #0) do
    Inc(L2);
  SetString(Result.Value, P, L2 - L1);
  Assert(Msg.Len = L2 + 1);
end;

function TClient.GetField: TField;
var
  P: PChar;
  L1: Cardinal;
begin
  Assert((Msg.ID = $0A) or (Msg.ID = $1c));
  Move(Msg.Data, Result.ID, SizeOf(Result.ID));
  P := @Msg.Data;
  L1 := SizeOf(Result.ID);
  Inc(P, L1);
  while (L1 <= Msg.Len) and (Msg.Data[L1] <> #0) do
    Inc(L1);
  SetString(Result.Name, P, L1 - SizeOf(Result.ID));
  Inc(L1);
 // Inc(P, L1);
  // AMF data Type + Flag32bits + Value
  case Ord(Msg.Data[L1]) of
    $00 : Result.Value := 'undefined';
    $01 : Result.Value := 'null';
    $02 : Result.Value := 'False';
    $03 : Result.Value := 'True';
    $04 : Result.Value := IntToStr(PInteger(@Msg.Data[L1 + 5])^);
    $05 : Result.Value := FloatToStr(PDouble(@Msg.Data[L1 + 5])^);
    $06 : Result.Value := 'string';
    $07 : Result.Value := 'xml-doc-marker';
    $08 : Result.Value := 'date';
    $09 : Result.Value := 'array()';
    $0A : Result.Value := 'object';
    $0B : Result.Value := 'xml-marker';
    $0C : Result.Value := 'bytes[]';
  end;
end;

function TClient.GetID: Cardinal;
begin
  Assert((Msg.ID = $03) or (Msg.ID = $04));
  Assert(Msg.Len = 4);
  Move(Msg.Data, Result, SizeOf(Result));
end;

function TClient.GetPlace: TPlace;
var
  P: PChar;
  L: Cardinal;
begin
  Assert(Msg.ID = $0D);
  Move(Msg.Data, Result.ID, SizeOf(Result.ID));
  P := @Msg.Data;
  L := SizeOf(Result.ID);
  Inc(P, L);
  while (L <= Msg.Len) and (Msg.Data[L] <> #0) do
    Inc(L);
  SetString(Result.Path, P, L - SizeOf(Result.ID));
  Assert(Msg.Len = L + 1);
end;

function TClient.GetString(id: Cardinal): string;
var
  L: Cardinal;
begin
  Assert(Msg.Id = id);
  L := 0;
  while (L < Msg.Len) and (Msg.Data[L] <> #0) do
    Inc(L);
  SetString(Result, Msg.Data, L);
  Assert(Msg.Len = L + 1);
end;

function TClient.getVersion: PVersion;
begin
  Assert(Msg.ID = $1A);
  Assert(Msg.Len = 5);
  Result := @Msg;
  Assert(Result.db = 4);
end;

function TClient.ThreadProc: Integer;
var
  Ptr: PChar;
  Len: Cardinal;
  Cnt: Integer;
begin
  SendMessage(MainForm.Handle, WM_USER, 1, Integer(Self));
  Len := 0;
  repeat
    Ptr := @Msg;
    Inc(Ptr, Len);
    Cnt := recv(Handle, Ptr^, SizeOf(Msg) - Len, 0);
    if Cnt <= 0 then
    begin
      Error('recv error');
      Break;
    end;
    Inc(Len, Cnt);
    while (Len >= 8) and (Len >= Msg.Len + 8) do
    begin
      SendMessage(MainForm.Handle, WM_USER, 2, Integer(Self));
      Dec(Len, Msg.Len + 8);
      if Len > 0 then
        Move(Msg.Data[Msg.Len], Msg, Len);
    end;
  until False;
  Result := 0;
end;

end.
