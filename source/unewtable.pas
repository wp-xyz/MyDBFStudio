unit uNewTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Buttons, DB, dbf, DBF_Fields;

type

  MyIndex         = Packed Record
   IdxName        : String;
   Fields         : String;
   Options        : TIndexOptions;
   Deleted        : Boolean;
  End;

  { TNewTable }

  TNewTable = class(TForm)
    CloseBtn: TBitBtn;
    CreateTableBtn: TBitBtn;
    DeleteIndexBtn: TBitBtn;
    DefineIndexBtn: TBitBtn;
    cbOpenTB: TCheckBox;
    DbTable: TDbf;
    FieldList: TStringGrid;
    GroupBox1: TGroupBox;
    IndexList: TListBox;
    lblIndexList: TLabel;
    lblTableType: TLabel;
    SaveTable: TSaveDialog;
    TableType: TComboBox;
    procedure CloseBtnClick(Sender: TObject);
    procedure CreateTableBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure IndexListDblClick(Sender: TObject);
    procedure TableTypeChange(Sender: TObject);
  private
    { private declarations }
    MyIndexList : Array Of MyIndex;

    Function ReturnTableLevel : Word;

    Procedure ShowIndexList;

    Function Check_Value(Val : String) : Boolean;

    Function RetFieldType(Val : String) : TFieldType;

    Function CreateNewFieldDefs : TDbfFieldDefs;

    Procedure CreateMyIndex;
  public
    { public declarations }
    Ret : Boolean;
    PageIdx : Integer;

    Function TestIndexName(Val : String) : Boolean;
  end;

var
  NewTable: TNewTable;

implementation

uses
  Math, uMain, uIdxTable, uOptions;

{$R *.lfm}

{ TNewTable }

procedure TNewTable.CloseBtnClick(Sender: TObject);
begin
 Main.WorkSiteCloseTabClicked(Main.WorkSite.Pages[Self.PageIdx]);
end;

procedure TNewTable.CreateTableBtnClick(Sender: TObject);
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
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftFloat]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftBlob]) Or
      (FieldList.Cells[2,Ind] = Fieldtypenames[ftMemo]) Or
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

 If SaveTable.Execute Then
  Begin
   Try
     DbTable.TableLevel := ReturnTableLevel();
     DbTable.TableName := SaveTable.FileName;

     DbTable.CreateTableEx(CreateNewFieldDefs());

     DbTable.Open;

     CreateMyIndex();

     DbTable.Close;

     Ret := True;

     CloseBtnClick(Sender);

     If cbOpenTB.Checked Then
      Main.Open_Table(SaveTable.FileName);
   Except
   end;
  end;
end;

procedure TNewTable.Button1Click(Sender: TObject);
 Var Ind : Word;
     lOpt : TIndexOptions;
     ExpField : String;
begin
 If FieldList.RowCount > 1 Then
  Begin
   IdxTable := TIdxTable.Create(Self);
   IdxTable.New := True;
   IdxTable.Calling := NewTable;
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

procedure TNewTable.Button2Click(Sender: TObject);
 Var dName : String;
     Ind : Word;
begin
 If IndexList.ItemIndex < 0 Then
  Exit;

 If MessageDlg('Delete the selected index?', mtWarning ,[mbOk, mbCancel],0) = mrOk Then
  Begin
   dName := IndexList.Items[IndexList.ItemIndex];

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If MyIndexList[Ind].IdxName = dName Then
     MyIndexList[Ind].Deleted := True;

   ShowIndexList();
  End;
end;

procedure TNewTable.FormCreate(Sender: TObject);
begin
 TableTypeChange(Sender);

 FieldList.RowCount := 2;

 FieldList.Cells[0,FieldList.RowCount - 1] := IntToStr(FieldList.RowCount - 1);
 FieldList.Col := 1;
 FieldList.Row := FieldList.RowCount - 1;

 Ret := False;
end;

procedure TNewTable.FormDestroy(Sender: TObject);
begin
 SetLength(MyIndexList, 0);
