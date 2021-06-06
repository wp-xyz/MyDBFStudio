unit uRestructure;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Buttons, ExtCtrls, db, dbf_fields;

type

  MyIndex = record
    IdxName : String;
    Fields  : String;
    Options : TIndexOptions;
    Deleted : Boolean;
  End;

  { TRestructure }

  TRestructure = class(TForm)
    CloseBtn: TBitBtn;
    lblTableLevel: TLabel;
    lblFieldList: TLabel;
    lblLanguage: TLabel;
    lblCodePage: TLabel;
    RestructureBtn: TBitBtn;
    DefineBtn: TBitBtn;
    EditBtn: TBitBtn;
    DeleteBtn: TBitBtn;
    cbPack: TCheckBox;
    FieldList: TStringGrid;
    IndexList: TListBox;
    lblIndexList: TLabel;
    Panel1: TPanel;
    procedure CloseBtnClick(Sender: TObject);
    procedure FieldListSelectEditor(Sender: TObject; aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RestructureBtnClick(Sender: TObject);
    procedure DefineBtnlick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure EditBtnlick(Sender: TObject);
    procedure FieldListKeyDown(Sender: TObject; var Key: Word;
      {%H-}Shift: TShiftState);
    procedure IndexListDblClick(Sender: TObject);
  private
    { private declarations }
    FDbf: TDbf;
    MyIndexList: array of MyIndex;
    function Check_Value(Val: String): Boolean;
    function CreateNewFieldDefs: TDbfFieldDefs;
    procedure EditSelectedIndex;
    procedure RecreateMyIndex;
    function RetFieldType(AValue: String): TFieldType;
    procedure ShowIndexList;
    procedure ShowInfo(ATable: TDbf);
  public
    { public declarations }
    function TestIndexName(Val: String): Boolean;
    property Dbf: TDbf read FDbf write FDbf;
  end;

var
  Restructure: TRestructure;

implementation

uses
  LCLType, TypInfo, Math,
  uUtils, uIdxTable, uOptions;

{$R *.lfm}

{ TRestructure }

procedure TRestructure.FormDestroy(Sender: TObject);
begin
  SetLength(MyIndexList, 0);
end;

procedure TRestructure.FieldListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  n: Integer;
begin
  n := FieldList.RowCount;
  if Key = 40 then     //Down Arrow
  begin
    if FieldList.Row = n - 1 then
      if (FieldList.Cells[1, n - 1] <> '') and (FieldList.Cells[2, n - 1] <> '') then
      begin
        FieldList.RowCount := n + 1;
        FieldList.Cells[0, n] := IntToStr(n);
        FieldList.Cells[4, n] := 'Y';     //New Field
        FieldList.Col := 1;
        FieldList.Row := n;
      end;
  end else
  if Key = 38 then                      //Up Arrow
  begin
    if (FieldList.Cells[1, n - 1] = '') and (FieldList.Cells[2, n - 1] = '') then
    begin
      FieldList.RowCount := n - 1;
    end;
  end else
  if Key = 46 then                     //Del
    if FieldList.Row >= 1 then
      if MessageDlg('Delete the field?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        FieldList.DeleteColRow(false, FieldList.Row);
        if FieldList.Row = 0 then
        begin
          FieldList.RowCount := n + 1;
          FieldList.Cells[0, n] := IntToStr(n);
          FieldList.Col := 1;
          FieldList.Row := n;
        end;
      end;
end;

procedure TRestructure.DeleteBtnClick(Sender: TObject);
var
  indexName: String;
  i: Integer;
begin
  if IndexList.ItemIndex < 0 then
    exit;

  if MessageDlg('Delete the selected index?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    exit;

  indexName := IndexList.Items[IndexList.ItemIndex];
  for i := 0 to High(MyIndexList) do
    if MyIndexList[i].IdxName = indexName then
      MyIndexList[i].Deleted := true;

  ShowIndexList;
end;

procedure TRestructure.EditBtnlick(Sender: TObject);
begin
  if IndexList.ItemIndex > -1 then
    EditSelectedIndex;
end;

procedure TRestructure.DefineBtnlick(Sender: TObject);
var
  row, n: Integer;
  lOpt: TIndexOptions;
  ExpField: String;
begin
  if FieldList.RowCount = 0 then
    exit;

  IdxTable := TIdxTable.Create(nil);
  try
    IdxTable.New := True;
    IdxTable.Calling := Restructure;
    lOpt := [];

    for row := 1 to FieldList.RowCount - 1 do
      IdxTable.IdxList.Items.Add(FieldList.Cells[1, row]);

    IdxTable.ShowModal;

    if IdxTable.Ret then
    begin
      ExpField := IdxTable.SelField.Text;

      if IdxTable.cbOpt.Checked[0] then
        lOpt := lOpt + [ixPrimary];

      if IdxTable.cbOpt.Checked[1] then
        lOpt := lOpt + [ixUnique];

      if IdxTable.cbOpt.Checked[2] then
        lOpt := lOpt + [ixDescending];

      if IdxTable.cbOpt.Checked[3] then
        lOpt := lOpt + [ixCaseInsensitive];

      n := Length(MyIndexList);
      SetLength(MyIndexList, n + 1);

      MyIndexList[n].Options := lOpt;
      MyIndexList[n].IdxName := IdxTable.IdxName.Text;
      MyIndexList[n].Fields := ExpField;
      MyIndexList[n].Deleted := False;

      ShowIndexList();
    end;

  finally
    IdxTable.Free;
  end;
end;

procedure TRestructure.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TRestructure.FieldListSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
 if (aCol = 2) and (Editor is TPickListcellEditor) then
   TPickListCellEditor(Editor).AutoComplete := true;
end;

procedure TRestructure.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.RestructureWindow.ExtractFromForm(Self);
end;

procedure TRestructure.FormCreate(Sender: TObject);
begin
  FieldList.AlternateColor := Options.AlternateColor
end;

procedure TRestructure.RestructureBtnClick(Sender: TObject);
var
  row: Integer;
begin
  for row := 1 To FieldList.RowCount - 1 do
  begin
    if Trim(FieldList.Cells[1, row]) = '' then
    begin
      MessageDlg('Row ' + IntToStr(row) + ': Missing field name.', mtError, [mbOK], 0);
      FieldList.Row := row;
      FieldList.Col := 1;
      exit;
    end;

    if FieldList.Cells[2, row] = '' then
    begin
      MessageDlg('Row ' + IntToStr(row) + ': Missing field type.', mtError, [mbOK], 0);
      FieldList.Row := row;
      FieldList.Col := 2;
      exit;
    end;

    if (FieldList.Cells[2, row] = FieldTypenames[ftString]) or
       //(FieldList.Cells[2, row] = Fieldtypenames[ftFloat]) or
       //(FieldList.Cells[2, row] = Fieldtypenames[ftBlob]) or
       //(FieldList.Cells[2, row] = Fieldtypenames[ftMemo]) or
       (FieldList.Cells[2, row] = FieldTypenames[ftFixedChar]) or
       (FieldList.Cells[2, row] = FieldTypenames[ftWideString]) or
       (FieldList.Cells[2, row] = FieldTypenames[ftBCD]) or
       (FieldList.Cells[2, row] = FieldTypenames[ftBytes])
    then
      if not Check_Value(FieldList.Cells[3, row]) then
      begin
        MessageDlg('Row ' + IntToStr(row) + ': Field length error', mtError, [mbOK], 0);
       FieldList.Row := row;
       FieldList.Col := 3;
       exit;
     end;

{   If (FieldList.Cells[2, row] = Fieldtypenames[ftFloat]) Or
      (FieldList.Cells[2, row] = Fieldtypenames[ftBCD]) Then
    If Not Check_Value(FieldList.Cells[4, row]) Then
     Begin
      ShowMessage('Row ' + IntToStr(row) + ': Decimals length error.');

      FieldList.Row := row;
      FieldList.Col := 4;

      Exit;
     End;}
   end;

  FDbf.Close;
  FDbf.RestructureTable(CreateNewFieldDefs(), cbPack.Checked);
  FDbf.Open;
 //Temp.RegenerateIndexes;
  RecreateMyIndex();

  Close;
end;

procedure TRestructure.FormShow(Sender: TObject);
var
  i, row: Integer;
  fieldDef: TFieldDef;
begin
  DefineBtn.Constraints.MinWidth := MaxValue([DefineBtn.Width, EditBtn.Width, DeleteBtn.Width]){%H-};
  EditBtn.Constraints.MinWidth := DefineBtn.Constraints.MinWidth;
  DeleteBtn.Constraints.MinWidth := DefineBtn.Constraints.MinWidth;

  Constraints.MinHeight :=
    Panel1.Top + Panel1.Height + CloseBtn.Height + CloseBtn.BorderSpacing.Top*2;
  Constraints.MinWidth :=
    FieldList.Left + FieldList.Constraints.MinWidth +
    FieldList.BorderSpacing.Around + Panel1.Width + Panel1.Borderspacing.Right;

  if Options.RememberWindowSizePos then
  begin
    AutoSize := false;
    Options.RestructureWindow.ApplyToForm(self);
  end;

  FieldList.RowCount := FDbf.FieldDefs.Count + 1;
  IndexList.Clear;

  for i := 0 to FDbf.FieldDefs.Count - 1 do
  begin
    fieldDef := FDbf.FieldDefs.Items[i];
    row := i + 1;
    FieldList.Cells[0, row] := IntToStr(row);
    FieldList.Cells[1, row] := fieldDef.Name;
    if fieldDef.DataType = ftBLOB then       // Hack to allow graphic fields
      FieldList.Cells[2, row] := FieldTypeNames[ftGraphic]
    else
      FieldList.Cells[2, row] := Fieldtypenames[fieldDef.DataType];
    FieldList.Cells[3, row] := '';
    if fieldDef.Size > 0 then
      FieldList.Cells[3, row] := IntToStr(fieldDef.Size);
    if fieldDef.Precision > 0 then
      FieldList.Cells[3, row] := IntToStr(fieldDef.Precision);
    FieldList.Cells[4, row] := 'N';
  end;

  SetLength(MyIndexList, FDbf.Indexes.Count);
  for i := 0 to FDbf.Indexes.Count - 1 do
  begin
    MyIndexList[i].IdxName := FDbf.Indexes.Items[i].Name;
    MyIndexList[i].Fields := FDbf.Indexes.Items[i].Expression;
    MyIndexList[i].Options := FDbf.Indexes.Items[i].Options;
    MyIndexList[i].Deleted := False;

    ShowIndexList();
  end;

  FieldTypePickList(FDbf.TableLevel, FieldList.Columns[2].PickList);

  ShowInfo(FDbf);
end;

procedure TRestructure.IndexListDblClick(Sender: TObject);
begin
  EditSelectedIndex;
end;

procedure TRestructure.EditSelectedIndex;
var
  oldIdxName: String;
  row, i: Integer;
  n: Integer;
  lOpt: TIndexOptions;
begin
  if IndexList.Items.Count = 0 then
    exit;

  oldIdxName := IndexList.Items[IndexList.ItemIndex];

  IdxTable := TIdxTable.Create(nil);
  try
    IdxTable.New := False;
    IdxTable.Calling := Restructure;
    lOpt := [];
    for row := 1 to FieldList.RowCount - 1 do
      IdxTable.IdxList.Items.Add(FieldList.Cells[1, row]);

    for i := 0 to High(MyIndexList) do
      if not MyIndexList[i].Deleted then
        if MyIndexList[i].IdxName = oldIdxName then
        begin
          lOpt := MyIndexList[i].Options;
          IdxTable.SelField.Text := MyIndexList[i].Fields;
          Break;
        end;
    IdxTable.IdxName.Text := OldIdxName;

    IdxTable.cbOpt.Checked[0] := ixPrimary in lOpt;
    IdxTable.cbOpt.Checked[1] := ixUnique in lOpt;
    IdxTable.cbOpt.Checked[2] := ixDescending in lOpt;
    IdxTable.cbOpt.Checked[3] := ixCaseInsensitive in lOpt;

    IdxTable.ShowModal;

    if IdxTable.Ret then
    begin
      for i := 0 to High(MyIndexList) do
        if not MyIndexList[i].Deleted then
          if MyIndexList[i].IdxName = oldIdxName then
            MyIndexList[i].Deleted := True;         //Delete old index...

      lOpt := [];
      if IdxTable.cbOpt.Checked[0] then
        lOpt := lOpt + [ixPrimary];
      if IdxTable.cbOpt.Checked[1] then
        lOpt := lOpt + [ixUnique];
      if IdxTable.cbOpt.Checked[2] then
        lOpt := lOpt + [ixDescending];
      if IdxTable.cbOpt.Checked[3] then
        lOpt := lOpt + [ixCaseInsensitive];

      n := Length(MyIndexList);
      SetLength(MyIndexList, n + 1);     //Insert New Index

      MyIndexList[n].Options := lOpt;
      MyIndexList[n].IdxName := IdxTable.IdxName.Text;
      MyIndexList[n].Fields := IdxTable.SelField.Text;
      MyIndexList[n].Deleted := False;

      ShowIndexList();
    end;

  finally
    FreeAndNil(IdxTable);
  end;
end;

procedure TRestructure.ShowIndexList;
var
  i: Integer;
begin
  IndexList.Clear;
  for i := 0 to High(MyIndexList) do
    if not MyIndexList[i].Deleted then
      IndexList.Items.Add(MyIndexList[i].IdxName);
end;

function TRestructure.Check_Value(Val: String): Boolean;
var
  n: Integer;
begin
  Result := false;
  if Trim(Val) = '' then
    exit;
  Result := TryStrToInt(val, n);
end;

function TRestructure.CreateNewFieldDefs: TDbfFieldDefs;
var
  row: Integer;
  fieldDef: TDbfFieldDef;
begin
  Result := TDbfFieldDefs.Create(self);

  for row := 1 to FieldList.RowCount - 1 do
  begin
    fieldDef := Result.AddFieldDef;
    fieldDef.FieldName := FieldList.Cells[1, row];
    fieldDef.FieldType := RetFieldType(FieldList.Cells[2, row]);

    if FieldList.Cells[4, row] = 'N' then
     fieldDef.CopyFrom := StrToInt(FieldList.Cells[0, row]) - 1;

    if fieldDef.FieldType <> ftFloat then
    begin
      if FieldList.Cells[3, row] <> '' then
        fieldDef.Size := StrToInt(FieldList.Cells[3, row]);
    end else
      fieldDef.Precision := StrToInt(FieldList.Cells[3, row]);   // todo: crashes for float fields when cell is empty
  end;
end;

procedure TRestructure.RecreateMyIndex;
var
  i: Integer;
  iOpt: TIndexOptions;
begin
  //First delete the index
  for i := 0 To High(MyIndexList) do
    if MyIndexList[i].Deleted then
     FDbf.DeleteIndex(MyIndexList[i].IdxName);

  //Next create indexes...
  for i := 0 to High(MyIndexList) do
    if not MyIndexList[i].Deleted then
    begin
      iOpt:= MyIndexList[i].Options;
      FDbf.AddIndex(MyIndexList[i].IdxName, MyIndexList[i].Fields, iOpt);
    end;
end;

function TRestructure.RetFieldType(AValue: String): TFieldType;
begin
  Result := TFieldType(GetEnumValue(TypeInfo(TFieldType), 'ft' + AValue));
  if not (Result in SupportedFieldTypes) then
    Result := ftUnknown;
end;

procedure TRestructure.ShowInfo(ATable: TDbf);
begin
  lblTableLevel.Caption := Format('Table level: %d (%s)', [ATable.TableLevel, TableFormat(ATable.TableLevel)]);
  lblCodepage.Caption := Format('Code page: %d', [ATable.CodePage]);
  if ATable.LanguageStr <> '' then
    lblLanguage.Caption := Format('Language: %s', [ATable.LanguageStr])
  else
    lblLanguage.Caption := '';
end;

function TRestructure.TestIndexName(Val: String): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to High(MyIndexList) do
    if MyIndexList[i].IdxName = Val then
      exit;
  Result := true;
end;

end.

