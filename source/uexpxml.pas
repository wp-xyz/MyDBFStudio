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
    Tmp: TDbf;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }

    Function CheckSpecialChar(Val : String) : String;

    Procedure ReplaceString(Var OrigStr : String; SubStr,Val : String);
  public
    { public declarations }
  end;

var
  ExpXML: TExpXML;

implementation

{$R *.lfm}

uses
  Math, uOptions;

{ TExpXML }

procedure TExpXML.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TExpXML.ExportBtnClick(Sender: TObject);
 Var F : TextFile;
     Ind : Word;
begin
 If SaveExp.Execute Then
  If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbOk, mbCancel],0) = mrOk Then
   Begin
    Try
      AssignFile(F,SaveExp.FileName);
      ReWrite(F);

      Tmp.First;
      pBar.Min := 0;
      pBar.Max := Tmp.ExactRecordCount;
      pBar.Position:=0;

      Writeln(F,'<?xml version="1.0" encoding="UTF-8"?>');
      Writeln(F,'<' + Tmp.TableName + '>');

      While Not Tmp.EOF Do
       Begin
        Writeln(F,'     <record>');

        For Ind := 0 To ClbField.Items.Count - 1 Do
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

        pBar.Position := pBar.Position + 1;

        //Application.ProcessMessages;
       End;

      Writeln(F,'</' + Tmp.TableName + '>');

      pBar.Position:=0;

      System.Close(F);

      ShowMessage('Export completed!');
    Except
      ShowMessage('Error writing file');
    End;
   End;
end;

procedure TExpXML.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
    Options.ExportXMLWindow.ExtractFromForm(Self);
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

  for Ind := 0 to Tmp.FieldDefs.Count - 1 do
  begin
    ClbField.Items.Add(Tmp.FieldDefs.Items[ind].Name);
    ClbField.Checked[ind] := True;
  end;
end;

function TExpXML.CheckSpecialChar(Val: String): String;
begin
 Result := Val;

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

 Result := Val;
end;

procedure TExpXML.ReplaceString(var OrigStr: String; SubStr, Val: String);
 Var App : String;
     Ind : Word;
begin
 App := '';

 If Pos(SubStr,OrigStr) > 0 Then
  For Ind := 1 To Pos(SubStr,OrigStr) - 1 Do
   App := App + OrigStr[Ind];

 App := App + Val;

 For Ind:=Pos(SubStr,OrigStr) + 1 To Length(OrigStr) Do
  App := App + OrigStr[Ind];

 OrigStr := App;
end;

end.

