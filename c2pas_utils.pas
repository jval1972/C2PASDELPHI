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

unit c2pas_utils;

interface

uses
  Classes;

type
  charset_t = set of char;

procedure splitstring(const inp: string; var out1, out2: string; const splitter: string = ' '); overload;

procedure splitstring(const inp: string; var out1, out2: string; const splitters: charset_t); overload;

function firstword(const inp: string; const splitter: string = ' '): string; overload;

function firstword(const inp: string; const splitters: charset_t): string; overload;

function secondword(const inp: string; const splitter: string = ' '): string; overload;

function secondword(const inp: string; const splitters: charset_t): string; overload;

function lastword(const inp: string; const splitter: string = ' '): string; overload;

function lastword(const inp: string; const splitters: charset_t): string; overload;

function str2list(const s: string; splitters: charset_t): TStringList;

procedure DeleteBlanks(s: TStringList);

function split_parenthesis(const s: string; var _before, _in, _after: string): boolean;

function IsInteger(const s: string): boolean;

function IsNumber(const s: string): boolean;

function IsNumeric(const s: string): boolean;

function IsIdentifier(const s: string): boolean;

function LeadingSpaces(const s: string): integer;

function s_spaces(const x: integer): string;

procedure removetrailingNL(var s: string);

function removequotes(s: string; q: charset_t): string;

function pascalnumber(s: string): string;

function checkbracketsclosed(const expr: string; b1, b2: Char): boolean;

function CountChr(const s: string; const c: Char): integer;

function textnospaces(const s: string): string;

type
  TDNumberList = class
  private
    fList: PIntegerArray;
    fNumItems: integer;
  protected
    function Get(Index: Integer): integer; virtual;
    procedure Put(Index: Integer; const value: integer); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Add(const value: integer): integer; overload; virtual;
    procedure Add(const nlist: TDNumberList); overload; virtual;
    function Delete(const Index: integer): boolean;
    function IndexOf(const value: integer): integer;
    procedure Clear;
    property Count: integer read fNumItems;
    property Numbers[Index: Integer]: integer read Get write Put; default;
  end;

function string2stringlist(const s: string; const c: char): TStringList;

procedure removeblanclines(const sl: TStringList);

function decide(const condition: boolean;
  const iftrue: string; const iffalse: string): string;

function Pos1(const subs, s: string): boolean;

function CharPos(const ch: Char; const s: string): integer;

function removeallspaces(const s: string): string;

implementation

uses
  SysUtils;

procedure splitstring(const inp: string; var out1, out2: string; const splitter: string = ' '); overload;
var
  p: integer;
begin
  p := Pos(splitter, inp);
  if p = 0 then
  begin
    out1 := inp;
    out2 := '';
  end
  else
  begin
    out1 := Trim(Copy(inp, 1, p - 1));
    out2 := Trim(Copy(inp, p + 1, Length(inp) - p));
  end;
end;

procedure splitstring(const inp: string; var out1, out2: string; const splitters: charset_t); overload;
var
  i: integer;
  p: integer;
  inp1: string;
begin
  inp1 := inp;
  for i := 1 to Length(inp1) do
    if inp1[i] in splitters then
      inp1[i] := ' ';
  p := CharPos(' ', inp1);
  if p = 0 then
  begin
    out1 := inp1;
    out2 := '';
  end
  else
  begin
    out1 := Trim(Copy(inp1, 1, p - 1));
    out2 := Trim(Copy(inp1, p + 1, Length(inp) - p));
  end;
end;

function firstword(const inp: string; const splitter: string = ' '): string; overload;
var
  tmp: string;
begin
  splitstring(inp, Result, tmp, splitter);
end;

function firstword(const inp: string; const splitters: charset_t): string; overload;
var
  tmp: string;
begin
  splitstring(inp, Result, tmp, splitters);
end;

function secondword(const inp: string; const splitter: string = ' '): string; overload;
var
  tmp, tmp2: string;
begin
  splitstring(inp, tmp, tmp2, splitter);
  Result := firstword(tmp2, splitter);
end;

function secondword(const inp: string; const splitters: charset_t): string; overload;
var
  tmp, tmp2: string;
begin
  splitstring(inp, tmp, tmp2, splitters);
  Result := firstword(tmp2, splitters);
end;

function lastword(const inp: string; const splitter: string = ' '): string; overload;
var
  i: integer;
