unit uAddAlias;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type

  { TAddAlias }

  TAddAlias = class(TForm)
    AliasDB: TDbf;
    AName: TEdit;
    CancelBtn: TBitBtn;
    lblAliasName: TLabel;
    lblPath: TLabel;
    OKBtn: TBitBtn;
    BrowseBtn: TButton;
    Path: TEdit;
    SelDir: TSelectDirectoryDialog;
    procedure CancelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure BrowseBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Function CheckAliasName(Val : String) : Boolean;

    Procedure InsertAlias;
  public
    { public declarations }
  end;

var
  AddAlias: TAddAlias;

implementation

{$R *.lfm}

{ TAddAlias }

procedure TAddAlias.BrowseBtnClick(Sender: TObject);
begin
 If SelDir.Execute Then
  Path.Text := SelDir.FileName;
end;

procedure TAddAlias.FormShow(Sender: TObject);
begin
  OKBtn.Constraints.MinWidth := CancelBtn.Width;
end;

function TAddAlias.CheckAliasName(Val: String): Boolean;
begin
 Result := True;

 ChDir(ExtractFilePath(Application.ExeName));

 AliasDB.TableName := 'alias.dbf';
 AliasDB.FilePath := ExtractFilePath(Application.ExeName);

 AliasDB.Open;

 AliasDB.Filter := 'ALIAS = ''' + Val + '''';

 If Not AliasDB.IsEmpty Then
  Result := False;

 AliasDB.Close;
end;

procedure TAddAlias.InsertAlias;
begin
 ChDir(ExtractFilePath(Application.ExeName));

 AliasDB.TableName := 'alias.dbf';
 AliasDB.FilePath := ExtractFilePath(Application.ExeName);

 AliasDB.Open;

 AliasDB.Insert;
 AliasDB.FieldByName('ALIAS').AsString := AName.Text;
 AliasDb.FieldByName('PATH').AsString := Path.Text;
 AliasDb.Post;

 AliasDB.Close;
end;

procedure TAddAlias.CancelBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TAddAlias.OKBtnClick(Sender: TObject);
begin
 If Trim(AName.Text) = '' Then
  Begin
   ShowMessage('You must insert an alias name.');

   AName.SetFocus;

   Exit;
  End;

 If Trim(Path.Text) = '' Then
  Begin
   ShowMessage('You must insert the tables path.');

   Path.SetFocus;

   Exit;
  End;

 If Not DirectoryExists(Path.Text) Then
  Begin
   ShowMessage('The directory dont''t exists.');

   Path.SetFocus;

   Exit;
  End;

 If Not CheckAliasName(AName.Text) Then
  Begin
   ShowMessage('The alias name alredy exists.');

   AName.SetFocus;

   Exit;
  End;

 Try
   InsertAlias;

   Close;
 Except
   ShowMessage('Error while writing alias data.');
 End;
end;

end.

