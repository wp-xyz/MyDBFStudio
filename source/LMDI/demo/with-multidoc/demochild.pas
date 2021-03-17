unit demochild;
{
   Demo of TMultiDoc component.
   
   The child form.

   This show how to use the TMultiDoc component and
   the function to implement to better mimic the MDI
   interface.

   This very simple demo can be used as a skeleton
   for a new application.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons;

type

  { TfrChild }

  TfrChild = class(TForm)
    btAdd: TButton;
    meText: TMemo;
    MainPanel: TPanel; // only component in this panel are viewed at run time
    pnTop: TPanel;
    procedure btAddClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frChild: TfrChild;

implementation

{ TfrChild }

procedure TfrChild.btAddClick(Sender: TObject);
begin
  meText.lines.Add(btAdd.Caption);
end;

initialization
  {$I demochild.lrs}

end.

