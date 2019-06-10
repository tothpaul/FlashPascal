unit Main;

interface

{$I FlashPascal\FlashPascal.inc}

uses
{$IFDEF DEBUGER}Debugger,{$ENDIF}
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SynEdit, SynHighlighterPas, Menus, ExtCtrls, ComCtrls, ShellAPI,
  IniFiles, Source, SWF, Preview, SynEditHighlighter, SynEditOptionsDialog,
  SynEditMiscClasses, SynEditSearch, SynEditTypes, SynEditKeyCmds, RegEdit,
  ImgList, ToolWin, HTTP, SHFolder, Translates;
  
type
  TSourceFile = class
    FileSource: string;                     
    SelStart  : Integer;
    SelEnd    : Integer;
    TopLine   : Integer;
    LeftChar  : Integer;
    Modified  : Boolean;
    TabIndex  : Integer;
  end;

  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuOpen: TMenuItem;
    mnuSave: TMenuItem;
    N1: TMenuItem;
    mnuQuit: TMenuItem;
    Flash1: TMenuItem;
    mnuCompile: TMenuItem;
    mnuRun: TMenuItem;
    OpenDialog: TOpenDialog;
    StatusBar1: TStatusBar;
    lbError: TLabel;
    TabControl: TTabControl;
    mnuHelp: TMenuItem;
    N2: TMenuItem;
    mnuAutoRefresh: TMenuItem;
    SaveDialog: TSaveDialog;
    mnuUsePlayer: TMenuItem;
    SynEdit1: TSynEdit;
    SynPasSyn1: TSynPasSyn;
    SynEditSearch1: TSynEditSearch;
    FindDialog1: TFindDialog;
    mnuRecent: TMenuItem;
    mmMsg: TMemo;
    mnuDebug: TMenuItem;
    mnuHTML: TMenuItem;
    ToolBar1: TToolBar;
    ImageList1: TImageList;
    btNew: TToolButton;
    btOpen: TToolButton;
    btSave: TToolButton;
    btUndo: TToolButton;
    btRedo: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    btRun: TToolButton;
    Edition1: TMenuItem;
    mnuCopy: TMenuItem;
    mnuPaste: TMenuItem;
    mnuCut: TMenuItem;
    N4: TMenuItem;
    mnuSearch: TMenuItem;
    N5: TMenuItem;
    Nouveau1: TMenuItem;
    mnuNewFPR: TMenuItem;
    mnuNewPAS: TMenuItem;
    popupTabs: TPopupMenu;
    ppmClose: TMenuItem;
    mnuClose: TMenuItem;
    mnuAbout: TMenuItem;
    N3: TMenuItem;
    mnuSamples: TMenuItem;
    N7: TMenuItem;
    mnuOptions: TMenuItem;
    mnuSaveAs: TMenuItem;
    AdobeAir1: TMenuItem;
    mnuUndo: TMenuItem;
    mnuRedo: TMenuItem;
    N6: TMenuItem;
    Forumweb1: TMenuItem;
    N8: TMenuItem;
    Siteweb1: TMenuItem;
    mnuObfusc: TMenuItem;
    lbWarnings: TListBox;
    Splitter: TSplitter;
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure mnuCompileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SynEdit1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TabControlChange(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);
    procedure mnuQuitClick(Sender: TObject);
    procedure FindDialog1Find(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SynEdit1ContextHelp(Sender: TObject; word: String);
    procedure SynEdit1CommandProcessed(Sender: TObject;
      var Command: TSynEditorCommand; var AChar: Char; Data: Pointer);
    procedure mnuHTMLClick(Sender: TObject);
    procedure mnuCloseClick(Sender: TObject);
    procedure mnuNewFPRClick(Sender: TObject);
    procedure mnuNewPASClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btNewClick(Sender: TObject);
    procedure mnuCutClick(Sender: TObject);
    procedure mnuCopyClick(Sender: TObject);
    procedure mnuPasteClick(Sender: TObject);
    procedure mnuSearchClick(Sender: TObject);
    procedure mnuUsePlayerClick(Sender: TObject);
    procedure mnuOptionsClick(Sender: TObject);
    procedure mnuSaveAsClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SynEdit1Change(Sender: TObject);
    procedure mnuUndoClick(Sender: TObject);
    procedure mnuRedoClick(Sender: TObject);
    procedure Forumweb1Click(Sender: TObject);
    procedure Siteweb1Click(Sender: TObject);
    procedure lbWarningsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbWarningsClick(Sender: TObject);
  private
    { Déclarations privées }
    FIni     : TIniFile;
    FLogo    : TIcon;
    FFileName: string;
    FTarget  : string;
    FPlayer  : string;
    FSources : TStringList;
    FSource  : TSourceFile;
    FRunning : Cardinal;
    FProcess : THandle;
    FWindow  : THandle;
    FModified: Boolean;
    FChecker : TVersionCheck;
    FFPRCount: Integer;
    FPASCount: Integer;
   {$IFDEF DEBUGER}
    FDebugger: TDebugger;
   {$ENDIF}
    procedure SetUI(Enabled: Boolean);
    procedure LoadSamplesMenu;
    procedure LoadSampleProjects(const Path: string; parent: TMenuItem);
    procedure LoadRecent(Sender: TObject);
    procedure AddMRU(const FileName: string);
    procedure SaveMemo;
    procedure LoadMemo;
    function DoSave: TModalResult;
    procedure Load(AFileName: string);
    procedure OnIdle(Sender: TObject; var Done: Boolean);
    procedure StartPlayer;
    function GetUniqueFile(const Base, Ext: string): Integer;
    procedure AddSource;
    function FindFile(const FileName: string): string;
   {$IFDEF DEBUGER}
    procedure WMUser(var Msg: TMessage); message WM_USER;
   {$ENDIF}
    procedure WMVersion(var Msg: TMessage); message WM_USER + 1;
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
  public
    { Déclarations publiques }
    function GetSource(const AFileName: string): TSourceProvider;
  end;

var
  MainForm: TMainForm;

implementation

uses FlashPascal, About, Compiler, Debug, HTML, InfoBulles, Options,
  NewProject, Global;

{$R *.dfm}
{$R lib\WinXP.RES}

const
  sPlayerNotFound = 'FlashPlayer.exe introuvable dans le répertoire de FlashPascal';
  sSaveFile       = 'Voulez-vous enregistrer "%s" ?';
  sFlashPath      = 'Veuillez indiquer l''emplacement du Player Flash';


function NewUID: string;
var
  Id: TGUID;
begin
  CreateGuid(Id);
  Result := GUIDToString(Id);
end;

function EnumWindowsProc(HWnd: THandle; Sender: TMainForm): BOOL; stdcall;
var
  PID: THandle;
begin
  GetWindowThreadProcessId(HWnd, PID);
  if PID = Sender.FRunning then
  begin
    Sender.FWindow := HWnd;
    Result := False;
  end else begin
    Result := True;
  end;
end;

procedure TMainForm.mnuOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    Load(OpenDialog.FileName);
    if mnuAutoRefresh.Checked and SWFForm.Visible then
      mnuCompileClick(mnuRun);
  end;
end;

procedure TMainForm.mnuSaveClick(Sender: TObject);
begin
  if FFileName = '' then
  begin
    if SaveDialog.Execute then
      FFileName := SaveDialog.FileName;
  end;
  if FFileName <> '' then
  begin
    SynEdit1.Lines.SaveToFile(FFileName);
    SynEdit1.Modified := False;
    FModified := False;
    SynEdit1Change(Self);
    //btSave.Enabled := False;
    //mnuSave.Enabled := False;
  end;
end;

procedure TMainForm.mnuCompileClick(Sender: TObject);
begin
  if FFileName <> '' then
  begin
    try
      Warnings.Clear;
      lbWarnings.Hide;
      Splitter.Hide;
      CompileFile(FFileName, SynEdit1.Lines, TComponent(Sender).Tag = 1, Sender = mnuDebug, mnuObfusc.checked);
      if TComponent(Sender).Tag = 1 then
      begin
        FTarget := ChangeFileExt(FFileName, '.swf');
        StartPlayer;
      end;
    except
      on e: CompilerException do
      begin
        Load(e.FileName);
        SynEdit1.CaretY := e.Row;
        SynEdit1.CaretX := e.Col;
        lbError.Caption := {$IFNDEF RELEASE}'(' + e.Num + ') ' +{$ENDIF} e.Message;
        lbError.Show;
      end;
    end;
  end;
  lbWarnings.Count := Warnings.Count;
  lbWarnings.Visible := Warnings.Count > 0;
  Splitter.Visible := Warnings.Count > 0;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  a,b,c,d : Word;
  MRU  : string;
  MRU2 : string;
  mnu  : TMenuItem;
  Index: Integer;
  Name : string;
begin
  if GetVersion(a, b, c, d) then
  begin
    Caption := Caption + Format( ' (%0.2d.%0.2d.%0.2d)', [b, c, d]);
  {$IFDEF RELEASE}
    FChecker := TVersionCheck.Create(Handle, WM_USER + 1, Format('%0.2x%0.2x%0.2x%0.2x', [a, b, c, d]));
  {$ENDIF}
  end;
  Application.Title := Caption;

  DragAcceptFiles(Handle, True);


  Warnings := TWarnings.Create;
{$IFNDEF DEBUGER}
  mnuDebug.Visible := False;
  mmMsg.Hide;
{$ENDIF}

  FIni := TIniFile.Create(IniPath + 'FlashPascal2.ini');

  NoOptimize := FIni.ReadInteger('FlashPascal2', 'NoOptimize', 0) = 1;

  LibPath := DataPath;//ExtractFilePath(Application.ExeName); // default LibPath is this compiler's path + 'units'
  if DirectoryExists(LibPath + 'units') then
  begin
    LibPath := LibPath + 'units\';
  end else
  if DirectoryExists(LibPath + '..\units') then
  begin
    LibPath := ExtractFilePath(ExcludeTrailingPathDelimiter(LibPath)) + 'units\';
  end;
  DecimalSeparator := '.';

  mnu := nil;
  // Projets récents
  MRU := FIni.ReadString('Projects', 'MRU', '');
  MRU2 := '';
  for Index := 1 to Length(MRU) do
  begin
    Name := FIni.ReadString('Projects', MRU[Index], '');
    if (Name <> '') and (FileExists(Name)) and (Length(MRU2) < 5) then
    begin
      mnu := TMenuItem.Create(Self);
      mnu.Caption := Name;
      mnu.Hint := Name;
      mnu.OnClick := LoadRecent;
      mnu.Tag := 1;
      mnuRecent.Add(mnu);
      MRU2 := MRU2 + MRU[Index];
      Inc(FFPRCount);
    end else begin
      FIni.DeleteKey('Projects', MRU[Index]);
    end;
  end;
  if MRU2 <> MRU then
    FIni.WriteString('Projects', 'MRU', MRU2);

  // Sources Pascal récents
  MRU := FIni.ReadString('Recent', 'MRU', '');
  MRU2 := '';
  for Index := 1 to Length(MRU) do
  begin
    Name := FIni.ReadString('Recent', MRU[Index], '');
    if (Name <> '') and (FileExists(Name)) then
    begin
      if UpperCase(ExtractFileExt(Name)) = '.FPR' then
      begin
      // patch pour faire passer les anciens FPR dans la section Projets
        AddMRU(Name);
        FIni.DeleteKey('Recent', MRU[Index]);
      end else begin
        if (mnu <> nil) and (mnu.Tag = 1) and (Length(MRU2) < 10) then
        begin
          mnu := TMenuItem.Create(Self);
          mnu.Caption := '-';
          mnuRecent.Add(mnu);
        end;
        mnu := TMenuItem.Create(Self);
        mnu.Caption := Name;
        mnu.Hint := Name;
        mnu.OnClick := LoadRecent;
        mnu.Tag := 2;
        mnuRecent.Add(mnu);
        MRU2 := MRU2 + MRU[Index];
        Inc(FPASCount);
      end;
    end else begin
      FIni.DeleteKey('Recent', MRU[Index]);
    end;
  end;
  if MRU2 <> MRU then
    FIni.WriteString('Recent', 'MRU', MRU2);
  mnuRecent.Enabled := mnuRecent.Count > 0;

  LoadSamplesMenu;

 {$IFDEF DEBUGER}
  FDebugger := TDebugger.Create;
 {$ENDIF}
  FSources := TStringList.Create;
  if ParamCount = 1 then
    Load(ParamStr(1))
  else
    if FFPRCount > 0 then
      mnuRecent.Items[0].Click
    else
      SetUI(False);
  Application.OnIdle := OnIdle;

  FPlayer := FIni.ReadString('Player', 'Path', '');
  if (FPlayer <> '') and (FileExists(FPlayer) = False) then
    FPlayer := '';
  if FPlayer <> '' then
    mnuUsePlayer.Checked := FIni.ReadInteger('Player', 'Extern', 0) = 1;
  mnuAutoRefresh.Checked := FIni.ReadInteger('Player', 'Refresh', 0) = 1;

  (*
  Path := FIni.ReadString('FlashPascal2', 'UID', '');
  if Path = '' then
  begin
    Path := NewUID;
    FIni.WriteString('FlashPascal2', 'UID', Path);
  end;
  *)
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Index : Integer;
  Source: TSourceFile;
begin
  SaveMemo;
  for Index := 0 to FSources.Count - 1 do
  begin
    Source := FSources.Objects[Index] as TSourceFile;
    if Source.Modified then
    begin
      FFileName := ExpandFileName(FSources[Index]);
      FSource := Source;
      LoadMemo;
      if DoSave = mrCancel then
      begin
        CanClose := False;
        Exit;
      end;
    end;
  end;

  if FProcess <> 0 then
    TerminateProcess(FProcess, 0);
end;

function TMainForm.DoSave: TModalResult;
begin
  Result := MessageDlg(Format(sSaveFile, [FFileName]), mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if Result = mrYes then
    mnuSave.Click;
end;

procedure TMainForm.SynEdit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Opt: TFindOptions;
  Str: string;
begin
  lbError.Hide;
  if (ssCtrl in Shift) then
  begin
    case Key of
      Ord('B'):
      begin
        SynEdit1.SelText := 'begin'#13#10'  '#13#10'end;';
        SynEdit1.SelStart := SynEdit1.SelStart - 5;
      end;
      Ord('F'): mnuSearch.Click;
      Ord('I'):
      begin
        SynEdit1.SelText := 'if  then';
        SynEdit1.SelStart := SynEdit1.SelStart - 5;
      end;
      Ord('N'): btNew.Click;
      Ord('W'):
      begin
        SynEdit1.SelText := 'while  do';
        SynEdit1.SelStart := SynEdit1.SelStart - 3;
      end;
      VK_RETURN:
      begin
        Str := FindFile(SynEdit1.WordAtCursor + '.pas');
        if Str <> '' then
          Load(Str);
      end;
    end;
  end else
  if Key = VK_F3 then
  begin
    Opt := FindDialog1.Options;
    if ssShift in Shift then
    begin
      if frDown in Opt then
        FindDialog1.Options := Opt - [frDown]
      else
        FindDialog1.Options := Opt + [frDown];
    end;
    FindDialog1Find(Self);
    FindDialog1.Options := Opt;
  end;
end;

procedure TMainForm.SaveMemo;
begin
  if FSource <> nil then
  begin
    FSource.Modified := SynEdit1.Modified;
    FSource.FileSource := SynEdit1.Lines.Text;
    FSource.SelStart := SynEdit1.SelStart;
    FSource.SelEnd := SynEdit1.SelEnd;
    FSource.TopLine := SynEdit1.TopLine;
    FSource.LeftChar := SynEdit1.LeftChar;
  end;
end;

procedure TMainForm.LoadMemo;
begin
  SynEdit1.Lines.Text := FSource.FileSource;
  SynEdit1.Modified := FSource.Modified;
  SynEdit1.SelStart := FSource.SelStart;
  SynEdit1.SelEnd := FSource.SelEnd;
  SynEdit1.TopLine := FSource.TopLine;
  SynEdit1.LeftChar := FSource.LeftChar;
  TabControl.TabIndex := FSource.TabIndex;
  SynEdit1Change(Self);
  //btSave.Enabled := FSource.Modified;
  //mnuSave.Enabled := FSource.Modified;
  Caption := Application.Title + ' [' + (FFileName) + ']';
end;

procedure TMainForm.Load(AFileName: string);
var
  Index : Integer;
begin
  SaveMemo;
  AFileName := ExpandFileName(AFileName);
  Index := FSources.IndexOf(AFileName);
  if Index >= 0 then
  begin
    if Index = TabControl.TabIndex then
      Exit;
    FFileName := AFileName;
    OpenDialog.InitialDir := ExtractFilePath(AFileName);
    SaveDialog.InitialDir := OpenDialog.InitialDir;
    FSource := FSources.Objects[Index] as TSourceFile;
    LoadMemo;
    Exit;
  end;

  FFileName := ChangeFileExt(Application.ExeName, '.pas');
  Caption := Application.Title;
  if AFileName <> '' then
  begin
    try
      SynEdit1.Lines.LoadFromFile(AFileName);
      FFileName := AFileName;
      AddSource;
      //FSource := TSourceFile.Create;
      //FSources.AddObject(AFileName, FSource);
      //FSource.TabIndex := TabControl.Tabs.Add(ExtractFileName(FFileName));
      //TabControl.TabIndex := FSource.TabIndex;
      //Caption := Application.Title + ' [' + (FFileName) + ']';
      OpenDialog.InitialDir := ExtractFilePath(FFileName);
      SaveDialog.InitialDir := OpenDialog.InitialDir;

      AddMRU(FFileName);
      SynEdit1Change(Self);
      //btSave.Enabled := False;
      //mnuSave.Enabled := False;
    except
      FFileName := '';
      raise;
    end;
  end;
end;

procedure TMainForm.TabControlChange(Sender: TObject);
begin
  lbError.Hide;
  if FSource <> nil then
  begin
    if TabControl.TabIndex = FSource.TabIndex then
      Exit;
    SaveMemo;
  end;
  FFileName := FSources[TabControl.TabIndex];
  FSource := FSources.Objects[TabControl.TabIndex] as TSourceFile;
  LoadMemo;
end;

function TMainForm.GetSource(const AFileName: string): TSourceProvider;
var
  Index: Integer;
  Source: TSourceFile;
begin
  Index := FSources.IndexOf(AFileName);
  if Index < 0 then
    Result := nil
  else begin
    if Index = TabControl.TabIndex then
      Result := TStringsProvider.Create(AFileName, SynEdit1.Lines)
    else begin
      Source := FSources.Objects[Index] as TSourceFile;
      Result := TStringProvider.Create(AFileName, Source.FileSource);
    end;
  end;
end;

procedure TMainForm.mnuAboutClick(Sender: TObject);
begin
  with TAboutBox.Create(Self) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TMainForm.mnuQuitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.OnIdle(Sender: TObject; var Done: Boolean);
begin
  if mnuAutoRefresh.Checked and SynEdit1.Modified then
  begin
    try
      CompileFile(FFileName, SynEdit1.Lines, True, False, False);
    except
      on e: CompilerException do
      begin
      //  Load(e.FileName);
      //  SynEdit1.CaretY := e.Row;
      //  SynEdit1.CaretX := e.Col;
        lbError.Caption := e.Message;
        lbError.Show;
        Exit;
      end;
      on e: Exception do
        Exit;
    end;
    FModified := True;
    SynEdit1.Modified := False;
    StartPlayer;
  end;
end;

procedure TMainForm.StartPlayer;
var
  Back  : Boolean;
  Rect  : TRect;
  SI    : TStartupInfo;
  PI    : TProcessInformation;
begin
  if mnuUsePlayer.Checked then
  begin
    if FileExists(FPlayer) then
    begin
      //Flash  := '"' + ChangeFileExt(FFileName,'.SWF') + '"';
      //ShellExecute(0,nil, PChar('"'+ ExtractFilePath(ParamStr(0)) + 'FlashPlayer.exe"'),PChar('"'+ChangeFileExt(FFileName,'.SWF')+'"'),nil,SW_SHOW);
      FillChar(SI, SizeOf(SI), 0);
      SI.cb := SizeOf(SI);
      if FWindow <> 0 then
      begin
        GetWindowRect(FWindow, Rect);
        SI.dwX := Rect.Left;
        SI.dwY := Rect.Top;
        SI.dwXSize := Rect.Right - Rect.Left;
        SI.dwYSize := Rect.Bottom - Rect.Top;
        SI.wShowWindow := SW_SHOWNA;
        SI.dwFlags := STARTF_USEPOSITION or STARTF_USESIZE or STARTF_USESHOWWINDOW;
      end;
      if FProcess <> 0 then
      begin
        TerminateProcess(FProcess, 0);
        FRunning := 0;
        FProcess := 0;
        FWindow := 0;
      end;
      FillChar(PI, SizeOf(PI), 0);
      CreateProcess(nil, PChar(FPlayer + ' ' + FTarget), nil, nil, False, 0, nil, nil, SI, PI);
      FRunning := PI.dwProcessId;
      FProcess := PI.hProcess;
      EnumWindows(@EnumWindowsProc, Integer(Self));
      Exit;
    end;
    ShowMessage(sPlayerNotFound);
    mnuUsePlayer.Checked := False;
  end;

  SWFForm.Play(FTarget);
  Back := SWFForm.Visible;
  SWFForm.Show; // il est nécessaire de donner le focus au player
  if Back then
    SetFocus;
end;


procedure TMainForm.FindDialog1Find(Sender: TObject);
var
  Opt: TSynSearchOptions;
begin
  Opt := [];
  if frWholeWord in FindDialog1.Options then
    Include(Opt, ssoWholeWord);
  if frMatchCase in FindDialog1.Options then
    Include(Opt, ssoMatchCase);
  if not (frDown in FindDialog1.Options) then
    Include(Opt, ssoBackwards);
  if SynEdit1.SearchReplace(FindDialog1.FindText, '', Opt) = 0 then
    ShowMessage(FindDialog1.FindText + ' not found');
end;

procedure TMainForm.LoadSamplesMenu;
var
  Path  : string;
  Search: TSearchRec;
  menu  : TMenuItem;
begin
  Path := DataPath;
  if DirectoryExists(Path + 'Exemples') then
    Path := Path + 'Exemples\'
  else begin
    if DirectoryExists(Path + '..\Exemples') then
      Path := ExtractFilePath(ExcludeTrailingPathDelimiter(Path)) + 'Exemples\';
  end;
  if FindFirst(Path + '*.', faDirectory, Search) = 0 then
  begin
    repeat
      if Search.Name[1] <> '.' then
      begin
        menu := TMenuItem.Create(Self);
        menu.Caption := Search.Name;
        LoadSampleProjects(Path + Search.Name + '\', menu);
        mnuSamples.Add(menu);
      end;
    until FindNext(Search) <> 0;
    FindClose(Search);
  end;

  LoadSampleProjects(Path, mnuSamples);
end;

procedure TMainForm.LoadSampleProjects(const Path: string; parent: TMenuItem);
var
  Search: TSearchRec;
  menu  : TMenuItem;
begin
  if FindFirst(Path + '*.fpr', faAnyFile, Search) = 0 then
  begin
    repeat
      menu := TMenuItem.Create(Self);
      menu.Caption := Search.Name;
      menu.Hint := Path + Search.Name;
      menu.OnClick := LoadRecent;
      parent.Add(menu);
    until FindNext(Search) <> 0;
    FindClose(Search);
  end;
  parent.Visible := parent.Count > 0;
end;

procedure TMainForm.LoadRecent(Sender: TObject);
begin
  Load(TMenuItem(Sender).Hint);
end;

procedure TMainForm.AddMRU(const FileName: string);
var
  Section: string;
  max    : Integer;
  top    : Integer;
  mru    : string;
  Index  : Integer;
  Let    : Char;
  mnu    : TMenuItem;

begin
  mnuRecent.Enabled := True;

  if UpperCase(ExtractFileExt(FileName)) = '.FPR' then
  begin
    Section := 'Projects';
    top := 0;
    max := 5;
  end else begin
    Section := 'Recent';
    top := FFPRCount;
    if top > 0 then
    begin
      if FPASCount = 0 then
      begin
        mnu := TMenuItem.Create(Self);
        mnu.Caption := '-';
        mnuRecent.Add(mnu);
      end;
      Inc(top);
    end;
    max := 10;
  end;

  mru   := FIni.ReadString(Section, 'MRU', '');
  mnu   := mnuRecent.Find(FileName) as TMenuItem;
  Index := mnuRecent.IndexOf(mnu);
  if (mnu = nil) and (Length(mru) = max) then
  begin
    Index := top + max - 1;
    mnu := mnuRecent.Items[Index] as TMenuItem;
    mnu.Caption := FileName;
  end;
  if (mnu <> nil) then
  begin
    if Index = top then
      Exit;
    mnuRecent.Remove(mnu);
    mnuRecent.Insert(top, mnu);
    Dec(Index, top);
    Let := mru[Index + 1];
    Delete(mru, Index + 1, 1);
  end else begin
    if Length(mru) = max then
    begin
      Let := mru[max];
      SetLength(mru, max - 1);
      mnu := mnuRecent.Items[top + max - 1] as TMenuItem;
      mnuRecent.Remove(mnu);
    end else begin
      Let := 'a';
      while Pos(Let, MRU) > 0 do
        Inc(Let);
      mnu := TMenuItem.Create(Self);
      mnu.OnClick := LoadRecent;
    end;
    mnu.Caption := FileName;
    mnuRecent.Insert(top, mnu);
    if top > 0 then
      Inc(FPASCount)
    else begin
      if FFPRCount = 0 then
      begin
        mnu := TMenuItem.Create(Self);
        mnu.Caption := '-';
        mnuRecent.Insert(1, mnu);
      end;
      Inc(FFPRCount);
    end;
  end;
  FIni.WriteString(Section, Let, FileName);
  FIni.WriteString(Section, 'MRU', Let + mru);
end;

{$IFDEF DEBUGER}
procedure TMainForm.WMUser(var Msg: TMessage);
var
  Client: TClient;
begin
  case Msg.wParam of
    1 :
    begin
      mmMsg.Lines.Add('Nouveau client');
      Client := TClient(Msg.lParam);
      Client.Form := TDebugForm.Create(Self);
    end;
    2 :
    begin
      Client := TClient(Msg.lParam);
      case Client.Msg.ID of
       $00 : mmMsg.Lines.add('Menu flags');
       $03 : Client.Form.CreateAnonymousObject(Client.GetID);
       $04 : Client.Form.RemoveObject(Client.GetID);
       $0C : with Client.GetAttr do mmMsg.Lines.Add(Name + ' = ' + Value);
       $0D : with Client.GetPlace do Client.Form.PlaceObject(ID, Path);
       $0F : mmMsg.Lines.Add('Ask breakpoints');
       $18 : mmMsg.Lines.Add('getUrl error ' + Client.GetString($18));
       $19 : mmMsg.Lines.Add('ProcessTag');
  $0A, $1C : with Client.GetField do Client.Form.GetObject(ID).SetField(Name, Value);
       $1A : with Client.GetVersion^ do mmMsg.Lines.Add('Version ' + IntToStr(majorVersion));
      else  mmMsg.Lines.add('$' + IntToHex(Client.Msg.ID, 2) + ' ' + IntToStr(Client.Msg.Len) + ' bytes');
      end;
    end;
    //99: mmMsg.Lines.Add('Erreur : ' + TThread(Msg.lParam).Msg);
    else
      mmMsg.Lines.Add('Message ' + IntToStr(Msg.wParam));
  end;
end;
{$ENDIF}

procedure TMainForm.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
{$IFDEF DEBUGER}
  FDebugger.Free;
{$ENDIF}
  Warnings.Free;
  //FChecker.Free;
  FLogo.Free;
  FIni.Free;
  for i := 0 to FSources.Count - 1 do
    FSources.Objects[i].Free;
  FSources.Free;
end;

procedure TMainForm.SynEdit1ContextHelp(Sender: TObject; word: String);
begin
//  HelpForm.ShowPage(Word);
end;

procedure TMainForm.SynEdit1CommandProcessed(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: Char; Data: Pointer);
begin
  if Command = ecPaste then // Corrige un bug d'affichage sur le copier/coller
    SynEdit1.Invalidate;
end;

procedure TMainForm.mnuHTMLClick(Sender: TObject);
begin
  if FTarget <> '' then
    HTMLForm.Show(FTarget);
end;

procedure TMainForm.mnuCloseClick(Sender: TObject);
var
  i, j: Integer;
begin
  if FSource <> nil then
  begin
    if FSource.Modified then
    begin
      if DoSave = mrCancel then
        Exit;
    end;
    i := TabControl.TabIndex;
    for j := i + 1 to FSources.Count - 1 do
      Dec(TSourceFile(FSources.Objects[j]).TabIndex);
    FSources.Delete(i);
    FreeAndNil(FSource);
    TabControl.Tabs.Delete(i);
    if TabControl.Tabs.Count = 0 then
    begin
      TabControl.Hide;
      SetUI(False);
      Caption := Application.Title;
    end else begin
      if i >= TabControl.Tabs.Count then
        i := TabControl.Tabs.Count - 1;
      TabControl.TabIndex := i;
      TabControlChange(Self);
    end;
  end;
end;

function TMainForm.GetUniqueFile(const Base, Ext: string): Integer;
var
  s: string;
begin
  if FFileName = '' then
    FFileName := Application.ExeName;
  FFileName := ExtractFilePath(FFileName) + Base;
  Result := 1;
  s := FFileName + IntToStr(Result) + Ext;
  while (FSources.IndexOf(s) > 0) or FileExists(s) do
  begin
    Inc(Result);
    s := FFileName + IntToStr(Result) + Ext;
  end;
  FFileName := s;
end;

procedure TMainForm.AddSource;
begin
  FSource := TSourceFile.Create;
  FSources.AddObject(FFileName, FSource);
  FSource.TabIndex := TabControl.Tabs.Add(ExtractFileName(FFileName));
  TabControl.TabIndex := FSource.TabIndex;
  Caption := Application.Title + ' [' + (FFileName) + ']';
  TabControl.Visible := True;
  SetUI(True);
  ActiveControl := SynEdit1;
  lbError.Hide;
end;

procedure TMainForm.mnuNewFPRClick(Sender: TObject);
var
  n: Integer;
begin
  SaveMemo;
  with TProjectForm.Create(Self) do
  begin
    if ShowModal = mrOK then
    begin
      n := GetUniqueFile('Project', '.fpr');

      SynEdit1.Text := 'program Project' + IntToStr(n) + ';'#13#10
                     + #13#10
                     + '{$FRAME_WIDTH ' + edWidth.Text + '}'#13#10
                     + '{$FRAME_HEIGHT ' + edHeight.Text + '}'#13#10
                     + '{$FRAME_RATE ' + edFrameRate.Text + '}'#13#10
                     + '{$BACKGROUND $' + edColor.Text + '}'#13#10
                     + #13#10
                     + 'uses'#13#10
                     + '  Flash8;'#13#10
                     + #13#10
                     + 'begin'#13#10
                     + '  '#13#10
                     + 'end.';
      SynEdit1.SelStart := 133;
      SynEdit1.Modified := True;

      AddSource;
    end;
    Free;
  end;
end;

procedure TMainForm.mnuNewPASClick(Sender: TObject);
var
  n: Integer;
begin
  SaveMemo;
  n := GetUniqueFile('Unit', '.pas');

  SynEdit1.Text := 'unit Unit' + IntToStr(n) + ';'#13#10
                 + #13#10
                 + 'interface'#13#10
                 + #13#10
                 + #13#10
                 + #13#10
                 + 'implementation'#13#10
                 + '  '#13#10
                 + 'end.';
  SynEdit1.SelStart := 28;
  SynEdit1.Modified := True;

  AddSource;
  SynEdit1Change(Self);
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  if TabControl.Visible = False then
  begin
    FLogo := TIcon.Create;
    FLogo.Handle := LoadImage(hInstance, 'MAINICON', IMAGE_ICON, 128, 128, 0);
    with Canvas do
      Draw(ClientWidth div 2 - 64, ClientHeight div 2 - 64, FLogo);
  end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if TabControl.Visible = False then
    Invalidate;
end;

procedure TMainForm.btNewClick(Sender: TObject);
begin
  if TabControl.Visible then
    mnuNewPAS.Click
  else
    mnuNewFPR.Click;
end;

procedure TMainForm.mnuCutClick(Sender: TObject);
begin
  SynEdit1.CutToClipboard;
end;

procedure TMainForm.mnuCopyClick(Sender: TObject);
begin
  SynEdit1.CopyToClipboard;
end;

procedure TMainForm.mnuPasteClick(Sender: TObject);
begin
  SynEdit1.PasteFromClipboard;
end;

procedure TMainForm.mnuSearchClick(Sender: TObject);
begin
  if (SynEdit1.SelLength > 0) and (SynEdit1.SelLength < 20) then
    FindDialog1.FindText := SynEdit1.SelText;
  FindDialog1.Execute;
end;

procedure TMainForm.mnuUsePlayerClick(Sender: TObject);
begin
  if mnuUsePlayer.Checked then
  begin
    if FPlayer = '' then
    begin
      ShowMessage(sFlashPath);
      mnuOptions.Click;
      if FPlayer = '' then
      begin
        mnuUsePlayer.Checked := False;
        Exit;
      end;
    end;
  end;
end;

procedure TMainForm.WMVersion(var Msg: TMessage);
var
  Info: TInfoBulle;
begin
  if FChecker.Version <> '' then
  begin
    Info := TInfoBulle.Create(Self);
    Info.Say('FlashPascal 2 Information', FChecker.Version, 20000, nil)
  end;
  FreeAndNil(FChecker);
end;

procedure TMainForm.SetUI(Enabled: Boolean);
begin
  btSave.Enabled := Enabled;
  btUndo.Enabled := Enabled;
  btRedo.Enabled := Enabled;
  btRun.Enabled := Enabled;
  mnuSave.Enabled := Enabled;
  mnuClose.Enabled := Enabled;
  mnuCut.Enabled := Enabled;
  mnuCopy.Enabled := Enabled;
  mnuPaste.Enabled := Enabled;
  mnuSearch.Enabled := Enabled;
  mnuHTML.Enabled := Enabled;
  mnuCompile.Enabled := Enabled;
  mnuRun.Enabled := Enabled;
end;

procedure TMainForm.mnuOptionsClick(Sender: TObject);
begin
  with TOptionsForm.Create(Self) do
  begin
    edPlayer.Text := FPlayer;
    cbUserPlayer.Checked := FIni.ReadInteger('Player', 'Extern', 0) = 1;
    cbAutoRefresh.Checked := FIni.ReadInteger('Player', 'Refresh', 0) = 1;
    if ShowModal = mrOK then
    begin
      FPlayer := edPlayer.Text;
      FIni.WriteString('Player','Path', FPlayer);
      FIni.WriteInteger('Player', 'Extern', Ord(cbUserPlayer.Checked));
      FIni.WriteInteger('Player', 'Refresh', Ord(cbAutoRefresh.Checked));
      if NoOptimize <> cbNoOptimize.Checked then
      begin
        NoOptimize := not NoOptimize;
        FIni.WriteInteger('FlashPascal2', 'NoOptimize', Ord(NoOptimize));
      end;
    end;
  end;
end;

procedure TMainForm.WMDropFiles(var Msg: TMessage);
var
  Count: Integer;
  Name : PChar;
  Size : Integer;
begin
  Count := DragQueryFile(Msg.wParam,$FFFFFFFF,nil,0);
  while Count > 0 do
  begin
    Dec(Count);
    Size := DragQueryFile(Msg.wParam, Count, nil, 0) + 1;
    GetMem(Name, Size);
    try
      DragQueryFile(Msg.wParam, Count, Name, Size);
      Load(Name);
    finally
      FreeMem(Name, Size);
    end;
  end;
end;

procedure TMainForm.mnuSaveAsClick(Sender: TObject);
var
  Index: Integer;
begin
  SaveDialog.InitialDir := ExtractFilePath(FFileName);
  SaveDialog.FileName := FFileName;
  if SaveDialog.Execute then
  begin
    if SaveDialog.FileName <> FFileName then
    begin
      Index := FSources.IndexOf(FFileName);
      FFileName := SaveDialog.FileName;
      FSources[Index] := FFileName;
      TabControl.Tabs[FSource.TabIndex] := ExtractFileName(FFileName);
      Caption := Application.Title + ' [' + (FFileName) + ']';
      AddMRU(FFileName);
    end;
    mnuSaveClick(Self);
  end;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('N')) then
    btNew.Click;
end;

procedure TMainForm.SynEdit1Change(Sender: TObject);
begin
  mnuSave.Enabled := SynEdit1.Modified;
  btSave.Enabled := SynEdit1.Modified;
  mnuUndo.Enabled := SynEdit1.UndoList.CanUndo;
  mnuRedo.Enabled := SynEdit1.RedoList.CanUndo;
  btUndo.Enabled := mnuUndo.Enabled;
  btRedo.Enabled := mnuRedo.Enabled;
end;

function TMainForm.FindFile(const FileName: string): string;
begin
  Result := ExtractFilePath(FFileName) + FileName;
  if not FileExists(Result) then
  begin
    Result := LibPath + FileName;
    if not FileExists(Result) then
      Result := '';
  end;
end;

procedure TMainForm.mnuUndoClick(Sender: TObject);
begin
  SynEdit1.Undo;
end;

procedure TMainForm.mnuRedoClick(Sender: TObject);
begin
  SynEdit1.Redo;
end;

procedure TMainForm.Forumweb1Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://www.developpez.net/forums/f1723/autres-langages/pascal/flash-pascal/', nil, nil, SW_SHOW);
end;

procedure TMainForm.Siteweb1Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://flashpascal.execute.re', nil, nil, SW_SHOW);
end;

procedure TMainForm.lbWarningsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
  with lbWarnings.Canvas do
  begin
    with Warnings[Index] do
    TextRect(Rect, Rect.Left, Rect.Top, Format('%s (%d) %s', [FileName, Row, Message]));
  end;
end;

procedure TMainForm.lbWarningsClick(Sender: TObject);
var
  i: Integer;
begin
  i := lbWarnings.ItemIndex;
  if i < 0 then
    Exit;
  with Warnings[i] do
  begin
    Load(FileName);
    SynEdit1.CaretY := Row;
    SynEdit1.CaretX := Col;
    SynEdit1.SetFocus;
  end;
end;

end.