end;

procedure TNewTable.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 If Key = 40 Then     //Down Arrow
  Begin
   If FieldList.Row = FieldList.RowCount - 1 Then
    If (FieldList.Cells[1,FieldList.RowCount - 1] <> '') And
       (FieldList.Cells[2,FieldList.RowCount - 1] <> '') Then
     Begin
      FieldList.RowCount:=FieldList.RowCount + 1;

      FieldList.Cells[0,FieldList.RowCount - 1]:=IntToStr(FieldList.RowCount - 1);
      FieldList.Col:=1;
      FieldList.Row:=FieldList.RowCount - 1;
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
     If MessageDlg('Delete the field?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
      Begin
       FieldList.DeleteColRow(False,FieldList.Row);

       If FieldList.Row = 0 Then
        Begin
         FieldList.RowCount:=FieldList.RowCount + 1;

         FieldList.Cells[0,FieldList.RowCount - 1]:=IntToStr(FieldList.RowCount - 1);
         FieldList.Col:=1;
         FieldList.Row:=FieldList.RowCount - 1;
        End;
      End;
end;

procedure TNewTable.FormShow(Sender: TObject);
begin
  DefineIndexBtn.Constraints.MinWidth := Max(DefineIndexBtn.Width, DeleteIndexBtn.Width);
  DeleteIndexBtn.Constraints.MinWidth := DefineIndexBtn.Constraints.MinWidth;

  CreateTableBtn.Constraints.MinWidth := Max(CreateTableBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := CreateTableBtn.Constraints.MinWidth;
end;

procedure TNewTable.IndexListDblClick(Sender: TObject);
 Var OldIdxName : String;
     Ind : Word;
     lOpt : TIndexOptions;
begin
 If IndexList.Items.Count > 0 Then
  Begin
   OldIdxName := IndexList.Items[IndexList.ItemIndex];

   IdxTable := TIdxTable.Create(Self);
   IdxTable.New := False;
   IdxTable.Calling := NewTable;
   lOpt := [];

   For Ind := 1 To FieldList.RowCount - 1 Do
    IdxTable.IdxList.Items.Add(FieldList.Cells[1,Ind]);

   For Ind := 0 To Length(MyIndexList) - 1 Do
    If Not MyIndexList[Ind].Deleted Then
     If MyIndexList[Ind].IdxName = OldIdxName Then
      Begin
       lOpt := MyIndexList[Ind].Options;

       Break;
      End;

   IdxTable.IdxName.Text := OldIdxName;

   IdxTable.SelField.Text := MyIndexList[Ind].Fields;

   If ixPrimary In lOpt Then
    IdxTable.cbOpt.Checked[0] := True;

   If ixUnique In lOpt Then
    IdxTable.cbOpt.Checked[1] := True;

   If ixDescending In lOpt Then
    IdxTable.cbOpt.Checked[2] := True;

   If ixCaseInsensitive In lOpt Then
    IdxTable.cbOpt.Checked[3] := True;

   IdxTable.ShowModal;

   If IdxTable.Ret Then
    Begin
     For Ind := 0 To Length(MyIndexList) - 1 Do
      If Not MyIndexList[Ind].Deleted Then
       If MyIndexList[Ind].IdxName = OldIdxName Then
        MyIndexList[Ind].Deleted := True;         //Delete old index...

     lOpt := [];

     If IdxTable.cbOpt.Checked[0] Then
      lOpt := lOpt + [ixPrimary];

     If IdxTable.cbOpt.Checked[1] Then
      lOpt := lOpt + [ixUnique];

     If IdxTable.cbOpt.Checked[2] Then
      lOpt := lOpt + [ixDescending];

     If IdxTable.cbOpt.Checked[3] Then
      lOpt := lOpt + [ixCaseInsensitive];

     SetLength(MyIndexList, Length(MyIndexList) + 1);     //Insert New Index

     MyIndexList[Length(MyIndexList) - 1].Options := lOpt;
     MyIndexList[Length(MyIndexList) - 1].IdxName := IdxTable.IdxName.Text;
     MyIndexList[Length(MyIndexList) - 1].Fields := IdxTable.SelField.Text;
     MyIndexList[Length(MyIndexList) - 1].Deleted := False;

     ShowIndexList;
    End;

   IdxTable.Free;
  End;
end;

procedure TNewTable.TableTypeChange(Sender: TObject);
 Var Tl : Word;
begin
 FieldList.Columns[2].PickList.Clear;

 Tl := ReturnTableLevel;

 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftString]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftSmallInt]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftInteger]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftWord]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftBoolean]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftFloat]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftDate]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftDateTime]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftBlob]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftMemo]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftDBaseOle]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftFixedChar]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftWideString]);
 FieldList.Columns[2].PickList.Add(Fieldtypenames[ftLargeInt]);

 If Tl = 7 Then
  FieldList.Columns[2].PickList.Add(Fieldtypenames[ftAutoInc]);
