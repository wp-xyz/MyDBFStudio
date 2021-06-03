unit uDbfTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  ComCtrls, DbCtrls, StdCtrls, ExtCtrls, DBGrids, Buttons;

type

  { TDbfTable }

  TDbfTable = class(TForm)
    LoadBlobBtn: TButton;
    OpenDialog: TOpenDialog;
    SaveBlobBtn: TButton;
    CopyBlobBtn: TButton;
    PasteBlobBtn: TButton;
    cbShowDel: TCheckBox;
    DBMemo: TDBMemo;
    Image: TImage;
    Indexes: TComboBox;
    DBGrid: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBTable: TDbf;
    Ds: TDataSource;
    Label1: TLabel;
    Label2: TLabel;
    leFilter: TEdit;
    Notebook: TNotebook;
    Panel2: TPanel;
    pgGraphic: TPage;
    pgMemo: TPage;
    Panel1: TPanel;
    SaveDialog: TSaveDialog;
    sbInfo: TStatusBar;
    MemoSplitter: TSplitter;
    TabControl: TTabControl;
    ToolBar1: TToolBar;
    Pack: TToolButton;
    Empty: TToolButton;
    CloseTabBtn: TToolButton;
    tbAutoFillColumns: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ViewDel: TToolButton;
    Restruct: TToolButton;
    SetField: TToolButton;
    procedure cbShowDelChange(Sender: TObject);
    procedure CopyBlobBtnClick(Sender: TObject);
    procedure EmptyClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IndexesChange(Sender: TObject);
    procedure leFilterKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure LoadBlobBtnClick(Sender: TObject);
    procedure PackClick(Sender: TObject);
    procedure PasteBlobBtnClick(Sender: TObject);
    procedure RestructClick(Sender: TObject);
    procedure SaveBlobBtnClick(Sender: TObject);
    procedure SetFieldClick(Sender: TObject);
    Procedure ShowTableInfo(DataSet: TDataSet);
    procedure TabControlChange(Sender: TObject);
    procedure CloseTabBtnClick(Sender: TObject);
    procedure tbAutoFillColumnsClick(Sender: TObject);
    procedure ViewDelClick(Sender: TObject);
  private
    { private declarations }
    FColWidths: array of Integer;
    function IsGraphicStream(AStream: TStream): Boolean;
    Procedure Load_Table_Indexes;
    procedure RestoreColWidths(ATable: TDbf);
    procedure SaveColWidths(ATable: TDbf);
    procedure ShowBlob(ATable: TDbf);
    procedure ShowBlobField(AField: TField);
    function TranslateHandler(ATable: TDbf; Src, Dest: PChar; ToOem: Boolean): Integer;

  public
    { public declarations }
    procedure Setup;
  end;

var
  DbfTable: TDbfTable;

implementation

{$R *.lfm}

uses
  LConvEncoding, LCLType, clipbrd,
  {%H-}uDataModule,  // uDatamodule needed for imagelist
  uRestructure, uSetFV;

const
  GRAPHIC_FILTER = 'BMP files (*.bmp)|*.bmp|'+
    'JPEG files (*.jpg;*.jpeg)|*.jpeg;*.jpg|'+
    'PNG files (*.png)|*.png';
  MEMO_FILTER = 'Text files (*.txt)|*.txt|'+
    'All files (*.*)|*.*';

var
  cfJpeg: TClipboardFormat = 0;
  cfPng: TClipboardFormat = 0;


{ TDbfTable }

procedure TDbfTable.IndexesChange(Sender: TObject);
begin
 DbTable.IndexName := Indexes.Text;
end;

procedure TDbfTable.leFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 If Key = 13 Then
  Begin
   If Trim(leFilter.Text) <> '' Then
    Begin
     Try
       DbTable.Filter := leFilter.Text;
     Except
       ShowMessage('Error in filter...');

       DbTable.Filter := '';
     End;
    End
   Else
    DbTable.Filter := '';

   ShowTableInfo(DbTable);
  End;
end;

procedure TDbfTable.LoadBlobBtnClick(Sender: TObject);
var
  field: TField;
