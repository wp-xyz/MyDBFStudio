unit uAddTables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Buttons;

type

  { TAddTables }

  TAddTables = class(TForm)
    CloseBtn: TBitBtn;
    StartBtn: TBitBtn;
    cbFT: TComboBox;
    cbST: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    lblProgress: TLabel;
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

    Procedure AddTable(D1,D2 : TDbf);
  public
    { public declarations }
  end;

var
  AddTables: TAddTables;

implementation

uses
  Math,
  uMain, uTabForm, uDbfTable, uOptions;

{$R *.lfm}

{ TAddTables }

procedure TAddTables.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TAddTables.StartBtnClick(Sender: TObject);
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

 fT1 := (Main.WorkSite.Pages[IdxT1] As TTabForm).ParentForm;
 fT2 := (Main.WorkSite.Pages[IdxT2] As TTabForm).ParentForm;

 With (fT1 As TDbfTable) Do
  T1 := DbTable;

 With (fT2 As TDbfTable) Do
  T2 := DbTable;

 If T1.Fields.Count <> T2.Fields.Count Then
  Begin
   ShowMessage('The structur of the tables is different.');

   Exit;
  End;

 If T1.Fields.Count <> T2.Fields.Count Then
  Begin
   ShowMessage('The structur of the tables is different.');

   Exit;
  End;

 If Check_Table_Structure Then
  Begin
   (fT1 As TDbfTable).DBGrid.BeginUpdate;
   (fT2 As TDbfTable).DBGrid.BeginUpdate;

   If rgTPri.ItemIndex = 0 Then
    AddTable(T1, T2)
   Else
    AddTable(T2, T1);

   (fT1 As TDbfTable).DBGrid.EndUpdate(False);
   (fT2 As TDbfTable).DBGrid.EndUpdate(False);
  end;
end;

procedure TAddTables.FormCreate(Sender: TObject);
begin
 ListT1PageIdx := TStringList.Create;
 ListT2PageIdx := TStringList.Create;
end;

procedure TAddTables.FormDestroy(Sender: TObject);
begin
 ListT1PageIdx.Free;
 ListT2PageIdx.Free;
end;

procedure TAddTables.FormShow(Sender: TObject);
 Var Ind : Word;
     Tmp : TForm;
begin
 StartBtn.Constraints.MinWidth := Max(StartBtn.Width, CloseBtn.Width);
 CloseBtn.Constraints.MinWidth := StartBtn.Constraints.MinWidth;

 Constraints.MinWidth := Width;
 Constraints.MinHeight := Height;
 Constraints.MaxHeight := Height;

 if Options.RememberWindowSizePos and (Options.AddTablesWidth > 0) then
 begin
   AutoSize := false;
   Width := Min(Options.AddTablesWidth, Screen.WorkAreaWidth);
 end;

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
end;

function TAddTables.Check_Table_Structure: Boolean;
 Var Ind : Word;
begin
 Result := True;

 For Ind := 0 To T1.Fields.Count - 1 Do
  If T1.Fields[Ind].DataType <> T2.Fields[Ind].DataType Then
   Begin
    ShowMessage('The structur of the tables is different.');

    Result := False;

    Break;
   End;
end;

procedure TAddTables.AddTable(D1, D2: TDbf);
 Var Ind : Integer;
begin
 D1.First;
 D2.First;

 pBar.Min := 0;
 pBar.Max := D1.ExactRecordCount;
 pBar.Position := 0;

 Try
   While Not D1.EOF Do
    Begin
     D2.Insert;

     For Ind := 0 To D1.Fields.Count - 1 Do
      D2.Fields[Ind].AsVariant := D1.Fields[Ind].AsVariant;

     D2.Post;

     pBar.Position := pBar.Position + 1;

     D1.Next;
    End;

   ShowMessage('Process completed!');
 Except
  ShowMessage('Error while insert field.');
 End;

 pBar.Position := 0;
end;

end.

