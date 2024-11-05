unit DsBiffFile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

Const
     LEN_BOF_BIFF5              = 6;
     LEN_EOF_BIFF5              = 0;
     LEN_DIM_BIFF5              = 10;
     LEN_RECORDHEADER           = 4;

     RT5_CELL_EMPTY             = 1;
     RT5_CELL_INT               = 2;
     RT5_CELL_DOUBLE            = 3;
     RT5_CELL_LABEL             = 4;
     RT5_CELL_BOOL              = 5;

     DOCTYPE_XLS                = $0010;
     DOCTYPE_XLC                = $0020;
     DOCTYPE_XLM                = $0040;
     DOCTYPE_XLW                = $0100;

     MAX_DIM                    = 65535;

Type
     LabelString                = String[255];
     rgbAttrib                  = Array[0..2] of Byte;
     TCellCoord                 = Word;
     TCellAttribute             = (caHidden, caLocked, caShaded,
                                   caBottomBorder, caTopBorder, caRightBorder, caLeftBorder,
                                   caFont1, caFont2, caFont3, caFont4,
                                   caLeft, caCenter, caRight, caFill);

     TCellAttributes            = Set Of TCellAttribute;

     TCellType                  = (ctBlank, ctInteger, ctDouble, ctLabel, ctBoolean);

     { TDsBiffFile }

     TDsBiffFile                = Class(TObject)
      Protected
       FStream                  : TStream;

       Function Write(const Buffer; Count: Integer): Longint;

       Procedure Internal_WriteBOF();
       Procedure Internal_WriteEOF();
       Procedure WriteRecordHeader(ALen, AType: Integer);
       Procedure SetAttributes(ARow, ACol: TCellCoord; AAttributes: TCellAttributes= []);

       Function GetRgbAttrib(AAttributes: TCellAttributes): rgbAttrib;

      Public
       Procedure SetDimensions(AFirstRow: Word = 1; ALastRow: Word = MAX_DIM;
                               AFirstCol: Word = 1; ALastCol: Word = MAX_DIM);
       Procedure WriteCell(ARow, ACol: TCellCoord; AData: Variant;
                           ACellType: TCellType; AAttributes: TCellAttributes = []);
       Procedure WriteStringCell(ARow, ACol: TCellCoord; AData: LabelString;
                                 AAttributes: TCellAttributes = []);
       Procedure WriteWordCell(ARow, ACol: TCellCoord; AData: Word;
                               AAttributes: TCellAttributes = []);
       Procedure WriteDoubleCell(ARow, ACol: TCellCoord; AData: Double;
                                 AAttributes: TCellAttributes = []);
       Procedure WriteBooleanCell(ARow, ACol: TCellCoord; AData: Boolean;
                                  AAttributes: TCellAttributes = []);
       Procedure ClearCell(ARow, ACol: TCellCoord; AAttributes: TCellAttributes= []);
       Procedure SetColRangeWidth(AFirstCol, ALastCol: Byte; AWidth: Word);
       Procedure SetColWidth(ACol: Byte; AWidth: Word);
       Procedure WriteCellNote(ARow, ACol: TCellCoord; AText: LabelString);
       Procedure WriteFontByName(AHeight: Word; AFontStyle: TFontStyles; AFontName: LabelString);
       Procedure WriteFont(AFont: TFont);
       Procedure SetRowAttributes(ARow, FirstDefCol, ALastDefCol: TCellCoord;
                                  ARowHeight: Word; ADefAttibutes: Boolean = True;
                                  AAttributes: TCellAttributes = [];
                                  AOffset: Word = 0);
       Procedure SetDefaultRowHeight(AHeight: Word);

       Constructor Create(AStream: TStream);
       Destructor Destroy; override;
     End;

implementation

Uses Variants;

{ TDsBiffFile }

function TDsBiffFile.Write(const Buffer; Count: Integer): Longint;
begin
 Result:=FStream.Write(Buffer,Count);
end;

procedure TDsBiffFile.Internal_WriteBOF();
 Var aBuf : Array[0..1] Of Word;
begin
 aBuf[0]:=2;
 aBuf[1]:=10;

 WriteRecordHeader(4,9);

 Write(aBuf,SizeOf(aBuf));
end;

procedure TDsBiffFile.Internal_WriteEOF();
begin
 WriteRecordHeader(0,$000A);
end;

procedure TDsBiffFile.WriteRecordHeader(ALen, AType: Integer);
 Var aBuf : Array[0..1] Of Word;
begin
 aBuf[0]:=AType;
 aBuf[1]:=ALen;

 Write(aBuf,LEN_RECORDHEADER);
