unit uIdxTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons;

type

  { TIdxTable }

  TIdxTable = class(TForm)
    CloseBtn: TBitBtn;
    CreateIndexBtn: TBitBtn;
    cbOpt: TCheckGroup;
    IdxList: TListBox;
    IdxName: TEdit;
    lblIndexName: TLabel;
    lblSelField: TLabel;
    SelField: TEdit;
    procedure CloseBtnClick(Sender: TObject);
    procedure CreateIndexBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IdxListClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    New : Boolean;
    Ret : Boolean;
    Calling : TObject;
  end;

var
  IdxTable: TIdxTable;

implementation

uses
  uNewTable, uRestructure, uOptions;

{$R *.lfm}

{ TIdxTable }

procedure TIdxTable.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.IndexTableWindow.ExtractFromForm(Self);
end;

procedure TIdxTable.FormCreate(Sender: TObject);
begin
 Ret := False;
end;

procedure TIdxTable.FormShow(Sender: TObject);
begin
//  CloseBtn.Constraints.MinWidth := Max(CloseBtn.Width, CreateIndexBtn.Width);
//  CreateIndexBtn.Constraints.MinWidth := CloseBtn.Constraints.MinWidth;

  Constraints.MinWidth := (CreateIndexBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := IdxName.Top + Idxname.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.IndexTableWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.IndexTableWindow.ApplyToForm(Self);
  end;
end;

procedure TIdxTable.IdxListClick(Sender: TObject);
begin
 SelField.Text := IdxList.Items[IdxList.ItemIndex];
end;

procedure TIdxTable.CreateIndexBtnClick(Sender: TObject);
begin
 If Trim(IdxName.Text) = '' Then
  Begin
   ShowMessage('You MUST insert a Index Name or Expression!');

   IdxName.SetFocus;

   Exit;
  End;

 If Calling Is TRestructure Then
  Begin
   If New Then
    If Not Restructure.TestIndexName(IdxName.Text) Then
     Begin
      ShowMessage('Index name already exists!');

      IdxName.SetFocus;

      Exit;
     End;
  End
 Else
  If Calling Is TNewTable Then
   If New Then
    If Not NewTable.TestIndexName(IdxName.Text) Then
     Begin
      ShowMessage('Index name already exists!');

      IdxName.SetFocus;

      Exit;
     End;

 Ret := True;

 Close;
end;

procedure TIdxTable.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

end.

