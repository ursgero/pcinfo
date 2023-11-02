unit pcinfo5;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, GlobalConfig;

type

  { TForm3 }

  TForm3 = class(TForm)
    Memo1: TMemo;
    procedure Memo1Change(Sender: TObject);
  private

  public

  end;

var
  Form3: TForm3;

implementation

{$R *.lfm}

{ TForm3 }

procedure TForm3.Memo1Change(Sender: TObject);
begin

end;

end.

