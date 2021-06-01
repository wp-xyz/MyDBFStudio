unit uRestructure;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Buttons, ExtCtrls, db, dbf_fields;

type

  MyIndex         = Packed Record
   IdxName        : String;
   Fields         : String;
   Options        : TIndexOptions;
   Deleted        : Boolean;
  End;

  { TRestructure }

  TRestructure = class(TForm)
    CloseBtn: TBitBtn;
    lblFieldList: TLabel;
    lblLanguage: TLabel;
    lblCodePage: TLabel;
    RestructureBtn: TBitBtn;
    DefineBtn: TBitBtn;
    EditBtn: TBitBtn;
    DeleteBtn: TBitBtn;
    cbPack: TCheckBox;
    FieldList: TStringGrid;
    IndexList: TListBox;
    lblIndexList: TLabel;
    Panel1: TPanel;
    Temp: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RestructureBtnClick(Sender: TObject);
    procedure DefineBtnlick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure EditBtnlick(Sender: TObject);
    procedure FieldListKeyDown(Sender: TObject; var Key: Word;
      {%H-}Shift: TShiftState);
    procedure IndexListDblClick(Sender: TObject);
  private
    { private declarations }
    MyIndexList : Array Of MyIndex;

    Procedure ShowIndexList;

    Function Check_Value(Val : String) : Boolean;

    function CreateNewFieldDefs : TDbfFieldDefs;
    procedure RecreateMyIndex;
    function RetFieldType(AValue: String) : TFieldType;

    procedure ShowInfo(ATable: TDbf);
  public
    { public declarations }
    Function TestIndexName(Val : String) : Boolean;
  end;

var
  Restructure: TRestructure;

implementation

Uses
  LCLType, TypInfo, Math, uUtils, uIdxTable, uOptions;

{$R *.lfm}

{ TRestructure }

procedure TRestructure.FormDestroy(Sender: TObject);
begin
 SetLength(MyIndexList, 0);
end;

