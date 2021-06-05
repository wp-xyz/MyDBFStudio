unit uExpSQL;

{todo: Export MEMO and BLOB fields }
{todo: Allow selection of code page }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  CheckLst, StdCtrls, ComCtrls, Buttons, DB;

type

  { TExpSQL }

  TExpSQL = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    ClbField: TCheckListBox;
    CrTab: TCheckBox;
    ExpRec: TCheckBox;
    lblExportFields: TLabel;
    lblProgress: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FDbfTable: TDbf;
    Procedure GenCreateTableScript;
    Function Remove_FileExtension(Val : String) : String;
    Function ConvertFloat(Val : String) : String;
    Procedure CreateSQLScript;
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
    Options.ExportSQLScriptWindow.ExtractFromForm(Self);
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
  w := Max(w, (crTab.Width - ExportBtn.BorderSpacing.Right) div 2);
  ExportBtn.Constraints.MinWidth := w;
  CloseBtn.Constraints.MinWidth := w;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportSQLScriptWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportSQLScriptWindow.ApplyToForm(Self);
  end;

  ClbField.Clear;

  for ind := 0 to DbfTable.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(DbfTable.FieldDefs.Items[ind].Name);
    ClbField.Checked[ind] := True;
  end;
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
    for Ind := 0 To ClbField.Items.Count - 1 do
      if ClbField.Checked[Ind] then
      begin
        field := DbfTable.FieldByName(ClbField.Items[Ind]);
        case field.DataType Of
          ftString,
          ftFixedChar,
          ftWideString,
          ftFixedWideChar:
            Str.Add(Format('      %s VARCHAR(%d) CHARACTER SET WIN1252',
              [ClbField.Items[Ind], field.DataSize]));

          ftSmallint,
          ftInteger,
          ftWord,
          ftBytes,
          ftVarBytes:
            Str.Add(Format('      %s INTEGER', [ClbField.Items[Ind]]));

          ftAutoInc,
          ftLargeint:
            Str.Add(Format('      %s DOUBLE PRECISION', [ClbField.ITems[ind]]));

          ftFloat,
          ftCurrency,
          ftBCD:
            Str.Add(Format('      %s NUMERIC (%d,%d)',
              [ClbField.Items[Ind], field.DataSize, Field.DataSize]));

          ftBoolean:
            Str.Add(Format('      %s CHAR(1) CHARACTER SET WIN1252', [ClbField.Items[ind]]));

          ftDate,
          ftDateTime:
            Str.Add(Format('      %s DATE', [ClbField.Items[ind]]));

          ftTime:
            Str.Add(Format('      %s TIME', [ClbField.Items[ind]]));
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
 Var I : Word;
begin
 Result := Val;

 If Pos(',',Val) > 0 Then
  Begin
   Result := '';

   For I := 1 To Pos(',',Val) - 1 Do
    Result := Result + Val[I];

   Result := Result + '.';

   For I := Pos(',',Val) + 1 To Length(Val) Do
    Result := Result + Val[I];
  End;
end;

procedure TExpSQL.CreateSQLScript;
var
  Ind : Word;
  Str : TStringList;
  F : TextFile;
  field: TField;
begin
  DbfTable.First;
  pBar.Min := 0;
  pBar.Max := DbfTable.ExactRecordCount;
  pBar.Position := 0;

  Str := TStringList.Create;
  try
    AssignFile(F, SaveExp.FileName);
    ReWrite(F);

    while not DbfTable.EOF do
    begin
      Str.Clear;

      for Ind := 0 To ClbField.Items.Count - 1 do
        if ClbField.Checked[Ind] then
        begin
          field := DbfTable.FieldByName(ClbField.Items[Ind]);
          case field.DataType of
            ftString,
            ftFixedChar,
            ftWideString,
            ftFixedWideChar:
              if field.AsString <> '' then
                Str.Add(Format('      %s', [QuotedStr(field.AsString)]))
              else
                Str.Add(Format('      %s', [QuotedStr('')]));

            ftAutoInc,
            ftLargeint,
            ftSmallint,
            ftInteger,
            ftWord,
            ftBytes,
            ftVarBytes:
              if field.AsString <> '' then
                Str.Add(Format('      %s', [field.AsString]))
              else
                Str.Add(       '      NULL');

            ftFloat,
            ftCurrency,
            ftBCD:
              if field.AsString <> '' then
                Str.Add(Format('      %s', [ConvertFloat(field.AsString)]))
              else
                Str.Add(       '      NULL');

            ftBoolean:
              if field.AsBoolean then
                Str.Add(       '      1')
              else
                Str.Add(       '      0');

            ftDate:
              if field.AsString <> '' then
                Str.Add(Format('      %s', [DateToStr(field.AsDateTime)]))   // todo: Is this the right format???
              else
                Str.Add(       '      NULL');

            ftDateTime:
              if field.AsString <> '' then
                Str.Add(Format('      %s', [DateTimeToStr(field.AsDateTime)]))  // todo: Is this the right format ???
              else
                Str.Add(       '      NULL');

            ftTime:
              if field.AsString <> '' then
                Str.Add(Format('      %s', [TimeToStr(field.AsDateTime)]))   // todo: Is this format correct?
              else
                Str.Add(       '      NULL');
          end;
        end;

      DbfTable.Next;

      if Str.Count > 0 then
      begin
        Writeln(F, Format('INSERT INTO %s VALUES(', [UpperCase(Remove_FileExtension(DbfTable.TableName))]));

        for Ind := 0 To Str.Count - 1 do
          if Ind < Str.Count - 1 then
            Writeln(F, Str.Strings[Ind] + ',')
          else
            Writeln(F, Str.Strings[Ind]);

        Writeln(F, ');');
      end;

      pBar.Position := pBar.Position + 1;
    end;

  finally
    pBar.Position := 0;
    System.Close(F);
    Str.Free;
  end;
end;

procedure TExpSQL.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TExpSQL.ExportBtnClick(Sender: TObject);
begin
  if not SaveExp.Execute then
    exit;

  try
    if CrTab.Checked then
      GenCreateTableScript;

    if ExpRec.Checked then
      CreateSQLScript;

    Close;
    MessageDlg('Table successfully exported.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('Error writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

end.

