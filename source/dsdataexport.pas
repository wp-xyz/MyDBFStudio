unit DsDataExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Db;

Type
    TDsDataExport               = Class;

    { TDsExportField }

    TDsExportField              = Class(TCollectionItem)
     Private
      FDataField                : String;
      FSave                     : Boolean;

      Function GetField: TField;
      Function GetDataSet: TDataSet;

     Protected
      Function GetDisplayName : String; Override;

     Public
      Constructor Create(lCollection: TCollection); Override;
      Procedure Assign(Source: TPersistent); Override;

      Property DataSet : TDataSet Read GetDataSet;
      Property Field : TField Read GetField;

     Published
      Property DataField : String Read FDataField Write FDataField;
      Property Save : Boolean Read FSave Write FSave Default True;
    End;

    TDsExportFieldClass         = Class Of TDsExportField;

    { TDsExportFields }

    TDsExportFields             = Class(TCollection)
     Private
      Function GetItem(Index: Integer) : TDsExportField;
      Procedure SetItem(Index: Integer; const Value: TDsExportField);

     Protected
      FOwner                   : TDsDataExport;

     Public
      Procedure BuildFields();
      Function GetOwner: TPersistent; Override;
      Constructor Create(AOwner : TDsDataExport; lItemClass: TDsExportFieldClass);
      Function Add() : TDsExportField;

      Property Items[Index: Integer]: TDsExportField Read GetItem Write SetItem; Default;
    End;

    TDsExportFieldsClass        = Class Of TDsExportFields;

    TCancelEvent                = Procedure(Sender: TObject; Var Cancel : Boolean) Of Object;

    { TDsDataExport }

    TDsDataExport               = Class(TComponent)
     Private
      FDataSet                  : TDataSet;
      FActive,
      FSaveIfEmpty,
      FFetchFirst,
      FPreserveBookmark         : Boolean;
      FMaxRecords,
      FRecNo                    : Cardinal;
      FOnBeginExport,
      FOnEndExport,
      FAfterWriteRecord         : TNotifyEvent;
      FBeforeWriteRecord        : TCancelEvent;

      Procedure SetDataSet(Const Value: TDataSet);

     Protected
      FStream                   : TStream;
      FDynamicFields            : Boolean;

      Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;

      Procedure OpenFile; Virtual;
      Procedure CloseFile; Virtual;
      Procedure SaveRecords; Virtual;
      Procedure WriteRecord; Virtual; Abstract;

      Function Write(const Buffer; Count: Longint): Longint;
      Function WriteLine(AString: String): Longint;
      Function WriteString(AString: string; Count:Longint = 0): Longint;
      Function WriteChar(AChar: Char): Longint;

      Property SaveIfEmpty: Boolean read FSaveIfEmpty write FSaveIfEmpty default False;
      Property FetchFirst: boolean read FFetchFirst write FFetchFirst default True;
      Property MaxRecords: Cardinal read FMaxRecords write FMaxRecords default 0;
      Property RecNo: Cardinal read FRecNo;
      Property PreserveBookmark : Boolean read FPreserveBookmark write FPreserveBookmark default True;
      Property OnBeginExport: TNotifyEvent read FOnBeginExport write FOnBeginExport;
      Property OnEndExport: TNotifyEvent read FOnEndExport write FOnEndExport;
      Property BeforeWriteRecord: TCancelEvent read FBeforeWriteRecord write FBeforeWriteRecord;
      Property AfterWriteRecord: TNotifyEvent read FAfterWriteRecord write FAfterWriteRecord;

     Public
      Function GetFields: TDsExportFields; Virtual; Abstract;

      Constructor Create(AOwner: TComponent); Override;
      Destructor Destroy; Override;

      Procedure SaveToStream(Stream: TStream);
      Procedure SaveToFile(const FileName: String);

      Procedure Cancel();

      Property Active: Boolean Read FActive;
      Property DataSet: TDataSet Read FDataSet Write SetDataSet;
    End;

implementation

Uses DbGrids;

Resourcestring
              SDataNotAssigned = 'Cannot perform this operation without a dataset';
              SStreamNotAssigned = 'Cannot perform this operation without a Stream';
              SDataSetClosed = 'Cannot perform this operation on a closed dataset';
              SDataSetEmpty = 'Cannot perform this operation on a empty dataset';

{ TDsExportField }

function TDsExportField.GetField: TField;
 Var FDataSet : TDataSet;
begin
 FDataSet:=GetDataSet;

 If Assigned(FDataSet) And FDataSet.Active Then
  Result:=FDataSet.FieldByName(FDataField)
 Else
  Result:=Nil;
end;

function TDsExportField.GetDataSet: TDataSet;
begin
 If (Collection Is TDsExportFields) Then
  Result:=TDsExportFields(Collection).FOwner.DataSet
 Else
  Result:=Nil;
end;

function TDsExportField.GetDisplayName: String;
begin
 If FDataField <> '' Then
  Result:=FDataField
 Else
  Result:=inherited GetDisplayName;
end;

constructor TDsExportField.Create(lCollection: TCollection);
begin
 inherited Create(lCollection);

 FSave:=True;
end;

procedure TDsExportField.Assign(Source: TPersistent);
begin
 If Source Is TDsExportField Then
  With Source As TDsExportField Do
   Begin
    FDataField:=DataField;
    FSave:=Save;
   End
 Else
  If Source Is TField Then
   With Source As TField Do
    Begin
     FDataField:=FieldName;
     FSave:=Visible;
    End
  Else
   If Source Is TColumn Then
    With Source As TColumn Do
     Begin
      FDataField:=FieldName;
      FSave:=Visible;
     End
   Else
    Inherited Assign(Source);
