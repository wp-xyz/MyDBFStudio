unit uNewTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Buttons, DB, dbf, DBF_Fields, DBF_Common;

type

  MyIndex = Record
   IdxName : String;
   Fields  : String;
   Options : TIndexOptions;
   Deleted : Boolean;
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
    procedure FieldListSelectEditor(Sender: TObject; aCol, {%H-}aRow: Integer;
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
    FFileName: String;
    MyIndexList: array of MyIndex;
    Function ReturnTableLevel : Word;
    Procedure ShowIndexList;
    Function Check_Value(Val : String) : Boolean;
    Function RetFieldType(AValue: String) : TFieldType;
    Function CreateNewFieldDefs : TDbfFieldDefs;
    Procedure CreateMyIndex;
  public
    { public declarations }
    Ret : Boolean;
    function TestIndexName(Val : String) : Boolean;
    procedure UpdateOptions;
    property DBTable: TDbf read FDBTable;
    property FileName: String read FFileName;
  end;

var
  NewTable: TNewTable;

implementation

uses
  Math, TypInfo, uUtils, uOptions, uIdxTable;

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
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftFixedChar]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftWideString]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftBCD]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftBytes])
    then
      if not Check_Value(FieldList.Cells[3,Ind]) then
      begin
        MessageDlg('Row ' + IntToStr(Ind) + ': Field length error', mtError, [mbOK], 0);
        FieldList.Row := Ind;
        FieldList.Col := 3;
        Exit;
      end;
{
    if (FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) or
       (FieldList.Cells[2,Ind] = Fieldtypenames[ftBCD])
    then
      if not Check_Value(FieldList.Cells[4, Ind]) then
      begin
        MessageDlg('Row: ' + IntToStr(Ind) + ': Decimals count error!',mtError, [mbOK], 0);
        FieldList.Row := Ind;
        FieldList.Col := 4;
        exit;
      end;
}
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

      if cbOpenTB.Checked then
        // This file will be opened by the OnClose handler.
        FFileName := SaveTableDlg.FileName
      else
        FFileName := '';

      Close;
    except
    end;
  end;
end;

procedure TNewTable.DefineIndexBtnClick(Sender: TObject);
var
  row, n: Integer;
  idxOpt: TIndexOptions;
  ExpField : String;
begin
  if FieldList.RowCount > 1 then
  begin
    IdxTable := TIdxTable.Create(nil);
    try
      IdxTable.New := True;
      IdxTable.Calling := NewTable;
      idxOpt := [];

      for row := 1 to FieldList.RowCount - 1 do
        IdxTable.IdxList.Items.Add(FieldList.Cells[1, row]);

      IdxTable.ShowModal;

      if IdxTable.Ret then
      begin
        ExpField := IdxTable.SelField.Text;

        if IdxTable.cbOpt.Checked[0] then idxOpt := idxOpt + [ixPrimary];
        if IdxTable.cbOpt.Checked[1] then idxOpt := idxOpt + [ixUnique];
        if IdxTable.cbOpt.Checked[2] then idxOpt := idxOpt + [ixDescending];
        if IdxTable.cbOpt.Checked[3] then idxOpt := idxOpt + [ixCaseInsensitive];

        n := Length(MyIndexList);
        SetLength(MyIndexList, n + 1);

        MyIndexList[n].Options := idxOpt;
        MyIndexList[n].IdxName := IdxTable.IdxName.Text;
        MyIndexList[n].Fields := ExpField;
        MyIndexList[n].Deleted := False;

        ShowIndexList();
      end;
    finally
      IdxTable.Free;
    end;
  end;
end;

procedure TNewTable.DeleteIndexBtnClick(Sender: TObject);
var
  idxName: String;
  i: Word;
begin
  if IndexList.ItemIndex < 0 then
    Exit;

  if MessageDlg('Delete the selected index?', mtWarning ,[mbYes, mbNo], 0) <> mrYes then
    exit;

  idxName := IndexList.Items[IndexList.ItemIndex];
  for i := 0 To High(MyIndexList) do
    if MyIndexList[i].IdxName = idxName then
    begin
      MyIndexList[i].Deleted := True;
      break;
    end;

  ShowIndexList();
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

  UpdateOptions;

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
         FieldList.RowCount := FieldList.RowCount + 1;

         FieldList.Cells[0,FieldList.RowCount - 1] := IntToStr(FieldList.RowCount - 1);
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
var
  oldIdxName: String;
  row, i, n: Integer;
  idxOpt: TIndexOptions;
