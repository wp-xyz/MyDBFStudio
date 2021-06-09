unit uExpHTML;

// Todo: Fix BLOB fields being exported as MEMO fields.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  CheckLst, ColorBox, ExtCtrls, ComCtrls, Buttons, ComboEx, DsHtml, dbf;

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
    HeaderST: TCheckComboBox;
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
    PageFT: TCheckComboBox;
    PageTLT: TEdit;
    pBar: TProgressBar;
    SaveExp: TSaveDialog;
    TableBC: TColorBox;
    TableW: TEdit;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    UpDown3: TUpDown;
    procedure ClbFieldItemClick(Sender: TObject; Index: integer);
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExpObj : TDsDataToHTML;
    FDbfTable: TDbf;
    Procedure IncrementPBar(Sender: TObject);
    Function Return_Font_Size(cb : TComboBox) : THTMLFontSize;
    Procedure Generate_Field_List;
    function GetFontStyles(cb: TCheckComboBox): THTMLFontStyles;
    procedure SetFontStyles(cb: TCheckCombobox; fs: THTMLFontStyles);
  public
    { public declarations }
    property DbfTable: TDbf read FDbfTable write FDbfTable;
  end;

var
  ExpHTML: TExpHTML;

implementation

{$R *.lfm}

uses
  DB, Math, uOptions;

{ TExpHTML }

procedure TExpHTML.FormDestroy(Sender: TObject);
begin
  ExpObj.Free;
end;

procedure TExpHTML.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

// Do not allow check a BLOB item: cannot export a picture to html this way.
procedure TExpHTML.ClbFieldItemClick(Sender: TObject; Index: integer);
var
  fieldDef: TFieldDef;
begin
  fieldDef := FDbfTable.FieldDefs.Items[Index];
  if (fieldDef.DataType = ftBlob) and (fieldDef.DataType <> ftMemo) then
  begin
    ClbField.Checked[Index] := false;
    MessageDlg('Exporting a BLOB field to HTML is not supported.', mtError, [mbOK], 0);
  end;
end;

