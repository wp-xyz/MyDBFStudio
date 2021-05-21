unit T_MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, Menus, ExtCtrls, LazHelpHTML, buttonsbar, MultiDoc, ChildDoc,
  dbf_prscore, dbf_prsdef, dbf, HelpIntfs, db;

Type
    IconRec                    = Packed Record
     FileName                  : String;
     MaskR,
     MaskG,
     MaskB                     : Byte;
    End;

Const
     StrVer                    = '0.4 beta';

type

  { TMain }

  TMain = class(TForm)
    HTMLBrowserHelpViewer1: THTMLBrowserHelpViewer;
    HtmlHD: THTMLHelpDatabase;
//    AppTmpImg: TImage;
    ImgMenu: TImageList;
    MenuItem10: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem28: TMenuItem;
    MenuItem29: TMenuItem;
    MenuItem9: TMenuItem;
    SaveAsTable: TSaveDialog;
    ImgList: TImageList;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem3: TMenuItem;
    mWindow: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    OpenTable: TOpenDialog;
    StatusBar: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure ButtonsBarClickClose(Sender: TObject);
    procedure ButtonsBarClickMaximize(Sender: TObject);
    procedure ButtonsBarClickMinimize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem14Click(Sender: TObject);
    procedure MenuItem15Click(Sender: TObject);
    procedure MenuItem16Click(Sender: TObject);
    procedure MenuItem17Click(Sender: TObject);
    procedure MenuItem18Click(Sender: TObject);
    procedure MenuItem19Click(Sender: TObject);
    procedure MenuItem20Click(Sender: TObject);
    procedure MenuItem21Click(Sender: TObject);
    procedure MenuItem22Click(Sender: TObject);
    procedure MenuItem24Click(Sender: TObject);
    procedure MenuItem25Click(Sender: TObject);
    procedure MenuItem26Click(Sender: TObject);
    procedure MenuItem28Click(Sender: TObject);
    procedure MenuItem29Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
  private
    { private declarations }
    IconList                  : Array [0..5] Of IconRec;
    IconMenu                  : Array [0..12] Of IconRec;
    ButtonsBar: TButtonsBar;

    Procedure MultiDocMaximize(Sender: TObject);

    Procedure ChildMinimize(Sender: TObject);
    Procedure ChildMaximize(Sender: TObject);
    Procedure ChildClose(Sender : TObject; var CanClose : boolean);
    Procedure ChildEnter(Sender: TObject);

    Procedure Set_Up();

    Procedure ShowSplashScreen();

    Procedure Load_Icons();

    Procedure CreateAliasDB();
  public
    { public declarations }
    MultiWnd: TMultiDoc;

    Procedure Open_Table(TblName : String);
  end; 

var
  Main: TMain;

implementation

{$R *.lfm}

uses
  T_DbfTable, T_NewTable, T_AddTables, T_SubTables, uSortTable, uOpenBA,
  uExpCSV, uExpDbf, uExpHtml, uExpXls, uExpXml, uExpSQL, uSplash, uInfo;

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
var
  dir: String;
begin
  ShowSplashScreen();

  MultiWnd := TMultiDoc.Create(self);
  with MultiWnd do
  begin
    Align := alClient;
    HorzScrollbar.Page := 1;
    VertScrollbar.Page := 1;
    WindowList:=mWindow;
    OnMaximize:=@MultiDocMaximize;
    Parent := self;
  end;

  Buttonsbar := TButtonsBar.Create(self);
  with ButtonsBar do
  begin
    Visible := False;
    OnClickClose := @ButtonsBarClickClose;
    OnClickMinimize := @ButtonsBarClickMinimize;
    OnClickMaximize := @ButtonsBarClickMaximize;
    Parent := self;
  end;

  if not FileExists(Application.Location + 'alias.dbf') then
    CreateAliasDB();

  dbf_prscore.DbfWordsGeneralList.Add(TFunction.Create('STR',       '',      'LII', 1, etString, @FuncFloatToStr, ''));

  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('=', 'DS', etBoolean, @FuncStrD_StrEq, 80));
  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('<>', 'DS', etBoolean, @FuncStrD_StrDif, 80));
  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('>', 'DS', etBoolean, @FuncStrD_StrMax, 80));
  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('<', 'DS', etBoolean, @FuncStrD_StrMin, 80));
  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('>=', 'DS', etBoolean, @FuncStrD_StrMaxEq, 80));
  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('<=', 'DS', etBoolean, @FuncStrD_StrMinEq, 80));

  dbf_prscore.DbfWordsSensPartialList.Add(TFunction.CreateOper('=', 'BS', etBoolean, @FuncStrB_StrEq, 80));

  Load_Icons();

  Caption:=Caption + ' v' + StrVer;

  HtmlHD.BaseURL:='file://' + Application.Location + 'help';

  if ParamStr(1) <> '' Then
    Open_Table(ParamStr(1));
