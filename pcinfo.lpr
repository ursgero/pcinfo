program pcinfo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, pcinfo1, pcinfo2, pcinfo3, pcinfo4, pcinfo5
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.MainFormOnTaskBar:=true;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormConfig, FormConfig);
  Application.CreateForm(TFormStandardDateiNamenEditor, 
    FormStandardDateiNamenEditor);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.

