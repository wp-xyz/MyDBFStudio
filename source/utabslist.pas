unit uTabsList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Buttons;

type

  { TTabsList }

  TTabsList = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    lvTabs: TListView;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Procedure Load_Tabs;
  public
    { public declarations }
  end;

var
  TabsList: TTabsList;

implementation

Uses uMain, uTabForm, uDbfTable;

{$R *.lfm}

{ TTabsList }

procedure TTabsList.FormShow(Sender: TObject);
begin
 Load_Tabs;
end;

procedure TTabsList.BitBtn1Click(Sender: TObject);
begin
 Close;
end;

procedure TTabsList.BitBtn2Click(Sender: TObject);
 Var OldPos : Integer;
begin
 If lvTabs.Items.Count > 1 Then
  If lvTabs.Selected.Index > 0 Then
   Begin
    OldPos := lvTabs.Selected.Index;

    Main.WorkSite.Pages[OldPos].PageIndex := OldPos - 1;

    Load_Tabs;

    lvTabs.SetFocus;
    lvTabs.Items[OldPos - 1].Selected := True;
   end;
end;

procedure TTabsList.BitBtn3Click(Sender: TObject);
 Var OldPos : Integer;
begin
 If lvTabs.Items.Count > 1 Then
  If lvTabs.Selected.Index < lvTabs.Items.Count - 1 Then
   Begin
    OldPos := lvTabs.Selected.Index;

    Main.WorkSite.Pages[OldPos].PageIndex := OldPos + 1;

    Load_Tabs;

    lvTabs.SetFocus;
    lvTabs.Items[OldPos + 1].Selected := True;
   end;
end;

procedure TTabsList.BitBtn4Click(Sender: TObject);
begin
 If lvTabs.Selected <> Nil Then
  Begin
   Main.WorkSite.TabIndex := lvTabs.Selected.Index;

   Close;
  end;
end;

procedure TTabsList.BitBtn5Click(Sender: TObject);
begin
 If lvTabs.Selected <> Nil Then
  Begin
   Main.WorkSite.TabIndex := lvTabs.Selected.Index;

   Main.WorkSiteCloseTabClicked(Main.WorkSite.ActivePage);

   Load_Tabs;
  end;
end;

procedure TTabsList.Load_Tabs;
 Var Ind : Integer;
     Tmp : TForm;
     sFile : String;
begin
 lvTabs.BeginUpdate;

 lvTabs.Clear;

 If Main.WorkSite.PageCount > 0 Then
  For Ind := 0 To Main.WorkSite.PageCount - 1 Do
   Begin
    lvTabs.Items.Add;

    lvTabs.Items.Item[Ind].Caption := IntToStr(Ind + 1);

    lvTabs.Items.Item[Ind].SubItems.Add(Main.WorkSite.Pages[Ind].Caption);

    sFile := '';

    If (Main.WorkSite.Pages[Ind] Is TTabForm) Then
     Begin
      Tmp := (Main.WorkSite.Pages[Ind] As TTabForm).ParentForm;

      If (Tmp Is TDbfTable) Then
       With (Tmp As TDbfTable) Do
        sFile := DBTable.FilePathFull + DBTable.TableName;
     end;

    lvTabs.Items.Item[Ind].SubItems.Add(sFile);
   end;

 lvTabs.EndUpdate;
end;

end.

