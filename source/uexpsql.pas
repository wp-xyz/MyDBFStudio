unit uExpSQL;

{ todo: Export MEMO and BLOB fields }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  CheckLst, StdCtrls, ComCtrls, Buttons, ExtCtrls, Menus, DB;

type

  { TExpSQL }

  TExpSQL = class(TForm)
    Bevel1: TBevel;
    cbDateFmt: TComboBox;
    cbDateSep: TComboBox;
    cbTimeSep: TComboBox;
    cbTimeFmt: TComboBox;
    cbDateTimeFmt: TComboBox;
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    clbFields: TCheckListBox;
    cbCreateTable: TCheckBox;
    cbExportRec: TCheckBox;
    FieldsPopup: TPopupMenu;
    lblDateFmt: TLabel;
    lblTimeFmt: TLabel;
    lblDateTimeFmt: TLabel;
    lblDateSep: TLabel;
    lblTimeSep: TLabel;
    lblExportFields: TLabel;
    lblProgress: TLabel;
    mnuSelectAll: TMenuItem;
    mnuSelectNone: TMenuItem;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    procedure cbExportRecChange(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mnuSelectAllClick(Sender: TObject);
    procedure mnuSelectNoneClick(Sender: TObject);
  private
    { private declarations }
    FDbfTable: TDbf;
    Procedure GenCreateTableScript;
    Function Remove_FileExtension(Val : String) : String;
    Function ConvertFloat(Val : String) : String;
    procedure CreateSQLScript;
    function Validate(out AMsg: String; out AControl: TWinControl): Boolean;
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write FDbfTable;
  end;

var
  ExpSQL: TExpSQL;

implementation

{$R *.lfm}

uses
  Math, uOptions;

{ TExpSQL }

procedure TExpSQL.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.ExportSQLScriptWindow.ExtractFromForm(Self);
    Options.ExportSQLScriptItems := 0;
    if cbCreateTable.Checked then inc(Options.ExportSQLScriptItems, 1);
    if cbExportRec.Checked then inc(Options.ExportSQLScriptItems, 2);
    Options.ExportSQLScriptDateFormat := cbDateFmt.Text;
    Options.ExportSQLScriptTimeFormat := cbTimeFmt.Text;
    Options.ExportSQLScriptDateTimeFormat := cbDateTimeFmt.Text;
    Options.ExportSQLScriptDateSeparator := cbDateSep.Text;
    Options.ExportSQLScriptTimeSeparator := cbTimeSep.Text;
  end;
end;

procedure TExpSQL.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
end;

procedure TExpSQL.FormShow(Sender: TObject);
var
  ind: Integer;
  w: Integer;
begin
  w := Max(ExportBtn.Width, CloseBtn.Width);
  w := Max(w, (cbCreateTable.Width - ExportBtn.BorderSpacing.Right) div 2);
  ExportBtn.Constraints.MinWidth := w;
  CloseBtn.Constraints.MinWidth := w;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePosContent then
  begin
    if (Options.ExportSQLScriptWindow.Width > 0) then
    begin
      AutoSize := false;
      Options.ExportSQLScriptWindow.ApplyToForm(Self);
    end;
    cbCreateTable.Checked := Options.ExportSQLScriptItems and 1 <> 0;
    cbExportRec.Checked := Options.ExportSQLScriptItems and 2 <> 0;
    cbDateFmt.Text := Options.ExportSQLScriptDateFormat;
    cbTimeFmt.Text := Options.ExportSQLScriptTimeFormat;
    cbDateTimeFmt.Text := Options.ExportSQLScriptDateTimeFormat;
    cbDateSep.Text := Options.ExportSQLScriptDateSeparator;
    cbTimeSep.Text := Options.ExportSQLScriptTimeSeparator;
  end;

  clbFields.Clear;
  for ind := 0 to DbfTable.FieldDefs.Count - 1 do
  begin
    clbFields.Items.Add(DbfTable.FieldDefs.Items[ind].Name);
    clbFields.Checked[ind] := True;
  end;
end;

procedure TExpSQL.mnuSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbFields.Items.Count-1 do
    clbFields.Checked[i] := true;
end;

procedure TExpSQL.mnuSelectNoneClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbFields.Items.Count-1 do
    clbFields.Checked[i] := false;
end;

procedure TExpSQL.GenCreateTableScript;
var
  App: String;
  F: TextFile;
  Ind: Word;
  Str: TStringList;
  field: TField;
begin
  App := Remove_FileExtension(ExtractFileName(SaveExp.FileName));
  App := App + '-crt.sql';
  App := ExtractFilePath(SaveExp.FileName) + App;

  AssignFile(F,App);
  ReWrite(F);

  Str := TStringList.Create;
  try
    for Ind := 0 To clbFields.Items.Count - 1 do
      if clbFields.Checked[Ind] then
      begin
        field := DbfTable.FieldByName(clbFields.Items[Ind]);
        case field.DataType Of
          ftString,
          ftFixedChar,
          ftWideString,
          ftFixedWideChar:
            Str.Add(Format('      %s VARCHAR(%d) CHARACTER SET WIN1252',
              [clbFields.Items[Ind], field.DataSize]));

          ftSmallint,
          ftInteger,
          ftWord,
          ftBytes,
          ftVarBytes:
            Str.Add(Format('      %s INTEGER', [clbFields.Items[Ind]]));

          ftAutoInc,
          ftLargeint:
            Str.Add(Format('      %s DOUBLE PRECISION', [clbFields.ITems[ind]]));

          ftFloat,
          ftCurrency,
          ftBCD:
            Str.Add(Format('      %s NUMERIC (%d,%d)',
              [clbFields.Items[Ind], field.DataSize, Field.DataSize]));

          ftBoolean:
            Str.Add(Format('      %s CHAR(1) CHARACTER SET WIN1252', [clbFields.Items[ind]]));

          ftDate,
          ftDateTime:
            Str.Add(Format('      %s DATE', [clbFields.Items[ind]]));

          ftTime:
            Str.Add(Format('      %s TIME', [clbFields.Items[ind]]));
        end;
      end;

    if Str.Count > 0 then
    begin
      Writeln(F, Format('CREATE TABLE %s (', [UpperCase(Remove_FileExtension(DbfTable.TableName))]));

      for Ind := 0 To Str.Count - 1 do
        if Ind < Str.Count - 1 then
          Writeln(F, Str.Strings[Ind] + ',')
        else
          Writeln(F, Str.Strings[Ind]);

      Writeln(F, ');');
    end;

  finally
    System.Close(F);
    Str.Free;
  end;
end;

function TExpSQL.Remove_FileExtension(Val: String): String;
 Var Ind : Word;
begin
 Result := '';

 If Val <> '' Then
  For Ind := 1 To Pos('.',Val) - 1 Do
   Result := Result + Val[Ind];
end;

function TExpSQL.ConvertFloat(Val: String): String;
var
  i: Integer;
begin
  Result := Val;
  for i := 1 to Length(Result) do
    if Result[i] = ',' then Result[i] := '.';
end;

procedure TExpSQL.CreateSQLScript;
const
  INDENT = '  ';
var
  i, n: Integer;
  Str : TStringList;
  F : TextFile;
  field: TField;
  savedAfterScroll: TDatasetNotifyEvent;
  bm: TBookMark;
  counter: Integer;
  percent: Integer;
  fs: TFormatSettings;
begin
  pBar.Min := 0;
  pBar.Max := 100;
  pBar.Position := 0;

  savedAfterScroll := DbfTable.AfterScroll;
  DbfTable.AfterScroll := nil;
  DbfTable.DisableControls;
  bm := DbfTable.GetBookmark;
  n := DbfTable.ExactRecordCount;

  fs := FormatSettings;
  if cbDateSep.Text <> '' then fs.DateSeparator := cbDateSep.Text[1];
  if cbTimeSep.Text <> '' then fs.TimeSeparator := cbTimeSep.Text[1];

  Str := TStringList.Create;
  try
    AssignFile(F, SaveExp.FileName);
    ReWrite(F);

    DbfTable.First;
    counter := 0;

    while not DbfTable.EOF do
    begin
      Str.Clear;

      for i := 0 To clbFields.Items.Count - 1 do
        if clbFields.Checked[i] then
        begin
          field := DbfTable.FieldByName(clbFields.Items[i]);
          case field.DataType of
            ftString,
            ftFixedChar,
            ftWideString,
            ftFixedWideChar:
              if field.AsString <> '' then
                Str.Add(INDENT + QuotedStr(field.AsString))
              else
                Str.Add(INDENT + QuotedStr(''));

            ftAutoInc,
            ftLargeint,
            ftSmallint,
            ftInteger,
            ftWord,
            ftBytes,
            ftVarBytes:
              if field.AsString <> '' then
                Str.Add(INDENT + field.AsString)
              else
                Str.Add(INDENT + 'NULL');

            ftFloat,
            ftCurrency,
            ftBCD:
              if field.AsString <> '' then
                Str.Add(INDENT + ConvertFloat(field.AsString))
              else
                Str.Add(INDENT + 'NULL');

            ftBoolean:
              if field.AsBoolean then
                Str.Add(INDENT + '1')
              else
                Str.Add(INDENT + '0');

            ftDate:
              if field.AsString <> '' then
                Str.Add(INDENT + FormatDateTime(cbDateFmt.Text, field.AsDateTime, fs))
              else
                Str.Add(INDENT + 'NULL');

            ftDateTime:
              if field.AsString <> '' then
                Str.Add(INDENT + FormatDateTime(cbDateTimeFmt.Text, field.AsDateTime, fs))
              else
                Str.Add(INDENT + 'NULL');

            ftTime:
              if field.AsString <> '' then
                Str.Add(INDENT + FormatDateTime(cbTimeFmt.Text, field.AsDateTime, fs))
              else
                Str.Add(INDENT + 'NULL');
          end;
        end;

      DbfTable.Next;

      if Str.Count > 0 then
      begin
        Writeln(F, Format('INSERT INTO %s VALUES(', [UpperCase(Remove_FileExtension(DbfTable.TableName))]));

        for i := 0 to Str.Count - 1 do
          if i < Str.Count - 1 then
            Writeln(F, Str.Strings[i] + ',')
          else
            Writeln(F, Str.Strings[i]);

        Writeln(F, ');');
      end;

      inc(counter);
      percent := (counter * 100) div n;
      if percent <> pBar.Position then
        pBar.Position := percent;;
    end;

  finally
    System.Close(F);
    Str.Free;

    DbfTable.AfterScroll := savedAfterScroll;
    DbfTable.EnableControls;
    DbfTable.GotoBookmark(bm);
    DbfTable.FreeBookmark(bm);
  end;
end;

procedure TExpSQL.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TExpSQL.cbExportRecChange(Sender: TObject);
var
  doExportRec: Boolean;
begin
  doExportRec := cbExportRec.Checked;
  lblDateSep.Enabled := doExportRec;
  cbDateSep.Enabled := doExportRec;
  lblTimeSep.Enabled := doExportRec;
  cbTimeSep.Enabled := doExportRec;
  lblDateFmt.Enabled := doExportRec;
  cbDateFmt.Enabled := doExportRec;
  lblTimeFmt.Enabled := doExportRec;
  cbTimeFmt.Enabled := doExportRec;
  lblDateTimeFmt.Enabled := doExportRec;
  cbDateTimeFmt.Enabled := doExportRec;
end;

procedure TExpSQL.ExportBtnClick(Sender: TObject);
var
  C: TWinControl;
  msg: String;
begin
  if not Validate(msg, C) then
  begin
    C.SetFocus;
    MessageDlg(msg, mtError, [mbOK], 0);
    exit;
  end;

  if not SaveExp.Execute then
    exit;

  try
    if cbCreateTable.Checked then
      GenCreateTableScript;

    if cbExportRec.Checked then
      CreateSQLScript;

    Close;
    MessageDlg('Table successfully exported.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('Error writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

function TExpSQL.Validate(out AMsg: String; out AControl: TWinControl): Boolean;
var
  f: TField;
  i: Integer;
  noneSelected: Boolean = true;
begin
  Result := false;

  for i := 0 to clbFields.Items.Count-1 do
    if clbFields.Checked[i] then
    begin
      noneSelected := false;
      break;
    end;
  if noneSelected then
  begin
    AControl := clbFields;
    AMsg := 'No field selected for export.';
    exit;
  end;

  if not (cbCreateTable.Checked or cbExportRec.Checked) then
  begin
    AControl := cbCreateTable;
    AMsg := 'No script item selected.';
    exit;
  end;

  if cbExportRec.Checked then
    for f in DbfTable.Fields do
    begin
      if (f.DataType in [ftDate, ftDateTime]) and (cbDateSep.Text = '') then
      begin
        AControl := cbDateSep;
        AMsg := 'Date separator not specified.';
        exit;
      end;
      if (f.DataType in [ftTime, ftDateTime]) and (cbTimeSep.Text = '') then
      begin
        AControl := cbTimeSep;
        AMsg := 'Time separator not specified.';
        exit;
      end;
      if (f.DataType = ftDate) and (cbDateFmt.Text = '') then
      begin
        AControl := cbDateFmt;
        AMsg := 'No date format specified.';
        exit;
      end;
      if (f.DataType = ftTime) and (cbTimeFmt.Text = '') then
      begin
        AControl := cbTimeFmt;
        AMsg := 'No time format specified.';
        exit;
      end;
      if (f.DataType = ftDateTime) and (cbDateTimeFmt.Text = '') then
      begin
        AControl := cbDateTimeFmt;
        AMsg := 'No date/time format specified.';
        exit;
      end;
    end;

  Result := true;
end;

end.

