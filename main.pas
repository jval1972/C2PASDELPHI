unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, Buttons, StdCtrls;

type
  TForm1 = class(TForm)
    SaveDialog1: TSaveDialog;
    Panel1: TPanel;
    NewButton1: TSpeedButton;
    OpenButton1: TSpeedButton;
    SaveButton1: TSpeedButton;
    SaveAsButton1: TSpeedButton;
    AboutButton1: TSpeedButton;
    ExitButton1: TSpeedButton;
    FormPanel: TPanel;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    ConvertButton1: TSpeedButton;
    Memo2: TMemo;
    ConvertNaiveButton1: TSpeedButton;
    Panel2: TPanel;
    Bevel1: TBevel;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure NewButton1Click(Sender: TObject);
    procedure SaveButton1Click(Sender: TObject);
    procedure AboutButton1Click(Sender: TObject);
    procedure SaveAsButton1Click(Sender: TObject);
    procedure Memo2Change(Sender: TObject);
    procedure OpenButton1Click(Sender: TObject);
    procedure ExitButton1Click(Sender: TObject);
    procedure ConvertButton1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ConvertNaiveButton1Click(Sender: TObject);
  private
    { Private declarations }
    ffilename: string;
    changed: Boolean;
    function CheckCanClose: boolean;
    procedure DoNew;
    procedure DoSave(const fname: string);
    procedure DoLoad(const fname: string);
    procedure DoConvert;
    procedure SetFileName(const fname: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  qforms, c2pas_convert, c2pas_convert_naive;

{$R *.dfm}

resourcestring
  rsTitle = 'C2PAS Editor';

procedure TForm1.FormCreate(Sender: TObject);
begin
  Memo1.Width := Width div 2;
  DoNew;
  if ParamCount > 0 then
  begin
    DoLoad(ParamStr(1));
  end;
end;

procedure TForm1.DoLoad(const fname: string);
begin
  Memo1.Lines.LoadFromFile(fname);
  Memo2.Lines.Clear;
  SetFileName(fname);
  DoConvert;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := CheckCanClose;
end;

function TForm1.CheckCanClose: boolean;
var
  ret: integer;
begin
  if changed then
  begin
    ret := MessageBox(Handle, 'Do you want to save changes?', PChar(rsTitle), MB_YESNOCANCEL or MB_ICONQUESTION or MB_APPLMODAL);
    if ret = IDCANCEL	then
    begin
      result := false;
      exit;
    end;
    if ret = IDNO	then
    begin
      result := true;
      exit;
    end;
    if ret = IDYES then
    begin
      SaveButton1Click(self);
      result := not changed;
      exit;
    end;
  end;
  result := true;
end;

procedure TForm1.NewButton1Click(Sender: TObject);
begin
  if not CheckCanClose then
    Exit;
  DoNew;
end;

procedure TForm1.DoNew;
begin
  Memo1.Lines.Clear;
  Memo2.Lines.Clear;
  SetFileName('');
  changed := false;
end;

function MkSortName(const fname: string): string;
var
  i: integer;
begin
  if Length(fname) < 40 then
  begin
    result := fname;
    exit;
  end;
  result := '';
  for i := Length(fname) downto Length(fname) - 35 do
    Result := fname[i] + Result;
  Result := '...' + Result;
  for i := 3 downto 1 do
    Result := fname[i] + Result;
end;

procedure TForm1.SetFileName(const fname: string);
var
  i: integer;
  l: integer;
begin
  ffilename := fname;
  Caption := rsTitle;
  if ffilename <> '' then
  begin
    l := Length(ffilename);
    if l > 4 then
      if (not (ffilename[l] in ['s', 'S'])) or
         (not (ffilename[l - 1] in ['a', 'A'])) or
         (not (ffilename[l - 2] in ['p', 'P'])) or
         (not (ffilename[l - 3] in ['.'])) then
      begin
        for i := l downto 1 do
          if ffilename[i] = '.' then
          begin
            ffilename[i] := '_';
            break;
          end
          else if ffilename[i] in ['/', '\'] then
            break;
        ffilename := ffilename + '.pas';
      end;
    Caption := Caption + ' - ' + MkSortName(ffilename);
  end;
end;

procedure TForm1.SaveButton1Click(Sender: TObject);
begin
  if ffilename = '' then
  begin
    if SaveDialog1.Execute then
      ffilename := SaveDialog1.FileName
    else
    begin
      Beep;
      Exit;
    end;
  end;
  DoSave(ffilename);
end;

procedure TForm1.DoSave(const fname: string);
begin
  SetFileName(fname);
  Memo2.Lines.SaveToFile(ffilename);
  changed := false;
end;

procedure TForm1.AboutButton1Click(Sender: TObject);
begin
  MessageBox(
    Handle,
    PChar(Format('%s'#13#10'Version 1.0'#13#10#13#10'A tool for translating C source code to Pascal.'#13#10, [rsTitle])),
    PChar(rsTitle),
    MB_OK or MB_ICONINFORMATION or MB_APPLMODAL);
end;

procedure TForm1.SaveAsButton1Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    DoSave(SaveDialog1.FileName);
end;

procedure TForm1.Memo2Change(Sender: TObject);
begin
  changed := true;
end;

procedure TForm1.OpenButton1Click(Sender: TObject);
begin
  if not CheckCanClose then
    Exit;

  if OpenDialog1.Execute then
  begin
    DoLoad(OpenDialog1.FileName);
  end;
end;

procedure TForm1.ExitButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.DoConvert;
var
  s: TStringList;
begin
  Screen.Cursor := crHourGlass;
  s := TStringList.Create;
  try
    s.Text := c2pas_parse(Memo1.Lines);
    Memo2.Lines.Text := c2pas_parse1(s);
//    c2pas_parse2(s);

{  Memo2.Lines.Text := c2pas_parse(Memo1.Lines);
  Memo2.Lines.Text := c2pas_parse1(Memo2.Lines);}
  finally
    s.Free;
  end;
  Screen.Cursor := crDefault;
end;

procedure TForm1.ConvertButton1Click(Sender: TObject);
begin
  DoConvert;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Memo1.Width := Width div 2;
end;

procedure TForm1.ConvertNaiveButton1Click(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    Memo2.Lines.Text := ConvertNaive(Memo1.Lines.Text);
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
