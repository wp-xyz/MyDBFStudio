{

                                FormPanel.pas
                             -------------------
                               The LMDI Suite
              Release: December 2007 (2007-12-28) - (The LMDI Suite)

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
  TWireFrame: Is a Panel to simulate a "Wire Frame" to move/resize FormPanel.
              Should be added an transparent mode to TWireFrame.
  TFormPanel: Is a Panel to simulate a "Form Docked". It use TTitleBar.

ToDo List:
  + Test CLX Compatibility (in Delphi7 CLX work. Must be tested in Kylix)

Know Issues:
  - ???

Enjoy, is OpenSource =)
}
unit formpanel;

{$I defines.inc}

interface

uses
  {$IFDEF FPC}
    LResources, LCLProc,
    Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  {$ELSE}
    {$IFDEF DK_CLX} // Not tested in Kylix
    QForms, QControls, QGraphics, QDialogs, QExtCtrls, QStdCtrls,
    {$ELSE}
    Windows,
    Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
    {$ENDIF}
  {$ENDIF}
  Classes, SysUtils, Types, ButtonsBar, TitleBar;
  
const
  MG = 4; // Margin Size
  // you should use same value from FTitleBar.[Top/Left] - FormPanel.[Top/Left]
  MGD = 15; // Diagonal Margin (should be > MG)

type

  { TPanelDirection }
  TPanelDirection =
  (pdBottom, pdBottomLeft, pdBottomRight, pdLeft, pdNone,
   pdTop, pdTopLeft, pdTopRight, pdRight);

  { TWireFrame }
  TWireFrame = class(TPanel)
  protected
    FSendMouseEvents: Boolean;
  public
    spWire: TShape;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TFormPanel }
  TFormPanel = class(TPanelSenderMouseEvents) // SendMouseEvents = False
    procedure TitleBarChangeStatus(Sender: TObject);
  protected
    FLockMove, FLockResize, FWireFrameMoveResize,
    IsMovingX, IsResizingX: Boolean;
    // "X" to avoid confusion with inherited property "IsResizing"
    SHeight, SWidth, SLeft, STop: Integer; // Start Positions to Move and Resize
    StartPoint: TPoint; // Start point to Move and Resize
    pnDir: TPanelDirection;
    Mouse: TMouse;
    procedure CreateWnd; override;
    procedure DblClick; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  protected
    TopPanel: TPanelSenderMouseEvents;
    // TPanel to store TitleBar (TitleBar.align is <> alTop)
    {$IFDEF DK_CLX}
    procedure ControlsDblClick(Sender: TObject);
    procedure ControlsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ControlsMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ControlsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    {$ENDIF}
  public
    ClientArea: TPanelSenderMouseEvents;
    TitleBar: TTitleBar;
    WireFrame: TWireFrame;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function MouseIsInsideControl(Control: TControl): Boolean;
    procedure UpdateClientArea;
    procedure UpdateTopArea;
  published
    property LockMove: Boolean read FLockMove write FLockMove default False;
    property LockResize: Boolean read FLockResize write FLockResize default False;
    property WireFrameMoveResize: Boolean read FWireFrameMoveResize
             write FWireFrameMoveResize default False;
  end;

procedure Register;

implementation

{-}
procedure Register;
begin
  RegisterComponents('LMDI', [TFormPanel]);
end;

{ TWireFrame }

{-}
constructor TWireFrame.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  BevelOuter := bvNone;
  spWire := TShape.Create(Self);
  spWire.Align := alClient;
  spWire.Parent := Self;
  spWire.Brush.Style := bsClear;
  spWire.Pen.Width := 2;
end;

{-}
destructor TWireFrame.Destroy;
begin
  FreeAndNil(spWire);
  Inherited Destroy;
end;

{ TFormPanel }

{-}
constructor TFormPanel.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  SendMouseEvents := False;
  Height := 250;
  Width := 400;
  BevelInner := bvRaised;
  BevelOuter := bvRaised;

  TopPanel := TPanelSenderMouseEvents.Create(Self);
  TopPanel.Parent := (Self);

  TitleBar := TTitleBar.Create(Self);
  TitleBar.Parent := TWinControl(TopPanel);
  TitleBar.OnChangeStatus := @TitleBarChangeStatus;

  ClientArea := TPanelSenderMouseEvents.Create(nil);
  ClientArea.Parent := TWinControl(Self);

  WireFrame := TWireFrame.Create(nil);
  WireFrame.ParentColor := True;
  WireFrame.Visible := False;

  // SendMouseEvents do not work in CLX. Then do this manually =)
  {$IFDEF DK_CLX}
  TopPanel.OnDblClick := ControlsDblClick;
  TopPanel.OnMouseDown := ControlsMouseDown;
  TopPanel.OnMouseMove := ControlsMouseMove;
  TopPanel.OnMouseUp := ControlsMouseUp;
  TitleBar.OnDblClick := ControlsDblClick;
  TitleBar.OnMouseDown := ControlsMouseDown;
  TitleBar.OnMouseMove := ControlsMouseMove;
  TitleBar.OnMouseUp := ControlsMouseUp;
  ClientArea.OnDblClick := ControlsDblClick;
  ClientArea.OnMouseDown := ControlsMouseDown;
  ClientArea.OnMouseMove := ControlsMouseMove;
  ClientArea.OnMouseUp := ControlsMouseUp;
  {$ENDIF}
