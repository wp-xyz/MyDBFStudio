unit uSortTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, ComCtrls, DB;

type

  { TSortTable }

  TSortTable = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    DesTask: TLabel;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    OptSort: TRadioGroup;
    Orig: TDbf;
    OrigFields: TListBox;
    Pb1: TProgressBar;
    SortFields: TListBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Tmp: TDbf;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure OrigFieldsDblClick(Sender: TObject);
    procedure SortFieldsDblClick(Sender: TObject);
  private
    { private declarations }

    Function CreateTmpTable : Boolean;
    Function CreateSortIndex : Boolean;

    Procedure MoveRecord;
  public
    { public declarations }
  end;

var
  SortTable: TSortTable;

implementation

{$R *.lfm}

uses
  uOptions;

{ TSortTable }

procedure TSortTable.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    Options.SubtractTablesWindow.ExtractFromForm(Self);
    Orig.Open;
  end;
end;

procedure TSortTable.BitBtn1Click(Sender: TObject);
begin
 Close;
end;

procedure TSortTable.BitBtn2Click(Sender: TObject);
begin
 If MessageDlg('The sorting can be very slow for big table, continue?',mtWarning,[mbOk, mbCancel],0) <> mrOk Then
  Exit;

 If (SortFields.Items.Count - 1) > -1 Then
  Begin
   If CreateTmpTable Then
    Begin
     If CreateSortIndex Then
      Begin
       MoveRecord;

       Orig.Open;

       ShowMessage('Process completed!');
      End;
    End
   Else
    ShowMessage('Error while creating tmp table...');
  End
 Else
  ShowMessage('You must select at least one field to sort on.');
end;

procedure TSortTable.FormShow(Sender: TObject);
var
  Ind : Word;
begin
  OrigFields.Clear;

  for Ind := 0 To Orig.FieldDefs.Count - 1 do
    OrigFields.Items.Add(Orig.FieldDefs.Items[Ind].Name);

  Options.SortTableWindow.ApplyToForm(self);
end;

procedure TSortTable.OrigFieldsDblClick(Sender: TObject);
begin
 If OrigFields.ItemIndex > -1 Then
  Begin
   SortFields.Items.Add(OrigFields.Items[OrigFields.ItemIndex]);

   OrigFields.Items.Delete(OrigFields.ItemIndex);
  End;
end;

procedure TSortTable.SortFieldsDblClick(Sender: TObject);
begin
 If SortFields.ItemIndex > -1 Then
  Begin
   OrigFields.Items.Add(SortFields.Items[SortFields.ItemIndex]);

   SortFields.Items.Delete(SortFields.ItemIndex);
  End;
end;

function TSortTable.CreateTmpTable: Boolean;
begin
 Orig.Close;

 ChDir(Orig.FilePathFull);

 DesTask.Caption := 'Create tmp table...';

 Application.ProcessMessages;

 Result := CopyFile(Orig.FilePathFull + Orig.TableName, 'sorttmp.dbf');

 DesTask.Caption := 'Progress';
end;

function TSortTable.CreateSortIndex: Boolean;
 Var T : TDbf;
     Ind : Word;
     Exp : String;
     iOpt : TIndexOptions;
begin
 ChDir(Orig.FilePathFull);

 T := TDbf.Create(Self);
 T.FilePathFull := Orig.FilePathFull;
 T.TableName := 'sorttmp.dbf';
 T.TableLevel := Orig.TableLevel;
 T.Exclusive := True;

 Result := True;

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

   iOpt := [];

   If OptSort.ItemIndex > 0 Then
    iOpt := iOpt + [ixDescending];

   DesTask.Caption := 'Create sort index on tmp table...';

   Application.ProcessMessages;

   T.AddIndex('TMP',Exp,iOpt);

   DesTask.Caption := 'Progress';
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

procedure TSortTable.MoveRecord;
 Var T : TDbf;
     Ind : Word;
begin
 ChDir(Orig.FilePathFull);

 T := TDbf.Create(Self);
 T.FilePathFull := Orig.FilePathFull;
 T.TableName := 'sorttmp.dbf';
 T.TableLevel := Orig.TableLevel;
 T.IndexName := 'TMP';

 T.Open;

 Orig.Open;
 Orig.Zap;

 Pb1.Min := 1;
 Pb1.Max := T.ExactRecordCount;
 Pb1.Position := 0;

 DesTask.Caption := 'Move records...';

 Application.ProcessMessages;

 While Not T.EOF Do
  Begin
   Orig.Append;

   For Ind := 0 To T.FieldDefs.Count - 1 Do
    Orig.FieldByName(T.FieldDefs.Items[Ind].Name).AsVariant:=T.FieldByName(T.FieldDefs.Items[Ind].Name).AsVariant;

   Orig.Post;
   T.Next;

   Pb1.Position := Pb1.Position + 1;
  End;

 Pb1.Position := 0;

 Orig.Close;
 T.Close;

 DesTask.Caption := 'Progress';

 DeleteFile(T.FilePathFull + 'sorttmp.dbf');
 DeleteFile(T.FilePathFull + 'sorttmp.mdx');

 T.Free;
end;

end.

