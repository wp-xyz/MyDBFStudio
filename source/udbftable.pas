unit uDbfTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  ComCtrls, DbCtrls, StdCtrls, ExtCtrls, DBGrids, Buttons;

type

  { TDbfTable }

  TDbfTable = class(TForm)
    cbShowDel: TCheckBox;
    Indexes: TComboBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBTable: TDbf;
    Ds: TDataSource;
    Label1: TLabel;
    Label2: TLabel;
    leFilter: TEdit;
    Panel1: TPanel;
    sbInfo: TStatusBar;
    ToolBar1: TToolBar;
    Pack: TToolButton;
    Empty: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ViewDel: TToolButton;
    Restruct: TToolButton;
    SetField: TToolButton;
    procedure cbShowDelChange(Sender: TObject);
    procedure EmptyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IndexesChange(Sender: TObject);
    procedure leFilterKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure PackClick(Sender: TObject);
    procedure RestructClick(Sender: TObject);
    procedure SetFieldClick(Sender: TObject);
    Procedure ShowTableInfo(DataSet: TDataSet);
    procedure SpeedButton1Click(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ViewDelClick(Sender: TObject);
  private
    { private declarations }
    Procedure Fix_DBNavigatorIcons;
    Procedure Load_Table_Indexes;
  public
    { public declarations }
    PageIdx : Integer;

    Procedure Set_Up;
  end;

var
  DbfTable: TDbfTable;

implementation

Uses 
  uDataModule, uRestructure, uSetFV, uMain;

{$R *.lfm}

{ TDbfTable }

procedure TDbfTable.IndexesChange(Sender: TObject);
begin
 DbTable.IndexName := Indexes.Text;
end;

procedure TDbfTable.leFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 If Key = 13 Then
  Begin
   If Trim(leFilter.Text) <> '' Then
    Begin
     Try
       DbTable.Filter := leFilter.Text;
     Except
       ShowMessage('Error in filter...');

       DbTable.Filter := '';
     End;
    End
   Else
    DbTable.Filter := '';

   ShowTableInfo(DbTable);
  End;
end;

procedure TDbfTable.PackClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Pack the table?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
   DbTable.PackTable;
end;

procedure TDbfTable.RestructClick(Sender: TObject);
begin
 Restructure := TRestructure.Create(Self);
 Restructure.Temp := DbTable;

 Restructure.ShowModal;

 Restructure.Free;

 DbTable.Close;
 DbTable.Open;

 Set_Up;
end;

procedure TDbfTable.SetFieldClick(Sender: TObject);
begin
 SetFV := TSetFV.Create(Self);
 SetFV.SetTable := DbTable;

 SetFV.ShowModal;

 SetFV.Free;

 DbTable.Close;
 DbTable.Open;
end;

procedure TDbfTable.cbShowDelChange(Sender: TObject);
begin
 DBTable.ShowDeleted := cbShowDel.Checked;
end;

procedure TDbfTable.EmptyClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Delete all records in the table?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
   Begin
    DbGrid1.BeginUpdate;

    DbTable.EmptyTable;

    DbGrid1.EndUpdate(False);

    DbTable.Close;
    DbTable.Open;
   End;
end;

procedure TDbfTable.FormCreate(Sender: TObject);
begin
  Fix_DBNavigatorIcons;
end;

procedure TDbfTable.Fix_DBNavigatorIcons;
const
  // Image indices of the navigator's buttons in the CommonData imagelist.
  NAV_IMG_INDEX: array[TDBNavButtonType] of Integer = (
    37,  // nbFirst
    38,  // nbPrior
    39,  // nbNext
    40,  // nbLast
    30,  // nbInsert
    31,  // nbDelete
    32,  // nbEdit
    28,  // nbPost
    29,  // nbCancel
    36   // nbRefresh
  );
var
  i: Integer;
  btn: TDBNavButton;
begin
  DBNavigator1.Images := CommonData.Images;
  for i := 0 to DBNavigator1.ControlCount-1 do
    if DBNavigator1.Controls[i] is TDBNavButton then
    begin
      btn := TDBNavButton(DBNavigator1.Controls[i]);
      btn.ImageIndex := NAV_IMG_INDEX[btn.Index];
    end;
end;

procedure TDbfTable.FormDestroy(Sender: TObject);
begin
 If DBTable.Active Then
  DBTable.Close;
end;

procedure TDbfTable.Load_Table_Indexes;
 Var Ind : Word;
begin
 Indexes.Clear;

 Indexes.Items.Add('');

 If DBTable.Indexes.Count > 0 Then
  For Ind := 0 To DBTable.Indexes.Count - 1 Do
   Indexes.Items.Add(DBTable.Indexes.Items[Ind].Name);
end;

procedure TDbfTable.ShowTableInfo(DataSet: TDataSet);
begin
 Assert(Dataset is TDbf, 'Dataset must be a TDbf');

 SbInfo.Panels[0].Text := 'Record Count: ' + IntToStr(TDbf(DataSet).ExactRecordCount);

 If Not DbTable.IsEmpty Then
  SbInfo.Panels[1].Text := 'Record Number: ' + IntToStr(Dataset.RecNo)
 Else
  SbInfo.Panels[1].Text := 'Record Number: 0';
end;

procedure TDbfTable.SpeedButton1Click(Sender: TObject);
begin
 Main.WorkSiteCloseTabClicked(Main.WorkSite.Pages[Self.PageIdx]);
end;

procedure TDbfTable.ToolButton1Click(Sender: TObject);
begin
 Main.WorkSiteCloseTabClicked(Main.WorkSite.Pages[Self.PageIdx]);
end;

procedure TDbfTable.ViewDelClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Delete all records in grid?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
   Begin
    DbGrid1.BeginUpdate;

    While Not DbTable.EOF Do
     DbTable.Delete;

    DbGrid1.EndUpdate(False);

    DbTable.Close;
    DbTable.Open;
   End;
end;

procedure TDbfTable.Set_Up;
begin
 Load_Table_Indexes();

 ShowTableInfo(DbTable);
end;

end.

