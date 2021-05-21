unit uOpenBA;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids, FileCtrl, Buttons, ExtCtrls;

type

  { TOpenBA }

  TOpenBA = class(TForm)
    AliasDB: TDbf;
    CloseBtn: TBitBtn;
    OpenTableBtn: TBitBtn;
    DeleteAliasBtn: TBitBtn;
    AddAliasBtn: TBitBtn;
    DBGrid1: TDBGrid;
    Ds1: TDataSource;
    Elenco: TFileListBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Splitter1: TSplitter;
    procedure CloseBtnClick(Sender: TObject);
    procedure OpenTableBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    PageIdx : Integer;
  end;

var
  OpenBA: TOpenBA;

implementation

Uses Math, uMain, uAddAlias;

{$R *.lfm}

{ TOpenBA }

procedure TOpenBA.FormDestroy(Sender: TObject);
begin
 If AliasDB.Active Then
  AliasDB.Close;
end;

procedure TOpenBA.FormShow(Sender: TObject);
begin
 Elenco.Clear;
 Elenco.Columns:=2;

 If FileExists(Application.Location + 'alias.dbf') Then
  Begin
   AliasDB.TableName := 'alias.dbf';
   AliasDB.FilePath := Application.Location;
   AliasDB.IndexName := 'ALIAS';

   AliasDB.Open;

   DBGrid1CellClick(Nil);
  End
 Else
  Begin
   Ds1.Enabled := False;

   ShowMessage('Alias db non found!');
  End;
end;

procedure TOpenBA.CloseBtnClick(Sender: TObject);
begin
  Main.WorkSiteCloseTabClicked(Main.WorkSite.Pages[Self.PageIdx]);
end;

procedure TOpenBA.OpenTableBtnClick(Sender: TObject);
 Var Ind : Word;
begin
 If Elenco.Count > 0 Then
  For Ind := 0 To Elenco.Count - 1 Do
   If Elenco.Selected[Ind] Then
    Begin
     Try
       Main.Open_Table(IncludeTrailingBackslash(Elenco.Directory) + Elenco.Items.Strings[Ind]);
     Except
     End;
    End;
end;

procedure TOpenBA.Button1Click(Sender: TObject);
begin
 If Ds1.Enabled Then
  Begin
   AddAlias := TAddAlias.Create(Self);

   AddAlias.ShowModal;

   AddAlias.Release;

   AliasDB.Close;
   AliasDB.Open;

   DBGrid1CellClick(Nil);
  End;
end;

procedure TOpenBA.Button2Click(Sender: TObject);
begin
 If Ds1.Enabled Then
  If Not AliasDB.IsEmpty Then
   If MessageDlg('Delete the selected alias?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
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
 If Ds1.Enabled Then
  If Not AliasDB.IsEmpty Then
   Elenco.Directory := AliasDB.FieldByName('PATH').AsString;
end;

end.