end;

procedure TDsBiffFile.SetAttributes(ARow, ACol: TCellCoord;
  AAttributes: TCellAttributes);
 Var aBuf : Array[0..1] Of TCellCoord;
     AAttribute : rgbAttrib;
begin
 aBuf[0]:=ARow;
 aBuf[1]:=ACol;

 AAttribute:=GetRgbAttrib(AAttributes);

 Write(aBuf,SizeOf(aBuf));
 Write(AAttribute,SizeOf(AAttribute));
end;

function TDsBiffFile.GetRgbAttrib(AAttributes: TCellAttributes): rgbAttrib;
begin
 Result[0]:=0;
 Result[1]:=0;
 Result[2]:=0;

 If caHidden In AAttributes Then  { byte 0 bit 7 }
  Result[0]:=Result[0] + 128;

 If caLocked In AAttributes Then  { byte 0 bit 6 }
  Result[0]:=Result[0] + 64;

 If caFont2 In AAttributes Then
  Result[1]:=Result[1] + 64
 Else
  If caFont3 In AAttributes Then
   Result[1]:=Result[1] + 128
  Else
   If caFont4 In AAttributes Then
    Result[1]:=Result[1] + 192;

 If caShaded In AAttributes Then  { byte 2 bit 7 }
  Result[2]:=Result[2] + 128;

 If caBottomBorder In AAttributes Then  { byte 2 bit 6 }
  Result[2]:=Result[2] + 64;

 If caTopBorder In AAttributes Then  { byte 2 bit 5 }
  Result[2]:=Result[2] + 32;

 If caRightBorder In AAttributes Then  { byte 2 bit 4 }
  Result[2]:=Result[2] + 16;

 If caLeftBorder In AAttributes Then  { byte 2 bit 3 }
  Result[2]:=Result[2] + 8;

 If caLeft In AAttributes Then  { byte 2 bit 1 }
  Result[2]:=Result[2] + 1
 Else
  If caCenter In AAttributes Then  { byte 2 bit 1 }
   Result[2]:=Result[2] + 2
  Else
   If caRight In AAttributes Then  { byte 2, bit 0 dan bit 1 }
    Result[2]:=Result[2] + 3;

 If caFill In AAttributes Then  { byte 2, bit 0 }
  Result[2]:=Result[2] + 4;
end;

procedure TDsBiffFile.SetDimensions(AFirstRow: Word; ALastRow: Word;
  AFirstCol: Word; ALastCol: Word);
 Var aBuf : Array[0..3] Of Word;
begin
 aBuf[0]:=AFirstRow;
 aBuf[1]:=ALastRow;
 aBuf[2]:=AFirstCol;
 aBuf[3]:=ALastCol;

 WriteRecordHeader(8,$0000);
 Write(aBuf,SizeOf(aBuf));
end;

procedure TDsBiffFile.WriteCell(ARow, ACol: TCellCoord; AData: Variant;
  ACellType: TCellType; AAttributes: TCellAttributes);
begin
 If VarIsNull(AData) Then
  ACellType:=ctBlank;

 Case ACellType Of
  ctBlank            : ClearCell(ARow,ACol,AAttributes);
  ctInteger          : WriteWordCell(ARow,ACol,Integer(AData),AAttributes);
  ctDouble           : WriteDoubleCell(ARow,ACol,Double(AData),AAttributes);
  ctLabel            : WriteStringCell(ARow,ACol,String(AData),AAttributes);
  ctBoolean          : WriteBooleanCell(ARow,ACol,Boolean(AData),AAttributes);
 End;
end;

procedure TDsBiffFile.WriteStringCell(ARow, ACol: TCellCoord;
  AData: LabelString; AAttributes: TCellAttributes);
 Var ALen : Byte;
begin
 ALen:=Length(AData);

 WriteRecordHeader(ALen + 8,RT5_CELL_LABEL);

 SetAttributes(ARow,ACol,AAttributes);

 Write(ALen,SizeOf(ALen));
 Write(Pointer(String(AData))^,ALen);
 //Write(String(AData),ALen);
end;

procedure TDsBiffFile.WriteWordCell(ARow, ACol: TCellCoord; AData: Word;
  AAttributes: TCellAttributes);
begin
 WriteRecordHeader(9,RT5_CELL_INT);

 SetAttributes(ARow,ACol,AAttributes);

 Write(AData,2);
end;

procedure TDsBiffFile.WriteDoubleCell(ARow, ACol: TCellCoord; AData: Double;
  AAttributes: TCellAttributes);
