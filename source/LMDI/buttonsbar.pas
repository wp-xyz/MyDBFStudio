{

                                ButtonBar.pas
                            --------------------
                               The LMDI Suite
              First Release: March 2006 (2006-03-16) - (TMDButtonsBar)
             Last Release: December 2007 (2007-12-28) - (The LMDI Suite)

 *****************************************************************************
 *                                                                           *
 *  This file is part of the LMDI Suite                                      *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

Author: Júnior Gonçalves (Curitiba/Pr - Brazil) - <hipernetjr@yahoo.com.br>
	<http://lazaruspascal.codigolivre.org.br/portal.php>
            <http://geocities.yahoo.com.br/hipernetjr>

Abstract:
  TPanelSenderMouseEvents: TPanel to send Mouse events to "ControlToGetEvents"
  TButtonsBar: A Buttons Bar to simulate Title bar of O.S specific.

ToDo List:
  + Test CLX Compatibility (in Delphi7 CLX work. Must be tested in Kylix)
  + More Style Buttons (KDE, WinXP-MDI...)

Know Issues:
  Delphi:
  - Some Problems in Delphi®, because Delphi® TImage don't have OnMouseLeave =\
    By whiling, the buttons in delphi are updated in MouseMove Procedure
    ToDo: Add an method to update the images.

Enjoy, is OpenSource =)
}
unit buttonsbar;

{$I defines.inc}

interface

uses
  {$IFDEF FPC}
    LResources,
    Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  {$ELSE}
    {$IFDEF DK_CLX} // Not tested in Kylix
    QForms, QControls, QGraphics, QDialogs, QExtCtrls, QStdCtrls,
    {$ELSE}
    Windows, Messages, // used in Mouse Events to send Mouse Messages
    Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
    {$ENDIF}
  {$ENDIF}
  Classes, SysUtils, Types;

const
  // Button's State (Used in Tags properties... to LoadBitmap from Skin)
  bsDown = 0;
  bsUp = 1;
  bsActive = 2;
  // Button's Number (Used to set Tags properties and load bitmaps)
  bnClose = 0;
  bnMaximize = 1;
  bnRestore = 2;
  bnMinimize = 3;
  bnHelp = 4;

  {$IFNDEF FPC}
  LineEnding = #13#10;
  {$ENDIF}

type

  TVisibleButtons = Set of (vbClose, vbHelp, vbMaximize, vbMinimize);
  TStyle = (stGnome, stMacOS, stWaterColorBlue, stWin9x, stWinXPBlue);
  TStyleBar = (sbMaximize, sbMDIMinimized, sbRestore);

var
  TStyleStr: array[0 .. 4] of String =
  ('GNOME', 'MACOS', 'WATERCOLORBLUE', 'WIN9X', 'WINXPBLUE');

