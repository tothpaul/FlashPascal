unit Source;

{ FlashPascal (c)2012 Execute SARL }

interface

{$I FlashPascal.inc}

uses
  Windows, SysUtils, Global;

type
  EndOfFile = class(Exception)
  end;
  
  TSourceProvider = class
    FileName: string;
    function EOF: Boolean; virtual; abstract;
    function ReadChar: Char; virtual; abstract;
  end;

  CompilerException = class(Exception)
  private
    FNum     : string;
    FRow     : Integer;
    FCol     : Integer;
    FFileName: string;
  public
    constructor Create(ANum: string; ARow, ACol: Integer; const AFileName, AMsg: string);
    property FileName: string read FFileName;
    property Num: string read FNum;
    property Row: Integer read FRow;
    property Col: Integer read FCol;
  end;

  TFileProvider = class(TSourceProvider)
  private
    FHandle  : TextFile;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    function EOF: Boolean; override;
    function ReadChar: Char; override;
  end;

  TSource = class
    Provider : TSourceProvider;
    Line     : Integer;  // current line
    Index    : Integer;  // current char in line
    Src      : string;   // current readed line
    SrcToken : string;   // current token
    LastChar : Char;     // last readed char
    NextChar : Char;     // current readed char (next in token)
    CharAfter: Char;
    Token    : string;   // current token (uppercase for keywords, without quotes for litteral strings)
    constructor Create(AProvider: TSourceProvider);
    destructor Destroy; override;
    function StrToInt(const Str: string): Integer;
    function BitsCount(const Str: string): Integer;
    procedure Error(const Num, Msg: string; Symbol: TSymbol = nil);
    procedure Warning(const Msg, Fnc: string);
    function ReadChar: Char;
    function SkipChar(c: Char): Boolean;
    function StringConst: string;
    function AsciiChar: string;
  end;

implementation

constructor TSource.Create(AProvider: TSourceProvider);
begin
  Provider := AProvider;
  Src := '';
  Line := 1;
  Index := 0;
  NextChar := ' ';
  CharAfter := ' ';
  ReadChar;
end;

destructor TSource.Destroy;
begin
  Provider.Free;
end;

// convert Str to an integer
function TSource.StrToInt(const Str: string): Integer;
var
  e: Integer;
begin
  Val(Str, Result, e);
  if e > 0 then
    Error('S0088', 'Invalid number'); // 'Invalid number '+str
end;

// how many bits to store this numeric ?
function TSource.BitsCount(const Str:string):integer;
begin
 Result := -1; // remove warning
 case Length(Str) of
  0    : Error('S0095', 'Invalid number');
  1..2 : Result:=8;
  3    : if StrLess(Str,'255') then Result:=8 else Result:=16;
  4    : Result:=16;
  5    : if StrLess(Str,'65535') then Result:=16 else Result:=32;
  else   if StrLess(Str,'4294967295') then
           Result:=32
         else
           Error('S0103', 'Cardinal overflow');
 end;
end;

procedure TSource.Error(const Num, Msg:string; Symbol: TSymbol = nil); // error message, function id
var
  i:integer;
  ch:Char;
begin
  if DisplayErrors then
  begin
    Write(Provider.Filename,'(',Line,',',Index-Length(SrcToken),') Error: ',Msg);
    {if Fnc<>'' then WriteLn(' (',Fnc,')') else} WriteLn;
    if DisplaySourceOnErrors then begin
      //Ch:=#0;
      {$I-}
      while(not Provider.EOF)do begin // get the full line of source code
        Ch := Provider.ReadChar;
        //if IOResult<>0 then FatalError('Cannot read file '+_FileName,'Error');
        Src:=Src+Ch;
      end;
      {$I+}
      WriteLn(Src);
      for i:=1 to Index-1-Length(SrcToken) do Write(' ');
      for i:=1 to Length(SrcToken) do Write('^');
    end;
  end;
  //Halt(1);// programming error
  if Symbol = nil then
    raise CompilerException.Create(Num, Line, Index - Length(SrcToken), Provider.FileName, Msg)
  else
    raise CompilerException.Create(Num, Symbol.Row, Symbol.Col, Symbol.FileName, Msg)
end;

