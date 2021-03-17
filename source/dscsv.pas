unit DsCsv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Db;

Type
    TDsCSVErrorResponse          = (dscsvAbort, dscsvIgnore);

    TDsCSVProgressEvent          = Procedure(Sender : TObject; AProgress: LongInt; var StopIt: Boolean) of object;
    TDsCSVExportErrorEvent       = Procedure(Sender : TObject; Mess: string; RecNo: LongInt; var Response:TDsCSVErrorResponse) of object;

    { TDsCSV }

    TDsCSV                       = Class(TComponent)
     Private
      FDataset                   : TDataset;
      FCSVMap,
      FCSVFile,
      FDateFormat,
      FIgnoreStr                 : String;
      FSeprator,
      FDelimiter,
      FFieldIndicator            : String;
      FAutoOpen,
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

     Protected
      FFile                      : TextFile;

      Function CountMapItems() : Integer;
      Function GetMapItem(ItemIndex:Integer; Var AField:Boolean) : String;
      Function GetCSVRecordItem(ItemIndex : Integer; CSVRecord : String) : String;
      Function BuildMap() : String;
      Function ExtractWord(Item: Integer;S, WordDelim: String): String;
      Function WordCount(const S ,WordDelim: String): Integer;
      Function WordPosition(Item: Integer; const S, SubStr: string): Integer;

     Public
      Constructor Create(AOwner: TComponent); Override;

     Published
      Property Dataset : TDataset Read FDataset Write FDataset;
      Property CSVMap : String Read FCSVMap Write FCSVMap;
      Property CSVFile : String Read FCSVFile Write FCSVFile;
      Property Separator : String Read FSeprator Write FSeprator;
      Property FieldIndicator : String Read FFieldIndicator Write FFieldIndicator;
      Property AutoOpen : Boolean Read FAutoOpen Write FAutoOpen;
      Property IgnoreString : String Read FIgnoreStr Write FIgnoreStr;
      Property Delimiter : String Read FDelimiter Write FDelimiter;
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

      Procedure CSVToDataset();
      Procedure DatasetToCSV();
    End;

implementation

{ TDsCSV }

function TDsCSV.CountMapItems(): Integer;
begin
 If FMapItems = 0 Then
  FMapItems:=WordCount(FCSVMap,FSeprator);

 Result:=FMapItems;
end;

function TDsCSV.GetMapItem(ItemIndex: Integer; var AField: Boolean): String;
 Var S : String;
     P : ^ShortString;
begin
 If FFieldCache.Count < ItemIndex Then
  Begin
   S:=ExtractWord(ItemIndex,FCSVMap,FSeprator);

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
  S:=ExtractWord(ItemIndex,CSVRecord,FDelimiter + FSeprator + FDelimiter)
 Else
  S:=ExtractWord(ItemIndex,CSVRecord,FSeprator);

 If FUseDelimiter Then
  Begin
   If (ItemIndex = 1) And (S[1] = FDelimiter) Then
    Delete(S,1,1);

   If (ItemIndex = WordCount(CSVRecord,FDelimiter + FSeprator + FDelimiter)) And
      (S[Length(S)] = FDelimiter) Then
    Delete(S,Length(S),1);
  End;

 Result:=S;
end;

function TDsCSV.BuildMap(): String;
 Var I : Integer;
     S : String;
begin
 S:='';

 For I:=0 To FDataset.FieldCount - 1 Do
  S:=S + FFieldIndicator + FDataset.Fields[i].FieldName + FSeprator;

 Delete(S,Length(S),1);

 Result:=S;
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

 FDelimiter:='"';
 FIgnoreStr:='(ignore)';
 FAutoOpen:=True;
 FUseDelimiter:=True;
 FSilentExport:=False;
 FEmptyTable:=False;
 FSeprator:=',';
 FFieldIndicator:='$';
 FDateFormat:='MM/DD/YY';
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
end;

procedure TDsCSV.CSVToDataset();
 Var RecordString,Temp : String;
     I : Integer;
     C : LongInt;
     D : Boolean;
     F : Real;
     ErrorResponse : TDsCSVErrorResponse;
     Buffer : Pointer;
