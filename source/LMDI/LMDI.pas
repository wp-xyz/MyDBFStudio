{ This file was automatically created by Lazarus. Do not edit!
This source is only used to compile and install the package.
 }

unit LMDI; 

interface

uses
  titlebar, formpanel, buttonsbar, LazarusPackageIntf; 

implementation

procedure Register; 
begin
  RegisterUnit('titlebar', @titlebar.Register); 
  RegisterUnit('formpanel', @formpanel.Register); 
  RegisterUnit('buttonsbar', @buttonsbar.Register); 
end; 

initialization
  RegisterPackage('LMDI', @Register); 
end.
