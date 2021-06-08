unit uOptions;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ColorBox, ComCtrls, Buttons, ExtCtrls, Spin, IniFiles;

type
  TWindowOptions = record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    procedure Init;
    procedure ApplyToForm(AForm: TForm);
    procedure ExtractFromForm(AForm: TForm);
    procedure ReadFromIni(AIniFile: TCustomIniFile; ASection: String);
    procedure WriteToIni(AIniFile: TCustomIniFile; ASection: String);
  end;

  TRecOptions = Record
    RememberWindowSizePos         : Boolean;
    MainWindowState               : TWindowState;
    MainWidth                     : Integer;
    MainHeight                    : Integer;
    MainTop                       : Integer;
    MainLeft                      : Integer;
    ExportCSVWindow               : TWindowOptions;
    ExportHTMLWindow              : TWindowOptions;
    ExportXLSWindow               : TWindowOptions;
    ExportDBFWindow               : TWindowOptions;
    ExportDBFTableLevel           : String;
    ExportXMLWindow               : TWindowOptions;
    ExportSQLScriptWindow         : TWindowOptions;
    ExportSQLScriptItems          : Integer;
    ExportSQLScriptDateFormat     : String;
    ExportSQLScriptTimeFormat     : String;
    ExportSQLScriptDateTimeFormat : String;
    ExportSQLScriptDateSeparator  : String;
    ExportSQLScriptTimeSeparator  : String;
    AddTablesWindow               : TWindowOptions;
    AddAliasWindow                : TWindowOptions;
    SubtractTablesWindow          : TWindowOptions;
    SortTableWindow               : TWindowOptions;
    TabsListWindow                : TWindowOptions;
    RestructureWindow             : TWindowOptions;
    SetFieldValueWindow           : TWindowOptions;
    IndexTableWindow              : TWindowOptions;
    OptionsWindow                 : TWindowOptions;
    StartWithOBA                  : Boolean;
    GotoLastRecord                : Boolean;
    EnableToolBar                 : Boolean;
    EnableStatusBar               : Boolean;
    AlternateColor                : TColor;
    MaxHistoryRecords             : Integer;
    ShowSplashScreen              : Boolean;
  end;