begin
  if not (DBTable.State in [dsEdit, dsInsert]) then
    exit;
  if TabControl.TabIndex = -1 then
    exit;
  field := DBTable.FieldByName(TabControl.Tabs[TabControl.TabIndex]);;
  if not (field is TBLOBField) then
    exit;
  case Notebook.PageIndex of
    0: OpenDialog.Filter := MEMO_FILTER;
    1: OpenDialog.Filter := GRAPHIC_FILTER;
  end;
  if OpenDialog.Execute then
    TBLOBField(field).LoadFromFile(OpenDialog.FileName);
end;

function TDbfTable.IsGraphicStream(AStream: TStream): boolean;
begin
  Result := false;

  AStream.Position := 0;

  Result := TBitmap.IsStreamFormatSupported(AStream);
  if Result then exit;

  Result := TPortableNetworkGraphic.IsStreamFormatSupported(AStream);
  if Result then exit;

  Result := TJpegImage.IsStreamFormatSupported(AStream);
  if Result then exit;

  Result := TIcon.IsStreamFormatSupported(AStream);
  if Result then exit;
end;

procedure TDbfTable.PackClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Pack the table?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
   DbTable.PackTable;
end;

procedure TDbfTable.PasteBlobBtnClick(Sender: TObject);
var
  field: TField;
  stream: TStream;
begin
  if not (DBTable.State in [dsEdit, dsInsert]) then
    exit;
  if TabControl.TabIndex = -1 then
    exit;
  field := DBTable.FieldByName(TabControl.Tabs[TabControl.TabIndex]);;
  if not (field is TBLOBField) then
    exit;
  case Notebook.PageIndex of
    0: if Clipboard.HasFormat(CF_TEXT) then
         TBLOBField(field).AsString := Clipboard.AsText;
    1: if Clipboard.HasPictureFormat then
       begin
         stream := TMemoryStream.Create;
         try
           if Clipboard.HasFormat(CF_BITMAP) or Clipboard.HasFormatName('image/bitmap') then
             Clipboard.GetFormat(CF_BITMAP, stream)
           else if Clipboard.HasFormat(cfJpeg) then
             Clipboard.GetFormat(cfJpeg, stream)
           else if Clipboard.HasFormat(cfPng) then
             Clipboard.GetFormat(cfPng, stream)
           else
             exit;
           stream.Position := 0;
           TBLOBField(field).LoadFromStream(stream);
           stream.Position := 0;
           Image.Picture.LoadfromStream(stream);
         finally
           stream.Free;
         end;
       end;
  end;
end;

procedure TDbfTable.RestructClick(Sender: TObject);
begin
  Restructure := TRestructure.Create(Self);
  try
    Restructure.Temp := DbTable;
    Restructure.ShowModal;
  finally
    Restructure.Free;
  end;
  DbTable.Close;
  DbTable.Open;
  Setup;
end;

procedure TDbfTable.SaveBlobBtnClick(Sender: TObject);
var
  field: TField;
  ext: String;
  img: TCustomBitmap;
begin
  if TabControl.TabIndex = -1 then
    exit;
  field := DBTable.FieldByName(TabControl.Tabs[TabControl.TabIndex]);;
  if not (field is TBLOBField) then
    exit;
  case Notebook.PageIndex of
    0: SaveDialog.Filter := MEMO_FILTER;
    1: SaveDialog.Filter := GRAPHIC_FILTER;
  end;
  if SaveDialog.Execute then
  begin
    ext := lowercase(ExtractFileExt(SaveDialog.FileName));
    if (ext = '.bmp') then
    begin
      if Image.Picture.Bitmap <> nil then
        Image.Picture.Bitmap.SaveToFile(SaveDialog.Filename)
      else
      if (Image.Picture.Graphic <> nil) and (Image.Picture.Graphic is TCustomBitmap) then
      begin
        img := TBitmap.Create;
        try
          img.Assign(TCustomBitmap(Image.Picture.Graphic));
          img.SaveToFile(SaveDialog.FileName);
        finally
          img.Free;
        end;
      end;
    end else
    if (ext = '.jpg') or (ext = '.jpeg') then
    begin
      if Image.Picture.Jpeg <> nil then
        Image.Picture.Jpeg.SaveToFile(Savedialog.FileName)
      else
      if (Image.Picture.Graphic <> nil) and (Image.Picture.Graphic is TCustomBitmap) then
      begin
        img := TJpegImage.Create;
        try
          img.Assign(TCustomBitmap(Image.Picture.Graphic));
          img.SaveToFile(SaveDialog.FileName);
        finally
          img.Free;
        end;
      end;
    end else
    if (ext = '.png') then
    begin
      if Image.Picture.Png <> nil then
        Image.Picture.PNG.SaveToFile(SaveDialog.FileName)
      else
      if (Image.Picture.Graphic <> nil) and (Image.Picture.Graphic is TPortableNetworkGraphic) then
      begin
        img := TPortableNetworkGraphic.Create;
        try
          img.Assign(TCustomBitmap(Image.Picture.Graphic));
          img.SaveToFile(SaveDialog.FileName);
        finally
          img.Free;
        end;
      end;
    end else
      TBlobField(field).SaveToFile(SaveDialog.FileName);
  end;
