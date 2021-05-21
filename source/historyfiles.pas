unit HistoryFiles;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Menus, Graphics, LazFileUtils, Dialogs;

Const
  MsgPosOutOfRange             = 'Position out of range';
  MsgParentMenuNotAssigned     = 'ParentMenu not assigned';
  MsgIndexOutOfRange           = 'Index out of range';

Type

  TSeparatorStyle              = (sepNone, sepTop, sepBottom, sepBoth);

  THistoryItemClick            = Procedure(Sender : TObject; Item : TMenuItem; Const FileName : String) Of Object;
  THistoryCreateItem           = Procedure(Sender : TObject; Item : TMenuItem; Const FileName : String) Of Object;

  Items                        = 1..255;

  { THistoryFiles }

  THistoryFiles                = Class(TComponent)
    Private
      FItems                   : TStringList;
      FOnHistoryItemClick      : THistoryItemClick;
      FOnHistoryCreateItem     : THistoryCreateItem;
      FMaxItems                : Items;
      FIniKey,
      FLocalPath,
      FIniFile                 : String;
      FParentMenu              : TMenuItem;
      FSeparator               : TSeparatorStyle;
      FShowFullPath            : Boolean;
      FPosition,
      FLastItemIndex,
      FNumberOfItems,
      FCount                   : Integer;
      FFileMustExist           : Boolean;
      FOriginalMainMenuItems   : Integer;
      FSorted                  : Boolean;
      FShowNumber              : Boolean;
      FItemBitmap              : TBitmap;
      FItemSelectedBitmap      : TBitmap;
      FCheckLastItem           : Boolean;

      Procedure ClearMenu(MainMenu : TMenuItem);
      Procedure OnMainMenuClickHistoryItem(Sender : TObject);
      Procedure SetParentMenu(Const Value : TMenuItem);
      Procedure SetPosition(Const Value : Integer);
      Procedure ReadIniSection(Var List : TStringList; LocalIniFile : TIniFile; Var bChanged : Boolean);
      Procedure WriteIniSection(Const List : TStringList; LocalIniFile : TIniFile);
      Procedure InternalUpdateParentMenu(Const CurrentList : TStringList);
      Procedure ChangeSort(Const Sorted : Boolean);
      Function GetLastItemIndex : Integer;
      Procedure SetLastItemIndex(Const Index : Integer);
      Procedure LastItemIndex_WriteIni;
      Procedure SetItemBitmap(Const B : TBitmap);
      Procedure SetItemSelectedBitmap(Const B : TBitmap);

    Public
      Constructor Create(AOwner : TComponent); Override;
      Destructor Destroy; Override;
      Procedure UpdateList(TheFile : String);
      Procedure UpdateParentMenu;
      Function GetItemValue(Const Index : Integer) : String;
      Procedure DeleteItem(Const Index : Integer);

      Property Count : Integer Read FCount;
      Property LastItemIndex : Integer Read GetLastItemIndex Write SetLastItemIndex Default 0;

      Procedure ClearLastItem;

    Published
      Property MaxItems : Items Read FMaxItems Write FMaxItems Default 5;
      Property IniKey : String Read FIniKey Write FIniKey;
      Property LocalPath : String Read FLocalPath Write FLocalPath;
      Property ShowFullPath : Boolean Read FShowFullPath Write FShowFullPath Default True;
      Property IniFile : String Read FIniFile Write FIniFile;
      Property ParentMenu : TMenuItem Read FParentMenu Write SetParentMenu;
      Property Separator : TSeparatorStyle Read FSeparator Write FSeparator Default SepNone;
      Property Position : Integer Read FPosition Write SetPosition Default 0;
      Property FileMustExist : Boolean Read FFileMustExist Write FFileMustExist Default False;
      Property Sorted : Boolean Read FSorted Write ChangeSort Default False;
      Property ShowNumber : Boolean Read FShowNumber Write FShowNumber Default True;
      Property OnClickHistoryItem : THistoryItemClick Read FOnHistoryItemClick Write FOnHistoryItemClick;
      Property OnCreateItem : THistoryCreateItem Read FOnHistoryCreateItem Write FOnHistoryCreateItem;
      Property ItemBitmap : TBitmap Read FItemBitmap Write SetItemBitmap;
      Property ItemSelectedBitmap : TBitmap Read FItemSelectedBitmap Write SetItemSelectedBitmap;
      Property CheckLastItem : Boolean Read FCheckLastItem Write FCheckLastItem Default False;
  end;