type

  { TPanelSenderMouseEvents }
  TPanelSenderMouseEvents = class(TPanel)
  protected
    FSendMouseEvents: Boolean;
    FControlToGetMouseEvents: TControl;
    {$IFDEF DK_CLX}
    WasCreated: Boolean;
    // Create an "CreateWnd false" method to CLX (virtual to override)
    procedure CreateWnd; virtual;
    procedure Paint; override; // Paint method will trigger "false CreateWnd"
    {$ELSE} // CLX do not support Messages (this should be do manually)
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure DblClick; override;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ControlToGetMouseEvents: TControl read FControlToGetMouseEvents
             write FControlToGetMouseEvents;
    property SendMouseEvents: Boolean read FSendMouseEvents
             write FSendMouseEvents default False;
  end;

  { TButtonsBar }
  TButtonsBar = class(TPanelSenderMouseEvents)
    procedure MenuMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MenuMouseUp(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuMouseLeave(Sender: TObject);
  protected
    FAutoConstraints, StateDown: Boolean;
    FBitmapSkin: TBitmap;
    FTransparentColor: TColor;
    MenuClose, MenuHelp, MenuMaximize, MenuMinimize: TImage;
    FMarginClose, FMarginMaximize, FMarginMinimize, FMarginHelp: Integer;
    FHints: TStrings;
    FVisibleButtons: TVisibleButtons;
    FStyle: TStyle;
    FStyleBar: TStyleBar;
    FOnChangeStatus, FOnClickClose, FOnClickHelp, FOnClickMinimize,
    FOnClickMaximize, FOnClickRestore: TNotifyEvent;
    procedure CreateWnd; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  private
    procedure LoadBitmap(Image: TImage; State: Word);
    procedure LoadStyle(StyleStr: String);
    procedure LoadResource(Bitmap: TBitmap; ResourceStr: String);
    procedure SetAutoConstraints(const AValue: Boolean);
    procedure SetBitmapSkin(const AValue: TBitmap);
    procedure SetMarginClose(const AValue: Integer);
    procedure SetMarginHelp(const AValue: Integer);
    procedure SetMarginMaximize(const AValue: Integer);
    procedure SetMarginMinimize(const AValue: Integer);
    procedure SetHints(const AValue: TStrings);
    procedure SetStyle(const AValue: TStyle);
    procedure SetStyleBar(const AValue: TStyleBar);
    procedure SetTransparentColor(const AValue: TColor);
    procedure SetVisibleButtons(const AValue: TVisibleButtons);
    procedure UpdateButtons;
    procedure UpdateHints;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property OnChangeStatus: TNotifyEvent read FOnChangeStatus write FOnChangeStatus;
  published
    property Align default alTop;
    property AutoConstraints: Boolean read FAutoConstraints
             write SetAutoConstraints default True;
    property BevelOuter default bvNone;
    property BitmapSkin: TBitmap read FBitmapSkin write SetBitmapSkin;
    {$IFNDEF DK_CLX}
    property DoubleBuffered default True;
    {$ENDIF}
    property Hints: TStrings read FHints write SetHints;
    property MarginClose: Integer read FMarginClose
             write SetMarginClose default 2;
    property MarginHelp: Integer read FMarginHelp write SetMarginHelp default 2;
    property MarginMaximize: Integer read FMarginMaximize
             write SetMarginMaximize default 2;
    property MarginMinimize: Integer read FMarginMinimize
             write SetMarginMinimize default 0;
    property ShowHint default True;
    property Style: TStyle read FStyle write SetStyle default stWin9x;
    property StyleBar: TStyleBar read FStyleBar write SetStyleBar
             default sbMaximize;
    property TransparentColor: TColor read FTransparentColor
             write SetTransparentColor default clFuchsia;
    property VisibleButtons: TVisibleButtons read FVisibleButtons
             write SetVisibleButtons default [vbClose, vbMaximize, vbMinimize];
    property OnClickClose: TNotifyEvent read FOnClickClose write FOnClickClose;
    property OnClickHelp: TNotifyEvent read FOnClickHelp write FOnClickHelp;
    property OnClickMinimize: TNotifyEvent read FOnClickMinimize
             write FOnClickMinimize;
    property OnClickMaximize: TNotifyEvent read FOnClickMaximize
             write FOnClickMaximize;
    property OnClickRestore: TNotifyEvent read FOnClickRestore
             write FOnClickRestore;
  end;

procedure Register;

implementation

{-}
procedure Register;
begin
  RegisterComponents('LMDI', [TButtonsBar]);
end;

{ TPanelSenderMouseEvents }

{-}
constructor TPanelSenderMouseEvents.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  ControlToGetMouseEvents := (Parent as TWinControl);
  {$IFDEF DK_CLX}
    WasCreated := True;
  {$ENDIF}
end;

{$IFDEF DK_CLX}
{-}
procedure TPanelSenderMouseEvents.CreateWnd;
begin
  // Do Nothing. Override this procedure
end;

{-}
procedure TPanelSenderMouseEvents.Paint;
begin
  Inherited Paint;
  If WasCreated = True then
  begin
    WasCreated := False;
    CreateWnd;
  end;
end;
{$ELSE}

{-}
procedure TPanelSenderMouseEvents.DblClick;
begin
  Inherited DblClick;
  If ((FSendMouseEvents = True) and (FControlToGetMouseEvents <> nil)) then
  begin
    with FControlToGetMouseEvents do
    {$IFDEF FPC}
      DblClick;
    {$ELSE}
      Perform(WM_LBUTTONDBLCLK, 0, 0);
    {$ENDIF}
  end;
end;

{-}
procedure TPanelSenderMouseEvents.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Inherited MouseDown(Button, Shift, X, Y);
  If ((FSendMouseEvents = True) and (FControlToGetMouseEvents <> nil)) then
  begin
    X := ClientOrigin.X - FControlToGetMouseEvents.ClientOrigin.X + X;
    Y := ClientOrigin.Y - FControlToGetMouseEvents.ClientOrigin.Y + Y;
    with FControlToGetMouseEvents do
    {$IFDEF FPC}
      MouseDown(Button, Shift, X, Y);
    {$ELSE}
      If Button = mbLeft then
        Perform(WM_LBUTTONDOWN, 0, MakeLong(X, Y)) else
        If Button = mbRight then
          Perform(WM_RBUTTONDOWN, 0, MakeLong(X, Y));
    {$ENDIF}
  end;
end;

{-}
procedure TPanelSenderMouseEvents.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  Inherited MouseMove(Shift, X, Y);
  If ((FSendMouseEvents = True) and (FControlToGetMouseEvents <> nil)) then
  begin
    X := ClientOrigin.X - FControlToGetMouseEvents.ClientOrigin.X + X;
    Y := ClientOrigin.Y - FControlToGetMouseEvents.ClientOrigin.Y + Y;
    with FControlToGetMouseEvents do
    {$IFDEF FPC}
      MouseMove(Shift, X, Y);
    {$ELSE}
      Perform(WM_MOUSEMOVE, 0, MakeLong(X, Y));
    {$ENDIF}
  end;
end;

{-}
procedure TPanelSenderMouseEvents.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Inherited MouseUp(Button, Shift, X, Y);
  If ((FSendMouseEvents = True) and (FControlToGetMouseEvents <> nil)) then
  begin
    X := ClientOrigin.X - FControlToGetMouseEvents.ClientOrigin.X + X;
    Y := ClientOrigin.Y - FControlToGetMouseEvents.ClientOrigin.Y + Y;
    with FControlToGetMouseEvents do
    {$IFDEF FPC}
      MouseUp(Button, Shift, X, Y);
    {$ELSE}
      If Button = mbLeft then
        Perform(WM_LBUTTONUP, 0, MakeLong(X, Y)) else
          Perform(WM_RBUTTONUP, 0, MakeLong(X, Y));
    {$ENDIF}
  end;
end;
{$ENDIF}

{ TButtonsBar }

{-}
constructor TButtonsBar.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);

  // Define inheriteds properties
  Align := alTop;
  BevelOuter := bvNone;
  {$IFNDEF DK_CLX} // CLX don't have DoubleBuffered property
  DoubleBuffered := True;
  {$ENDIF}
  ShowHint := True;

  // Create Images
  MenuClose := TImage.Create(nil);
  MenuHelp := TImage.Create(nil);
  MenuMaximize := TImage.Create(nil);
  MenuMinimize := TImage.Create(nil);
  MenuClose.Parent := Self;
  MenuHelp.Parent := Self;
  MenuMaximize.Parent := Self;
  MenuMinimize.Parent := Self;

  // Define custom properties
  FAutoConstraints := True;
  FBitmapSkin := TBitmap.Create;
  FBitmapSkin.Transparent := True;
  FBitmapSkin.TransparentColor := clFuchsia;
  FHints := TStringList.Create;
  FHints.Text := 'Close' + LineEnding +
                 'Maximize' + LineEnding +
                 'Restore to down|Restore to up' + LineEnding +
                 'Minimize' + LineEnding +
                 'Help';
  FMarginClose := 2;
  FMarginHelp := 2;
  FMarginMaximize := 2;
  FMarginMinimize := 0;
  FStyle := stWin9x;
  FVisibleButtons := [vbClose, vbMaximize, vbMinimize];
  FTransparentColor := clFuchsia;
  LoadStyle('Win9x');

  // Define Image properties
  with MenuClose do
  begin
    Anchors := [akTop, akRight];
    Picture.Bitmap.Create;
    Tag := bnClose;
    Top := 2;
    Transparent := True;
    Visible := (vbClose in FVisibleButtons);
    OnMouseDown  := {$IFDEF FPC}@{$ENDIF}MenuMouseDown;
    OnMouseMove  := {$IFDEF FPC}@{$ENDIF}MenuMouseMove;
    OnMouseUp    := {$IFDEF FPC}@{$ENDIF}MenuMouseUp;
    {$IFDEF FPC}
    OnMouseLeave := {$IFDEF FPC}@{$ENDIF}MenuMouseLeave;
    {$ENDIF}
  end;

  with MenuHelp do
  begin
    Anchors := [akTop, akRight];
    Tag := bnHelp;
    Top := 2;
    Transparent := True;
    Visible := (vbHelp in FVisibleButtons);
    OnMouseDown  := {$IFDEF FPC}@{$ENDIF}MenuMouseDown;
    OnMouseMove  := {$IFDEF FPC}@{$ENDIF}MenuMouseMove;
    OnMouseUp    := {$IFDEF FPC}@{$ENDIF}MenuMouseUp;
    {$IFDEF FPC}
    OnMouseLeave := {$IFDEF FPC}@{$ENDIF}MenuMouseLeave;
    {$ENDIF}
  end;

  with MenuMaximize do
  begin
    Anchors := [akTop, akRight];
    Tag := bnMaximize;
    Top := 2;
    Transparent := True;
    Width := Picture.Bitmap.Width;
    OnMouseDown  := {$IFDEF FPC}@{$ENDIF}MenuMouseDown;
    OnMouseMove  := {$IFDEF FPC}@{$ENDIF}MenuMouseMove;
    OnMouseUp    := {$IFDEF FPC}@{$ENDIF}MenuMouseUp;
    {$IFDEF FPC}
    OnMouseLeave := {$IFDEF FPC}@{$ENDIF}MenuMouseLeave;
    {$ENDIF}
  end;

  with MenuMinimize do
  begin
    Anchors := [akTop, akRight];
    Tag := bnMinimize;
    Top := 2;
    Transparent := True;
    Visible := (vbMinimize in FVisibleButtons);
    OnMouseDown  := {$IFDEF FPC}@{$ENDIF}MenuMouseDown;
    OnMouseMove  := {$IFDEF FPC}@{$ENDIF}MenuMouseMove;
    OnMouseUp    := {$IFDEF FPC}@{$ENDIF}MenuMouseUp;
    {$IFDEF FPC}
    OnMouseLeave := {$IFDEF FPC}@{$ENDIF}MenuMouseLeave;
    {$ENDIF}
  end;

  UpdateButtons; // Keep it. This define Self.Height and Self.Width in Creation.
