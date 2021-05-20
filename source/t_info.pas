unit T_Info;

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

const
  StrVer = '0.5.1-2021';

{ TInfo }

procedure TInfo.FormShow(Sender: TObject);
var
  fn: String;
begin
  fn := Application.Location + 'img/splash.png';
  if FileExists(fn) Then
   Img.Picture.LoadFromFile(fn);

  Version.Caption:='Version: ' + StrVer;
end;


end.

