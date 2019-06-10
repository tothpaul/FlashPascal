{ This file is part of Flash Pascal project. See 'http://flashpascal.sf.net' for more. }

unit SWF;

//----------------------------------------------------------------------------//
// the SWF code part is based on Sphing (Swf with PHp without mING)
// Project homepage: http://sphing.sourceforge.net/
// Copyright 2002 Igor Clukas <igor -at- clukas -dot- de>

{
Flash actions:

Add = #$0A
Add_typed = #$47
And = #$60
BranchAlways = #$99
BranchIfTrue = #$9D
CallFrame = #$9E
CallFunction = #$3D
CallMethod = #$52
Chr = #$33
Chr_multi_bytes = #$37
ConcatenateStrings = #$21
CastObject = #$2B
ColorObject = *
DeclareArray = #$42
DeclareDictionary = #$88
DeclareFunction = #$9B
DeclareFunction_V7 = #$8E
DeclareLocalVariable = #$41
DeclareObject = #$43
Decrement = #$51
Delete = #$3A
DeleteAll = #$3B
Divide = #$0D
Duplicate = #$4C
DuplicateSprite = #$24
End = #$00
Enumerate = #$46
EnumerateObject = #$55
Equal = #$0E
Equal_typed = #$49
Extends = #$69
FSCommand2 = #$2D
GetMember = #$4E
GetProperty = #$22
GetTarget = #$45
GetTimer = #$34
GetURL = #$83
GetURL2 = #$9A
GetVariable = #$1C
GotoExpression = #$9F
GotoFrame = #$81
GotoLabel = #$8C
GreaterThan_typed = #$67
Implements = #$2C
Increment = #$50
InstanceOf = #$54
IntegralPart = #$18
LessThan = #$0F
LessThan_typed = #$48
LogicalAnd = #$10
LogicalNot = #$12
LogicalOr = #$11
MathObject = *
Modulo = #$3F
Multiply = #$0C
NextFrame = #$04
New = #$40
NewMethod = #$53
Number = #$4A
Or = #$61
Ord = #$32
Ord_multi_bytes = #$36
Play = #$06
PreviousFrame = #$05
PushData = #$96
Random = #$30
RemoveSprite = #$25
Return = #$3E
SetLocalVariable = #$3C
SetMember = #$4F
SetProperty = #$23
SetTarget = #$8B
SetTarget (dynamic) = #$20
SetVariable = #$1D
ShiftLeft = #$63
ShiftRight = #$64
ShiftRightUnsigned = #$65
StartDrag = #$27
Stop = #$07
StopDrag = #$28
StopSound = #$09
StoreRegister = #$87
StrictEqual = #$66
StrictMode = #$89
String = #$4B
StringEqual = #$13
StringGreaterThan = #$68
StringLength = #$14
StringLength_multi_bytes = #$31
StringLessThan = #$29
StringObject = *
SubString = #$15
SubString_multi_bytes = #$35
Subtract = #$0B
Swap = #$4D
Throw = #$2A
ToggleQuality = #$08
Trace = #$26
Try = #$8F
TypeOf = #$44
WaitForFrame = #$8A
WaitForFrame_dynamic = #$8D
With = #$94
XOr = #$62
}

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
 Deflate;

