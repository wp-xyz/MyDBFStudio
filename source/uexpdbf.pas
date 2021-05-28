unit uExpDBF;

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
    Exp: TDbf;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableType: TComboBox;
    Tmp: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    Function ReturnTableLevel : Word;

    Procedure Create_Fields_List;

    Procedure Move_Records;
  public
    { public declarations }
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
 If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbOk, mbCancel],0) = mrOk Then
  Begin
   If Not SaveExp.Execute Then
    Exit;

   Exp.TableName := SaveExp.FileName;
   Exp.TableLevel := ReturnTableLevel;

   Try
     Create_Fields_List();

     Move_Records();

     Exp.Close;

     ShowMessage('Export completed!');
   Except
     ShowMessage('Error writing file');
   End;
  End;
end;

procedure TExpDBF.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.ExportDBFWindow.ExtractFromForm(Self);
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

  for ind := 0 to Tmp.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(Tmp.FieldDefs.Items[ind].Name);
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
 Var Ind : Word;
     App : TDbfFieldDefs;
     TmpF : TDbfFieldDef;
begin
 App := TDbfFieldDefs.Create(Self);

 For Ind := 0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   Begin
    TmpF := App.AddFieldDef;

    TmpF.AssignDb(Tmp.FieldDefs[Ind]);
   End;

 If Assigned(App) Then
  Exp.CreateTableEx(App);
end;

procedure TExpDBF.Move_Records;
 Var Ind : Word;
begin
 Exp.Open;
 Tmp.First;

 pBar.Min := 0;
 pBar.Max := Tmp.ExactRecordCount;
 pBar.Position := 0;

 While Not Tmp.EOF Do
  Begin
   Exp.Insert;

   For Ind := 0 To ClbField.Items.Count - 1 Do
    If ClbField.Checked[Ind] Then
     Exp.FieldByName(ClbField.Items[Ind]).AsVariant := Tmp.FieldByName(ClbField.Items[Ind]).AsVariant;

   Exp.Post;

   Tmp.Next;

   pBar.StepIt;
  End;

 pBar.Position := 0;
end;

end.