procedure TExpHTML.ExportBtnClick(Sender: TObject);
begin
  if not SaveExp.Execute then
    exit;

  pBar.Min := 0;
  pBar.Max := DbfTable.ExactRecordCount;
  pBar.Position := 0;

  DbfTable.First;

  ExpObj := TDsDataToHTML.Create(self);     // Must be destroyed by self, crashes otherwise!
  ExpObj.AfterWriteRecord := @IncrementPBar;
  ExpObj.DataSet := DbfTable;
  ExpObj.PageOptions.Title := PageTLT.Text;
  ExpObj.PageOptions.BackColor := PageBC.Colors[PageBC.ItemIndex];
  ExpObj.PageOptions.Font.Color := PageFC.Colors[PageFC.ItemIndex];
  ExpObj.PageOptions.Font.Size := Return_Font_Size(PageFS);
  ExpObj.PageOptions.Font.Style := GetFontStyles(PageFT);
  ExpObj.Detail.Headers.BackColor := HeaderBC.Colors[HeaderBC.ItemIndex];
  ExpObj.Detail.Headers.Font.Color := HeaderFC.Colors[HeaderFC.ItemIndex];
  ExpObj.Detail.Headers.Font.Size := Return_Font_Size(HeaderFS);
  ExpObj.Detail.Headers.Font.Style := GetFontStyles(HeaderST);
  if TableW.Text <> '' then
    ExpObj.Detail.BorderWidth := StrToInt(TableW.Text);
  ExpObj.Detail.BorderColor := TableBC.Colors[TableBC.ItemIndex];
  if CellP.Text <> '' then
    ExpObj.Detail.CellPadding := StrToInt(CellP.Text);
  if CellS.Text <> '' then
    ExpObj.Detail.CellSpacing := StrToInt(CellS.Text);

  Generate_Field_List;

  try
    ExpObj.SaveToFile(SaveExp.FileName);
    Close;
    MessageDlg('Table successfully exported to ' + SaveExp.FileName, mtInformation, [mbOK], 0);
  except
    on E:Exception do
      MessageDlg('Error on writing file:' + LineEnding + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TExpHTML.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.ExportHTMLWindow.ExtractFromForm(Self);
    Options.ExportHTMLPageBackColor := PageBC.Selected;
    Options.ExportHTMLPageFontColor := PageFC.Selected;
    Options.ExportHTMLHeaderBackColor := HeaderBC.Selected;
    Options.ExportHTMLHeaderFontColor := HeaderFC.Selected;
    Options.ExportHTMLPageFontSize := THtmlFontSize(PageFS.ItemIndex);
    Options.ExportHTMLHeaderFontSize := THtmlFontSize(HeaderFS.ItemIndex);
    Options.ExportHTMLPageFontStyle := GetFontStyles(PageFT);
    Options.ExportHTMLHeaderFontStyle := GetFontStyles(HeaderST);
    Options.ExportHTMLTableWidth := StrToIntDef(TableW.Text, -1);
    Options.ExportHTMLTableBorderColor := TableBC.Selected;
    Options.ExportHTMLCellPadding := StrToIntDef(CellP.Text, -1);
    Options.ExportHTMLCellSpacing := StrToIntDef(CellS.Text, -1);
  end;
end;

procedure TExpHTML.FormCreate(Sender: TObject);
begin
  FDbfTable := TDbf.Create(self);
end;

procedure TExpHTML.FormShow(Sender: TObject);
var
  ind: Integer;
  w: Integer;
begin
  w := {%H-}MaxValue([lblPageBackColor.Width, lblPageFontColor.Width,
                 lblHeaderBackColor.Width, lblHeaderFontColor.Width,
                 lblPageFontStyle.Width, lblHeaderFontStyle.Width,
                 lblTableWidth.Width, lblTableBorderColor.Width,
                 ExportBtn.Width, CloseBtn.Width]);
  ExportBtn.Constraints.MinWidth := w;
  CloseBtn.Constraints.MinWidth := w;

  Constraints.MinWidth :=
    (ExportBtn.Width + CloseBtn.Width + 4*CloseBtn.BorderSpacing.Right) * 2;
  Constraints.MinHeight :=
    pBar.Top + pBar.Height +
    CloseBtn.BorderSpacing.Top + CloseBtn.Height + CloseBtn.BorderSpacing.Bottom;

  // Get initial values from options
  if Options.RememberWindowSizePos and (Options.ExportHTMLWindow.Width > 0) then
  begin
    AutoSize := false;
    Options.ExportHTMLWindow.ApplyToForm(Self);
  end;
  PageBC.Selected := Options.ExportHTMLPageBackColor;
  PageFC.Selected := Options.ExportHTMLPageFontColor;
  HeaderBC.Selected := Options.ExportHTMLHeaderBackColor;
  HeaderFC.Selected := Options.ExportHTMLHeaderFontColor;
  PageFS.ItemIndex := ord(Options.ExportHTMLPageFontSize);
  HeaderFS.ItemIndex := ord(Options.ExportHTMLHeaderFontSize);
  SetFontStyles(PageFT, Options.ExportHTMLPageFontStyle);
  SetFontStyles(HeaderST,  Options.ExportHTMLHeaderFontStyle);
  if Options.ExportHTMLTableWidth > -1 then
    TableW.Text := IntToStr(Options.ExportHTMLTableWidth)
  else
    TableW.Text := '';
  TableBC.Selected := Options.ExportHTMLTableBorderColor;
  if Options.ExportHTMLCellPadding > -1 then
    CellP.Text := IntToStr(Options.ExportHTMLCellPadding)
  else
    CellP.Text := '';
  if Options.ExportHTMLCellSpacing > -1 then
    CellS.Text := IntToStr(Options.ExportHTMLCellSpacing)
  else
    CellS.Text := '';

  // Prepare field list
  ClbField.Clear;
  for ind := 0 to DbfTable.FieldDefs.Count - 1 do
    with FDbftable.FieldDefs.Items[Ind] do
    begin
      ClbField.Items.Add(Name);
      // Do not allow exporting graphic fields, it will be embedded in the html which is not valid
      if (DataType = ftBlob) and (DataType <> ftMemo) then
        ClbField.Checked[ind] := false
      else
        ClbField.Checked[ind] := True;
    end;

  PageTLT.Text := DbfTable.TableName;
end;

procedure TExpHTML.IncrementPBar(Sender: TObject);
begin
  pBar.StepIt;
  Application.ProcessMessages;
end;

function TExpHTML.Return_Font_Size(cb: TComboBox): THTMLFontSize;
begin
  if (cb.ItemIndex >= 0) and (cb.ItemIndex <= ord(High(THtmlFontSize))) then
    Result := THtmlFontSize(cb.ItemIndex)
  else
    Result := fsNormal;
end;

function TExpHTML.GetFontStyles(cb: TCheckComboBox): THTMLFontStyles;
var
  i: Integer;
  s: String;
begin
  s := '';
  Result := [];
  for i := 0 to cb.Items.Count-1 do
    if cb.Checked[i] then
    begin
      Include(Result, THtmlFontStyle(i));
      if s = '' then s := cb.Items[i] else s := s + ' ' + cb.Items[i]
    end;
  cb.Text := s;  // does not work - TCheckCombobox is crappy!
  // Todo: Replace TCheckCombobox by a component in which the checked items are visible in the non-dropped-down state.
end;

procedure TExpHTML.SetFontStyles(cb: TCheckCombobox; fs: THTMLFontStyles);
var
  i: Integer;
begin
  for i := 0 to cb.Items.Count-1 do
    cb.Checked[i] := THTMLFontStyle(i) in fs;
end;

procedure TExpHTML.Generate_Field_List;
var
  Ind: Integer;
begin
  ExpObj.GetFields.Clear;
  for Ind := 0 To ClbField.Items.Count - 1 do
    if ClbField.Checked[Ind] then
      ExpObj.Fields.Add().Assign(DbfTable.Fields[Ind]);
end;

end.

