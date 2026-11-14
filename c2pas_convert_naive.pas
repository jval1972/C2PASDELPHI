unit c2pas_convert_naive;

interface

function ConvertNaive(const sinp: string): string;

implementation

uses
  SysUtils, Classes, StrUtils, c2pas_memmgr, c2pas_utils;

function ConvertNaive_Pass1(const sinp: string): string;
begin
  result := sinp;

  result := StringReplace(result, #13#10, #10, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #10, #13#10, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #9, '  ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '=&', '=@', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '= &', '= @', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '=  &', '= @', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '(&', '(@', [rfReplaceAll, rfIgnoreCase]);

  result := StringReplace(result, '} else ', '}'#13#10'  else ', [rfReplaceAll, rfIgnoreCase]);

  result := StringReplace(result, '|=', #254#250, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '| =', #254#250, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '^=', #254#251, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '^ =', #254#251, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '&=', #254#252, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '& =', #254#252, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '>>=', #254#253, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '>> =', #254#253, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '<<=', #254#254, [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '<< =', #254#254, [rfReplaceAll, rfIgnoreCase]);

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
  result := StringReplace(result, '(void)', ';', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ';;', ';', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '!', ' not ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' )', ')', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '( ', '(', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' 0x', ' $', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '(0x', '($', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '[0x', '[$', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '#endif', '{$ENDIF}', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '#else', '{$ELSE}', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #254#250, '|:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #254#251, '^:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #254#252, '&:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #254#253, '>>:=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, #254#254, '<<:=', [rfReplaceAll, rfIgnoreCase]);
end;

function ConvertNaive_Pass2(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, stmpt: string;
  nspaces: integer;
begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  s.Text := sinp;

  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    nspaces := 0;
    for j := 1 to length(stmp) do
    begin
      if stmp[j] = ' ' then
        inc(nspaces)
      else
        break;
    end;

    stmp := Trim(stmp);

    if (lastword(stmp) = 'begin') and (Length(stmp) > 5) then
    begin
      SetLength(stmp, Length(stmp) - 5);
      stmpt := Trim(stmp);
      if stmpt <> '' then
      begin
        if firstword(stmpt) = 'if' then
        begin
          if stmp[Length(stmp)] <> ' ' then
            stmp := stmp + ' ';
          stmp := stmp + 'then';
        end;
        if firstword(stmpt) = 'for' then
        begin
          if stmp[Length(stmp)] <> ' ' then
            stmp := stmp + ' ';
          stmp := stmp + 'do';
        end;
      end;

      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      s2.Add(stmp);

      stmp := '';
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      stmp := stmp + 'begin';
      s2.Add(stmp);
    end
    else
    begin
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      s2.Add(stmp);
    end;
  end;

  result := s2.Text;
  s.Free;
  s2.Free;
end;

function isidentifier(const stmp1: string): boolean;
var
  i: integer;
  stmp: string;
  start: integer;
begin
  stmp := Trim(stmp1);
  Result := False;
  if stmp = '' then
    Exit;

  if stmp[1] = '$' then
  begin
    if Length(stmp) < 2 then
      Exit;
    start := 2;
  end
  else if (stmp[1] = '-') and (Length(stmp) >= 2) and (stmp[2] in ['1'..'9', '0']) then
  begin
    start := 2;
  end
  else
    start := 1;

  for i := start to length(stmp) do
    if not (stmp[i] in ['A'..'Z']) then
      if not (stmp[i] in ['a'..'z']) then
        if not (stmp[i] in ['1'..'9', '0', '_', '.', '/','[',']']) then
        begin
          if stmp[i] = '-' then
            if i > 1 then
              if stmp[i - 1] = '[' then
                Continue;
          Exit;
        end;
  Result := True;
end;

function ConvertNaive_Pass3(const sinp: string): string;
var
  s: TStringList;
  i, j: integer;
  stmp: string;
  s1, s2, s3: string;
  nspaces: integer;
  changed: boolean;
  beginhack: boolean;
  spacehack: boolean;

  function resolvedoubleassigment: string;
  var
    ii: integer;
    p: integer;
    stmp1, stmp2: string;
    praxi: string;
    elsehack: boolean;
    start_skip: integer;
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
      p := Pos('|:=', result);
    if p < 1 then
      p := Pos('&:=', result);
    if p < 1 then
      p := Pos('^:=', result);
    if p < 1 then
      p := Pos('>>:=', result);
    if p < 1 then
      p := Pos('<<:=', result);
    if p < 1 then
      exit;

    stmp1 := '';
    stmp2 := '';
    for ii := 1 to p - 1 do
      stmp1 := stmp1 + stmp[ii];
    start_skip := 3;
    if stmp[p + start_skip] = '=' then
      inc(start_skip);
    for ii := p + start_skip to length(result) - 1 do
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
        if praxi = '|' then
          praxi := 'or'
        else if praxi = '&' then
          praxi := 'and'
        else if praxi = '^' then
          praxi := 'xor'
        else if praxi = '<' then
          praxi := 'shl'
        else if praxi = '>' then
          praxi := 'shr';

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
    else if (firstword(stmp) = 'static') and (secondword(stmp) = 'void') then
    begin
      splitstring(stmp, s1, s2);
      splitstring(s2, s1, s3);
      if s3[length(s3)] in [';', ')'] then
      begin
        stmp := 'procedure ' + s3;
        if s3[length(s3)] = ')' then
          stmp := stmp + ';';
        changed := true;
      end;
    end
    else if (Pos('+:=', stmp) > 0) or (Pos('-:=', stmp) > 0) or (Pos('*:=', stmp) > 0) or (Pos('/:=', stmp) > 0) or
            (Pos('|:=', stmp) > 0)  or (Pos('&:=', stmp) > 0) or (Pos('^:=', stmp) > 0) or (Pos('>>:=', stmp) > 0) or (Pos('<<:=', stmp) > 0) then
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

function ConvertNaive_Pass4(const sinp: string): string;
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

function ConvertNaive_Pass5(const sinp: string): string;
begin
  result := sinp;

  result := StringReplace(result, ':=  ', ':= ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  :=', ' :=', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  then', ' then', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  do', ' do', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' if  ', ' if ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '()', '', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '~', ' not ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  shr ', ' shr ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' shr  ', ' shr ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  shl ', ' shl ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' shl  ', ' shl ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  and ', ' and ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' and  ', ' and ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, '  or ', ' or ', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, ' or  ', ' or ', [rfReplaceAll, rfIgnoreCase]);
end;

function ConvertNaive_Pass6(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, stmp2: string;
  p1, p2, p3: integer;
  nspaces, nspaces2: integer;
begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  s.Text := sinp;

  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    nspaces := 0;
    for j := 1 to length(stmp) do
    begin
      if stmp[j] = ' ' then
        inc(nspaces)
      else
        break;
    end;
    stmp := Trim(stmp);

    if i > 0 then
    begin
      stmp2 := s2.Strings[i - 1];
      nspaces2 := 0;
      for j := 1 to length(stmp2) do
      begin
        if stmp2[j] = ' ' then
          inc(nspaces2)
        else
          break;
      end;
      stmp2 := Trim(stmp2);
    end
    else
    begin
      nspaces2 := 0;
      stmp2 := '';
    end;

    if odd(nspaces) then
      Dec(nspaces);

    if stmp = 'end;' then
    begin
      if i > 0 then
      begin
        if nspaces2 >= 2 then
//          if nspaces >= nspaces2 then
          nspaces := nspaces2 - 2;
      end;
    end
    else if stmp2 = 'begin' then
    begin
      nspaces := nspaces2 + 2;
    end;

    stmp := Trim(stmp);
    for j := 1 to nspaces do
      stmp := ' ' + stmp;

    p1 := Pos(':=', stmp);
    if p1 > 0 then
    begin
      p2 := Pos('(', stmp);
      if (p2 > 0) and (CountChr(stmp, ')') = 1) and (CountChr(stmp, '(') = 1) then
      begin
        p3 := Pos(')', stmp);
        if (p3 < p2) and (p3 > p1) then
        begin
          stmp2 := stmp;
          stmp := '';
          for j := 1 to Length(stmp2) do
            if not (stmp2[j] in ['(', ')']) then
              stmp := stmp + stmp2[j];
        end;
      end;
    end;
    
    s2.Add(stmp);
  end;

  result := s2.Text;
  s.Free;
  s2.Free;
end;

function ConvertNaive_Pass7(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, token, rest: string;
  p1, p2, p3, start: integer;
  nspaces: integer;
begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  s.Text := sinp;

  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    nspaces := 0;
    for j := 1 to length(stmp) do
    begin
      if stmp[j] = ' ' then
        inc(nspaces)
      else
        break;
    end;
    stmp := Trim(stmp);

    if Pos('for ', stmp) = 0 then
    begin
      p1 := Pos('++', stmp);
      p2 := Pos('--', stmp);
      if (p1 > 0) xor (p2 > 0) then
      begin
        token := '';
        p3 := 0;
        if p1 > 0 then
          start := p1
        else
          start := p2;

        if start = 1 then
        begin
          for j := 3 to Length(stmp) do
          begin
            token := token + stmp[j];
            if stmp[j] = ';' then
            begin
              p3 := j + 1;
              Break;
            end;
          end;
        end
        else
        begin
          for j := 1 to start - 1 do
            token := token + stmp[j];
          p3 := start + 2;
        end;

        token := Trim(token);

        if (p3 > 0) and (token <> '') then
        begin
          if token[length(token)] = ';' then
            SetLength(token, length(token) - 1);
          token := Trim(token);
          if isidentifier(token) then
          begin
            if p1 > 0 then
              token := 'Inc(' + token + ');'
            else if p2 > 0 then
              token := 'Dec(' + token + ');';
            token := token + ' ';
            if Odd(Length(token)) then
              token := token + ' ';
            rest := '';
            for j := p3 to Length(stmp) do
              rest := rest + stmp[j];
            rest := Trim(rest);
            if rest <> '' then
              if rest[1] = ';' then
              begin
                rest[1] := ' ';
                rest := Trim(rest);
              end;
            stmp := token + rest;
          end;
        end;
      end;

    end;

    for j := 1 to nspaces do
      stmp := ' ' + stmp;

    s2.Add(stmp);
  end;

  result := s2.Text;
  s.Free;
  s2.Free;
end;

function ConvertNaive(const sinp: string): string;
begin
  result := ConvertNaive_Pass1(sinp);
  result := ConvertNaive_Pass2(result);
  result := ConvertNaive_Pass3(result);
  result := ConvertNaive_Pass4(result);
  result := ConvertNaive_Pass5(result);
  result := ConvertNaive_Pass6(result);
  result := ConvertNaive_Pass7(result);
end;


end.
