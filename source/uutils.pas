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
    ftString, ftSmallInt, ftInteger, ftWord, ftBoolean,
    ftFloat, ftDate, ftDateTime, ftBLOB, ftDBaseOLE, ftFixedChar, ftWideString,
    ftLargeInt, ftCurrency, ftBCD, ftBytes, ftAutoInc,
    ftMemo];

procedure FieldTypePickList(ATableLevel: Integer; const AList: TStrings);
function GetVersionStr: String;

implementation

uses
  FileInfo;

{$IF LCL_FullVersion < 2010000}
function TDBGridColumnsHelper.ColumnByFieldname(const aFieldname: string): TColumn;
var
  i: Integer;
begin
  result := nil;
  for i:=0 to Count-1 do
    if CompareText(Items[i].FieldName, aFieldname)=0 then begin
      result := Items[i];
      break;
    end;
end;
{$IFEND}

procedure FieldTypePickList(ATableLevel: Integer; const AList: TStrings);
begin
  AList.Clear;

  AList.Add(Fieldtypenames[ftString]);
  AList.Add(Fieldtypenames[ftWideString]);
  AList.Add(Fieldtypenames[ftSmallInt]);
  AList.Add(Fieldtypenames[ftInteger]);
  AList.Add(Fieldtypenames[ftWord]);
  AList.Add(Fieldtypenames[ftLargeInt]);
  AList.Add(Fieldtypenames[ftBoolean]);
  AList.Add(Fieldtypenames[ftFloat]);
  AList.Add(Fieldtypenames[ftDate]);
  AList.Add(Fieldtypenames[ftDateTime]);
  AList.Add(Fieldtypenames[ftBlob]);
  AList.Add(Fieldtypenames[ftMemo]);
  AList.Add(Fieldtypenames[ftDBaseOle]);
  AList.Add(Fieldtypenames[ftFixedChar]);

  If ATableLevel = 7 Then
   AList.Add(Fieldtypenames[ftAutoInc]);
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

