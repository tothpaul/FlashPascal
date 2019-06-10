unit Parser;

{ FlashPascal (c)2012 Execute SARL }

interface

uses
  SysUtils, Math, Global, Source, SWF;

{$I FlashPascal.inc}

type
  TTokens = set of TToken;

  TValueType = (
    vtNone,
    vtNil,
    vtBoolean,
    vtInteger,
    vtFloat,
    vtString,
    vtArray,
    vtSet
  );

  TConstantValue = record
    ValueType: TValueType;
    AsInt64  : Int64;
    AsFloat  : Extended;
    AsString : string;
    AsArray  : string; // init Code
  end;

  TVariable = class(TSymbol)
    Kind    : TSymbol;
    Owner   : TSymbol; // nil for Global var...
    Reg     : Byte;
    Externe : Boolean;
    IsSet   : Boolean;
  end;

  TConstant = class(TSymbol)
    Value : TConstantValue;
    Kind  : TSymbol;
    function GetInteger(var Value: Integer): Boolean;
  end;

  TParameter = class(TSymbol)
    IsConst  : Boolean; // not used for now
    IsParent : Boolean; // use _root instead of nil
    ByRef    : Integer; // 1, 2, ..
    Kind     : TSymbol;
    Default  : string;
    Reg      : Byte;
    NextParam: TParameter;
    function Clone: TParameter;
  end;

  TClassDef = class;

  TPrototype = class;

  TProperty = class(TSymbol)
    Static   : Boolean; // class property
    Kind     : TSymbol;
    ReadOnly : Boolean;
    WriteOnly: Boolean;
    Deprecate: Boolean;
    Owner    : TClassDef;
    Proto    : TPrototype; // property name[params] read f(params) write f(params)
    OnGet    : TSymbol;
    OnSet    : TSymbol;
    destructor Destroy; override;
  end;

  TStructure = class(TSymbol)
    Scope       : TScope;
    Init1       : string;    // initialization code for this class
    destructor Destroy; override;
  end;

  TPrototype = class(TSymbol)
    params  : TParameter;
    count   : Integer;
    regs    : Integer;
    Kind    : TSymbol;   // function result (double emploi avec Return.Kind ?)
    Return  : TVariable;
    OfObject: Boolean;   // function/procedure prototype only (procedure at this time)
    ByRefs  : Integer;
  end;

  TFunction = class(TStructure)
    proto    : TPrototype;
    NeedRoot : Boolean;
    destructor Destroy; override;
    function DeclareFunction(Flags: Word; const Name, Code: string): string;
  end;

  TMethod = class(TFunction)
    static    : Boolean;    // class procedure
    IsVirtual : Boolean;
    IsAbstract: Boolean;
    IsEmpty   : Boolean;
    alias     : string;     // alias used for MovieClip.createTextField()
    Parent    : TParameter; // MovieClip in this case
    code      : string;     // for UserClass only
    Owner     : TClassDef;
    //Symbols  : TSymbol;    // local symbols
    Externe   : string;     // like Math.floor
    SysCall   : Byte;       // like: function getTimer(): Number external 52;
    IsConstructor: Boolean;
    LocalName : string; // onRelease et non TMonClip$onRelease
    NextMethod: TMethod; // Linked list of classes methods
    NeedParent: Boolean;
    destructor Destroy; override;
    function LastParm: TParameter;
    function Definition(Flags: Word = FLAG_7): string;
    function Declaration: string;
  end;

  TReference = class(TSymbol)
    Done     : Boolean;
    Structure: TStructure; // TRecord or TClassDef
  end;

  TVisibility = (sPrivate, sProtected, sPublic);

  TClassDef = class(TStructure)
    _external   : Boolean;   // usefull only for external forwarded classes : type ClassName = external class;
    userClass   : Boolean;   // non-external class
    _forward    : Boolean;   // forward declaration
    _inherite   : TClassDef; // class(_inherite)
    _constructor: TMethod;   // todo: support multiple constructors (overload also)
    //_symbols    : TSymbol;   // members
    visibility  : TVisibility;
    Reference   : TReference;
    Default     : TProperty;
    InitProto   : string;
    Methods     : TMethod; // Linked list of Methods
    destructor Destroy; override;
    function GetSymbol(const AName: string; var AToken: TToken): Boolean;
    function Aliased: Boolean;
    procedure BuildCode;
  end;

  TParser = class(TSource)
    TokenType    : TToken;  // what kind of token is it ?
    FCurrentClass: TClassDef;  // set while parsing a method code
    FDepth       : Integer;
    procedure GetDigits;
    procedure AlphaToken;
    procedure NumericToken;
    procedure StringToken;
    procedure SymbolToken;
    procedure HexaToken;
    procedure GetToken;
    procedure NextToken; virtual;
    function TokenIndex(ATokens: TTokens): TToken;
    function TokenSymbol(AScope: PScope = nil): TToken;
    function SkipToken(AToken: TToken): Boolean;
    procedure DropToken(Token: TToken);
    procedure DropIdent(const Ident: string);
    function GetIdent: string;
    function GetInteger: Integer;
    function GetConstantValue(Level: Integer = 0): TConstantValue;
    procedure AddConstantValue(var Value: TConstantValue);
    procedure SubConstantValue(var Value: TConstantValue);
    procedure MulConstantValue(var Value: TConstantValue);
    procedure DivIntConstantValue(var Value: TConstantValue);
    procedure DivRealConstantValue(var Value: TConstantValue);
    procedure ShlConstantValue(var Value: TConstantValue);
  end;

