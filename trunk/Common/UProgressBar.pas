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
  UTypes,
  UUtils;

const
  cMaxBuf = 512;
  cSizeProgress = 52;

type
  TProgressBar = class
  private
    FLastPos, FLastPS: Integer;
    FSaveScreen: THandle;
    FMaxCounter: Integer;
    FTitle, FConsoleTitle: TFarString;
    FLinesBefore, FLinesAfter: Integer;
    FTitleBuf: array[0..cMaxBuf - 1] of TFarChar;
    FEsc: Boolean;
    FConfirmTitle, FConfirmText: PFarChar;
    FSizeProgress: Integer;
    FShowPs: Boolean;

    function CheckForEsc: Boolean;
  public
    constructor Create(const aTitle: TFarString; aMaxCounter: Integer;
      aSizeProgress: Integer = cSizeProgress; aShowPs: Boolean = True;
      aLinesBefore: Integer = 0; aLinesAfter: Integer = 0); overload;
    constructor Create(const aTitle: TFarString; aMaxCounter: Integer;
      aEsc: Boolean; aConfirmTitle: PFarChar = nil; aConfirmText: PFarChar = nil;
      aSizeProgress: Integer = cSizeProgress; aShowPs: Boolean = True;
      aLinesBefore: Integer = 0; aLinesAfter: Integer = 0); overload;
    destructor Destroy; override;
    function UpdateProgress(counter: Integer;
      const TextBefore: TFarString = ''; const TextAfter: TFarString = ''): Boolean;
    function IncProgress(addcounter: Integer = 1;
      const TextBefore: TFarString = ''; const TextAfter: TFarString = ''): Boolean;
    property LinesBefore: Integer read FLinesBefore;
    property LinesAfter: Integer read FLinesAfter;
  end;

implementation

const
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

constructor TProgressBar.Create(const aTitle: TFarString;
  aMaxCounter, aSizeProgress: Integer;
  aShowPs: Boolean; aLinesBefore, aLinesAfter: Integer);
var
  i: Integer;
  str: TFarString;
begin
  inherited Create;
{$IFDEF UNICODE}
  GetConsoleTitleW(FTitleBuf, cMaxBuf);
  FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSSTATE,
    Pointer(PS_NORMAL));
{$ELSE}
  GetConsoleTitleA(FTitleBuf, cMaxBuf);
{$ENDIF}
  FTitle := aTitle;
  FConsoleTitle := FTitleBuf;
  i := PosEx(cFar, FConsoleTitle);
  if i > 0 then
    Delete(FConsoleTitle, 1, i - 1);
  FConsoleTitle := FTitle + FConsoleTitle;
  FLastPS := -1;
{$IFDEF UNICODE}
  SetConsoleTitleW(PFarChar(FConsoleTitle));
{$ELSE}
  SetConsoleTitleA(PFarChar(FConsoleTitle));
{$ENDIF}
  FLinesBefore := aLinesBefore;
  FLinesAfter := aLinesAfter;
  FShowPs := aShowPs;
  str := FTitle + #10;
  for i := 0 to FLinesBefore - 1 do
    str := str + #10;
  FSizeProgress := aSizeProgress;
  if FShowPs then
    Dec(FSizeProgress, 5);
  for i := 1 to FSizeProgress do
    str := str + chrHatch;
  if FShowPs then
    str := str + '   0%';
  str := str + #10;
  for i := 0 to FLinesAfter - 1 do
    str := str + #10;
  FSaveScreen := FARAPI.SaveScreen(0, 0, -1, -1);
  FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
    PPCharArray(@str[1]), 0, 0);
  FMaxCounter := aMaxCounter;
  FLastPos := 0;
  FEsc := False;
end;

constructor TProgressBar.Create(const aTitle: TFarString; aMaxCounter: Integer;
  aEsc: Boolean; aConfirmTitle, aConfirmText: PFarChar;
  aSizeProgress: Integer; aShowPs: Boolean; aLinesBefore, aLinesAfter: Integer);
begin
  Create(aTitle, aMaxCounter, aSizeProgress, aShowPs, aLinesBefore, aLinesAfter);
  FEsc := aEsc;
  if FEsc then
  begin
    FConfirmTitle := aConfirmTitle;
    FConfirmText := aConfirmText;
  end
  else
  begin
    FConfirmTitle := nil;
    FConfirmText := nil;
  end;
end;

destructor TProgressBar.Destroy;
begin
{$IFDEF UNICODE}
  SetConsoleTitleW(FTitleBuf);
  FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSSTATE,
    Pointer(PS_NOPROGRESS));
  FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_PROGRESSNOTIFY, nil);
{$ELSE}
  SetConsoleTitleA(FTitleBuf);
{$ENDIF}
  FARAPI.RestoreScreen(FSaveScreen);
  inherited;
end;

function TProgressBar.IncProgress(addcounter: Integer;
  const TextBefore, TextAfter: TFarString): Boolean;
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
  Result := UpdateProgress(counter, TextBefore, TextAfter);
end;

function TProgressBar.UpdateProgress(counter: Integer;
  const TextBefore, TextAfter: TFarString): Boolean;
var
  pos, ps: Integer;
  str: TFarString;
  i: Integer;
{$IFDEF UNICODE}
  pv: TProgressValue;
{$ENDIF}
begin
  if counter <> 0 then
  begin
    if FLastPos > FMaxCounter then
      FLastPos := FMaxCounter;
    if (FLastPos <> counter) or
      ((FLinesBefore > 0) and (TextBefore <> '')) or
      ((FLinesAfter > 0) and (TextAfter <> '')) then
    begin
      ps := counter * 100 div FMaxCounter;
      FLastPos := counter;
      pos := counter * FSizeProgress div FMaxCounter;
      str := FTitle + #10;
      if FLinesBefore > 0 then
         str := str + TextBefore + #10;
      if pos <> 0 then
        for i := 1 to pos do
          str := str + chrBrick;
      if pos <> FSizeProgress then
        for i := pos + 1 to FSizeProgress do
          str := str + chrHatch;
      if FShowPs then
        str := str + Format(' %3d%%', [ps]);
      str := str + #10;
      if FLinesAfter > 0 then
         str := str + TextAfter;
      FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
        PPCharArray(@str[1]), 0, 0);
      if FLastPS <> ps then
{$IFDEF UNICODE}
      begin
        SetConsoleTitleW(PFarChar('{' + Int2Str(ps) + '%} ' + FConsoleTitle));
        pv.Completed := counter;
        pv.Total := FMaxCounter;
        FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSVALUE, @pv);
      end;
{$ELSE}
        SetConsoleTitleA(PFarChar('{' + Int2Str(ps) + '%} ' + FConsoleTitle));
{$ENDIF}
    end;
  end;
  Result := not (FEsc and CheckForEsc);
  if not Result then
  begin
    if Assigned(FConfirmTitle) then
    begin
{$IFDEF UNICODE}
      FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSSTATE,
        Pointer(PS_PAUSED));
      try
{$ENDIF}
        Result := ShowMessage(FConfirmTitle, FConfirmText,
          FMSG_WARNING + FMSG_MB_YESNO) <> 0;
{$IFDEF UNICODE}
      finally
        FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSSTATE,
          Pointer(PS_NORMAL));
        pv.Completed := counter;
        pv.Total := FMaxCounter;
        FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSVALUE, @pv);
      end;
{$ENDIF}
    end;
  end;
end;

end.
