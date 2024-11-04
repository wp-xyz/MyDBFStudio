unit DsHtml;

// Todo: Cell font is not applied

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DsDataExport, Graphics;

Type
    THTMLSource                   = TStrings;
    THTMLFontSize                 = (fsNormal, fs8, fs10, fs12, fs14, fs18, fs24, fs36);
    THTMLFontStyle                = (hfBold, hfItalic, hfUnderline, hfStrikeOut, hfBlink, hfSup,
                                     hfSub, hfDfn, hfStrong, hfEm, hfCite, hfVariable,
                                     hfKeyboard, hfCode);

    THTMLFontStyles               = Set Of THTMLFontStyle;

    { THTMLObject }

    THTMLObject                   = Class(TPersistent)
     Protected
      Function GetCode(AInside: String): String; Virtual; Abstract;
    End;

    { THTMLFont }

    THTMLFont                     = Class(THTMLObject)
     Private
      FColor                      : TColor;
      FName                       : TFontName;
      FSize                       : THTMLFontSize;
      FStyle                      : THTMLFontStyles;

     Protected
      Function GetCode(AInside: String): String; Override;
      Function GetStyle(AInside: String): String;

     Public
      Constructor Create();

     Published
      Property Color: TColor read FColor write FColor default clNone;
      Property Name: TFontName read FName write FName;
      Property Size: THTMLFontSize read FSize write FSize default fsNormal;
      Property Style: THTMLFontStyles read FStyle write FStyle default [];
    End;

    { THTMLBand }

    THTMLBand                     = Class(THTMLObject)
     Private
      FBackColor                  : TColor;
      FFont                       : THTMLFont;

     Protected
      Function GetCode(AInside: String): String; Override;
      Function ColorValue(): String;
      Function PropertyCode(): String; Virtual;

     Public
      Constructor Create();
      Destructor Destroy; override;

     Published
      Property Font : THTMLFont Read FFont Write FFont;
      Property BackColor : TColor Read FBackColor Write FBackColor Default clNone;
    End;

    { THTMLPage }

    THTMLPage                     = Class(THTMLBand)
     Private
      FTopMargin                  : Integer;
      FLeftMargin                 : Integer;
      FTitle                      : String;

     Protected
      Function GetCode : String; Reintroduce;

     Published
      Property Title : String Read FTitle write FTitle;
      Property TopMargin: Integer read FTopMargin write FTopMargin default 0;
      Property LeftMargin: Integer read FLeftMargin write FLeftMargin default 0;
    End;

    { THTMLTitle }

    THTMLTitle                    = Class(THTMLBand)
     Private
      TText                       : String;

     Protected
      Function GetCode: String; Reintroduce;

     Published
      Property Text: string read TText write TText;
    End;

    { THTMLHeader }

    THTMLHeader                   = Class(THTMLBand)
     Private
      FVisible                    : Boolean;

     Public
      Constructor Create();

     Published
      Property Visible: Boolean read FVisible write FVisible default True;
    End;

    { THTMLDetail }

    THTMLDetail                   = Class(THTMLBand)
     Private
      FHeaders                    : THTMLHeader;
      FBorderWidth                : Integer;
      FBorderColor                : TColor;
      FCellSpacing                : Integer;
      FCellPadding                : Integer;

     Protected
      Function PropertyCode: String; Override;

     Public
      Constructor Create();
      Destructor Destroy; Override;

     Published
      Property Headers: THTMLHeader read FHeaders write FHeaders;
      Property BorderWidth: Integer read FBorderWidth write FBorderWidth default 0;
      Property BorderColor: TColor  read FBorderColor write FBorderColor default clNone;
      Property CellSpacing: Integer read FCellSpacing write FCellSpacing default 2;
      Property CellPadding: Integer read FCellPadding write FCellPadding default 1;
    End;

    { THTMLField }

    THTMLField                    = Class(TDsExportField)
     Private
      FTitle                      : String;
      FAlignment                  : TAlignment;

     Public
      Procedure Assign(Source: TPersistent); override;
      Constructor Create(lCollection: TCollection); override;

     Published
      Property Title: string read FTitle write FTitle;
      Property Alignment: TAlignment read FAlignment write FAlignment default taLeftJustify;
    End;

    { THTMLFields }

    THTMLFields                   = Class(TDsExportFields)
     Private
      Function GetItem(Index: Integer): THTMLField;
      Procedure SetItem(Index: Integer; const Value: THTMLField);

     Public
      Function Add(): THTMLField;

      Property Items[Index: Integer]: THTMLField read GetItem write SetItem; default;
    End;

    { TDsDataToHTML }

    TDsDataToHTML                 = Class(TDsDataExport)
     Private
      FFields                     : THTMLFields;
      FPageOptions                : THTMLPage;
      FTitle                      : THTMLTitle;
      FDetail                     : THTMLDetail;

     Protected
      Procedure OpenFile; Override;
      Procedure CloseFile; Override;
      Procedure WriteRecord; Override;
      Procedure WriteHeaders();

     Public
      Function GetFields : TDsExportFields; override;
      Constructor Create (AOwner: TComponent); override;
      Destructor Destroy; override;

     Published
      Property DataSet;
      Property Fields: THTMLFields read FFields write FFields;
      Property PageOptions: THTMLPage read FPageOptions write FPageOptions;
      Property Title: THTMLTitle read FTitle write FTitle;
      Property Detail: THTMLDetail read FDetail write FDetail;
      Property OnBeginExport;
      Property OnEndExport;
      Property BeforeWriteRecord;
      Property AfterWriteRecord;
    End;

