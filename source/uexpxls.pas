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
    Tmp: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpObj : TDsXlsFile;
    XlsRow : Word;

    Procedure CreateFieldTitle;
    Procedure WriteRecordValue(T : TDbf);

    Function CreateSplitFileName(Orig : String; Ind : Word) : String;
  public
    { public declarations }
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

procedure TExpXLS.FormShow(Sender: TObject);
var
  ind: Integer;
  w: Integer;
begin
  w := MaxValue([lblFormatNumberWidthDecimals.Width div 2,
                 lblMaskNumberWidthDecimals.Width div 2,
                 ExportBtn.Width,
                 CloseBtn.Width
                ]);
  ExportBtn.Constraints.MinWidth := w;
  CloseBtn.Constraints.MinWidth := w;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportXLSWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportXLSWindow.ApplyToForm(Self);
  end;

  ClbField.Clear;

  for ind := 0 to Tmp.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(Tmp.FieldDefs.Items[ind].Name);
    ClbField.Checked[ind] := True;
  end;
end;

procedure TExpXLS.CreateFieldTitle;
 Var Ind : Word;
begin
 For Ind := 0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   ExpObj.PutStr(1, Ind + 1, ClbField.Items.Strings[Ind]);
end;

procedure TExpXLS.WriteRecordValue(T: TDbf);
 Var Ind : Word;
begin
 For Ind := 0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   Begin
    Case T.FieldByName(ClbField.Items.Strings[Ind]).DataType Of
     ftString,
     ftFixedChar,
     ftWideString,
     ftMemo                      : ExpObj.PutStr(XlsRow,Ind + 1,T.FieldByName(ClbField.Items.Strings[Ind]).AsString);

     ftFloat,
     ftLargeInt,
     ftCurrency,
     ftBCD                       : ExpObj.PutExt(XlsRow,Ind + 1,T.FieldByName(ClbField.Items.Strings[Ind]).AsFloat);

     ftBytes,
     ftSmallInt,
     ftWord,
     ftAutoInc,
     ftInteger                   : ExpObj.PutInt(XlsRow,Ind + 1,T.FieldByName(ClbField.Items.Strings[Ind]).AsInteger);

     ftDate,
     ftDateTime                  : ExpObj.PutDay(XlsRow,Ind + 1,T.FieldByName(ClbField.Items.Strings[Ind]).AsDateTime);

     ftBoolean                   : If T.FieldByName(ClbField.Items.Strings[Ind]).AsBoolean Then
                                    ExpObj.PutInt(XlsRow,Ind + 1,1)
                                   Else
                                    ExpObj.PutInt(XlsRow,Ind + 1,0);
    End;
   End;
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

procedure TExpXLS.ExportBtnClick(Sender: TObject);
 Var NumBlocchi65K : Extended;
     IntBlc,Ind,Ind2 : LongInt;
     FileName : String;
begin
 If SaveExp.Execute Then
  Begin
   NumBlocchi65K:=Tmp.ExactRecordCount / $FFFF;

   pBar.Min:=0;
   pBar.Max:=Tmp.ExactRecordCount;
   pBar.Position:=0;

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

   Tmp.First;
   XlsRow:=2;

   If NumBlocchi65K < 1.0 Then
    Begin
     Try
     ExpObj.Open(SaveExp.FileName);

     CreateFieldTitle();

     While Not Tmp.EOF Do
      Begin
       WriteRecordValue(Tmp);

       Tmp.Next;
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
         WriteRecordValue(Tmp);

         Tmp.Next;
         pBar.Position:=pBar.Position + 1;

         Inc(XlsRow);
        End;

       ExpObj.Close;
       Except
        ShowMessage('Error on writing file...');

        Exit;
       End;
      End;

     If Not Tmp.EOF Then
      Begin
       XlsRow:=2;
       FileName:=CreateSplitFileName(SaveExp.FileName,Ind + 1);

       Try
       ExpObj.Open(FileName);

       CreateFieldTitle();

       While Not Tmp.EOF Do
        Begin
         WriteRecordValue(Tmp);

         Tmp.Next;
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

