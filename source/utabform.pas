unit uTabForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ComCtrls, Forms, Controls;

Type

    { TTabForm }

    TTabForm                   = Class(TTabSheet)
      Private
        ParentPageControl      : TPageControl;

        Procedure TSShow(Sender: TObject);

      Public
        ParentForm             : TForm;
        Constructor Create(AOwner : TComponent); Override;
        Destructor Destroy; Override;
        Procedure AddFormToPageControl(MyForm : TForm);
    end;

implementation

{ TTabForm }

procedure TTabForm.TSShow(Sender: TObject);
begin
 (Sender As TTabForm).PageControl.Color := (Sender As TTabForm).Color;
end;

constructor TTabForm.Create(AOwner: TComponent);
begin
 ParentPageControl := TPageControl(AOwner);
 ParentForm := Nil;

 Inherited Create(AOwner);
end;

destructor TTabForm.Destroy;
begin
 If Self.ParentForm <> Nil Then
  Begin
   Self.ParentForm.Release;
   Self.ParentForm := Nil;
  end;

 Inherited Destroy;
end;

procedure TTabForm.AddFormToPageControl(MyForm: TForm);
 Var ts : TTabForm;
begin
 ts := TTabForm.Create(ParentPageControl);
 ts.ParentForm := MyForm;

 ts.PageControl := ParentPageControl;
 ts.ParentForm.Parent := ts;
 ts.ParentForm.Align := alClient;
 ts.ParentForm.BorderStyle := bsNone;
 ts.ParentForm.Visible := True;
 ts.Caption := ts.ParentForm.Caption;
 ts.Color := MyForm.Color;
 ts.PageControl.Color := MyForm.Color;

 ts.OnShow := @TSShow;

 ParentPageControl.ActivePage := ts;
 ParentPageControl.Visible := True;
end;

end.

