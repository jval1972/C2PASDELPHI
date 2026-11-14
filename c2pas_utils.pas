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
  p := Pos(' ', inp1);
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
  splitstring(inp, result, tmp, splitter);
end;

function firstword(const inp: string; const splitters: charset_t): string; overload;
var
  tmp: string;
begin
  splitstring(inp, result, tmp, splitters);
end;

function secondword(const inp: string; const splitter: string = ' '): string; overload;
var
  tmp: string;
begin
  splitstring(inp, tmp, result, splitter);
end;

function secondword(const inp: string; const splitters: charset_t): string; overload;
var
  tmp: string;
begin
  splitstring(inp, tmp, result, splitters);
end;

function lastword(const inp: string; const splitter: string = ' '): string; overload;
var
  i: integer;
begin
  result := '';
  i := length(inp);
  while i > 0 do
  begin
    if inp[i] = splitter then
      exit
    else
    begin
      result := inp[i] + result;
      dec(i);
    end;
  end;
end;

function lastword(const inp: string; const splitters: charset_t): string; overload;
var
  i: integer;
begin
  result := '';
  i := length(inp);
  while i > 0 do
  begin
    if inp[i] in splitters then
      exit
    else
    begin
      result := inp[i] + result;
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
  result := TStringList.Create;
  result.Text := stmp;
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
  result := False;
  if Length(s) = 0 then
    exit;

  for i := 1 to Length(s) do
    if not (s[i] in ['-', '.', '^', '[', ']', 'a'..'z', 'A'..'Z', '0', '1'..'9', '_']) then
      exit;

  if Pos('-', s) > 1 then
    exit;
    
  Result := not (s[1] in ['0', '1'..'9']);
end;

function IsInteger(const s: string): boolean;
var
  i: integer;
begin
  if Length(s) = 0 then
  begin
    result := false;
    exit;
  end;

  if s[1] = '$' then
  begin
    if Length(s) < 2 then
    begin
      Result := false;
      exit;
    end;
    Result := false;
    for i := 2 to Length(s) do
      if not (s[i] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A'..'F', 'a'..'f']) then
        Exit;
    result := true;
    exit;
  end;
  result := IntToStr(StrToIntDef(s, -1)) = s;
end;

function IsNumber(const s: string): boolean;
var
  code: integer;
  v: double;
begin
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
  result := false;

  if s = '' then
    exit;

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
        result := true;
        exit;
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
  result := 0;
  i := 1;
  while i <= Length(s) do
  begin
    if s[i] = ' ' then
    begin
      inc(result);
      inc(i);
    end
    else
      exit;
  end;
end;

function s_spaces(const x: integer): string;
var
  i: integer;
begin
  result := '';
  for i := 1 to x do
    result := Result + ' ';
end;

procedure removetrailingNL(var s: string);
begin
  while true do
  begin
    if Length(s) > 2 then
    begin
      if (s[Length(s) - 1] = #13) and (s[Length(s)] = #10) then
        SetLength(s, Length(s) - 2)
      else
        exit;
    end
    else
      exit;
  end;
end;

function removequotes(s: string; q: charset_t): string;
begin
  if s = '' then
  begin
    result := '';
    exit;
  end;
  if s[1] in q then
    s[1] := ' ';
  if s[Length(s)] in q then
    s[Length(s)] := ' ';
  result := Trim(s);
end;

function pascalnumber(s: string): string;
begin
  if Length(s) = 0 then
  begin
    Result := '';
    exit;
  end;

  if IsInteger(s) then
    if Pos('0x', s) = 1 then
    begin
      s[1] := ' ';
      s[2] := '$';
      Result := Trim(s);
      exit;
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
      result := false;
      exit;
    end;
  end;
  result := plevel = 0;
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
    result := 0
  else
    result := fList[Index];
end;

procedure TDNumberList.Put(Index: Integer; const value: integer);
begin
  fList[Index] := value;
end;

function TDNumberList.Add(const value: integer): integer;
begin
  ReallocMem(fList, (fNumItems + 1) * SizeOf(integer));
  Put(fNumItems, value);
  result := fNumItems;
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
    result := false;
    exit;
  end;

  for i := Index + 1 to fNumItems - 1 do
    fList[i - 1] := fList[i];

  ReallocMem(fList, (fNumItems - 1) * SizeOf(integer));
  dec(fNumItems);

  result := true;
end;

function TDNumberList.IndexOf(const value: integer): integer;
var
  i: integer;
begin
  for i := 0 to fNumItems - 1 do
    if fList[i] = value then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;

procedure TDNumberList.Clear;
begin
  ReallocMem(fList, 0);
  fList := nil;
  fNumItems := 0;
end;



end.