implementation

Uses Db, DbGrids;

Const
     HTML_FONTSTYLETAGS: Array[0..14] Of String = ('b', 'i', 'u', 'strike', 'blink',
                                                   'sup', 'sub', 'sub', 'dfn',
                                                   'strong', 'em', 'cite', 'var',
                                                   'kdb', 'code');

     HTML_FONTSIZEPOINT: Array[0..7] Of Integer = (0, 8, 10, 12, 14, 18, 24, 36);
     HTML_INDENT                     = '  ';



Function HTMLSimpleTag(AName, AInside: String): String;
Begin
 Result:='<'  + AName + '>' + AInside + '</' + AName + '>';
End;

Function HTMLTag(AName, APropertys, AInside: String): String;
Begin
 Result:='<'  + AName + ' ' + APropertys + '>' + AInside + '</' + AName + '>';
End;

Function HTMLProperty(APropName, APropValue: String): String;
Begin
 Result:=APropName + '="' + APropValue + '"';
End;

Function HTMLIntProperty(APropName: String; APropValue: Integer): String;
Begin
 Result:=HTMLProperty(APropName,IntToStr(APropValue));
End;

Function HTMLQuotedProperty(APropName, APropValue: String): String;
Begin
 Result:=APropName + ': ' + APropValue;
End;

Function ColorToHtml(AColor: TColor): String;
Begin
 Result:=Format('#%.2x%.2x%.2x',[Red(AColor),Green(AColor),Blue(AColor)]);
End;

{ THTMLFont }

function THTMLFont.GetCode(AInside: String): String;
 Var sProp : String;
begin
 sProp:='';
 Result:=GetStyle(AInside);

 If FSize <> fsNormal Then
  sProp:=sProp + ' ' + HTMLIntProperty('size',Integer(FSize));

 If FName <> '' Then
  sProp:=sProp + ' ' + HTMLProperty('face',FName);

 If FColor <> clNone Then
  sProp:=sProp + ' ' + HTMLProperty('color',ColorToHtml(FColor));

 If sProp <> '' Then
  Result:=HTMLTag('font',sProp,Result)
 Else
  Result:=Result;
end;

function THTMLFont.GetStyle(AInside: String): String;
 Var I : Integer;
begin
 Result:=AInside;

 For I:=0 To High(HTML_FONTSTYLETAGS) Do
  If THTMLFontStyle(I) In FStyle Then
   Result:=HTMLSimpleTag(HTML_FONTSTYLETAGS[I],Result);
end;

constructor THTMLFont.Create();
begin
 Inherited;

 FColor:=clNone;
 FName:='';
 FSize:=fsNormal;
 FStyle:=[];
end;

{ THTMLBand }

function THTMLBand.GetCode(AInside: String): String;
begin
  Result:=FFont.GetCode(AInside);

  if FBackColor <> clNone then
    Result:=HTMLTag('span',HTMLProperty('style',HTMLQuotedProperty('background-color',ColorValue())),Result);
end;

function THTMLBand.ColorValue(): String;
begin
  Result:=ColorToHtml(FBackColor);
end;

function THTMLBand.PropertyCode(): String;
begin
  if FBackColor <> clNone then
   Result := ' ' + HTMLProperty('bgcolor',ColorValue())
  else
   Result := '';
end;

constructor THTMLBand.Create();
begin
  inherited;

  FFont := THTMLFont.Create;
  FBackColor := clNone;
end;

destructor THTMLBand.Destroy;
begin
 FFont.Free;
 inherited Destroy;
end;

{ THTMLPage }

function THTMLPage.GetCode: String;
 Var sStyle : String;
begin
 Result:='';

 If FBackColor <> clNone Then
  Result:=Result + ' ' +  HTMLProperty('bgcolor',ColorValue());

 If FTopMargin <> 0 Then
  Result:=Result + ' ' + HTMLIntProperty('topmargin',FTopMargin);

 If FLeftMargin <> 0 Then
  Result:=Result + ' ' + HTMLIntProperty('leftmargin',FLeftMargin);

 If Font.Name <> '' Then
  sStyle:='font-family: ' + Font.Name;

 If Font.Size <> fsNormal Then
  sStyle:=sStyle + ' font-size: ' + IntToStr(HTML_FONTSIZEPOINT[Integer(Font.Size)]) + ' pt';

 If Font.Color <> clNone Then
  sStyle:=sStyle + ' color: ' + ColorToHtml(Font.Color);

 If sStyle <> '' Then
  Result:=Result + ' ' + HTMLProperty('style',sStyle);
