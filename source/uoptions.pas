unit uOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ColorBox, ComCtrls, Buttons, ExtCtrls;

type

  TRecOptions                 = Packed Record
    RememberWindowsSizePos    : Boolean;
    WindowsState              : TWindowState;
    wWidth,
    wHeight,
    wTop,
    wLeft                     : Integer;
    StartWithOBA              : Boolean;
    GotoToLastRecord          : Boolean;
    EnableToolBar             : Boolean;
    EnaleStatusBar            : Boolean;
    AlternateColor            : TColor;
    MaxHistoryRecords         : Integer;
    ShowSplashScreen          : Boolean;
  end;

  { TOptions }

  TOptions = class(TForm)
    Bevel1: TBevel;
    Button1: TBitBtn;
    CloseBtn: TBitBtn;
    ConfirmBtn: TBitBtn;
    cbRememberWPos: TCheckBox;
    cbStartWithOBA: TCheckBox;
    cbGotoToLastRec: TCheckBox;
    cbEnableToolbar: TCheckBox;
    cbEnableStatusBar: TCheckBox;
    cbAlternateColor: TColorBox;
    cbShowSplashScreen: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    lNumberOf: TLabel;
    tbMaxNumberFileHistory: TTrackBar;
    procedure CloseBtnClick(Sender: TObject);
    procedure ConfirmBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tbMaxNumberFileHistoryChange(Sender: TObject);
  private
    { private declarations }
    OptFName : String;
  public
    { public declarations }
    RecOptions : TRecOptions;

    Procedure LoadOptions;
    Procedure SaveOptions;
  end;

var
  Options: TOptions;

implementation

Uses Math, uMain;

{$R *.lfm}

{ TOptions }

procedure TOptions.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TOptions.ConfirmBtnClick(Sender: TObject);
begin
 RecOptions.RememberWindowsSizePos := cbRememberWPos.Checked;
 RecOptions.StartWithOBA := cbStartWithOBA.Checked;
 RecOptions.GotoToLastRecord := cbGotoToLastRec.Checked;
 RecOptions.EnableToolBar := cbEnableToolbar.Checked;
 RecOptions.EnaleStatusBar := cbEnableStatusBar.Checked;
 RecOptions.AlternateColor := cbAlternateColor.Selected;
 RecOptions.MaxHistoryRecords := tbMaxNumberFileHistory.Position;
 RecOptions.ShowSplashScreen := cbShowSplashScreen.Checked;

 SaveOptions;

 ShowMessage('Changes will take effect at the next reboot.');

 Close;
end;

procedure TOptions.Button1Click(Sender: TObject);
begin
 If FileExists(ExtractFilePath(Application.ExeName) + 'recentf.ini') Then
  Begin
   If DeleteFile(ExtractFilePath(Application.ExeName) + 'recentf.ini') Then
    Begin
     Main.FileHistory.UpdateParentMenu;

     ShowMessage('History cleared!');
    end;
  end;
end;

procedure TOptions.FormCreate(Sender: TObject);
begin
 RecOptions.EnableToolBar := True;
 RecOptions.EnaleStatusBar := True;
 RecOptions.MaxHistoryRecords := 10;
 RecOptions.RememberWindowsSizePos := False;
 RecOptions.StartWithOBA := False;
 RecOptions.GotoToLastRecord := False;
 RecOptions.AlternateColor := clCream;
 RecOptions.ShowSplashScreen := True;

 OptFName := ExtractFilePath(Application.ExeName) + 'options.reg';
end;

procedure TOptions.FormShow(Sender: TObject);
begin
 ConfirmBtn.Constraints.MinWidth := Max(ConfirmBtn.Width, CloseBtn.Width);
 CloseBtn.Constraints.MinWidth := ConfirmBtn.Constraints.MinWidth;

 LoadOptions;
end;

procedure TOptions.tbMaxNumberFileHistoryChange(Sender: TObject);
begin
 lNumberOf.Caption := '(' + IntToStr(tbMaxNumberFileHistory.Position) + ')';
end;

procedure TOptions.LoadOptions;
 Var F : File Of TRecOptions;
begin
 If FileExists(OptFName) Then
  Begin
   AssignFile(F, OptFName);
   Reset(F);

   Read(F, RecOptions);

   CloseFile(F);
  end;

 cbRememberWPos.Checked := RecOptions.RememberWindowsSizePos;
 cbStartWithOBA.Checked := RecOptions.StartWithOBA;
 cbGotoToLastRec.Checked := RecOptions.GotoToLastRecord;
 cbEnableToolbar.Checked := RecOptions.EnableToolBar;
 cbEnableStatusBar.Checked := RecOptions.EnaleStatusBar;
 cbAlternateColor.Selected := RecOptions.AlternateColor;
 tbMaxNumberFileHistory.Position := RecOptions.MaxHistoryRecords;
 cbShowSplashScreen.Checked := RecOptions.ShowSplashScreen;
end;

procedure TOptions.SaveOptions;
 Var F : File Of TRecOptions;
begin
 AssignFile(F, OptFName);
 ReWrite(F);

 Write(F, RecOptions);

 CloseFile(F);
end;

end.