var
// Symbols :TSymbol; // chained list of symbols

 Symbol  :TSymbol; // token symbol

implementation

uses Compiler;

const
  TokenNames : array[tkProgram .. tkTrace] of string = (
    'PROGRAM',
    'USES', 'IN', 'UNIT', 'INTERFACE', 'IMPLEMENTATION',
    'VAR', 'TYPE', 'CONST',
    'BEGIN', 'END',
    'PROCEDURE', 'FUNCTION',
    'EXTERNAL',
    'CLASS', 'CONSTRUCTOR', 'AS',
    'PRIVATE', 'PROTECTED', 'PUBLIC',
    'PROPERTY', 'READONLY', 'WRITEONLY', 'READ', 'WRITE', 'DEFAULT',
    'DEPRECATED',
    'NIL',
    'DIV', 'MOD',
    'TRUE', 'FALSE',
    'IF', 'THEN',
    'FOR', 'TO', 'DOWNTO', 'DO', 'WITH',
    'ARRAY', 'OF', 'RECORD', 'SET',
    'OBJECT',
    'INHERITED', 'VIRTUAL', 'OVERRIDE', 'ABSTRACT',
    'SELF',
    'CASE', 'ELSE',
    'REPEAT', 'UNTIL',
    'WHILE',
    'OR', 'AND',
    'XOR', 'NOT',
    'SHL', 'SHRI', 'SHR',
    'EXIT',
   // const
    'FLOOR', 'SQRT',
   // built in functions
    'INTTOSTR', 'FLOATTOSTR', 'TRUNC', 'SORT',
    'POS', 'COPY', 'LENGTH', 'ORD', 'CHR', 'INC', 'DEC',
    'BOOLTOSTR', 'HIGH', 'LOW', 'ABS', 'INCLUDE', 'EXCLUDE',
    'TRACE'
  );

{ TConstant }

function TConstant.GetInteger(var Value: Integer): Boolean;
begin
  Result := Self.Value.ValueType = vtInteger;
  if Result then
    Value := Self.Value.AsInt64;
end;

{ TParameter }

function TParameter.Clone:TParameter;
begin
  Result := TParameter.Create(tk_Parameter);
  Result.IsConst := IsConst;
  Result.ByRef := ByRef;
  Result.Kind := Kind;
  Result.default := Default;
  Result.Reg := Reg;
  Result.name := name;
  Result.realName := realName;
  Result.codeName := codeName;
end;

{ TClassDef }

destructor TClassDef.Destroy;
//var
//  s: TSymbol;
begin
  {s := _symbols;
  while s <> nil do
  begin
    _symbols := s.NextSymbol;
    s.Free;
    s := _symbols;
  end;}
  inherited;
end;

function TClassDef.GetSymbol(const AName: string; var AToken: TToken): Boolean;
var
  AClass: TClassDef;
