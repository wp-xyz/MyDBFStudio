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
    lblMaskNumberWidthDecimals: TLabel;
    lblMaskNumber: TLabel;
    lblFormatNumberWidthDecimals: TLabel;
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
    FDbf: TDbf;
    Procedure CreateFieldTitle;
    Procedure WriteRecordValue(T : TDbf);
    Function CreateSplitFileName(Orig : String; Ind : Word) : String;
  public
    { public declarations }
    property Dbf: TDbf read FDbf write FDbf;
  end;

var
  ExpXLS: TExpXLS;

implementation

{$R *.lfm}

uses
  Math, uOptions;

{ TExpXLS }

procedure TExpXLS.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.ExportXLSWindow.ExtractFromForm(Self);
end;

procedure TExpXLS.FormCreate(Sender: TObject);
begin
  FDbf := TDbf.Create(self);
end;

procedure TExpXLS.FormShow(Sender: TObject);
var
  ind: Integer;
  w: Integer;
begin
  w := {%H-}MaxValue([lblFormatNumberWidthDecimals.Width div 2,
                 lblMaskNumberWidthDecimals.Width div 2,
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

  for ind := 0 to FDbf.FieldDefs.Count - 1 do
    with FDbf.FieldDefs.Items[Ind] do
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
  for Ind := 0 To ClbField.Items.Count - 1 do
    if ClbField.Checked[Ind] then
      ExpObj.PutStr(1, Ind + 1, ClbField.Items.Strings[Ind]);
end;

procedure TExpXLS.WriteRecordValue(T: TDbf);
var
  Ind: Word;
  field: TField;
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
          ExpObj.PutStr(XlsRow, Ind + 1, field.AsString);

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

        ftBlob:
          ;  // Do not write a picture
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
  fd := FDbf.FieldDefs.Items[ClbField.ItemIndex];
  if (fd.DataType = ftBlob) and (fd.DataType <> ftMemo) then
  begin
    ClbField.Checked[ClbField.ItemIndex] := false;
    MessageDlg('Exporting a BLOB field to Excel is not possible.', mtError, [mbOK], 0);
  end;
end;

procedure TExpXLS.ExportBtnClick(Sender: TObject);
 Var NumBlocchi65K : Extended;
     IntBlc,Ind,Ind2 : LongInt;
     FileName : String;
begin
  If SaveExp.Execute Then
  Begin
   NumBlocchi65K:= FDbf.ExactRecordCount / $FFFF;

   pBar.Min:=0;
   pBar.Max := FDbf.ExactRecordCount;
   pBar.Position := 0;

   If NumBlocchi65K > 1 Then
    If MessageDlg('Table records is more then 65.535 and must split the export file, continue?',mtWarning,[mbYes, mbCancel],0) = mrCancel Then
     Exit;

   ExpObj:=TDsXlsFile.Create;

   ExpObj.StrFormatNumber:=StrFN.Text;
   ExpObj.StrFormatNumberDec:=StrFND.Text;
   ExpObj.StrFormatMaskNumber:=StrMFN.Text;
   ExpObj.StrFormatMaskNumberDec:=StrMFND.Text;
   ExpObj.StrFormatDate:=cbDateF.Text;

   IntBlc:=Trunc(NumBlocchi65K);

   Dbf.First;
   XlsRow:=2;

   If NumBlocchi65K < 1.0 Then
    Begin
     Try
     ExpObj.Open(SaveExp.FileName);

     CreateFieldTitle();

     While Not Dbf.EOF Do
      Begin
       WriteRecordValue(Dbf);
       Dbf.Next;
       pBar.Position:=pBar.Position + 1;

       Inc(XlsRow);
      End;

     ExpObj.Close;

     ShowMessage('Export completed!');
     Except
      ShowMessage('Error on writing file...');
     End;
    End
   Else
    Begin
     For Ind:=1 To IntBlc Do
      Begin
       XlsRow:=2;

       If Ind = 1 Then
        FileName:=SaveExp.FileName
       Else
        FileName:=CreateSplitFileName(SaveExp.FileName,Ind);

       Try
       ExpObj.Open(FileName);

       CreateFieldTitle();

       For Ind2:=1 To $FFFF Do
        Begin
         WriteRecordValue(Dbf);

         Dbf.Next;
         pBar.Position:=pBar.Position + 1;

         Inc(XlsRow);
        End;

       ExpObj.Close;
       Except
        ShowMessage('Error on writing file...');

        Exit;
       End;
      End;

     If Not Dbf.EOF Then
      Begin
       XlsRow:=2;
       FileName:=CreateSplitFileName(SaveExp.FileName,Ind + 1);

       Try
       ExpObj.Open(FileName);

       CreateFieldTitle();

       While Not Dbf.EOF Do
        Begin
         WriteRecordValue(Dbf);

         Dbf.Next;
         pBar.Position:=pBar.Position + 1;

         Inc(XlsRow);
        End;

       ExpObj.Close;

       ShowMessage('Export completed!');
       Except
         ShowMessage('Error on writing file...');
       End;
      End
     Else
      ShowMessage('Export completed!');
    End;

   pBar.Position:=0;

   ExpObj.Free;
  End;
end;

end.

