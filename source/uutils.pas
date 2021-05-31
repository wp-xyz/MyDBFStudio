unit uUtils;

{$mode ObjFPC}

interface

uses
  Classes, SysUtils, LCLVersion,
  DBGrids;

{$IF LCL_FullVersion < 2010000}
type
  TDBGridColumnsHelper = class helper for TDBGridColumns
    function COlumnByFieldName(const aFieldName: String): TColumn;
  end;
{$IFEND}

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

function GetVersionStr: String;
var
  ver: TProgramVersion;
begin
  ver := Default(TProgramVersion);
  GetProgramVersion(ver);
  Result := Format('v%d.%d.%d', [ver.Major, ver.Minor, ver.Revision]);
end;

end.

