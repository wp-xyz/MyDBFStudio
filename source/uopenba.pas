unit uOpenBA;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids, Buttons, ExtCtrls, ComCtrls, ShellCtrls;

type
  { TOpenBA }

  TOpenBA = class(TForm)
    CloseBtn: TBitBtn;
    FileListView: TShellListView;
    SmallImages: TImageList;
    LargeImage: TImageList;
    OpenTableBtn: TBitBtn;
    DeleteAliasBtn: TBitBtn;
    AddAliasBtn: TBitBtn;
    AliasGrid: TDBGrid;
    DataSource: TDataSource;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Splitter: TSplitter;
    ToolBar1: TToolBar;
    tbViewStyleList: TToolButton;
    tbViewStyleIcon: TToolButton;
    tvViewStyleReport: TToolButton;
    procedure AddAliasClick(Sender: TObject);
    procedure AliasGridCellClick({%H-}Column: TColumn);
    procedure CloseBtnClick(Sender: TObject);
    procedure DeleteAliasClick(Sender: TObject);
    procedure FileListViewDblClick(Sender: TObject);
    procedure FileListViewFileAdded(Sender: TObject; Item: TListItem);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OpenTableBtnClick(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
    procedure tbViewStyleIconClick(Sender: TObject);
    procedure tbViewStyleListClick(Sender: TObject);
    procedure tvViewStyleReportClick(Sender: TObject);
  private
    { private declarations }
    FAliasDB: TDbf;
    procedure SelectCurrentFile;
  public
    { public declarations }
    procedure UpdateOptions;
    property AliasDB: TDbf read FAliasDB;
  end;

var
  OpenBA: TOpenBA;

implementation

uses
  uUtils, uDataModule, uMain, uAddAlias, uOptions;

{$R *.lfm}


{ TOpenBA }

procedure TOpenBA.FormCreate(Sender: TObject);
begin
  FAliasDB := TDbf.Create(self);
  FAliasDB.TableName := 'alias.dbf';
  FAliasDB.FilePath := GetAliasDir;
  FAliasDB.IndexName := 'ALIAS';
  DataSource.Dataset := FAliasDB;

  if Options.UseAlternateColor then
    AliasGrid.AlternateColor := Options.AlternateColor
  else
    AliasGrid.AlternateColor := AliasGrid.Color;
  if Options.ShowGridLines then
    AliasGrid.Options := AliasGrid.Options + [dgRowLines, dgColLines]
  else
    AliasGrid.Options := AliasGrid.Options - [dgRowLines, dgColLines];
  AliasGrid.GridLineColor := Options.GridLineColor;
end;

procedure TOpenBA.FormDestroy(Sender: TObject);
begin
  if FAliasDB.Active then
    FAliasDB.Close;
end;

procedure TOpenBA.FormShow(Sender: TObject);
var
  fn: String;
begin
  FileListView.Clear;

  fn := FAliasDB.FilePath + FAliasDB.Tablename;
  if FileExists(fn) then
  begin
    FAliasDB.Open;
    SelectCurrentFile;
  end else
  begin
    DataSource.Enabled := False;
    MessageDlg('Alias db non found.', mtError, [mbOK], 0);
  end;

  if Options.OpenByAliasSplitter > -1 then
    Splitter.Top := Options.OpenByAliasSplitter;
end;

procedure TOpenBA.SplitterMoved(Sender: TObject);
begin
  Options.OpenByAliasSplitter := Splitter.Top;
end;

procedure TOpenBA.tbViewStyleIconClick(Sender: TObject);
begin
  FileListView.ViewStyle := vsIcon;
  FileListView.Width := FileListView.Width + 1;
  FileListview.Width := FileListview.Width - 1;
end;

procedure TOpenBA.tbViewStyleListClick(Sender: TObject);
var
  oldViewStyle: TViewStyle;
begin
  oldViewStyle := FileListView.ViewStyle;

  FileListView.ViewStyle := vsList;

  if ((oldViewStyle = vsIcon) and (FileListView.ViewStyle <> vsIcon)) or
     ((oldViewStyle <> vsIcon) and (FileListView.ViewStyle = vsIcon)) then
  begin
    FileListView.Width := FileListView.Width + 1;
    FileListview.Width := FileListview.Width - 1;
//    FileListView.PopulateWithRoot;
  end;
end;

procedure TOpenBA.tvViewStyleReportClick(Sender: TObject);
begin
  FileListView.ViewStyle := vsReport;
  FileListView.Width := FileListView.Width + 1;
  FileListview.Width := FileListview.Width - 1;
end;

procedure TOpenBA.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TOpenBA.FileListViewDblClick(Sender: TObject);
begin
  OpenTableBtnClick(nil);
end;

procedure TOpenBA.FileListViewFileAdded(Sender: TObject; Item: TListItem);
begin
  Item.ImageIndex := 0;
end;

procedure TOpenBA.OpenTableBtnClick(Sender: TObject);
var
  i: Word;
  fn: String;
begin
  if FileListView.Items.Count = 0 then
    exit;

  for i := 0 to FileListView.Items.Count-1 do
    if FileListView.Items[i].Selected then
      try
        fn := FileListView.GetPathFromItem(FileListView.Items[i]);
        Main.Open_Table(fn);
      except
      end;
end;

procedure TOpenBA.AddAliasClick(Sender: TObject);
begin
  if DataSource.Enabled then
  begin
    AddAlias := TAddAlias.Create(nil);
    try
      AddAlias.ShowModal;
    finally
      AddAlias.Free;
    end;
    FAliasDB.Close;
    FAliasDB.Open;
    SelectCurrentFile;
  end;
end;

procedure TOpenBA.DeleteAliasClick(Sender: TObject);
begin
  if DataSource.Enabled then
    if not FAliasDB.IsEmpty then
      if MessageDlg('Delete the selected alias?', mtWarning, [mbOk, mbCancel],0) = mrOk then
      begin
        FAliasDB.Delete;
        FAliasDB.Close;
        FAliasDB.Open;
        FileListView.Clear;
        SelectCurrentFile;
      end;
end;

procedure TOpenBA.AliasGridCellClick(Column: TColumn);
begin
  SelectCurrentFile;
end;

procedure TOpenBA.SelectCurrentFile;
var
  F: TField;
begin
  if DataSource.Enabled then
  begin
    F := FAliasDB.FieldByName('PATH');
    if not F.IsNull then
      FileListView.Root := F.AsString;
//      FileListbox.Directory := F.AsString;
//    if not FAliasDB.IsEmpty then
//      FileListbox.Directory := FAliasDB.FieldByName('PATH').AsString;
  end;
end;

procedure TOpenBA.UpdateOptions;
begin
  if Options.UseAlternateColor then
    AliasGrid.AlternateColor := Options.AlternateColor
  else
    AliasGrid.AlternateColor := AliasGrid.Color;
  if Options.ShowGridLines then
    AliasGrid.Options := AliasGrid.Options + [dgRowLines, dgColLines]
  else
    AliasGrid.Options := AliasGrid.Options - [dgRowLines, dgColLines];
  AliasGrid.GridLineColor := Options.GridLineColor;
end;

end.

