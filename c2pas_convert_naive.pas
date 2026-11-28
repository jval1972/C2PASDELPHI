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

var
  cnv_strings: TStringList;

type
  TStringObject = class(TObject)
    str: string;
    constructor Create(const astr: string); virtual;
  end;

constructor TStringObject.Create(const astr: string);
begin
  str := astr;
  Inherited Create;
end;

const
  STR_PREFIX = '___STR_VARIABLE___';
  STR_SKIP = '$SKIP_THIS_LINE';

function EncodeStrings(const inp: string): string;
var
  i: Integer;
  cnt: Integer;
  incomment: boolean;
  inlinecomment: boolean;
  instring: boolean;
  stoken: string;

  function _add_string: string;
  begin
    if stoken = '' then
      Exit;

    Inc(cnt);
    Result := '(' + STR_PREFIX + IntToStr(cnt) + ')';
    cnv_strings.AddObject(Result, TStringObject.Create(stoken));
    stoken := '';
  end;

begin
  cnv_strings := TStringList.Create;

  cnt := 0;
  Result := '';
  incomment := False;
  inlinecomment := False;
  instring := False;
  stoken := '';

  for i := 1 to Length(inp) - 1 do
  begin
    if inp[i] = '"' then
    begin
      if not (incomment or inlinecomment) then
      begin
        instring := not instring;
        if not instring then
          Result := Result + _add_string;
      end
      else
        Result := Result + '"';
    end
    else if inp[i] = #13 then
    begin
      if instring then
      begin
        instring := False;
        Result := Result + _add_string;
      end
      else if inlinecomment then
        inlinecomment := False;
      Result := Result + #13;
    end
    else if (inp[i] = '/') and (inp[i + 1] = '/') and not instring then
    begin
      inlinecomment := True;
      Result := Result + '/';
    end
    else if (inp[i] = '/') and (inp[i + 1] = '*') and not instring then
    begin
      incomment := True;
      Result := Result + '/';
    end
    else if (inp[i] = '*') and (inp[i + 1] = '/') and not instring then
    begin
      incomment := False;
      Result := Result + '*';
    end
    else if instring then
      stoken := stoken + inp[i]
    else
      Result := Result + inp[i];
  end;
end;

function DecodeStrings(const inp: string): string;
var
  i, j, len: Integer;
  stmp, stmp2: string;
  q, q2: string;
  skip, skip1, skip2: boolean;
