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
    Label2: TLabel;
    Version: TLabel;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Label2MouseEnter(Sender: TObject);
    procedure Label2MouseLeave(Sender: TObject);
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
  LCLIntf, LCLType, uUtils;

{ TInfo }

procedure TInfo.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TInfo.FormCreate(Sender: TObject);
begin
  Version.Caption := 'Version: ' + GetVersionStr;
  Img.Picture.LoadFromResourceName(HINSTANCE, 'SPLASH', TPortableNetworkGraphic);
  Img.AutoSize := true;
end;

procedure TInfo.Label2Click(Sender: TObject);
begin
  OpenURL((Sender as TLabel).Caption);
end;

procedure TInfo.Label2MouseEnter(Sender: TObject);
begin
  (Sender as TControl).Font.Style := [fsUnderline];
end;

procedure TInfo.Label2MouseLeave(Sender: TObject);
begin
  (Sender as TControl).Font.Style := [];
end;

end.

