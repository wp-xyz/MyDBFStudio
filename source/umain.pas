unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazFileUtils,
  Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  LazHelpHTML, HelpIntfs,
  dbf_prscore, dbf_prsdef, dbf, DB,
  HistoryFiles, uTabForm;

type

  { TMain }

  TMain = class(TForm)
    HTMLBrowserHelpViewer: THTMLBrowserHelpViewer;
    HtmlHD: THTMLHelpDatabase;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    miSettings: TMenuItem;
    MenuItem3: TMenuItem;
    miHelp: TMenuItem;
    miInfo: TMenuItem;
    miRecentFiles: TMenuItem;
    miTabsList: TMenuItem;
    miSortTable: TMenuItem;
    MenuItem2: TMenuItem;
    miOptions: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    miEmptyTables: TMenuItem;
    miSubTables: TMenuItem;
    miAdd2Tbls: TMenuItem;
    miExpSQL: TMenuItem;
    miExpXML: TMenuItem;
    miExpDbf: TMenuItem;
    miExpXLS: TMenuItem;
    miExpHtml: TMenuItem;
    miExpCSV: TMenuItem;
    miExit: TMenuItem;
    miCloseAll: TMenuItem;
    miClose: TMenuItem;
    miSaveAs: TMenuItem;
    miOpenAlias: TMenuItem;
    miOpen: TMenuItem;
    miNew: TMenuItem;
    OpenTable: TOpenDialog;
    HistoryPopup: TPopupMenu;
    SaveAsTable: TSaveDialog;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    tbQuit: TToolButton;
    tbFileOpen: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    WorkSite: TPageControl;
    StatusBar: TStatusBar;
    ToolBar1: TToolBar;
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormShow(Sender: TObject);
    procedure miHelpClick(Sender: TObject);
    procedure miAdd2TblsClick(Sender: TObject);
    procedure miCloseAllClick(Sender: TObject);
    procedure miCloseClick(Sender: TObject);
    procedure miEmptyTablesClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miExpCSVClick(Sender: TObject);
    procedure miExpDbfClick(Sender: TObject);
    procedure miExpHtmlClick(Sender: TObject);
    procedure miExpSQLClick(Sender: TObject);
    procedure miExpXLSClick(Sender: TObject);
    procedure miExpXMLClick(Sender: TObject);
    procedure miInfoClick(Sender: TObject);
    procedure miNewClick(Sender: TObject);
    procedure miOpenAliasClick(Sender: TObject);
    procedure miOpenClick(Sender: TObject);
    procedure miSettingsClick(Sender: TObject);
    procedure miSaveAsClick(Sender: TObject);
    procedure miSortTableClick(Sender: TObject);
    procedure miSubTablesClick(Sender: TObject);
    procedure miTabsListClick(Sender: TObject);
    procedure tbQuitClick(Sender: TObject);
    procedure tbFileOpenMouseDown(Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure ToolButton2Click(Sender: TObject);
    procedure WorkSiteChange(Sender: TObject);
    procedure WorkSiteCloseTabClicked(Sender: TObject);

  private
    { private declarations }
    WorkSpace : TTabForm;
    FirstShow : Boolean;
    Procedure CreateAliasDB;
    Procedure ClickOnHistoryFile(Sender : TObject; {%H-}Item : TMenuItem; Const FileName : String);
    procedure TabChildCloseHandler(Sender: TObject; var CloseAction: TCloseAction);
    procedure HistoryPopupClick(Sender: TObject);
    Function TableIsAlreadyOpen(TblName : String): Integer;
    Function OBAIsAlreadyOpen: Integer;
    procedure ReadCmdLine;

  public
    { public declarations }
    FileHistory : THistoryFiles;
    Procedure Open_Table(TblName : String);
  end;

var
  Main: TMain;

implementation

{$R *.lfm}

Uses
  uNewTable, uDbfTable, uOpenBA, uExpCSV, uExpHtml, uExpXLS, uExpDBF,
  uExpXML, uExpSQL, uAddTables, uSubTables, uSortTable, uTabsList,
  uOptions, uSplash, uInfo, uUtils;

const
  KEYWORD_PREFIX = 'help';

Procedure FuncStrD_StrEq(Param: PExpressionRec);
Begin
 With Param^ Do
  Res.MemoryPos^^:=Char(PDateTime(Args[0])^ = StrToDate(Args[1]));
End;

Procedure FuncStrD_StrDif(Param: PExpressionRec);
Begin
 With Param^ Do
  Res.MemoryPos^^:=Char(PDateTime(Args[0])^ <> StrToDate(Args[1]));
End;

Procedure FuncStrD_StrMax(Param: PExpressionRec);
Begin
 With Param^ Do
  Res.MemoryPos^^:=Char(PDateTime(Args[0])^ > StrToDate(Args[1]));
End;

Procedure FuncStrD_StrMin(Param: PExpressionRec);
Begin
 With Param^ Do
  Res.MemoryPos^^:=Char(PDateTime(Args[0])^ < StrToDate(Args[1]));
End;

Procedure FuncStrD_StrMaxEq(Param: PExpressionRec);
Begin
 With Param^ Do
  Res.MemoryPos^^:=Char(PDateTime(Args[0])^ >= StrToDate(Args[1]));
End;

Procedure FuncStrD_StrMinEq(Param: PExpressionRec);
Begin
 With Param^ Do
  Res.MemoryPos^^:=Char(PDateTime(Args[0])^ <= StrToDate(Args[1]));
End;

Procedure FuncStrB_StrEq(Param: PExpressionRec);
 Var Tmp : String;
Begin
 If Boolean(Param^.Args[0]^) Then
  Tmp:='TRUE'
 Else
  Tmp:='FALSE';

 With Param^ Do
  Res.MemoryPos^^:=Char(Tmp = UpperCase(Args[1]));
End;

{ TMain }

procedure TMain.FormCreate(Sender: TObject);
begin
 FirstShow := True;

 LoadOptions;

 Splash := TSplash.Create(Self);
 try
   if Options.ShowSplashScreen Then
     Splash.ShowModal;
 finally
   FreeAndNil(Splash);
 end;

 If not FileExists(GetAliasDir + 'alias.dbf') Then
  CreateAliasDB();

 FileHistory := THistoryFiles.Create(Self);
 FileHistory.ParentMenu := miRecentFiles;
 FileHistory.LocalPath := Application.Location;
 FileHistory.IniFile := IniFileName;
 FileHistory.OnClickHistoryItem := @ClickOnHistoryFile;
 FileHistory.FileMustExist := True;
 FileHistory.MaxItems := Options.MaxHistoryRecords;

 WorkSpace := TTabForm.Create(WorkSite);

 dbf_prscore.DbfWordsGeneralList.Add(TFunction.Create('STR',       '',      'LII', 1, etString, @FuncFloatToStr, ''));

 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('=', 'DS', etBoolean, @FuncStrD_StrEq, 80));
 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('<>', 'DS', etBoolean, @FuncStrD_StrDif, 80));
 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('>', 'DS', etBoolean, @FuncStrD_StrMax, 80));
 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('<', 'DS', etBoolean, @FuncStrD_StrMin, 80));
 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('>=', 'DS', etBoolean, @FuncStrD_StrMaxEq, 80));
 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('<=', 'DS', etBoolean, @FuncStrD_StrMinEq, 80));
 dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('=', 'BS', etBoolean, @FuncStrB_StrEq, 80));

 Caption := Caption + ' ' + GetVersionStr;

 HtmlHD.KeywordPrefix := KEYWORD_PREFIX + '/';
 HtmlHD.BaseURL := 'file://' + Application.Location + KEYWORD_PREFIX;

 If ParamStr(1) <> '' Then
  Open_Table(ParamStr(1));
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
 If MessageDlg('Do you want to close MyDbf Studio?',mtWarning,[mbOk, mbCancel],0) = mrOk Then
   CanClose := true
 Else
   CanClose := False;