{in Flash multibyte character encodings use 16 bits (UCS-2, UTF-8)}
const
 acEndAction         =#$00;
 acSubstract         =#$0B;
 acMultiply          =#$0C;
 acDivide            =#$0D;
 acLogicalAnd        =#$10;
 acLogicalOr         =#$11;
 acLogicalNot        =#$12;
 acStringEqual       =#$13; // --> acEqual
 acStringLength      =#$14; // --> acStringLengthMulti
 acSubString         =#$15; // --> acSubStringMulti
 acPop               =#$17;
 acIntegralPart      =#$18;
 acGetVariable       =#$1C;
 acSetVariable       =#$1D;
 acConcat            =#$21;
 acTrace             =#$26;
 acStringLessThan    =#$29; // --> acLessThan
 acCastObject        =#$2B; // 0 (o) operation: (s2) o1 // if(s2=o1)then result=o1 else result=nil
 acFSCommand2        =#$2D; // fscommand2(Param_1_theN, Param_2_TheCommand, Param_3, Param_4 ... Param_N);
 acStringLengthMulti =#$31; // multibyte
 acOrd               =#$32; // --> acOrdMulti
 acChr               =#$33; // --> acChrMulti
 acGetTimer          =#$34;
 acSubStringMulti    =#$35; // multibyte
 acOrdMulti          =#$36; // multibyte
 acChrMulti          =#$37; // multibyte
 acDelete            =#$3A;
 acDeleteAll         =#$3B; // swfpushstring(name)+acDeleteAll - cleanup an object with all of its members
 acSetLocalVar       =#$3C;
 acCallFunction      =#$3D;
 acReturn            =#$3E;
 acModulo            =#$3F;
 acNewObject         =#$40;
 acDeclareLocalVar   =#$41;
 acDeclareArray      =#$42;
 acDeclareObject     =#$43;
 acAdd               =#$47;
 acLessThan          =#$48;
 acEqual             =#$49;
 acString            =#$4B;
 acDuplicate         =#$4C;
 acSwap              =#$4D;
 acGetMember         =#$4E;
 acSetMember         =#$4F;
 acIncrement         =#$50;
 acDecrement         =#$51;
 acCallMethod        =#$52;
 acBitwiseAnd        =#$60;
 acBitwiseOr         =#$61;
 acBitwiseXOr        =#$62;
 acShl               =#$63;
 acShrSigned         =#$64;
 acShrUnsigned       =#$65; // pascal programmers use unsigned shift :)
 acGreaterThan       =#$67;
//acStringGreaterThan =#$68; // --> acGreaterThan
 acExtends           =#$69;
 acSetRegister       =#$87;
 acDeclareDictionary =#$88;
 acDeclareFunction7  =#$8E; // ActionDefineFunction2
 acWith              =#$94;
 acPush              =#$96;
 acBranch            =#$99;
 acDeclareFunction   =#$9B;
 acBranchIfEq        =#$9D;

 SWFPushNull     =acPush+#$01#$00#$02;
 SWFPushUndefined=acPush+#$01#$00#$03;

 FLAG_7 = $19;//$19;//1 + 2 + 4 + 8 + 16 + 32;   $2a
 // $15  010101
 // $19  011001
 // $1A  011010
 // $2A  101010
{
unsigned short  f_declare_function2_reserved : 7;
unsigned short  f_preload_global : 1;               256
unsigned short  f_preload_parent : 1;               128
unsigned short  f_preload_root : 1;                  64
unsigned short  f_suppress_super : 1;                32
unsigned short  f_preload_super : 1;                 16
unsigned short  f_suppress_arguments : 1;             8
unsigned short  f_preload_arguments : 1;              4
unsigned short  f_suppress_this : 1;                  2
unsigned short  f_preload_this : 1;                   1
}

// Is there any reason for these to have here? - I think none
{$DEFINE REG_THIS}  // use Register 1 for this
{$DEFINE REG_PARAM} // use Registers 2..n for parameters
{$DEFINE REG_VARS}  // use Registers n+1...m for local var

type
  TDictionary = class
    Value: string;
    Next : TDictionary;
  end;

  TDicInfo = record
    Items : TDictionary;
    Length: Integer;
    Count : Integer;
  end;

var
  Dictionary: TDicInfo;

function SWFFile(ver, w, h, rate, frames: Cardinal; const code: string): string;
function SWFFileNotCompressed(ver, w, h, rate, frames: Cardinal; const code: string): string; // for special needs if any

