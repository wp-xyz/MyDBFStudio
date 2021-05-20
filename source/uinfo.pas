unit uInfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type

  { TInfo }

  TInfo = class(TForm)
    CloseBtn: TBitBtn;
    Img: TImage;
    Memo1: TMemo;
    Version: TLabel;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
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
  uUtils;

{ TInfo }

procedure TInfo.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TInfo.FormShow(Sender: TObject);
var
  fn: String;
begin
  fn := Application.Location + 'img/splash.png';
  if FileExists(fn) Then
   Img.Picture.LoadFromFile(fn);

  Version.Caption:='Version: ' + GetVersionStr;
end;

end.

