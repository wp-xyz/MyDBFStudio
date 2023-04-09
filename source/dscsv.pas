unit DsCsv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Db;

Type
    TDsCSVErrorResponse          = (dscsvAbort, dscsvIgnore);

    TDsCSVProgressEvent          = Procedure(Sender : TObject; AProgress: LongInt; out StopIt: Boolean) of object;
    TDsCSVExportErrorEvent       = Procedure(Sender : TObject; Mess: string; RecNo: LongInt; out Response:TDsCSVErrorResponse) of object;

    { TDsCSV }

    TDsCSV                       = Class(TComponent)
     Private
      FDataset                   : TDataset;
      FCSVMap,
      FCSVFile,
      FDateFormat,
      FIgnoreStr                 : String;
      FFieldIndicator            : String;
      FAutoOpen,
      FExpHeader,
      FUseDelimiter,
      FSilentExport,
      FTrimData,
      FStop,
      FEmptyTable                : Boolean;
      FBeforeOpenTable,
      FAfterOpenTable,
      FBeforeCloseTable,
      FAfterCloseTable,
      FBeforeEmptyTable,
      FAfterEmptyTable,
      FBeforeExport,
      FAfterExport,
      FBeforeImport,
      FAfterImport,
      FOnAddRecord               : TNotifyEvent;
      FExportProgress,
      FImportProgress            : TDsCSVProgressEvent;
      FExportError               : TDsCSVExportErrorEvent;
      FMapItems,
      FDefaultInt                : Integer;
      FBufferSize                : LongInt;
      FFieldCache                : TList;
      FDecimalSeparator: Char;
      FFieldDelimiter: String;
      FFieldSeparator: String;

     Protected
      FFile                      : TextFile;

      Function CountMapItems() : Integer;
      Function GetMapItem(ItemIndex:Integer; out AField:Boolean) : String;
      Function GetCSVRecordItem(ItemIndex : Integer; CSVRecord : String) : String;
      Function BuildMap() : String;
      Function ExtractWord(Item: Integer;S, WordDelim: String): String;
      Function WordCount(const S, WordDelim: String): Integer;
      Function WordPosition(Item: Integer; const S, SubStr: string): Integer;

     Public
      Constructor Create(AOwner: TComponent); Override;

     Published
      Property Dataset : TDataset Read FDataset Write FDataset;
      Property CSVMap : String Read FCSVMap Write FCSVMap;
      Property CSVFile : String Read FCSVFile Write FCSVFile;
      property DecimalSeparator: Char read FDecimalSeparator write FDecimalSeparator;
      Property FieldSeparator: String Read FFieldSeparator Write FFieldSeparator;
      Property FieldDelimiter: String Read FFieldDelimiter Write FFieldDelimiter;
      Property FieldIndicator : String Read FFieldIndicator Write FFieldIndicator;
      Property AutoOpen : Boolean Read FAutoOpen Write FAutoOpen;
      Property IgnoreString : String Read FIgnoreStr Write FIgnoreStr;
      Property EmptyTable : Boolean Read FEmptyTable Write FEmptyTable;
      Property UseDelimiter : Boolean Read FUseDelimiter Write FUseDelimiter;
      Property SilentExport : Boolean Read FSilentExport Write FSilentExport;
      Property DateFormat : String Read FDateFormat Write FDateFormat;
      Property TrimData : Boolean Read FTrimData Write FTrimData;
      Property DefaultInt : Integer Read FDefaultInt Write FDefaultInt;
      Property BufferSize : LongInt Read FBufferSize Write FBufferSize;

      Property BeforeOpenTable : TNotifyEvent Read FBeforeOpenTable Write FBeforeOpenTable;
      Property AfterOpenTable : TNotifyEvent Read FAfterOpenTable Write FAfterOpenTable;
      Property BeforeCloseTable : TNotifyEvent Read FBeforeCloseTable Write FBeforeCloseTable;
      Property AfterCloseTable : TNotifyEvent Read FAfterCloseTable Write FAfterCloseTable;
      Property BeforeEmptyTable : TNotifyEvent Read FBeforeEmptyTable Write FBeforeEmptyTable;
      Property AfterEmptyTable : TNotifyEvent Read FAfterEmptyTable  Write FAfterEmptyTable;
      Property BeforeImport : TNotifyEvent Read FBeforeImport Write FBeforeImport;
      Property AfterImport : TNotifyEvent Read FAfterImport Write FAfterImport;
      Property BeforeExport : TNotifyEvent Read FBeforeExport Write FBeforeExport;
      Property AfterExport : TNotifyEvent Read FAfterExport Write FAfterExport;
      Property ExportProgress : TDsCSVProgressEvent Read FExportProgress Write FExportProgress;
      Property ImportProgress : TDsCSVProgressEvent Read FImportProgress Write FImportProgress;
      Property OnAddRecord : TNotifyEvent Read FOnAddRecord Write FOnAddRecord;
      Property ExportError : TDsCSVExportErrorEvent Read FExportError Write FExportError;
      Property ExportHeader : Boolean Read FExpHeader Write FExpHeader;

      Procedure CSVToDataset();
      Procedure DatasetToCSV();
    End;

