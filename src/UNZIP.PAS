unit Unzip;
{$I-,R-,Q-}
{ Unzips deflated, imploded, shrunk and stored files }

{
  Original version (1.x): Christian Ghisler
   C code by info-zip group, translated to pascal by Christian Ghisler
   based on unz51g.zip;
   Special thanks go to Mark Adler,who wrote the main inflate and
   explode code, and did NOT copyright it!!!

 v2.00: March 1998: Dr Abimbola Olowofoyeku (The African Chief)
        Homepage: http://ourworld.compuserve.com/homepages/African_Chief
   * modified to compile for Delphi v2.x and Delphi v3.x

 v2.01: April 1998: Dr Abimbola Olowofoyeku (The African Chief)
   * source files merged into a single source (this) file
   * several high level functions added - i.e.,
              FileUnzip()
              FileUnzipEx()
              ViewZip()
              UnzipSize()
              SetUnzipReportProc()
              SetUnzipQuestionProc()
              ChfUnzip_Init()
   * callbacks added
   * modified to support Virtual Pascal v2.0 (Win32)
   * Delphi component added (chfunzip.pas)

  v2.02: May 1998: Dr Abimbola Olowofoyeku
   * Functionality to make subdirectory recursion optional added
        "SetNoRecurseDirs"
   * Support for Free Pascal (FPC) added (by Peter Vreman)

   V2.03: June 1998: Dr Abimbola Olowofoyeku
   * STDCALL added for all Win32 platforms

   V2.04: June 1998: Dr Abimbola Olowofoyeku
   * support for OS/2 added (Virtual Pascal 2.0)
   * several amendments to UNZIP.INC

   V2.05: June 1998: Dr Abimbola Olowofoyeku
   * fixed to support OS/2 DLLs
   * minor enhancements to MATCH.PAS

   v3.00: September 2000 : Paul TOTH
   * Remove a lot of things to keep a single Delphi Unit to "just" unzip a Stream (File/Memory/Resource)
   * Replace PChar by String
   * Replace File by TStream
   * added high level functions
     UnZipAll
     UnZipAllFromFile
     UnZipAllFromResName

     (you can install BDE from a ZIPed Resource - for Paradox only :

      IDAPI32  DLL
      CHARSET  CVB
      CEEUROPE BTL
      EUROPE   BTL
      IDAPI32  CFG
      BANTAM   DLL
      IDPDX32  DLL
      IDR2000C DLL
      ------------
      BDE32    ZIP  -->  572,128
     )

    v3.01: November 2000 : Paul TOTH
    * locatation of PK56 was wrong

    v3.10: Jav. 2001 - Paul TOTH
    * New version of GetFirst/NextInZip for archives with "a lot of files"

}

interface

uses
  Windows, Classes;//, Messages, Sysutils;

CONST {stored, shrunk, imploded and deflated}
  SupportedMethods = 1 + ( 1 SHL 1 ) + ( 1 SHL 6 ) + ( 1 SHL 8 );

CONST {Error codes returned by the main unzip functions}
  unzip_Ok             =   0;
  unzip_CRCErr         = - 1;
  unzip_WriteErr       = - 2;
  unzip_ReadErr        = - 3;
  unzip_ZipFileErr     = - 4;
//  unzip_UserAbort      = - 5;
  unzip_NotSupported   = - 6;
  unzip_Encrypted      = - 7;
//  unzip_InUse          = - 8;
  unzip_InternalError  = - 9;    {Error in zip format}
  unzip_NoMoreItems    = - 10;
  unzip_FileError      = - 11;   {Error Accessing file}
  unzip_NotZipfile     = - 12;   {not a zip file}
  unzip_SeriousError   = - 100;  {serious error}
  unzip_MissingParameter = - 500; {missing parameter}

CONST
 tBufSize  = 256 * 1024;   {buffer size}
 BufDefault= 4096;

Type
{$IFNDEF UNICODE}
  RawByteString = string;
{$ENDIF}
 buftype  = ARRAY [ 0..tBufSize ] of AnsiChar;

 TFileHeader=packed record
  Signature :integer;// central file header signature   4 bytes  (0x02014b50)
  VerMadeBy :word;   // version made by                 2 bytes
  VerNeeded :word;   // version needed to extract       2 bytes
  Flags     :word;   // general purpose bit flag        2 bytes
  Method    :word;   // compression method              2 bytes
  DateTime  :integer;// last mod file time              2 bytes
                     // last mod file date              2 bytes
  CRC32     :integer;// crc-32                          4 bytes
  CompSize  :integer;// compressed size                 4 bytes
  RealSize  :integer;// uncompressed size               4 bytes
  NameLen   :word;   // filename length                 2 bytes
  ExtraLen  :word;   // extra field length              2 bytes
  CommentLen:word;   // file comment length             2 bytes
  DiskStart :word;   // disk number start               2 bytes
  iFileAttr :word;   // internal file attributes        2 bytes
  eFileAttr :integer;// external file attributes        4 bytes
  HeaderPos :integer;// relative offset of local header 4 bytes
  // filename (variable size)
  // extra field (variable size)
  // file comment (variable size)
  END;

 TZipRec = PACKED RECORD
  buf : RawByteString;          {buffer containing central dir}
  bufsize,               {size of buffer}
  localstart : word;     {start pos in buffer}
  Time,Size,CompressSize,headeroffset : Longint;
  Attr : Byte;
 // Paul TOTH
  Stream     :TStream;
  MainHeader :integer;
  Comment    : RawByteString;
  FileOffset :integer; // First FileHeader offset
  FileCount  :integer;
  FileIndex  :integer;
  FileHeader :TFileHeader;
  FileName   :RawByteString;
//EtraFields :string;
  FileComment:RawByteString;
 END; { TZipRec }


Function FindZipName(ZipStream:TStream; FileName:string):integer;
Function UnZipStream(ZipStream,OutStream:TStream):integer;
Function UnZipAll(AStream:TStream; OutPath:string): Boolean;
Function UnZipAllFromFile(AFileName:string; OutPath:string): Boolean;
Function UnZipAllFromResName(AResourceName:string; OutPath:string): Boolean;

FUNCTION UnZipFile(AStream:TStream; out_name : string ;offset : longint) : integer;

FUNCTION  GetFirstInZip(AStream:TStream;Var Zprec:TZipRec):integer;
FUNCTION  GetNextInZip (Var Zprec:tZiprec): integer;
PROCEDURE CloseZipFile (Var Zprec:tZiprec); {Only free buffer, file only open in Getfirstinzip}

IMPLEMENTATION

(*****SYSUTILS.PAS*****)
function StrScan(Str: PAnsiChar; Chr: AnsiChar): PAnsiChar; assembler;
asm
        PUSH    EDI
        PUSH    EAX
        MOV     EDI,Str
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        POP     EDI
        MOV     AL,Chr
        REPNE   SCASB
        MOV     EAX,0
        JNE     @@1
        MOV     EAX,EDI
        DEC     EAX
@@1:    POP     EDI
end;

function ExtractFileName(const FileName: string): string;
var
  I: Integer;
