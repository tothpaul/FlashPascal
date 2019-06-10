unit FontBuilder;

interface

uses
  Windows, Classes, SysUtils, Graphics, SWF;

function FontGlyphs(const Font: string; Styles: TFontStyles; const Text: string): string;

implementation

uses
  Compiler, ShapeBuilder;

function BuildGlyphs(DC: hDC; List: TStrings; Min, Max: Integer; const TextMetric: TTextMetric; var Layout: string; const Text: string): string;
var
  i        : Integer;
  cSize    : Cardinal;
  cBuffer  : array of Byte;
  cMetrics : TGLYPHMETRICS;
  cMatrix  : TMAT2;
  cIndex   : Cardinal;
  cLength  : Cardinal;
  cHeader  : PTTPolygonHeader;
  cCurve   : PTTPolyCurve;
  px, py   : Double;
  cx, cy   : Double;
  cPoint   : PPointfx;
  cCount   : Integer;
  cWidth   : Integer;

  cGlyph   : TShape;
  cBounds  : string;

  function FixToX(const AFix: TFixed): Double;
  begin
    Result := (AFix.fract/65536.0 + AFix.value);
  end;

  function FixToY(const AFix: TFixed): Double;
  begin
    Result := - (AFix.fract/65536.0 + AFix.value);
  end;

