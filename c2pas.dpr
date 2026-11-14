program c2pas;

uses
  Forms,
  c2pas_convert in 'c2pas_convert.pas',
  c2pas_memmgr in 'c2pas_memmgr.pas',
  main in 'main.pas' {Form1},
  c2pas_script in 'c2pas_script.pas',
  c2pas_utils in 'c2pas_utils.pas',
  c2pas_convert_naive in 'c2pas_convert_naive.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
