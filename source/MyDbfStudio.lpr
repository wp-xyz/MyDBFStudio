program MyDbfStudio;

// todo: set grid line color to some system color for less dominant rendering in dark mode.
// todo: Fix dbgrid scrollbar behaviour

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain, uDatamodule;

{$R *.res}

begin
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TCommonData, CommonData);
  Application.CreateForm(TMain, Main);
  Application.Run;
end.