procedure TSource.Warning(const Msg,Fnc:string); // warning message, function id
begin
  if DisplayWarnings then begin
    Write(Provider.Filename,'(',Line,',',Index-Length(SrcToken),') Warning: ',Msg);
    {if Fnc<>'' then WriteLn(' (',Fnc,')') else} WriteLn;
  end;
end;
(*
procedure TSource.Note(const Msg:string); // message
begin
  if DisplayNotes then WriteLn(_Filename,'('{,Line,',',Index-Length(SrcToken),}') Note: ',Msg);
end;
*)
// read one char
function TSource.ReadChar:char;
  procedure NewLine;
  begin
    Inc(Line);
    Index:=0;
  end;
begin
  if NextChar = #27 then
  begin
    Inc(Index);
    SrcToken := ' '; //to show the buggy source correctly
    Error('S0158', 'Unexpected end of file');
  end;
  SrcToken := SrcToken + NextChar;
  LastChar := NextChar;
  Result := NextChar;
{$I-}
  NextChar := CharAfter;
  if Provider.Eof then
    CharAfter := #27
  else
    CharAfter := Provider.ReadChar;
{$I+}
 {$IFDEF LOG}Write(NextChar);{$ENDIF}
//******************************************************************************
//* support of all kind of new line markers of all kind of operating systems :)
//******************************************************************************
  if (NextChar = #10) and (LastChar = #13) then
  begin {Windows}
    NewLine;
  end else
  if (NextChar = #10) and ( LastChar <> #13) then
  begin {Unix/Linux}
    NewLine;
  end else begin
    if (LastChar = #13) {and(NextChar<>#10)} then
      NewLine; {MacOSX's new line checking - must be here}
//******************************************************************************
    Inc(Index);
    if NextChar <> #27 then
    begin
      if Index = 1 then
        Src := NextChar
      else
        Src := Src + NextChar;
    end;
  end;
end;

// skip one char ?
function TSource.SkipChar(c:char):boolean;
begin
 Result:=NextChar=c;
 if Result then ReadChar;
end;

// read a quoted string
function TSource.StringConst: string;
var
  quote: Char;
  done : Boolean;
begin
  quote := ReadChar; // ''''
  Result := '';
  repeat
    while NextChar <> quote do
    begin
      if NextChar in [#10,#13] then
        Error('S0206', 'Open string');
      Result := Result + ReadChar;
    end;
    ReadChar; // ''''
    if NextChar = quote then
    begin
      Result := Result + ReadChar;
      done := False;
    end else begin
      done := True;
    end;
  until done;
end;

// read an ascii char value (#xxx) - this code is NOT MULTIMYTE friendly yet (UCS-2/UTF-8)
function TSource.AsciiChar:string;
begin
  ReadChar; // #
  Result:='';
  if NextChar = '$' then
  begin
    repeat
      Result := Result + ReadChar;
    until not (NextChar in ['0'..'9','a'..'z','A'..'Z']);
    if Length(Result) > 3 then
      Error('S0231', 'Byte overflow');
  end else begin
    while NextChar in ['0'..'9'] do Result:=Result+ReadChar;
    if BitsCount(Result) > 8 then
      Error('S0235', 'Byte overflow');
  end;
  Result := Chr(StrToInt(Result));
end;

{ TFileProvider }

constructor TFileProvider.Create(const AFileName: string);
begin
  FileName := AFileName;
 {$I-}
  AssignFile(FHandle, FileName);
  Reset(FHandle); // not existing or locked files raised exception here...
  if IOResult <> 0 then
    //FatalError('Cannot open file ' + FFileName, 'Source');
    raise Exception.Create('Cannot open file ' + FileName);
 {$I+}
end;

destructor TFileProvider.Destroy;
begin
  CloseFile(FHandle);
  inherited;
end;

function TFileProvider.EOF: Boolean;
begin
  Result := System.EOF(FHandle);
end;

function TFileProvider.ReadChar: Char;
begin
  Read(FHandle, Result);
end;

{ CompilerException }

constructor CompilerException.Create(ANum: string; ARow, ACol: Integer; const AFileName,
  AMsg: string);
begin
  FNum := ANum;
  FRow := ARow;
  FCol := ACol;
  FFileName := AFileName;
  inherited Create(AMsg);
end;

initialization
  {$IFDEF LOG}AllocConsole;{$ENDIF}
end.
