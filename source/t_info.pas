unit T_Info;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type

  { TInfo }

  TInfo = class(TForm)
    BitBtn1: TBitBtn;
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

uses
  T_MainForm;

{ TInfo }

procedure TInfo.FormShow(Sender: TObject);
var
  fn: String;
begin
  fn := Application.Location + 'img/splash.png';
  if FileExists(fn) Then
   Img.Picture.LoadFromFile(fn);

  Version.Caption:='Version: ' + T_MainForm.StrVer;
end;


end.