end;

procedure TMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  If Options.RememberWindowSizePos Then
  Begin
    Options.MainWindowState := WindowState;
    if WindowState = wsNormal then
    begin
      Options.MainHeight := Height;
      Options.MainLeft := Left;
      Options.MainTop := Top;
      Options.MainWidth := Width;
    end;
  end;

  SaveOptions;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  WorkSpace.Free;
end;

procedure TMain.FormDropFiles(Sender: TObject; const FileNames: array of string);
const
  MAX_LOG = 10;
var
  fn: String;
  L: TStrings;
begin
  L := TStringList.Create;
  try
    for fn in FileNames do
      if Lowercase(ExtractFileExt(fn)) = '.dbf' then
        Open_Table(fn)
      else
        L.Add(fn);
    if L.Count > 0 then
    begin
      if L.Count > MAX_LOG then
      begin
        while L.Count > MAX_LOG do
          L.Delete(L.Count-1);
        L.Add('(more...)');
      end;
      MessageDlg(
        'The following files could not be loaded due to incorrect extension: ' +
          LineEnding + L.Text,
        mtError, [mbOK], 0
      );
    end;
  finally
    L.Free;
  end;
end;

procedure TMain.FormShow(Sender: TObject);
var
  W, H, L, T: Integer;
  R: TRect;
