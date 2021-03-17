unit T_ExpDbf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, CheckLst, ComCtrls, Buttons, dbf_fields, db;

type

  { TExpDbf }

  TExpDbf = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ClbField: TCheckListBox;
    Exp: TDbf;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableType: TComboBox;
    Tmp: TDbf;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Function ReturnTableLevel() : Word;

    Procedure Create_Fields_List();
    Procedure Move_Records();
  public
    { public declarations }
  end; 

var
  ExpDbf: TExpDbf;

implementation

{ TExpDbf }

procedure TExpDbf.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 ClbField.Clear;

 For Ind:=0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind]:=True;
  End;
end;

function TExpDbf.ReturnTableLevel(): Word;
begin
 Case TableType.ItemIndex Of
      0                   : Result:=3;
      1                   : Result:=4;
      2                   : Result:=7;
      3                   : Result:=25;
 End;
end;

procedure TExpDbf.Create_Fields_List();
 Var Ind : Word;
     App : TDbfFieldDefs;
     TmpF : TDbfFieldDef;
begin
 App:=TDbfFieldDefs.Create(Self);

 For Ind:=0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   Begin
    TmpF:=App.AddFieldDef;

    TmpF.FieldName:=Tmp.FieldDefs.Items[Ind].Name;
    TmpF.FieldType:=Tmp.FieldDefs.Items[Ind].DataType;
    TmpF.Required:=True;

    If (TmpF.FieldType = ftString) Or
       (TmpF.FieldType = ftFloat) Or
       (TmpF.FieldType = ftBlob) Or
       (TmpF.FieldType = ftMemo) Or
       (TmpF.FieldType = ftFixedChar) Or
       (TmpF.FieldType = ftWideString) Or
       (TmpF.FieldType = ftBCD) Or
       (TmpF.FieldType = ftBytes) Then
     TmpF.Size:=Tmp.FieldDefs.Items[Ind].Size;

    If (TmpF.FieldType = ftFloat) Or
       (TmpF.FieldType = ftBCD) Then
     TmpF.Precision:=Tmp.FieldDefs.Items[Ind].Precision;
   End;

 If Assigned(App) Then
  Exp.CreateTableEx(App);
end;

procedure TExpDbf.Move_Records();
 Var Ind : Word;
begin
 Exp.Open;
 Tmp.First;

 pBar.Min:=0;
 pBar.Max:=Tmp.ExactRecordCount;
 pBar.Position:=0;

 While Not Tmp.EOF Do
  Begin
   Exp.Insert;

   For Ind:=0 To ClbField.Items.Count - 1 Do
    If ClbField.Checked[Ind] Then
     Exp.FieldByName(ClbField.Items[Ind]).AsVariant:=Tmp.FieldByName(ClbField.Items[Ind]).AsVariant;

   Exp.Post;

   Tmp.Next;

   pBar.Position:=pBar.Position + 1;
  End;

 pBar.Position:=0;
end;

procedure TExpDbf.BitBtn2Click(Sender: TObject);
begin
 If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
  Begin
   If Not SaveExp.Execute Then
    Exit;

   Exp.TableName:=SaveExp.FileName;
   Exp.TableLevel:=ReturnTableLevel();

   Try
     Create_Fields_List();

     Move_Records();

     Exp.Close;

     Close;
   Except
     ShowMessage('Error writing file');
   End;
  End;
end;

initialization
  {$I t_expdbf.lrs}

end.

