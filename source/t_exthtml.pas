unit T_ExtHTML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, CheckLst, Buttons, ColorBox, ExtCtrls, ComCtrls,
  DsDataExport, DsHtml;

type

  { TExpHTML }

  TExpHTML = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ClbField: TCheckListBox;
    CellP: TLabeledEdit;
    CellS: TLabeledEdit;
    Label11: TLabel;
    pBar: TProgressBar;
    TableBC: TColorBox;
    HeaderFS: TComboBox;
    HeaderST: TComboBox;
    Label10: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    TableW: TLabeledEdit;
    PageTLT: TLabeledEdit;
    PageFS: TComboBox;
    HeaderBC: TColorBox;
    HeaderFC: TColorBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    PageFC: TColorBox;
    Label3: TLabel;
    PageBC: TColorBox;
    Label1: TLabel;
    Label2: TLabel;
    PageFT: TComboBox;
    SaveExp: TSaveDialog;
    Tmp: TDbf;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    UpDown3: TUpDown;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpObj : TDsDataToHTML;

    Procedure IncrementPBar(Sender: TObject);

    Function Return_Font_Size(cb : TComboBox) : THTMLFontSize;
    Function Return_Font_Style(cb : TComboBox) : THTMLFontStyles;

    Procedure Generate_Field_List();
  public
    { public declarations }
  end; 

var
  ExpHTML: TExpHTML;

implementation

{$R *.lfm}

{ TExpHTML }

procedure TExpHTML.BitBtn2Click(Sender: TObject);
begin
 If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbYes, mbCancel],0) <> mrYes Then
  Exit;

 If SaveExp.Execute Then
  Begin
   pBar.Min:=0;
   pBar.Max:=Tmp.ExactRecordCount;
   pBar.Position:=0;

   Tmp.First;

   ExpObj:=TDsDataToHTML.Create(Self);
   ExpObj.AfterWriteRecord:=@IncrementPBar;
   ExpObj.DataSet:=Tmp;

   ExpObj.PageOptions.BackColor:=PageBC.Colors[PageBC.ItemIndex];
   ExpObj.PageOptions.Font.Color:=PageFC.Colors[PageFC.ItemIndex];
   ExpObj.Detail.Headers.BackColor:=HeaderBC.Colors[HeaderBC.ItemIndex];
   ExpObj.Detail.Headers.Font.Color:=HeaderFC.Colors[HeaderFC.ItemIndex];

   ExpObj.PageOptions.Font.Size:=Return_Font_Size(PageFS);
   ExpObj.Detail.Headers.Font.Size:=Return_Font_Size(HeaderFS);

   ExpObj.PageOptions.Font.Style:=Return_Font_Style(PageFT);
   ExpObj.Detail.Headers.Font.Style:=Return_Font_Style(HeaderST);

   ExpObj.Detail.BorderWidth:=StrToInt(TableW.Text);
   ExpObj.Detail.BorderColor:=TableBC.Colors[TableBC.ItemIndex];
   ExpObj.Detail.CellPadding:=StrToInt(CellP.Text);
   ExpObj.Detail.CellSpacing:=StrToInt(CellS.Text);

   ExpObj.PageOptions.Title:=PageTLT.Text;

   Generate_Field_List();

   Try
     ExpObj.SaveToFile(SaveExp.FileName);

     //pBar.Position:=0;

     Close;
   Except
     ShowMessage('Error on writing file...');
   End;
  End;
end;

procedure TExpHTML.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 If Assigned(ExpObj) Then
  ExpObj.Free;
end;

procedure TExpHTML.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 ClbField.Clear;

 For Ind:=0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind]:=True;
  End;

 PageTLT.Text:=Tmp.TableName;
end;

procedure TExpHTML.IncrementPBar(Sender: TObject);
begin
 pBar.StepIt;

 Application.ProcessMessages;
end;

function TExpHTML.Return_Font_Size(cb : TComboBox) : THTMLFontSize;
begin
 Case cb.ItemIndex Of
  0                : Result:=fsNormal;
  1                : Result:=fs8;
  2                : Result:=fs10;
  3                : Result:=fs12;
  4                : Result:=fs14;
  5                : Result:=fs18;
  6                : Result:=fs24;
  7                : Result:=fs36;
 End;
end;

function TExpHTML.Return_Font_Style(cb: TComboBox): THTMLFontStyles;
begin
 Case cb.ItemIndex Of
  0                : Result:=[];
  1                : Result:=[hfBold];
  2                : Result:=[hfItalic];
  3                : Result:=[hfUnderline];
  4                : Result:=[hfStrikeOut];
  5                : Result:=[hfBlink];
  6                : Result:=[hfSup];
  7                : Result:=[hfSub];
  8                : Result:=[hfDfn];
  9                : Result:=[hfStrong];
  10               : Result:=[hfEm];
  11               : Result:=[hfCite];
  12               : Result:=[hfVariable];
  13               : Result:=[hfKeyboard];
  14               : Result:=[hfCode];
 End;
end;

procedure TExpHTML.Generate_Field_List();
 Var Ind : Word;
begin
 ExpObj.GetFields.Clear;

 For Ind:=0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   ExpObj.Fields.Add().Assign(Tmp.Fields[Ind]);
end;


end.

