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
  UTypes;

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
    function GetMatches(Index: Integer): TFarString;
{$ELSE}
    FRegExpr: TRegExpr;
{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    function Compile(const ARegExp: TFarString): Boolean;
    function Match(const AText: TFarString): Boolean;
    property Matches[Index: Integer]: TFarString read GetMatches;
    property Brackets: Integer read FBrackets;
  end;

implementation

uses SysUtils;

{ TRegExp }

function TRegExp.Compile(const ARegExp: TFarString): Boolean;
begin
{$IFDEF UNICODE}
  FRegExp := QuoteRegExp(ARegExp);
  Result := (FARAPI.RegExpControl(FHandle, RECTL_COMPILE, PFarChar(FRegExp)) <> 0) and
    (FARAPI.RegExpControl(FHandle, RECTL_OPTIMIZE, nil) <> 0);
{$ELSE}
  try
    FRegExpr.Expression := ARegExp;
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

function TRegExp.GetMatches(Index: Integer): TFarString;
begin
{$IFDEF UNICODE}
  Result := FMatchesStr[Index];
{$ELSE}
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
  Result := FRegExpr.Exec(Text);
{$ENDIF}
end;

function TRegExp.QuoteRegExp(const AText: TFarString): TFarString;
begin
  if (AText <> '') and (AText[1] <> '/') then
    Result := '/' + AText + '/'
  else
    Result := AText;
end;

end.