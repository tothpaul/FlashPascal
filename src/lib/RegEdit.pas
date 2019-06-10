unit RegEdit;

interface

uses
  Windows, Classes;

function ReadRegString(Key: HKEY; const Path, Value, Default: string): string;
function WriteRegString(Key: HKEY; const Path, Value,Data: string): Boolean;
function DeleteRegString(Key: HKEY; const Path, Value:string): Boolean;
function WriteRegDWord(Key: HKEY; const Path, Value: string; Data: DWord): Boolean;
//function DeleteRegDouble(Key: HKEY; const Path, Value: string): Boolean;
function GetRegKeys(Key: HKEY; const Path: string; Keys: TStrings): boolean;

procedure SetFileType(const Extension, Description, Application: string);
function IsFileType(const Extension, Application: string): Boolean;
procedure UnsetFileType(const Extension, Description, Application: string);

implementation

function WriteRegString(Key: HKEY; const Path, Value,Data: string): Boolean;
var
  Handle: HKEY;
  Disposition: Integer;
begin
  Result := RegCreateKeyEx(Key, PChar(Path), 0, nil, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, nil, Handle, @Disposition) = ERROR_SUCCESS;
  if Result then
  begin
    Result := RegSetValueEx(Handle, PChar(Value), 0, REG_SZ, PChar(Data), Length(Data)) = ERROR_SUCCESS;
    RegCloseKey(Handle);
  end;
end;

function ReadRegString(Key: HKEY; const Path, Value, Default: string): string;
var
  Handle: HKEY;
  RegType: Integer;
  DataSize: Integer;
begin
  Result := Default;
  if RegOpenKeyEx(Key, PChar(Path), 0, KEY_ALL_ACCESS, Handle) = ERROR_SUCCESS then
  begin
    if RegQueryValueEx(Handle, PChar(Value), nil, @RegType, nil, @DataSize)=ERROR_SUCCESS then
    begin
      SetLength(Result, Datasize);
      RegQueryValueEx(Handle, PChar(Value), nil, @RegType, PByte(PChar(Result)), @DataSize);
      if Result[DataSize] = #0 then
        SetLength(Result, Datasize - 1);
    end;
    RegCloseKey(Handle);
  end;
end;

function DeleteRegString(Key: HKEY; const Path, Value:string): Boolean;
var
  Handle: HKEY;
begin
  Result := RegOpenKeyEx(Key, PChar(Path), 0, KEY_ALL_ACCESS, Handle) = ERROR_SUCCESS;
  if Result then
  begin
    Result:= RegDeleteValue(Handle, PChar(Value)) = ERROR_SUCCESS;
    RegCloseKey(Handle);
  end;
end;

function WriteRegDWord(Key: HKEY; const Path, Value: string; Data: DWord): Boolean;
var
  Handle: HKEY;
  Disposition: Integer;
begin
  Result := RegCreateKeyEx(Key, PChar(Path), 0, nil, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, nil, Handle, @Disposition) = ERROR_SUCCESS;
  if Result then
  begin
    Result := RegSetValueEx(Handle, PChar(Value), 0, REG_DWORD, PChar(@Data), SizeOf(Data)) = ERROR_SUCCESS;
    RegCloseKey(Handle);
  end;
end;


function GetRegKeys(Key: HKEY; const Path: string; Keys: TStrings): boolean;
var
  Handle: HKEY;
  Count, Len: DWORD;
  Str: string;
  i: Integer;
begin
  Result := RegOpenKeyEx(Key, PChar(Path), 0, KEY_ALL_ACCESS, Handle) = ERROR_SUCCESS;
  if Result then
  begin
    try
      Result := RegQueryInfoKey(Handle, nil, nil, nil, @Count, @Len, nil, nil, nil, nil, nil, nil) = ERROR_SUCCESS;
      if Result then
      begin
        Inc(Len);
        SetLength(Str, Len);
        for i := 0 to Count - 1 do
        begin
          RegEnumKeyEx(Handle, I, PChar(Str), Len, nil, nil, nil, nil);
          Keys.Add(PChar(Str));
        end;
      end;
    finally
      RegCloseKey(Handle);
    end;
  end;
end;



procedure SetFileType(const Extension, Description, Application: string);
var
  ext: string;
  dsc: string;
  exe: string;
begin
  ext := '.' + Extension;
  dsc := ReadRegString(HKEY_CLASSES_ROOT, ext, '', '');
  if dsc = '' then
  begin
    dsc := Extension + 'Files';
    WriteRegString(HKEY_CLASSES_ROOT, ext, '', dsc);
    WriteRegString(HKEY_CLASSES_ROOT, dsc, '', Description);
  end;
  ext := ReadRegString(HKEY_CLASSES_ROOT, dsc + '\DefaultIcon', '', '');
  if ext = '' then
    WriteRegString(HKEY_CLASSES_ROOT, dsc + '\DefaultIcon', '', Application + ',0');
  exe := '"' + Application + '" "%1"';
  ext := ReadRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\Open\Command', '', '');
  if (ext = '') then
    WriteRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\Open\Command', '', exe)
  else
    if (ext <> exe) then
    begin
      WriteRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\ExecuteSARL', '' , Description);
      WriteRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\ExecuteSARL\Command', '', exe);
    end;
end;

function IsFileType(const Extension, Application: string): Boolean;
var
  ext: string;
  dsc: string;
  exe: string;
begin
  ext := '.' + Extension;
  dsc := ReadRegString(HKEY_CLASSES_ROOT, ext, '', '');
  if dsc = '' then
    dsc := Extension + 'Files';
  exe := '"' + Application + '" "%1"';
  Result := ReadRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\Open\Command', '', '') = exe;
  if not Result then
    Result := ReadRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\ExecuteSARL\Command', '', '') = exe;
end;

procedure UnsetFileType(const Extension, Description, Application: string);
var
  ext : string;
  dsc : string;
  exe : string;
begin
  ext := '.' + Extension;
  dsc := ReadRegString(HKEY_CLASSES_ROOT, ext, '', '');
  exe := '"' + Application + '" "%1"';
  if ReadRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\Open\Command', '',  '') = exe then
  begin
    RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc + '\Shell\Open\Command'));
    RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc + '\Shell\Open'));
    RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc + '\Shell'));
    RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc + '\DefaultIcon'));
    RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc));
    RegDeleteKey(HKEY_CLASSES_ROOT, PChar(ext));
  end else begin
    if ReadRegString(HKEY_CLASSES_ROOT, dsc + '\Shell\ExecuteSARL\Command', '', '') = exe then
    begin
      RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc + '\Shell\ExecuteSARL\Command'));
      RegDeleteKey(HKEY_CLASSES_ROOT, PChar(dsc + '\Shell\ExecuteSARL'));
    end;
  end;
end;

end.