begin
 WriteRecordHeader(15,RT5_CELL_DOUBLE);

 SetAttributes(ARow,ACol,AAttributes);

 Write(AData,8);
end;

procedure TDsBiffFile.WriteBooleanCell(ARow, ACol: TCellCoord; AData: Boolean;
  AAttributes: TCellAttributes);
 Var ABoolResult : Byte;
begin
 WriteRecordHeader(9,RT5_CELL_BOOL);

 SetAttributes(ARow,ACol,AAttributes);

 If AData Then
  ABoolResult:=1
 Else
  ABoolResult:=0;

 Write(ABoolResult,SizeOf(ABoolResult));

 ABoolResult:=0;

 Write(ABoolResult,SizeOf(ABoolResult));
end;

procedure TDsBiffFile.ClearCell(ARow, ACol: TCellCoord;
  AAttributes: TCellAttributes);
begin
 WriteRecordHeader(7,RT5_CELL_EMPTY);

 SetAttributes(ARow,ACol,AAttributes);
end;

procedure TDsBiffFile.SetColRangeWidth(AFirstCol, ALastCol: Byte; AWidth: Word);
 Var aBuf : Array[0..1] Of Byte;
begin
 aBuf[0]:=AFirstCol;
 aBuf[1]:=ALastCol;

 WriteRecordHeader(4,$0024);

 Write(aBuf,2);
 Write(AWidth,2);
end;

procedure TDsBiffFile.SetColWidth(ACol: Byte; AWidth: Word);
begin
 SetColRangeWidth(ACol,ACol,AWidth);
end;

procedure TDsBiffFile.WriteCellNote(ARow, ACol: TCellCoord; AText: LabelString);
 Var aBuf : Array[0..2] Of Word;
begin
 aBuf[0]:=ARow;
 aBuf[1]:=ACol;
 aBuf[2]:=Length(AText);

 WriteRecordHeader(aBuf[2] + 6,28);

 Write(aBuf,6);
 Write(Pointer(String(AText))^,aBuf[2]);
end;

procedure TDsBiffFile.WriteFontByName(AHeight: Word; AFontStyle: TFontStyles;
  AFontName: LabelString);
 Var ALen : Byte;
     AStyle : Array[0..1] Of Byte;
begin
 ALen:=Length(AFontName);

 WriteRecordHeader(ALen + 5 ,$0031);

 Write(AHeight, 2);

 AStyle[0]:=0;
 AStyle[1]:=0;

 If fsBold In AFontStyle Then
  AStyle[0]:=AStyle[0] + 1;

 If fsItalic In AFontStyle Then
  AStyle[0]:=AStyle[0] + 2;

 If fsUnderline In AFontStyle Then
  AStyle[0]:=AStyle[0] + 4;

 If fsStrikeOut In AFontStyle Then
  AStyle[0]:=AStyle[0] + 8;

 Write(AStyle,SizeOf(AStyle));
 Write(ALen,1);
 Write(Pointer(String(AFontName))^,ALen);
end;

procedure TDsBiffFile.WriteFont(AFont: TFont);
begin
 WriteFontByName(AFont.Size * 20,AFont.Style,AFont.Name);
end;

procedure TDsBiffFile.SetRowAttributes(ARow, FirstDefCol,
  ALastDefCol: TCellCoord; ARowHeight: Word; ADefAttibutes: Boolean;
  AAttributes: TCellAttributes; AOffset: Word);
 Var aBuf : Array [0..4] Of Word;
     aByte : Byte;
     AAttribute : rgbAttrib;
begin
 WriteRecordHeader(13,$0008);

 aBuf[0]:=ARow;
 aBuf[1]:=FirstDefCol;
 aBuf[2]:=ALastDefCol + 1;
 aBuf[3]:=ARowHeight;
 aBuf[4]:=0;

 Write(aBuf,10);

 If ADefAttibutes Then
  aByte:=1
 Else
  aByte:=0;

 AAttribute:=GetRgbAttrib(AAttributes);

 Write(aByte,SizeOf(aByte));
 Write(AOffset,SizeOf(AOffset));
 Write(AAttribute,SizeOf(AAttribute));
end;

procedure TDsBiffFile.SetDefaultRowHeight(AHeight: Word);
begin
 WriteRecordHeader(2,$0025);
 Write(AHeight,2);
end;

constructor TDsBiffFile.Create(AStream: TStream);
begin
 FStream:=AStream;

 Internal_WriteBOF();
end;

destructor TDsBiffFile.Destroy;
begin
 Internal_WriteEOF();

 Inherited Destroy;
end;

end.

