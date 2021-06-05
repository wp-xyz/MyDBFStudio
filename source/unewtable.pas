unit uNewTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Buttons, DB, dbf, DBF_Fields;

type

  MyIndex         = Packed Record
   IdxName        : String;
   Fields         : String;
   Options        : TIndexOptions;
   Deleted        : Boolean;
  End;

  { TNewTable }

  TNewTable = class(TForm)
    CloseBtn: TBitBtn;
    CreateTableBtn: TBitBtn;
    DeleteIndexBtn: TBitBtn;
    DefineIndexBtn: TBitBtn;
    cbOpenTB: TCheckBox;
    FieldList: TStringGrid;
    GroupBox1: TGroupBox;
    IndexList: TListBox;
    lblIndexList: TLabel;
    lblTableType: TLabel;
    SaveTableDlg: TSaveDialog;
    TableType: TComboBox;
    procedure CloseBtnClick(Sender: TObject);
    procedure CreateTableBtnClick(Sender: TObject);
    procedure DefineIndexBtnClick(Sender: TObject);
    procedure DeleteIndexBtnClick(Sender: TObject);
    procedure FieldListSelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure IndexListDblClick(Sender: TObject);
    procedure TableTypeChange(Sender: TObject);
  private
    { private declarations }
    FDBTable: TDbf;
    MyIndexList : array of MyIndex;
    Function ReturnTableLevel : Word;
    Procedure ShowIndexList;
    Function Check_Value(Val : String) : Boolean;
    Function RetFieldType(AValue: String) : TFieldType;
    Function CreateNewFieldDefs : TDbfFieldDefs;
    Procedure CreateMyIndex;
  public
    { public declarations }
    Ret : Boolean;
    PageIdx : Integer;
    Function TestIndexName(Val : String) : Boolean;
    property DBTable: TDbf read FDBTable;
  end;

var
  NewTable: TNewTable;

implementation

uses
  Math, TypInfo, uUtils, uMain, uIdxTable;

{$R *.lfm}

{ TNewTable }

procedure TNewTable.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TNewTable.CreateTableBtnClick(Sender: TObject);
Var
  Ind: Word;
begin
  for Ind := 1 to FieldList.RowCount - 1 do
  begin
    if Trim(FieldList.Cells[1,Ind]) = '' then
    begin
      MessageDlg('Row ' + IntToStr(Ind) + ': Missing field name', mtError, [mbOK], 0);
      FieldList.Row := Ind;
      FieldList.Col := 1;
      exit;
    end;

    if FieldList.Cells[2,Ind] = '' then
    begin
      MessageDlg('Row ' + IntToStr(Ind) + ': Missing field type', mtError, [mbOK], 0);
      FieldList.Row := Ind;
      FieldList.Col := 2;
      exit;
    end;

    if (FieldList.Cells[2,Ind] = Fieldtypenames[ftString]) or
//      (FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) or
//      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBlob]) or
//      (FieldList.Cells[2,Ind] = Fieldtypenames[ftMemo]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftFixedChar]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftWideString]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftBCD]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftBytes])
    then
      if Not Check_Value(FieldList.Cells[3,Ind]) then
      begin
        MessageDlg('Row ' + IntToStr(Ind) + ': Field length error', mtError, [mbOK], 0);
        FieldList.Row := Ind;
        FieldList.Col := 3;
        Exit;
      end;

{   If (FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBCD]) Then
    If Not Check_Value(FieldList.Cells[4,Ind]) Then
     Begin
      ShowMessage('Row: ' + IntToStr(Ind) + '. Decimals length error!');

      FieldList.Row:=Ind;
      FieldList.Col:=4;

      Exit;
     End;}
  end;

  if SaveTableDlg.Execute then
  begin
    try
      FDBTable.TableLevel := ReturnTableLevel();
      FDBTable.TableName := SaveTableDlg.FileName;
      FDBTable.CreateTableEx(CreateNewFieldDefs());
      FDBTable.Open;
      CreateMyIndex();
      FDBTable.Close;
      Ret := True;

      if cbOpenTB.Checked Then
        Main.Open_Table(SaveTableDlg.FileName);

      Close;
    except
    end;
  end;
end;

procedure TNewTable.DefineIndexBtnClick(Sender: TObject);
 Var Ind : Word;
     lOpt : TIndexOptions;
     ExpField : String;
