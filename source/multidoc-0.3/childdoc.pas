{
  Copyright (C) 2007 Patrick Chevalley

  Contributors:
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
  TChildDoc: The Panel that to simulate child form.

ToDo List:
  + Test CLX Compatibility (in Delphi7 CLX work. Must be tested in Kylix)

Know Issues:
  - ???

Enjoy, is OpenSource =)
}
unit ChildDoc;

{$I defines.inc}

interface

uses
  {$IFDEF FPC}
    LResources, Graphics, Menus, Buttons, Controls, StdCtrls, ExtCtrls, Forms,
  {$ELSE}
    {$IFDEF DK_CLX} // Not tested in Kylix
    QGraphics, QMenus, QButtons, QControls, QStdCtrls, QExtCtrls, QForms,
    {$ELSE}
    Graphics, Menus, Buttons, Controls, StdCtrls, ExtCtrls, Forms,
    {$ENDIF}
  {$ENDIF}
  Classes, SysUtils, Dialogs, FormPanel;

{
   TChildDoc
   The "child form" component.
   This is a TFormPanel (see FormPanel unit) descendant that emulate a child
   form with sizeable border and buttonsbar (see buttonsbar and titlebar units).
   Use: See TMultiDoc in MultiDoc unit.
}

type
  
  TChildDoc = class(TFormPanel)
  private
    FDockedObject: TForm;
    FDockedPanel: TPanel;
    FCaption: TCaption;
    FCanClose, FMaximized,FIconized: Boolean;
    SavedLeft, SavedTop, SavedHeight, SavedWidth,
    InitialWidth, InitialHeight: Integer;
    FOnCaptionChange, FOnClose, FOnCloseX, FOnMaximize, FOnRestore: TNotifyEvent;
    FOnCloseQuery: TCloseQueryEvent;
    procedure SetCaption(AValue: TCaption);
    procedure SetDockedPanel(AValue: TPanel);
    procedure SetMaximized(AValue: Boolean);
    procedure ChildCloseClick(Sender: TObject);
    procedure ChildMaximizeClick(Sender: TObject);
    procedure Maximize;
    procedure Restore;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Close;
    procedure RestoreSize;
    property CanClose: Boolean read FCanClose write FCanClose;
    property OnMaximize: TNotifyEvent read FOnMaximize write FOnMaximize;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
    property OnCloseQuery : TCloseQueryEvent read FOnCloseQuery
             write FOnCloseQuery;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnCloseX: TNotifyEvent read FOnCloseX write FOnCloseX;
    property OnCaptionChange: TNotifyEvent read FOnCaptionChange
             write FOnCaptionChange;
  published
    property DockedObject: TForm read FDockedObject;
    property DockedPanel: TPanel read FDockedPanel write SetDockedPanel;
    property Caption: TCaption read FCaption write SetCaption;
    property Maximized: Boolean read FMaximized write SetMaximized;
    Property Iconized : Boolean Read FIconized Write FIconized;
  end;

implementation

{-}
constructor TChildDoc.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  FDockedObject := nil;
  FDockedPanel := nil;
  CanClose := True;
  ParentColor := False;
  Color := clBtnFace; // Parent MultiDoc.Color isn't clBtnFace
  TitleBar.OnClickClose    := {$IFDEF FPC}@{$ENDIF}ChildCloseClick;
  TitleBar.OnClickMaximize := {$IFDEF FPC}@{$ENDIF}ChildMaximizeClick;
  TitleBar.OnDblClick      := {$IFDEF FPC}@{$ENDIF}ChildMaximizeClick;
end;

{-}
destructor TChildDoc.Destroy;
begin
  try
    Inherited Destroy;
  except
    // Any Error Message?
  end;
end;

{-}
procedure TChildDoc.SetDockedPanel(AValue: TPanel);
begin
  If FDockedObject <> nil then
    FDockedObject.Free;
  FDockedObject := TForm(AValue.Parent);
  FDockedObject.Hide;
  FDockedPanel := AValue;
  FDockedPanel.BevelInner := bvNone;
  FDockedPanel.BevelOuter := bvNone;
  FDockedPanel.Parent := ClientArea;
  Height := TitleBar.Height + FDockedPanel.Height;
  Width := FDockedPanel.Width;
  SavedTop := Top;
  SavedLeft := Left;
  SavedWidth := Width + MG + MG;
  SavedHeight := Height + MG + MG;
  InitialWidth := SavedWidth;
  InitialHeight := SavedHeight;
  If FMaximized = False then
  begin
    ClientWidth := InitialWidth;
    ClientHeight := InitialHeight;
  end;
  FDockedPanel.Align := alClient;
  Caption := FDockedPanel.Caption;
  Self.Show;
end;

{-}
procedure TChildDoc.SetCaption(AValue: TCaption);
begin
  If (AValue <> FCaption) then
  begin
    FCaption := AValue;
    TitleBar.Caption := FCaption;
    If Assigned(FOnCaptionChange) then FOnCaptionChange(Self);
  end;
end;

{-}
procedure TChildDoc.Close;
begin
  If Assigned(OnCloseQuery) then FOnCloseQuery(Self, FCanClose);
  If (CanClose = True) then
  begin
    If Assigned(FOnCloseX) then FOnCloseX(Self); // Used for some parent
    If Assigned(FOnClose) then FOnClose(Self);   // Used for final programmer
  end;
end;

{-}
procedure TChildDoc.ChildCloseClick(Sender: TObject);
begin
  Self.Close;
end;

{-}
procedure TChildDoc.Maximize;
begin
  FMaximized := True;
  SavedTop := Top;
  SavedLeft := Left;
  SavedWidth := Width;
  SavedHeight := Height;
  BevelInner := bvNone;
  BevelOuter := bvNone;
  Align := alClient;
  TopPanel.Visible := not(FMaximized);
  UpdateClientArea;
  LockResize := True;
  If Assigned(FOnMaximize) then FOnMaximize(Self);
end;

{-}
procedure TChildDoc.Restore;
begin
  FMaximized := False;
  Align := alNone;
  Top := SavedTop;
  Left := SavedLeft;
  Width := SavedWidth;
  Height := SavedHeight;
  BevelInner := bvRaised;
  BevelOuter := bvRaised;
  TopPanel.Visible := not(FMaximized);
  UpdateClientArea;
  LockResize := False;
  If Assigned(FOnRestore) then FOnRestore(Self);
end;

{-}
procedure TChildDoc.RestoreSize;
begin
 Restore;

 Width := InitialWidth;
 Height := InitialHeight;
end;

{-}
procedure TChildDoc.SetMaximized(AValue: Boolean);
begin
  If FMaximized <> AValue then
    begin
      FMaximized := AValue;
      If FMaximized = True then
        Maximize else
          Restore;
    end;
end;

{-}
procedure TChildDoc.ChildMaximizeClick(Sender: TObject);
begin
  Maximized := True;
end;

initialization
// Without Resources Yet

end.
