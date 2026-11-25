program c2pascmd_naive;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  c2pas_convert_naive in 'c2pas_convert_naive.pas',
  c2pas_utils in 'c2pas_utils.pas',
  c2pas_script in 'c2pas_script.pas',
  c2pas_memmgr in 'c2pas_memmgr.pas';

var
  cnt: integer = 0;

function get_pas_filename(ffilename: string): string;
var
  i: integer;
  l: integer;
begin
  Result := ffilename;
  if Result <> '' then
  begin
    l := Length(Result);
    if l > 4 then
      if (not (Result[l] in ['s', 'S'])) or
         (not (Result[l - 1] in ['a', 'A'])) or
         (not (Result[l - 2] in ['p', 'P'])) or
         (not (Result[l - 3] in ['.'])) then
      begin
        for i := l downto 1 do
          if Result[i] = '.' then
          begin
            Result[i] := '_';
            break;
          end
          else if Result[i] in ['/', '\'] then
            break;
        Result := Result + '.pas';
      end;
  end;
  if Result = ffilename then
    Result := Result + '.pas';
  Result := LowerCase(Result);
end;

procedure make_pas_source_naive(const inp: string);
var
  s: TStringList;
begin
  write('  ' + ExtractFileName(inp));
  write(s_spaces(12 - Length(ExtractFileName(inp))));
  if not FileExists(inp) then
  begin
    Writeln('->(!NOT FOUND)');
    exit;
  end;
  s := TStringList.Create;
  try
    write('.');
    s.LoadFromFile(inp);
    write('.');
    s.Text := ConvertNaive(s.Text);
    write('.');
    if s.Count > 0 then
    begin
      if Pos('unit ', s.Strings[0]) = 1 then
        s.Strings[0] := 'unit ' + StringReplace(ExtractFileName(inp), '.', '_', [rfReplaceAll]) + ';';
    end;
    write('.');
    s.SaveToFile(get_pas_filename(inp));
    write('.->', ExtractFileName(get_pas_filename(inp)));
  finally
    s.Free;
  end;
  Inc(cnt);
end;

procedure make_pas_r(const inp: string); forward;

procedure make_pas(const inp: string; r: boolean);
var
  sr: TSearchRec;
begin
  if r then
  begin
    make_pas_r(inp);
    exit;
  end;

  if FindFirst(inp, faAnyFile, sr) = 0 then
  begin
    repeat
      make_pas_source_naive(sr.Name);
      writeln;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;


procedure FindFiles(FilesList: TStringList; StartDir, FileMask: string);
var
  SR: TSearchRec;
  DirList: TStringList;
  IsFound: Boolean;
  i: integer;
begin
  if StartDir[length(StartDir)] <> '\' then
    StartDir := StartDir + '\';

  { Build a list of the files in directory StartDir
     (not the directories!)                         }

  IsFound :=
    FindFirst(StartDir+FileMask, faAnyFile-faDirectory, SR) = 0;
  while IsFound do begin
    FilesList.Add(StartDir + SR.Name);
    IsFound := FindNext(SR) = 0;
  end;
  FindClose(SR);

  // Build a list of subdirectories
  DirList := TStringList.Create;
  IsFound := FindFirst(StartDir+'*.*', faAnyFile, SR) = 0;
  while IsFound do begin
    if ((SR.Attr and faDirectory) <> 0) and
         (SR.Name[1] <> '.') then
      DirList.Add(StartDir + SR.Name);
    IsFound := FindNext(SR) = 0;
  end;
  FindClose(SR);

  // Scan the list of subdirectories
  for i := 0 to DirList.Count - 1 do
    FindFiles(FilesList, DirList[i], FileMask);

  DirList.Free;
end;

procedure make_pas_r(const inp: string);
var
  FilesList: TStringList;
  dir: string;
  msk: string;
  i: integer;
begin
  FilesList := TStringList.Create;
  try
    dir := ExtractFilePath(inp);
    msk := ExtractFileName(inp);
    if dir = '' then
      dir := GetCurrentDir;
    FindFiles(FilesList, dir, msk);
    for i := 0 to FilesList.Count - 1 do
    begin
      make_pas_source_naive(FilesList.Strings[i]);
      writeln;
    end;
  finally
    FilesList.Free;
  end;
end;



var
  i: integer;
  recurs: Boolean;
begin
  if ParamCount < 1 then
  begin
    Writeln('Usage:');
    Writeln('  c2pascmd file1.c [file2.c file1.h ...] (also wildcards) [-s]');
    Halt(1);
  end;

  Writeln('Convering....');
  recurs := false;
  for i := 1 to ParamCount do
    if ParamStr(i) = '-s' then
      recurs := true;
  for i := 1 to ParamCount do
    if ParamStr(i) <> '-s' then
      make_pas(ParamStr(i), recurs);
  Writeln('Total Files Converted: ', cnt);
end.
