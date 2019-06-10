program FlashPascal2;

{%File 'FlashPascal\FlashPascal.inc'}

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  FlashPascal in 'FlashPascal\FlashPascal.pas',
  Compiler in 'FlashPascal\Compiler.pas',
  Deflate in 'FlashPascal\Deflate.pas',
  Global in 'FlashPascal\Global.pas',
  Parser in 'FlashPascal\Parser.pas',
  Source in 'FlashPascal\Source.pas',
  SWF in 'FlashPascal\SWF.pas',
  About in 'About.pas' {AboutBox},
  Preview in 'Preview.pas' {SWFForm},
  Debugger in 'Debugger.pas',
  Debug in 'Debug.pas' {DebugForm},
  HTML in 'HTML.pas' {HTMLForm},
  RegEdit in 'lib\RegEdit.pas',
  InfoBulles in 'InfoBulles.pas' {InfoBulle},
  HTTP in 'HTTP.pas',
  Options in 'Options.pas' {OptionsForm},
  NewProject in 'NewProject.pas' {ProjectForm},
  FontBuilder in 'FontBuilder.pas',
  ShapeBuilder in 'ShapeBuilder.pas',
  Translates in 'Translates.pas';

{$R *.res}

begin
{$IFNDEF RELEASE}
 // FastMM4.RegisterExpectedMemoryLeak(36, 2); // THelpManager x 1, THTMLHelpViewer x 1
 // FastMM4.RegisterExpectedMemoryLeak(20, 7); // TObjectList x 3, THelpSelector x 1, Unknown x 3
 // FastMM4.RegisterExpectedMemoryLeak(52);    // TWinHelpViewer x 1
{$ENDIF}
  Application.Initialize;
  Application.Title := '';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSWFForm, SWFForm);
  Application.CreateForm(THTMLForm, HTMLForm);
  Application.CreateForm(TOptionsForm, OptionsForm);
  Application.Run;
end.
