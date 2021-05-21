unit uSubTables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Buttons, DB;

type

  { TSubTables }

  TSubTables = class(TForm)
    CloseBtn: TBitBtn;
    StartBtn: TBitBtn;
    cbFT: TComboBox;
    cbST: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    pBar: TProgressBar;
    rgTPri: TRadioGroup;
    T1: TDbf;
    T2: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ListT1PageIdx,
    ListT2PageIdx : TStringList;

    Function Check_Table_Structure : Boolean;

    Function Return_Field_Value(D : TDbf; I : Integer) : String;

    Procedure SubTable(D1,D2 : TDbf);
  public
    { public declarations }
  end;

var
  SubTables: TSubTables;

implementation

uses
  Math,
  T_MainForm, T_DbfTable;

//Uses uMain, U_TabForm, uDbfTable;

{$R *.lfm}

{ TSubTables }

procedure TSubTables.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TSubTables.StartBtnClick(Sender: TObject);
 Var fT1, fT2 : TForm;
     IdxT1, IdxT2 : Integer;
begin
 If cbFT.Text = '' Then
  Begin
   ShowMessage('You MUST select a first table...');

   cbFT.SetFocus;

   Exit;
  End;

 If cbST.Text = '' Then
  Begin
   ShowMessage('You MUST select a second table...');

   cbST.SetFocus;

   Exit;
  End;

 If cbFT.Text = cbST.Text Then
  Begin
   ShowMessage('The tables must be different.');

   Exit;
  End;

 IdxT1 := StrToInt(ListT1PageIdx.Strings[cbFT.ItemIndex]);
 IdxT2 := StrToInt(ListT1PageIdx.Strings[cbST.ItemIndex]);

 { todo }
 With Main.MultiWnd.Childs[cbFT.ItemIndex].DockedObject As TDbfTable Do
  T1:=DbTable;

 With Main.MultiWnd.Childs[cbST.ItemIndex].DockedObject As TDbfTable Do
  T2:=DbTable;

 {todo }
 {
 fT1 := (Main.WorkSite.Pages[IdxT1] As TTabForm).ParentForm;
 fT2 := (Main.WorkSite.Pages[IdxT2] As TTabForm).ParentForm;

 With (fT1 As TDbfTable) Do
  T1 := DbTable;

 With (fT2 As TDbfTable) Do
  T2 := DbTable;
}

 If T1.Fields.Count <> T2.Fields.Count Then
  Begin
   ShowMessage('The structur of the tables is different.');

   Exit;
  End;

 If Check_Table_Structure Then
  Begin
   (fT1 As TDbfTable).DBGrid1.BeginUpdate;
   (fT2 As TDbfTable).DBGrid1.BeginUpdate;

   If rgTPri.ItemIndex = 0 Then
    SubTable(T1, T2)
   Else
    SubTable(T2, T1);

   (fT1 As TDbfTable).DBGrid1.EndUpdate(False);
   (fT2 As TDbfTable).DBGrid1.EndUpdate(False);
  end;
end;

procedure TSubTables.FormCreate(Sender: TObject);
begin
 ListT1PageIdx := TStringList.Create;
 ListT2PageIdx := TStringList.Create;
end;

procedure TSubTables.FormDestroy(Sender: TObject);
begin
 ListT1PageIdx.Free;
 ListT2PageIdx.Free;
end;

procedure TSubTables.FormShow(Sender: TObject);
 Var Ind : Word;
     Tmp : TForm;
