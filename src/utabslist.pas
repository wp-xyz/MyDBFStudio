unit uTabsList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Buttons, Grids;

type

  { TTabsList }

  TTabsList = class(TForm)
    CloseBtn: TBitBtn;
    MoveUpBtn: TBitBtn;
    MoveDownBtn: TBitBtn;
    GoToTabBtn: TBitBtn;
    CloseTabBtn: TBitBtn;
    TabsGrid: TStringGrid;
    procedure CloseBtnClick(Sender: TObject);
    procedure CloseTabBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure GoToTabBtnClick(Sender: TObject);
    procedure MoveUpBtnClick(Sender: TObject);
    procedure MoveDownBtnClick(Sender: TObject);
  private
    { private declarations }
    Procedure Load_Tabs;
    procedure UpdateCmds;
  public
    { public declarations }
  end;

var
  TabsList: TTabsList;

implementation

uses
  uMain, uTabForm, uDbfTable, uOptions;

{$R *.lfm}

{ TTabsList }

procedure TTabsList.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.TabsListWindow.ExtractFromForm(Self);
end;

procedure TTabsList.FormShow(Sender: TObject);
begin
  Options.TabsListWindow.ApplyToForm(self);
  Load_Tabs;
  UpdateCmds;
end;

procedure TTabsList.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TTabsList.FormCreate(Sender: TObject);
begin
  if Options.UseAlternateColor then
    TabsGrid.AlternateColor := Options.AlternateColor
  else
    TabsGrid.AlternateColor := TabsGrid.Color;
  if Options.ShowGridLines then
    TabsGrid.Options := TabsGrid.Options + [goHorzLine]
  else
    TabsGrid.Options := TabsGrid.Options - [goHorzLine];
  TabsGrid.GridLineColor := Options.GridLineColor;
end;

procedure TTabsList.MoveUpBtnClick(Sender: TObject);
var
  oldPos : Integer;
begin
  if (TabsGrid.RowCount > TabsGrid.FixedRows + 1) and (TabsGrid.Row > TabsGrid.FixedRows) then
  begin
    oldPos := TabsGrid.Row - TabsGrid.FixedRows;
    Main.WorkSite.Pages[oldPos].PageIndex := oldPos - 1;
    Load_Tabs;
    TabsGrid.SetFocus;
    TabsGrid.Row := oldPos - 1 + TabsGrid.FixedRows;
    UpdateCmds;
  end;
end;

procedure TTabsList.MoveDownBtnClick(Sender: TObject);
var
  oldPos: Integer;
begin
  if (TabsGrid.RowCount > TabsGrid.FixedRows + 1) and (TabsGrid.Row < TabsGrid.RowCount - 1) then
  begin
    oldPos := TabsGrid.Row - TabsGrid.FixedRows;
    Main.WorkSite.Pages[oldPos].PageIndex := oldPos + 1;
    Load_Tabs;
    TabsGrid.SetFocus;
    TabsGrid.Row := oldPos + 1 + TabsGrid.FixedRows;
    UpdateCmds;
  end;
end;

procedure TTabsList.GoToTabBtnClick(Sender: TObject);
begin
  if TabsGrid.Row >= TabsGrid.FixedRows then
  begin
    Main.WorkSite.TabIndex := TabsGrid.Row - TabsGrid.FixedRows;
    Close;
  end;
end;

procedure TTabsList.CloseTabBtnClick(Sender: TObject);
begin
  if TabsGrid.Row >= TabsGrid.FixedRows then
  begin
    Main.WorkSite.TabIndex := TabsGrid.Row - TabsGrid.FixedRows;
    Main.WorkSite.Pages[Main.WorkSite.TabIndex].Free;
    Load_Tabs;
    UpdateCmds;
  end;
end;

procedure TTabsList.Load_Tabs;
var
  ind: Integer;
  Frm: TForm;
  sFile: String;
  row: Integer;
begin
  TabsGrid.BeginUpdate;
  try
    TabsGrid.RowCount := Main.WorkSite.PageCount + TabsGrid.FixedRows;
    if Main.Worksite.PageCount > 0 then
    begin
      row := TabsGrid.FixedRows;
      for ind := 0 to Main.WorkSite.PageCount - 1 do
      begin
        TabsGrid.Cells[0, row] := IntToStr(row);
        TabsGrid.Cells[1, row] := Main.WorkSite.Pages[ind].Caption;
        sFile := '';
        if (Main.WorkSite.Pages[ind] is TTabForm) then
        begin
          frm := TTabForm(Main.WorkSite.Pages[ind]).ParentForm;
          if frm is TDbfTable then
            with TDbfTable(frm) do
              sFile := DBTable.FilePathFull + DBTable.TableName;
        end;
        TabsGrid.Cells[2, row] := sFile;
        inc(row);
      end;
      TabsGrid.Row := Main.WorkSite.ActivePageIndex + TabsGrid.FixedRows;
    end;
  finally
    TabsGrid.EndUpdate;
  end;
end;

procedure TTabsList.UpdateCmds;
var
  hasData: Boolean;
begin
  hasData := TabsGrid.RowCount > TabsGrid.FixedRows;
  MoveUpBtn.Enabled := hasData and (TabsGrid.Row > TabsGrid.FixedRows);
  MoveDownBtn.Enabled := hasData and (TabsGrid.Row < TabsGrid.RowCount - 1);
  GoToTabBtn.Enabled := hasData and (TabsGrid.Row >= TabsGrid.FixedRows);
  CloseTabBtn.Enabled := hasData and (TabsGrid.Row >= TabsGrid.FixedRows);
end;

end.

