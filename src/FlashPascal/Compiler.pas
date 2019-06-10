unit Compiler;

{ FlashPascal (c)2012 Execute SARL }

interface

{$I FlashPascal.inc}
{$i-}
uses
 Graphics,
 Classes, SysUtils { StrToFloat }, {$IFDEF SHELL}Windows, {$IFNDEF FPC}ShellAPI,{$ENDIF}{$ENDIF}
 Global, Parser, Source, SWF, Deflate;

type

  TCompiler = class;
  TUnit = class;

  TWarning = class
  private
    FNum     : string;
    FFileName: string;
    FMessage : string;
    FRow     : Integer;
    FCol     : Integer;
  public
    constructor Create(const ANum, AMsg, AFile: string; ARow, ACol: Integer);
    property Message : string read FMessage;
    property FileName: string read FFileName;
    property Num: string read FNum;
    property Row: Integer read FRow;
    property Col: Integer read FCol;
  end;

  TWarnings = class(TClearList)
  private
    function GetItem(Index: Integer): TWarning;
  public
    property Items[Index: Integer]: TWarning read GetItem; default; 
  end;

  TExpression = class
    code   : string; // code of the expression
    Kind   : TSymbol;
    Source : TCompiler; // to show error messages from TExpression
    procedure Add(ex: TExpression);
    procedure Sub(ex: TExpression);
    procedure _Or(ex: TExpression);
    procedure _Xor(ex: TExpression);
    procedure _Not;
    procedure _And(ex: TExpression);
    procedure MulBy(ex: TExpression);
    procedure DivBy(ex: TExpression);
    procedure Modulo(ex: TExpression);
    procedure Divide(ex: TExpression);
    procedure _Shl(ex: TExpression);
    procedure _ShrSigned(ex: TExpression);
    procedure _ShrUnsigned(ex: TExpression); // pascal programmers use unsigned shift :)
    procedure IsEqual(ex: TExpression);
    procedure IsGreater(ex: TExpression);
    procedure IsGreaterOrEqual(ex: TExpression);
    procedure IsLesser(ex: TExpression);
    procedure IsLesserOrEqual(ex: TExpression);
    procedure IsNotEqual(ex: TExpression);
    procedure IsIn(ex: TExpression);
    procedure Negate;
    function IsType(AKind: TSymbol): Boolean;
    constructor Create(ACompiler:TCompiler);
    destructor Destroy; override;
  end;

  TRange = class(TSymbol)
    Kind : TSymbol;
    _Low : Integer;
    _High: Integer;
  end;

  TArray = class(TSymbol)
    _open : Boolean;
    Range : TRange;
//    _low  : Integer;
//    _high : Integer;
    _kind : TSymbol;
  end;

  TRecord = class(TStructure)
  //Init  : string;
  //Scope : TScope;
    Count : Integer;
  end;

  TSetOf = class(TSymbol)
    Items: TSymbol;
  end;

  TSet = class(TSymbol)
    First: TConstant;
    Last : TConstant;
    Count: Integer;
    SetOf: TSetOf;
    constructor Create;
    destructor Destroy; override;
  end;

  TInstance = record
    getcode: string;
    setcode: string;
    kind   : TSymbol;
    getter : string;
    setter : string;
    read   : Boolean;
    write  : Boolean;
    Source : TSymbol;
  end;

  TBaseType = class(TSymbol)
  end;

  TBaseTypeAlias = class(TSymbol)
    Base: TBaseType;
  end;

  TArrayOfString = array of string;

  TCompiler = class(TParser)
  private
    FTarget: string;        // full path name without extension
    FNext  : TCompiler;     // Linked list of source code
    FUses  : TUnit;         // used units
    FInit  : string;        // initializing code
    FExit  : string;        // Exit Code
    FCode  : string;        // main code
    FReturn: TSymbol;       // Valeur attendu (:=, paramètre...)
    FMethod: TSymbol;       // Current Method
    FThis  : Boolean;       // this est-il accessible sans self ?
    FWith  : Integer;       // number of with instructions (to compare with TParser.FDepth)
    FWithVariant: TInstance;
    FSetThisMember: string; // set by GetThis
    FGetThisMember: string; //  "
    FPrefix: string;        // préfixe des variables globales
    FProlog: string;
    FPrologIndex: Integer;
    FNameIDs: Integer;
    FDefines: TStringList;  // List of defines
    FIfDefs : string;       // YNYNYN...
    function GetName(Code: Char; const Name: string): string;
    procedure OpenFile(var f: file; const AFileName: string);
    function ColorMap(AResourceID: Word; const AFileName: string):string;
    function getResourceParams(const types: string; const names: array of string): TArrayOfString;
    procedure AddBitmapResource;
    procedure AddJPEGResource;
    procedure AddFontResource;
    procedure AddVideoResource;
    procedure AddShapeResource;
    procedure CompilerSwitch(StopToken: TToken);
    procedure DoIfDef(Defined: Boolean);
    procedure DoDefine(Define: Boolean);
    procedure DoElseDef;
    procedure DoEndDef;
    function GetThis: string;
    function GetSelf: string;
    function IntegerExpression: TExpression;
    function IntegerCode: string;
    function StringExpression: TExpression;
    function StringCode: string;
    function Expression: TExpression;
    function Expression1: TExpression;
    function Expression2: TExpression;
    function Expression3: TExpression;
    procedure PropertyExpression(ex: TExpression; prop: TProperty);
    function GetConstantCode(AValue: TConstantValue): string;
    procedure VarSuffix(ex: TExpression);
    function GetArray: TArray;
    function GetRange: TRange;
    function GetRecord: TRecord;
    function GetSet: TSet;
    function GetSetOf: TSetOf;
    function IsType: Boolean;
    function GetType: TSymbol;
    function BuildArray(Arr: TArray): string;
    function DeclareField(Owner: TRecord): string;
    function DeclareVar(Owner: TSymbol; local: Boolean): string;
    function GetParam(Proto: TPrototype; Prev: TParameter; Owner: TFunction): TParameter;
    function GetMethod(AClass: TClassDef; void: Boolean; isConstructor: Boolean): TMethod;
    procedure ImplementStatic(AMethod: TMethod);
    function MethodAlias(m:TMethod):TMethod;
    procedure ConstructorAlias(m: TMethod);
    procedure GetProperty(AClass: TClassDef; Static: Boolean);
    procedure ExternalFlashClass(const ClassName, SymbolName: string);
    procedure ForwardClass(AClass: TClassDef);
    procedure DefineExternalFlashClass(AClass: TClassDef);
    procedure DefineUserClass(const name, symbol: string);
    procedure UserClassDefine(AClass: TClassDef);
    function UserProperty(AClass: TClassDef; static: Boolean): TProperty;
    function FunctionPrototype(const name: string; void: Boolean): TSymbol;
    procedure DeclareType;
    procedure DeclareConst;
    function DropVariable: TVariable;
    function DropParameter: TParameter;
    function DropProperty: TProperty;
    function PushString: string;
    function PushInteger: string;
    function PushSetOf(Kind: TSetOf): string;
    function PushDouble: string;
    procedure VarInstance(variable: TVariable; var Instance: TInstance);
    procedure ParamInstance(param: TParameter; var Instance: TInstance);
    procedure PropertyInstance(prop: TProperty; var Instance: TInstance; Root: Boolean = True);
    function GetVariable(Variable: TVariable): string;
    function PushBoolean: string;
    procedure GetInstance(var Instance: TInstance);
    function LookupSymbol(List: TSymbol; const Name: string): TSymbol;
    function LookupInherited(AClass: TClassDef; const Name: string): TSymbol;
    function GetSymbol(List: TSymbol; Skip: Boolean = True): TSymbol;
    function GetInheritedSymbol(AClass: TClassDef; Skip: Boolean = True): TSymbol;
    function InheritedSymbol(AClass: TClassDef; Skip: Boolean = True): TSymbol;
  //function ClassLookup(AClass: TClassDef; const Symbol: string): TSymbol;
    function ClassSymbol(AClass: TClassDef): TSymbol;
    function RecordField(ARecord: TRecord): TSymbol;
    function PushInstance: string;
    function PushStaticObject: string;
    function GetConstantSetOf(Kind: TSet): Integer;
    function GetConstantSet(Kind: TSet): TConstant;
    function PushMethod: string;
    function PushArray(A: TArray): string;
    function ConstArray(A: TArray): string;
    function PushConst(Kind: TSymbol): string;
    function PushKind(Kind: TSymbol): string;
    function CallConstructor(ACreate: TMethod): string;
    function CallFunction(method: TMethod): string;
    function PushParams(Proto: TPrototype; var Count: Integer): string;
    function PushParams2(Param: TParameter; var Count: Integer): string;
    procedure ClassInstance(AClass: TClassDef; var Instance: TInstance);
    function ClassExpression(AClass: TClassDef): TExpression;
    function ClassStatement(AClass: TClassDef; APop: Boolean = False): string;
    function ConstructClass(create: TMethod): string;
    function AssignStatement(Kind: TSymbol): string;// todo: a lot of things !
    function CallPrototype(instance: string; Proto: TPrototype; method: TMethod): string;
    function CallMethod(const instance: string; method: TMethod): string;
    function GetPrototype(Proto: TPrototype): string;
    procedure InstanceSuffix(var Instance: TInstance);
    function ResolveInstance(var instance: TInstance; APop: Boolean = True): string;
    function VariableSuffix: string;
    function ParameterSuffix: string;
    function PropertySuffix: string;
    function IfStatement: string;
    function ForStatement: string;
    function CallThisMethod: string;
    function NextCase(Kind: TSymbol): string;
    procedure NextCaseValue(Kind: TSymbol; var ANext, ACode, AOther: string);
    function CaseStatement: string;
    function RepeatStatement: string;
    function WhileStatement: string;
    function DotStatement: string;
    function WithStatement: string;
    function SortStatement: string;
    function IncStatement: string;
    function DecStatement: string;
    function IncludeStatement: string;
    function ExcludeStatement: string;
    function TraceStatement:string; // not tested
    function ExitStatement: string;
    function SelfStatement: string;
    function UnitStatement: string;
    function Statement: string;
    function DropParams(Param: TParameter): Boolean;
    function MethodCall(AClass: TClassDef; AMethod: TMethod; const Caller: string): string; // constructor/method inheritence
    function IsFlashClass(AClass: TClassDef): boolean;
    function IsConstructor(Symbol: TSymbol): boolean;
    function inheritedConstructor(AClass: TClassDef): TMethod;
    procedure DefaultConstructor(AClass: TClassDef);
    //function DeclareConstructor(AClass: TClassDef): string;
    function DefineConstructor: string;
    function DefineMethod(void: boolean): string;//this "void" parameter was made for debugging
    procedure PublicMethod(void: Boolean);
    procedure ExternalMethod(AMethod: TMethod);
    function StaticMethod(void: boolean): string;
    function CheckClass(AClass: TClassDef): string;
    function CheckClasses: string;
    function GetArrayIndex(var Kind: TSymbol): string;
    function GetClass: TClassDef;
    procedure AddUnit(AUnit: TCompiler);
    procedure AddUses;
    procedure CompileUnit(const ASourceName, AFileName:string);//procedure CompileUnit(const Name:string);
    function UnitsCode: string;
    procedure UnitCompilation(const Name: string);
    procedure UnitInterface;
    procedure UnitImplementation;
    procedure ImplementUnits;
    procedure CheckForwardClasses;
    procedure MainStatement;
    function BaseTypeAlias(const SrcName, Name: string; base: TBaseType): TSymbol;
    function DeclareFunction(Method: TMethod; const name: string): string;
  protected
    FRealName: string;
    FName  : string;        // source name
    FIntf  : TSymbol;
    FUnit  : (uNone, uInterface, uImplementation, uDone);
    function GetFileCompiler(const AFileName: string): TCompiler; virtual;
  public
    Scope  : TScope;
    constructor Create(AProvider: TSourceProvider);
    destructor Destroy; override;
    function GetUnitSymbol(const AName: string; var AToken: TToken): Boolean;
    procedure NextToken; override;
    procedure Compile(Debug: Boolean);
    procedure Save(Debug: Boolean);
  end;

  TUnit = class(TSymbol)
    Source: TCompiler;
    Next  : TUnit;
  end;

var
  _System   : TCompiler;   // System Unit
//  _Root     : TVariable; // hidden symbol
  _Char     : TSymbol;   // Internal type for string[x]
  _String   : TSymbol;   // Flash String
  _Integer  : TSymbol;   // base type integer
  _Double   : TSymbol;   // base type double
  _Boolean  : TSymbol;   // base type boolean
  _Object   : TSymbol;
  _Variant  : TSymbol;   // generic object, like in _root['param']

  FlashVersion: Byte;
  FrameWidth  : Word; // SWF frame properties
  FrameHeight : Word;
  FrameRate   : Byte;
  Background  : Cardinal; // Frame background

  Resources   : string;
  ExportNames : string;

  CodeItem    : TCodeItem;
  
  ResourceID  : Integer;

  Anonyms   : TSymbol;

  Variable  : TVariable absolute Symbol;
  Parameter : TParameter absolute Symbol;

  MainSource: TCompiler = nil;
  SourceList: TCompiler = nil;
  ThisSource: TCompiler;
  SourceID  : Integer;

  Warnings: TWarnings;

implementation

uses FontBuilder;

type
  TBMPHeader = packed record
    bfType : array[1..2] of Char;
    bfSize : Longint;
    bfReserved: Longint;
    bfOffBits: Longint;
    biSize: Longint;
    biWidth: Longint;
    biHeight: Longint;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: Longint;
    biSizeImage: Longint;
    biXPelsPerMeter: Longint;
    biYPelsPerMeter: Longint;
    biClrUsed: Longint;
    biClrImportant: Longint;
  end;

  TBMPColors=packed array[0..255,0..3] of byte;


function TCompiler.BaseTypeAlias(const SrcName, Name: string; base: TBaseType): TSymbol;
begin
  Result := TBaseTypeAlias.Create(tk_Type);
  Result.Name := Name;
  Result.realName := SrcName;
  Result.codeName := SrcName;
  TBaseTypeAlias(Result).Base := base;
  Result.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := Result;
end;

function RealType(Symbol: TSymbol): TSymbol;
begin
  while Symbol is TBaseTypeAlias do
    Symbol := TBaseTypeAlias(Symbol).Base;
  Result := Symbol;
end;

function IsBoolean(Symbol: TSymbol): Boolean;
begin
  Result := RealType(Symbol) = _Boolean;
end;

function IsChar(Symbol: TSymbol): Boolean;
begin
  Result := RealType(Symbol) = _Char;
end;

function IsNumber(Symbol:TSymbol):boolean;
begin
  Symbol := RealType(Symbol);
  Result := (Symbol = _Integer) or (Symbol = _Double);
end;

function IsSet(Symbol: TSymbol): Boolean;
begin
  Symbol := RealType(Symbol);
  Result := Symbol.Token = tk_Set;
end;

function IsSetOf(Symbol, Kind: TSymbol): Boolean;
begin
  Symbol := RealType(Symbol);
  Result := (Symbol.Token = tk_SetOf) and ((Kind = nil) or (RealType(TSetOf(Symbol).Items) = RealType(Kind)));
end;

function IsInteger(Symbol: TSymbol): Boolean;
begin
  Result := RealType(Symbol) = _Integer;
end;

function IsOrdinal(Symbol: TSymbol): Boolean;
begin
  Symbol := RealType(Symbol);
  Result := (Symbol = _Integer) or (Symbol.Token = tk_Set);
end;

function IsDouble(Symbol: TSymbol): Boolean;
begin
  Result := RealType(Symbol) = _Double;
end;

function IsArray(Symbol: TSymbol): Boolean;
begin
  Result := RealType(Symbol) is TArray;
end;

function IsRecord(Symbol: TSymbol): Boolean;
begin
  Result := RealType(Symbol) is TRecord;
end;

function BoolToInteger(const Code: string): string;
var
  s1, s2: string;
begin
  s1 := SWFPushInteger(1); // True  = 1
  s2 := SWFPushInteger(0); // False = 0
  s1 := s1 + Branch(Length(s2));
  Result := Code + acLogicalNot + BranchIfEq(Length(s1)) + s1 + s2;
end;

function SameBase(Kind1, Kind2: TSymbol): Boolean;
var
  Base1, Base2: TSymbol;
begin
  Result := False;
  if Kind1 is TBaseType then
    Base1 := Kind1
  else
  if Kind1 is TBaseTypeAlias then
    Base1 := TBaseTypeAlias(Kind1).Base
  else
    Exit;
  if Kind2 is TBaseType then
    Base2 := Kind2
  else
  if Kind2 is TBaseTypeAlias then
    Base2 := TBaseTypeAlias(Kind2).Base
  else
    Exit;
  Result := (Base1 = Base2) or (IsNumber(Base1) and IsNumber(Base2));
end;

function IsObject(Symbol: TSymbol): Boolean;
begin
  Result := (Symbol = _Object) or (Symbol = _Variant) or (Symbol is TClassDef);
end;

function GetParameter(Parameter: TParameter): string;
begin
  Result := {$IFDEF REG_PARAM}SWFGetRegister(Parameter.Reg){$ELSE}SWFGetVariable(Parameter.codeName){$ENDIF};
end;

function TCompiler.GetThis: string;
begin
  //if FInWith then
  if FDepth < FWith then
  begin
    Result := '';
    FGetThisMember := acGetVariable;
    FSetThisMember := acSetVariable;
  end else begin
    Result := GetSelf;
    FGetThisMember := acGetMember;
    FSetThisMember := acSetMember;
  end;
end;

function TCompiler.getSelf: string;
begin
  Result := {$IFDEF REG_THIS}SWFGetRegister(1){$ELSE}SWFGetVariable('this'){$ENDIF};
end;

function SetThis(Value: string): string;
begin
 {$IFDEF REG_THIS}
  Result := Value + SWFSetRegister(1) + acPop;
 {$ELSE}
  Result := SWFPushString('this') + Value + acSetVariable;
 {$ENDIF}
end;

function SetVariable(Variable: TVariable; const Value: string): string;
begin
{$IFDEF REG_VARS}
  if Variable.Reg = 0 then
  begin
{$ENDIF}
   Result := SWFOptimize(
               SWFPushString(Variable.codeName)
             + Value
             + acSetVariable
             );
{$IFDEF REG_VARS}
 end else begin
   Result := SWFOptimize(Value)
           + SWFSetRegister(Variable.Reg)
           + acPop;
 end;
{$ENDIF}
end;

function TCompiler.DeclareFunction(Method: TMethod; const name: string): string;
var
  s : string;
  p : TParameter;
  ss: string;
  f : Word;
begin
  if Length(method.Code) > $FFFF then
    Error('C0472', 'function too long');

  f := FLAG_7;
  if Method.NeedRoot then
    f := f or $40;
  //if Method.NeedParent then
    f := f or 16;

  s := name + #0
     + SWFshort(Method.proto.count)
     + Chr(Method.proto.regs)
     + SWFShort(f);
  p := Method.proto.params;
  ss:= '';
  while p <> nil do
  begin
    ss := {$IFDEF REG_PARAM}Chr(p.Reg){$ELSE}#0{$ENDIF} + p.CodeName + #0 + ss;
    p := p.NextParam;
  end;
  s := s + ss + SWFshort(Length(Method.code));

  Result := acDeclareFunction7
          + SWFshort(Length(s))
          + s
          + Method.code;
end;

{ TExpression }

constructor TExpression.Create(ACompiler: TCompiler);
begin
  inherited Create;
  Source := ACompiler;
  {$IFDEF MEMCHECK}
  Inc(eCount);
  {$ENDIF}
end;

destructor TExpression.Destroy;
begin
 {$IFDEF MEMCHECK}
 dec(eCount);
 {$ENDIF}
end;

procedure TExpression.Add(ex:TExpression);
var
  Items: TSymbol;
begin
  if Kind = _Variant then
  begin
    if ex.Kind = _Variant then
    begin
      code := code + ex.Code + acAdd;
      Exit;
    end;
    Kind := ex.Kind;
  end;
  if (Kind = _String) or (Kind = _Char) then
  begin
    if (ex.Kind = _String) or (ex.Kind = _Char) or (ex.Kind = _Variant) then
    begin
      code := code + ex.Code + acConcat;
      Kind := _String;
      ex.Free;
    end else begin
      Source.Error('C0409', 'String expected');
    end;
  end else
  if IsNumber(Kind) and IsNumber(ex.Kind) then
  begin
    code := code + ex.Code + acAdd;
    if ex.Kind = _Double then
      Kind := _Double;
    ex.Free;
  end else
  if IsSetOf(Kind, nil) then
  begin
    Items := TSetOf(RealType(Kind)).Items;
    if not IsSetOf(ex.Kind, Items) then
      Source.Error('C0591', 'Unexpected type');
    code := code + ex.Code + acBitwiseOr;
    ex.Free;
  end else
    Source.Error('C0418', 'Integer or Double expected');
end;

procedure TExpression.Sub(ex:TExpression);
var
  Items: TSymbol;
begin
 if IsNumber(Kind) and IsNumber(ex.Kind) then begin
  code := SWFSubstract(code, ex.Code); //code + ex.Code + acSubstract;
  if ex.Kind = _Double then
    Kind := _Double;
  ex.Free;
 end else
  if IsSetOf(Kind, nil) then
  begin
    Items := (RealType(Kind) as TSetOf).Items;
    if not IsSetOf(ex.Kind, Items) then
      Source.Error('C0591', 'Unexpected type');
    //code := code + SWFPushInteger((1 shl ((Items as TSet).Last.Value.AsInt64 + 1)) - 1) +  ex.Code + acSubstract + acBitwiseAnd;
    code := code + SWFSubstract(SWFPushInteger((1 shl ((Items as TSet).Last.Value.AsInt64 + 1)) - 1),  ex.Code) + acBitwiseAnd;
    ex.Free;
  end else
  Source.Error('C0429', 'Integer or Double expected');
end;

procedure TExpression._Or(ex:TExpression);
begin
  if Kind = _Variant then
    Kind := ex.Kind;
 //if IsNumber(Kind) and IsNumber(ex.Kind) then begin
 if (Kind=_Integer) and (ex.Kind=_Integer) then begin
  code:=code+ex.Code+acBitwiseOr;
  ex.Free;
 end else
 if (Kind=_Boolean) and (ex.kind=_Boolean) then begin
  code:=code+ex.Code+acLogicalOr;
  ex.Free;
 end else
  Source.Error('C0443', 'Integer or Boolean expected');
end;

procedure TExpression._Xor(ex:TExpression);
begin
 //if IsNumber(Kind) and IsNumber(ex.Kind) then begin // double ?
 if IsInteger(Kind) and IsInteger(ex.Kind) then begin
  code:=code+ex.Code+acBitwiseXOr;
  ex.Free;
 end else
 if IsBoolean(Kind) and IsBoolean(ex.kind) then begin
  code:=code+ex.code+acEqual+acLogicalNot; // true if inputs are different
  ex.Free;
 end else
  Source.Error('C0457', 'Integer or Boolean expected');
end;

procedure TExpression._Not;
begin
  //if IsNumber(Kind) then // double ?
  if Kind=_Integer then
    code:=SWFOptimize(code+SWFPushInteger(-1))+acBitwiseXor // BitwiseNOT(x) = (x XOR -1)
  else
  if Kind=_Boolean then
    code:=code+acLogicalNot
  else
    Source.Error('C0469', 'Integer or Boolean expected');
end;

procedure TExpression._And(ex:TExpression);
begin
  //if IsNumber(Kind) and IsNumber(ex.Kind) then begin // double ?
  if (Kind=_Integer) and (ex.Kind=_Integer) then begin
    code:=code+ex.Code+acBitwiseAnd;
    ex.Free;
  end else
    if (Kind=_Boolean) and (ex.kind=_Boolean) then begin
      code:=code+ex.Code+acLogicalAnd;
      ex.Free;
    end else
      Source.Error('C0483', 'Integer or Boolean expected');
end;

procedure TExpression.MulBy(ex:TExpression);
var
  Items: TSymbol;
begin
  if IsSetOf(Kind, nil) then
  begin
    Items := TSetOf(RealType(Kind)).Items;
    if not IsSetOf(ex.Kind, Items) then
      Source.Error('C0591', 'Unexpected type');
    code := code + ex.Code + acBitwiseAnd;
    ex.Free;
  end else begin
    if not IsNumber(kind) then
      Source.Error('C0489', 'Integer or Double expected');
    if not IsNumber(ex.Kind) then
      Source.Error('C0491', 'Integer or Double expected');
    code:=code+ex.Code+acMultiply;
    if (RealType(ex.Kind)=_Double) then Kind:=_Double;
    ex.Free;
  end;
end;

procedure TExpression.DivBy(ex:TExpression);
begin
  if not (IsInteger(kind) and IsInteger(ex.kind)) then
    Source.Error('C0500', 'Integer expected');
  code:=code+ex.Code+acDivide+acIntegralPart;
  ex.Free;
end;

procedure TExpression.Modulo(ex:TExpression);
begin
  if (kind<>_Integer)or(ex.kind<>_Integer) then
    Source.Error('C0506', 'Integer expected');
  code:=code+ex.Code+acModulo;
  ex.Free;
end;

procedure TExpression.Divide(ex: TExpression);
var
  v1, v2: Double;