end;

{ THTMLTitle }

function THTMLTitle.GetCode: String;
begin
 Result:=inherited GetCode(TText);
end;

{ THTMLHeader }

constructor THTMLHeader.Create();
begin
 Inherited;
 FVisible := true;
end;

{ THTMLDetail }

function THTMLDetail.PropertyCode: String;
begin
  Result := inherited PropertyCode;

  if FBorderWidth <> 0 then
    Result := Result + ' ' + HTMLIntProperty('border',FBorderWidth);

  if FBorderColor <> clNone Then
    Result := Result + ' ' + HTMLProperty('bordercolor',ColorToHtml(FBorderColor));

  if FCellSpacing <> 2 then
    Result := Result + ' ' + HTMLIntProperty('cellspacing',FCellSpacing);

  if FCellPadding <> 1 then
    Result := Result + ' ' + HTMLIntProperty('cellpadding',FCellPadding);
end;

constructor THTMLDetail.Create();
begin
 Inherited;

 FHeaders:=THTMLHeader.Create;
 FBorderWidth:=0;
 FBorderColor:=clNone;
 FCellSpacing:=2;
 FCellPadding:=1;
end;

destructor THTMLDetail.Destroy;
begin
 FHeaders.Free;

 Inherited Destroy;
end;

{ THTMLField }

procedure THTMLField.Assign(Source: TPersistent);
begin
 Inherited Assign(Source);

 If Source Is THTMLField Then
  With Source As THTMLField Do
   Begin
    FTitle:=Title;
    FAlignment:=Alignment;
   End
 Else
  If Source Is TField Then
   With Source As TField Do
    Begin
     FTitle:=DisplayLabel ;
     FAlignment:=Alignment;
    End
  Else
   If Source Is TColumn Then
    With Source As TColumn Do
     Begin
      FTitle:=Title.Caption;
      FAlignment:=Alignment;
     End;
end;

constructor THTMLField.Create(lCollection: TCollection);
begin
 Inherited Create(lCollection);

 FAlignment:=taLeftJustify;
end;

{ THTMLFields }

function THTMLFields.GetItem(Index: Integer): THTMLField;
begin
 Result:=THTMLField(Inherited GetItem(Index));
end;

procedure THTMLFields.SetItem(Index: Integer; const Value: THTMLField);
begin
 Inherited SetItem(Index,Value);
end;

function THTMLFields.Add(): THTMLField;
begin
 Result:=THTMLField(Inherited Add());
end;

{ TDsDataToHTML }

procedure TDsDataToHTML.OpenFile;
begin
 Inherited OpenFile;

 WriteString('<html>'#13#10'<head>'#13#10'<title>' + FPageOptions.Title + '</title>'#13#10'</head>'#13#10,0);
 WriteString('<body' + FPageOptions.GetCode + '>'#13#10,0);
 WriteString('<!-- Created by MyDbf Studio -->'#13#10,0);

 If FTitle.Text <> '' Then
  WriteLine(FTitle.GetCode);

 WriteString('<table' + FDetail.PropertyCode + '>'#13#10,0);

 WriteHeaders();
end;

procedure TDsDataToHTML.CloseFile;
begin
 WriteString('</table>'#13#10'</body>'#13#10'</html>',0);

 Inherited CloseFile;
end;

procedure TDsDataToHTML.WriteRecord;
 Var iField : Integer;
begin
 WriteLine(HTML_INDENT + '<tr>');

 For iField:=0 To FFields.Count - 1 Do
  If FFields[iField].Save Then
   WriteLine(HTML_INDENT + HTML_INDENT + '<td>' + FFields[iField].Field.AsString + '</td>');

 WriteLine(HTML_INDENT + '</tr>');
end;

procedure TDsDataToHTML.WriteHeaders();
 Var iField: Integer;
begin
 WriteLine(HTML_INDENT + '<tr>');

 For iField:=0 To FFields.Count - 1 Do
  If FFields[iField].Save Then
   WriteLine(HTML_INDENT + HTML_INDENT +  '<td' + FDetail.Headers.PropertyCode + '>' + FDetail.Headers.Font.GetCode(FFields[iField].Title) + '</td>');

 WriteLine(HTML_INDENT + '</tr>');
end;

function TDsDataToHTML.GetFields: TDsExportFields;
begin
 Result:=FFields;
end;

constructor TDsDataToHTML.Create(AOwner: TComponent);
begin
 Inherited Create(AOwner);

 FFields:=THTMLFields.Create(Self, THTMLField);
 FPageOptions:=THTMLPage.Create;
 FTitle:=THTMLTitle.Create;
 FDetail:=THTMLDetail.Create;
end;

destructor TDsDataToHTML.Destroy;
begin
 FDetail.Free;
 FTitle.Free;
 FPageOptions.Free;
 FFields.Free;

 Inherited Destroy;
end;

end.