end;

{-}
destructor TButtonsBar.Destroy;
begin
  FreeAndNil(FBitmapSkin);
  FreeAndNil(FHints);
  FreeAndNil(MenuClose);
  FreeAndNil(MenuHelp);
  FreeAndNil(MenuMaximize);
  FreeAndNil(MenuMinimize);
  Inherited Destroy;
end;

{-}
procedure TButtonsBar.CreateWnd;
begin
  Inherited CreateWnd;
  Caption := '';
  MenuClose.BringToFront;
  MenuHelp.BringToFront;
  MenuMaximize.BringToFront;
  MenuMinimize.BringToFront;
  UpdateButtons;
  // Keep it. If Style is modified in Creation, buttons aren't updated again
  UpdateHints;
end;

{-}
procedure TButtonsBar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  Inherited MouseMove(Shift, X, Y);
  UpdateButtons;
end;

{ ----------------------------------------------------------------------------
  ButtonTag: 0 = Close | 1 = Maximize | 2 = Restore | 3 = Minimize | 4 = Help
  State:     0 = Down  | 1 = Up       | 2 = Active
  See constants and buttons tags properties before this procedure
  ---------------------------------------------------------------------------- }

{-}
procedure TButtonsBar.LoadBitmap(Image: TImage; State: Word);
var
  DRect, SRect: TRect;
  ButtonHeight, ButtonWidth, PH, PW, ButtonTag: Word;
