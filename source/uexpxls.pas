unit uExpXLS;

{ todo: Allow selection of code page }

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
    XlsRow : Word;
    FDbfTable: TDbf;
    Procedure CreateFieldTitle;
    Procedure WriteRecordValue(T : TDbf);
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
  Math, LConvEncoding, uOptions;

{ TExpXLS }

procedure TExpXLS.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.ExportXLSWindow.ExtractFromForm(Self);
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
  w := {%H-}MaxValue([lblFormatNumberWithDecimals.Width div 2,
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
      ExpObj.PutStr(1, Ind + 1, ClbField.Items.Strings[Ind]);
end;

procedure TExpXLS.WriteRecordValue(T: TDbf);
var
  Ind: Word;
  field: TField;
  s: String;
begin
  for Ind := 0 To ClbField.Items.Count - 1 do
    if ClbField.Checked[Ind] then
    begin
      field := T.FieldByName(ClbField.Items.Strings[Ind]);
      case field.DataType Of
        ftString,
        ftFixedChar,
        ftWideString,
        ftMemo:
          begin
            // field.AsString is utf8. Excel2 is ANSI
            s := ConvertEncoding(field.AsString, 'utf8', 'cp1252');
            ExpObj.PutStr(XlsRow, Ind + 1, s);
          end;

        ftFloat,
        ftLargeInt,
        ftCurrency,
        ftBCD:
          ExpObj.PutExt(XlsRow, Ind + 1, field.AsFloat);

        ftBytes,
        ftSmallInt,
        ftWord,
        ftAutoInc,
        ftInteger:
          ExpObj.PutInt(XlsRow, Ind + 1, field.AsInteger);

        ftDate,
        ftDateTime:
          ExpObj.PutDay(XlsRow, Ind + 1, field.AsDateTime);

        ftBoolean:
          if field.AsBoolean then
            ExpObj.PutInt(XlsRow, Ind + 1, 1)
          else
            ExpObj.PutInt(XlsRow, Ind + 1, 0);
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
  NumBlocks65K: Extended;
  IntBlc, Ind, Ind2: LongInt;
  FileName: String;
begin
  if not SaveExp.Execute then
    exit;

  NumBlocks65k := DbfTable.ExactRecordCount / $FFFF;

  pBar.Min:=0;
  pBar.Max := DbfTable.ExactRecordCount;
  pBar.Position := 0;

  if NumBlocks65K > 1 then
    if MessageDlg('Table records is more then 65.535 and must split the export file. Continue?', mtWarning, [mbYes, mbCancel], 0) = mrCancel then
      Exit;

  ExpObj:=TDsXlsFile.Create;
  try
    ExpObj.StrFormatNumber:=StrFN.Text;
    ExpObj.StrFormatNumberDec:=StrFND.Text;
    ExpObj.StrFormatMaskNumber:=StrMFN.Text;
    ExpObj.StrFormatMaskNumberDec:=StrMFND.Text;
    ExpObj.StrFormatDate:=cbDateF.Text;

    IntBlc:=Trunc(NumBlocks65K);

    DbfTable.First;
    XlsRow := 2;

    if NumBlocks65K < 1.0 then
    begin
      try
        FileName := SaveExp.FileName;
        ExpObj.Open(FileName);
        CreateFieldTitle();
        while not DbfTable.EOF Do
        begin
          WriteRecordValue(DbfTable);
          DbfTable.Next;
          pBar.Position := pBar.Position + 1;
          Inc(XlsRow);
        end;

        ExpObj.Close;

        pBar.Position := 0;
      except
        on E:Exception do
        begin
          MessageDlg('Error writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
          exit;
        end;
      end;
    end else
    begin
      for Ind:=1 To IntBlc do
      begin
        XlsRow := 2;

        if Ind = 1 then
          FileName := SaveExp.FileName
        else
          FileName := CreateSplitFileName(SaveExp.FileName, Ind);

        try
          ExpObj.Open(FileName);
          CreateFieldTitle();
          for ind2 := 1 To $FFFF do
          begin
            WriteRecordValue(DbfTable);
            DbfTable.Next;
            pBar.Position := pBar.Position + 1;
            Inc(XlsRow);
          end;
          ExpObj.Close;
        except
          on E:Exception do
            begin
              MessageDlg('Error on writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
              exit;
            end;
        end;
      end;

      if not DbfTable.EOF then
      begin
        XlsRow := 2;
        FileName := CreateSplitFileName(SaveExp.FileName, Ind + 1);     // todo: is Ind defined here?

        try
          ExpObj.Open(FileName);
          CreateFieldTitle();
          while not DbfTable.EOF do
          begin
            WriteRecordValue(DbfTable);
            DbfTable.Next;
            pBar.Position := pBar.Position + 1;
            Inc(XlsRow);
          end;
          ExpObj.Close;

          pBar.Position := 0;
        except
          on E:Exception do
            begin
              MessageDlg('Error writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
              exit;
            end;
        end;
      end;
    end;

    Close;
    MessageDlg('Table successfully exported to ' + FileName, mtInformation, [mbOK], 0);

  finally
    ExpObj.Free;
  end;
end;

end.