begin
  I := Length(FileName);
  while (I > 0) and not (FileName[I] in ['\', ':']) do Dec(I);
  Result := Copy(FileName, I + 1, 255);
end;
(********************)


const
 PK56=$06054B50; // 'PK'#5#6 = End of central dir record
 PK12=$02014B50; // 'PK'#1#2 = Central directory structure
 PK34=$04034B50; // 'PK'#3#4 = Local file header
 //$CA0F9E

{*************************************************************************}

CONST   {Error codes returned by huft_build}
  huft_complete  = 0;   {Complete tree}
  huft_incomplete = 1;  {Incomplete tree <- sufficient in some cases!}
  huft_error     = 2;   {bad tree constructed}
  huft_outofmem  = 3;   {not enough memory}
  MaxMax = 256 * 1024;   {32-bits =  256kb buffer}

CONST SlideSize = $8000;   {Size of sliding dictionary}
      INBUFSIZ = 1024 * 4; {Size of input buffer}

CONST lbits : integer = 9;
      dbits : integer = 6;

CONST b_max = 16;
      n_max = 288;
      BMAX = 16;

TYPE push = ^ush;
     ush = word;
     pbyte = ^byte;
     pushlist = ^ushlist;
     ushlist = ARRAY [ 0..maxmax ] of ush;  {only pseudo-size!!}
     pword = ^word;
     pwordarr = ^twordarr;
     twordarr = ARRAY [ 0..maxmax ] of word;
     iobuf = ARRAY [ 0..inbufsiz - 1 ] of byte;

TYPE pphuft = ^phuft;
     phuft = ^huft;
     phuftlist = ^huftlist;
     huft = PACKED RECORD
       e,             {# of extra bits}
       b : byte;        {# of bits in code}
       v_n : ush;
       v_t : phuftlist; {Linked List}
     END;
     huftlist = ARRAY [ 0..8190 ] of huft;

TYPE li = PACKED RECORD
       lo, hi : word;
     END;

{pkzip header in front of every file in archive}
TYPE
  plocalheader = ^tlocalheader;
  tlocalheader = PACKED RECORD
    signature : longint; // local file header signature 'PK'#1#2
    version   : word;    // version needed to extract
    flags     : word;    // general purpose bit flag
    method    : word;    // compression method
    timedate  : longint; // last mod file
    crc_32    : longint;
    compress_size,
    uncompress_size : longint;
    filename_len,
    extra_field_len : word;
   // filename[]
   // extrafield[]
  END;

VAR slide : PAnsiChar;            {Sliding dictionary for unzipping}
    inbuf : iobuf;            {input buffer}
    inpos, readpos : integer;  {position in input buffer, position read from file}

VAR w : word;                 {Current Position in slide}
    b : longint;              {Bit Buffer}
    k : byte;                 {Bits in bit buffer}
    infile : TStream;       {handle to zipfile}
    outfile: TStream;       {handle to extracted file}
    compsize,               {comressed size of file}
    reachedsize,            {number of bytes read from zipfile}
    uncompsize : longint;     {uncompressed size of file}
  //  oldpercent : integer;     {last percent value shown}
    crc32val : longint;       {crc calculated from data}
    hufttype : word;          {coding type=bit_flag from header}
    zipeof : boolean;         {read over end of zip section for this file}


(***************************************************************************)
{b and mask_bits[i] gets lower i bits out of i}
CONST mask_bits : ARRAY [ 0..16 ] of word =
   ( $0000, $0001, $0003, $0007, $000f, $001f, $003f, $007f, $00ff,
    $01ff, $03ff, $07ff, $0fff, $1fff, $3fff, $7fff, $ffff );

{ Tables for deflate from PKZIP's appnote.txt. }

CONST border : ARRAY [ 0..18 ] of byte =   { Order of the bit length code lengths }
        ( 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 );
CONST cplens : ARRAY [ 0..30 ] of word =    { Copy lengths for literal codes 257..285 }
        ( 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
        35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 0, 0 );
        { note: see note #13 above about the 258 in this list.}
CONST cplext : ARRAY [ 0..30 ] of word =    { Extra bits for literal codes 257..285 }
        ( 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
        3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, 99, 99 ); { 99==invalid }
CONST cpdist : ARRAY [ 0..29 ] of word =     { Copy offsets for distance codes 0..29 }
        ( 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
        257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
        8193, 12289, 16385, 24577 );
CONST cpdext : ARRAY [ 0..29 ] of word =    { Extra bits for distance codes }
        ( 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
        7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
        12, 12, 13, 13 );

{ Tables for explode }

CONST cplen2 : ARRAY [ 0..63 ] of word = ( 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
        18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
        35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65 );
CONST cplen3 : ARRAY [ 0..63 ] of word = ( 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
        19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
        53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66 );
CONST extra : ARRAY [ 0..63 ] of word = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        8 );
CONST cpdist4 : ARRAY [ 0..63 ] of word = ( 1, 65, 129, 193, 257, 321, 385, 449, 513, 577, 641, 705,
        769, 833, 897, 961, 1025, 1089, 1153, 1217, 1281, 1345, 1409, 1473,
        1537, 1601, 1665, 1729, 1793, 1857, 1921, 1985, 2049, 2113, 2177,
        2241, 2305, 2369, 2433, 2497, 2561, 2625, 2689, 2753, 2817, 2881,
        2945, 3009, 3073, 3137, 3201, 3265, 3329, 3393, 3457, 3521, 3585,
        3649, 3713, 3777, 3841, 3905, 3969, 4033 );
CONST cpdist8 : ARRAY [ 0..63 ] of word = ( 1, 129, 257, 385, 513, 641, 769, 897, 1025, 1153, 1281,
        1409, 1537, 1665, 1793, 1921, 2049, 2177, 2305, 2433, 2561, 2689,
        2817, 2945, 3073, 3201, 3329, 3457, 3585, 3713, 3841, 3969, 4097,
        4225, 4353, 4481, 4609, 4737, 4865, 4993, 5121, 5249, 5377, 5505,
        5633, 5761, 5889, 6017, 6145, 6273, 6401, 6529, 6657, 6785, 6913,
        7041, 7169, 7297, 7425, 7553, 7681, 7809, 7937, 8065 );

{************************************ CRC-Calculation ************************************}

CONST crc_32_tab : ARRAY [ 0..255 ] of dword =
(
   $00000000, $77073096, $ee0e612c, $990951ba, $076dc419,
   $706af48f, $e963a535, $9e6495a3, $0edb8832, $79dcb8a4,
   $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,
   $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de,
   $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7, $136c9856,
   $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
   $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
   $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
   $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3,
   $45df5c75, $dcd60dcf, $abd13d59, $26d930ac, $51de003a,
   $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599,
   $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
   $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190,
   $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
   $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e,
   $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
   $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed,
   $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
   $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3,
   $fbd44c65, $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2,
   $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
   $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5,
   $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa, $be0b1010,
   $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
   $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17,
   $2eb40d81, $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6,
   $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615,
   $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
   $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344,
   $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
   $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a,
   $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
   $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1,
   $a6bc5767, $3fb506dd, $48b2364b, $d80d2bda, $af0a1b4c,
   $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
   $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
   $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe,
   $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31,
   $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c,
   $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
   $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b,
   $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
   $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1,
   $18b74777, $88085ae6, $ff0f6a70, $66063bca, $11010b5c,
   $8f659eff, $f862ae69, $616bffd3, $166ccf45, $a00ae278,
   $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7,
   $4969474d, $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66,
   $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
   $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
   $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8,
   $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b,
   $2d02ef8d ); { end crc_32_tab[] }
{*********************************** CRC Checking ********************************}

PROCEDURE UpdateCRC ( VAR s : iobuf;len : integer );
VAR i : integer;
BEGIN
 FOR i := 0 TO Pred ( len ) DO BEGIN
    { update running CRC calculation with contents of a buffer }
    crc32val := integer(crc_32_tab [  ( byte ( crc32val ) XOR s [ i ] ) AND $ff ]) XOR ( crc32val SHR 8 );
  END;
END;

{************************** fill inbuf from infile *********************}

PROCEDURE readbuf;
BEGIN
  IF reachedsize > compsize + 2 THEN BEGIN {+2: last code is smaller than requested!}
    readpos := sizeof ( inbuf ); {Simulates reading -> no blocking}
    zipeof := TRUE
  END ELSE BEGIN
    readpos:=infile.read(inbuf,sizeof(inbuf));
    IF ( readpos = 0 ) THEN BEGIN  {readpos=0: kein Fehler gemeldet!!!}
      readpos := sizeof ( inbuf ); {Simulates reading -> CRC error}
      zipeof := TRUE;
    END;
    inc ( reachedsize, readpos );
    dec ( readpos );    {Reason: index of inbuf starts at 0}
  END;
  inpos := 0;
END;

{**** read byte, only used by explode ****}
Procedure ReadByte(var bt:byte);
begin
 if inpos>readpos then readbuf;
 bt:=inbuf[inpos];
 inc(inpos);
end;

{*********** read at least n bits into the global variable b *************}
Procedure NEEDBITS(n:byte);
Var
 nb:longint;
begin
 While k<n do begin
  if inpos>readpos then readbuf;
  nb:=inbuf[inpos];
  inc(inpos);
  b:=b OR nb SHL k;
  inc(k,8);
 end;
END;

{***************** dump n bits no longer needed from global variable b *************}
Procedure DUMPBITS(n:byte);
begin
 b:=b shr n;
 dec(k,n);
end;

{********************* Flush w bytes directly from slide to file ******************}
Function flush(w:word):boolean;
 var
  n:integer;
 begin
  //blockwrite(outfile,slide[0],w,n);
  n:=outfile.Write(slide[0],w);
  Result:=(n=w);// and (ioresult=0);
  UpdateCRC(iobuf(pointer(@slide[0])^),w);
 end;

{******************************* Break string into tokens ****************************}
VAR
  _Token : PAnsiChar;

FUNCTION StrTok ( Source : PAnsiChar; Token : AnsiCHAR ) : PAnsiChar;
  VAR P : PAnsiChar;
BEGIN
  IF Source <> NIL THEN _Token := Source;
  IF _Token = NIL THEN BEGIN
    strTok := NIL;
    exit
  END;
  P := StrScan ( _Token, Token );
  StrTok := _Token;
  IF P <> NIL THEN BEGIN
    P^ := #0;
    Inc ( P );
  END;
  _Token := P;
END;

{*************** free huffman tables starting with table where t points to ************}

PROCEDURE huft_free ( t : phuftlist );

VAR p, q : phuftlist;
    z : integer;

BEGIN
  p := pointer ( t );
  WHILE p <> NIL DO BEGIN
    dec ( longint ( p ), sizeof ( huft ) );
    q := p^ [ 0 ].v_t;
    z := p^ [ 0 ].v_n;   {Size in Bytes, required by TP ***}
    freemem ( p, ( z + 1 ) * sizeof ( huft ) );
    p := q
  END;
END;

{*********** build huffman table from code lengths given by array b^ *******************}
FUNCTION huft_build(b:pword;n,s:word;d,e:pushlist;t:pphuft;var m:integer):integer;
VAR a : word;                        {counter for codes of length k}
    c : ARRAY [ 0..b_max + 1 ] of word;   {bit length count table}
    f : word;                        {i repeats in table every f entries}
    g,                             {max. code length}
    h : integer;                     {table level}
    i,                             {counter, current code}
    j : word;                        {counter}
    k : integer;                     {number of bits in current code}
    p : pword;                       {pointer into c, b and v}
    q : phuftlist;                   {points to current table}
    r : huft;                        {table entry for structure assignment}
    u : ARRAY [ 0..b_max ] of phuftlist;{table stack}
    v : ARRAY [ 0..n_max ] of word;     {values in order of bit length}
    w : integer;                     {bits before this table}
    x : ARRAY [ 0..b_max + 1 ] of word;   {bit offsets, then code stack}
    l : ARRAY [  - 1..b_max + 1 ] of word;  {l[h] bits in table of level h}
    xp : ^word;                      {pointer into x}
    y : integer;                     {number of dummy codes added}
    z : word;                        {number of entries in current table}
    tryagain : boolean;              {bool for loop}
    pt : phuft;                      {for test against bad input}
    el : word;                       {length of eob code=code 256}

BEGIN
  IF n > 256 THEN el := pword (longint(b)+256*sizeof(word))^ ELSE el := BMAX;
  {generate counts for each bit length}
  fillchar ( c, sizeof ( c ), #0 );
  p := b; i := n;                      {p points to array of word}
  REPEAT
    IF p^ > b_max THEN BEGIN
      t^ := NIL;
      m := 0;
      huft_build := huft_error;
      exit
    END;
    inc ( c [ p^ ] );
    inc ( longint ( p ), sizeof ( word ) );   {point to next item}
    dec ( i );
  UNTIL i = 0;
  IF c [ 0 ] = n THEN BEGIN
    t^ := NIL;
    m := 0;
    huft_build := huft_complete;
    exit
  END;

  {find minimum and maximum length, bound m by those}
  j := 1;
  WHILE ( j <= b_max ) AND ( c [ j ] = 0 ) DO inc ( j );
  k := j;
  IF m < j THEN m := j;
  i := b_max;
  WHILE ( i > 0 ) AND ( c [ i ] = 0 ) DO dec ( i );
  g := i;
  IF m > i THEN m := i;

  {adjust last length count to fill out codes, if needed}
  y := 1 SHL j;
  WHILE j < i DO BEGIN
    y := y - c [ j ];
    IF y < 0 THEN BEGIN
      huft_build := huft_error;
      exit
    END;
    y := y SHL 1;
    inc ( j );
  END;
  dec ( y, c [ i ] );
  IF y < 0 THEN BEGIN
    huft_build := huft_error;
    exit
  END;
  inc ( c [ i ], y );

  {generate starting offsets into the value table for each length}
  x [ 1 ] := 0;
  j := 0;
  p := @c; inc ( longint ( p ), sizeof ( word ) );
  xp := @x;inc ( longint ( xp ), 2 * sizeof ( word ) );
  dec ( i );
  WHILE i <> 0 DO BEGIN
    inc ( j, p^ );
    xp^ := j;
    inc ( longint ( p ), 2 );
    inc ( longint ( xp ), 2 );
    dec ( i );
  END;

  {make table of values in order of bit length}
  p := b; i := 0;
  REPEAT
    j := p^;
    inc ( longint ( p ), sizeof ( word ) );
    IF j <> 0 THEN BEGIN
      v [ x [ j ] ] := i;
      inc ( x [ j ] );
    END;
    inc ( i );
  UNTIL i >= n;

  {generate huffman codes and for each, make the table entries}
  x [ 0 ] := 0; i := 0;
  p := @v;
  h := - 1;
  l [  - 1 ] := 0;
  w := 0;
  u [ 0 ] := NIL;
  q := NIL;
  z := 0;

  {go through the bit lengths (k already is bits in shortest code)}
  FOR k := k TO g DO BEGIN
    FOR a := c [ k ] DOWNTO 1 DO BEGIN
      {here i is the huffman code of length k bits for value p^}
      WHILE k > w + l [ h ] DO BEGIN
        inc ( w, l [ h ] ); {Length of tables to this position}
        inc ( h );
        z := g - w;
        IF z > m THEN z := m;
        j := k - w;
        f := 1 SHL j;
        IF f > a + 1 THEN BEGIN
          dec ( f, a + 1 );
          xp := @c [ k ];
          inc ( j );
          tryagain := TRUE;
          WHILE ( j < z ) AND tryagain DO BEGIN
            f := f SHL 1;
            inc ( longint ( xp ), sizeof ( word ) );
            IF f <= xp^ THEN tryagain := FALSE
                      ELSE BEGIN
                        dec ( f, xp^ );
                        inc ( j );
                      END;
          END;
        END;
        IF ( w + j > el ) AND ( w < el ) THEN
          j := el - w;       {Make eob code end at table}
        IF w = 0 THEN BEGIN
          j := m;  {*** Fix: main table always m bits!}
        END;
        z := 1 SHL j;
        l [ h ] := j;

        {allocate and link new table}
        getmem ( q, ( z + 1 ) * sizeof ( huft ) );
        IF q = NIL THEN BEGIN
          IF h <> 0 THEN huft_free ( pointer ( u [ 0 ] ) );
          huft_build := huft_outofmem;
          exit
        END;
        fillchar ( q^, ( z + 1 ) * sizeof ( huft ), #0 );
        q^ [ 0 ].v_n := z;  {Size of table, needed in freemem ***}
        t^ := @q^ [ 1 ];     {first item starts at 1}
        t := @q^ [ 0 ].v_t;
        t^ := NIL;
        q := @q^ [ 1 ];   {pointer(longint(q)+sizeof(huft));} {???}
        u [ h ] := q;
        {connect to last table, if there is one}
        IF h <> 0 THEN BEGIN
          x [ h ] := i;
          r.b := l [ h - 1 ];
          r.e := 16 + j;
          r.v_t := q;
          j := ( i AND ( ( 1 SHL w ) - 1 ) ) SHR ( w - l [ h - 1 ] );

          {test against bad input!}
          pt := phuft ( longint ( u [ h - 1 ] ) - sizeof ( huft ) );
          IF j > pt^.v_n THEN BEGIN
            huft_free ( pointer ( u [ 0 ] ) );
            huft_build := huft_error;
            exit
          END;

          pt := @u [ h - 1 ]^ [ j ];
          pt^ := r;
        END;
      END;

      {set up table entry in r}
      r.b := word ( k - w );
      r.v_t := NIL;   {Unused}   {***********}
      IF longint ( p ) >= longint ( @v [ n ] ) THEN r.e := 99
      ELSE IF p^ < s THEN BEGIN
        IF p^ < 256 THEN r.e := 16 ELSE r.e := 15;
        r.v_n := p^;
        inc ( longint ( p ), sizeof ( word ) );
      END ELSE BEGIN
        IF ( d = NIL ) OR ( e = NIL ) THEN BEGIN
          huft_free ( pointer ( u [ 0 ] ) );
          huft_build := huft_error;
          exit
        END;
        r.e := word ( e^ [ p^ - s ] );
        r.v_n := d^ [ p^ - s ];
        inc ( longint ( p ), sizeof ( word ) );
      END;

      {fill code like entries with r}
      f := 1 SHL ( k - w );
      j := i SHR w;
      WHILE j < z DO BEGIN
        q^ [ j ] := r;
        inc ( j, f );
      END;

      {backwards increment the k-bit code i}
      j := 1 SHL ( k - 1 );
      WHILE ( i AND j ) <> 0 DO BEGIN
        {i:=i^j;}
        i := i XOR j;
        j := j SHR 1;
      END;
      i := i XOR j;

      {backup over finished tables}
      WHILE ( ( i AND ( ( 1 SHL w ) - 1 ) ) <> x [ h ] ) DO BEGIN
        dec ( h );
        dec ( w, l [ h ] ); {Size of previous table!}
      END;
    END;
  END;
  IF ( y <> 0 ) AND ( g <> 1 ) THEN huft_build := huft_incomplete
                       ELSE huft_build := huft_complete;
END;

(***************************************************************************)
FUNCTION inflate_codes ( tl, td : phuftlist;bl, bd : integer ) : integer;
VAR
    n, d, e1,          {length and index for copy}
    ml, md : word;      {masks for bl and bd bits}
    t : phuft;         {pointer to table entry}
    e : byte;          {table entry flag/number of extra bits}

BEGIN
  { inflate the coded data }
  ml := mask_bits [ bl ];          {precompute masks for speed}
  md := mask_bits [ bd ];
  WHILE NOT ( zipeof ) DO BEGIN
    NEEDBITS ( bl );
    t := @tl^ [ b AND ml ];
    e := t^.e;
    IF e > 16 THEN REPEAT       {then it's a literal}
      IF e = 99 THEN BEGIN
        inflate_codes := unzip_ZipFileErr;
        exit
      END;
      DUMPBITS ( t^.b );
      dec ( e, 16 );
      NEEDBITS ( e );
      t := @t^.v_t^ [ b AND mask_bits [ e ] ];
      e := t^.e;
    UNTIL e <= 16;
    DUMPBITS ( t^.b );
    IF e = 16 THEN BEGIN
      slide [ w ] := Ansichar ( t^.v_n );
      inc ( w );
      IF w = SlideSize THEN BEGIN
        IF NOT flush ( w ) THEN BEGIN
          inflate_codes := unzip_WriteErr;
          exit;
        END;
        w := 0
      END;
    END ELSE BEGIN                {it's an EOB or a length}
      IF e = 15 THEN BEGIN {Ende}   {exit if end of block}
        inflate_codes := unzip_Ok;
        exit;
      END;
      NEEDBITS ( e );                 {get length of block to copy}
      n := t^.v_n + ( b AND mask_bits [ e ] );
      DUMPBITS ( e );

      NEEDBITS ( bd );                {decode distance of block to copy}
      t := @td^ [ b AND md ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          inflate_codes := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [ b AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );
      NEEDBITS ( e );
      d := w - t^.v_n - b AND mask_bits [ e ];
      DUMPBITS ( e );
      {do the copy}
      REPEAT
        d := d AND ( SlideSize - 1 );
        IF d > w THEN e1 := SlideSize - d
               ELSE e1 := SlideSize - w;
        IF e1 > n THEN e1 := n;
        dec ( n, e1 );
        IF ( w - d >= e1 ) THEN BEGIN
          move ( slide [ d ], slide [ w ], e1 );
          inc ( w, e1 );
          inc ( d, e1 );
        END ELSE REPEAT
          slide [ w ] := slide [ d ];
          inc ( w );
          inc ( d );
          dec ( e1 );
        UNTIL ( e1 = 0 );
        IF w = SlideSize THEN BEGIN
          IF NOT flush ( w ) THEN BEGIN
            inflate_codes := unzip_WriteErr;
            exit;
          END;
          w := 0;
        END;
      UNTIL n = 0;
    END;
  END;
  inflate_codes := unzip_readErr;
END;

{**************************** "decompress" stored block **************************}
Function inflate_stored:integer;
Var
 n:word; { number of bytes in block}
begin
{go to byte boundary}
 n:=k AND 7; dumpbits(n);
{get the length and its complement}
 NEEDBITS(16); n:=b AND $ffff; DUMPBITS(16);
 NEEDBITS(16);
 if (n<>(not b) and $ffff) then begin
  inflate_stored:=unzip_zipFileErr;
  exit
 end;
 DUMPBITS(16);
 while (n>0) and not (zipeof) do begin {read and output the compressed data}
  dec(n);
  NEEDBITS(8); slide[w]:=Ansichar(b);
  inc(w);
  if w=SlideSize then begin
   if not flush(w) then begin
    inflate_stored:=unzip_WriteErr;
    exit
   end;
   w:=0;
  end;
  DUMPBITS(8);
 end;
 if zipeof then inflate_stored:=unzip_readErr else inflate_stored:=unzip_Ok;
END;

{**************************** decompress fixed block **************************}
Function inflate_fixed:integer;
var
 i:integer;               {temporary variable}
 tl,                      {literal/length code table}
 td : phuftlist;                {distance code table}
 bl, bd : integer;           {lookup bits for tl/bd}
 l : ARRAY [ 0..287 ] of word; {length list for huft_build}
begin
{set up literal table}
 FOR i:=0   to 143 do l[i]:=8;
 FOR i:=144 to 255 do l[i]:=9;
 FOR i:=256 to 279 do l[i]:=7;
 FOR i:=280 to 287 do l[i]:=8; {make a complete, but wrong code set}
 bl:=7;
 Result:=huft_build(pword(@l), 288, 257, pushlist(@cplens),pushlist(@cplext),@tl,bl);
 if Result<>huft_complete then exit;
 for i:=0 to 29 do l[i]:=5;    {make an incomplete code set}
 bd:=5;
 Result:=huft_build(pword(@l),30,0,pushlist(@cpdist),pushlist(@cpdext),@td,bd);
 if Result>huft_incomplete then begin
  huft_free(tl);
  inflate_fixed:=unzip_ZipFileErr;
  exit
 end;
 inflate_fixed:=inflate_codes(tl,td,bl,bd);
 huft_free(tl);
 huft_free(td);
END;

{**************************** decompress dynamic block **************************}

FUNCTION inflate_dynamic : integer;
VAR i : integer;                      {temporary variables}
    j,
    l,                              {last length}
    m,                              {mask for bit length table}
    n : word;                         {number of lengths to get}
    tl,                             {literal/length code table}
    td : phuftlist;                   {distance code table}
    bl, bd : integer;                  {lookup bits for tl/bd}
    nb, nl, nd : word;                  {number of bit length/literal length/distance codes}
    ll : ARRAY [ 0..288 + 32 - 1 ] of word;  {literal/length and distance code lengths}

BEGIN
  {read in table lengths}
  NEEDBITS ( 5 ); nl := 257 + word ( b ) AND $1f; DUMPBITS ( 5 );
  NEEDBITS ( 5 ); nd :=   1 + word ( b ) AND $1f; DUMPBITS ( 5 );
  NEEDBITS ( 4 ); nb :=   4 + word ( b ) AND  $f; DUMPBITS ( 4 );
  IF ( nl > 288 ) OR ( nd > 32 ) THEN BEGIN
    inflate_dynamic := 1;
    exit
  END;
  fillchar ( ll, sizeof ( ll ), #0 );

  {read in bit-length-code lengths}
  FOR j := 0 TO nb - 1 DO BEGIN
    NEEDBITS ( 3 );  ll [ border [ j ] ] := b AND 7; DUMPBITS ( 3 );
  END;
  FOR j := nb TO 18 DO ll [ border [ j ] ] := 0;

  {build decoding table for trees--single level, 7 bit lookup}
  bl := 7;
  i := huft_build ( pword ( @ll ), 19, 19, NIL, NIL, @tl, bl );
  IF i <> huft_complete THEN BEGIN
    IF i = huft_incomplete THEN huft_free ( tl ); {other errors: already freed}
    inflate_dynamic := unzip_ZipFileErr;
    exit
  END;

  {read in literal and distance code lengths}
  n := nl + nd;
  m := mask_bits [ bl ];
  i := 0; l := 0;
  WHILE word ( i ) < n DO BEGIN
    NEEDBITS ( bl );
    td := @tl^ [ b AND m ];
    j := phuft ( td ) ^.b;
    DUMPBITS ( j );
    j := phuft ( td ) ^.v_n;
    IF j < 16 THEN BEGIN            {length of code in bits (0..15)}
      l := j;                       {ave last length in l}
      ll [ i ] := l;
      inc ( i )
    END ELSE IF j = 16 THEN BEGIN   {repeat last length 3 to 6 times}
      NEEDBITS ( 2 );
      j := 3 + b AND 3;
      DUMPBITS ( 2 );
      IF i + j > n THEN BEGIN
        inflate_dynamic := 1;
        exit
      END;
      WHILE j > 0 DO BEGIN
        ll [ i ] := l;
        dec ( j );
        inc ( i );
      END;
    END ELSE IF j = 17 THEN BEGIN   {3 to 10 zero length codes}
      NEEDBITS ( 3 );
      j := 3 + b AND 7;
      DUMPBITS ( 3 );
      IF i + j > n THEN BEGIN
        inflate_dynamic := 1;
        exit
      END;
      WHILE j > 0 DO BEGIN
        ll [ i ] := 0;
        inc ( i );
        dec ( j );
      END;
      l := 0;
    END ELSE BEGIN                {j == 18: 11 to 138 zero length codes}
      NEEDBITS ( 7 );
      j := 11 + b AND $7f;
      DUMPBITS ( 7 );
      IF i + j > n THEN BEGIN
        inflate_dynamic := unzip_zipfileErr;
        exit
      END;
      WHILE j > 0 DO BEGIN
        ll [ i ] := 0;
        dec ( j );
        inc ( i );
      END;
      l := 0;
    END;
  END;
  huft_free ( tl );        {free decoding table for trees}

  {build the decoding tables for literal/length and distance codes}
  bl := lbits;
  i := huft_build ( pword ( @ll ), nl, 257, pushlist ( @cplens ), pushlist ( @cplext ), @tl, bl );
  IF i <> huft_complete THEN BEGIN
    IF i = huft_incomplete THEN huft_free ( tl );
    inflate_dynamic := unzip_ZipFileErr;
    exit
  END;
  bd := dbits;
  i := huft_build ( pword ( @ll [ nl ] ), nd, 0, pushlist ( @cpdist ), pushlist ( @cpdext ), @td, bd );
  IF i > huft_incomplete THEN BEGIN {pkzip bug workaround}
    IF i = huft_incomplete THEN huft_free ( td );
    huft_free ( tl );
    inflate_dynamic := unzip_ZipFileErr;
    exit
  END;
  {decompress until an end-of-block code}
  inflate_dynamic := inflate_codes ( tl, td, bl, bd );
  huft_free ( tl );
  huft_free ( td );
END;

{**************************** decompress a block ******************************}
Function inflate_block (Var e:integer):integer;
Var
 t:word; {block type}
begin
 NEEDBITS(1); e:=b and 1; DUMPBITS(1);
 NEEDBITS(2); t:=b and 3; DUMPBITS(2);
 case t of
  0 : Result:=inflate_stored;
  1 : Result:=inflate_fixed;
  2 : Result:=inflate_dynamic;
 else Result:=unzip_ZipFileErr;  {bad block type}
 end;
end;

{**************************** decompress an inflated entry **************************}
Function inflate:integer;
var
 e:integer; {last block flag}
begin
 inpos  := 0; {Input buffer position}
 readpos:=-1; {Nothing read}
{initialize window, bit buffer}
 w:=0;
 k:=0;
 b:=0;
{decompress until the last block}
 repeat
  result:=inflate_block(e);
  if result<>0 then exit;
 until e<>0;
{flush out slide}
 if not flush(w) then result:=unzip_WriteErr else result:=unzip_Ok;
END;
{************************* copy stored file ************************************}
Function CopyStored:integer;
Var
 readin:longint;
 outcnt:integer;
begin
 While (reachedsize<compsize) do begin
  readin:=compsize-reachedsize;
  If readin>SlideSize then readin:=SlideSize;
  outcnt:=InFile.read(slide[0],readin);
  IF (outcnt<>readin) then begin
   copystored := unzip_ReadErr;
   exit
  end;
  If Not flush(outcnt) Then begin  {Flushoutput takes care of CRC too}
   copystored := unzip_WriteErr;
   exit
  end;
  inc(reachedsize,outcnt);
 end;
 copystored:=unzip_Ok
end;
{************************************* explode ********************************}

{*********************************** read in tree *****************************}
FUNCTION get_tree ( l : pword;n : word ) : integer;
VAR i, k, j, b : word;
    bytebuf : byte;

BEGIN
  READBYTE ( bytebuf );
  i := bytebuf;
  inc ( i );
  k := 0;
  REPEAT
    READBYTE ( bytebuf );
    j := bytebuf;
    b := ( j AND $F ) + 1;
    j := ( ( j AND $F0 ) SHR 4 ) + 1;
    IF ( k + j ) > n THEN BEGIN
      get_tree := 4;
      exit
    END;
    REPEAT
      l^ := b;
      inc ( longint ( l ), sizeof ( word ) );
      inc ( k );
      dec ( j );
    UNTIL j = 0;
    dec ( i );
  UNTIL i = 0;
  IF k <> n THEN get_tree := 4 ELSE get_tree := 0;
END;

{******************exploding, method: 8k slide, 3 trees ***********************}

FUNCTION explode_lit8 ( tb, tl, td : phuftlist;bb, bl, bd : integer ) : integer;
VAR s : longint;
    e : word;
    n, d : word;
    w : word;
    t : phuft;
    mb, ml, md : word;
    u : word;

BEGIN
  b := 0; k := 0; w := 0;
  u := 1;
  mb := mask_bits [ bb ];
  ml := mask_bits [ bl ];
  md := mask_bits [ bd ];
  s := uncompsize;
  WHILE ( s > 0 ) AND NOT ( zipeof ) DO BEGIN
    NEEDBITS ( 1 );
    IF ( b AND 1 ) <> 0 THEN BEGIN  {Litteral}
      DUMPBITS ( 1 );
      dec ( s );
      NEEDBITS ( bb );
      t := @tb^ [  ( NOT b ) AND mb ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_lit8 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );
      slide [ w ] := Ansichar ( t^.v_n );
      inc ( w );
      IF w = SlideSize THEN BEGIN
        IF NOT flush ( w ) THEN BEGIN
          explode_lit8 := unzip_WriteErr;
          exit
        END;
        w := 0; u := 0;
      END;
    END ELSE BEGIN
      DUMPBITS ( 1 );
      NEEDBITS ( 7 );
      d := b AND $7F;
      DUMPBITS ( 7 );
      NEEDBITS ( bd );
      t := @td^ [  ( NOT b ) AND md ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_lit8 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );

      d := w - d - t^.v_n;
      NEEDBITS ( bl );
      t := @tl^ [  ( NOT b ) AND ml ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_lit8 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;

      DUMPBITS ( t^.b );

      n := t^.v_n;
      IF e <> 0 THEN BEGIN
        NEEDBITS ( 8 );
        inc ( n, byte ( b ) AND $ff );
        DUMPBITS ( 8 );
      END;
      dec ( s, n );
      REPEAT
        d := d AND pred ( SlideSize );
        IF d > w THEN e := SlideSize - d ELSE e := SlideSize - w;
        IF e > n THEN e := n;
        dec ( n, e );
        IF ( u <> 0 ) AND ( w <= d ) THEN BEGIN
          fillchar ( slide [ w ], e, #0 );
          inc ( w, e );
          inc ( d, e );
        END ELSE IF ( w - d >= e ) THEN BEGIN
          move ( slide [ d ], slide [ w ], e );
          inc ( w, e );
          inc ( d, e );
        END ELSE REPEAT
          slide [ w ] := slide [ d ];
          inc ( w );
          inc ( d );
          dec ( e );
        UNTIL e = 0;
        IF w = SlideSize THEN BEGIN
          IF NOT flush ( w ) THEN BEGIN
            explode_lit8 := unzip_WriteErr;
            exit
          END;
          w := 0; u := 0;
        END;
      UNTIL n = 0;
    END;
  END;
  IF NOT flush ( w ) THEN explode_lit8 := unzip_WriteErr
  ELSE
    IF zipeof THEN explode_lit8 := unzip_readErr
  ELSE
    explode_lit8 := unzip_Ok;
END;

{******************exploding, method: 4k slide, 3 trees ***********************}

FUNCTION explode_lit4 ( tb, tl, td : phuftlist;bb, bl, bd : integer ) : integer;
VAR s : longint;
    e : word;
    n, d : word;
    w : word;
    t : phuft;
    mb, ml, md : word;
    u : word;

BEGIN
  b := 0; k := 0; w := 0;
  u := 1;
  mb := mask_bits [ bb ];
  ml := mask_bits [ bl ];
  md := mask_bits [ bd ];
  s := uncompsize;
  WHILE ( s > 0 ) AND NOT ( zipeof ) DO BEGIN
    NEEDBITS ( 1 );
    IF ( b AND 1 ) <> 0 THEN BEGIN  {Litteral}
      DUMPBITS ( 1 );
      dec ( s );
      NEEDBITS ( bb );
      t := @tb^ [  ( NOT b ) AND mb ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_lit4 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );
      slide [ w ] := Ansichar ( t^.v_n );
      inc ( w );
      IF w = SlideSize THEN BEGIN
        IF NOT flush ( w ) THEN BEGIN
          explode_lit4 := unzip_WriteErr;
          exit
        END;
        w := 0; u := 0;
      END;
    END ELSE BEGIN
      DUMPBITS ( 1 );
      NEEDBITS ( 6 );
      d := b AND $3F;
      DUMPBITS ( 6 );
      NEEDBITS ( bd );
      t := @td^ [  ( NOT b ) AND md ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_lit4 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );
      d := w - d - t^.v_n;
      NEEDBITS ( bl );
      t := @tl^ [  ( NOT b ) AND ml ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_lit4 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;

      DUMPBITS ( t^.b );
      n := t^.v_n;
      IF e <> 0 THEN BEGIN
        NEEDBITS ( 8 );
        inc ( n, b AND $ff );
        DUMPBITS ( 8 );
      END;
      dec ( s, n );
      REPEAT
        d := d AND pred ( SlideSize );
        IF d > w THEN e := SlideSize - d ELSE e := SlideSize - w;
        IF e > n THEN e := n;
        dec ( n, e );
        IF ( u <> 0 ) AND ( w <= d ) THEN BEGIN
          fillchar ( slide [ w ], e, #0 );
          inc ( w, e );
          inc ( d, e );
        END ELSE IF ( w - d >= e ) THEN BEGIN
          move ( slide [ d ], slide [ w ], e );
          inc ( w, e );
          inc ( d, e );
        END ELSE REPEAT
          slide [ w ] := slide [ d ];
          inc ( w );
          inc ( d );
          dec ( e );
        UNTIL e = 0;
        IF w = SlideSize THEN BEGIN
          IF NOT flush ( w ) THEN BEGIN
            explode_lit4 := unzip_WriteErr;
            exit
          END;
          w := 0; u := 0;
        END;
      UNTIL n = 0;
    END;
  END;
  IF NOT flush ( w ) THEN explode_lit4 := unzip_WriteErr
  ELSE
    IF zipeof THEN explode_lit4 := unzip_readErr
  ELSE explode_lit4 := unzip_Ok;
END;

{******************exploding, method: 8k slide, 2 trees ***********************}

FUNCTION explode_nolit8 ( tl, td : phuftlist;bl, bd : integer ) : integer;
VAR s : longint;
    e : word;
    n, d : word;
    w : word;
    t : phuft;
    ml, md : word;
    u : word;

BEGIN
  b := 0; k := 0; w := 0;
  u := 1;
  ml := mask_bits [ bl ];
  md := mask_bits [ bd ];
  s := uncompsize;
  WHILE ( s > 0 ) AND NOT (zipeof ) DO BEGIN
    NEEDBITS ( 1 );
    IF ( b AND 1 ) <> 0 THEN BEGIN  {Litteral}
      DUMPBITS ( 1 );
      dec ( s );
      NEEDBITS ( 8 );
      slide [ w ] := Ansichar ( b );
      inc ( w );
      IF w = SlideSize THEN BEGIN
        IF NOT flush ( w ) THEN BEGIN
          explode_nolit8 := unzip_WriteErr;
          exit
        END;
        w := 0; u := 0;
      END;
      DUMPBITS ( 8 );
    END ELSE BEGIN
      DUMPBITS ( 1 );
      NEEDBITS ( 7 );
      d := b AND $7F;
      DUMPBITS ( 7 );
      NEEDBITS ( bd );
      t := @td^ [  ( NOT b ) AND md ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_nolit8 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );

      d := w - d - t^.v_n;
      NEEDBITS ( bl );
      t := @tl^ [  ( NOT b ) AND ml ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_nolit8 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;

      DUMPBITS ( t^.b );

      n := t^.v_n;
      IF e <> 0 THEN BEGIN
        NEEDBITS ( 8 );
        inc ( n, b AND $ff );
        DUMPBITS ( 8 );
      END;
      dec ( s, n );
      REPEAT
        d := d AND pred ( SlideSize);
        IF d > w THEN e := SlideSize - d ELSE e := SlideSize - w;
        IF e > n THEN e := n;
        dec ( n, e );
        IF ( u <> 0 ) AND ( w <= d ) THEN BEGIN
          fillchar ( slide [ w ], e, #0 );
          inc ( w, e );
          inc ( d, e );
        END ELSE IF ( w - d >= e ) THEN BEGIN
          move ( slide [ d ], slide [ w ], e );
          inc ( w, e );
          inc ( d, e );
        END ELSE REPEAT
          slide [ w ] := slide [ d ];
          inc ( w );
          inc ( d );
          dec ( e );
        UNTIL e = 0;
        IF w = SlideSize THEN BEGIN
          IF NOT flush ( w ) THEN BEGIN
            explode_nolit8 := unzip_WriteErr;
            exit
          END;
          w := 0; u := 0;
        END;
      UNTIL n = 0;
    END;
  END;
  IF NOT flush ( w ) THEN explode_nolit8 := unzip_WriteErr
  ELSE
    IF zipeof THEN explode_nolit8 := unzip_readErr
  ELSE explode_nolit8 := unzip_Ok;
END;

{******************exploding, method: 4k slide, 2 trees ***********************}

FUNCTION explode_nolit4 ( tl, td : phuftlist;bl, bd : integer ) : integer;
VAR s : longint;
    e : word;
    n, d : word;
    w : word;
    t : phuft;
    ml, md : word;
    u : word;

BEGIN
  b := 0; k := 0; w := 0;
  u := 1;
  ml := mask_bits [ bl ];
  md := mask_bits [ bd ];
  s := uncompsize;
  WHILE ( s > 0 ) AND NOT ( zipeof ) DO BEGIN
    NEEDBITS ( 1 );
    IF ( b AND 1 ) <> 0 THEN BEGIN  {Litteral}
      DUMPBITS ( 1 );
      dec ( s );
      NEEDBITS ( 8 );
      slide [ w ] := Ansichar ( b );
      inc ( w );
      IF w = SlideSize THEN BEGIN
        IF NOT flush ( w ) THEN BEGIN
          explode_nolit4 := unzip_WriteErr;
          exit
        END;
        w := 0; u := 0;
      END;
      DUMPBITS ( 8 );
    END ELSE BEGIN
      DUMPBITS ( 1 );
      NEEDBITS ( 6 );
      d := b AND $3F;
      DUMPBITS ( 6 );
      NEEDBITS ( bd );
      t := @td^ [  ( NOT b ) AND md ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_nolit4 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
      DUMPBITS ( t^.b );
      d := w - d - t^.v_n;
      NEEDBITS ( bl );
      t := @tl^ [  ( NOT b ) AND ml ];
      e := t^.e;
      IF e > 16 THEN REPEAT
        IF e = 99 THEN BEGIN
          explode_nolit4 := unzip_ZipFileErr;
          exit
        END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [  ( NOT b ) AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;

      DUMPBITS ( t^.b );
      n := t^.v_n;
      IF e <> 0 THEN BEGIN
        NEEDBITS ( 8 );
        inc ( n, b AND $ff );
        DUMPBITS ( 8 );
      END;
      dec ( s, n );
      REPEAT
        d := d AND pred ( SlideSize );
        IF d > w THEN e := SlideSize - d ELSE e := SlideSize - w;
        IF e > n THEN e := n;
        dec ( n, e );
        IF ( u <> 0 ) AND ( w <= d ) THEN BEGIN
          fillchar ( slide [ w ], e, #0 );
          inc ( w, e );
          inc ( d, e );
        END ELSE IF ( w - d >= e ) THEN BEGIN
          move ( slide [ d ], slide [ w ], e );
          inc ( w, e );
          inc ( d, e );
        END ELSE REPEAT
          slide [ w ] := slide [ d ];
          inc ( w );
          inc ( d );
          dec ( e );
        UNTIL e = 0;
        IF w = SlideSize THEN BEGIN
          IF NOT flush ( w ) THEN BEGIN
            explode_nolit4 := unzip_WriteErr;
            exit
          END;
          w := 0; u := 0;
        END;
      UNTIL n = 0;
    END;
  END;
  IF NOT flush ( w ) THEN explode_nolit4 := unzip_WriteErr
  ELSE
    IF zipeof THEN explode_nolit4 := unzip_readErr
  ELSE explode_nolit4 := unzip_Ok;
END;

{****************************** explode *********************************}

FUNCTION explode : integer;
VAR r : integer;
    tb, tl, td : phuftlist;
    bb, bl, bd : integer;
    l : ARRAY [ 0..255 ] of word;

BEGIN
  inpos := 0;
  readpos := - 1;  {Nothing read in}
  bl := 7;
  IF compsize > 200000 THEN bd := 8 ELSE bd := 7;
  IF hufttype AND 4 <> 0 THEN BEGIN
    bb := 9;
    r := get_tree ( @l [ 0 ], 256 );
    IF r <> 0 THEN BEGIN
      explode := unzip_ZipFileErr;
      exit
    END;
    r := huft_build ( @l, 256, 256, NIL, NIL, @tb, bb );
    IF r <> 0 THEN BEGIN
      IF r = huft_incomplete THEN huft_free ( tb );
      explode := unzip_ZipFileErr;
      exit
    END;
    r := get_tree ( @l [ 0 ], 64 );
    IF r <> 0 THEN BEGIN
      huft_free ( tb );
      explode := unzip_ZipFileErr;
      exit
    END;
    r := huft_build ( @l, 64, 0, pushlist ( @cplen3 ), pushlist ( @extra ), @tl, bl );
    IF r <> 0 THEN BEGIN
      IF r = huft_incomplete THEN huft_free ( tl );
      huft_free ( tb );
      explode := unzip_ZipFileErr;
      exit
    END;
    r := get_tree ( @l [ 0 ], 64 );
    IF r <> 0 THEN BEGIN
      huft_free ( tb );
      huft_free ( tl );
      explode := unzip_ZipFileErr;
      exit
    END;
    IF hufttype AND 2 <> 0 THEN BEGIN {8k}
      r := huft_build ( @l, 64, 0, pushlist ( @cpdist8 ), pushlist ( @extra ), @td, bd );
      IF r <> 0 THEN BEGIN
        IF r = huft_incomplete THEN huft_free ( td );
        huft_free ( tb );
        huft_free ( tl );
        explode := unzip_ZipFileErr;
        exit
      END;
      r := explode_lit8 ( tb, tl, td, bb, bl, bd );
    END ELSE BEGIN
      r := huft_build ( @l, 64, 0, pushlist ( @cpdist4 ), pushlist ( @extra ), @td, bd );
      IF r <> 0 THEN BEGIN
        IF r = huft_incomplete THEN huft_free ( td );
        huft_free ( tb );
        huft_free ( tl );
        explode := unzip_ZipFileErr;
        exit
      END;
      r := explode_lit4 ( tb, tl, td, bb, bl, bd );
    END;
    huft_free ( td );
    huft_free ( tl );
    huft_free ( tb );
  END ELSE BEGIN       {No literal tree}
    r := get_tree ( @l [ 0 ], 64 );
    IF r <> 0 THEN BEGIN
      explode := unzip_ZipFileErr;
      exit
    END;
    r := huft_build ( @l, 64, 0, pushlist ( @cplen2 ), pushlist ( @extra ), @tl, bl );
    IF r <> 0 THEN BEGIN
      IF r = huft_incomplete THEN huft_free ( tl );
      explode := unzip_ZipFileErr;
      exit
    END;

    r := get_tree ( @l [ 0 ], 64 );
    IF r <> 0 THEN BEGIN
      huft_free ( tl );
      explode := unzip_ZipFileErr;
      exit
    END;
    IF hufttype AND 2 <> 0 THEN BEGIN {8k}
      r := huft_build ( @l, 64, 0, pushlist ( @cpdist8 ), pushlist ( @extra ), @td, bd );
      IF r <> 0 THEN BEGIN
        IF r = huft_incomplete THEN huft_free ( td );
        huft_free ( tl );
        explode := unzip_ZipFileErr;
        exit
      END;
      r := explode_nolit8 ( tl, td, bl, bd );
    END ELSE BEGIN
      r := huft_build ( @l, 64, 0, pushlist ( @cpdist4 ), pushlist ( @extra ), @td, bd );
      IF r <> 0 THEN BEGIN
        IF r = huft_incomplete THEN huft_free ( td );
        huft_free ( tl );
        explode := unzip_ZipFileErr;
        exit
      END;
      r := explode_nolit4 ( tl, td, bl, bd );
    END;
    huft_free ( td );
    huft_free ( tl );
  END;
  explode := r;
END;
{*************************** unshrink **********************************}
{Written and NOT copyrighted by Christian Ghisler.
 I have rewritten unshrink because the original
 function was copyrighted by Mr. Smith of Info-zip
 This funtion here is now completely FREE!!!!
 The only right I claim on this code is that
 noone else claims a copyright on it!}
Const
 max_code = 8192;
 max_stack = 8192;
 initial_code_size = 9;
 final_code_size = 13;
 write_max = SlideSize - 3 * ( max_code - 256 ) - max_stack - 2;  {Rest of slide=write buffer}
                                                     {=766 bytes}

Type
 prev  = array[ 257..max_code ] of integer;
 pprev = ^prev;
 cds = ARRAY [ 257..max_code ] of Ansichar;
 pcds = ^cds;
 stacktype = ARRAY [ 0..max_stack ] of Ansichar;
 pstacktype = ^stacktype;
 writebuftype = ARRAY [ 0..write_max ] of Ansichar;   {write buffer}
 pwritebuftype = ^writebuftype;

VAR previous_code : pprev;       {previous code trie}
    actual_code : pcds;          {actual code trie}
    stack : pstacktype;          {Stack for output}
    writebuf : pwritebuftype;    {Write buffer}
    next_free,                 {Next free code in trie}
    write_ptr : integer;         {Pointer to output buffer}

FUNCTION unshrink_flush : boolean;
VAR
 n : integer;
BEGIN
  //blockwrite(outfile,writebuf^[0],write_ptr,n);
  n:=outfile.Write(WriteBuf^[0],write_ptr);
  Result:=(n=write_ptr);// AND (ioresult=0);
  UpdateCRC(iobuf(pointer(@writebuf^[0])^),write_ptr);
END;

FUNCTION write_char ( c : Ansichar ) : boolean;
BEGIN
  writebuf^[write_ptr]:=c;
  inc(write_ptr);
  IF write_ptr>write_max THEN BEGIN
    write_char:=unshrink_flush;
    write_ptr :=0;
  END ELSE write_char := TRUE;
END;

PROCEDURE ClearLeafNodes;
VAR pc,                    {previous code}
    i,                     {index}
    act_max_code : integer;  {max code to be searched for leaf nodes}
    previous : pprev;   {previous code trie}

BEGIN
  previous := previous_code;
  act_max_code := next_free - 1;
  FOR i := 257 TO act_max_code DO
    previous^ [ i ] := previous^ [ i ] OR $8000;
  FOR i := 257 TO act_max_code DO BEGIN
    pc := previous^ [ i ] AND NOT $8000;
    IF pc > 256 THEN
      previous^ [ pc ] := previous^ [ pc ] AND ( NOT $8000 );
  END;
  {Build new free list}
  pc := - 1;
  next_free := - 1;
  FOR i := 257 TO act_max_code DO
    IF previous^ [ i ] AND $C000 <> 0 THEN BEGIN {Either free before or marked now}
      IF pc <> - 1 THEN previous^ [ pc ] := - i     {Link last item to this item}
                ELSE next_free := i;
      pc := i;
    END;
  IF pc <> - 1 THEN
    previous^ [ pc ] := - act_max_code - 1;
END;


FUNCTION unshrink : integer;

VAR incode : integer;            {code read in}
    lastincode : integer;        {last code read in}
    lastoutcode : Ansichar;          {last code emitted}
    code_size : byte;            {Actual code size}
    stack_ptr,                 {Stackpointer}
    new_code,                  {Save new code read}
    code_mask,                 {mask for coding}
    i : integer;                 {Index}
    bits_to_read : longint;

BEGIN
  If compsize = maxlongint then begin   {Compressed Size was not in header!}
   unshrink := unzip_NotSupported;
   exit
  end;
  inpos  := 0;         {Input buffer position}
  readpos:=-1;         {Nothing read}

  {initialize window, bit buffer}
  w := 0;
  k := 0;
  b := 0;

  {Initialize pointers for various buffers}
  previous_code:=@slide[ 0 ];
  actual_code:=@slide[sizeof(prev)];
  stack:=@slide[sizeof(prev)+sizeof(cds)];
  writebuf:=@slide[sizeof(prev)+sizeof(cds)+sizeof(stacktype)];
  fillchar(slide^,SlideSize,0);

  {initialize free codes list}
  FOR i := 257 TO max_code DO previous_code^[i]:=-(i+1);
  next_free := 257;
  stack_ptr := max_stack;
  write_ptr := 0;
  code_size := initial_code_size;
  code_mask := mask_bits[code_size];

  NEEDBITS(code_size);
  incode:=b AND code_mask;
  DUMPBITS(code_size);

  lastincode:=incode;
  lastoutcode:=Ansichar(incode);
  IF NOT write_char(lastoutcode) THEN BEGIN
   unshrink := unzip_writeErr;
   exit
  END;

  bits_to_read:=8*compsize-code_size; {Bits to be read}
  WHILE (bits_to_read>=code_size) DO BEGIN
    NEEDBITS ( code_size );
    incode := b AND code_mask;
    DUMPBITS ( code_size );
    dec(bits_to_read,code_size );
    IF incode = 256 THEN BEGIN            {Special code}
      NEEDBITS (code_size);
      incode := b AND code_mask;
      DUMPBITS ( code_size );
      dec(bits_to_read,code_size);
      CASE incode of
        1 : BEGIN
          inc(code_size);
          IF code_size>final_code_size THEN BEGIN
            unshrink:=unzip_ZipFileErr;
            exit
          END;
          code_mask:=mask_bits[code_size];
        END;
        2 : ClearLeafNodes;
      ELSE
        unshrink := unzip_ZipFileErr;
        exit
      END;
    END ELSE BEGIN
      new_code:=incode;
      IF incode<256 THEN BEGIN          {Simple char}
        lastoutcode:=Ansichar(incode);
        IF NOT write_char ( lastoutcode ) THEN BEGIN
          unshrink := unzip_writeErr;
          exit
        END;
      END ELSE BEGIN
        IF previous_code^ [ incode ] < 0 THEN BEGIN
          stack^ [ stack_ptr ] := lastoutcode;
          dec ( stack_ptr );
          incode := lastincode;
        END;
        WHILE incode > 256 DO BEGIN
          stack^ [ stack_ptr ] := actual_code^ [ incode ];
          dec ( stack_ptr );
          incode := previous_code^ [ incode ];
        END;
        lastoutcode := Ansichar ( incode );
        IF NOT write_char ( lastoutcode ) THEN BEGIN
          unshrink := unzip_writeErr;
          exit
        END;
        FOR i := stack_ptr + 1 TO max_stack DO
          IF NOT write_char ( stack^ [ i ] ) THEN BEGIN
            unshrink := unzip_writeErr;
            exit
          END;
        stack_ptr := max_stack;
      END;
      incode := next_free;
      IF incode <= max_code THEN BEGIN
        next_free := - previous_code^ [ incode ];   {Next node in free list}
        previous_code^ [ incode ] := lastincode;
        actual_code^ [ incode ] := lastoutcode;
      END;
      lastincode := new_code;
    END;
  END;
  IF unshrink_flush THEN
    unshrink := unzip_ok
  ELSE
    unshrink := unzip_WriteErr;
END;

{******************** main low level function: unzipfile ********************}
Procedure ConvertPath ( var p : string );
Var
  i: longint;
begin
  For i := 1 to Length(p) do if p[i]='/' then p[i]:='\';
end;

function DirectoryExists(const Name: string): Boolean;
var
  Code: Integer;
begin
  Code := GetFileAttributes(PChar(Name));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

Procedure Makedir(Dir:string);
 var
  p:word;
 begin
  if Dir='' then exit;
  if DirectoryExists(Dir) then exit; // Directory Exist
  p:=length(dir); while (p>0) and (dir[p]<>'\') do dec(p);
  if p>0 then MakeDir(Copy(Dir,1,p-1)); // Make Parent Directory
  MkDir(Dir); // Make Directory
 end;

{ MakeDirs by Paul TOTH }
function GetPath(Name:string):string;
 var
  i:integer;
 begin
  i:=length(name);
  while (i>0)and(Name[i]<>'\') do dec(i);
  if i>0 then Result:=Copy(Name,1,i-1) else Result:='';
 end;

procedure MakeDirs(Name:string);
{
 c:\windows\desktop\sample\dir\extrat.ext
 c:\windows\desktop\sample\dir
 c:\windows\desktop\sample
 c:\windows\desktop
 c:\windows
 c:
}
 begin
  if Name='' then exit;
  MakeDirs(GetPath(Name));
  try MkDir(Name) except end;
 end;

{written and not copyrighted by Christian Ghisler}
FUNCTION UnZipFile(AStream:TStream; out_name:string; offset:longint):integer;
Var
 Stream:TFileStream;
BEGIN
 MakeDirs(GetPath(out_name));
 Stream:=TFileStream.Create(out_name,fmCreate or 1{fmOpenWrite});
 try
  AStream.Position:=offset;
  UnZipFile:=UnZipStream(AStream,Stream);
 finally
  Stream.Free;
 end;
END;

{**************** Get next entry from ZIP file ********************}
Function GetNextInZip (Var Zprec : tZiprec ) : integer;
begin
 With zprec do begin
  if FileIndex>=FileCount then begin
   Result:=unzip_nomoreitems;
   exit;
  end;
  inc(FileIndex);
  Stream.Position:=FileOffset;
  Stream.ReadBuffer(FileHeader,SizeOf(FileHeader));
  if FileHeader.Signature<>PK12 then begin
   Result:=unzip_InternalError;
   exit;
  end;
  SetLength(FileName,FileHeader.NameLen);
  Stream.ReadBuffer(FileName[1],FileHeader.NameLen);
  Stream.Position:=Stream.Position+FileHeader.ExtraLen;
  SetLength(FileComment,FileHeader.CommentLen);
  Stream.ReadBuffer(FileComment[1],FileHeader.CommentLen);
  FileOffset:=Stream.Position;

  Size:=FileHeader.RealSize;
  CompressSize:=FileHeader.CompSize;
  if FileHeader.VerMadeBy=0 then Attr:=FileHeader.eFileAttr else Attr:=0;
  Time:=FileHeader.DateTime;
  HeaderOffset:=FileHeader.HeaderPos; {Other header size}

  ConvertPath(FileName);
 // Skip Directories
  if ExtractFileName(FileName)='' then Result:=GetNextInZip(ZPrec) else Result:=unzip_ok;
 END;
END;

{**************** Get first entry from ZIP file ********************}
TYPE
  TMainHeader=packed record
   Signature           :longint; // end of central dir signature 'PK'#5#6}
   ThisDisk            :word;    // number of this disk
   CentralStartDisk    :word;
   EntriesOnThisDisk   :word;
   Entries             :word;
   HeadSize            :longint;
   HeadStart           :longint;
   CommentLen          :word;
  // comment[]
  end;

FUNCTION GetFirstInZip(AStream:TStream; VAR zprec : tZipRec ):integer;
Var
 Header:TMainHeader;
 Start :longint;
 Start2:integer;
 Block :RawByteString;
BEGIN
{ ZIP file Format :
  [PK34-LocalFileHeader+FileData+DataDescrp]...
  [PK12-FileHeader]...
  [PK56-EndOfDir]

 1-localize PK56
 2-load PK12s
 3-Extract PK54s
}
 Result:=unzip_FileError;
 WITH zprec DO BEGIN
  Stream:=AStream;
  Size:=Stream.Size;
  if Size<SizeOf(TMainHeader) then exit; // at least, we need a MainHeader
  MainHeader:=Size-SizeOf(TMainHeader); // Mainheader offset
 // non-commented ZIP file :
  Stream.Position:=MainHeader;
  Stream.ReadBuffer(Header,SizeOf(Header));
  if Header.Signature<>PK56 then begin // not a ZIP file - or - commented ZIP file
  {Search from back of file to central directory start}
   SetLength(Block,SizeOf(TMainHeader));
   repeat
    if MainHeader=0 then exit; // not a ZIP file
    dec(MainHeader,SizeOf(TMainHeader)-4);
    if MainHeader<0 then MainHeader:=0;
    Stream.Position:=MainHeader;
    Stream.ReadBuffer(Block[1],SizeOf(TMainHeader));
    Start:=Pos('PK'#5#6,Block);
   until Start<>0;
   Start2:=pos('PK'#5#6,Copy(Block,Start+1,Length(Block)));
   while Start2>0 do begin
    Inc(Start,Start2);
    Start2:=pos('PK'#5#6,Copy(Block,Start+1,Length(Block)));
   end;
   Stream.Position:=MainHeader+Start-1;
   Stream.ReadBuffer(Header,SizeOf(Header));
  end;
  SetLength(Comment,Header.CommentLen);
  Stream.ReadBuffer(Comment[1],Header.CommentLen);
  FileOffset:=Header.HeadStart;
  FileCount :=Header.Entries;
  FileIndex :=0;
  Result:=GetNextInZip(ZPrec);
 end;
end;


{**************** free ZIP buffers ********************}
PROCEDURE CloseZipFile (Var ZPRec:TZIPRec );  {Only free buffer, file only open in Getfirstinzip}
 begin
  ZPrec.Buf:=''; // I don't think that Delphi can release this himself.
 end;

//-- Paul TOTH
Function FindZipName(ZipStream:TStream; FileName:string):integer;
 var
  r:TZIPRec;
  i:integer;
 begin
  Result:=-1;
  i:=getFirstInZip(ZipStream,r);
  while i=unzip_ok do begin
   if r.FileName=FileName then begin
    Result:=r.HeaderOffset;
    break;
   end;
   i:=GetNextInZip(r);
  end;
  CloseZipFile(r);
 end;

Function UnZipStream(ZipStream,OutStream:TStream):integer;
Var
 offset:integer;
 Header:PLocalHeader;
 originalcrc:longint;    {crc from zip-header}
 ziptype,aResult:integer;
begin
 InFile:=ZipStream;
 Header:=@InBuf;
 offset:=InFile.Position;
 InFile.Readbuffer(Header^,SizeOf(Header^));
 If header.signature<>PK34 then begin
  Result:=unzip_ZipFileErr;
  exit
 end;

{calculate offset of data}
 Inc(offset,header^.filename_len + header^.extra_field_len + sizeof ( tlocalheader ));
 if (hufttype and 8)=0 then begin  {Size and crc at the beginning}
  compsize   :=header^.compress_size;
  uncompsize :=header^.uncompress_size;
  originalcrc:=header^.crc_32;
 end else begin
  compsize   :=maxlongint;           {Don't get a sudden zipeof!}
  uncompsize :=maxlongint;
  originalcrc:=0
 end;
 ziptype:=header^.method;     {0=stored, 6=imploded, 8=deflated}
 if (1 shl ziptype) and SupportedMethods=0 then begin  {Not Supported!!!}
  Result:=unzip_NotSupported;
  exit;
 end;
 hufttype:=header^.flags;
 if (hufttype and 1)<>0 then begin {encrypted}
   Result:=unzip_Encrypted;
   exit;
 end;

 reachedsize := 0;
 InFile.Position:=offset;
 OutFile:=OutStream;

 getmem(slide,SlideSize); fillchar(slide[0], SlideSize, #0 );
 zipeof := FALSE;
 crc32val := Integer($FFFFFFFF);
 {Unzip correct type}
 CASE ziptype of
   0 : aResult := copystored;
   1 : aResult := unshrink;
   6 : aResult := explode;
   8 : aResult := inflate;
 ELSE
   aResult := unzip_NotSupported;
 END;
 Result:=aResult;

 IF ( aResult = unzip_ok ) AND ( ( hufttype AND 8 ) <> 0 ) THEN BEGIN {CRC at the end}
   dumpbits ( k AND 7 );
   needbits ( 16 );
   dumpbits ( 16 );
   needbits ( 16 );
   originalcrc := ( b AND $FFFF ) SHL 16;
   dumpbits ( 16 );
 END;

 crc32val:=not(crc32val);  {one's complement}
 if (originalcrc<>crc32val) then Result:=unzip_CRCErr;

 freemem(slide,SlideSize);
END;

Function UnZipAll(AStream:TStream; OutPath:string): Boolean;
 var
  r:TZIPRec;
  i:integer;
begin
  i := GetFirstInZip(AStream,r);
  Result := i = unzip_ok;
  while i = unzip_ok do
  begin
    i := UnZipFile(AStream,OutPath+r.FileName,r.HeaderOffset);
    if i = unzip_ok then
      i := GetNextInZip(r)
    else
      Result := False;
  end;
  CloseZipFile(r);
end;

Function UnZipAllFromFile(AFileName:string; OutPath:string): Boolean;
var
  F:TFileStream;
begin
  F:=TFileStream.Create(AFileName,0{fmOpenRead});
  try
    Result := UnZipAll(F, OutPath);
  finally
    F.Free;
  end;
end;

function UnZipAllFromResName(AResourceName:string; OutPath:string): Boolean;
var
  R: TResourceStream;
begin
  R := TResourceStream.Create(hInstance, AResourceName, RT_RCDATA);
  try
    Result := UnZipAll(R, OutPath);
  finally
    R.Free;
  end;
end;


end.

