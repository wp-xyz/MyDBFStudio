unit T_OpenBA;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, db, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, Buttons, DBGrids, FileCtrl;

type

  { TOpenBA }

  TOpenBA = class(TForm)
    AliasDB: TDbf;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    DS: TDataSource;
    DBGrid1: TDBGrid;
    Elenco: TFileListBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    procedure BitBtn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  OpenBA: TOpenBA;

implementation

Uses T_AddAlias, T_MainForm;

{ TOpenBA }

procedure TOpenBA.FormShow(Sender: TObject);
begin
  Elenco.Clear;
  Elenco.Columns:=2;

  If FileExists(Application.Location + 'alias.dbf') Then
  Begin
    AliasDB.TableName:='alias.dbf';
    AliasDB.FilePath:=Application.Location;
    AliasDB.IndexName:='ALIAS';

    AliasDB.Open;

    DBGrid1CellClick(Nil);
  End
  Else
  Begin
    DS.Enabled:=False;
    ShowMessage('Alias db non found!');
  End;
end;

procedure TOpenBA.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 If AliasDB.Active Then
  AliasDB.Close;
end;

procedure TOpenBA.Button1Click(Sender: TObject);
begin
 If Ds.Enabled Then
  Begin
   AddAlias:=TAddAlias.Create(Self);

   AddAlias.ShowModal;

   AddAlias.Release;

   AliasDB.Close;
   AliasDB.Open;

   DBGrid1CellClick(Nil);
  End;
end;

procedure TOpenBA.BitBtn2Click(Sender: TObject);
 Var Ind : Word;
     CanCls : Boolean;
begin
 CanCls:=False;

 If Elenco.Count > 0 Then
  For Ind:=0 To Elenco.Count - 1 Do
   If Elenco.Selected[Ind] Then
    Begin
     Try
       MainForm.Open_Table(IncludeTrailingBackslash(Elenco.Directory) + Elenco.Items.Strings[Ind]);

       CanCls:=True;
     Except
     End;
    End;

 If CanCls Then
  Close;
end;

procedure TOpenBA.Button2Click(Sender: TObject);
begin
 If Ds.Enabled Then
  If Not AliasDB.IsEmpty Then
   If MessageDlg('Delete the selected alias?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
    Begin
     AliasDB.Delete;

     AliasDB.Close;
     AliasDB.Open;

     Elenco.Clear;

     DBGrid1CellClick(Nil);
    End;
end;

procedure TOpenBA.DBGrid1CellClick(Column: TColumn);
begin
 If DS.Enabled Then
  If Not AliasDB.IsEmpty Then
   Elenco.Directory:=AliasDB.FieldByName('PATH').AsString;
end;

initialization
  {$I t_openba.lrs}

end.