end;

procedure TDbfTable.SetFieldClick(Sender: TObject);
begin
 SetFV := TSetFV.Create(Self);
 SetFV.SetTable := DbTable;

 SetFV.ShowModal;

 SetFV.Free;

 DbTable.Close;
 DbTable.Open;
end;

procedure TDbfTable.cbShowDelChange(Sender: TObject);
begin
 DBTable.ShowDeleted := cbShowDel.Checked;
end;

procedure TDbfTable.CopyBlobBtnClick(Sender: TObject);
var
  field: TField;
  stream: TMemoryStream;
begin
  if TabControl.TabIndex = -1 then
    exit;
  field := DBTable.FieldByName(TabControl.Tabs[TabControl.TabIndex]);
  if field = nil then
    exit;

  case Notebook.PageIndex of
    0: DBMemo.CopyToClipboard;
    1: begin
         Clipboard.Open;
         try
           Clipboard.Clear;
           stream := TMemoryStream.Create;
           try
             if Image.Picture.Bitmap <> nil then
             begin
               stream.Clear;
               Image.Picture.Bitmap.SaveToStream(stream);
               stream.Position := 0;
               Clipboard.AddFormat(CF_Bitmap, stream);
             end;
             if Image.Picture.Jpeg <> nil then
             begin
               stream.Clear;
               Image.Picture.Jpeg.SaveToStream(stream);
               stream.Position := 0;
               Clipboard.AddFormat(cfJpeg, stream);
             end;
             if Image.Picture.Png <> nil then
             begin
               stream.Clear;
               Image.Picture.Png.SaveToStream(stream);
               stream.Position := 0;
               Clipboard.AddFormat(cfPNG, stream);
             end;
           finally
             stream.Free;
           end;
         finally
           Clipboard.Close;
         end;
         {
         if Image.Picture.Bitmap <> nil then
           Image.Picture.Bitmap.SaveToClipboardFormat(CF_Bitmap)
         else
           Image.Picture.SaveToClipboardFormat(CF_Picture);
           }
       end;
  end;
end;