var
  Options: TRecOptions = (
    RememberWindowSizePos: true;
    MainWindowState: wsNormal;
    MainWidth: 0;
    MainHeight: 0;
    MainTop: 0;
    MainLeft: 0;
    ExportCSVWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    ExportHTMLWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    ExportXLSWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    ExportDBFWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    ExportDBFTableLevel: '';
    ExportXMLWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    ExportSQLScriptWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    ExportSQLScriptItems: 0;
    ExportSQLScriptDateFormat: '';
    ExportSQLScriptTimeFormat: '';
    ExportSQLScriptDateTimeFormat: '';
    ExportSQLScriptDateSeparator: '';
    ExportSQLScriptTimeSeparator: '';
    AddTablesWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    AddAliasWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    SubtractTablesWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    SortTableWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    TabsListWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    RestructureWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    SetFieldValueWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    IndexTableWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
    OptionsWindow: (Left:-1; Top:-1; Width:-1; Height:-1);
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
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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

uses
  Math, uMain;

{$R *.lfm}

procedure TWindowOptions.Init;
begin
  Left := -1;
  Top := -1;
  Width := -1;
  Height := -1;
end;

procedure TWindowOptions.ApplyToForm(AForm: TForm);
var
  R: TRect;
  W, H: Integer;
begin
  if not Options.RememberWindowSizePos then
    exit;

  R := Screen.WorkAreaRect;

  if AForm.AutoSize then
  begin
    W := AForm.Width;
    H := AForm.Height;
  end else
  begin
    if Width = -1 then
      W := AForm.Width
    else
      W := Width;
    if W > R.Width then
      W := R.Width;
    if Height = -1 then
      H := AForm.Height
    else
      H := Height;
    if Height > R.Height then
      H := R.Height;
  end;

  if (Left <> -1) then
  begin
    if (Left < R.Left) then Left := R.Left;
    if Left + W > R.Right then Left := R.Right - W;
  end else
    Left := AForm.Left;

  if (Top <> -1) then
  begin
    if Top < R.Top then Top := R.Top;
    if Top + H > R.Bottom then Top := R.Bottom - H;
  end else
    Top := AForm.Top;

  AForm.Position := poDesigned;
  AForm.SetBounds(Left, Top, W, H);
end;

procedure TWindowOptions.ExtractFromForm(AForm: TForm);
begin
  Left := AForm.Left;
  Top := AForm.Top;
  Width := AForm.Width;
  Height := AForm.Height;
end;

procedure TWindowOptions.ReadFromIni(AIniFile: TCustomIniFile; ASection: String);
begin
  Left := AIniFile.ReadInteger(ASection, 'Left', Left);
  Top := AIniFile.ReadInteger(ASection, 'Top', Top);
  Width := AIniFile.ReadInteger(ASection, 'Width', Width);
  Height := AIniFile.ReadInteger(ASection, 'Height', Height);
end;

procedure TWindowOptions.WriteToIni(AIniFile: TCustomIniFile; ASection: String);
begin
  AIniFile.WriteInteger(ASection, 'Left', Left);
  AIniFile.WriteInteger(ASection, 'Top', Top);
  AIniFile.WriteInteger(ASection, 'Width', Width);
  AIniFile.WriteInteger(ASection, 'Height', Height);
end;


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
begin
  if MessageDlg('Do you really want to clear the list of recently used files', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    Main.FileHistory.Clear;
end;

procedure TOptionsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.OptionsWindow.ExtractFromForm(Self);
end;

procedure TOptionsForm.FormShow(Sender: TObject);
begin
  ConfirmBtn.Constraints.MinWidth := Max(ConfirmBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := ConfirmBtn.Constraints.MinWidth;

  OptionsToControls;
  Options.OptionsWindow.ApplyToForm(Self);
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
      Options.MainWindowState := TWindowState(ini.ReadInteger('MainForm', 'WindowState',
        Integer(Options.MainWindowState)));
      if Options.MainWindowState = wsNormal then
      begin
        Options.MainWidth := ini.ReadInteger('MainForm', 'Width', Options.MainWidth);
        Options.MainHeight := ini.ReadInteger('MainForm', 'Height', Options.MainHeight);
        Options.MainLeft := ini.ReadInteger('MainForm', 'Left', Options.MainLeft);
        Options.MainTop := ini.ReadInteger('MainForm', 'Top', Options.MainTop);
      end;

      Options.ExportCSVWindow.ReadFromIni(ini, 'ExportCSVForm');
      Options.ExportHTMLWindow.ReadFromIni(ini, 'ExportHTMLForm');
      Options.ExportXLSWindow.ReadFromIni(ini, 'ExportXLSForm');

      Options.ExportDBFWindow.ReadFromIni(ini, 'ExportDBFForm');
      Options.ExportDBFTableLevel := ini.ReadString('ExportDBFForm', 'TableLevel', '');

      Options.ExportXMLWindow.ReadFromIni(ini, 'ExportXMLForm');

      Options.ExportSQLScriptWindow.ReadFromIni(ini, 'ExportSQLScriptForm');
      Options.ExportSQLScriptItems := ini.ReadInteger('ExportSQLScriptForm', 'Items', 0);
      Options.ExportSQLScriptDateFormat := ini.ReadString('ExportSQLScriptForm', 'DateFormat', '');
      Options.ExportSQLScriptTimeFormat := ini.ReadString('ExportSQLScriptForm', 'TimeFormat', '');
      Options.ExportSQLScriptDateTimeFormat := ini.ReadString('ExportSQLScriptForm', 'DateTimeFormat', '');
      Options.ExportSQLSCriptDateSeparator := ini.ReadString('ExportSQLScriptForm', 'DateSeparator', '');
      Options.ExportSQLSCriptTimeSeparator := ini.ReadString('ExportSQLScriptForm', 'TimeSeparator', '');

      Options.AddTablesWindow.ReadFromIni(ini, 'AddTablesForm');
      Options.AddAliasWindow.ReadFromIni(ini, 'AddAliasForm');
      Options.SubtractTablesWindow.ReadFromIni(ini, 'SubtractTablesForm');
      Options.SortTableWindow.ReadFromIni(ini, 'SortTableForm');
      Options.TabsListWindow.ReadFromIni(ini, 'TabsListForm');
      Options.RestructureWindow.ReadFromIni(ini, 'RestructureForm');
      Options.SetFieldValueWindow.ReadFromIni(ini, 'SetFieldValueForm');
      Options.IndexTableWindow.ReadFromIni(ini, 'IndexTableForm');
      Options.OptionsWindow.ReadFromIni(ini, 'OptionsForm');
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
    ini.WriteBool('Options', 'StartWithOBA', Options.StartWithOBA);
    ini.WriteBool('Options', 'GotoLastRecord', Options.GotoLastRecord);
    ini.WriteBool('Options', 'EnableToolbar', Options.EnableToolbar);
    ini.WriteBool('Options', 'EnableStatusbar', Options.EnableStatusbar);
    ini.WriteInteger('Options', 'AlternateColor', integer(Options.AlternateColor));
    ini.WriteInteger('Options', 'MaxHistoryRecords', Options.MaxHistoryRecords);
    ini.WriteBool('Options', 'ShowSplashScreen', Options.ShowSplashScreen);

    ini.WriteInteger('MainForm', 'WindowState', ord(Options.MainWindowState));
    if Options.MainWindowState = wsNormal then
    begin
      ini.WriteInteger('MainForm', 'Width', Options.MainWidth);
      ini.WriteInteger('MainForm', 'Height', Options.MainHeight);
      ini.WriteInteger('MainForm', 'Left', Options.MainLeft);
      ini.WriteInteger('MainForm', 'Top', Options.MainTop);
    end;

    Options.ExportCSVWindow.WriteToIni(ini, 'ExportCSVForm');
    Options.ExportHTMLWindow.WriteToIni(ini, 'ExportHTMLForm');
    Options.ExportXLSWindow.WriteToIni(ini, 'ExportXLSForm');

    Options.ExportDBFWindow.WriteToIni(ini, 'ExportDBFForm');
    ini.WriteString('ExportDBFForm', 'TableLevel', Options.ExportDBFTableLevel);

    Options.ExportXMLWindow.WriteToIni(ini, 'ExportXMLForm');

    Options.ExportSQLScriptWindow.WriteToIni(ini, 'ExportSQLScriptForm');
    ini.WriteInteger('ExportSQLScriptForm', 'Items', Options.ExportSQLScriptItems);
    ini.WriteString('ExportSQLScriptForm', 'DateFormat', Options.ExportSQLScriptDateFormat);
    ini.WriteString('ExportSQLScriptForm', 'TimeFormat', Options.ExportSQLScriptTimeFormat);
    ini.WriteString('ExportSQLScriptForm', 'DateTimeFormat', Options.ExportSQLScriptDateTimeFormat);
    ini.WriteString('EXportSQLScriptForm', 'DateSeparator', Options.ExportSQLScriptDateSeparator);
    ini.WriteString('EXportSQLScriptForm', 'TimeSeparator', Options.ExportSQLScriptTimeSeparator);

    Options.AddTablesWindow.WriteToIni(ini, 'AddTablesForm');
    Options.AddAliasWindow.WriteToIni(ini, 'AddAliasForm');
    Options.SubtractTablesWindow.WriteToIni(ini, 'SubtractTablesForm');
    Options.SortTableWindow.WriteToIni(ini, 'SortTableForm');
    Options.TabsListWindow.WriteToIni(ini, 'TabListForm');
    Options.RestructureWindow.WriteToIni(ini, 'RestructureForm');
    Options.SetFieldValueWindow.WriteToIni(ini, 'SetFieldValueForm');
    Options.IndexTableWindow.WriteToIni(ini, 'IndexTableForm');
    Options.OptionsWindow.WriteToIni(ini, 'OptionsForm');
  finally
    ini.Free;
  end;
end;

end.