begin
  Result := '';
  i := length(inp);
  while i > 0 do
  begin
    if inp[i] = splitter then
      Exit
    else
    begin
      Result := inp[i] + Result;
      dec(i);
    end;
  end;
end;

function lastword(const inp: string; const splitters: charset_t): string; overload;
var
  i: integer;
begin
  Result := '';
  i := length(inp);
  while i > 0 do
  begin
    if inp[i] in splitters then
      Exit
    else
    begin
      Result := inp[i] + Result;
      dec(i);
    end;
  end;
end;

function str2list(const s: string; splitters: charset_t): TStringList;
var
  i: integer;
  stmp: string;
begin
  stmp := '';
  for i := 1 to Length(s) do
  begin
    if s[i] in splitters then
      stmp := stmp + #13#10
    else
      stmp := stmp + s[i];
  end;
  Result := TStringList.Create;
  Result.Text := stmp;
end;

procedure DeleteBlanks(s: TStringList);
var
  i: integer;
begin
  for i := s.Count - 1 downto 0 do
    if s.Strings[i] = '' then
      s.Delete(i);
end;

function IsIdentifier(const s: string): boolean;
var
  i: integer;
begin
  Result := False;
  if Length(s) = 0 then
    Exit;

  for i := 1 to Length(s) do
    if not (s[i] in ['-', '.', '^', '[', ']', 'a'..'z', 'A'..'Z', '0', '1'..'9', '_']) then
      Exit;

  if CharPos('-', s) > 1 then
    Exit;
    
  Result := not (s[1] in ['0', '1'..'9']);
end;

function IsInteger(const s: string): boolean;
var
  i: integer;