begin
  if not IsNumber(Kind) then
    Source.Error('C0514', 'Integer or Double expected');
  if not IsNumber(ex.Kind) then
    Source.Error('C0516', 'Integer or Double expected');
  if SWFIsPushNumber(Code, v1) and SWFIsPushNumber(ex.Code, v2) then
    code := SWFPushDouble(v1 / v2) // todo: Handle div by 0
  else
    code := code + ex.Code + acDivide;
  kind := _Double;
  ex.Free;
end;

procedure TExpression._Shl(ex:TExpression); // SHL <<
begin
  if not (IsInteger(Kind) and IsInteger(ex.Kind)) then
    Source.Error('C0525', 'Integer expected');
  code:=code+ex.Code+acShl;
  ex.Free;
end;

procedure TExpression._ShrSigned(ex:TExpression); // SHRI >>
begin
  //if not IsNumber(Kind) or not IsNumber(ex.Kind) then Source.Error('Numeric expression expected','_ShrSigned');
  if (Kind<>_Integer) or (ex.Kind<>_Integer) then
    Source.Error('C0534', 'Integer expected');
  code:=code+ex.Code+acShrSigned;
  ex.Free;
end;

procedure TExpression._ShrUnsigned(ex:TExpression); // SHR >>>
begin
  //if not IsNumber(Kind) or not IsNumber(ex.Kind) then Source.Error('Numeric expression expected','_ShrUnsigned');
  if not (IsInteger(Kind) and IsInteger(ex.Kind)) then
    Source.Error('C0543', 'Integer expected');
  code:=code+ex.Code+acShrUnsigned;
  ex.Free;
end;

procedure TExpression.IsEqual(ex:TExpression);
var
  k1, k2: TSymbol;
begin
  k1 := RealType(Kind);
  k2 := RealType(ex.Kind);
  if (k1 = _Char) and (k2 = _String) then k1 := _String;
  if (k1 = _String) and (k2 = _Char) then k2 := _String;
  if k1 <> k2 then begin
    if IsObject(Kind) and IsObject(ex.Kind)then // ok: object types are compatible
    else
//******************************************************************************
      if IsNumber(Kind) and IsNumber(ex.Kind) then // ok: numeric types are compatible
      else // nothing else but NIL=SWFPushUndefined at compiletime ?
        if(code=SWFPushUndefined)or(ex.code=SWFPushUndefined)then // okay: anything can be compared with NIL (undefined)
        else
//******************************************************************************
          Source.Error('C0769', 'Type mismatch');
  end;
  code:=code+ex.code+acEqual;
  kind:=_Boolean;
  ex.Free;
end;

procedure TExpression.IsGreater(ex:TExpression);
begin
  if Kind<>ex.kind then begin
    if IsNumber(Kind) and IsNumber(ex.Kind) then // ok: numeric types are compatible
    else
      Source.Error('C0571', 'Type mismatch');
  end;
  code:=code+ex.code+acGreaterThan;
  kind:=_Boolean;
  ex.Free;
end;

procedure TExpression.IsGreaterOrEqual(ex:TExpression);
begin
  if Kind<>ex.kind then begin
    if IsNumber(Kind) and IsNumber(ex.Kind) then // ok: numeric types are compatible
    else
      Source.Error('C0583', 'Type mismatch');
  end;
  code:=code+ex.code+acLessThan+acLogicalNot;
  kind:=_Boolean;
  ex.Free;
end;

procedure TExpression.IsLesser(ex:TExpression);
begin
  if Kind<>ex.kind then begin
    if IsNumber(Kind) and IsNumber(ex.Kind) then  // ok: numeric types are compatible
    else
      Source.Error('C0595', 'Type mismatch');
  end;
  code:=code+ex.code+acLessThan;
  kind:=_Boolean;
  ex.Free;
end;

procedure TExpression.IsLesserOrEqual(ex:TExpression);
begin
  if Kind<>ex.kind then begin
    if IsNumber(Kind) and IsNumber(ex.Kind) then // ok: numeric types are compatible
    else
      Source.Error('C0607', 'Type mismatch');
  end;
  code:=code+ex.code+acGreaterThan+acLogicalNot;
  kind:=_Boolean;
  ex.Free;
end;

procedure TExpression.IsNotEqual(ex:TExpression);
begin
  if Kind <> ex.kind then begin
    if IsObject(Kind) and IsObject(ex.Kind)then // ok: object types are compatible
    else
//******************************************************************************
      if IsNumber(Kind) and IsNumber(ex.Kind) then // ok: numeric types are compatible
      else // nothing else but NIL=SWFPushUndefined at compiletime ?
        if(code=SWFPushUndefined)or(ex.code=SWFPushUndefined)then // okay: anything can be compared with NIL (undefined)
        else
//******************************************************************************
          Source.Error('C0625', 'Type mismatch');
  end;
  code := code + ex.code + acEqual + acLogicalNot;
  kind := _Boolean;
  ex.Free;
end;

procedure TExpression.Negate;
var
  i:integer;
begin
  if not IsNumber(Kind) then
    Source.Error('C0637', 'Integer or Double expected');
  // have we push a constant integer ?
  if SWFIsPushInteger(Code, i) then begin
    code := SWFPushInteger(-i);
  end else begin
    //code:=SWFPushInteger(0)+code+acSubstract;
    code := SWFSubstract(SWFPushInteger(0), code);
  end;
end;

function TExpression.IsType(AKind: TSymbol): Boolean;
begin
  Result := (Kind = AKind) or (Kind = RealType(AKind));
  if Result = False then
  begin
    if (Kind = _Object) and ((AKind is TPrototype) or (AKind is TClassDef) or (AKind = _Variant)) then // nil à tester
      Result := True
    else
    if IsNumber(Kind) and IsNumber(AKind) then
      Result := True;
  end;
end;

procedure TExpression.IsIn(ex: TExpression);
begin
  if IsSet(Kind) then
  begin
    if not IsSetOf(ex.Kind, Kind) then
      Source.Error('C835', 'unexpected type');
    Code := SWFOptimize(SWFPushInteger(0) + ex.code + SWFPushInteger(1) + Code) + acShl + acBitwiseAnd + acEqual + acLogicalNot;
  end;
  Kind := _Boolean;
end;

{ TCompiler }

constructor TCompiler.Create(AProvider: TSourceProvider);
begin
  inherited;
  FGetThisMember := acGetMember;
  FSetThisMember := acSetMember;
  FDefines := TStringList.Create;
  FDefines.Add('FLASHPASCAL');
  FDefines.Add('SWF');
  FDefines.Add('SWF8');
end;

procedure TCompiler.OpenFile(var f: File; const AFileName: string);
var
  str: string;
begin
  if FileExists(AFileName) then
    AssignFile(f, AFileName)
  else begin
    str := Path + AFileName;
    if FileExists(str) then
      AssignFile(f, str)
    else
      Error('C0792', 'File not found "' + AFileName + '"');
  end;
  Reset(f, 1);
  if IoResult <>  0 then
    Error('C0798', 'Access denied to "' + AFileName + '"');
end;

function TCompiler.ColorMap(AResourceID: Word; const AFileName:string):string;
var
 f     :file;
 header:TBMPHeader;
 Colors:TBMPColors;
 Count :integer;
 Size  :integer;
 i,x,j :integer;
 width :integer;
 rgb   : PCardinal;
begin
 OpenFile(f, AFileName);
 Reset(f,1);
 try
  BlockRead(f,header,SizeOf(header));

  if header.bfType<>'BM' then
    Error('C0769', 'Not a valid bitmap file '+AFileName);

  if header.biBitCount = 32 then
  begin
    Seek(f,header.bfOffBits);
    Size:=header.biWidth * header.biHeight;
    SetLength(Result, 4 * Size);
    x:=Length(Result) + 1;
    for i := 0 to header.biHeight-1 do
    begin
      Dec(x, 4 * header.biWidth);
      BlockRead(f, Result[x], 4 * header.biWidth);
      rgb := @Result[x];
      for j := 0 to header.biWidth - 1 do
      begin
        if rgb^ shr 24 = 0 then
          rgb^ := 0
        else
          rgb^ := swap(rgb^ shr 16) + swap(rgb^) shl 16;
        inc(rgb);
      end;
    end;

    Result:=SWFlhead(36, // DefineBitsLossless2
            SWFshort(ResourceID)
           +#5  // ARGB with colormap
           +SWFshort(header.biWidth)
           +SWFshort(header.biHeight)
           +zCompressStr(Result)
           );
    Exit;
  end;

  if header.biBitCount <> 8 then
    Error('C0803', 'Not a 8 or 32 bits bitmap '+AFilename);

  Count:=header.biClrUsed;
  if Count=0 then Count:=256;
  BlockRead(f,Colors,4*Count);

  Seek(f,header.bfOffBits);

  width:=(header.biWidth+3) and (not 3);
  Size:=width*header.biHeight;
  SetLength(Result,3*Count+Size);
  x:=1;
  for i:=0 to Count-1 do begin
   Result[x]:=chr(Colors[i,2]); inc(x);
   Result[x]:=chr(Colors[i,1]); inc(x);
   Result[x]:=chr(Colors[i,0]); inc(x);
  end;
  x:=Length(Result)+1;
  for i:=0 to header.biHeight-1 do begin
   dec(x,width);
   BlockRead(f,Result[x],header.biWidth);
  end;

  Result:=SWFlhead(20, // DefineBitsLossless
          SWFshort(AResourceID)
         +#3  // RGB with colormap
         +SWFshort(header.biWidth)
         +SWFshort(header.biHeight)
         +chr(Count-1)
         +zCompressStr(Result)
         );

 finally
  CloseFile(f);
 end;

end;

function TCompiler.getResourceParams(const types: string; const names: array of string): TArrayOfString;
var
  Len  : Integer;
  Index: Integer;

  function IsInteger(const s: string): string;
  var
    i: Integer;
  begin
    if TryStrToInt(s, i) = False then
      Error('C0911', 'Integer expected for ' + names[Index]);
    Result := s;
  end;

  function GetValue(c: Char): string;
  begin
    if TokenType <> tk_String then
      Error('C918', 'name="value" expected for ' + names[Index]);
    case c of
      's' : Result := Token;
      'i' : Result := IsInteger(Token);
    else
      Error('C910', 'Internal Error 910');
    end;
    NextToken;
  end;

  function GetType(c: Char): string;
  begin
    case c of
      's' :
      if TokenType = tk_String then
        Result := Token
      else
        Result := SrcToken;
      'i' : Result := IsInteger(Token);
    else
      Error('C910', 'Internal Error 910');
    end;
    NextToken;
  end;

begin
  Len := Length(types);
  if (len = 0) or (length(names) <> len) then
    Error('C0906', 'Internal error 906');
  SetLength(Result, Len);
  if (NextChar = '=') then
  begin
    for Index := 0 to Len - 1 do
    begin
      DropIdent(names[Index]);
      DropToken(tk_EQ);
      Result[Index] := GetValue(types[Index + 1]);
    end;
  end else begin
    for Index := 0 to Len - 1 do
    begin
      Result[Index] := GetType(types[Index + 1]);
    end;
  end;
end;

procedure TCompiler.AddBitmapResource; //****************************************** Resource
var
  name: string;
  data: string;
begin
  name := SrcToken;
  DropToken(tk_Ident);
  data := Token;
  DropToken(tk_String);
  Inc(ResourceID);
  data := ColorMap(ResourceID, data);
  ExportNames := ExportNames + SWFshort(ResourceID) + name + #0;
  Resources := Resources + Data;
end;

procedure TCompiler.AddJPEGResource;
var
  name: string;
  data: string;
  jpeg: File;
  len : Integer;
begin
  name := SrcToken;
  DropToken(tk_Ident);
  data := Token;
  DropToken(tk_String);
  Inc(ResourceID);
  OpenFile(jpeg, data);
  if IoResult <> 0 then
    Error('C0880', 'Can''t open file ' + data);
  try
    len := FileSize(jpeg);
    SetLength(data, len);
    BlockRead(jpeg, data[1], Length(data));
    Resources := Resources + SWFlhead(21, // DefineBitsJPEG2
                  SWFshort(ResourceID)
                 +data
                 );
    ExportNames := ExportNames + SWFshort(ResourceID) + name + #0;
  finally
    CloseFile(jpeg);
  end;
end;

procedure TCompiler.AddFontResource;
var
  name: string;
  font: string;
  text: string;
  Style: TFontStyles;
  c   : Char;
begin
  if TokenType = tk_String then
    name := Token
  else
    name := SrcToken;
  NextToken;
  font := Token;
  DropToken(tk_String);
  Style := [];
  if SkipToken(tk_LBracket) then
  begin
    while TokenType <> tk_RBracket do
    begin
      if Token = 'BOLD' then
        Style := Style + [fsBold]
      else
      if Token = 'ITALIC' then
        Style := Style + [fsItalic]
      else
        Error('C0957', 'Unknow font style');
      NextToken;
      if TokenType <> tk_RBracket then
        DropToken(tk_Comma);
    end;
    NextToken;
  end;
  if TokenType = tk_String then
  begin
    Text := Token;
    NextToken;
    while TokenType = tk_Range do
    begin
      NextToken;
      if TokenType <> tk_String then
        Error('C0961', 'String expected');
      for c := Text[Length(Text)] to Pred(Token[1]) do
        Text := Text + c;
      Text := Text + Token;
      NextToken;
    end;
  end;
  Inc(ResourceID);
  Resources := Resources + FontGlyphs(font, style, text);
  ExportNames := ExportNames + SWFshort(ResourceID) + name + #0;
end;

procedure TCompiler.AddVideoResource;
// {$VIDEO name depth left top width heigth}
var
  parms: TArrayOfString;
  name : string;
  depth: Integer;
  org  : TPoint;
  size : TSize;
begin
  parms := GetResourceParams('siiiii', ['NAME', 'DEPTH', 'LEFT', 'TOP', 'WIDTH', 'HEIGHT']);
  name := parms[0];
  depth := StrToInt(parms[1]);
  org.X := StrToInt(parms[2]);
  org.Y := StrToInt(parms[3]);
  size.cx := StrToInt(parms[4]);
  size.cy := StrToInt(parms[5]);
  Inc(ResourceID);
  Resources := Resources +
               SWFhead(60, // DefineVideoStream
                 SWFshort(ResourceID)
                +#0#0 // FrameCount = 0
                +SWFshort(Size.cx) // width in pixels !
                +SWFShort(Size.cy) // height in pixels !
                +#0 // no flag
                +#0 // no codec
               ) +
               SWFhead(26, // PlaceObject2
                 Chr(2 + 4 + 32) // id, matrix, name
                +SWFshort(depth)
                +SWFshort(ResourceID)
                +SWFTranslateMatrix(20 * Org.x, 20 * Org.y)
                +name + #0
               );
  //ExportNames := ExportNames + SWFShort(ResourceID) + name + #0;
end;

procedure TCompiler.AddShapeResource;
var
  name  : string;
  f     : file;
  shape : string;
  i     : Integer;
  sprite: string;
begin
// {$SHAPE export_name 'shape_file.shp'}
  name := SrcToken;
  DropToken(tk_Ident);

  OpenFile(f, Token);
  DropToken(tk_String);
  SetLength(shape, FileSize(f));
  BlockRead(f, shape[1], Length(shape));
  CloseFile(f);

  Inc(ResourceID);
  if Ord(shape[1]) and $3F = $3F then
    i := 7
  else
    i := 2;
  Move(ResourceID, shape[i], 2);

  Inc(ResourceID);
  sprite := SWFshort(ResourceID) // sprite ID
          + SWFshort(1) // frame count
          + SWFplaceObject(ResourceID - 1, 1)
          + SWFShowFrame()
          + SWFEndTag();
  sprite := SWFlhead(39, sprite);

  ExportNames := ExportNames + SWFshort(ResourceID) + name + #0;

  Resources := Resources + shape + sprite;
end;

// deal with Frame properties and other things
procedure TCompiler.CompilerSwitch(StopToken:TToken);
var
  s: string;
  switch: (
    sNone,
    sFrameWidth, sFrameHeight, sFrameRate, sBackground,
    sVersion,
    sBitmap, sJPEG,
    sFont,
    sVideo,
    sShape,
    sLink, sExport,
    sIfDef, sIfNDef, sElse, sEndIf,
    sDefine, sUndef
  );
  b: Integer;
  f: file;
begin
  s := '';
  switch := sNone;
  while UpCase(NextChar) in ['A'..'Z','_'] do
    s := s + UpCase(ReadChar);

  if s = 'FRAME_WIDTH'  then switch := sFrameWidth  else
  if s = 'FRAME_HEIGHT' then switch := sFrameHeight else
  if s = 'FRAME_RATE'   then switch := sFrameRate   else
  if s = 'BACKGROUND'   then switch := sBackground  else
  if s = 'VERSION'      then switch := sVersion     else
  if s = 'BITMAP'       then switch := sBitmap      else
  if s = 'JPEG'         then switch := sJPEG else
  if s = 'FONT'         then switch := sFont else
  if s = 'VIDEO'        then switch := sVideo else
  if s = 'SHAPE'        then switch := sShape else
  if (s = 'LINK')
  or (s = 'L')        then switch := sLink else
  if s = 'EXPORT'     then switch := sExport else
  if s = 'IFDEF'      then switch := sIfDef else
  if s = 'IFNDEF'     then switch := sIfNDef else
  if s = 'ELSE'       then switch := sElse else
  if s = 'ENDIF'      then switch := sEndIf else
  if s = 'DEFINE'     then switch := sDefine else
  if s = 'UNDEF' then switch := sUnDef else
    Error('C0956', 'Unknown switch ' + s);

 if switch in [sIfDef, sIfNDef] then
 begin
   DoIfDef(switch = sIfDef);
 end else
 if switch in [sDefine, sUndef] then
 begin
   DoDefine(switch = sDefine);
 end else
 if switch = sElse then
   DoElseDef
 else
 if switch = sEndIf then
   DoEndDef
 else
 if switch = sBitmap then
 begin
   GetToken;
   AddBitmapResource;
 end else
 if switch = sJPEG then
 begin
   GetToken;
   AddJPEGResource;
 end else
 if switch = sFont then
 begin
   GetToken;
   AddFontResource;
 end else
 if switch = sVideo then
 begin
  GetToken;
  AddVideoResource;
 end else
 if switch = sShape then
 begin
   GetToken;
   AddShapeResource;
 end else
 if switch = sLink then
 begin
   GetToken;
   if TokenType <> tk_String then
     Error('C1000', 'File name expected');
   OpenFile(f, Token);
   NextToken;
   SetLength(s, FileSize(f));
   BlockRead(f, s[1], Length(s));
   CloseFile(f);
   if TokenType = tk_String then
   begin
     Inc(ResourceID);
     if Ord(s[1]) and $3F = $3F then
       b := 7
     else
       b := 2;
     Move(ResourceID, s[b], 2);
     ExportNames := ExportNames + SWFshort(ResourceID) + Token + #0;
     NextToken;
   end;
   Resources := Resources + s;
 end else
 if Switch = sExport then
 begin
   GetToken;
   if TokenType <> tk_Number then
     Error('C1018', 'ID expected');
   b := StrToInt(Token);
   GetToken;
   if TokenType <> tk_String then
     Error('C1022', 'Export name expected');
   Inc(ResourceID); // todo: fix this
   ExportNames := ExportNames + SWFshort(b) + Token + #0;
   NextToken;
 end else begin
  GetToken;
  if TokenType <> tk_Number then
    Error('C1002', 'Integer expected');
  b:=BitsCount(Token);
  if switch=sBackground then begin
   if b > 32  then
     Error('C1006', 'Ordinal overflow');
  end else
  if switch in [sFrameRate,sVersion] then begin
   if b > 8  then
     Error('C1010', 'Byte overflow');
  end else begin
   if b > 16 then
     Error('C1013', 'Word overflow');
  end;
  case switch of
   sFrameWidth  : FrameWidth  :=StrToInt(Token);
   sFrameHeight : FrameHeight :=StrToInt(Token);
   sFrameRate   : FrameRate   :=StrToInt(Token);
   sBackground  : Background  :=StrToInt(Token);
   sVersion     : FlashVersion:=StrToInt(Token);
  end;
  GetToken;
 end;
 DropToken(StopToken);
end;

function TCompiler.GetUnitSymbol(const AName: string; var AToken : TToken): Boolean;
begin
  Symbol := FIntf;
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
  Result := False;
end;

procedure TCompiler.DoIfDef(Defined: Boolean);
var
  LocalDefs: string;
  Len : Integer;
begin
  GetToken;
  if TokenType <> tk_Ident then
    Error('C1426', 'Expected ident');
  if (FDefines.IndexOf(Token) >= 0) = Defined then
  begin
    FIfDefs := FIfDefs + 'Y';
    while TokenType <> tk_RComment1 do
        GetToken;
  end else begin
    while TokenType <> tk_RComment1 do
       GetToken;
    GetToken;
    LocalDefs := '';
    repeat
      while TokenType <> tk_Switch1 do
        GetToken;
      GetToken;
      if Token = 'IFDEF' then
      begin
        LocalDefs := LocalDefs + 'Y';
        Continue;
      end;
      if Token = 'ELSE' then
      begin
        Len := Length(LocalDefs);
        if Len = 0 then
        begin
          FIfDefs := FIfDefs + 'E';
          Break;
        end;
        if LocalDefs[Len] <> 'Y' then
          Error('C1467', 'ELSE without IF');
        LocalDefs[Len] := 'E';
        Continue;
      end;
      if Token = 'ENDIF' then
      begin
        Len := Length(LocalDefs);
        if Len = 0 then
          Break;
        SetLength(LocalDefs, Len - 1);
        Continue;
      end;
    until False;
    repeat
      GetToken
    until TokenType = tk_RComment1;
 end;
end;

procedure TCompiler.DoDefine(Define: Boolean);
var
  Index: Integer;
begin
  GetToken;
  if TokenType <> tk_Ident then
    Error('C1469', 'Expected ident');
  Index := FDefines.IndexOf(Token);
  if Define then begin
    if Index < 0 then
      FDefines.Add(Token)
  end else begin
    if Index >= 0 then
      FDefines.Delete(Index);
  end;
  while TokenType <> tk_RComment1 do
      GetToken;
end;

procedure TCompiler.DoElseDef;
var
  Ln : Integer;
  Len: Integer;
  LocalDefs: string;
begin
  Ln := Line;
  Len := Length(FIfDefs);
  if (Len = 0) or (FIfDefs[Len] <> 'Y') then
    Error('C1456', 'ELSE without IF');
  repeat
    GetToken;
  until TokenType = tk_RComment1;
  LocalDefs := '';
  Len := 0;
  repeat
    while TokenType <> tk_Switch1 do
    begin
      try
        GetToken;
      except
        on E:EndOfFile do
          Error('C1521', 'ELSE without ENDIF at line ' + IntToStr(Ln));
      end;
    end;
    GetToken;
    if (Token = 'IFDEF') or (Token = 'IFNDEF') then
    begin
      LocalDefs := LocalDefs + 'Y';
      Inc(Len);
    end;
    if (Token = 'ELSE') then
    begin
      if (Len = 0) or (LocalDefs[Len] <> 'Y') then
        Error('C1529', 'ELSE without IF');
      LocalDefs[Len] := 'E';
    end;
    if (Len > 0) and (Token = 'ENDIF') then
    begin
      Dec(Len);
      SetLength(LocalDefs, Len);
      Token := ''; // do not exit loop
    end;
  until Token = 'ENDIF';
  DoEndDef;
end;

procedure TCompiler.DoEndDef;
var
  Len: Integer;
begin
  Len := Length(FIfDefs);
  if (Len = 0) then
    Error('C1456', 'ENDIF without IF');
  SetLength(FIfDefs, Len - 1);
  repeat
    GetToken;
  until TokenType = tk_RComment1;
end;

procedure TCompiler.NextToken;
begin
  inherited;
  if TokenType=tk_Switch1 then CompilerSwitch(tk_RComment1);
end;

function TCompiler.GetArrayIndex(var Kind: TSymbol): string;
begin
  Kind := RealType(Kind);
  Result := PushInteger;
  if (TArray(Kind).Range <> nil) and (TArray(Kind).Range._low <> 0) then
    Result := SWFSubstract(Result, SWFPushInteger(TArray(Kind).Range._low));
  Kind := RealType(TArray(kind)._kind);
  if (kind is TArray) and SkipToken(tk_Comma) then
  begin
//    DropToken(tk_Comma);
    Result := Result + acGetMember + GetArrayIndex(Kind);
  end;
(*
  Result := PushInteger;
  Kind := TArray(Kind)._kind;
  while Kind is TArray do begin
    DropToken(tk_Comma);
    with TArray(Kind) do
      Result := Result + SWFPushInteger(1 + _high - _low) + acMultiply + PushInteger + acAdd;
    Kind := TArray(Kind)._kind;
  end;
*)
end;

procedure TCompiler.PropertyExpression(ex: TExpression; Prop: TProperty);
var
  code : string;
  count: Integer;
begin
  if prop.onGet = nil then
  begin
    ex.code := ex.code + SWFPushString(prop.codeName) + acGetMember;
  end else begin
    case prop.onGet.Token of
      tk_Variable:
      begin
        ex.code := ex.code + SWFPushString(prop.OnGet.codeName) + acGetMember;
      end;
      tk_Method:
      begin
        Count := 0;
        code := PushParams(TMethod(prop.onGet).proto, Count);
        ex.code := SWFOptimize(code +SWFPushInteger(count) + ex.code +SWFCallMethod(TMethod(prop.onGet).localName));
      end;
    else
      Error('C1215', 'Unknow getter');
    end;
  end;
  ex.kind := prop.Kind;
