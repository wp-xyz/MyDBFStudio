unit DsXls;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Type

    { TDsXlsFile }

    TDsXlsFile                    = class
     Private
      FStream                     : TFileStream;
      FStrNumber                  : String;
      FStrNumberDec               : String;
      FStrMaskNumber              : String;
      FStrMaskNumberDec           : String;
      FStrDate                    : String;
      FCodePage                   : Word;

      Procedure WriteByte(B : Byte);
      Procedure WriteWord(W : Word);
      Procedure WriteInt(I : Longint);
      Procedure WriteDbl(D : Double);
      Procedure WritePos(Row,Col,Format: Word; Fmt: Byte);
      Procedure WriteAgPos(Row,Col,Format: Word; Ag: TAlignment);

     Public
      constructor Create;
      Destructor Destroy; Override;

      Procedure PutGenStr(Row,Col,Format: Word; Fmt: Byte; S: string);
      Procedure PutGenExt(Row,Col,Format: Word; Fmt: Byte; E: Extended);
      Procedure PutAgStr(Row,Col: Word; Ag: TAlignment; S: string);
      Procedure PutAgExt(Row,Col: Word; Ag: TAlignment; E: Extended);
      Procedure PutAgInt(Row,Col: Word; Ag: TAlignment; I: Integer);
      Procedure PutAgWord(Row,Col: Word; Ag: TAlignment; W: Word);
      Procedure PutAgDay(Row,Col: Word; Ag: TAlignment; D: TDateTime);
      Procedure PutStr(Row,Col: Word; S: String);
      Procedure PutExt(Row,Col: Word; E: Extended);
      Procedure PutInt(Row,Col: Word; I: Integer);
      Procedure PutDay(Row,Col: Word; D: TDateTime);
      Procedure ColWidth(Col,Chars: Byte);
      Procedure Open(Fn : String);
      Procedure Close;

     Published
      Property StrFormatNumber : String Read FStrNumber Write FStrNumber;
      Property StrFormatNumberDec : String Read FStrNumberDec Write FStrNumberDec;
      Property StrFormatMaskNumber : String Read FStrMaskNumber Write FStrMaskNumber;
      Property StrFormatMaskNumberDec : String Read FStrMaskNumberDec Write FStrMaskNumberDec;
      Property StrFormatDate : String Read FStrDate Write FStrDate;
      Property CodePage: Word Read FCodePage write FCodePage;
    End;

implementation

{ TDsXlsFile }

procedure TDsXlsFile.WriteByte(B: Byte);
begin
 FStream.Write(B,1);
end;

procedure TDsXlsFile.WriteWord(W: Word);
begin
  FStream.Write(W,2);
end;

procedure TDsXlsFile.WriteInt(I: Longint);
begin
  FStream.Write(I,4);
end;

procedure TDsXlsFile.WriteDbl(D: Double);
begin
  FStream.Write(D,8);
end;

procedure TDsXlsFile.WritePos(Row, Col, Format: Word; Fmt: Byte);
begin
 WriteWord(Row - 1);
 WriteWord(Col - 1);

 WriteWord(Format);
 WriteByte(Fmt);
end;

procedure TDsXlsFile.WriteAgPos(Row, Col, Format: Word; Ag: TAlignment);
 Var A : Byte;
begin
 Case Ag Of
  taLeftJustify                      : A:=1;
  taRightJustify                     : A:=3;
  taCenter                           : A:=2;
  Else                                 A:=0;
 End;

 WritePos(Row,Col,Format,A);
end;

constructor TDsXlsFile.Create;
begin
 FStrNumber:='0';
 FStrNumberDec:='0.00';
 FStrMaskNumber:='# ### ##0';
 FStrMaskNumberDec:='# ### ##0.00';
 FStrDate:='dd/mm/yyyy';
end;

destructor TDsXlsFile.Destroy;
begin
 FStream.Free;
 Inherited Destroy;
end;

procedure TDsXlsFile.PutGenStr(Row, Col, Format: Word; Fmt: Byte; S: string);
 Var Len : Byte;
begin
 Len:=Length(S);

 WriteWord(4);                // String code
 WriteWord(8 + Len);          // Length

 WritePos(Row,Col,Format,Fmt);

 WriteByte(Len);

 FStream.Write(S[1],Len);
end;

procedure TDsXlsFile.PutGenExt(Row, Col, Format: Word; Fmt: Byte; E: Extended);
begin
 WriteWord(3);                // Double code
 WriteWord(15);               // Length

 WritePos(Row,Col,Format,Fmt);

 WriteDbl(E);