begin
  ButtonTag := Image.Tag;
  If ButtonTag > 4 then ButtonTag := 4;
  If State > 2 then State := 2;

  ButtonHeight := FBitmapSkin.Height div 3;
  ButtonWidth := FBitmapSkin.Width div 5;
  PW := (ButtonWidth * (ButtonTag + 1)) - ButtonWidth;
  PH := (ButtonHeight * (State + 1)) - ButtonHeight;
  SRect := Rect(PW, PH, PW + ButtonWidth, PH + ButtonHeight);
  DRect := Rect(0, 0, ButtonWidth, ButtonHeight);

  with Image.Picture.Bitmap do
    begin
      Height := ButtonHeight - 1;
      Width := ButtonWidth - 1;
      TransparentColor := FTransparentColor;
      Canvas.CopyRect(DRect, FBitmapSkin.Canvas, SRect);
    end;

  Image.Height := Image.Picture.Bitmap.Height;
  Image.Width := Image.Picture.Bitmap.Width;
end;

{ ----------------------------------------------------------------------------
  This procedure load component resources
  If compiler is FPC then to load Lazarus Resources else...
  If compiler is Delphi then to load Win32 Resources (*.res)
  ---------------------------------------------------------------------------- }

{-}
procedure TButtonsBar.LoadResource(Bitmap: TBitmap; ResourceStr: String);
begin
  {$IFDEF FPC}
    Bitmap.LoadFromLazarusResource(ResourceStr);
  {$ELSE}
    Bitmap.LoadFromResourceName(hInstance, ResourceStr);
  {$ENDIF}
