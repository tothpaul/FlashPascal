unit Links;
{ Windows ShortCuts (C) 2001, by Paul TOTH <tothpaul@free.com>
  http://tothpaul.free.fr

 - 18 june 2001
  fix NT4 OLE32 error.
}

{
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}


interface

{$define noole}

uses
 sysutils;

Function CreateLink(Link,Pgm,Parm:string):boolean;

implementation

Uses
{$ifNdef noole}ActiveX,{$endif} Windows;

Type
{$ifdef noole}
 TUUID=record d1:integer; d2,d3:word; d4:array[0..7] of byte end;
{$else}
 TUUID=TGUID;
{$endif}

Const
 CLSID_ShellLink : TUUID = (D1:$00021401; D2:$0000; D3:$0000; D4:($C0,$00,$00,$00,$00,$00,$00,$46));
 IID_IShellLink  : TUUID = (D1:$000214EE; D2:$0000; D3:$0000; D4:($C0,$00,$00,$00,$00,$00,$00,$46));
 IID_IPersistFile: TUUID = (D1:$0000010B; D2:$0000; D3:$0000; D4:($C0,$00,$00,$00,$00,$00,$00,$46));

Type
{$ifdef noole}
 IUnknown=^PUnknown;
 PUnknown=^TUnknown;
 TUnknown=record
  QueryInterface:function(Self:pointer; Const ID:TUUID; Var Instance):integer; stdcall;
  AddRef        :function(Self:pointer):integer; stdcall;
  Release       :function(Self:pointer):integer; stdcall;
 end;

 IPersist=^PPersist;
 PPersist=^TPersist;
 TPersist=record
 // IUnknow
  Unknown:TUnknown;
 // IPersist
  GetClassID:function(var ID: TUUID):integer; stdcall;
 end;

 IPersistFile=^PPersistFile;
 PPersistFile=^TPersistFile;
 TPersistFile=record
 // IPersist
  Persist:TPersist;
 // IPersistFile
  IsDirty      :pointer;
  Load         :pointer;
  Save         :function(Self:pointer; FileName:PWideChar; Remember:boolean):integer; stdcall;
  SaveCompleted:pointer;
  GetCurFile   :pointer;
 end;

 IShellLink=^PShellLink;
 PShellLink=^TShellLink;
 TShellLink=record
 // IUnknow
  Unknown:TUnknown;
 // IShellLink
  GetPath                                 :pointer;
  GetIDList,SetIDList                     :pointer;
  GetDescription,SetDescription           :pointer;
  GetWorkingDirectory,SetWorkingDirectory :pointer;
  GetArguments                            :pointer;
  SetArguments                            :function(Self:pointer; Args:PChar):integer; stdcall;
  GetHotKey,SetHotKey                     :pointer;
  GetShowCmd,SetShowCmd                   :pointer;
  GetIconLocation,SetIconLocation         :pointer;
  SetRelativePath                         :pointer;
  Resolve                                 :pointer;
  SetPath                                 :function(Self:pointer; Path:PChar):integer; stdcall;
 end;

function CoCreateInstance(const clsid: TUUID; unkOuter,dwClsContext: Longint; const iid: TUUID; var pv): integer; stdcall; external 'ole32.dll' name 'CoCreateInstance';

Function CreateLink(Link,Pgm,Parm:string):boolean;
 var
  Lnk:IShellLink;
  PF :IPersistFile;
  WC :array[0..255] of WideChar;
 begin
  Result:=False;
  if CoCreateInstance(CLSID_ShellLink, 0, 1, IID_IShellLink, Lnk)=0 then begin
   Lnk^^.SetPath(lnk,pchar(Pgm));
   Lnk^^.SetArguments(lnk,pchar(Parm));
   if Lnk^^.Unknown.QueryInterface(lnk,IID_IPersistFile,PF)=0 then begin
    PF^^.Save(pf,StringToWideChar(Link,WC,SizeOf(WC) div 2),TRUE);
    PF^^.Persist.Unknown.Release(pf);
    Result:=True;
   end;
   Lnk^^.Unknown.Release(lnk);
  end;
 end;


{$else}
 IShellLink=Interface
  function GetPath(pszFile: PAnsiChar; cchMaxPath: Integer; var pfd: TWin32FindData; fFlags: DWORD): HResult; stdcall;
  function GetIDList(var ppidl: {PItemIDList}integer): HResult; stdcall;
  function SetIDList(pidl: {PItemIDList}integer): HResult; stdcall;
  function GetDescription(pszName: PAnsiChar; cchMaxName: Integer): HResult; stdcall;
  function SetDescription(pszName: PAnsiChar): HResult; stdcall;
  function GetWorkingDirectory(pszDir: PAnsiChar; cchMaxPath: Integer): HResult; stdcall;
  function SetWorkingDirectory(pszDir: PAnsiChar): HResult; stdcall;
  function GetArguments(pszArgs: PAnsiChar; cchMaxPath: Integer): HResult; stdcall;
  function SetArguments(pszArgs: PAnsiChar): HResult; stdcall;
  function GetHotkey(var pwHotkey: Word): HResult; stdcall;
  function SetHotkey(wHotkey: Word): HResult; stdcall;
  function GetShowCmd(piShowCmd: Integer): HResult; stdcall;
  function SetShowCmd(iShowCmd: Integer): HResult; stdcall;
  function GetIconLocation(pszIconPath: PAnsiChar; cchIconPath: Integer; piIcon: Integer): HResult; stdcall;
  function SetIconLocation(pszIconPath: PAnsiChar; iIcon: Integer): HResult; stdcall;
  function SetRelativePath(pszPathRel: PAnsiChar; dwReserved: DWORD): HResult; stdcall;
  function Resolve(Wnd: HWND; fFlags: DWORD): HResult; stdcall;
  function SetPath(pszFile: PAnsiChar): HResult; stdcall;
 end;

Function CreateLink(Link,Pgm,Parm:string):boolean;
 var
  Lnk:IShellLink;
  PF :IPersistFile;
  WC :array[0..255] of WideChar;
 begin
  Result:=False;
  if CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLink, Lnk)=0 then begin
   Lnk.SetPath(pchar(Pgm));
   Lnk.SetArguments(pchar(Parm));
   if Lnk.QueryInterface(IID_IPersistFile,PF)=0 then begin
    PF.Save(StringToWideChar(Link,WC,SizeOf(WC) div 2),TRUE);
    //PF.Release;
    Result:=True;
   end;
   //Lnk.Release;
  end;
 end;
{$endif}

{$ifdef noole}
function CoInitialize(pvReserved:integer):integer; stdcall; external 'ole32.dll';
procedure CoUninitialize; stdcall; external 'ole32.dll';

initialization
 CoInitialize(0);

finalization
 CoUninitialize;
{$endif}
end.
