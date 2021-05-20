unit T_AddTables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, Buttons, ComCtrls;

type

  { TAddTables }

  TAddTables = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    cbFT: TComboBox;
    cbST: TComboBox;
    Label1: TLabel;
    pBar: TProgressBar;
    T1: TDbf;
    T2: TDbf;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    rgTPri: TRadioGroup;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Function Check_Table_Structure() : Boolean;

    Procedure AddTable(D1,D2 : TDbf);
  public
    { public declarations }
  end; 

var
  AddTables: TAddTables;

implementation

{$R *.lfm}

uses
  T_MainForm, T_DbfTable;

{ TAddTables }

procedure TAddTables.FormShow(Sender: TObject);
 Var Ind : Word;
begin
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

function TAddTables.Check_Table_Structure(): Boolean;
 Var Ind : Word;
begin
 Result:=True;

 For Ind:=0 To T1.Fields.Count - 1 Do
  If T1.Fields[Ind].DataType <> T2.Fields[Ind].DataType Then
   Begin
    ShowMessage('The structur of the tables is different.');

    Result:=False;

    Break;
   End;
end;

procedure TAddTables.AddTable(D1, D2: TDbf);
 Var Ind : Integer;
begin
 D1.First;
 D2.First;

 pBar.Min:=0;
 pBar.Max:=D1.ExactRecordCount;
 pBar.Position:=0;

 Try
   While Not D1.EOF Do
    Begin
     D2.Insert;

     For Ind:=0 To D1.Fields.Count - 1 Do
      D2.Fields[Ind].AsVariant:=D1.Fields[Ind].AsVariant;

     D2.Post;

     pBar.Position:=pBar.Position + 1;

     D1.Next;
    End;

   Close;
 Except
  ShowMessage('Error while insert field.');
 End;

 pBar.Position:=0;
end;

procedure TAddTables.BitBtn2Click(Sender: TObject);
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

 With Main.MultiWnd.Childs[cbFT.ItemIndex].DockedObject As TDbfTable Do
  T1:=DbTable;

 With Main.MultiWnd.Childs[cbST.ItemIndex].DockedObject As TDbfTable Do
  T2:=DbTable;

 If T1.Fields.Count <> T2.Fields.Count Then
  Begin
   ShowMessage('The structur of the tables is different.');

   Exit;
  End;

 If Check_Table_Structure() Then
  If rgTPri.ItemIndex = 0 Then
   AddTable(T1,T2)
  Else
   AddTable(T2,T1);
end;


end.