function SWFshort(value:word):string;
function SWFlong(value:integer):string;
function SWFrect(x1, y1, x2, y2:integer):string;
function SWFshead(id,length:cardinal):string;
function SWFlhead(id:word; const data:string):string;
function SWFhead(id: Word; const data: string): string;
function SWFbin(const bin:string):string;
function SWFval2bin(v, bits: Integer):string;
function SWFval2bin2(v, bits: Cardinal):string;

function SWFDoAction(Actions:string):string;

function SWFPushBoolean(Value:boolean):string;
function SWFPushInteger(Value:integer):string;
function SWFPushDouble(Value:double):string;
function SWFPushString(const Str:string):string;

function SWFIsPushInteger(const Code: string; var Value: Integer): Boolean;
function SWFIsPushDouble(const Code: string; var Value: Double): Boolean;
function SWFIsPushNumber(const Code: string; var Value: Double): Boolean;

function SWFGetRegister(Reg:byte):string;
function SWFSetRegister(Reg:byte):string;
function SWFGetVariable(const name:string):string;
function SWFGetMember(const name:string):string;
function SWFNewObject(const name:string):string;
function SWFDeleteObject(const name:string):string; // classname.Destroy?
function SWFCallFunction(const Name:string):string;
function SWFCallMethod(const name:string):string;

function SWFSubstract(a, b: string): string;
function SWFOptimize(code:string):string;

function Branch(ofs:smallint):string;
function BranchIfEq(ofs:smallint):string;

function SWFAttributes(Flags:cardinal):string;
function SWFBackground(r,g,b:byte):string;
function SWFShowframe():string;
function SWFEndTag:string;

function SWFdefineshape(x1, y1, x2, y2, fills:integer; fillstyles:string; lines:integer; linestyles, shapes:string; id:word):string;
function SWFFillStyleBitmap(id:word):string;
function SWFshapebox(x1, y1, x2, y2, fill:integer):string;
function SWFplaceobject(id, depth:word):string;
function SWFTranslateMatrix(x, y: Integer): string;

function SWFDictionary: string;

implementation


function BitCount(value: Integer): Integer;
begin
  Value := Abs(Value);
  Result := 31;
  while (Result > 0) and ((Value and (1 shl Result)) = 0) do
    Dec(Result);
  Inc(Result);
end;

function SWFshort(value: Word): string;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(value));
end;

function DictionaryIndex(const Str: string): Integer;
var
  d: TDictionary;
  l: TDictionary;
begin
  Result := 0;
  l := nil;
  d := Dictionary.Items;
  while d <> nil do
  begin
    if d.Value = Str then
      Exit;
    l := d;
    d := d.Next;
    Inc(Result);
  end;
  if (Result > 255) or ((Length(Str) + Dictionary.Length + 2) > 65535) then
    Result := -1
  else begin
    d := TDictionary.Create;
    d.value := Str;
    if l = nil then
      Dictionary.Items := d
    else
      l.Next := d;
    Inc(Dictionary.Length, Length(Str) + 1);
    Inc(Dictionary.Count);
  end;
end;

function SWFDictionary: string;
var
  n: TDictionary;
begin
  if Dictionary.Items = nil then
    Result := ''
  else begin
    Result := #$88 + SWFshort(Dictionary.Length + 2) + SWFshort(Dictionary.Count);
    while Dictionary.Items <> nil do
    begin
      n := Dictionary.Items.Next;
      Result := Result + Dictionary.Items.Value + #0;
      Dictionary.Items.Free;
      Dictionary.Items := n;
    end;
  end;
end;

function SWFlong(value:integer):string;
begin
 SetLength(Result,SizeOf(Value));
 move(value,Result[1],SizeOf(value));
end;

function SWFPushBoolean(Value:boolean):string;
begin
 Result:=#$96+SWFshort(2)+#$05+chr(ord(Value));
end;

function SWFPushInteger(Value:integer):string;
begin
 Result:=#$96+SWFshort(5)+#$07+SWFlong(value);
end;

