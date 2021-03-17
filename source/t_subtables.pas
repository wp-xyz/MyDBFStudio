unit T_SubTables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Buttons, db;

type

  { TSubTables }

  TSubTables = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    cbFT: TComboBox;
    cbST: TComboBox;
    T1: TDbf;
    T2: TDbf;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    pBar: TProgressBar;
    rgTPri: TRadioGroup;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Function Check_Table_Structure() : Boolean;

    Function Return_Field_Value(D : TDbf; I : Integer) : String;

    Procedure SubTable(D1,D2 : TDbf);
  public
    { public declarations }
  end; 

var
  SubTables: TSubTables;

implementation

Uses T_MainForm, T_DbfTable;

{ TSubTables }

procedure TSubTables.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 If MainForm.MultiWnd.ChildCount > 0 Then
  Begin
   For Ind:=0 To MainForm.MultiWnd.ChildCount - 1 Do
    If Assigned(MainForm.MultiWnd.Childs[Ind]) Then
     Begin
      With MainForm.MultiWnd.Childs[Ind].DockedObject As TDbfTable Do
       Begin
        cbFT.Items.Add(DbTable.FilePathFull + DBTable.TableName);

        cbST.Items.Add(DbTable.FilePathFull + DBTable.TableName);
       End;
     End;
  End;

 cbFT.ItemIndex:=0;
 cbST.ItemIndex:=0;
end;

function TSubTables.Check_Table_Structure(): Boolean;
 Var Ind : Word;
begin
 Result:=True;

 For Ind:=0 To T1.Fields.Count - 1 Do
  If (T1.Fields[Ind].DataType <> T2.Fields[Ind].DataType) Or
     (T1.FieldDefs.Items[Ind].Name <> T2.FieldDefs.Items[Ind].Name) Then
   Begin
    ShowMessage('The structur of the tables is different.');

    Result:=False;

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
  ftWideString                : Result:='"' + D.Fields[I].AsString + '"';
  ftBoolean                   : If D.Fields[I].AsBoolean Then
                                 Result:='"True"'
                                Else
                                 Result:='"False"';
  Else                          Result:=D.Fields[I].AsString;
 End;
end;

procedure TSubTables.SubTable(D1, D2: TDbf);
 Var Ind : Integer;
     Filtro : String;
begin
 D1.First;
 D2.First;
 D2.Filtered:=True;

 pBar.Min:=0;
 pBar.Max:=D1.ExactRecordCount;
 pBar.Position:=0;

 Try
   While Not D1.EOF Do
    Begin
     Filtro:='';

     For Ind:=0 To D1.Fields.Count - 1 Do
      If Filtro = '' Then
       Filtro:=Filtro + D1.FieldDefs.Items[Ind].Name + '=' + Return_Field_Value(D1,Ind)
      Else
       Filtro:=Filtro + ' AND ' + D1.FieldDefs.Items[Ind].Name + '=' + Return_Field_Value(D1,Ind);

     D2.Filter:=Filtro;

     If Not D2.IsEmpty Then
      D2.Delete;

     D1.Next;

     pBar.Position:=pBar.Position + 1;
    End;

   D2.Filter:='';

   Close;
 Except
   ShowMessage('Error while deleting field.');
 End;

 pBar.Position:=0;
end;

procedure TSubTables.BitBtn2Click(Sender: TObject);
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

 With MainForm.MultiWnd.Childs[cbFT.ItemIndex].DockedObject As TDbfTable Do
  T1:=DbTable;

 With MainForm.MultiWnd.Childs[cbST.ItemIndex].DockedObject As TDbfTable Do
  T2:=DbTable;

 If T1.Fields.Count <> T2.Fields.Count Then
  Begin
   ShowMessage('The structur of the tables is different.');

   Exit;
  End;

 If Check_Table_Structure() Then
  If rgTPri.ItemIndex = 0 Then
   SubTable(T1,T2)
  Else
   SubTable(T2,T1);
end;

initialization
  {$I t_subtables.lrs}

end.

