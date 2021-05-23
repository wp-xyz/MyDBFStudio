unit uSplash;

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
    procedure FormCreate(Sender: TObject);
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
begin
 Timer1.Enabled:=True;
end;

procedure TSplash.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if Timer1.Enabled Then
    CanClose:=False;
end;

procedure TSplash.FormCreate(Sender: TObject);
begin
  Img.Picture.LoadFromResourceName(HINSTANCE, 'SPLASH', TPortableNetworkGraphic);
  Img.AutoSize := true;
  Ver.Caption := Ver.Caption + GetVersionStr;
end;

procedure TSplash.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=False;
  Close;
end;


end.

