unit Global;

{ FlashPascal (c)2012 Execute SARL }

interface

uses
  Windows, Classes;

{$I FlashPascal.inc}

type
  PScope = ^TScope;

  TToken = (
   tkProgram,
   tkUses, tkIn, tkUnit, tkInterface, tkImplementation,
   tkVar, tkType, tkConst,
   tkBegin, tkEnd,
   tkProcedure, tkFunction,
   tkExternal,
   tkClass, tkConstructor, tkAs,
   tkPrivate, tkProtected, tkPublic,
   tkProperty, tkReadOnly, tkWriteOnly, tkRead, tkWrite, tkDefault,
   tkDeprecated,
   tkNil,
   tkDiv, tkMod,
   tkTrue,tkFalse,
   tkIf, tkThen,
   tkFor, tkTo, tkDownto, tkDo, tkWith,
   tkArray, tkOf, tkRecord, tkSet,
   tkObject,
   tkInherited, tkVirtual, tkOverride, tkAbstract,
   tkSelf,
   tkCase, tkElse,
   tkRepeat, tkUntil,
   tkWhile,
   tkOr, tkAnd,
   tkXOr, tkNot,
   tkShl, tkShrSigned, tkShrUnsigned,
   tkExit,

 // built-in const expression
   tkFloor, tkSqrt,

 // built in functions
   tkIntToStr, tkFloatToStr, tkTrunc, tkSort,
   tkPos, tkCopy, tkLength, tkOrd, tkChr, tkInc, tkDec,
   tkBoolToStr, tkHigh, tkLow, tkAbs, tkInclude, tkExclude,
   tkTrace,

 // user defined symbol
   tk_Ident, tk_Unit,
   tk_BaseType, tk_Type, tk_Variable, tk_Parameter, tk_Property, tk_Method, tk_Prototype, tk_Class, tk_Constant,
   tk_Array, tk_Record, tk_Set, tk_SetOf,
   tk_Symbol, tk_Reference,

 // Symbols, etc...
   tk_EQ, tk_GT, tk_LS, tk_GE, tk_LE, tk_NE,
   tk_Add, tk_Sub, tk_Mul, tk_Slash, tk_Range,
   tk_Assign, tk_Comma, tk_Colon, tk_SemiColon, tk_Dot,
   tk_LParen, tk_RParen,
   tk_LBracket, tk_RBracket,
   tk_String, tk_Number, tk_Float,
   tk_Comment, tk_LComment1, tk_RComment1, tk_LComment2, tk_RComment2,
   tk_Switch1,
   tk_Shl, tk_ShrSigned, tk_ShrUnsigned
  );

  TClearList = class(TList)
  public
    procedure Clear; override;
  end;

  // Les TCodeItem permette un enchainement complexe des portions de code
  // - CodeList contient la liste des tous les TCodeItem du projet
  // - le dernier CodeItem correspond au code begin/end. du projet; il est le seul obligatoirement inclus dans le SWF
  // - CodeItem.Depends contient la liste des symbols nécessaires à un CodeItem, chaque symbol peut être lié à un CodeItem
  // - Pour insérer un CodeItem lié à un symbol dans CodeList on crée lien entre entre les CodeItem précédent et suivant via le membre Previous
  // exemple:
  //   CodeItem1
  //   CodeItem2 lié à une classe
  //   CodeItem3.Previous = CodeItem1
  // - la méthode Needed force Required à True pour le CodeItem, les Previous et les CodeItem des symbols de Depends
  // - finalement le SWF contiendra tous les TCodeItem dont Required = True
  TCodeItem = class
    Owner   : TObject;
    Code    : string;    // SWF code
    Required: Boolean;   // is this code required ?
    Depends : TList;     // list of TSymbol required for this portion of code
    Previous: TCodeItem; // Linked list
    constructor Create(AOwner: TObject; APrevious: TCodeItem);
    destructor Destroy; override;
    procedure Needed;
  end;

  TSymbol = class
    Level     : PScope;  // Scope Level
    name      : string;  // upper case name
    realName  : string;  // the real name as in type or var definition
    CodeName  : string;  // obfusced name
    Token     : TToken;
    NextSymbol: TSymbol; // linked list of symbols
    CodeItem  : TCodeItem;
    FileName  : string;
    Row,Col   : Integer;
    constructor Create(AToken: TToken);
    destructor Destroy; override;
  end;

  TScope = record
    Symbol: TSymbol; // last symbol of the linked list in this scope
    Next  : PScope;  // next scope
    Step  : Integer; // -1 for a WITH
  end;