end;

procedure TCompiler.VarSuffix(ex: TExpression);
var
  s: TSymbol;
  p: TSymbol;
  e: TExpression;
  Str: string;
  Cod: string;
  Cnt: Integer;
begin
  while TokenType in [tk_Dot, tk_LBracket] do begin
   if SkipToken(tk_Dot) then begin
     if ex.Kind is TArray then
     begin
       DropToken(tkLength);
       ex.code := ex.Code + SWFPushString('length') + acGetMember;
       ex.Kind := _Integer;
     end else
     if IsRecord(ex.Kind) then
     begin
       s := RecordField(RealType(ex.Kind) as TRecord);
       if s = nil then
         Error('C1116', 'Field expected');
       ex.code := ex.code + SWFPushString(s.codeName) + acGetMember;
       ex.Kind := TVariable(s).Kind;
     end else
     if (ex.Kind = _Variant) and (TokenType = tk_ident) then
     begin
       Str := SrcToken;
       DropToken(tk_Ident);
       if SkipToken(tk_LParen) then
       begin
     // variant.method()
        Cnt := 0;
        Cod := '';
        while not SkipToken(tk_RParen) do
        begin
          if Cnt > 0 then
            DropToken(tk_Comma);
          e := Expression;
          Cod := e.code + Cod;
          e.Free;
          Inc(Cnt);
        end;
        ex.code := Cod + SWFPushInteger(Cnt) + ex.Code + SWFCallMethod(Str);
       end else begin
     // variant.property
         ex.Code := ex.Code + SWFPushString(Str) + acGetMember;
       end;
       ex.Kind := _Variant;
     end else begin
       if not (ex.Kind is TClassDef) then
         Error('C1357', 'Class expected');
       s := ClassSymbol(ex.Kind as TClassDef);
       if s = nil then
         Error('C1360', 'Unknown method');
       if s is TVariable then begin
         ex.code := ex.code + SWFPushString(s.codeName) + acGetMember;
         ex.kind := TVariable(s).Kind;
       end else
       if s is TProperty then begin
         PropertyExpression(ex, TProperty(s));
       end else
       if s is TMethod then begin
         ex.code := CallMethod(ex.code, TMethod(s));
         ex.kind := TMethod(s).proto.Kind;
       end else
         Error('C1087', 'Unexpected variable suffix '+s.className);
     end;
   end else begin // Brackets
     DropToken(tk_LBracket);
     if ex.Kind = _String then
     begin
       ex.Code := SWFOptimize(IntegerCode +  {SWFPushInteger(1)+ acSubstract} acDecrement + SWFPushInteger(1) + ex.Code) + SWFCallMethod('charAt');
       ex.Kind := _Char;
     end else
     if IsArray(ex.Kind) then
     begin
       ex.code := ex.code + GetArrayIndex(ex.Kind) + acGetMember
       //GetArrayItem(ex);
     end else
     if (ex.Kind = _Variant) then
     begin
       e := Expression;
       ex.Code := ex.Code + e.Code + acGetMember;
       e.Free;
       ex.Kind := _Variant;
     end else
     if ex.Kind is TClassDef then
     begin
       p := TClassDef(ex.Kind).Default;
       if p <> nil then
         PropertyExpression(ex, TProperty(p))
       else begin
         e := Expression;
         ex.Code := ex.Code + e.Code + acGetMember;
         e.Free;
         ex.Kind := _Variant;
       end;
     (**
       p := ClassLookup(TClassDef(ex.Kind), '[]');
       if p = nil then
       begin
         p := TClassDef(ex.Kind).Default;
         if p = nil then
           Error('C2618', 'no default property');
         PropertyExpression(ex, TProperty(p));
       end else begin
         if (not (p is TProperty)) then
           Error('C1104', 'not a property');
         e := Expression;
         ex.Code := ex.Code + e.code + acGetMember;
         e.Free;
         ex.Kind := TProperty(p).Kind;
       end;
     **)
     end else
       Error('C1110', 'Array expected'); // array or char index
     DropToken(tk_RBracket);
   end;
 end;
end;

function TCompiler.IntegerExpression: TExpression;
begin
  Result := Expression;
  if not IsInteger(Result.Kind)  then
    Error('C1482', 'Integer expected');
end;

function TCompiler.IntegerCode: string;
var
  e: TExpression;
begin
  e := IntegerExpression;
  Result := e.Code;
  e.Free;
end;

function TCompiler.StringExpression: TExpression;
begin
  Result := Expression;
  if (Result.Kind <> _String) and (Result.Kind <> _Char) then
    Error('C1136', 'String expected');
end;

function TCompiler.StringCode: string;
var
  e: TExpression;
begin
  e := StringExpression;
  Result := e.Code;
  e.Free;
end;

function TCompiler.Expression1:TExpression;
var
  m: TMethod;
  c: TClassDef;
  s: string;
  sc: PScope;
  code: string;
  count: Integer;
  Kind: TSymbol;
begin
  if TokenIndex([
    tkNil, tkSelf, tkNot,
    tkIntToStr, tkFloatToStr, tkTrunc, tkBoolToStr,
    tkPos, tkCopy, tkAbs, tkLength,
    tkHigh, tkLow,
    tkOrd, tkChr,
    tkTrue, tkFalse,
    tkInherited]) = tk_Ident then
    TokenSymbol;
  case TokenType of
   tk_Unit:
    begin
      sc := @TUnit(Symbol).Source.Scope;
      NextToken;
      DropToken(tk_Dot);
      TokenSymbol(sc);
    end;
  end;
  case TokenType of
    tkNil:
    begin
      NextToken;
      Result:= TExpression.Create(Self);
      Result.code:=SWFPushNull;//SWFPushUndefined;
      Result.kind:=_Object;
    end;
    tkSelf:
    begin
      if FCurrentClass = nil then
        Error('C1622', 'Self outside a class method');
      NextToken;
      Result := TExpression.Create(Self);
      Result.Code := getSelf;
      Result.Kind := FCurrentClass;
      VarSuffix(Result);
    end;
    tkNot:
    begin
      NextToken;
      Result := Expression;
      Result._Not;
    end;
    tk_Add:
    begin
      NextToken;
      Result := Expression;
      if not IsNumber(Result.Kind) then
        Error('C1173', 'Integer or Double expected');
    end;
    tk_LParen:
    begin
      NextToken;
      Result := Expression;
      DropToken(tk_RParen);
    end;
    tk_String:
    begin
      Result := TExpression.Create(Self);
      Result.code := SWFPushString(Token);
      if Length(Token) = 1 then // ----------------------------------------------- UCS-2/UTF-8 ?
        Result.Kind := _Char
      else
        Result.Kind := _String;
      NextToken;
    end;
    tkIntToStr:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := IntegerExpression;
      DropToken(tk_RParen);
      Result.Kind := _String; // nothing else to do ? or add acString(#$4B)
    end;
    tkFloatToStr:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := Expression;
      if not IsDouble(Result.Kind) then
        Error('C1200', 'Double expected');
      DropToken(tk_RParen);
      Result.Kind := _String; // nothing else to do ? or add acString(#$4B)
    end;
    tkTrunc:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := Expression;
      if not IsDouble(Result.Kind) then
        Error('C1209', 'Double expected');
      DropToken(tk_RParen);
      Result.Code := Result.Code + acIntegralPart;
      Result.Kind := _Integer;
    end;
    tkBoolToStr:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := Expression;
      if Result.Kind <> _Boolean then
        Error('C1219', 'Boolean expected');
      DropToken(tk_RParen);
      Result.Kind := _String; // nothing else to do ? or add acString(#$4B)
    end;
    tkPos:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := StringExpression;
      DropToken(tk_Comma);
      Result.Code := Result.Code + SWFPushInteger(1) + StringCode;
      DropToken(tk_RParen);
      Result.Code := SWFOptimize(Result.Code + SWFPushString('indexOf')) + acCallMethod + acIncrement;
      Result.Kind := _Integer;
    end;
    tkCopy:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := StringExpression;
      DropToken(tk_Comma);
      Result.Code := Result.Code + IntegerCode;
      DropToken(tk_Comma);
      Result.Code := Result.Code + IntegerCode;
      DropToken(tk_RParen);
      Result.code := Result.code + acSubStringMulti; // acSubString
    end;
    tkAbs:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := Expression;
      if not IsNumber(Result.Kind) then
        Error('C1264', 'Number expected');
      DropToken(tk_RParen);
      Result.Code := Result.Code + acDuplicate + SWFPushInteger(0) + acGreaterThan;
      s := SWFPushInteger(0) + acSwap + acSubstract;
      Result.Code := Result.Code + BranchIfEq(Length(s)) + s;
    end;
    tkLength:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := Expression;
      if Result.Kind = _String then
      begin
        Result.Code:=Result.Code+acStringLengthMulti; // acStringLength
        Result.Kind:=_Integer;
      end else
      if Result.Kind is TArray then
      begin
        Result.Code := Result.Code + SWFPushString('length') + acGetMember;
        Result.Kind:=_Integer;
      end else
        Error('C1285', 'String or Array expected');
      DropToken(tk_RParen);
    end;
    tkHigh:
    begin //ARRAY size: ._high for fixed arrays and 'array.length-1' for ._open
      NextToken;
      DropToken(tk_LParen);
      if IsType then
      begin
        if IsSet(Symbol) then
        begin
          Result := TExpression.Create(Self);
          Result.Kind := Symbol;
          Result.code := SWFPushInteger((RealType(Symbol) as TSet).Last.Value.AsInt64);
          NextToken;
        end else begin
          Result := nil;
          Error('C1716', 'Unexpected type');
        end;
      end else begin
        Result:= Expression;
        if not (Result.Kind is TArray) then
          Error('C1296', 'Array variable expected');
        if TArray(Result.Kind)._open then
          Result.Code := Result.Code + SWFGetMember('length') + acDecrement // 'cause we need the highest index and not the length
        else
          Result.Code := SWFPushInteger(TArray(Result.Kind).Range._high);
        Result.Kind := _Integer;
      end;
      DropToken(tk_RParen);
    end;
    tkLow:
    begin //ARRAY size: ._low for fixed arrays and 0 for ._open
      //Result:= TExpression.Create(Self);
      NextToken;
      DropToken(tk_LParen);
      // Low(Type)
      if IsType then
      begin
        if IsSet(Symbol) then
        begin
          Result:= TExpression.Create(Self);
          Result.Kind := Symbol;
          Result.Code := SWFPushInteger((RealType(Symbol) as TSet).First.Value.AsInt64);
          NextToken;
        end else begin
          Result := nil;
          Error('C1734', 'Unexpected type');
        end;
      end else begin
        Result := Expression;
        if not (Result.Kind is TArray) then
          Error('C1357', 'Array variable expected');
        if TArray(Result.Kind)._open then
          Result.Code := SWFPushInteger(0)
        else
          Result.Code := SWFPushInteger(TArray(Result.Kind).Range._low);
        Result.Kind := _Integer;
      end;
      DropToken(tk_RParen);
    end;
    tkOrd:
    begin
      NextToken;
      DropToken(tk_LParen);

      Result := Expression;

      if IsSet(Result.Kind) then
      begin
        // ok
      end else begin
        if Result.Kind = _Boolean then
        begin
          // Ord(Boolean)
          Result.code := BoolToInteger(Result.code);
        end else begin
          if Result.Kind <> _Char then
            Error('C1709', 'Char expected');
          Result.Code := Result.Code + acOrdMulti; // acOrd
        end;
      end;

      DropToken(tk_RParen);
      Result.Kind := _Integer;
    end;
    tkChr:
    begin
      NextToken;
      DropToken(tk_LParen);
      Result := IntegerExpression;
      DropToken(tk_RParen);
      Result.Code:=Result.Code+acChrMulti; // acChr
      Result.Kind := _Char;
    end;
    tk_Sub:
    begin
      NextToken;
      Result := Expression1;
      Result.Negate;
    end;
    tkTrue, tkFalse:
    begin
      Result := TExpression.Create(Self);
      Result.Kind := _Boolean;
      Result.Code := SWFPushBoolean(TokenType = tkTrue);
      NextToken;
    end;
    tk_Number:
    begin
      Result:=TExpression.Create(Self);
      if BitsCount(Token) > 32 then
      begin
        Result.Code := SWFPushDouble(StrToFloat(Token));
        Result.Kind := _Double;
      end else begin
        Result.Code := SWFPushInteger(StrToInt(Token));
        Result.kind:=_Integer;
      end;
      NextToken;
    end;
    tk_Float:
    begin
      Result:=TExpression.Create(Self);
      Result.Code := SWFPushDouble(StrToFloat(Token));
      Result.Kind := _Double;
      NextToken;
    end;
    tk_Variable:
    begin
      Result:=TExpression.Create(Self);
      CodeItem.Depends.Add(Variable);
      Result.Code := GetVariable(Variable);
      Result.Kind := RealType(Variable.Kind);
      NextToken;
      VarSuffix(Result);
    end;
    tk_Property:
    begin
      CodeItem.Depends.Add(Symbol);
      Result := TExpression.Create(Self);
      Result.Kind := TProperty(Symbol).Kind;
      if TProperty(Symbol).onGet = nil then
        Result.Code := SWFOptimize(GetThis + SWFPushString(Symbol.codeName)) + FGetThisMember
      else
      case TProperty(Symbol).onGet.Token of
        tk_Variable:
        begin
          Variable := TVariable(TProperty(Symbol).onGet);
          CodeItem.Depends.Add(Variable);
          Result.Code := GetVariable(Variable);
          Result.Kind := Variable.Kind;
          VarSuffix(Result);
        end;
        tk_Method:
        begin
          Count := 0;
          if TMethod(TProperty(Symbol).onGet).proto = nil then
            code := ''
          else
            code := PushParams(TMethod(TProperty(Symbol).onGet).proto, Count);
          Result.code := SWFOptimize(code +SWFPushInteger(count) + GetThis +SWFCallMethod(TMethod(TProperty(Symbol).onGet).localName));
        end;
      else
        Error('C1603', 'Unknow getter');
      end;
      NextToken;
      VarSuffix(Result);
    end;
    tk_Constant:
    begin
      CodeItem.Depends.Add(Symbol);
      Result:=TExpression.Create(Self);
      Result.Kind := TConstant(Symbol).Kind;
      Result.Code := GetConstantCode(TConstant(Symbol).Value);
      NextToken;
      VarSuffix(Result);
    end;
    tk_Parameter:
    begin
      CodeItem.Depends.Add(Symbol);
      Result:=TExpression.Create(Self);
      Result.Code := GetParameter(Parameter);
      Result.Kind := Parameter.Kind;
      NextToken;
      VarSuffix(Result);
    end;
    tkInherited:
    begin
      if FCurrentClass = nil then
        Error('C1632', 'inherited outside a class method');
      NextToken;
      Symbol := InheritedSymbol(FCurrentClass, True);
      if Symbol is TMethod then
      begin
        CodeItem.Depends.Add(Symbol);
        m := TMethod(Symbol);
        Result := TExpression.Create(Self);
        Result.Kind := m.proto.Kind;
        m.NeedParent := True;
        if FCurrentClass.Aliased then
          Result.Code := CallMethod(GetThis, m)
        else
          Result.Code := CallMethod(SWFGetRegister(2), m);
      end else begin
        Error('C1621', 'unexpected inherited symbol');
        Result := nil;
      end;
    end;
    tk_Method:
    begin
      CodeItem.Depends.Add(Symbol);
      m := TMethod(Symbol);
      NextToken;
      Result := TExpression.Create(Self);
      Result.Kind := m.proto.Kind;
      if (m.realName[1] = '/') and (m.proto.Count = 0) then
      begin
        Result.Code := SWFGetVariable(m.realName);
        if SkipToken(tk_LParen) then
          DropToken(tk_RParen);
      end else
      if (m.Externe = '') or (m.SysCall > 0) then
      begin
        if m.Owner = nil then
        begin
          Result.Code := CallMethod('', m)
        end else begin
          Result.Code := CallMethod(GetThis, m);
        end;
      end else begin
        Result.Code := CallMethod(SWFGetVariable(m.Externe),m);
      end;
    end;
    tk_Class:
    begin
      CodeItem.Depends.Add(Symbol);
      c := TClassDef(Symbol);
      NextToken;
      if SkipToken(tk_LParen) then
      begin
        Result := Expression;
        if not IsObject(Result.Kind) then
          Error('C1422', 'Object expected');
        DropToken(tk_RParen);
        Result.Kind := c;
      end else begin
        Result := ClassExpression(c);
      end;
      VarSuffix(Result);
    end;
    tk_ident:
    begin
      Error('C1375', 'Unknow symbol ' + SrcToken);
      Result := nil;
    end;
    tk_LBracket:
    begin
      NextToken;
      Result := TExpression.Create(Self);
      if (TokenSymbol(@Scope) = tk_Constant) and (IsSet(TConstant(Symbol).Kind)) then
      begin
        Result.Kind := TSet(RealType(TConstant(Symbol).Kind)).SetOf;
        Result.Code := SWFPushInteger(GetConstantSetOf(TSet(RealType(TConstant(Symbol).Kind))));
      end else begin
        Result.Kind := _Object;
        Result.code := PushStaticObject;
      end;
    end;
    tk_Type,
    tk_BaseType:
    begin
      Kind := Symbol;
      NextToken;
      DropToken(tk_LParen);
      Result := Expression;
      // Rustine
      if (Result.Kind = _Boolean) and (Kind = _Integer) then
      begin
        Result.Code := BoolToInteger(Result.Code);
      end;
      DropToken(tk_RParen);
      Result.Kind := Kind;
    end;
  else
    Error('C1378', 'Unknow symbol : ' + SrcToken);
    Result := nil;
  end;
end;

function TCompiler.Expression2:TExpression;
var
  op: TToken;
  ex: TExpression;
begin
  Result:=Expression1;
  while TokenIndex([tkDIV, tkMOD, tkAND, tkSHL, tkShrSigned, tkShrUnsigned]) in
   [tk_Mul, tkDiv, tkMod, tk_Slash, tkAnd,  tkShl, tkShrSigned, tkShrUnsigned, tk_Shl, tk_ShrSigned, tk_ShrUnsigned]
  do begin
    op:=TokenType;
    NextToken;
    ex:=Expression1;
    case op of
      tk_Mul  : Result.MulBy(ex);
      tkDiv   : Result.DivBy(ex);
      tkMod   : Result.Modulo(ex);
      tk_Slash: try Result.Divide(ex) except Error('C1534', 'Div by 0') end;
      tkAnd   : Result._And(ex);
      tkShl,tk_Shl                 : Result._Shl(ex);
      tkShrSigned,tk_ShrSigned     : Result._ShrSigned(ex);
      tkShrUnsigned,tk_ShrUnsigned : Result._ShrUnsigned(ex);
    end;
  end;
end;

function TCompiler.Expression3:TExpression;
var
  op: TToken;
  ex: TExpression;
begin
  Result := Expression2;
  while TokenIndex([tkOr, tkXor]) in [tk_Add, tk_Sub, tkOr, tkXor] do
  begin
    op:=TokenType;
    NextToken;
    ex:=Expression2;
    case op of
      tk_Add : Result.Add(ex);
      tk_Sub : Result.Sub(ex);
      tkOr   : Result._Or(ex);
      tkXor  : Result._Xor(ex);
    end;
  end;
end;

function TCompiler.Expression:TExpression;
var
  op: TToken;
  ex: TExpression;
begin
  Result := Expression3;
  while TokenIndex([tkIN]) in [tk_EQ, tk_GT, tk_LS, tk_GE, tk_LE, tk_NE, tkIN] do
  begin
    op := TokenType;
    NextToken;
    ex := Expression3;
    case op of
      tk_EQ : Result.IsEqual(ex);
      tk_GT : Result.IsGreater(ex);
      tk_LS : Result.IsLesser(ex);
      tk_GE : Result.IsGreaterOrEqual(ex);
      tk_LE : Result.IsLesserOrEqual(ex);
      tk_NE : Result.IsNotEqual(ex);
      tkIN  : Result.IsIn(ex);
    end;
  end;
end;

function TCompiler.GetConstantCode(AValue: TConstantValue): string;
begin
  case AValue.ValueType of
    vtSet,
    vtInteger: Result := SWFPushInteger(AValue.AsInt64);
    vtFloat  : Result := SWFPushDouble(AValue.AsFloat);
    vtString : Result := SWFPushString(AValue.AsString);
    vtArray  : Result := AValue.AsArray;
  else
    Error('C1957', 'GetConstantCode');
  end;
end;

function TCompiler.GetArray: TArray;
var
  final: TArray;
  next : TArray;
begin
  NextToken;
  Result := TArray.Create(tk_Array);
  Result.NextSymbol := Anonyms;
  Anonyms := Result;
  final := Result;
  if SkipToken(tkOf) then
    Result._open := True
  else begin
    Result._open := False;
    DropToken(tk_LBracket);

    // todo: GetRange : array of [Word], array of [TValues], ...
    Result.Range := GetRange;
//    Result._low := GetInteger;
//    DropToken(tk_Range);
//    Result._high := GetInteger;

    while SkipToken(tk_Comma) do
    begin
      next := TArray.Create(tk_Array);
      next.NextSymbol := Anonyms;
      Anonyms := Next;
      next.Range := GetRange();
      //next._low := GetInteger;
      //DropToken(tk_Range);
      //next._high := GetInteger;
      final._kind := next;
      final := next;
    end;

    DropToken(tk_RBracket);
    DropToken(tkOf);
  end;
  final._kind := GetType;
  Result.Name := 'array of ' + final._Kind.realName;
end;

function TCompiler.GetRange: TRange;
begin
  Result := TRange.Create(tk_Range);
  Result.NextSymbol := Anonyms;
  Anonyms := Result;
  Result.Kind := _Integer;
  Result._Low := GetInteger;
  DropToken(tk_Range);
  Result._High := GetInteger;
end;

function TCompiler.GetRecord: TRecord;
var
  s: PScope;
begin
  NextToken;
  Result := TRecord.Create(tk_Record);
  Result.NextSymbol := Anonyms;
  Anonyms := Result;
  s := Scopes;
  try
    Result.Scope.Next := Scopes;
    Scopes := @Result.Scope;
    while Token <> 'END' do
    begin
      Result.Init1 := SWFOptimize(Result.Init1 + DeclareField(Result));
      if Token <> 'END' then
        DropToken(tk_SemiColon);
    end;
    Result.Init1 := SWFOptimize(Result.Init1 + SWFPushInteger(Result.Count)) + acDeclareObject;
    NextToken;
  finally
    Scopes := s;
  end;
end;

function TCompiler.GetSet: TSet;
var
  c: TConstant;
  v: Integer;
  i: Integer;
begin
  Result := TSet.Create;
  Result.NextSymbol := Anonyms;
  Anonyms := Result;

  v := 0;
  repeat
    c := TConstant.Create(tk_Constant);
    c.realName := SrcToken;
    c.CodeName := GetName('c', FPrefix + c.RealName);
    c.Name := GetIdent;
    c.Kind := Result;

    if v = 0 then
      Result.First := c;
    Result.Last := c;
    Inc(Result.Count);

    if SkipToken(tk_EQ) then
    begin
      i := GetInteger;
      if i < v then
        Error('C2156', 'Invalid value');
      v := i;
    end;

    c.Value.ValueType := vtSet;
    c.Value.AsInt64 := v;
    Inc(v);

    c.NextSymbol := Scopes.Symbol;
    Scopes.Symbol := c;

    if TokenType <> tk_RParen then
      DropToken(tk_Comma);
  until SkipToken(tk_RParen);
end;

function TCompiler.GetSetOf: TSetOf;
var
  Kind: TSymbol;
begin
  Result := nil;
  NextToken;
  DropToken(tkOf);
  {
  Result := TSetOf.Create(tk_SetOf);
  Result.NextSymbol := Anonyms;
  Anonyms := Result;
  }
  Kind := GetType;
  if RealType(Kind) is TSet then
    //Result.Items := Kind
    Result := TSet(RealType(Kind)).SetOf
  else
    Error('C2058', 'Set expected');
end;

function TCompiler.IsType: Boolean;
begin
  Result := False;
  if TokenType <> tk_Ident then
    Exit;
  case TokenSymbol(@Scope) of
    tk_BaseType, tk_Type, tk_Class, tk_Prototype: Result := True;
  end;
end;

// NB: Flash do not use typed variable, but we are Pascal programmers :D
function TCompiler.GetType: TSymbol;
var
  void: Boolean;
  s: PScope;
