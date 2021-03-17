unit demomultidoc1;
{
   Demo of TMultiDoc component and TMDButtonsBar component.
   
   The main form.
   
   This show how to use the TMultiDoc component and
   the function to implement to better mimic the MDI
   interface.
   
   This very simple demo can be used as a skeleton
   for a new application.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus, ComCtrls, MultiDoc, ChildDoc, StdCtrls, ButtonsBar;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonsBar: TButtonsBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Close1: TMenuItem;
    mCascade: TMenuItem;
    mTileVer: TMenuItem;
    mTileHor: TMenuItem;
    MenuItem3: TMenuItem;
    SendText: TMenuItem;
    Window1: TMenuItem;
    MultiDoc1: TMultiDoc;
    NewChild1: TMenuItem;
    Panel1: TPanel;
    procedure BtnCloseChildClick(Sender: TObject);
    procedure BtnRestoreChildClick(Sender: TObject);
    procedure ButtonsBarClickClose(Sender: TObject);
    procedure ButtonsBarClickMaximize(Sender: TObject);
    procedure ButtonsBarClickMinimize(Sender: TObject);
    procedure mCascadeClick(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure NewChild1Click(Sender: TObject);
    procedure SendTextClick(Sender: TObject);
    procedure mTileHorClick(Sender: TObject);
    procedure mTileVerClick(Sender: TObject);
  private
    { private declarations }
    basecaption: string;
    procedure MultiDocActiveChildChange(Sender: TObject);
    procedure MultiDocMaximize(Sender: TObject);
  public
    { public declarations }
  end; 

var
  Form1: TForm1; 

implementation

uses demochild;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
 // save the form caption to add the current child name later
 BaseCaption := Caption;
 // set the menuitem that receive the child list
 MultiDoc1.WindowList := Window1;
 // what to do when the current child change
 MultiDoc1.onActiveChildChange := @MultiDocActiveChildChange;
 // what to do when maximize state change
 MultiDoc1.onMaximize := @MultiDocMaximize;
end;

{ Close the main form }
procedure TForm1.Close1Click(Sender: TObject);
begin
  Close;
end;

{ Create a new child}
procedure TForm1.NewChild1Click(Sender: TObject);
var
  Child: TChildDoc;
  FormChild: TfrChild;
begin
  Child := MultiDoc1.NewChild;
  FormChild := TfrChild.Create(Child);
  Child.DockedPanel := FormChild.MainPanel;
  Child.Caption:='demo child '+inttostr(MultiDoc1.ChildCount);
  Caption := BaseCaption + ' - ' + MultiDoc1.ActiveChild.Caption;

  with Child.TitleBar do
  begin
    Child.RestoreSize;
  //  Child.Left := DefaultPos.X - Self.VertScrollBar.Position;
  //  Child.Top := DefaultPos.Y - Self.HorzScrollBar.Position;
  //  Child.BringToFront;
    {
    DefaultPos.X := DefaultPos.X + Height + MG;
    DefaultPos.Y := DefaultPos.Y + Height + MG;
    If (DefaultPos.Y > (10 * (Height + MG))) then
    begin
      DefaultPos.Y := 0;
      If (DefaultPos.X > (20 * (Height + MG))) then
        DefaultPos.X := 0;
    end;
    }
  end;

end;

procedure TForm1.SendTextClick(Sender: TObject);
begin
 If MultiDoc1.ActiveObject is TfrChild then
   with MultiDoc1.ActiveObject as TfrChild do
      meText.lines.Add('Text from main form');
end;

procedure TForm1.BtnRestoreChildClick(Sender: TObject);
begin
  MultiDoc1.Maximized := not(MultiDoc1.Maximized); // or Maximized := False;
end;

procedure TForm1.ButtonsBarClickClose(Sender: TObject);
begin
 If MultiDoc1.ActiveObject is TfrChild then
    MultiDoc1.ActiveChild.Close;
  ButtonsBar.Visible := (MultiDoc1.ChildCount <> 0);
end;

procedure TForm1.ButtonsBarClickMaximize(Sender: TObject);
begin
 If MultiDoc1.ActiveObject is TfrChild then
  MultiDoc1.Maximized := not(MultiDoc1.Maximized);
end;

procedure TForm1.ButtonsBarClickMinimize(Sender: TObject);
begin
 If MultiDoc1.ActiveObject is TfrChild then
  //MultiDoc1.Maximized := not(MultiDoc1.Maximized);
  MulTiDoc1.ActiveChild.Maximized:=False;

  ButtonsBar.Visible:=False;
end;

procedure TForm1.BtnCloseChildClick(Sender: TObject);
begin
 ShowMessage('Min');

  If MultiDoc1.ActiveObject is TfrChild then
    MultiDoc1.ActiveChild.Close;
  ButtonsBar.Visible := (MultiDoc1.ChildCount <> 0);
end;

procedure TForm1.mCascadeClick(Sender: TObject);
begin
  MultiDoc1.Cascade;
end;

procedure TForm1.mTileHorClick(Sender: TObject);
begin
  MultiDoc1.TileHorizontal;
end;

procedure TForm1.mTileVerClick(Sender: TObject);
begin
  MultiDoc1.TileVertical;
end;

procedure TForm1.MultiDocActiveChildChange(Sender: TObject);
begin
  If MultiDoc1.ActiveChild <> nil then
    Caption := BaseCaption + ' - ' + MultiDoc1.ActiveChild.Caption else
      Caption := BaseCaption;
end;

procedure TForm1.MultiDocMaximize(Sender: TObject);
begin
 ButtonsBar.Visible := MultiDoc1.Maximized;
end;


initialization
  {$I demomultidoc1.lrs}

end.

