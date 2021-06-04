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
    ftBLOB, ftMemo, ftGraphic,   // ftGraphic not supported by wiki, but seems to be outdated.
    ftCurrency, ftBCD, ftBytes,  // TableLevel 25 only
    ftAutoInc  // TableLevel 7 and 30 only
    ];

function FieldTypeAsString(AFieldType: TFieldType; Nice: Boolean): String;
procedure FieldTypePickList(ATableLevel: Integer; const AList: TStrings);
function GetVersionStr: String;

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

function FieldTypeAsString(AFieldType: TFieldType; Nice: Boolean): String;
begin
  Result := GetEnumName(TypeInfo(TFieldType), integer(AFieldType));
  if Nice then Delete(Result, 1, 2);
end;

function GetVersionStr: String;
var
  ver: TProgramVersion;
begin
  ver := Default(TProgramVersion);
  GetProgramVersion(ver);
  Result := Format('v%d.%d.%d', [ver.Major, ver.Minor, ver.Revision]);
end;

end.

