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
    miexpXML: TMenuItem;
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
    procedure miexpXMLClick(Sender: TObject);
    procedure miInfoClick(Sender: TObject);
    procedure miNewClick(Sender: TObject);
    procedure miOpenAliasClick(Sender: TObject);
    procedure miOpenClick(Sender: TObject);
    procedure miOptionsClick(Sender: TObject);
    procedure miSaveAsClick(Sender: TObject);
    procedure miSortTableClick(Sender: TObject);
    procedure miSubTablesClick(Sender: TObject);
    procedure miTabsListClick(Sender: TObject);
    procedure tbQuitClick(Sender: TObject);
    procedure tbFileOpenMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ToolButton2Click(Sender: TObject);
    procedure WorkSiteChange(Sender: TObject);
    procedure WorkSiteCloseTabClicked(Sender: TObject);

  private
    { private declarations }
    WorkSpace : TTabForm;
    FirstShow : Boolean;

    Procedure CreateAliasDB;

    Procedure ClickOnHistoryFile(Sender : TObject; {%H-}Item : TMenuItem; Const FileName : String);
    procedure HistoryPopupClick(Sender: TObject);
    Function TableIsAlredyOpened(TblName : String) : Integer;
    Function OBAIsAlredyOpened : Integer;
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
  Math,
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

 If Not FileExists(Application.Location + 'alias.dbf') Then
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
 AddTables := TAddTables.Create(Self);
 try
   AddTables.ShowModal;
   Options.AddTablesWidth := AddTables.Width;
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
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
  Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    ExpCSV := TExpCSV.Create(nil);
    try
      ExpCSV.Tmp := (Tmp As TDbfTable).DBTable;

      (Tmp As TDbfTable).Ds.Enabled := False;
      (Tmp As TDbfTable).Ds.DataSet := Nil;

      ExpCSV.ShowModal;

      (Tmp As TDbfTable).Ds.DataSet := (Tmp As TDbfTable).DBTable;
      (Tmp As TDbfTable).Ds.Enabled := True;
    finally
      FreeAndNil(ExpCSV);
    end;
  end;
end;

procedure TMain.miExpDbfClick(Sender: TObject);
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    ExpDBF := TExpDBF.Create(nil);
    try
      ExpDBF.Tmp := (Tmp As TDbfTable).DBTable;

      (Tmp As TDbfTable).Ds.Enabled := False;
      (Tmp As TDbfTable).Ds.DataSet := Nil;

      ExpDBF.ShowModal;

      (Tmp As TDbfTable).Ds.DataSet := (Tmp As TDbfTable).DBTable;
      (Tmp As TDbfTable).Ds.Enabled := True;

    finally
      FreeAndNil(ExpDBF);
    end;
   end;
end;

procedure TMain.miExpHtmlClick(Sender: TObject);
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    ExpHTML := TExpHTML.Create(nil);
    try
      ExpHTML.Tmp := (Tmp As TDbfTable).DBTable;

      (Tmp As TDbfTable).Ds.Enabled := False;
      (Tmp As TDbfTable).Ds.DataSet := Nil;

      ExpHTML.ShowModal;

      (Tmp As TDbfTable).Ds.DataSet := (Tmp As TDbfTable).DBTable;
      (Tmp As TDbfTable).Ds.Enabled := True;

    finally
      FreeAndNil(ExpHTML);
    end;
   end;
end;

procedure TMain.miExpSQLClick(Sender: TObject);
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    ExpSQL := TExpSQL.Create(nil);
    try
      ExpSQL.Tmp := (Tmp As TDbfTable).DBTable;

      (Tmp As TDbfTable).Ds.Enabled := False;
      (Tmp As TDbfTable).Ds.DataSet := Nil;

      ExpSQL.ShowModal;

      (Tmp As TDbfTable).Ds.DataSet := (Tmp As TDbfTable).DBTable;
      (Tmp As TDbfTable).Ds.Enabled := True;
    finally
      FreeAndNil(ExpSQL);
    end;
   end;
end;

procedure TMain.miExpXLSClick(Sender: TObject);
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    ExpXLS := TExpXLS.Create(nil);
    try
      ExpXLS.Tmp := (Tmp As TDbfTable).DBTable;

      (Tmp As TDbfTable).Ds.Enabled := False;
      (Tmp As TDbfTable).Ds.DataSet := Nil;

      ExpXLS.ShowModal;

      (Tmp As TDbfTable).Ds.DataSet := (Tmp As TDbfTable).DBTable;
      (Tmp As TDbfTable).Ds.Enabled := True;
    finally
      FreeAndNil(ExpXLS);
    end;
   end;
end;

procedure TMain.miexpXMLClick(Sender: TObject);
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    ExpXML := TExpXML.Create(nil);
    try
      ExpXML.Tmp := (Tmp As TDbfTable).DBTable;

      (Tmp As TDbfTable).Ds.Enabled := False;
      (Tmp As TDbfTable).Ds.DataSet := Nil;

      ExpXML.ShowModal;

      (Tmp As TDbfTable).Ds.DataSet := (Tmp As TDbfTable).DBTable;
      (Tmp As TDbfTable).Ds.Enabled := True;
    finally
      FreeAndNil(ExpXML);
    end;
   end;