implementation

{ THistoryFiles }

procedure THistoryFiles.ClearMenu(MainMenu: TMenuItem);
 Var I : Integer;
begin
 For I := 1 To FNumberOfItems Do
  MainMenu.Items[FPosition].Destroy;

 FNumberOfItems := 0;
 FCount := 0;
 FItems.Clear;
end;

procedure THistoryFiles.OnMainMenuClickHistoryItem(Sender: TObject);
 Var TheFile : String;
begin
 TheFile := '';

 If Assigned(FOnHistoryItemClick) Then
  Begin
   TheFile := FItems.Strings[TMenuItem(Sender).Tag - 1];

   If TheFile <> '' Then
    FLastItemIndex := TMenuItem(Sender).Tag;

   LastItemIndex_WriteIni;

   FOnHistoryItemClick(Self, TMenuItem(Sender), TheFile);

   UpdateParentMenu;
  end;
end;

procedure THistoryFiles.SetParentMenu(const Value: TMenuItem);
begin
 If Assigned(FParentMenu) Then
  ClearMenu(FParentMenu);

 FParentMenu := Value;

 If Assigned(FParentMenu) Then
  Begin
   FOriginalMainMenuItems := FParentMenu.Count;

   If (csDesigning In ComponentState) And Not(csLoading In ComponentState) Then
    Begin
     If (FPosition > FParentMenu.Count) Or (FPosition = 0) Then
      FPosition := FParentMenu.Count;
    end
   Else
   If FPosition > FParentMenu.Count Then
    FPosition := FParentMenu.Count;
  end;
end;

procedure THistoryFiles.SetPosition(const Value: Integer);
begin
 If Assigned(FParentMenu) Then
  Begin
   If Value > FParentMenu.Count Then
    MessageDlg(MsgPosOutOfRange, mtError, [mbOk], 0)
   Else
    FPosition := Value;
  end
 Else
  FPOsition := Value;
end;

procedure THistoryFiles.ReadIniSection(var List: TStringList;
  LocalIniFile: TIniFile; var bChanged: Boolean);
 Var B, sLastFile : String;
     N : Integer;
begin
 bChanged := False;
 N := 1;
 B := LocalIniFile.ReadString(FIniKey, IntToStr(N), 'empty');

 FLastItemIndex := LocalIniFile.ReadInteger(FIniKey, 'LastItemIndex', 0);
 sLastFile := LocalIniFile.ReadString(FIniKey, IntToStr(FLastItemIndex), '');

 While B <> 'empty' Do
  Begin
   If List.IndexOf(B) < 0 Then
    Begin
     If Not (FFileMustExist And Not FileExistsUTF8(B)) Then
      List.Add(B)
     Else
      bChanged := True;
    end;

   Inc(N);

   B := LocalIniFile.ReadString(FIniKey, IntToStr(N), 'empty');
  end;

 FLastItemIndex := List.IndexOf(sLastFile) + 1;
end;

procedure THistoryFiles.WriteIniSection(const List: TStringList;
  LocalIniFile: TIniFile);
 Var N : Integer;
     iListCount : Integer;
begin
 If Not FSorted And (List.Count > FMaxItems) Then
  iListCount := FMaxItems
 Else
  iListCount := List.Count;

 If FLastItemIndex > iListCount Then
  FLastItemIndex := 0;

 LocalIniFile.EraseSection(FIniKey);

 For N := 0 To iListCount - 1 Do
  LocalIniFile.WriteString(FIniKey, IntToStr(N + 1), List.Strings[N]);

 LocalIniFile.WriteInteger(FIniKey, 'LastItemIndex', FLastItemIndex);
end;

procedure THistoryFiles.InternalUpdateParentMenu(const CurrentList: TStringList
  );
 Var LocalIniFile : TIniFile;
     NewItem : TMenuItem;
     A, S : String;
     N, iListCount : Integer;
     bSepTop, bChanged : Boolean;
     List : TStringList;
