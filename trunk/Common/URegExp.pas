unit URegExp;

{$i CommonDirectives.inc}

interface

{$IFNDEF UNICODE}
  // ƒл€ ANSI версии возможны 2 варианта внешних регул€рных выражеий:
  // TRegExpr class library и Perl Regular Expressions
  // TRegExpr class library имеет меньший объем, но поддерживает не все свойства
  // Perl Regular Expressions добавл€ет к коду около 100  б
  // USE_PerlRegEx - использование Perl Regular Expressions
  {$DEFINE USE_PerlRegEx}
{$ENDIF}

uses
  Kol,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  PerlRegEx,
  {$ELSE}
  RegExpr,
  {$ENDIF}
{$ENDIF}
  UTypes,
  UUtils;

type
  TRegExp = class
  private
{$IFDEF UNICODE}
    FRegExp: TFarString;
    FHandle: THandle;
    FBrackets: Integer;
    FRegExpSearch: TRegExpSearch;
    FMatches: array of TRegExpMatch;
    function QuoteRegExp(const AText: TFarString): TFarString;
    function InternalMatch: Boolean;
{$ELSE}
    {$IFDEF USE_PerlRegEx}
    FPerlRegExpr: TPerlRegEx;
    {$ELSE}
    FRegExpr: TRegExpr;
    {$ENDIF}
    function UnquoteRegExp(const AText: TFarString): TFarString;
{$ENDIF}
    function GetMatchCount: Integer;
    function GetMatch(Index: Integer): TFarString;
    function GetMatchLen(Index: Integer): Integer;
    function GetMatchPos(Index: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Compile(const ARegExp: TFarString): Boolean;
    function Exec(const AText: TFarString): Boolean;
    function ExecNext: Boolean;
    property MatchCount: Integer read GetMatchCount;
    property Match[Index: Integer]: TFarString read GetMatch;
    property MatchPos[Index: Integer]: Integer read GetMatchPos;
    property MatchLen[Index: Integer]: Integer read GetMatchLen;
  end;

{$IFNDEF Release}
procedure TestRegExp;
{$ENDIF}

implementation

{$IFNDEF Release}
procedure TestRegExp;
var
  str: TFarString;
  i, pos, len: Integer;
begin
  with TRegExp.Create do
  try
{$IFDEF UNICODE}
    Compile('/\d(\d\d)(?=\d)/i');
{$ELSE}
  {$IFDEF USE_PerlRegEx}
    Compile('/\d(\d\d)(?=\d)/i');
  {$ELSE}
    Compile('/\d(\d\d)/i');
  {$ENDIF}
{$ENDIF}
    if Exec('1234567890') then
      repeat
        for i := 0 to MatchCount - 1 do
        begin
          str := PFarChar(Match[i]);
          pos := MatchPos[i];
          len := MatchLen[i];
        end;
      until not ExecNext;
  finally
    Free;
  end;
end;
{$ENDIF}

{ TRegExp }

function TRegExp.Compile(const ARegExp: TFarString): Boolean;
begin
{$IFDEF UNICODE}
  FBrackets := -1;
  FRegExp := QuoteRegExp(ARegExp);
  Result := FARAPI.RegExpControl(FHandle, RECTL_COMPILE, PFarChar(FRegExp)) <> 0;
  if Result then
    FARAPI.RegExpControl(FHandle, RECTL_OPTIMIZE, nil);
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  try
    FPerlRegExpr.RegEx := UnquoteRegExp(ARegExp);
    FPerlRegExpr.Compile;
    Result := True;
  except
    Result := False;
  end;
  {$ELSE}
  try
    FRegExpr.Expression := UnquoteRegExp(ARegExp);
    Result := True;
  except
    on E: ERegExpr do
      Result := False;
  end;
  {$ENDIF}
{$ENDIF}
end;

constructor TRegExp.Create;
begin
  inherited;
{$IFDEF UNICODE}
  FARAPI.RegExpControl(0, RECTL_CREATE, @FHandle);
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  FPerlRegExpr := TPerlRegEx.Create;
  {$ELSE}
  FRegExpr := TRegExpr.Create;
  {$ENDIF}
{$ENDIF}
end;

destructor TRegExp.Destroy;
begin
{$IFDEF UNICODE}
  FARAPI.RegExpControl(FHandle, RECTL_FREE, nil);
  SetLength(FMatches, 0);
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  FPerlRegExpr.Free;
  {$ELSE}
  FRegExpr.Free;
  {$ENDIF}
{$ENDIF}
  inherited;
end;

function TRegExp.GetMatchCount: Integer;
begin
{$IFDEF UNICODE}
  Result := FBrackets;
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  Result := FPerlRegExpr.SubExpressionCount + 1;
  {$ELSE}
  Result := FRegExpr.SubExprMatchCount + 1;
  {$ENDIF}
{$ENDIF}
end;

function TRegExp.GetMatch(Index: Integer): TFarString;
begin
{$IFDEF UNICODE}
  with FMatches[Index] do
    Result := Copy(FRegExp, Start + 1, EndPos - Start);
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  Result := FPerlRegExpr.SubExpressions[index];
  {$ELSE}
  Result := FRegExpr.Match[Index];
  {$ENDIF}
{$ENDIF}
end;

function TRegExp.Exec(const AText: TFarString): Boolean;
begin
{$IFDEF UNICODE}
  FRegExp := AText;
  FBrackets := FARAPI.RegExpControl(FHandle, RECTL_BRACKETSCOUNT, nil);
  Result := FBrackets > 0;
  if Result then
  begin
    SetLength(FMatches, FBrackets);
    with FRegExpSearch do
    begin
      Text := PFarChar(AText);
      Match := @FMatches[0];
      Position := 0;
      Length := WStrLen(Text);
      Count := FBrackets;
      Reserved := nil;
    end;
    Result := InternalMatch;
  end;
{$ELSE}
  {$IFDEF USE_PerlRegEx}
    FPerlRegExpr.Subject := AText;
    Result := FPerlRegExpr.Match;
  {$ELSE}
  try
    Result := FRegExpr.Exec(AText);
  except
    Result := False;
  end;
  {$ENDIF}
{$ENDIF}
end;

{$IFDEF UNICODE}
function TRegExp.InternalMatch: Boolean;
begin
  Result := FARAPI.RegExpControl(FHandle, RECTL_SEARCHEX, @FRegExpSearch) <> 0;
  if Result then
    FRegExpSearch.Position := FMatches[0].EndPos;
end;

function TRegExp.QuoteRegExp(const AText: TFarString): TFarString;
begin
  if (AText <> '') and (AText[1] <> '/') then
    Result := '/' + AText + '/'
  else
    Result := AText;
end;
{$ELSE}
function TRegExp.UnquoteRegExp(const AText: TFarString): TFarString;
var
  p, p1: Integer;
begin
  if (AText <> '') and (AText[1] = '/') then
  begin
    p := PosEx('/', AText, 2);
    if p <> 0 then
    begin
      repeat
        p1 := p + 1;
        p := PosEx('/', AText, p1);
      until p = 0;
{$IFDEF USE_PerlRegEx}
      if p1 <= Length(AText) then
      begin
        (*
        preCaseLess
          /i -> Case insensitive
        preMultiLine
          /m -> ^ and $ also match before/after a newline, not just at the
          beginning and the end of the PCREString
        preSingleLine
          /s -> Dot matches any character, including \n (newline).
          Otherwise, it matches anything except \n
        preExtended
          /x -> Allow regex to contain extra whitespace, newlines and
          Perl-style comments, all of which will be filtered out
        preAnchored
          /A -> Successful match can only occur at the start of the subject or
          right after the previous match
        preUnGreedy (non standard)
          /u -> Repeat operators (+, *, ?) are not greedy by default (i.e. they
          try to match the minimum number of characters instead of the maximum)
        preNoAutoCapture (not used)
          (group) is a non-capturing group; only named groups capture}
        *)
        FPerlRegExpr.Options := [];
        repeat
          case AText[p1] of
            'i': FPerlRegExpr.Options := FPerlRegExpr.Options + [preCaseLess];
            'm': FPerlRegExpr.Options := FPerlRegExpr.Options + [preMultiLine];
            's': FPerlRegExpr.Options := FPerlRegExpr.Options + [preSingleLine];
            'x': FPerlRegExpr.Options := FPerlRegExpr.Options + [preExtended];
            'A': FPerlRegExpr.Options := FPerlRegExpr.Options + [preAnchored];
            'u': FPerlRegExpr.Options := FPerlRegExpr.Options + [preUnGreedy];
          end;
          Inc(p1);
        until p1 > Length(AText);
      end;
{$ELSE}
      if p1 <= Length(AText) then
        FRegExpr.ModifierStr := Copy(AText, p1, Length(AText) - p1 + 1);
{$ENDIF}
      Result := Copy(AText, 2, p1 - 3);
      Exit;
    end;
  end;
  Result := AText;
end;
{$ENDIF}

function TRegExp.ExecNext: Boolean;
begin
{$IFDEF UNICODE}
  Result := (FBrackets > 0) and InternalMatch;
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  Result := FPerlRegExpr.MatchAgain;
  {$ELSE}
  try
    Result := FRegExpr.ExecNext;
  except
    Result := False;
  end;
  {$ENDIF}
{$ENDIF}
end;

function TRegExp.GetMatchLen(Index: Integer): Integer;
begin
{$IFDEF UNICODE}
  Result := FMatches[Index].EndPos - FMatches[Index].Start;
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  Result := FPerlRegExpr.SubExpressionLengths[Index];
  {$ELSE}
  Result := FRegExpr.MatchLen[Index];
  {$ENDIF}
{$ENDIF}
end;

function TRegExp.GetMatchPos(Index: Integer): Integer;
begin
{$IFDEF UNICODE}
  Result := FMatches[Index].Start + 1;
{$ELSE}
  {$IFDEF USE_PerlRegEx}
  Result := FPerlRegExpr.SubExpressionOffsets[Index];
  {$ELSE}
  Result := FRegExpr.MatchPos[Index];
  {$ENDIF}
{$ENDIF}
end;

end.