begin
  AClass := Self;
  repeat
    Symbol := AClass.Scope.Symbol;
    while Symbol <> nil do
    begin
      if Symbol.Name = AName then
      begin
        AToken := Symbol.Token;
        Result := True;
        Exit;
      end;
      Symbol := Symbol.NextSymbol;
    end;
    AClass := AClass._inherite;
  until AClass = nil;
  Result := False;
end;

function TClassDef.Aliased: Boolean;
var
  cl: TClassDef;
begin
  Result := True;
  cl := Self;
  while cl <> nil do
  begin
    if cl.userClass = False then
    begin
      if cl._constructor <> nil then
      begin
        if cl._constructor.alias <> '' then
          Exit;
      end;
    end;
    cl := cl._inherite;
  end;
  Result := False;
end;

procedure TClassDef.BuildCode;
var
  Method: TMethod;
  Extends: string;
begin
// todo: better solution
  if _constructor = nil then
    Exit;

  if Aliased then
  begin
    //CodeItem.Code := _constructor.Definition;
    Exit;
  end;

  {
  CodeItem.Code :=
    SWFPushString('_global') + acGetVariable
  + SWFPushString(CodeName)
  + _constructor.Declaration
  + SWFSetRegister(1)
  + acSetMember;
  }
  CodeItem.Code :=
    _constructor.Definition
  + SWFPushString(_constructor.CodeName)
  + acGetVariable
  + SWFSetRegister(1);

  if _inherite <> nil then
  begin
    if _inherite.userClass then
      Extends := _inherite._constructor.CodeName
    else
      Extends := _inherite.CodeName;
    CodeItem.Code := CodeItem.Code + SWFOptimize(SWFGetRegister(1) + SWFPushString(Extends)) + acGetVariable + acExtends;
  end;

  Method := Methods;
  if Method <> nil then
  begin
    CodeItem.Code := CodeItem.Code + SWFOptimize(SWFGetRegister(1) + SWFPushString('prototype')) + acGetMember + SWFSetRegister(2);
    repeat
      if Method.IsAbstract = False then
        CodeItem.Code := CodeItem.Code + SWFOptimize(SWFGetRegister(2) + SWFPushString(Method.localName)) +  Method.Declaration + acSetMember;
      Method := Method.NextMethod;
    until Method = nil;
  end;

  // class definition
  (*
  CodeItem.Code :=
    SWFPushString('_global') + acGetVariable
  + SWFPushString(CodeName) + acGetMember
  + acLogicalNot
  + acLogicalNot
  + BranchIfEq(Length(CodeItem.Code))
  + CodeItem.Code;
  *)
end;

{ TFunction }

function TFunction.DeclareFunction(Flags: Word; const Name, Code: string): string;
var
 s,ss: string;
 p :TParameter;
begin
  s := Name + #0
     + SWFshort(proto.count)
     + chr(proto.regs + 1)
     + SWFshort(Flags);
  p := proto.params;
  ss := '';
  while p <> nil do
  begin
    ss := {$IFDEF REG_PARAM}chr(p.Reg) + p.codeName {$ELSE}#0 + p.codeName {$ENDIF} + #0 + ss;
    p := p.NextParam;
  end;

  s := s + ss + SWFshort(Length(code));

  Result := acDeclareFunction7 + SWFshort(Length(s)) + s + code;
end;

destructor TFunction.Destroy;
//var
//  p: TParameter;
begin
(*
  p := Params;
 {$IFDEF GARBAGE}
  if Garbage = nil then
    p := nil;
 {$ENDIF}
  while p <> nil do
  begin
    Params := p.NextParam;
    p.Free;
    p := Params;
  end;
 *)
  inherited;
end;

{ TMethod }

function TMethod.Definition(Flags: Word = FLAG_7): string;
begin
  Result := DeclareFunction(Flags, CodeName, Code);
end;

function TMethod.Declaration: string;
begin
  Result := DeclareFunction(FLAG_7, '', Code);
end;

destructor TMethod.Destroy;
begin
{$IFDEF GARBAGE}
//  if Garbage <> nil then
{$ENDIF}
//  Parent.Free;
  proto.Free;
  inherited;