begin
 If Assigned(FParentMenu) Then
  Begin
   bSepTop := False;
   bChanged := False;

   List := TStringList.Create;

   Try
     List.Clear;

     ClearMenu(FParentMenu);

     If CurrentList.Count = 0 Then
      Begin
       LocalIniFile := TIniFile.Create(FIniFile);

       Try
         ReadIniSection(List, LocalIniFile, bChanged);

         If bChanged Then
          WriteIniSection(List, LocalIniFile);
       finally
         LocalIniFile.Free;
       end;
      end
     Else
      Begin
       For N := 0 To CurrentList.Count - 1 Do
        List.Add(CurrentList.Strings[N]);
      end;

     If Not FSorted And (List.Count > FMaxItems) Then
      iListCount := FMaxItems
     Else
      iListCount := List.Count;

     If FLastItemIndex > iListCount Then
      FLastItemIndex := 0;

     For N := 0 To iListCount - 1 Do
      Begin
       A := List.Strings[N];

       If A <> 'empty' Then
        Begin
         If (FSeparator In [sepTop,sepBoth]) And Not bSepTop Then
          Begin
           bSepTop := True;

           NewItem := TMenuItem.Create(FParentMenu);
           NewItem.Caption := '-';
           FParentMenu.insert(FPosition + FNumberOfItems, NewItem);

           Inc(FNumberOfItems);
          end;

         NewItem := TMenuItem.Create(FParentMenu);

         If FShowFullPath Then
          Begin
           If UpperCase(ExtractFilePath(A)) = UpperCase(FLocalPath) Then
            S := ExtractFileName(A)
           Else
            S := A;
          end
         Else
          S := ExtractFileName(A);

         If FShowNumber Then
          NewItem.Caption := '&'+ inttostr(n+1) + ' ' + S
         Else
          NewItem.Caption := S;

         If FCheckLastItem And (N = FLastItemIndex - 1) Then
          Begin
           If Not FItemSelectedBitmap.Empty Then
            NewItem.Bitmap := FItemSelectedBitmap
           Else
            NewItem.Checked := True;
          end
         Else
          Begin
           If Not FItemBitmap.Empty Then
            NewItem.Bitmap := FItemBitmap;
          end;

         NewItem.onclick :=  @OnMainMenuClickHistoryItem;

         NewItem.Tag := N + 1;

         FItems.Add(A);

         FParentMenu.Insert(FPosition + FNumberOfItems, NewItem);

         If Assigned(FOnHistoryCreateItem) Then
          FOnHistoryCreateItem(Self, NewItem, A);

         Inc(FNumberOfItems);
         Inc(FCount);
        end;
      end;

     If (FSeparator In [sepBottom,sepBoth]) And (FNumberOfItems > 0) Then
      Begin
       NewItem := TMenuItem.Create(FParentMenu);
       NewItem.Caption := '-';
       FParentMenu.insert(FPosition + FNumberOfItems, NewItem);

       Inc(FNumberOfItems);
      end;
   finally
     List.Free;
   end;
  end
 Else
  MessageDlg(MsgParentMenuNotAssigned, mtError, [mbOk], 0);
end;

procedure THistoryFiles.ChangeSort(const Sorted: Boolean);
 Var List : TStringList;
     LocalIniFile : TIniFile;
     bChanged : Boolean;
     sLastFile : String;
begin
 If (csDesigning In ComponentState) And Not(csLoading In ComponentState) Then
  FSorted := Sorted
 Else
  Begin
   bChanged := False;

   If FSorted <> Sorted Then
    Begin
     FSorted := Sorted;

     If FSorted Then
      Begin
       List := TStringList.Create;

       Try
         LocalIniFile := TIniFile.create(FIniFile);

         Try
           List.Clear;

           ReadIniSection(List, LocalIniFile, bChanged);

           If FLastItemIndex > 0 Then
            sLastFile := List.Strings[FLastItemIndex-1]
           Else
            sLastFile := '';

           List.Sort;

           FLastItemIndex := List.IndexOf(sLastFile) + 1;

           WriteIniSection(List, LocalIniFile);

           InternalUpdateParentMenu(List);
         finally
           LocalIniFile.Free;
         end;
       finally
         List.Free;
       end;
      end
     Else
      UpdateParentMenu;
    end;
  end;
end;

function THistoryFiles.GetLastItemIndex: Integer;
begin
 Result := FLastItemIndex - 1;
end;

procedure THistoryFiles.SetLastItemIndex(const Index: Integer);
begin
 FLastItemIndex := Index + 1;

 LastItemIndex_WriteIni;
end;

