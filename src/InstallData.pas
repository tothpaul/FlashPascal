unit InstallData;

interface

uses
  Windows, SysUtils, SHFolder;

const
  WINKEY = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\ExecuteSARL.FlashPascal2';
  DisplayName = 'FlashPascal 2 - Execute SARL';

  LinkName = 'FlashPascal 2';
  Version  = '14.04.22';
  FileExt  = 'FPR';
  FileType = 'FlashPascal Project';

  AppPath  = 'FlashPascal2';

var
  ExecutePath: string; // = 'C:\Program Files (x86)\Execute SARL\';
  InstallPath: string; // = ExecutePath + 'FlashPascal2\';
  CommonPath : string; // = 'C:\Users\Public\Documents\FlashPascal2\'

function GetTempFileName(ext: string): string;
function GetSpecialFolderPath(folder : integer) : string;

implementation

function GetTempDir: string;
begin
  SetLength(Result, MAX_PATH);
  GetTempPath(MAX_PATH, @Result[1]);
end;

function GetTempFileName(ext: string): string;
var
  tmp: string;
begin
  tmp := GetTempDir;
  SetLength(Result, MAX_PATH);
  Windows.GetTempFileName(PChar(tmp), '974', 0, @Result[1]);
  Result := PChar(Result);
  DeleteFile(Result);
  Result := ChangeFileExt(Result, ext);
end;

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

initialization
  ExecutePath := GetSpecialFolderPath(CSIDL_PROGRAM_FILES) + '\Execute SARL\';
  InstallPath := ExecutePath + AppPath + '\';
  CommonPath  := GetSpecialFolderPath(CSIDL_COMMON_DOCUMENTS) + '\FlashPascal2';
end.