begin
 StartBtn.Constraints.MinWidth := Max(StartBtn.Width, CloseBtn.Width);
 CloseBtn.Constraints.MinWidth := StartBtn.Constraints.MinWidth;

 Constraints.MinHeight := Height;
 Constraints.MaxHeight := Height;

 { todo }
 If Main.MultiWnd.ChildCount > 0 Then
  Begin
   For Ind:=0 To Main.MultiWnd.ChildCount - 1 Do
    If Assigned(Main.MultiWnd.Childs[Ind]) Then
     Begin
      With Main.MultiWnd.Childs[Ind].DockedObject As TDbfTable Do
       Begin
        cbFT.Items.Add(DbTable.FilePathFull + DBTable.TableName);

        cbST.Items.Add(DbTable.FilePathFull + DBTable.TableName);
       End;
     End;
  End;
  {
 If Main.WorkSite.PageCount > 0 Then
  For Ind := 0 To Main.WorkSite.PageCount - 1 Do
   If (Main.WorkSite.Pages[Ind] Is TTabForm) Then
    If (Main.WorkSite.Pages[Ind] As TTabForm).ParentForm Is TDbfTable Then
     Begin
      Tmp := (Main.WorkSite.Pages[Ind] As TTabForm).ParentForm;

      With (Tmp As TDbfTable) Do
       Begin
        cbFT.Items.Add(DbTable.FilePathFull + DBTable.TableName);

        ListT1PageIdx.Add(IntToStr(PageIdx));

        cbST.Items.Add(DbTable.FilePathFull + DBTable.TableName);

        ListT2PageIdx.Add(IntToStr(PageIdx));
       end;

     end;

 If cbFT.Items.Count > 0 Then
  Begin
   cbFT.ItemIndex := 0;
   cbST.ItemIndex := 0;
  end;
 }

 // todo
 If Main.MultiWnd.ChildCount > 0 Then
  Begin
   For Ind:=0 To Main.MultiWnd.ChildCount - 1 Do
    If Assigned(Main.MultiWnd.Childs[Ind]) Then
     Begin
      With Main.MultiWnd.Childs[Ind].DockedObject As TDbfTable Do
       Begin
        cbFT.Items.Add(DbTable.FilePathFull + DBTable.TableName);

        cbST.Items.Add(DbTable.FilePathFull + DBTable.TableName);
       End;
     End;
  End;

 cbFT.ItemIndex:=0;
 cbST.ItemIndex:=0;
end;

function TSubTables.Check_Table_Structure: Boolean;
 Var Ind : Word;
begin
 Result := True;

 For Ind := 0 To T1.Fields.Count - 1 Do
  If (T1.Fields[Ind].DataType <> T2.Fields[Ind].DataType) Or
     (T1.FieldDefs.Items[Ind].Name <> T2.FieldDefs.Items[Ind].Name) Then
   Begin
    ShowMessage('The structur of the tables is different.');

    Result := False;

    Break;
   End;
end;

function TSubTables.Return_Field_Value(D: TDbf; I: Integer): String;
begin
 Case D.FieldDefs[I].DataType Of
  ftString,
  ftFixedChar,
  ftDate,
  ftTime,
  ftDateTime,
  ftWideString                : Result := '"' + D.Fields[I].AsString + '"';
  ftBoolean                   : If D.Fields[I].AsBoolean Then
                                 Result := '"True"'
                                Else
                                 Result := '"False"';

  Else                          Result := D.Fields[I].AsString;
 End;
end;

procedure TSubTables.SubTable(D1, D2: TDbf);
 Var Ind : Integer;
     Filtro : String;
begin
 D1.First;
 D2.First;
 D2.Filtered := True;

 pBar.Min := 0;
 pBar.Max := D1.ExactRecordCount;
 pBar.Position := 0;

 Try
   While Not D1.EOF Do
    Begin
     Filtro := '';

     For Ind := 0 To D1.Fields.Count - 1 Do
      If Filtro = '' Then
       Filtro := Filtro + D1.FieldDefs.Items[Ind].Name + '=' + Return_Field_Value(D1,Ind)
      Else
       Filtro := Filtro + ' AND ' + D1.FieldDefs.Items[Ind].Name + '=' + Return_Field_Value(D1,Ind);

     D2.Filter := Filtro;

     If Not D2.IsEmpty Then
      D2.Delete;

     D1.Next;

     pBar.Position := pBar.Position + 1;
    End;

   D2.Filter := '';

   ShowMessage('Process completed!');
 Except
   ShowMessage('Error while deleting field.');
 End;

 pBar.Position:=0;
end;

end.