begin
  Result := nil;
  if SkipToken(tk_LParen) then
    Result := GetSet
  else
  case TokenIndex([tkProcedure, tkFunction, tkObject, tkArray, tkRecord, tkSet]) of
    tk_Class:
    begin
      Result := Symbol;
      NextToken;
    end;
    tkProcedure,
    tkFunction:
    begin
      void := TokenType = tkProcedure;
      NextToken;
      Result := FunctionPrototype('',  void);
    end;
    tkObject:
    begin
      Result := _Object;
      NextToken;
    end;
    tkArray: Result := GetArray;
    tkSet  : Result := GetSetOf;
    tk_Ident:
    begin
      case TokenSymbol(@Scope) of
        tk_Unit:
        begin
          s := Scopes;
          Scopes := @TUnit(Symbol).Source.Scope;
          NextToken;
          DropToken(tk_Dot);
          Result := GetType;
          Scopes := s;
        end;
        tk_BaseType, tk_Type, tk_Class, tk_Prototype :
        begin
          Result := Symbol;
          NextToken;
        end;
        tk_Symbol:
          if (Symbol is TBaseType) or (Symbol is TBaseTypeAlias) or (Symbol is TClassDef) or (Symbol is TFunction) then
          begin
            Result := Symbol;
            NextToken;
          end else begin
            Error('C1513', 'Type expected');
            Result := nil;
          end;
        else
          Error('C2101', 'Unknow ident ' + SrcToken);
      end;
    end;
    tkRecord: Result := GetRecord;
  else
    Error('C1521', 'Type expected');
  end;
end;

function TCompiler.GetClass: TClassDef;
var
  s: TSymbol;
begin
  s := GetType;
  if not (s is TClassDef) then
    Error('C1579', 'Class expected');
  Result := TClassDef(s);
end;

function TCompiler.BuildArray(Arr: TArray): string;
var
  Kind : TSymbol;
  Count: Integer;
  Index: Integer;
begin
  Result := '';
  Count := 0;
  if Arr._open = False then
  begin
    Kind := RealType(Arr._kind);
    if Kind is TArray then
    begin
      Count := Arr.Range._high - Arr.Range._low + 1;
      for Index := 0 to Count - 1 do
        Result := Result + BuildArray(TArray(Kind));
    end else
    if Kind is TRecord then
    begin
      Count := Arr.Range._high - Arr.Range._low + 1;
      for Index := 0 to Count - 1 do
        Result := Result + TRecord(Kind).Init1;
    end;
  end;
  Result := Result + SWFPushInteger(Count) + SWFNewObject('Array');
end;

function TCompiler.DeclareField(Owner: TRecord): string;
var
  k: TSymbol;
  v: TVariable;
begin
  Inc(Owner.Count);
  v := TVariable.Create(tk_Variable);
  v.Owner := Owner;
  v.realName := SrcToken;
  v.codeName := GetName('f', v.realName);
  v.name := GetIdent;
  v.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := v;
  if SkipToken(tk_Comma) then
  begin
    Result := DeclareField(Owner);
    v.Kind := TVariable(Scopes.Symbol).Kind;
  end else begin
    Result := '';
    DropToken(tk_Colon);
    v.Kind := GetType;
  end;

  Result := Result + SWFPushString(v.codeName);

  k := RealType(v.Kind);
  if k is TArray then
    Result := Result + BuildArray(TArray(k))
  else
  if k is TRecord then
    Result := Result + TRecord(k).Init1
  else
  if IsNumber(k) then
    Result := Result + SWFPushInteger(0)
  else
    Result := Result + SWFPushUndefined;
end;

// var declaration
function TCompiler.DeclareVar(Owner: TSymbol; local: Boolean): string;
var
  v: TVariable;
  c: TCodeItem;
  r: TSymbol;
begin
  v := TVariable.Create(tk_Variable);
  v.Owner := Owner;

  v.realName := SrcToken;
  v.codeName := SrcToken;
  // unique name
  r := GetSymbol(Scopes.Symbol);
  if r <> nil then
    Error('C2375', 'Duplicate symbol');
  v.name := GetIdent;
  v.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := v;
  if SkipToken(tk_Comma) then
  begin
    Result := DeclareVar(Owner, local);
    v.Kind := TVariable(Scopes.Symbol).Kind;
    v.Externe := TVariable(Scopes.Symbol).Externe;
  end else begin
    Result := '';
    DropToken(tk_Colon);
    v.Kind := GetType;
    v.Externe := SkipToken(tkExternal);
  end;

  // fix 02/06/2013, on touche à CodeItem *après* l'appel récursif à DeclareVar
  if Owner = nil then
  begin
    c := CodeItem;
    CodeItem := TCodeItem.Create(Self, nil);
    v.CodeItem := CodeItem;
  end else
    c := nil;

  if (Owner = nil) and (not Local) and (v.Externe = False) then
    v.CodeName := GetName('v', FPrefix + v.codeName);

  if v.Owner is TMethod then
  begin
 {$IFDEF REG_VARS}
    v.Reg := TMethod(v.Owner).proto.regs;
    Inc(TMethod(v.Owner).proto.Regs);
 {$ENDIF}
  end;

  r := RealType(v.Kind);
  if (Owner <> nil) and (not Local) and IsNumber(r) then
  begin
    Result := Result + SWFOptimize(GetThis + SWFPushString(v.CodeName) + SWFPushInteger(0)) + FSetThisMember;
  end else
  if IsArray(r) then
  begin
    if (v.Owner = nil) or local then
      Result := Result + SetVariable(v, BuildArray(TArray(r)))
    else
      Result := Result + SWFOptimize(GetThis + SWFPushstring(v.codeName) + BuildArray(TArray(r))) + FSetThisMember;
  end else
  if IsRecord(r) then
  begin
    v.IsSet := True;
    if (v.Owner = nil) or local then
      Result := Result + SetVariable(v, TRecord(r).Init1)
    else
      Result := Result + SWFOptimize(GetThis + SWFPushString(v.codeName) + TRecord(r).Init1) + FSetThisMember;
  end;

  if Owner = nil then
  begin
    // var v: Video external 'my_video'
    if v.Externe and IsObject(v.Kind) and (TokenType = tk_String) then
    begin
      //Result := SWFOptimize(SWFPushString(v.CodeName) + SWFPushString('_root')) + acGetVariable + SWFPushString(Token) + acGetMember + acSetLocalVar;
      v.CodeName := Token;
      NextToken;
    end else begin
      if (Result = '') and (v.Externe = False) then
        Result := SWFPushString(v.CodeName) + acDeclareLocalVar;
    end;
    CodeItem.Code := Result;
    Result := '';
    CodeItem := TCodeItem.Create(c, nil);
  end;

end;

// one method parameter
function TCompiler.GetParam(Proto: TPrototype; Prev:TParameter; Owner: TFunction):TParameter;
var
  p: TParameter;
  e: TExpression;
begin
  Result := TParameter.Create(tk_Parameter);
// param1,param2 : type
  if Prev = nil then
  begin
    if SkipToken(tkConst) then Result.IsConst := True else
    if SkipToken(tkVar)   then
    begin
      Inc(Proto.ByRefs);
      Result.ByRef := Proto.ByRefs;
    end;
  end else begin
    Result.IsConst := Prev.IsConst;
    Result.ByRef := Prev.ByRef;
  end;
{$IFDEF REG_PARAM}
  Result.Reg := Proto.regs;
  Inc(Proto.Regs);
{$ENDIF}
// param name
  Result.realName := SrcToken;
  if not Obfuscate then
    Result.codeName := SrcToken;
  Result.name:=GetIdent;
// check for duplicates
  p := Proto.params;
  while p <> nil do
  begin
    if p.name = Result.name then
      Error('C1682', 'Duplicate identifier'); // Duplicate param name
    p := p.NextParam;
  end;
// add the parameter to the method
  Result.NextParam := Proto.params;
  Result.NextSymbol := Scopes.Symbol; // prepare linked list
  Scopes.Symbol := Result;
  Proto.params := Result;
  Inc(Proto.count);
// one more ?
  if SkipToken(tk_Comma) then
  begin
    p := GetParam(Proto, Result, Owner);
    Result.Kind := p.Kind;
    Result.Default := p.Default;
  end else begin
// get type
    DropToken(tk_Colon);
    Result.Kind := GetType;
 // default value ?
    if SkipToken(tk_EQ) then
    begin
      e := Expression;
      if not e.IsType(Result.Kind) then
        Error('C1664', 'Type mismatch');
      if (Owner is TMethod) and (TMethod(Owner).Owner <> nil) and not (TMethod(Owner).Owner.userClass) then
        Result.Default := acEndAction
      else
        Result.Default := e.Code;
      e.Free;
    end;
  end;
end;

// read a class method
function TCompiler.GetMethod(AClass: TClassDef; void: Boolean; isConstructor: Boolean): TMethod;
var
  s: PScope;
  m: TMethod;
begin
 // m := nil;
  if AClass = nil then
  begin
    // forward method
    if (TokenType = tk_Method) and (Symbol.Level = @Scope) then
    begin
      Result := TMethod(Symbol);
      if Result.Owner <> nil then
        Error('C1881', 'Unexpected method found');
      if Result.CodeItem <> nil then
        Error('C2003', 'function already defined');
      ImplementStatic(Result);
      Exit;
    end;
  end else begin
    if (GetSymbol(AClass.Scope.Symbol) <> nil) then
      Error('C1725', 'Duplicate ident');
  end;

  m := TMethod.Create(tk_Method);
  m.IsConstructor := isConstructor;
  m.Row := Line;
  m.Col := Index;
  m.Proto := TPrototype.Create(tk_Prototype);
  m.Owner := AClass;
  if (AClass <> nil) and (isConstructor = False) then
  begin
    m.NextMethod := AClass.Methods;
    AClass.Methods := m;
  end;
  // we need a case sensitive name !
  m.realName := SrcToken;
  m.localName := SrcToken;
  if AClass = nil then
  begin
    m.CodeName := GetName('p', FPrefix + SrcToken);
  end else begin
    if AClass._external then
    begin
      m.codeName := m.realName;
    end else begin
      if (length(m.realName) < 3) or (copy(m.realName, 1, 2) <> 'on') or (m.realName[3] <> Upcase(m.realName[3])) then
        m.localName := GetName('l', m.realName);
      if IsConstructor then
        m.codeName := GetName('C', FPrefix + AClass.realName + '_' + m.realName)
      else
        m.codeName := GetName('m', FPrefix + AClass.realName + '_' + m.realName);
    end;
  end;
  m.name := GetIdent;
  m.proto.Regs:=3; // 1 this, 2 = parent : need a better code optimization to avoid those 2 regs
  s := Scopes;
  m.Scope.Next := Scopes;
  Scopes := @m.Scope;
  if TokenType = tk_LParen then begin
    NextToken;
    while not SkipToken(tk_RParen) do begin
      GetParam(m.Proto, nil, m);
      if TokenType <> tk_RParen then DropToken(tk_SemiColon);
    end;
  end;
  if not void then
  begin
  // function method
    DropToken(tk_Colon);
    m.proto.Kind := GetType;
    m.proto.Return := TVariable.Create(tk_Variable);
    m.proto.Return.Owner := m;
    m.proto.Return.Name := 'RESULT';
    m.proto.Return.realName := '$Result';
    m.proto.Return.codeName := '$$';
    m.proto.Return.NextSymbol := Scopes.Symbol;
    Scopes.Symbol := m.proto.Return;
    m.proto.Return.Kind := m.proto.Kind;
  {$IFDEF REG_VARS}
    m.proto.Return.Reg := m.proto.Regs;
    Inc(m.proto.Regs);
  {$ENDIF}
  end;
(*
  if AClass <> nil then
  begin
    i := LookupInherited(AClass, m.Name);
    if (i <> nil) and (i is TMethod) then
    begin
      if TMethod(i).IsVirtual then
      begin
        if not SkipToken(tk_SemiColon) then
          TWarning.Create('C2107', 'Expected override', Provider.FileName, Line, Index)
        else
        if not SkipToken(tkOverride) then
          TWarning.Create('C2110', 'Expected override', Provider.FileName, Line, Index)
        else
          if TMethod(i).Owner._external then
            m.localName := TMethod(i).localName;
      end;
    end;
  end;
*)
  Scopes := s;
  m.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := m;
  Result := m;
end;

procedure TCompiler.ImplementStatic(AMethod: TMethod);
var
  sc: PScope;
  ci: TCodeItem;
//  oldExit: string;
begin
  if Symbol.Level <> @Scope then
    Error('C1935', 'function out of scope');
  DropIdent(AMethod.Name);
  //--

  ci := CodeItem;
  CodeItem := TCodeItem.Create(Self, nil);
  AMethod.CodeItem := CodeItem;

  sc := Scopes;
  Scopes := @AMethod.Scope;

  if AMethod.proto.params <> nil then
  begin
    DropToken(tk_LParen);
    DropParams(AMethod.proto.params);
    DropToken(tk_RParen);
  end else begin
    if SkipToken(tk_LParen) then DropToken(tk_RParen);
  end;

  if AMethod.proto.Kind <> nil then
  begin
    DropToken(tk_Colon);
    DropIdent(AMethod.proto.Kind.name);

    if IsArray(AMethod.proto.Kind) then
      CodeItem.Code := SetVariable(AMethod.proto.Return, BuildArray(TArray(RealType(AMethod.proto.Kind))))
    else
    if IsRecord(AMethod.proto.Kind) then
      CodeItem.Code := SetVariable(AMethod.proto.Return, TRecord(RealType(AMethod.proto.Kind)).Init1);
  end;

  CodeItem := TCodeItem.Create(Self, ci);
  Scopes := sc;
end;

function TCompiler.MethodAlias(m:TMethod):TMethod;
begin
  // MethodAlias - reserved word override operator is 'AS'
// we need a case sensitive name !
  m.realName := SrcToken;
  GetIdent;
  while SkipToken(tk_Dot) do
  begin // this is valid!
    m.realName := m.realName + '.' + SrcToken;
    GetIdent;
  end;
  m.codeName := m.realName;
  Result:=m;
end;

// we use a special syntax to define a pseudo constructor for "MovieClip.createTextField(instanceName,...)"
// constructor Create(Parent:MovieClip,...) as Parent.createTextField
procedure TCompiler.ConstructorAlias(m:TMethod);
var
 p:TParameter;
begin
// Last parm is the first one (reversed chained list)
 p:=m.LastParm;
// we need one
 if (p=nil) then
   Error('C1796', 'Method alias need at least one parameter');
// need to be a class
 if (p.Kind=nil)or(not(p.Kind is TClassDef)) then
   Error('C1799', 'Method alias need a parent class parameter');
// skip its name
 if GetIdent<>p.name then
   Error('C1802', p.name+' expected'); // on some bad declarations p.Name can be empty
// dot
 DropToken(tk_Dot);
// get alias
 m.alias:=SrcToken;
 GetIdent;
// save the parent
 m.Parent:=p;
// remove it from param list
 if m.proto.params=p then
  m.proto.params:=nil
 else begin
  p:=m.proto.params;
  while p.NextParam<>m.Parent do p:=p.NextParam;
  p.NextParam:=nil;
 end;
end;

// read class property
procedure TCompiler.GetProperty(AClass:TClassDef; Static: Boolean);
var
  p : TProperty;
begin
  p := TProperty.Create(tk_Property);
  p.Static := Static;
  p.Owner := AClass;
  // Special handling for [] property
  if SkipToken(tk_LBracket) then
  begin
    DropToken(tk_RBracket);
    p.name := '[]';
  end else begin
    if GetSymbol(AClass.Scope.Symbol) <> nil then
      Error('C1836', 'Duplicate ident');
  // we need a case sensitive name !
    p.realName := SrcToken;
    p.codeName := SrcToken;
    p.name := GetIdent;
  end;
  p.NextSymbol:=AClass.Scope.Symbol;
  AClass.Scope.Symbol := p;
  DropToken(tk_Colon);
  p.Kind := GetType;

  if SkipToken(tkReadOnly) then
    p.ReadOnly := True
  else
  if SkipToken(tkWriteOnly) then
    p.WriteOnly := True;
  if SkipToken(tkDeprecated) then
    p.Deprecate := True;
end;

// define an external class : a Flash class
procedure TCompiler.ExternalFlashClass(const ClassName, SymbolName:string);
var
  cl : TClassDef;
begin
  DropToken(tkClass);
  cl := TClassDef.Create(tk_Class);
  cl._external := True;
  cl.name := SymbolName;
  cl.realName := ClassName;
  cl.CodeName := ClassName;
  cl.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := cl;

  if TokenType = tk_SemiColon then
  begin
    cl._forward := True;
  end else begin
    DefineExternalFlashClass(cl);
  end;
end;

procedure TCompiler.ForwardClass(AClass: TClassDef);
begin
  NextToken;
  DropToken(tk_EQ);
  if AClass._external then
    DropToken(tkExternal)
  else begin
    AClass._external := SkipToken(tkExternal);
    AClass.userClass := not AClass._external;
  end;
  DropToken(tkClass);
  Aclass._forward := False;
  if Aclass._external then
    DefineExternalFlashClass(AClass)
  else
    UserClassDefine(AClass);
end;

procedure TCompiler.DefineExternalFlashClass(AClass: TClassDef);
var
  sc: PScope;
  mt: TMethod;
  cl: TClassDef;
  tt: TToken;
begin
  sc := Scopes;
  try
    try
      if SkipToken(tk_LParen) then
      begin
        // check for parent class
        tt := TokenType;
        if TokenSymbol(@Scope) = tk_Class then
          cl := TClassDef(Symbol)
        else begin
          cl := nil;
          TokenType := tt; // permet de déclarer la classe "System.capabilities" en tant que tt_Indent et non tt_Unit
        end;
        // we need a case sensitive name !
        AClass.realName := SrcToken;
        if TokenType = tk_Class then
          NextToken
        else
          GetIdent;
        if TokenType = tk_Comma then
        begin
          if (cl = nil) and (cl._external) then
           Error('C2285', 'Parent class expected');
          AClass._inherite := cl;
          NextToken;
          AClass.realName := SrcToken;
          GetIdent;
        end;
        while SkipToken(tk_Dot) do
        begin
          AClass.realName := AClass.realName + '.' + SrcToken;
          GetIdent;
        end;
        AClass.CodeName := AClass.realName;
        DropToken(tk_RParen);
      end;
      //AClass.scope.Symbol := Scopes.Symbol;
      AClass.scope.Next := Scopes;
      Scopes := @AClass.Scope;

      AClass.Reference := TReference.Create(tk_Reference);
      AClass.Reference.Structure := AClass;
      AClass.Reference.NextSymbol := Scopes.Symbol;
      Scopes.Symbol :=AClass.Reference;

      while not SkipToken(tkEnd) do
      begin
        mt := nil; // see below Virtual
        // todo: support multiple constructor ?
        if SkipToken(tkConstructor) then
        begin
          if AClass._constructor <> nil then
            Error('C1953', 'Duplicate constructor');
          AClass._constructor := GetMethod(AClass,true, True);
          AClass._constructor.proto.Kind := AClass;
          if SkipToken(tkAs) then
            ConstructorAlias(AClass._constructor);
        end else
        if SkipToken(tkClass) then
        begin
          if SkipToken(tkProperty) then
          begin
            GetProperty(AClass, True);
          end else
          if SkipToken(tkProcedure) then
          begin
            mt := GetMethod(AClass, True, False);
            mt.static := True;
            if SkipToken(tkAs) then
              MethodAlias(mt);
          end else begin
            DropToken(tkFunction);
            mt := GetMethod(AClass, False, False);
            mt.static := True;
            if SkipToken(tkAs) then
              MethodAlias(mt);
           {$IFDEF REG_VARS}
           Dec(mt.proto.Regs);
           {$ENDIF}
          end;
        end else
        if SkipToken(tkProcedure) then
        begin
          mt := GetMethod(AClass, True, False);
          if SkipToken(tkAs) then
            MethodAlias(mt); // MethodAlias - reserved word override operator is 'AS'
        end else
        if SkipToken(tkFunction) then
        begin
          mt := GetMethod(AClass, False, False);
          if SkipToken(tkAs) then
            MethodAlias(mt); // MethodAlias - reserved word override operator is 'AS'
          {$IFDEF REG_VARS}
          dec(mt.proto.Regs);
          {$ENDIF}
        end else
        // todo: readonly, writeonly attributes
        if SkipToken(tkProperty) then
        begin
          GetProperty(AClass, False); // PropertyAlias (included) - reserved word override operator is 'AS'
        end else
          Error('C2003', 'Unexpected token for class declaration'); // end expected
        if TokenType <> tkEnd then
          DropToken(tk_SemiColon);
        if (mt <> nil) and SkipToken(tkVirtual) then
        begin
          mt.IsVirtual := True;
          if TokenType <> tkEnd then
            DropToken(tk_SemiColon);
        end;
      end;

      AClass.Reference.Done := True;
    finally
      scopes := AClass.scope.Next;
    end;
  finally
    Scopes := sc;
  end;
end;

procedure TCompiler.DefineUserClass(const name,symbol:string);
var
  c: TClassDef;
begin
  c := TClassDef.Create(tk_Class);
  c.userClass := True;
  c.realName := name;
  c.codeName := GetName('o', FPrefix + c.RealName);
  c.name := symbol;
  c.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := c;

  if TokenType = tk_SemiColon then
    c._forward := True
  else
    UserclassDefine(c);
end;

procedure TCompiler.UserclassDefine(AClass: TClassDef);
var
  s: PScope;
  m: TMethod;
  p: TProperty;
  v: TSymbol;
  c: TCodeItem;
  base  : TClassDef;
  create: TMethod;
  alias : Boolean;
begin
  s := Scopes;
  try
    AClass.Scope.Next := Scopes; // global symbols are available in the scope of the class
    Scopes := @AClass.Scope;     // the Class is the main scope level

    c := CodeItem;  // save current CodeItem
    CodeItem := TCodeItem.Create(AClass, nil); // create a new one   --> Onwer = AClass to invoke BuildCode()
    AClass.CodeItem := CodeItem; // link it to this class

    // add a reference to this class is the scope chain
    AClass.Reference := TReference.Create(tk_Reference);
    AClass.Reference.Structure := AClass;
    AClass.Reference.NextSymbol := Scopes.Symbol;
    Scopes.Symbol := AClass.Reference;

    // iheritence
    if SkipToken(tk_LParen) then
    begin
      AClass._inherite := GetClass;
      CodeItem.Depends.Add(AClass._inherite);
      DropToken(tk_RParen);
    end;

    // for Self and Inherit keywords
    FCurrentClass := AClass;

    AClass.visibility := sPublic; // default

    alias := AClass.Aliased; // MovieClip.Create = Parent.createEmptyMovieClip

    while Token <> 'END' do
    begin
      m := nil; // not a method
      p := nil; // not a property
      case TokenIndex([tkConstructor, tkProcedure, tkFunction, tkProperty, tkPrivate, tkProtected, tkPublic]) of
        tkPrivate:
        begin
          AClass.visibility := sPrivate;
          NextToken;
          Continue;
        end;
        tkProtected:
        begin
          AClass.visibility := sProtected;
          NextToken;
          Continue;
        end;
        tkPublic:
        begin
          AClass.visibility := sPublic;
          NextToken;
          Continue;
        end;
        tk_Class,
        tk_Ident:
        begin
          AClass.init1 := AClass.init1 + DeclareVar(AClass, False);
        end;
        tkConstructor:
        begin
          NextToken;
          if AClass._constructor <> nil then
            Error('C2062', 'Duplicate constructor');
          AClass._constructor := GetMethod(AClass, True, True);
          AClass._constructor.proto.Kind := AClass;
        end;
        tkProcedure:
        begin
          NextToken;
          m := GetMethod(AClass, True, False);
          CodeItem.Depends.Add(m); // todo: keep only used methods
          if alias then
            AClass.init1 := AClass.init1 + SWFOptimize(GetThis + SWFPushString(m.localName) + SWFGetVariable(m.codeName)) + FSetThisMember
          else
            AClass.InitProto := AClass.InitProto + SWFOptimize(SWFGetRegister(2) + SWFPushString(m.localName) + SWFGetVariable(m.CodeName)) + acSetMember;
        end;
        tkFunction:
        begin
          NextToken;
          m := GetMethod(AClass, False, False);
          CodeItem.Depends.Add(m); // todo: keep only used methods
          if alias then
            AClass.init1 := AClass.init1 + SWFOptimize(GetThis + SWFPushString(m.localName) + SWFGetVariable(m.codeName)) + FSetThisMember
          else
            AClass.InitProto := AClass.InitProto + SWFOptimize(SWFGetRegister(2) + SWFPushString(m.localName) + SWFGetVariable(m.CodeName)) + acSetMember;
        end;
        tkProperty:
        begin
          NextToken;
          p := UserProperty(AClass, False);
        end;
        else
          Error('C2077', 'Unexpected token ' + Token); // What is this? -> property in user defined class?
      end;
      if Token <> 'END' then
        DropToken(tk_SemiColon);

      // default  property
      if (p <> nil) and (SkipToken(tkDefault)) then
      begin
        AClass.Default := p;
        if Token <> 'END' then
          DropToken(tk_SemiColon);
      end;

      // override
      if m <> nil then
      begin
        v := LookupInherited(AClass, m.Name);
        if (v <> nil) and (v is TMethod) and TMethod(v).IsVirtual then
        begin
          if not SkipToken(tkOverride) then
            TWarning.Create('C2110', 'Cette méthode remplace la méthode héritée, utilisez override', Provider.FileName, m.Row, m.Col)
          else
          begin
            m.IsVirtual := True; // override d'un override
            if TMethod(v).Owner._external then
              m.localName := TMethod(v).localName;
            if not AClass.Aliased then
            begin
              m.codeName := TMethod(v).codeName;
              m.localName := TMethod(v).localName;
            end;
            if Token <> 'END' then
              DropToken(tk_SemiColon);
          end;
        end else
        if SkipToken(tkVirtual) then
        begin
          m.IsVirtual := True;
          if Token <> 'END' then
            DropToken(tk_SemiColon);
          if SkipToken(tkAbstract) then
          begin
            m.IsAbstract := True;
            if Token <> 'END' then
              DropToken(tk_SemiColon);
          end;
        end;
      end;

     end;
     NextToken; // END

     FCurrentClass := nil;

    // requiered for inherited class whithout constructor: ie Sudoku.pas, TButton = class(TCustomButton)
    if (AClass._constructor = nil) and ((AClass.init1 <> '')  or (AClass.InitProto <> '')) then
    begin
      AClass._constructor := InheritedConstructor(AClass);
      AClass._constructor.proto.kind := AClass;
      if alias then
        CodeItem.Code := AClass._constructor.Definition($19);
      //FInit := FInit +
      //CodeItem.Code := CodeItem.Code + DeclareConstructor(AClass);
    end else begin
      if not IsFlashClass(AClass) then
      begin
        base := AClass;
        create := base._constructor;
        while create = nil do
        begin
          base := base._inherite;
          if base = nil then
            break;
          create := base._constructor;
        end;
        if create = nil then
        begin
          DefaultConstructor(AClass);
          //CodeItem.Code := CodeItem.Code + DeclareConstructor(AClass);
        end;
      end;
    end;

    AClass.Reference.Done := True;

    CodeItem := TCodeItem.Create(Self, c);

  finally
    Scopes := s;
  end;