function SWFIsPushInteger(const Code: string; var Value: Integer): Boolean;
begin
  Result := (Length(Code) = 8) and (Copy(Code, 1, 4) = (#$96 + SWFshort(5) + #$07));
  if Result then
    Move(Code[5], Value, SizeOf(Value));
end;

function SWFPushDouble(Value:double): string;
begin
  SetLength(Result, 8);
  Move(Value, Result[1], 8);
  Result := #$96#$09#$00#$06 + Copy(Result, 5, 4) + Copy(Result, 1, 4);
end;

function SWFIsPushDouble(const Code: string; var Value: Double): Boolean;
var
  Str: string;
begin
  Result := (Length(Code) = 16) and (Copy(Code, 1, 4) = #$96#$09#$00#$06);
  if Result then
  begin
    Str := Copy(Code,12, 4) + Copy(Code, 8, 4);
    Move(Str[1], Value, SizeOf(Value));
  end;
end;

function SWFIsPushNumber(const Code: string; var Value: Double): Boolean;
var
  i: Integer;
begin
  if SWFIsPushInteger(Code, i) then
  begin
    Result := True;
    Value := i
  end else
    Result := SWFIsPushDouble(Code, Value);
end;

function SWFPushString(const Str:string):string;
var
 i:integer;
begin
 i:=DictionaryIndex(Str);
 if i<0 then
  Result:=#$96+SWFshort(Length(Str)+2)+#0+Str+#0
 else begin
  if i<256 then
   Result:=#$96+#$02#$00#$08+chr(i)
  else
   Result:=#$96+#$02#$00#$09+SWFshort(i);
 end;
end;

function SWFGetVariable(const name:string):string;
begin
 Result:=SWFPushString(name)+acGetVariable;
end;

function SWFGetRegister(Reg:byte):string;
begin
 Result:=#$96+#$02#$00#$04+chr(Reg);
end;

function SWFGetMember(const name:string):string;
begin
 Result:=SWFPushString(name)+acGetMember;
end;

function SWFCallMethod(const name:string):string;
begin
 Result:=SWFPushString(name)+acCallMethod;//#$52
end;

function SWFNewObject(const name:string):string;
begin
 Result:=SWFPushString(name)+acNewObject;//#$40
end;

function SWFDeleteObject(const name:string):string;
begin
 Result:=SWFPushString(name)+acDeleteAll;
end;

function SWFSetMember(const name:string):string;
begin
 Result:=SWFPushString(name)+acSetMember;//#$4F
end;

function SWFSetRegister(Reg:byte):string;
begin
 Result:=#$87#$01#$00+chr(Reg);
end;

function SWFlhead(id:word; const data:string):string;
begin
 Result:=SWFshort((id shl 6) or $3f)+SWFlong(Length(data))+data;
end;

function SWFshead(id,length:cardinal):string;
begin
 Result:=SWFshort((id shl 6) or (length and $3f));
end;

function SWFhead(id:word; const data:string):string;
begin
  if Length(data) >= $3f then
    Result := SWFlhead(id, data)
  else
    Result := SWFshead(id, Length(data)) + data;
end;

function SWFDoAction(Actions:string):string;
begin
 Actions:=SWFDictionary+Actions;
 Result:=SWFlhead(12,Actions);
end;

function SWFAttributes(Flags:cardinal):string;
begin
 Result:=SWFshead(69,4)+SWFlong(Flags);
end;

function SWFBackground(r,g,b:byte):string;
begin
 Result:=SWFshead(9, 3) + chr(r) + chr(g) + chr(b);
end;

function SWFEndTag:string;
begin
 Result:=SWFshead(0,0);
end;

function SWFbin(const bin:string):string;
var
 i,v,b:integer;
begin
 Result:='';
 v:=0;
 b:=0;
 for i:=1 to length(bin) do begin
  v:=v shl 1;
  if bin[i]='1' then inc(v);
  inc(b);
  if b=8 then begin
   Result:=Result+chr(v);
   v:=0;
   b:=0;
  end;
 end;
 if b>0 then Result:=Result+chr(v shl (8-b));
end;


function SWFval2bin(v, bits: Integer): string;
var
  i: Integer;
begin
  SetLength(Result, bits);
  for i := bits downto 1 do
  begin
    if Odd(v) then
      Result[i] := '1'
    else
      Result[i] := '0';
    v := v shr 1;
  end;
end;

function SWFval2bin2(v, bits: Cardinal): string;
var
  i: Integer;
begin
  SetLength(Result, bits);
  for i := bits downto 1 do
  begin
    if Odd(v) then
      Result[i] := '1'
    else
      Result[i] := '0';
    v := v shr 1;
  end;
  while v > 0 do
  begin
    if Odd(v) then
      Result := '1' + Result
    else
      Result := '0' + Result;
    v := v shr 1;
  end;
end;

function SWFrect(x1, y1, x2, y2:integer):string;
var
 bits:integer;
begin
 if (abs(x1)<$1fff)and(abs(y1)<$1fff)and(abs(x2)<$1fff)and(abs(y2)<$1fff) then bits:=14 else bits:=16;
 Result:=SWFbin(SWFval2bin2(bits,5)
               +SWFval2bin(x1,bits)
               +SWFval2bin(x2,bits)
               +SWFval2bin(y1,bits)
               +SWFval2bin(y2,bits));
end;

function SWFShowframe():string;
begin
 Result:=SWFshead(1,0);
end;

function SWFFile(ver, w, h, rate, frames: Cardinal; const code: string): string;
var
  cSize: Integer;
begin
  Result := SWFrect(0, 0, w * 20, h * 20) + #0 + Chr(rate) + SWFshort(frames) + code;
  cSize :=Length(Result) + 8;
  Result := 'CWS' + Chr(ver) + SWFlong(cSize) + zCompressStr(Result);
end;

function SWFFileNotCompressed(ver, w, h, rate, frames: Cardinal; const code: string): string; // for special needs if any
var
  cSize: Integer;
begin
  Result := SWFrect(0, 0, w * 20, h * 20) + #0 + Chr(rate) + SWFshort(frames) + code;
  cSize :=Length(Result) + 8;
  Result := 'CWS' + Chr(ver) + SWFlong(cSize) + Result;
end;

function Branch(ofs: smallint): string;
begin
  Result := #$99#$02#$00 + SWFshort(Word(ofs));
end;

function BranchIfEq(ofs: smallint): string;
begin
  Result := #$9D#$02#$00 + SWFshort(Word(ofs));
end;

function SWFCallFunction(const Name:string):string;
begin
 Result:=SWFPushString(Name)
        +acCallFunction;
end;

function IsInteger(a: string; var i: Integer): Boolean;
begin
  Result := (Length(a) = 8) and (Copy(a, 1, 4) = #$96 + SWFshort(5) + #$07);
  if Result then
    Move(a[5], i, 4);
end;

function SWFSubstract(a, b: string): string;
var
  i, j: Integer;
begin
  if IsInteger(a, i) and IsInteger(b, j) then
    Result := SWFPushInteger(i - j)
  else
    Result := a + b + acSubstract;
end;

// concat Push operations
function SWFOptimize(code:string):string;
var
 i:integer;
 l:integer;
 c:byte;
 w:word;
begin
 i:=1;
 while i<length(code) do begin
  c:=ord(code[i]);
  inc(i);
  if (c and $80)=0 then
   l:=0
  else begin
   move(code[i],w,2);
   inc(i,2);
   l:=w;
  end;
  if (i+l<length(code))and(c=$96)and(code[i+l]=#$96) then begin // 2 PUSH
   move(code[i+l+1],w,2);
   if l+w<65535 then begin // we can merge them
    code:=copy(code,1,i-3)+SWFshort(l+w)+copy(code,i,l)+copy(code,i+l+3,MaxInt);
    i:=i-3;
    l:=0;
   end;
  end;
  inc(i,l);
 end;
 Result:=code;
end;

// Shape1 only!
function SWFdefineshape(x1, y1, x2, y2, fills:integer; fillstyles:string; lines:integer; linestyles, shapes:string; id:word):string;
var
 fbits:integer;
 lbits:integer;
begin
 if (fills = 0) then
  fbits:=0
 else begin
  fbits:=1;
  while (fbits<8)and(fills shr fbits>0) do inc(fbits);
 end;
 if (lines = 0) then
  lbits:=0
 else begin
  lbits:=1;
  while (lbits<8)and(lines shr lbits>0) do inc(lbits);
 end;
 Result:=SWFshort(id)
        +SWFrect(x1, y1, x2, y2) // bounds
        +chr(fills)+fillStyles // # of fill styles and fill styles array
        +chr(lines)+linestyles // # of line styles and line styles array
        +chr((fbits shl 4) or lbits) // fill and line style index bits
        +shapes;
 Result:=SWFlhead(2, Result);
end;

// this is totally INCOMPLETE and currently only a hack!
function SWFFillStyleBitmap(id:word):string;
begin
 Result:=chr($41)+SWFshort(id)
        +SWFbin('1'     // has scale
               +'10110' // 22 bits (4.16)
               +'0101000000000000000000' // 20
               +'0101000000000000000000' // 20
               +'0' // has rotate
               +'0' // translate bits
               );
end;

// creates a box shape, INCOMPLETE
function SWFshapebox(x1, y1, x2, y2, fill:integer):string;
var
 max  :integer;
 bits :integer;
 bitsl:integer;
begin
 max := abs(x1);
 if (abs(x2) > max) then max := abs(x2);
 if (abs(y1) > max) then max := abs(y1);
 if (abs(y2) > max) then max := abs(y2);
 bits:=2;
 if (max <> 0) then begin
  while (bits<32)and((max shr bits)>0) do inc(bits);
  inc(bits); // extra bit for signed values...
 end;
 bitsl := bits-2; // in line records Flash adds 2 to the bitcount
 Result:=SWFbin('0' // non-edge record flag
               +'0' // new styles flag
               +'0' // line style change flag
               +'1' // fill style 1 change flag
               +'0' // fill style 0 change flag
               +'1' // move to flag
               +SWFval2bin2(bits,5) ////14
               +SWFval2bin(x2, bits)    // move to x2,y2
               +SWFval2bin(y2, bits)
               +SWFval2bin2(fill,1) // fill style (bit length should be the same as in fill style array!)
               +'11' // edge record
               +SWFval2bin2(bitsl,4)
               +'00' // gen line = no, vert line = no
               +SWFval2bin(x1-x2, bits)
               +'11' // edge record
               +SWFval2bin2(bitsl,4)
               +'01' // gen line = no, vert line = yes
               +SWFval2bin(y1-y2, bits)
               +'11' // edge record
               +SWFval2bin2(bitsl,4)
               +'00' // gen line = no, vert line = no
               +SWFval2bin(x2-x1, bits)
               +'11' // edge record
               +SWFval2bin2(bitsl,4)
               +'01' // gen line = no, vert line = yes
               +SWFval2bin(y2-y1, bits)
               +'000000');      // end of shape record
end;

// placeobject tag, INCOMPLETE
function SWFplaceobject(id, depth:word):string;
begin
 Result:=SWFshead(26,6)
        +chr($06) // has matrix, has character
        +SWFshort(depth)
        +SWFshort(id)
        +chr(0);        // empty matrix
end;


function SWFTranslateMatrix(x, y: Integer): string;
var
  xBits, yBits: Integer;
begin
  xBits := BitCount(x) + 1;
  yBits := BitCount(y) + 1;
  if xBits < yBits then
    xBits := yBits;
  Result := swfBin('00' + swfVal2Bin(xBits, 5) + swfVal2Bin(x, xBits) + swfVal2Bin(y, xBits));
end;

end.

