unit uAddTables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Buttons;

type

  { TAddTables }

  TAddTables = class(TForm)
    CloseBtn: TBitBtn;
    StartBtn: TBitBtn;
    cbTable1: TComboBox;
    cbTable2: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    lblProgress: TLabel;
    pBar: TProgressBar;
    rgTPri: TRadioGroup;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
  private
    { private declarations }
    FDbfTable1: TDbf;
    FDbfTable2: TDbf;
    Function Check_Table_Structures: Boolean;
    Procedure AddTable(D1, D2: TDbf);
  public
    { public declarations }
  end;

var
  AddTables: TAddTables;

implementation

uses
  DB, Math,
  uMain, uTabForm, uDbfTable, uOptions, uUtils;

{$R *.lfm}

{ TAddTables }

procedure TAddTables.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TAddTables.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.AddTablesWindow.ExtractFromForm(Self);
end;

procedure TAddTables.StartBtnClick(Sender: TObject);
var
  FT1, FT2 : TForm;
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
    Exit;
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
        AddTable(FDbfTable1, FDbfTable2)
      else
        AddTable(FDbfTable2, FDbfTable1);
    finally
      TDbfTable(fT1).DBGrid.EndUpdate(true);
      TDbfTable(fT2).DBGrid.EndUpdate(true);
    end;
  end;
end;

procedure TAddTables.FormShow(Sender: TObject);
var
  Ind: Word;
  F: TDbfTable;
begin
  StartBtn.Constraints.MinWidth := Max(StartBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := StartBtn.Constraints.MinWidth;

  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;

  if Options.RememberWindowSizePosContent and (Options.AddTablesWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.AddTablesWindow.ApplyToForm(self);
  end;

  for Ind := 0 To Main.WorkSite.PageCount - 1 do
    if (Main.WorkSite.Pages[Ind] is TTabForm) then
    begin
      if TTabForm(Main.WorkSite.Pages[Ind]).ParentForm is TDbfTable then
      begin
        F := TDbfTable(TTabForm(Main.WorkSite.Pages[Ind]).ParentForm);
        cbTable1.Items.Add(F.DBTable.FilePathFull + F.DBTable.TableName);
        cbTable2.Items.Add(F.DBTable.FilePathFull + F.DBTable.TableName);
       end;
     end;
end;

function TAddTables.Check_Table_Structures: Boolean;
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
  end;

  Result := true;
end;

procedure TAddTables.AddTable(D1, D2: TDbf);
var
  ind: Integer;
begin
  D1.First;
  D2.First;

  pBar.Min := 0;
  pBar.Max := D1.ExactRecordCount - 1;
  pBar.Position := 0;

  try
    while not D1.EOF do
    begin
      D2.Insert;
      for Ind := 0 To D1.Fields.Count - 1 Do
        D2.Fields[Ind].AsVariant := D1.Fields[Ind].AsVariant;
      D2.Post;
      pBar.Position := pBar.Position + 1;
      D1.Next;
    end;

    MessageDlg('Process completed!', mtInformation, [mbOK], 0);
  except
    on E:Exception do
      MessageDlg('Error while inserting fields:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;

  pBar.Position := 0;
end;

end.

