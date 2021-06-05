unit uOpenBA;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids, FileCtrl, Buttons, ExtCtrls;

type

  { TOpenBA }

  TOpenBA = class(TForm)
    CloseBtn: TBitBtn;
    OpenTableBtn: TBitBtn;
    DeleteAliasBtn: TBitBtn;
    AddAliasBtn: TBitBtn;
    DBGrid1: TDBGrid;
    Ds1: TDataSource;
    FileListbox: TFileListBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Splitter1: TSplitter;
    procedure CloseBtnClick(Sender: TObject);
    procedure FileListboxResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OpenTableBtnClick(Sender: TObject);
    procedure AddAliasClick(Sender: TObject);
    procedure DeleteAliasClick(Sender: TObject);
    procedure DBGrid1CellClick({%H-}Column: TColumn);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FAliasDB: TDbf;
  public
    { public declarations }
//    PageIdx : Integer;
    property AliasDB: TDbf read FAliasDB;
  end;

var
  OpenBA: TOpenBA;

implementation

uses
  Math,
  uUtils, uMain, uAddAlias;

{$R *.lfm}

{ TOpenBA }

procedure TOpenBA.FormDestroy(Sender: TObject);
begin
  if FAliasDB.Active then
    FAliasDB.Close;
end;

procedure TOpenBA.FormShow(Sender: TObject);
var
  fn: String;
begin
  FileListbox.Clear;
  FileListbox.Columns := 2;

  fn := FAliasDB.FilePath + FAliasDB.Tablename;
  if FileExists(fn) then
  begin
    FAliasDB.Open;
    DBGrid1CellClick(Nil);
  end else
  begin
    Ds1.Enabled := False;
    MessageDlg('Alias db non found.', mtError, [mbOK], 0);
  end;
end;

procedure TOpenBA.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

// More columns on a wide form, fewer columns on a narrow form.
procedure TOpenBA.FileListboxResize(Sender: TObject);
var
  w: Integer;
  fn: String;
begin
  if not FileListbox.HandleAllocated then
    exit;

  if FileListbox.Items.Count = 0 then
    exit;

  w := 0;
  for fn in FileListbox.Items do
    w := Max(w, FileListbox.Canvas.TextWidth(fn));
  FileListbox.Columns := FileListbox.ClientWidth div w;
end;

procedure TOpenBA.FormCreate(Sender: TObject);
begin
  FAliasDB := TDbf.Create(self);
  FAliasDB.TableName := 'alias.dbf';
  FAliasDB.FilePath := GetAliasDir;
  FAliasDB.IndexName := 'ALIAS';
  Ds1.Dataset := FAliasDB;
end;

procedure TOpenBA.OpenTableBtnClick(Sender: TObject);
var
  Ind: Word;
  dir: String;
  fn: String;
begin
  if FileListbox.Count > 0 then
  begin
    dir := IncludeTrailingPathDelimiter(FileListbox.Directory);
    for Ind := 0 to FileListbox.Count - 1 do
      if FileListbox.Selected[Ind] then
      begin
        try
          fn := dir + FileListbox.Items[ind];
          Main.Open_Table(fn);
        except
        end;
      end;
  end;
end;

procedure TOpenBA.AddAliasClick(Sender: TObject);
begin
  if Ds1.Enabled then
  begin
    AddAlias := TAddAlias.Create(nil);
    AddAlias.ShowModal;
    AddAlias.Release;
    FAliasDB.Close;
    FAliasDB.Open;
    DBGrid1CellClick(nil);
  end;
end;

procedure TOpenBA.DeleteAliasClick(Sender: TObject);
begin
  if Ds1.Enabled then
    if not FAliasDB.IsEmpty then
      if MessageDlg('Delete the selected alias?', mtWarning, [mbOk, mbCancel],0) = mrOk then
      begin
        FAliasDB.Delete;
        FAliasDB.Close;
        FAliasDB.Open;
        FileListbox.Clear;
        DBGrid1CellClick(nil);
      end;
end;

procedure TOpenBA.DBGrid1CellClick(Column: TColumn);
begin
  if Ds1.Enabled then
    if not FAliasDB.IsEmpty then
      FileListbox.Directory := FAliasDB.FieldByName('PATH').AsString;
end;

end.

