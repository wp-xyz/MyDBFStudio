unit uInfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type

  { TInfo }

  TInfo = class(TForm)
    Bevel1: TBevel;
    CloseBtn: TBitBtn;
    Img: TImage;
    Label1: TLabel;
    lblIcons8: TLabel;
    lblSourceForge: TLabel;
    Label4: TLabel;
    Version: TLabel;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure URLLabelClick(Sender: TObject);
    procedure URLLabelMouseEnter(Sender: TObject);
    procedure URLLabelMouseLeave(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  Info: TInfo;

implementation

{$R *.lfm}

uses
  InterfaceBase, LCLPlatformDef, LCLIntf, LCLType, uUtils;

{ TInfo }

procedure TInfo.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TInfo.FormCreate(Sender: TObject);
var
  OS, WS: String;
begin
  OS := {$I %FPCTARGETOS%};
  WS := LCLPlatformDisplayNames[WidgetSet.LCLPlatform];
  Version.Caption := Format('Version: %s (%s, widgetset: %s)', [GetVersionStr, OS, WS]);
  Img.Picture.LoadFromResourceName(HINSTANCE, 'SPLASH', TPortableNetworkGraphic);
  Img.AutoSize := true;
end;

procedure TInfo.URLLabelClick(Sender: TObject);
begin
  OpenURL((Sender as TLabel).Caption);
end;

procedure TInfo.URLLabelMouseEnter(Sender: TObject);
begin
  (Sender as TControl).Font.Style := [fsUnderline];
end;

procedure TInfo.URLLabelMouseLeave(Sender: TObject);
begin
  (Sender as TControl).Font.Style := [];
end;

end.