begin
  if Length(s) = 0 then
  begin
    Result := False;
    Exit;
  end;

  if s[1] = '$' then
  begin
    if Length(s) < 2 then
    begin
      Result := False;
      Exit;
    end;
    Result := False;
    for i := 2 to Length(s) do
      if not (s[i] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A'..'F', 'a'..'f']) then
        Exit;
    Result := True;
    Exit;
  end;
  Result := IntToStr(StrToIntDef(s, -1)) = s;
end;

function IsNumber(const s: string): boolean;
var
  code: integer;
  v: double;
begin
  DecimalSeparator := '.';
  Val(s, v, code);
  Result := code = 0;
end;

function IsNumeric(const s: string): boolean;
begin
  Result := IsInteger(s) or IsNumber(s);
end;

function split_parenthesis(const s: string; var _before, _in, _after: string): boolean;
var
  i, j: integer;
  plevel: integer;
begin
  Result := False;

  if s = '' then
    Exit;

  plevel := 0;

  _before := '';
  _in := '';
  _after := '';

  for i := 1 to Length(s) do
  begin
    if s[i] = '(' then
      inc(plevel)
    else if s[i] = ')' then
    begin
      dec(plevel);
      if plevel = 0 then
      begin
        for j := i + 1 to Length(s) do
          _after := _after + s[j];
        _after := Trim(_after);
        _before := Trim(_before);
        _in := Trim(_in);
        Result := True;
        Exit;
      end;
    end
    else
    begin
      if plevel = 0 then
        _before := _before + s[i]
      else
        _in := _in + s[i];
    end;
  end;
  _after := Trim(_after);
  _before := Trim(_before);
  _in := Trim(_in);
end;


function LeadingSpaces(const s: string): integer;
var
  i: integer;
begin
  Result := 0;
  i := 1;
  while i <= Length(s) do
  begin
    if s[i] = ' ' then
    begin
      inc(Result);
      inc(i);
    end
    else
      Exit;
  end;
end;

function s_spaces(const x: integer): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to x do
    Result := Result + ' ';
end;

procedure removetrailingNL(var s: string);
begin
  while True do
  begin
    if Length(s) > 2 then
    begin
      if (s[Length(s) - 1] = #13) and (s[Length(s)] = #10) then
        SetLength(s, Length(s) - 2)
      else
        Exit;
    end
    else
      Exit;
  end;
end;

function removequotes(s: string; q: charset_t): string;
begin
  if s = '' then
  begin
    Result := '';
    Exit;
  end;
  if s[1] in q then
    s[1] := ' ';
  if s[Length(s)] in q then
    s[Length(s)] := ' ';
  Result := Trim(s);
end;

function pascalnumber(s: string): string;
begin
  if Length(s) = 0 then
  begin
    Result := '';
    Exit;
  end;

  if IsInteger(s) then
    if Pos1('0x', s) then
    begin
      s[1] := ' ';
      s[2] := '$';
      Result := Trim(s);
      Exit;
    end;

  if IsNumber(s) then
  begin
    Result := s;
  end;
end;

function checkbracketsclosed(const expr: string; b1, b2: Char): boolean;
var
  plevel: Integer;
  i: integer;
begin
  plevel := 0;
  for i := 1 to Length(expr) do
  begin
    if expr[i] = b1 then
      Inc(plevel)
    else if expr[i] = b2 then
      Dec(plevel);
    if plevel < 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := plevel = 0;
end;

function CountChr(const s: string; const c: Char): integer;
var
  i: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
    if s[i] = c then
      inc(Result);
end;

function textnospaces(const s: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    if s[i] <> ' ' then
      Result := Result + s[i];
end;

////////////////////////////////////////////////////////////////////////////////
// TDNumberList
constructor TDNumberList.Create;
begin
  fList := nil;
  fNumItems := 0;
end;

destructor TDNumberList.Destroy;
begin
  Clear;
end;

function TDNumberList.Get(Index: Integer): integer;
begin
  if (Index < 0) or (Index >= fNumItems) then
    Result := 0
  else
    Result := fList[Index];
end;

procedure TDNumberList.Put(Index: Integer; const value: integer);
begin
  fList[Index] := value;
end;

function TDNumberList.Add(const value: integer): integer;
begin
  ReallocMem(fList, (fNumItems + 1) * SizeOf(integer));
  Put(fNumItems, value);
  Result := fNumItems;
  inc(fNumItems);
end;

procedure TDNumberList.Add(const nlist: TDNumberList);
var
  i: integer;
begin
  for i := 0 to nlist.Count - 1 do
    Add(nlist[i]);
end;

function TDNumberList.Delete(const Index: integer): boolean;
var
  i: integer;
begin
  if (Index < 0) or (Index >= fNumItems) then
  begin
    Result := False;
    Exit;
  end;

  for i := Index + 1 to fNumItems - 1 do
    fList[i - 1] := fList[i];

  ReallocMem(fList, (fNumItems - 1) * SizeOf(integer));
  dec(fNumItems);

  Result := True;
end;

function TDNumberList.IndexOf(const value: integer): integer;
var
  i: integer;
begin
  for i := 0 to fNumItems - 1 do
    if fList[i] = value then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

procedure TDNumberList.Clear;
begin
  ReallocMem(fList, 0);
  fList := nil;
  fNumItems := 0;
end;

function string2stringlist(const s: string; const c: char): TStringList;
var
  i: integer;
  tmp: string;
begin
  tmp := '';
  for i := 1 to length(s) do
  begin
    if s[i] = c then
      tmp := tmp + #13#10
    else
      tmp := tmp + s[i];
  end;
  Result := TStringList.Create;
  Result.Text := tmp;
end;

procedure removeblanclines(const sl: TStringList);
var
  i: Integer;
begin
  for i := sl.Count - 1 downto 0 do
    if Trim(sl.Strings[i]) = '' then
      sl.Delete(i);
end;

function decide(const condition: boolean;
  const iftrue: string; const iffalse: string): string;
begin
  if condition then
    result := iftrue
  else
    result := iffalse;
end;

function Pos1(const subs, s: string): boolean;
var
  len1, len1b, len2: integer;
  i: integer;
begin
  len1 := Length(subs);
  len2 := Length(s);
  if len2 < len1 then
  begin
    Result := False;
    Exit;
  end;

  len1b := len1 - 4;
  i := 1;
  while i <= len1b do
  begin
    if PLongWord(@subs[i])^ <> PLongWord(@s[i])^ then
    begin
      Result := False;
      Exit;
    end;
    Inc(i, 4);
  end;

  while i <= len1 do
  begin
    if subs[i] <> s[i] then
    begin
      Result := False;
      Exit;
    end;
    Inc(i);
  end;

  Result := True;
end;


function CharPos(const ch: Char; const s: string): integer;
var
  i: integer;
begin
  for i := 1 to Length(s) do
    if s[i] = ch then
    begin
      result := i;
      exit;
    end;
  result := 0;
end;

function removeallspaces(const s: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    if s[i] <> ' ' then
      Result := Result + s[i];
end;

end.
