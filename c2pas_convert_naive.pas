//------------------------------------------------------------------------------
//
//  C2PAS
//  Convert C source code to Pascal code
//  Copyright (C) 2026 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://github.com/jval1972/C2PASDELPHI
//------------------------------------------------------------------------------

unit c2pas_convert_naive;

interface

function ConvertNaive(const sinp: string): string;

implementation

uses
  SysUtils, Classes, StrUtils, c2pas_memmgr, c2pas_utils;

procedure splitcomment(var sin: string; out scomment: string);
var
  p1, p2: integer;

  function _split1(const c1, c2: string): boolean;
  var
    ii: integer;
  begin
    p1 := Pos(c1, sin);
    if p1 > 0 then
    begin
      p2 := Pos(c2, sin);
      if p2 > 0 then
      begin
        scomment := '';
        for ii := p1 to p2 + Length(c2) - 1 do
        begin
          scomment := scomment + sin[ii];
          sin[ii] := ' ';
        end;
        Result := True;
        Exit;
      end;
    end;
    Result := False;
  end;

begin
  p1 := Pos('//', sin);
  if p1 > 0 then
  begin
    scomment := Copy(sin, p1, Length(sin) - p1 + 1);
    SetLength(sin, p1 - 1);
    Exit;
  end;

  // ********************************
//  scomment := '';
//  Exit;
  // ********************************
  if _split1('(*', '*)') then
    Exit;
  if _split1('{', '}') then
    Exit;
  if _split1('/*', '*/') then
    Exit;

  scomment := '';
end;

function isCtypename(const s: string): boolean;
var
  s1: string;
begin
  s1 := LowerCase(s);
  Result :=
    (s1 = 'char') or
    (s1 = 'byte') or
    (s1 = 'long') or
    (s1 = 'int') or
    (s1 = 'bool') or
    (s1 = 'double') or
    (s1 = 'float') or
    (s1 = 'fixed_t') or
    (s1 = 'int8_t') or
    (s1 = 'uint8_t') or
    (s1 = 'int16_t') or
    (s1 = 'uint16_t') or
    (s1 = 'int32_t') or
    (s1 = 'uint32_t') or
    (s1 = 'int64_t') or
    (s1 = 'uint64_t');
end;

function C2Pastype(const s: string): string;
var
  s1: string;
begin
  s1 := LowerCase(s);
  if s1 = 'char' then
    Result := 'Char'
  else if s1 = 'byte' then
    Result := 'Byte'
  else if s1 = 'long' then
    Result := 'LongInt'
  else if s1 = 'int' then
    Result := 'Integer'
  else if s1 = 'bool' then
    Result := 'Boolean'
  else if s1 = 'double' then
    Result := 'Double'
  else if s1 = 'float' then
    Result := 'Single'
  else if s1 = 'int64_t' then
    Result := 'int64'
  else
    Result := s;
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

function isintidentifier(const stmp1: string): boolean;
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
        if not (stmp[i] in ['1'..'9', '0', '_', '[',']']) then
        begin
          if stmp[i] = '.' then
            if i < Length(stmp) then
              if stmp[i + 1] in ['A'..'Z', 'a'..'z'] then
                Continue;
          if stmp[i] = '-' then
            if i > 1 then
              if stmp[i - 1] = '[' then
                Continue;
          Exit;
        end;
  Result := True;
end;

function issingleidentifier(const stmp1: string): boolean;
var
  i: integer;
  stmp: string;
begin
  stmp := Trim(stmp1);
  Result := False;
  if stmp = '' then
    Exit;

  if stmp[1] = '$' then
    Exit;

  for i := 1 to length(stmp) do
    if not (stmp[i] in ['A'..'Z']) then
      if not (stmp[i] in ['a'..'z']) then
        if not (stmp[i] in ['1'..'9', '0', '_']) then
          Exit;

  Result := True;
end;

function isinsingleparenthesis(const stmp1: string): boolean;
var
  stmp: string;
begin
  stmp := Trim(stmp1);
  Result := False;

  if CountChr(stmp, '(') = 1 then
    if CountChr(stmp, ')') = 1 then
      if stmp[1] = '(' then
        if stmp[Length(stmp)] = ')' then
          Result := True;
