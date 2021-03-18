unit T_AddAlias;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, Buttons;

type

  { TAddAlias }

  TAddAlias = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    AliasDB: TDbf;
    Path: TLabeledEdit;
    AName: TLabeledEdit;
    SelDir: TSelectDirectoryDialog;
    procedure BitBtn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { private declarations }

    Function CheckAliasName(Val : String) : Boolean;

    Procedure InsertAlias();
  public
    { public declarations }
  end; 

var
  AddAlias: TAddAlias;

implementation

{$R *.lfm}

{ TAddAlias }

procedure TAddAlias.Button1Click(Sender: TObject);
begin
  If SelDir.Execute Then
   Path.Text:=SelDir.FileName;
end;

function TAddAlias.CheckAliasName(Val: String): Boolean;
begin
  Result:=True;

  AliasDB.TableName:='alias.dbf';
  AliasDB.FilePath:= Application.Location;

  AliasDB.Open;
  AliasDB.Filter:='ALIAS = ''' + Val + '''';

  If Not AliasDB.IsEmpty Then
    Result:=False;

  AliasDB.Close;
end;

procedure TAddAlias.InsertAlias();
begin
  AliasDB.TableName:='alias.dbf';
  AliasDB.FilePath:= Application.Location;

  AliasDB.Open;

  AliasDB.Insert;
  AliasDB.FieldByName('ALIAS').AsString:=AName.Text;
  AliasDb.FieldByName('PATH').AsString:=Path.Text;
  AliasDb.Post;

  AliasDB.Close;
end;

procedure TAddAlias.BitBtn2Click(Sender: TObject);
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
   InsertAlias();

   Close;
 Except
   ShowMessage('Error while writing alias data.');
 End;
end;


end.

