unit c2pas_convert;

interface

uses
  Classes;

function c2pas_doReplace(const src: string; const _old, _new: string): string;

function c2pas_convert_if(const src: string): string;

function c2pas_convert_if2(const src: string): string;

function c2pas_convert_if3(const src: string): string;

function c2pas_convert_while1(const src: string): string;

function c2pas_convert_assignments(const src: string): string;

function c2pas_convert_for(const src: string): string;

function c2pas_convert_switch(const src: string): string;

function c2pas_parse(const lines: TStrings): string;

function c2pas_parse1(const lines: TStrings): string;

function c2pas_parse2(const lines: TStrings): string;

implementation

uses
  SysUtils, StrUtils, c2pas_memmgr, c2pas_utils;

function c2pas_doReplace(const src: string; const _old, _new: string): string;
begin
  Result := StringReplace(src, _old, _new, [rfReplaceAll, rfIgnoreCase]);
{  if Pos('', src) <> 0 then
    Result := Result + ' ';}
end;

type
  buffer_t = packed array[0..$1FFFF] of char;
  buffer_p = ^buffer_t;

function bufferlen(const b: buffer_p): integer;
begin
  Result := 0;
  while b[Result] <> #0 do
    Inc(Result);
end;

const
  FCT_NONE = 0;       // none
  FCT_BLANC = 1;      // white space
  FCT_COMMENT = 2;    // comment
  FCT_DEFINE = 3;     // defines, include etc
  FCT_SOURCE = 4;     // source code
  FCT_STRING = 5;     // string
  FCT_LAST = 5;       // last


type
  fracsource_t = record
    _string: buffer_p;
    _type: byte;
    _type2: byte;
  end;


  fracsource_array = array[0..8192 + 2048 - 1] of fracsource_t;
  pfracsource_array = ^fracsource_array;

  FracManager = class
  private
    fnumitems: integer;
    frealnumitems: integer;
    fitems: pfracsource_array;
    function Get(Index: Integer): string;
    procedure Put(Index: Integer; const S: string);
    function GetT(Index: Integer): integer;
    procedure PutT(Index: Integer; const t: integer);
    function GetT2(Index: Integer): integer;
    procedure PutT2(Index: Integer; const t: integer);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(const s: string; _type: integer; _type2: Integer = -1); overload;
    procedure Add(const p: buffer_p; _type: integer; _type2: integer = -1); overload;
    procedure Clear;
    property Strings[Index: Integer]: string read Get write Put; default;
    property Types[Index: Integer]: Integer read GetT write PutT;
    property Types2[Index: Integer]: Integer read GetT2 write PutT2;
    property Count: Integer read fnumitems;
  end;

constructor FracManager.Create;
begin
  fnumitems := 0;
  frealnumitems := 0;
  fitems := nil;
end;

procedure FracManager.Add(const s: string; _type: integer; _type2: Integer = -1);
var
  i: integer;
begin
  if Length(s) = 0 then
    exit;

  if fnumitems >= frealnumitems then
  begin
    ReallocMem(fitems, (frealnumitems + 1024) *  SizeOf(fracsource_t));
    frealnumitems := frealnumitems + 1024;
  end;
  GetMem(fitems[fnumitems]._string, (Length(s) + 1) * SizeOf(Char) and (not 15) + 16);
  for i := 1 to Length(s) do
    fitems[fnumitems]._string[i - 1] := s[i];
  fitems[fnumitems]._string[Length(s)] := #0;
  fitems[fnumitems]._type := _type;
  fitems[fnumitems]._type2 := _type2;
  Inc(fnumitems);
end;

procedure FracManager.Add(const p: buffer_p; _type: integer; _type2: Integer = -1);
var
  i: integer;
  len: integer;
begin
  if p[0] = #0 then
    exit;

  try
    if fnumitems >= frealnumitems then
    begin
      ReallocMem(fitems, (frealnumitems + 1024) *  SizeOf(fracsource_t));
      frealnumitems := frealnumitems + 1024;
    end;
    len := bufferlen(p);
    GetMem(fitems[fnumitems]._string, (len + 1) * SizeOf(Char) and (not 15) + 16);
    for i := 0 to len - 1 do
      fitems[fnumitems]._string[i] := p[i];
    fitems[fnumitems]._string[len] := #0;
    fitems[fnumitems]._type := _type;
    fitems[fnumitems]._type2 := _type2;
    Inc(fnumitems);
  except
    raise Exception.Create('FracManager.Add(): Invalid operation');
  end;
end;

procedure FracManager.Clear;
var
  i: integer;
begin
  for i := 0 to fnumitems - 1 do
  begin
    FreeMem(fitems[i]._string);
    fitems[i]._string := nil;
  end;
  fnumitems := 0;
  frealnumitems := 0;
  FreeMem(fitems);
  fitems := nil;
end;

destructor FracManager.Destroy;
begin
  Clear;
end;

function FracManager.Get(Index: Integer): string;
var
  i: integer;
begin
  if (index < 0) or (index >= fnumitems) then
    raise Exception.Create('FracManager.Get(): Invalid index');

  Result := '';
  if fitems[index]._type = FCT_NONE then
    exit;
    
  i := 0;
  while fitems[index]._string[i] <> #0 do
  begin
    Result := Result + fitems[index]._string[i];
    inc(i);
  end;
end;

procedure FracManager.Put(Index: Integer; const S: string);
var
  i: integer;
begin
  if (index < 0) or (index >= fnumitems) then
    raise Exception.Create('FracManager.Get(): Invalid index');

  FreeMem(fitems[index]._string);
  GetMem(fitems[index]._string, (Length(s) + 1) * SizeOf(Char) and (not 15) + 16);
  for i := 1 to Length(s) do
    fitems[index]._string[i - 1] := s[i];
  fitems[index]._string[Length(s)] := #0;
end;

function FracManager.GetT(Index: Integer): integer;
begin
  Result := fitems[index]._type;
end;

procedure FracManager.PutT(Index: Integer; const t: integer);
begin
  fitems[index]._type := t;
end;

function FracManager.GetT2(Index: Integer): integer;
begin
  Result := fitems[index]._type2;
end;

procedure FracManager.PutT2(Index: Integer; const t: integer);
begin
  fitems[index]._type2 := t;
end;

