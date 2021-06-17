unit uUtils;

{$mode ObjFPC} {$H+}

interface

uses
  Classes, SysUtils, LCLVersion,
  DB, DBGrids;

{$IF LCL_FullVersion < 2010000}
type
  TDBGridColumnsHelper = class helper for TDBGridColumns
    function COlumnByFieldName(const aFieldName: String): TColumn;
  end;
{$IFEND}

const
  SupportedFieldTypes: set of TFieldType = [
    ftString, ftSmallInt, ftInteger, ftWord, ftBoolean, ftFloat,
    ftDate, ftDateTime, ftDBaseOLE, ftFixedChar, ftWideString, ftLargeInt,
    //ftBLOB,  // Seems to be equivalent to ftMemo. Causes confusion when both are available.
    ftMemo,
    ftGraphic, // ftGraphic not supported according to wiki, but works. Displayed in grid as (BLOB).
    ftCurrency, ftBCD, ftBytes,  // TableLevel 25 only
    ftAutoInc  // TableLevel 7 and 30 only
    ];

function FieldTypeAsString(AFieldType: TFieldType; Nice: Boolean): String;
procedure FieldTypePickList(ATableLevel: Integer; const AList: TStrings);
function GetAliasDir: String;
function GetVersionStr: String;
function IndexOfTableLevel(ATabelLevelStr: String; AList: TStrings): Integer;
function MaxValueI(const AData: array of Integer): Integer;
function TableFormat(ATableLevel: Integer): String;
//function TryScanDateTime(AMask, ADateStr: String; out ADate: TDateTime;
//  const AFmtSettings: TFormatSettings): Boolean;
function TryScanDateTime(const Pattern: String; const s: String; out ADate: TDateTime;
  const fmt: TFormatSettings): Boolean;

implementation

uses
  TypInfo, DateUtils, FileInfo;

{$IF LCL_FullVersion < 2010000}
{ Fixes a compilation problem in the DBGrid of Lazarus before v2.2 }
function TDBGridColumnsHelper.ColumnByFieldname(const aFieldname: string): TColumn;
var
  i: Integer;
begin
  result := nil;
  for i:=0 to Count-1 do
    if CompareText(Items[i].FieldName, aFieldName)=0 then begin
      result := Items[i];
      break;
    end;
end;
{$IFEND}

{ Populates a list with the field types supported by a specific table level. }
procedure FieldTypePickList(ATableLevel: Integer; const AList: TStrings);
var
  ft: TFieldType;
begin
  AList.Clear;
  for ft in SupportedFieldTypes - [ftCurrency, ftBCD, ftBytes, ftAutoInc] do
    AList.Add(FieldTypeNames[ft]);

  // These are supported by Visual dBase
  if ATableLevel in [7] then
  begin
    AList.Add(FieldTypeNames[ftCurrency]);
    AList.Add(FieldTypeNames[ftBCD]);
    AList.Add(FieldTypeNames[ftBytes]);
  end;

  // ftAutoInc is supported by Visual dBase, FoxPro and Visual FoxPro
  if ATableLevel in [7, 25, 30] then
    AList.Add(FieldTypeNames[ftAutoInc]);
end;

{ Converts a enumerated TFieldType value to a string. When Nice=true, the leading
  'ft' is stripped. }
function FieldTypeAsString(AFieldType: TFieldType; Nice: Boolean): String;
begin
  Result := GetEnumName(TypeInfo(TFieldType), integer(AFieldType));
  if Nice then Delete(Result, 1, 2);
end;

{ Returns the directory in which the default "alias.dbf" file is stored. }
function GetAliasDir: String;
begin
  Result := GetAppConfigDir(false);
end;

{ Returns the version of the application. }
function GetVersionStr: String;
var
  ver: TProgramVersion;
begin
  ver := Default(TProgramVersion);
  GetProgramVersion(ver);
  Result := Format('v%d.%d.%d', [ver.Major, ver.Minor, ver.Revision]);
end;

{ Reimplements the MaxValue() function from Math to fix a 64-bit compilation
  problem. }
function MaxValueI(const AData: Array of Integer): Integer;
var
  value: Integer;
begin
  Result := -MaxInt;
  for value in AData do
    if value > Result then Result := value;
end;

function IndexOfTableLevel(ATabelLevelStr: String; AList: TStrings): Integer;
var
  i: Integer;
begin
  for i := 0 to AList.Count-1 do
    if ATabelLevelStr = AList[i] then
    begin
      Result := i;
      exit;
  end;
  Result := -1;
end;