end;

function TMethod.LastParm: TParameter;
begin
  Result := proto.Params;
  if Result <> nil then
  begin
    while Result.NextParam <> nil do
      Result := Result.NextParam;
  end;
end;

{ TParser }

procedure TParser.GetDigits;
begin
  while NextChar in ['0'..'9'] do
    Token := Token + ReadChar;
end;

// read an alpha token
procedure TParser.AlphaToken;
//var
//  scope: PScope;
begin
  TokenType := tk_Ident;
  while UpCase(NextChar) in ['_','A'..'Z','0'..'9'] do
  begin
    Token := Token + UpCase(ReadChar);
  end;
end;

// read a numeric token
procedure TParser.NumericToken;
begin
  TokenType := tk_Number;
  GetDigits;
  if (NextChar = '.') and (CharAfter <> '.') then
  begin
    TokenType := tk_Float;
    Token := Token + DecimalSeparator;
    ReadChar;
    GetDigits;
  end;
  if (NextChar = 'e') and (CharAfter in ['+', '-', '0'..'9']) then
  begin
    TokenType := tk_Float;
    Token := Token + ReadChar;
    if NextChar in ['+', '-'] then
      Token := Token + ReadChar;
    GetDigits;
  end;
end;

// read a string made of litterals and ascii chars
procedure TParser.StringToken;
begin
  TokenType := tk_String;
  while NextChar in ['#','''','"'] do
  begin
    case NextChar of
      '#': Token := Token + AsciiChar;
      '"': Token := Token + UTF8Encode(StringConst);
      else Token := Token + StringConst;
    end;
  end;
end;

// get a special symbol
procedure TParser.SymbolToken;
begin
  case ReadChar of
    '=' : TokenType := tk_EQ;
    '>' :
      if SkipChar('=') then
        TokenType := tk_GE
      else
        TokenType := tk_GT;
    '<' :
      if SkipChar('=') then
        TokenType:=tk_LE
      else
      if SkipChar('>') then
        TokenType := tk_NE
      else
        TokenType := tk_LS;
    '+' : TokenType := tk_Add;
    '-' : TokenType := tk_Sub;
    '*' : TokenType := tk_Mul;
    '.' :
      if SkipChar('.') then
        TokenType := tk_Range
      else
        TokenType := tk_Dot;
    ',' : TokenType := tk_Comma;
    ':' :
      if SkipChar('=') then
        TokenType := tk_Assign
      else
        TokenType := tk_Colon;
    ';' : TokenType := tk_SemiColon;
    '(' :
      if SkipChar('*') then
        TokenType := tk_LComment2
      else
        TokenType := tk_LParen;
    ')' : TokenType := tk_RParen;
    '{' :
      if SkipChar('$') then
        TokenType := tk_Switch1
      else
        TokenType := tk_LComment1;
    '}' : TokenType := tk_RComment1;
    '[' : TokenType := tk_LBracket;
    ']' : TokenType := tk_RBracket;
    '/' :
      if SkipChar('/') then
        Tokentype := tk_Comment
      else
        TokenType := tk_Slash;
  else
    Error('P0529', 'Unknown symbol ' + LastChar);
  end;
  Token := SrcToken; // case insensitive
end;

// get an hexadecimal number
procedure TParser.HexaToken;
begin
  TokenType := tk_Number;
  Token := ReadChar;
  while UpCase(NextChar) in ['0'..'9','A'..'F'] do
  begin
    Token := Token + UpCase(ReadChar);
  end;
  if Length(Token) > 9 then
    Error('P0544', 'Ordinal overflow');
end;

// get the next token
procedure TParser.GetToken;
begin
  while NextChar <= #32 do
    ReadChar;
  SrcToken := '';
  Token := '';
  case NextChar of
    '_', 'a'..'z',
    'A'..'Z'     : AlphaToken;
    '0'..'9'     : NumericToken;
    '$'          : HexaToken;
    '#','''','"' : StringToken;
    else           SymbolToken;
  end;
end;

// get the next token, handle compiler switch & comments
procedure TParser.NextToken;
begin
  GetToken;
  case TokenType of
    tk_Comment :
    begin
      repeat
      until ReadChar in [#10,#13];
      NextToken;
    end;
    tk_LComment1 :
    begin
      repeat
      until ReadChar = '}';
      NextToken;
    end;
    tk_LComment2 :
    begin
      repeat
        repeat
        until ReadChar = '*';
      until NextChar = ')';
      ReadChar;
      NextToken;
    end;
  end;
end;

function TParser.TokenIndex(ATokens: TTokens): TToken;
var
  cToken: TToken;
begin
  if TokenType = tk_Ident then
  begin
    for cToken := Low(TokenNames) to High(TokenNames) do
    begin
      if (cToken in ATokens) and (Token = TokenNames[cToken]) then
      begin
        TokenType := cToken;
        Break;
      end;
    end;
  end;
  Result := TokenType;
end;

function TParser.TokenSymbol(AScope: PScope = nil): TToken;
var
  cSymbol: TSymbol;
begin
  FDepth := 0;
  // Check for local scope symbols
  if AScope = nil then
    AScope := Scopes;
  while AScope <> nil do
  begin
    cSymbol := AScope.Symbol;
    while cSymbol <> nil do
    begin
      if cSymbol.name = Token then
      begin
        Symbol := cSymbol;
        TokenType := Symbol.Token;
        Result := TokenType;
        Exit;
      end;
      if (cSymbol is TReference) and (TReference(cSymbol).Done) and (TReference(cSymbol).Structure is TClassDef) then
      begin
        if TClassDef(TReference(cSymbol).Structure).GetSymbol(Token, TokenType) then
        begin
          Result := TokenType;
          Exit;
        end;
      end;
      if cSymbol is TUnit then
      begin
        if TUnit(cSymbol).Source.GetUnitSymbol(Token, TokenType) then
        begin
          Result := TokenType;
          Exit;
        end;
      end;
      cSymbol := cSymbol.NextSymbol;
    end;
    Inc(FDepth, AScope.Step);
    AScope := AScope.Next;
  end;
  Result := TokenType;
end;

// skip a token
function TParser.SkipToken(AToken: TToken): Boolean;
begin
  Result := (TokenType = AToken) or ((AToken in [tkProgram..tkTrace]) and (Token = TokenNames[AToken]));
  if Result then
    NextToken;
end;

// request a token
procedure TParser.DropToken(Token: TToken);
begin
  if not SkipToken(Token) then
    Error('P0702', 'Unexpected token drop');
end;

procedure TParser.DropIdent(const Ident: string);
begin
  if Token <> Ident then
    Error('P0675', Ident + ' expected');
  NextToken;
end;

// request an ident
function TParser.GetIdent: string;
begin
  if TokenType <> tk_Ident then
  begin
    if Symbol = nil then
      Error('P0685', 'Ident expected');
    if {(TokenType in [tk_Variable, tk_Class, tk_Symbol]) and} (Symbol.Level <> Scopes) then
   // ok
    else
      Error('P0689', 'Ident expected');
  end;
  Result := Token;
  NextToken;
end;

function TParser.GetInteger: Integer;
var
  Value: TConstantValue;
begin
  Value := GetConstantValue;
  if Value.ValueType <> vtInteger then
    Error('P0701', 'Integer expected');
  Result := Value.AsInt64;
end;

function TParser.GetConstantValue(Level: Integer = 0): TConstantValue;
const
  Ops: array[0..2] of TTokens = (
    [tk_EQ, tk_NE, tk_LS, tk_GT, tk_LE, tk_GE], // tkIN, tkIS
    [tk_ADD, tk_SUB, tkOR, tkXOR],
    [tk_MUL, tk_SLASH, tkDIV, tkMOD, tkAND, tkSHL] // tkSHR, tkAS
    // tkAT, tkNOT
  );
var
  Done: Boolean;
begin
  if Level = 3 then
  begin
    case TokenType of

      tk_Add:
      begin
        NextToken;
        Result := GetConstantValue;
        if not (Result.ValueType in [vtInteger, vtFloat]) then
          Error('P0734', 'Not a number');
      end;

      tk_Sub:
      begin
        NextToken;
        Result := GetConstantValue;
        case Result.ValueType of
          vtInteger: Result.AsInt64 := - Result.AsInt64;
          vtFloat  : Result.AsFloat := - Result.AsFloat;
        else
          Error('P0729', 'Integer expected');
        end;
      end;

      tk_Number:
      begin
        Result.ValueType := vtInteger;
        Result.AsInt64 := StrToInt(Token);
        NextToken;
      end;

      tk_Float:
      begin
        Result.ValueType := vtFloat;
        Result.AsFloat := StrToFloat(Token);
        NextToken;
      end;

      tk_String:
      begin
        Result.ValueType := vtString;
        Result.AsString := Token;
        NextToken;
      end;

      tk_LParen:
      begin
        NextToken;
        Result := GetConstantValue;
        DropToken(tk_RParen);
      end;

      tk_Ident:
      begin

        case TokenIndex([tkNil, tkTrue, tkFalse, tkFloor, tkSqrt]) of

          tkNil   :
          begin
            NextToken;
            Result.ValueType := vtNil;
          end;

          tkTrue  :
          begin
            NextToken;
            Result.ValueType := vtBoolean;
            Result.AsInt64 := 1;
          end;

          tkFalse :
          begin
            NextToken;
            Result.ValueType := vtBoolean;
            Result.AsInt64 := 0;
          end;

          tkFloor :
          begin
            NextToken;
            DropToken(tk_LParen);
            Result := GetConstantValue;
            if Result.ValueType <> vtInteger then
            begin
              if Result.ValueType <> vtFloat then
                Error('P0795', 'Float expected');
              Result.AsInt64 := Floor(Result.AsFloat);
              Result.ValueType := vtInteger;
            end;
            DropToken(tk_RParen);
          end;

          tkSqrt :
          begin
            NextToken;
            DropToken(tk_LParen);
            Result := GetConstantValue;
            if not (Result.ValueType in [vtInteger, vtFloat]) then
              Error('P0823', 'Number expected');
            if Result.ValueType = vtInteger then
            begin
              Result.ValueType := vtFloat;
              Result.AsFloat := Result.AsInt64;
            end;
            Result.AsFloat := Sqrt(Result.AsFloat);
            DropToken(tk_RParen);
          end;

        else
          case TokenSymbol of
            tk_Constant:
            begin
              Result := TConstant(Symbol).Value;
              NextToken;
            end;
          else
            Error('P0739', 'Unexpected symbol');
          end;
        end;
      end; // tk_Ident

    else
      Error('P0814', 'Unexpected symbol');
    end;
  end else begin
    Result := GetConstantValue(Level + 1);
    repeat
      Done := False;
      TokenIndex(Ops[Level]);
      case Level of
        1:
        case TokenType of
          tk_Add  : AddConstantValue(Result);
          tk_Sub  : SubConstantValue(Result);
        else
          Done := True;
        end;
        2:
        case TokenType of
          tk_Mul  : MulConstantValue(Result);
          tkDiv   : DivIntConstantValue(Result);
          tkShl   : ShlConstantValue(Result);
          tk_Slash: DivRealConstantValue(Result);
        else
          Done := True;
        end;
      else
        Done := True;
      end;
    until Done;
  end;
end;

procedure TParser.AddConstantValue(var Value: TConstantValue);
var
  Term: TConstantValue;
begin
  if not (Value.ValueType in [vtInteger, vtFloat, vtString]) then
    Error('P0840', 'Not a number nor a string');
  NextToken;
  Term := GetConstantValue(1);
  case Value.ValueType of

    vtInteger:
    begin
      case Term.ValueType of
        vtInteger : Inc(Value.AsInt64, Term.AsInt64);
        vtFloat   :
        begin
          Value.AsFloat := Value.AsInt64 + Term.AsFloat;
          Value.ValueType := vtFloat;
        end;
      else
        Error('P0860', 'Not a number');
      end;
    end;

    vtFloat:
    begin
      case Term.ValueType of
        vtInteger,
        vtFloat   : Value.AsFloat := Value.AsFloat + Term.AsInt64;
      else
        Error('P0860', 'Not a number');
      end;
    end;

    vtString:
    begin
      if Term.ValueType <> vtString then
        Error('P0877', 'Not a string');
      Value.AsString := Value.AsString + Term.AsString;
    end;

  else
    Error('P0813', 'Add error');
  end;
end;

procedure TParser.SubConstantValue(var Value: TConstantValue);
var
  Term: TConstantValue;
begin
  if not (Value.ValueType in [vtInteger, vtFloat]) then
    Error('P0840', 'Not a number');
  NextToken;
  Term := GetConstantValue(1);
  case Value.ValueType of
    vtInteger:
      if Term.ValueType <> vtInteger then
        Error('P0825', 'Integer expected')
      else
        Dec(Value.AsInt64, Term.AsInt64);
  else
    Error('P0829', 'Add error');
  end;
end;

procedure TParser.MulConstantValue(var Value: TConstantValue);
var
  Factor: TConstantValue;
begin
  if not (Value.ValueType in [vtInteger, vtFloat]) then
    Error('P0840', 'Not a number');
  NextToken;
  Factor := GetConstantValue(2);
  if not (Factor.ValueType in [vtInteger, vtFloat]) then
    Error('P0840', 'Not a number');
  case Value.ValueType of
    vtInteger:
      case Factor.ValueType of
        vtInteger: Value.AsInt64 := Value.AsInt64 * Factor.AsInt64;
        vtFloat  :
        begin
          Value.AsFloat := Value.AsInt64 * Factor.AsFloat;
          Value.ValueType := vtFloat;
        end;
      else
        Error('P0925', 'Not a number');
      end;
    vtFloat:
      case Factor.ValueType of
        vtInteger: Value.AsFloat := Value.AsFloat * Factor.AsInt64;
        vtFloat  : Value.AsFloat := Value.AsFloat * Factor.AsFloat;
      else
        Error('P0925', 'Not a number');
      end;
  else
    Error('P0829', 'Mul error');
  end;
end;

procedure TParser.DivIntConstantValue(var Value: TConstantValue);
var
  Q: TConstantValue;
begin
  if Value.ValueType <> vtInteger then
    Error('P0971', 'Not an Integer');
  NextToken;
  Q := GetConstantValue(2);
  if Q.ValueType <> vtInteger then
    Error('P0975', 'Not an Integer');
  if Q.AsInt64 = 0 then
    Error('P0977', 'Div by 0');
  Value.AsInt64 := Value.AsInt64 div Q.AsInt64;
end;

procedure TParser.DivRealConstantValue(var Value: TConstantValue);
var
  Q: TConstantValue;
begin
  if not (Value.ValueType in [vtInteger, vtFloat]) then
    Error('P0840', 'Not a number');
  NextToken;
  Q := GetConstantValue(2);
  if not (Q.ValueType in [vtInteger, vtFloat]) then
    Error('P0843', 'Not a number');
  if Value.ValueType = vtInteger then
    Value.AsFloat := Value.AsInt64;
  if Q.ValueType = vtInteger then
    Q.AsFloat := Q.AsInt64;
  if Q.AsFloat = 0 then
    Error('P0849', 'Div by 0');
  Value.AsFloat := Value.AsFloat / Q.AsFloat;
  Value.ValueType := vtFloat;
end;

procedure TParser.ShlConstantValue(var Value: TConstantValue);
var
  Q: TConstantValue;
begin
  if Value.ValueType <> vtInteger then
    Error('P0971', 'Not an Integer');
  NextToken;
  Q := GetConstantValue(2);
  if Q.ValueType <> vtInteger then
    Error('P0975', 'Not an Integer');
  Value.AsInt64 := Value.AsInt64 shl Q.AsInt64;
end;

{ TProperty }

destructor TProperty.Destroy;
begin
 {$IFDEF GARBAGE}
  if Garbage <> nil then
 {$ENDIF}
  Proto.Free;
  inherited;
end;

{ TStructure }

destructor TStructure.Destroy;
var
  s: TSymbol;
begin
 {$IFDEF GARBAGE}
  if Garbage <> nil then
 {$ENDIF}
  while Scope.Symbol <> nil do
  begin
    s := Scope.Symbol;
    Scope.Symbol := s.NextSymbol;
    s.Free;
  end;
  inherited;
end;

end.