const
  fct_strings: array[FCT_NONE..FCT_LAST] of string = (
    '(*NONE*)',
    '(*BLANC*)',
    '(*COMMENT*)',
    '(*DEFINE*)',
    '(*SOURCE*)',
    '(*STRING*)'
  );

  ansi_c_reserved_words: array[0..31] of string = (
    'auto',
    'break',
    'case',
    'char',
    'const',
    'continue',
    'default',
    'do',
    'double',
    'else',
    'enum',
    'extern',
    'float',
    'for',
    'goto',
    'if',
    'int',
    'long',
    'register',
    'return',
    'short',
    'signed',
    'sizeof',
    'static',
    'struct',
    'switch',
    'typedef',
    'union',
    'unsigned',
    'void',
    'volatile',
    'while'
  );

  pascal_reserved_words: array[0..53] of string = (
    'absolute',
    'and',
    'array',
    'asm',
    'begin',
    'case',
    'const',
    'constructor',
    'destructor',
    'div',
    'do',
    'downto',
    'else',
    'end',
    'file',
    'for',
    'function',
    'goto',
    'if',
    'implementation',
    'in',
    'inherited',
    'inline',
    'interface',
    'label',
    'mod',
    'nil',
    'not',
    'object',
    'of',
    'on',
    'operator',
    'or',
    'packed',
    'procedure',
    'program',
    'record',
    'reintroduce',
    'repeat',
    'self',
    'set',
    'shl',
    'shr',
    'string',
    'then',
    'to',
    'type',
    'unit',
    'until',
    'uses',
    'var',
    'while',
    'with',
    'xor'
  );

  whitespacestr: string = ' '#13#10#9;
  symbolstr: string = '''[]{}()|&@^+-*/:?<>=%!.;,';

function whitespace(c: Char): Boolean;
begin
  Result := Pos(c, whitespacestr) > 0;
end;

function symbol(c: Char): Boolean;
begin
  Result := Pos(c, symbolstr) > 0;
end;

function pascalkeyword(const s: string): boolean;
var
  i: integer;
begin
  for i := Low(pascal_reserved_words) to High(pascal_reserved_words) do
    if s = pascal_reserved_words[i] then
    begin
      Result := true;
      exit;
    end;
  Result := false;
end;

function ansickeyword(const s: string): boolean;
var
  i: integer;
begin
  for i := Low(ansi_c_reserved_words) to High(ansi_c_reserved_words) do
    if s = ansi_c_reserved_words[i] then
    begin
      Result := true;
      exit;
    end;
  Result := false;
end;

type
  sourceanalisisitem_t = record
    _char: char;
    _type: byte;
  end;
  sourceanalisis_t = array[0..$FFF] of sourceanalisisitem_t;
  sourceanalisis_p = ^sourceanalisis_t;

  token_t = record
    _str: string;
    _type: byte;
    _type2: byte;
  end;

function ManagerToAnalisis(const m: FracManager): sourceanalisis_p;
var
  size: integer;
  i, j: integer;
  stmp: string;
  cnt: integer;
  len: integer;
  typ: byte;
begin
  size := 1;
  for i := 0 to m.Count - 1 do
  begin
    stmp := m.Strings[i];
    size := size + Length(stmp);
  end;
  GetMem(Result, size * SizeOf(sourceanalisisitem_t));

  cnt := 0;
  for i := 0 to m.Count - 1 do
  begin
    stmp := m.Strings[i];
    typ := m.Types[i];
    len := Length(stmp);
    for j := 1 to len do
    begin
      Result[cnt]._char := stmp[j];
      Result[cnt]._type := typ;
      Inc(cnt);
    end;
  end;

  Result[cnt]._char := #0;
  Result[cnt]._type := FCT_NONE;
end;

function analisis_nexttoken(a: sourceanalisis_p; var start: integer): token_t;
var
  i: integer;
  blocktyp: integer;
begin
  Result._str := '';
  Result._type := a[start]._type;
  Result._type2 := 255;
  i := start;
  while true do
  begin
    if a[i]._type = FCT_NONE then
    begin
      Result._str := #0;
      Result._type := FCT_NONE;
      Result._type2 := FCT_NONE;
      start := i;
      exit;
    end;
    while whitespace(a[i]._char) do
    begin
      a[i]._type := FCT_BLANC;
      Result._str := Result._str + '#' + IntToStr(Ord(a[i]._char));
      Inc(i);
    end;
    if Result._str <> '' then
    begin
      start := i;
      exit;
    end;
    start := i;
    while a[i]._type <> FCT_NONE do
    begin
{      while whitespace(a[i]._char) do
        Inc(i);}
      if a[i]._type <> FCT_SOURCE then
      begin
        blocktyp := a[i]._type;
        while a[i]._type = blocktyp do
        begin
          Result._str := Result._str + a[i]._char;
          Result._type := blocktyp;
          Inc(i);
        end;
        start := i + 1;
        Exit;
      end;
      if a[i]._type = FCT_SOURCE then
      begin
        if symbol(a[i]._char) then
        begin
          start := i + 1;
          Result._str := a[i]._char;
          if a[i]._char = '+' then
          begin
            if a[i + 1]._char in ['+', '='] then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '-' then
          begin
            if a[i + 1]._char in ['-', '=', '>'] then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '/' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '*' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '=' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '!' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '>' then
          begin
            if a[i + 1]._char in ['=', '>'] then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '<' then
          begin
            if a[i + 1]._char in ['=', '>', '<'] then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '|' then
          begin
            if a[i + 1]._char = '|' then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '&' then
          begin
            if a[i + 1]._char = '&' then
            begin
              Result._str := Result._str + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          Exit;
        end
        else
        begin
          while not symbol(a[i]._char) and not whitespace(a[i]._char) do
          begin
            Result._str := Result._str + a[i]._char;
            Inc(i);
          end;
          start := i;
          exit;
        end;
      end;
      Inc(i);
    end;
  end;
end;


function analisis_nextword(a: sourceanalisis_p; var start: integer): string;
var
  i: integer;
  blocktyp: integer;
begin
  Result := '';
  i := start;
  while true do
  begin
    if a[i]._type = FCT_NONE then
    begin
      start := i;
      exit;
    end;
    while whitespace(a[i]._char) do
    begin
      a[i]._type := FCT_BLANC;
      Result := Result + '#' + IntToStr(Ord(a[i]._char));
      Inc(i);
    end;
    if Result <> '' then
    begin
      start := i;
      exit;
    end;
    start := i;
    while a[i]._type <> FCT_NONE do
    begin
      while whitespace(a[i]._char) do
        Inc(i);
      if a[i]._type <> FCT_SOURCE then
      begin
        blocktyp := a[i]._type;
        while a[i]._type = blocktyp do
        begin
          Result := Result + a[i]._char;
          Inc(i);
        end;
        start := i + 1;
        Exit;
      end;
      if a[i]._type = FCT_SOURCE then
      begin
        if symbol(a[i]._char) then
        begin
          start := i + 1;
          Result := a[i]._char;
          if a[i]._char = '+' then
          begin
            if a[i + 1]._char in ['+', '='] then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '-' then
          begin
            if a[i + 1]._char in ['-', '=', '>'] then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '/' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '*' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '=' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '!' then
          begin
            if a[i + 1]._char = '=' then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '>' then
          begin
            if a[i + 1]._char in ['=', '>'] then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '<' then
          begin
            if a[i + 1]._char in ['=', '>', '<'] then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '|' then
          begin
            if a[i + 1]._char = '|' then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          if a[i]._char = '&' then
          begin
            if a[i + 1]._char = '&' then
            begin
              Result := Result + a[i + 1]._char;
              Inc(start);
            end;
            Exit;
          end;
          Exit;
        end
        else
        begin
          while not symbol(a[i]._char) and not whitespace(a[i]._char) do
          begin
            Result := Result + a[i]._char;
            Inc(i);
          end;
          start := i;
          exit;
        end;
      end;
      Inc(i);
    end;
  end;
end;

procedure AnalisisToManager(const m: FracManager; const a: sourceanalisis_p);
var
  token: token_t;
  i: integer;
begin
  i := 0;
  m.Clear;

  while a[i]._type <> FCT_NONE do
  begin
    token._type := a[i]._type;
    token._type2 := a[i]._type;
    token._str := analisis_nextword(a, i) + ' ';
    m.Add(token._str, token._type, token._type2)
  end;

{  while true do
  begin
    token := analisis_nexttoken(a, i);
    if token._type <> FCT_NONE then
      m.Add(token._str, token._type, token._type2)
    else
      exit;
  end;}
end;

procedure AnalisisToManager2(const m: FracManager; const a: sourceanalisis_p);
var
  i: integer;
  stmp: string;
  lasttyp: byte;
begin
  lasttyp := FCT_NONE;
  stmp := '';
  m.Clear;
  i := -1;
  repeat
    Inc(i);
    if lasttyp <> a[i]._type then
    begin
      if stmp <> '' then
      begin
        m.Add(stmp, lasttyp);
        stmp := '';
      end;
      lasttyp := a[i]._type;
    end;
    stmp := stmp + a[i]._char;
  until a[i]._type = FCT_NONE;
end;

function SearchAnalisis(a: sourceanalisis_p; c: Char; x1, x2: integer): integer;
var
  i: integer;
  dx: Integer;
begin
  if x1 = x2 then
  begin
    if a[x1]._char = c then
      Result := x1
    else
      Result := -1;
    exit;
  end;

  Result := -1;

  if x1 < x2 then
    dx := 1
  else
    dx := -1;

  i := x1;
  while i <> x2 do
  begin
    if a[i]._char = c then
    begin
      Result := i;
      exit;
    end;
    if a[i]._type = FCT_NONE then
      exit;
    i := i + dx;
  end;
end;

procedure analisis_defines(a: sourceanalisis_p);
var
  i, j: integer;
begin
  i := 0;
  while a[i]._type <> FCT_NONE do
  begin
    if (a[i]._char = '#') and (a[i]._type = FCT_SOURCE) then
    begin
      if (i = 0) or (a[i - 1]._char = #10) then
      begin
        repeat
          j := i;
          while (a[i]._char <> #10) and (a[i]._type in [FCT_SOURCE, FCT_STRING]) do
          begin
            a[i]._type := FCT_DEFINE;
            Inc(i);
            if a[i]._type = FCT_NONE then
              exit;
          end;
          Inc(i);
        until SearchAnalisis(a, '\', i - 2, j + 1) = -1;
      end
      else
        inc(i);
    end
    else
    begin
      Inc(i);
    end;
  end;
end;

procedure analisis_whitespace(a: sourceanalisis_p);
var
  i: integer;
begin
  i := 0;
  while a[i]._type <> FCT_NONE do
  begin
    if a[i]._type = FCT_SOURCE then
      if whitespace(a[i]._char) then
        a[i]._type := FCT_BLANC;
    Inc(i);
  end;
end;

function _blanks(const s: string): string;
var
  i: integer;
  s1: string;
  l: TStringList;
begin
  Result := '';
  l := str2list(s, ['#']);
  for i := 0 to l.Count - 1 do
  begin
    s1 := Trim(l.strings[i]);
    if s1 <> '' then
      Result := Result + Chr(StrToIntDef(s1, 32));
  end;
  l.free;
end;

type
  PascalConvertor = class
  private
    fmanager: FracManager;
    _fuses: TStringList;
    _fconsts: TStringList;
    _fprocs: TStringList;
    _ftypes: TStringList;
    _fvars: TStringList;
    fparent: PascalConvertor;
    fparent_l0: PascalConvertor;
    fparent_l1: PascalConvertor;
    function Getuses: string;
    function Getconsts: string;
    function Getprocs: string;
    function Gettypes: string;
    function Getvars: string;
    function Searchforward(const x: integer; const sr: string): integer;
    procedure ReplaceTokens(const _from, _to: integer; const _old, _new: string);
    function tokenrange(const _from, _to: integer): string;
    function nexttoken(const x: Integer): integer;
    function CheckConst(var pos: integer): string;
    procedure InitArraysPass;
    procedure InitTypeDefEnumsPass;
  public
    constructor Create(m: FracManager; p: PascalConvertor = nil; _lo: integer = -1; _hi: integer = -1); virtual;
    destructor Destroy; override;
    function GetPascalText: string;
    function FinalPass: string;
  end;

constructor PascalConvertor.Create(m: FracManager; p: PascalConvertor = nil; _lo: integer = -1; _hi: integer = -1);
var
  i: integer;
  pp: PascalConvertor;
begin
  _fuses := TStringList.Create;
  _fprocs := TStringList.Create;
  _fconsts := TStringList.Create;
  _ftypes := TStringList.Create;
  _fvars := TStringList.Create;

  fparent := p;
  if p = nil then
  begin
    fparent_l0 := Self;
    fparent_l1 := Self;
  end
  else
  begin
    pp := p;
    while pp.fparent <> nil do
      pp := pp.fparent;
    fparent_l0 := pp;
    fparent_l1 := pp.fparent;
  end;

  if _lo = -1 then
    _lo := 0;
  if _hi = -1 then
    _hi := m.Count - 1;

  fmanager := FracManager.Create;
  for i := _lo to _hi do
    fmanager.Add(m.Strings[i], m.Types[i], m.Types2[2]);
end;

destructor PascalConvertor.Destroy;
begin
  fmanager.Free;
  _fuses.Free;
  _fconsts.Free;
  _fvars.Free;
  _ftypes.Free;
  _fprocs.Free;
end;

function PascalConvertor.Getuses: string;
var
  i: integer;
begin
  if _fuses.Count = 0 then
  begin
    Result := '';
    exit;
  end;
  Result := 'uses'#13#10;
  for i := 0 to _fuses.Count - 1 do
  begin
    Result := Result + '  ' + _fuses.Strings[i];
    if i = _fuses.Count - 1 then
      Result := Result + ';'#13#10
    else
      Result := Result + ','#13#10;
  end;
  Result := Result + #13#10;
end;

function PascalConvertor.Getconsts: string;
var
  i: integer;
begin
  if _fconsts.Count = 0 then
  begin
    Result := '';
    exit;
  end;
  Result := Result + 'const'#13#10;
  for i := 0 to _fconsts.Count - 1 do
    Result := Result + _fconsts.Strings[i] + #13#10;
  Result := Result + #13#10;
end;

function PascalConvertor.Getprocs: string;
var
  i: integer;
begin
  if _fprocs.Count = 0 then
  begin
    Result := '';
    exit;
  end;
  for i := 0 to _fprocs.Count - 1 do
    Result := Result + _fprocs.Strings[i] + #13#10#13#10;
  Result := Result + #13#10;
end;

function PascalConvertor.Gettypes: string;
var
  i: integer;
begin
  if _ftypes.Count = 0 then
  begin
    Result := '';
    exit;
  end;
  Result := Result + 'type'#13#10;
  for i := 0 to _ftypes.Count - 1 do
    Result := Result + _ftypes.Strings[i] + #13#10;
  Result := Result + #13#10;
end;

function PascalConvertor.Getvars: string;
var
  i: integer;
begin
  if _fvars.Count = 0 then
  begin
    Result := '';
    exit;
  end;
  Result := Result + 'var'#13#10;
  for i := 0 to _fvars.Count - 1 do
    Result := Result + _fvars.Strings[i] + #13#10;
  Result := Result + #13#10;
end;


function PascalConvertor.Searchforward(const x: integer; const sr: string): integer;
var
  ii: integer;
begin
  for ii := x to fmanager.Count - 1 do
    if fmanager.Strings[ii] = sr then
    begin
      Result := ii;
      exit;
    end;
  Result := -1;
end;

procedure PascalConvertor.ReplaceTokens(const _from, _to: integer; const _old, _new: string);
var
  i: integer;
begin
  for i := _from to _to do
    if fmanager.Strings[i] = _old then
      fmanager.Strings[i] := _new;
end;

// Next not blanc token
function PascalConvertor.nexttoken(const x: Integer): integer;
begin
  Result := x + 1;
  while fmanager.Types[Result] <> FCT_SOURCE do
  begin
    if fmanager.Types[Result] = FCT_NONE then
    begin
      Result := -1;
      exit;
    end;
    Inc(Result);
  end;
end;

function PascalConvertor.tokenrange(const _from, _to: integer): string;
var
  i: integer;
begin
  Result := '';
  for i := _from to _to do
    if fmanager.Types[i] = FCT_BLANC then
      Result := Result + _blanks(fmanager.Strings[i])
    else
      Result := Result + fmanager.Strings[i];
end;

function PascalConvertor.CheckConst(var pos: integer): string;
var
  p_equal: integer;
  p_stop: integer;
  p_br1, p_br2: integer;
  i_var, i_type: integer;
  next: integer;
  n: TStringList;
  i: integer;
  x: integer;
begin
  Result := '';
  if fmanager.Types[pos] <> FCT_SOURCE then
    exit;

  next := nexttoken(pos);
  if next = -1 then
    Exit;

  if fmanager.Strings[pos] = 'static' then
    if fmanager.Strings[next] = 'const' then
      pos := next;

  if fmanager.Strings[pos] <> 'const' then
    Exit;

  if pos > fmanager.Count - 5 then
    exit;

  p_equal := Searchforward(pos + 1, '=');
  if p_equal < 0 then
    exit;

  p_stop := Searchforward(pos + 1, ';');

  if p_stop < p_equal then
    exit;

  if not checkbracketsclosed(tokenrange(pos + 1, p_equal - 1), '[', ']') then
    exit;

  p_br1 := Searchforward(pos + 1, '[');
  p_br2 := Searchforward(pos + 1, ']');

  if ((p_br1 = -1) and (p_br2 = -1)) or ((p_br1 > p_stop) and (p_br2 > p_stop)) then
  begin // Single const
  end
  else
  begin
    i_type := nexttoken(pos);
    i_var := nexttoken(i_type);

    n := TStringList.Create;

    i := nexttoken(i_var);
    while True do
    begin
      if i = p_equal then break;

      if fmanager.Strings[i] <> '[' then
      begin
        n.free;
        exit;
      end;

      i := nexttoken(i);
      if fmanager.Strings[i] = ']' then
        n.Add('')
      else
      begin
        if not IsInteger(fmanager.Strings[i]) then
        begin
          n.free;
          exit;
        end;

        n.Add(fmanager.Strings[i]);

        i := nexttoken(i);
        if fmanager.Strings[i] <> ']' then
        begin
          n.free;
          exit;
        end;

        i := nexttoken(i);
      end;

      ReplaceTokens(p_equal + 1, p_stop, '{', '(');
      ReplaceTokens(p_equal + 1, p_stop, '}', ')');

      Result := #13#10'const'#13#10 +
                '  ' + fmanager.Strings[i_var] + ': array';

      for x := 0 to n.Count - 1 do
        Result := Result + '[0..' + n.Strings[x] + ']';

      Result := Result + ' of ' +
                fmanager.Strings[i_type] + ' == ' +
                tokenrange(p_equal + 1, p_stop);
      pos := p_stop;
    end;
    n.Free;
  end;
end;

procedure PascalConvertor.InitArraysPass;
var
  i: integer;
  prevblock: integer;
  p_stop: integer;

  procedure _check;
  var
    i_type: integer;
    i_var: integer;
    eq_pos: integer;
    xx: integer;
  begin
    i_type := nexttoken(prevblock);
    if i_type = -1 then
      exit;

    i_var := nexttoken(i_type);
    if i_var = -1 then
      Exit;

    if not IsIdentifier(fmanager.Strings[i_type]) then
      Exit;

    if not IsIdentifier(fmanager.Strings[i_var]) then
      Exit;

    eq_pos := Searchforward(i_var, '=');
    if eq_pos = -1 then
      Exit;

    if eq_pos > p_stop then
      Exit;

    if not checkbracketsclosed(tokenrange(eq_pos + 1, p_stop - 1), '{', '}') then
      exit;

    xx := eq_pos;
    while xx < p_stop do
    begin
      xx := nexttoken(xx);
      if (fmanager.Strings[xx] = '{') or (fmanager.Strings[xx] = ',') or (fmanager.Strings[xx] = '}') or (IsInteger(fmanager.Strings[xx])) then
        Continue;
      if (fmanager.Strings[xx] = ';') then
        if xx = p_stop then
          break;
      exit;
    end;
    ReplaceTokens(eq_pos + 1, p_stop - 1, '{', '(');
    ReplaceTokens(eq_pos + 1, p_stop - 1, '}', ')');
    fmanager.Strings[eq_pos] := '==';
  end;

begin
  i := 0;
  prevblock := -1;
  while i < fmanager.Count - 2 do
  begin
    p_stop := Searchforward(i, ';');
    if p_stop = -1 then
      exit;

    _check;
    prevblock := i;
    i := p_stop + 1;
  end;
end;

procedure PascalConvertor.InitTypeDefEnumsPass;
var
  i: integer;
  prevblock: integer;
  p_stop: integer;

  procedure _check;
  var
    i_type: integer;
    i_enum: integer;
    i_var: integer;
  begin
    i_type := nexttoken(prevblock);
    if i_type = -1 then
      exit;

    if fmanager.Strings[i_type] <> 'typedef' then
      Exit;

    i_enum := nexttoken(i_type);
    if i_enum = -1 then
      Exit;

    if fmanager.Strings[i_enum] <> 'enum' then
      Exit;

    i_var := nexttoken(i_enum);
    if i_var = -1 then
      Exit;

    if not IsIdentifier(fmanager.Strings[i_var]) then
      Exit;

    if not checkbracketsclosed(tokenrange(i_var + 1, p_stop - 1), '{', '}') then
      exit;

(*    xx := i_var;
    while xx < p_stop do
    begin
      xx := nexttoken(xx);
      if (fmanager.Strings[xx] = '{') or (fmanager.Strings[xx] = '=') or (fmanager.Strings[xx] = ',') or (fmanager.Strings[xx] = '}') or (IsInteger(fmanager.Strings[xx]) or (IsIdentifier(fmanager.Strings[xx]))) then
        Continue;
      if (fmanager.Strings[xx] = ';') then
        if xx = p_stop then
          break;
      exit;
    end;*)
    ReplaceTokens(i_var + 1, p_stop - 1, '{', '(');
    ReplaceTokens(i_var + 1, p_stop - 1, '}', ')');
    ReplaceTokens(i_var + 1, p_stop - 1, '=', '==');
  end;

begin
  i := 0;
  prevblock := -1;
  while i < fmanager.Count - 2 do
  begin
    p_stop := Searchforward(i, ';');
    if p_stop = -1 then
      exit;

    _check;
    prevblock := i;
    i := p_stop + 1;
  end;
end;

function PascalConvertor.GetPascalText: string;
var
  i: integer;
  _typ: byte;
  _str: string;
  s1, s2: string;
  dowhitespace: boolean;
  s_ret: string;
begin
  InitArraysPass;
  InitTypeDefEnumsPass;
  i := 0;
  dowhitespace := true;
  while i < fmanager.Count - 1 do
  begin
    _typ := fmanager.Types[i];
    if _typ = FCT_NONE then
      break;
    _str := fmanager.Strings[i];
    if _typ = FCT_BLANC then
    begin
      if dowhitespace then
        Result := Result + _blanks(_str);
      Inc(i);
      Continue;
    end;
    if _typ = FCT_COMMENT then
    begin
      Result := Result + _str;
      Inc(i);
      Continue;
    end;
    if _typ = FCT_DEFINE then
    begin
      dowhitespace := False;
      if Pos('#include ', _str) = 1 then
      begin
        _str := c2pas_doReplace(Trim(RightStr(_str, Length(_str) - 9)), '.', '_');
        fparent_l0._fuses.add(removequotes(_str, ['"', '<', '>']));
      end
      else if Pos('#define ', _str) = 1 then
      begin
        _str := Trim(RightStr(_str, Length(_str) - 8));
        s1 := Trim(firstword(_str));
        s2 := Trim(secondword(_str));
        if s2 <> '' then
        begin
          if IsNumeric(s2) then
            fparent_l0._fconsts.Add('  ' + s1 + ' = ' + s2 + ';')
          else
            fparent_l0._ftypes.Add('  ' + s1 + ' = ' + s2 + ';');
        end
        else
        begin
          Result := Result + '{$DEFINE ' + s1 + '}';
          dowhitespace := true;
        end;
      end
      else if Pos('#ifdef ', _str) = 1 then
      begin
        _str := Trim(RightStr(_str, Length(_str) - 6));
        s1 := Trim(firstword(_str));
        s2 := Trim(secondword(_str));
        Result := Result + '{$IFDEF ' + s1 + '} ' + s2 + #13#10;
        dowhitespace := true;
      end
      else if Pos('#ifndef ', _str) = 1 then
      begin
        _str := Trim(RightStr(_str, Length(_str) - 7));
        s1 := Trim(firstword(_str));
        s2 := Trim(secondword(_str));
        Result := Result + '{$IFNDEF ' + s1 + '} ' + s2 + #13#10;
        dowhitespace := true;
      end
      else if Pos('#endif ', _str) = 1 then
      begin
        _str := Trim(RightStr(_str, Length(_str) - 6));
        Result := Result + '{$ENDIF} ' + _str + #13#10;
        dowhitespace := true;
      end;
      Inc(i);
      Continue;
    end;
    dowhitespace := True;
    if (not ansickeyword(_str)) and pascalkeyword(_str) then
      Result := Result + _str + '_1'
    else if (fmanager.Types[i] = FCT_SOURCE) and (fmanager.Strings[i] = 'Object') then
    begin
      fmanager.Strings[i] := 'obj_t';
      Result := Result + 'obj_t';
    end
    else
    begin
      s_ret := CheckConst(i);
      if s_ret <> '' then
        Result := Result + s_ret
      else
        Result := Result + _str;
    end;
    Inc(i);
  end;

  Result := 'unit unit1;'#13#10#13#10'interface'#13#10#13#10 +
            Getuses +
            Getconsts +
            Gettypes +
            Getvars +
            Getprocs +
            'implementation'#13#10#13#10 +
            Result +
            #13#10#13#10'end.';

end;

function PascalConvertor.FinalPass: string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to fmanager.Count - 1 do
  begin
    if fmanager.Types[i] = FCT_SOURCE then
      if fmanager.Strings[i] = 'Object' then
        fmanager.Strings[i] := 'obj_t';
    Result := Result + fmanager.Strings[i];
  end;
end;

function c2pas_parse(const lines: TStrings): string;
var
  i, j: integer;
  text_start: integer;
  code_start: integer;
  s1, s2, s3: string;
  frac: buffer_t;
  fi: integer;
  src: string;
  analisis: sourceanalisis_p;
  manager: FracManager;
  l: TStringList;
begin
  if lines = nil then
  begin
    Result := '';
    Exit;
  end;

  if lines.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  if Trim(lines.Text) = '' then
  begin
    Result := '';
    Exit;
  end;

  manager := FracManager.Create;
  manager.Clear;

  l := TStringList.Create;
  for i := 0 to lines.Count - 1 do
    l.Add(lines.strings[i] + ' ');
{  src := '';
  for i := 0 to lines.Count - 1 do
    src := src + lines.Strings[i] + ' '#13#10;}

  src := l.Text;

  l.Free;

  src := c2pas_doReplace(src, #13#10, #10);

  Result := '';

  s1 := src;
  s2 := '';
  s3 := '';

  frac[0] := #0;
  code_start := 1;

  // First Pass -> Identify strings and comments
  i := 0;
  while i < Length(src) - 1 do
  begin
    Inc(i);

    if src[i] in ['''', '"'] then
    try
      fi := 0;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      text_start := i;
      fi := 0;
      frac[fi] := src[i];
      Inc(i);
      Inc(fi);
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if src[i] = src[text_start] then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_STRING);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing string');
    end;

    if (src[i] = '/') and (src[i + 1] = '/') then
    try
      fi := 0;;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      fi := 0;
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if src[i] = #10 then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_COMMENT);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing comment (//)');
    end;

    if (src[i] = '/') and (src[i + 1] = '*') then
    try
      fi := 0;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      fi := 0;
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if (src[i - 1] = '*') and (src[i] = '/') then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_COMMENT);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing comment (/*..*/)');
    end;

  end;

  fi := 0;
  for j := code_start to Length(src) do
  begin
    frac[fi] := src[j];
    Inc(fi);
  end;
  frac[fi] := #0;
  manager.Add(@frac, FCT_SOURCE);

  // Second Pass ->
  analisis := ManagerToAnalisis(manager);
  analisis_defines(analisis);
  analisis_whitespace(analisis);
  AnalisisToManager(manager, analisis);
{  i := 0;
  Result := '';
  while analisis[i]._type <> FCT_NONE do
    Result := Result + analisis_nextword(analisis, i) + #13#10;}
  with PascalConvertor.Create(manager) do
  try
    Result := GetPascalText;
  finally
    free;
  end;
  FreeMem(analisis);

  manager.Free;
end;

function c2pas_parse1(const lines: TStrings): string;
var
  i, j: integer;
  text_start: integer;
  code_start: integer;
  s1, s2, s3: string;
  frac: buffer_t;
  fi: integer;
  len: integer;
  stmp: string;
  src: string;
  l: TStringList;
  manager: FracManager;
begin
  if lines = nil then
  begin
    Result := '';
    Exit;
  end;

  if lines.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  if Trim(lines.Text) = '' then
  begin
    Result := '';
    Exit;
  end;

  manager := FracManager.Create;
  manager.Clear;

  l := TStringList.Create;
  for i := 0 to lines.Count - 1 do
    l.Add(lines.Strings[i] + ' ');

  src := l.Text;

  l.Free;

  Result := '';

  s1 := src;
  s2 := '';
  s3 := '';

  frac[0] := #0;
  code_start := 1;

  // First Pass -> Identify strings and comments
  i := 0;
  while i < Length(src) - 1 do
  begin
    Inc(i);

    if src[i] in ['''', '"'] then
    try
      fi := 0;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      text_start := i;
      fi := 0;
      frac[fi] := src[i];
      Inc(i);
      Inc(fi);
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if src[i] = src[text_start] then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_STRING);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing string');
    end;

    if (src[i] = '/') and (src[i + 1] = '/') then
    try
      fi := 0;;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      fi := 0;
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if src[i] = #10 then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_COMMENT);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing comment (//)');
    end;

    if (src[i] = '/') and (src[i + 1] = '*') then
    try
      fi := 0;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      fi := 0;
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if (src[i - 1] = '*') and (src[i] = '/') then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_COMMENT);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing comment (/*..*/)');
    end;

  end;

  fi := 0;
  for j := code_start to Length(src) do
  begin
    frac[fi] := src[j];
    Inc(fi);
  end;
  frac[fi] := #0;
  manager.Add(@frac, FCT_SOURCE);

  for i := 0 to manager.Count - 1 do
  begin
    if manager.types[i] = FCT_STRING then
    begin
      try
        stmp := manager.strings[i];
        stmp[1] := '''';
        stmp[Length(stmp)] := '''';
        if stmp = '''\0''' then
          stmp := '#0'
        else if stmp = '''\r''' then
          stmp := '#13'
        else if stmp = '''\n''' then
          stmp := '#10';

        manager.strings[i] := stmp;
      except
        raise Exception.Create('C2Pas(): Error while parsing string (replace pass)');
      end;
    end
    else if manager.types[i] = FCT_SOURCE then
    begin
      try
        stmp := manager.strings[i];
        stmp := c2pas_doReplace(stmp, #13#10, #10);
        stmp := c2pas_doReplace(stmp, #10, #13#10);
        stmp := c2pas_doReplace(stmp, #9, '  ');
        stmp := c2pas_doReplace(stmp, ' % ', ' mod ');
        stmp := c2pas_doReplace(stmp, '{ ', ' begin ');
        stmp := c2pas_doReplace(stmp, ' }', ' end ');
        stmp := c2pas_doReplace(stmp, #13#10'}'#13#10, #13#10'end;'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10' end ', #13#10'end ');
        stmp := c2pas_doReplace(stmp, #13#10'end '#13#10, #13#10'end;'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10' begin ', #13#10'begin ');
        stmp := c2pas_doReplace(stmp, ':=', #255#253);
        stmp := c2pas_doReplace(stmp, #255#253, ' = ');
        stmp := c2pas_doReplace(stmp, ' = ', ' := ');
        stmp := c2pas_doReplace(stmp, ' == ', ' = ');
        stmp := c2pas_doReplace(stmp, ' != ', ' <> ');
        stmp := c2pas_doReplace(stmp, '->', '^.');
        stmp := c2pas_doReplace(stmp, ' >> ', ' shr ');
        stmp := c2pas_doReplace(stmp, ' << ', ' shl ');
        stmp := c2pas_doReplace(stmp, ' 0x', ' $');
        stmp := c2pas_doReplace(stmp, '(0x', '($');
        stmp := c2pas_doReplace(stmp, ' & ', ' and ');
        stmp := c2pas_doReplace(stmp, ' | ', ' or ');
        stmp := c2pas_doReplace(stmp, '!', ' not ');
        stmp := c2pas_doReplace(stmp, ' return;', ' Exit;');
        stmp := c2pas_doReplace(stmp, ' NULL ', ' nil ');
        stmp := c2pas_doReplace(stmp, ' NULL;', ' nil;');
        stmp := c2pas_doReplace(stmp, ' NULL)', ' nil)');
        stmp := c2pas_doReplace(stmp, ' NULL,', ' nil,');
        stmp := c2pas_doReplace(stmp, '(NULL,', '(nil,');
        stmp := c2pas_doReplace(stmp, '(NULL)', '(nil)');
        stmp := c2pas_doReplace(stmp, #10'void ', #10'procedure ');
        stmp := c2pas_doReplace(stmp, #10'static void ', #10'procedure ');
        stmp := c2pas_doReplace(stmp, #10'static  void ', #10'procedure ');
        stmp := c2pas_doReplace(stmp, #10'procedure *', #10'void *');
        stmp := c2pas_doReplace(stmp, #10'static void ', #10'procedure ');
        stmp := c2pas_doReplace(stmp, #10'procedure *', #10'static void *');
        stmp := c2pas_doReplace(stmp, '( not ', '(not ');
        stmp := c2pas_convert_if(stmp);
        stmp := c2pas_doReplace(stmp, ') && (', ') and (');
        stmp := c2pas_doReplace(stmp, ' && ', ') and (');
        stmp := c2pas_doReplace(stmp, ') || (', ') or (');
        stmp := c2pas_doReplace(stmp, ' || ', ') or (');
        stmp := c2pas_convert_if2(stmp);
        stmp := c2pas_doReplace(stmp, '(&', '(@');
        stmp := c2pas_doReplace(stmp, '( not ', '(not ');
        stmp := c2pas_doReplace(stmp, ' '#13#10, #13#10);
        stmp := c2pas_doReplace(stmp, ':= &', ':= @');
        stmp := c2pas_doReplace(stmp, ' then  ', ' then ');
        stmp := c2pas_convert_for(stmp);
        stmp := c2pas_doReplace(stmp, ' ? true : false;'#13#10, ' <> 0;'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10' return true;'#13#10'end'#13#10#13#10, #13#10' Result := true;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10' return false;'#13#10'end'#13#10#13#10, #13#10' Result := false;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  return true;'#13#10'end'#13#10#13#10, #13#10'  Result := true;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  return false;'#13#10'end'#13#10#13#10, #13#10'  Result := false;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  return true;'#13#10'end;'#13#10#13#10, #13#10'  Result := true;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  return false;'#13#10'end;'#13#10#13#10, #13#10'  Result := false;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, '(void)'#13#10, ';'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  end else if ', #13#10'  end'#13#10'  else if ');
        stmp := c2pas_doReplace(stmp, #13#10'    end else if ', #13#10'    end'#13#10'    else if ');
        stmp := c2pas_doReplace(stmp, #13#10#13#10#13#10, #13#10#13#10);
        stmp := c2pas_doReplace(stmp, ' end  else  begin'#13#10, ' end else begin'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  end else begin'#13#10, #13#10'  end'#13#10'  else'#13#10'  begin'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'    end else begin'#13#10, #13#10'    end'#13#10'    else'#13#10'    begin'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'      end else begin'#13#10, #13#10'      end'#13#10'      else'#13#10'      begin'#13#10);
        stmp := c2pas_doReplace(stmp, ' case ', ' ');
        stmp := c2pas_doReplace(stmp, #13#10'  while (true) begin'#13#10, #13#10'  while true do'#13#10'  begin'#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'    while (true) begin'#13#10, #13#10'    while true do'#13#10'    begin'#13#10);
        stmp := c2pas_convert_if3(stmp);
        stmp := c2pas_convert_while1(stmp);
        stmp := c2pas_convert_assignments(stmp);
        stmp := c2pas_doReplace(stmp, #13#10'end '#13#10, #13#10'end;'#13#10);
        stmp := c2pas_doReplace(stmp, ' ;', ';');

        stmp := c2pas_convert_switch(stmp);
        stmp := c2pas_doReplace(stmp, ' switch(', ' case ');

        stmp := c2pas_doReplace(stmp, #13#10'  return true;'#13#10'}'#13#10#13#10, #13#10'  Result := true;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'  return false;'#13#10'}'#13#10#13#10, #13#10'  Result := false;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, ';'#13#10'}'#13#10#13#10, ';'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, ';'#13#10'}'#13#10#13#10, ';'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, 'end '#13#10'}'#13#10#13#10, 'end;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, 'end '#13#10'}'#13#10#13#10, 'end;'#13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'}'#13#10#13#10, #13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, #13#10'} '#13#10#13#10, #13#10'end;'#13#10#13#10);
        stmp := c2pas_doReplace(stmp, '(void)'#13#10, ';'#13#10);

        ////////////////////////////////////////////////////
        stmp := c2pas_doReplace(stmp, #9, '  ');
        stmp := c2pas_doReplace(stmp, '( )', '()');
        stmp := c2pas_doReplace(stmp, '  if   ', '  if ');
        stmp := c2pas_doReplace(stmp, '  if   ', '  if ');
        stmp := c2pas_doReplace(stmp, ' if  ', ' if ');
        stmp := c2pas_doReplace(stmp, ' then  ', ' then ');
        stmp := c2pas_doReplace(stmp, '  :=  ', ' := ');
        stmp := c2pas_doReplace(stmp, '  =  ', ' = ');
        stmp := c2pas_doReplace(stmp, '  +  ', ' + ');
        stmp := c2pas_doReplace(stmp, '  -  ', ' - ');
        stmp := c2pas_doReplace(stmp, '  *  ', ' * ');
        stmp := c2pas_doReplace(stmp, '  /  ', ' / ');
        stmp := c2pas_doReplace(stmp, '  >  ', ' > ');
        stmp := c2pas_doReplace(stmp, '  >=  ', ' >= ');
        stmp := c2pas_doReplace(stmp, '  <  ', ' < ');
        stmp := c2pas_doReplace(stmp, '  <=  ', ' <= ');
        stmp := c2pas_doReplace(stmp, '  <>  ', ' <> ');
        stmp := c2pas_doReplace(stmp, ' ^. ', '^.');
        stmp := c2pas_doReplace(stmp, ' . ', '.');
        stmp := c2pas_doReplace(stmp, ' . ', '.');
        stmp := c2pas_doReplace(stmp, ' return;', ' Exit;');
        stmp := c2pas_doReplace(stmp, '  and  ', ' and ');
        stmp := c2pas_doReplace(stmp, '  or  ', ' or ');
        stmp := c2pas_doReplace(stmp, '  shr  ', ' shr ');
        stmp := c2pas_doReplace(stmp, ' [', '[');
        stmp := c2pas_doReplace(stmp, '[ ', '[');
        stmp := c2pas_doReplace(stmp, ' ]', ']');
        stmp := c2pas_doReplace(stmp, '] ', ']');
        stmp := c2pas_doReplace(stmp, ',  ', ', ');
        stmp := c2pas_doReplace(stmp, 'procedure  ', 'procedure ');

        manager.strings[i] := stmp;
      except
        raise Exception.Create('C2Pas(): Error while parsing source block (replace pass)');
      end;
    end
    else if manager.types[i] = FCT_DEFINE then
    begin
      try
        stmp := manager.strings[i];
        stmp := c2pas_doReplace(stmp, '#include ', '//- #include ');
        manager.strings[i] := stmp;
      except
        raise Exception.Create('C2Pas(): Error while parsing defines block (replace pass)');
      end;
    end
    else if manager.types[i] = FCT_COMMENT then
    begin
      try
        manager.strings[i] := c2pas_doReplace(manager.strings[i], #9, '  ');
        len := Length(manager.strings[i]);
        if len >= 4 then
        begin
          stmp := manager.strings[i];
          if (stmp[1] = '/') and (stmp[2] = '*') then
            stmp[1] := '(';
          if (stmp[len] = '/') and (stmp[len - 1] = '*') then
            stmp[len] := ')';
          manager.strings[i] := stmp;
        end;
      except
        raise Exception.Create('C2Pas(): Error while parsing comment (replace pass)');
      end;
    end;
  end;

{  for i := 0 to manager.Count - 2 do
    if Pos('procedure ', manager.Strings[i]) = 1 then
      if Pos('begin', manager.Strings[i + 1]) = 1 then
      begin
        stmp := Trim(manager.Strings[i]);
        if Pos(';', stmp) < 1 then
          stmp := stmp + ';';
      end;}

  Result := '';
  for i := 0 to manager.Count - 1 do
    Result := Result + manager.strings[i];
  manager.Free;

end;

function c2pas_parse2(const lines: TStrings): string;
var
  i, j: integer;
  text_start: integer;
  code_start: integer;
  s1, s2, s3: string;
  frac: buffer_t;
  fi: integer;
  src: string;
  analisis: sourceanalisis_p;
  manager: FracManager;
begin
  if lines = nil then
  begin
    Result := '';
    Exit;
  end;

  if lines.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  if Trim(lines.Text) = '' then
  begin
    Result := '';
    Exit;
  end;

  manager := FracManager.Create;
  manager.Clear;

  src := lines.Text;
//  src := c2pas_doReplace(src, #13#10, #10);

  Result := '';

  s1 := src;
  s2 := '';
  s3 := '';

  frac[0] := #0;
  code_start := 1;

  // First Pass -> Identify strings and comments
  i := 0;
  while i < Length(src) - 1 do
  begin
    Inc(i);

    if src[i] in ['''', '"'] then
    try
      fi := 0;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      text_start := i;
      fi := 0;
      frac[fi] := src[i];
      Inc(i);
      Inc(fi);
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if src[i] = src[text_start] then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_STRING);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing string');
    end;

    if (src[i] = '/') and (src[i + 1] = '/') then
    try
      fi := 0;;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      fi := 0;
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if src[i] = #10 then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_COMMENT);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing comment (//)');
    end;

    if (src[i] = '/') and (src[i + 1] = '*') then
    try
      fi := 0;
      for j := code_start to i - 1 do
      begin
        frac[fi] := src[j];
        Inc(fi);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_SOURCE);

      fi := 0;
      while i < Length(src) do
      begin
        frac[fi] := src[i];
        Inc(fi);
        if (src[i - 1] = '*') and (src[i] = '/') then
          Break;
        Inc(i);
      end;
      frac[fi] := #0;
      manager.Add(@frac, FCT_COMMENT);

      code_start := i + 1;
      Continue;
    except
      raise Exception.Create('C2Pas(): Error during parsing comment (/*..*/)');
    end;

  end;

  fi := 0;
  for j := code_start to Length(src) do
  begin
    frac[fi] := src[j];
    Inc(fi);
  end;
  frac[fi] := #0;
  manager.Add(@frac, FCT_SOURCE);

  // Second Pass ->
  analisis := ManagerToAnalisis(manager);
  analisis_defines(analisis);
  analisis_whitespace(analisis);
  AnalisisToManager(manager, analisis);
{  i := 0;
  Result := '';
  while analisis[i]._type <> FCT_NONE do
    Result := Result + analisis_nextword(analisis, i) + #13#10;}
  with PascalConvertor.Create(manager) do
  try
    Result := FinalPass;
  finally
    free;
  end;
  FreeMem(analisis);

  manager.Free;
end;



function c2pas_convert_if(const src: string): string;
var
  s1: string;

  procedure parse_if(pos: integer);
  var
    plevel: integer;
    maxplevel: integer;
    i: integer;
    pstart: integer;
    pend: integer;
    len: integer;
    s2: string;
  begin
    if pos < 1 then
      exit;

    plevel := 0;
    maxplevel := -1;

    len := length(s1);

    s1[pos + 1] := 'I';
    s1[pos + 2] := 'F';

    pstart := -1;
    pend := -1;

    for i := pos + 3 to len do
    begin
      if s1[i] = '(' then
      begin
        inc(plevel);
        if plevel > maxplevel then
          maxplevel := plevel;
        if plevel = 1 then
        begin
          pstart := i;
        end;
      end
      else if s1[i] = ')' then
      begin
        dec(plevel);
        if plevel = 0 then
        begin
          pend := i;
          break;
        end;
      end;
    end;

    if (pstart > 0) and (pend > 0) then
    begin
      s2 := '';

      for i := 1 to pstart - 1 do
        s2 := s2 + s1[i];
      if maxplevel > 1 then
        s2 := s2 + '(';

      if s2[Length(s2)] = 'F' then
        s2 := s2 + ' ';

      for i := pstart + 1 to pend - 1 do
        s2 := s2 + s1[i];

      if maxplevel > 1 then
        s2 := s2 + ')';

      if s2[Length(s2)] <> ' ' then
        s2 := s2 + ' ';
      s2 := s2 + 'then ';

      for i := pend + 1 to len do
        s2 := s2 + s1[i];

      s1 := s2;
    end;
  end;

  function doif: boolean;
  begin
    if (Pos(' if ', s1) = 0) and (Pos(#10'if ', s1) = 0) and
       (Pos(' if(', s1) = 0) and (Pos(#10'if(', s1) = 0) then
    begin
      Result := false;
      Exit;
    end;

    Result := true;
    parse_if(Pos(' if ', s1));
    parse_if(Pos(#10'if ', s1));
    parse_if(Pos(' if(', s1));
    parse_if(Pos(#10'if(', s1));
  end;

begin
  s1 := src;
  while doif do;
  s1 := StringReplace(s1, ' IF ', ' if ', [rfReplaceAll]);
  s1 := StringReplace(s1, #10'IF ', #10'if ', [rfReplaceAll]);
  s1 := StringReplace(s1, ' IF(', ' if(', [rfReplaceAll]);
  Result := StringReplace(s1, #10'IF(', #10'if(', [rfReplaceAll]);
end;

function c2pas_convert_if2(const src: string): string;
var
  if_pos1, if_pos2: integer;
  then_pos1, then_pos2: integer;
  s: TStringList;
  i: integer;
  stmp: string;
  lastln: Boolean;
  pos1: integer;
  pos2: integer;
  else_pos: integer;
begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;
  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];

    else_pos := Pos(' end else begin', stmp);
    if (else_pos > 0) then
      stmp := StringReplace(stmp, ' end else begin',
              ' end'#13#10 +
              s_spaces(LeadingSpaces(stmp)) + 'else'#13#10 +
              s_spaces(LeadingSpaces(stmp)) + 'begin', []);

    if_pos1 := Pos(' if ', stmp);
    if_pos2 := Pos(' if (', stmp);
    if (if_pos1 = 0) and (if_pos2 = 0) then
    begin
      Result := Result + stmp + #13#10;
      Continue;
    end;

    then_pos1 := Pos(' then ', stmp);
    then_pos2 := Pos(') then ', stmp);
    if (then_pos1 = 0) and (then_pos2 = 0) then
    begin
      Result := Result + stmp + #13#10;
      Continue;
    end;

    if_pos1 := Pos(' if ', stmp);
    if_pos2 := Pos(' if (', stmp);
    then_pos1 := Pos(' then ', stmp);
    then_pos2 := Pos(') then ', stmp);
    if if_pos1 <> if_pos2 then
      if (if_pos2 = 0) and (then_pos2 = 0) and (if_pos1 > 0) and (then_pos1 > 0) then
      begin
        pos1 := Pos(')', stmp);
        pos2 := Pos('(', stmp);
        if pos1 < pos2 then
          if pos1 > if_pos1 then
            if pos2 < then_pos1 then
            begin
              stmp := StringReplace(stmp, ' if ', ' if (', []);
              stmp := StringReplace(stmp, ' then ', ') then ', []);
            end;
      end;

    then_pos1 := Pos(' then   begin', stmp);
    then_pos2 := Pos(' then', stmp);
    if (then_pos1 > 0) then
      if then_pos1 = then_pos2 then
        stmp := StringReplace(stmp, ' then   begin', ' then'#13#10 + s_spaces(LeadingSpaces(stmp)) + 'begin', []);

    then_pos1 := Pos(' then  begin', stmp);
    then_pos2 := Pos(' then', stmp);
    if (then_pos1 > 0) then
      if then_pos1 = then_pos2 then
        stmp := StringReplace(stmp, ' then  begin', ' then'#13#10 + s_spaces(LeadingSpaces(stmp)) + 'begin', []);

    then_pos1 := Pos(' then begin', stmp);
    then_pos2 := Pos(' then', stmp);
    if (then_pos1 > 0) then
      if then_pos1 = then_pos2 then
        stmp := StringReplace(stmp, ' then begin', ' then'#13#10 + s_spaces(LeadingSpaces(stmp)) + 'begin', []);

    then_pos1 := Pos(' then  return true;', stmp);
    if (then_pos1 > 0) then
      stmp := StringReplace(stmp, ' then  return true;',
         ' then'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'begin'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'Result := true;'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'exit;'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'end;'#13#10, []);

    then_pos1 := Pos(' then return true;', stmp);
    if (then_pos1 > 0) then
      stmp := StringReplace(stmp, ' then return true;',
         ' then'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'begin'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'Result := true;'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'exit;'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'end;'#13#10, []);

    then_pos1 := Pos(' then  return false;', stmp);
    if (then_pos1 > 0) then
      stmp := StringReplace(stmp, ' then  return false;',
         ' then'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'begin'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'Result := false;'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'exit;'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'end;'#13#10, []);

    then_pos1 := Pos(' then return false;', stmp);
    if (then_pos1 > 0) then
      stmp := StringReplace(stmp, ' then return false;',
         ' then'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'begin'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'Result := false;'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'exit;'#13#10 +
         s_spaces(LeadingSpaces(stmp)) + 'end;'#13#10, []);

    then_pos1 := Pos(' then  exit;', stmp);
    if (then_pos1 > 0) then
      stmp := StringReplace(stmp, ' then  exit;',
         ' then'#13#10 +
         s_spaces(LeadingSpaces(stmp) + 2) + 'exit;'#13#10#13#10, []);

    stmp := StringReplace(stmp, ' then  ', ' then ', []);
      Result := Result + stmp + #13#10;
  end;
  s.Free;

  if not lastln then
    removetrailingNL(Result);
end;

function c2pas_convert_for(const src: string): string;
var
  s: TStringList;
  i: integer;
  stmp: string;
  lspaces: integer;
  l1: TStringList;
  ll1: TStringList;
  ll2: TStringList;
  ll3: TStringList;
  s3: string;
  _to: Boolean;
  _downto: boolean;
  _ss_i: string;
  _ss_from: string;
  _ss_to: string;
  lastln: Boolean;
  _before, _in, _after: string;
  _no_begin: boolean;
begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;

  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    lspaces := LeadingSpaces(stmp);
    stmp := Trim(stmp);
    _to := false;
    _downto := false;

    _ss_i := '';
    _ss_from := '';
    _ss_to := '';

    _no_begin := false;

    if Length(stmp) > 6 then
      if (LeftStr(stmp, 4) = 'for ') or (LeftStr(stmp, 4) = 'for(') then
      begin
        if (RightStr(stmp, 6) = ' begin') or (RightStr(stmp, 6) = ')begin') then
        begin
          stmp := MidStr(stmp, 4, Length(stmp) - 9);
          stmp := Trim(stmp);
          if Length(stmp) > 3 then
          begin
            if stmp[1] = '(' then
              stmp[1] := ' ';
            if stmp[Length(stmp)] = ')' then
              stmp[Length(stmp)] := ' ';
            stmp := Trim(stmp);
          end;
          l1 := str2list(stmp, [';']);
          if l1.Count = 3 then
          begin
            l1.Strings[0] := Trim(l1.Strings[0]);
            ll1 := str2list(l1.Strings[0], [' ']);
            l1.Strings[1] := Trim(l1.Strings[1]);
            ll2 := str2list(l1.Strings[1], [' ']);
            l1.Strings[2] := Trim(l1.Strings[2]);
            ll3 := str2list(l1.Strings[2], [' ']);
            if ll1.Count = 3 then
            begin
              ll1.Strings[0] := Trim(ll1.Strings[0]);
              ll1.Strings[1] := Trim(ll1.Strings[1]);
              ll1.Strings[2] := Trim(ll1.Strings[2]);
              if ll1.Strings[1] = ':=' then
              begin
                if ll2.Count = 3 then
                begin
                  ll2.Strings[0] := Trim(ll2.Strings[0]);
                  ll2.Strings[1] := Trim(ll2.Strings[1]);
                  ll2.Strings[2] := Trim(ll2.Strings[2]);
                  if (ll2.Strings[1] = '<') or (ll2.Strings[1] = '<='){ or (ll2.Strings[1] = '>') or (ll2.Strings[1] = '>=')} then
                    if ll2.Strings[0] = ll1.Strings[0] then
                      if IsIdentifier(ll1.Strings[2]) or IsInteger(ll1.Strings[2]) then
                        if IsIdentifier(ll2.Strings[2]) or IsInteger(ll2.Strings[2]) then
                          if ll3.Count = 1 then
                          begin
                            s3 := Trim(ll3.Strings[0]);
                            if Length(s3) > 2 then
                            begin
                              if (s3[Length(s3)] = '+') and (s3[Length(s3) - 1] = '+') then
                              begin
                                s3 := Trim(LeftStr(s3, Length(s3) - 2));
                                if s3 = ll1.Strings[0] then
                                begin
                                  _to := True;
                                  _ss_i := s3;
                                  _ss_from := ll1.Strings[2];
                                  _ss_to := ll2.Strings[2];
                                  if ll2.Strings[1] = '<' then
                                  begin
                                    if IsInteger(_ss_to) and (_ss_to[1] <> '$') then
                                      _ss_to := IntToStr(StrToInt(_ss_to) - 1)
                                    else
                                      _ss_to := _ss_to + ' - 1';
                                  end;
                                end;
                              end;
                             { if (s3[Length(s3)] = '-') and (s3[Length(s3) - 1] = '-') then
                              begin
                                s3 := Trim(LeftStr(s3, Length(s3) - 2));
                                if s3 =  ll1.Strings[0] then
                                begin
                                  _downto := True;
                              end;}
                            end;
                          end;
                end;
              end;
            end;

            ll1.Free;
            ll2.Free;
            ll3.Free;
          end;
        end
        else
        begin
          stmp := MidStr(stmp, 4, Length(stmp) - 3);
          stmp := Trim(stmp);
          _no_begin := true;
          if split_parenthesis(stmp, _before, _in, _after) then
          if _before = '' then
          if Length(_after) > 0 then
          if _after[Length(_after)] = ';' then
          begin
            l1 := str2list(Trim(_in), [';']);
            if l1.Count = 3 then
            begin
              l1.Strings[0] := Trim(l1.Strings[0]);
              ll1 := str2list(l1.Strings[0], [' ']);
              l1.Strings[1] := Trim(l1.Strings[1]);
              ll2 := str2list(l1.Strings[1], [' ']);
              l1.Strings[2] := Trim(l1.Strings[2]);
              ll3 := str2list(l1.Strings[2], [' ']);
              if ll1.Count = 3 then
              begin
                ll1.Strings[0] := Trim(ll1.Strings[0]);
                ll1.Strings[1] := Trim(ll1.Strings[1]);
                ll1.Strings[2] := Trim(ll1.Strings[2]);
                if ll1.Strings[1] = ':=' then
                begin
                  if ll2.Count = 3 then
                  begin
                    ll2.Strings[0] := Trim(ll2.Strings[0]);
                    ll2.Strings[1] := Trim(ll2.Strings[1]);
                    ll2.Strings[2] := Trim(ll2.Strings[2]);
                    if (ll2.Strings[1] = '<') or (ll2.Strings[1] = '<='){ or (ll2.Strings[1] = '>') or (ll2.Strings[1] = '>=')} then
                      if ll2.Strings[0] = ll1.Strings[0] then
                        if IsIdentifier(ll1.Strings[2]) or IsInteger(ll1.Strings[2]) then
                          if IsIdentifier(ll2.Strings[2]) or IsInteger(ll2.Strings[2]) then
                            if ll3.Count = 1 then
                            begin
                              s3 := Trim(ll3.Strings[0]);
                              if Length(s3) > 2 then
                              begin
                                if (s3[Length(s3)] = '+') and (s3[Length(s3) - 1] = '+') then
                                begin
                                  s3 := Trim(LeftStr(s3, Length(s3) - 2));
                                  if s3 = ll1.Strings[0] then
                                  begin
                                    _to := True;
                                    _ss_i := s3;
                                    _ss_from := ll1.Strings[2];
                                    _ss_to := ll2.Strings[2];
                                    if ll2.Strings[1] = '<' then
                                    begin
                                      if IsInteger(_ss_to) and (_ss_to[1] <> '$') then
                                        _ss_to := IntToStr(StrToInt(_ss_to) - 1)
                                      else
                                        _ss_to := _ss_to + ' - 1';
                                    end;
                                  end;
                                end;
                               { if (s3[Length(s3)] = '-') and (s3[Length(s3) - 1] = '-') then
                                begin
                                  s3 := Trim(LeftStr(s3, Length(s3) - 2));
                                  if s3 =  ll1.Strings[0] then
                                  begin
                                    _downto := True;
                                end;}
                              end;
                            end;
                  end;
                end;
              end;

              ll1.Free;
              ll2.Free;
              ll3.Free;
            end;
          end;
        end;
      end;

    if _no_begin then
    begin
      if _to or _downto then
      begin
        Result := Result + s_spaces(lspaces) + 'for ' + _ss_i + ' := ' + _ss_from;
        if _to then
          Result := Result + ' to '
        else
          Result := Result + ' downto ';
        Result := Result + _ss_to + ' do'#13#10 + s_spaces(lspaces + 2) + _after + #13#10;
      end
      else
        Result := Result + s.Strings[i] + #13#10;
    end
    else
    begin
      if _to or _downto then
      begin
        Result := Result + s_spaces(lspaces) + 'for ' + _ss_i + ' := ' + _ss_from;
        if _to then
          Result := Result + ' to '
        else
          Result := Result + ' downto ';
        Result := Result + _ss_to + ' do'#13#10 + s_spaces(lspaces) + 'begin' + #13#10;
      end
      else
        Result := Result + s.Strings[i] + #13#10;
    end;

  end;
  s.Free;

  if not lastln then
    removetrailingNL(Result);
end;

function c2pas_convert_switch(const src: string): string;
var
  s: TStringList;
  i: integer;
  stmp: string;
  lastln: Boolean;
  lspaces: integer;
  _before, _in, _after: string;
begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;
  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    lspaces := LeadingSpaces(stmp);
    stmp := Trim(stmp);

    if split_parenthesis(stmp, _before, _in, _after) then
    begin
      if _before = 'switch' then
        if IsIdentifier(_in) then
          if _after = 'begin' then
          begin
            Result := Result + s_spaces(lspaces) + 'case ' + _in + ' of'#13#10;
            Continue;
          end;
    end;
    Result := Result + s.Strings[i] + #13#10;
  end;

  s.Free;

  if not lastln then
    removetrailingNL(Result);
end;


function c2pas_convert_if3(const src: string): string;
var
  s: TStringList;
  i, j, p: integer;
  stmp: string;
  lastln: Boolean;
  lspaces: integer;
  rest: string;
begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;
  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    lspaces := LeadingSpaces(stmp);
    stmp := Trim(stmp);
    if stmp = '' then
    begin
      Result := Result + #13#10;
      Continue;
    end;

    if stmp[Length(stmp)] = ';' then
      if Pos('if ', stmp) = 1 then
      begin
        p := Pos(' then ', stmp);
        if p > 0 then
        begin
          rest := '';
          for j := p + 6 to Length(stmp) do
            rest := rest + stmp[j];
          stmp := Trim(LeftStr(stmp, p + 5));
          Result := Result + s_spaces(lspaces) + stmp + #13#10 + s_spaces(lspaces + 2) + rest + #13#10;
          Continue;
        end;
      end;

    Result := Result + s.Strings[i] + #13#10;
  end;

  s.Free;

  if not lastln then
    removetrailingNL(Result);
end;


function c2pas_convert_while1(const src: string): string;
var
  s: TStringList;
  i: integer;
  stmp: string;
  lastln: Boolean;
  lspaces: integer;
  ll: TStringList;
  s2: string;
begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;
  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    lspaces := LeadingSpaces(stmp);
    stmp := Trim(stmp);
    if stmp = '' then
    begin
      Result := Result + #13#10;
      Continue;
    end;

    stmp := c2pas_doReplace(stmp, '   ', ' ');
    stmp := c2pas_doReplace(stmp, '  ', ' ');
    stmp := c2pas_doReplace(stmp, '  ', ' ');
    stmp := c2pas_doReplace(stmp, '  ', ' ');

    ll := str2list(stmp, [' ']);
    if ll.Count = 3 then
      if ll.Strings[0] = 'while' then
        if ll.Strings[1] = '(true)' then
          if ll.Strings[2] = 'begin' then
          begin
            Result := Result + s_spaces(lspaces) + 'while true do'#13#10 + s_spaces(lspaces) + 'begin'#13#10;
            ll.Free;
            Continue;
          end;

    ll := str2list(stmp, [' ']);
    if ll.Count = 3 then
      if ll.Strings[0] = 'while' then
        if ll.Strings[2] = 'begin' then
        begin
          s2 := ll.Strings[1];
          if Length(s2) > 2 then
          begin
            if (s2[1] = '(') and (s2[Length(s2)] = ')') then
            begin
              s2[1] := ' ';
              s2[Length(s2)] := ' ';
              s2 := Trim(s2);
              if IsIdentifier(s2) then
              begin
                Result := Result + s_spaces(lspaces) + 'while ' + s2 + ' do'#13#10 + s_spaces(lspaces) + 'begin'#13#10;
                ll.Free;
                Continue;
              end;
            end;
          end;
        end;

    ll.Free;
    Result := Result + s.Strings[i] + #13#10;
  end;

  s.Free;

  if not lastln then
    removetrailingNL(Result);
end;

function c2pas_convert_assignments(const src: string): string;
var
  s: TStringList;
  i: integer;
  stmp: string;
  lastln: Boolean;
  lspaces: integer;
  ll: TStringList;
  _as_ret: string;

  function _assignment_test(const xx: string; const asgn: string): Boolean;
  var
    ss2: string;
    ii: integer;
    expr: string;
  begin
    Result := false;

    if ll.Count < 3 then
      exit;
      
    if not IsIdentifier(ll.Strings[0]) then
      exit;

    if ll.Strings[1] <> xx then
      exit;

    if ll.Count = 3 then
    begin
      ss2 := Trim(ll.Strings[2]);
      if Length(ss2) < 1 then
        exit;
      if ss2[Length(ss2)] = ';' then
      begin
        ss2[Length(ss2)] := ' ';
        ss2 := Trim(ss2);
        if IsIdentifier(ss2) or IsNumber(ss2) or IsInteger(ss2) then
        begin
          _as_ret := ll.Strings[0] + ' := ' + ll.Strings[0] + ' ' + asgn + ' ' + ss2 + ';';
          Result := True;
          exit;
        end;
      end;
    end
    else
    begin
      expr := '';
      for ii := 2 to ll.Count - 1 do
        expr := expr + ' ' + ll.Strings[ii] + ' ';
      expr := Trim(expr);
      if Length(expr) = 0 then
        exit;
      if expr[Length(expr)] <> ';' then
        exit;
      expr[Length(expr)] := ' ';
      expr := Trim(expr);
      if Pos(';', expr) = 0 then
        if Pos(',', expr) = 0 then
          if Pos('{', expr) = 0 then
            if Pos('}', expr) = 0 then
              if checkbracketsclosed(expr, '(', ')') then
                if checkbracketsclosed(expr, '[', ']') then
                begin
                  if Pos(' ', expr) > 0 then
                    _as_ret := ll.Strings[0] + ' := ' + ll.Strings[0] + ' ' + asgn + ' (' + expr + ');'
                  else
                    _as_ret := ll.Strings[0] + ' := ' + ll.Strings[0] + ' ' + asgn + ' ' + expr + ';';
                  Result := True;
                  exit;
                end;
    end;
  end;

  function _plusplus_test(const cc: char; const func: string): Boolean;
  var
    ss2: string;
  begin
    Result := false;
    if ll.Count <> 1 then
      exit;

    ss2 := Trim(ll.Strings[0]);
    if Length(ss2) < 4 then
      exit;

    if ss2[Length(ss2)] <> ';' then
      exit;

    ss2[Length(ss2)] := ' ';
    ss2 := Trim(ss2);

    if ss2[Length(ss2)] <> cc then
      exit;

    if ss2[Length(ss2) - 1] <> cc then
      exit;

    ss2[Length(ss2)] := ' ';
    ss2[Length(ss2) - 1] := ' ';
    ss2 := Trim(ss2);

    if not IsIdentifier(ss2) then
      exit;

    _as_ret := func + '(' + ss2 + ');';
     Result := True;
  end;

begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;
  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    lspaces := LeadingSpaces(stmp);
    stmp := Trim(stmp);
    if stmp = '' then
    begin
      Result := Result + #13#10;
      Continue;
    end;

    stmp := c2pas_doReplace(stmp, '   ', ' ');
    stmp := c2pas_doReplace(stmp, '  ', ' ');
    stmp := c2pas_doReplace(stmp, '  ', ' ');
    stmp := c2pas_doReplace(stmp, '  ', ' ');

    ll := str2list(stmp, [' ']);

    if _assignment_test('+=', '+') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('-=', '-') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('*=', '*') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('/=', '/') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('|=', 'or') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('&=', 'and') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('<<=', 'shl') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _assignment_test('>>=', 'shr') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _plusplus_test('+', 'inc') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else if _plusplus_test('-', 'dec') then
      Result := Result + s_spaces(lspaces) + _as_ret + #13#10
    else
      Result := Result + s.Strings[i] + #13#10;
    ll.Free;
  end;

  s.Free;

  if not lastln then
    removetrailingNL(Result);
end;

(*
function c2pas_convert_XXXX(const src: string): string;
var
  if_pos1, if_pos2: integer;
  then_pos1, then_pos2: integer;
  s: TStringList;
  i: integer;
  stmp: string;
  lastln: Boolean;
  pos1: integer;
  pos2: integer;
  else_pos: integer;
begin
  if Length(src) < 8 then
  begin
    Result := src;
    exit;
  end;
  lastln := (src[Length(src) - 1] = #13) and (src[Length(src)] = #10);

  s := TStringList.Create;
  s.Text := src;
  Result := '';
  for i := 0 to s.Count - 1 do
  begin
    stmp := s.Strings[i];
    lspaces := LeadingSpaces(stmp);
    stmp := Trim(stmp);

    if split_parenthesis(stmp, _before, _in, _after) then
    begin

    end;
    Result := Result + s.Strings[i] + #13#10;
  end;

  s.Free;

  if not lastln then
  begin
    if (Result[Length(Result) - 1] = #13) and (Result[Length(Result)] = #10) then
      SetLength(Result, Length(Result) - 2);
  end;


end;

*)
end.