{ Returns the database type of a given table level }
function TableFormat(ATableLevel: Integer): String;
begin
  case ATableLevel of
    3: Result := 'dBase III+';
    4: Result := 'dBase IV';
    7: Result := 'Visual dBase VII';
    25: Result := 'FoxPro';
    30: Result := 'Visual FoxPro';
    else Result := '(unsupported)';
  end;
end;

const whitespace  = [' ',#13,#10];
      hrfactor    = 1/(24);
      minfactor   = 1/(24*60);
      secfactor   = 1/(24*60*60);
      mssecfactor = 1/(24*60*60*1000);

const AMPMformatting : array[0..2] of string =('am/pm','a/p','ampm');

// Duplicates the fcl function ScanDateTime, but returns false rather than
// raising an exception --> much faster
function TryScanDateTime(const Pattern: String; const s: String; out ADate: TDateTime;
  const fmt: TFormatSettings): Boolean;
var
  len, ind: integer;
  yy, mm, dd: integer;
  timeVal: TDateTime;
  activeQuote: char;
  isError: Boolean;

  procedure intscandate(ptrn:pchar;plen:integer;poffs:integer);
  // poffs is the offset to
  var
    pind : integer;

    function findimatch(const mnts:array of string; p:pchar):integer;
    var
      i: integer;
      plen, findlen: integer;
    begin
      result:=-1;
      i:=0;
      plen := strlen(p);
      while (i<=high(mnts)) and (result=-1) do
        begin
          findlen := length(mnts[i]);
          if (findlen > 0) and (findlen <= plen) then // protect against buffer over-read
            if AnsiStrLIComp(p,@(mnts[i][1]),findlen)=0 then
              result:=i;
          inc(i);
        end;
    end;

    procedure arraymatcherror;
    begin
      isError := true;
    end;

    function scanmatch(const mnts: array of string;p:pchar; patlen: integer):integer;
    begin
      result:=findimatch(mnts,p);
      if result=-1 then
        arraymatcherror
      else
      begin
        inc(ind,length(mnts[result]));
        inc(pind,patlen);
        inc(result); // was 0 based.
      end;
    end;

    var
      pivot: Integer;
      i: Integer;

    function scanfixedint(maxv:integer):integer;
    var c : char;
        oi:integer;
    begin
      result:=0;
      oi:=ind;
      c:=ptrn[pind];
      while (pind<plen) and (ptrn[pind]=c) do inc(pind);
      while (maxv>0) and (ind<=len) and (s[ind] in ['0'..'9']) do
        begin
          result:=result*10+ord(s[ind])-48;
          inc(ind);
          dec(maxv);
        end;
      if oi=ind then
        isError := true;
    end;

    procedure matchchar(c:char);
    begin
      if (ind > len) or (s[ind] <> c) then
      begin
        isError := true;
        exit;
      end;
      inc(pind);
      inc(ind);
    end;

    function ScanPatLen: integer;
    var
      c: char;
      lind: Integer;
    begin
      result := pind;
      lind := pind;
      c:=ptrn[lind];

      while (lind<=plen) and (ptrn[lind]=c) do
        inc(lind);
      result:=lind-result;
    end;

    procedure matchpattern(const lptr:string);
    var len:integer;
    begin
      len:=length(lptr);
      if (len>0) and (not isError) then
        intscandate(@lptr[1], len, pind+poffs);
    end;

  var
    lasttoken,lch : char;

  begin
    pind:=0;
    lasttoken:=' ';
    while (ind<=len) and (pind<plen) and (not isError) do
       begin
         lch:=upcase(ptrn[pind]);
         if activequote=#0 then
            begin
              if (lch='M') and (lasttoken='H') then
                begin
                  i:=scanpatlen;
                  if i>2 then
                    isError := true
                  else
                    timeval:=timeval+scanfixedint(2)* minfactor;
                end
              else
              case lch of
                 'H':  timeval:=timeval+scanfixedint(2)* hrfactor;
                 'D':  begin
                         i:=scanpatlen;
                         if isError then
                           break;
                         case i of
                            1,2 : dd:=scanfixedint(2);
                            3   : dd:=scanmatch(fmt.shortDayNames,@s[ind],i);
                            4   : dd:=scanmatch(fmt.longDayNames,@s[ind],i);
                            5   :
                              begin
                                matchpattern(fmt.shortdateformat);
                                inc(pind, i);
                              end;
                            6   :
                              begin
                                matchpattern(fmt.longdateformat);
                                inc(pind, i);
                              end;
                           end;
                       end;
                 'N':  timeval:=timeval+scanfixedint(2)* minfactor;
                 'S':  timeval:=timeval+scanfixedint(2)* secfactor;
                 'Z':  timeval:=timeval+scanfixedint(3)* mssecfactor;
                 'Y':  begin
                         i:=scanpatlen;
                         if isError then
                           break;
                         case i of
                            1,2 : yy:=scanfixedint(2);
                            else  yy:=scanfixedint(i);
                         end;
                         if i<=2 then
                           begin
                             pivot:=YearOf(now)-fmt.TwoDigitYearCenturyWindow;
                             inc(yy, pivot div 100 * 100);
                             if (fmt.TwoDigitYearCenturyWindow > 0) and (yy < pivot) then
                                inc(yy, 100);
                           end;
                        end;
                 'M': begin
                         i:=scanpatlen;
                         if isError then
                           break;
                         case i of
                            1,2: mm:=scanfixedint(2);
                            3:   mm:=scanmatch(fmt.ShortMonthNames,@s[ind],i);
                            4:   mm:=scanmatch(fmt.LongMonthNames,@s[ind],i);
                            end;
                      end;
                 'T' : begin
                         i:=scanpatlen;
                         if isError then
                           break;
                         case i of
                         1:
                           begin
                             matchpattern(fmt.shorttimeformat);
                             inc(pind, i);
                           end;
                         2:
                           begin
                             matchpattern(fmt.longtimeformat);
                             inc(pind, i);
                           end;
                         end;
                       end;
                 'A' : begin
                         i:=findimatch(AMPMformatting,@ptrn[pind]);
                         if isError then break;
                         case i of
                           0: begin
                                i:=findimatch(['AM','PM'],@s[ind]);
                                case i of
                                  0: ;
                                  1: timeval:=timeval+12*hrfactor;
                                else
                                  arraymatcherror
                                end;
                                inc(pind,length(AMPMformatting[0]));
                                inc(ind,2);
                              end;
                           1: begin
                                case upcase(s[ind]) of
                                  'A' : ;
                                  'P' : timeval:=timeval+12*hrfactor;
                                else
                                  arraymatcherror
                                end;
                                inc(pind,length(AMPMformatting[1]));
                                inc(ind);
                              end;
                           2: begin
                                i:=findimatch([fmt.timeamstring,fmt.timepmstring],@s[ind]);
                                case i of
                                  0: inc(ind,length(fmt.timeamstring));
                                  1: begin
                                       timeval:=timeval+12*hrfactor;
                                       inc(ind,length(fmt.timepmstring));
                                     end;
                                else
                                  arraymatcherror
                                end;
                                inc(pind,length(AMPMformatting[2]));
                                end;
                              else  // no AM/PM match. Assume 'a' is simply a char
                                matchchar(ptrn[pind]);
                         end;
                       end;
                 '/' : matchchar(fmt.dateSeparator);
                 ':' : begin
                         matchchar(fmt.TimeSeparator);
                         lch:=lasttoken;
                       end;
                 #39,'"' : begin
                             activequote:=lch;
                             inc(pind);
                           end;
                 'C' : begin
                         intscandate(@fmt.shortdateformat[1],length(fmt.ShortDateFormat),pind+poffs);
                         intscandate(@fmt.longtimeformat[1],length(fmt.longtimeformat),pind+poffs);
                         inc(pind);
                       end;
                 '?' : begin
                         inc(pind);
                         inc(ind);
                       end;
                 #9  : begin
                         while (ind<=len) and (s[ind] in whitespace) and (not isError) do
                           inc(ind);
                         inc(pind);
                       end;
                 else
                   matchchar(ptrn[pind]);
               end; {case}
               lasttoken:=lch;
              end
            else
              begin
                if activequote=lch then
                  begin
                    activequote:=#0;
                    inc(pind);
                  end
                else
                  matchchar(ptrn[pind]);
              end;
       end;
     if (pind<plen) and (plen>0) and not (ptrn[plen-1] in [#9, '"']) then  // allow omission of trailing whitespace
       isError := true;
  end;

var
  plen: integer;
begin
  isError := false;
  activeQuote := #0;
  yy:=0;
  mm:=0;
  dd:=0;
  timeval := 0.0;
  len := length(s);
  ind := 1;
  plen := Length(pattern);
  IntScanDate(@pattern[1], plen, 0);
  if isError then
  begin
    ADate := 0;
    Result := false;
  end else
  begin
    ADate := timeval;
    if (yy>0) and (mm>0) and (dd>0) then
       ADate := ADate + EncodeDate(yy,mm,dd);
    Result := True;
  end;
end;

(*
function TryScanDateTime(AMask, ADateStr: String; out ADate: TDateTime;
  const AFmtSettings: TFormatSettings): Boolean;
begin
  try
    ADate := ScanDateTime(AMask, ADateStr, AFmtSettings);
    Result := true;
  except
    Result := false;
    ADate := 0;
  end;
end;
*)

end.

