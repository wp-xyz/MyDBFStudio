program DbfStudio;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain;

//{$IFDEF WINDOWS}{$R DbfStudio.rc}{$ENDIF}

{$R *.res}

begin
  Application.Scaled:=True;
  Application.Title:='MyDbf Studio';
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.

