unit uExpDBF;

// Todo: Copy CodePage from source table to destination table

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ComCtrls, Buttons, dbf_fields, db;

type

  { TExpDBF }

  TExpDBF = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    ClbField: TCheckListBox;
    lblExportField: TLabel;
    lblTableType: TLabel;
    lblProgress: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableType: TComboBox;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FDbfTable: TDbf;
    FExpTable: TDbf;
    Function ReturnTableLevel : Word;
    Procedure Create_Fields_List;
    Procedure Move_Records;
    property ExpTable: TDbf read FExpTable write FExpTable;
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write FDbfTable;
  end;

var
  ExpDBF: TExpDBF;

implementation

{$R *.lfm}

uses
  Math, uOptions;

{ TExpDBF }

procedure TExpDBF.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TExpDBF.ExportBtnClick(Sender: TObject);
begin
  lblProgress.Caption := 'Progress';

  if not SaveExp.Execute then
    Exit;

  ExpTable.TableName := SaveExp.FileName;
  ExpTable.TableLevel := ReturnTableLevel;

  try
    Create_Fields_List();
    Move_Records();
    ExpTable.Close;
    lblProgress.Caption := 'Progress (completed)';
    pBar.Position := 0;
  except
    on E: Exception do
      MessageDlg('Error writing file.' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TExpDBF.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    // Save form position and size to ini
    Options.ExportDBFWindow.ExtractFromForm(Self);
end;

procedure TExpDBF.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
  FExpTable := TDbf.Create(self);
end;

procedure TExpDBF.FormShow(Sender: TObject);
var
  ind: Integer;
begin
  ExportBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := ExportBtn.Constraints.MinWidth;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportDBFWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportDBFWindow.ApplyToForm(Self);
  end;

  ClbField.Clear;

  for ind := 0 to DbfTable.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(DbfTable.FieldDefs.Items[ind].Name);
    ClbField.Checked[ind] := True;
  end;
end;

function TExpDBF.ReturnTableLevel: Word;
const
  TABLE_LEVELS: array[0..3] of Integer = (3, 4, 7, 25);
begin
  if (TableType.ItemIndex >= 0) and (TableType.ItemIndex <= 3) then
    Result := TABLE_LEVELS[TableType.ItemIndex]
  else
    Result := 4;
end;

procedure TExpDBF.Create_Fields_List;
var
  Ind: Word;
  App: TDbfFieldDefs;
  TmpF: TDbfFieldDef;
begin
  App := TDbfFieldDefs.Create(Self);

  for Ind := 0 To ClbField.Items.Count - 1 do
    if ClbField.Checked[Ind] then
    begin
      TmpF := App.AddFieldDef;
      TmpF.AssignDb(DbfTable.FieldDefs[Ind]);
    end;

  if Assigned(App) then
    ExpTable.CreateTableEx(App);
end;

procedure TExpDBF.Move_Records;
var
  Ind: Word;
begin
  ExpTable.Open;
  DbfTable.First;

  pBar.Min := 0;
  pBar.Max := DbfTable.ExactRecordCount;
  pBar.Position := 0;

  while not DbfTable.EOF do
  begin
    ExpTable.Insert;
    for Ind := 0 To ClbField.Items.Count - 1 do
      if ClbField.Checked[Ind] then
        ExpTable.FieldByName(ClbField.Items[Ind]).AsVariant := Dbftable.FieldByName(ClbField.Items[Ind]).AsVariant;
    ExpTable.Post;
    DbfTable.Next;
    pBar.StepIt;
  end;
end;

end.

