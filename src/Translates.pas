unit Translates;

{ FlashPascal (c)2012 Execute SARL }

interface

uses
  Windows, SysUtils, Classes, Dialogs,
  IniFiles,  SHFolder,
  Forms, StdCtrls, ExtCtrls, Menus, ComCtrls;

type
  ITranslate = interface
  ['{57F003D5-8394-4174-8FEB-CE947C853B43}']
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

// Pour chaque élément nous avons besoin de conserver la valeur 'fr_FR' comme nom de référence
  TMenuItem = class(Menus.TMenuItem, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TLabel = class(StdCtrls.TLabel, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TButton = class(StdCtrls.TButton, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TCheckBox = class(StdCtrls.TCheckBox, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TRadioButton = class(StdCtrls.TRadioButton, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TRadioGroup = class(ExtCtrls.TRadioGroup, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TToolButton = class(ComCtrls.TToolButton, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TComboBox = class(StdCtrls.TComboBox, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TOpenDialog = class(Dialogs.TOpenDialog, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

  TSaveDialog = class(Dialogs.TSaveDialog, ITranslate)
  private
    fr_FR: string;
    function NeedTranslate: Boolean;
    procedure DoTranslate;
  end;

// La fiche possède une langue et se charge de traduire tous ses composants
  TForm = class(Forms.TForm)
  private
    fr_FR: string;
    Lang : string;
    Trans: TList;
    procedure Translate(Reload: Boolean); 
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;
  end;

// Change la langue de toutes les fiches ouvertes
procedure SetLang(const Str: string; Reload: Boolean);

// Traduit une chaîne dans la langue courante
function Translate(const Str: string; const Category: string = 'Messages'): string;

function EncodeStr(const Str: string): string;
function DecodeStr(const Str: string): string;

var
  IniPath   : string;
  DataPath  : string;
  LangPath  : string;   // ExtractFilePath(ParamStr(0))
  LangFile  : string;   // ExtractFileName(ParamStr(0))
  Language  : string;   // Langue de Windows 'fr_FR'
  LangName  : string;   // 'Français France'

function GetSpecialFolderPath(folder : integer) : string;

implementation

var
  Translater: TIniFile; // Fichier ini pour cette langue
  FormList  : TList;

function GetSpecialFolderPath(folder : integer) : string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0,folder,0,SHGFP_TYPE_CURRENT,@path[0])) then
    Result := path
  else
    Result := '';
end;

function EncodeStr(const Str: string): string;
begin
  Result := StringReplace(Str, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, '#', '#d', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '#e', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '#n', [rfReplaceAll]);
end;

function DecodeStr(const Str: string): string;
begin
  Result := StringReplace(Str, '#e', '=', [rfReplaceAll]);
  Result := StringReplace(Result, '#n', #13#10, [rfReplaceAll]);
  Result := StringReplace(Result, '#d', '#', [rfReplaceAll]);
end;

procedure GetLang;
var
  LangID  : array[0..4] of Char;
  Country : array[0..4] of Char;
  FullName: array[0..80] of Char;
//  Exists  : Boolean;
  FileName: string;
begin
  GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SISO639LANGNAME, LangID, SizeOf(LangID));
  GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SISO3166CTRYNAME, Country, SizeOf(Country));
  GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SLANGUAGE, FullName, SizeOf(FullName));

  Language := LangID + '_' + Country;
  //Language := 'en_US';
  LangName := FullName;

  LangFile := ExtractFileName(ChangeFileExt(ParamStr(0), ''));
  FileName := LangPath + LangFile + '.' + Language;

//  Exists := FileExists(FileName);
  Translater := TIniFile.Create(FileName);
  {
  if not Exists then
  begin
    Translater.WriteString('Language', 'Locale', Language);
    Translater.WriteString('Language', 'Name', LangName);
    Translater.WriteString('Language', 'Currency', CurrencyString);
    Translater.WriteDateTime('Language', 'Created', Now);
  end;
  }
end;

procedure SetLang(const Str: string; Reload: Boolean);
var
  Index: Integer;
  FileName: string;
begin
  if Reload or (Language <> Str) then
  begin
    Language := Str;
    Translater.Free;
    FileName := LangPath + LangFile + '.' + Str;
    Translater := TIniFile.Create(FileName);
    LangName := Translater.ReadString('Language', 'Name', Language);
    for Index := 0 to FormList.Count - 1 do
      TForm(FormList[Index]).Translate(Reload);
  end;
end;

function Translate(const Str: string; const Category: string = 'Messages'): string;
begin
  Result := Translater.ReadString(Category, EncodeStr(Str), '');
  if Result = '' then
    Result := Str
  else
    Result := DecodeStr(Result);
end;

{ TForm }

constructor TForm.Create;
begin
  Trans := TList.Create;
  inherited;
end;

destructor TForm.Destroy;
begin
  FormList.Remove(Self);
  Trans.Free;
  inherited;
end;

procedure TForm.Loaded;
var
  Index: Integer;
  Comp : TComponent;
begin
  inherited;
  fr_FR := Caption;
  FormList.Add(Self);
  for Index := 0 to ComponentCount - 1 do
  begin
    Comp := Components[Index];
    if Supports(Comp, ITranslate) then
    begin
      if (Comp as ITranslate).NeedTranslate then
        Trans.Add(Comp);
    end;
  end;
  Translate(False);
end;

procedure TForm.Translate(Reload: Boolean);
var
  Index: Integer;
begin
  if (Reload = False) and (Lang = Language) then
    Exit;
  Lang := Language;
  Caption := Translates.Translate(fr_FR, 'Labels');
  for Index := 0 to Trans.Count - 1 do
  begin
    (TComponent(Trans[Index]) as ITranslate).DoTranslate;
  end;
end;

{ TMenuItem }

function TMenuItem.NeedTranslate: Boolean;
begin
  if Caption <> '-' then
    fr_FR := StringReplace(Caption, '&', '', [rfReplaceAll]);
  Result := fr_FR <> '';
end;

procedure TMenuItem.DoTranslate;
begin
  Caption := Translate(fr_FR, 'Menu');
end;

{ TLabel }

function TLabel.NeedTranslate: Boolean;
begin
  if Caption <> Name then
    fr_FR := Caption;
  Result := fr_FR <> '';
end;

procedure TLabel.DoTranslate;
begin
  Caption := Translate(fr_FR, 'Labels');
end;

{ TButton }

function TButton.NeedTranslate: Boolean;
begin
  fr_FR := Caption;
  Result := fr_FR <> '';
end;

procedure TButton.DoTranslate;
begin
  Caption := Translate(fr_FR, 'Buttons');
end;

{ TCheckBox }

function TCheckBox.NeedTranslate: Boolean;
begin
  fr_FR := Caption;
  Result := fr_FR <> '';
end;

procedure TCheckBox.DoTranslate;
begin
  Caption := Translate(fr_FR, 'Labels');
end;

{ TOpenDialog }

function TOpenDialog.NeedTranslate: Boolean;
begin
  fr_FR := Filter;
  Result := fr_FR <> '';
end;

procedure TOpenDialog.DoTranslate;
begin
  Filter := Translate(fr_FR, 'Filters');
end;

{ TSaveDialog }

function TSaveDialog.NeedTranslate: Boolean;
begin
  fr_FR := Filter;
  Result := fr_FR <> '';
end;

procedure TSaveDialog.DoTranslate;
begin
  Filter := Translate(fr_FR, 'Filters');
end;

{ TRadioButton }

procedure TRadioButton.DoTranslate;
begin
  Caption := Translate(fr_FR, 'Labels');
end;

function TRadioButton.NeedTranslate: Boolean;
begin
  fr_FR := Caption;
  Result := fr_FR <> '';
end;

{ TComboBox }

procedure TComboBox.DoTranslate;
var
  Index: Integer;
begin
  Index := ItemIndex;
  Items.Text := Translate(fr_FR, 'Lists');
  if Index < Items.Count then
    ItemIndex := Index;
end;

function TComboBox.NeedTranslate: Boolean;
begin
  fr_FR := Items.Text;
  Result := (fr_FR <> '') and (fr_FR <> Name);
end;

{ TRadioGroup }

procedure TRadioGroup.DoTranslate;
var
  Index: Integer;
begin
  Index := ItemIndex;
  Items.Text := Translate(fr_FR, 'Lists');
  if Index < Items.Count then
    ItemIndex := Index;
end;

function TRadioGroup.NeedTranslate: Boolean;
begin
  fr_FR := Items.Text;
  Result := (fr_FR <> '') and (fr_FR <> Name);
end;

{ TToolButton }

procedure TToolButton.DoTranslate;
begin
  Hint := Translate(fr_FR, 'Buttons');
end;

function TToolButton.NeedTranslate: Boolean;
begin
  fr_FR := Hint;
  Result := fr_FR <> '';
end;

initialization
  FormList := TList.Create;

  IniPath := GetSpecialFolderPath(CSIDL_PROGRAM_FILES);
  LangPath := ExtractFilePath(Application.ExeName);
  if Copy(Application.ExeName, 1, Length(IniPath)) = IniPath then
  begin
    IniPath := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA) + '\Execute SARL\FlashPascal2\';
    ForceDirectories(IniPath);
    DataPath := GetSpecialFolderPath(CSIDL_COMMON_DOCUMENTS) + '\FlashPascal2\';
  end else begin
    IniPath := LangPath;
    DataPath := IniPath;
  end;

  GetLang;
finalization
  FormList.Free;
  Translater.Free;
end.

