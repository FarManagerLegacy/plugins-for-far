unit UProgressBar;

{$i CommonDirectives.inc}

interface

uses
  Windows,
  kol,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  plugin,
{$ENDIF}
  UTypes;

const
  cMaxBuf = 512;

type
  TProgressBar = class
  private
    FLastPos, FLastPS: Integer;
    FSaveScreen: THandle;
    FMaxCounter: Integer;
    FTitle, FConsoleTitle: TFarString;
    FAddLine: Integer;
    FTitleBuf: array[0..cMaxBuf - 1] of TFarChar;

    function CheckForEsc: Boolean;
  public
    constructor Create(const aTitle: TFarString; aMaxCounter: Integer;
      aAddLine: Integer = 0);
    destructor Destroy; override;
    function UpdateProgress(counter: Integer; esc: Boolean = False;
      const text: TFarString = ''): Boolean;
    function IncProgress(addcounter: Integer = 1; esc: Boolean = False;
      const text: TFarString = ''): Boolean;
  end;

implementation

const
  cSizeTherm = 43;
  cSizeX = cSizeTherm;

 {$IFDEF UNICODE}
  chrVertLine = #$2502;
  chrUpArrow  = #$25B2;
  chrDnArrow  = #$25BC;
  chrHatch    = #$2591;
  chrDkHatch  = #$2593;
  chrBrick    = #$2588;
  chrCheck    = #$FB;
 {$ELSE}
  chrVertLine = #$B3;
  chrUpArrow  = #$1E;
  chrDnArrow  = #$1F;
  chrHatch    = #$B0;
  chrDkHatch  = #$B2;
  chrBrick    = #$DB;
  chrCheck    = #$FB;
 {$ENDIF}

  //chrHatch = #$B0;
  //chrBrick = #$DB;
  cFar = ' - Far';

 { TProgressBar }

function TProgressBar.CheckForEsc: Boolean;
var
  rec: INPUT_RECORD;
  hConInp: THandle;
  ReadCount: DWORD;
begin
  Result := False;
  hConInp := GetStdHandle(STD_INPUT_HANDLE);
  repeat
    PeekConsoleInput(hConInp, rec, 1, ReadCount);
    if ReadCount = 0 then
      Break;
    ReadConsoleInput(hConInp, rec, 1, ReadCount);
    if rec.EventType = KEY_EVENT then
      if (rec.Event.KeyEvent.wVirtualKeyCode = VK_ESCAPE) and
        rec.Event.KeyEvent.bKeyDown then
      Result := True;
  until False;
end;

constructor TProgressBar.Create(const aTitle: TFarString; aMaxCounter,
  aAddLine: Integer);
var
  i: Integer;
  str: TFarString;
begin
  inherited Create;
{$IFDEF UNICODE}
  GetConsoleTitleW(FTitleBuf, cMaxBuf);
{$ELSE}
  GetConsoleTitleA(FTitleBuf, cMaxBuf);
{$ENDIF}
  FTitle := aTitle;
  FConsoleTitle := FTitle + cFar;
  FLastPS := -1;
{$IFDEF UNICODE}
  SetConsoleTitleW(PFarChar(FConsoleTitle));
{$ELSE}
  SetConsoleTitleA(PFarChar(FConsoleTitle));
{$ENDIF}
  FAddLine := aAddLine;
  str := FTitle + #10;
  for i := 0 to FAddLine - 1 do
    str := str + #10;
  for i := 1 to cSizeX do
    str := str + chrHatch;
  FSaveScreen := FARAPI.SaveScreen(0, 0, -1, -1);
  FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
    PPCharArray(@str[1]), 0, 0);
  FMaxCounter := aMaxCounter;
  FLastPos := 0;
end;

destructor TProgressBar.Destroy;
begin
{$IFDEF UNICODE}
  SetConsoleTitleW(FTitleBuf);
{$ELSE}
  SetConsoleTitleA(FTitleBuf);
{$ENDIF}
  FARAPI.RestoreScreen(FSaveScreen);
  inherited;
end;

function TProgressBar.IncProgress(addcounter: Integer; esc: Boolean;
  const text: TFarString): Boolean;
var
  counter: Integer;
begin
  if FLastPos < FMaxCounter then
  begin
    counter := FLastPos + addcounter;
    if counter > FMaxCounter then
      counter := FMaxCounter;
  end
  else
    counter := FMaxCounter;
  Result := UpdateProgress(counter, esc, text);
end;

function TProgressBar.UpdateProgress(counter: Integer; esc: Boolean;
  const text: TFarString): Boolean;
var
  pos, ps: Integer;
  str: TFarString;
  i: Integer;
begin
  if counter <> 0 then
  begin
    if FLastPos > FMaxCounter then
      FLastPos := FMaxCounter;
    if (FLastPos <> counter) or ((FAddLine > 0) and (text <> '')) then
    begin
      ps := counter * 100 div FMaxCounter;
      FLastPos := counter;
      pos := counter * cSizeX div FMaxCounter;
      str := FTitle + #10;
      if FAddLine > 0 then
         str := str + text + #10;
      if pos <> 0 then
        for i := 1 to pos do
          str := str + chrBrick;
      if pos <> cSizeX then
        for i := pos + 1 to cSizeX do
          str := str + chrHatch;
      FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
        PPCharArray(@str[1]), 0, 0);
      if FLastPS <> ps then
{$IFDEF UNICODE}
        SetConsoleTitleW(PFarChar('{' + Int2Str(ps) + '%} ' + FConsoleTitle));
{$ELSE}
        SetConsoleTitleA(PFarChar('{' + Int2Str(ps) + '%} ' + FConsoleTitle));
{$ENDIF}
    end;
  end;
  Result := not (esc and CheckForEsc);
end;

end.
