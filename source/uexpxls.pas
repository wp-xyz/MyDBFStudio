unit uExpXLS;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  CheckLst, ExtCtrls, ComCtrls, Buttons, DsXls, dbf, DB;

type

  { TExpXLS }

  TExpXLS = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    cbDateF: TComboBox;
    ClbField: TCheckListBox;
    lblDateFormat: TLabel;
    lblMaskNumberWithDecimals: TLabel;
    lblMaskNumber: TLabel;
    lblFormatNumberWithDecimals: TLabel;
    lblFormatNumber: TLabel;
    lblExportField: TLabel;
    lblProgress: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    StrFN: TEdit;
    StrFND: TEdit;
    StrMFN: TEdit;
    StrMFND: TEdit;
    procedure ClbFieldClickCheck(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpObj : TDsXlsFile;
    FDbfTable: TDbf;
    Procedure CreateFieldTitle;
    Procedure WriteRecordValue(T: TDbf; ARow: Word);
    Function CreateSplitFileName(Orig : String; Ind : Word) : String;
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write FDbfTable;
  end;

var
  ExpXLS: TExpXLS;

implementation

{$R *.lfm}

uses
  LConvEncoding, uUtils, uOptions;

{ TExpXLS }

procedure TExpXLS.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.ExportXLSWindow.ExtractFromForm(Self);
    Options.ExportXLSNumberFormat := StrFN.Text;
    Options.ExportXLSFloatNumberFormat := StrFND.Text;
    Options.ExportXLSNumberMaskFormat := StrMFN.Text;
    Options.ExportXLSFloatNumberMaskFormat := StrMFND.Text;
    Options.ExportXLSDateFormat := cbDateF.Text;
  end;
end;

procedure TExpXLS.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
end;

procedure TExpXLS.FormShow(Sender: TObject);
var
  ind: Integer;
  w: Integer;
begin
  w := MaxValueI([lblFormatNumberWithDecimals.Width div 2,
                 lblMaskNumberWithDecimals.Width div 2,
                 ExportBtn.Width,
                 CloseBtn.Width
                ]);
  ExportBtn.Constraints.MinWidth := w;
  CloseBtn.Constraints.MinWidth := w;

  Constraints.MinWidth :=
    (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight :=
    pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportXLSWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportXLSWindow.ApplyToForm(Self);
  end;
  // Apply the format settings defined by the Options
  StrFN.Text := Options.ExportXLSNumberFormat;
  StrFND.Text := Options.ExportXLSFloatNumberFormat;
  StrMFN.Text := Options.ExportXLSNumberMaskFormat;
  StrMFND.Text := Options.ExportXLSFloatNumberMaskFormat;
  cbDateF.Text := Options.ExportXLSDateFormat;

  // Populate the field list
  ClbField.Clear;
  for ind := 0 to DbfTable.FieldDefs.Count - 1 do
    with DbfTable.FieldDefs.Items[Ind] do
    begin
      ClbField.Items.Add(Name);
      // Do not allow exporting graphic fields to Excel
      if (DataType = ftBlob) and (DataType <> ftMemo) then
        ClbField.Checked[ind] := false
      else
        ClbField.Checked[ind] := True;
    end;
end;

procedure TExpXLS.CreateFieldTitle;
var
  Ind: Word;
begin
  for Ind := 0 to ClbField.Items.Count - 1 do
    if ClbField.Checked[Ind] then
      ExpObj.PutStr(1, Ind + 1, ClbField.Items[Ind]);
end;

procedure TExpXLS.WriteRecordValue(T: TDbf; ARow: Word);
var
  i: Integer;
  field: TField;
  s: String;
begin
  for i := 0 to ClbField.Items.Count - 1 do
    if ClbField.Checked[i] then
    begin
      field := T.FieldByName(ClbField.Items[i]);
      case field.DataType of
        ftString,
        ftFixedChar,
        ftWideString,
        ftMemo:
          begin
            // field.AsString is utf8. Excel2 is ANSI
            s := ConvertEncoding(field.AsString, 'utf8', 'cp' + IntToStr(DbfTable.CodePage));
            ExpObj.PutStr(ARow, i + 1, s);
          end;

        ftFloat,
        ftLargeInt,
        ftCurrency,
        ftBCD:
          ExpObj.PutExt(ARow, i + 1, field.AsFloat);

        ftBytes,
        ftSmallInt,
        ftWord,
        ftAutoInc,
        ftInteger:
          ExpObj.PutInt(ARow, i + 1, field.AsInteger);

        ftDate,
        ftDateTime:
          ExpObj.PutDay(ARow, i + 1, field.AsDateTime);

        ftBoolean:
          if field.AsBoolean then
            ExpObj.PutInt(ARow, i + 1, 1)
          else
            ExpObj.PutInt(ARow, i + 1, 0);
      end;
    end;
end;

function TExpXLS.CreateSplitFileName(Orig: String; Ind: Word): String;
 Var I : Word;
     lExt : String;
begin
 Result := '';

 If Trim(Orig) = '' Then
  Exit;

 lExt := ExtractFileExt(Orig);

 If lExt = '' Then
  Exit;

 For I := 1 To Pos(lExt,Orig) - 1 Do
  Result := Result + Orig[I];

 Result := Result + IntToStr(Ind) + lExt;
end;

procedure TExpXLS.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

// Do not allow to export a picture to Excel, this will damage the file.
procedure TExpXLS.ClbFieldClickCheck(Sender: TObject);
var
  fd: TFieldDef;
begin
  fd := DbfTable.FieldDefs.Items[ClbField.ItemIndex];
  if (fd.DataType = ftBlob) and (fd.DataType <> ftMemo) then
  begin
    ClbField.Checked[ClbField.ItemIndex] := false;
    MessageDlg('Exporting a BLOB field to Excel is not possible.', mtError, [mbOK], 0);
  end;
end;

procedure TExpXLS.ExportBtnClick(Sender: TObject);
var
  i, j, n: Integer;
  FileName: String;
  percent: Integer;
  xlsRow: Integer;
  savedAfterScroll: TDatasetNotifyEvent;
  bm: TBookmark;
begin
  if not SaveExp.Execute then
    exit;

  n := DbfTable.ExactRecordCount;
  if n > 65535 then
    if MessageDlg('There are more than 65.535 records. The export file must be split. Continue?', mtWarning, [mbYes, mbCancel], 0) = mrCancel then
      Exit;

  pBar.Min := 0;
  pBar.Max := 100; //DbfTable.ExactRecordCount;
  pBar.Position := 0;

  savedAfterScroll := DbfTable.AfterScroll;
  DbfTable.AfterScroll := nil;
  bm := DbfTable.GetBookmark;
  DbfTable.DisableControls;

  ExpObj := TDsXLSFile.Create;
  try
    ExpObj.StrFormatNumber := StrFN.Text;
    ExpObj.StrFormatNumberDec := StrFND.Text;
    ExpObj.StrFormatMaskNumber := StrMFN.Text;
    ExpObj.StrFormatMaskNumberDec := StrMFND.Text;
    ExpObj.StrFormatDate := cbDateF.Text;
    ExpObj.CodePage := DbfTable.CodePage;

    xlsRow := 2;
    FileName := SaveExp.FileName;
    ExpObj.Open(FileName);
    CreateFieldTitle();

    i := 0;
    j := 1;
    DbfTable.First;
    try
      while not DbfTable.EOF do
      begin
        WriteRecordValue(DbfTable, xlsRow);
        DbfTable.Next;
        inc(i);
        percent := (i * 100) div n;
        if percent <> pBar.Position then
          pBar.Position := percent;
        Inc(xlsRow);
        // Write at most 65535 records to an Excel2 file. Begin a new file if there are more.
        if xlsRow = 65536 then begin
          ExpObj.Close;
          if DbfTable.EOF then
            break;
          // Prepare next part
          FileName := CreateSplitFileName(SaveExp.FileName, j);
          xlsRow := 2;
          ExpObj.Open(FileName);
          CreateFieldTitle();
          inc(j);
        end;
      end;
      if i <> 65536 then
        ExpObj.Close;

      Close;
      MessageDlg('Table successfully exported to ' + FileName, mtInformation, [mbOK], 0);

    except
      on E:Exception do
      begin
        MessageDlg('Error writing file ' + FileName + ':' + LineEnding + E.Message, mtError, [mbOK], 0);
        exit;
      end;
    end;

  finally
    ExpObj.Free;
    DbfTable.AfterScroll := savedAfterScroll;
    DbfTable.DisableControls;
    DbfTable.GotoBookmark(bm);
    DbfTable.FreeBookmark(bm);
  end;
end;

end.