procedure THistoryFiles.LastItemIndex_WriteIni;
 Var LocalIniFile : TIniFile;
begin
 LocalIniFile := TIniFile.Create(FIniFile);

 Try
   LocalIniFile.WriteInteger(FIniKey, 'LastItemIndex', FLastItemIndex);
 finally
   LocalIniFile.Free;
 end;
end;

procedure THistoryFiles.SetItemBitmap(const B: TBitmap);
begin
 If Not B.Empty Then
  FItemBitmap.Assign(B);
end;

procedure THistoryFiles.SetItemSelectedBitmap(const B: TBitmap);
begin
 If Not B.Empty Then
  FItemSelectedBitmap.Assign(B);
end;

constructor THistoryFiles.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);

 FIniKey:='History Files';
 FMaxItems:=5;
 FLocalPath:='';
 FIniFile:='History.ini';
 FParentMenu:=Nil;
 FSeparator:=sepNone;
 FOriginalMainMenuItems:=0;
 FItems := TStringList.Create;
 FShowFullPath:=True;
 FPosition:=0;
 FLastItemIndex :=0;
 FNumberOfItems:=0;
 FCount:=0;
 FOnHistoryItemClick:=Nil;
 FOnHistoryCreateItem:=Nil;
 FFileMustExist:=False;
 FSorted:=False;
 FShowNumber:=True;
 FItemBitmap := TBitmap.Create;
 FItemSelectedBitmap := TBitmap.Create;
 FCheckLastItem := False;
end;

destructor THistoryFiles.Destroy;
begin
 inherited Destroy;

 FItems.Free;
 FItemBitmap.Free;
 FItemSelectedBitmap.Free;
end;

procedure THistoryFiles.UpdateList(TheFile: String);
 Var A : String;
     bChanged : Boolean;
     LocalIniFile : TIniFile;
     List : TStringList;
begin
 List := TStringList.Create;

 Try
   bChanged := False;

   LocalIniFile := TIniFile.Create(FIniFile);

   Try
     List.Clear;

     A := TheFile;

     If ExtractFilePath(A) = '' Then
      A := FLocalPath + A;

     List.Add(A);

     ReadIniSection(List, LocalIniFile, bChanged);

     FLastItemIndex := 1;

     If FSorted Then
      Begin
       List.Sort;

       FLastItemIndex := List.IndexOf(A) + 1;
      end;

     WriteIniSection(List, LocalIniFile);

     InternalUpdateParentMenu(List);
   finally
     LocalIniFile.Free;
   end;
 finally
   List.Free;
 end;
end;

procedure THistoryFiles.UpdateParentMenu;
 Var List : TStringList;
begin
 List := TStringList.Create;

 Try
   InternalUpdateParentMenu(List);
 finally
   List.Free;
 end;
end;

function THistoryFiles.GetItemValue(const Index: Integer): String;
begin
 If (Index < 0) Or (Index > FItems.Count - 1) Then
  Begin
   MessageDlg(MsgIndexOutOfRange, mtError, [mbOk], 0);

   Result := '';
  end
 Else
  Result := FItems.Strings[Index];
end;

procedure THistoryFiles.DeleteItem(const Index: Integer);
 Var List : TStringList;
     bChanged : Boolean;
     LocalIniFile : TIniFile;
     sLastFile : String;
begin
 bChanged := False;

 If Index < 0 Then
  MessageDlg(MsgIndexOutOfRange, mtError, [mbOk], 0)
 Else
  Begin
   LocalIniFile := TIniFile.Create(FIniFile);

   Try
     List := TStringList.Create;

     Try
       ReadIniSection(List, LocalIniFile, bChanged);

       If Index > List.Count - 1 Then
        MessageDlg(MsgIndexOutOfRange, mtError, [mbOk], 0)
       Else
        Begin
         If FLastItemIndex > 0 Then
          sLastFile := List.Strings[FLastItemIndex - 1]
         Else
          sLastFile := '';

         List.Delete(Index);

         FLastItemIndex := List.IndexOf(sLastFile) + 1;

         WriteIniSection(List, LocalIniFile);

         InternalUpdateParentMenu(List);
        end;
     finally
       List.Free;
     end;
   finally
     LocalIniFile.Free;
   end;
  end;
end;

procedure THistoryFiles.ClearLastItem;
begin
 FLastItemIndex := 0;
end;

end.