end;

function TCompiler.UserProperty(AClass: TClassDef; static: Boolean): TProperty;
var
  p : TProperty;
begin
  p := TProperty.Create(tk_Property);
  Result := p;
  p.Static := Static;
  p.Owner := AClass;
  if GetSymbol(AClass.Scope.Symbol) <> nil then
    Error('C1836', 'Duplicate ident');

  p.realName := SrcToken;
  p.codeName := GetName('p', FPrefix + SrcToken);
  p.name := GetIdent;

  p.NextSymbol := AClass.Scope.Symbol;
  AClass.Scope.Symbol := p;

  if SkipToken(tk_LBracket) then
  begin
    p.Proto := TPrototype.Create(tk_Prototype);
    while not SkipToken(tk_RBracket) do
    begin
      GetParam(p.Proto, nil, nil);
      if TokenType <> tk_RBracket then DropToken(tk_SemiColon);
    end;
  end;

  DropToken(tk_Colon);
  p.Kind := GetType;

  if SkipToken(tkRead) then
  begin
    p.OnGet := ClassSymbol(AClass);
    if p.OnGet = nil then
      Error('C2626', 'Unexpected');
  end
  else begin
    p.WriteOnly := True;
  end;

  if SkipToken(tkWrite) then
  begin
    p.OnSet := ClassSymbol(AClass);
  end else begin
    if p.WriteOnly then
      Error('C2634', 'Expected read or write');
    p.ReadOnly := True;
  end;

  if SkipToken(tkDeprecated) then
    p.Deprecate := True;
end;

// declare a function/procedure prototype
function TCompiler.FunctionPrototype(const name:string; void:boolean): TSymbol;
var
  f: TPrototype;
begin
  if not void then Warning('Calling function prototype is experimental and untested','FunctionPrototype');

  f := TPrototype.Create(tk_Prototype);
  f.name := name;
  f.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := f;
  f.Regs := 2;
  if SkipToken(tk_LParen) then begin
    while not SkipToken(tk_RParen) do begin
      GetParam(f, nil, nil);
      if TokenType<>tk_RParen then DropToken(tk_SemiColon);
    end;
  end;

  if not void then begin //----------------------------------------------------- prototype function:result
    DropToken(tk_Colon);
    f.Kind:=GetType;
  end;

  if SkipToken(tkOf) then
  begin
    DropToken(tkObject);
    f.OfObject:=True;
  end;

  Result := f;
end;

// declare a new type
procedure TCompiler.DeclareType;
var
  cname   : string;
  uname   : string;
  typed   : TSymbol;
begin
  cname := SrcToken;
  uname := GetIdent;
  DropToken(tk_EQ);
  case TokenIndex([tkExternal, tkProcedure, tkFunction, tkClass]) of
    tkExternal:
    begin
      NextToken;
      ExternalFlashClass(cname,uname);
    end;
    tkProcedure:
    begin
      NextToken;
      FunctionPrototype(uname,true);
    end;
    tkFunction:
    begin
      NextToken;
      FunctionPrototype(uname,false);
    end;
    tkClass:
    begin
      NextToken;
      DefineUserClass(cname,uname);
    end;
  else
    (*if Symbol = _Double then
    begin
      BaseTypeAlias(uname, TBaseType(Symbol));
      NextToken;
    end else*) begin
   // todo: user defined class, record ?
  //  Error('Type expected','DeclareType');
      Typed := GetType;
      BaseTypeAlias(cname, uname, TBaseType(Typed));
    end;
  end;

  DropToken(tk_SemiColon);
end;

procedure TCompiler.DeclareConst;
var
  c: TConstant;
  k: TSymbol;
  ci: TCodeItem;
begin
  c := TConstant.Create(tk_Constant);
  c.realName := SrcToken;
  c.CodeName := GetName('c', FPrefix + c.RealName);
  c.Name := GetIdent;
  if SkipToken(tk_Colon) then
    c.Kind := GetType;
  DropToken(tk_EQ);
  if c.Kind <> nil then
  begin
    k := RealType(c.Kind);
    if k is TArray then
    begin
      ci := CodeItem;
      CodeItem := TCodeItem.Create(Self, nil);
      c.CodeItem := CodeItem;
      CodeItem.Code := SWFPushString(c.codeName) + ConstArray(TArray(k)) + acSetVariable;
      CodeItem := TCodeItem.Create(Self, ci);
      c.Value.ValueType := vtArray;
      c.Value.AsArray := SWFPushString(c.codeName) + acGetVariable;
    end;
    c.Kind := k;
  end else begin
    c.Value := GetConstantValue;
    case c.Value.ValueType of
      vtNil     : c.Kind := _Object;
      vtBoolean : c.Kind := _Boolean;
      vtInteger : c.Kind := _Integer;
      vtFloat   : c.Kind := _Double;
      vtString  : c.Kind := _String;
      vtArray   : c.Kind := Anonyms; // todo: verify this !
    else
      Error('C2241', 'Unknown constant type');
    end;
  end;
  DropToken(tk_SemiColon);
  c.NextSymbol := Scopes.Symbol;
  Scopes.Symbol := c;
end;

// get a variable reference
function TCompiler.DropVariable: TVariable;
begin
  TokenSymbol;
  Result := Variable;
  DropToken(tk_Variable);
  CodeItem.Depends.Add(Result);
end;

function TCompiler.DropParameter: TParameter;
begin
  TokenSymbol;
  Result := Parameter;
  DropToken(tk_Parameter);
end;

function TCompiler.DropProperty: TProperty;
begin
  TokenSymbol;
  Result := TProperty(Symbol);
  DropToken(tk_Property);
end;

// push a string
function TCompiler.PushString:string;
var
 e:TExpression;
begin
  if SkipToken(tkNil) then
    Result := SWFPushNull
  else begin
     e := Expression;
     if (e.kind <> _String) and (e.Kind <> _Char) and (e.Kind <> _Variant) then
       Error('C2246', 'String expected');
     Result := e.Code;
     e.Free;
  end;
end;

// push an integer
function TCompiler.PushInteger: string;
var
  e: TExpression;
begin
  e := Expression;
  if not IsInteger(e.kind) then
    Error('C2513', 'Integer expected'); // Ordinal expected
  Result := e.Code;
  e.Free;
end;

function TCompiler.PushSetOf(Kind: TSetOf): string;
var
  e: TExpression;
begin
  if SkipToken(tk_LBracket) then
  begin
    Result := SWFPushInteger(GetConstantSetOf(RealType(Kind.Items) as TSet));
  end else begin
    e := Expression;
    if RealType(e.Kind) <> RealType(Kind) then
      Error('C3178', 'Invalid type');
    Result := e.Code;
    e.Free;
  end;
end;

// push a double
function TCompiler.PushDouble:string;
var
 e:TExpression;
begin
 e:=Expression;
 if not IsNumber(e.kind) then
   Error('C2270', 'Integer or Double expected');// Ordinal expected
 Result:=e.Code;
 e.Free;
end;

procedure TCompiler.VarInstance(variable:TVariable; var Instance:TInstance);
begin
  instance.read := True;
  instance.write := True;
  instance.Source := variable;
  if variable.Owner = nil then begin
//    if variable.Externe then
    begin
      instance.getcode:= SWFPushString(variable.codeName);
      instance.setcode:= instance.getcode;
      instance.getter := acGetVariable;
      instance.setter := acSetVariable;//acSetLocalVar
    end{ else begin
      instance.code  := SWFOptimize(SWFGetVariable('$top') + SWFPushString(variable.codeName) );
      instance.getter := acGetMember;
      instance.setter := acSetMember;
    end};
    instance.kind   := variable.Kind;
  end else
  if (variable.Owner is TClassDef) or (variable.Owner is TRecord) then begin
    instance.getcode  := SWFOptimize(GetThis + SWFPushString(variable.codeName) );
    instance.setcode:= instance.getcode;
    instance.getter := FGetThisMember;
    instance.setter := FSetThisMember;
    instance.kind   := variable.Kind;
  end else
  if variable.owner is TMethod then begin
  {$IFDEF REG_VARS}
    if Variable.Reg=0 then begin
  {$ENDIF}
      instance.getcode   := SWFPushString(variable.codeName);
      instance.setcode:= instance.getcode;
      instance.getter := acGetVariable;
      instance.setter := acSetLocalVar;
  {$IFDEF REG_VARS}
    end else begin
      instance.getcode   := '';
      instance.setcode:= instance.getcode;
      instance.getter := SWFGetRegister(variable.Reg);
      instance.setter := SWFSetRegister(variable.Reg) + acPop;
     end;
  {$ENDIF}
    instance.kind  := variable.Kind;
  end else
    Error('C2308', 'Variable instance for '+variable.Owner.ClassName);
  InstanceSuffix(instance);
end;

procedure TCompiler.ParamInstance(Param:TParameter; var Instance:TInstance);
begin
  instance.read := True;
  instance.write := Param.IsConst = False;
  instance.Source := Param;
  {$IFDEF REG_PARAM}
    if Param.Reg=0 then begin
  {$ENDIF}
      instance.getcode   := SWFPushString(Param.codeName);
      instance.setcode:= instance.getcode;
      instance.getter := acGetVariable;
      instance.setter := acSetLocalVar;
  {$IFDEF REG_PARAM}
    end else begin
      instance.getcode   := '';
      instance.setcode:= instance.getcode;
      {if Param.ByRef > 0 then
      begin
        instance.getcode:= SWFGetRegister(Param.Reg) + SWFPushInteger(Param.ByRef);
        instance.setcode:= instance.getcode;
        instance.getter := acGetMember;
        instance.setter := acSetMember;
      end else} begin
        instance.getter := SWFGetRegister(Param.Reg);
        instance.setter := SWFSetRegister(Param.Reg) + acPop;
      end;
     end;
  {$ENDIF}
    instance.kind  := param.Kind;//variable.Kind;
  InstanceSuffix(instance);
end;

procedure TCompiler.PropertyInstance(prop: TProperty; var Instance: TInstance; Root: Boolean = True);
var
  this, getter, setter, parms: string;
  count: Integer;
begin
  if root then
  begin
    this := GetThis;
    getter := FGetThisMember;
    setter := FSetThisMember;
  end else begin
    this := instance.getcode + instance.getter;
    getter := acGetMember;
    setter := acSetMember;
  end;
  if (prop.OnGet = nil) and (prop.OnSet = nil) then
  begin
    instance.getcode := SWFOptimize(this + SWFPushString(Prop.codeName));
    instance.setcode:= instance.getcode;
    instance.getter := getter;
    instance.setter := setter;
  end else begin
    Count := 0;
    if prop.Proto = nil then
    begin
      parms := '';
    end else
      parms := PushParams(prop.Proto, Count);
    if prop.OnGet <> nil then
    begin
      case prop.OnGet.Token of
        tk_Variable:
        begin
          instance.getcode := SWFOptimize(this + SWFPushString(TVariable(prop.OnGet).codeName) );
          instance.getter := getter;
        end;
        tk_Method :
          if this = '' then
            instance.getter := SWFOptimize(parms + SWFPushInteger(Count) + SWFCallFunction(TMethod(prop.OnGet).localName))
          else
            instance.getter := SWFOptimize(parms + SWFPushInteger(Count) + this + SWFCallMethod(TMethod(prop.OnGet).localName));
      else
        Error('C2905', 'todo');
      end;
    end;
    if prop.OnSet <> nil then
    begin
      case prop.OnSet.Token of
        tk_Variable:
        begin
          instance.setcode := SWFOptimize(this + SWFPushString(TVariable(prop.OnSet).codeName) );
          instance.setter := setter;
        end;
        tk_Method  :
        begin
          if this = '' then
            instance.setter := SWFOptimize(parms + SWFPushInteger(count + 1) + SWFCallFunction(TMethod(prop.OnSet).localName)) + acPop
          else
            instance.setter := SWFOptimize(parms + SWFPushInteger(count + 1) + this +SWFCallMethod(TMethod(prop.OnSet).localName)) + acPop;
        end;
      else
        Error('C2905', 'todo');
      end;
    end;
  end;
  instance.kind := Prop.Kind;
  instance.read := not prop.WriteOnly;
  instance.write := not prop.ReadOnly;
  instance.source := prop;
  InstanceSuffix(instance);
end;

function TCompiler.GetVariable(Variable:TVariable):string;
var
  Instance:TInstance;
begin
  VarInstance(Variable,Instance);
  Result := Instance.getcode + Instance.getter;
end;

function TCompiler.PushBoolean:string;
var
 e:TExpression;
begin
 e:=Expression;
 if e.kind<>_Boolean then Error('C2359', 'Boolean expected');
 Result:=e.Code;
 e.Free;
end;

procedure TCompiler.GetInstance(var Instance:TInstance);
var
  m: TMethod;
  c: TClassDef;
begin
  case TokenSymbol of
    tk_Variable : VarInstance(DropVariable, Instance);
    tk_Property : PropertyInstance(DropProperty, Instance);
    tk_Parameter: ParamInstance(DropParameter, Instance);
    tk_Method   : begin
      m := TMethod(Symbol);
      NextToken;
      if m.Externe = '' then
      begin
        if m.Owner = nil then
        begin
          Instance.getcode := CallMethod('',m);
          instance.setcode:= instance.getcode;
        end else begin
          Instance.getcode := CallMethod(GetThis, m);
          instance.setcode:= instance.getcode;
        end;
      end else begin
        if (m.Externe[1] = '/') and (m.Proto.Count = 0) then
        begin
          Instance.getCode := SWFGetVariable(m.Externe);
          instance.setcode:= instance.getcode;
          if SkipToken(tk_LParen) then
            DropToken(tk_RParen);
        end else begin
          Instance.getCode := CallMethod(SWFGetVariable(m.Externe),m);
          instance.setcode:= instance.getcode;
        end;
      end;
      Instance.source := m;
    end;
    tk_Class : begin
      c := TClassDef(Symbol);
      NextToken;
      if SkipToken(tk_LParen) then
      begin
        GetInstance(Instance);
        if not IsObject(Instance.kind) then
          Error('C2396', 'class expected');
        Instance.Kind := c;
        DropToken(tk_RParen);
      end else begin
        Instance.getcode := ClassStatement(c);
        instance.setcode:= instance.getcode;
        Instance.kind := c;
      end;
    end;
    else Error('C2404', 'Unknown instance ' + SrcToken);
  end;
end;

function TCompiler.LookupSymbol(List: TSymbol; const name: string): TSymbol;
begin
  while List <> nil do
  begin
    if List.name = name then
    begin
      Result:=List;
      Exit;
     end;
     List := List.NextSymbol;
  end;
  Result := nil;
end;

function TCompiler.LookupInherited(AClass: TClassDef; const Name: string): TSymbol;
var
  base: TClassDef;
begin
  base := AClass._inherite;
  while base <> nil do
  begin
    Result := LookupSymbol(base.Scope.Symbol, name);
    if Result <> nil then
      Exit;
    base := base._inherite;
  end;
  Result := nil;
end;

function TCompiler.GetSymbol(List: TSymbol; Skip: Boolean = True):TSymbol;
begin
  Result := LookupSymbol(List, Token);
  if (Result <> nil) and Skip then
    NextToken;
end;

function TCompiler.GetInheritedSymbol(AClass: TClassDef; Skip: Boolean = True): TSymbol;
var
  base: TClassDef;
begin
  Result := nil;
  base := AClass._inherite;
  if base = nil then
    Exit;
  Result := GetSymbol(base.Scope.Symbol, Skip);
  while Result = nil do
  begin
    base := base._inherite;
    if base = nil then
      Exit;
    Result := GetSymbol(base.Scope.Symbol, Skip);
  end;
end;

function TCompiler.InheritedSymbol(AClass: TClassDef; Skip: Boolean = True): TSymbol;
begin
  Result := GetInheritedSymbol(AClass, Skip);
  if Result = nil then
    Error('C2913', 'Unknown member');
end;
(*
function TCompiler.ClassLookup(AClass:TClassDef; const Symbol: string):TSymbol;
begin
  while AClass <> nil do
  begin
    Result := LookupSymbol(AClass.Scope.Symbol{_symbols}, Symbol);
    if Result <> nil then
      Exit;
    AClass := AClass._inherite;
  end;
  Result := nil;
end;
*)
function TCompiler.ClassSymbol(AClass:TClassDef):TSymbol;
begin
  Result := GetSymbol(AClass.Scope.Symbol);
  if Result = nil then
    Result := InheritedSymbol(AClass);
end;

function TCompiler.RecordField(ARecord: TRecord): TSymbol;
begin
  Result := GetSymbol(ARecord.Scope.Symbol);
end;

function TCompiler.PushInstance:string;
var
  i: TInstance;
  s: TSymbol;
begin
  if SkipToken(tkNil) then
    Result := SWFPushNull//SWFPushInteger(0)
  else
  if SkipToken(tkSelf) then
  begin
    if FCurrentClass = nil then
      Error('C2736', 'Self outside a class method');
    Result := GetSelf;
  end else
  if TokenType = tk_LBracket then
  begin
    // [ field1: value; field2 : value2]
    NextToken;
    Result := PushStaticObject;
  end else begin
    GetInstance(i);
    while SkipToken(tk_Dot) do begin
      if not (i.Kind is TClassDef) then
        Error('C2476', 'Class expected');
      s := ClassSymbol(i.kind as TClassDef);
      if s is TVariable then begin
        i.getcode := i.getcode + i.getter + SWFPushString(s.codeName);
        i.setcode:= i.getcode;
        i.kind := TVariable(s).Kind;
        i.getter := acGetMember;
        i.setter := acSetMember;
      end else
        Error('C2484', 'Unexpected '+s.className);
    end;
    Result := i.getcode + i.getter;
  end;
end;

function TCompiler.PushStaticObject: string;
// [ field1: value1; field2: value2 ]
var
  Count: Integer;
  Value: TConstantValue;
begin
  Result := '';
  Count := 0;
  //DropToken(tk_LBracket);
  while not SkipToken(tk_RBracket) do
  begin
    if Count > 0 then
      DropToken(tk_SemiColon);
    Result := Result + SWFPushString(SrcToken);
    DropToken(tk_Ident);
    DropToken(tk_Colon);
    Value := GetConstantValue();
    Result := Result + GetConstantCode(Value);
    Inc(Count);
  end;
  Result := SWFOptimize(Result + SWFPushInteger(Count)) + acDeclareObject;
end;

function TCompiler.GetConstantSetOf(Kind: TSet): Integer;
var
  Item : TConstant;
  Next : TConstant;
begin
  Result := 0;
  while not SkipToken(tk_RBracket) do
  begin
    if Result > 0 then
      DropToken(tk_Comma);
    Item := GetConstantSet(Kind);
    Result := Result or (1 shl Item.Value.AsInt64);
    if SkipToken(tk_Range) then
    begin
      Next := GetConstantSet(Kind);
      if Next.Value.AsInt64 < Item.Value.AsInt64 then
        Error('C3721', 'Invalid range');
      repeat
        Result := Result or (1 shl Next.Value.AsInt64);
        Next := TConstant(Next.NextSymbol);
      until Next = Item;
    end;
  end;
end;

function TCompiler.GetConstantSet(Kind: TSet): TConstant;
var
  Index: Integer;
begin
  Index := Kind.Count;
  Result := Kind.Last as TConstant;
  while Index > 0 do
  begin
    Dec(Index);
    if Token = Result.name then
    begin
      NextToken;
      Exit;
    end;
    Result := Result.NextSymbol as TConstant;
  end;
  Error('C3705', 'unknow value');
end;

function TCompiler.PushMethod:string;
begin
  if not (Symbol is TMethod) then
    Error('C2492', 'Method expected');
  Result := SWFOptimize(GetThis + SWFGetMember(TMethod(Symbol).codeName));
  NextToken;
end;

function TCompiler.PushArray(A:TArray):string;
var
  count: Integer;
begin
 DropToken(tk_LBracket);
 count:=0;
 Result:='';
  while not SkipToken(tk_RBracket) do
  begin
  Result:=PushKind(A._kind)+Result;
    Inc(count);
    if TokenType <> tk_RBracket then
      DropToken(tk_Comma);
 end;
  if (A._open = False) then
  begin
    if (count<a.Range._high-a.Range._low+1) then Error('C2513', 'Not enough items');
    if (count>a.Range._high-a.Range._low+1) then Error('C2514', 'Too many items');
 end;
 Result:=Result+SWFPushInteger(count)+acDeclareArray;
end;

function TCompiler.ConstArray(A:TArray):string;
var
  count:integer;
begin
  DropToken(tk_LParen);
  Count := 0;
  Result:='';
  while not SkipToken(tk_RParen) do
  begin
    Result := SWFOptimize(PushConst(A._kind) + Result);
    inc(Count);
    if TokenType <> tk_RParen then
      DropToken(tk_Comma);
  end;
  if (A._open = False) then
  begin
    if (count<a.Range._high-a.Range._low+1) then Error('C2535', 'Not enough items');
    if (count>a.Range._high-a.Range._low+1) then Error('C2536', 'Too many items');
  end else begin
    A._open := False;
    A.Range := TRange.Create(tk_Range);
    A.Range.NextSymbol := Anonyms;
    Anonyms := A.Range;
    A.Range.Kind := _Integer;
    A.Range._low := 0;
    a.Range._high := count - 1;
  end;
  Result:=SWFOptimize(Result+SWFPushInteger(count))+acDeclareArray;
end;

function TCompiler.PushConst(Kind: TSymbol): string;
begin
  Kind := RealType(Kind);
  if Kind is TArray then
    Result := ConstArray(TArray(Kind))
  else
  if Kind = _Integer then
    Result := PushInteger
  else
  if Kind = _Double then
    Result := PushDouble
  else
  if Kind = _String then
    Result := PushString
  else
    Error('C2559', 'Const of type ' + Kind.Name);
end;

function TCompiler.PushKind(Kind:TSymbol):string;
var
  e: TExpression;
begin
  Kind := RealType(Kind);
  if (Kind is TArray) and (TokenType=tk_LBracket) then
    Result := PushArray(TArray(Kind))
  else
  if Kind = _String then
    Result := PushString
  else
  if Kind = _Integer then
    Result := PushInteger
  else
  if Kind.Token = tk_SetOf then
    Result := PushSetOf(TSetOf(Kind))
  else
  if Kind = _Double  then
    Result := PushDouble
  else
  if Kind = _Boolean then
    Result := PushBoolean
  else
  if Kind is TPrototype then
    Result := PushMethod
  else //**************************************************
  if (Kind is TClassDef) or (Kind = _Object) then
    Result := PushInstance
  else begin
    e:=Expression;
    if RealType(e.Kind) <> RealType(Kind) then
    begin
      if ((e.Kind is TClassDef) and (Kind = _Object))
      or ((e.Kind is TArray) and (Kind is TArray))// to accept 'array' type results of methods - without this "Error:  expected (PushKind)"
      or (SameBase(e.Kind, Kind))
      or (Kind = _Variant)
      then { ok }
      else
        Error('C2579', Kind.Name+' expected');
  end;
  Result := e.Code;
  e.Free;
 end;
end;

function TCompiler.PushParams(Proto:TPrototype; var Count: Integer):string;
begin
//  Result := '';
//  SetLength(vars, Proto.ByRefs + 1); // 1 - based for now
//  if Proto.ByRefs > 0 then
//  begin
//    Result := SWFPushString('$var') + acDeclareLocalVar;
//  end;
  Result := PushParams2(Proto.Params, Count);
end;

