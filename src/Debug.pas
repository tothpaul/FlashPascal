unit Debug;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls;

type
  TObjectNode = class(TTreeNode)
  public
    id    : Cardinal;
    procedure SetField(const Name, Value: string);
  end;

  TDebugForm = class(TForm)
    TreeView1: TTreeView;
  private
    { Déclarations privées }
    function FindNode(id: Cardinal): TObjectNode;
  public
    { Déclarations publiques }
    function CreateAnonymousObject(id: Cardinal): TObjectNode;
    procedure RemoveObject(id: Cardinal);
    function GetObject(id: Cardinal): TObjectNode;
    function PlaceObject(id: Cardinal; Path: string): TObjectNode;
  end;

var
  DebugForm: TDebugForm;

implementation

{$R *.dfm}

{ TDebugForm }

function TDebugForm.CreateAnonymousObject(id: Cardinal): TObjectNode;
begin
  Result := TObjectNode.Create(TreeView1.Items);
  Result.id := id;
  TreeView1.Items.AddNode(Result, nil, IntToStr(id), nil, naAdd);
end;

function TDebugForm.FindNode(id: Cardinal): TObjectNode;
var
  i: Integer;
begin
  for i := 0 to TreeView1.Items.Count - 1 do
  begin
    Result := TreeView1.Items[i] as TObjectNode;
    if Result.id = id then
      Exit;
  end;
  Result := nil;
end;

function TDebugForm.GetObject(id: Cardinal): TObjectNode;
begin
  Result := FindNode(id);
  if Result = nil then
  begin
//  raise Exception.Create('unknow object');
    Result := CreateAnonymousObject(id);
    Result.Text := Result.Text + ' ??';
  end;
end;

function TDebugForm.PlaceObject(id: Cardinal; Path: string): TObjectNode;
begin
  Result := GetObject(id);
  Result.Text := IntToStr(Result.id) + ' ' + Path;
end;

procedure TDebugForm.RemoveObject(id: Cardinal);
var
  node: TObjectNode;
begin
  node := FindNode(id);
  if node <> nil then
    node.Free;
end;

{ TObjectNode }

procedure TObjectNode.SetField(const Name, Value: string);
var
  Node: TObjectNode;
begin
  Node := TObjectNode.Create(Owner);
  Owner.AddNode(Node, Self, Name + '=' + Value, nil, naAddChild)
end;

end.