procedure TRestructure.FieldListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 If Key = 40 Then     //Down Arrow
  Begin
   If FieldList.Row = FieldList.RowCount - 1 Then
    If (FieldList.Cells[1,FieldList.RowCount - 1] <> '') And
       (FieldList.Cells[2,FieldList.RowCount - 1] <> '') Then
     Begin
      FieldList.RowCount:=FieldList.RowCount + 1;

      FieldList.Cells[0,FieldList.RowCount - 1] := IntToStr(FieldList.RowCount - 1);
      FieldList.Cells[4,FieldList.RowCount - 1] := 'Y';                        //New Field
      FieldList.Col := 1;
      FieldList.Row := FieldList.RowCount - 1;
     End;
  End
 Else
  If Key = 38 Then                      //Up Arrow
   Begin
    If (FieldList.Cells[1,FieldList.RowCount - 1] = '') And
       (FieldList.Cells[2,FieldList.RowCount - 1] = '') Then
     Begin
      FieldList.RowCount:=FieldList.RowCount - 1;

     //FieldList.Col:=1;
     //FieldList.Row:=FieldList.RowCount + 1;
     End;
   End
  Else
   If Key = 46 Then                      //Del
    If FieldList.Row >= 1 Then
     If MessageDlg('Delete the field?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
      Begin
       FieldList.DeleteColRow(False, FieldList.Row);

       If FieldList.Row = 0 Then
        Begin
         FieldList.RowCount := FieldList.RowCount + 1;

         FieldList.Cells[0,FieldList.RowCount - 1] := IntToStr(FieldList.RowCount - 1);
         FieldList.Col := 1;
         FieldList.Row := FieldList.RowCount - 1;
        End;
      End;
end;

procedure TRestructure.DeleteBtnClick(Sender: TObject);
 Var dName : String;
     Ind : Word;
begin
 If IndexList.ItemIndex < 0 Then
  Exit;

 If MessageDlg('Delete the selected index?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
  Begin
   dName := IndexList.Items[IndexList.ItemIndex];

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If MyIndexList[Ind].IdxName = dName Then
     MyIndexList[Ind].Deleted := True;

   ShowIndexList;
  End;
end;

procedure TRestructure.EditBtnlick(Sender: TObject);
begin
 If IndexList.ItemIndex < 0 Then
  Exit;

 IndexListDblClick(Sender);
end;

procedure TRestructure.DefineBtnlick(Sender: TObject);
 Var Ind : Word;
     lOpt : TIndexOptions;
     ExpField : String;
begin
 If FieldList.RowCount > 1 Then
  Begin
   IdxTable := TIdxTable.Create(Self);
   IdxTable.New := True;
   IdxTable.Calling := Restructure;
   lOpt := [];

   For Ind := 1 To FieldList.RowCount - 1 Do
    IdxTable.IdxList.Items.Add(FieldList.Cells[1,Ind]);

   IdxTable.ShowModal;

   If IdxTable.Ret Then
    Begin
     ExpField := IdxTable.SelField.Text;

     If IdxTable.cbOpt.Checked[0] Then
      lOpt := lOpt + [ixPrimary];

     If IdxTable.cbOpt.Checked[1] Then
      lOpt := lOpt + [ixUnique];

     If IdxTable.cbOpt.Checked[2] Then
      lOpt := lOpt + [ixDescending];

     If IdxTable.cbOpt.Checked[3] Then
      lOpt := lOpt + [ixCaseInsensitive];

     SetLength(MyIndexList, Length(MyIndexList) + 1);

     MyIndexList[Length(MyIndexList) - 1].Options := lOpt;
     MyIndexList[Length(MyIndexList) - 1].IdxName := IdxTable.IdxName.Text;
     MyIndexList[Length(MyIndexList) - 1].Fields := ExpField;
     MyIndexList[Length(MyIndexList) - 1].Deleted := False;

     ShowIndexList();
    End;

   IdxTable.Free;
  End;
end;

procedure TRestructure.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TRestructure.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.RestructureWindow.ExtractFromForm(Self);
end;

procedure TRestructure.FormCreate(Sender: TObject);
begin
  FieldList.AlternateColor := Options.AlternateColor
end;

procedure TRestructure.RestructureBtnClick(Sender: TObject);
 Var Ind : Word;
begin
 For Ind := 1 To FieldList.RowCount - 1 Do
  Begin
   If Trim(FieldList.Cells[1,Ind]) = '' Then
    Begin
     ShowMessage('Row: ' + IntToStr(Ind) + '. Missing field name!');

     FieldList.Row := Ind;
     FieldList.Col := 1;

     Exit;
    End;

   If FieldList.Cells[2,Ind] = '' Then
    Begin
     ShowMessage('Row: ' + IntToStr(Ind) + '. Missing field type!');

     FieldList.Row := Ind;
     FieldList.Col := 2;

     Exit;
    End;

   If (FieldList.Cells[2,Ind] = Fieldtypenames[ftString]) Or
      //(FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBlob]) Or
      //(FieldList.Cells[2,Ind] = Fieldtypenames[ftMemo]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftFixedChar]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftWideString]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBCD]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBytes]) Then
    If Not Check_Value(FieldList.Cells[3,Ind]) Then
     Begin
      ShowMessage('Row: ' + IntToStr(Ind) + '. Field length error!');

      FieldList.Row := Ind;
      FieldList.Col := 3;

      Exit;
     End;

{   If (FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBCD]) Then
    If Not Check_Value(FieldList.Cells[4,Ind]) Then
     Begin
      ShowMessage('Row: ' + IntToStr(Ind) + '. Decimals length error!');

      FieldList.Row:=Ind;
      FieldList.Col:=4;

      Exit;
     End;}
  End;

 Temp.Close;

 Temp.RestructureTable(CreateNewFieldDefs(), cbPack.Checked);

 Temp.Open;
 //Temp.RegenerateIndexes;

 RecreateMyIndex();

 Close;
end;

procedure TRestructure.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 DefineBtn.Constraints.MinWidth := MaxValue([DefineBtn.Width, EditBtn.Width, DeleteBtn.Width]){%H-};
 EditBtn.Constraints.MinWidth := DefineBtn.Constraints.MinWidth;
 DeleteBtn.Constraints.MinWidth := DefineBtn.Constraints.MinWidth;

 Constraints.MinHeight := Panel1.Top + Panel1.Height + CloseBtn.Height + CloseBtn.BorderSpacing.Top*2;
 Constraints.MinWidth := FieldList.Left + FieldList.Constraints.MinWidth +
   FieldList.BorderSpacing.Around + Panel1.Width + Panel1.Borderspacing.Right;

 if Options.RememberWindowSizePos then
 begin
   AutoSize := false;
   Options.RestructureWindow.ApplyToForm(self);
 end;

 FieldList.RowCount := Temp.FieldDefs.Count + 1;
 IndexList.Clear;

 For Ind :=0 To Temp.FieldDefs.Count - 1 Do
  Begin
   FieldList.Cells[0,Ind + 1] := IntToStr(Ind + 1);
   FieldList.Cells[1,Ind + 1] := Temp.FieldDefs.Items[Ind].Name;
   FieldList.Cells[2,Ind + 1] := Fieldtypenames[Temp.FieldDefs.Items[Ind].DataType];

   FieldList.Cells[3,Ind + 1] := '';

   If Temp.FieldDefs.Items[Ind].Size > 0 Then
    FieldList.Cells[3,Ind + 1] := IntToStr(Temp.FieldDefs.Items[Ind].Size);

   If Temp.FieldDefs.Items[Ind].Precision > 0 Then
    FieldList.Cells[3,Ind + 1] := IntToStr(Temp.FieldDefs.Items[Ind].Precision);

   FieldList.Cells[4,Ind + 1] := 'N';
  end;

 If Temp.Indexes.Count > 0 Then
  Begin
   SetLength(MyIndexList, Temp.Indexes.Count);

   For Ind := 0 To Temp.Indexes.Count - 1 Do
    Begin
     MyIndexList[Ind].IdxName := Temp.Indexes.Items[Ind].Name;
     MyIndexList[Ind].Fields := Temp.Indexes.Items[Ind].Expression;
     MyIndexList[Ind].Options := Temp.Indexes.Items[Ind].Options;
     MyIndexList[Ind].Deleted := False;

     ShowIndexList();
    end;
  end;

 FieldTypePickList(Temp.TableLevel, FieldList.Columns[2].PickList);

 ShowInfo(Temp);
end;

procedure TRestructure.IndexListDblClick(Sender: TObject);
 Var OldIdxName : String;
     Ind : Word;
     lOpt : TIndexOptions;
begin
 If IndexList.Items.Count > 0 Then
  Begin
   OldIdxName:=IndexList.Items[IndexList.ItemIndex];

   IdxTable:=TIdxTable.Create(Self);
   IdxTable.New:=False;
   IdxTable.Calling:=Restructure;
   lOpt:=[];

   For Ind:=1 To FieldList.RowCount - 1 Do
    IdxTable.IdxList.Items.Add(FieldList.Cells[1,Ind]);

   For Ind:=0 To Length(MyIndexList) - 1 Do
    If Not MyIndexList[Ind].Deleted Then
     If MyIndexList[Ind].IdxName = OldIdxName Then
      Begin
       lOpt:=MyIndexList[Ind].Options;

       Break;
      End;

   IdxTable.IdxName.Text:=OldIdxName;

   IdxTable.SelField.Text:=MyIndexList[Ind].Fields;

   If ixPrimary In lOpt Then
    IdxTable.cbOpt.Checked[0]:=True;

   If ixUnique In lOpt Then
    IdxTable.cbOpt.Checked[1]:=True;

   If ixDescending In lOpt Then
    IdxTable.cbOpt.Checked[2]:=True;

   If ixCaseInsensitive In lOpt Then
    IdxTable.cbOpt.Checked[3]:=True;

   IdxTable.ShowModal;

   If IdxTable.Ret Then
    Begin
     For Ind:=0 To Length(MyIndexList) - 1 Do
      If Not MyIndexList[Ind].Deleted Then
       If MyIndexList[Ind].IdxName = OldIdxName Then
        MyIndexList[Ind].Deleted:=True;         //Delete old index...

     lOpt:=[];

     If IdxTable.cbOpt.Checked[0] Then
      lOpt:=lOpt + [ixPrimary];

     If IdxTable.cbOpt.Checked[1] Then
      lOpt:=lOpt + [ixUnique];

     If IdxTable.cbOpt.Checked[2] Then
      lOpt:=lOpt + [ixDescending];

     If IdxTable.cbOpt.Checked[3] Then
      lOpt:=lOpt + [ixCaseInsensitive];

     SetLength(MyIndexList,Length(MyIndexList) + 1);     //Insert New Index

     MyIndexList[Length(MyIndexList) - 1].Options:=lOpt;
     MyIndexList[Length(MyIndexList) - 1].IdxName:=IdxTable.IdxName.Text;
     MyIndexList[Length(MyIndexList) - 1].Fields:=IdxTable.SelField.Text;
     MyIndexList[Length(MyIndexList) - 1].Deleted:=False;

     ShowIndexList();
    End;

   IdxTable.Free;
  End;
end;

procedure TRestructure.ShowIndexList;
 Var Ind : Word;
begin
 IndexList.Clear;

 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    IndexList.Items.Add(MyIndexList[Ind].IdxName);
end;

function TRestructure.Check_Value(Val: String): Boolean;
begin
 Result := True;

 If Trim(Val) = '' Then
  Begin
   Result := False;

   Exit;
  End;

 Try
   StrToInt(Val);
 Except
   Result := False;
 End;
end;

function TRestructure.CreateNewFieldDefs: TDbfFieldDefs;
 Var Ind : Word;
     App : TDbfFieldDefs;
     TmpF : TDbfFieldDef;
begin
 App := TDbfFieldDefs.Create(Self);

 For Ind := 1 To FieldList.RowCount - 1 Do
  Begin
   TmpF := App.AddFieldDef;
   TmpF.FieldName := FieldList.Cells[1,Ind];
   TmpF.FieldType := RetFieldType(FieldList.Cells[2,Ind]);

   If FieldList.Cells[4,Ind] = 'N' Then
    TmpF.CopyFrom := StrToInt(FieldList.Cells[0,Ind]) - 1;

   If TmpF.FieldType <> ftFloat Then
    Begin
     If FieldList.Cells[3,Ind] <> '' Then
      TmpF.Size := StrToInt(FieldList.Cells[3,Ind]);
    End
   Else
    TmpF.Precision := StrToInt(FieldList.Cells[3,Ind]);
  End;

 Result := App;
end;

procedure TRestructure.RecreateMyIndex;
 Var Ind : Word;
     Tmp : TIndexOptions;
begin
 If Length(MyIndexList) > 0 Then
  Begin
   //First delete the index

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If MyIndexList[Ind].Deleted Then
     Temp.DeleteIndex(MyIndexList[Ind].IdxName);

   //Next Create indexes...

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If Not MyIndexList[Ind].Deleted Then
     Begin
      Tmp := MyIndexList[Ind].Options;
      Temp.AddIndex(MyIndexList[Ind].IdxName, MyIndexList[Ind].Fields, Tmp);
     End;
  End;
end;

function TRestructure.RetFieldType(AValue: String): TFieldType;
begin
  Result := TFieldType(GetEnumValue(TypeInfo(TFieldType), 'ft' + AValue));
  if not (Result in SupportedFieldTypes) then
    Result := ftUnknown;
end;

procedure TRestructure.ShowInfo(ATable: TDbf);
begin
  lblCodepage.Caption := Format('Code page: %d', [ATable.CodePage]);
  if ATable.LanguageStr <> '' then
    lblLanguage.Caption := Format('Language: %s', [ATable.LanguageStr])
  else
    lblLanguage.Caption := '';
end;

function TRestructure.TestIndexName(Val: String): Boolean;
 Var Ind : Word;
begin
 Result := True;

 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    If MyIndexList[Ind].IdxName = Val Then
     Begin
      Result := False;

      Break;
     End;
end;

end.

