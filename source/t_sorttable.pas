unit T_SortTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, Db;

type

  { TSortTable }

  TSortTable = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    InfoDesc: TLabel;
    Tmp: TDbf;
    Orig: TDbf;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    DesTask: TLabel;
    OrigFields: TListBox;
    SortFields: TListBox;
    Pb1: TProgressBar;
    OptSort: TRadioGroup;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { private declarations }

    Function CreateTmpTable() : Boolean;

    Function CreateSortIndex() : Boolean;

    Procedure MoveRecord();
  public
    { public declarations }
  end; 

var
  SortTable: TSortTable;

implementation

{$R *.lfm}

{ TSortTable }

procedure TSortTable.FormShow(Sender: TObject);
 Var Ind : Word;
begin
 OrigFields.Clear;

 For Ind:=0 To Orig.FieldDefs.Count - 1 Do
  OrigFields.Items.Add(Orig.FieldDefs.Items[Ind].Name);
end;

procedure TSortTable.BitBtn2Click(Sender: TObject);
begin
 If MessageDlg('The sorting can be very slow for big table, continue?',mtWarning,[mbYes, mbCancel],0) <> mrYes Then
  Exit;

 If (SortFields.Items.Count - 1) > -1 Then
  Begin
   If CreateTmpTable() Then
    Begin
     If CreateSortIndex() Then
      Begin
       MoveRecord();

       Orig.Open;

       Close;
      End;
    End
   Else
    ShowMessage('Error while creating tmp table...');
  End
 Else
  ShowMessage('You must select at least one field to sort on.');
end;

procedure TSortTable.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 Orig.Open;
end;

procedure TSortTable.SpeedButton1Click(Sender: TObject);
begin
 If SortFields.ItemIndex > -1 Then
  Begin
   OrigFields.Items.Add(SortFields.Items[SortFields.ItemIndex]);

   SortFields.Items.Delete(SortFields.ItemIndex);
  End;
end;

procedure TSortTable.SpeedButton2Click(Sender: TObject);
begin
 If OrigFields.ItemIndex > -1 Then
  Begin
   SortFields.Items.Add(OrigFields.Items[OrigFields.ItemIndex]);

   OrigFields.Items.Delete(OrigFields.ItemIndex);
  End;
end;

function TSortTable.CreateTmpTable(): Boolean;
begin
 Orig.Close;

 ChDir(Orig.FilePathFull);

 InfoDesc.Caption:='Create tmp table...';

 Application.ProcessMessages;

 Result:=CopyFile(Orig.FilePathFull + Orig.TableName,'sorttmp.dbf');
end;

function TSortTable.CreateSortIndex(): Boolean;
 Var T : TDbf;
     Ind : Word;
     Exp : String;
     iOpt : TIndexOptions;
begin
 ChDir(Orig.FilePathFull);

 T:=TDbf.Create(Self);
 T.FilePathFull:=Orig.FilePathFull;
 T.TableName:='sorttmp.dbf';
 T.TableLevel:=Orig.TableLevel;
 T.Exclusive:=True;

 Result:=True;

 Try
   T.Open;
   Exp:='';

   For Ind:=0 To SortFields.Items.Count - 1 Do
    Begin
     Case T.FieldDefs.Find(SortFields.Items[Ind]).DataType Of
      ftString,
      ftFixedChar,
      ftWideString,
      ftFixedWideChar                            : If Exp = '' Then
                                                    Exp:=SortFields.Items[Ind]
                                                   Else
                                                    Exp:=Exp + ' + ' + SortFields.Items[Ind];

      ftSmallint,
      ftInteger,
      ftWord,
      ftLargeint,
      ftFloat,
      ftBytes,
      ftCurrency,
      ftAutoInc                                  : If Exp = '' Then
                                                    Exp:='STR(' + SortFields.Items[Ind] + ')'
                                                   Else
                                                    Exp:=Exp + ' + STR(' + SortFields.Items[Ind] + ')';

      ftDate,
      ftTime,
      ftDateTime,
      ftTimeStamp                                : If Exp = '' Then
                                                    Exp:='DTOS(' + SortFields.Items[Ind] + ')'
                                                   Else
                                                    Exp:=Exp + ' + DTOS(' + SortFields.Items[Ind] + ')';
     End;
    End;

   iOpt:=[];

   If OptSort.ItemIndex > 0 Then
    iOpt:=iOpt + [ixDescending];

   InfoDesc.Caption:='Create sort index on tmp table...';

   Application.ProcessMessages;

   T.AddIndex('TMP',Exp,iOpt);
 Except
   On E:Exception Do
    Begin
     Result:=False;

     ShowMessage(E.Message);
    End;
 End;

 T.Close;
 T.Free;
end;

procedure TSortTable.MoveRecord();
 Var T : TDbf;
     Ind : Word;
begin
 ChDir(Orig.FilePathFull);

 T:=TDbf.Create(Self);
 T.FilePathFull:=Orig.FilePathFull;
 T.TableName:='sorttmp.dbf';
 T.TableLevel:=Orig.TableLevel;
 T.IndexName:='TMP';

 T.Open;

 Orig.Open;
 Orig.Zap;

 Pb1.Min:=1;
 Pb1.Max:=T.ExactRecordCount;
 Pb1.Position:=0;

 InfoDesc.Caption:='Move records...';

 Application.ProcessMessages;

 While Not T.EOF Do
  Begin
   Orig.Append;

   For Ind:=0 To T.FieldDefs.Count - 1 Do
    Orig.FieldByName(T.FieldDefs.Items[Ind].Name).AsVariant:=T.FieldByName(T.FieldDefs.Items[Ind].Name).AsVariant;

   Orig.Post;
   T.Next;

   Pb1.Position:=Pb1.Position + 1;
  End;

 Pb1.Position:=0;

 Orig.Close;
 T.Close;

 DeleteFile(T.FilePathFull + 'sorttmp.dbf');
 DeleteFile(T.FilePathFull + 'sorttmp.mdx');

 T.Free;
end;


end.

