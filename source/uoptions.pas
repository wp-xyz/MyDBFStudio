unit uOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ColorBox, ComCtrls, Buttons, ExtCtrls, Spin;

type
  TRecOptions = Record
    RememberWindowSizePos     : Boolean;
    MainWindowState           : TWindowState;
    MainWidth                 : Integer;
    MainHeight                : Integer;
    MainTop                   : Integer;
    MainLeft                  : Integer;
    AddTablesWidth            : Integer;
    SubtractTablesWidth       : Integer;
    StartWithOBA              : Boolean;
    GotoLastRecord            : Boolean;
    EnableToolBar             : Boolean;
    EnableStatusBar           : Boolean;
    AlternateColor            : TColor;
    MaxHistoryRecords         : Integer;
    ShowSplashScreen          : Boolean;
  end;

var
  Options: TRecOptions = (
    RememberWindowSizePos: true;
    MainWindowState: wsNormal;
    MainWidth: 0;
    MainHeight: 0;
    MainTop: 0;
    MainLeft: 0;
    AddTablesWidth: 0;
    SubtractTablesWidth: 0;
    StartWithOBA: false;
    GotoLastRecord: false;
    EnableToolBar: true;
    EnableStatusBar: true;
    AlternateColor: clCream;
    MaxHistoryRecords: 10;
    ShowSplashScreen: true
  );

type
  { TOptionsForm }

  TOptionsForm = class(TForm)
    Bevel1: TBevel;
    ClearRecentBtn: TBitBtn;
    CloseBtn: TBitBtn;
    ConfirmBtn: TBitBtn;
    cbRememberWPos: TCheckBox;
    cbStartWithOBA: TCheckBox;
    cbGotoLastRec: TCheckBox;
    cbEnableToolbar: TCheckBox;
    cbEnableStatusBar: TCheckBox;
    cbAlternateColor: TColorBox;
    cbShowSplashScreen: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    seMaxNumberFileHistory: TSpinEdit;
    procedure CloseBtnClick(Sender: TObject);
    procedure ConfirmBtnClick(Sender: TObject);
    procedure ClearRecentBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    procedure OptionsToControls;
    procedure ControlsToOptions;
  public
    { public declarations }
  end;

var
  OptionsForm: TOptionsForm;

function IniFileName: String;
procedure LoadOptions;
procedure SaveOptions;


implementation

Uses Math, IniFiles, uMain;

{$R *.lfm}

{ TOptionsForm }

procedure TOptionsForm.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TOptionsForm.ConfirmBtnClick(Sender: TObject);
begin
  ControlsToOptions;
  SaveOptions;

  ShowMessage('Some changes will become effective only at the next reboot.');

  Close;
end;

procedure TOptionsForm.ClearRecentBtnClick(Sender: TObject);
var
  ini: TCustomIniFile;