end;

procedure TFormPanel.TitleBarChangeStatus(Sender: TObject);
begin
  UpdateClientArea;
end;

{-}
procedure TFormPanel.CreateWnd;
var
  I: Integer;
begin
  Inherited CreateWnd;
  Caption := '';

  with TopPanel do
    begin
      Align := alTop;
      ParentColor := True;
      BevelInner := bvNone;
      BevelOuter := bvNone;
      // Note: SendMouseEvents do not work in CLX!
      ControlToGetMouseEvents := Self;
      SendMouseEvents := True;
    end;

  with TitleBar do
    begin
      Align := alNone;
      Anchors := [akLeft, akTop, akRight];
      ControlToGetMouseEvents := Self;
      SendMouseEvents := True;
      Style := stWin9x;
      // FPC: give a default value to Linux and Darwin with IFDEFS ???
    end;

  with ClientArea do
    begin
      BevelInner := bvNone;
      BevelOuter := bvNone;
      //Color := clBlue; // uncomment for some tests (where are ClientArea?) =)
      // Note: SendMouseEvents do not work in CLX!
      ControlToGetMouseEvents := Self;
      SendMouseEvents := True;
      If not(csDesigning in ComponentState) then
        ClientArea.SendToBack else // Show all T[Win]Controls in Self
          Visible := False; // Hide ClientArea in design time
    end;

  UpdateClientArea; // Keep it. Necessary to calculate TopArea and ClientArea

  // Start move all components from FormPanel to ClientArea
  If (Parent <> nil) then
    for I := Parent.ComponentCount - 1 downto 0 do
      If (Parent.Components[I] is TControl) then
        If (Parent.Components[I] as TControl).Parent = Self then
        with (Parent.Components[I] as TControl) do
          begin
            Parent := ClientArea;
            Left := Left - ClientArea.Left;
            Top := Top - ClientArea.Top;
          end;
end;

{-}
destructor TFormPanel.Destroy;
begin
  FreeAndNil(ClientArea);
  FreeAndNil(TitleBar);
  FreeAndNil(TopPanel);
  Inherited Destroy;
end;

{$IFDEF DK_CLX}
{-}
procedure TFormPanel.ControlsDblClick(Sender: TObject);
begin
  DblClick;
end;

{-}
procedure TFormPanel.ControlsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  X := ClientOrigin.X - Self.ClientOrigin.X + X;
  Y := ClientOrigin.Y - Self.ClientOrigin.Y + Y;
  MouseDown(Button, Shift, X, Y);
end;

{-}
procedure TFormPanel.ControlsMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  X := ClientOrigin.X - Self.ClientOrigin.X + X;
  Y := ClientOrigin.Y - Self.ClientOrigin.Y + Y;
  MouseMove(Shift, X, Y);
end;

{-}
procedure TFormPanel.ControlsMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  X := ClientOrigin.X - Self.ClientOrigin.X + X;
  Y := ClientOrigin.Y - Self.ClientOrigin.Y + Y;
  MouseUp(Button, Shift, X, Y);
end;
{$ENDIF}

{-}
function TFormPanel.MouseIsInsideControl(Control: TControl): Boolean;
var
  P, P2: TPoint;
begin
  Result := False;
  P := Control.ClientOrigin;
  P2 :=  Mouse.CursorPos;
  If ((P2.X > (P.X)) and (P2.X <= (P.X + Control.Width)) and
      (P2.Y > (P.Y)) and (P2.Y <= (P.Y + Control.Height))) then
  Result := True;
end;

{-}
procedure TFormPanel.DblClick;
begin
  Inherited DblClick;
  IsMovingX := False;
  IsResizingX := False;
  WireFrame.Hide;
end;