end;

function TNewTable.ReturnTableLevel: Word;
begin
 Result := 3;

 Case TableType.ItemIndex Of
      0                   : Result := 3;
      1                   : Result := 4;
      2                   : Result := 7;
      3                   : Result := 25;
 End;
end;

procedure TNewTable.ShowIndexList;
 Var Ind : Word;
begin
 IndexList.Clear;

 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    IndexList.Items.Add(MyIndexList[Ind].IdxName);
end;

function TNewTable.Check_Value(Val: String): Boolean;
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

function TNewTable.RetFieldType(Val: String): TFieldType;
begin
 Result := ftUnknown;
 If Val = Fieldtypenames[ftString] Then
  Result:=ftString
 Else
  If Val = Fieldtypenames[ftSmallInt] Then
   Result:=ftSmallInt
  Else
   If Val = Fieldtypenames[ftInteger] Then
    Result:=ftInteger
   Else
    If Val = Fieldtypenames[ftWord] Then
     Result:=ftWord
    Else
     If Val = Fieldtypenames[ftBoolean] Then
      Result:=ftBoolean
     Else
      If Val = Fieldtypenames[ftFloat] Then
       Result:=ftFloat
      Else
       If Val = Fieldtypenames[ftDate] Then
        Result:=ftDate
       Else
        If Val = Fieldtypenames[ftDateTime] Then
         Result:=ftDateTime
        Else
         If Val = Fieldtypenames[ftBlob] Then
          Result:=ftBlob
         Else
          If Val = Fieldtypenames[ftDBaseOle] Then
           Result:=ftDbaseOle
          Else
           If Val = Fieldtypenames[ftFixedChar] Then
            Result:=ftFixedChar
           Else
            If Val = Fieldtypenames[ftWideString] Then
             Result:=ftWideString
            Else
             If Val = Fieldtypenames[ftLargeInt] Then
              Result:=ftLargeInt
             Else
              If Val = Fieldtypenames[ftCurrency] Then
               Result:=ftCurrency
              Else
               If Val = Fieldtypenames[ftBCD] Then
                Result:=ftBCD
               Else
                If Val = Fieldtypenames[ftBytes] Then
                 Result:=ftBytes
                Else
                 If Val = Fieldtypenames[ftAutoInc] Then
                  Result:=ftAutoInc;
end;

function TNewTable.CreateNewFieldDefs: TDbfFieldDefs;
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
   TmpF.Required := True;

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

procedure TNewTable.CreateMyIndex;
 Var Ind : Word;
     Tmp : TIndexOptions;
begin
 If Length(MyIndexList) > 0 Then
  For Ind := 0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    Begin
     Tmp := MyIndexList[Ind].Options;

     DbTable.AddIndex(MyIndexList[Ind].IdxName, MyIndexList[Ind].Fields, Tmp);
    end;
end;

function TNewTable.TestIndexName(Val: String): Boolean;
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

