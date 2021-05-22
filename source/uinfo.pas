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
    Memo1: TMemo;
    Version: TLabel;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    procedure MeasureMemo;
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

procedure TInfo.FormActivate(Sender: TObject);
begin
  MeasureMemo;
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

procedure TInfo.MeasureMemo;
var
  R: TRect;
  s: String;
  bmp: TBitmap;
  flags: Integer;
begin
  bmp := TBitmap.Create;
  try
    bmp.SetSize(1, 1);
    bmp.Canvas.Font.Assign(Memo1.Font);
    R := Rect(0, 0, Memo1.Width, 0);
    s := Memo1.Lines.Text;
    flags := DT_CALCRECT or DT_WORDBREAK and not DT_SINGLELINE;
    DrawText(bmp.Canvas.Handle, PChar(s), Length(s), R, flags);
    Memo1.Constraints.MinHeight := R.Bottom - R.Top;
  finally
    bmp.Free;
  end;
end;

end.