end;

procedure TMain.miInfoClick(Sender: TObject);
begin
  Info := TInfo.Create(Self);
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
  WorkSpace.AddFormToPageControl(NT);
  NT.PageIdx := WorkSite.ActivePage.PageIndex;
end;

procedure TMain.miOpenAliasClick(Sender: TObject);
 Var ObA : TOpenBA;
     FindOBA : Integer;
begin
 FindOBA := OBAIsAlredyOpened;

 If FindOBA < 0 Then
  Begin
   ObA := TOpenBA.Create(WorkSite);

   WorkSpace.AddFormToPageControl(ObA);

   ObA.PageIdx := WorkSite.ActivePage.PageIndex;
  end
 Else
  WorkSite.TabIndex := FindOBA;
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

procedure TMain.miOptionsClick(Sender: TObject);
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
 Var Tmp : TForm;
begin
 If (WorkSite.ActivePage Is TTabForm) Then
  If (WorkSite.ActivePage As TTabForm).ParentForm Is TDbfTable Then
   Begin
    Tmp := (WorkSite.ActivePage As TTabForm).ParentForm;

    With (Tmp As TDbfTable) Do
     Begin
      SortTable := TSortTable.Create(nil);
      try
        SortTable.Orig := DBTable;

        Ds.Enabled := False;
        Ds.DataSet := Nil;

        SortTable.ShowModal;
      finally
        FreeAndNil(SortTable);
      end;

      Ds.DataSet := DBTable;
      Ds.Enabled := True;
     end;
   end;
end;

procedure TMain.miSubTablesClick(Sender: TObject);
begin
  SubTables := TSubTables.Create(nil);
  try
    SubTables.ShowModal;
    Options.SubtractTablesWidth := SubTables.Width;
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
  miOptionsClick(nil);
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
 Var T : TDbf;
begin
 Try
   T := TDbf.Create(Self);
   try
     T.TableName := 'alias.dbf';
     T.FilePath := ExtractFilePath(Application.ExeName);
     T.FieldDefs.Add('ALIAS', ftString, 80);
     T.FieldDefs.Add('PATH', ftString, 255);
     T.CreateTable;

     T.Open;
     T.AddIndex('ALIAS', 'ALIAS', [ixPrimary]);
     ShowMessage('Alias DB not found! Created!');
     T.Close;
   except
     ShowMessage('Error while creating alias db.');
   end;
 finally
   T.Free;
 end;
end;

function TMain.TableIsAlredyOpened(TblName: String): Integer;
 Var Ind : Integer;
     Tmp : TForm;
     fName : String;
begin
 Result := -1;

 If WorkSite.PageCount > 0 Then
  For Ind := 0 To WorkSite.PageCount - 1 Do
   If (WorkSite.Pages[Ind] Is TTabForm) Then
    If (WorkSite.Pages[Ind] As TTabForm).ParentForm Is TDbfTable Then
     Begin
      Tmp := (WorkSite.Pages[Ind] As TTabForm).ParentForm;

      With (Tmp As TDbfTable) Do
       Begin
        fName := DbTable.FilePathFull + DBTable.TableName;

        If fName = TblName Then
         Begin
          Result := PageIdx;

          Break;
         end;
       end;
     end;
end;

function TMain.OBAIsAlredyOpened : Integer;
 Var Ind : Integer;
begin
 Result := -1;

 If WorkSite.PageCount > 0 Then
  For Ind := 0 To WorkSite.PageCount - 1 Do
   If (WorkSite.Pages[Ind] Is TTabForm) Then
    If (WorkSite.Pages[Ind] As TTabForm).ParentForm Is TOpenBA Then
     Begin
      Result := Ind;

      Break;
     end;
end;

procedure TMain.Open_Table(TblName: String);
 Var OT : TDbfTable;
     FindTbl : Integer;
begin
 If Not FileExists(TblName) Then
  Exit;

 FindTbl := TableIsAlredyOpened(TblName);

 If FindTbl < 0 Then
  Begin
   OT := TDbfTable.Create(WorkSite);

   WorkSpace.AddFormToPageControl(OT);

   OT.DBTable.TableName := TblName;
   OT.DBGrid1.AlternateColor := Options.AlternateColor;
   OT.DBTable.Open;

   If Options.GotoLastRecord Then
    OT.DBTable.Last;

   OT.Set_Up;

   WorkSite.ActivePage.Caption := ExtractFileName(TblName);

   OT.PageIdx := WorkSite.ActivePage.PageIndex;

   StatusBar.SimpleText := OT.DBTable.FilePathFull + OT.DBTable.TableName;

   FileHistory.UpdateList(TblName);
  end
 Else
  WorkSite.TabIndex := FindTbl;
end;

end.

