unit uDatamodule;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls;

type

  { TCommonData }

  TCommonData = class(TDataModule)
    Images: TImageList;
  private

  public

  end;

var
  CommonData: TCommonData;

implementation

{$R *.lfm}

end.