begin
  If FirstShow Then
  Begin
   FileHistory.MaxItems := Options.MaxHistoryRecords;
   FileHistory.UpdateParentMenu;

   ToolBar1.Visible := Options.EnableToolBar;
   StatusBar.Visible := Options.EnableStatusBar;

   If Options.StartWithOBA Then
    miOpenAliasClick(Sender);

   If Options.RememberWindowSizePos Then
   Begin
     WindowState := Options.MainWindowState;
     if WindowState = wsNormal then
     begin
       R := Screen.WorkAreaRect;
       H := Options.MainHeight;
       if H = 0 then H := Height;
       L := Options.MainLeft;
       if L = 0 then L := Left;
       T := Options.MainTop;
       if T = 0 then T := Top;
       W := Options.MainWidth;
       if W = 0 then W := Width;
       if W > R.Width then W := R.Width;
       if H > R.Height then H := R.Height;
       if L < R.Left then L := R.Left;
       if T < R.Top then T := R.Top;
       if L + W > R.Right then L := R.Right - W;
       if T + H > R.Bottom then T := R.Bottom - H;
       SetBounds(L, T, W, H);
    end;
    FirstShow := False;
   end;
  end;

  ReadCmdLine;
end;

procedure TMain.HistoryPopupClick(Sender: TObject);
var
  item: TMenuItem;
  idx: Integer;
begin
  if not (Sender is TMenuItem) then exit;
  idx := TMenuItem(Sender).Tag;
  item := FileHistory.ParentMenu.Items[idx];
  if item.OnClick <> nil then item.OnClick(item);
end;

procedure TMain.miHelpClick(Sender: TObject);
begin
  ShowHelpOrErrorForKeyword('', KEYWORD_PREFIX + '/index.html');
end;

procedure TMain.miAdd2TblsClick(Sender: TObject);
begin
  AddTables := TAddTables.Create(nil);
  try
    AddTables.ShowModal;
  finally
    FreeAndNil(AddTables);
  end;
end;

procedure TMain.miCloseAllClick(Sender: TObject);
 Var Ind : Integer;
begin
 WorkSite.BeginUpdateBounds;

 If WorkSite.PageCount > 0 Then
  If MessageDlg('Close all tabs?', mtWarning, [mbOk, mbCancel],0) = mrOk Then
   For Ind := WorkSite.PageCount - 1 DownTo 0 Do
    WorkSiteCloseTabClicked(WorkSite.Pages[Ind]);

 WorkSite.EndUpdateBounds;
end;

procedure TMain.miCloseClick(Sender: TObject);
begin
 If WorkSite.PageCount > 0 Then
  If WorkSite.ActivePage <> Nil Then
   WorkSiteCloseTabClicked(WorkSite.ActivePage);
end;

procedure TMain.miEmptyTablesClick(Sender: TObject);
 Var Ind : Word;
     Tmp : TDbf;
begin
 If OpenTable.Execute Then
  Begin
   Tmp := TDbf.Create(Self);
   Tmp.Exclusive := True;

   For Ind := 0 To OpenTable.Files.Count - 1 Do
    Begin
     Tmp.TableName := OpenTable.Files.Strings[Ind];

     Try
       Tmp.Open;

       If MessageDlg('Delete all records in the table ' + Tmp.TableName,mtWarning,[mbOk, mbCancel],0) = mrOk Then
        Tmp.EmptyTable;

       Tmp.Close;
     Except
       ShowMessage('Can''t open table ' + Tmp.TableName + ' in exclusive mode!');
     End;
    End;

   Tmp.Close;
   Tmp.Free;
  End;
end;

procedure TMain.miExitClick(Sender: TObject);
begin
 Close;
end;

procedure TMain.miExpCSVClick(Sender: TObject);
var
  F: TForm;
