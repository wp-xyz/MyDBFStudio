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
    Label1: TLabel;
    Label11: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FDbf: TDbf;
    Function CheckSpecialChar(Val : String) : String;
  public
    { public declarations }
    property Dbf: TDbf read FDbf write FDbf;
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
  s: String;
  rs: RawByteString = '';
begin
  if SaveExp.Execute then
    if MessageDlg('Do you want to attempt to export data?',mtWarning,[mbOk, mbCancel],0) = mrOk then
    begin
      try
        AssignFile(F, SaveExp.FileName);
        ReWrite(F);

        FDbf.First;
        pBar.Min := 0;
        pBar.Max := FDbf.ExactRecordCount;
        pBar.Position:=0;

        Writeln(F, '<?xml version="1.0" encoding="UTF-8"?>');
        Writeln(F, '<' + FDbf.TableName + '>');

        while not FDbf.EOF Do
        begin
          Writeln(F, '  <record>');

          for Ind := 0 To ClbField.Items.Count - 1 Do
          if ClbField.Checked[Ind] then
          begin
            field := FDbf.FieldByName(ClbField.Items[Ind]);
            if field.IsNull then
              WriteLn(F, Format('  <%0:s> </%0:s>', [
                ClbField.Items[Ind]]))
            else
            if (field is TMemoField) then
            begin
              s := ConvertEncoding(field.AsString, Format('cp%d', [FDbf.CodePage]), 'utf8');
              WriteLn(F, Format('  <%0:s>%1:s</%0:s>', [ClbField.Items[Ind], s]));
            end
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
                WriteLn(F, Format('  <%0:s>%1:s</%0:s>', [ClbField.Items[Ind], rs]));
              finally
                stream.Free;
              end;
            end else
            begin
              s := ConvertEncoding(field.AsString, Format('cp%d', [FDbf.CodePage]), 'utf8');
              WriteLn(F, Format('  <%0:s>%1:s</%0:s>', [ClbField.Items[Ind], s]));
            end;
          end;

          Writeln(F, '  </record>');

          FDbf.Next;

          pBar.Position := pBar.Position + 1;
        end;

        Writeln(F, '</' + FDbf.TableName + '>');

        pBar.Position:=0;
        System.Close(F);
        ShowMessage('Export completed!');
      except
        ShowMessage('Error writing file');
      end;
   End;
end;

procedure TExpXML.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.ExportXMLWindow.ExtractFromForm(Self);
end;

procedure TExpXML.FormCreate(Sender: TObject);
begin
  FDbf := TDbf.Create(self);
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

  for Ind := 0 to FDbf.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(FDbf.FieldDefs.Items[ind].Name);
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

