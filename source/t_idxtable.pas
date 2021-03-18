unit T_IdxTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Buttons;

type

  { TIdxTable }

  TIdxTable = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    cbOpt: TCheckGroup;
    IdxList: TListBox;
    IdxName: TLabeledEdit;
    SelField: TLabeledEdit;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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

{$R *.lfm}

uses
  T_Restructure, T_NewTable;

{ TIdxTable }

procedure TIdxTable.IdxListClick(Sender: TObject);
begin
 SelField.Text:=IdxList.Items[IdxList.ItemIndex];
end;

procedure TIdxTable.FormCreate(Sender: TObject);
begin
 Ret:=False;
end;

procedure TIdxTable.BitBtn2Click(Sender: TObject);
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

 Ret:=True;

 Close;
end;


end.