procedure TDbfTable.EmptyClick(Sender: TObject);
begin
 If DbTable.Active Then
  If MessageDlg('Delete all records in the table?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
   Begin
    DBGrid.BeginUpdate;

    DbTable.EmptyTable;

    DBGrid.EndUpdate(False);

    DbTable.Close;
    DbTable.Open;
   End;
end;

procedure TDbfTable.FormDestroy(Sender: TObject);
begin
  if DBTable.Active then
    DBTable.Close;
end;

procedure TDbfTable.Load_Table_Indexes;
 Var Ind : Word;
begin
 Indexes.Clear;

 Indexes.Items.Add('');

 If DBTable.Indexes.Count > 0 Then
  For Ind := 0 To DBTable.Indexes.Count - 1 Do
   Indexes.Items.Add(DBTable.Indexes.Items[Ind].Name);
end;

procedure TDbfTable.ShowTableInfo(DataSet: TDataSet);
var
  field: TField;
begin
  Assert(Dataset is TDbf, 'Dataset must be a TDbf');

  SbInfo.Panels[0].Text := Format('Record Count: %d', [TDbf(DataSet).ExactRecordCount]);
  if DbTable.IsEmpty then
    SbInfo.Panels[1].Text := 'Record Number: (none)'
  else
    SbInfo.Panels[1].Text := Format('Record Number: %d', [Dataset.RecNo]);

  if TabControl.Tabs.Count > 0 then
  begin
    field := (Dataset as TDbf).FieldByName(TabControl.Tabs[TabControl.TabIndex]);
    ShowBlobField(field);
  end;
end;

procedure TDbfTable.TabControlChange(Sender: TObject);
 var
   field: TField;
 begin
   field := DBTable.FieldByName(TabControl.Tabs[TabControl.TabIndex]);
   ShowBLOBField(field);
 end;

procedure TDbfTable.CloseTabBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TDbfTable.tbAutoFillColumnsClick(Sender: TObject);
begin
  if tbAutoFillColumns.Down then
    SaveColWidths(DBTable);
  DBGrid.AutoFillColumns := tbAutoFillColumns.Down;
  if not tbAutoFillColumns.Down then
    RestoreColWidths(DBTable);
end;

procedure TDbfTable.ViewDelClick(Sender: TObject);
begin
  if DbTable.Active then
    if MessageDlg('Delete all records in grid?', mtWarning, [mbOk, mbCancel],0) = mrOk then
    begin
      DBGrid.BeginUpdate;
      try
        while Not DbTable.EOF do
          DbTable.Delete;
      finally
        DBGrid.EndUpdate(False);
      end;
      DbTable.Close;
      DbTable.Open;
    end;
end;

procedure TDbfTable.RestoreColWidths(ATable: TDbf);
var
  i: Integer;
  col: TColumn;
begin
  for i := 0 to ATable.FieldCount-1 do
  begin
    col := DBGrid.Columns.ColumnByFieldName(ATable.Fields[i].FieldName);
    col.Width := FColWidths[i];
  end;
end;

procedure TDbfTable.SaveColWidths(ATable: TDbf);
var
  i: Integer;
  col: TColumn;
begin
  SetLength(FColWidths, ATable.FieldCount);
  for i := 0 to ATable.FieldCount-1 do
  begin
    col := DBGrid.Columns.ColumnByFieldName(ATable.Fields[i].FieldName);
    FColWidths[i] := col.Width;
  end;
end;

procedure TDbfTable.Setup;
var
  field: TField;
begin
  Load_Table_Indexes();
  ShowBlob(DbTable);
  ShowTableInfo(DbTable);

  // Make sure that strings are converted to UTF-8.
  DbTable.OnTranslate := @TranslateHandler;
  for field in DbTable.Fields do
    if (field is TStringField) then
      TStringField(field).Transliterate := true;
end;

procedure TDbfTable.ShowBlob(ATable: TDbf);
var
  field: TField;
begin
  TabControl.BeginUpdate;
  try
    TabControl.Tabs.Clear;

    // For each BLOB field, add a tab to the tabcontrol
    for field in ATable.Fields do
      if (field is TBlobField) then
        TabControl.Tabs.Add(field.FieldName);

    // No BLOBs --> hide tabcontrol
    if TabControl.Tabs.Count = 0 then
    begin
      TabControl.Hide;
      MemoSplitter.Hide;
    end else
    begin
      // BLOBs found --> Display first BLOB field in tab control.
      field := ATable.FieldByName(TabControl.Tabs[0]);
      ShowBLOBField(field);
      TabControl.Show;
      TabControl.PageIndex := 0;
      MemoSplitter.Show;
      MemoSplitter.Top := 0;
    end;
  finally
    TabControl.EndUpdate;
  end;
end;

procedure TDbfTable.ShowBlobField(AField: TField);
var
  stream: TStream;
begin
  Assert(AField is TBlobField, 'Field must be a TBlobField');

  stream := TMemoryStream.Create;
  try
    TBlobField(AField).SaveToStream(stream);
    stream.Position := 0;
    if IsGraphicStream(stream) then
    begin
      Notebook.PageIndex := 1;
      Image.Picture.LoadFromStream(stream);
    end else
    if (AField is TMemoField) or (AField is TWideMemoField) then
    begin
      Notebook.PageIndex := 0;
      DBMemo.DataField := AField.FieldName;
    end;
  finally
    stream.Free;
  end;
end;

function TDbfTable.TranslateHandler(ATable: TDbf; Src, Dest: PChar; ToOem: Boolean): Integer;
var
  s: String;
  cp: String;
begin
  cp := 'cp' + IntToStr(ATable.CodePage);
  if ToOEM then
    s := ConvertEncoding(Src, 'utf8', cp)
  else
    s := ConvertEncoding(Src, cp, 'utf8');
  StrCopy(Dest, PChar(s));
  Result := StrLen(Dest);
end;


initialization
  cfJPEG := RegisterClipboardFormat('image/jpeg');
  cfPNG := RegisterClipboardFormat('image/png');

end.

