unit uExpCSV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, ComCtrls, Buttons, Menus, DsCsv;

type

  { TExpCSV }

  TExpCSV = class(TForm)
    CloseBtn: TBitBtn;
    cbFieldSeparator: TComboBox;
    ExportBtn: TBitBtn;
    cbDateF: TComboBox;
    cbSaveHeader: TCheckBox;
    clbFields: TCheckListBox;
    edFieldDelimiter: TEdit;
    Ignore: TEdit;
    lblDecimalSeparator: TLabel;
    lblStringToIgnore: TLabel;
    lblFieldDelimiter: TLabel;
    lblFieldSeparator: TLabel;
    lblExportFields: TLabel;
    lblDateFormat: TLabel;
    lblProgress: TLabel;
    mnuSelectAll: TMenuItem;
    mnuSelectNone: TMenuItem;
    pBar: TProgressBar;
    FieldsPopup: TPopupMenu;
    SaveExp: TSaveDialog;
    cbDecimalSeparator: TComboBox;
    procedure clbFieldsItemClick(Sender: TObject; Index: integer);
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mnuSelectAllClick(Sender: TObject);
    procedure mnuSelectNoneClick(Sender: TObject);
  private
    { private declarations }
    ExpDs : TDsCSV;
    FDbfTable: TDbf;
    function CreateCSVFieldMap: String;
    function GetDecimalSeparator: Char;
    function GetFieldSeparator: Char;
    procedure StepIt(Sender : TObject; AProgress: LongInt; out StopIt: Boolean);
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write FDbfTable;
  end;

var
  ExpCSV: TExpCSV;

implementation

{$R *.lfm}

uses
  DB, Math, uOptions;

{ TExpCSV }

procedure TExpCSV.FormShow(Sender: TObject);
var
  Ind: Integer;
  sep: Char;
begin
  CloseBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
  ExportBtn.Constraints.MinWidth := CloseBtn.Constraints.MinWidth;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;

//  Constraints.MinWidth :=
//    (Width - cbFieldSeparator.Left) * 3 div 2;
  Constraints.MinHeight :=
    pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePosContent then
  begin
    if (Options.ExportCSVWindow.Width > 0) then
    begin
      AutoSize := false;
      Options.ExportCSVWindow.ApplyToForm(Self);
    end;
    case Options.ExportCSVDecimalSeparator of
      '.': cbDecimalSeparator.ItemIndex := 0;
      ',': cbDecimalSeparator.ItemIndex := 1;
    end;
    for ind := 0 to cbFieldSeparator.Items.Count-1 do
    begin
      sep := cbFieldSeparator.Items[ind][1];
      if sep = 't' then sep := #9;
      if sep = Options.ExportCSVFieldSeparator then
      begin
        cbFieldSeparator.ItemIndex := ind;
        break;
      end;
    end;
    cbDateF.Text := Options.ExportCSVDateFormat;
    edFieldDelimiter.Text := Options.ExportCSVFieldDelimiter;
    Ignore.Text := Options.ExportCSVStringToIgnore;
    cbSaveHeader.Checked := Options.ExportCSVSaveFieldsHeader;
  end;

  cbFieldSeparator.Height := cbDateF.Height;
  edFieldDelimiter.Height := cbFieldSeparator.Height;
  Ignore.Height := cbFieldSeparator.Height;

  clbFields.Clear;
  for Ind := 0 To DbfTable.FieldDefs.Count - 1 do
    with DbfTable.FieldDefs.Items[Ind] do
    begin
      clbFields.Items.Add(Name);
      // Do not allow exporting graphic fields to csv
      if (DataType = ftBlob) and (DataType <> ftMemo) then
        clbFields.Checked[ind] := false
      else
        clbFields.Checked[ind] := True;
    end;
end;

procedure TExpCSV.mnuSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbFields.Items.Count-1 do
    clbFields.Checked[i] := true;
end;

procedure TExpCSV.mnuSelectNoneClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbFields.Items.Count-1 do
    clbFields.Checked[i] := false;
end;

function TExpCSV.CreateCSVFieldMap: String;
var
  Ind: Integer;
  sep: Char;
begin
  Result := '';
  sep := GetFieldSeparator;
  for Ind := 0 To clbFields.Items.Count - 1 do
    if clbFields.Checked[Ind] then
      Result := Result + '$' + clbFields.Items[Ind] + sep;
end;

procedure TExpCSV.StepIt(Sender: TObject; AProgress: LongInt;
  out StopIt: Boolean);
begin
  StopIt := false;
  pBar.Position := AProgress;
  Application.ProcessMessages;
end;

procedure TExpCSV.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

