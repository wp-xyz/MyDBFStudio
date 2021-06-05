unit uExpXML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ComCtrls, Buttons;

type

  { TExpXML }

  TExpXML = class(TForm)
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    ClbField: TCheckListBox;
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
    Function CheckSpecialChar(Val : String) : String;
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write FDbfTable;
  end;

var
  ExpXML: TExpXML;

implementation

{$R *.lfm}

uses
  DB, Base64, LConvEncoding, Math, uOptions;

{ TExpXML }

procedure TExpXML.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TExpXML.ExportBtnClick(Sender: TObject);
var
  F: TextFile;
  Ind: Word;
  field: TField;
  stream: TStream;
  rs: RawByteString = '';
begin
  if not SaveExp.Execute then
    exit;

  try
    AssignFile(F, SaveExp.FileName);
    ReWrite(F);

    DbfTable.First;
    pBar.Min := 0;
    pBar.Max := DbfTable.ExactRecordCount;
    pBar.Position := 0;

    Writeln(F, '<?xml version="1.0" encoding="UTF-8"?>');
    Writeln(F, '<' + DbfTable.TableName + '>');

    while not DbfTable.EOF Do
    begin
      Writeln(F, '  <record>');

      for Ind := 0 To ClbField.Items.Count - 1 Do
      if ClbField.Checked[Ind] then
      begin
        field := DbfTable.FieldByName(ClbField.Items[Ind]);
        if field.IsNull then
          WriteLn(F, Format('    <%0:s> </%0:s>', [ClbField.Items[Ind]]))
        else
        if (field is TMemoField) then
          WriteLn(F, Format('    <%0:s>%1:s</%0:s>', [ClbField.Items[Ind], field.AsString]))
        else
        if (field is TBlobField) then
        begin
          // Picture field --> encode with Base64
          stream := TMemoryStream.Create;
          try
            TBlobField(field).SaveToStream(stream);
            SetLength(rs, stream.Size);
            stream.Position := 0;
            stream.Write(rs[1], Length(rs));
            rs := EncodeStringBase64(rs);
            WriteLn(F, Format('    <%0:s>%1:s</%0:s>', [ClbField.Items[Ind], rs]));
          finally
            stream.Free;
          end;
        end else
          WriteLn(F, Format('    <%0:s>%1:s</%0:s>', [ClbField.Items[Ind], field.AsString]));
      end;

      Writeln(F, '  </record>');

      DbfTable.Next;

      pBar.Position := pBar.Position + 1;
    end;

    Writeln(F, '</' + DbfTable.TableName + '>');
    System.Close(F);

    Close;
    MessageDlg('File successfully exported to ' + SaveExp.FileName, mtInformation, [mbOK], 0);

  except
    on E: Exception do
      MessageDlg('Error writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TExpXML.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.ExportXMLWindow.ExtractFromForm(Self);
end;

procedure TExpXML.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
end;

procedure TExpXML.FormShow(Sender: TObject);
var
  ind: Integer;
begin
  ExportBtn.Constraints.MinWidth := Max(ExportBtn.Width, CloseBtn.Width);
  CloseBtn.Constraints.MinWidth := ExportBtn.Constraints.MinWidth;

  Constraints.MinWidth := (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight := pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  if Options.RememberWindowSizePos and (Options.ExportXMLWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportXMLWindow.ApplyToForm(Self);
  end;

  ClbField.Clear;

  for Ind := 0 to DbfTable.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(Dbftable.FieldDefs.Items[ind].Name);
    ClbField.Checked[ind] := True;
  end;
end;

function TExpXML.CheckSpecialChar(Val: String): String;
begin
  Result := Val;
  Result := StringReplace(Result, '&', '☼', [rfReplaceAll]);
  Result := StringReplace(Result, '☼', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos:', [rfReplaceAll]);
end;

end.