{-}
procedure TFormPanel.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  If Button = mbLeft then
  begin
    SHeight := Self.Height;
    STop := Self.Top;
    SLeft := Self.Left;
    SWidth := Self.Width;
    WireFrame.Left := Self.Left;
    WireFrame.Top := Self.Top;
    WireFrame.Width := Self.Width;
    WireFrame.Height := Self.Height;
    StartPoint :=  Mouse.CursorPos;

    // If has clicked inside TitleBar
    If MouseIsInsideControl(TitleBar) = True then
    begin
      If ((IsMovingX = False) and (FLockMove = False) and (Align <> alClient)) then
      begin
        IsMovingX := True;
        WireFrame.Parent := Self.Parent;
        WireFrame.Visible := FWireFrameMoveResize;
      end;
    end else // click out of TitleBar? then start Resizing (if not Maximized)
    If ((IsResizingX = False) and (FLockResize = False) and
        (Align <> alClient)) then
    begin
      IsResizingX := True;
      WireFrame.Parent := Self.Parent;
      WireFrame.Visible := FWireFrameMoveResize;
    end;
    If WireFrame.Visible then WireFrame.BringToFront;
  end;
  Inherited MouseDown(Button, Shift, X, Y);
end;

{-}
procedure TFormPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  MIN_WIDTH, MIN_HEIGHT, L, T, H, W: Integer;
  P: TPoint; // Current Point
begin
  P := Mouse.CursorPos; // GetCursorPos (Current Point)

  If (FLockMove = False) then
  begin
    If ((IsMovingX = True) and (IsResizingX = False)) then
    begin
      L := SLeft + (P.X - StartPoint.X);
      T := STop + (P.Y - StartPoint.Y);
      If (T >= 0) then
        WireFrame.Top := T;
      WireFrame.Left := L;
      If (WireFrameMoveResize = False) then
      begin
        Self.Top := WireFrame.Top;
        Self.Left := WireFrame.Left;
      end;
    end;
  end;

  If (FLockResize = False) then
  begin
    If IsResizingX = False then
    with Self do
      begin
        If ((X < MG) or (X > Width - MG)) then
        begin
          If (X < MG) then
          begin
            If ((X < MG) and (Y < MGD)) then
              pnDir := pdTopLeft else
            If ((X < MG) and (Y > Height - MGD)) then
              pnDir := pdBottomLeft else pnDir := pdLeft;
          end else
          begin
            If ((X > Width - MG) and (Y < MGD)) then
              pnDir := pdTopRight else
            If ((X > Width - MG) and (Y > Height - MGD)) then
              pnDir := pdBottomRight else pnDir := pdRight;
          end;
        end else
        If ((Y < MG) or (Y > Height - MG)) then
        begin
          If (Y < MG) then
          begin
            If ((Y < MG) and (X < MGD)) then
              pnDir := pdTopLeft else
            If ((Y < MG) and (X > Width - MGD)) then
              pnDir := pdTopRight else pnDir := pdTop;
          end else
          begin
            If ((Y > Height - MG) and (X < MGD)) then
              pnDir := pdBottomLeft else
            If ((Y > Height - MG) and (X > Width - MGD)) then
              pnDir := pdBottomRight else pnDir := pdBottom;
          end;
        end else pnDir := pdNone;
      end;

    If (IsMovingX = False) then
    begin
      with Self do
        Case pnDir of
          pdTopLeft: Cursor := crSizeNWSE;
          pdBottomLeft: Cursor := crSizeNESW;
          pdLeft: Cursor := crSizeWE;
          pdTopRight: Cursor := crSizeNESW;
          pdBottomRight: Cursor := crSizeNWSE;
          pdRight: Cursor := crSizeWE;
          pdTop: Cursor := crSizeNS;
          pdBottom: Cursor := crSizeNS;
          else Cursor := crDefault;
        end;
      If ((pnDir = pdTopLeft) or (pnDir = pdTop) or (pnDir = pdTopRight)) then
        TopPanel.Cursor := Self.Cursor else
          TopPanel.Cursor := crDefault;
    end;

    If ((IsResizingX = True) and (IsMovingX = False)) then
    begin
      MIN_WIDTH := 150;
      MIN_HEIGHT := TitleBar.Height + MG + MG;
      with WireFrame do
      begin
        Case pnDir of
          pdTopLeft:
            begin
              L := SLeft + (P.X - StartPoint.X);
              T := STop + (P.Y - StartPoint.Y);
              H := SHeight - (P.Y - StartPoint.Y);
              W := SWidth - (P.X - StartPoint.X);
              If ((H > MIN_HEIGHT) and (T >= 0)) then
              begin
                Height := H;
                Top := T;
                //SetBounds(Left, T, Width, H);
              end;
              If W > MIN_WIDTH then
              begin
                Left := L;
                Width := W;
                //SetBounds(L, Top, W, Height);
              end;
            end;

          pdBottomLeft:
            begin
              W := SWidth - (P.X - StartPoint.X);
              L := SLeft + (P.X - StartPoint.X);
              H := SHeight + (P.Y - StartPoint.Y);
              If H > MIN_HEIGHT then Height := H;
              If W > MIN_WIDTH then
              begin
                Left := L;
                Width := W;
                //SetBounds(L, Top, W, Height);
              end;
            end;

          pdLeft:
            begin
              W := SWidth - (P.X - StartPoint.X);
              L := SLeft + (P.X - StartPoint.X);
              If W > MIN_WIDTH then
              begin
                Left := L;
                Width := W;
                //SetBounds(L, Top, W, Height);
              end;
            end;

          pdTopRight:
            begin
              W := SWidth + (P.x - StartPoint.X);
              H := SHeight - (P.Y - StartPoint.Y);
              T := STop + (P.Y - StartPoint.Y);
              If ((H > MIN_HEIGHT) and (T >= 0)) then
                begin
                  Height := H;
                  Top := T;
                  //SetBounds(Left, T, Width, H);
                end;
              If W > MIN_WIDTH then Width := W;
            end;

          pdBottomRight:
            begin
              W := SWidth + (P.X - StartPoint.X);
              H := SHeight + (P.Y - StartPoint.Y);
              If H > MIN_HEIGHT then Height := H;
              If W > MIN_WIDTH then Width := W;
            end;

          pdRight:
            begin
              W := SWidth + (P.X - StartPoint.X);
              If W > MIN_WIDTH then Width := W;
            end;

          pdTop:
            begin
              H := SHeight - (P.Y - StartPoint.Y);
              T := STop + (P.Y - StartPoint.Y);
              If ((H > MIN_HEIGHT) and (T >= 0)) then
              begin
                Height := H;
                Top := T;
                //SetBounds(Left, T, Width, H);
              end;
            end;

          pdBottom:
            begin
              H := SHeight + (P.Y - StartPoint.Y);
              If H > MIN_HEIGHT then Height := H;
            end;
        end;

        If FWireFrameMoveResize = False then
        begin
          Self.Left := Left;
          Self.Top := Top;
          Self.Height := Height;
          Self.Width := Width;
        end;
        { * Bug in older version of Lazarus *
          TitleBar.Invalidate;
          TitleBar.Repaint;}
      end;
    end;
  end;
  Inherited MouseMove(Shift, X, Y);
