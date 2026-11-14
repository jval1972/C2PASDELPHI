unit c2pas_convert_naive;

interface

function ConvertNaive(const sinp: string): string;

implementation

uses
  SysUtils, Classes, StrUtils, c2pas_memmgr, c2pas_utils;

function ConvertNaive_Pass1(const sinp: string): string;
begin
  result := sinp;

  result := StringReplace(result, #9, '  ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '=&', '=@', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '==', #255#250, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '!=', #255#251, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '>=', #255#252, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '<=', #255#253, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '||', '|', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '^^', '^', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '^', ') xor (', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '&&', '&', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '<<', ' shl ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '>>', ' shr ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '&', ') and (', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '|', ') or (', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '=', ':=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ':=', ' := ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  :=', ' :=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ':=', ':= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '+ :=', '+:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '- :=', '-:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '* :=', '*:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '/ :=', '/:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #255#250, ' = ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  =', ' =', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '=  ', '= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #255#251, ' <> ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  <>', ' <>', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '<>  ', '<> ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #255#252, ' >= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  >=', ' >=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '>=  ', '>= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #255#253, ' <= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  <=', ' <=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '<=  ', '<= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, 'return;', 'exit;', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '->', '.', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' case ', ' ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' switch ', ' case ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '{', ' begin ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '}', ' end;', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '"', '''', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '/*', '(*', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '*/', '*)', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '()', '', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '(void)', ';', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ';;', ';', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '!', ' not ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' )', ')', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '( ', '(', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' 0x', ' $', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '#endif', '{$ENDIF}', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '#else', '{$ELSE}', [rfReplaceAll, rfIgnoreCase]);
end;

function isidentifier(const stmp1: string): boolean;
var
  i: integer;
  stmp: string;
begin
  stmp := Trim(stmp1);
  result := false;
  for i := 1 to length(stmp) do
    if not (stmp[i] in ['A'..'Z']) then
      if not (stmp[i] in ['a'..'z']) then
        if not (stmp[i] in ['1'..'9', '0', '_', '.', '/','[',']']) then
          exit;
  result := true;
end;

function ConvertNaive_Pass2(const sinp: string): string;
var
  s: TStringList;
  i, j: integer;
  stmp: string;
  nspaces: integer;
  changed: boolean;
  beginhack: boolean;
  spacehack: boolean;

  function resolvedoubleassigment: string;
  var
    ii: integer;
    p: integer;
    stmp1, stmp2: string;
    praxi: char;
    elsehack: boolean;
  begin
    result := stmp;
    if length(result) = 0 then
      exit;
    if stmp[length(result)] <> ';' then
      exit;
    p := Pos('+:=', result);
    if p < 1 then
      p := Pos('-:=', result);
    if p < 1 then
      p := Pos('*:=', result);
    if p < 1 then
      p := Pos('/:=', result);
    if p < 1 then
      exit;

    stmp1 := '';
    stmp2 := '';
    for ii := 1 to p - 1 do
      stmp1 := stmp1 + stmp[ii];
    for ii := p + 3 to length(result) - 1 do
      stmp2 := stmp2 + result[ii];

    stmp1 := trim(stmp1);
    stmp2 := trim(stmp2);

    elsehack := false;
    if Pos('else ', stmp1) > 0 then
    begin
      stmp1[1] := ' ';
      stmp1[2] := ' ';
      stmp1[3] := ' ';
      stmp1[4] := ' ';
      stmp1 := Trim(stmp1);
      elsehack := true;
    end;

    if isidentifier(stmp1) then
      if isidentifier(stmp2) then
      begin
        praxi := stmp[p];
        result := stmp1 + ' := ' + stmp1 + ' ' + praxi + ' ' + stmp2 + ';';
        if elsehack then
          result := 'else ' + result;
      end;
  end;

begin
  s := TStringList.Create;

  s.Text := sinp;

  nspaces := 0;
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    changed := false;
    beginhack := false;
    if Pos('PUBLIC ', Trim(stmp)) = 1 then
    begin
      stmp[1] := ' ';
      stmp[2] := ' ';
      stmp[3] := ' ';
      stmp[4] := ' ';
      stmp[5] := ' ';
      stmp[6] := ' ';
      stmp := Trim(stmp);
      s.Strings[i] := stmp;
      changed := true;
    end
    else if Pos('PRIVATE ', Trim(stmp)) = 1 then
    begin
      stmp[1] := ' ';
      stmp[2] := ' ';
      stmp[3] := ' ';
      stmp[4] := ' ';
      stmp[5] := ' ';
      stmp[6] := ' ';
      stmp[7] := ' ';
      stmp := Trim(stmp);
      s.Strings[i] := stmp;
      changed := true;
    end;

    if Trim(stmp) <> 'begin' then
    begin
      nspaces := 0;
      for j := 1 to length(stmp) do
      begin
        if stmp[j] = ' ' then
          inc(nspaces)
        else
          break;
      end;
    end
    else if i > 0 then
    begin
      nspaces := 0;
      for j := 1 to length(s.Strings[i - 1]) do
      begin
        if s.Strings[i - 1][j] = ' ' then
          inc(nspaces)
        else
          break;
      end;
      changed := true;
      beginhack := true;
    end;
    spacehack := false;
    if nspaces = 1 then
    begin
      spacehack := true;
      nspaces := 2;
    end;
    stmp := Trim(s.Strings[i]);
    if Pos('int ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': integer;';
          changed := true;
        end;
    end
    else if Pos('uint32 ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp[5] := ' ';
          stmp[6] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': LongWord;';
          changed := true;
        end;
    end
    else if Pos('word ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': word;';
          changed := true;
        end;
    end
    else if Pos('longint ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp[5] := ' ';
          stmp[6] := ' ';
          stmp[7] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': integer;';
          changed := true;
        end;
    end
    else if Pos('FILE ', stmp) = 1 then
    begin
      if (Pos('*', stmp) > 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': file;';
          for j := 1 to length(stmp) do
            if stmp[j] = '*' then
              stmp[j] := ' ';
          changed := true;
        end;
    end
    else if Pos('long long ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp[5] := ' ';
          stmp[6] := ' ';
          stmp[7] := ' ';
          stmp[8] := ' ';
          stmp[9] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': int64;';
          changed := true;
        end;
    end
    else if Pos('long ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': integer;';
          changed := true;
        end;
    end
    else if Pos('#ifdef ', stmp) = 1 then
    begin
      if (Pos('<', stmp) < 1) and (Pos('>', stmp) < 1) and (Pos('=', stmp) < 1) then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp[3] := ' ';
        stmp[4] := ' ';
        stmp[5] := ' ';
        stmp[6] := ' ';
        stmp := Trim(stmp);
        stmp := '{$IFDEF ' + stmp + '}';
        changed := true;
      end;
    end
    else if Pos('fixed_t ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp[5] := ' ';
          stmp[6] := ' ';
          stmp[7] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': fixed_t;';
          changed := true;
        end;
    end
    else if Pos('bool ', stmp) = 1 then
    begin
      if (Pos('*', stmp) < 1) and (Pos('[', stmp) < 1) then
        if stmp[length(stmp)] = ';' then
        begin
          stmp[length(stmp)] := ' ';
          stmp[1] := ' ';
          stmp[2] := ' ';
          stmp[3] := ' ';
          stmp[4] := ' ';
          stmp := Trim(stmp);
          stmp := '  ' + stmp + ': boolean;';
          changed := true;
        end;
    end
    else if (Pos('if (', stmp) = 1) or (Pos('if(', stmp) = 1) then
    begin
      if stmp[length(stmp)] = ')' then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp := 'if ' + Trim(stmp) + ' then';
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := true;
      end;
    end
    else if (Pos('while (', stmp) = 1) or (Pos('while(', stmp) = 1) then
    begin
      if stmp[length(stmp)] = ')' then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp[3] := ' ';
        stmp[4] := ' ';
        stmp[5] := ' ';
        stmp := 'while ' + Trim(stmp) + ' do';
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := true;
      end;
    end
    else if (Pos('else if (', stmp) = 1) or (Pos('else if(', stmp) = 1) then
    begin
      if i > 0 then
        if Trim(s.Strings[i - 1]) = 'end;' then
        begin
          s.Strings[i - 1] := stringofchar(' ', nspaces) + 'end';
        end;
      if stmp[length(stmp)] = ')' then
        if i < s.Count - 1 then
          if Trim(s.Strings[i + 1]) = 'begin' then
          begin
            stmp[1] := ' ';
            stmp[2] := ' ';
            stmp[3] := ' ';
            stmp[4] := ' ';
            stmp[5] := ' ';
            stmp[6] := ' ';
            stmp[7] := ' ';
            stmp := 'else if ' + Trim(stmp) + ' then';
            for j := 1 to nspaces do
              stmp := ' ' + stmp;
            changed := true;
          end;
    end
    else if Pos('void ', stmp) = 1 then
    begin
      if stmp[length(stmp)] = ';' then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp[3] := ' ';
        stmp[4] := ' ';
        stmp := Trim(stmp);
        stmp := 'procedure ' + stmp;
        changed := true;
      end
      else if stmp[length(stmp)] = ')' then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp[3] := ' ';
        stmp[4] := ' ';
        stmp := Trim(stmp);
        stmp := 'procedure ' + stmp + ';';
        changed := true;
      end;
    end
    else if (Pos('+:=', stmp) > 0) or (Pos('-:=', stmp) > 0) or (Pos('*:=', stmp) > 0) or (Pos('/:=', stmp) > 0) then
    begin
      stmp := resolvedoubleassigment;
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      changed := true;
    end
    else if (Pos('''', stmp) = 0) and (Pos('%', stmp) > 0) then
    begin
      stmp := StringReplace(stmp, '%', ' mod ', [rfReplaceAll, rfIgnoreCase]);
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      changed := true;
    end;

    if not changed then
      if spacehack then
      begin
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := true;
      end;

    if changed then
    begin
      if beginhack then
      begin
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
      end;
      s.Strings[i] := stmp;
    end;
  end;

  result := s.Text;
  s.Free;
end;

function ConvertNaive_Pass3(const sinp: string): string;
var
  s: TStringList;
  i, j: integer;
  stmp: string;
  nspaces: integer;
  changed: boolean;

  procedure removeparenthesis;
  var
    xx: integer;
    p1, p2: integer;
  begin
    p1 := 0;
    p2 := 0;
    for xx := 1 to Length(stmp) do
    begin
      if stmp[xx] = '(' then
        inc(p1)
      else if stmp[xx] = ')' then
        inc(p2);
    end;
    if (p1 = 1) and (p2 = 1) then
    begin
      p1 := Pos('(', stmp);
      p2 := Pos(')', stmp);
      if p1 < p2 then
      begin
        for xx := 1 to Length(stmp) do
          if stmp[xx] in ['(', ')'] then
            stmp[xx] := ' ';
        stmp := stringreplace(stmp, '  ', ' ', [rfReplaceAll, rfIgnoreCase]);
        stmp := stringreplace(stmp, '  ', ' ', [rfReplaceAll, rfIgnoreCase]);
        for xx := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := true;
      end;
    end;
  end;

begin
  s := TStringList.Create;

  s.Text := sinp;

  nspaces := 0;
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    changed := false;
    nspaces := 0;
    for j := 1 to length(stmp) do
    begin
      if stmp[j] = ' ' then
        inc(nspaces)
      else
        break;
    end;

    stmp := Trim(stmp);
    if (Pos('if ', stmp) = 1) and (Pos(' then', stmp) = Length(stmp) - 4) then
      removeparenthesis
    else if (Pos('while ', stmp) = 1) and (Pos(' do', stmp) = Length(stmp) - 2) then
      removeparenthesis
    else if (Pos('else if ', stmp) = 1) and (Pos(' then', stmp) = Length(stmp) - 4) then
      removeparenthesis
    else if (Pos('case ', stmp) = 1) and (Pos(')', stmp) = Length(stmp)) then
    begin
      removeparenthesis;
      stmp := stmp + ' of'
    end;

    if changed then
      s.Strings[i] := stmp;
  end;

  result := s.Text;
  s.Free;
end;


function ConvertNaive(const sinp: string): string;
begin
  result := ConvertNaive_Pass1(sinp);
  result := ConvertNaive_Pass2(result);
  result := ConvertNaive_Pass3(result);
end;


end.
