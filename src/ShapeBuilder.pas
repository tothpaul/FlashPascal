unit ShapeBuilder;

interface

uses
  SysUtils;

type
  TShape = class
  private
    ox   : Integer;
    oy   : Integer;
    px   : Integer;
    py   : Integer;
    Code : string;
    bits : Integer;
    Count: Integer;
    procedure AddBit(Bit: Boolean);
    procedure AddBits(const Str: string);
  public
    procedure Clear;
    procedure beginFill(x, y: Double);
    procedure moveTo(x, y: Double);
    procedure lineTo(x, y: Double);
    procedure curveTo(cx, cy, ax, ay: Double);
    function GetCode: string;
  end;

implementation

function BitCount(Value: Integer): Integer;
begin
  Value := Abs(Value);
  Result := 31;
  while (Result > 0) and ((Value and (1 shl Result)) = 0) do
    Dec(Result);
  Inc(Result);
end;

function XYBitCount(x, y: Integer): Integer;
begin
  x := BitCount(x);
  y := BitCount(y);
  if x > y then
    Result := x
  else
    Result := y;
end;

function Val2bin(v, bits: Integer): string;
var
  c: Cardinal;
  i: Integer;
begin
  c := Cardinal(v);
  SetLength(Result, bits);
  FillChar(Result[1], bits, '0');
  for i := bits downto 1 do
  begin
    if c = 0 then
      Break;
    if Odd(c) then
      Result[i] := '1'
    else
      Result[i] := '0';
    c := c shr 1;
  end;
end;

{ TShape }

procedure TShape.AddBit(Bit: Boolean);
begin
  if Bit then
    AddBits('1')
  else
    AddBits('0');
end;

procedure TShape.AddBits(const Str: string);
var
  i: Integer;
begin
  for i := 1 to Length(Str) do
  begin
    Bits := 2 * Bits;
    if Str[i] = '1' then
      Inc(Bits);
    Inc(Count);
    if Count = 8 then
    begin
      Code := Code + Chr(Bits);
      Bits := Bits shr 8;
      Dec(Count, 8);
    end;
  end;
end;

procedure TShape.beginFill(x, y: Double);
var
  b: Integer;
begin
  //WriteLn('; setup');
  //WriteLn(Format('moveTo(%0.2f, %0.2f);',[x,y]));
  ox := Round(x);
  oy := Round(y);
  px := ox;
  py := oy;
  AddBits('00001'); // Setup, No ExtStyle, No LineStyle, no FillStyle1, FillStyle0
  if (ox = 0) and (oy = 0) then
    AddBits('0')
  else begin
    AddBits('1');
    b := XYBitCount(ox, oy) + 1;
    AddBits(Val2Bin(b, 5));
    AddBits(Val2Bin(ox, b));
    AddBits(Val2Bin(oy, b));
  end;
  AddBit(True); // FillStyle0 = 1
end;

procedure TShape.Clear;
begin
  Code := '';
  Bits := 0;
  Count := 0;
end;

procedure TShape.curveTo(cx, cy, ax, ay: Double);
var
  _x, _y, dx, dy, b, c: Integer;
begin
  //WriteLn(Format('curveTo(%0.2f, %0.2f,%0.2f, %0.2f);',[cx,cy,ax,ay]));
  _x := px;
  _y := py;
  px := Round(cx);
  py := Round(cy);
  _x := px - _x;
  _y := py - _y;
  dx := px;
  dy := py;
  px := Round(ax);
  py := Round(ay);
  dx := px - dx;
  dy := py - dy;
{
  _x := Round(cx - px);
  _y := Round(cy - py);
  dx := Round(ax - cx);
  dy := Round(ay - cy);
  px := ax;
  py := ay;
}
  b := XYBitCount(_x, _y) + 1;
  c := XYBitCount(dx, dy) + 1;
  if c > b then
    b := c;
  AddBits('10');
  AddBits(Val2Bin(b - 2, 4));
  Addbits(Val2Bin(_x, b));
  Addbits(Val2Bin(_y, b));
  Addbits(Val2Bin(dx, b));
  Addbits(Val2Bin(dy, b));
end;

function TShape.GetCode: string;
begin
  lineTo(ox, oy);
  AddBits('000000');
  //while Count > 0 do AddBits('0');
  if Count > 0 then
    Code := Code + Chr(Bits shl (8 - Count));
  Result := Code;
end;

procedure TShape.lineTo(x, y: Double);
var
  dx, dy, b: Integer;
begin
  //WriteLn(Format('lineTo(%0.2f, %0.2f);',[x,y]));
  dx := px;
  dy := py;
  px := Round(x);
  py := Round(y);
  dx := px - dx;
  dy := py - dy;
  if (dx = 0) and (dy = 0) then
    Exit;
  b := XYBitCount(dx, dy) + 1;
  AddBits('11');
  AddBits(Val2Bin(b - 2, 4));
  if dx = 0 then
    Addbits('01' + Val2Bin(dy, b))
  else
  if dy = 0 then
    AddBits('00' + Val2Bin(dx, b))
  else
    AddBits('1' + Val2Bin(dx, b) + Val2Bin(dy, b));
end;

procedure TShape.moveTo(x, y: Double);
var
  b: Integer;
begin
  lineTo(ox, oy);
  ox := Round(x);
  oy := Round(y);
  //WriteLn(Format('moveTo(%0.2f, %0.2f);',[x,y]));
  AddBits('000001'); // Setup, No ExtStyle, No LineStyle, no FillStyle1, no FillStyle0, move
  px := ox;
  py := oy;
  b := XYBitCount(ox, oy) + 1;
  AddBits(Val2Bin(b, 5));
  AddBits(Val2Bin(ox, b));
  AddBits(Val2Bin(oy, b));
end;

end.
