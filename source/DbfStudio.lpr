program DbfStudio;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, T_MainForm, DBFLaz, T_DbfTable, T_Restructure, T_IdxTable, T_NewTable,
  DsCsv, T_ExpCSV, DsDataExport, DsHtml, T_ExtHTML, DsXls, T_ExpXls,
  T_AddTables, T_SubTables, T_ExpDbf, T_ExpXml,
  T_SortTable, T_ExpSQL;

//{$IFDEF WINDOWS}{$R DbfStudio.rc}{$ENDIF}

{$R *.res}

begin
  Application.Scaled:=True;
  Application.Title:='MyDbf Studio';
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.

