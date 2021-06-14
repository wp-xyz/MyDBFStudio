unit uImpCSV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Buttons, ExtCtrls, DB, dbf, DBF_Fields;

type

  MyIndex = Record
   IdxName : String;
   Fields  : String;
   Options : TIndexOptions;
   Deleted : Boolean;
  End;

  { TImportCSVForm }

  TImportCSVForm = class(TForm)
    cbDateFormat: TComboBox;
    cbDateSep: TComboBox;
    cbDateTimeFormat: TComboBox;
    cbDecSep: TComboBox;
    cbFieldSep: TComboBox;
    cbUseFirstLine: TCheckBox;
    cbTimeFormat: TComboBox;
    cbTimeSep: TComboBox;
    CSVParams: TGroupBox;
    Label1: TLabel;
    CloseBtn: TBitBtn;
    CreateTableBtn: TBitBtn;
    DeleteIndexBtn: TBitBtn;
    DefineIndexBtn: TBitBtn;
    cbOpenTbl: TCheckBox;
    FieldList: TStringGrid;
    ButtonPanel: TPanel;
    TableOptionsGroup: TGroupBox;
    IndexList: TListBox;
    Label2: TLabel;
    lblDateFormat: TLabel;
    lblDateSep: TLabel;
    lblDateTimeFormat1: TLabel;
    lblDecSep: TLabel;
    lblFieldSep: TLabel;
    lblIndexList: TLabel;
    lblTableType: TLabel;
    lblTimeFormat: TLabel;
    lblTimeSep: TLabel;
    BottomPanel: TPanel;
    TopPanelLeft: TPanel;
    TopPanelRight: TPanel;
    VertSplitter: TSplitter;
    HorSplitter: TSplitter;
    ImportGrid: TStringGrid;
    TestButton: TButton;
    TopPanel: TPanel;
    SaveTableDlg: TSaveDialog;
    cbTableLevel: TComboBox;
    procedure cbTableLevelChange(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure CreateTableBtnClick(Sender: TObject);
    procedure DefineIndexBtnClick(Sender: TObject);
    procedure DeleteIndexBtnClick(Sender: TObject);
    procedure FieldListSelectEditor(Sender: TObject; aCol, {%H-}aRow: Integer;
      var Editor: TWinControl);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IndexListDblClick(Sender: TObject);
    procedure TestButtonClick(Sender: TObject);
  private
    { private declarations }
    FCSVFileName: String;
    FDBTable: TDbf;
    FFileName: String;
    MyIndexList: array of MyIndex;
    Function ReturnTableLevel : Word;
    Procedure ShowIndexList;
    procedure AnalyzeColumn(AIndex: Integer; out ATitle: String;
      out AFieldType: TFieldType; out AFieldSize: Integer);
    Function Check_Value(Val : String) : Boolean;
    Function CreateNewFieldDefs : TDbfFieldDefs;
    Procedure CreateMyIndex;
    function ExtractSchema: Boolean;
    function GetSeparator(ACombo: TCombobox): Char;
    procedure ImportToTable;
    function RemoveIllegalChars(const ATitle: String): String;
    function SelectFieldType(AFieldType: TFieldType): String;
    procedure SetCSVFileName(const AValue: String);
    Function StrToFieldType(AValue: String) : TFieldType;
    function Validate(out AMsg: String; out AControl: TWinControl): Boolean;
  public
    { public declarations }
    function TestIndexName(Val : String) : Boolean;
    procedure UpdateOptions;
    property CSVFileName: String read FCSVFileName write SetCSVFileName;
    property DBTable: TDbf read FDBTable;
    property FileName: String read FFileName;
  end;

var
  ImportCSVForm: TImportCSVForm;

implementation

uses
  Math, TypInfo, DateUtils, LCLIntf, LCLType,
  uUtils, uOptions, uIdxTable;

{$R *.lfm}


{ TImportCSVForm }

procedure TImportCSVForm.AnalyzeColumn(AIndex: Integer; out ATitle: String;
  out AFieldType: TFieldType; out AFieldSize: Integer);
var
  fs: TFormatSettings;
  valueType, tmpValType: Integer;  // 1=string, 2=integer, 4=float, 8=date, 16=time
  row: Integer;
  s: String;
  valInt: Integer;
  valFloat: Double;
  valDateTime: TDateTime;
begin
  fs := FormatSettings;
  fs.DecimalSeparator := GetSeparator(cbDecSep);
  fs.DateSeparator := GetSeparator(cbDateSep);
  fs.TimeSeparator := GetSeparator(cbTimeSep);

  ATitle := RemoveIllegalChars(ImportGrid.Cells[AIndex, 0]);
  AFieldSize := 0;

  valueType := 0;
  for row := 1 to ImportGrid.RowCount-1 do
  begin
    tmpValType := 0;
    s := ImportGrid.Cells[AIndex, row];
    if s = '' then
      continue;
    if TryStrToInt(s, valInt) then
      tmpValType := 2
    else if TryStrToFloat(s, valFloat, fs) then
      tmpValType := 4
    else if TryScanDateTime(cbDateFormat.Text, s, valDateTime, fs) then
      tmpValType := 8
    else if TryScanDateTime(cbTimeFormat.Text, s, valDateTime, fs) then
      tmpValType := 16
    else if TryScanDateTime(cbDateTimeFormat.Text, s, valDateTime, fs) then
      tmpValType := 8+16
    else
      tmpValType := 1;
    valueType := valueType or tmpValType;
    AFieldSize := Max(AFieldSize, Length(s));
  end;
  if valueType = 1 then
    AFieldType := ftString
  else if valueType = 2 then
    AFieldType := ftInteger
  else if (valueType in [4, 6]) then
    AFieldType := ftFloat
  else if (valueType = 8) then
    AFieldType := ftDate
  else if (valueType = 16) then
    AFieldType := ftDateTime  // ftTime not supported by dbf
  else if (valueType = 16+8) then
    AFieldType := ftDateTime
  else
    AFieldType := ftString;
end;

procedure TImportCSVForm.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TImportCSVForm.CreateTableBtnClick(Sender: TObject);
var
  i: Word;
  msg: String;
  C: TWinControl;
begin
  if not Validate(msg, C) then
  begin
    C.SetFocus;
    MessageDlg(msg, mtError, [mbOK], 0);
    ModalResult := mrNone;
    exit;
  end;

  for i := 1 to FieldList.RowCount - 1 do
  begin
    if Trim(FieldList.Cells[1, i]) = '' then
    begin
      MessageDlg('Row ' + IntToStr(i) + ': Missing field name', mtError, [mbOK], 0);
      FieldList.Row := i;
      FieldList.Col := 1;
      ModalResult := mrNone;
      exit;
    end;

    if FieldList.Cells[2, i] = '' then
    begin
      MessageDlg('Row ' + IntToStr(i) + ': Missing field type', mtError, [mbOK], 0);
      FieldList.Row := i;
      FieldList.Col := 2;
      ModalResult := mrNone;
      exit;
    end;

    if (FieldList.Cells[2, i] = FieldTypeNames[ftString]) or
      // (FieldList.Cells[2, i] = FieldTypeNames[ftFloat]) or
       (FieldList.Cells[2, i] = FieldTypeNames[ftFixedChar]) or
       (FieldList.Cells[2, i] = FieldTypeNames[ftWideString]) or
       (FieldList.Cells[2, i] = FieldTypeNames[ftBCD]) or
       (FieldList.Cells[2, i] = FieldTypeNames[ftBytes])
    then
      if not Check_Value(FieldList.Cells[3, i]) then
      begin
        MessageDlg('Row ' + IntToStr(i) + ': Field length error', mtError, [mbOK], 0);
        FieldList.Row := i;
        FieldList.Col := 3;
        ModalResult := mrNone;
        Exit;
      end;
{
    if (FieldList.Cells[2, i] = FieldTypeNames[ftFloat]) or
       (FieldList.Cells[2, i] = FieldTypeNames[ftBCD])
    then
      if not Check_Value(FieldList.Cells[4, i]) then
      begin
        MessageDlg('Row: ' + IntToStr(i) + ': Decimals count error!',mtError, [mbOK], 0);
        FieldList.Row := i;
        FieldList.Col := 4;
        ModalResult := mrNone;
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
      ImportToTable();
      FDBTable.Close;

      if cbOpenTbl.Checked then
        // This file will be opened by the OnClose handler.
        FFileName := SaveTableDlg.FileName
      else
        FFileName := '';

    except
    end;
  end;
end;

procedure TImportCSVForm.DefineIndexBtnClick(Sender: TObject);
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
      IdxTable.Calling := Self;
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

procedure TImportCSVForm.DeleteIndexBtnClick(Sender: TObject);
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

procedure TImportCSVForm.FieldListSelectEditor(Sender: TObject; aCol, aRow: Integer;
  var Editor: TWinControl);
begin
  if (aCol = 2) and (Editor is TPickListCellEditor) then
    TPickListCellEditor(Editor).AutoComplete := true;
end;

procedure TImportCSVForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.ImportCSVWindow.ExtractFromForm(Self);
    Options.ImportCSVFieldSeparator := cbFieldSep.Text;
    Options.ImportCSVDateFormat := cbDateFormat.Text;
    Options.ImportCSVTimeFormat := cbTimeFormat.Text;
    Options.ImportCSVDateTimeFormat := cbDateTimeFormat.Text;
    Options.ImportCSVDateSeparator := cbDateSep.Text;
    Options.ImportCSVTimeSeparator := cbTimeSep.Text;
    Options.ImportCSVDecimalSeparator := cbDecSep.Text;
    Options.ImportCSVUseFirstLine := cbUseFirstLine.Checked;
    if cbTableLevel.ItemIndex > -1 then
      Options.ImportCSVTableLevel := cbTableLevel.Items[cbTableLevel.ItemIndex];
    Options.ImportCSVOpenAfterCreating := cbOpenTbl.Checked;
  end;
end;

procedure TImportCSVForm.FormCreate(Sender: TObject);
begin
  FDBTable := TDbf.Create(self);
  FDBTable.Exclusive := true;

  cbTableLevelChange(Sender);

  FieldList.RowCount := 2;
  FieldList.Cells[0,FieldList.RowCount - 1] := IntToStr(FieldList.RowCount - 1);
  FieldList.Col := 1;
  FieldList.Row := FieldList.RowCount - 1;

  UpdateOptions;
end;

procedure TImportCSVForm.FormDestroy(Sender: TObject);
begin
  SetLength(MyIndexList, 0);
end;

procedure TImportCSVForm.FormShow(Sender: TObject);
var
  i, w: Integer;
begin
  DefineIndexBtn.Constraints.MinWidth := Max(DefineIndexBtn.Width, DeleteIndexBtn.Width);
  DeleteIndexBtn.Constraints.MinWidth := DefineIndexBtn.Constraints.MinWidth;

  CreateTableBtn.Constraints.MinWidth := Max(CreateTableBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := CreateTableBtn.Constraints.MinWidth;

  w := 0;
  for i := 0 to cbDateTimeFormat.Items.Count-1 do
    w := Max(w, cbDateTimeFormat.Canvas.TextWidth(cbDateTimeFormat.Items[i]));
  TopPanelRight.Constraints.MinWidth := Max(
    lblDecSep.BorderSpacing.Left + lblDecSep.Width + cbDecSep.BorderSpacing.Left + w + 16,
    cbUseFirstLine.Left + cbUseFirstLine.Width
  );
  TopPanel.Constraints.MinHeight := CSVParams.Height;
  TopPanel.Height := TopPanel.Constraints.MinHeight;
  CSVParams.AutoSize := false;
  ClientHeight := TopPanel.BorderSpacing.Top + TopPanel.Constraints.MinHeight +
    TopPanel.BorderSpacing.Bottom + HorSplitter.Height +
    BottomPanel.BorderSpacing.Top + TableOptionsGroup.Height +
    ButtonPanel.Height;

  if Options.RememberWindowSizePosContent then
  begin
    if (Options.ImportCSVWindow.Width > 0) then
    begin
      AutoSize := false;
      Options.ImportCSVWindow.ApplyToForm(Self);
    end;
    cbFieldSep.Text := Options.ImportCSVFieldSeparator;
    cbDateFormat.Text := Options.ImportCSVDateFormat;
    cbTimeFormat.Text := Options.ImportCSVTimeFormat;
    cbDateTimeFormat.Text := Options.ImportCSVDateTimeFormat;
    cbDateSep.Text := Options.ImportCSVDateSeparator;
    cbTimeSep.Text := Options.ImportCSVTimeSeparator;
    cbDecSep.Text := Options.ImportCSVDecimalSeparator;
    cbUseFirstLine.Checked := Options.ImportCSVUseFirstLine;
    cbTableLevel.ItemIndex := IndexOfTableLevel(Options.ImportCSVTableLevel, cbTableLevel.Items);
    cbOpenTbl.Checked := Options.ImportCSVOpenAfterCreating;
  end;

  ExtractSchema;
end;

procedure TImportCSVForm.IndexListDblClick(Sender: TObject);
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
    IdxTable.Calling := Self;
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

procedure TImportCSVForm.cbTableLevelChange(Sender: TObject);
var
  i: Integer;
  fieldType: TFieldType;
  L: TStringList;
begin
  L := TStringList.Create;
  try
    FieldTypePickList(ReturnTableLevel, L);

    // Remove those not supported by the CSV import
    for i := L.Count-1 downto 0 do
    begin
      fieldtype := TFieldType(GetEnumValue(TypeInfo(TFieldType), 'ft'+L[i]));
      if not (fieldType in [ftInteger, ftSmallInt, ftWord, ftFloat, ftString, ftDate, ftDateTime]) then
        L.Delete(i);
    end;

    FieldList.Columns[2].PickList.Assign(L);
  finally
    L.Free;
  end;
end;

function TImportCSVForm.RemoveIllegalChars(const ATitle: String): String;
const
  ILLEGAL_CHARS = #9#10#13' ,;.:''~"?';
var
  ch: String;
begin
  Result := '';
  for ch in ATitle do begin
    if (pos(ch, ILLEGAL_CHARS) > 0) or (Length(ch) > 1) then
      continue;
    Result := Result + ch;
  end;
end;

function TImportCSVForm.ReturnTableLevel: Word;
const
  TABLE_LEVELS: array[-1..4] of Integer = (3, 3, 4, 7, 25, 30);
begin
  Result := TABLE_LEVELS[cbTableLevel.ItemIndex];
end;

function TImportCSVForm.Check_Value(Val: String): Boolean;
var
  n: Integer;
begin
  Result := false;
  if Trim(Val) <> '' Then
    Result := TryStrToInt(Val, n);
end;

function TImportCSVForm.CreateNewFieldDefs: TDbfFieldDefs;
var
  row: Integer;
  fieldDef: TDbfFieldDef;
  n: Integer;
begin
  Result := TDbfFieldDefs.Create(Self);

  for row := 1 to FieldList.RowCount - 1 do
  begin
    fieldDef := Result.AddFieldDef;
    fieldDef.FieldName := FieldList.Cells[1, row];
    fieldDef.FieldType := StrToFieldType(FieldList.Cells[2, row]);
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

procedure TImportCSVForm.CreateMyIndex;
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

function TImportCSVForm.ExtractSchema: Boolean;
var
  i, j: Integer;
  fieldname: String;
  fieldtype: TFieldType;
  fieldsize: Integer;
begin
  Result := false;
  if FCSVFileName = '' then
    exit;
  ImportGrid.LoadFromCSVFile(FCSVFileName, GetSeparator(cbFieldSep), cbUseFirstLine.Checked);
  ImportGrid.FixedCols := 0;
  if not cbUseFirstLine.Checked then
    for i := 0 to ImportGrid.ColCount-1 do
      ImportGrid.Cells[i, 0] := 'Col' + IntToStr(i+1);

  j := 1;
  FieldList.RowCount := ImportGrid.ColCount + 1;
  for i := 0 to ImportGrid.ColCount-1 do
  begin
    AnalyzeColumn(i, fieldName, fieldType, fieldSize);
    FieldList.Cells[0, j] := IntToStr(j);
    FieldList.Cells[1, j] := fieldName;
    FieldList.cells[2, j] := SelectFieldType(fieldType);
    if (fieldType in [ftString]) then
      FieldList.Cells[3, j] := IntToStr(fieldSize)
    else
      FieldList.cells[3, j] := '';
    inc(j);
  end;

  Result := true;
end;

function TImportCSVForm.GetSeparator(ACombo: TCombobox): Char;
var
  s: String;
begin
  s := ACombo.Text;
  if s = '' then
    s := ACombo.Items[0];
  if s = 'tab' then
    Result := #9
  else
    Result := s[1];
end;

procedure TImportCSVForm.ImportToTable;
var
  row, col: Integer;
  s: String;
  fs: TFormatSettings;
  field: TField;
  dt: TDateTime;
  n: Integer;
  x: Double;
begin
  fs := FormatSettings;
  fs.DecimalSeparator := GetSeparator(cbDecSep);
  fs.DateSeparator := GetSeparator(cbDecSep);
  fs.TimeSeparator := GetSeparator(cbTimeSep);

  for row := 1 to ImportGrid.RowCount-1 do
  begin
    DBTable.Append;
    for col := 0 to ImportGrid.ColCount-1 do
    begin
      field := DBTable.Fields[col];
      s := ImportGrid.Cells[col, row];
      case field.DataType of
        ftInteger:
          if TryStrToInt(s, n) then
            field.AsInteger := n;
        ftFloat:
          if TryStrToFloat(s, x, fs) then
            field.AsFloat := x;
        ftDate, ftDateTime:
          if TryScanDateTime(cbDateFormat.Text, s, dt, fs) or
             TryScanDateTime(cbTimeFormat.Text, s, dt, fs) or
             TryScanDateTime(cbDateTimeFormat.Text, s, dt, fs) then
          begin
            field.AsDateTime := dt;
          end;
        otherwise
          field.AsString := s;
      end;
    end;
    DBTable.Post;
  end;
end;

function TImportCSVForm.SelectFieldType(AFieldType: TFieldType): String;
var
  i: Integer;
  ft: Integer;
begin
  for i := 0 to FieldList.Columns[2].PickList.Count-1 do
  begin
    ft := GetEnumValue(TypeInfo(TFieldType), 'ft'+FieldList.Columns[2].PickList[i]);
    if ft = ord(AFieldType) then
    begin
      Result := FieldList.Columns[2].PickList[i];
      exit;
    end;
  end;
  Result := '';
end;

procedure TImportCSVForm.SetCSVFileName(const AValue: String);
begin
  if AValue = FCSVFileName then exit;
  FCSVFileName := AValue;
  Caption := Format('Importing CSV file "%s"...', [FCSVFileName]);
end;

procedure TImportCSVForm.ShowIndexList;
var
  i: Integer;
begin
  IndexList.Clear;
  for i := 0 to High(MyIndexList) do
    if not MyIndexList[i].Deleted then
      IndexList.Items.Add(MyIndexList[i].IdxName);
end;

function TImportCSVForm.StrToFieldType(AValue: String): TFieldType;
begin
  Result := TFieldType(GetEnumValue(TypeInfo(TFieldType), 'ft' + AValue));
  if not (Result in SupportedFieldTypes) then
    Result := ftUnknown;
end;

procedure TImportCSVForm.TestButtonClick(Sender: TObject);
begin
  ExtractSchema;
end;

function TImportCSVForm.TestIndexName(Val: String): Boolean;
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

procedure TImportCSVForm.UpdateOptions;
begin
  if Options.UseAlternateColor then
  begin
    FieldList.AlternateColor := Options.AlternateColor;
    ImportGrid.AlternateColor := Options.AlternateColor;
  end else
  begin
    FieldList.AlternateColor := FieldList.Color;
    ImportGrid.AlternateColor := ImportGrid.Color;
  end;

  if Options.ShowGridLines then
  begin
    FieldList.Options := FieldList.Options + [goHorzLine, goVertLine];
    ImportGrid.Options := ImportGrid.Options + [goHorzLine, goVertLine];
  end else
  begin
    FieldList.Options := FieldList.Options - [goHorzLine, goVertLine];
    ImportGrid.Options := ImportGrid.Options - [goHorzLine, goVertLine];
  end;

  FieldList.GridLineColor := Options.GridLineColor;
  ImportGrid.GridLineColor := Options.GridLineColor;
end;

function TImportCSVForm.Validate(out AMsg: String; out AControl: TWinControl): Boolean;
begin
  Result := false;

  if cbFieldSep.Text = '' then
  begin
    AMsg := 'Field delimiter not selected.';
    AControl := cbFieldSep;
    exit;
  end;

  if cbDateFormat.Text = '' then
  begin
    AMsg := 'No date format selected.';
    AControl := cbDateFormat;
    exit;
  end;

  if cbTimeFormat.Text = '' then
  begin
    AMsg := 'No time format selected.';
    AControl := cbTimeFormat;
    exit;
  end;

  if cbDateTimeFormat.Text = '' then
  begin
    AMsg := 'No date/time format selected.';
    AControl := cbDateTimeFormat;
    exit;
  end;

  if cbDateSep.Text = '' then
  begin
    AMsg := 'Date separator not selected.';
    AControl := cbDateSep;
    exit;
  end;

  if cbTimeSep.Text = '' then
  begin
    AMsg := 'Time separator not selected.';
    AControl := cbTimeSep;
    exit;
  end;

  if cbDecSep.Text = '' then
  begin
    AMsg := 'Decimal separator not selected.';
    AControl := cbDecSep;
    exit;
  end;

  if cbTableLevel.ItemIndex = -1 then
  begin
    AMsg := 'Table level  not selected.';
    AControl := cbTableLevel;
    exit;
  end;

  Result := true;
end;

end.

