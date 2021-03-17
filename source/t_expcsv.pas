unit T_ExpCSV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, Buttons, ComCtrls, DsCsv, dbf;

type

  { TExpCSV }

  TExpCSV = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ClbField: TCheckListBox;
    cbDateF: TComboBox;
    fDel: TLabeledEdit;
    Tmp: TDbf;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SaveExp: TSaveDialog;
    Separator: TLabeledEdit;
    Ignore: TLabeledEdit;
    pBar: TProgressBar;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpDs : TDsCSV;

    Function CreateCSVFieldMap() : String;

    Procedure StepIt(Sender : TObject; AProgress: LongInt; var StopIt: Boolean);
  public
    { public declarations }
  end; 

var
  ExpCSV: TExpCSV;

implementation

{ TExpCSV }

procedure TExpCSV.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 ClbField.Clear;

 Separator.Height:=cbDateF.Height;
 fDel.Height:=Separator.Height;
 Ignore.Height:=Separator.Height;

 For Ind:=0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind]:=True;
  End;
end;

procedure TExpCSV.BitBtn2Click(Sender: TObject);
begin
 If Trim(Separator.Text) = '' Then
  Begin
   ShowMessage('You MUST insert a record separator...');

   Separator.SetFocus;

   Exit;
  End;

 If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
  Begin
   If Not SaveExp.Execute Then
    Exit;

   Tmp.First;

   ExpDs:=TDsCSV.Create(Self);

   pBar.Min:=0;
   pBar.Max:=Tmp.ExactRecordCount - 1;
   pBar.Position:=0;

   Try
     ExpDs.Dataset:=Tmp;
     ExpDs.CSVFile:=SaveExp.FileName;
     ExpDs.EmptyTable:=True;
     ExpDs.AutoOpen:=False;
     ExpDs.IgnoreString:=Ignore.Text;
     ExpDs.Delimiter:=fDel.Text;

     ExpDs.CSVMap:=CreateCSVFieldMap();

     ExpDs.Separator:=Separator.Text[1];

     ExpDs.DateFormat:=cbDateF.Text;

     ExpDs.ImportProgress:=@StepIt;

     ExpDs.DatasetToCSV();
   Finally
     ExpDs.Free;

     pBar.Position:=0;
   End;
  End;
end;

function TExpCSV.CreateCSVFieldMap(): String;
 Var Ind : Integer;
begin
 Result:='';

 For Ind:=0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   Result:=Result + '$' + ClbField.Items[Ind] + Separator.Text[1];
end;

procedure TExpCSV.StepIt(Sender: TObject; AProgress: LongInt; var StopIt: Boolean);
begin
 pBar.Position:=AProgress;

 Application.ProcessMessages;
end;

initialization
  {$I t_expcsv.lrs}

end.

