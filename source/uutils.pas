unit uUtils;

{$mode ObjFPC}

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
function TableFormat(ATableLevel: Integer): String;

implementation

uses
  TypInfo, FileInfo;

{$IF LCL_FullVersion < 2010000}
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

function GetVersionStr: String;
var
  ver: TProgramVersion;
begin
  ver := Default(TProgramVersion);
  GetProgramVersion(ver);
  Result := Format('v%d.%d.%d', [ver.Major, ver.Minor, ver.Revision]);
end;

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

end.

