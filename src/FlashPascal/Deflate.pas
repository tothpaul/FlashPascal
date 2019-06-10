unit Deflate;

{ Deflate decompression, (c)2008-2009 by Paul TOTH }
{
  Based on paszlib : Copyright (C) 1998 by Jacques Nomssi Nzali

  Original ZLib : Copyright (C) 1995-1998 Jean-loup Gailly and Mark Adler
}

interface

{$R-,Q-}

type
  TCustomDeflateStream = class
  protected
    function Read(var Data; Size: Cardinal): Cardinal; virtual; abstract;
    procedure Write(var Data; Size: Cardinal); virtual; abstract;
  public
    procedure Compress;
  end;

function zCompressStr(const Str:string):string;

implementation

const
 LENGTH_CODES = 29;  // number of length codes, not counting the special END_BLOCK code
 LITERALS     = 256; // number of literal bytes 0..255
 L_CODES      =(LITERALS+1+LENGTH_CODES); // number of Literal or Length codes, including the END_BLOCK code
 D_CODES      = 30;  // number of distance codes
 BL_CODES     = 19;  // number of codes used to transfer the bit lengths
 HEAP_SIZE    =(2*L_CODES+1); // maximum heap size
 MAX_BITS     = 15;  // All codes must not exceed MAX_BITS bits

 SMALLEST  = 1;
 END_BLOCK = 256;

 MIN_MATCH = 3;
 MAX_MATCH = 258;

type
  ct_data_ptr = ^ct_data;
  ct_data = array[0..1] of word;
  pbyte = ^byte;
  pword = ^word;

const
 TREE_FREQ = 0;
 TREE_CODE = 0;
 TREE_DAD  = 1;
 TREE_LEN  = 1;

 static_ltree : array[0..L_CODES+2-1] of ct_data = (
  ( 12, 8), (140, 8), ( 76, 8), (204, 8), ( 44, 8), (172, 8),
  (108, 8), (236, 8), ( 28, 8), (156, 8), ( 92, 8), (220, 8),
  ( 60, 8), (188, 8), (124, 8), (252, 8), (  2, 8), (130, 8),
  ( 66, 8), (194, 8), ( 34, 8), (162, 8), ( 98, 8), (226, 8),
  ( 18, 8), (146, 8), ( 82, 8), (210, 8), ( 50, 8), (178, 8),
  (114, 8), (242, 8), ( 10, 8), (138, 8), ( 74, 8), (202, 8),
  ( 42, 8), (170, 8), (106, 8), (234, 8), ( 26, 8), (154, 8),
  ( 90, 8), (218, 8), ( 58, 8), (186, 8), (122, 8), (250, 8),
  (  6, 8), (134, 8), ( 70, 8), (198, 8), ( 38, 8), (166, 8),
  (102, 8), (230, 8), ( 22, 8), (150, 8), ( 86, 8), (214, 8),
  ( 54, 8), (182, 8), (118, 8), (246, 8), ( 14, 8), (142, 8),
  ( 78, 8), (206, 8), ( 46, 8), (174, 8), (110, 8), (238, 8),
  ( 30, 8), (158, 8), ( 94, 8), (222, 8), ( 62, 8), (190, 8),
  (126, 8), (254, 8), (  1, 8), (129, 8), ( 65, 8), (193, 8),
  ( 33, 8), (161, 8), ( 97, 8), (225, 8), ( 17, 8), (145, 8),
  ( 81, 8), (209, 8), ( 49, 8), (177, 8), (113, 8), (241, 8),
  (  9, 8), (137, 8), ( 73, 8), (201, 8), ( 41, 8), (169, 8),
  (105, 8), (233, 8), ( 25, 8), (153, 8), ( 89, 8), (217, 8),
  ( 57, 8), (185, 8), (121, 8), (249, 8), (  5, 8), (133, 8),
  ( 69, 8), (197, 8), ( 37, 8), (165, 8), (101, 8), (229, 8),
  ( 21, 8), (149, 8), ( 85, 8), (213, 8), ( 53, 8), (181, 8),
  (117, 8), (245, 8), ( 13, 8), (141, 8), ( 77, 8), (205, 8),
  ( 45, 8), (173, 8), (109, 8), (237, 8), ( 29, 8), (157, 8),
  ( 93, 8), (221, 8), ( 61, 8), (189, 8), (125, 8), (253, 8),
  ( 19, 9), (275, 9), (147, 9), (403, 9), ( 83, 9), (339, 9),
  (211, 9), (467, 9), ( 51, 9), (307, 9), (179, 9), (435, 9),
  (115, 9), (371, 9), (243, 9), (499, 9), ( 11, 9), (267, 9),
  (139, 9), (395, 9), ( 75, 9), (331, 9), (203, 9), (459, 9),
  ( 43, 9), (299, 9), (171, 9), (427, 9), (107, 9), (363, 9),
  (235, 9), (491, 9), ( 27, 9), (283, 9), (155, 9), (411, 9),
  ( 91, 9), (347, 9), (219, 9), (475, 9), ( 59, 9), (315, 9),
  (187, 9), (443, 9), (123, 9), (379, 9), (251, 9), (507, 9),
  (  7, 9), (263, 9), (135, 9), (391, 9), ( 71, 9), (327, 9),
  (199, 9), (455, 9), ( 39, 9), (295, 9), (167, 9), (423, 9),
  (103, 9), (359, 9), (231, 9), (487, 9), ( 23, 9), (279, 9),
  (151, 9), (407, 9), ( 87, 9), (343, 9), (215, 9), (471, 9),
  ( 55, 9), (311, 9), (183, 9), (439, 9), (119, 9), (375, 9),
  (247, 9), (503, 9), ( 15, 9), (271, 9), (143, 9), (399, 9),
  ( 79, 9), (335, 9), (207, 9), (463, 9), ( 47, 9), (303, 9),
  (175, 9), (431, 9), (111, 9), (367, 9), (239, 9), (495, 9),
  ( 31, 9), (287, 9), (159, 9), (415, 9), ( 95, 9), (351, 9),
  (223, 9), (479, 9), ( 63, 9), (319, 9), (191, 9), (447, 9),
  (127, 9), (383, 9), (255, 9), (511, 9), (  0, 7), ( 64, 7),
  ( 32, 7), ( 96, 7), ( 16, 7), ( 80, 7), ( 48, 7), (112, 7),
  (  8, 7), ( 72, 7), ( 40, 7), (104, 7), ( 24, 7), ( 88, 7),
  ( 56, 7), (120, 7), (  4, 7), ( 68, 7), ( 36, 7), (100, 7),
  ( 20, 7), ( 84, 7), ( 52, 7), (116, 7), (  3, 8), (131, 8),
  ( 67, 8), (195, 8), ( 35, 8), (163, 8), ( 99, 8), (227, 8));

  static_dtree : array[0..D_CODES-1] of ct_data = (
  ( 0,5), (16,5), ( 8,5), (24,5), ( 4,5), (20,5),
  (12,5), (28,5), ( 2,5), (18,5), (10,5), (26,5),
  ( 6,5), (22,5), (14,5), (30,5), ( 1,5), (17,5),
  ( 9,5), (25,5), ( 5,5), (21,5), (13,5), (29,5),
  ( 3,5), (19,5), (11,5), (27,5), ( 7,5), (23,5));