begin
 If FieldList.RowCount > 1 Then
  Begin
   IdxTable := TIdxTable.Create(Self);
   IdxTable.New := True;
   IdxTable.Calling := NewTable;
   lOpt := [];

   For Ind := 1 To FieldList.RowCount - 1 Do
    IdxTable.IdxList.Items.Add(FieldList.Cells[1,Ind]);

   IdxTable.ShowModal;

   If IdxTable.Ret Then
    Begin
     ExpField := IdxTable.SelField.Text;

     If IdxTable.cbOpt.Checked[0] Then
      lOpt := lOpt + [ixPrimary];

     If IdxTable.cbOpt.Checked[1] Then
      lOpt := lOpt + [ixUnique];

     If IdxTable.cbOpt.Checked[2] Then
      lOpt := lOpt + [ixDescending];

     If IdxTable.cbOpt.Checked[3] Then
      lOpt := lOpt + [ixCaseInsensitive];

     SetLength(MyIndexList, Length(MyIndexList) + 1);

     MyIndexList[Length(MyIndexList) - 1].Options := lOpt;
     MyIndexList[Length(MyIndexList) - 1].IdxName := IdxTable.IdxName.Text;
     MyIndexList[Length(MyIndexList) - 1].Fields := ExpField;
     MyIndexList[Length(MyIndexList) - 1].Deleted := False;

     ShowIndexList();
    End;

   IdxTable.Free;
  End;
end;

procedure TNewTable.DeleteIndexBtnClick(Sender: TObject);
 Var dName : String;
     Ind : Word;
begin
  If IndexList.ItemIndex < 0 Then
    Exit;

 If MessageDlg('Delete the selected index?', mtWarning ,[mbOk, mbCancel],0) = mrOk Then
  Begin
   dName := IndexList.Items[IndexList.ItemIndex];

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If MyIndexList[Ind].IdxName = dName Then
     MyIndexList[Ind].Deleted := True;

   ShowIndexList();
  End;
end;

procedure TNewTable.FieldListSelectEditor(Sender: TObject; aCol, aRow: Integer;
  var Editor: TWinControl);
begin
  if (aCol = 2) and (Editor is TPickListCellEditor) then
    TPickListCellEditor(Editor).AutoComplete := true;
end;

procedure TNewTable.FormCreate(Sender: TObject);
begin
  FDBTable := TDbf.Create(self);
  FDBTable.Exclusive := true;

  TableTypeChange(Sender);

  FieldList.RowCount := 2;

  FieldList.Cells[0,FieldList.RowCount - 1] := IntToStr(FieldList.RowCount - 1);
  FieldList.Col := 1;
  FieldList.Row := FieldList.RowCount - 1;

  Ret := False;
end;

procedure TNewTable.FormDestroy(Sender: TObject);
begin
  SetLength(MyIndexList, 0);
end;

