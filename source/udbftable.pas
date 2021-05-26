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
    DBMemo: TDBMemo;
    Indexes: TComboBox;
    DBGrid: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBTable: TDbf;
    Ds: TDataSource;
    Label1: TLabel;
    Label2: TLabel;
    leFilter: TEdit;
    Panel1: TPanel;
    sbInfo: TStatusBar;
    MemoSplitter: TSplitter;
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
    Procedure Load_Table_Indexes;
    procedure ShowMemo(ATable: TDbf);
    function TranslateHandler(ATable: TDbf; Src, Dest: PChar; ToOem: Boolean): Integer;

  public
    { public declarations }
    PageIdx : Integer;

    Procedure Set_Up;
  end;

var
  DbfTable: TDbfTable;

implementation

Uses
  LConvEncoding,
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
    DBGrid.BeginUpdate;

    DbTable.EmptyTable;

    DBGrid.EndUpdate(False);

    DbTable.Close;
    DbTable.Open;
   End;
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
  if DbTable.Active then
    if MessageDlg('Delete all records in grid?', mtWarning, [mbOk, mbCancel],0) = mrOk then
    begin
      DBGrid.BeginUpdate;
      try
        while Not DbTable.EOF do
          DbTable.Delete;
      finally
        DBGrid.EndUpdate(False);
      end;
      DbTable.Close;
      DbTable.Open;
    end;
end;

procedure TDbfTable.Set_Up;
var
  field: TField;
begin
  Load_Table_Indexes();
  ShowMemo(DbTable);
  ShowTableInfo(DbTable);

  // Make sure that strings are converted to UTF-8.
  DbTable.OnTranslate := @TranslateHandler;
  for field in DbTable.Fields do
    if (field is TStringField) then
      TStringField(field).Transliterate := true;
end;

procedure TDbfTable.ShowMemo(ATable: TDbf);
var
  field: TField;
begin
  for field in ATable.Fields do
    if field.DataType in [ftMemo, ftWideMemo] then
    begin
      DBMemo.DataField := field.FieldName;
      DBMemo.Show;
      MemoSplitter.Show;
      MemoSplitter.Top := 0;
      exit;
    end;

  // No memo found
  DBMemo.Hide;
  MemoSplitter.Hide;
end;

function TDbfTable.TranslateHandler(ATable: TDbf; Src, Dest: PChar; ToOem: Boolean): Integer;
var
  s: String;
  cp: String;
begin
  cp := 'cp' + IntToStr(ATable.CodePage);
  if ToOEM then
    s := ConvertEncoding(Src, 'utf8', cp)
  else
    s := ConvertEncoding(Src, cp, 'utf8');
  StrCopy(Dest, PChar(s));
  Result := StrLen(Dest);
end;

end.