end;

{ TDsExportFields }

function TDsExportFields.GetItem(Index: Integer): TDsExportField;
begin
 Result:=Inherited GetItem(Index) As TDsExportField;
end;

procedure TDsExportFields.SetItem(Index: Integer; const Value: TDsExportField);
begin
 SetItem(Index,Value);
end;

procedure TDsExportFields.BuildFields();
 Var ADataSet : TDataSet;
     iField : Integer;
begin
 Clear;

 If (GetOwner Is TDsDataExport) And Assigned(TDsDataExport(GetOwner).DataSet) Then
  Begin
   ADataSet:=TDsDataExport(GetOwner).DataSet;

   For iField:=0 To ADataSet.FieldCount - 1 Do
    Add.Assign(ADataSet.Fields[iField]);
  End;
end;

function TDsExportFields.GetOwner: TPersistent;
begin
 Result:=FOwner;
end;

constructor TDsExportFields.Create(AOwner: TDsDataExport;
  lItemClass: TDsExportFieldClass);
begin
 Inherited Create(lItemClass);

 FOwner:=AOwner;
end;

function TDsExportFields.Add(): TDsExportField;
begin
 Result:=Inherited Add As TDsExportField;
end;

{ TDsDataExport }

procedure TDsDataExport.SetDataSet(const Value: TDataSet);
begin
 FDataSet:=Value;

 If Value <> Nil Then
  Value.FreeNotification(Self);
end;

procedure TDsDataExport.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
 Inherited Notification(AComponent, Operation);

 If (Operation = opRemove) And (AComponent = FDataSet) Then
  SetDataSet(Nil);
end;

procedure TDsDataExport.OpenFile;
 Var FFields: TDsExportFields;
begin
 FActive:=True;

 If Assigned(FOnBeginExport) Then
  FOnBeginExport(Self);

 FFields:=GetFields;

 If Assigned(FFields) And (FFields.Count = 0) Then
  Begin
   FDynamicFields:=True;

   FFields.BuildFields();
  End
 Else
  FDynamicFields:=False;
end;

procedure TDsDataExport.CloseFile;
 Var FFields: TDsExportFields;
begin
 FFields:=GetFields;

 If FDynamicFields And Assigned(FFields) Then
  FFields.Clear;

 If Assigned(FOnEndExport) Then
  FOnEndExport(Self);

 FActive:=False;
end;

procedure TDsDataExport.SaveRecords;
 Var Bookmark : TBookmarkStr;
     ACancel : Boolean;
begin
 FDataSet.DisableControls;

 Try
   If FPreserveBookmark Then
    Bookmark := PAnsiChar(@DataSet.Bookmark[0]);

   Try
     FRecNo:=0;

     If FFetchFirst Then
      FDataSet.First;

     While (Not FDataSet.EOF) And FActive And
           ((FRecNo <= FMaxRecords) Or (FMaxRecords = 0)) Do
      Begin
       ACancel:=False;

       If Assigned(FBeforeWriteRecord) Then
        FBeforeWriteRecord(Self,ACancel);

       If Not ACancel Then
        Begin
         WriteRecord;

         Inc(FRecNo);

         If Assigned(FAfterWriteRecord) Then
          FAfterWriteRecord(Self);
        End;

       FDataSet.Next;
      End;
   Finally
     If FPreserveBookmark Then
      FDataSet.Bookmark := @Bookmark;
   End;
 Finally
   FDataSet.EnableControls;
 End;
end;

function TDsDataExport.Write(const Buffer; Count: Longint): Longint;
begin
 If Assigned(FStream) Then
  Result:=FStream.Write(Buffer,Count)
 Else
  Raise Exception.Create(SStreamNotAssigned);
end;

function TDsDataExport.WriteLine(AString: String): Longint;
begin
 Result:=WriteString(AString + #13#10,0);
end;

function TDsDataExport.WriteString(AString: string; Count: Longint): Longint;
begin
 If Count = 0 Then
  Count:=Length(AString);

 Result:=Write(AString[1],Count);
end;

function TDsDataExport.WriteChar(AChar: Char): Longint;
begin
 Result:=Write(AChar,1);
end;

constructor TDsDataExport.Create(AOwner: TComponent);
begin
 Inherited Create(AOwner);

 FActive:=False;
 FFetchFirst:=True;
 FSaveIfEmpty:=False;
 FMaxRecords:=0;
 FStream:=Nil;
 FPreserveBookmark := False;
end;

destructor TDsDataExport.Destroy;
begin
 If FActive Then
  Cancel();

 Inherited Destroy;
end;

procedure TDsDataExport.SaveToStream(Stream: TStream);
begin
 If FDataset = Nil Then
  Raise Exception.Create(SDataNotAssigned);

 If Not FDataSet.Active Then
  Raise Exception.Create(SDataSetClosed);

 If (Not FSaveIfEmpty) And FDataset.IsEmpty Then
  Raise Exception.Create(SDataSetEmpty);

 FStream:=Stream;

 Try
   OpenFile;
   SaveRecords;
   CloseFile;
 Finally
   FStream:=Nil;
 End;
end;

procedure TDsDataExport.SaveToFile(const FileName: String);
 Var Stream : TStream;
begin
 Stream:=TFileStream.Create(FileName,fmCreate);

 Try
   SaveToStream(Stream);
 Finally
   Stream.Free;
 End;
end;

procedure TDsDataExport.Cancel();
begin
 FActive:=False;

 Repeat
 Until FStream = Nil;
end;

end.