begin
  if (WorkSite.ActivePage is TTabForm) then
    if TTabForm(WorkSite.ActivePage).ParentForm is TDbfTable then
    begin
      F := TTabForm(WorkSite.ActivePage).ParentForm;

      ExpCSV := TExpCSV.Create(nil);
      try
        ExpCSV.DbfTable := TDbfTable(F).DBTable;

        TDbfTable(F).Ds.Enabled := false;
        TDbfTable(F).Ds.DataSet := nil;

        ExpCSV.ShowModal;

        TDbfTable(F).Ds.DataSet := TDbfTable(F).DBTable;
        TDbfTable(F).Ds.Enabled := True;
      finally
        FreeAndNil(ExpCSV);
      end;
    end;
end;

procedure TMain.miExpDbfClick(Sender: TObject);
var
  F: TForm;
begin
  if (WorkSite.ActivePage is TTabForm) then
    if (TTabForm(WorkSite.ActivePage).ParentForm is TDbfTable) then
    begin
      F := TTabForm(WorkSite.ActivePage).ParentForm;

      ExpDBF := TExpDBF.Create(nil);
      try
        ExpDBF.DbfTable := TDbfTable(F).DBTable;

        TDbfTable(F).Ds.Enabled := False;
        TDbfTable(F).Ds.DataSet := nil;

        ExpDBF.ShowModal;

        TDbfTable(F).Ds.DataSet := TDbfTable(F).DBTable;
        TDbfTable(F).Ds.Enabled := True;
      finally
        FreeAndNil(ExpDBF);
      end;
    end;
end;

procedure TMain.miExpHtmlClick(Sender: TObject);
var
  F: TForm;
