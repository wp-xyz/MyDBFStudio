unit uSortTable;

// To do: Sorting not correct (test with industry.dbf)

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, ComCtrls, DB;

type

  { TSortTable }

  TSortTable = class(TForm)
    CloseBtn: TBitBtn;
    StartBtn: TBitBtn;
    lblProgress: TLabel;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    OptSort: TRadioGroup;
    OrigFields: TListBox;
    pBar: TProgressBar;
    SortFields: TListBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure CloseBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure OrigFieldsDblClick(Sender: TObject);
    procedure SortFieldsDblClick(Sender: TObject);
  private
    { private declarations }
    FOrigTable: TDbf;
    Function CreateTempTable: Boolean;
    Function CreateSortIndex: Boolean;
    Procedure MoveRecord;
  public
    { public declarations }
    property OrigTable: TDbf read FOrigTable write FOrigTable;
  end;

var
  SortTable: TSortTable;

implementation

{$R *.lfm}

uses
  uOptions;

const
  TMP_DBF_NAME = '_sort_tmp_.dbf';
  TMP_MDX_NAME = '_sort_tmp_.mdx';

{ TSortTable }

procedure TSortTable.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.SubtractTablesWindow.ExtractFromForm(Self);
    FOrigTable.Open;
  end;
end;

procedure TSortTable.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TSortTable.StartBtnClick(Sender: TObject);
begin
  if MessageDlg('The sorting can be very slow for a big table. Continue?',
    mtWarning, [mbYes, mbNo], 0) <> mrYes
  then
    exit;

  if SortFields.Items.Count = 0 then
  begin
    MessageDlg('You must select at least one field to sort on.', mtError, [mbOK], 0);
    exit;
  end;

  if CreateTempTable then
  begin
    if CreateSortIndex then
    begin
      MoveRecord;
      FOrigTable.Open;
      MessageDlg('Process completed.', mtInformation, [mbOK], 0);
      pBar.Position := 0;
    end;
  end else
    MessageDlg('Error while creating temporary table...', mtError, [mbOK], 0);
end;

procedure TSortTable.FormShow(Sender: TObject);
var
  Ind : Word;
begin
  OrigFields.Clear;
  for Ind := 0 To FOrigTable.FieldDefs.Count - 1 do
    OrigFields.Items.Add(FOrigTable.FieldDefs.Items[Ind].Name);

  Options.SortTableWindow.ApplyToForm(self);
end;

procedure TSortTable.OrigFieldsDblClick(Sender: TObject);
begin
  If OrigFields.ItemIndex > -1 then
  begin
    SortFields.Items.Add(OrigFields.Items[OrigFields.ItemIndex]);
    OrigFields.Items.Delete(OrigFields.ItemIndex);
  end;
end;

procedure TSortTable.SortFieldsDblClick(Sender: TObject);
begin
  if SortFields.ItemIndex > -1 then
  begin
    OrigFields.Items.Add(SortFields.Items[SortFields.ItemIndex]);
    SortFields.Items.Delete(SortFields.ItemIndex);
  end;
end;

// Creates a work file as copy of the original file.
function TSortTable.CreateTempTable: Boolean;
begin
  FOrigTable.Close;
  lblProgress.Caption := 'Create work table...';
  Application.ProcessMessages;
  Result := CopyFile(
    FOrigTable.FilePath + FOrigTable.TableName,
    FOrigTable.FilePath + TMP_DBF_NAME
  );
  lblProgress.Caption := 'Progress';
end;

// Creates an index for sorting the work file based on the sort fields specified.
function TSortTable.CreateSortIndex: Boolean;
var
  T: TDbf;
  Ind: Word;
  Exp: String;
  iOpt: TIndexOptions;
  fieldName: String;
begin
  T := TDbf.Create(nil);
  try
    T.FilePath := FOrigTable.FilePath;
    T.TableName := TMP_DBF_NAME;
    T.TableLevel := FOrigTable.TableLevel;
    T.Exclusive := True;

    Result := True;
    try
      T.Open;
      Exp := '';
      for Ind:=0 to SortFields.Items.Count - 1 do
      begin
        fieldName := SortFields.Items[Ind];
        case T.FieldDefs.Find(fieldName).DataType of
          ftString,
          ftFixedChar,
          ftWideString,
          ftFixedWideChar:
            if Exp = '' then
              Exp := fieldName
            else
              Exp := Exp + ' + ' + fieldName;     // wp: why '+' ?

          ftSmallint,
          ftInteger,
          ftWord,
          ftLargeint,
          ftFloat,
          ftBytes,
          ftCurrency,
          ftAutoInc:
            if Exp = '' then
              Exp := 'STR(' + fieldName + ')'
            else
              Exp := Exp + ' + STR(' + fieldName + ')';

          ftDate,
          ftTime,
          ftDateTime,
          ftTimeStamp:
            if Exp = '' then
              Exp := 'DTOS(' + fieldName + ')'
            else
              Exp := Exp + ' + DTOS(' + fieldName + ')';
        end;
      end;

      case OptSort.ItemIndex of
        0: iOpt := [];
        1: iOpt := [ixDescending];
      end;

      lblProgress.Caption := 'Create sort index on work table...';
      Application.ProcessMessages;
      T.AddIndex('TMP', Exp, iOpt);
      lblProgress.Caption := 'Progress';
    except
      on E:Exception do
      begin
        Result := false;
        ShowMessage(E.Message);
      end;
    end;

  finally
    T.Close;
    T.Free;
  end;
end;

// Copies the records from the sorted work table to the original table.
// Because of the established sorting index the records are sorted in
// the requested order.
procedure TSortTable.MoveRecord;
var
  T: TDbf;
  Ind: Word;
  fieldName: String;
begin
  T := TDbf.Create(nil);
  try
    T.FilePath := FOrigTable.FilePath;
    T.TableName := TMP_DBF_NAME;
    T.TableLevel := FOrigTable.TableLevel;
    T.IndexName := 'TMP';
    T.Open;

    FOrigTable.Open;
    FOrigTable.Zap;   // Erases the original table

    pBar.Min := 1;
    pBar.Max := T.ExactRecordCount;
    pBar.Position := 0;

    lblProgress.Caption := 'Moving records...';
    Application.ProcessMessages;
    while not T.EOF do
    begin
      FOrigTable.Append;
      for Ind := 0 to T.FieldDefs.Count - 1 do
      begin
        fieldName := T.FieldDefs.Items[ind].Name;
        FOrigTable.FieldByName(fieldName).AsVariant := T.FieldByName(fieldName).AsVariant;
      end;
      FOrigTable.Post;
      T.Next;
      pBar.Position := pBar.Position + 1;
    end;

    FOrigTable.Close;
    T.Close;

    lblProgress.Caption := 'Progress';

    DeleteFile(T.FilePath + TMP_DBF_NAME);
    DeleteFile(T.FilePath + TMP_MDX_NAME);
  finally
    T.Free;
  end;
end;

end.