function StrLess(const Str, Value: string): Boolean;
procedure FinalProc;
procedure FatalError(const Msg, Fnc: string); // error message, function id

var
{$IFDEF MEMCHECK}
  sCount : Integer;
  eCount : Integer;
{$ENDIF}
  CodeList    : TList; // list of all the CodeItems of the project
{$IFDEF GARBAGE}
  Garbage      : TList;
  PrototypeCount: Integer = 0;
{$ENDIF}
  Obfuscate    : Boolean;
const
  VersionString = 'version 13.04.29';

var
  Scopes                : PScope;  // linked list of Scopes
  Path                  : string;  // path to the program source file
  LibPath               : string;  // default path to the units
  DisplayErrors         : Boolean; // -e display error messages on programming errors
  PauseBeforeExit       : Boolean; // -p pause before exit (unused variable)
  DisplaySourceOnErrors : Boolean; // -s show source line on errors
  DisplayWarnings       : Boolean; // -w display warning messages on possible mistakes
  UncompressedOutput    : Boolean; // -u do not compress the swf file (for special needs if any)
  HtmlTestPageOutput    : Boolean; // -t generate html file for testing
  DisplayNotes          : Boolean; // -n display notes stored in the source
  //UseRegisterVariables  :Boolean; // -r use registers for variables where it is possible
  SyntaxCheckingOnly    : Boolean; // -x syntax checking only, no files written

  NoOptimize            : Boolean;

implementation

uses Parser, Compiler;

// compare two litteral integers
function StrLess(const Str,Value:string):boolean;
var
 i,l:integer;
begin
 l:=Length(Str);
 if l=Length(Value) then begin
  for i := 1 to L do begin
   if Str[i] < Value[i] then begin
    Result:=True;
    exit;
   end;
   if Str[i] > Value[i] then begin
    Result:=False;
    exit;
   end;
  end;
  Result:=True;
 end else begin
  Result:=l<Length(Value);
 end;
end;

// pause before exit or not
procedure FinalProc;
begin
  if PauseBeforeExit then ReadLn else WriteLn;
end;

// non pascal related errors such as file IO and others
procedure FatalError(const Msg,Fnc:string); // error message, function id
begin
  Write('Fatal: ',Msg);
  {if Fnc<>'' then WriteLn(' (',Fnc,')') else} WriteLn;
  Halt(255);// fatal error
end;

function urlEncode(s:string):string;
{URL Encoding of special characters
;   %3B
?   %3F
/   %2F
:   %3A
#   %23
&   %26
=   %3D
+   %2B
$   %24
,   %2C
<space>   %20 or +
%   %25
<   %3C
>   %3E
~   %7E}
var i:integer;
begin
  for i:=1 to length(s) do
    case s[i] of
      ';': result:=result+'%3B';
      '?': result:=result+'%3F';
      '/': result:=result+'%2F';
      ':': result:=result+'%3A';
      '#': result:=result+'%23';
      '&': result:=result+'%26';
      '=': result:=result+'%3D';
      '+': result:=result+'%2B';
      '$': result:=result+'%24';
      ',': result:=result+'%2C';
      ' ': result:=result+'%20'; // or + {deprecated}
      '%': result:=result+'%25';
      '<': result:=result+'%3C';
      '>': result:=result+'%3E';
      '~': result:=result+'%7E';
      else result:=result+s[i];
    end;