end;

{-}
procedure TButtonsBar.LoadStyle(StyleStr: String);
begin
  LoadResource(FBitmapSkin, StyleStr);
  If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
end;

{-}
procedure TButtonsBar.MenuMouseDown(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Self.MouseDown(mbRight{Temporary: Keep this!!!}, Shift, X, Y);
  If Button = mbLeft then
  begin
    LoadBitmap((Sender as TImage), bsDown);
    StateDown := True;
  end;
end;

{-}
procedure TButtonsBar.MenuMouseLeave(Sender: TObject);
begin
  LoadBitmap((Sender as TImage), bsUp);
end;

{-}
procedure TButtonsBar.MenuMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  SW, SH: Integer; // Sender.Width and Sender.Height
  Image: TImage;
begin
  Image := (Sender as TImage);
  If StateDown = True then
  with Image do
  begin
    SW := Image.Width;
    SH := Image.Height;
    If ((X >= 0) and (X < SW)) and ((Y >= 0) and (Y < SH)) then
      LoadBitmap(Image, bsDown) else
        LoadBitmap(Image, bsUp);
  end else LoadBitmap(Image, bsActive);
  {$IFNDEF FPC} // Delphi® 7 TImage don't have OnMouseLeave Event (Temporary)
    If Image <> MenuClose then LoadBitmap(MenuClose, bsUp);
    If Image <> MenuMaximize then LoadBitmap(MenuMaximize, bsUp);
    If Image <> MenuMinimize then LoadBitmap(MenuMinimize, bsUp);
    If Image <> MenuHelp then LoadBitmap(MenuHelp, bsUp);
  {$ENDIF}
end;

{-}
procedure TButtonsBar.MenuMouseUp(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  SW, SH: Integer; // Sender.Width and Sender.Height
begin
  If StateDown = True then
  begin
    SW := (Sender as TImage).Width;
    SH := (Sender as TImage).Height;

    // The code below make sure if has clicked inside buttons
    If ((X >= 0) and (X < SW)) and ((Y >= 0) and (Y < SH)) then
    begin
      // Load "Up Image" from Sender (TImage Component)
      LoadBitmap((Sender as TImage), bsUp);
      Case (Sender as TImage).Tag of
        bnClose:    // If click in Close Button
            If Assigned(FOnClickClose) then FOnClickClose(Self);
        bnMaximize: // If click in Maximize Button (StyleBar <> sbMaximize)
            If Assigned(FOnClickMaximize) then FOnClickMaximize(Self);
        bnRestore:  // If click in Restore Button (StyleBar <> sbRestore)
            If Assigned(FOnClickRestore) then FOnClickRestore(Self);
        bnMinimize: // If click in Minimize Button (StyleBar <> sbMDIMinimized)
            If Assigned(FOnClickMinimize) then FOnClickMinimize(Self);
        bnHelp:     // If click in Help Button
            If Assigned(FOnClickHelp) then FOnClickHelp(Self);
      end; {CASE}
    end;
    StateDown := False;
  end;
end;

{-}
procedure TButtonsBar.SetAutoConstraints(const AValue: Boolean);
begin
  If (AValue <> FAutoConstraints) then
  begin
    FAutoConstraints := AValue;
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetBitmapSkin(const AValue: TBitmap);
begin
  If (AValue <> FBitmapSkin) then
  begin
    FBitmapSkin.Assign(AValue);
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetHints(const AValue: TStrings);
begin
  If AValue <> FHints then
  begin
    FHints.Assign(AValue);
    UpdateHints;
  end;
end;

{-}
procedure TButtonsBar.SetMarginClose(const AValue: Integer);
begin
  If (AValue <> FMarginClose) then
  begin
    FMarginClose := AValue;
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetMarginHelp(const AValue: Integer);
begin
  If (AValue <> FMarginHelp) then
  begin
    FMarginHelp := AValue;
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end
end;

{-}
procedure TButtonsBar.SetMarginMaximize(const AValue: Integer);
begin
  If (AValue <> FMarginMaximize) then
  begin
    FMarginMaximize := AValue;
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetMarginMinimize(const AValue: Integer);
begin
  If (AValue <> FMarginMinimize) then
  begin
    FMarginMinimize := AValue;
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetStyle(const AValue: TStyle);
begin
  If AValue <> FStyle then
  begin
    FStyle := AValue;
    LoadStyle(UpperCase(TStyleStr[Ord(FStyle)]));
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetStyleBar(const AValue: TStyleBar);
begin
  If AValue <> FStyleBar then
  begin
    FStyleBar := AValue;
    If FStyleBar = sbRestore then
      MenuMaximize.Tag := bnRestore else
        MenuMaximize.Tag := bnMaximize;
    If FStyleBar <> sbMDIMinimized then
      MenuMinimize.Tag := bnMinimize else
        MenuMinimize.Tag := bnRestore;
    UpdateButtons;
    UpdateHints;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetTransparentColor(const AValue: TColor);
begin
  If AValue <> FTransparentColor then
  begin
    FTransparentColor := AValue;
    FBitmapSkin.TransparentColor := FTransparentColor;
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{-}
procedure TButtonsBar.SetVisibleButtons(const AValue: TVisibleButtons);
begin
  If AValue <> FVisibleButtons then
  begin
    FVisibleButtons := AValue;
    MenuClose.Visible := (vbClose in FVisibleButtons);
    MenuMaximize.Visible := (vbMaximize in FVisibleButtons);
    MenuMinimize.Visible := (vbMinimize in FVisibleButtons);
    MenuHelp.Visible := (vbHelp in FVisibleButtons);
    UpdateButtons;
    If Assigned(FOnChangeStatus) then FOnChangeStatus(Self);
  end;
end;

{ ----------------------------------------------------------------------------
  This procedure get margins, load bitmaps, define size and update buttons
  ---------------------------------------------------------------------------- }
{-}
procedure TButtonsBar.UpdateButtons;
var
  MCLOSE, MMAXIMIZE, MMINIMIZE, MHELP: Integer;
begin

  // Margins definitions
  If MenuClose.Visible then
     MCLOSE := FMarginClose else MCLOSE := 0;
  If MenuMaximize.Visible then
     MMAXIMIZE := FMarginMaximize else MMAXIMIZE := 0;
  If MenuMinimize.Visible then
     MMINIMIZE := FMarginMinimize else MMINIMIZE := 0;
  If MenuHelp.Visible then
     MHELP := FMarginHelp else MHELP := 0;

  LoadBitmap(MenuClose, bsUp);
  LoadBitmap(MenuMaximize, bsUp);
  LoadBitmap(MenuMinimize, bsUp);
  LoadBitmap(MenuHelp, bsUp);

  If AutoConstraints = True then
  begin
    Constraints.MinHeight := MenuClose.Height + 4;
    Constraints.MaxHeight := MenuClose.Height + 4;
    Height := Constraints.MaxHeight;
  end else
  begin
    Constraints.MinHeight := 0;
    Constraints.MaxHeight := 0;
    Height := MenuClose.Height + 4;
  end;

  MenuClose.Left := Width - (MenuClose.Width + MCLOSE);
  MenuMaximize.Left := MenuClose.Left - (MenuMaximize.Width + MMAXIMIZE);
  MenuMinimize.Left := MenuMaximize.Left - (MenuMinimize.Width + MMINIMIZE);
  MenuHelp.Left := MenuMinimize.Left - (MenuHelp.Width + MHELP);

  If not(vbClose in FVisibleButtons) then
  begin
    MenuMaximize.Left := MenuClose.Left - MMAXIMIZE + MCLOSE;
    MenuMinimize.Left := MenuMaximize.Left - (MenuMinimize.Width + MMINIMIZE);
    MenuHelp.Left := MenuMinimize.Left - (MenuHelp.Width + MHELP);
  end;
  If not(vbMaximize in FVisibleButtons) then
  begin
    MenuMinimize.Left := MenuMaximize.Left - MMINIMIZE + MMAXIMIZE;
    MenuHelp.Left := MenuMinimize.Left - (MenuHelp.Width + MHELP);
  end;
  If not(vbMinimize in FVisibleButtons) then
  begin
    MenuHelp.Left := MenuMinimize.Left - MHELP + MMINIMIZE;
  end;
  If not(vbHelp in FVisibleButtons) then
  begin
    // Nothing yet
  end;
end;

{-}
procedure TButtonsBar.UpdateHints;
var
  HRes: String; // FHints[bnRestore]. To diminutive Copy and Pos arguments
begin
  If FHints.Count >= bnRestore then HRes := FHints[bnRestore];
  If (FHints.Count >= bnClose) then
    MenuClose.Hint := FHints[bnClose] else MenuClose.Hint := '';
  If (FHints.Count >= bnHelp) then
    MenuHelp.Hint := FHints[bnHelp] else MenuHelp.Hint := '';
  If ((FHints.Count >= bnMaximize) and (FStyleBar <> sbRestore))then
    MenuMaximize.Hint := FHints[bnMaximize] else MenuMaximize.Hint := '';
  If ((FHints.Count >= bnMinimize) and (FStyleBar <> sbMDIMinimized)) then
    MenuMinimize.Hint := FHints[bnMinimize] else MenuMinimize.Hint := '';
  If ((FHints.Count >= bnRestore) and (FStyleBar = sbRestore)) then
    If Pos('|', FHints[bnRestore]) <> 0 then
      MenuMaximize.Hint := Copy(HRes, 1, Pos('|', HRes) - 1) else
        MenuMaximize.Hint := FHints[bnRestore];
  If ((FHints.Count >= bnRestore) and (FStyleBar = sbMDIMinimized)) then
    If Pos('|', FHints[bnRestore]) <> 0 then
      MenuMinimize.Hint := Copy(HRes, Pos('|', HRes) + 1, Length(HRes)) else
        MenuMinimize.Hint := FHints[bnRestore];
end;

initialization
  {$IFDEF FPC}
    {$I buttonsbar.lrs}
  {$ELSE}
    {$R buttonsbar.res}
  {$ENDIF}

end.
