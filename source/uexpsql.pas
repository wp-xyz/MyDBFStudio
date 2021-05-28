unit uExpSQL;

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
    Label1: TLabel;
    Label11: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    Tmp: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Procedure GenCreateTableScript;

    Function Remove_FileExtension(Val : String) : String;

    Function ConvertFloat(Val : String) : String;

    Procedure CreateSQLScript;
  public
    { public declarations }
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

  for ind := 0 to Tmp.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(Tmp.FieldDefs.Items[ind].Name);
    ClbField.Checked[ind] := True;
  end;
end;

procedure TExpSQL.GenCreateTableScript;
 Var App : String;
     F : TextFile;
     Ind : Word;
     Str : TStringList;
begin
 App := Remove_FileExtension(ExtractFileName(SaveExp.FileName));
 App := App + '-crt.sql';
 App := ExtractFilePath(SaveExp.FileName) + App;

 AssignFile(F,App);
 ReWrite(F);

 Str := TStringList.Create;

 For Ind := 0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   Begin
    Case Tmp.FieldByName(ClbField.Items[Ind]).DataType Of
     ftString,
     ftFixedChar,
     ftWideString,
     ftFixedWideChar       : Str.Add('      ' + ClbField.Items[Ind] + ' VARCHAR(' +
                                     IntToStr(Tmp.FieldByName(ClbField.Items[Ind]).DataSize) +
                                     ') CHARACTER SET WIN1252');

     ftSmallint,
     ftInteger,
     ftWord,
     ftBytes,
     ftVarBytes            : Str.Add('      ' + ClbField.Items[Ind] + ' INTEGER');

     ftAutoInc,
     ftLargeint            : Str.Add('      ' + ClbField.Items[Ind] + ' DOUBLE PRECISION');

     ftFloat,
     ftCurrency,
     ftBCD                 : Str.Add('      ' + ClbField.Items[Ind] + ' NUMERIC(' +
                             IntToStr(Tmp.FieldByName(ClbField.Items[Ind]).DataSize) + ',' +
                             IntToStr(Tmp.FieldByName(ClbField.Items[Ind]).DataSize) + ')');

     ftBoolean             : Str.Add('      ' + ClbField.Items[Ind] + ' CHAR(1) CHARACTER SET WIN1252');

     ftDate,
     ftDateTime            : Str.Add('      ' + ClbField.Items[Ind] + ' DATE');

     ftTime                : Str.Add('      ' + ClbField.Items[Ind] + ' TIME');
    End;
   End;

 If Str.Count > 0 Then
  Begin
   Writeln(F,'CREATE TABLE ' + UpperCase(Remove_FileExtension(Tmp.TableName)) + ' (');

   For Ind := 0 To Str.Count - 1 Do
    If Ind < Str.Count - 1 Then
     Writeln(F,Str.Strings[Ind] + ',')
    Else
     Writeln(F,Str.Strings[Ind]);

   Writeln(F,');');
  End;

 System.Close(F);

 Str.Free;
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
 Var Ind : Word;
     Str : TStringList;
     F : TextFile;
begin
 Tmp.First;
 pBar.Min := 0;
 pBar.Max := Tmp.ExactRecordCount;
 pBar.Position := 0;

 Str := TStringList.Create;

 AssignFile(F,SaveExp.FileName);
 ReWrite(F);

 While Not Tmp.EOF Do
  Begin
   Str.Clear;

   For Ind := 0 To ClbField.Items.Count - 1 Do
    If ClbField.Checked[Ind] Then
     Begin
      Case Tmp.FieldByName(ClbField.Items[Ind]).DataType Of
       ftString,
       ftFixedChar,
       ftWideString,
       ftFixedWideChar       : If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
                                Str.Add('      ' + QuotedStr(Tmp.FieldByName(ClbField.Items[Ind]).AsString))
                               Else
                                Str.Add('      ' + QuotedStr(''));

       ftAutoInc,
       ftLargeint,
       ftSmallint,
       ftInteger,
       ftWord,
       ftBytes,
       ftVarBytes            : If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
                                Str.Add('      ' + Tmp.FieldByName(ClbField.Items[Ind]).AsString)
                               Else
                                Str.Add('      NULL');

       ftFloat,
       ftCurrency,
       ftBCD                 : If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
                                Str.Add('      ' + ConvertFloat(Tmp.FieldByName(ClbField.Items[Ind]).AsString))
                               Else
                                Str.Add('      NULL');

       ftBoolean             : If Tmp.FieldByName(ClbField.Items[Ind]).AsBoolean Then
                                Str.Add('      ' + '1')
                               Else
                                Str.Add('      ' + '0');

       ftDate                : If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
                                Str.Add('      ' + DateToStr(Tmp.FieldByName(ClbField.Items[Ind]).AsDateTime))
                               Else
                                Str.Add('      NULL');

       ftDateTime            : If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
                                Str.Add('      ' + DateTimeToStr(Tmp.FieldByName(ClbField.Items[Ind]).AsDateTime))
                               Else
                                Str.Add('      NULL');

       ftTime                : If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
                                Str.Add('      ' + TimeToStr(Tmp.FieldByName(ClbField.Items[Ind]).AsDateTime))
                               Else
                                Str.Add('      NULL');
      End;
     End;

   Tmp.Next;

   If Str.Count > 0 Then
    Begin
     Writeln(F,'INSERT INTO ' + UpperCase(Remove_FileExtension(Tmp.TableName)) + ' VALUES(');

     For Ind := 0 To Str.Count - 1 Do
      If Ind < Str.Count - 1 Then
       Writeln(F,Str.Strings[Ind] + ',')
      Else
       Writeln(F,Str.Strings[Ind]);

     Writeln(F,');');
    End;

   pBar.Position := pBar.Position + 1;
  End;

 pBar.Position := 0;

 System.Close(F);

 Str.Free;
end;

procedure TExpSQL.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TExpSQL.ExportBtnClick(Sender: TObject);
begin
 If SaveExp.Execute Then
  If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbOk, mbCancel],0) = mrOk Then
   Begin
    Try
      If CrTab.Checked Then
       GenCreateTableScript;

      If ExpRec.Checked Then
       CreateSQLScript;

      ShowMessage('Export completed!');
    Except
      ShowMessage('Error writing file');
    End;
   End;
end;

end.

