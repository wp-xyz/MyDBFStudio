unit uDatamodule;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls;

type

  { TCommonData }

  TCommonData = class(TDataModule)
    Images: TImageList;  // Do not rearrange the first 10 icons, needed by DBNavigator at this place.
  private

  public

  end;

var
  CommonData: TCommonData;

implementation

{$R *.lfm}

end.

