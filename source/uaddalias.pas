unit uAddAlias;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type

  { TAddAlias }

  TAddAlias = class(TForm)
    AName: TEdit;
    CancelBtn: TBitBtn;
    lblAliasName: TLabel;
    lblPath: TLabel;
    OKBtn: TBitBtn;
    BrowseBtn: TButton;
    Path: TEdit;
    SelDir: TSelectDirectoryDialog;
    procedure CancelBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure BrowseBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FAliasDB: TDbf;
    Function CheckAliasName(Val : String) : Boolean;
    Procedure InsertAlias;
  public
    { public declarations }
    property AliasDB: TDbf read FAliasDB;
  end;

var
  AddAlias: TAddAlias;

implementation

{$R *.lfm}

uses
  uUtils, uOptions;

{ TAddAlias }

procedure TAddAlias.BrowseBtnClick(Sender: TObject);
begin
  if SelDir.Execute then
    Path.Text := SelDir.FileName;
end;

function TAddAlias.CheckAliasName(Val: String): Boolean;
begin
  Result := true;

  AliasDB.TableName := 'alias.dbf';
  AliasDB.FilePath := GetAliasDir;
  AliasDB.Open;
  AliasDB.Filter := 'ALIAS = ''' + Val + '''';
  if not AliasDB.IsEmpty then
    Result := false;

  AliasDB.Close;
end;

procedure TAddAlias.InsertAlias;
begin
  FAliasDB.TableName := 'alias.dbf';
  FAliasDB.FilePath := GetAliasDir;
  FAliasDB.Open;
  FAliasDB.Insert;
  FAliasDB.FieldByName('ALIAS').AsString := AName.Text;
  FAliasDb.FieldByName('PATH').AsString := Path.Text;
  FAliasDb.Post;
  FAliasDB.Close;
end;

procedure TAddAlias.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TAddAlias.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.AddAliasWindow.ExtractFromForm(Self);
end;

procedure TAddAlias.FormCreate(Sender: TObject);
begin
  FAliasDB := TDbf.Create(self);
  FAliasDB.Filtered := true;
end;

procedure TAddAlias.FormShow(Sender: TObject);
begin
  OKBtn.Constraints.MinWidth := CancelBtn.Width;
  Options.AddAliasWindow.ApplyToForm(Self);
end;

procedure TAddAlias.OKBtnClick(Sender: TObject);
begin
  if Trim(AName.Text) = '' then
  begin
    MessageDlg('You must provide an alias name.', mtError, [mbOK], 0);
    AName.SetFocus;
    exit;
  end;

  if Trim(Path.Text) = '' then
  begin
    MessageDlg('You must insert the tables path.', mtError, [mbOK], 0);
    Path.SetFocus;
    exit;
  end;

  if not DirectoryExists(Path.Text) then
  begin
    MessageDlg('The directory does not exist.', mtError, [mbOK], 0);
    Path.SetFocus;
    exit;
  end;

  if not CheckAliasName(AName.Text) then
  begin
    MessageDlg('The alias name alredy exists.', mtError, [mbOK], 0);
    AName.SetFocus;
    exit;
  end;

  try
    InsertAlias;
    Close;
  except
    on E: Exception do
      MessageDlg('Error while writing alias data:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

end.

