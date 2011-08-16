unit URegExp;

{$i CommonDirectives.inc}

interface

uses
  Kol,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  RegExpr,
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
    FMatches: array of TRegExpMatch;
    FMatchesStr: array of TFarString;
    function QuoteRegExp(const AText: TFarString): TFarString;
{$ELSE}
    FRegExpr: TRegExpr;
    function UnquoteRegExp(const AText: TFarString): TFarString;
{$ENDIF}
    function GetMatchCount: Integer;
    function GetMatches(Index: Integer): TFarString;
  public
    constructor Create;
    destructor Destroy; override;
    function Compile(const ARegExp: TFarString): Boolean;
    function Match(const AText: TFarString): Boolean;
    property Matches[Index: Integer]: TFarString read GetMatches;
    property MatchCount: Integer read GetMatchCount;
  end;

implementation

{ TRegExp }

function TRegExp.Compile(const ARegExp: TFarString): Boolean;
begin
{$IFDEF UNICODE}
  FRegExp := QuoteRegExp(ARegExp);
  Result := FARAPI.RegExpControl(FHandle, RECTL_COMPILE, PFarChar(FRegExp)) <> 0;
  if Result then
    FARAPI.RegExpControl(FHandle, RECTL_OPTIMIZE, nil);
{$ELSE}
  try
    FRegExpr.Expression := UnquoteRegExp(ARegExp);
    Result := True;
  except
    on E: ERegExpr do
      Result := False;
  end;
{$ENDIF}
end;

constructor TRegExp.Create;
begin
  inherited;
{$IFDEF UNICODE}
  FARAPI.RegExpControl(0, RECTL_CREATE, @FHandle);
{$ELSE}
  FRegExpr := TRegExpr.Create;
{$ENDIF}
end;

destructor TRegExp.Destroy;
begin
{$IFDEF UNICODE}
  FARAPI.RegExpControl(FHandle, RECTL_FREE, nil);
  SetLength(FMatches, 0);
{$ELSE}
  FRegExpr.Free;
{$ENDIF}
  inherited;
end;

function TRegExp.GetMatchCount: Integer;
begin
{$IFDEF UNICODE}
  Result := FBrackets;
{$ELSE}
  Result := FRegExpr.SubExprMatchCount + 1;
{$ENDIF}
end;

function TRegExp.GetMatches(Index: Integer): TFarString;
begin
{$IFDEF UNICODE}
  Result := FMatchesStr[Index];
{$ELSE}
  Result := FRegExpr.Match[Index];
{$ENDIF}
end;

function TRegExp.Match(const AText: TFarString): Boolean;
{$IFDEF UNICODE}
var
  RegExpSearch: TRegExpSearch;
  i: Integer;
{$ENDIF}
begin
{$IFDEF UNICODE}
  Result := False;
  FBrackets := FARAPI.RegExpControl(FHandle, RECTL_BRACKETSCOUNT, nil);
  if FBrackets > 0 then
  begin
    SetLength(FMatches, FBrackets);
    with RegExpSearch do
    begin
      Text := PFarChar(AText);
      Match := @FMatches[0];
      Position := 0;
      Length := WStrLen(Text);
      Count := FBrackets;
      Reserved := nil;
    end;
    Result := FARAPI.RegExpControl(FHandle, RECTL_SEARCHEX, @RegExpSearch) <> 0;
    if Result then
    begin
      SetLength(FMatchesStr, FBrackets);
      for i := 0 to FBrackets - 1 do
        FMatchesStr[i] := Copy(AText, FMatches[i].Start + 1,
          FMatches[i].EndPos - FMatches[i].Start);
    end;
  end;
{$ELSE}
  Result := FRegExpr.Exec(AText);
{$ENDIF}
end;

{$IFDEF UNICODE}
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
      if p1 <= Length(AText) then
        FRegExpr.ModifierStr := Copy(AText, p1, Length(AText) - p1 + 1);
      Result := Copy(AText, 2, p1 - 3);
      Exit;
    end;
  end;
  Result := AText;
end;
{$ENDIF}


end.