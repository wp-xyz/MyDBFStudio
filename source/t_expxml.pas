unit T_ExpXml;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, CheckLst, Buttons, ComCtrls;

type

  { TExpXml }

  TExpXml = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
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

    Procedure ReplaceString(Var OrigStr : String; SubStr,Val : String);

    Function CheckSpecialChar(Val : String) : String;
  public
    { public declarations }
  end; 

var
  ExpXml: TExpXml;

implementation

{ TExpXml }

procedure TExpXml.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 ClbField.Clear;

 For Ind:=0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind]:=True;
  End;
end;

procedure TExpXml.ReplaceString(var OrigStr: String; SubStr, Val: String);
 Var App : String;
     Ind : Word;
begin
 App:='';

 If Pos(SubStr,OrigStr) > 0 Then
  For Ind:=1 To Pos(SubStr,OrigStr) - 1 Do
   App:=App + OrigStr[Ind];

 App:=App + Val;

 For Ind:=Pos(SubStr,OrigStr) + 1 To Length(OrigStr) Do
  App:=App + OrigStr[Ind];

 OrigStr:=App;
end;

Function TExpXml.CheckSpecialChar(Val: String) : String;
begin
 Result:=Val;

 While Pos('&',Val) > 0 Do
  ReplaceString(Val,'&','☼');

 While Pos('☼',Val) > 0 Do
  ReplaceString(Val,'☼','&amp;');

 While Pos('<',Val) > 0 Do
  ReplaceString(Val,'<','&lt;');

 While Pos('>',Val) > 0 Do
  ReplaceString(Val,'>','&gt;');

 While Pos('"',Val) > 0 Do
  ReplaceString(Val,'"','&quot;');

 While Pos('''',Val) > 0 Do
  ReplaceString(Val,'''','&apos;');

 Result:=Val;
end;

procedure TExpXml.BitBtn2Click(Sender: TObject);
 Var F : TextFile;
     Ind : Word;
begin
 If SaveExp.Execute Then
  If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
   Begin
    Try
      AssignFile(F,SaveExp.FileName);
      ReWrite(F);

      Tmp.First;
      pBar.Min:=0;
      pBar.Max:=Tmp.ExactRecordCount;
      pBar.Position:=0;

      Writeln(F,'<?xml version="1.0" encoding="UTF-8"?>');
      Writeln(F,'<' + Tmp.TableName + '>');

      While Not Tmp.EOF Do
       Begin
        Writeln(F,'     <record>');

        For Ind:=0 To ClbField.Items.Count - 1 Do
         If ClbField.Checked[Ind] Then
          Begin
           If Tmp.FieldByName(ClbField.Items[Ind]).AsString <> '' Then
            Writeln(F,'          <' + ClbField.Items[Ind] + '>' +
                    CheckSpecialChar(Tmp.FieldByName(ClbField.Items[Ind]).AsString) +
                    '</' + ClbField.Items[Ind] + '>')
           Else
            Writeln(F,'          <' + ClbField.Items[Ind] + '> ' +
                      '</' + ClbField.Items[Ind] + '>');

          End;

        Writeln(F,'     </record>');

        Tmp.Next;

        pBar.Position:=pBar.Position + 1;

        //Application.ProcessMessages;
       End;

      Writeln(F,'</' + Tmp.TableName + '>');

      pBar.Position:=0;

      System.Close(F);

      Close;
    Except
      ShowMessage('Error writing file');
    End;
   End;
end;

initialization
  {$I t_expxml.lrs}

end.