end;

{ TCodeItem }

constructor TCodeItem.Create(AOwner: TObject; APrevious: TCodeItem);
begin
  inherited Create;
{$IFDEF GARBAGE}
  Garbage.Add(Self);
{$ENDIF}
  Owner := AOwner;
  Previous := APrevious;
  Depends := TList.Create;
  CodeList.Add(Self);
end;

destructor TCodeItem.Destroy;
begin
{$IFDEF GARBAGE}
  if Garbage <> nil then
    Garbage.Remove(Self);
{$ENDIF}
  Depends.Free;
  inherited;
end;

//**
//* Cette procédure détermine les dépendences de code
//**
procedure TCodeItem.Needed;
var
  Symbol: TSymbol;
  Index : Integer;
begin
  if not Required then
  begin
    Required := True;
    for Index := 0 to Depends.Count - 1 do
    begin
      Symbol := TSymbol(Depends[Index]);
      if Symbol is TVariable then
        with TVariable(Symbol) do
          if (Owner = nil) and (IsSet = False) and (Externe = False) then
            TWarning.Create('C0257', 'La valeur de cette variable globale n''est jamais définie; utilisez le mot clé external si elle est externe', Symbol.FileName, Symbol.Row, Symbol.Col);
      with Symbol do
      begin
        if CodeItem <> nil then
          CodeItem.Needed;
      end;
    end;
    if Previous <> nil then
      Previous.Needed;
  end;
end;

{ TSymbol }

constructor TSymbol.Create(AToken: TToken);
begin
{$IFDEF GARBAGE}
  Garbage.Add(Self);
{$ENDIF}
  Level := Scopes;
  Token := AToken;
  if ThisSource <> nil then
  begin
    if ThisSource.Provider <> nil then
      FileName := ThisSource.Provider.FileName;
    Row := ThisSource.Line;
    Col := ThisSource.Index;
  end;
{$IFDEF MEMCHECK}
  Inc(sCount);
{$ENDIF}
end;

destructor TSymbol.Destroy;
begin
{$IFDEF GARBAGE}
  if Garbage <> nil then
    Garbage.Remove(Self);
{$ENDIF}
{$IFDEF MEMCHECK}
// WriteLn(realName,'->',ClassName);
 dec(sCount);
{$ENDIF}
  inherited;
end;

{ TClearList }

procedure TClearList.Clear;
var
  Index: Integer;
begin
  for Index := 0 to Count - 1 do
    TObject(List[Index]).Free;
  inherited;
end;


{$IFDEF GARBAGE}
procedure GarbageCollect;
var
  g: TList;
  i: Integer;
  l: TStringList;
  o: TObject;
  s: string;
  n: Integer;
  c: Integer;
begin
  if Garbage.Count = 0 then
    Exit;
  g := Garbage;
  Garbage := nil;
  try
    AllocConsole;
    WriteLn('Garbage count = ', g.Count);
    l := TStringList.Create;
    try
      l.Sorted := True;
      for i := g.Count - 1 downto 0 do
      begin
        o := g[i];
        s := o.className;
        n := l.IndexOf(s);
        if n < 0 then
        begin
          c := 1;
          l.AddObject(s, TObject(c));
        end else begin
          c := Integer(l.Objects[n]) + 1;
          l.Objects[n] := TObject(c);
        end;
        o.Free;
      end;
      for i := 0 to l.Count - 1 do
      begin
        WriteLn(Integer(l.Objects[i]):3, ' ', l[i]);
      end;
      WriteLn('Prototype count = ', PrototypeCount);
      ReadLn;
    finally
      l.Free;
    end;
    g.Clear;
  finally
    Garbage := g;
  end;
end;

initialization
  Garbage := TList.Create;
finalization
  GarbageCollect;
  Garbage.Free;
{$ENDIF}
end.
