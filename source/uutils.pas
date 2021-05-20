unit uUtils;

{$mode ObjFPC}

interface

uses
  Classes, SysUtils;

function GetVersionStr: String;

implementation

uses
  FileInfo;

function GetVersionStr: String;
var
  ver: TProgramVersion;
begin
  GetProgramVersion(ver);
  Result := Format('v%d.%d.%d', [ver.Major, ver.Minor, ver.Revision]);
end;

end.