begin
  FillChar(cMatrix, SizeOf(cMatrix), 0);
  cMatrix.eM11.value := 1;
  cMatrix.eM22.value := 1;

  cGlyph := TShape.Create;
  try

    Result := '';
    Layout := SWFshort(TextMetric.tmAscent) + SWFshort(TextMetric.tmDescent) + SWFshort(TextMetric.tmExternalLeading);
    cBounds := '';


    if Min > 32 then
    begin
      Result := Result + #32;
      GetCharWidth(DC, 32, 32, cWidth);
      Layout := Layout + SWFshort(cWidth);
      cBounds := cBounds + SWFRect(0,0,0,0);
      List.Add(#$10#$00);
    end;

    for i := Min to Max do
    begin
      if (Text <> '') and (Pos(Chr(i), Text) = 0) then
        Continue;
        
      cSize := GetGlyphOutline(DC, i, GGO_NATIVE, cMetrics, 0, nil, cMatrix);
      if (cSize = 0) or (cSize = GDI_ERROR) then
      begin
        if i = 32 then
        begin
          Result := Result + #32;
          GetCharWidth(DC, 32, 32, cWidth);
          Layout := Layout + SWFshort(cWidth);
          cBounds := cBounds + SWFRect(0,0,0,0);
          List.Add(#$10#$00);
        end;
        Continue;
      end;

      SetLength(cBuffer, cSize);
      cSize := GetGlyphOutline(DC, i, GGO_NATIVE, cMetrics, cSize, @cBuffer[0], cMatrix);
      if (cSize = 0) or (cSize = GDI_ERROR) then
        Continue;

      cGlyph.Clear;
      //AssignFile(Output,'Glyph' + IntToStr(i) + '.txt');
      //Rewrite(Output);

      cIndex := 0;
      while cIndex < cSize do // for Each Poly
      begin
        cHeader := @cBuffer[cIndex];
        if cHeader.dwType <> TT_POLYGON_TYPE then
          raise Exception.Create('Unsupported font');

        px := FixToX(cHeader.pfxStart.x);
        py := FixToY(cHeader.pfxStart.y);

        if cIndex = 0 then
          cGlyph.beginFill(px, py)
        else
          cGlyph.moveTo(px, py);

        cLength := cIndex + cHeader.cb;
        Inc(cIndex, SizeOf(TTPOLYGONHEADER)); // First poly
        while cIndex < cLength do // for each poly
        begin
          cCurve := @cBuffer[cIndex]; // current curve
          cPoint := @cCurve.apfx;
          case cCurve.wType of
            TT_PRIM_LINE:
              for cCount := 1 to cCurve.cpfx do
              begin
                px := FixToX(cPoint.x);
                py := FixToY(cPoint.y);
                Inc(cPoint);
                cGlyph.lineTo(px, py);
              end;
            TT_PRIM_QSPLINE:
              for cCount := 1 to cCurve.cpfx - 1 do
              begin
                px := FixToX(cPoint.x);
                py := FixToY(cPoint.y);
                Inc(cPoint);
                cx := FixToX(cPoint.x);
                cy := FixToY(cPoint.y);
                if cCount < cCurve.cpfx - 1 then
                begin
                  cx := (px + cx) / 2;
                  cy := (py + cy) / 2;
                end;
                cGlyph.curveTo(px, py, cx, cy);
              end;
          else
            raise Exception.Create('Unsupported font');
          end;
          Inc(cIndex, SizeOf(TTPOLYCURVE) + Pred(cCurve.cpfx) * SizeOf(TPOINTFX));
        end;
      end;
      Result := Result + Chr(i);
      Layout := Layout + SWFshort(cMetrics.gmCellIncX);
      cBounds := cBounds
               + SWFRect(
                 cMetrics.gmptGlyphOrigin.X,
                 cMetrics.gmptGlyphOrigin.Y,
                 cMetrics.gmBlackBoxX,
                 cMetrics.gmBlackBoxY
               );
      List.Add(#$10 + cGlyph.GetCode);

      //CloseFile(Output);
    end;

    Layout := Layout + cBounds + #0#0; // no kerming

  finally
    cGlyph.Free;
  end;
end;

function FontGlyphs(const Font: string; Styles: TFontStyles; const Text: string): string;
var
  cFlags     : Byte;
  cGlyphs    : TStringList;
  cFont      : TFont;
  cDC        : HDC;
  cOld       : hFont;
  cTextMetric: TTextMetric;
  cMin, cMax : Integer;
  cChars     : string;
  cIndex     : Integer;
  cOffset    : Integer;
  cWideOfs   : Boolean;
  cLayout    : string;
begin
  cGlyphs := TStringList.Create;
  cFont := TFont.Create;
  try
    cFont.Name := Font;
    cFont.Height := -20*1024;//size;
    cFont.Style := Styles;
    cDC := CreateCompatibleDC(GetDC(0));
    try
      cOld := SelectObject(cDC, cFont.Handle);
      GetTextMetrics(cDC, cTextMetric);
      cMin := Ord(cTextMetric.tmFirstChar);
      cMax := Ord(cTextMetric.tmLastChar);
      if cMax > 255 then
        cMax := 255;
      //cMin := Ord('A');//cMin + 5;
      //cMax := Ord('C');//cMin;
      cChars := BuildGlyphs(cDC, cGlyphs, cMin, cMax, cTextMetric, cLayout, Text);
      SelectObject(cDC, cOld);
    finally
      DeleteDC(cDC);
    end;

    cOffset := Length(cChars) * 2 + 2;
    for cIndex := 0 to cGlyphs.Count - 1 do
      Inc(cOffset, Length(cGlyphs[cIndex]));
    cWideOfs := cOffset > $FFFF;

    cFlags := 4 + 128; // wide + has_layout

    if fsBold in Styles then
      cFlags := cFlags or 1;
    if fsItalic in Styles then
      cFlags := cFlags or 2;
    if cWideOfs then
      cFlags := cFlags or 8;

    Result := SWFshort(ResourceID)
            + Chr(cFlags)
            + #1 // lang
            + Chr(Length(Font) + 1)
            + Font + #0
            + SWFShort(Length(cChars));

    if cWideOfs then
      cOffset := Length(cChars) * 4 + 4
    else
      cOffset := Length(cChars) * 2 + 2;

    for cIndex := 0 to cGlyphs.Count - 1 do
    begin
      if cWideOfs then
        Result := Result + SWFlong(cOffset)
      else
        Result := Result + SWFshort(cOffset);
      Inc(cOffset, Length(cGlyphs[cIndex]));
    end;
    if cWideOfs then
      Result := Result + SWFlong(cOffset)
    else
      Result := Result + SWFshort(cOffset);

    for cIndex := 0 to cGlyphs.Count - 1 do
      Result := Result + cGlyphs[cIndex];
    for cIndex := 1 to Length(cChars) do
      Result := Result + cChars[cIndex] + #0;

    Result := SWFlhead(75, Result + cLayout);// DefineFont3
  finally
    cFont.Free;
    cGlyphs.Free;
  end;
end;

end.