function TCompiler.PushParams2(Param:TParameter; var Count: Integer):string;
begin
  Result := '';
  if Param <> nil then
  begin
    if Param.NextParam <> nil then
    begin
      Result := PushParams2(Param.NextParam, Count);
      if TokenType <> tk_RParen then
        DropToken(tk_Comma);
    end;
    if (TokenType = tk_RParen) and (Param.default <> '') then
    begin
      if (Param.default <> acEndAction) then
      begin
        Result := Param.default + Result;
        Inc(Count);
      end;
    end else begin
      // Parent hack
      if (Token = 'NIL') and Param.IsParent then
      begin
        DropToken(tkNil);
        Result := SWFGetVariable('_root') + Result;
      end else begin
        {if Param.ByRef > 0 then
        begin
          GetInstance(vars[Param.ByRef]);
          Result := Result + SWFPushString('$var') + acDuplicate + SWFPushInteger(Param.ByRef) + vars[Param.ByRef].getcode + vars[Param.ByRef].getter +  acSetMember + acGetVariable;
        end else} begin
          Result := PushKind(Param.Kind) + Result;
        end;
      end;
      Inc(Count);
    end;
  end;
end;

function TCompiler.CallConstructor(ACreate:TMethod):string;
var
  parent: string;
  pcount: Integer;
begin
  Result := '';
  pcount := 0;
  if acreate.alias <> '' then
  begin
   // call a parent method to create the new instance
   // Parent.create('instance',...)
    DropToken(tk_LParen);
   // nil parent is _root !
    if SkipToken(tkNil) then
      parent := SWFGetVariable('_root')
    else
    if SkipToken(tkSelf) then
    begin
      if FCurrentClass = nil then
        Error('C2905', 'Self outside a class method');
      parent := GetSelf;
    end else begin
      parent := PushInstance;
   { Version qui fonctionne mais qui perturbe SWF Decompiler
      root   := acPop + SWFGetVariable('_root');
      parent := parent
              + acDuplicate
              + SWFPushNull
              + acEqual
              + acLogicalNot
              + BranchIfEq(Length(root))
              + root;
   }
   { Version qui ne perturbe pas SWF Decompiler }
   (*
      root := SWFGetVariable('_root');
      s1 := parent +
            Branch(Length(root));

    parent := parent
            + SWFPushNull
            + acEqual
            + BranchIfEq(Length(s1))
            + s1
            + root;
    *)
    end;
    if SkipToken(tk_Comma) then
    begin
      Result := PushParams(acreate.proto, pcount);
    end else begin
      if acreate.proto.params <> nil then
        Error('C2667', 'Parameter expected');
    end;
    DropToken(tk_RParen);
    Result := SWFOptimize(Result + SWFPushInteger(pcount{ - 1}) + parent + SWFCallMethod(acreate.alias));
  end else begin
   // instance=new Class(...)
    if SkipToken(tk_LParen) then
    begin
      Result := PushParams(acreate.proto, pcount);
      DropToken(tk_RParen);
    end else begin
      if (acreate.proto.params <> nil) and (acreate.proto.params.Default = '') then
        Error('C2679', 'Parameter expected');
    end;
    if TClassDef(acreate.proto.Kind).userClass then
    begin
      //if IsFlashClass(acreate.Owner) then
      if acreate.owner.Aliased then
        Result := SWFOptimize(Result + SWFPushInteger(pcount) + SWFCallFunction(acreate.codeName))
      else
        Result := SWFOptimize(Result + SWFPushInteger(pcount) + SWFNewObject(acreate.codeName))
    end else begin
      Result := SWFOptimize(Result + SWFPushInteger(pcount) + SWFNewObject(TClassDef(acreate.proto.Kind).codeName));
    end;
  end;
end;

function TCompiler.CallFunction(method:TMethod):string;
var
  count: Integer;
begin
  if (method.Externe = '') or (method.SysCall > 0) then
  begin
    Result := '';
    count := 0;
    if SkipToken(tk_LParen) then
    begin
      Result := PushParams(method.proto, count);
      DropToken(tk_RParen);
    end;
    CodeItem.Depends.Add(method); // indique que le code courant à besoin du code de definition de la méthode
    if method.SysCall = 0 then
    begin
      Result := SWFOptimize(Result + SWFPushInteger(count) + SWFCallFunction(method.codeName));
    end else begin
      if Count > 0 then
        Result := SWFOptimize(Result + SWFPushInteger(count)) + Chr(method.SysCall)
      else
        Result := Chr(Method.SysCall);
    end;
  end else begin
    if (method.Externe[1] = '/') and (method.proto.Count = 0) then
    begin
      Result := SWFGetVariable(method.Externe);
      if SkipToken(tk_LParen) then
        DropToken(tk_RParen);
    end else
      Result := CallMethod(SWFGetVariable(method.Externe), method);
  end;
end;

function TCompiler.ConstructClass(create: TMethod):string;
var
  s     : string;
begin
  if (create.Owner.UserClass) then
  begin
    CodeItem.Depends.Add(create);
    if (create.code = '') and (not create.IsEmpty) then
    begin
      s := create.realName;
      create.realName := create.owner.realName + '_' + s;
      create.codeName := GetName('C', FPrefix + create.realName);
    end;
    //if IsFlashClass(create.Owner) then
    if Create.Owner.Aliased then
      Result := CallFunction(create)
    else
      Result := CallConstructor(create);
    if create.code = '' then create.realName := s;
  end else begin
     Result := CallConstructor(create);
  end;
end;

// todo: a lot of things !
function TCompiler.AssignStatement(Kind: TSymbol):string;
var
 e:TExpression;
begin
  if Kind is TClassDef then
  begin
    if (TokenSymbol=tk_Class) then
      Result := ClassStatement(GetClass)
    else begin
      e := Expression;
      if (e.Kind <> Kind) and (e.Kind <> _Object) then
        Error('C2738', 'Type mismatch');
      Result := e.Code;
      e.Free;
    end;
  end else
  if Kind is TPrototype then
  begin
    FThis := False;
    Result := GetPrototype(TPrototype(Kind));
  end else
    Result := PushKind(Kind);
end;

function TCompiler.CallPrototype(instance: string; Proto: TPrototype; method: TMethod): string;
var
  param : TParameter;
  code  : string;
  sender: TParameter;
  flag  : Word;
  count : Word;
begin
  param := proto.params;
  Result:= '';
  code  := '';

  // Sender
  sender := nil;
  if method.proto.count <> proto.count then
  begin
    if method.proto.count <> proto.count + 1 then
      Error('C3328', 'Incompatibles types');
    sender := method.LastParm;
    if sender.name <> 'SENDER' then
      Error('C3330', 'Sender expected');
    if not IsObject(sender.Kind) then
      Error('C3330', 'Sender have to be an object');
  end;

  while param <> nil do
  begin
    Result := Chr(param.Reg - 1) +  param.codeName + #0 + Result;
    code := code + SWFGetRegister(Param.Reg - 1);
    param := param.NextParam;
  end;

  if instance = '' then
    instance := GetSelf;

  FProlog := SWFPushString('$' + IntToStr(FPrologIndex)) + instance + acSetlocalVar;
  instance := SWFPushString('$' + IntToStr(FPrologIndex)) + acGetVariable;
  Inc(FPrologIndex);

  if sender = nil then
  begin
    flag := $2A;
    count := proto.count + 1;
  end else begin
    flag := FLAG_7;
    code := code + GetSelf;
    count := proto.count + 2;
  end;

  code := SWFOptimize(code + SWFPushInteger(method.proto.count) + instance + SWFPushString(method.localName)) + acCallMethod + acPop;
  if Length(code) > $FFFF then
    Error('C3082', 'Function too long');
  Result := {no name}#0 + SWFShort(proto.count) + Chr(count) + SWFShort(flag) + Result + SWFShort(Length(Code));
  Result := acDeclareFunction7 + SWFshort(Length(Result)) + Result + code;
end;

function TCompiler.CallMethod(const instance:string; method:TMethod):string;
var
  count : Integer;
begin
  CodeItem.Depends.Add(method);
  Result:='';
  count := 0;
  if SkipToken(tk_LParen) then
  begin
    Result := PushParams(method.proto, count);
    DropToken(tk_RParen);
  end;
  if instance = '' then
  begin
    if method.SysCall = 0 then
      Result := SWFOptimize(Result +SWFPushInteger(count) +SWFCallFunction(method.localName)) // codeName ?
    else begin
      if Count = 0 then
        Result := Chr(method.SysCall)
      else
        Result := SWFOptimize(Result +SWFPushInteger(count)) + Chr(method.SysCall);
    end;
  end else begin
    //if method.IsConstructor then
    //  Result := SWFOptimize(Result +SWFPushInteger(count) + instance + SWFPushUndefined + acCallMethod)
    //else
      Result := SWFOptimize(Result +SWFPushInteger(count) + instance +SWFCallMethod(method.localName));
  end;
end;

procedure TCompiler.InstanceSuffix(var Instance: TInstance);
var
  p: TSymbol;
  e: TExpression;
  s: TSymbol;
  str: string;
  cod: string;
  Cnt: Integer;
begin
  while TokenType in [tk_Dot, tk_LBracket] do
  begin
    if Instance.read = False then
      Error('C2878', 'can''t read this');
    if SkipToken(tk_LBracket) then
    begin
      if instance.Kind is TClassDef then
      begin
        p := TClassDef(Instance.Kind).Default;
        if p <> nil then
        begin
          Error('C3795', 'Todo');
        end else begin
          e := Expression;
          Instance.getCode := Instance.getcode + Instance.getter + e.Code;
          Instance.setCode := Instance.getCode;
          e.Free;
          Instance.getter := acGetMember;
          Instance.setter := acSetMember;
          Instance.Kind := _Variant;
        //Instance.Source := ??
        end;
      (**
        p := ClassLookup(TClassDef(instance.Kind), '[]');
        if (p = nil) or (not (p is TProperty)) then
          Error('C2885', 'no [] property');
        e := Expression;
        Instance.getCode := Instance.getCode + Instance.getter + e.code;
        instance.setcode:= instance.getcode;
        e.Free;
        Instance.getter := acGetMember;
        Instance.setter := acSetMember;
        Instance.Kind := TProperty(p).Kind;
        Instance.Source := p;
      **)
      end else
      if instance.kind = _Variant then
      begin
        e := Expression;
        Instance.getCode := Instance.getcode + Instance.getter + e.Code;
        Instance.setCode := Instance.getCode;
        e.Free;
        Instance.getter := acGetMember;
        Instance.setter := acSetMember;
        Instance.Kind := _Variant;
      end else
      if instance.kind = _String then
      begin
        // get/setcode = SWFPushString(varname)
        // get/setter  = acGet/SetVariable/Member
        cod := Instance.getcode + instance.getter; // string
        e := IntegerExpression;
        Instance.setcode :=
          instance.getcode // varname
          + cod
          + SWFPushInteger(1)
          + e.code
          + acDecrement
          + acSubStringMulti;
          // AssignStatement()
          Instance.setter :=
            acAdd
          + cod
          + e.code
          + acIncrement
          + cod
          + acStringLengthMulti
          + acSubStringMulti
          + acAdd
        + Instance.setter;
        e.Free;
        //Error('C4227', 'Flash strings are readonly...');
        // instance.setcode + AssignStatement(instance.kind) + instance.setter
      end else begin
        if not IsArray(instance.Kind) then
          Error('C4220', 'Array expected');
        instance.getcode := instance.getcode + instance.getter + GetArrayIndex(instance.kind);
        instance.setcode:= instance.getcode;
        instance.getter := acGetMember;
        instance.setter := acSetMember;
      end;
      DropToken(tk_RBracket);
    end else begin
      DropToken(tk_Dot);
      if Instance.Kind is TArray then
      begin
         DropToken(tkLength);
         Instance.getcode := Instance.getCode + Instance.getter + SWFPushString('length');
         instance.setcode:= instance.getcode;
         Instance.getter := acGetMember;
         Instance.Kind := _Integer;
      end else
      if IsRecord(Instance.Kind) then
      begin
        s := RecordField(RealType(Instance.Kind) as TRecord);
        if s = nil then
          Error('C2885', 'Unknow field');
        Instance.getcode := Instance.getcode + Instance.getter + SWFPushString(s.codeName);
        instance.setcode:= instance.getcode;
        Instance.getter := acGetMember;
        Instance.setter := acSetMember;
        Instance.kind := TVariable(s).Kind;
      end else
      if Instance.Kind = _Variant then
      begin
        str := SrcToken;
        DropToken(tk_Ident);
        if SkipToken(tk_lParen) then
        begin
      // variant.method()
          Cnt := 0;
          Cod := '';
          while not SkipToken(tk_rParen) do
          begin
            if Cnt > 0 then
              DropToken(tk_Comma);
            e := Expression;
            Cod := e.code + Cod;
            e.Free;
            Inc(Cnt);
          end;
          Instance.getcode := Cod + SWFPushInteger(Cnt) + Instance.getCode + Instance.getter + SWFCallMethod(Str);
          instance.setcode:= '';
          Instance.getter := '';
          Instance.setter := '';
        end else begin
      // variant.property
          Instance.getcode := Instance.getCode + Instance.getter + SWFPushString(Str);
          instance.setcode:= instance.getcode;
          Instance.getter := acGetMember;
          Instance.setter := acSetMember;
        end;
        Instance.kind := _Variant;
      end else begin
        if not (Instance.Kind is TClassDef) then
          Error('C2911', 'Class expected');
        FThis := False;
        s := ClassSymbol(Instance.Kind as TClassDef);
        if s = nil then
          Error('C2915', 'Unknown method');
        if s is TVariable then
        begin
          Instance.getcode := Instance.getCode + Instance.getter + SWFPushString(s.codeName);
          instance.setcode:= instance.getcode;
          Instance.getter := acGetMember;
          Instance.setter := acSetMember;
          Instance.kind := TVariable(s).Kind;
       end else
       if s is TProperty then
       begin
          PropertyInstance(TProperty(s), Instance, False);
          {
          if TProperty(s).OnGet = nil then
          begin
            Instance.code :=Instance.Code + Instance.getter + SWFPushString(s.codeName);
            Instance.getter := acGetMember;
            Instance.setter := acSetMember;
            Instance.kind := TProperty(s).Kind;
          end else begin
           --
          end;
          }
       end else
       if s is TMethod then
       begin
         if (FReturn <> nil) and (FReturn is TPrototype) then
         begin
           Instance.getcode := CallPrototype(Instance.getCode + Instance.getter, TPrototype(FReturn), TMethod(s));//SWFPushString(s.realName);
           Instance.getcode := FProlog + Instance.getcode;
           instance.setcode:= instance.getcode;
           Instance.getter := acGetMember;
           Instance.setter := acSetMember;
           Instance.kind := TMethod(s);
         end else begin
           if TokenType = tk_Assign then
           begin
             if TMethod(s).IsVirtual = False then
               Error('C3413', 'Not a virtual method');
             Instance.getcode :=Instance.getCode + Instance.getter + SWFPushString(TMethod(s).localName); // codeName ?
             instance.setcode:= instance.getcode;
             Instance.getter := acGetMember;
             Instance.setter := acSetMember;
             Instance.kind := TMethod(s).proto;
           end else begin
             Instance.getcode := CallMethod(Instance.getCode + Instance.getter, TMethod(s));
             instance.setcode:= instance.getcode;
             Instance.getter := '';
             Instance.setter := '';
             Instance.kind := TMethod(s).proto.Kind;
           end;
         end;
       end else
         Error('C2946', 'Unexpected variable suffix '+s.className);
     end;
    end;
  end;
end;

function TCompiler.ResolveInstance(var instance: TInstance; APop: Boolean = True): string;
begin
  if SkipToken(tk_Assign) then
  begin
    if instance.write = False then
    begin
      if Instance.Source is TProperty then
        Error('C2964', 'Can''t set a readonly property')
      else
        Error('C2966', 'Invalid target assignment');
    end;
    if (instance.kind is TPrototype) and SkipToken(tkNil) then
    begin
      Result := SWFOptimize(instance.getcode) + acDelete + acPop;
    end else begin
      FReturn := instance.kind;
      Result := SWFOptimize(instance.setcode + AssignStatement(instance.kind) + instance.setter);
      FReturn := nil;
    end;
  end else begin
    Result := SWFOptimize(instance.getcode + instance.getter);
    //if Instance.kind <> nil then
    if APop then
      Result := Result + acPop;
  end;
end;

function TCompiler.VariableSuffix: string;
var
  instance: TInstance;
  v: TVariable;
begin
//  v := DropVariable;
  v := Variable;
  DropToken(tk_Variable);
  CodeItem.Depends.Add(v);
  VarInstance(v, Instance);
  v.IsSet := True;
  Result := ResolveInstance(instance);
end;

function TCompiler.ParameterSuffix: string;
var
  param: TParameter;
  instance: TInstance;
begin
  param := TParameter(Symbol);
  DropToken(tk_Parameter);
  ParamInstance(Param, instance);
  Result := ResolveInstance(instance);
end;

function TCompiler.PropertySuffix:string;
var
  instance:TInstance;
begin
  PropertyInstance(DropProperty, instance);
  Result := ResolveInstance(instance);
end;

// if boolean then statement [else statement]
function TCompiler.IfStatement:string;
var
 e:TExpression;
 s1:string;
 s2:string;
begin
 NextToken;
 e:=Expression;
 if e.Kind<>_Boolean then Error('C3028', 'Boolean expected');
 DropToken(tkThen);
 s1:=Statement;
 if SkipToken(tkElse) then begin
  s2:=Statement;
  s1:=s1+Branch(Length(s2));
 end else begin
  s2:='';
 end;
 Result:=e.code+acLogicalNot+BranchIfEq(Length(s1))+s1+s2;
 e.Free;
end;

// for var:=a to b do/downto statement;
function TCompiler.ForStatement:string;
var
  v: TVariable;
  init: string;
  test: string;
  code: string;
