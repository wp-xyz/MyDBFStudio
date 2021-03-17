{

                                 TitleBar.pas
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
  TTitleBar: Is a TButtonsBar descendent to simulate an TitleBar.
  It's come with gradient property (for Win9x users).

ToDo List:
  + Test CLX Compatibility (in Delphi7 CLX work. Must be tested in Kylix)
  + Add LeftImage, MiddleImage and RightImage to styles appear "most real" (?)

Know Issues:
  - ???

Enjoy, is OpenSource =)
}
unit titlebar;

{$I defines.inc}

interface

uses
  {$IFDEF FPC}
    LResources, LCLIntf, LCLType, // used in SetGradientColor
    Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  {$ELSE}
    {$IFDEF DK_CLX} // Not tested in Kylix
      {$IFDEF DELPHI_CLX} // DELPHI_CLX
      Windows,
      {$ELSE} // KYLIX_CLX
      Libc, // has Libc GetRValue, GetGValue, GetBValue???
      {$ENDIF}
    QForms, QControls, QGraphics, QDialogs, QExtCtrls, QStdCtrls,
    {$ELSE}
    Windows, // used in SetGradientColor
    Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
    {$ENDIF}
  {$ENDIF}
  Classes, SysUtils, ButtonsBar;

const
  {$IFDEF DK_CLX} // Delphi_Kylix_CLX
    cColorActive  = clBlue;
    cColorInactive  = clBlue;
    cColorActiveGradient = clBlue;
    cColorInactiveGradient = clBlue;
  {$ELSE}
    {$IFDEF MSWINDOWS}
      cColorActive  = clActiveCaption;
      cColorInactive  = clInactiveCaption;
      cColorActiveGradient = clGradientActiveCaption;
      cColorInactiveGradient = clGradientInactiveCaption;
    {$ELSE} // Change below as you like =)
      cColorActive  = clBlue;
      cColorInactive  = clBlue;
      cColorActiveGradient = clBlue;
      cColorInactiveGradient = clBlue;
    {$ENDIF}
  {$ENDIF}

type

  { TTitleBar }
  TTitleBar = class(TButtonsBar)
    procedure ImgIconMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer); virtual;
  protected
    FInactive, FGradientColor, FShowCaption, FShowIcon: Boolean;
    FColorActive, FColorActiveGradient,
    FColorInactive, FColorInactiveGradient: TColor;
    ImgIcon: TImage;
    FIcon: TPicture;
    FCaption: TCaption;
    FCaptionFont: TFont;
    procedure CreateWnd; override;
    procedure Paint; override;
  private
    procedure SetGradientColor(const AValue: Boolean);
    procedure SetColorActive(const AValue: TColor);
    procedure SetColorActiveGradient(const AValue: TColor);
    procedure SetColorInactive(const AValue: TColor);
    procedure SetColorInactiveGradient(const AValue: TColor);
    procedure SetIcon(const AValue: TPicture);
    procedure SetInactive(const AValue: Boolean);
    procedure SetShowCaption(const AValue: Boolean);
    procedure SetShowIcon(const AValue: Boolean);
    procedure SetCaption(const AValue: TCaption);
    procedure SetCaptionFont(const AValue: TFont);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption: TCaption read FCaption write SetCaption;
    property CaptionFont: TFont read FCaptionFont write SetCaptionFont;
    property ColorActive: TColor read FColorActive
             write SetColorActive default cColorActive;
    property ColorActiveGradient: TColor read FColorActiveGradient
             write SetColorActiveGradient default cColorActiveGradient;
    property ColorInactive: TColor read FColorInactive
             write SetColorInactive default cColorInactive;
    property ColorInactiveGradient: TColor read FColorInactiveGradient
             write SetColorInactiveGradient default cColorInactiveGradient;
    property GradientColor: Boolean read FGradientColor
             write SetGradientColor default False;
    property Icon: TPicture read FIcon write SetIcon;
    property Inactive: Boolean read FInactive write SetInactive default False;
    property ShowIcon: Boolean read FShowIcon write SetShowIcon default True;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption
             default True;
  end;

procedure Register;

implementation

{-}
procedure Register;
begin
  RegisterComponents('LMDI', [TTitleBar]);
end;

{ TTitleBar }

{-}
constructor TTitleBar.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  GradientColor := True;
  FColorActive := cColorActive;
  FColorActiveGradient := cColorActiveGradient;
  FColorInactive := cColorInactive;
  FColorInactiveGradient := cColorInactiveGradient;
  FShowIcon := True;
  FShowCaption := True;
  ImgIcon := TImage.Create(nil);
  ImgIcon.OnMouseDown := {$IFDEF FPC}@{$ENDIF}ImgIconMouseDown;
  ImgIcon.Anchors := [akLeft];
  ImgIcon.Parent := TWinControl(Self);
  ImgIcon.Left := 1;
  If ((AOwner <> nil) and (AOwner is TForm)) then
    FCaption := (AOwner as TForm).Caption else
      FCaption := 'MyCustomChildForm';
  FCaptionFont := TFont.Create;
  FCaptionFont.Color := clWhite;
  FCaptionFont.Size := 8;
  FCaptionFont.Style := [fsBold];
  FIcon := TPicture.Create;
  {$IFDEF FPC}
    FIcon.Bitmap.LoadFromLazarusResource('DEFAULT_ICON');
  {$ELSE}
    FIcon.Bitmap.LoadFromResourceName(hInstance, 'DEFAULT_ICON');
  {$ENDIF}
