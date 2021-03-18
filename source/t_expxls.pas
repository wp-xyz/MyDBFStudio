unit T_ExpXls;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, CheckLst, Buttons, ExtCtrls, ComCtrls, DsXls, Db;

type

  { TExpXls }

  TExpXls = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ClbField: TCheckListBox;
    cbDateF: TComboBox;
    Label1: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    pBar: TProgressBar;
    StrMFND: TLabeledEdit;
    StrMFN: TLabeledEdit;
    StrFND: TLabeledEdit;
    StrFN: TLabeledEdit;
    SaveExp: TSaveDialog;
    Tmp: TDbf;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpObj : TDsXlsFile;
    XlsRow : Word;

    Function CreateSplitFileName(Orig : String; Ind : Word) : String;

    Procedure CreateFieldTitle();
    Procedure WriteRecordValue(T : TDbf);
  public
    { public declarations }
  end; 

var
  ExpXls: TExpXls;

implementation

{$R *.lfm}

{ TExpXls }

procedure TExpXls.BitBtn2Click(Sender: TObject);
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

     Close;
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

       Close;
       Except
         ShowMessage('Error on writing file...');
       End;
      End
     Else
      Close;
    End;

   pBar.Position:=0;

   ExpObj.Free;
  End;
end;

procedure TExpXls.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 ClbField.Clear;

 For Ind:=0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind]:=True;
  End;
end;

function TExpXls.CreateSplitFileName(Orig: String; Ind: Word): String;
 Var I : Word;
     lExt : String;
begin
 Result:='';

 If Trim(Orig) = '' Then
  Exit;

 lExt:=ExtractFileExt(Orig);

 If lExt = '' Then
  Exit;

 For I:=1 To Pos(lExt,Orig) - 1 Do
  Result:=Result + Orig[I];

 Result:=Result + IntToStr(Ind) + lExt;
end;

procedure TExpXls.CreateFieldTitle();
 Var Ind : Word;
begin
 For Ind:=0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   ExpObj.PutStr(1,Ind + 1,ClbField.Items.Strings[Ind]);
end;

procedure TExpXls.WriteRecordValue(T : TDbf);
 Var Ind : Word;
begin
 For Ind:=0 To ClbField.Items.Count - 1 Do
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


end.

