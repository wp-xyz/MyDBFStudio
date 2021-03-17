unit umain;

interface

uses
  {$IFDEF FPC}LResources, ColorBox,{$ENDIF}
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls,
  StdCtrls, ButtonsBar, TitleBar, Spin;

type

  { TfrMain }

  TfrMain = class(TForm)
    Panel: TPanel;
    cbStyleButtons: TComboBox;
    lbStyleButtons: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    lbVisibleButtons: TLabel;
    rgGradientColor: TRadioGroup;
    lbStyleButtonsBar: TLabel;
    cbStyleButtonsBar: TComboBox;
    spCloseMargin: TSpinEdit;
    lbCloseMargin: TLabel;
    lbMaximizeMargin: TLabel;
    spMaximizeMargin: TSpinEdit;
    lbMinimizeMargin: TLabel;
    spMinimizeMargin: TSpinEdit;
    lbHelpMargin: TLabel;
    spHelpMargin: TSpinEdit;
    cbTransparentColor: TColorBox;
    lbTransparentColor: TLabel;
    procedure cbStyleButtonsSelect(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure rgGradientColorClick(Sender: TObject);
    procedure TBClickClose(Sender: TObject);
    procedure TBClickHelp(Sender: TObject);
    procedure TBClickMaximize(Sender: TObject);
    procedure TBClickRestore(Sender: TObject);
    procedure TBClickMinimize(Sender: TObject);
    procedure cbStyleButtonsBarSelect(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure spHelpMarginChange(Sender: TObject);
    procedure spMinimizeMarginChange(Sender: TObject);
    procedure spMaximizeMarginChange(Sender: TObject);
    procedure spCloseMarginChange(Sender: TObject);
    procedure cbTransparentColorChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frMain: TfrMain;
  IsMouseDown: Boolean;
  PosX, PosY: Integer;
  TB: TTitleBar;

implementation

{$IFNDEF FPC}
  {$R *.dfm}
{$ENDIF}

procedure TfrMain.cbStyleButtonsSelect(Sender: TObject);
begin
  If cbStyleButtons.ItemIndex >= 0 then
    Case cbStyleButtons.ItemIndex of
      0: TB.Style := stGnome;
      1: TB.Style := stWaterColorBlue;
      2: TB.Style := stWin9X;
      3: TB.Style := stWinXPBlue;
    end;
end;

procedure TfrMain.CheckBox4Click(Sender: TObject);
begin
  If CheckBox1.Checked then
     TB.VisibleButtons := TB.VisibleButtons + [vbClose] else
     TB.VisibleButtons := TB.VisibleButtons - [vbClose];
  If CheckBox2.Checked then
     TB.VisibleButtons := TB.VisibleButtons + [vbMaximize] else
     TB.VisibleButtons := TB.VisibleButtons - [vbMaximize];
  If CheckBox3.Checked then
     TB.VisibleButtons := TB.VisibleButtons + [vbMinimize] else
     TB.VisibleButtons := TB.VisibleButtons - [vbMinimize];
  If CheckBox4.Checked then
     TB.VisibleButtons := TB.VisibleButtons + [vbHelp] else
     TB.VisibleButtons := TB.VisibleButtons - [vbHelp];
end;

procedure TfrMain.rgGradientColorClick(Sender: TObject);
begin
  If rgGradientColor.ItemIndex = 0 then
     TB.GradientColor := False else
        TB.GradientColor := True;
end;

procedure TfrMain.TBClickClose(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrMain.TBClickHelp(Sender: TObject);
begin
  ShowMessage('This is a Help Click... What I do?');
end;

procedure TfrMain.TBClickMaximize(Sender: TObject);
begin
  Self.WindowState := wsMaximized;
  TB.StyleBar := sbRestore;
end;

procedure TfrMain.TBClickRestore(Sender: TObject);
begin
  Self.WindowState := wsNormal;
  If TB.StyleBar = sbRestore then
     TB.StyleBar := sbMaximize else
       If TB.StyleBar = sbMDIMinimized then
          ShowMessage('StyleButtonsBar is sbbMDIMinimized... What I do? =)');
end;

procedure TfrMain.TBClickMinimize(Sender: TObject);
begin
  Application.Minimize;
end;

procedure TfrMain.cbStyleButtonsBarSelect(Sender: TObject);
const TSB_is = 'The StyleBar of the TitleBar is ';
begin
  If cbStyleButtonsBar.ItemIndex >= 0 then
  Case cbStyleButtonsBar.ItemIndex of
    0: TB.StyleBar := sbMaximize;
    1: TB.StyleBar := sbMDIMinimized;
    2: TB.StyleBar := sbRestore;
  end;
  with TB do
  If ((StyleBar = sbMaximize) and (WindowState = wsMaximized)) then
     ShowMessage(TSB_is + ' sbbMaximize, but windows is alredy maximized') else
  If ((StyleBar = sbMDIMinimized) and (WindowState = wsMaximized)) then
     ShowMessage(TSB_is + ' sbbMDIMinimized, but windows is alredy maximized') else
  If ((StyleBar = sbRestore) and (WindowState = wsNormal)) then
     ShowMessage(TSB_is + ' sbbRestore, but windows is alredy restored')
end;

procedure TfrMain.FormDblClick(Sender: TObject);
begin
  If Self.WindowState = wsNormal then
     TBClickMaximize(TB) else
        TBClickRestore(TB);
end;

procedure TfrMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  If WindowState <> wsMaximized then
  begin
    If IsMouseDown = False then IsMouseDown := True;
    PosX := X; PosY := Y;
  end;
end;

procedure TfrMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  IsMouseDown := False;
end;

procedure TfrMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  If IsMouseDown = True then
    begin
       Self.Left := Self.Left + (X - PosX);
       Self.Top := Self.Top + (Y - PosY);
    end;
end;

procedure TfrMain.FormCreate(Sender: TObject);
begin
  {$IFDEF FPC}
    Self.OnDblClick := @FormDblClick;
  {$ENDIF}
  TB := TTitleBar.Create(Self);
  TB.Parent := Self;
  TB.SendMouseEvents := True;

  TB.OnClickClose := {$IFDEF FPC}@{$ENDIF}TBClickClose;
  TB.OnClickHelp := {$IFDEF FPC}@{$ENDIF}TBClickHelp;
  TB.OnClickMaximize := {$IFDEF FPC}@{$ENDIF}TBClickMaximize;
  TB.OnClickMinimize := {$IFDEF FPC}@{$ENDIF}TBClickMinimize;
  TB.OnClickRestore := {$IFDEF FPC}@{$ENDIF}TBClickRestore;

  // This not work very nice in Delphi!
  TB.OnDblClick := {$IFDEF FPC}@{$ENDIF}FormDblClick;
  TB.OnMouseDown := {$IFDEF FPC}@{$ENDIF}FormMouseDown;
  TB.OnMouseMove := {$IFDEF FPC}@{$ENDIF}FormMouseMove;
  TB.OnMouseUp := {$IFDEF FPC}@{$ENDIF}FormMouseUp;
end;

procedure TfrMain.FormDestroy(Sender: TObject);
begin
  TB.Free;
end;

procedure TfrMain.spHelpMarginChange(Sender: TObject);
begin
  If spHelpMargin.Text <> '' then
    TB.MarginHelp := spHelpMargin.Value;
end;

procedure TfrMain.spMinimizeMarginChange(Sender: TObject);
begin
  If spMinimizeMargin.Text <> '' then
    TB.MarginMinimize := spMinimizeMargin.Value;
end;

procedure TfrMain.spMaximizeMarginChange(Sender: TObject);
begin
  If spMaximizeMargin.Text <> '' then
    TB.MarginMaximize := spMaximizeMargin.Value;
end;

procedure TfrMain.spCloseMarginChange(Sender: TObject);
begin
  If spCloseMargin.Text <> '' then
    TB.MarginClose := spCloseMargin.Value;
end;

procedure TfrMain.cbTransparentColorChange(Sender: TObject);
begin
  TB.TransparentColor := cbTransparentColor.Selected;
end;

initialization
 {$IFDEF FPC}
   {$I umain.lrs}
 {$ENDIF}

end.
