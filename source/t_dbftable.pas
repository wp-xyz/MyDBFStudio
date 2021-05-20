unit T_DbfTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, DB, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, DBGrids, DbCtrls, Buttons, ComCtrls;

type

  { TDbfTable }

  TDbfTable = class(TForm)
    DS: TDataSource;
    ShowDel: TCheckBox;
    SbInfo: TStatusBar;
    ViewDel: TSpeedButton;
    Indexes: TComboBox;
    DBNavigator: TDBNavigator;
    DBGrid1: TDBGrid;
    DBTable: TDbf;
    Empty: TSpeedButton;
    Filter: TLabeledEdit;
    Restruct: TSpeedButton;
    Panel1: TPanel;
    Pack: TSpeedButton;
    SetField: TSpeedButton;
    WndPanel: TPanel;
    procedure EmptyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PackClick(Sender: TObject);
    procedure RestructClick(Sender: TObject);
    procedure SetFieldClick(Sender: TObject);
    procedure ShowDelChange(Sender: TObject);
    procedure FilterKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure IndexesChange(Sender: TObject);
    procedure ViewDelClick(Sender: TObject);

    Procedure ShowTableInfo(DataSet: TDataSet);
  private
    { private declarations }
    Procedure Load_Table_Indexes();
  public
    { public declarations }

    Procedure Set_Up();
  end; 

var
  DbfTable: TDbfTable;

implementation

{$R *.lfm}

uses
  T_Restructure, uSetFV;

{ TDbfTable }

procedure TDbfTable.IndexesChange(Sender: TObject);
begin
 DbTable.IndexName:=Indexes.Text;
end;

procedure TDbfTable.ViewDelClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Delete all records in grid?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
   Begin
    DbGrid1.Enabled:=False;

    While Not DbTable.EOF Do
     DbTable.Delete;

   DbGrid1.Enabled:=True;

   DbTable.Close;
   DbTable.Open;
   End;
end;

procedure TDbfTable.FilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 If Key = 13 Then
  Begin
   If Trim(Filter.Text) <> '' Then
    Begin
     Try
       DbTable.Filter:=Filter.Text;
     Except
       ShowMessage('Error in filter...');

       DbTable.Filter:='';
     End;
    End
   Else
    DbTable.Filter:='';

   ShowTableInfo(DbTable);
  End;
end;

procedure TDbfTable.ShowDelChange(Sender: TObject);
begin
 DBTable.ShowDeleted:=ShowDel.Checked;
end;

procedure TDbfTable.PackClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Pack the table?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
   DbTable.PackTable;
end;

procedure TDbfTable.RestructClick(Sender: TObject);
begin
 Restructure:=TRestructure.Create(Self);
 Restructure.Temp:=DbTable;

 Restructure.ShowModal;

 Restructure.Release;

 DbTable.Close;
 DbTable.Open;

 Set_Up();
end;

procedure TDbfTable.SetFieldClick(Sender: TObject);
begin
 SetFV:=TSetFV.Create(Self);
 SetFV.SetTable:=DbTable;

 SetFV.ShowModal;

 SetFV.Release;

 DbTable.Close;
 DbTable.Open;
end;

procedure TDbfTable.EmptyClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Delete all records in the table?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
   Begin
    DbTable.EmptyTable;

    DbTable.Close;
    DbTable.Open;
   End;
end;

procedure TDbfTable.FormCreate(Sender: TObject);
var
  dir: String;
begin
  dir := Application.Location;

  if FileExists(dir + 'img/pack_s.bmp') Then
    Pack.Glyph.LoadFromFile(dir + 'img/pack_s.bmp');

  If FileExists(dir + 'img/empty_s.bmp') Then
    Empty.Glyph.LoadFromFile(dir + 'img/empty_s.bmp');

  If FileExists(dir + 'img/cut_s.bmp') Then
    ViewDel.Glyph.LoadFromFile(dir + 'img/cut_s.bmp');

  If FileExists(dir + 'img/restr_s.bmp') Then
    Restruct.Glyph.LoadFromFile(dir + 'img/restr_s.bmp');

  If FileExists(dir + 'img/set_s.bmp') Then
    SetField.Glyph.LoadFromFile(dir + 'img/set_s.bmp');
end;

procedure TDbfTable.Load_Table_Indexes();
 Var Ind : Word;
begin
 Indexes.Clear;

 Indexes.Items.Add('');

 If DBTable.Indexes.Count > 0 Then
  For Ind:=0 To DBTable.Indexes.Count - 1 Do
   Indexes.Items.Add(DBTable.Indexes.Items[Ind].Name);
end;

procedure TDbfTable.ShowTableInfo(DataSet: TDataSet);
begin
 SbInfo.Panels[0].Text:='Record Count: ' + IntToStr(DbTable.ExactRecordCount);

 SbInfo.Panels[1].Text:='Record Number: ' + IntToStr(DbTable.RecNo);
end;

procedure TDbfTable.Set_Up();
begin
 Load_Table_Indexes();

 ShowTableInfo(DbTable);
end;


end.