implementation

{ TDsCSV }

function TDsCSV.CountMapItems(): Integer;
begin
 If FMapItems = 0 Then
  FMapItems:=WordCount(FCSVMap, FFieldSeparator);

 Result:=FMapItems;
end;

function TDsCSV.GetMapItem(ItemIndex: Integer; out AField: Boolean): String;
 Var S : String;
     P : ^ShortString;
begin
  If FFieldCache.Count < ItemIndex Then
  Begin
   S:=ExtractWord(ItemIndex, FCSVMap, FFieldSeparator);

   New(P);

   P^:=S;

   FFieldCache.Add(P);
  End
  Else
    S:=ShortString(FFieldCache.Items[ItemIndex - 1]^);

 AField:=True;

 If (Length(S) >= 1) And (S[1] = FFieldIndicator) Then
  Result:=Copy(S,2,Length(S) - 1)
 Else
  Begin
   AField:=False;

   Result:=S;
  End;
end;

function TDsCSV.GetCSVRecordItem(ItemIndex: Integer; CSVRecord: String): String;
 Var S : String;
begin
  If FUseDelimiter Then
    S:=ExtractWord(ItemIndex,CSVRecord,FFieldDelimiter + FFieldSeparator + FFieldDelimiter)
  Else
    S:=ExtractWord(ItemIndex,CSVRecord,FFieldSeparator);

  If FUseDelimiter Then
  Begin
    If (ItemIndex = 1) And (S[1] = FFieldDelimiter) Then
      Delete(S,1,1);

    If (ItemIndex = WordCount(CSVRecord, FFieldDelimiter + FFieldSeparator + FFieldDelimiter)) And
      (S[Length(S)] = FFieldDelimiter) Then
    Delete(S,Length(S),1);
  End;

  Result:=S;
end;

function TDsCSV.BuildMap(): String;
var
  I: Integer;
  S: String;
begin
  S := '';
  for I:=0 To FDataset.FieldCount - 1 do
    S := S + FFieldIndicator + FDataset.Fields[i].FieldName + FFieldSeparator;
  Delete(S, Length(S), 1);
  Result := S;
end;

function TDsCSV.ExtractWord(Item: Integer; S, WordDelim: String): String;
 Var First, Second : Integer;
begin
 First:=WordPosition(Item - 1,S,WordDelim);
 Second:=WordPosition(Item,S,WordDelim);

 If Second = 0 Then
  Second:=Length(S) + Length(WordDelim);

 If First = 1 Then
  First:=-Length(WordDelim);

 Result:=Copy(S,First + Length(WordDelim),Second - (First + Length(WordDelim)));

 If Item = 1 Then
  Delete(Result,Length(Result),1);
end;

function TDsCSV.WordCount(const S, WordDelim: String): Integer;
 Var I, Count : Integer;
begin
 Count:=0;

 For I:=1 To Length(S) Do
  If Copy(S,I,Length(WordDelim)) = WordDelim Then
   Inc(Count);

 Result:=Count + 1;
