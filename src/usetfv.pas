unit uSetFV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Buttons;

type

  { TSetFV }

  TSetFV = class(TForm)
    CloseBtn: TBitBtn;
    ConfirmBtn: TBitBtn;
    cbFirst: TComboBox;
    rgMode: TRadioGroup;
    cbOp: TComboBox;
    cbSecond: TComboBox;
    cbUseMathOperations: TCheckBox;
    FieldList: TListBox;
    gbMath: TGroupBox;
    gbSelField: TGroupBox;
    gbSetVal: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SelField: TEdit;
    sSetVal: TEdit;
    procedure cbUseMathOperationsChange(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure ConfirmBtnClick(Sender: TObject);
    procedure FieldListClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FSetTable: TDbf;
  public
    { public declarations }
    property SetTable: TDbf read FSetTable write FSetTable;
  end;

var
  SetFV: TSetFV;

implementation

{$R *.lfm}

uses
  DB, uOptions;

{ TSetFV }

procedure TSetFV.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.SetFieldValueWindow.ExtractFromForm(Self);
end;

procedure TSetFV.FormShow(Sender: TObject);
var
  Ind: Word;
  fieldName: STring;
begin
  CloseBtn.Constraints.MinWidth := ConfirmBtn.Width;

  Options.SetFieldValueWindow.ApplyToForm(self);

  rgMode.ItemIndex := 0;
  gbMath.Enabled := False;

  FieldList.Clear;
  cbFirst.Clear;
  cbSecond.Clear;

  for Ind := 0 To SetTable.FieldDefs.Count - 1 do
  begin
    fieldName := SetTable.FieldDefs.Items[ind].Name;
    FieldList.Items.Add(fieldName);
    cbFirst.Items.Add(fieldName);
    cbSecond.Items.Add(fieldName);
  end;
end;

procedure TSetFV.cbUseMathOperationsChange(Sender: TObject);
begin
  gbMath.Enabled := cbUseMathOperations.Checked;
  sSetVal.Enabled := Not cbUseMathOperations.Checked;
end;

procedure TSetFV.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TSetFV.ConfirmBtnClick(Sender: TObject);
var
  Error: Boolean;
  lSelField: TField;
  lFirstField: TField;
  lSecondField: TField;
begin
  if Trim(SelField.Text) = '' then
  begin
    MessageDlg('You must select a destination field...', mtError, [mbOK], 0);
    FieldList.SetFocus;
    exit;
  end;

  if not cbUseMathOperations.Checked then
  begin
    if Trim(sSetVal.Text) = '' then
    begin
      MessageDlg('You must insert a value to set...', mtError,[mbOK], 0);
      sSetVal.SetFocus;
      exit;
    end;
  end else
  begin
    if cbFirst.Text = '' then
    begin
      MessageDlg('You must select a first field in matemathical operation...', mtError, [mbOK], 0);
      cbFirst.SetFocus;
      exit;
    end;

    if cbSecond.Text = '' then
    begin
      MessageDlg('You must select a second field in matemathical operation...', mtError, [mbOK], 0);
      cbSecond.SetFocus;
      exit;
    end;
  end;

  if MessageDlg('Do you really want to set field values?',mtWarning,[mbok, mbCancel],0) <> mrOk then
    exit;

  Error := False;
  if rgMode.ItemIndex = 1 Then
    SetTable.Filter := '';

  SetTable.First;
  lSelField := SetTable.FieldByName(SelField.Text);
  if cbUseMathOperations.Checked then
  begin
    lFirstField := SetTable.FieldByName(cbFirst.Text);
    lSecondField := SetTable.FieldByName(cbSecond.Text);
  end;
  while not SetTable.EOF do
  begin
    if not cbUseMathOperations.Checked then
    begin
      try
        SetTable.Edit;
        lSelField.AsVariant := sSetVal.Text{%H-};
        SetTable.Post;
      except
        MessageDlg(
          'Error while set value in table. Check if the value match width field type or size.',
          mtError, [mbOK], 0
        );
        Error := True;
        Break;
      end;
    end else
    begin
      try
        SetTable.Edit;
        case cbOp.ItemIndex of
          0: lSelField.AsVariant := lFirstField.AsVariant + lSecondField.AsVariant;
          1: lSelField.AsVariant := lFirstField.AsVariant - lSecondField.AsVariant;
          2: lSelField.AsVariant := lFirstField.AsVariant * lSecondField.AsVariant;
          3: lSelField.AsVariant := lfirstField.AsVariant / lSecondField.AsVariant;
        end;
        SetTable.Post;
      except
        MessageDlg(
          'Error while set value in table. Check if the value match width field type or operation.',
          mtError, [mbOK], 0);
        Error := True;
        Break;
      end;
    end;
    SetTable.Next;
  end;

  if not Error then
    Close;
end;

procedure TSetFV.FieldListClick(Sender: TObject);
begin
  SelField.Text := FieldList.Items[FieldList.ItemIndex];
end;

end.