end;

{-}
destructor TTitleBar.Destroy;
begin
  FreeAndNil(FIcon);
  FreeAndNil(FCaptionFont);
  FreeAndNil(ImgIcon);
  Inherited Destroy;
end;

{-}
procedure TTitleBar.CreateWnd;
begin
  Inherited CreateWnd;
  with ImgIcon do
    begin
      BringToFront;
      Picture.Assign(FIcon);
      Height := 16;
      Width := 16;
      Transparent := True;
      Visible := FShowIcon;
    end;
end;

{-}
procedure TTitleBar.Paint;
var
  I, R, G, B: Byte;
  CaptionLeft, CaptionTop, RGB1, RGB2, RGB3: Integer;
  C1, C2: TColor;
begin
  Inherited Paint;
  If FGradientColor = True then
  begin
    If FInactive = False then // If Active
    begin
      C1 := FColorActive;
      C2 := FColorActiveGradient;
    end else // If Inactive
    begin
      C1 := FColorInactive;
      C2 := FColorInactiveGradient;
    end;
    {$IFDEF KYLIX_CLX}
     // ToDo: Gradient Code to Kylix (see Libc comment in uses clause)
    {$ELSE}
    RGB1 := GetRValue (ColorToRGB (C2)) - GetRValue (ColorToRGB (C1));
    RGB2 := GetGValue (ColorToRGB (C2)) - GetGValue (ColorToRGB (C1));
    RGB3 := GetBValue (ColorToRGB (C2)) - GetBValue (ColorToRGB (C1));
    for I := 0 to 255 do
    begin
      R := GetRValue (ColorToRGB (C1)) + MulDiv (I, RGB1, 255 - 1);
      G := GetGValue (ColorToRGB (C1)) + MulDiv (I, RGB2, 255 - 1);
      B := GetBValue (ColorToRGB (C1)) + MulDiv (I, RGB3, 255 - 1);
      Canvas.Brush.Color := RGB(R, G, B);
      with Canvas do
        FillRect(Rect(MulDiv(I, Width, 255), 0, MulDiv(I + 1, Width, 254), Height))
    end;
    {$ENDIF}
  end;
  ImgIcon.Top := (Self.Height - Icon.Height) div 2;
  If FShowCaption = True then // Write, or Draw, the Caption
  begin
    Canvas.Font.Assign(FCaptionFont);
    Canvas.Brush.Style := bsClear;
    CaptionLeft := 5;
    If ImgIcon.Visible = True then CaptionLeft := CaptionLeft + Icon.Width;
    CaptionTop := 0;
    If Canvas.TextHeight(FCaption) <= Height then
      CaptionTop := ((Height - Canvas.TextHeight(FCaption)) div 2);
    Canvas.TextOut(CaptionLeft, CaptionTop, FCaption);
    Canvas.Brush.Style := bsSolid;
  end;
end;

{-}
procedure TTitleBar.ImgIconMouseDown(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Self.MouseDown(mbRight{Temporary: Keep this!!!}, Shift, X, Y);
  If Assigned(PopupMenu) then // Show PopupMenu if click inside of ImgIcon
    with ClientOrigin do
      PopupMenu.Popup(X + ImgIcon.Left, Y + ImgIcon.Top + ImgIcon.Height);
end;

{-}
procedure TTitleBar.SetGradientColor(const AValue: Boolean);
begin
  If (AValue <> FGradientColor) then
  begin
    FGradientColor := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetInactive(const AValue: Boolean);
begin
  If (AValue <> FInactive) then
  begin
    FInactive := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetColorActive(const AValue: TColor);
begin
  If (AValue <> FColorActive) then
  begin
    FColorActive := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetColorActiveGradient(const AValue: TColor);
begin
  If (AValue <> FColorActiveGradient) then
  begin
    FColorActiveGradient := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetColorInactive(const AValue: TColor);
begin
  If (AValue <> FColorInactive) then
  begin
    FColorInactive := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetColorInactiveGradient(const AValue: TColor);
begin
  If (AValue <> FColorInactiveGradient) then
  begin
    FColorInactiveGradient := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetIcon(const AValue: TPicture);
begin
  If AValue <> FIcon then
  begin
    FIcon.Assign(AValue);
    ImgIcon.Picture.Assign(FIcon);
  end;
end;

{-}
procedure TTitleBar.SetShowCaption(const AValue: Boolean);
begin
  If AValue <> FShowCaption then
  begin
    FShowCaption := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetShowIcon(const AValue: Boolean);
begin
  If AValue <> FShowIcon then
  begin
    FShowIcon := AValue;
    ImgIcon.Visible := FShowIcon;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetCaption(const AValue: TCaption);
begin
  If AValue <> FCaption then
  begin
    FCaption := AValue;
    Invalidate;
  end;
end;

{-}
procedure TTitleBar.SetCaptionFont(const AValue: TFont);
begin
  If AValue <> FCaptionFont then
  begin
    FCaptionFont.Assign(AValue);
    Invalidate;
  end;
end;

initialization
  {$IFDEF FPC}
    {$I titlebar.lrs}
  {$ELSE}
    {$R titlebar.res}
  {$ENDIF}

end.