begin
  Result := inp;
  for i := 0 to cnv_strings.Count - 1 do
  begin
    stmp := (cnv_strings.Objects[i] as TStringObject).str;

    stmp2 := '';
    len := Length(stmp);
    skip := False;
    skip1 := False;
    skip2 := False;
    for j := 1 to len do
    begin
      if skip then
      begin
        skip := False;
        Continue;
      end;
      if stmp[j] = '''' then
      begin
        if j = 1 then
        begin
          q := '';
          skip1 := True;
        end
        else
          q := '''';
        if j = len then
        begin
          skip2 := True;
          q2 := ''
        end
        else
          q2 := '''';
        stmp2 := stmp2 + q + '$27' + q2;
        Continue;
      end
      else if (stmp[j] = '\') and (j < len) then
      begin
        if j = 1 then
          q := ''
        else
          q := '''';
        if j = len - 1 then
          q2 := ''
        else
          q2 := '''';
        skip := True;
        if stmp[j + 1] = 'a' then
          stmp2 := stmp2 + q + '#7' + q2
        else if stmp[j + 1] = 'b' then
          stmp2 := stmp2 + q + '#8' + q2
        else if stmp[j + 1] = 'e' then
          stmp2 := stmp2 + q + '$1B' + q2
        else if stmp[j + 1] = 'e' then
          stmp2 := stmp2 + q + '$C' + q2
        else if stmp[j + 1] = 'n' then
          stmp2 := stmp2 + q + '#10' + q2
        else if stmp[j + 1] = 'r' then
          stmp2 := stmp2 + q + '#13' + q2
        else if stmp[j + 1] = 't' then
          stmp2 := stmp2 + q + '#9' + q2
        else if stmp[j + 1] = 'v' then
          stmp2 := stmp2 + q + '$B' + q2
        else if stmp[j + 1] = '\' then
          stmp2 := stmp2 + '\'
        else if stmp[j + 1] = '''' then
          stmp2 := stmp2 + q + '$27' + q2
        else if stmp[j + 1] = '"' then
          stmp2 := stmp2 + '"'
        else if stmp[j + 1] = '?' then
          stmp2 := stmp2 + '?'
        else
        begin
          stmp2 := stmp2 + '\';
          skip := False;
        end;
        if skip then
          Continue;
      end
      else
        stmp2 := stmp2 + stmp[j];
      if j = 1 then
        stmp2 := '''' + stmp2
      else if j = len then
        stmp2 := stmp2 + '''';
    end;

    stmp2 := StringReplace(stmp2, '''''', '', [rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result, cnv_strings.Strings[i], stmp2, [rfReplaceAll, rfIgnoreCase]);
    (cnv_strings.Objects[i] as TStringObject).Free;
  end;
  cnv_strings.Free;
end;

function C2Pastype(const s: string): string;
var
  s1: string;
begin
  s1 := LowerCase(s);
  if s1 = 'char' then
    Result := 'Char'
  else if (s1 = '^char') or (s1 = 'char*') then
    Result := 'PChar'
  else if s1 = 'byte' then
    Result := 'Byte'
  else if (s1 = '^byte') or (s1 = 'byte*') then
    Result := 'PByte'
  else if s1 = 'long' then
    Result := 'LongInt'
  else if (s1 = '^long') or (s1 = 'long*') then
    Result := 'PLongInt'
  else if s1 = 'int' then
    Result := 'Integer'
  else if (s1 = '^int') or (s1 = 'int*') then
    Result := 'PInteger'
  else if s1 = 'short' then
    Result := 'SmallInt'
  else if (s1 = '^short') or (s1 = 'short*') then
    Result := 'PSmallInt'
  else if s1 = 'bool' then
    Result := 'Boolean'
  else if (s1 = '^bool') or (s1 = 'bool*') then
    Result := 'Boolean'
  else if s1 = 'double' then
    Result := 'Double'
  else if (s1 = '^double') or (s1 = 'double*') then
    Result := 'PDouble'
  else if s1 = 'float' then
    Result := 'Single'
  else if (s1 = '^float') or (s1 = 'float*') then
    Result := 'PSingle'
  else if s1 = 'int64_t' then
    Result := 'int64'
  else if (s1 = '^int64_t') or (s1 = 'int64_t*') then
    Result := 'Pint64'
  else if s1 = 'void*' then
    Result := 'Pointer'
  else if (s1 = 'file*') or (s1 = '^file') or (s1 = 'FILE') then
    Result := 'file'
  else
    Result := s;
end;

procedure Resolve2WordCTypes(const sL: TStringList);
var
  s0, s1, s2: string;
  ii: Integer;
begin
  if sL.Count < 2 then
    Exit;

  for ii := 0 to sl.Count - 2 do
  begin
    s0 := LowerCase(sL.Strings[ii]);
    s1 := LowerCase(sL.Strings[ii + 1]);
    if ii < sl.Count - 2 then
      s2 := LowerCase(sL.Strings[ii + 2])
    else
      s2 := '';

    if (s0 = 'long') and (s1 = 'long') then
    begin
      sL.Delete(ii);
      sL.Strings[ii] := 'int64';
      Resolve2WordCTypes(sL);
      Exit;
    end
    else if (s0 = 'longint') and (s1 = 'longint') then
    begin
      sL.Delete(ii);
      sL.Strings[ii] := 'int64';
      Resolve2WordCTypes(sL);
      Exit;
    end
    else if s0 = 'unsigned' then
    begin
      if (s1 = 'long') and (s2 = 'long') then
      begin
        sL.Delete(ii);
        sL.Delete(ii);
        sL.Strings[ii] := 'UInt64';
        Resolve2WordCTypes(sL);
        Exit;
      end
      else if (s1 = 'byte') or (s1 = 'char') or (s1 = 'word') or (s1 = 'longword') then
      begin
        sL.Delete(ii);
        Resolve2WordCTypes(sL);
        Exit;
      end
      else if (s1 = 'short') or (s1 = 'smallint') or (s1 = 'word') then
      begin
        sL.Delete(ii);
        if (sL.Strings[ii] = 'int') or (sL.Strings[ii] = 'integer') then
          if sL.Count > 1 then
            sL.Delete(ii);
        sl.Strings[ii] := 'Word';
        Resolve2WordCTypes(sL);
        Exit;
      end
      else if (s1 = 'int') or (s1 = 'integer')  or (s1 = 'long') or (s1 = 'longint') then
      begin
        sL.Delete(ii);
        sl.Strings[ii] := 'LongWord';
        Resolve2WordCTypes(sL);
        Exit;
      end
      else if s1 = 'int64' then
      begin
        sL.Delete(ii);
        sL.Strings[ii] := 'UInt64';
        Resolve2WordCTypes(sL);
        Exit;
      end
      else
      begin
        sL.Delete(ii);
        Resolve2WordCTypes(sL);
        Exit;
      end;
    end
    else if s0 = 'signed' then
    begin
      if (s1 = 'byte') or (s1 = 'char') then
      begin
        sL.Delete(ii);
        sL.Strings[ii] := 'ShortInt';
        Resolve2WordCTypes(sL);
        Exit;
      end
      else
      begin
        sL.Delete(ii);
        Resolve2WordCTypes(sL);
        Exit;
      end;
    end;
  end;
end;

function MakeFuncParams(const parms: string): string;
var
  sl: TStringList;
  i, p1: Integer;
  stmp, t1, t2: string;

  function _make_param(const parm: string): string;
  var
    s2: TStringList;
    isconst: Boolean;
    isstruct: Boolean;
    idx, ii: Integer;
    rest: string;
  begin
    Result := Trim(parm);

    s2 := string2stringlist(parm, ' ');
    removeblanclines(s2);
    if s2.Count < 2 then
    begin
      s2.Free;
      Exit;
    end;

    isconst := False;
    isstruct := False;

    idx := s2.IndexOf('const');
    if idx >= 0 then
    begin
      isconst := True;
      if idx >= s2.Count - 2 then
      begin
        s2.Free;
        Exit;
      end;
      s2.Delete(idx);
    end;

    idx := s2.IndexOf('struct');
    if idx >= 0 then
    begin
      isstruct := True;
      if idx >= s2.Count - 2 then
      begin
        s2.Free;
        Exit;
      end;
      s2.Delete(idx);
    end;

    if s2.Count <> 2 then
    begin
      Resolve2WordCTypes(s2);
      if s2.Count <> 2 then
      begin
        s2.Free;
        Exit;
      end;
    end;

    Result := '';
    if isconst then
      Result := Result + 'const ';
    if isstruct then
      Result := Result + '(*struct*)';

    rest := removeallspaces(s2.Strings[0] + s2.Strings[1]);
    if Pos1('void*', rest) then
    begin
      s2.Strings[0] := 'Pointer';
      rest[1] := ' ';
      rest[2] := ' ';
      rest[3] := ' ';
      rest[4] := ' ';
      rest[5] := ' ';

      s2.Strings[1] := Trim(rest);
    end;

    p1 := CharPos('*', rest);
    if p1 > 0 then
    begin
      t1 := '';
      for ii := 1 to p1 - 1 do
        t1 := t1 + rest[ii];
      t2 := '';
      for ii := p1 to Length(rest) do
        t2 := t2 + rest[ii];
      while CharPos('*', t2) = 1 do
      begin
        t1 := '^' + t1;
        Delete(t2, 1, 1);
      end;
      while CharPos('*', t1) = Length(t1) do
      begin
        t1 := '^' + t1;
        Delete(t1, 1, 1);
      end;
      t1 := Trim(t1);
      t2 := Trim(t2);
      if (t1 = '') or (t2 = '') then
      begin
        s2.Free;
        Exit;
      end;
      s2.Strings[0] := t1;
      s2.Strings[1] := t2;
    end;

    rest := s2.Strings[1];

    for ii := 1 to Length(rest) do
    begin
      if rest[ii] = '*' then
        rest[ii] := '^'
      else
        Break;
      s2.Strings[1] := rest;
    end;

    Result := Result + s2.Strings[1] + ': ' + C2Pastype(s2.Strings[0]);

    s2.Free;
  end;

begin
  Result := Trim(parms);
  stmp := Trim(parms);

  if stmp = '' then
  begin
    Result := '';
    Exit;
  end;

  if stmp = '()' then
  begin
    Result := '';
    Exit;
  end;

  if stmp[1] = '(' then
    Delete(stmp, 1, 1);

  if stmp[Length(stmp)] = ')' then
    SetLength(stmp, Length(stmp) - 1);

  sl := string2stringlist(stmp, ',');
  stmp := '';
  for i := 0 to sl.Count - 1 do
  begin
    stmp := stmp + _make_param(sl.Strings[i]);
    if i < sl.Count - 1 then
      stmp := stmp + '; ';
  end;

  sl.Free;

  Result := Trim(stmp);
end;

procedure splitcomment(var sin: string; out scomment: string);
var
  p1, p2: integer;

  function _split1(const c1, c2: string): boolean;
  var
    ii: integer;
    dels: TDNumberList;
    p: Integer;
  begin
    dels := TDNumberList.Create;

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
          dels.Add(ii);
        end;
        Result := True;
        for ii := dels.Count - 1 downto 0 do
          Delete(sin, dels.Numbers[ii], 1);
        p := dels.Numbers[0];
        if (p > 2) and (p < Length(sin)) then
        begin
          if (sin[p - 2] = ' ') and (sin[p - 1] = ' ') then
            Delete(sin, p - 1, 1)
          else if (sin[p - 1] = ' ') and (sin[p] = ' ') then
            Delete(sin, p, 1)
          else if (sin[p + 1] = ' ') and (sin[p] = ' ') then
            Delete(sin, p + 1, 1);
        end;
        dels.Free;
        Exit;
      end;
    end;
    Result := False;
    dels.Free;
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

procedure joincomment(var sin: string; const scomment: string);
begin
  while sin <> '' do
  begin
    if sin[Length(sin)] = ' ' then
      SetLength(sin, Length(sin) - 1)
    else
      Break;
  end;

  if sin = '' then
    sin := scomment
  else if scomment <> '' then
    sin := sin + ' ' + scomment;
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
    (s1 = 'short') or
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
    (s1 = 'uint64_t') or
    (s1 = 'file');
end;

function isPastypename(const s: string): boolean;
var
  s1: string;
begin
  s1 := LowerCase(s);
  Result :=
    (s1 = 'char') or
    (s1 = 'byte') or
    (s1 = 'longint') or
    (s1 = 'integer') or
    (s1 = 'word') or
    (s1 = 'smallint') or
    (s1 = 'shortint') or
    (s1 = 'boolean') or
    (s1 = 'double') or
    (s1 = 'single') or
    (s1 = 'int64') or
    (s1 = 'file');
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
    Result := IsInteger(stmp);
    Exit;
  end
  else if (stmp[1] = '-') and (Length(stmp) >= 2) and (stmp[2] in ['1'..'9', '0']) then
  begin
    Result := IsNumeric(stmp);
    Exit;
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

function issinglevariable(const stmp1: string): boolean;
var
  i: integer;
  stmp: string;
begin
  stmp := Trim(stmp1);
  Result := False;
  if stmp = '' then
    Exit;

  if stmp[1] in ['1'..'9', '0'] then
    Exit;

  for i := 1 to length(stmp) do
    if not (stmp[i] in ['A'..'Z']) then
      if not (stmp[i] in ['a'..'z']) then
        if not (stmp[i] in ['1'..'9', '0', '_']) then
          Exit;

  Result := True;
end;

function isstructidentifier(const stmp1: string): boolean;
var
  i: integer;
  stmp: string;
begin
  stmp := Trim(stmp1);
  stmp := StringReplace(stmp, '->', '.', [rfReplaceAll, rfIgnoreCase]);

  Result := False;
  if stmp = '' then
    Exit;

  if stmp[1] = '$' then
    Exit;

  for i := 1 to length(stmp) do
    if not (stmp[i] in ['A'..'Z']) then
      if not (stmp[i] in ['a'..'z']) then
        if not (stmp[i] in ['1'..'9', '0', '_', '.', '[', ']']) then
          Exit;

  if Pos('..', stmp) > 0 then
    Exit;
  if Pos('[]', stmp) > 0 then
    Exit;
  if CountChr(stmp, '[') <> CountChr(stmp, ']') then
    Exit;
  if CharPos('[', stmp) > 0 then
    if CharPos(']', stmp) < CharPos('[', stmp) then
      Exit;
  if Pos1('.', stmp) then
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

function isinpascalquote(const stmp1: string): boolean;
var
  stmp: string;
begin
  stmp := Trim(stmp1);
  Result := False;

  if CountChr(stmp, '''') = 2 then
    if stmp[1] = '''' then
      if stmp[Length(stmp)] = '''' then
        Result := True;
end;

function isinCquote(const stmp1: string): boolean;
var
  stmp: string;
begin
  stmp := Trim(stmp1);
  Result := False;

  if CountChr(stmp, '"') = 2 then
    if stmp[1] = '"' then
      if stmp[Length(stmp)] = '"' then
        Result := True;
end;

function replace_else(const sinp: string): string;
var
  s1, s2: string;
  i, j: Integer;
begin
  Result := sinp;

  for i := 10 downto 0 do
  begin
    s1 := #13#10;
    for j := 0 to i do
      s1 := s1 + #9;
    s1 := s1 + '} else ';

    s2 := #13#10;
    for j := 0 to i do
      s2 := s2 + '  ';
    s2 := s2 + 'end';
    s2 := s2 + #13#10;
    for j := 0 to i do
      s2 := s2 + '  ';
    s2 := s2 + 'else ';

    Result := StringReplace(Result, s1, s2, [rfReplaceAll, rfIgnoreCase]);
  end;

  for i := 20 downto 0 do
  begin
    s1 := #13#10;
    for j := 0 to i do
      s1 := s1 + ' ';
    s1 := s1 + '} else ';

    s2 := #13#10;
    for j := 0 to i do
      s2 := s2 + ' ';
    s2 := s2 + 'end';
    s2 := s2 + #13#10;
    for j := 0 to i do
      s2 := s2 + ' ';
    s2 := s2 + 'else ';

    Result := StringReplace(Result, s1, s2, [rfReplaceAll, rfIgnoreCase]);
  end;

end;

function MakeBrackets(const sinp: string): string;
var
  s, s2: TStringList;
  stmp, stmp2: string;
  i, p: Integer;
begin
  s := TStringList.Create;
  s.Text := sinp;
  s2 := TStringList.Create;

  for i := 0 to s.Count - 1 do
  begin
    stmp := Trim(s.Strings[i]);

    if stmp = STR_SKIP then
      Continue;

    if i < s.Count - 1 then
      if Pos1('if ', stmp) or Pos1('for ', stmp) then
        if CharPos('{', stmp) <= 0 then
        begin
          stmp2 := Trim(s.Strings[i + 1]);
          if stmp2 = '{' then
          begin
            s2.Add(s.Strings[i] + ' {');
            s.Strings[i + 1] := STR_SKIP;
            Continue;
          end;
          if Pos1('{', stmp2) then
          begin
            p := Pos('{', s.Strings[i + 1]);
            if p > 0 then
            begin
              stmp2 := s.Strings[i + 1];
              Delete(stmp2, p, 1);
              s.Strings[i + 1] := stmp2;
            end;
            s2.Add(s.Strings[i] + ' {');
            Continue;
          end;
        end;

    s2.Add(s.Strings[i]);
  end;

  s.Free;
  Result := s2.Text;
  s2.Free;
end;

function ResolveSingleElseIfs(const sinp: string): string;
var
  s, s2: TStringList;
  i, j, p: Integer;
  stmp1, stmp2, stmp3: string;
  scomment1, scomment2: string;
  nspaces, nspaces2: Integer;
begin
  s := TStringList.Create;
  s.Text := sinp;
  s2 := TStringList.Create;

  for i := 0 to s.Count - 1 do
  begin
    stmp1 := s.Strings[i];
    nspaces := 0;
    for j := 1 to Length(stmp1) do
    begin
      if stmp1[j] = ' ' then
        Inc(nspaces)
      else
        Break;
    end;

    stmp1 := Trim(stmp1);

    if (i < s.Count - 3) and (Pos1('if ', stmp1) or Pos1('else if ', stmp1) or Pos1('if(', stmp1) or Pos1('else if(', stmp1)) then
      if (CharPos('{', stmp1) = 0) and (CharPos('}', stmp1) = 0) then
      begin
        stmp2 := s.Strings[i + 1];
        nspaces2 := 0;
        for j := 1 to Length(stmp2) do
        begin
          if stmp2[j] = ' ' then
            Inc(nspaces2)
          else
            Break;
        end;
        stmp2 := Trim(stmp2);
        if (CharPos('{', stmp2) = 0) and (CharPos('}', stmp2) = 0) and (Pos('else', stmp2) = 0) then
        begin
          stmp3 := Trim(s.Strings[i + 2]);
          if Pos1('else if ', stmp3) or Pos1('else if(', stmp3) or Pos1('else ', stmp3) or Pos1('else(', stmp3) then
          begin
            splitcomment(stmp2, scomment2);
            stmp2 := Trim(stmp2);
            if CharPos(';', stmp2) = Length(stmp2) then
            begin
              splitcomment(stmp1, scomment1);
              stmp1 := stmp1 + ' {';
              joincomment(stmp1, scomment1);
              stmp2 := stmp2 + #255;
              joincomment(stmp2, scomment2);
              for j := 1 to nspaces2 do
                stmp2 := ' ' + stmp2;
              s.Strings[i + 1] := stmp2;
            end;
          end;
        end;
      end;

    for j := 1 to nspaces do
      stmp1 := ' ' + stmp1;
    s2.Add(stmp1);
  end;

  s.Clear;
  for i := 0 to s2.Count - 1 do
  begin
    stmp1 := s2.Strings[i];
    p := CharPos(#255, stmp1);
    if p > 0 then
    begin
      Delete(stmp1, p, 1);
      s.Add(stmp1);
      s.Add('}');
    end
    else
      s.Add(stmp1);
  end;
  Result := s.Text;
  s.Free;
  s2.Free;
end;

function ConvertNaive_Pass1(const sinp: string): string;
begin
  Result := EncodeStrings(sinp);
  Result := MakeBrackets(Result);

  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #10, #13#10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #9, '  ', [rfReplaceAll, rfIgnoreCase]);
  Result := replace_else(Result);
  Result := ResolveSingleElseIfs(Result);
  Result := StringReplace(Result, '(void **)&', '(void **)@', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(void *)&', '(void *)@', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(int *)&', '(int *)@', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(byte *)&', '(byte *)@', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(char *)&', '(char *)@', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ',  &', ',  @', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ', &', ', @', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ',&', ',@', [rfReplaceAll, rfIgnoreCase]);


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
  Result := StringReplace(Result, '{'#13#10, ' begin'#13#10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{', ' begin'#13#10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '}'#13#10, ' end;'#13#10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '}', ' end;'#13#10, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '/*', '(*', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '*/', '*)', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(void)', '();', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ';;', ';', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '!', ' not ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' )', ')', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '( ', '(', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' 0x', ' $', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(0x', '($', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[0x', '[$', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ',0x', ',$', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '~0x', '~$', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '#endif', '{$ENDIF}', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '#else', '{$ELSE}', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#250, '|:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#251, '^:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#252, '&:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#253, '>>:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #254#254, '<<:=', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' true;', ' True;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' false;', ' False;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' continue;', ' Continue;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #13#10'continue;', #13#10'Continue;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' break;', ' Break;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #13#10'break;', #13#10'Break;', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' sizeof(', ' SizeOf(', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(sizeof(', '(SizeOf(', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' NULL ', ' nil ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' NULL)', ' nil)', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ' NULL;', ' nil;', [rfReplaceAll, rfIgnoreCase]);
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

    if CharPos(',', data) = 0 then
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
      s.Strings[ii] := STR_SKIP;

    a_items.Free;
  end;

begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  s.Text := sinp;

  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    if stmp = STR_SKIP then
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

      joincomment(stmp, scomment);

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
  stmp, scomment: string;
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
    if Pos1('PUBLIC ', Trim(stmp)) then
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
    else if Pos1('PRIVATE ', Trim(stmp)) then
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
    if Pos1('int ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('uint32 ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('word ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('longint ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('FILE ', stmp) then
    begin
      if (CharPos('*', stmp) > 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('long long ', stmp) or Pos1('int64 ', stmp) or Pos1('int64_t ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('long ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('#ifdef ', stmp) then
    begin
      if (CharPos('<', stmp) < 1) and (CharPos('>', stmp) < 1) and (CharPos('=', stmp) < 1) then
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
    else if Pos1('fixed_t ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('bool ', stmp) then
    begin
      if (CharPos('*', stmp) < 1) and (CharPos('[', stmp) < 1) then
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
    else if Pos1('if (', stmp) or Pos1('if(', stmp) then
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
    else if Pos1('while (', stmp) or Pos1('while(', stmp) then
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
    else if Pos1('else if (', stmp) or Pos1('else if(', stmp) then
    begin
      if i > 0 then
        if Trim(s.Strings[i - 1]) = 'end;' then
        begin
          s.Strings[i - 1] := stringofchar(' ', nspaces) + 'end';
        end;

      splitcomment(stmp, scomment);
      stmp := Trim(stmp);
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

      joincomment(stmp, scomment);
    end
    else if Pos1('void ', stmp) then
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
    else if (CharPos('''', stmp) = 0) and (CharPos('%', stmp) > 0) then
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
  scomment: string;

  procedure _try_function;
  var
    stmp0: string;
    sl: TStringList;
    isforward, isstatic, isconst, isinline, isstruct, ispointer: Boolean;
    pidx: Integer;
    ii, idx: Integer;
    p1, p2: Integer;
    s_ret: string;
    s_rest: string;
    s_name: string;
    s_params: string;
  begin
    stmp0 := Trim(stmp);

    if Length(stmp0) < 6 then
      Exit;

    isforward := False;
    if stmp0[Length(stmp0)] = ';' then
    begin
      SetLength(stmp0, Length(stmp0) - 1);
      stmp0 := Trim(stmp0);
      if Length(stmp0) < 6 then
        Exit;

      isforward := True;
      if i < s.Count - 1 then
        if (Trim(s.Strings[i + 1]) = 'begin') or Pos1('begin ', s.Strings[i + 1]) then
          isforward := False;

      if isforward then
        if i < s.Count - 2 then
          if (Trim(s.Strings[i + 1]) = '') or Pos1('//', Trim(s.Strings[i + 1])) or Pos1('(*', Trim(s.Strings[i + 1])) then
            if (Trim(s.Strings[i + 2]) = 'begin') or Pos1('begin ', s.Strings[i + 2]) then
              isforward := False;
    end;

    if stmp0[Length(stmp0)] <> ')' then
      Exit;

    if (CountChr(stmp0, '(') <> 1) or (CountChr(stmp0, ')') <> 1) or
      (CharPos('.', stmp0) > 0) or (CharPos('?', stmp0) > 0) or
      (CharPos(':', stmp0) > 0) or (CharPos('=', stmp0) > 0) or
      (CharPos('<', stmp0) > 0) or (CharPos('>', stmp0) > 0) or
      (CharPos('$', stmp0) > 0) or (CharPos('/', stmp0) > 0) or
      (CharPos('+', stmp0) > 0) or (CharPos('-', stmp0) > 0) or
      (CharPos('.', stmp0) > 0) or (CharPos('@', stmp0) > 0) or
      (CharPos(';', stmp0) > 0) or (CharPos('&', stmp0) > 0) then
      Exit;

    if Pos1('return', stmp0) then
      Exit;
      
    sl := string2stringlist(stmp0, ' ');
    removeblanclines(sl);

    pidx := -1;
    for ii := 0 to sl.Count - 1 do
      if CharPos('(', sl.Strings[ii]) > 0 then
      begin
        pidx := ii;
        Break;
      end;

    if sl.Count < 2 then
    begin
      sl.Free;
      Exit;
    end;

    isstatic := False;
    isconst := False;
    isstruct := False;
    isinline := False;

    idx := sl.IndexOf('static');
    if idx < pidx then
    begin
      if idx > 2 then
      begin
        sl.Free;
        Exit;
      end;
      if (idx >= 0) and (idx < pidx) then
        isstatic := True;
    end;

    idx := sl.IndexOf('const');
    if idx < pidx then
    begin
      if idx > 2 then
      begin
        sl.Free;
        Exit;
      end;
      if (idx >= 0) and (idx < pidx) then
        isconst := True;
    end;

    idx := sl.IndexOf('struct');
    if idx < pidx then
    begin
      if (idx > 0) and (idx < Ord(isstatic) + Ord(isconst) + Ord(isinline)) then
      begin
        sl.Free;
        Exit;
      end;
      if (idx >= 0) and (idx < pidx) then
        isstruct := True;
    end;

    idx := sl.IndexOf('inline');
    if idx > 2 then
    begin
      sl.Free;
      Exit;
    end;
    if (idx >= 0) and (idx < pidx) then
      isinline := True;

    if isstatic then
      sl.Delete(sl.IndexOf('static'));
    if isconst then
      sl.Delete(sl.IndexOf('const'));
    if isstruct then
      sl.Delete(sl.IndexOf('struct'));
    if isinline then
      sl.Delete(sl.IndexOf('inline'));

    if sl.Count < 2 then
    begin
      sl.Free;
      Exit;
    end;

    ispointer := False;

    Resolve2WordCTypes(sl); // SOS

    s_ret := Trim(sl.Strings[0]);
    if s_ret = '' then
    begin
      sl.Free;
      Exit;
    end;

    if s_ret[Length(s_ret)] = '*' then
    begin
      SetLength(s_ret, Length(s_ret) - 1);
      s_ret := Trim(sl.Strings[0]);
      if s_ret = '' then
      begin
        sl.Free;
        Exit;
      end;
      ispointer := True;
    end;

    if not issinglevariable(s_ret) then
    begin
      sl.Free;
      Exit;
    end;

    s_rest := '';
    for ii := 1 to sl.Count - 1 do
    begin
      s_rest := s_rest + Trim(sl.Strings[ii]);
      if ii <> sl.Count - 1 then
        s_rest := s_rest + ' ';
    end;

    s_rest := Trim(s_rest);
    p1 := CharPos('(', s_rest);
    p2 := CharPos(')', s_rest);

    if (p1 < 0) or (p1 < 0) or (p1 > p2) or (p2 <> Length(s_rest)) then
    begin
      sl.Free;
      Exit;
    end;

    s_name := '';
    for ii := 1 to p1 - 1 do
      s_name := s_name + s_rest[ii];

    s_name := Trim(s_name);
    if s_name = '' then
    begin
      sl.Free;
      Exit;
    end;

    if s_name[1] = '*' then
    begin
      Delete(s_name, 1, 1);
      s_name := Trim(s_name);
      if ispointer or (s_name = '') then
      begin
        sl.Free;
        Exit;
      end;
      ispointer := True;
    end;

    if not issinglevariable(s_name) then
    begin
      sl.Free;
      Exit;
    end;

    s_params := '';
    for ii := p1 + 1 to p2 - 1 do
      s_params := s_params + s_rest[ii];

    s_params := MakeFuncParams(s_params);

    if ((s_ret = 'void') or (s_ret = 'procedure')) and not ispointer then
    begin
      stmp := 'procedure ' + Trim(s_name) + '(' + s_params + ');'
    end
    else
    begin
      stmp := 'function ' + Trim(s_name) + '(' + s_params + '): ' + decide(ispointer, '^', '') + C2Pastype(s_ret) + ';';
    end;

    if isforward then
      stmp := stmp + ' forward;';

    s_rest := '';
    if isinline then
      s_rest := s_rest + 'inline ';
    if isstatic then
      s_rest := s_rest + 'static ';
    if isconst then
      s_rest := s_rest + 'const ';

    s_rest := Trim(s_rest);
    if s_rest <> '' then
      stmp := stmp + ' // ' + s_rest;

    sl.Free;
    changed := True;
  end;

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
      p1 := CharPos('(', stmp);
      p2 := CharPos(')', stmp);
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

    splitcomment(stmp, scomment);

    stmp := Trim(stmp);
    if Pos1('if ', stmp) and (Pos(' then', stmp) = Length(stmp) - 4) then
      removeparenthesis
    else if Pos1('while ', stmp) and (Pos(' do', stmp) = Length(stmp) - 2) then
      removeparenthesis
    else if Pos1('else if ', stmp) and (Pos(' then', stmp) = Length(stmp) - 4) then
      removeparenthesis
    else if Pos1('case ', stmp) and (CharPos(')', stmp) = Length(stmp)) then
    begin
      removeparenthesis;
      stmp := stmp + ' of'
    end
    else
      _try_function;

    if changed then
    begin
      joincomment(stmp, scomment);
      s.Strings[i] := stmp;
    end;
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
      p2 := CharPos('(', stmp);
      if (p2 > 0) and (CountChr(stmp, ')') = 1) and (CountChr(stmp, '(') = 1) then
      begin
        p3 := CharPos(')', stmp);
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

function remove_single_parenthesis(var stmp: string): boolean;
var
  i, j: integer;
  p1, p2: integer;
  scheck: string;
begin
  Result := False;

  p1 := 0;
  p2 := 0;
  for i := 1 to Length(stmp) do
  begin
    if stmp[i] = '(' then
      p1 := i
    else if stmp[i] = ')' then
    begin
      if p1 = 0 then
        Exit;
      p2 := i;
      scheck := '';
      for j := p1 + 1 to p2 - 1 do
        scheck := scheck + stmp[j];
      if not Pos1(STR_PREFIX, scheck) then
        if issingleidentifier(scheck) or isstructidentifier(scheck) or isidentifier(scheck) then
          if ((p1 = 1) or (stmp[p1 - 1] in ['(', ' '])) and
            ((p2 = Length(stmp)) or (stmp[p2 + 1] in [')', ' ', ';'])) then
          begin
            Delete(stmp, p2, 1);
            Delete(stmp, p1, 1);
            stmp := Trim(stmp);
            Result := True;
            remove_single_parenthesis(stmp);
            Exit;
          end;
      p1 := 0;
      p2 := 0;
    end;
  end;
end;

function remove_extra_parenthesis(var stmp: string): boolean;
var
  i, j: integer;
  p1, p2: integer;
  depth: integer;
  scheck, stmp0: string;
begin
  Result := False;

  p1 := 0;
  p2 := 0;
  depth := 0;
  for i := 1 to Length(stmp) do
  begin
    if depth < -1 then
      Exit;

    if stmp[i] = '(' then
    begin
      Inc(depth);
      if (depth = 0) and (p1 > 0) then
      begin
        p2 := i;
        scheck := '';
        for j := p1 + 1 to p2 - 1 do
          scheck := scheck + stmp[j];
        scheck := Trim(scheck);
        if (scheck = 'or') or (scheck = 'and')  or (scheck = 'xor') then
        begin
          stmp0 := '';
          for j := 1 to p1 - 1 do
            stmp0 := stmp0 + stmp[j];
          stmp0 := stmp0 + ' ' + scheck + ' ';
          for j := p2 + 1 to Length(stmp) do
            stmp0 := stmp0 + stmp[j];
          stmp := stmp0;
          Result := True;
          remove_extra_parenthesis(stmp);
          Exit;
        end;
        p1 := 0;
        p2 := 0;
      end;
    end
    else if stmp[i] = ')' then
    begin
      Dec(depth);
      if depth = - 1 then
        p1 := i;
    end;
  end;
end;

function remove_ifthen_parenthesis(var stmp: string): boolean;
var
  j: integer;
  p1, p2: integer;
  scheck, stmp0: string;
begin
  Result := False;

  scheck := 'if (';
  p1 := Pos(scheck, stmp);
  if p1 <> 1 then
  begin
    scheck := 'else if (';
    p1 := Pos(scheck, stmp);
  end;

  if p1 = 1 then
  begin
    p2 := Pos(') then', stmp);
    if p2 = Length(stmp) - 5 then
      if (CountChr(stmp, '(') = 1) and (CountChr(stmp, ')') = 1) then
      begin
        stmp0 := '';
        for j := Length(scheck) + 1 to Length(stmp) - 6 do
          stmp0 := stmp0 + stmp[j];
        stmp0 := Trim(stmp0);
        SetLength(scheck, Length(scheck) - 1);
        stmp := scheck + stmp0 + ' then';
        Result := True;
      end;
  end;
end;

function remove_double_parenthesis(var stmp: string): boolean;
var
  p1, p2: Integer;
begin
  Result := False;

  p1 := Pos('((', stmp);
  p2 := Pos('))', stmp);
  if (p1 > 0) and (p2 > p1) then
    if (Pos('if ', stmp) > 0) and (Pos(' then', stmp) > 0) then
      if (CountChr(stmp, '(') = 2) and (CountChr(stmp, ')') = 2) then
      begin
        stmp := StringReplace(stmp, '((', '(', [rfReplaceAll, rfIgnoreCase]);
        stmp := StringReplace(stmp, '))', ')', [rfReplaceAll, rfIgnoreCase]);
        Result := True;
      end;
end;

function ConvertNaive_Pass7(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, stmp0, token, rest, scomment: string;
  p1, p2, p3, start: integer;
  ret1: Boolean;
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
    okdo: Boolean;
  begin
    first := firstword(stmp);
    if first <> 'for' then
      Exit;

    last := lastword(stmp);
    if last <> 'do' then
    begin
      okdo := False;
      if Pos1('for ', stmp) then
        if Pos(' do', stmp) = 0 then
        begin
          if stmp[Length(stmp)] = ')' then
          begin
            stmp := stmp + ' do';
            okdo := True;
          end
          else if i < s.Count - 1 then
          begin
           ftmp4 := Trim(s.Strings[i + 1]);
            if Pos1('if ', ftmp4) or Pos1('for ', ftmp4) then
            begin
              stmp := stmp + ' do';
              okdo := True;
            end;
          end;
        end;

      if not okdo then
        Exit;
    end;

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
    if CharPos(';', s3) > 0 then
      Exit;
    if (Pos('++', s3) = 0) and (Pos('--', s3) = 0) then
      Exit;

    s1 := Trim(s1);
    s2 := Trim(s2);
    s3 := Trim(s3);

    if Pos1('int ', s1) then
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

    pp1 := CharPos('<', s2);
    pp2 := CharPos('>', s2);
    pp3 := CharPos('=', s2);

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

    if (ipp1 + ipp2 + ipp3 < 1) or (ipp1 + ipp2 + ipp3 > 2) then
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

      pp4 := CharPos('/', ftmp2);
      if pp4 > 0 then
        sdiv := '/'
      else
      begin
        pp4 := CharPos('\', ftmp2);
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

  stmp0 := StringReplace(sinp, '( not ', '(not ', [rfReplaceAll, rfIgnoreCase]);
  stmp0 := StringReplace(stmp0, '  mod  ', ' mod ', [rfReplaceAll, rfIgnoreCase]);
  stmp0 := StringReplace(stmp0, #13#10#13#10'begin'#13#10, #13#10'begin'#13#10, [rfReplaceAll, rfIgnoreCase]);
  stmp0 := StringReplace(stmp0, #13#10#13#10'begin ', #13#10'begin ', [rfReplaceAll, rfIgnoreCase]);

  s.Text := stmp0;

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

    stmp0 := stmp;
    splitcomment(stmp0, scomment);
    ret1 := False;
    if remove_single_parenthesis(stmp0) then ret1 := True;
    if remove_extra_parenthesis(stmp0) then ret1 := True;
    if remove_ifthen_parenthesis(stmp0) then ret1 := True;
    if remove_double_parenthesis(stmp0) then ret1 := True;
    if ret1 then
    begin
      joincomment(stmp0, scomment);
      stmp := stmp0;
    end;

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
      splitcomment(stmp, scomment);
      resolve_for;
      if stmp = 'while 1 do' then
        stmp := 'while True do';
      joincomment(stmp, scomment);
    end;

    for j := 1 to nspaces do
      stmp := ' ' + stmp;

    s2.Add(stmp);
  end;

  Result := s2.Text;
  s.Free;
  s2.Free;
end;

function _line_fix_if_then_1(const line: string): string;
var
  sl: TStringList;
  i: Integer;
  stmp, scomment: string;
begin
  Result := line;

  if Pos('if ', line) = 0 then // Trimmed string
    if Pos('else if ', line) = 0 then // Trimmed string
      Exit;

  stmp := line;

  for i := 0 to Length(stmp) do
    if stmp[i] in ['(', ')'] then
      stmp[i] := ' ';

  splitcomment(stmp, scomment);

  sl := string2stringlist(stmp, ' ');
  removeblanclines(sl);

  if (sl.Count = 7) and Pos1('if ', stmp) then
    if (sl.strings[2] = 'and') and ((sl.strings[4] = '=') or (sl.strings[4] = '<>')) and (sl.strings[6] = 'then') then
      if isidentifier(sl.Strings[1]) or issingleidentifier(sl.Strings[1]) or isstructidentifier(sl.Strings[1]) then
        if isidentifier(sl.Strings[3]) or issingleidentifier(sl.Strings[3]) or isstructidentifier(sl.Strings[3]) then
          if isidentifier(sl.Strings[5]) or issingleidentifier(sl.Strings[5]) or isstructidentifier(sl.Strings[5]) then
          begin
            Result := 'if ' + sl.Strings[1] + ' and ' + sl.Strings[3] + ' ' + sl.strings[4] + ' ' + sl.Strings[5] + ' then';
            if scomment <> '' then
            begin
              Result := Result + ' ';
              if Odd(Length(Result)) then
                Result := Result + ' ';
                Result := Result + scomment;
            end;
            sl.Free;
            Exit;
          end;

  if (sl.Count = 5) and Pos1('if ', stmp)  then
    if (sl.strings[2] = 'and') and (sl.strings[4] = 'then') then
      if isidentifier(sl.Strings[1]) or issingleidentifier(sl.Strings[1]) or isstructidentifier(sl.Strings[1]) then
        if isidentifier(sl.Strings[3]) or issingleidentifier(sl.Strings[3]) or isstructidentifier(sl.Strings[3]) then
        begin
          Result := 'if ' + sl.Strings[1] + ' and ' + sl.Strings[3] + ' <> 0 then';
          if scomment <> '' then
          begin
            Result := Result + ' ';
            if Odd(Length(Result)) then
              Result := Result + ' ';
              Result := Result + scomment;
          end;
          sl.Free;
          Exit;
        end;

  if (sl.Count = 8) and Pos1('else if ', stmp) then
    if (sl.strings[3] = 'and') and ((sl.strings[5] = '=') or (sl.strings[5] = '<>')) and (sl.strings[7] = 'then') then
      if isidentifier(sl.Strings[2]) or issingleidentifier(sl.Strings[2]) or isstructidentifier(sl.Strings[2]) then
        if isidentifier(sl.Strings[4]) or issingleidentifier(sl.Strings[4]) or isstructidentifier(sl.Strings[4]) then
          if isidentifier(sl.Strings[6]) or issingleidentifier(sl.Strings[6]) or isstructidentifier(sl.Strings[6]) then
          begin
            Result := 'else if ' + sl.Strings[2] + ' and ' + sl.Strings[4] + ' ' + sl.strings[5] + ' ' + sl.Strings[6] + ' then';
            if scomment <> '' then
            begin
              Result := Result + ' ';
              if Odd(Length(Result)) then
                Result := Result + ' ';
                Result := Result + scomment;
            end;
            sl.Free;
            Exit;
          end;

  if (sl.Count = 6) and Pos1('else if ', stmp)  then
    if (sl.strings[3] = 'and') and (sl.strings[5] = 'then') then
      if isidentifier(sl.Strings[2]) or issingleidentifier(sl.Strings[2]) or isstructidentifier(sl.Strings[2]) then
        if isidentifier(sl.Strings[4]) or issingleidentifier(sl.Strings[4]) or isstructidentifier(sl.Strings[4]) then
        begin
          Result := 'else if ' + sl.Strings[2] + ' and ' + sl.Strings[4] + ' <> 0 then';
          if scomment <> '' then
          begin
            Result := Result + ' ';
            if Odd(Length(Result)) then
              Result := Result + ' ';
              Result := Result + scomment;
          end;
          sl.Free;
          Exit;
        end;

  sl.Free;
end;

function ConvertNaive_Pass8(const sinp: string): string;
var
  s, s2, s3: TStringList;
  i, j, idx: integer;
  stmp, stmp0, stmp1, stmp2, stmp3, stmp4, stmp5, stmp6, stmp7, sident, sname: string;
  p1, p2, p3, len: integer;
  nspaces, nspaces2: integer;
  scomment: string;
  changed: boolean;
  sfront: string;
  tern_op, inc_op: string;
begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  stmp0 := StringReplace(sinp, '  do', ' do', [rfReplaceAll, rfIgnoreCase]);
  stmp0 := StringReplace(stmp0, ' / SizeOf(', ' div SizeOf(', [rfReplaceAll, rfIgnoreCase]);
  s.Text := DecodeStrings(stmp0);

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

    if stmp = '' then
    begin
      s2.Add('');
      Continue;
    end;

    if stmp = ';' then
    begin
      if s2.Count > 0 then
        if s2.Strings[s2.Count - 1] = '' then
          Continue;
      s2.Add('');
      Continue;
    end;

    stmp := Trim(_line_fix_if_then_1(stmp));
    
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

    if (stmp = 'end') or (stmp = 'end;') then
    begin
      if s2.Count > 0 then
      begin
        stmp1 := Trim(s2.Strings[s2.Count - 1]);
        if Pos1('return ', stmp1) then
        begin
          splitcomment(stmp1, scomment);
          stmp1 := Trim(stmp1);
          if (CountChr(stmp1, ';') = 1) and (CountChr(stmp1, '=') = 0) then
            if stmp1[Length(stmp1)] = ';' then
            begin
              stmp1[1] := ' ';
              stmp1[2] := ' ';
              stmp1[3] := ' ';
              stmp1[4] := ' ';
              stmp1[5] := ' ';
              stmp1[6] := ' ';
              stmp1 := 'Result := ' + Trim(stmp1);
              joincomment(stmp1, scomment);
              for j := 1 to nspaces + 2 do
                stmp1 := ' ' + stmp1;
              s2.Strings[s2.Count - 1] := stmp1;
              stmp1 := 'Exit;';
              for j := 1 to nspaces + 2 do
                stmp1 := ' ' + stmp1;
              s2.Add(stmp1);
            end;
        end;
      end;
      for j := 1 to nspaces do
        stmp := ' ' + stmp;
      s2.Add(stmp);
      Continue;
    end;

    if stmp[Length(stmp)] = ';' then
    begin
      SetLength(stmp, Length(stmp) - 1);
      stmp0 := ';';
    end
    else
      stmp0 := '';

    stmp := StringReplace(stmp, '"', #255, [rfReplaceAll, rfIgnoreCase]);
    if CountChr(stmp, #255) = 2 then
      if (stmp[1] = #255) and (stmp[Length(stmp)] = #255) then
      begin
        stmp := StringReplace(stmp, '''', #254, [rfReplaceAll, rfIgnoreCase]);
        stmp := StringReplace(stmp, #255, '''', [rfReplaceAll, rfIgnoreCase]);

        if isinpascalquote(stmp) then
        begin
          if Pos('\n', stmp) > 0 then
          begin
            if Pos('\n''', stmp) = Length(stmp) - 2 then
            begin
              stmp[Length(stmp) - 2] := '''';
              stmp[Length(stmp) - 1] := '#';
              stmp[Length(stmp)] := '1';
              stmp := stmp + '3#10''';
              Delete(stmp, 1, 1);
            end
            else
            begin
              Delete(stmp, 1, 1);
              SetLength(stmp, Length(stmp) - 1);
            end;
            stmp := StringReplace(stmp, '\n', '''#13#10''', [rfReplaceAll, rfIgnoreCase]);
            stmp := '''' + stmp + '''';
            stmp := StringReplace(stmp, '''''', '', [rfReplaceAll, rfIgnoreCase]);
          end;
          stmp := StringReplace(stmp, #254, '''''', [rfReplaceAll, rfIgnoreCase]);
          for j := 1 to nspaces do
            stmp := ' ' + stmp;
          s2.Add(stmp + stmp0);
          Continue;
        end;
      end;

    stmp := StringReplace(stmp, #255, '''', [rfReplaceAll, rfIgnoreCase]);
    stmp := StringReplace(stmp, #254, '''', [rfReplaceAll, rfIgnoreCase]);

    stmp := stmp + stmp0;

    changed := False;

    if Pos1('default:', stmp) then
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

      Changed := True;
    end;

    if Pos1('case ', stmp) then
    begin
      len := Length(stmp);
      if (stmp[len - 3] = ' ') and (stmp[len - 2] = ' ') and (stmp[len - 1] = 'o') and (stmp[len] = 'f') then
      begin
        stmp[len - 2] := 'o';
        stmp[len - 1] := 'f';
        SetLength(stmp, len - 1);
      end;
    end;

    if Pos1('case ', stmp2) then
    begin
      len := Length(stmp2);
      if (stmp2[len - 2] = ' ') and (stmp2[len - 1] = 'o') and (stmp2[len] = 'f') then
        if stmp = 'begin' then
          Continue;
    end;

    if (CountChr(stmp, '(') = 1) and  (CountChr(stmp, ')') = 1) then
    begin
      p1 := CharPos('(', stmp);
      p2 := CharPos(')', stmp);
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
            Changed := True;
          end;
        end;
      end;
    end;

    if not Changed then
    begin
      // Ternary operator
      p1 := Pos(':=', stmp);
      p2 := CharPos('?', stmp);

      stmp0 := stmp;
      splitcomment(stmp, scomment);
      stmp := Trim(stmp);

      p3 := 0;
      for j := Length(stmp) downto 1 do
        if stmp[j] = ':' then
        begin
          p3 := j;
          Break;
        end;

      if (p1 > 0) and (p2 > p1) and (p3 > p2) and (CountChr(stmp, ':') = 2) and
        (CountChr(stmp, '?') = 1) and (CountChr(stmp, '=') >= 1) and (CountChr(stmp, ';') = 1) and
        (CharPos(';', stmp) = Length(stmp)) then
      begin
        splitstring(stmp, stmp1, stmp5, ':');
        if Length(stmp5) > 6 then
          if stmp5[1] = '=' then
          begin
            Delete(stmp5, 1, 1);
            splitstring(stmp5, stmp2, stmp6, '?');
            splitstring(stmp6, stmp3, stmp4, ':');
            stmp1 := Trim(stmp1);
            stmp2 := Trim(stmp2);
            stmp3 := Trim(stmp3);
            stmp4 := Trim(stmp4);

            tern_op := '';
            inc_op := '';
            if stmp1 <> '' then
            begin
              if stmp1[Length(stmp1)] = '+' then
              begin
                tern_op := '+';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
                if stmp1 <> '' then
                begin
                  if stmp1[Length(stmp1)] = '+' then
                  begin
                    inc_op := '++';
                    tern_op := '';
                    SetLength(stmp1, Length(stmp1) - 1);
                    stmp1 := Trim(stmp1);
                  end;
                end;
              end
              else if stmp1[Length(stmp1)] = '-' then
              begin
                tern_op := '-';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
                if stmp1 <> '' then
                begin
                  if stmp1[Length(stmp1)] = '-' then
                  begin
                    inc_op := '--';
                    tern_op := '';
                    SetLength(stmp1, Length(stmp1) - 1);
                    stmp1 := Trim(stmp1);
                  end;
                end;
              end
              else if stmp1[Length(stmp1)] = '*' then
              begin
                tern_op := '*';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
              end
              else if stmp1[Length(stmp1)] = '/' then
              begin
                tern_op := '/';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
              end
              else if stmp1[Length(stmp1)] = '/' then
              begin
                tern_op := '/';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
              end
              else if stmp1[Length(stmp1)] = '&' then
              begin
                tern_op := 'and';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
              end
              else if stmp1[Length(stmp1)] = '|' then
              begin
                tern_op := 'or';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
              end
              else if stmp1[Length(stmp1)] = '^' then
              begin
                tern_op := 'xor';
                SetLength(stmp1, Length(stmp1) - 1);
                stmp1 := Trim(stmp1);
              end
              else if stmp1[Length(stmp1)] = '>' then
              begin
                if Length(stmp1) > 2 then
                  if stmp1[Length(stmp1) - 1] = '>' then
                  begin
                    tern_op := 'shr';
                    SetLength(stmp1, Length(stmp1) - 2);
                    stmp1 := Trim(stmp1);
                  end;
              end
              else if stmp1[Length(stmp1)] = '<' then
              begin
                if Length(stmp1) > 2 then
                  if stmp1[Length(stmp1) - 1] = '<' then
                  begin
                    tern_op := 'shl';
                    SetLength(stmp1, Length(stmp1) - 2);
                    stmp1 := Trim(stmp1);
                  end;
              end;
            end;

            if (stmp1 <> '') and (stmp2 <> '') and (stmp3 <> '') and (stmp4 <> '') then
              if stmp4[Length(stmp4)] = ';' then
              begin
                SetLength(stmp4, Length(stmp4) - 1);
                stmp4 := Trim(stmp4);
                stmp1 := StringReplace(stmp1, '   ', ' ', [rfReplaceAll, rfIgnoreCase]);
                stmp1 := StringReplace(stmp1, '  ', ' ', [rfReplaceAll, rfIgnoreCase]);

                s3 := string2stringlist(stmp1, ' ');
                removeblanclines(s3);

                sfront := '';

                idx := s3.IndexOf('static');
                if idx = 0 then
                begin
                  s3.Delete(0);
                  sfront := sfront + ' static';
                end;

                idx := s3.IndexOf('const');
                if idx = 0 then
                begin
                  s3.Delete(0);
                  sfront := sfront + ' const';
                end;

                if s3.Count > 1 then
                  if isCtypename(s3.Strings[0]) or isPastypename(s3.Strings[0]) or issingleidentifier(s3.Strings[0]) then
                  begin
                    sfront := sfront + ' ' + s3.Strings[0];
                    s3.Delete(0);
                  end;

                if s3.Count = 1 then
                  stmp1 := s3.Strings[0];

                if (s3.Count = 1) and (isstructidentifier(stmp1) or issingleidentifier(stmp1)) and
                  (stmp2 <> '') and
//                  isinsingleparenthesis(stmp2) and
                  (stmp3 <> '') and
                  (stmp4 <> '') then
//                  (issingleidentifier(stmp3) or isintidentifier(stmp3)) and
//                  (issingleidentifier(stmp4) or isintidentifier(stmp4)) then
                begin
                  stmp1 := Trim(sfront + ' ' + stmp1);

                  stmp := '';
                  for j := 1 to nspaces do
                    stmp := stmp + ' ';
                  if isinsingleparenthesis(stmp2) then
                  begin
                    Delete(stmp2, 1, 1);
                    SetLength(stmp2, Length(stmp2) - 1);
                    stmp2 := Trim(stmp2);
                  end;

                  if stmp2 <> '' then
                    if (stmp2[1] = '(') and (stmp2[Length(stmp2)] = ')') then
                    begin
                      stmp7 := stmp2;
                      Delete(stmp7, 1, 1);
                      SetLength(stmp7, Length(stmp7) - 1);
                      if (CountChr(stmp7, '(') = 1) and (CountChr(stmp7, ')') = 1) and
                        (CharPos('(', stmp7) < CharPos(')', stmp7)) then
                          stmp2 := stmp7;
                    end;

                  if stmp2 <> '' then
                  begin
                    stmp := stmp + 'if ' + stmp2 + ' then';
                    joincomment(stmp, scomment);
                    s2.Add(stmp);

                    if tern_op <> '' then
                    begin
                      if not isstructidentifier(stmp3) then
                        if not issingleidentifier(stmp3) then
                          if not isinsingleparenthesis(stmp3) then
                            stmp3 := '(' + stmp3 + ')';
                      if not isstructidentifier(stmp4) then
                        if not issingleidentifier(stmp4) then
                          if not isinsingleparenthesis(stmp4) then
                            stmp4 := '(' + stmp4 + ')';
                    end;

                    stmp := '';
                    for j := 1 to nspaces + 2 do
                      stmp := stmp + ' ';             
                    stmp := stmp + stmp1 + ' := ' + decide(tern_op = '', '', stmp1 + ' ' + tern_op + ' ') + stmp3;
                    s2.Add(stmp);

                    stmp := '';
                    for j := 1 to nspaces do
                      stmp := stmp + ' ';
                    stmp := stmp + 'else';
                    s2.Add(stmp);

                    stmp := '';
                    for j := 1 to nspaces + 2 do
                      stmp := stmp + ' ';
                    stmp := stmp + stmp1 + ' := ' + decide(tern_op = '', '', stmp1 + ' ' + tern_op + ' ') + stmp4 + ';';
                    s2.Add(stmp);

                    if inc_op <> '' then
                    begin
                      stmp := '';
                      for j := 1 to nspaces do
                        stmp := stmp + ' ';
                      if inc_op[1] = '+' then
                        stmp := stmp + 'Inc(' + stmp1 + ');'
                      else if inc_op[1] = '-' then
                        stmp := stmp + 'Dec(' + stmp1 + ');'
                    end;

                    s3.Free;
                    Continue;
                  end;
                end;
                s3.Free;
              end;
          end;
      end;

      stmp := stmp0;
    end;

    if CharPos('&', stmp) > 0 then
    begin
      stmp0 := ' &:=  not ';
      p1 := Pos(stmp0, stmp);
      if p1 <= 0 then
      begin
        stmp0 := ' &:= not ';
        p1 := Pos(stmp0, stmp);
      end;

      if p1 > 0 then
      begin
        stmp1 := '';
        for j := 1 to p1 - 1 do
          stmp1 := stmp1 + stmp[j];

        stmp2 := '';
        for j := p1 + Length(stmp0) to Length(stmp) do
        begin
          stmp2 := stmp2 + stmp[j];
        end;

        stmp1 := Trim(stmp1);
        stmp2 := Trim(stmp2);
        splitcomment(stmp2, scomment);
        stmp2 := Trim(stmp2);

        s3 := string2stringlist(stmp1, ' ');
        removeblanclines(s3);

        sfront := '';

        idx := s3.IndexOf('static');
        if idx = 0 then
        begin
          s3.Delete(0);
          sfront := sfront + ' static';
        end;

        idx := s3.IndexOf('const');
        if idx = 0 then
        begin
          s3.Delete(0);
          sfront := sfront + ' const';
        end;

        if s3.Count > 1 then
          if isCtypename(s3.Strings[0]) or isPastypename(s3.Strings[0]) or issingleidentifier(s3.Strings[0]) then
          begin
            sfront := sfront + ' ' + s3.Strings[0];
            s3.Delete(0);
          end;

        if s3.Count = 1 then
          stmp1 := s3.Strings[0];

        if (s3.Count = 1) and (CharPos(';', stmp2) = Length(stmp2)) then
          if issingleidentifier(stmp1) or isidentifier(stmp1) or isstructidentifier(stmp1) or isintidentifier(stmp1) or isinsingleparenthesis(stmp1) then
          begin
            stmp0 := '';
            for j := 1 to nspaces do
              stmp0 := stmp0 + ' ';

            if sfront <> '' then
              sfront := Trim(sfront) + ' ';

            stmp0 := stmp0 + sfront + stmp1 + ' := ' + stmp1 + ' and not ' + stmp2;

            s2.Add(stmp0);

            s3.Free;
            Continue;
          end;

        s3.Free;
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

function ConvertNaive_Pass9(const sinp: string): string;
var
  s, s2: TStringList;
  i, j: integer;
  stmp, stmp1, stmp2, stmp3, scomment: string;
  nspaces: integer;
  changed: boolean;

  procedure check_array_var;
  var
    stmp1: string;
    t1, t2: string;
    fw, sw: string;
    s_type: string;
    s_name: string;
    s_size: string;
    isstatic, isconst, isstruct: boolean;
    acomment: string;
  begin
    if CharPos('[', stmp) >= CharPos(']', stmp) then
      Exit;

    if CountChr(stmp, '[') <> 1 then
      Exit;

    if CountChr(stmp, ']') <> 1 then
      Exit;

    if CharPos('=', stmp) <> 0 then
      Exit;

    if CharPos('(', stmp) <> 0 then
      Exit;

    if CharPos(')', stmp) <> 0 then
      Exit;

    if CharPos(';', stmp) <> Length(stmp) then
      Exit;

    if Pos('return ', stmp) <> 0 then
      Exit;

    isstatic := False;
    isconst := False;
    isstruct := False;

    stmp1 := stmp;
    fw := firstword(stmp1);
    if fw = 'static' then
    begin
      splitstring(stmp1, t1, t2);
      stmp1 := t2;
      fw := firstword(stmp1);
      isstatic := True;
    end;

    if fw = 'const' then
    begin
      splitstring(stmp1, t1, t2);
      stmp1 := t2;
      fw := firstword(stmp1);
      isconst := True;
    end;

    if fw = 'isstruct' then
    begin
      splitstring(stmp1, t1, t2);
      stmp1 := t2;
      fw := firstword(stmp1);
      isstruct := True;
    end;

    if not issingleidentifier(fw) then
      Exit;

    splitstring(stmp1, fw, sw);
    s_type := fw;

    splitstring(sw, t1, t2, '[');
    if not issingleidentifier(t1) then
      Exit;

    s_name := t1;

    stmp1 := t2;

    splitstring(t2, fw, sw, ']');

    if sw <> ';' then
      Exit;

    s_size := fw;

    stmp := '';
    if isstatic then
      stmp := stmp + 'static ';
    if isconst then
      stmp := stmp + 'const ';
    if isstruct then
      stmp := stmp + 'struct ';
    stmp := stmp + s_name + ': array[0..';

    acomment := '';
    if IntToStr(StrToIntDef(s_size, 0)) = s_size then
    begin
      s_size := IntToStr(StrToIntDef(s_size, 0) - 1);
      acomment := '// ' + s_size + ' - 1';
      if scomment <> '' then
      begin
        if Pos1('//', scomment) or Pos1('/*', scomment) then
        begin
          scomment[1] := ' ';
          scomment[2] := ' ';
        end
        else
          acomment := acomment + ' ';
        scomment := acomment + scomment;
      end;
    end
    else if issingleidentifier(s_size) then
      s_size := s_size + ' - 1'
    else if isinsingleparenthesis(s_size) then
      s_size := s_size + ' - 1'
    else
      s_size := '(' + s_size + ') - 1';

    stmp := stmp + s_size + '] of ' + s_type + ';';
  end;

begin
  s := TStringList.Create;
  s2 := TStringList.Create;

  s.Text := sinp;

  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    if stmp = STR_SKIP then
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

    changed := False;

    splitcomment(stmp, scomment);
    stmp := Trim(stmp);
    check_array_var;
    joincomment(stmp, scomment);

    if (stmp = 'begin') and (i < s.Count - 3) and (s2.Count > 0) then
    begin
      stmp3 := Trim(s2.Strings[s2.Count - 1]);
      splitcomment(stmp3, scomment);
      stmp3 := Trim(stmp3);
      if (Pos1('if ', stmp3) and (Pos(' then', stmp3) = Length(stmp3) - 4)) or
         (Pos1('for ', stmp3) and (Pos(' do', stmp3) = Length(stmp3) - 2)) or
         ((stmp3 = 'else') or Pos1('else if ', stmp3)) then
      begin
        stmp1 := Trim(s.Strings[i + 1]);
        splitcomment(stmp1, scomment);
        stmp1 := Trim(stmp1);
        if (CountChr(stmp1, ';') = 1) and (CharPos(';', stmp1) = Length(stmp1)) and (Pos('return ', stmp1) = 0) then
        begin
          stmp2 := Trim(s.Strings[i + 2]);
          if ((stmp2 = 'end') or (stmp2 = 'end;')) and (Length(stmp1) >= 2) then
          begin
            if stmp2 = 'end' then
              SetLength(stmp1, Length(stmp1) - 1);
            stmp := stmp1 + ' ' + scomment;
            s.Strings[i + 1] := STR_SKIP;
            s.Strings[i + 2] := STR_SKIP;
            nspaces := nspaces + 2;
            changed := True;
          end;
        end;
      end;
      if not changed then
      begin
        stmp1 := Trim(s.Strings[i + 1]);
        if (stmp1 = 'end') or (stmp1 = 'end;') then
        begin
          stmp2 := Trim(s.Strings[i + 2]);
          if (stmp2 = 'else') or Pos1('else if ', stmp2) then
          begin
            s.Strings[i + 1] := STR_SKIP;
            Continue;
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
  Result := ConvertNaive_Pass9(Result);
end;


end.
