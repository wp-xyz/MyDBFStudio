{
  Copyright (C) 2007 Patrick Chevalley

  Júnior Gonçalves <hipernetjr@yahoo.com.br> - (MultiDoc v0.3 - April/Dec 2007)
               <http://lazaruspascal.codigolivre.org.br/portal.php>
                    <http://geocities.yahoo.com.br/hipernetjr>

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

Author: Patrick Chevalley

Contributors:
    Júnior Gonçalves (Curitiba/Pr - Brazil) - <hipernetjr@yahoo.com.br>
        <http://lazaruspascal.codigolivre.org.br/portal.php>
            <http://geocities.yahoo.com.br/hipernetjr>

Abstract:
  TMultiDoc: The container to childdocs, or "childforms".

ToDo List:
  + Test CLX Compatibility (in Delphi7 CLX work. Must be tested in Kylix)
  + Minimize Method
  + Adjust, in "Minimized Mode", to ShowPopup if has clicked in TitleBar

Know Issues:
  - ???

Warning(s):
  * You don't should NEVER to use 'MultiDocX.Childs[X].Free;' "directly"
    Use MultiDocX.Childs[X].Close, so MultiDoc can recalculate ChildIndex

Enjoy, is OpenSource =)
}
unit MultiDoc;

{$I defines.inc}

interface

uses
  {$IFDEF FPC}
    LResources,
    Graphics, Menus, Buttons, Controls, StdCtrls, ExtCtrls, Forms,
  {$ELSE}
    {$IFDEF DK_CLX} // Not tested in Kylix!
    QGraphics, QMenus, QButtons, QControls, QStdCtrls, QExtCtrls, QForms,
    {$ELSE}
    Graphics, Menus, Buttons, Controls, StdCtrls, ExtCtrls, Forms,
    {$ENDIF}
  {$ENDIF}
  Types, Classes, SysUtils, Dialogs, ButtonsBar, ChildDoc, FormPanel;

type

  ChildArray = array of TChildDoc;