end;

function ConvertNaive_Pass1(const sinp: string): string;
begin
  Result := sinp;

  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #10, #13#10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #9, '  ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '=&', '=@', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '= &', '= @', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '=  &', '= @', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(&', '(@', [rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result, '} else ', '}'#13#10'  else ', [rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result, '|=', #254#250, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '| =', #254#250, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '^=', #254#251, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '^ =', #254#251, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&=', #254#252, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '& =', #254#252, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '>>=', #254#253, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '>> =', #254#253, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '<<=', #254#254, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '<< =', #254#254, [rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result, '==', #255#250, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '!=', #255#251, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '>=', #255#252, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '<=', #255#253, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '||', '|', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '^^', '^', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '^', ') xor (', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&&', '&', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '<<', ' shl ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '>>', ' shr ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&', ') and (', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '|', ') or (', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '=', ':=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ':=', ' := ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  :=', ' :=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ':=', ':= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '+ :=', '+:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '- :=', '-:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '* :=', '*:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '/ :=', '/:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #255#250, ' = ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  =', ' =', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '=  ', '= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #255#251, ' <> ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  <>', ' <>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '<>  ', '<> ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #255#252, ' >= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  >=', ' >=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '>=  ', '>= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #255#253, ' <= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  <=', ' <=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '<=  ', '<= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'return;', 'Exit;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '->', '.', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' case ', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' switch ', ' case ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{', ' begin ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '}', ' end;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '"', '''', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '/*', '(*', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '*/', '*)', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(void)', ';', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ';;', ';', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '!', ' not ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' )', ')', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '( ', '(', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' 0x', ' $', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(0x', '($', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[0x', '[$', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ',0x', ',$', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '#endif', '{$ENDIF}', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '#else', '{$ELSE}', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#250, '|:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#251, '^:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#252, '&:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#253, '>>:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#254, '<<:=', [rfReplaceAll, rfIgnoreCase]);
end;

