unit T_SetFV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type

  { TSetFV }

  TSetFV = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    CheckBox1: TCheckBox;
    cbFirst: TComboBox;
    cbSecond: TComboBox;
    cbOp: TComboBox;
    CbMode: TRadioGroup;
    SetTable: TDbf;
    gbMath: TGroupBox;
    Label1: TLabel;
    FieldList: TListBox;
    Label2: TLabel;
    Label3: TLabel;
    sSetVal: TLabeledEdit;
    SelField: TLabeledEdit;
    procedure BitBtn2Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FieldListClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  SetFV: TSetFV;

implementation

{$R *.lfm}

{ TSetFV }

procedure TSetFV.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 CbMode.ItemIndex:=0;
 gbMath.Enabled:=False;

 FieldList.Clear;
 cbFirst.Clear;
 cbSecond.Clear;

 For Ind:=0 To SetTable.FieldDefs.Count - 1 Do
  Begin
   FieldList.Items.Add(SetTable.FieldDefs.Items[Ind].Name);

   cbFirst.Items.Add(SetTable.FieldDefs.Items[Ind].Name);
   cbSecond.Items.Add(SetTable.FieldDefs.Items[Ind].Name);
  End;
end;

procedure TSetFV.FieldListClick(Sender: TObject);
begin
 SelField.Text:=FieldList.Items[FieldList.ItemIndex];
end;

procedure TSetFV.CheckBox1Change(Sender: TObject);
begin
 gbMath.Enabled:=CheckBox1.Checked;

 sSetVal.Enabled:=Not CheckBox1.Checked;
end;

procedure TSetFV.BitBtn2Click(Sender: TObject);
 Var Error : Boolean;
begin
 If Trim(SelField.Text) = '' Then
  Begin
   ShowMessage('You must select a destination field...');

   FieldList.SetFocus;

   Exit;
  End;

 If Not CheckBox1.Checked Then
  Begin
   If Trim(sSetVal.Text) = '' Then
    Begin
     ShowMessage('You must insert a value to set...');

     sSetVal.SetFocus;

     Exit;
    End;
  End
 Else
  Begin
   If cbFirst.Text = '' Then
    Begin
     ShowMessage('You must select a first field in matemathical operation...');

     cbFirst.SetFocus;

     Exit;
    End;

   If cbSecond.Text = '' Then
    Begin
     ShowMessage('You must select a second field in matemathical operation...');

     cbSecond.SetFocus;

     Exit;
    End;
  End;

 If MessageDlg('Do you want to attempt to set field?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
  Begin
   Error:=False;

   If CbMode.ItemIndex = 1 Then
    SetTable.Filter:='';

   SetTable.First;

   While Not SetTable.EOF Do
    Begin
     If Not CheckBox1.Checked Then
      Begin
       Try
         SetTable.Edit;

         SetTable.FieldByName(SelField.Text).AsVariant:=sSetVal.Text;

         SetTable.Post;
       Except
         ShowMessage('Error while set value in table. Check if the value match width field type or size.');
         Error:=True;

         Break;

         Exit;
       End;
      End
     Else
      Begin
       Try
         SetTable.Edit;

         Case cbOp.ItemIndex Of
          0                  : SetTable.FieldByName(SelField.Text).AsVariant:=
                               SetTable.FieldByName(cbFirst.Text).AsVariant +
                               SetTable.FieldByName(cbSecond.Text).AsVariant;

          1                  : SetTable.FieldByName(SelField.Text).AsVariant:=
                               SetTable.FieldByName(cbFirst.Text).AsVariant -
                               SetTable.FieldByName(cbSecond.Text).AsVariant;

          2                  : SetTable.FieldByName(SelField.Text).AsVariant:=
                               SetTable.FieldByName(cbFirst.Text).AsVariant *
                               SetTable.FieldByName(cbSecond.Text).AsVariant;

          3                  : SetTable.FieldByName(SelField.Text).AsVariant:=
                               SetTable.FieldByName(cbFirst.Text).AsVariant /
                               SetTable.FieldByName(cbSecond.Text).AsVariant;
         End;

         SetTable.Post;
       Except
         ShowMessage('Error while set value in table. Check if the value match width field type or operation.');
         Error:=True;

         Break;

         Exit;
       End;
      End;

     SetTable.Next;
    End;

   If Not Error Then
    Close;
  End;
end;


end.