end;

function TDsCSV.WordPosition(Item: Integer; const S, SubStr: string): Integer;
 Var I,Count : Integer;
begin
 Count:=0;
 Result:=0;

 For I:=1 to Length(S) Do
  Begin
   If Copy(S,i,Length(SubStr)) = SubStr Then
    Inc(Count);

   If Count = Item Then
    Begin
     Result:=I;

     Break;
    End;
  End;
end;

constructor TDsCSV.Create(AOwner: TComponent);
begin
 Inherited Create(AOwner);

 FFieldDelimiter:='"';
 FIgnoreStr:='(ignore)';
 FAutoOpen:=True;
 FUseDelimiter:=True;
 FSilentExport:=False;
 FEmptyTable:=False;
 FFieldSeparator:=',';
 FFieldIndicator:='$';
 FDateFormat:='MM/DD/YY';
 FDecimalSeparator := '.';
 FBufferSize:=1024;
 FStop:=False;

 FBeforeOpenTable:=Nil;
 FAfterOpenTable:=Nil;
 FBeforeCloseTable:=Nil;
 FAfterCloseTable:=Nil;
 FBeforeEmptyTable:=Nil;
 FAfterEmptyTable:=Nil;
 FBeforeExport:=Nil;
 FAfterExport:=Nil;
 FBeforeImport:=Nil;
 FAfterImport:=Nil;
 FOnAddRecord:=Nil;
 FExpHeader := False;
end;

procedure TDsCSV.CSVToDataset();
var
  RecordString, SavedDateFmt: String;
  SavedDecSep: Char;
  I: Integer;
  C: LongInt;
  D: Boolean;
  F: Double;
  ErrorResponse: TDsCSVErrorResponse;
  Buffer: Pointer;
begin
  SavedDateFmt := FormatSettings.ShortDateFormat;
  SavedDecSep := FormatSettings.DecimalSeparator;
  FFieldCache := TList.Create;
  FMapItems := 0;
  GetMem(Buffer,FBufferSize);
  AssignFile(FFile, FCSVFile);
  try
    SetTextBuf(FFile,Buffer^,FBufferSize);
    Reset(FFile);

    if FAutoOpen then
    begin
      if Assigned(FBeforeOpenTable) then
        FBeforeOpenTable(Self);
      FDataset.Open;
      if Assigned(FAfterOpenTable) then
        FAfterOpenTable(Self);
    end;

    if Assigned(FBeforeExport) then
      FBeforeExport(Self);

    C := 0;

    FormatSettings.ShortDateformat := FDateFormat;
    FormatSettings.DecimalSeparator := FDecimalSeparator;

    FDataset.DisableControls;
    try
      while (not Eof(FFile)) and (not FStop) do
      begin
        Readln(FFile, RecordString);
        try
          FDataset.Append;
          for I := 1 To CountMapItems() do
            if Uppercase(GetMapItem(I,D)) <> Uppercase(FIgnoreStr) then
              case FDataset.FieldByName(GetMapItem(I,D)).DataType of
                ftInteger:
                  FDataset.FieldByName(GetMapItem(I,D)).AsInteger := StrToIntDef(Trim(GetCSVRecordItem(I,RecordString)), FDefaultInt);
                ftFloat:
                  FDataset.FieldByName(GetMapItem(I,D)).AsFloat := StrToFloatDef(Trim(GetCSVRecordItem(I,RecordString)), FDefaultInt);
                else
                  if FTrimData then
                    FDataset.FieldByName(GetMapItem(I,D)).AsString := Trim(GetCSVRecordItem(i,RecordString))
                  else
                    FDataset.FieldByName(GetMapItem(I,D)).AsString := GetCSVRecordItem(i,RecordString);
              end;
          FDataset.Post;
        except
          on E:Exception do
            if not FSilentExport then
              raise
            else
            if Assigned(FExportError) then
            begin
              FExportError(Self, E.Message, C, ErrorResponse);
              if ErrorResponse = dscsvAbort then
                Break;
            end;
        end;

        if Assigned(FOnAddRecord) then
          FOnAddRecord(Self);

        if Assigned(FExportProgress) then
          FExportProgress(Self, C, FStop);

        inc(C);
      end;
    finally
      FDataset.EnableControls;
    end;

    if Assigned(FAfterExport) then
      FAfterExport(Self);

    if FAutoOpen then
    begin
      if Assigned(FBeforeCloseTable) then
        FBeforeCloseTable(Self);
      FDataset.Close;
      if Assigned(FAfterCloseTable) then
        FAfterCloseTable(Self);
    end;
  finally
    CloseFile(FFile);
    FreeMem(Buffer);
    FormatSettings.ShortDateFormat := SavedDateFmt;
    FormatSettings.DecimalSeparator := SavedDecSep;
    FFieldCache.Free;
  end;