end;

procedure TMain.FormResize(Sender: TObject);
 Var Ind : Word;
     TmpLeft,TmpTop : Integer;
begin
 If MultiWnd.ChildCount > 0 Then
  Begin
   TmpLeft:=-200;
   TmpTop:=MultiWnd.Height - 34;

   For Ind:=0 To MultiWnd.ChildCount - 1 Do
    If Assigned(MultiWnd.Childs[Ind]) Then
     If MultiWnd.Childs[Ind].Iconized = True Then
      Begin
       TmpLeft:=TmpLeft + 200;

       If (TmpLeft + 200) > MultiWnd.Width Then
        Begin
         TmpLeft:=0;
         TmpTop:=TmpTop - 30;
        End;

       MultiWnd.Childs[Ind].Left:=TmpLeft;
       MultiWnd.Childs[Ind].Top:=TmpTop;
      End;
  End;
end;

procedure TMain.MenuItem10Click(Sender: TObject);
begin
 ShowHelpOrErrorForKeyword('','help/index.html');
end;

procedure TMain.MenuItem11Click(Sender: TObject);
begin
 If MessageDlg('Do you want to close MyDbf Studio?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
  Application.Terminate;
end;

procedure TMain.MenuItem13Click(Sender: TObject);
begin
 AddTables:=TAddTables.Create(Self);

 AddTables.ShowModal;

 AddTables.Release;
end;

procedure TMain.MenuItem14Click(Sender: TObject);
begin
 SubTables:=TSubTables.Create(Self);

 SubTables.ShowModal;

 SubTables.Release;
end;

procedure TMain.ButtonsBarClickMaximize(Sender: TObject);
begin
 If MultiWnd.ActiveChild <> Nil Then
  Begin
   MultiWnd.ActiveChild.Iconized:=False;

   If MultiWnd.ActiveChild.Maximized Then
    Begin
     MultiWnd.ActiveChild.RestoreSize;
     MultiWnd.ActiveChild.Left:=0;
     MultiWnd.ActiveChild.Top:=0;

     ButtonsBar.Visible:=False;
    End;
  End;
end;

procedure TMain.ButtonsBarClickClose(Sender: TObject);
 Var Ind : Word;
     BBVisible : Boolean;
begin
 If MultiWnd.ActiveChild <> Nil Then
  Begin
   MultiWnd.ActiveChild.Iconized:=False;
   MultiWnd.ActiveChild.Maximized:=False;

   MultiWnd.ActiveChild.Close;

   BBVisible:=False;

   If Length(MultiWnd.Childs) > 0 Then
    For Ind:=0 To MultiWnd.ChildCount - 1 Do
     If Assigned(MultiWnd.Childs[Ind]) Then
      If MultiWnd.Childs[Ind].Maximized Then
       BBVisible:=True;

   ButtonsBar.Visible:=BBVisible;
  End;
end;

procedure TMain.ButtonsBarClickMinimize(Sender: TObject);
begin
 If MultiWnd.ActiveChild <> Nil Then
  Begin
   MultiWnd.ActiveChild.RestoreSize;
   MultiWnd.ActiveChild.Left:=0;
   MultiWnd.ActiveChild.Top:=0;

   ButtonsBar.Visible:=False;

   MultiWnd.ActiveChild.TitleBar.OnClickMinimize(Sender);
  End;
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
 If MessageDlg('Do you want to close MyDbf Studio?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
  Application.Terminate
 Else
  CanClose:=False;
end;

procedure TMain.MenuItem15Click(Sender: TObject);
 Var Ind : Word;
begin
 If OpenTable.Execute Then
  Begin
   For Ind:=0 To OpenTable.Files.Count - 1 Do
    Open_Table(OpenTable.Files.Strings[Ind]);
  End;
end;

procedure TMain.MenuItem16Click(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    ExpCSV:=TExpCSV.Create(Self);
    ExpCSV.Tmp:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    ExpCSV.ShowModal;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;

    ExpCSV.Release;
   End;
end;

procedure TMain.MenuItem17Click(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    ExpHTML:=TExpHTML.Create(Self);
    ExpHTML.Tmp:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    ExpHTML.ShowModal;

    ExpHTML.Release;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;
   End;
end;

procedure TMain.MenuItem18Click(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    ExpXls:=TExpXls.Create(Self);
    ExpXls.Tmp:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    ExpXls.ShowModal;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;

    ExpXls.Release;
   End;
end;

procedure TMain.MenuItem19Click(Sender: TObject);
begin
  if MultiWnd.ActiveObject Is TDbfTable then
  with MultiWnd.ActiveObject As TDbfTable Do
  begin
    ExpDbf:=TExpDbf.Create(Self);
    ExpDbf.Tmp:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    ExpDbf.ShowModal;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;

    ExpDbf.Release;
  end;
end;

procedure TMain.MenuItem20Click(Sender: TObject);
begin
  MultiWnd.Cascade;
end;

procedure TMain.MenuItem21Click(Sender: TObject);
begin
  MultiWnd.TileVertical;
end;

procedure TMain.MenuItem22Click(Sender: TObject);
begin
 MultiWnd.TileHorizontal;
end;

procedure TMain.MenuItem24Click(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    ExpXml:=TExpXml.Create(Self);
    ExpXml.Tmp:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    ExpXml.ShowModal;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;

    ExpXml.Release;
   End;
end;

procedure TMain.MenuItem25Click(Sender: TObject);
 Var Ind : Word;
     Tmp : TDbf;
begin
 If OpenTable.Execute Then
  Begin
   Tmp:=TDbf.Create(Self);
   Tmp.Exclusive:=True;

   For Ind:=0 To OpenTable.Files.Count - 1 Do
    Begin
     Tmp.TableName:=OpenTable.Files.Strings[Ind];

     Try
       Tmp.Open;

       If MessageDlg('Delete all records in the table ' + Tmp.TableName,mtWarning,[mbYes, mbCancel],0) = mrYes Then
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

procedure TMain.MenuItem26Click(Sender: TObject);
begin
 OpenBA:=TOpenBA.Create(Self);

 OpenBA.ShowModal;

 OpenBA.Release;
end;

procedure TMain.MenuItem28Click(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    SortTable:=TSortTable.Create(Self);
    SortTable.Orig:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    SortTable.ShowModal;

    SortTable.Release;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;
   End;
end;

procedure TMain.MenuItem29Click(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    ExpSQL:=TExpSQL.Create(Self);
    ExpSQL.Tmp:=DBTable;

    Ds.Enabled:=False;
    Ds.DataSet:=Nil;

    ExpSQL.ShowModal;

    Ds.DataSet:=DBTable;
    Ds.Enabled:=True;

    ExpSQL.Release;
   End;
end;

procedure TMain.MenuItem3Click(Sender: TObject);
 Var IdxName : String;
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   If SaveAsTable.Execute Then
    Begin
     DBTable.Close;

     ChDir(DbTable.FilePathFull);

     If CopyFile(DbTable.FilePathFull + DBTable.TableName,SaveAsTable.FileName) Then
      Begin
       IdxName:=ExtractFileNameWithoutExt(DBTable.TableName) + '.mdx';

       If FileExists(IdxName) Then
        If Not CopyFile(DbTable.FilePathFull + IdxName,ExtractFileNameWithoutExt(SaveAsTable.FileName) + '.mdx',False) Then
         ShowMessage('Error while copy index!');
      End
     Else
      ShowMessage('Error while copy table!');

     DbTable.Open;
    End;
end;

procedure TMain.MenuItem5Click(Sender: TObject);
begin
 NewTable:=TNewTable.Create(Self);

 NewTable.ShowModal;

 If NewTable.Ret Then
  Open_Table(NewTable.SaveTable.FileName);

 NewTable.Release;
end;

procedure TMain.MenuItem6Click(Sender: TObject);
begin
 If MultiWnd.ActiveChild <> Nil Then
  MultiWnd.ActiveChild.Close;
end;

procedure TMain.MenuItem7Click(Sender: TObject);
 Var NumCh : Word;
begin
 If MultiWnd.ChildCount > 0 Then
  If MessageDlg('Close all tables?',mtWarning,[mbYes, mbCancel],0) = mrYes Then
   Begin
    NumCh:=MultiWnd.ChildCount - 1;

    While NumCh > 0 Do
     Begin
      Try
        MultiWnd.Childs[NumCh].Close;

        Dec(NumCh);
      Except
      End;
     End;

    If MultiWnd.ActiveChild <> Nil Then
     MultiWnd.ActiveChild.Close;

   ButtonsBar.Visible:=False;
  End;
end;

procedure TMain.MenuItem9Click(Sender: TObject);
begin
 Info:=TInfo.Create(Self);

 Info.ShowModal;

 Info.Release;
end;

procedure TMain.MultiDocMaximize(Sender: TObject);
begin
 ButtonsBar.Visible:=MultiWnd.Visible;
end;

procedure TMain.ChildMinimize(Sender: TObject);
 Var Ind : Word;
     TmpLeft,TmpTop : Integer;
begin
 If MultiWnd.ActiveChild <> Nil Then
  Begin
   If MultiWnd.ActiveChild.Iconized Then
    Exit;

   FormResize(Sender);              //Reset Iconized Window

   With MultiWnd.ActiveChild Do
    Begin
     Width:=200;
     Height:=30;
     TmpLeft:=0;
     TmpTop:=MultiWnd.Height - 34;

     For Ind:=0 To MultiWnd.ChildCount - 1 Do
      If Assigned(MultiWnd.Childs[Ind]) Then
       If MultiWnd.Childs[Ind].Iconized = True Then
        Begin
         TmpLeft:=TmpLeft + 200;

         If (TmpLeft + 200) > MultiWnd.Width Then
          Begin
           TmpLeft:=0;
           TmpTop:=TmpTop - 30;
          End;
        End;

     Iconized:=True;

     Left:=TmpLeft;
     Top:=TmpTop;
    End;
  End;
end;

procedure TMain.ChildMaximize(Sender: TObject);
begin
 If MultiWnd.ActiveChild <> Nil Then
  Begin
   MultiWnd.ActiveChild.Iconized:=False;
   MultiWnd.ActiveChild.Maximized:=True;
  End;
end;

procedure TMain.ChildClose(Sender: TObject; var CanClose: boolean);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   Begin
    If DBTable.Active Then
     DBTable.Close;

    StatusBar.SimpleText:='';
   End;
end;

procedure TMain.ChildEnter(Sender: TObject);
begin
 If MultiWnd.ActiveObject Is TDbfTable Then
  With MultiWnd.ActiveObject As TDbfTable Do
   StatusBar.SimpleText:=DBTable.FilePathFull + DBTable.TableName;
end;

procedure TMain.Set_Up();
begin
 IconList[0].FileName:='open.png';
 IconList[0].MaskR:=255;
 IconList[0].MaskG:=255;
 IconList[0].MaskB:=255;

 IconList[1].FileName:='new.png';
 IconList[1].MaskR:=0;
 IconList[1].MaskG:=0;
 IconList[1].MaskB:=0;

 IconList[2].FileName:='empty.png';
 IconList[2].MaskR:=0;
 IconList[2].MaskG:=0;
 IconList[2].MaskB:=0;

 IconList[3].FileName:='add.png';
 IconList[3].MaskR:=0;
 IconList[3].MaskG:=0;
 IconList[3].MaskB:=0;

 IconList[4].FileName:='sub.png';
 IconList[4].MaskR:=0;
 IconList[4].MaskG:=0;
 IconList[4].MaskB:=0;

 IconList[5].FileName:='opena.png';
 IconList[5].MaskR:=255;
 IconList[5].MaskG:=255;
 IconList[5].MaskB:=255;

 IconMenu[0].FileName:='open_s.png';
 IconMenu[0].MaskR:=0;
 IconMenu[0].MaskG:=0;
 IconMenu[0].MaskB:=0;

 IconMenu[1].FileName:='new_s.png';
 IconMenu[1].MaskR:=0;
 IconMenu[1].MaskG:=0;
 IconMenu[1].MaskB:=0;

 IconMenu[2].FileName:='setting_s.png';
 IconMenu[2].MaskR:=0;
 IconMenu[2].MaskG:=0;
 IconMenu[2].MaskB:=0;

 IconMenu[3].FileName:='exit_s.png';
 IconMenu[3].MaskR:=0;
 IconMenu[3].MaskG:=0;
 IconMenu[3].MaskB:=0;

 IconMenu[4].FileName:='add_s.png';
 IconMenu[4].MaskR:=0;
 IconMenu[4].MaskG:=0;
 IconMenu[4].MaskB:=0;

 IconMenu[5].FileName:='sub_s.png';
 IconMenu[5].MaskR:=0;
 IconMenu[5].MaskG:=0;
 IconMenu[5].MaskB:=0;

 IconMenu[6].FileName:='exp_s.png';
 IconMenu[6].MaskR:=0;
 IconMenu[6].MaskG:=0;
 IconMenu[6].MaskB:=0;

 IconMenu[7].FileName:='close_s.png';
 IconMenu[7].MaskR:=0;
 IconMenu[7].MaskG:=0;
 IconMenu[7].MaskB:=0;

 IconMenu[8].FileName:='empty_s.png';
 IconMenu[8].MaskR:=0;
 IconMenu[8].MaskG:=0;
 IconMenu[8].MaskB:=0;

 IconMenu[9].FileName:='opena_s.png';
 IconMenu[9].MaskR:=255;
 IconMenu[9].MaskG:=255;
 IconMenu[9].MaskB:=255;

 IconMenu[10].FileName:='sort_s.png';
 IconMenu[10].MaskR:=255;
 IconMenu[10].MaskG:=255;
 IconMenu[10].MaskB:=255;

 IconMenu[11].FileName:='saveas_s.png';
 IconMenu[11].MaskR:=255;
 IconMenu[11].MaskG:=255;
 IconMenu[11].MaskB:=255;

 IconMenu[12].FileName:='closeall_s.png';
 IconMenu[12].MaskR:=255;
 IconMenu[12].MaskG:=255;
 IconMenu[12].MaskB:=255;
end;

procedure TMain.ShowSplashScreen();
begin
 Splash:=TSplash.Create(Self);

 Splash.ShowModal;

 Splash.Release;
end;

procedure TMain.Load_Icons();
var
  Ind : Word;
  dir: String;
  pic: TPicture;
begin
  dir := Application.Location + 'img/';
  Set_Up();

  pic := TPicture.Create;
  try
    for Ind:=0 To 5 Do
      if FileExists(dir + IconList[Ind].FileName) Then
      begin
        pic.LoadFromFile(dir + IconList[ind].FileName);
        ImgList.InsertMasked(
          Ind,
          pic.Bitmap,
          RGBToColor(IconList[Ind].MaskR, IconList[Ind].MaskG, IconList[Ind].MaskB)
        );
       end;

    for Ind:=0 To 12 Do
      if FileExists(dir + IconMenu[Ind].FileName) Then
      begin
        pic.LoadFromFile(dir + IconMenu[Ind].FileName);
        ImgMenu.InsertMasked(
          Ind,
          pic.Bitmap,
          RGBToColor(IconMenu[Ind].MaskR, IconMenu[Ind].MaskG, IconMenu[Ind].MaskB)
        );
       end;

  finally
    pic.Free;
  end;
end;

procedure TMain.Open_Table(TblName: String);
var
  Tmp: TChildDoc;
  DbfTmp: TDbfTable;
begin
  Tmp := MultiWnd.NewChild;
  Tmp.TitleBar.OnClickMinimize := @ChildMinimize;
  Tmp.TitleBar.OnClickMaximize := @ChildMaximize;
  Tmp.OnCloseQuery := @ChildClose;
  Tmp.OnPaint := @ChildEnter;

  DbfTmp := TDbfTable.Create(Tmp);
  DbfTmp.DBTable.TableName := TblName;
  DbfTmp.DBTable.Open;
  DbfTmp.Set_Up();

  Tmp.DockedPanel := DbfTmp.WndPanel;
  Tmp.Caption := ExtractFileName(TblName);
  Tmp.TitleBar.Icon := nil;
  Tmp.RestoreSize;
  Tmp.TitleBar.ColorActive := clActiveCaption;  //RgbToColor(153,180,209);
  Tmp.TitleBar.ColorActiveGradient := clGradientActiveCaption; //RgbToColor(153,180,209);
  Tmp.TitleBar.ColorInactive := clInactiveCaption;  //RgbToColor(191,205,219);
  Tmp.TitleBar.ColorInactiveGradient := clGradientInactiveCaption;  //RgbToColor(191,205,219);

  Tmp.Width := (MultiWnd.Width - Tmp.Left) - 20;

  if WindowState <> wsMaximized then
   Tmp.Height := MultiWnd.Height - 21;
end;

procedure TMain.CreateAliasDB();
var
  T : TDbf;
begin
  Try
    T:=TDbf.Create(Self);
    T.TableName:='alias.dbf';
    T.FilePath:=Application.Location;

    T.FieldDefs.Add('ALIAS',ftString,80);
    T.FieldDefs.Add('PATH',ftString,255);

    T.CreateTable;
    T.Open;
    T.AddIndex('ALIAS','ALIAS',[ixPrimary]);

    T.Close;
    T.Free;

    ShowMessage('Alias DB not found! Created!');
  Except
    ShowMessage('Error while creating alias db.');
  End;
end;


end.