{
   TMultiDoc
   The docking area for a TChildDoc component.

   Use:
   Create a child form with a main TPanel.
   Put all the object you want for the child to the panel, write the event, etc...
   Do not rely on TForm event as this form is never show.
   On the application main form place a TMultiDoc
   At run time:
   Create a new child from TMultiDoc.NewChild
   Create a child form with the new childdoc as owner.
   Assign the main panel to the Dockedpanel property.

   Replace the standard MDI function as below:
   MDIChildCount   -> MultiDoc1.ChildCount
   ActiveMdiChild  -> MultiDoc1.ActiveObject
                   or MultiDoc1.ActiveChild
   MDIChildren[i]  -> MultiDoc1.Childs[i].DockedObject
                   or MultiDoc1.Childs[i]
}

  TMultiDoc = class(TScrollBox)
  private
    FChildIndex, FActiveChild: Integer;
    FMaximized, FKeepLastChild, FWireFrameMoveResize: Boolean;
    FOnActiveChildChange, FOnBeforeMaximize, FOnBeforeRestore,
    FOnMaximize, FOnRestore, FOnResize: TNotifyEvent;
    FChild: ChildArray;
    FWindowList: TMenuItem;
    FWindowListOffSet: Integer;
    DefaultPos: TPoint;
    function GetActiveChild: TChildDoc;
    function GetActiveObject: TForm;
    function GetChildCount: Integer;
    procedure CaptionChange(Sender: TObject);
    procedure ChildClose(Sender: TObject);
    procedure ChildMaximize(Sender: TObject);
    procedure ChildMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChildRestore(Sender: TObject);
    procedure FocusChildClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SetMaximized(AValue: Boolean);
    procedure SetResize(Sender: TObject);
    procedure SetWindowList(AValue: TMenuItem);
    procedure SetWireFrameMoveResize(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function NewChild: TChildDoc;
    procedure Cascade;
    procedure SetActiveChild(N: Integer);
    procedure TileVertical;
    procedure TileHorizontal;
    property ActiveChild: TChildDoc read GetActiveChild;
    property ActiveObject: TForm read GetActiveObject;
    property Childs: ChildArray read FChild;
  published
    property ChildCount: Integer read GetChildCount;
    property KeepLastChild: Boolean read FKeepLastChild write FKeepLastChild;
    property Maximized: Boolean read FMaximized write SetMaximized;
    property WindowList: TmenuItem read FWindowList write SetWindowList;
    property WireFrameMoveResize: Boolean read FWireFrameMoveResize
             write SetWireFrameMoveResize;
    property OnActiveChildChange: TNotifyEvent read FOnActiveChildChange
             write FOnActiveChildChange;
    property OnBeforeMaximize: TNotifyEvent read FOnBeforeMaximize
             write FOnBeforeMaximize;
    property OnBeforeRestore: TNotifyEvent read FOnBeforeRestore
             write FOnBeforeRestore;
    property OnMaximize: TNotifyEvent read FOnMaximize write FOnMaximize;
    property OnResize: TNotifyEvent read FOnResize write FOnResize;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

procedure Register;

implementation

{-}
procedure Register;
begin
  RegisterComponents('LMDI', [TMultiDoc]);
end;

{-}
constructor TMultiDoc.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  FChildIndex := -1;
  FActiveChild := -1;
  FWindowListOffset := 0;
  SetLength(FChild, 0);
  Align := alClient;
  AutoScroll := True;
  {$IFDEF WIN32}
  Color := clAppWorkSpace;
  {$ELSE}
  Color := $007C654E;
  {$ENDIF}
  DefaultPos := Point(0, 0);
  FOnResize := nil;
  Inherited OnResize := {$IFDEF FPC}@{$ENDIF}SetResize;
end;

{-}
destructor  TMultiDoc.Destroy;
begin
  try
    FActiveChild := -1;
    Inherited Destroy;
  except
    // Some Error Message?
  end;
end;

{-}
function TMultiDoc.NewChild: TChildDoc;
var
  MenuChild: TMenuItem;
begin
  Inc(FChildIndex);
  SetLength(FChild, FChildIndex + 1);
  FChild[FChildIndex] := TChildDoc.Create(Self);

  with FChild[FChildIndex] do
  begin
    Hide;
    Parent := Self;
    WireFrameMoveResize := FWireFrameMoveResize;
    OnCloseX        := {$IFDEF FPC}@{$ENDIF}ChildClose;
    OnMaximize      := {$IFDEF FPC}@{$ENDIF}ChildMaximize;
    OnMouseDown     := {$IFDEF FPC}@{$ENDIF}ChildMouseDown;
    OnRestore       := {$IFDEF FPC}@{$ENDIF}ChildRestore;
    OnCaptionChange := {$IFDEF FPC}@{$ENDIF}CaptionChange;
    OnCloseQuery    := {$IFDEF FPC}@{$ENDIF}FormCloseQuery;
    Tag := FChildIndex;
    Top := DefaultPos.Y - Self.VertScrollBar.Position;
    Left := DefaultPos.X - Self.HorzScrollBar.Position;
    Self.VertScrollBar.Position := 0;
    Self.HorzScrollBar.Position := 0;
    FActiveChild := FChildIndex;
    If Assigned(FWindowList) then
    begin
      MenuChild := TMenuItem.Create(Self);
      MenuChild.Caption := 'Child ' + IntToStr(FChildIndex);
      MenuChild.Tag := 100 + FChildIndex;
      MenuChild.OnClick := {$IFDEF FPC}@{$ENDIF}FocusChildClick;
      FWindowList.Add(MenuChild);
    end;
    Maximized := FMaximized;
    SetActiveChild(FChildIndex);
    with TitleBar do
    begin
      DefaultPos.X := DefaultPos.X + Height + MG;
      DefaultPos.Y := DefaultPos.Y + Height + MG;
      If (DefaultPos.Y > (10 * (Height + MG))) then
      begin
        DefaultPos.Y := 0;
        If (DefaultPos.X > (20 * (Height + MG))) then
          DefaultPos.X := 0;
      end;
    end;
    Result := FChild[FChildIndex];
  end;
end;

{-}
procedure TMultiDoc.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not(KeepLastChild and (ChildCount = 1));
end;

{-}
function TMultiDoc.GetActiveChild: TChildDoc;
begin
  If FActiveChild >= 0 then
    Result := FChild[FActiveChild] else
      Result := nil;
end;

{-}
function TMultiDoc.GetActiveObject: TForm;
begin
  If FActiveChild >= 0 then
    Result := FChild[FActiveChild].DockedObject else
      Result := nil;
end;

{-}
function TMultiDoc.GetChildCount: Integer;
begin
  Result := FChildIndex + 1;
end;

{-}
procedure TMultiDoc.CaptionChange(Sender: TObject);
var
  I, N: Integer;
begin
  N := (Sender as TChildDoc).Tag + 100;
  If Assigned(FWindowList) then
    for I := 0 to FWindowList.Count - 1 do
      If FWindowList.Items[I].Tag = N then
      begin
        FWindowList.Items[I].Caption := (Sender as TChildDoc).Caption;
        break;
      end;
end;

{-}
procedure TMultiDoc.ChildClose(Sender: TObject);
var
  I, J, N: Integer;
begin
  N := (Sender as TChildDoc).Tag;
  If Assigned(FWindowList) then
  begin
    J := FWindowList.Count;
    for I := 0 to FWindowList.Count - 1 do
    If FWindowList.Items[I].Tag = (100 + N) then
    begin
      FWindowList.Delete(I);
      J := I;
      break;
    end;
    for I := J to FWindowList.Count - 1 do
      FWindowList.Items[I].Tag := FWindowList.Items[I].Tag - 1;
  end;
  for I := N to FChildIndex - 1 do
  begin
    FChild[I] := FChild[I + 1];
    FChild[I].Tag := I;
  end;
  Dec(FChildIndex);
  SetLength(FChild, FChildIndex + 1);
  SetActiveChild(FChildIndex);
  TChildDoc(Sender).Free;
  TChildDoc(Sender) := nil;
end;

{-}
procedure TMultiDoc.ChildMaximize(Sender: TObject);
var
  I: Integer;
begin
  If Assigned(FOnBeforeMaximize) then FOnBeforeMaximize(Self);
  AutoScroll := False;
  BorderStyle := bsNone;

  for I := 0 to FChildIndex do
    FChild[I].Maximized := True;

  FMaximized := True;
  If Assigned(FOnMaximize) then FOnMaximize(Self);
end;

{-}
procedure TMultiDoc.ChildMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  SetActiveChild((Sender as TComponent).Tag);
end;

{-}
procedure TMultiDoc.ChildRestore(Sender: TObject);
var
  I: Integer;
begin
  If Assigned(FOnBeforeRestore) then FOnBeforeRestore(Self);
  for I := 0 to FChildIndex do
    FChild[I].Maximized := False;

  FMaximized := False;
  If Assigned(FOnRestore) then FOnRestore(Self);
  AutoScroll := True;
  BorderStyle := bsSingle;
end;

{-}
procedure TMultiDoc.SetMaximized(AValue: Boolean);
var
  I: Integer;
begin
  If (AValue <> FMaximized) then
  begin
    FMaximized := AValue;
    for I := 0 to FChildIndex do
      FChild[I].Maximized := FMaximized;
    If Assigned(FOnMaximize) then FOnMaximize(Self);
  end;
end;

{-}
procedure TMultiDoc.SetActiveChild(N: Integer);
var
  I: Integer;
begin
  try
    If ((Parent <> nil) and (Parent.Visible) and (N >= 0)) then
    begin
      FChild[N].BringToFront;
      FChild[N].WireFrame.BringToFront;
    end;
  except
    // Some Error Message?
  end;
  FActiveChild := N;
  for I := 0 to FChildIndex do
    If FChild[I] <> nil then
    begin
      // All others "Childs.TitleBar" are disabled
      FChild[I].TitleBar.Inactive := (I <> N);
      // ON/OFF "lock TAB key" and "inactive child windows" get focus with Click
      FChild[I].ClientArea.Enabled := (I = N);
    end;
  If Assigned(FOnActiveChildChange) then FOnActiveChildChange(Self);
end;

{-}
procedure TMultiDoc.FocusChildClick(Sender: TObject);
begin
  SetActiveChild((Sender as TMenuItem).Tag - 100);
end;

{-}
procedure TMultiDoc.SetWireFrameMoveResize(AValue: Boolean);
var
  I: Integer;
begin
  FWireFrameMoveResize := AValue;
  for I := 0 to FChildIndex do
    FChild[I].WireFrameMoveResize := FWireFrameMoveResize;
end;

{-}
procedure TMultiDoc.SetWindowList(AValue: TMenuItem);
begin
  FWindowList := AValue;
  FWindowListOffSet := FWindowList.Count;
end;

{-}
procedure TMultiDoc.SetResize(Sender: TObject);
var
  I: Integer;
begin
  If Maximized = True then
    for I := 0 to FChildIndex do
    begin
      FChild[I].Width := ClientWidth;
      FChild[I].Height := ClientHeight;
    end;
  If Assigned(FOnResize) then FOnResize(Sender);
end;

{-}
procedure TMultiDoc.Cascade;
var
  I: Integer;
begin
  Maximized := False;
  If ChildCount > 0 then
  begin
    DefaultPos.X := 0;
    DefaultPos.Y := 0;
    for I := 0 to FChildIndex do
      with FChild[I].TitleBar do
      begin
        FChild[I].RestoreSize;
        FChild[I].Left := DefaultPos.X - Self.VertScrollBar.Position;
        FChild[I].Top := DefaultPos.Y - Self.HorzScrollBar.Position;
        FChild[I].BringToFront;
        DefaultPos.X := DefaultPos.X + Height + MG;
        DefaultPos.Y := DefaultPos.Y + Height + MG;
        If (DefaultPos.Y > (10 * (Height + MG))) then
        begin
          DefaultPos.Y := 0;
          If (DefaultPos.X > (20 * (Height + MG))) then
            DefaultPos.X := 0;
        end;
      end;
    SetActiveChild(FChildIndex);
  end;
end;

{-}
procedure TMultiDoc.TileVertical;
var
  I, J, N, DX, DY, NX, NY, X, Y: Integer;
  D: Double;
begin
  Maximized := False;
  If ChildCount > 0 then
  begin
    AutoScroll := False;
    D := Round(100 * SQRT(FChildIndex + 1)) / 100;
    NY := Trunc(D);
    If Frac(D) = 0 then NX := NY else
      If Frac(D) < 0.5 then NX := NY + 1 else
      begin
        NY := NY + 1;
        NX := NY;
      end;
    DX := ClientWidth div NX;
    DY := ClientHeight div NY;
    for I := 0 to NX - 1 do
    begin
      for J := 0 to NY - 1 do
      begin
        X := I * DX;
        Y := J * DY;
        N := I * NY + J;
        If N < FChildIndex then
        begin
          FChild[N].Top := Y;
          FChild[N].Left := X;
          FChild[N].Width := DX;
          FChild[N].Height := DY;
        end;
        If N = FChildIndex then
        begin
          FChild[N].Top := Y;
          FChild[N].Left := X;
          FChild[N].Width := DX;
          FChild[N].Height := ClientHeight - Y;
        end;
      end;
    end;
    AutoScroll := True;
  end;
end;

{-}
procedure TMultiDoc.TileHorizontal;
var
  I, J, N, DX, DY, NX, NY, X, Y: Integer;
  D: Double;
begin
  Maximized := False;
  If ChildCount > 0 then
  begin
    AutoScroll := False;
    D := Round(100 * SQRT(FChildIndex + 1)) / 100;
    NX := Trunc(D);
    If Frac(D) = 0 then NY := NX else
      If Frac(D) < 0.5 then NY := NX + 1 else
      begin
        NX := NX + 1;
        NY := NX;
      end;
    DX := ClientWidth div NX;
    DY := ClientHeight div NY;
    for I := 0 to NY - 1 do
    begin
      for J := 0 to NX - 1 do
      begin
        X := J * DX;
        Y := I * DY;
        N := I * NX + J;
        If N < FChildIndex then
        begin
          FChild[N].Top := Y;
          FChild[N].Left := X;
          FChild[N].Width := DX;
          FChild[N].Height := DY;
        end;
        If N = FChildIndex then
        begin
          FChild[N].Top := Y;
          FChild[N].Left := X;
          FChild[N].Width := ClientWidth - X;
          FChild[N].Height := DY;
        end;
      end;
    end;
    AutoScroll := True;
  end;
end;

initialization
  {$IFDEF FPC}
    {$I multidoc.lrs}
  {$ELSE}
    {$R multidoc.res}
  {$ENDIF}

end.

