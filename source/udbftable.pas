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
    TabControl: TTabControl;
    ToolBar1: TToolBar;
    Pack: TToolButton;
    Empty: TToolButton;
    CloseTabBtn: TToolButton;
    tbAutoFillColumns: TToolButton;
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
    procedure TabControlChange(Sender: TObject);
    procedure CloseTabBtnClick(Sender: TObject);
    procedure tbAutoFillColumnsClick(Sender: TObject);
    procedure ViewDelClick(Sender: TObject);
  private
    { private declarations }
    FColWidths: array of Integer;
    Procedure Load_Table_Indexes;
    procedure RestoreColWidths(ATable: TDbf);
    procedure SaveColWidths(ATable: TDbf);
    procedure ShowMemo(ATable: TDbf);
    function TranslateHandler(ATable: TDbf; Src, Dest: PChar; ToOem: Boolean): Integer;

  public
    { public declarations }
    procedure Setup;
  end;

var
  DbfTable: TDbfTable;

implementation

uses
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
  try
    Restructure.Temp := DbTable;
    Restructure.ShowModal;
  finally
    Restructure.Free;
  end;
  DbTable.Close;
  DbTable.Open;
  Setup;
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
  if DBTable.Active then
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

  SbInfo.Panels[0].Text := Format('Record Count: %d', [TDbf(DataSet).ExactRecordCount]);
  if DbTable.IsEmpty then
    SbInfo.Panels[1].Text := 'Record Number: (none)'
  else
    SbInfo.Panels[1].Text := Format('Record Number: %d', [Dataset.RecNo]);
end;

procedure TDbfTable.TabControlChange(Sender: TObject);
begin
  DBMemo.DataField := TabControl.Tabs[TabControl.TabIndex];
end;

procedure TDbfTable.CloseTabBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TDbfTable.tbAutoFillColumnsClick(Sender: TObject);
begin
  if tbAutoFillColumns.Down then
    SaveColWidths(DBTable);
  DBGrid.AutoFillColumns := tbAutoFillColumns.Down;
  if not tbAutoFillColumns.Down then
    RestoreColWidths(DBTable);
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

procedure TDbfTable.RestoreColWidths(ATable: TDbf);
var
  i: Integer;
  col: TColumn;
begin
  for i := 0 to ATable.FieldCount-1 do
  begin
    col := DBGrid.Columns.ColumnByFieldName(ATable.Fields[i].FieldName);
    col.Width := FColWidths[i];
  end;
end;

procedure TDbfTable.SaveColWidths(ATable: TDbf);
var
  i: Integer;
  col: TColumn;
begin
  SetLength(FColWidths, ATable.FieldCount);
  for i := 0 to ATable.FieldCount-1 do
  begin
    col := DBGrid.Columns.ColumnByFieldName(ATable.Fields[i].FieldName);
    FColWidths[i] := col.Width;
  end;
end;

procedure TDbfTable.Setup;
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
  TabControl.BeginUpdate;
  try
    TabControl.Tabs.Clear;
//    TabControl.Pages.Clear;
    for field in ATable.Fields do
      if (field is TMemoField) or (field is TWideMemoField) then
//        TabControl.Pages.Add(field.FieldName);
        TabControl.Tabs.Add(field.FieldName);

    if TabControl.Tabs.Count = 0 then
//    if Tabcontrol.PageCount = 0 then
    begin
      TabControl.Hide;
      MemoSplitter.Hide;
    end else
    begin
//      DBMemo.DataField := TabControl.Pages[0];
      DBMemo.DataField := TabControl.Tabs[0];
      TabControl.Show;
      TabControl.PageIndex := 0;
      MemoSplitter.Show;
      MemoSplitter.Top := 0;
    end;
  finally
    TabControl.EndUpdate;
  end;
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

