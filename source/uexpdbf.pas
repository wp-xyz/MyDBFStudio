unit uExpDBF;

// Todo: Copy CodePage from source table to destination table

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ComCtrls, Buttons, dbf_fields, db;

type

  { TExpDBF }

  TExpDBF = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    ClbField: TCheckListBox;
    lblExportField: TLabel;
    lblTableType: TLabel;
    lblProgress: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableType: TComboBox;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
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
begin
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
    // Save form position and size to ini
    Options.ExportDBFWindow.ExtractFromForm(Self);
end;

procedure TExpDBF.FormShow(Sender: TObject);
var
  ind: Integer;
begin
  ExportBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := ExportBtn.Constraints.MinWidth;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportDBFWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportDBFWindow.ApplyToForm(Self);
  end;
end;

function TExpDBF.ReturnTableLevel: Word;
const
  TABLE_LEVELS: array[0..3] of Integer = (3, 4, 7, 25);
begin
  if (TableType.ItemIndex >= 0) and (TableType.ItemIndex <= 3) then
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

  for Ind := 0 To ClbField.Items.Count - 1 do
    if ClbField.Checked[Ind] then
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
  rs: RawByteString;
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
      for i := 0 to ClbField.Items.Count - 1 do
        if ClbField.Checked[i] then
        begin
          srcField := DbfTable.FieldByName(ClbField.Items[i]);
          expField := ExpTable.FieldByName(ClbField.Items[i]);
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

  ClbField.Clear;
  for i := 0 to DbfTable.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(DbfTable.FieldDefs.Items[i].Name);
    ClbField.Checked[i] := True;
  end;
end;

end.