begin
 FFieldCache:=TList.Create;
 FMapItems:=0;

 GetMem(Buffer,FBufferSize);

 AssignFile(FFile,FCSVFile);

 SetTextBuf(FFile,Buffer^,FBufferSize);

 Reset(FFile);

 If FAutoOpen Then
  Begin
   If Assigned(FBeforeOpenTable) Then
    FBeforeOpenTable(Self);

   FDataset.Open;

   If Assigned(FAfterOpenTable) Then
    FAfterOpenTable(Self);
  End;

 If Assigned(FBeforeExport) Then
  FBeforeExport(Self);

 C:=0;
 Temp:=ShortDateFormat;
 ShortDateFormat:=FDateFormat;

 FDataset.DisableControls;

 While (Not Eof(FFile)) And (Not FStop) Do
  Begin
   Readln(FFile,RecordString);

   Try
     FDataset.Append;

     For I:=1 To CountMapItems() Do
      If Uppercase(GetMapItem(I,D)) <> Uppercase(FIgnoreStr) Then
       Case FDataset.FieldByName(GetMapItem(I,D)).DataType Of
            ftInteger          : FDataset.FieldByName(GetMapItem(I,D)).AsInteger:=StrToIntDef(Trim(GetCSVRecordItem(I,RecordString)),FDefaultInt);
            ftFloat            : Begin
                                  Try
                                    F:=StrToFloat(Trim(GetCSVRecordItem(I,RecordString)));
                                  Except
                                    F:=FDefaultInt;
                                  End;

                                  FDataset.FieldByName(GetMapItem(I,D)).AsFloat:=F;
                                 End;
            Else                 If FTrimData Then
                                  FDataset.FieldByName(GetMapItem(I,D)).AsString:=Trim(GetCSVRecordItem(i,RecordString))
                                 Else
                                  FDataset.FieldByName(GetMapItem(I,D)).AsString:=GetCSVRecordItem(i,RecordString);
       End;

     FDataset.Post;
   Except
     On E:Exception Do
      If Not FSilentExport Then
       Raise
      Else
       If Assigned(FExportError) Then
        Begin
         FExportError(Self,E.Message,C,ErrorResponse);

         If ErrorResponse = dscsvAbort Then
          Break;
        End;
   End;

   If Assigned(FOnAddRecord) Then
    FOnAddRecord(Self);

   If Assigned(FExportProgress) Then
    FExportProgress(Self,C,FStop);

   Inc(C);
  End;

 FDataset.EnableControls;

 If Assigned(FAfterExport) Then
  FAfterExport(Self);

 If FAutoOpen Then
  Begin
   If Assigned(FBeforeCloseTable) Then
    FBeforeCloseTable(Self);

   FDataset.Close;

   If Assigned(FAfterCloseTable) Then
    FAfterCloseTable(Self);
  End;

 CloseFile(FFile);

 FreeMem(Buffer);

 ShortDateFormat:=Temp;

 FFieldCache.Free;
end;

procedure TDsCSV.DatasetToCSV();
 Var S,D,T : String;
     I : Integer;
     C : LongInt;
     B : Boolean;
     Buffer : Pointer;
begin
 FFieldCache:=TList.Create;

 FMapItems:=0;

 GetMem(Buffer,FBufferSize);

 AssignFile(FFile,FCSVFile);

 SetTextBuf(FFile,Buffer^,FBufferSize);

 If FEmptyTable Then
  Begin
   If Assigned(FBeforeEmptyTable) Then
    FBeforeEmptyTable(Self);

   Rewrite(FFile);

   If Assigned(FAfterEmptyTable) Then
    FAfterEmptyTable(Self);
  End
 Else
  Append(FFile);

 If FAutoOpen Then
  Begin
   If Assigned(FBeforeOpenTable) Then
    FBeforeOpenTable(Self);

   FDataset.Open;

   If Assigned(FAfterOpenTable) Then
    FAfterOpenTable(Self);
  End;

 If Assigned(FBeforeImport) Then
  FBeforeImport(Self);

 C:=0;

 FDataset.First;

 If Trim(FCSVMap) = '' Then
  FCSVMap:=BuildMap();

 FDataset.DisableControls;

 While (Not FDataset.Eof) And (Not FStop) Do
  Begin
   S:='';

   For I:=1 To CountMapItems() Do
    Begin
     D:=GetMapItem(I,B);

     If B Then
      Begin
       If FTrimData Then
        T:=Trim(FDataset.FieldByName(D).AsString)
       Else
        T:=FDataset.FieldByName(D).AsString;
      End
     Else
      T:=D;

     If FUseDelimiter Then
      T:=FDelimiter + T + FDelimiter;

     S:=S + T + FSeprator;
    End;

   Delete(S,Length(S),1);

   Writeln(FFile,S);

   FDataset.Next;

   If Assigned(FImportProgress) Then
    FImportProgress(Self,C,FStop);

   Inc(C);
  End;

 FDataset.EnableControls;

 If Assigned(FAfterImport) Then
  FAfterImport(Self);

 If FAutoOpen Then
  Begin
   If Assigned(FBeforeCloseTable) Then
    FBeforeCloseTable(Self);

   FDataset.Close;

   If Assigned(FAfterCloseTable) Then
    FAfterCloseTable(Self);
  End;

 CloseFile(FFile);

 FreeMem(Buffer);

 FFieldCache.Free;
end;

end.

