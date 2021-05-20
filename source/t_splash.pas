unit T_Splash; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls;

type

  { TSplash }

  TSplash = class(TForm)
    Img: TImage;
    Ver: TStaticText;
    Timer1: TTimer;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  Splash: TSplash;

implementation

{$R *.lfm}

uses
  uUtils;

{ TSplash }

procedure TSplash.FormShow(Sender: TObject);
var
  fn: String;
begin
  fn := Application.Location + 'img/splash.png';
  if FileExists(fn) then
    Img.Picture.LoadFromFile(fn);

  Ver.Caption := Ver.Caption + GetVersionStr;

 Timer1.Enabled:=True;
end;

procedure TSplash.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if Timer1.Enabled Then
    CanClose:=False;
end;

procedure TSplash.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=False;
  Close;
end;


end.