{ Distance codes. The first 256 values correspond to the distances
  3 .. 258, the last 256 values correspond to the top 8 bits of
  the 15 bit distances. }
  _dist_code : array[0..512-1] of byte = (
    0,  1,  2,  3,  4,  4,  5,  5,  6,  6,  6,  6,  7,  7,  7,  7,  8,  8,  8,  8,
    8,  8,  8,  8,  9,  9,  9,  9,  9,  9,  9,  9, 10, 10, 10, 10, 10, 10, 10, 10,
   10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
   11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
   12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13,
   13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
   13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
   14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
   14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
   14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15,
   15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
   15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
   15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,  0,  0, 16, 17,
   18, 18, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22,
   23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
   24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
   26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
   26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27,
   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
   27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
   28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
   28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
   28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
   29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
   29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
   29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29
  );

{ length code for each normalized match length (0 == MIN_MATCH) }
  _length_code : array[0..MAX_MATCH-MIN_MATCH+1-1] of byte = (
   0,  1,  2,  3,  4,  5,  6,  7,  8,  8,  9,  9, 10, 10, 11, 11, 12, 12, 12, 12,
  13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16,
  17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19,
  19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
  21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22,
  22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23,
  23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
  25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28
 );

{ repeat a zero length 11-138 times  (7 bits of repeat count) }
  extra_lbits : array[0..LENGTH_CODES-1] of integer
    { extra bits for each length code }
   = (0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0);
  extra_dbits : array[0..D_CODES-1] of integer
    { extra bits for each distance code }
   = (0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
  extra_blbits : array[0..BL_CODES-1] of integer { extra bits for each bit length code }
   = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,3,7);

  MAX_BL_BITS = 7;
{ Bit length codes must not exceed MAX_BL_BITS bits }
  REP_3_6 = 16;
{ repeat previous bit length 3-6 times (2 bits of repeat count) }
  REPZ_3_10 = 17;
{ repeat a zero length 3-10 times  (3 bits of repeat count) }
  REPZ_11_138 = 18;

  bl_order : array[0..BL_CODES-1] of byte
   = (16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

{ First normalized length for each code (0 = MIN_MATCH) }
  base_length : array[0..LENGTH_CODES-1] of integer = (
   0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56,
  64, 80, 96, 112, 128, 160, 192, 224, 0
  );

{ First normalized distance for each code (0 = distance of 1) }
  base_dist : array[0..D_CODES-1] of integer = (
     0,     1,     2,     3,     4,     6,     8,    12,    16,    24,
    32,    48,    64,    96,   128,   192,   256,   384,   512,   768,
  1024,  1536,  2048,  3072,  4096,  6144,  8192, 12288, 16384, 24576
  );

const
 COMPRESS_LEVEL   = 9;

 WINDOW_BITS      = 15;
 WINDOW_SIZE      = 1 shl WINDOW_BITS;
 WINDOW_MASK      = WINDOW_SIZE-1;

 Z_DEFLATED       = 8;
 Z_HEADER         = (Z_DEFLATED + ((WINDOW_BITS-8) shl 4)) shl 8;

 MIN_LOOKAHEAD    = (MAX_MATCH+MIN_MATCH+1);
 TOO_FAR          = 4096;

 BUF_SIZE         = (8 * 2*sizeof(char));

 MEM_LEVEL        = 8;
 HASH_BITS        = MEM_LEVEL+7;
 HASH_SIZE        = 1 shl HASH_BITS;
 HASH_MASK        = HASH_SIZE-1;
 HASH_SHIFT       = (HASH_BITS+2) div 3;
 LIT_BUF_SIZE     = 1 shl (MEM_LEVEL+6);

 STORED_BLOCK     = 0;
 STATIC_TREES     = 1;
 DYN_TREES        = 2;

 GOOD_MATCH       = 32;
 MAX_LAZY_MATCH   = 258;
 NICE_MATCH       = 258;
 MAX_CHAIN_LENGTH = 4096;

type
 TOverlayBuffers = record
   Pending : array[0..LIT_BUF_SIZE-1] of byte;
   Dis     : array[0..LIT_BUF_SIZE-1] of word;
   Lit     : array[0..LIT_BUF_SIZE-1] of byte; { buffer for literals or lengths }
 end;

 THuffmanTrees=class
 private
 // NB: fPendingBuf overlay fLitBuf, so they MUST be declared together !
 // This works since the average output size for (length,distance) codes is <= 24 bits
 {
  fPendingBuf : array[0..LIT_BUF_SIZE-1] of byte;
  fDisBuf     : array[0..LIT_BUF_SIZE-1] of word;
  fLitBuf     : array[0..LIT_BUF_SIZE-1] of byte; { buffer for literals or lengths }
  FBuf        : TOverlayBuffers;
  fPending    : integer; { nb of bytes in the pending buffer }
  fLastLit    : cardinal;
  fBits       : word;
  fBitCount   : integer;
  fLitTree    : array[0..HEAP_SIZE-1] of ct_data;    { literal and length tree }
  fDisTree    : array[0..2*D_CODES+1-1] of ct_data;  { distance tree }
  fBitLenTree : array[0..2*BL_CODES+1-1] of ct_data; { Huffman tree for bit lengths }
  fBitLenCount: array[0..MAX_BITS+1-1] of word;      { number of codes at each bit length for an optimal tree }
  fDepth      : array[0..2*L_CODES+1-1] of byte;
  fHeap       : array[0..2*L_CODES+1-1] of integer;
  fHeapLen    : integer;
  fHeapMax    : integer;
  fOptLen     : cardinal;
  fStaticLen  : cardinal;
  function Tally(dist,lc: cardinal):boolean;
  procedure FlushBlock (buf : pbyte; stored_len : cardinal; eof: boolean);
  procedure SendBits(value, length : integer);
  procedure WindUp;
  procedure StoredBlock(buf : pbyte; len : cardinal; eof : boolean);
  procedure CompressBlock(const ltree, dtree: array of ct_data);
  procedure SendAllTrees(lcodes, dcodes, blcodes: integer);
  procedure SendTree(const tree: array of ct_data; max_code: integer);
  function BuildTree(var tree : array of ct_data; const stree: array of ct_data; max_length, base : integer; const extra : array of integer):integer;
  procedure PQDownHeap(var tree: array of ct_data; k :integer);
  procedure ScanTree(var tree: array of ct_data; max_code:integer);
  procedure GenBitLen(var tree : array of ct_data; const stree: array of ct_data; max_code,max_length,base : integer; const extra:array of integer);
  procedure GenCodes(var tree : array of ct_data; max_code : integer);
 end;

 TDeflateState=class(THuffmanTrees)
 private
  fStream         : TCustomDeflateStream;
  fWindow         : array[0..(2*WINDOW_SIZE)-1] of byte;
  fPrev           : array[0..WINDOW_SIZE-1] of word;
  fHead           : array[0..HASH_SIZE-1] of word;
  fAdler          : cardinal;
  fHashIndex      : cardinal;
  fStrStart       : cardinal;
  fMatchStart     : cardinal;
  fLookahead      : cardinal;
  fPrevLength     : cardinal;
  fBlockStart     : integer;
  procedure FlushPending;
  procedure PutWord(value:word);
  procedure PutLong(Value:cardinal);
  procedure FillWindow;
  procedure InsertString(var match_head:cardinal);
  function LongestMatch(cur_match : cardinal):cardinal;
  procedure FlushBlockOnly(eof : boolean);
 public
  procedure Compress(Stream:TCustomDeflateStream);
 end;

function adler32(adler : cardinal; buf : pbyte; len : cardinal) : cardinal;
const
  BASE = cardinal(65521); { largest prime smaller than 65536 }
  {NMAX = 5552; original code with unsigned 32 bit integer }
  { NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 }
  NMAX = 3854;        { code with signed 32 bit integer }
  { NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^31-1 }
  { The penalty is the time loss in the extra MOD-calls. }
var
  s1, s2 : cardinal;
  k : integer;
begin
  s1 := adler and $ffff;
  s2 := (adler shr 16) and $ffff;

  if not Assigned(buf) then
  begin
    adler32 := cardinal(1);
    exit;
  end;

  while (len > 0) do
  begin
    if len < NMAX then
      k := len
    else
      k := NMAX;
    Dec(len, k);
    while (k > 0) do
    begin
      Inc(s1, buf^);
      Inc(s2, s1);
      Inc(buf);
      Dec(k);
    end;
    s1 := s1 mod BASE;
    s2 := s2 mod BASE;
  end;
  adler32 := (s2 shl 16) or s1;
end;

function bi_reverse(code : cardinal;         { the value to invert }
                    len : integer) : cardinal;   { its bit length }
begin
  Result := 0;
  repeat
    Result := Result or (code and 1);
    code := code shr 1;
    Result := Result shl 1;
    Dec(len);
  until (len <= 0);
  Result := Result shr 1;
end;

type
 TDeflateString=class(TCustomDeflateStream)
 private
   FInput  : string;
   FOutput : string;
   FInPos  : Cardinal;
   FOutSize: Cardinal;
 protected
   function Read(var Data; Size: Cardinal): Cardinal; override;
   procedure Write(var Data; Size: Cardinal); override;
 public
  function Compress(const Str:string):string;
 end;

{ TDeflateString }

function TDeflateString.Read(var Data; Size: Cardinal): Cardinal;
begin
  Result := Cardinal(Length(FInput)) - FInPos;
  if Result > Size then
    Result := Size;
  Move(FInput[FInPos + 1], Data, Result);
  Inc(FInPos, Result);
end;

procedure TDeflateString.Write(var Data; Size: Cardinal);
var
  oldLen : Cardinal;
  newLen : Cardinal;
begin
  OldLen := Length(FOutput);
  NewLen := FOutSize + Size;
  if NewLen > OldLen then
    SetLength(FOutput, NewLen);
  Move(Data, FOutput[FOutSize + 1], Size);
  FOutSize := NewLen;
end;

function TDeflateString.Compress(const Str:string):string;
var
  len : Integer;
begin
  FInput := Str;
  FInPos := 0;
  len := Length(FInput);
  SetLength(FOutput, len + len div 10 + 12);
  FOutSize := 0;
 inherited Compress;
  SetLength(FOutput, FOutSize);
  Result := FOutput;
end;

{ TCustomDeflateStream }

procedure TCustomDeflateStream.Compress;
var
  State: TDeflateState;
begin
  State := TDeflateState.Create;
  try
    State.Compress(Self);
  finally
    State.Free;
  end;
end;

{ THuffmanTrees }
function THuffmanTrees.Tally(dist,lc : cardinal):boolean;
var
 code : word;
begin
 FBuf.Dis[fLastLit] := word(dist);
 FBuf.Lit[fLastLit] := byte(lc);
 inc(fLastLit);
 if (dist = 0) then
   { lc is the unmatched char }
  inc(fLitTree[lc,TREE_FREQ])
 else begin
 { Here, lc is the match length - MIN_MATCH }
  dec(dist);             { dist := match distance - 1 }
  if (dist) < 256 then
   code := _dist_code[dist]
  else
   code := _dist_code[256+(dist shr 7)];
  inc(fLitTree[_length_code[lc]+LITERALS+1,TREE_FREQ]);
  inc(fDisTree[code,TREE_FREQ]);
 end;
 Result := (fLastLit = LIT_BUF_SIZE-1);
end;

procedure THuffmanTrees.FlushBlock(buf : pbyte; stored_len : cardinal; eof: boolean);
var
  opt_lenb, static_lenb : cardinal; { opt_len and static_len in bytes }
  max_blindex : integer;  { index of last bit length code of non zero freq }
  MaxLit : Integer;
  MaxDis : Integer;
begin
{ Build the Huffman trees  }
{ Construct the literal and distance trees }
 MaxLit:=BuildTree(fLitTree, static_ltree, MAX_BITS, LITERALS+1,extra_lbits);
 MaxDis:=BuildTree(fDisTree, static_dtree, MAX_BITS, 0,extra_dbits);
{ At this point, opt_len and static_len are the total bit lengths of
 the compressed block data, excluding the tree representations. }
{ Build the bit length tree for the above two trees, and get the index
 in bl_order of the last bit length code to send. }
// max_blindex := build_bl_tree(s);
  ScanTree(fLitTree, MaxLit);
  ScanTree(fDisTree, MaxDis);
  { Build the bit length tree: }
  BuildTree(fBitLenTree, [], MAX_BL_BITS, 0, extra_blbits);
  { opt_len now includes the length of the tree representations, except
    the lengths of the bit lengths codes and the 5+5+4 bits for the counts. }
  { Determine the number of bit length codes to send. The pkzip format
    requires that at least 4 bit length codes be sent. (appnote.txt says
    3 but the actual value used is 4.) }
  for max_blindex := BL_CODES-1 downto 3 do
  begin
    if (fBitLenTree[bl_order[max_blindex],TREE_LEN] <> 0) then
      break;
  end;
  { Update opt_len to include the bit length tree and counts }
  Inc(fOptLen, 3*(max_blindex+1) + 5+5+4);

{ Determine the best encoding. Compute first the block length in bytes}
 opt_lenb := (fOptLen+3+7) shr 3;
 static_lenb := (fStaticLen+3+7) shr 3;
 if (static_lenb <= opt_lenb) then
  opt_lenb := static_lenb;
 if (stored_len+4 <= opt_lenb) and (buf <> pbyte(0)) then begin
 { 4: two words for the lengths }
 { The test buf <> NULL is only necessary if LIT_BUFSIZE > WSIZE.
   Otherwise we can't have processed more than WSIZE input bytes since
   the last block flush, because compression would have been
   successful. If LIT_BUFSIZE <= WSIZE, it is never too late to
   transform a block into a stored block. }
  StoredBlock(buf, stored_len, eof);
 end else
 if (static_lenb = opt_lenb) then begin
  SendBits((STATIC_TREES shl 1)+ord(eof), 3);
  CompressBlock(static_ltree, static_dtree);
 end else begin
  SendBits((DYN_TREES shl 1)+ord(eof), 3);
  SendAllTrees(MaxLit+1, MaxDis+1, max_blindex+1);
  CompressBlock(fLitTree, fDisTree);
 end;
 
 // init block
 FillChar(fLitTree,SizeOf(fLitTree),0);
 FillChar(fDisTree,SizeOf(fDisTree),0);
 FillChar(fBitLenTree,SizeOf(fBitLenTree),0);
 fLitTree[END_BLOCK,TREE_FREQ] := 1;
 fStaticLen := 0;
 fOptLen := 0;
 fLastLit := 0;

 if (eof) then WindUp;
end;

procedure THuffmanTrees.SendBits(value, length: integer);
begin
 if (fBitCount > BUF_SIZE - length) then begin
  fBits := fBits or (value shl fBitCount);
  FBuf.Pending[FPending] := FBits;
  Inc(FPending);
  FBuf.Pending[FPending] := FBits shr 8;
  Inc(FPending);

  fBits := value shr (BUF_SIZE - fBitCount);
  inc(fBitCount, length - BUF_SIZE);
 end else begin
  fBits := fBits or (value shl fBitCount);
  inc(fBitCount, length);
 end;
end;

procedure THuffmanTrees.WindUp;
begin
 if (fBitCount > 8) then begin
  FBuf.Pending[fPending] := fBits;
  inc(fPending);
  FBuf.Pending[fPending] := fBits shr 8;
  inc(fPending);
 end else
 if (fBitCount > 0) then begin
  FBuf.Pending[fPending] := fBits;
  inc(fPending);
 end;
 fBits := 0;
 fBitCount := 0;
end;

procedure THuffmanTrees.StoredBlock(buf : pbyte; len : cardinal; eof : boolean);
begin
 SendBits((STORED_BLOCK shl 1)+ord(eof), 3);  { send block type }
 Windup;        { align on byte boundary }
 FBuf.Pending[fPending] := len and $ff;
 inc(fPending);
 FBuf.Pending[fPending] := len shr 8;
 inc(fPending);
 FBuf.Pending[fPending] := (not len) and $ff;
 inc(fPending);
 FBuf.Pending[fPending] := (not len) shr 8;
 inc(fPending);
 move(buf^,FBuf.Pending[fPending],len);
 inc(fPending,len);
end;

var
 Counteur: Integer = 0;

procedure THuffmanTrees.CompressBlock(const ltree, dtree : array of ct_data);
var
 dist : cardinal;      { distance of matched string }
 lc : integer;             { match length or unmatched char (if dist == 0) }
 lx : cardinal;        { running index in l_buf }
 code : cardinal;      { the code to send }
 extra : integer;          { number of extra bits to send }
begin
 lx := 0;
 if (fLastLit <> 0) then
  repeat
   dist := FBuf.Dis[lx];
   lc := FBuf.Lit[lx];
   inc(lx);
   if (dist = 0) then
    SendBits(ltree[lc,TREE_CODE], ltree[lc,TREE_LEN])
   else begin
   { Here, lc is the match length - MIN_MATCH }
    code := _length_code[lc];
   { send the length code }
    SendBits(ltree[code+LITERALS+1,TREE_CODE], ltree[code+LITERALS+1,TREE_LEN]);
    extra := extra_lbits[code];
    if (extra <> 0) then begin
     dec(lc, base_length[code]);
     SendBits(lc, extra);       { send the extra length bits }
    end;
    dec(dist); { dist is now the match distance - 1 }
    if (dist < 256) then
     code := _dist_code[dist]
    else
     code := _dist_code[256+(dist shr 7)];
   { send the distance code }
    SendBits(dtree[code,TREE_CODE], dtree[code,TREE_LEN]);
    extra := extra_dbits[code];
    if (extra <> 0) then begin
     dec(dist, base_dist[code]);
     SendBits(dist, extra);   { send the extra distance bits }
    end;
   end; { literal or match pair ? }
  { Check that the overlay between pending_buf and d_buf+l_buf is ok: }
  Assert(Cardinal(FPending) < LIT_BUF_SIZE + 2 * lx, 'pendingBuf overflow');
  until (lx >= fLastLit);
 SendBits(ltree[END_BLOCK,TREE_CODE], ltree[END_BLOCK,TREE_LEN]);
end;

procedure THuffmanTrees.SendAllTrees(lcodes, dcodes, blcodes : integer);
var
 rank : integer;                    { index in bl_order }
begin
 SendBits(lcodes-257, 5); { not +255 as stated in appnote.txt }
 SendBits(dcodes-1,   5);
 SendBits(blcodes-4,  4); { not -3 as stated in appnote.txt }
 for rank := 0 to blcodes-1 do
  SendBits(fBitLenTree[bl_order[rank],TREE_LEN], 3);
 SendTree(fLitTree, lcodes-1); { literal tree }
 SendTree(fDisTree, dcodes-1); { distance tree }
end;

procedure THuffmanTrees.SendTree(const tree : array of ct_data; max_code : integer);
var
 n : integer;                { iterates over all tree elements }
 prevlen : integer;          { last emitted length }
 curlen : integer;           { length of current code }
 nextlen : integer;          { length of next code }
 count : integer;            { repeat count of the current code }
 max_count : integer;        { max repeat count }
 min_count : integer;        { min repeat count }
begin
 prevlen := -1;
 nextlen := tree[0,TREE_LEN];
 count := 0;
 max_count := 7;
 min_count := 4;
 if (nextlen = 0) then begin
  max_count := 138;
  min_count := 3;
 end;
 for n := 0 to max_code do begin
  curlen := nextlen;
  nextlen := tree[n+1,TREE_LEN];
  inc(count);
  if (count < max_count) and (curlen = nextlen) then
   continue
  else
  if (count < min_count) then begin
   repeat
    SendBits(fBitLenTree[curlen,TREE_CODE], fBitLenTree[curlen,TREE_LEN]);
    dec(count);
   until (count = 0);
  end else
  if (curlen <> 0) then begin
   if (curlen <> prevlen) then begin
    SendBits(fBitLenTree[curlen,TREE_CODE], fBitLenTree[curlen,TREE_LEN]);
    dec(count);
   end;
   SendBits(fBitLenTree[REP_3_6,TREE_CODE], fBitLenTree[REP_3_6,TREE_LEN]);
   SendBits(count-3, 2);
  end else
  if (count <= 10) then begin
   SendBits(fBitLenTree[REPZ_3_10,TREE_CODE], fBitLenTree[REPZ_3_10,TREE_LEN]);
   SendBits(count-3, 3);
  end else begin
   SendBits(fBitLenTree[REPZ_11_138,TREE_CODE], fBitLenTree[REPZ_11_138,TREE_LEN]);
   SendBits(count-11, 7);
  end;
  count := 0;
  prevlen := curlen;
  if (nextlen = 0) then begin
   max_count := 138;
   min_count := 3;
  end else
  if (curlen = nextlen) then begin
   max_count := 6;
   min_count := 3;
  end else begin
   max_count := 7;
   min_count := 4;
  end;
 end;
end;


function THuffmanTrees.BuildTree(var tree: array of ct_data;
  const stree: array of ct_data; max_length, base: integer;
  const extra: array of integer): integer;
var
  elems : integer;
  n, m : integer;          { iterate over heap elements }
  max_code : integer;      { largest code with non zero frequency }
  node : integer;          { new node being created }
begin
  elems := base + length(extra);
  max_code := -1;
  { Construct the initial heap, with least frequent element in
    heap[SMALLEST]. The sons of heap[n] are heap[2*n] and heap[2*n+1].
    heap[0] is not used. }
  fHeapLen := 0;
  fHeapMax := HEAP_SIZE;
  for n := 0 to elems-1 do 
    if (tree[n,TREE_FREQ] = 0) then
      tree[n,TREE_LEN] := 0
    else begin
      max_code := n;
      Inc(fHeapLen);
      fHeap[fHeapLen] := n;
      fDepth[n] := 0;
    end;

  { The pkzip format requires that at least one distance code exists,
    and that at least one bit should be sent even if there is only one
    possible code. So to avoid special checks later on we force at least
    two codes of non zero frequency. }

  while (fHeapLen < 2) do begin
    Inc(fHeapLen);
    if (max_code < 2) then begin
      Inc(max_code);
      fHeap[fHeapLen] := max_code;
      node := max_code;
    end else begin
      fHeap[fHeapLen] := 0;
      node := 0;
    end;
    tree[node,TREE_FREQ] := 1;
    fDepth[node] := 0;
    Dec(fOptLen);
    if length(stree)>0 then
      Dec(fStaticLen, stree[node,TREE_LEN]);
    { node is 0 or 1 so it does not have extra bits }
  end;
  Result := max_code;

  { The elements heap[heap_len/2+1 .. heap_len] are leaves of the tree,
    establish sub-heaps of increasing lengths: }
  for n := fHeapLen div 2 downto 1 do
    PQDownHeap(tree, n);

  { Construct the Huffman tree by repeatedly combining the least two
    frequent nodes. }

  node := elems;              { next internal node of the tree }
  repeat
    {pqremove(s, tree, n);}  { n := node of least frequency }
    n := fHeap[SMALLEST];
    fHeap[SMALLEST] := fHeap[fHeapLen];
    Dec(fHeapLen);
    PQDownHeap(tree, SMALLEST);

    m := fHeap[SMALLEST]; { m := node of next least frequency }

    Dec(fHeapMax);
    fHeap[fHeapMax] := n; { keep the nodes sorted by frequency }
    Dec(fHeapMax);
    fHeap[fHeapMax] := m;

    { Create a new node father of n and m }
    tree[node,TREE_FREQ] := tree[n,TREE_FREQ] + tree[m,TREE_FREQ];
    { maximum }
    if (fDepth[n] >= fDepth[m]) then
      fDepth[node] := byte (fDepth[n] + 1)
    else
      fDepth[node] := byte (fDepth[m] + 1);

    tree[m,TREE_DAD] := word(node);
    tree[n,TREE_DAD] := word(node);
    { and insert the new node in the heap }
    fHeap[SMALLEST] := node;
    Inc(node);
    PQDownHeap(tree, SMALLEST);
  until (fHeapLen < 2);
  dec(fHeapMax);
  fHeap[fHeapMax] := fHeap[SMALLEST];
  { At this point, the fields freq and dad are set. We can now
    generate the bit lengths. }
  GenBitLen(tree, stree, max_code, max_length, base, extra);
  { The field len is now set, we can generate the bit codes }
  GenCodes(tree, max_code);
end;

procedure THuffmanTrees.PQDownHeap(var tree: array of ct_data; k: integer);
var
  v : integer;
  j : integer;
begin
  v := fHeap[k];
  j := k shl 1;  { left son of k }
  while (j <= fHeapLen) do
  begin
    { Set j to the smallest of the two sons: }
    if (j < fHeapLen) and
      ( (tree[fHeap[j+1],TREE_FREQ] < tree[fHeap[j],TREE_FREQ]) or
        ((tree[fHeap[j+1],TREE_FREQ] = tree[fHeap[j],TREE_FREQ]) and
         (fDepth[fHeap[j+1]] <= fDepth[fHeap[j]])) ) then
      Inc(j);
    { Exit if v is smaller than both sons }
    if ( (tree[v,TREE_FREQ] < tree[fHeap[j],TREE_FREQ]) or
       ((tree[v,TREE_FREQ] = tree[fHeap[j],TREE_FREQ]) and
        (fDepth[v] <= fDepth[fHeap[j]])) ) then
      break;
    { Exchange v with the smallest son }
    fHeap[k] := fHeap[j];
    k := j;
    { And continue down the tree, setting j to the left son of k }
    j := j shl 1;
  end;
  fHeap[k] := v;
end;
procedure THuffmanTrees.ScanTree(var tree: array of ct_data;
  max_code: integer);
var
  n : integer;                 { iterates over all tree elements }
  prevlen : integer;           { last emitted length }
  curlen : integer;            { length of current code }
  nextlen : integer;           { length of next code }
  count : integer;             { repeat count of the current code }
  max_count : integer;         { max repeat count }
  min_count : integer;         { min repeat count }
begin
  prevlen := -1;
  nextlen := tree[0,TREE_LEN];
  count := 0;
  max_count := 7;
  min_count := 4;
  if (nextlen = 0) then
  begin
    max_count := 138;
    min_count := 3;
  end;
  tree[max_code+1,TREE_LEN] := word($ffff); { guard }

  for n := 0 to max_code do
  begin
    curlen := nextlen;
    nextlen := tree[n+1,TREE_LEN];
    Inc(count);
    if (count < max_count) and (curlen = nextlen) then
      continue
    else
      if (count < min_count) then
        Inc(fBitLenTree[curlen,TREE_FREQ], count)
      else
        if (curlen <> 0) then
        begin
          if (curlen <> prevlen) then
            Inc(fBitLenTree[curlen,TREE_FREQ]);
          Inc(fBitLenTree[REP_3_6,TREE_FREQ]);
        end
        else
          if (count <= 10) then
            Inc(fBitLenTree[REPZ_3_10,TREE_FREQ])
          else
            Inc(fBitLenTree[REPZ_11_138,TREE_FREQ]);

    count := 0;
    prevlen := curlen;
    if (nextlen = 0) then
    begin
      max_count := 138;
      min_count := 3;
    end
    else
      if (curlen = nextlen) then
      begin
        max_count := 6;
        min_count := 3;
      end
      else
      begin
        max_count := 7;
        min_count := 4;
      end;
  end;
end;

procedure THuffmanTrees.GenBitLen(var tree: array of ct_data;
  const stree: array of ct_data; max_code, max_length, base: integer;
  const extra: array of integer);
var
  h : integer;              { heap index }
  n, m : integer;           { iterate over the tree elements }
  bits : integer;           { bit length }
  xbits : integer;          { extra bits }
  f : word;              { frequency }
  overflow : integer;   { number of elements with bit length too large }
begin
  overflow := 0;

  FillChar(fBitLenCount,SizeOf(fBitLenCount),0);

  { In a first pass, compute the optimal bit lengths (which may
    overflow in the case of the bit length tree). }

  tree[fHeap[fHeapMax],TREE_LEN] := 0; { root of the heap }

  for h := fHeapMax+1 to HEAP_SIZE-1 do
  begin
    n := fHeap[h];
    bits := tree[tree[n,TREE_DAD],TREE_LEN] + 1;
    if (bits > max_length) then
    begin
      bits := max_length;
      Inc(overflow);
    end;
    tree[n,TREE_LEN] := word(bits);
    { We overwrite tree[n,TREE_DAD] which is no longer needed }

    if (n > max_code) then
      continue; { not a leaf node }

    Inc(fBitLenCount[bits]);
    xbits := 0;
    if (n >= base) then
      xbits := extra[n-base];
    f := tree[n,TREE_FREQ];
    Inc(fOptLen, cardinal(f) * cardinal(bits + xbits));
    if length(stree)>0 then
      Inc(fStaticLen, cardinal(f) * cardinal(stree[n,TREE_LEN] + xbits));
  end;
  if (overflow = 0) then
    exit;

  { Find the first bit length which could increase: }
  repeat
    bits := max_length-1;
    while (fBitLenCount[bits] = 0) do
      Dec(bits);
    Dec(fBitLenCount[bits]);      { move one leaf down the tree }
    Inc(fBitLenCount[bits+1], 2); { move one overflow item as its brother }
    Dec(fBitLenCount[max_length]);
    { The brother of the overflow item also moves one step up,
      but this does not affect bl_count[max_length] }

    Dec(overflow, 2);
  until (overflow <= 0);

  { Now recompute all bit lengths, scanning in increasing frequency.
    h is still equal to HEAP_SIZE. (It is simpler to reconstruct all
    lengths instead of fixing only the wrong ones. This idea is taken
    from 'ar' written by Haruhiko Okumura.) }
  h := HEAP_SIZE;  { Delphi3: compiler warning w/o this }
  for bits := max_length downto 1 do
  begin
    n := fBitLenCount[bits];
    while (n <> 0) do
    begin
      Dec(h);
      m := fHeap[h];
      if (m > max_code) then
        continue;
      if (tree[m,TREE_LEN] <> cardinal(bits)) then
      begin
        Inc(fOptLen, (integer(bits) - integer(tree[m,TREE_LEN]))
                        * integer(tree[m,TREE_FREQ]) );
        tree[m,TREE_LEN] := word(bits);
      end;
      Dec(n);
    end;
  end;
end;

procedure THuffmanTrees.GenCodes(var tree: array of ct_data;
  max_code: integer);
var
  next_code : array[0..MAX_BITS+1-1] of word; { next code value for each bit length }
  code : word;              { running code value }
  bits : integer;                  { bit index }
  n : integer;                     { code index }
var
  len : integer;
begin
  code := 0;

  { The distribution counts are first used to generate the code values
    without bit reversal. }

  for bits := 1 to MAX_BITS do
  begin
    code := ((code + fBitLenCount[bits-1]) shl 1);
    next_code[bits] := code;
  end;
  { Check that the bit counts in bl_count are consistent. The last code
    must be all ones. }

  for n := 0 to max_code do
  begin
    len := tree[n,TREE_LEN];
    if (len = 0) then
      continue;
    { Now reverse the bits }
    tree[n,TREE_CODE] := bi_reverse(next_code[len], len);
    Inc(next_code[len]);
  end;
end;

{ TDeflateState}

procedure TDeflateState.FlushPending;
begin
  FStream.Write(FBuf.Pending, FPending);
  FPending := 0;
end;

procedure TDeflateState.PutWord(Value: Word);
begin
  FBuf.Pending[FPending] := Value shr 8;
  Inc(FPending);
  FBuf.Pending[FPending] := Value;
  Inc(FPending);
end;

procedure TDeflateState.PutLong(value:cardinal);
begin
 PutWord(value shr 16);
 PutWord(word(value));
end;

procedure TDeflateState.FillWindow;
var
 n, m : cardinal;
 p    : pword;
 more : cardinal;    { Amount of free space at the end of the window. }
 wsize: cardinal;
begin
 wsize := WINDOW_SIZE;
 repeat
  more := 2*WINDOW_SIZE - fLookahead - fStrStart;
  if (fStrStart >= wsize+ (wsize-MIN_LOOKAHEAD)) then begin
   move(fWindow[wsize],fWindow,wsize);
   dec(fMatchStart, wsize);
   dec(fStrStart, wsize); { we now have strstart >= MAX_DIST }
   dec(fBlockStart, wsize);

   p := @fHead[0];
   for n:=0 to HASH_SIZE-1 do begin
    m:=p^;
    if m>=wsize then p^:=m-wsize else p^:=0;
    inc(p);
   end;
   p:=@fPrev[0];
   for n:=0 to wsize-1 do begin
    m:=p^;
    if m>=wsize then p^:=m-wsize else p^:=0;
    inc(p);
   end;
   inc(more, wsize);
  end;
  n := fStream.Read(fWindow[fStrStart + fLookahead],more);
  if n=0 then exit;
  fAdler := adler32(fAdler,pbyte(@(fWindow[fStrStart + fLookahead])), n);
  inc(fLookahead, n);
  { Initialize the hash value now that we have some input: }
  if (fLookahead >= MIN_MATCH) then begin
   fHashIndex := fWindow[fStrStart];
   fHashIndex := ((fHashIndex shl HASH_SHIFT) xor fWindow[fStrStart+1]) and HASH_MASK;
  end;
 until (fLookahead >= MIN_LOOKAHEAD);
end;

procedure TDeflateState.InsertString(var match_head:cardinal);
begin
 fHashIndex := ((fHashIndex shl HASH_SHIFT) xor (fWindow[(fStrStart) + (MIN_MATCH-1)])) and HASH_MASK;
 match_head := fHead[fHashIndex];
 fPrev[fStrStart and WINDOW_MASK] := match_head;
 fHead[fHashIndex] := fStrStart;
end;

function TDeflateState.LongestMatch(cur_match : cardinal):cardinal;
var
  chain_len : cardinal;    { max hash chain length }
  scan      : pchar;   { current string }
  match     : pchar;  { matched string }
  len       : integer;       { length of current match }
  best_len  : integer;             { best match length so far }
  nicematch : integer;           { stop if match long enough }
  limit     : cardinal;
  strend    : pchar;
  scan_end1 : char;
  scan_end  : char;
  MAX_DIST  : cardinal;
begin
  chain_len := MAX_CHAIN_LENGTH; { max hash chain length }
  scan := @(fWindow[fStrStart]);
  best_len := fPrevLength;              { best match length so far }
  nicematch := NICE_MATCH;             { stop if match long enough }
  MAX_DIST := WINDOW_SIZE - MIN_LOOKAHEAD;
  if fStrStart > MAX_DIST then
    limit := fStrStart - MAX_DIST
  else
    limit := 0;
  strend := @(fWindow[fStrStart + MAX_MATCH]);
  scan_end1  := scan[best_len-1];
  scan_end   := scan[best_len];
 { Do not waste too much time if we already have a good match: }
  if (fPrevLength >= GOOD_MATCH) then
   chain_len := chain_len shr 2;
 { Do not look for matches beyond the end of the input. This is necessary
   to make deflate deterministic. }
  if (cardinal(nicematch) > fLookahead) then
   nicematch := fLookahead;
  repeat
   match := @(fWindow[cur_match]);
  { Skip to next match if the match length cannot increase
    or if the match length is less than 2: }
   if (match^ = scan^)
   and(match[best_len]   = scan_end)
   and(match[best_len-1] = scan_end1) then begin
    inc(match);
    if (match^ = scan[1]) then begin
    { The check at best_len-1 can be removed because it will be made
      again later. (This heuristic is not always a win.)
      It is not necessary to compare scan[2] and match[2] since they
      are always equal when the other bytes match, given that
      the hash keys are equal and that HASH_BITS >= 8. }
     inc(scan, 2);
     inc(match);
    { We check for insufficient lookahead only every 8th comparison;
      the 256th check will be made at strstart+258. }
     repeat
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
      inc(scan); inc(match); if (scan^ <> match^) then break;
     until (cardinal(scan) >= cardinal(strend));
     len := MAX_MATCH - integer(cardinal(strend) - cardinal(scan));
     scan := strend;
     dec(scan, MAX_MATCH);
     if (len > best_len) then begin
      fMatchStart := cur_match;
      best_len := len;
      if (len >= nicematch) then break;
      scan_end1  := scan[best_len-1];
      scan_end   := scan[best_len];
     end;
    end; 
   end;
   cur_match := fPrev[cur_match and WINDOW_MASK];
   dec(chain_len);
  until (cur_match <= limit) or (chain_len = 0);

  if (cardinal(best_len) <= fLookahead) then
   Result := best_len
  else
   Result := fLookahead;
end;

procedure TDeflateState.FlushBlockOnly(eof : boolean);
begin
  if fBlockStart>=0 then
   FlushBlock(pbyte(@fWindow[fBlockStart]), fStrStart - cardinal(fBlockStart), eof)
  else
   FlushBlock(nil,fStrStart +cardinal(-fBlockStart),eof);
  fBlockStart := fStrStart;
  FlushPending;
end;


procedure TDeflateState.Compress(Stream: TCustomDeflateStream);
var
  header : Cardinal;
  level_flags : Cardinal;
  hash_head : Cardinal;       { head of hash chain }
  bflush : Boolean;       { set if current block must be flushed }
  max_insert : Cardinal;

  prev_match : Cardinal;
  match_length    : cardinal;
  match_available : boolean;
begin
 FStream:=Stream;

{ Initialize the first block of the first file: }
 fLitTree[END_BLOCK,TREE_FREQ] := 1;

 fPrevLength  := MIN_MATCH-1;
 match_length := MIN_MATCH-1;

{ Write the zlib header }
 header := Z_HEADER;
 level_flags := (COMPRESS_LEVEL-1) shr 1;
 if (level_flags > 3) then level_flags := 3;
 header := header or (level_flags shl 6);
 inc(header, 31 - (header mod 31));
 PutWord(header);
 fAdler := 1;
 FlushPending;

{ Start a new block  }
 hash_head := 0;
 match_available:=false;

{ Process the input block. }
 while True do begin
  if (fLookahead < MIN_LOOKAHEAD) then begin
    FillWindow;
    if fLookahead = 0 then break;
  end;

 { Insert the string window[strstart .. strstart+2] in the
   dictionary, and set hash_head to the head of the hash chain: }

  if (fLookahead >= MIN_MATCH) then InsertString(hash_head);

 { Find the longest match, discarding those <= prev_length. }

  fPrevLength := match_length;
  prev_match := fMatchStart;
  match_length := MIN_MATCH-1;

  if (hash_head <> 0) and (fPrevLength < MAX_LAZY_MATCH)
  and(fStrStart - hash_head <= (WINDOW_SIZE-MIN_LOOKAHEAD)) then begin
   match_length := LongestMatch(hash_head);
   if (match_length <= 5) and ((match_length = MIN_MATCH) and (fStrStart - fMatchStart > TOO_FAR)) then
    match_length := MIN_MATCH-1;
  end;

  if (fPrevLength >= MIN_MATCH) and (match_length <= fPrevLength) then begin
   max_insert := fStrStart + fLookahead - MIN_MATCH;
  { Do not insert strings in hash table beyond this. }
   bflush := Tally(fStrStart -1 - prev_match, fPrevLength - MIN_MATCH);

  { Insert in hash table all strings up to the end of the match.
    strstart-1 and strstart are already inserted. If there is not
    enough lookahead, the last two strings are not inserted in
    the hash table. }
   dec(fLookahead, fPrevLength-1);
   dec(fPrevLength, 2);
   repeat
    inc(fStrStart);
    if (fStrStart <= max_insert) then InsertString(hash_head);
    dec(fPrevLength);
   until (fPrevLength = 0);
   match_available := FALSE;
   match_length := MIN_MATCH-1;
   inc(fStrStart);

   if (bflush) then FlushBlockOnly(FALSE);
  end else
   if (match_available) then begin
    bflush := Tally ( 0, fWindow[fStrStart-1]);
    if bflush then FlushBlockOnly(FALSE);
    inc(fStrStart);
    dec(fLookahead);
   end else begin
    match_available := TRUE;
    inc(fStrStart);
    dec(fLookahead);
   end;
 end;
 if (match_available) then
  Tally ( 0, fWindow[fStrStart-1]);
 FlushBlockOnly(TRUE);
{ Write the zlib trailer (adler32) }
 PutLong(fAdler);
 FlushPending;
end;

function zCompressStr(const Str:string):string;
var
 d:TDeflateString;
begin
 d:=TDeflateString.Create;
 try
  Result:=d.Compress(Str);
 finally
  d.Free;
 end;
end;

end.