begin
{$DEFINE FULLTEST}{prev.: -$DEFINE FULLTEST}
  NextToken;
  v := DropVariable;
  if not IsOrdinal(v.Kind) then Error('C3052', 'Ordinal variable expected');
  DropToken(tk_Assign);
  v.IsSet := True;
  init := SetVariable(v, PushKind(v.Kind));
  if SkipToken(tkTo) then begin
   {$IFDEF FULLTEST}
    test := PushKind(v.Kind) + GetVariable(v) + acLessThan;
   {$ELSE}
    init := init + PushKind(v.Kind);
    test := acDuplicate + GetVariable(v) + acLessThan;
   {$ENDIF}
    code := SetVariable(v, GetVariable(v) + acIncrement);
  end else begin
    DropToken(tkDownto);
   {$IFDEF FULLTEST}
    test := PushKind(v.Kind) + GetVariable(v) + acGreaterThan;
   {$ELSE}
    init := init + PushKind(v.Kind);
    test := acDuplicate + GetVariable(v) + acGreaterThan;
   {$ENDIF}
    code := SetVariable(v, GetVariable(v) + acDecrement);
  end;
  DropToken(tkDo);
  code := Statement + SWFOptimize(code);
  code := SWFOptimize(test) + BranchIfEq(Length(code) + 5 { Branch(-Length-(Code) } ) + code;
  Result := SWFOptimize(init) + code + Branch(-Length(Code)-5) {$IFNDEF FULLTEST}{prev.: $IFDEF FULLTEST} + acPop{$ENDIF};
end;

function TCompiler.CallThisMethod: string;
var
  m: TMethod;
  i: TInstance;
  v: TVariable;
begin
  m := Symbol as TMethod;
  NextToken;
  if m.Owner = nil then // Static function
  begin
    if TokenType = tk_Assign then
    begin
      if m <> FMethod then
        Error('C4527', 'Unexpected assign');
      v := TMethod(m).Proto.Return;
      if v = nil then
        Error('C4529', 'Not a function');
      VarInstance(v, i);
      Result := ResolveInstance(i);
      Exit;
    end else begin
      Result := CallFunction(m) + acPop
    end;
  end else
    if m.IsConstructor then
      Result := ConstructClass(m)
    else begin
      if m.IsVirtual and (TokenType = tk_Assign) then
      begin
        i.getcode := SWFOptimize(GetThis + SWFPushString(m.localName));
        i.setcode:= i.getcode;
        i.kind := m.proto;
        i.setter := FSetThisMember;
        i.read := False;
        i.write := True;
        i.source := m;
        Result := ResolveInstance(i);
      end else
        Result := CallMethod(GetThis, m) + acPop;
    end;
end;

function TCompiler.NextCase(Kind: TSymbol): string;
var
  Range1: string;
  Next, Code, Other: string;
begin
  // end of case
  if SkipToken(tkEnd) then
  begin
    Result := '';
  end else
  // else case
  if SkipToken(tkElse) then
  begin
    Result := Statement;
    SkipToken(tk_SemiColon);
    DropToken(tkEnd);
  end else
  begin
  // Value[..Value][,Value[..Value]] : statement;

    Result := acDuplicate + PushKind(Kind);
    // Value1..Value2
    if SkipToken(tk_Range) then
    begin
      Result := Result + acLessThan; // BranchIfEq(NextChar)
      Range1 := acDuplicate + PushKind(Kind) + acGreaterThan; // BranchIfEq(NextCase)
    end else begin
    // Value [,|:]
      Result := Result + acEqual; // BranchIfEq(NextChar)
      Range1 := '';
    end;

    // [,Next] : Code;
    // [Other]
    NextCaseValue(Kind, Next, Code, Other);

    // no other value
    if Next = '' then
    begin
      // It's a Range
      if Range1 <> '' then
      begin
        Range1 := Range1 + BranchIfEq(Length(Code)); // goto Other
        Result := Result + BranchIfEq(Length(Range1) + Length(Code)) + Range1;
      end else begin
        Result := Result + acLogicalNot + BranchIfEq(Length(Code));
      end;
    end else begin
      if Range1 <> '' then
      begin
        Range1 := Range1 + acLogicalNot + BranchIfEq(Length(Next)); // do Code
        Result := Result + BranchIfEq(Length(Range1)) + Range1 + Next;
      end else begin
        Result := Result + BranchIfEq(Length(Next)) + Next;
      end;
    end;

    Result := Result + Code + Other;

    (**
    if s2 = '' then
    begin
      DropToken(tk_Colon);
      s3 := Statement;
      DropToken(tk_SemiColon);
      s4 := NextCase(Kind);
      l := length(s3);
      if s4 <> '' then
        Inc(l, 5);
      Result := Result + BranchIfEq(l) + s3;
      if s4 <> '' then
        Result := Result + Branch(Length(s4)) + s4;
    end else begin
      if s1 <> '' then
        s2 := s1 + BranchIfEq(+5) + Branch(Length(s2)) + s2;
      Result := Result + BranchIfEq(+5) + Branch(Length(s2)) + s2;
    end;
    (**
    if s2 <> '' then
    begin
      Result := Result + BranchIfEq(+5) + s2 + Branch
    end;

    s3 := NextCase(Kind);

    if s3 <> '' then
      s2 := s2 + Branch(Length(s3));

    if s1 <> '' then
      s1 := s1 + BranchIfEq(Length(s2));

    Result := Result + BranchIfEq(Length(s1) + Length(s2)) + s1 + s2 + s3;
    **)
  // dup
  // ne @1
  //  statement
  // jp @2
  // @1
  // <nextCase>
  // @2

  // dup
  // eq @1
  // dup
  // ne @2
  // @1
  //   statement
  //   jp @3
  // @2
  // <nextCase>
  // @3
  (*
    Result := acDuplicate + PushKind(Kind) + acEqual + acLogicalNot;
    DropToken(tk_Colon);
    s1 := Statement;
    DropToken(tk_SemiColon);
    s2 := NextCase(Kind);
    l := length(s1);
    if s2 <> '' then
      Inc(l, 5);
    Result := Result + BranchIfEq(l) + s1;
    if s2 <> '' then
      Result := Result + Branch(Length(s2)) + s2;
    *)
  end;
end;

procedure TCompiler.NextCaseValue(Kind: TSymbol; var ANext, ACode, AOther: string);
var
  Range, Next: string;
begin
  if SkipToken(tk_Comma) then
  begin

    ANext := acDuplicate + PushKind(Kind);
    // Value1..Value2
    if SkipToken(tk_Range) then
    begin
      ANext := ANext + acLessThan;
      Range := acDuplicate + PushKind(Kind) + acGreaterThan;
    end else begin
      ANext := aNext + acEqual;
      Range := '';
    end;

    NextCaseValue(Kind, Next, ACode, AOther);

    if Next = '' then
    begin
      // It's a Range
      if Range <> '' then
      begin
        Range := Range + BranchIfEq(Length(ACode)); // goto Other
        ANext := ANext + BranchIfEq(Length(Range) + Length(ACode)) + Range;
      end else begin
        ANext := ANext + acLogicalNot + BranchIfEq(Length(ACode));
      end;
    end else begin
      if Range <> '' then
      begin
        Range := Range + acLogicalNot + BranchIfEq(Length(Next)); // do Code
        ANext := ANext + BranchIfEq(Length(Range)) + Range + Next;
      end else begin
        ANext := ANext + BranchIfEq(Length(Next)) + Next;
      end;
    end;

  end else begin
    ANext := '';
    DropToken(tk_Colon);
    ACode := Statement;
    DropToken(tk_SemiColon);
    AOther := NextCase(Kind);

    if AOther <> '' then
      ACode := ACode + Branch(Length(AOther));
  end;

end;

// the case statement accept any kind of expression
// so it's time to use TExpression :)
function TCompiler.CaseStatement: string;
var
  e: TExpression;
begin
  NextToken; // case
  e := Expression;
  DropToken(tkOf);
  Result := e.code + NextCase(e.Kind) + acPop;
  e.Free;
end;

function TCompiler.RepeatStatement:string;
var
 e:TExpression;
begin
 NextToken;
 Result:='';
 while not SkipToken(tkUntil) do begin
  Result:=Result+Statement;
  if TokenType<>tkUntil then DropToken(tk_SemiColon);
 end;
 e:=Expression;
 if e.Kind<>_Boolean then Error('C3141', 'Boolean expected');
 Result:=Result+e.Code+acLogicalNot;
 Result:=Result+BranchIfEq(-Length(Result)-5);
 e.Free;
end;

function TCompiler.WhileStatement:string;
var
 e:TExpression;
begin
 NextToken;
 Result:='';
 e:=Expression;
 if e.Kind<>_Boolean then Error('C3154', 'Boolean expected');
 DropToken(tkDo);
 Result:=Statement;
 Result:=e.Code+acLogicalNot+BranchIfEq(Length(Result)+5)+Result;
 Result:=Result+Branch(-Length(Result)-5);
 e.Free;
end;

function TCompiler.DotStatement: string;
var
  i: TInstance;
  str: string;
  Cnt: Integer;
  Cod: string;
  e  : TExpression;
begin
  if FWith = 0 then
    Error('C4441', 'invalid outside with');
  NextToken;
  if (Scopes.Symbol = nil) and (FWithVariant.Kind <> nil) then
  begin
//    i := FWithVariant;
//    InstanceSuffix(i);
//    Result := ResolveInstance(i);

    str := SrcToken;
    DropToken(tk_Ident);
    if SkipToken(tk_lParen) then
    begin
      Cnt := 0;
      Cod := '';
      while not SkipToken(tk_rParen) do
      begin
        if Cnt > 0 then
          DropToken(tk_Comma);
        e := Expression;
        Cod := e.code + Cod;
        e.Free;
        Inc(Cnt);
      end;
      i.getcode := Cod + SWFPushInteger(Cnt) + SWFCallFunction(Str);
      i.setcode:= '';
      i.getter := '';
      i.setter := '';
    end else begin
    // variant.property
    {}
      i.getcode := FWithVariant.getcode + FWithVariant.getter + SWFPushString(Str);
      i.setcode:= i.getcode;
      i.getter := acGetMember;
      i.setter := acSetMember;
    {
      i.getcode := SWFPushString(Str);
      i.setcode := i.getcode;
      i.getter := acGetVariable;
      i.setter := acSetVariable;
    }
    end;
    i.kind := _Variant;
    InstanceSuffix(i);
    Result := ResolveInstance(i);
  end else
    Error('C4445', 'with variant expected');
end;

function TCompiler.WithStatement: string;
var
  i : TInstance;
  s1: PScope;
  s2: TScope;
  r : TSymbol;
  v : TInstance;
begin
  NextToken;
  GetInstance(i);
  if i.Kind = nil then
    Error('C3229', 'Instance expected');
//  DropToken(tkDo);
  s1 := Scopes;
  v := FWithVariant;
  try
    r := RealType(i.Kind);
    if r = _Variant then
    begin
      FWithVariant := i;
      s2.Symbol := nil;
    end else begin
      case r.Token of
        tk_Class:  s2.Symbol := TClassDef(r).Scope.Symbol;
        tk_Record: s2.Symbol := TRecord(r).Scope.Symbol;
      else
        Error('C44455', 'WithStatement');
      end;
    end;
    s2.Next := s1;
    Scopes := @s2;
    Scopes.Step := 1;
    Inc(FWith);
    FGetThisMember := acGetVariable;
    FSetThisMember := acSetVariable;
    if TokenType = tk_Comma then
      Result := WithStatement
    else begin
      DropToken(tkDo);
      Result := Statement;
    end;
    FWithVariant := v;
    Dec(FWith);
    if FWith = 0 then
    begin
      FGetThisMember := acGetMember;
      FSetThisMember := acSetMember;
    end;
  finally
    Scopes := s1;
  end;
  Result := i.getcode + i.getter + acWith + #$02#$00 + SWFshort(Length(Result)) + Result;
end;

function TCompiler.SortStatement:string;
var
 v:TVariable;
 s:TSymbol;
 m:string;
begin
 NextToken;
 DropToken(tk_LParen);
 v:=DropVariable;
 if not (v.Kind is TArray) then Error('C3171', 'Array variable expected');
 if SkipToken(tk_Comma) then begin
  if not (TArray(v.Kind)._kind is TClassDef) then
    Error('C3174', 'Class expected');
  s:=GetSymbol(TClassDef(TArray(v.Kind)._kind).Scope.Symbol{_symbols});
  Result:=SWFPushString(s.codeName)+SWFPushInteger(1);
  m:='sortOn';
 end else begin
  Result:=SWFPushInteger(0);
  m:='sort';
 end;
 DropToken(tk_RParen);
 Result := SWFOptimize(Result + GetVariable(v) + SWFCallMethod(m) + acPop);
end;

function TCompiler.IncludeStatement: string;
var
  i : TInstance;
begin
  NextToken;
  DropToken(tk_LParen);
  GetInstance(i);
  if not IsSetOf(i.kind, nil) then
    Error('C4816', 'Set of expected');
  DropToken(tk_Comma);
  Result := SWFOptimize(i.setcode + i.getcode + i.getter + SWFPushInteger(1) + PushKind((RealType(i.Kind) as TSetOf).Items)) + acShl + acBitwiseOr + i.setter;
  DropToken(tk_RParen);
end;

function TCompiler.ExcludeStatement: string;
var
  i : TInstance;
  s : TSet;
begin
  NextToken;
  DropToken(tk_LParen);
  GetInstance(i);
  if not IsSetOf(i.kind, nil) then
    Error('C4816', 'Set of expected');
  s := (RealType(i.Kind) as TSetOf).Items as TSet;
  DropToken(tk_Comma);
  Result := SWFOptimize(i.setcode + i.getcode + i.getter + SWFPushInteger((1 shl (s.Last.Value.AsInt64 + 1)) - 1) + SWFPushInteger(1) + PushKind(s)) + acShl + acSubstract + acBitwiseAnd + i.setter;
  DropToken(tk_RParen);
end;

function TCompiler.TraceStatement:string;
begin
  NextToken;
  DropToken(tk_LParen);
  Result:=StringCode+acTrace;
  DropToken(tk_RParen);
end;

function TCompiler.ExitStatement: string;
begin
  if FExit = '' then
    Error('C3197', 'Exit!');
  NextToken;
  Result := FExit;
end;

function TCompiler.SelfStatement: string;
begin
  if FCurrentClass = nil then
    Error('C4978', 'Self outside a class method');
  NextToken;
  DropToken(tk_Dot);
  case TokenSymbol(@FCurrentClass.Scope) of
    tk_Variable : Result := VariableSuffix;
    tk_Property : Result := PropertySuffix;
    tk_Method   : Result := CallThisMethod;
    else Error('C4985', 'Unexpected symbol ' + SrcToken);
  end;
end;

function TCompiler.UnitStatement: string;
var
  s: PScope;
begin
  s := @TUnit(Symbol).Source.Scope;
  NextToken;
  DropToken(tk_Dot);
  case TokenSymbol(s) of
    tk_Variable : Result := VariableSuffix;
    tk_Parameter: Result := ParameterSuffix;
    tk_Property : Result := PropertySuffix;
    tk_Method   : Result := CallThisMethod;
    tk_Class    : Result := ClassStatement(GetClass, True);// + acPop;
    tk_Unit     : Result := UnitStatement;
  else          Error('C3837', 'Unexpected symbol ' + SrcToken);
  end;
end;

procedure TCompiler.ClassInstance(AClass: TClassDef; var Instance: TInstance);
var
  Symb: TSymbol;
begin
  if SkipToken(tk_LParen) then
  begin
    GetInstance(Instance);
    if not IsObject(Instance.Kind) then
      Error('C3210', 'Object expected');
    DropToken(tk_RParen);
    Instance.Kind := AClass;
  end else
  if SkipToken(tk_Dot) then
  begin
    Symb := ClassSymbol(AClass);
    if Symb is TMethod then
    begin
      if TMethod(Symb).IsConstructor then
      begin
        Instance.getCode := ConstructClass(TMethod(Symb));
        instance.setcode:= instance.getcode;
        Instance.Kind := AClass;
      end else begin
        if TMethod(Symb).static then
        begin
          Instance.getCode := CallMethod(SWFGetVariable(AClass.codeName), TMethod(Symb));
          instance.setcode:= instance.getcode;
          Instance.Kind := TMethod(Symb).proto.Kind;
        end else
          Error('C3228', 'class method expected');
      end;
    end else
    if Symb is TProperty then
    begin
      if TProperty(Symb).static then
      begin
        Instance.getCode := SWFGetVariable(AClass.codeName) + SWFPushString(Symb.codeName);
        instance.setcode:= instance.getcode;
        Instance.getter := acGetMember;
        Instance.setter := acSetMember;
        Instance.kind := TProperty(Symb).Kind;
        Instance.read := TProperty(Symb).WriteOnly = False;
        Instance.write := TProperty(Symb).ReadOnly = False;
      end else
        Error('C3239', 'class property expected');
    end else
      Error('C3241', 'what ?');
  end else begin // with TClass do ClassFunction
    Instance.getCode := SWFPushString(AClass.codeName);
    instance.setcode:= instance.getcode;
    Instance.getter := acGetVariable;
    Instance.setter := '';
    Instance.kind := AClass;
    Instance.write := False;
    Instance.read := True;
  end;
  InstanceSuffix(Instance);
end;

function Tcompiler.ClassExpression(AClass: TClassDef): TExpression;
var
  Inst: TInstance;
begin
  ClassInstance(AClass, Inst);
  Result := TExpression.Create(Self);
  Result.code := Inst.getcode + Inst.getter;
  Result.Kind := Inst.Kind;
end;

function TCompiler.ClassStatement(AClass: TClassDef; APop: Boolean = False): string;
var
  Inst: TInstance;
begin
  FillChar(Inst, SizeOf(Inst), 0); // especialy Source
  CodeItem.Depends.Add(AClass);
  ClassInstance(AClass, Inst);
  Result := ResolveInstance(Inst, APop);//.code + Inst.getter;
end;

function TCompiler.IncStatement: string;
var
  i : TInstance;
  c : Boolean;
begin
  NextToken;
  DropToken(tk_LParen);
  GetInstance(i);
  c := IsChar(i.kind);
  if c then
  begin
    i.getter := i.getter + acOrdMulti;
    i.setter := acChrMulti + i.setter;
  end;
  if SkipToken(tk_Comma) then
    Result := SWFOptimize(i.setcode + i.getCode + i.getter + IntegerCode) + acAdd + i.setter
  else
    Result := SWFOptimize(i.setcode + i.getCode + i.getter) + acIncrement + i.setter;
  DropToken(tk_RParen);
end;

function TCompiler.DecStatement: string;
var
  i : TInstance;
begin
  NextToken;
  DropToken(tk_LParen);
  GetInstance(i);
  if SkipToken(tk_Comma) then
    Result := SWFOptimize(i.setcode + i.getCode + i.getter + IntegerCode) + acSubstract + i.setter
  else
    Result := SWFOptimize(i.setcode + i.getCode + i.getter) + acDecrement + i.setter;
  DropToken(tk_RParen);
end;

// statement -or- begin statement1; statement2; end;
function TCompiler.Statement: string;
begin
  Result := '';
  FThis := True;
  case TokenIndex([tkBegin, tkIf, tkFor, tkCase, tkRepeat, tkWhile, tkWith, tkSort, tkInc, tkDec, tkExit, tkInclude, tkExclude, tkTrace, tkSelf]) of
//  case TokenType of
    tkBegin: begin
      NextToken;
      while Token <> 'END' do
      begin
        Result := Result + Statement;
        if Token <> 'END' then
          DropToken(tk_SemiColon);
      end;
      NextToken;
    end;
    tkIf        : Result := IfStatement;
    tkFor       : Result := ForStatement;
    tkCase      : Result := CaseStatement;
    tkRepeat    : Result := RepeatStatement;
    tkWhile     : Result := WhileStatement;
    tkWith      : Result := WithStatement;
    tkSort      : Result := SortStatement;
    tkInc       : Result := IncStatement;
    tkDec       : Result := DecStatement;
    tkInclude   : Result := IncludeStatement;
    tkExclude   : Result := ExcludeStatement;
    tkTrace     : Result := TraceStatement;
    tkExit      : Result := ExitStatement;
    tkSelf      : Result := SelfStatement;
    tk_Dot      : Result := DotStatement;
    tk_SemiColon: {empty statements allowed};
    tk_Ident:
      case TokenSymbol of
        tk_Variable : Result := VariableSuffix;
        tk_Parameter: Result := ParameterSuffix;
        tk_Property : Result := PropertySuffix;
        tk_Method   : Result := CallThisMethod;
        tk_Class    : Result := ClassStatement(GetClass, True) {+ acPop}; // cf Quest
        tk_Unit     : Result := UnitStatement;
        else Error('C3912', 'Unexpected symbol ' + SrcToken);
      end;
    else Error('C4693', 'Unknown symbol ' + SrcToken); //unknowen identifier
 end;
end;

function TCompiler.DropParams(Param:TParameter): Boolean;
begin
  Result := False;
  if Param.NextParam = nil then
  begin
   // publish the parameters
   // Param.NextSymbol:=Symbols;
   // Symbols:=Param;
  end else begin
    Result := DropParams(Param.NextParam);
    SkipToken(tk_SemiColon);
  end;
  if Result then
  begin
    if (Param.IsConst <> Param.NextParam.IsConst)
    or ((Param.ByRef > 0) <> (Param.NextParam.ByRef > 0)) then
      Error('C5135', 'Invalid declaration');
  end else begin
    if Param.IsConst then
      DropToken(tkConst);
    if Param.ByRef > 0 then
      DropToken(tkVar);
  end;
  DropIdent(Param.name);
  if SkipToken(tk_Comma) then
  begin
    //Error('C5137', 'Comma Param');
    Result := True;
  end else begin
    Result := False;
    DropToken(tk_Colon);
    if Param.Kind.realName = '' then
    begin
      if not (Param.Kind is TArray) then
        Error('C3348', 'Kind ?');
      DropToken(tkArray);
      DropToken(tkOf);
      DropIdent(TArray(Param.Kind)._Kind.Name);
    end else
      DropIdent(Param.Kind.name);
  end;
end;

function TCompiler.MethodCall(AClass:TClassDef; AMethod:TMethod; const Caller: string):string;
var
  count: Integer;
begin
  Result:='';
  count := 0;
  if SkipToken(tk_LParen) then
  begin
    Result := PushParams(amethod.proto, count);
    DropToken(tk_RParen);
  end;
  //Result := SWFOptimize(Result + Caller + SWFPushInteger(count + 1) + SWFGetVariable(amethod.codeName) + SWFCallMethod('call') );
  if AMethod.IsConstructor then
    Result := Result + SWFOptimize(SWFPushInteger(Count) + Caller + SWFPushUndefined) + acCallMethod 
  else
    if AClass.Aliased then
      Result := SWFOptimize(Result + Caller + SWFPushInteger(count + 1) + SWFGetVariable(amethod.codeName) + SWFCallMethod('call') )
    else
      Result := Result + SWFOptimize(SWFPushInteger(Count) + Caller + SWFPushString(AMethod.realName)) + acCallMethod; // TODO: verify realName is OK
end;

function TCompiler.IsFlashClass(AClass:TClassDef):boolean;
begin
  if not (AClass.UserClass) then
    Result := True
  else begin
    if AClass._inherite = nil then
      Result := False
   else
      Result := IsFlashClass(AClass._inherite);
  end;
end;

function TCompiler.IsConstructor(Symbol:TSymbol):boolean;
begin
 Result:=(Symbol is TMethod)
      and(TMethod(Symbol).proto.Kind is TClassDef)
      and(TClassDef(TMethod(Symbol).proto.Kind)._constructor = Symbol);
end;

function TCompiler.inheritedConstructor(AClass: TClassDef): TMethod;
var
  base  : TClassDef;
  create: TMethod;
  s     : string;
  pp    : ^TParameter;
  pi    : TParameter;
  p     : TParameter;
begin
  base := AClass;
  create := base._constructor;
  while create = nil do
  begin
    base := base._inherite;
    if base = nil then
      break;//Error('C3415', 'TObject constructor ' + AClass.realName); // inherited constructor not found
    create := base._constructor;
  end;

  if (create = nil) and IsFlashClass(AClass) then
    Error('C3415', 'TObject constructor ' + AClass.realName); // inherited constructor not found

  Result := TMethod.Create(tk_Method);
  Result.proto := TPrototype.Create(tk_Prototype);
  Result.IsConstructor := True;
  Result.Owner := AClass;

  if create = nil then
  begin
    Result.Name := 'CREATE';
    Result.realName := AClass.realName + '_Create';
    Result.codeName := GetName('C', Result.realName);
    Result.proto.Regs := 3;
    Result.Code := {SetThis(SWFPushInteger(0) + acDeclareObject) +} AClass.init1 + GetThis + acReturn;
  end else begin
    CodeItem.Depends.Add(create);
    Result.name := create.name;
    Result.realName := AClass.realName + '_' + create.realName;
    Result.codeName := GetName('C', FPrefix + Result.realName);
    Result.proto.count := create.proto.Count;
    Result.proto.regs := 3;//create.proto.regs;

    pp := @Result.proto.params;
    pi := create.proto.params;
    while pi <> nil do
    begin
      p := pi.Clone;
    // for garbage collection
      p.NextSymbol := Result.Scope.Symbol;
      Result.Scope.Symbol := p;

      //p.Reg := Result.regs;
      Inc(Result.proto.regs);
      pp^ := p;
      pp := @p.NextParam;
      pi := pi.NextParam;
    end;

    s := '';
    if create.alias <> '' then
    begin
    // push parameters
      p := Result.proto.params;
      while p<>nil do
      begin
       {$IFDEF REG_PARAM}
        inc(p.Reg);
       {$ENDIF}
        s:=s+GetParameter(p);
        p:=p.NextParam;
      end;
      s := s + SWFPushInteger(Result.proto.Count - 1); // ignore the "Parent" parameter in Count
     // add Parent parameter for this constructor
      p := create.Parent.Clone;

      p.NextSymbol := Result.Scope.Symbol;
      Result.Scope.Symbol := p;

      p.IsParent := True;
      p.Reg := 4;
      Inc(Result.proto.regs);
      pp^ := p;

      s := SWFOptimize(s + GetParameter(p) + SWFCallMethod(create.alias));

      s := SetThis(s);

      //AClass.init1 := AClass.init1 + GetThis + acReturn;
    end else begin
    // push parameters
      p := Result.proto.params;
      while p <> nil do
      begin
       {$IFDEF REG_PARAM}
        Inc(p.Reg);
       {$ENDIF}
        s := s + GetParameter(p);
        p := p.NextParam;
      end;
//      s := s + SWFPushInteger(Result.proto.Count);
//      s := SWFOptimize(s)
//          + SWFCallFunction(create.Owner.realName + '$' + create.realName);

      if TClassDef(create.proto.Kind).userClass then
      begin
        if IsFlashClass(create.Owner) then
          s := SetThis(SWFOptimize(s + SWFPushInteger(Result.proto.Count) + SWFCallFunction(create.codeName)))
        else
          s := SWFOptimize(s + GetThis + SWFPushInteger(Result.proto.Count + 1) + SWFGetVariable(create.codeName) + SWFCallMethod('call') ) + acPop;
      end else begin
        if create.alias = '' then
          s := SWFOptimize(s + SWFPushInteger(Result.proto.Count) + SWFGetRegister(2) + SWFPushUndefined) + acCallMethod + acPop
        else begin
          s := SWFOptimize(s + SWFPushInteger(Result.proto.Count) + SWFNewObject(TClassDef(create.proto.Kind).codeName));
          s := SetThis(s);
        end;
      end;
    end;
    Result.code := s + AClass.init1;// + GetThis + acReturn;
    if AClass.Aliased then
      REsult.Code := REsult.Code + GetThis + acReturn;
  end;

  Result.NextSymbol := AClass.Scope.Symbol;
  AClass.Scope.Symbol := Result;
end;

procedure TCompiler.DefaultConstructor(AClass: TClassDef);
var
  c: TMethod;
begin
  C := TMethod.Create(tk_Method);
  C.proto := TPrototype.Create(tk_Prototype);
  AClass._constructor := C;
  C.proto.Kind := AClass;
  C.IsConstructor := True;
  C.Owner := AClass;
  C.Name := 'CREATE';
  C.realName := AClass.realName + '_Create';
  C.codeName := GetName('C', C.realName);
  C.proto.Regs := 3;
  C.Code := AClass.init1;// + GetThis + acReturn;//SetThis(SWFPushInteger(0) + acDeclareObject + AClass.init1) + GetThis + acReturn;
  C.IsEmpty := C.Code = '';
  C.NextSymbol := AClass.Scope.Symbol;
  AClass.Scope.Symbol := C;
end;

(*
function TCompiler.DeclareConstructor(AClass:TClassDef):string;
var
 s,ss:string;
 p:TParameter;
 f:word;
begin
//  if AClass is TUserClass then f:=FLAG_7+1 else
  f := FLAG_7;
  s := #0 //AClass._constructor.codeName+#0
   + SWFshort(AClass._constructor.proto.count)
   + chr(AClass._constructor.proto.regs)
   + SWFshort(f); // preload this
  p := AClass._constructor.proto.params;
  ss := '';
  while p<>nil do
  begin
    ss:={$IFDEF REG_PARAM}chr(p.Reg){$ELSE}#0{$ENDIF}+ p.codeName+ #0 + ss;
    p:=p.NextParam;
  end;
  if Length(AClass._constructor.code) > $FFFF then
    Error('C3984', 'Function too long');

  s := s + ss + SWFshort(length(AClass._constructor.code));
  Result := acDeclareFunction7 + SWFshort(Length(s)) + s + AClass._constructor.code;

  //Result :=  SWFPushString('_global') + acGetVariable + SWFPushString(AClass._constructor.CodeName) + Result + SWFSetRegister(1) + acSetMember;
  {
  if AClass.InitProto <> '' then
  begin
    Result := Result + SWFOptimize(SWFGetRegister(1) + SWFPushString('prototype')) + acGetMember + SWFSetRegister(2) + AClass.InitProto;
  end;
  }
end;
*)

function TCompiler.DefineConstructor: string;
var
  cl: TClassDef;
  sy: TSymbol;
  s : string;
  flash: Boolean;
  sc: PScope;
  ci: TCodeItem;
begin
  NextToken;
  cl := GetClass;
  if cl.Level <> @Scope then
    Error('C3446', 'class out of scope');
  if not (cl.UserClass) then
    Error('C3448', 'Not a user defined class');
  DropToken(tk_Dot);
  if cl._constructor = nil then
    Error('C3451', 'Unknown constructor');
  DropIdent(cl._constructor.name);

  if cl._constructor.CodeItem <> nil then
    Error('C3819', 'CodeItem constructor');

  ci := CodeItem;
  CodeItem := TCodeItem.Create(Self, nil);
  CodeItem.Depends.Add(cl);
  cl._constructor.CodeItem := CodeItem;

  sc := Scopes;
  Scopes := @cl._constructor.Scope;

  if cl._constructor.proto.params <> nil then
  begin
    DropToken(tk_LParen);
    DropParams(cl._constructor.proto.params);
    DropToken(tk_RParen);
  end else begin
    if SkipToken(tk_LParen) then
      DropToken(tk_RParen)
  end;
  DropToken(tk_SemiColon);
  cl._constructor.realName := cl.realName + '_' + cl._constructor.realName;
  if cl._constructor.codeName = '' then
    cl._constructor.codeName := GetName('C', FPrefix + cl._constructor.realName);
  s := '';
  flash := IsFlashClass(cl);

  if SkipToken(tkVar) then
  begin
    repeat
      s := s + DeclareVar(cl._constructor, True);
      DropToken(tk_SemiColon);
    until Token = 'BEGIN';
    //local.Symbol:=cl._constructor;
    //local.Next:=@Scope;
    //Scopes:=@local;
  end;

  DropToken(tkBegin);

 // for a Flash Class we need to imediatly call the inherited constructor !
  if flash then
  begin
    DropToken(tkInherited);
    sy := InheritedSymbol(cl);
    if not IsConstructor(sy) then
      Error('C3475', 'Flash constructor need to be called first');
    CodeItem.Depends.Add(sy);
    s := SetThis(CallConstructor(TMethod(sy))) + s;
    if Token <> 'END' then
      DropToken(tk_SemiColon);
  end;
  //else  -> for non-Flash classses, the constructor receive an empty this object (new 2013/04/10)
  //  s := s + SetThis(SWFPushInteger(0) + acDeclareObject);

  if cl.UserClass then
  begin
    s := s + cl.init1;
  end;

  FCurrentClass := cl;
  FThis := True;
  FPrologIndex := 0;

  while Token <> 'END' do
  begin
    if SkipToken(tkInherited) then
    begin
      sy := InheritedSymbol(cl);
      if sy is TMethod then
      begin
        CodeItem.Depends.Add(sy);
        s := s + MethodCall(cl,TMethod(sy), SWFGetRegister(2)) + acPop;
      end else
        Error('C3500', 'Unexpected '+sy.realName);
    end else
      s := s + Statement;
    if Token <> 'END' then
      DropToken(tk_SemiColon);
  end;
  NextToken; // END

  Scopes := sc;

  FCurrentClass := nil;

  cl._constructor.code := s + GetThis + acReturn;

  DropToken(tk_SemiColon);

{ VERSION 7 }
  Result := '';

  if cl.aliased then
    CodeItem.Code := cl._constructor.Definition;
  //BuildCode() : CodeItem.Code :=
  //  cl._constructor.code := DeclareConstructor(cl);
  CodeItem := TCodeItem.Create(Self, ci);

//  Scopes := Scope.Next;
end;

function TCompiler.DefineMethod(void: boolean):string; //this "void" parameter was made for debugging
var
  cl: TClassDef;
  mt: TMethod;
  sy: TSymbol;
  s : string;
  oldExit: string;
  sc: PScope;
  ci: TCodeItem;
begin
  if Symbol.Level <> @Scope then
    Error('C3562', 'class out of scope');
  sc := Scopes;
  cl := GetClass;
  if not (cl.UserClass) then Error('C3616', 'Not a user defined class');
    DropToken(tk_Dot);

  sy := GetSymbol(cl.Scope.Symbol{_symbols});
  if not (sy is TMethod) then Error('C3620', 'Method expected');

  mt := TMethod(sy);

  if mt.Code <> '' then
    Error('C3625', 'Method already defined');

  FMethod := mt;

  ci := CodeItem;
  CodeItem := TCodeItem.Create(Self, nil);
  CodeItem.Depends.Add(cl);
  mt.CodeItem := CodeItem;

  Scopes := @mt.Scope;

  if mt.proto.params <> nil then begin
    DropToken(tk_LParen);
    DropParams(mt.proto.params);
    DropToken(tk_RParen);
  end else begin
    if SkipToken(tk_LParen) then DropToken(tk_RParen);
  end;

  s := '';

  if mt.proto.Kind<>nil then
  begin
    DropToken(tk_Colon);
    DropIdent(mt.proto.Kind.name);

    if IsArray(mt.proto.Kind) then
      s := SetVariable(mt.proto.Return, BuildArray(TArray(RealType(mt.proto.Kind))))
    else
    if IsRecord(mt.proto.Kind) then
      s := SetVariable(mt.proto.Return, TRecord(RealType(mt.proto.Kind)).Init1);
  end;
  DropToken(tk_SemiColon);

  if SkipToken(tkVar) then
  begin
    repeat
      s := s + DeclareVar(mt, True);
      DropToken(tk_SemiColon);
    until Token = 'BEGIN';
  end;

  oldExit := FExit;
  if mt.proto.Return<>nil then
    FExit := GetVariable(mt.proto.Return) + acReturn
  else
    FExit := SWFPushUndefined + acReturn;

  DropToken(tkBegin);

  FCurrentClass := cl;

  while Token <> 'END' do
  begin
    if SkipToken(tkInherited) then begin
      sy:=InheritedSymbol(cl);
      if sy is TMethod then begin
        if cl.Aliased then
          s := s + MethodCall(cl, TMethod(sy), GetSelf) + acPop
        else
          s := s + MethodCall(cl, TMethod(sy), SWFGetRegister(2)) + acPop;
      end else
        Error('C3685', 'Unexpected '+sy.realName);
    end else
      s := s + Statement;
    if Token <> 'END' then
      DropToken(tk_SemiColon);
  end;
  NextToken; // END

  FMethod := nil;
  FCurrentClass := nil;

  if mt.proto.Return<>nil then // is the last acReturn required for a procedure ?
    s:=s+FExit; //s:=s+GetVariable(mt.Return)+acReturn
{ else // remove this!
  s:=s+SWFPushUndefined+acReturn};

  FExit := oldExit;

  if s = '' then s := acReturn; // empty proc (but defined)

  mt.code := s;//+acReturn;//this comment can be removed ? +acReturn;

  if Length(mt.code) > $FFFF then
    Error('C5681', 'Function too long');

  DropToken(tk_SemiColon);

  Result := '';
  if cl.Aliased then
    CodeItem.Code := mt.Definition;
 // CodeItem.Code := DeclareFunction(mt, mt.codeName);
 // mt.Code := DeclareFunction(mt, ''); // Anonymus fonction for BuildCode()

  CodeItem := TCodeItem.Create(Self, ci);

  Scopes := sc;
end;

procedure TCompiler.PublicMethod(void: Boolean);
var
  m: TMethod;
begin
  m := GetMethod(nil, void, False);
  if SkipToken(tkExternal) then
    ExternalMethod(m)
  else
    DropToken(tk_SemiColon);
end;

procedure TCompiler.ExternalMethod(AMethod: TMethod);
begin
 {$IFDEF REG_VARS}
  if AMethod.proto.Return <> nil then
    Dec(AMethod.proto.Regs);
 {$ENDIF}
  if TokenType = tk_Number then // function getTimer: Number external 52;
  begin
    if BitsCount(Token) <> 8 then
      Error('C4193', 'Byte expected');
    AMethod.SysCall := StrToInt(Token);
    NextToken;
    DropToken(tk_SemiColon);
  end else
  if SkipToken(tk_SemiColon) then // function escape(expression: string): string external;
  begin
    AMethod.CodeName := AMethod.realName;
    AMethod.Externe := '';
  end else begin
  // we need a case sensitive name !
    if TokenType = tk_String then // function StrToInt(expression: string; radix: Number = 10): Number external 'parseInt';
    begin
      AMethod.Externe := '';//Token;
      AMethod.realName := Token;
      NextToken;
    end else begin
      AMethod.Externe := SrcToken;
      GetIdent;
      DropToken(tk_Dot);
      AMethod.realName := SrcToken;
      NextToken;
      while SkipToken(tk_Dot) do
      begin
        AMethod.Externe := AMethod.Externe + ':' + AMethod.realName;
        AMethod.realName := SrcToken;
        NextToken;
      end;
    end;
    AMethod.CodeName := AMethod.realName;
    AMethod.localName := AMethod.realName;
    DropToken(tk_SemiColon);
  end;
end;

function TCompiler.StaticMethod(void:boolean): string;
var
  m: TMethod;
  s: string;
  OldExit: string;
  sc: PScope;
  ci: TCodeItem;
begin
  m := GetMethod(nil, void, False);
  if SkipToken(tkExternal) then
  begin // function cos(a:double):double external Math.cos;
    ExternalMethod(m);
    Result := ''; // pas de code pour une classe externe
  end else begin
    DropToken(tk_SemiColon);

    m.CodeName := GetName('f', FPrefix + m.realName);
    m.LocalName := m.CodeName;

    sc := Scopes;
    m.Scope.Next := Scopes;
    Scopes := @m.Scope;

    // sauver le codeItem courant
    ci := CodeItem;
    // Créer un nouveau codeItem
    CodeItem := TCodeItem.Create(Self, m.CodeItem);
    // le lier à la méthode (cf TCodeItem.Needed)
    m.CodeItem := CodeItem;

    s := '';
    if m.proto.Kind <> nil then
    begin
      if IsArray(m.proto.Kind) then
        s := SetVariable(m.proto.Return, BuildArray(TArray(RealType(m.proto.Kind))))
      else
      if IsRecord(m.proto.Kind) then
        s := SetVariable(m.proto.Return, TRecord(RealType(m.proto.Kind)).Init1);
    end;

    FMethod := m;

    if SkipToken(tkVar) then
    begin
      repeat
        s := s + DeclareVar(m, True);
        DropToken(tk_SemiColon);
      until Token = 'BEGIN';
      //local.Symbol := m;
      //local.Next := Scopes;
      //Scopes := @local;
    end;

    oldExit := FExit;
    if m.proto.Return <> nil then
      FExit := GetVariable(m.proto.Return) + acReturn
    else
      FExit := SWFPushUndefined + acReturn;

    DropToken(tkBegin);
    while Token <> 'END' do
    begin
      s := s + Statement;
      if Length(s) > $FFFF then
        Error('C04321', 'Function too long');
      if Token <> 'END' then
        DropToken(tk_SemiColon);
    end;
    NextToken;
    if m.proto.Return <> nil then
      s := s + FExit; // s:=s+GetVariable(m.Return)+acReturn;
{  else // remove this ???
    s:=s+SWFPushUndefined; }

    FExit := oldExit;

    m.code:=s;//+acReturn;//this comment can be removed ? +acReturn;

    DropToken(tk_SemiColon);

    // Code de cet item
    CodeItem.Code := DeclareFunction(m,m.codeName);
    // Créer un nouveau CodeItem lié au précédent
    CodeItem := TCodeItem.Create(Self, ci);

    FMethod := nil;

    Result := '';

    Scopes := sc;
  end;
end;

function TCompiler.CheckClass(AClass: TClassDef): string;
var
  base: TClassDef;
  s: TSymbol;
  m: TMethod absolute s;
begin
  Result := '';

  base := AClass._inherite;
  while (base <> nil) and (base.UserClass) do
  begin
    Result := Result + CheckClass(base);
    base := base._inherite;
  end;

  s := AClass.Scope.Symbol{_symbols};
  while s <> nil do
  begin
    if s is TMethod then
      if (m.code = '') and (not m.IsAbstract) and (not m.IsEmpty) then
        Error('C3832', 'Declaration not solved ' + AClass.realName + '.' + m.realName, m);  // do we need this or just a return?
    s := s.NextSymbol;
  end;
end;

function TCompiler.CheckClasses: string;
var
  s: TSymbol;
begin
  Result := '';
  s := Scope.Symbol;
  while s <> nil do
  begin
    if (s is TClassDef) and (TClassDef(s).UserClass) then
      Result := Result + CheckClass(TClassDef(s));
    s := s.NextSymbol;
  end;
end;

procedure TCompiler.UnitCompilation(const Name:string);
begin
  ThisSource := Self;
 //SourceList.FNext := Self;
 FNext := SourceList;
 SourceList := Self;
 NextToken;
 DropToken(tkUnit);
 FRealName := SrcToken;
 FName := Token;
 DropIdent(name);   // linux issue
 DropToken(tk_SemiColon);
 UnitInterface;
end;

procedure TCompiler.UnitInterface;
var
  Sc: PScope;
  Last, Next: TToken;
  Skip: Boolean;
begin
  Inc(SourceID);
  if Obfuscate then
    FPrefix := '$' + IntToStr(SourceID)
  else
    FPrefix := 'pas_' + FRealName + '_';

  SC := Scopes;
  try
  Scopes := @Scope;
  if FUnit <> uNone then
    Error('C3868', 'Invalid unit state');
  DropToken(tkInterface);
  FUnit := uInterface;
  AddUnit(_System);
  if SkipToken(tkUses) then
    AddUses;
  Last := tk_Ident;
  while Token <> 'IMPLEMENTATION' do
  begin
    Next := TokenIndex([tkVar, tkType, tkConst, tkProcedure, tkFunction]);
    Skip := True;
    if Next = tk_Ident then
    begin
      Next := TokenSymbol;
      if (Next in [tk_Constant]) and (Symbol.Level <> Scopes) then
        Next := tk_Ident;
      if Next = tk_Ident then
      begin
        Next := Last;
        Skip := False;
      end;
    end else
    if Last = tkType then
    begin
      CheckForwardClasses
    end;
    case Next of

      tk_Class:
      begin
        if (Last = tkType) and (TClassDef(Symbol)._forward) then
        begin
          ForwardClass(TClassDef(Symbol));
          DropToken(tk_SemiColon);
          Next := tkType;
        end else
          Error('C3746', 'Unexpected class type');
      end;

      tkVar:
      begin
        if Skip then
          NextToken;
        CodeItem.Code := CodeItem.Code + DeclareVar(nil, False);
        DropToken(tk_SemiColon);
      end;

      tkType:
      begin
        if Skip then
           NextToken;
        DeclareType;
      end;

      tkConst:
      begin
        if Skip then
          NextToken;
        DeclareConst
      end;

      tkProcedure:
      begin
        NextToken;
        PublicMethod(True);
      end;

      tkFunction:
      begin
        NextToken;
        PublicMethod(False);
      end;

     else
       Error('C4594', 'Unexpected token ' + SrcToken);//implementation expected
     end;
     Last := Next;
  end;
  if Last = tkType then
    CheckForwardClasses;
  finally
    FIntf := Scopes.Symbol;
    Scopes := sc;
  end;
end;

procedure TCompiler.UnitImplementation;
var
  sp: PScope;
begin
  if FUnit = uDone then
    Exit;
  if FUnit <> uInterface then
    Error('C3930', 'Missing interface');
  ThisSource := Self;
  DropToken(tkImplementation);
  FUnit := uImplementation;

  sp := Scopes;
  Scopes := @Scope;

  if SkipToken(tkUses) then
    AddUses;
  ImplementUnits;
  //FInit := '';
  while not SkipToken(tkEnd) do
  begin
    MainStatement;
    if SkipToken(tkBegin) then
    begin
      while Token <> 'END' do
      begin
        //FInit := FInit + Statement;
        CodeItem.Code := CodeItem.Code + Statement;
        CodeItem.Required := True;
        if Token <> 'END' then
          DropToken(tk_SemiColon);
      end;
      NextToken;
      Break;
    end;
  end;
  if TokenType <> tk_Dot then
    Error('C6278', '. expected');
  CheckClasses;
  if FIfDefs <> '' then
    Error('C6281', 'Missing ENDIF');
  CodeItem.Code := CodeItem.Code + FInit;// + CheckClasses; // CheckClasses looks better on the main begin
  FUnit := uDone;
  Scopes := sp;
end;

procedure TCompiler.ImplementUnits;
var
  u: TUnit;
begin
  u := FUses;
  while u <> nil do
  begin
    u.Source.UnitImplementation;
    u := u.Next;
  end;
  ThisSource := Self;
end;

procedure TCompiler.Compile(Debug: Boolean);
var
  i: Integer;
begin
  if MainSource <> nil then
    Error('C3959', 'Sources not null');//Assert(Sources=nil,'Sources not null');

  ThisSource := Self;

  Scopes := @Scope;

  FInit := '';

  SourceList := Self;
  NextToken;
  // UNIT
  if SkipToken(tkUnit) then
  begin
    FName := GetIdent;
    DropToken(tk_SemiColon);
    UnitInterface;
    UnitImplementation;
    Error('C4400', 'Unit is ok');
  end;
  // PROGRAM <name>;
  DropToken(tkProgram);
  FTarget := ChangeFileExt(Provider.FileName, '');

  if Obfuscate then
    FPrefix := '$_'
  else
    FPrefix := 'fpr_' + SrcToken + '_';


  FName := GetIdent;
  MainSource := Self;
  DropToken(tk_SemiColon);

  CodeItem := TCodeItem.Create(Self, nil);

  // USES <unit [in 'unit.pas'][,~]>;
  AddUnit(_System);
  if SkipToken(tkUses) then
    AddUses;
  ImplementUnits;

  CodeItem.Code := CodeItem.Code + UnitsCode;

  while Token <> 'BEGIN' do // do not fetch tkBegin twice !
  begin
    MainStatement;
  end;
  CheckClasses; // CheckClasses looks better on the main begin
  CodeItem.Code := CodeItem.Code + FInit;

  NextToken; // do not fetch tkBegin twice !

  while Token <> 'END' do
  begin
    CodeItem.Code := CodeItem.Code + Statement;
    if Token <> 'END' then
      DropToken(tk_SemiColon)
  end;
  DropToken(tkEnd);

  if Token <> '.' then
    Error('C6364', '. expected');

  if FIfDefs <> '' then
    Error('C6367', 'Missing ENDIF');

  if ResourceID > 0 then
    ExportNames := SWFlhead(56, // Export
                   SWFshort(ResourceID) // # of IDs
                  +ExportNames
                  );

  if Debug then
  begin
    Resources := SWFlhead(64, #0#0'$1$qj$gKK95cYMx2sdffh2Cg95H1'#0) // EnableDebugger2
               + Resources;
  end;

  CodeItem.Needed; // main code is requiered, that will check all dependency of the project
{
  FCode := SWFOptimize(
                     SWFPushString('$top')
                   + SWFPushInteger(0)
                   + acDeclareObject
                   + acSetVariable
                   );
}
  for i := 0 to CodeList.count - 1 do
  begin
    with TCodeItem(CodeList[i]) do
    begin
      if Required or NoOptimize then
      begin
        if Owner is TClassDef then
          TClassDef(Owner).BuildCode;
        FCode := FCode + Code;
      end;
    end;
  end;

  FCode:=SWFAttributes(0)
       +SWFBackground((Background shr 16) and $FF,(Background shr 8) and $FF,Background and $FF)
       +Resources
       +ExportNames
       +SWFDoAction(FCode+acEndAction)
       +SWFShowFrame // needed by FlashPlayer.exe to show the first frame
       +SWFEndTag;

  if UncompressedOutput then
    FCode := SWFFileNotCompressed(FlashVersion, FrameWidth, FrameHeight, FrameRate, 1, FCode) // for special needs if any
  else
    FCode := SWFFile(FlashVersion, FrameWidth, FrameHeight, FrameRate, 1, FCode);
end;

procedure TCompiler.MainStatement;
var
  Last, Next: TToken;
  Skip: Boolean;
begin
  Last := tk_Ident;
  repeat
    Next := TokenIndex([tkVar, tkType, tkConst, tkConstructor, tkProcedure, tkFunction, tkBegin, tkEnd]);
    Skip := True;
    if Next = tk_Ident then
    begin
      Next := TokenSymbol;
      if (Next in [tk_Variable..tk_Constant]) and (Symbol.Level <> @Scope) then
        Next := tk_Ident;
      if Next = tk_Ident then
      begin
        Next := Last;
        Skip := False;
      end;
    end else
    if Last = tkType then
    begin
      CheckForwardClasses;
    end;
    case Next of

      tkVar :
      begin
        if Skip then
          NextToken;
        CodeItem.Code := CodeItem.Code + DeclareVar(nil, False);
        DropToken(tk_SemiColon);
      end;

      tkType :
      begin
        if Skip then
          NextToken;
        DeclareType
      end;

      tk_Class:
      begin
        if (Last <> tkType) or (TClassDef(Symbol)._Forward = False) then
          Error('C5630', 'Duplicate class name');
        ForwardClass(TClassDef(Symbol));
        DropToken(tk_SemiColon);
        Next := tkType;
      end;

      tkConst :
      begin
        if Skip then
          NextToken;
        DeclareConst
      end;

      tkConstructor :
      begin
        CodeItem.Code := CodeItem.Code + DefineConstructor;
      end;

      tkProcedure   :
      begin
        NextToken;
        if TokenSymbol = tk_Class then
          CodeItem.Code := CodeItem.Code + DefineMethod(True)
        else
          CodeItem.Code := CodeItem.Code + StaticMethod(True);
      end;

      tkFunction    :
      begin
        NextToken;
        if TokenSymbol = tk_Class then
          CodeItem.Code := CodeItem.Code + DefineMethod(False)
        else
          CodeItem.Code := CodeItem.Code + StaticMethod(false);
      end;

      tkBegin, tkEnd : Break;

    else
      Error('C5660', 'Unexpected token.'); // ... expected
    end;

    Last := Next;

  until Next = tk_Ident;
end;

procedure TCompiler.Save(Debug: Boolean);
var
  f: File;
begin
{$I-}
  AssignFile(f, FTarget + '.swf');
  Rewrite(f,1);
  BlockWrite(f,FCode[1],Length(FCode));
  CloseFile(f);
  if IOResult<>0 then FatalError('Cannot write file '+FTarget+'.swf','Save');
{$IFDEF DEBUGER}
  if Debug then
  begin
    AssignFile(f, FTarget + '.swd');
    Rewrite(f,1);
    FCode := 'FWD'#7#3'0123456789ABCDEF';
    BlockWrite(f,FCode[1],Length(FCode));
    CloseFile(f);
    if IOResult<>0 then FatalError('Cannot write file '+FTarget+'.swd','Save');
  end;
{$ENDIF}
{$I+}
end;

procedure TCompiler.AddUses;
var
  SourceName: string;
  FileName  : string;
begin
  repeat
    SourceName := Token;
    FileName := SrcToken + '.pas'; // maybe we don't have the syntax: in 'unit.pas'
    GetIdent;
    if Self = MainSource then
    begin
      if SkipToken(tkIn) then
      begin
        FileName := SrcToken; // on Linux we need case sensitive file name, so let's get it
        DropToken(tk_String);
      end;
    end;
    CompileUnit(SourceName, FileName);
  until SkipToken(tk_Comma) = False;
  DropToken(tk_SemiColon);
end;

procedure TCompiler.CompileUnit(const ASourceName, AFileName: string);
var
  u: TUnit;
  s: TFileProvider;
  c: TCompiler;
begin
  u := FUses;
  while u <> nil do
  begin
    if u.Source.FName = ASourceName then
      Error('C4168', 'What happens here?'); // Circular unit reference?
    u := u.Next;
  end;
  c := SourceList;
  while c <> nil do
  begin
    if c.FName = ASourceName then
    begin
      if c = MainSource then
        Error('C4177', 'Can''t use main program');
      Break;
    end;
    c := c.FNext;
  end;
  if c = nil then
  begin
    c := GetFileCompiler(AFileName);
    if c = nil then
    begin
      // here to search on default unit path too
      if FileExists(Path + AFileName) then
        s := TFileProvider.Create(Path + AFileName)
      else
      if FileExists(LibPath + AFileName) then
        s := TFileProvider.Create(LibPath + AFileName)
      else begin
        Error('C4194', 'Unit not found '+AFileName{$IFNDEF WINDOWS}+'. File and unit names are case sensitive!'{$ENDIF});
        Exit;
      end;
      c := TCompiler.Create(s);
    end;
    c.UnitCompilation(ASourceName);
    ThisSource := Self;
  end;
  AddUnit(c);
end;

destructor TCompiler.Destroy;
var
  s: TSymbol;
//  u : TUnit;
begin
  MainSource := nil;
  SourceList := nil;
  if FNext <> nil then
    FNext.Free;
  (* units are just a kind of symbol
  while FUses<>nil do
  begin
    u := FUses;
    FUses := u.Next;
    u.Free;
  end;
  *)
 {$IFDEF GARBAGE}
  if Garbage <> nil then
 {$ENDIF}
  while Scope.Symbol <> nil do
  begin
    s := Scope.Symbol;
    Scope.Symbol := s.NextSymbol;
    s.Free;
  end;
  //Source := nil;
  FDefines.Free;
  inherited;
end;

function TCompiler.GetFileCompiler(
  const AFileName: string): TCompiler;
begin
  Result := nil;
end;

function TCompiler.GetPrototype(Proto: TPrototype): string;
var
  Inst: TInstance;
begin
  case TokenIndex([tkNil]) of

    tkNil: Error('C4135', 'nil assignement');

    tk_Ident:
      case TokenSymbol of
        tk_Variable:
        begin
          VarInstance(DropVariable, Inst);
          if not (Inst.Kind is TMethod) then
            Error('C4131', 'Method expected');
          Result := SWFOptimize(Inst.getcode);
        end;

        tk_Method:
        begin
          if TMethod(Symbol).Owner = nil then
            Error('C4140', 'Object method expected');
          if FThis then
            Result := SWFOptimize(GetThis + SWFGetMember(TMethod(Symbol).realName))
          else begin
            //Result := GetSelf + CallPrototype(SWFGetVariable('self'), Proto, TMethod(Symbol));
            Result := CallPrototype('', Proto, TMethod(Symbol));
            Result := FProlog + Result;
          end;
          NextToken;
        end

      else
        Error('C4279', 'Unexpected ident ' + SrcToken);
      end;

    else  Error('C4282', 'Method expected');

  end;
end;

procedure TCompiler.CheckForwardClasses;
var
  s: TSymbol;
begin
  s := Scopes.Symbol;
  while s <> nil do
  begin
    if (s is TClassDef) and (TClassDef(s)._forward) then
      Error('C4271', 'class not defined ' + s.realName);
    s := s.NextSymbol;
  end;
end;

function TCompiler.UnitsCode: string;
var
  C: TCompiler;
begin
  Result := '';
  C := SourceList;
  while C <> nil do
  begin
    if C <> Self then
      Result := Result + C.FCode;
    C := C.FNext;
  end;
end;

procedure TCompiler.AddUnit(AUnit: TCompiler);
var
  u: TUnit;
begin
  u := TUnit.Create(tk_Unit);
  u.Source := AUnit;
  u.name := AUnit.FName;
  u.NextSymbol :=Scopes.Symbol;
  Scopes.Symbol := u;
  u.Next := FUses;
  FUses := u;
end;

function TCompiler.GetName(Code: Char; const Name: string): string;
begin
  if Obfuscate then
  begin
    Inc(FNameIDs);
    Result := FPrefix + Code + IntToStr(FNameIDs);
  end else begin
    Result := Name;
  end;
end;

{ TWarnings }

function TWarnings.GetItem(Index: Integer): TWarning;
begin
  Result := List[Index];
end;

{ TWarning }

constructor TWarning.Create(const ANum, AMsg, AFile: string; ARow,
  ACol: Integer);
begin
  inherited Create;
  FNum := ANum;
  FMessage := AMsg;
  FFileName := AFile;
  FRow := ARow;
  FCol := ACol;
  Warnings.Add(Self);
end;

{ TSet }

constructor TSet.Create;
begin
  inherited Create(tk_Set);
  SetOf := TSetOf.Create(tk_SetOf);
  SetOf.Items := Self;
end;

destructor TSet.Destroy;
begin
  SetOf.Free;
  inherited;
end;

end.