procedure TNewTable.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = 40 Then     //Down Arrow
  Begin
   If FieldList.Row = FieldList.RowCount - 1 Then
    If (FieldList.Cells[1,FieldList.RowCount - 1] <> '') And
       (FieldList.Cells[2,FieldList.RowCount - 1] <> '') Then
     Begin
      FieldList.RowCount:=FieldList.RowCount + 1;

      FieldList.Cells[0,FieldList.RowCount - 1]:=IntToStr(FieldList.RowCount - 1);
      FieldList.Col:=1;
      FieldList.Row:=FieldList.RowCount - 1;
     End;
  End
  Else
  If Key = 38 Then                      //Up Arrow
   Begin
    If (FieldList.Cells[1,FieldList.RowCount - 1] = '') And
       (FieldList.Cells[2,FieldList.RowCount - 1] = '') Then
     Begin
      FieldList.RowCount:=FieldList.RowCount - 1;

     //FieldList.Col:=1;
     //FieldList.Row:=FieldList.RowCount + 1;
     End;
   End
   Else
   If Key = 46 Then                      //Del
    If FieldList.Row >= 1 Then
     If MessageDlg('Delete the field?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
      Begin
       FieldList.DeleteColRow(False,FieldList.Row);

       If FieldList.Row = 0 Then
        Begin
         FieldList.RowCount:=FieldList.RowCount + 1;

         FieldList.Cells[0,FieldList.RowCount - 1]:=IntToStr(FieldList.RowCount - 1);
         FieldList.Col:=1;
         FieldList.Row:=FieldList.RowCount - 1;
        End;
      End;
end;

procedure TNewTable.FormShow(Sender: TObject);
begin
  DefineIndexBtn.Constraints.MinWidth := Max(DefineIndexBtn.Width, DeleteIndexBtn.Width);
  DeleteIndexBtn.Constraints.MinWidth := DefineIndexBtn.Constraints.MinWidth;

  CreateTableBtn.Constraints.MinWidth := Max(CreateTableBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := CreateTableBtn.Constraints.MinWidth;
end;

procedure TNewTable.IndexListDblClick(Sender: TObject);
 Var OldIdxName : String;
     Ind : Word;
     lOpt : TIndexOptions;
begin
 If IndexList.Items.Count > 0 Then
  Begin
   OldIdxName := IndexList.Items[IndexList.ItemIndex];

   IdxTable := TIdxTable.Create(Self);
   IdxTable.New := False;
   IdxTable.Calling := NewTable;
   lOpt := [];

   For Ind := 1 To FieldList.RowCount - 1 Do
    IdxTable.IdxList.Items.Add(FieldList.Cells[1,Ind]);

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If Not MyIndexList[Ind].Deleted Then
     If MyIndexList[Ind].IdxName = OldIdxName Then
      Begin
       lOpt := MyIndexList[Ind].Options;

       Break;
      End;

   IdxTable.IdxName.Text := OldIdxName;

   IdxTable.SelField.Text := MyIndexList[Ind].Fields;

   If ixPrimary In lOpt Then
    IdxTable.cbOpt.Checked[0] := True;

   If ixUnique In lOpt Then
    IdxTable.cbOpt.Checked[1] := True;

   If ixDescending In lOpt Then
    IdxTable.cbOpt.Checked[2] := True;

   If ixCaseInsensitive In lOpt Then
    IdxTable.cbOpt.Checked[3] := True;

   IdxTable.ShowModal;

   If IdxTable.Ret Then
    Begin
     For Ind := 0 To Length(MyIndexList) - 1 Do
      If Not MyIndexList[Ind].Deleted Then
       If MyIndexList[Ind].IdxName = OldIdxName Then
        MyIndexList[Ind].Deleted := True;         //Delete old index...

     lOpt := [];

     If IdxTable.cbOpt.Checked[0] Then
      lOpt := lOpt + [ixPrimary];

     If IdxTable.cbOpt.Checked[1] Then
      lOpt := lOpt + [ixUnique];

     If IdxTable.cbOpt.Checked[2] Then
      lOpt := lOpt + [ixDescending];

     If IdxTable.cbOpt.Checked[3] Then
      lOpt := lOpt + [ixCaseInsensitive];

     SetLength(MyIndexList, Length(MyIndexList) + 1);     //Insert New Index

     MyIndexList[Length(MyIndexList) - 1].Options := lOpt;
     MyIndexList[Length(MyIndexList) - 1].IdxName := IdxTable.IdxName.Text;
     MyIndexList[Length(MyIndexList) - 1].Fields := IdxTable.SelField.Text;
     MyIndexList[Length(MyIndexList) - 1].Deleted := False;

     ShowIndexList;
    End;

   IdxTable.Free;
  End;
end;

procedure TNewTable.TableTypeChange(Sender: TObject);
begin
  FieldTypePickList(ReturnTableLevel, FieldList.Columns[2].PickList);
end;

function TNewTable.ReturnTableLevel: Word;
const
  TABLE_LEVELS: array[-1..4] of Integer = (3, 3, 4, 7, 25, 30);
begin
  Result := TABLE_LEVELS[TableType.ItemIndex];
end;

procedure TNewTable.ShowIndexList;
 Var Ind : Word;
begin
 IndexList.Clear;

 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    IndexList.Items.Add(MyIndexList[Ind].IdxName);
end;

function TNewTable.Check_Value(Val: String): Boolean;
var
  n: Integer;
begin
  Result := false;
  if Trim(Val) <> '' Then
    Result := TryStrToInt(Val, n);
end;

function TNewTable.RetFieldType(AValue: String): TFieldType;
begin
  Result := TFieldType(GetEnumValue(TypeInfo(TFieldType), 'ft' + AValue));
  if not (Result in SupportedFieldTypes) then
    Result := ftUnknown;
end;

function TNewTable.CreateNewFieldDefs: TDbfFieldDefs;
 Var Ind : Word;
     App : TDbfFieldDefs;
     TmpF : TDbfFieldDef;
begin
 App := TDbfFieldDefs.Create(Self);

 For Ind := 1 To FieldList.RowCount - 1 Do
  Begin
   TmpF := App.AddFieldDef;
   TmpF.FieldName := FieldList.Cells[1,Ind];
   TmpF.FieldType := RetFieldType(FieldList.Cells[2,Ind]);
   TmpF.Required := True;

   If TmpF.FieldType <> ftFloat Then
    Begin
     If FieldList.Cells[3,Ind] <> '' Then
      TmpF.Size := StrToInt(FieldList.Cells[3,Ind]);
    End
   Else
    TmpF.Precision := StrToInt(FieldList.Cells[3,Ind]);
  End;

 Result := App;
end;

procedure TNewTable.CreateMyIndex;
 Var Ind : Word;
     Tmp : TIndexOptions;
begin
 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    Begin
     Tmp := MyIndexList[Ind].Options;

     DbTable.AddIndex(MyIndexList[Ind].IdxName, MyIndexList[Ind].Fields, Tmp);
    end;
end;

function TNewTable.TestIndexName(Val: String): Boolean;
 Var Ind : Word;
begin
 Result := True;

 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    If MyIndexList[Ind].IdxName = Val Then
     Begin
      Result := False;

      Break;
     End;
end;

end.

