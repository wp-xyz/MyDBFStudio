unit T_ExpSQL;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, CheckLst, StdCtrls, ComCtrls, Buttons, db;

type

  { TExpSQL }

  TExpSQL = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ExpRec: TCheckBox;
    CrTab: TCheckBox;
    ClbField: TCheckListBox;
    Label1: TLabel;
    Label11: TLabel;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    Tmp: TDbf;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Procedure GenCreateTableScript();

    Function Remove_FileExtension(Val : String) : String;
    Function ConvertFloat(Val : String) : String;

    Procedure CreateSQLScript();
  public
    { public declarations }
  end; 

var
  ExpSQL: TExpSQL;

implementation

{$R *.lfm}

{ TExpSQL }

procedure TExpSQL.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 ClbField.Clear;

 For Ind:=0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind]:=True;
  End;
end;

procedure TExpSQL.GenCreateTableScript();
 Var App : String;
     F : TextFile;
     Ind : Word;
     Str : TStringList;
begin
 App:=Remove_FileExtension(ExtractFileName(SaveExp.FileName));
 App:=App + '-crt.sql';
 App:=ExtractFilePath(SaveExp.FileName) + App;

 AssignFile(F,App);
 ReWrite(F);

 Str:=TStringList.Create;

 For Ind:=0 To ClbField.Items.Count - 1 Do
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

   For Ind:=0 To Str.Count - 1 Do
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
 Result:='';

 If Val <> '' Then
  For Ind:=1 To Pos('.',Val) - 1 Do
   Result:=Result + Val[Ind];
end;

function TExpSQL.ConvertFloat(Val: String): String;
 Var I : Word;
Begin
 Result:=Val;

 If Pos(',',Val) > 0 Then
  Begin
   Result:='';

   For I:=1 To Pos(',',Val) - 1 Do
    Result:=Result + Val[I];

   Result:=Result + '.';

   For I:=Pos(',',Val) + 1 To Length(Val) Do
    Result:=Result + Val[I];
  End;
End;

procedure TExpSQL.CreateSQLScript();
 Var Ind : Word;
     Str : TStringList;
     F : TextFile;
begin
 Tmp.First;
 pBar.Min:=0;
 pBar.Max:=Tmp.ExactRecordCount;
 pBar.Position:=0;

 Str:=TStringList.Create;

 AssignFile(F,SaveExp.FileName);
 ReWrite(F);

 While Not Tmp.EOF Do
  Begin
   Str.Clear;

   For Ind:=0 To ClbField.Items.Count - 1 Do
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

     For Ind:=0 To Str.Count - 1 Do
      If Ind < Str.Count - 1 Then
       Writeln(F,Str.Strings[Ind] + ',')
      Else
       Writeln(F,Str.Strings[Ind]);

     Writeln(F,');');
    End;

   pBar.Position:=pBar.Position + 1;
  End;

 pBar.Position:=0;

 System.Close(F);

 Str.Free;
end;

procedure TExpSQL.BitBtn2Click(Sender: TObject);
begin
 If SaveExp.Execute Then
  If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
   Begin
    Try
      If CrTab.Checked Then
       GenCreateTableScript();

      If ExpRec.Checked Then
       CreateSQLScript();

      Close;
    Except
      ShowMessage('Error writing file');
    End;
   End;
end;


end.