// Do not allow to check a BLOB item: cannot export to csv format.
procedure TExpCSV.clbFieldsItemClick(Sender: TObject; Index: integer);
var
  fieldDef: TFieldDef;
begin
  fieldDef := DbfTable.FieldDefs.Items[Index];
  if (fieldDef.DataType = ftBlob) and (fieldDef.DataType <> ftMemo) then
  begin
    clbFields.Checked[Index] := false;
    MessageDlg('Exporting a BLOB field to CSV is not supported.', mtError, [mbOK], 0);
  end;
end;

procedure TExpCSV.ExportBtnClick(Sender: TObject);
var
  savedAfterScroll: TDatasetNotifyEvent;
  i: Integer;
  NoneChecked: Boolean = true;
begin
  for i := 0 to clbFields.Items.Count-1 do
    if clbFields.Checked[i] then
    begin
      NoneChecked := false;
      break;
    end;
  if NoneChecked then
  begin
    clbFields.Setfocus;
    MessageDlg('No field selected for export.', mtError, [mbOK], 0);
    exit;
  end;

  if cbFieldSeparator.ItemIndex = -1 then
  begin
    cbFieldSeparator.SetFocus;
    MessageDlg('You MUST insert a field separator...', mtError, [mbOK], 0);
    Exit;
  end;

  if GetFieldSeparator = GetDecimalSeparator then
  begin
    cbDecimalSeparator.SetFocus;
    MessageDlg('Field separator and decimal separator must not be equal.', mtError, [mbOK], 0);
    exit;
  end;

  if GetFieldSeparator = Trim(edFieldDelimiter.Text) then
  begin
    cbFieldSeparator.SetFocus;
    MessageDlg('Field separator and delimiter must not be equal.', mtError, [mbOK], 0);
    exit;
  end;

  if Trim(edFieldDelimiter.Text) = GetDecimalSeparator then
  begin
    cbDecimalSeparator.SetFocus;
    MessageDlg('Field delimiter and decimal separator must not be equal.', mtError, [mbOK], 0);
    exit;
  end;

  if not SaveExp.Execute then
    Exit;

  pBar.Min := 0;
  pBar.Max := DbfTable.ExactRecordCount - 1;
  pBar.Position:=0;

  savedAfterScroll := Dbftable.AfterScroll;
  DbfTable.AfterScroll := nil;
  DbfTable.DisableControls;

  ExpDs := TDsCSV.Create(Self);
  try
    try
      DbfTable.First;

      ExpDs.Dataset := DbfTable;
      ExpDs.CSVFile := SaveExp.FileName;
      ExpDs.EmptyTable := True;
      ExpDs.AutoOpen := False;
      ExpDs.IgnoreString := Ignore.Text;
      ExpDs.FieldDelimiter := edFieldDelimiter.Text;
      ExpDs.ExportHeader := cbSaveHeader.Checked;
      ExpDs.CSVMap := CreateCSVFieldMap;
      ExpDs.FieldSeparator := GetFieldSeparator;
      ExpDs.DecimalSeparator := GetDecimalSeparator;
      ExpDs.DateFormat := cbDateF.Text;
      ExpDs.ImportProgress := @StepIt;
      ExpDs.DatasetToCSV();
      Close;
      MessageDlg('Table successfully exported to ' + SaveExp.FileName, mtInformation, [mbOK], 0);
    except
      on E:Exception do
        MessageDlg('Error writing file:' + Lineending +  E.Message, mtError, [mbOK], 0);
    end;
  finally
    ExpDs.Free;
    DbfTable.AfterScroll := savedAfterScroll;
    DbfTable.EnableControls;
  end;
end;

procedure TExpCSV.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.ExportCSVWindow.ExtractFromForm(Self);
    Options.ExportCSVFieldSeparator := GetFieldSeparator;
    Options.ExportCSVDecimalSeparator := GetDecimalSeparator;
    Options.ExportCSVDateFormat := cbDateF.Text;
    Options.ExportCSVFieldDelimiter := edFieldDelimiter.Text;
    Options.ExportCSVStringToIgnore := Ignore.Text;
    Options.ExportCSVSaveFieldsHeader := cbSaveHeader.Checked;
  end;
end;

procedure TExpCSV.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
end;

function TExpCSV.GetDecimalSeparator: Char;
var
  decSepStr: String;
begin
  decSepStr := cbDecimalSeparator.Items[cbDecimalSeparator.ItemIndex];
  Result := decSepStr[1];
end;

function TExpCSV.GetFieldSeparator: Char;
var
  fs: String;
begin
  fs := cbFieldSeparator.Items[cbFieldSeparator.ItemIndex];
  Result := fs[1];
  if Result = 't' then Result := #9;
end;

end.

