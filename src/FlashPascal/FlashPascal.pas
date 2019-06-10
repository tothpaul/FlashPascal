unit FlashPascal;

{ FlashPascal (c)2012 Execute SARL }

interface

uses
  Classes, SysUtils, Source;

type
  TStringProvider = class(TSourceProvider)
    FText : string;
    FIndex: Integer;
  public
    constructor Create(const AFileName, AText: string);
    function EOF: Boolean; override;
    function ReadChar: Char; override;
  end;

  TStringsProvider = class(TSourceProvider)
  private
    FLines: TStrings;
    FLine : Integer;
    FText : string;
    FIndex: Integer;
  public
    constructor Create(const AFileName: string; ALines: TStrings);
    function EOF: Boolean; override;
    function ReadChar: Char; override;
  end;


procedure CompileFile(const AFileName: string; ASource: TStrings; Save, Debug, Obfusc: Boolean);

implementation

uses Compiler, Global, Parser, SWF, Main;

type
  TIDECompiler = class(TCompiler)
  protected
    function GetFileCompiler(const AFileName: string): TCompiler; override;
  end;

  TSystemUnit = class(TCompiler)
    constructor Create;
    function AddType(const Name: string): TSymbol;
  end;

function TIDECompiler.GetFileCompiler(const AFileName: string): TCompiler;
var
  S: TSourceProvider;
begin
  S := MainForm.GetSource(AFileName);
  if S = nil then
  begin
    S := MainForm.GetSource(Path + AFileName);
    if S = nil then
      S := MainForm.GetSource(LibPath + AFileName);
  end;
  if S = nil then
    Result := nil
  else
    Result := TIDECompiler.Create(S);
end;

constructor TSystemUnit.Create;
begin
  ThisSource := Self;
  FName := 'SYSTEM';
  Scopes := @Scope;
  _Char    := AddType('Char');
  _String  := AddType('string');
  _Integer := AddType('Integer');
  _Double  := AddType('Double');
  _Boolean := AddType('Boolean');
  _Object  := AddType('TObject');
  _Variant := AddType('Variant');
  FIntf := Scope.Symbol;
  FUnit := uDone;
end;

function TSystemUnit.AddType(const Name: string): TSymbol;
begin
  Result := TBaseType.Create(tk_BaseType);
  Result.name := UpperCase(Name);
  Result.realName := Name;
  Result.NextSymbol := Scope.Symbol{Symbols};
  Scope.Symbol{Symbols} := Result;
end;

procedure CompileFile(const AFileName: string; ASource: TStrings; Save, Debug, Obfusc: Boolean);
var
  c:TCompiler;
  s: TSymbol;
  src : TStringsProvider;
//  global: TScope;
begin
 Path := ExtractFilePath(AFileName);

// default path for units
(*
  LibPath := ExtractFilePath(ParamStr(0)); // default LibPath is this compiler's path + 'units'
  if DirectoryExists(LibPath + 'units') then
  begin
    LibPath := LibPath + 'units\';
  end else
  if DirectoryExists(LibPath + '..\units') then
  begin
    LibPath := ExtractFilePath(ExcludeTrailingPathDelimiter(LibPath)) + 'units\';
  end;
  DecimalSeparator := '.';
*)
// init symbols
//  Symbols := nil;
  Anonyms := nil;
  //Scopes  := @global;
  //global.Symbol := nil;
  //global.Next := nil;
//  _Root   := TVariable.Create;
//  _Root.realName := '_root';
  _System := TSystemUnit.Create;

//  syms := Symbols;

  FrameWidth   := 800;
  FrameHeight  := 600;
  FrameRate    := 32;
  Background   := $FFFFFF;
  FlashVersion := 9;

  src := TStringsProvider.Create(AFileName, ASource);
  c := TIDECompiler.Create(src);

  Dictionary.Items  := nil;
  Dictionary.Length := 0;
  Dictionary.Count  := 0;
  Resources := '';
  ExportNames := '';
  ResourceID := 0;

  SourceID := 0;
  Obfuscate := Obfusc;

  CodeList := TClearList.Create;

  try
    c.Compile(Debug);
    if Save then
      c.Save(Debug);
  finally
    CodeList.Free;

    SourceList.Free;

    SWFDictionary;

    Resources := '';
(*
    s := Symbols;
    while s <> syms do
    begin
      Symbols := s.NextSymbol;
      s.Free;
      S := Symbols;
    end; *)
    s := Anonyms;
    while s <> nil do
    begin
      Anonyms := s.NextSymbol;
      s.Free;
      s := Anonyms;
    end;

    _System.Free;
  end;
end;

{ TStringsProvider }

constructor TStringsProvider.Create(const AFileName: string;
  ALines: TStrings);
begin
  FileName := AFileName;
  FLines := ALines;
  FLine := 0;
  if FLines.Count > 0 then
    FText := FLines[0] + #13#10;
  FIndex := 1;
end;

function TStringsProvider.EOF: Boolean;
begin
  Result := FLine >= FLines.Count;
end;

function TStringsProvider.ReadChar: Char;
begin
  while FIndex > Length(FText) do
  begin
    Inc(FLine);
    if EOF then
      raise EndOfFile.Create('Unexpected end of file');
    FText := FLines[FLine] + #13#10;
    FIndex := 1;
  end;
  Result := FText[FIndex];
  Inc(FIndex);
end;

{ TStringProvider }

constructor TStringProvider.Create(const AFileName, AText: string);
begin
  FileName := AFileName;
  FText := AText;
  FIndex := 1;
end;

function TStringProvider.EOF: Boolean;
begin
  Result := FIndex > Length(FText);
end;

function TStringProvider.ReadChar: Char;
begin
  if EOF then
    raise Exception.Create('Unexpected end of file');
  Result := FText[FIndex];
  Inc(FIndex);
end;

end.
