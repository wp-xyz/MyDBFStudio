unit uSubTables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Buttons, DB;

type

  { TSubTables }

  TSubTables = class(TForm)
    CloseBtn: TBitBtn;
    StartBtn: TBitBtn;
    cbTable1: TComboBox;
    cbTable2: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    pBar: TProgressBar;
    rgTPri: TRadioGroup;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure StartBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FDbfTable1: TDbf;
    FDbfTable2: TDbf;
    Function Check_Table_Structures: Boolean;
    Function Return_Field_Value(D : TDbf; I : Integer) : String;
    Procedure SubTable(D1, D2: TDbf);
  public
    { public declarations }
  end;

var
  SubTables: TSubTables;

implementation

uses
  Math, uMain, uDbfTable, uTabForm, uOptions, uUtils;

{$R *.lfm}

{ TSubTables }

procedure TSubTables.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TSubTables.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.SubtractTablesWindow.ExtractFromForm(Self);
end;

procedure TSubTables.StartBtnClick(Sender: TObject);
var
  FT1, FT2: TForm;
  IdxT1, IdxT2 : Integer;
begin
  if cbTable1.Text = '' then
  begin
    MessageDlg('You MUST select a first table...', mtError, [mbOK], 0);
    cbTable1.SetFocus;
    Exit;
  end;

  if cbTable2.Text = '' then
  begin
    MessageDlg('You MUST select a second table...', mtError, [mbOK], 0);
    cbTable2.SetFocus;
    Exit;
  end;

  if cbTable1.Text = cbTable2.Text then
  begin
    MessageDlg('The tables must be different.', mtError, [mbOK], 0);
    exit;
  end;

  IdxT1 := cbTable1.ItemIndex;
  IdxT2 := cbTable2.ItemIndex;

  FT1 := TTabForm(Main.WorkSite.Pages[IdxT1]).ParentForm;
  FT2 := TTabForm(Main.WorkSite.Pages[IdxT2]).ParentForm;

  FDbfTable1 := TDbfTable(FT1).DBTable;
  FDbfTable2 := TDbfTable(FT2).DBTable;

  if Check_Table_Structures then
  begin
    TDbfTable(FT1).DBGrid.BeginUpdate;
    TDbfTable(FT2).DBGrid.BeginUpdate;
    try
      if rgTPri.ItemIndex = 0 then
        SubTable(FDbfTable1, FDbfTable2)
      else
        SubTable(FDbfTable2, FDbfTable1);
    finally
      TDbfTable(FT1).DBGrid.EndUpdate(true);
      TDbfTable(FT2).DBGrid.EndUpdate(true);
    end;
  end;
end;

procedure TSubTables.FormShow(Sender: TObject);
var
  Ind: Word;
  F: TDbfTable;
begin
  StartBtn.Constraints.MinWidth := Max(StartBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := StartBtn.Constraints.MinWidth;

  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;

  Options.SubtractTablesWindow.ApplyToForm(Self);

  for Ind := 0 To Main.WorkSite.PageCount - 1 do
    if (Main.WorkSite.Pages[Ind] is TTabForm) then
      if TTabForm(Main.WorkSite.Pages[Ind]).ParentForm is TDbfTable then
      begin
        F := TDbfTable(TTabForm(Main.WorkSite.Pages[Ind]).ParentForm);
        cbTable1.Items.Add(F.DbTable.FilePathFull + F.DBTable.TableName);
        cbTable2.Items.Add(F.DbTable.FilePathFull + F.DBTable.TableName);
     end;
end;

function TSubTables.Check_Table_Structures: Boolean;
var
  Ind: Word;
  f1, f2: TField;
begin
  Result := false;

  if FDbfTable1.Fields.Count <> FDbfTable2.Fields.Count then
  begin
    MessageDlg('The structure of the tables is different: Different field count.', mtError, [mbOK], 0);
    Exit;
  end;

  for Ind := 0 To FDbfTable1.Fields.Count - 1 do
  begin
    f1 := FDbfTable1.Fields[ind];
    f2 := FDbfTable2.Fields[ind];
    if f1.DataType <> f2.DataType then
    begin
      MessageDlg(
        'The structure of the tables is different: ' +
        LineEnding +
        '  Field "' + f1.FieldName + '" of the 1st table is ' + FieldTypeAsString(f1.DataType, true) +
        LineEnding +
        '  Field "' + f2.FieldName + '" of the 2nd table is ' + FieldTypeAsString(f2.DataType, true),
        mtError, [mbOK], 0);
      exit;
    end;
    if (f1.DataType = ftMemo) or (f1.DataType = ftBlob) then
    begin
      MessageDlg('This function cannot work with MEMO or BLOB fields (field "' + f1.FieldName + '")',
        mtError, [mbOK], 0);
      exit;
    end;
  end;

  Result := true;
end;

function TSubTables.Return_Field_Value(D: TDbf; I: Integer): String;
begin
  case D.FieldDefs[I].DataType of
    ftString,
    ftFixedChar,
    ftDate,
    ftTime,
    ftDateTime,
    ftWideString,
    ftMemo:
      Result := '"' + D.Fields[I].AsString + '"';

    ftBoolean:
      if D.Fields[I].AsBoolean then
        Result := '"True"'
      else
        Result := '"False"';

    else
      Result := D.Fields[I].AsString;
  end;
end;

procedure TSubTables.SubTable(D1, D2: TDbf);
var
  Ind: Integer;
  filter: String;
begin
  D1.First;
  D2.First;
  D2.Filtered := True;

  pBar.Min := 0;
  pBar.Max := D1.ExactRecordCount;
  pBar.Position := 0;

  try
    while not D1.EOF do
    begin
      filter := '';
      for Ind := 0 To D1.Fields.Count - 1 do
      begin
        if (D1.Fields[Ind] is TBlobField) then // Cannot handle MEMO or BLOB fields.
          Continue;
        if filter = '' Then
          filter := filter + D1.FieldDefs.Items[Ind].Name + '=' + Return_Field_Value(D1,Ind)
        else
          filter := filter + ' AND ' + D1.FieldDefs.Items[Ind].Name + '=' + Return_Field_Value(D1,Ind);
      end;
      D2.Filter := filter;
      if not D2.IsEmpty then
        D2.Delete;
      D1.Next;
      pBar.Position := pBar.Position + 1;
    end;

    D2.Filter := '';

    MessageDlg('Process completed.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('Error while deleting fields:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;

  pBar.Position := 0;
end;

end.