end;

{-}
procedure TFormPanel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y:
  Integer);
begin
  If ((IsMovingX = True) or (IsResizingX = True)) then
  begin
    If (IsMovingX = True) then IsMovingX := False else
      If (IsResizingX = True) then IsResizingX := False;
    If FWireFrameMoveResize = True then
    begin
      Self.Left := WireFrame.Left;
      Self.Top := WireFrame.Top;
      Self.Width := WireFrame.Width;
      Self.Height := WireFrame.Height;
      WireFrame.Hide;
    end;
  end;
  If (Parent <> nil) then
  begin
    Parent.Invalidate;
    Parent.Repaint;
  end;
  Inherited MouseUp(Button, Shift, X, Y);
end;

{ ----------------------------------------------------------------------------
  This procedure Update the client area in FormPanel
  This is necessary when stylebuttons, in titlebar, is modified
  ---------------------------------------------------------------------------- }
{-}
procedure TFormPanel.UpdateClientArea;
begin
  UpdateTopArea; // First UpdateTopArea
  If TopPanel.Visible = True then
  with ClientArea do
  begin
    Align := alNone;
    Anchors := [akLeft, akTop, akRight, akBottom];
    Left := MG;
    Height := Self.Height - TopPanel.Height - TopPanel.Top - MG;
    Top := Self.Height - Height - MG;
    Width := Self.Width - Left - MG;
  end else ClientArea.Align := alClient;
end;

{-}
procedure TFormPanel.UpdateTopArea;
begin
  with TitleBar do
  begin
    Left := 0;
    Left := (Self.ClientOrigin.X - ClientOrigin.X) + MG;
    Top := 0;
    Top := (Self.ClientOrigin.Y - ClientOrigin.Y) + MG;
    TopPanel.Height := Top + Height;
    Width := Self.ClientOrigin.X + Self.Width - Self.ClientOrigin.X - (MG * 2);
  end;
end;

initialization
  {$IFDEF FPC}
    {$I formpanel.lrs}
  {$ELSE}
    {$R formpanel.res}
  {$ENDIF}

end.