end;

procedure TDsCSV.DatasetToCSV();
var
  S, D, T: String;
  I: Integer;
  C: LongInt;
  B: Boolean;
  Buffer: Pointer = nil;
  SavedDecSep: char;
  SavedDateFmt: String;
begin
  FFieldCache := TList.Create;
  GetMem(Buffer,FBufferSize);
  SavedDecSep := FormatSettings.DecimalSeparator;
  SavedDateFmt := FormatSettings.ShortDateFormat;
  try
    FormatSettings.DecimalSeparator := FDecimalSeparator;
    FormatSettings.ShortDateFormat := FDateFormat;
    FMapItems:=0;
    AssignFile(FFile,FCSVFile);
    SetTextBuf(FFile,Buffer^,FBufferSize);

    if FEmptyTable then
    begin
      if Assigned(FBeforeEmptyTable) then
        FBeforeEmptyTable(Self);
      Rewrite(FFile);
      if Assigned(FAfterEmptyTable) then
        FAfterEmptyTable(Self);
    end else
      Append(FFile);

    if FAutoOpen then
    begin
      if Assigned(FBeforeOpenTable) then
        FBeforeOpenTable(Self);
      FDataset.Open;
      if Assigned(FAfterOpenTable) then
        FAfterOpenTable(Self);
    end;

    if Assigned(FBeforeImport) then
      FBeforeImport(Self);

    C:=0;
    FDataset.First;
    if Trim(FCSVMap) = '' then
      FCSVMap := BuildMap();
    FDataset.DisableControls;
    try
      if FExpHeader then
      begin
        S := '';
        for I := 1 To CountMapItems() do
        begin
          D := GetMapItem(I, B);
          if B then
            S := S + D + FFieldSeparator;
        end;
        Delete(S, Length(S), 1);
        Writeln(FFile, S);
      end;

      while (not FDataset.Eof) and (not FStop) do
      begin
        S := '';
        for I := 1 to CountMapItems do
        begin
          D := GetMapItem(I,B);
          if B then
          begin
            if FTrimData then
              T := Trim(FDataset.FieldByName(D).AsString)
            else
              T := FDataset.FieldByName(D).AsString;

            if FUseDelimiter then
              T := FFieldDelimiter + T + FFieldDelimiter;
            S := S + T + FFieldSeparator;
          end;
        end;
        Delete(S, Length(S), 1);
        Writeln(FFile,S);

        FDataset.Next;
        if Assigned(FImportProgress) then
          FImportProgress(Self, C, FStop);

        inc(C);
      end;
    finally
      FDataset.EnableControls;
    end;

    if Assigned(FAfterImport) then
      FAfterImport(Self);

    if FAutoOpen then
    begin
      if Assigned(FBeforeCloseTable) then
        FBeforeCloseTable(Self);
      FDataset.Close;
      if Assigned(FAfterCloseTable) then
        FAfterCloseTable(Self);
    end;

  finally
    CloseFile(FFile);
    FreeMem(Buffer);
    FFieldCache.Free;
    FormatSettings.DecimalSeparator := SavedDecSep;
    FormatSettings.ShortDateFormat := SavedDateFmt;
  end;
end;

end.