end;

procedure TDsXlsFile.PutAgStr(Row, Col: Word; Ag: TAlignment; S: string);
var
  Len: Integer;
begin
  Len := Length(S);
  if Len = 0 then
    exit;

  // Excel2 (used by this export) does not support strings longer than 255.
  if Len > 255 then begin
    SetLength(S, 255);
    Len := 255;
  end;

  WriteWord(4);                // String code
  WriteWord(8 + Len);          // Length

  WriteAgPos(Row, Col, 0, Ag);
  WriteByte(Len);

  FStream.Write(S[1], Len);
end;

procedure TDsXlsFile.PutAgExt(Row, Col: Word; Ag: TAlignment; E: Extended);
begin
 WriteWord(3);                // Double code
 WriteWord(15);               // Length

 WriteAgPos(Row,Col,$0400,Ag);

 WriteDbl(E);
end;

procedure TDsXlsFile.PutAgInt(Row, Col: Word; Ag: TAlignment; I: Integer);
begin
 If (I < 0) Or (I > $FFFF) Then
  PutAgExt(Row,Col,Ag,I)
 Else
  PutAgWord(Row,Col,Ag,I);
end;

procedure TDsXlsFile.PutAgWord(Row, Col: Word; Ag: TAlignment; W: Word);
begin
 WriteWord(2);                // Word code
 WriteWord(9);                // Length

 WriteAgPos(Row,Col,0,Ag);

 WriteWord(W);
end;

procedure TDsXlsFile.PutAgDay(Row, Col: Word; Ag: TAlignment; D: TDateTime);
begin
 WriteWord(3);                // Double code
 WriteWord(15);               // Length

 WriteAgPos(Row,Col,$0500,Ag);

 WriteDbl(D);
end;

procedure TDsXlsFile.PutStr(Row, Col: Word; S: String);
begin
 PutAgStr(Row,Col,taLeftJustify,s);
end;

procedure TDsXlsFile.PutExt(Row, Col: Word; E: Extended);
begin
 PutAgExt(Row,Col,taRightJustify,E);
end;

procedure TDsXlsFile.PutInt(Row, Col: Word; I: Integer);
begin
 PutAgInt(Row,Col,taRightJustify,I);
end;

procedure TDsXlsFile.PutDay(Row, Col: Word; D: TDateTime);
begin
 PutAgDay(Row,Col,taLeftJustify,D);
end;

procedure TDsXlsFile.ColWidth(Col, Chars: Byte);
begin
 WriteWord(36);               // ColWidth code
 WriteWord(4);                // Length

 WriteByte(Col - 1);
 WriteByte(Col - 1);

 WriteWord(225 + 255 * Chars);
end;

procedure TDsXlsFile.Open(Fn: String);

  procedure PutFormat(F: String);
  var
    len: Byte;
  begin
    len := Length(F);
     WriteWord(30);                // Format code
     WriteWord(1 + len);           // Length
     WriteByte(len);
     FStream.Write(F[1],len);
  end;

begin
  FStream.Free;
  FStream := TFileStream.Create(Fn, fmCreate);

  // Write BOF record
  WriteWord($0009);                 // BOF (Excel2)
  WriteWord(4);                     // Record length
  WriteWord($0200);                 // BIFF version
  WriteWord($0010);                 // XLS document

  // Write CODEPAGE record
  if FCodePage > 0 then
  begin
    WriteWord($0042);               // ID of CODEPAGE record
    WriteWord(2);                   // Record length
    WriteWord(FCodePage);           // Code page value
  end;

  // Write DIMENSION record
  WriteWord(0);                     // ID of DIMENSION record
  WriteWord(8);                     // Length
  WriteWord(0);                     // MinSaveRecs
  WriteWord($FFFF);                 // MaxSaveRecs
  WriteWord(0);                     // MinSaveCols
  WriteWord(512);                   // MaxSaveCols

  PutFormat('General');
  PutFormat(FStrNumber);
  PutFormat(FStrNumberDec);
  PutFormat(FStrMaskNumber);
  PutFormat(FStrMaskNumberDec);
  PutFormat(FStrDate);
end;

procedure TDsXlsFile.Close;
begin
  if FStream = Nil then
    Exit;

  WriteWord(10);                    // EOF
  WriteWord(0);

  FStream.Free;
  FStream := nil;
end;

end.

