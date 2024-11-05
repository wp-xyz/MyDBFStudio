unit uExpDBF;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ComCtrls, Buttons, Menus, dbf_fields, db;

type

  { TExpDBF }

  TExpDBF = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    clbFields: TCheckListBox;
    FieldsPopup: TPopupMenu;
    lblExportField: TLabel;
    lblTableType: TLabel;
    lblProgress: TLabel;
    mnuSelectAll: TMenuItem;
    mnuSelectNone: TMenuItem;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableType: TComboBox;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure mnuSelectAllClick(Sender: TObject);
    procedure mnuSelectNoneClick(Sender: TObject);
  private
    { private declarations }
    FDbfTable: TDbf;
    FExpTable: TDbf;
    Function ReturnTableLevel : Word;
    Procedure Create_Fields_List;
    Procedure Move_Records;
    procedure SetDbfTable(AValue: TDbf);
    property ExpTable: TDbf read FExpTable write FExpTable;
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write SetDbfTable;
  end;

var
  ExpDBF: TExpDBF;

implementation

{$R *.lfm}

uses
  Math, LConvEncoding, dbf_dbffile, uOptions;

{ TExpDBF }

procedure TExpDBF.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TExpDBF.ExportBtnClick(Sender: TObject);
var
  i: Integer;
  noneSelected: Boolean = true;
begin
  for i := 0 to clbFields.Items.Count-1 do
    if clbFields.Checked[i] then
    begin
      noneSelected := false;
      break;
    end;
  if noneSelected then
  begin
    clbFields.SetFocus;
    MessageDlg('No field selected for export.', mtError, [mbOK], 0);
    exit;
  end;

  if TableType.ItemIndex = -1 then
  begin
    TableType.SetFocus;
    MessageDlg('Table type not selected.', mtError, [mbOK], 0);
    exit;
  end;

  if not SaveExp.Execute then
    Exit;

  ExpTable.Free;
  ExpTable := TDbf.Create(self);
  try
    ExpTable.TableName := SaveExp.FileName;
    ExpTable.TableLevel := ReturnTableLevel;
    ExpTable.LanguageID := DbfTable.LanguageID;   // This copies the codepage
    Create_Fields_List();
    Move_Records();
    ExpTable.Close;
    Close;
    MessageDlg('Table successfully exported to ' + SaveExp.FileName, mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('Error writing file.' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TExpDBF.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    // Save form position and size to options (--> ini)
    Options.ExportDBFWindow.ExtractFromForm(Self);
    // Save selected table type to ini.
    if TableType.ItemIndex > -1 then
      Options.ExportDBFTableLevel := TableType.Items[TableType.ItemIndex];
  end;
end;

procedure TExpDBF.FormShow(Sender: TObject);
var
  i: Integer;
  idx: Integer;
begin
  ExportBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := ExportBtn.Constraints.MinWidth;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePosContent then
  begin
    if (Options.ExportDBFWindow.Width > 0) then
    begin
      AutoSize := false;
      Options.ExportDBFWindow.ApplyToForm(Self);
    end;
    // Find selected table type in options and restore it.
    idx := -1;
    for i := 0 to TableType.Items.Count-1 do
      if TableType.Items[i] = Options.ExportDBFTableLevel then
      begin
        idx := i;
        break;
      end;
    TableType.ItemIndex := idx;
  end;
end;

procedure TExpDBF.mnuSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbFields.Items.Count-1 do
    clbFields.Checked[i] := true;
end;

procedure TExpDBF.mnuSelectNoneClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbFields.Items.Count-1 do
    clbFields.Checked[i] := false;
end;

function TExpDBF.ReturnTableLevel: Word;
const
  TABLE_LEVELS: array[0..4] of Integer = (3, 4, 7, 25, 30);
begin
  if (TableType.ItemIndex >= 0) and (TableType.ItemIndex <= 4) then
    Result := TABLE_LEVELS[TableType.ItemIndex]
  else
    Result := 4;
end;

procedure TExpDBF.Create_Fields_List;
var
  Ind: Word;
  App: TDbfFieldDefs;
  TmpF: TDbfFieldDef;
begin
  App := TDbfFieldDefs.Create(Self);

  for Ind := 0 To clbFields.Items.Count - 1 do
    if clbFields.Checked[Ind] then
    begin
      TmpF := App.AddFieldDef;
      TmpF.AssignDb(DbfTable.FieldDefs[Ind]);
    end;

  if Assigned(App) then
    ExpTable.CreateTableEx(App);
end;

procedure TExpDBF.Move_Records;
var
  i, n: Integer;
  savedAfterScroll: TDatasetNotifyEvent;
  bm: TBookmark;
  counter: Integer;
  percent: Integer;
  srcField: TField;
  expField: TField;
  s: String;
  cp: String;
begin
  pBar.Min := 0;
  pBar.Max := 100;
  pBar.Position := 0;

  ExpTable.Open;
  cp := 'cp' + IntToStr(ExpTable.CodePage);

  n := DbfTable.ExactRecordCount;
  savedAfterScroll := DbfTable.AfterScroll;
  DbfTable.AfterScroll := nil;
  DbfTable.DisableControls;
  bm := DbfTable.GetBookmark;

  try

    DbfTable.First;
    counter := 0;

    while not DbfTable.EOF do
    begin
      ExpTable.Insert;
      for i := 0 to clbFields.Items.Count - 1 do
        if clbFields.Checked[i] then
        begin
          srcField := DbfTable.FieldByName(clbFields.Items[i]);
          expField := ExpTable.FieldByName(clbFields.Items[i]);
          if (srcField is TStringField) or (srcField is TMemoField) then
          begin
            s := srcField.AsString;
            expField.AsString := ConvertEncoding(s, 'utf-8', cp);
          end else
            expField.AsVariant := srcField.AsVariant;
        end;
      ExpTable.Post;
      DbfTable.Next;
      inc(counter);
      percent := (counter * 100) div n;
      if percent <> pBar.Position then
        pBar.Position := percent;
    end;

  finally
    DbfTable.AfterScroll := savedAfterScroll;
    DbfTable.EnableControls;
    DbfTable.GotoBookmark(bm);
    DbfTable.FreeBookmark(bm);
  end;
end;

procedure TExpDBF.SetDbfTable(AValue: TDbf);
var
  i: Integer;
begin
  if AValue = FDbfTable then
    exit;

  FDbfTable := AValue;

  clbFields.Clear;
  for i := 0 to DbfTable.FieldDefs.Count - 1 do
  begin
    clbFields.Items.Add(DbfTable.FieldDefs.Items[i].Name);
    clbFields.Checked[i] := True;
  end;
end;

end.