function ConvertNaive_Pass2(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, stmp2, stmpt: string;
  nspaces: integer;
  scomment: string;
  changed: boolean;

  procedure check_array_const;
  var
    stmp1: string;
    t1, t2, t3: string;
    fw, sw: string;
    s_type: string;
    s_name: string;
    ii: integer;
    endpos, startpos: integer;
    cntitems: integer;
    data, line, restbegin, comment1: string;
    a_items: TStringList;
  begin
    if Pos('[]', stmp) = 0 then
      Exit;

    if Pos(':=', stmp) = 0 then
      Exit;

    stmp1 := stmp;
    fw := firstword(stmp1);
    if fw = 'static' then
    begin
      splitstring(stmp1, t1, t2);
      stmp1 := t2;
      fw := firstword(stmp1);
    end;

    if fw <> 'const' then
      Exit;

    splitstring(stmp1, t1, t2);
    stmp1 := t2;
    fw := firstword(stmp1);

    if not isCtypename(fw) then
      Exit;

    s_type := fw;

    splitstring(stmp1, t1, t2);
    stmp1 := t2;
    splitstring(t2, fw, sw);

    if (Pos('[]', fw) = Length(fw) - 1) or (sw = '[]') then
    else
      Exit;

    if sw <> '[]' then
      SetLength(fw, Length(fw) - 2);

    s_name := fw;

    if not issingleidentifier(s_name) then
      Exit;

    splitstring(stmp1, t1, t2);
    stmp1 := t2;
    if sw = '[]' then
    begin
      splitstring(stmp1, t1, t2);
      stmp1 := t2;
    end;

    fw := firstword(stmp1);
    if fw <> ':=' then
      Exit;

    sw := secondword(stmp1);
    startpos := i;
    restbegin := '';
    if Trim(sw) = '' then
      if i < s.Count - 1 then
        if Trim(s.Strings[i + 1]) = 'begin' then
        begin
          sw := 'begin';
          splitstring(Trim(s.Strings[i + 1]), t3, restbegin);
          startpos := i + 1;
        end;

    if sw <> 'begin' then
      Exit;

    endpos := -1;
    data := '';

    for ii := startpos to s.Count - 1 do
    begin
      if ii = startpos then
        line := Trim(restbegin)
      else
        line := Trim(s.Strings[ii]);
      splitcomment(line, comment1);
      line := Trim(line);
      if line = '' then
        Continue;

      if data <> '' then
        data := data + ' ';
      data := data + line;
      if lastword(line) = 'end' then
        SetLength(data, Length(data) - 3)
      else if lastword(line) = 'end;' then
        SetLength(data, Length(data) - 4)
      else
        Continue;

      endpos := ii;
      Break;
    end;

    if endpos = -1 then
      Exit;

    if Pos(',', data) = 0 then
      Exit;

    a_items := string2stringlist(data, ',');

    if a_items.Count < 2 then
    begin
      a_items.Free;
      Exit;
    end;

    for ii := a_items.Count - 1 downto 0 do
    begin
      a_items.Strings[ii] := Trim(a_items.Strings[ii]);
      // if a_items.Strings[ii] = '' then a_items.delete(ii);
    end;

    cntitems := a_items.Count;

    if s2.Count > 0 then
      if Trim(s2.Strings[s2.Count - 1]) <> '' then
        s2.Add('');

    s2.Add('const');
    s2.Add('  ' + s_name + ': array[0..' + IntToStr(cntitems - 1) + '] of ' + s_type + ' = (');

    line := '    ';
    for ii := 0 to a_items.Count - 1 do
    begin
      line := line + a_items.Strings[ii];
      if ii < a_items.Count - 1 then
        line := line + ', ';
      if Length(line) >= 78 then
      begin
        s2.Add(line);
        line := '    ';
      end;
    end;

    if Trim(line) <> '' then
      s2.Add(line);

    nspaces := 2;
    stmp := ');';
    stmp2 := stmp;

    for ii := i + 1 to endpos do
      s.Strings[ii] := '$SKIP_THIS_LINE';

    a_items.Free;
  end;

begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  s.Text := sinp;

  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    if stmp = '$SKIP_THIS_LINE' then
      Continue;

    nspaces := 0;
    for j := 1 to length(stmp) do
    begin
      if stmp[j] = ' ' then
        inc(nspaces)
      else
        break;
    end;

    stmp := Trim(stmp);

    stmp2 := stmp;

    splitcomment(stmp, scomment);
    stmp := Trim(stmp);

    check_array_const;
    
    if (lastword(stmp) = 'begin') and (Length(stmp) > 5) then
    begin
      changed := False;

      SetLength(stmp, Length(stmp) - 5);
      stmpt := Trim(stmp);
      if stmpt <> '' then
      begin
        if firstword(stmpt) = 'if' then
        begin
          if stmp[Length(stmp)] <> ' ' then
            stmp := stmp + ' ';
          stmp := stmp + 'then';
          changed := True;
        end;
        if firstword(stmpt) = 'for' then
        begin
          if stmp[Length(stmp)] <> ' ' then
            stmp := stmp + ' ';
          stmp := stmp + 'do';
          changed := True;
        end;
      end;

      stmp := stmp + ' ' + scomment;

      stmp := Trim(stmp);

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
        stmp2 := ' ' + stmp2;
      s2.Add(stmp2);
    end;
  end;

  Result := s2.Text;
  s.Free;
  s2.Free;
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
    Result := stmp;
    if length(Result) = 0 then
      Exit;
    if stmp[length(Result)] <> ';' then
      Exit;
    p := Pos('+:=', Result);
    if p < 1 then
      p := Pos('-:=', Result);
    if p < 1 then
      p := Pos('*:=', Result);
    if p < 1 then
      p := Pos('/:=', Result);
    if p < 1 then
      p := Pos('|:=', Result);
    if p < 1 then
      p := Pos('&:=', Result);
    if p < 1 then
      p := Pos('^:=', Result);
    if p < 1 then
      p := Pos('>>:=', Result);
    if p < 1 then
      p := Pos('<<:=', Result);
    if p < 1 then
      Exit;

    stmp1 := '';
    stmp2 := '';
    for ii := 1 to p - 1 do
      stmp1 := stmp1 + stmp[ii];
    start_skip := 3;
    if stmp[p + start_skip] = '=' then
      inc(start_skip);
    for ii := p + start_skip to length(Result) - 1 do
      stmp2 := stmp2 + Result[ii];

    stmp1 := trim(stmp1);
    stmp2 := trim(stmp2);

    elsehack := False;
    if Pos('else ', stmp1) > 0 then
    begin
      stmp1[1] := ' ';
      stmp1[2] := ' ';
      stmp1[3] := ' ';
      stmp1[4] := ' ';
      stmp1 := Trim(stmp1);
      elsehack := True;
    end;

    if isidentifier(stmp1) then
      if isidentifier(stmp2) or isinsingleparenthesis(stmp2) then
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

        Result := stmp1 + ' := ' + stmp1 + ' ' + praxi + ' ' + stmp2 + ';';
        if elsehack then
          Result := 'else ' + Result;
      end;
  end;

begin
  s := TStringList.Create;

  s.Text := sinp;

  nspaces := 0;
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    changed := False;
    beginhack := False;
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
      changed := True;
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
      changed := True;
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
      changed := True;
      beginhack := True;
    end;
    spacehack := False;
    if nspaces = 1 then
    begin
      spacehack := True;
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
          changed := True;
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
          changed := True;
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
          changed := True;
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
          changed := True;
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
          changed := True;
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
          changed := True;
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
          changed := True;
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
        changed := True;
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
          changed := True;
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
          changed := True;
        end;
    end
    else if (Pos('if (', stmp) = 1) or (Pos('if(', stmp) = 1) then
    begin
      if (stmp[length(stmp)] = ')') and (Pos(' then ', stmp) = 0) then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp := 'if ' + Trim(stmp) + ' then';
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := True;
      end;
    end
    else if (Pos('while (', stmp) = 1) or (Pos('while(', stmp) = 1) then
    begin
      if (stmp[length(stmp)] = ')') and (Pos(' do ', stmp) = 0) then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp[3] := ' ';
        stmp[4] := ' ';
        stmp[5] := ' ';
        stmp := 'while ' + Trim(stmp) + ' do';
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := True;
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
            changed := True;
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
        changed := True;
      end
      else if stmp[length(stmp)] = ')' then
      begin
        stmp[1] := ' ';
        stmp[2] := ' ';
        stmp[3] := ' ';
        stmp[4] := ' ';
        stmp := Trim(stmp);
        stmp := 'procedure ' + stmp + ';';
        changed := True;
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
        changed := True;
      end;
    end
    else if (Pos('+:=', stmp) > 0) or (Pos('-:=', stmp) > 0) or (Pos('*:=', stmp) > 0) or (Pos('/:=', stmp) > 0) or
            (Pos('|:=', stmp) > 0)  or (Pos('&:=', stmp) > 0) or (Pos('^:=', stmp) > 0) or (Pos('>>:=', stmp) > 0) or (Pos('<<:=', stmp) > 0) then
    begin
      stmp := resolvedoubleassigment;
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      changed := True;
    end
    else if (Pos('''', stmp) = 0) and (Pos('%', stmp) > 0) then
    begin
      stmp := StringReplace(stmp, '%', ' mod ', [rfReplaceAll, rfIgnoreCase]);
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      changed := True;
    end;

    if not changed then
      if spacehack then
      begin
        for j := 1 to nspaces do
          stmp := ' ' + stmp;
        changed := True;
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

  Result := s.Text;
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
        changed := True;
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
    changed := False;
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

  Result := s.Text;
  s.Free;
end;

function ConvertNaive_Pass5(const sinp: string): string;
begin
  Result := sinp;

  Result := StringReplace(Result, ':=  ', ':= ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  :=', ' :=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  then', ' then', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  do', ' do', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' if  ', ' if ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '()', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '~', ' not ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  shr ', ' shr ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' shr  ', ' shr ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  shl ', ' shl ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' shl  ', ' shl ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  and ', ' and ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' and  ', ' and ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '  or ', ' or ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' or  ', ' or ', [rfReplaceAll, rfIgnoreCase]);
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

  Result := s2.Text;
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

  function resolve_pointers: boolean;
  var
    ii, jj: integer;
    s2: string;
  begin
    Result := False;
    token := '';
    for ii := 1 to Length(stmp) - 3 do
    begin
      if (stmp[ii] = '(') and (stmp[ii + 1] = '*') then
      begin
        p3 := 0;
        for jj := ii + 2 to Length(stmp) do
        begin
          if stmp[jj] = ')' then
          begin
            p3 := jj - 1;
            break;
          end;
          token := token + stmp[jj];
        end;
        token := Trim(token);
        if (token <> '') and (p3 > 0) then
          if isidentifier(token) then
          begin
            s2 := '';
            for jj := 1 to ii do
              s2 := s2 + stmp[jj];
            for jj := 1 to Length(token) do
              s2 := s2 + token[jj];
            s2 := s2 + '^';
            for jj := p3 + 1 to Length(stmp) do
              s2 := s2 + stmp[jj];
            stmp := s2;
            Result := True;
            Exit;
          end;

      end;
    end;
  end;

  function resolve_pointers2: boolean;
  var
    ii, jj: integer;
    s2: string;
  begin
    Result := False;
    token := '';
    for ii := 1 to Length(stmp) - 5 do
    begin
      if (stmp[ii] = 'i') and (stmp[ii + 1] = 'f') and (stmp[ii + 2] = ' ') and  (stmp[ii + 3] = '*') then
      begin
        p3 := 0;
        for jj := ii + 4 to Length(stmp) do
        begin
          if stmp[jj] = ' ' then
          begin
            p3 := jj - 1;
            break;
          end;
          token := token + stmp[jj];
        end;
        token := Trim(token);
        if (token <> '') and (p3 > 0) then
          if isidentifier(token) then
          begin
            s2 := '';
            for jj := 1 to ii + 2 do
              s2 := s2 + stmp[jj];
            for jj := 1 to Length(token) do
              s2 := s2 + token[jj];
            s2 := s2 + '^';
            for jj := p3 + 1 to Length(stmp) do
              s2 := s2 + stmp[jj];
            stmp := s2;
            Result := True;
            Exit;
          end;

      end;
    end;
  end;

  procedure resolve_for;
  var
    first, last: string;
    sfor: string;
    s1, s2, s3, ftmp, ftmp2, ftmp3, ftmp4: string;
    pp1, pp2, pp3, pp4: integer;
    ipp1, ipp2, ipp3: integer;
    sdiv: Char;
    scounter, sfrom, sdir, sto: string;
    ii, cnt1, cnt2: integer;
  begin
    first := firstword(stmp);
    if first <> 'for' then
      Exit;

    last := lastword(stmp);
    if last <> 'do' then
      Exit;

    sfor := Copy(stmp, 4, Length(stmp) - 6);
    sfor := Trim(sfor);
    if sfor = '' then
      Exit;

    if isinsingleparenthesis(sfor) then
    begin
      Delete(sfor, 1, 1);
      SetLength(sfor, Length(sfor) - 1);
    end;

    if sfor = '' then
      Exit;

    splitstring(sfor, s1, ftmp, ';');
    if Pos(':=', s1) = 0 then
      Exit;

    splitstring(ftmp, s2, s3, ';');
    if Pos(';', s3) > 0 then
      Exit;
    if (Pos('++', s3) = 0) and (Pos('--', s3) = 0) then
      Exit;

    s1 := Trim(s1);
    s2 := Trim(s2);
    s3 := Trim(s3);

    if Pos('int ', s1) = 1 then
    begin
      splitstring(s1, ftmp, ftmp2);
      ftmp2 := Trim(ftmp2);
    end
    else
      ftmp2 := s1;

    splitstring(ftmp2, scounter, sfrom);

    scounter := Trim(scounter);
    if scounter = '' then
      Exit;

    if not isidentifier(scounter) then
      Exit;

    sfrom := Trim(sfrom);
    if sfrom = '' then
      Exit;

    if sfrom[1] = ':' then
      Delete(sfrom, 1, 1);
    if sfrom = '' then
      Exit;

    if sfrom[1] = '=' then
      Delete(sfrom, 1, 1);
    sfrom := Trim(sfrom);
    if sfrom = '' then
      Exit;

    if not isidentifier(sfrom) then
      Exit;

    pp1 := Pos('<', s2);
    pp2 := Pos('>', s2);
    pp3 := Pos('=', s2);

    if pp1 > 0 then
      ipp1 := 1
    else
      ipp1 := 0;
    if pp2 > 0 then
      ipp2 := 1
    else
      ipp2 := 0;
    if pp3 > 0 then
      ipp3 := 1
    else
      ipp3 := 0;

    if (ipp1 + ipp2 + ipp3 < 1) and (ipp1 + ipp2 + ipp3 > 2) then
      Exit;

    if (pp1 > 0) and (pp2 > 0) then
      Exit;

    if (pp1 > 0) and (pp3 > 0) then
      if pp3 <> pp1 + 1 then
        Exit;

    if (pp2 > 0) and (pp3 > 0) then
      if pp3 <> pp2 + 1 then
        Exit;

    if pp1 > 0 then
      splitstring(s2, ftmp, ftmp2, '<')
    else if pp2 > 0 then
      splitstring(s2, ftmp, ftmp2, '>')
    else
      splitstring(s2, ftmp, ftmp2, '=');

    if Trim(ftmp) <> scounter then
      Exit;

    ftmp2 := Trim(ftmp2);

    if ftmp2 = '' then
      Exit;

    if (pp3 > 0) and (ftmp2[1] = '=') then
    begin
      Delete(ftmp2, 1, 1);
      ftmp2 := Trim(ftmp2);
    end;

    if ftmp2 = '' then
      Exit;

    if not isintidentifier(ftmp2) then
    begin
      if CountChr(ftmp2, '/') + CountChr(ftmp2, '\') <> 1 then
        Exit;

      sdiv := #0;

      pp4 := Pos('/', ftmp2);
      if pp4 > 0 then
        sdiv := '/'
      else
      begin
        pp4 := Pos('\', ftmp2);
        if pp4 > 0 then
          sdiv := '\';
      end;
      if sdiv = #0 then
        Exit;

      cnt1 := 0;
      for ii := pp4 - 1 downto 1 do
        if ftmp2[ii] = ' ' then
          Inc(cnt1)
        else
          Break;
      for ii := pp4 + 1 to Length(ftmp2) do
        if ftmp2[ii] = ' ' then
          Inc(cnt1)
        else
          Break;

      cnt2 := 0;
      for ii := 1 to Length(ftmp2) do
        if ftmp2[ii] = ' ' then
          Inc(cnt2);

      if cnt1 <> cnt2 then
        Exit;

      splitstring(ftmp2, ftmp3, ftmp4, sdiv);
      if isintidentifier(ftmp3) and isintidentifier(ftmp4) then
        ftmp2 := '(' + ftmp3 + ' div ' + ftmp4 + ')';
    end;

    if (pp3 > 0) and (pp1 + pp2 > 0) then
      sto := ftmp2
    else if pp1 > 0 then
    begin
      if IsInteger(ftmp2) then
        sto := IntToStr(StrToInt(ftmp2) - 1) + ' {' + ftmp2 + ' - 1}'
      else
        sto := ftmp2 + ' - 1';
    end
    else if pp2 > 0 then
    begin
      if IsInteger(ftmp2) then
        sto := IntToStr(StrToInt(ftmp2) + 1) + ' {' + ftmp2 + ' + 1}'
      else
        sto := ftmp2 + ' + 1';
    end
    else
      sto := ftmp2;

    pp1 := Pos('++', s3);
    pp2 := Pos('--', s3);

    if (pp1 > 0) = (pp2 > 0) then
      Exit;

    sdir := '';
    if pp1 > 0 then
      sdir := 'to'
    else if pp2 > 0 then
      sdir := 'downto';
    if sdir = '' then
      Exit;

    if pp1 > 0 then
    begin
      s3[pp1] := ' ';
      s3[pp1 + 1] := ' ';
    end
    else
    begin
      s3[pp2] := ' ';
      s3[pp2 + 1] := ' ';
    end;

    s3 := Trim(s3);

    if s3 <> scounter then
      Exit;

    stmp := 'for ' + scounter + ' := ' + sfrom + ' ' + sdir + ' ' + sto + ' do';
  end;

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

    p1 := 0;
    p2 := 0;

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

    if (p1 = 0) and (p2 = 0) then
    begin
      while resolve_pointers do
      begin
      end;
      while resolve_pointers2 do
      begin
      end;
      resolve_for;
      if stmp = 'while 1 do' then
        stmp := 'while True do';
    end;

    for j := 1 to nspaces do
      stmp := ' ' + stmp;

    s2.Add(stmp);
  end;

  Result := s2.Text;
  s.Free;
  s2.Free;
end;

function ConvertNaive_Pass8(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, stmp2, stmp3, sident, sname: string;
  p1, p2, p3, len: integer;
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
      stmp2 := s.Strings[i - 1];
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

    if Pos('default:', stmp) = 1 then
    begin
      stmp[1] := ' ';
      stmp[2] := ' ';
      stmp[3] := ' ';
      stmp[4] := ' ';
      stmp[5] := 'e';
      stmp[6] := 'l';
      stmp[7] := 's';
      stmp[8] := 'e';
      stmp := Trim(stmp);
    end;

    if Pos('case ', stmp) = 1 then
    begin
      len := Length(stmp);
      if (stmp[len - 3] = ' ') and (stmp[len - 2] = ' ') and (stmp[len - 1] = 'o') and (stmp[len] = 'f') then
      begin
        stmp[len - 2] := 'o';
        stmp[len - 1] := 'f';
        SetLength(stmp, len - 1);
      end;
    end;

    if Pos('case ', stmp2) = 1 then
    begin
      len := Length(stmp2);
      if (stmp2[len - 2] = ' ') and (stmp2[len - 1] = 'o') and (stmp2[len] = 'f') then
        if stmp = 'begin' then
          Continue;
    end;

    if (CountChr(stmp, '(') = 1) and  (CountChr(stmp, ')') = 1) then
    begin
      p1 := Pos('(', stmp);
      p2 := Pos(')', stmp);
      if p1 < p2 then
      begin
        stmp3 := '';
        for j := p1 + 1 to p2 - 1 do
          stmp3 := stmp3 + stmp[j];

        stmp3 := StringReplace(stmp3, '   ', ' ', [rfReplaceAll, rfIgnoreCase]);
        stmp3 := StringReplace(stmp3, '  ', ' ', [rfReplaceAll, rfIgnoreCase]);

        if CountChr(stmp3, ' ') = 1 then
        begin
          splitstring(stmp3, sident, sname);
          if isCtypename(sident) and issingleidentifier(sname) then
          begin
            stmp3 := '';
            for j := 1 to p1 do
              stmp3 := stmp3 + stmp[j];
            stmp3 := stmp3 + sname + ': ' + C2Pastype(sident);
            for j := p2 to Length(stmp) do
              stmp3 := stmp3 + stmp[j];
            stmp := stmp3;
          end;
        end;
      end;
    end;


    stmp := Trim(stmp);
    for j := 1 to nspaces do
      stmp := ' ' + stmp;

    s2.Add(stmp);
  end;

  Result := s2.Text;
  s.Free;
  s2.Free;
end;

function ConvertNaive(const sinp: string): string;
begin
  Result := ConvertNaive_Pass1(sinp);
  Result := ConvertNaive_Pass2(Result);
  Result := ConvertNaive_Pass3(Result);
  Result := ConvertNaive_Pass4(Result);
  Result := ConvertNaive_Pass5(Result);
  Result := ConvertNaive_Pass6(Result);
  Result := ConvertNaive_Pass7(Result);
  Result := ConvertNaive_Pass8(Result);
end;


end.
