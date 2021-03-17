unit T_NewTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, Grids, StdCtrls, Buttons, db, dbf_fields;

type
  MyIndex         = Record
   IdxName        : String;
   Fields         : String;
   Options        : TIndexOptions;
   Deleted        : Boolean;
  End;

  { TNewTable }

  TNewTable = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    cbFieldType: TComboBox;
    DbTable: TDbf;
    Label2: TLabel;
    SaveTable: TSaveDialog;
    TableType: TComboBox;
    FieldList: TStringGrid;
    IndexList: TListBox;
    Label1: TLabel;
    procedure BitBtn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure cbFieldTypeCloseUp(Sender: TObject);
    procedure FieldListKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FieldListSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure IndexListDblClick(Sender: TObject);
    procedure TableTypeChange(Sender: TObject);
  private
    { private declarations }
    MyIndexList : Array Of MyIndex;

    Function Check_Value(Val : String) : Boolean;

    Function ReturnTableLevel() : Word;

    Procedure ShowIndexList();

    Function RetFieldType(Val : String) : TFieldType;

    Function CreateNewFieldDefs() : TDbfFieldDefs;

    Procedure CreateMyIndex();
  public
    { public declarations }
    Ret : Boolean;

    Function TestIndexName(Val : String) : Boolean;
  end; 

var
  NewTable: TNewTable;

implementation

Uses T_IdxTable;

{ TNewTable }

procedure TNewTable.TableTypeChange(Sender: TObject);
 Var Tl : Word;
begin
 cbFieldType.Clear;

 Tl:=ReturnTableLevel();

 cbFieldType.Items.Add(Fieldtypenames[ftString]);
 cbFieldType.Items.Add(Fieldtypenames[ftSmallInt]);
 cbFieldType.Items.Add(Fieldtypenames[ftInteger]);
 cbFieldType.Items.Add(Fieldtypenames[ftWord]);
 cbFieldType.Items.Add(Fieldtypenames[ftBoolean]);
 cbFieldType.Items.Add(Fieldtypenames[ftFloat]);
 cbFieldType.Items.Add(Fieldtypenames[ftDate]);
 cbFieldType.Items.Add(Fieldtypenames[ftDateTime]);
 cbFieldType.Items.Add(Fieldtypenames[ftBlob]);
 cbFieldType.Items.Add(Fieldtypenames[ftMemo]);
 cbFieldType.Items.Add(Fieldtypenames[ftDBaseOle]);
 cbFieldType.Items.Add(Fieldtypenames[ftFixedChar]);
 cbFieldType.Items.Add(Fieldtypenames[ftWideString]);
 cbFieldType.Items.Add(Fieldtypenames[ftLargeInt]);

 If Tl = 25 Then
  Begin
   //Not Supported... :-(

   {cbFieldType.Items.Add(Fieldtypenames[ftCurrency]);
   cbFieldType.Items.Add(Fieldtypenames[ftBCD]);
   cbFieldType.Items.Add(Fieldtypenames[ftBytes]);
   cbFieldType.Items.Add(Fieldtypenames[ftAutoInc]);}
  End
 Else
  If Tl = 7 Then
   cbFieldType.Items.Add(Fieldtypenames[ftAutoInc]);
end;

function TNewTable.Check_Value(Val: String): Boolean;
begin
 Result:=True;

 If Trim(Val) = '' Then
  Begin
   Result:=False;

   Exit;
  End;

 Try
   StrToInt(Val);
 Except
   Result:=False;
 End;
end;

procedure TNewTable.FormCreate(Sender: TObject);
begin
 TableTypeChange(Sender);

 FieldList.RowCount:=2;

 FieldList.Cells[0,FieldList.RowCount - 1]:=IntToStr(FieldList.RowCount - 1);
 FieldList.Col:=1;
 FieldList.Row:=FieldList.RowCount - 1;

 Ret:=False;
end;

procedure TNewTable.IndexListDblClick(Sender: TObject);
 Var OldIdxName : String;
     Ind : Word;
     lOpt : TIndexOptions;
     ExpField : String;
begin
 If IndexList.Items.Count > 0 Then
  Begin
   OldIdxName:=IndexList.Items[IndexList.ItemIndex];

   IdxTable:=TIdxTable.Create(Self);
   IdxTable.New:=False;
   IdxTable.Calling:=NewTable;
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

   IdxTable.Release;
  End;
end;

procedure TNewTable.FieldListSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
 Var R : TRect;
begin
 If aCol = 2 Then
  Begin
   R:=TStringGrid(Sender).CellRect(aCol,aRow);

   R.Left:=R.Left + FieldList.Left;
   R.Right:=R.Right + FieldList.Left;
   R.Top:=R.Top + FieldList.Top;
   R.Bottom:=R.Bottom + FieldList.Top;

   cbFieldType.ItemIndex:=cbFieldType.Items.IndexOf(FieldList.Cells[aCol,aRow]);
   cbFieldType.Width:=R.Right - R.Left;
   cbFieldType.Left:=R.Left + 1;
   cbFieldType.Top:=R.Top + 1;

   cbFieldType.Visible:=True;
  End
 Else
  cbFieldType.Visible:=False;
end;

procedure TNewTable.cbFieldTypeCloseUp(Sender: TObject);
begin
 If cbFieldType.ItemIndex <> -1 Then
  Begin
   FieldList.Cells[FieldList.Col,FieldList.Row]:=cbFieldType.Text;

   //FieldList.SetFocus;

   FieldList.Col:=3;
  End;
end;

procedure TNewTable.Button2Click(Sender: TObject);
 Var dName : String;
     Ind : Word;
