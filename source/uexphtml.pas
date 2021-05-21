unit uExpHTML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  CheckLst, ColorBox, ExtCtrls, ComCtrls, Buttons, Spin, DsHtml, dbf;

type

  { TExpHTML }

  TExpHTML = class(TForm)
    Bevel1: TBevel;
    CellP: TEdit;
    CellS: TEdit;
    CloseBtn: TBitBtn;
    ExportBtn: TBitBtn;
    ClbField: TCheckListBox;
    HeaderBC: TColorBox;
    HeaderFC: TColorBox;
    HeaderFS: TComboBox;
    HeaderST: TComboBox;
    lblCellTitle: TLabel;
    lblCellSpacing: TLabel;
    lblCellPadding: TLabel;
    lblTableWidth: TLabel;
    lblExportField: TLabel;
    lblTableBorderColor: TLabel;
    lblProgress: TLabel;
    lblPageBackColor: TLabel;
    lblPageFontColor: TLabel;
    lblHeaderBackColor: TLabel;
    lblHeaderFontColor: TLabel;
    lblPageFontSize: TLabel;
    lblHeaderFontSize: TLabel;
    lblPageFontStyle: TLabel;
    lblHeaderFontStyle: TLabel;
    PageBC: TColorBox;
    PageFC: TColorBox;
    PageFS: TComboBox;
    PageFT: TComboBox;
    PageTLT: TEdit;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableBC: TColorBox;
    TableW: TEdit;
    Tmp: TDbf;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    UpDown3: TUpDown;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpObj : TDsDataToHTML;

    Procedure IncrementPBar(Sender: TObject);

    Function Return_Font_Size(cb : TComboBox) : THTMLFontSize;
    Function Return_Font_Style(cb : TComboBox) : THTMLFontStyles;

    Procedure Generate_Field_List;
  public
    { public declarations }
  end;

var
  ExpHTML: TExpHTML;

implementation

{$R *.lfm}

uses
  Math;

{ TExpHTML }

procedure TExpHTML.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 If Assigned(ExpObj) Then
  ExpObj.Free;
end;

procedure TExpHTML.CloseBtnClick(Sender: TObject);
begin
 Close;
end;

procedure TExpHTML.ExportBtnClick(Sender: TObject);
begin
 If MessageDlg('Do you want to attempt to export data?',mtWarning,[mbOk, mbCancel],0) <> mrOk Then
  Exit;

 If SaveExp.Execute Then
  Begin
   pBar.Min := 0;
   pBar.Max := Tmp.ExactRecordCount;
   pBar.Position := 0;

   Tmp.First;

   ExpObj := TDsDataToHTML.Create(Self);
   ExpObj.AfterWriteRecord := @IncrementPBar;
   ExpObj.DataSet := Tmp;

   ExpObj.PageOptions.BackColor := PageBC.Colors[PageBC.ItemIndex];
   ExpObj.PageOptions.Font.Color := PageFC.Colors[PageFC.ItemIndex];
   ExpObj.Detail.Headers.BackColor := HeaderBC.Colors[HeaderBC.ItemIndex];
   ExpObj.Detail.Headers.Font.Color := HeaderFC.Colors[HeaderFC.ItemIndex];

   ExpObj.PageOptions.Font.Size := Return_Font_Size(PageFS);
   ExpObj.Detail.Headers.Font.Size := Return_Font_Size(HeaderFS);

   ExpObj.PageOptions.Font.Style := Return_Font_Style(PageFT);
   ExpObj.Detail.Headers.Font.Style := Return_Font_Style(HeaderST);

   ExpObj.Detail.BorderWidth := StrToInt(TableW.Text);
   ExpObj.Detail.BorderColor := TableBC.Colors[TableBC.ItemIndex];
   ExpObj.Detail.CellPadding := StrToInt(CellP.Text);
   ExpObj.Detail.CellSpacing := StrToInt(CellS.Text);

   ExpObj.PageOptions.Title := PageTLT.Text;

   Generate_Field_List;

   Try
     ExpObj.SaveToFile(SaveExp.FileName);

     //pBar.Position:=0;

     ShowMessage('Export completed!');
   Except
     ShowMessage('Error on writing file...');
   End;
  End;
end;

procedure TExpHTML.FormShow(Sender: TObject);
 Var Ind : Integer;
   w: Integer;
begin
 w := MaxValue([lblPageBackColor.Width, lblPageFontColor.Width,
                lblHeaderBackColor.Width, lblHeaderFontColor.Width,
                lblPageFontStyle.Width, lblHeaderFontStyle.Width,
                lblTableWidth.Width, lblTableBorderColor.Width,
                ExportBtn.Width, CloseBtn.Width]);
 ExportBtn.Constraints.MinWidth := w;
 CloseBtn.Constraints.MinWidth := w;

 ClbField.Clear;

 For Ind := 0 To Tmp.FieldDefs.Count - 1 Do
  Begin
   ClbField.Items.Add(Tmp.FieldDefs.Items[Ind].Name);

   ClbField.Checked[Ind] := True;
  End;

 PageTLT.Text := Tmp.TableName;
end;

procedure TExpHTML.IncrementPBar(Sender: TObject);
begin
 pBar.StepIt;

 Application.ProcessMessages;
end;

function TExpHTML.Return_Font_Size(cb: TComboBox): THTMLFontSize;
begin
 Result := fsNormal;

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
 Result:=[];

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

procedure TExpHTML.Generate_Field_List;
 Var Ind : Integer;
begin
 ExpObj.GetFields.Clear;

 For Ind := 0 To ClbField.Items.Count - 1 Do
  If ClbField.Checked[Ind] Then
   ExpObj.Fields.Add().Assign(Tmp.Fields[Ind]);
end;

end.

