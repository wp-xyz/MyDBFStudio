unit uExpCSV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, ComCtrls, Buttons, DsCsv;

type

  { TExpCSV }

  TExpCSV = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    cbDateF: TComboBox;
    cbSaveHeader: TCheckBox;
    ClbField: TCheckListBox;
    fDel: TEdit;
    Ignore: TEdit;
    lblStringToIgnore: TLabel;
    lblFieldDelimiter: TLabel;
    lblFieldSeparator: TLabel;
    lblExportFields: TLabel;
    lblDateFormat: TLabel;
    lblProgress: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    Separator: TEdit;
    procedure ClbFieldItemClick(Sender: TObject; Index: integer);
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpDs : TDsCSV;
    FDbfTable: TDbf;
    Function CreateCSVFieldMap : String;
    Procedure StepIt(Sender : TObject; AProgress: LongInt; out StopIt: Boolean);
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
begin
  CloseBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
  ExportBtn.Constraints.MinWidth := CloseBtn.Constraints.MinWidth;

  Constraints.MinWidth :=
    (Width - Separator.Left) * 3 div 2;
  Constraints.MinHeight :=
    cbSaveHeader.Top + cbSaveHeader.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportCSVWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportCSVWindow.ApplyToForm(Self);
  end;
  Separator.Text := Options.ExportCSVSeparator;
  cbDateF.Text := Options.ExportCSVDateFormat;
  fDel.Text := Options.ExportCSVFieldDelimiter;
  Ignore.Text := Options.ExportCSVStringToIgnore;
  cbSaveHeader.Checked := Options.ExportCSVSaveFieldsHeader;

  Separator.Height := cbDateF.Height;
  fDel.Height := Separator.Height;
  Ignore.Height := Separator.Height;

  ClbField.Clear;
  for Ind := 0 To DbfTable.FieldDefs.Count - 1 do
    with DbfTable.FieldDefs.Items[Ind] do
    begin
      ClbField.Items.Add(Name);
      // Do not allow exporting graphic fields to csv
      if (DataType = ftBlob) and (DataType <> ftMemo) then
        ClbField.Checked[ind] := false
      else
        ClbField.Checked[ind] := True;
    end;
end;

function TExpCSV.CreateCSVFieldMap: String;
 Var Ind : Integer;
begin
 Result := '';

 For Ind := 0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   Result := Result + '$' + ClbField.Items[Ind] + Separator.Text[1];
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
procedure TExpCSV.ClbFieldItemClick(Sender: TObject; Index: integer);
var
  fieldDef: TFieldDef;
begin
  fieldDef := DbfTable.FieldDefs.Items[Index];
  if (fieldDef.DataType = ftBlob) and (fieldDef.DataType <> ftMemo) then
  begin
    ClbField.Checked[Index] := false;
    MessageDlg('Exporting a BLOB field to CSV is not supported.', mtError, [mbOK], 0);
  end;
end;

procedure TExpCSV.ExportBtnClick(Sender: TObject);
var
  savedAfterScroll: TDatasetNotifyEvent;
begin
  if Trim(Separator.Text) = '' then
  begin
    MessageDlg('You MUST insert a record separator...', mtError, [mbOK], 0);
    Separator.SetFocus;
    Exit;
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
      ExpDs.Delimiter := fDel.Text;
      ExpDs.ExportHeader := cbSaveHeader.Checked;
      ExpDs.CSVMap := CreateCSVFieldMap;
      ExpDs.Separator := Separator.Text[1];
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
    Options.ExportCSVSeparator := Separator.Text;
    Options.ExportCSVDateFormat := cbDateF.Text;
    Options.ExportCSVFieldDelimiter := fDel.Text;
    Options.ExportCSVStringToIgnore := Ignore.Text;
    Options.ExportCSVSaveFieldsHeader := cbSaveHeader.Checked;
  end;
end;

procedure TExpCSV.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
end;

end.