begin
  if (WorkSite.ActivePage Is TTabForm) then
    if (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable then
    begin
      F := (WorkSite.ActivePage As TTabForm).ParentForm;

      ExpHTML := TExpHTML.Create(nil);
      try
        ExpHTML.DbfTable := (F As TDbfTable).DBTable;

        (F As TDbfTable).Ds.Enabled := False;
        (F As TDbfTable).Ds.DataSet := Nil;
        ExpHTML.ShowModal;
        (F As TDbfTable).Ds.DataSet := (F As TDbfTable).DBTable;
        (F As TDbfTable).Ds.Enabled := True;

      finally
        FreeAndNil(ExpHTML);
      end;
    end;
end;

procedure TMain.miExpSQLClick(Sender: TObject);
var
  F: TForm;
begin
  if (WorkSite.ActivePage is TTabForm) then
    if TTabForm(WorkSite.ActivePage).ParentForm is TDbfTable then
    begin
      F := TTabForm(WorkSite.ActivePage).ParentForm;

      ExpSQL := TExpSQL.Create(nil);
      try
        ExpSQL.DbfTable := TDbfTable(F).DBTable;

        TDbfTable(F).Ds.Enabled := false;
        TDbfTable(F).Ds.DataSet := nil;

        ExpSQL.ShowModal;

        TDbfTable(F).Ds.DataSet := TDbfTable(F).DBTable;
        TDbfTable(F).Ds.Enabled := True;
      finally
        FreeAndNil(ExpSQL);
      end;
    end;
end;

procedure TMain.miExpXLSClick(Sender: TObject);
var
  F: TForm;
begin
  if (WorkSite.ActivePage is TTabForm) then
    if TTabForm(WorkSite.ActivePage).ParentForm is TDbfTable then
    begin
      F := TTabForm(WorkSite.ActivePage).ParentForm;

      ExpXLS := TExpXLS.Create(nil);
      try
        ExpXLS.DbfTable := TDbfTable(F).DBTable;

        TDbfTable(F).Ds.Enabled := false;
        TDbfTable(F).Ds.DataSet := nil;

        ExpXLS.ShowModal;

        TDbfTable(F).Ds.DataSet := TDbfTable(F).DBTable;
        TDbfTable(F).Ds.Enabled := true;
      finally
        FreeAndNil(ExpXLS);
      end;
    end;
end;

procedure TMain.miExpXMLClick(Sender: TObject);
var
  F: TForm;
begin
  if (WorkSite.ActivePage is TTabForm) then
    if TTabForm(WorkSite.ActivePage).ParentForm is TDbfTable then
    begin
      F := TTabForm(WorkSite.ActivePage).ParentForm;

      ExpXML := TExpXML.Create(nil);
      try
        ExpXML.DbfTable := TDbfTable(F).DBTable;

        TDbfTable(F).Ds.Enabled := false;
        TDbfTable(F As TDbfTable).Ds.DataSet := nil;

        ExpXML.ShowModal;

        TDbfTable(F).Ds.DataSet := TDbfTable(F).DBTable;
        TDbfTable(F).Ds.Enabled := True;
      finally
        FreeAndNil(ExpXML);
      end;
    end;
end;

procedure TMain.miInfoClick(Sender: TObject);
begin
  Info := TInfo.Create(nil);
  try
    Info.ShowModal;
  finally
    FreeAndNil(Info);
  end;
end;

procedure TMain.miNewClick(Sender: TObject);
var
  NT: TNewTable;
begin
  NT := TNewTable.Create(WorkSite);
  NT.FieldList.AlternateColor := Options.AlternateColor;
  NT.OnClose := @TabChildCloseHandler;
  WorkSpace.AddFormToPageControl(NT);
end;

procedure TMain.miOpenAliasClick(Sender: TObject);
var
  ObA: TOpenBA;
  tabIndex: Integer;
begin
  tabIndex := OBAIsAlreadyOpen;
  if tabIndex < 0 then
  begin
    ObA := TOpenBA.Create(WorkSite);
    ObA.OnClose := @TabChildCloseHandler;
    WorkSpace.AddFormToPageControl(ObA);
  end
  else
    WorkSite.TabIndex := tabIndex;
end;

procedure TMain.miOpenClick(Sender: TObject);
 Var Ind : Word;
begin
 If OpenTable.Execute Then
  Begin
   For Ind := 0 To OpenTable.Files.Count - 1 Do
    Open_Table(OpenTable.Files.Strings[Ind]);
  End;
end;

procedure TMain.miSettingsClick(Sender: TObject);
begin
  OptionsForm := TOptionsForm.Create(nil);
  try
    OptionsForm.ShowModal;
  finally
    FreeAndNil(OptionsForm);
  end;
end;

procedure TMain.miSaveAsClick(Sender: TObject);
 Var Tmp : TForm;
     IdxName : String;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    If SaveAsTable.Execute Then
     Begin
      With (Tmp As TDbfTable) Do
       Begin
        DBTable.Close;

        If CopyFile(DbTable.FilePathFull + DBTable.TableName, SaveAsTable.FileName) Then
         Begin
          IdxName := ExtractFileNameWithoutExt(DBTable.TableName) + '.mdx';

          If FileExists(IdxName) Then
           If Not CopyFile(DbTable.FilePathFull + IdxName, ExtractFileNameWithoutExt(SaveAsTable.FileName) + '.mdx', False) Then
            ShowMessage('Error while copy index!');
         end
        Else
         ShowMessage('Error while copy table!');

        DbTable.Open;
       end;
     end;
   end;
end;

procedure TMain.miSortTableClick(Sender: TObject);
var
  F: TDbfTable;
  tmp: TForm;
begin
  if (WorkSite.ActivePage is TTabForm) then
    if TTabForm(WorkSite.ActivePage).ParentForm is TDbfTable then
    begin
      F := TDbfTable(TTabForm(WorkSite.ActivePage).ParentForm);
      SortTable := TSortTable.Create(nil);
      try
        SortTable.OrigTable := F.DBTable;
        F.DS.Enabled := false;
        F.DS.Dataset := nil;
        SortTable.ShowModal;
        Options.SortTableWindow.ExtractFromForm(SortTable);
      finally
        FreeAndNil(SortTable);
        F.Ds.Dataset := F.DBTable;
        F.Ds.Enabled := true;
      end;
    end;
end;

procedure TMain.miSubTablesClick(Sender: TObject);
begin
  SubTables := TSubTables.Create(nil);
  try
    SubTables.ShowModal;
  finally
    FreeAndNil(SubTables);
  end;
end;

procedure TMain.miTabsListClick(Sender: TObject);
begin
  TabsList := TTabsList.Create(nil);
  try
    TabsList.ShowModal;
  finally
    FreeAndNil(TabsList);
  end;
end;

procedure TMain.tbQuitClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.tbFileOpenMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  item: TMenuItem;
begin
  HistoryPopup.Items.Clear;
  for i := 0 to FileHistory.ParentMenu.Count-1 do begin
    item := TMenuItem.Create(HistoryPopup);
    item.Caption := FileHistory.ParentMenu.Items[i].caption;
    item.OnClick := @HistoryPopupClick;
    item.Tag := i;
    HistoryPopup.Items.Add(item);
  end;
end;

procedure TMain.ToolButton2Click(Sender: TObject);
begin
  miSettingsClick(nil);
end;

procedure TMain.WorkSiteChange(Sender: TObject);
 Var Tmp : TForm;
begin
 If WorkSite.PageCount <= 0 Then
  Begin
   StatusBar.SimpleText := '';

   Exit;
  end;

 If (WorkSite.ActivePage Is TTabForm) Then
  Begin
   If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
    Begin
     Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

     With (Tmp As TDbfTable) Do
      StatusBar.SimpleText := DBTable.FilePathFull + DBTable.TableName;
    end
   Else
    StatusBar.SimpleText := '';
  end
 Else
  StatusBar.SimpleText := '';
end;

procedure TMain.WorkSiteCloseTabClicked(Sender: TObject);
begin
 (Sender As TTabForm).Free;
end;

procedure TMain.ClickOnHistoryFile(Sender: TObject; Item: TMenuItem;
  const FileName: String);
begin
 Open_Table(Filename);
end;

procedure TMain.CreateAliasDB;
var
  T: TDbf;
  dir: String;
begin
  dir := GetAliasDir;
  T := TDbf.Create(Self);
  try
    try
      T.TableName := 'alias.dbf';
      T.FilePath := dir;
      T.FieldDefs.Add('ALIAS', ftString, 80);
      T.FieldDefs.Add('PATH', ftString, 255);
      T.CreateTable;

      T.Open;
      T.AddIndex('ALIAS', 'ALIAS', [ixPrimary]);
      MessageDlg('Alias DB not found. Created in ' + dir, mtError, [mbOK], 0);
      T.Close;
    except
      on E:Exception do
        MessageDlg('Error while creating alias db.' + LineEnding + E.Message, mtError, [mbOK], 0);
    end;
  finally
    T.Free;
  end;
end;

procedure TMain.TabChildCloseHandler(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;

  // Remove the tabsheet
  if (Sender is TDBFTable) or (Sender is TNewTable) or (Sender is TOpenBA) then
    TControl(Sender).Parent.Free;
end;

function TMain.TableIsAlreadyOpen(TblName: String): Integer;
var
  ind: Integer;
  frm: TForm;
  fName: String;
begin
  Result := -1;

  if WorkSite.PageCount > 0 then
    for ind := 0 To WorkSite.PageCount - 1 do
      if (WorkSite.Pages[ind] Is TTabForm) then
        if (WorkSite.Pages[ind] As TTabForm).ParentForm Is TDbfTable then
        begin
          frm := (WorkSite.Pages[ind] As TTabForm).ParentForm;
          with TDbfTable(frm) do
          begin
            fName := DbTable.FilePathFull + DBTable.TableName;
            if fName = TblName then
            begin
              Result := ind;
              Exit;
            end;
          end;
        end;
end;

function TMain.OBAIsAlreadyOpen: Integer;
var
  ind: Integer;
begin
  Result := -1;
  if WorkSite.PageCount > 0 then
    for ind := 0 To WorkSite.PageCount - 1 do
      if (WorkSite.Pages[ind] Is TTabForm) then
        if (WorkSite.Pages[ind] As TTabForm).ParentForm Is TOpenBA then
        begin
          Result := ind;
          exit;
        end;
end;

procedure TMain.Open_Table(TblName: String);
var
  OT: TDbfTable;
  tabIndex: Integer;
begin
  TblName := ExpandFileName(TblName);
  if not FileExists(TblName) then
    Exit;

  tabIndex := TableIsAlreadyOpen(TblName);

  if tabIndex < 0 then
  begin
    OT := TDbfTable.Create(WorkSite);
    OT.OnClose := @TabChildCloseHandler;

    WorkSpace.AddFormToPageControl(OT);

    OT.DBTable.TableName := TblName;
    OT.DBGrid.AlternateColor := Options.AlternateColor;
    OT.DBTable.Open;

    If Options.GotoLastRecord Then
      OT.DBTable.Last;

    OT.Setup;
    WorkSite.ActivePage.Caption := ExtractFileName(TblName);
    StatusBar.SimpleText := OT.DBTable.FilePathFull + OT.DBTable.TableName;
    FileHistory.UpdateList(TblName);
  end
  else
    WorkSite.TabIndex := tabIndex;
end;

// For easier debugging...
procedure TMain.ReadCmdLine;
var
  i: Integer;
begin
  for i := 1 to ParamCount do
    Open_Table(ParamStr(i));
end;

end.