begin
  if (IndexList.Items.Count = 0) or (IndexList.ItemIndex = -1) then
     exit;

  oldIdxName := IndexList.Items[IndexList.ItemIndex];

  IdxTable := TIdxTable.Create(nil);
  try
    IdxTable.New := False;
    IdxTable.Calling := NewTable;
    idxOpt := [];

    for row := 1 to FieldList.RowCount - 1 do
      IdxTable.IdxList.Items.Add(FieldList.Cells[1, row]);

    for i := 0 to High(MyIndexList) do
      if not MyIndexList[i].Deleted then
        if MyIndexList[i].IdxName = oldIdxName then
        begin
          idxOpt := MyIndexList[i].Options;
          IdxTable.SelField.Text := MyIndexList[i].Fields;
          Break;
        end;
    IdxTable.IdxName.Text := oldIdxName;
    IdxTable.cbOpt.Checked[0] := ixPrimary in idxOpt;
    IdxTable.cbOpt.Checked[1] := ixUnique in idxOpt;
    IdxTable.cbOpt.Checked[2] := ixDescending in idxOpt;;
    IdxTable.cbOpt.Checked[3] := ixCaseInsensitive in idxOpt;

    IdxTable.ShowModal;

    if IdxTable.Ret then
    begin
      for i := 0 to High(MyIndexList) do
        if not MyIndexList[i].Deleted then
          if MyIndexList[i].IdxName = oldIdxName then
          begin
            MyIndexList[i].Deleted := True;         //Delete old index...
            break;
          end;

      idxOpt := [];
      if IdxTable.cbOpt.Checked[0] then idxOpt := idxOpt + [ixPrimary];
      if IdxTable.cbOpt.Checked[1] then idxOpt := idxOpt + [ixUnique];
      if IdxTable.cbOpt.Checked[2] then idxOpt := idxOpt + [ixDescending];
      if IdxTable.cbOpt.Checked[3] then idxOpt := idxOpt + [ixCaseInsensitive];

      n := Length(MyIndexList);
      SetLength(MyIndexList, n + 1);     //Insert New Index

      MyIndexList[n].Options := idxOpt;
      MyIndexList[n].IdxName := IdxTable.IdxName.Text;
      MyIndexList[n].Fields := IdxTable.SelField.Text;
      MyIndexList[n].Deleted := False;

      ShowIndexList;
    end;

  finally
    IdxTable.Free;
  end;
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
var
  i: Integer;
begin
  IndexList.Clear;
  for i := 0 to High(MyIndexList) do
    if not MyIndexList[i].Deleted then
      IndexList.Items.Add(MyIndexList[i].IdxName);
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
var
  row: Integer;
  fieldDef: TDbfFieldDef;
  n: Integer;
begin
  Result := TDbfFieldDefs.Create(Self);
  Result.DbfVersion := TableLevelToDbfVersion(DBTable.TableLevel);

  for row := 1 to FieldList.RowCount - 1 do
  begin
    fieldDef := Result.AddFieldDef;
    fieldDef.FieldName := FieldList.Cells[1, row];
    fieldDef.FieldType := RetFieldType(FieldList.Cells[2, row]);
    fieldDef.Required := True;

    if FieldList.Cells[3, row] <> '' then
      if TryStrToInt(FieldList.Cells[3, row], n) then
      begin
        if fieldDef.FieldType <> ftFloat then
          fieldDef.Size := n
        else
          fieldDef.Precision := n;
      end;
  end;
end;

procedure TNewTable.CreateMyIndex;
var
  i: Integer;
  idxOpt: TIndexOptions;
begin
  for i := 0 to High(MyIndexList) do
    if not MyIndexList[i].Deleted then
    begin
      idxOpt := MyIndexList[i].Options;
      DbTable.AddIndex(MyIndexList[i].IdxName, MyIndexList[i].Fields, idxOpt);
    end;
end;

function TNewTable.TestIndexName(Val: String): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to High(MyIndexList) do
    if not MyIndexList[i].Deleted then
      if MyIndexList[i].IdxName = Val then
        exit;
  Result := true;
end;

procedure TNewTable.UpdateOptions;
begin
  if Options.UseAlternateColor then
    FieldList.AlternateColor := Options.AlternateColor
  else
    FieldList.AlternateColor := FieldList.Color;
  if Options.ShowGridLines then
    FieldList.Options := FieldList.Options + [goHorzLine, goVertLine]
  else
    FieldList.Options := FieldList.Options - [goHorzLine, goVertLine];
  FieldList.GridLineColor := Options.GridLineColor;
end;

end.

