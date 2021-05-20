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
    Tmp: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpDs : TDsCSV;

    Function CreateCSVFieldMap : String;

    Procedure StepIt(Sender : TObject; AProgress: LongInt; var StopIt: Boolean);
  public
    { public declarations }
  end;

var
  ExpCSV: TExpCSV;

implementation

{$R *.lfm}

uses
  math;

{ TExpCSV }

procedure TExpCSV.FormShow(Sender: TObject);
 Var Ind : Integer;
begin
 CloseBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
 ExportBtn.Constraints.MinWidth := CloseBtn.Constraints.MinWidth;

 ClbField.Clear;

 Separator.Height := cbDateF.Height;
 fDel.Height := Separator.Height;
 Ignore.Height := Separator.Height;

 For Ind := 0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind] := True;
  End;
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
  var StopIt: Boolean);
begin
 pBar.Position := AProgress;

 Application.ProcessMessages;
end;

procedure TExpCSV.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TExpCSV.ExportBtnClick(Sender: TObject);
begin
 If Trim(Separator.Text) = '' Then
  Begin
   ShowMessage('You MUST insert a record separator...');

   Separator.SetFocus;

   Exit;
  End;

 If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbOk, mbCancel],0) = mrOk Then
  Begin
   If Not SaveExp.Execute Then
    Exit;

   Tmp.First;

   ExpDs := TDsCSV.Create(Self);

   pBar.Min := 0;
   pBar.Max := Tmp.ExactRecordCount - 1;
   pBar.Position:=0;

   Try
     ExpDs.Dataset := Tmp;
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
   Finally
     ExpDs.Free;

     pBar.Position := 0;

     ShowMessage('Export completed!');
   End;
  End;
end;

end.