begin
 If IndexList.ItemIndex < 0 Then
  Exit;

 If MessageDlg('Delete the selected index?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
  Begin
   dName:=IndexList.Items[IndexList.ItemIndex];

   For Ind:=0 To Length(MyIndexList) - 1 Do
    If MyIndexList[Ind].IdxName = dName Then
     MyIndexList[Ind].Deleted:=True;

   ShowIndexList();
  End;
end;

procedure TNewTable.Button1Click(Sender: TObject);
 Var Ind : Word;
     lOpt : TIndexOptions;
     ExpField : String;
begin
 If FieldList.RowCount > 1 Then
  Begin
   IdxTable:=TIdxTable.Create(Self);
   IdxTable.New:=True;
   IdxTable.Calling:=NewTable;
   lOpt:=[];

   For Ind:=1 To FieldList.RowCount - 1 Do
    IdxTable.IdxList.Items.Add(FieldList.Cells[1,Ind]);

   IdxTable.ShowModal;

   If IdxTable.Ret Then
    Begin
     ExpField:=IdxTable.SelField.Text;

     If IdxTable.cbOpt.Checked[0] Then
      lOpt:=lOpt + [ixPrimary];

     If IdxTable.cbOpt.Checked[1] Then
      lOpt:=lOpt + [ixUnique];

     If IdxTable.cbOpt.Checked[2] Then
      lOpt:=lOpt + [ixDescending];

     If IdxTable.cbOpt.Checked[3] Then
      lOpt:=lOpt + [ixCaseInsensitive];

     SetLength(MyIndexList,Length(MyIndexList) + 1);

     MyIndexList[Length(MyIndexList) - 1].Options:=lOpt;
     MyIndexList[Length(MyIndexList) - 1].IdxName:=IdxTable.IdxName.Text;
     MyIndexList[Length(MyIndexList) - 1].Fields:=ExpField;
     MyIndexList[Length(MyIndexList) - 1].Deleted:=False;

     ShowIndexList();
    End;

   IdxTable.Release;
  End;
end;

procedure TNewTable.BitBtn2Click(Sender: TObject);
 Var Ind : Word;
begin
 For Ind:=1 To FieldList.RowCount - 1 Do
  Begin
   If Trim(FieldList.Cells[1,Ind]) = '' Then
    Begin
     ShowMessage('Row: ' + IntToStr(Ind) + '. Missing field name!');

     FieldList.Row:=Ind;
     FieldList.Col:=1;

     Exit;
    End;

   If FieldList.Cells[2,Ind] = '' Then
    Begin
     ShowMessage('Row: ' + IntToStr(Ind) + '. Missing field type!');

     FieldList.Row:=Ind;
     FieldList.Col:=2;

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

      FieldList.Row:=Ind;
      FieldList.Col:=3;

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
     DbTable.TableLevel:=ReturnTableLevel();
     DbTable.TableName:=SaveTable.FileName;

     DbTable.CreateTableEx(CreateNewFieldDefs());

     DbTable.Open;

     CreateMyIndex();

     DbTable.Close;

     Ret:=True;

     Close;
   Except
   End;
  End;
end;

procedure TNewTable.FieldListKeyDown(Sender: TObject; var Key: Word;
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

function TNewTable.ReturnTableLevel(): Word;
begin
 Case TableType.ItemIndex Of
      0                   : Result:=3;
      1                   : Result:=4;
      2                   : Result:=7;
      3                   : Result:=25;
 End;
end;

procedure TNewTable.ShowIndexList();
 Var Ind : Word;
begin
 IndexList.Clear;

 If Length(MyIndexList) > 0 Then
  For Ind:=0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    IndexList.Items.Add(MyIndexList[Ind].IdxName);
end;

function TNewTable.RetFieldType(Val: String): TFieldType;
begin
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

function TNewTable.CreateNewFieldDefs(): TDbfFieldDefs;
 Var Ind : Word;
     App : TDbfFieldDefs;
     TmpF : TDbfFieldDef;
     lType : TFieldType;
begin
 App:=TDbfFieldDefs.Create(Self);

 For Ind:=1 To FieldList.RowCount - 1 Do
  Begin
   TmpF:=App.AddFieldDef;
   TmpF.FieldName:=FieldList.Cells[1,Ind];
   TmpF.FieldType:=RetFieldType(FieldList.Cells[2,Ind]);
   TmpF.Required:=True;

   If TmpF.FieldType <> ftFloat Then
    Begin
     If FieldList.Cells[3,Ind] <> '' Then
      TmpF.Size:=StrToInt(FieldList.Cells[3,Ind]);
    End
   Else
    TmpF.Precision:=StrToInt(FieldList.Cells[3,Ind]);
  End;

 Result:=App;
end;

procedure TNewTable.CreateMyIndex();
 Var Ind : Word;
     Tmp : TIndexOptions;
begin
 If Length(MyIndexList) > 0 Then
  Begin
   //Next Create indexes...

   For Ind:=0 To Length(MyIndexList) - 1 Do
    If Not MyIndexList[Ind].Deleted Then
     Begin
      Tmp:=MyIndexList[Ind].Options;

      DbTable.AddIndex(MyIndexList[Ind].IdxName,MyIndexList[Ind].Fields,Tmp);
     End;
  End;
end;

function TNewTable.TestIndexName(Val: String): Boolean;
 Var Ind : Word;
begin
 Result:=True;

 If Length(MyIndexList) > 0 Then
  For Ind:=0 To Length(MyIndexList) - 1 Do
   If Not MyIndexList[Ind].Deleted Then
    If MyIndexList[Ind].IdxName = Val Then
     Begin
      Result:=False;

      Break;
     End;
end;

initialization
  {$I t_newtable.lrs}

end.