begin
  if MessageDlg('Do you really want to clear the list of recently used files', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ini := TIniFile.Create(IniFileName);
    try
      ini.EraseSection('RecentFiles');
    finally
      ini.Free;
    end;
    Main.FileHistory.UpdateParentMenu;
    ShowMessage('History cleared.');
  end;
end;

procedure TOptionsForm.FormShow(Sender: TObject);
begin
  ConfirmBtn.Constraints.MinWidth := Max(ConfirmBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := ConfirmBtn.Constraints.MinWidth;

  LoadOptions;
  OptionsToControls;
end;

procedure TOptionsForm.ControlsToOptions;
begin
  Options.RememberWindowSizePos := cbRememberWPos.Checked;
  Options.StartWithOBA := cbStartWithOBA.Checked;
  Options.GotoLastRecord := cbGotoLastRec.Checked;
  Options.EnableToolBar := cbEnableToolbar.Checked;
  Options.EnableStatusBar := cbEnableStatusBar.Checked;
  Options.AlternateColor := cbAlternateColor.Selected;
  Options.MaxHistoryRecords := seMaxNumberFileHistory.Value;
  Options.ShowSplashScreen := cbShowSplashScreen.Checked;
end;

procedure TOptionsForm.OptionsToControls;
begin
  cbRememberWPos.Checked := Options.RememberWindowSizePos;
  cbStartWithOBA.Checked := Options.StartWithOBA;
  cbGoToLastRec.Checked := Options.GotoLastRecord;
  cbEnableToolbar.Checked := Options.EnableToolbar;
  cbEnableStatusBar.Checked := Options.EnableStatusbar;
  cbAlternateColor.Selected := Options.AlternateColor;
  seMaxNumberFileHistory.Value := Options.MaxHistoryRecords;
  cbShowSplashScreen.Checked := Options.ShowSplashScreen;
end;


{ Global procedures }

function IniFileName: String;
begin
  Result := ChangeFileExt(GetAppConfigFile(false), '.ini');
end;

procedure LoadOptions;
var
  ini: TCustomIniFile;
begin
  ini := TIniFile.Create(IniFileName);
  try
    Options.RememberWindowSizePos := ini.ReadBool('Options', 'RememberWindowSizePos',
      Options.RememberWindowSizePos);
    if Options.RememberWindowSizePos then
    begin
      Options.MainWindowState := TWindowState(ini.ReadInteger('Options', 'MainWindowState',
        Integer(Options.MainWindowState)));
      if Options.MainWindowState = wsNormal then
      begin
        Options.MainWidth := ini.ReadInteger('Options', 'MainWidth', Options.MainWidth);
        Options.MainHeight := ini.ReadInteger('Options', 'MainHeight', Options.MainHeight);
        Options.MainLeft := ini.ReadInteger('Options', 'MainLeft', Options.MainLeft);
        Options.MainTop := ini.ReadInteger('Options', 'MainTop', Options.MainTop);
      end;
      Options.AddTablesWidth := ini.ReadInteger('Options', 'AddTablesWidth', Options.AddTablesWidth);
      Options.SubtractTablesWidth := ini.ReadInteger('Options', 'SubtractTablesWidth', Options.SubtractTablesWidth);
    end;
    Options.StartWithOBA := ini.ReadBool('Options', 'StartWithOBA', Options.StartWithOBA);
    Options.GotoLastRecord := ini.ReadBool('Options', 'GotoLastRecord', Options.GotoLastRecord);
    Options.EnableToolbar := ini.ReadBool('Options', 'EnableToolbar', Options.EnableToolbar);
    Options.EnableStatusbar := ini.ReadBool('Options', 'EnableStatusbar', Options.EnableStatusbar);
    Options.AlternateColor := TColor(ini.ReadInteger('Options', 'AlternateColor', Integer(Options.AlternateColor)));
    Options.MaxHistoryRecords := ini.ReadInteger('Options', 'MaxHistoryRecords', Options.MaxHistoryRecords);
    Options.ShowSplashScreen := ini.ReadBool('Options', 'ShowSplashScreen', Options.ShowSplashScreen);
  finally
    ini.Free;
  end;
end;

procedure SaveOptions;
var
  ini: TCustomIniFile;
begin
  ini := TIniFile.Create(IniFileName);
  try
    ini.WriteBool('Options', 'RememberWindowSizePos', Options.RememberWindowSizePos);
    ini.WriteInteger('Options', 'MainWindowState', ord(Options.MainWindowState));
    if Options.MainWindowState = wsNormal then
    begin
      ini.WriteInteger('Options', 'MainWidth', Options.MainWidth);
      ini.WriteInteger('Options', 'MainHeight', Options.MainHeight);
      ini.WriteInteger('Options', 'MainLeft', Options.MainLeft);
      ini.WriteInteger('Options', 'MainTop', Options.MainTop);
    end;
    ini.WriteInteger('Options', 'AddTablesWidth', Options.AddTablesWidth);
    ini.WriteInteger('Options', 'SubtractTablesWidth', Options.SubtractTablesWidth);
    ini.WriteBool('Options', 'StartWithOBA', Options.StartWithOBA);
    ini.WriteBool('Options', 'GotoLastRecord', Options.GotoLastRecord);
    ini.WriteBool('Options', 'EnableToolbar', Options.EnableToolbar);
    ini.WriteBool('Options', 'EnableStatusbar', Options.EnableStatusbar);
    ini.WriteInteger('Options', 'AlternateColor', integer(Options.AlternateColor));
    ini.WriteInteger('Options', 'MaxHistoryRecords', Options.MaxHistoryRecords);
    ini.WriteBool('Options', 'ShowSplashScreen', Options.ShowSplashScreen);
  finally
    ini.Free;
  end;
end;

end.

