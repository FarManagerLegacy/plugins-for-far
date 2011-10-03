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
  TProgressInit = record
    FMaxPos: Integer;
    FShowPs: Boolean;
    FLines: Integer;
  end;
  TProgressInfo = record
    FPos: Integer;
    FText: TFarString;
  end;
  TProgressData = record
    FInit: TProgressInit;
    FLastPos, FLastPS, FSizeProgress: Integer;
  end;
  TMultiProgressBar = class
  private
    FSaveScreen: THandle;
    FTitle, FConsoleTitle: TFarString;
    FTitleBuf: array[0..cMaxBuf - 1] of TFarChar;
    FEsc: Boolean;
    FConfirmTitle, FConfirmText: PFarChar;
    FProgressData: array of TProgressData;
    FProgressCount: Integer;
    FTotalIndex: Integer;
    FLinesAfter: Integer;

    function CheckForEsc: Boolean;
  public
    constructor Create(const aTitle: TFarString; const aInit: array of TProgressInit;
      aSizeProgress: Integer = cSizeProgress;
      aProgressCount: Integer = -1; aTotalIndex: Integer = -1;
      aLinesAfter: Integer = 0); overload;
    constructor Create(const aTitle: TFarString; const aInit: array of TProgressInit;
      aEsc: Boolean; aConfirmTitle: PFarChar = nil; aConfirmText: PFarChar = nil;
      aSizeProgress: Integer = cSizeProgress;
      aProgressCount: Integer = -1; aTotalIndex: Integer = -1;
      aLinesAfter: Integer = 0); overload;
    destructor Destroy; override;
    function UpdateProgress(const aData: array of TProgressInfo;
      const TextAfter: TFarString = ''): Boolean;
    function IncProgress(const aData: array of TProgressInfo;
      const TextAfter: TFarString = ''): Boolean;
    property LinesAfter: Integer read FLinesAfter;
    property ProgressCount: Integer read FProgressCount;
  end;

  TProgressBar = class(TMultiProgressBar)
  public
    constructor Create(const aTitle: TFarString;
      aMaxPos: Integer;
      aLinesBefore: Integer = 0;
      aShowPs: Boolean = True;
      aLinesAfter: Integer = 0;
      aSizeProgress: Integer = cSizeProgress); overload;
    constructor Create(const aTitle: TFarString; aEsc: Boolean;
      aMaxPos: Integer;
      aLinesBefore: Integer = 0;
      aShowPs: Boolean = True;
      aLinesAfter: Integer = 0;
      aConfirmTitle: PFarChar = nil; aConfirmText: PFarChar = nil;
      aSizeProgress: Integer = cSizeProgress); overload;
    function UpdateProgress(aPos: Integer;
      const TextBefore: TFarString = ''; const TextAfter: TFarString = ''): Boolean;
    function IncProgress(aPos: Integer = 1;
      const TextBefore: TFarString = ''; const TextAfter: TFarString = ''): Boolean;
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
  cFar = ' - Far';

{ TMultiProgressBar }

constructor TMultiProgressBar.Create(const aTitle: TFarString;
  const aInit: array of TProgressInit;
  aSizeProgress, aProgressCount, aTotalIndex, aLinesAfter: Integer);
var
  i, j: Integer;
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
{$IFDEF UNICODE}
  SetConsoleTitleW(PFarChar(FConsoleTitle));
{$ELSE}
  SetConsoleTitleA(PFarChar(FConsoleTitle));
{$ENDIF}
  FLinesAfter := aLinesAfter;
  str := FTitle + #10;
  if aProgressCount < 0 then
    FProgressCount := Length(aInit)
  else
    FProgressCount := aProgressCount;
  if aTotalIndex < 0 then
    FTotalIndex := FProgressCount - 1
  else
    FTotalIndex := aTotalIndex;
  SetLength(FProgressData, FProgressCount);
  for j := 0 to FProgressCount - 1 do
    with FProgressData[j] do
    begin
      FInit := aInit[j];
      FLastPos := 0;
      FLastPS := -1;
      for i := 0 to FInit.FLines - 1 do
        str := str + #10;
      FSizeProgress := aSizeProgress;
      if FInit.FShowPs then
        Dec(FSizeProgress, 5);
      for i := 1 to FSizeProgress do
        str := str + chrHatch;
      if FInit.FShowPs then
        str := str + '   0%';
      str := str + #10;
    end;
  for i := 0 to FLinesAfter - 1 do
    str := str + #10;
  FSaveScreen := FARAPI.SaveScreen(0, 0, -1, -1);
  FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
    PPCharArray(@str[1]), 0, 0);
  FEsc := False;
end;

function TMultiProgressBar.CheckForEsc: Boolean;
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

constructor TMultiProgressBar.Create(const aTitle: TFarString;
  const aInit: array of TProgressInit; aEsc: Boolean; aConfirmTitle,
  aConfirmText: PFarChar;
  aSizeProgress, aProgressCount, aTotalIndex, aLinesAfter: Integer);
begin
  Create(aTitle, aInit, aSizeProgress, aProgressCount, aTotalIndex, aLinesAfter);
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

destructor TMultiProgressBar.Destroy;
begin
  SetLength(FProgressData, 0);
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

function TMultiProgressBar.IncProgress(const aData: array of TProgressInfo;
  const TextAfter: TFarString): Boolean;
var
  i: Integer;
  Data: array of TProgressInfo;
begin
  SetLength(Data, Length(aData));
  for i := 0 to Length(aData) - 1 do
  begin
    Data[i] := aData[i];
    if FProgressData[i].FLastPos < FProgressData[i].FInit.FMaxPos then
    begin
      Data[i].FPos := FProgressData[i].FLastPos + Data[i].FPos;
      if Data[i].FPos > FProgressData[i].FInit.FMaxPos then
        Data[i].FPos := FProgressData[i].FInit.FMaxPos;
    end
    else
      Data[i].FPos := FProgressData[i].FInit.FMaxPos;
  end;
  Result := UpdateProgress(Data, TextAfter);
end;

function TMultiProgressBar.UpdateProgress(const aData: array of TProgressInfo;
  const TextAfter: TFarString): Boolean;
var
  pos, ps: Integer;
  str: TFarString;
  i, j: Integer;
{$IFDEF UNICODE}
  pv: TProgressValue;
{$ENDIF}
begin
  str := FTitle + #10;
  for j := 0 to FProgressCount - 1 do
  begin
    if FProgressData[j].FLastPos > FProgressData[j].FInit.FMaxPos then
      FProgressData[j].FLastPos := FProgressData[j].FInit.FMaxPos;
    if (FProgressCount > 1) or
      (FProgressData[j].FLastPos <> aData[j].FPos) or
      ((FProgressData[j].FInit.FLines > 0) and (aData[j].FText <> '')) or
      ((FLinesAfter > 0) and (TextAfter <> '')) then
    begin
      ps := aData[j].FPos * 100 div FProgressData[j].FInit.FMaxPos;
      FProgressData[j].FLastPos := aData[j].FPos;
      pos := aData[j].FPos * FProgressData[j].FSizeProgress div
        FProgressData[j].FInit.FMaxPos;
      if FProgressData[j].FInit.FLines > 0 then
         str := str + aData[j].FText + #10;
      if pos <> 0 then
        for i := 1 to pos do
          str := str + chrBrick;
      if pos <> FProgressData[j].FSizeProgress then
        for i := pos + 1 to FProgressData[j].FSizeProgress do
          str := str + chrHatch;
      if FProgressData[j].FInit.FShowPs then
        str := str + Format(' %3d%%', [ps]);
      str := str + #10;
    if (j = FTotalIndex) and (FProgressData[j].FLastPS <> ps) then
{$IFDEF UNICODE}
    begin
      SetConsoleTitleW(PFarChar('{' + Int2Str(ps) + '%} ' + FConsoleTitle));
      pv.Completed := aData[j].FPos;
      pv.Total := FProgressData[j].FInit.FMaxPos;
      FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSVALUE, @pv);
    end;
{$ELSE}
      SetConsoleTitleA(PFarChar('{' + Int2Str(ps) + '%} ' + FConsoleTitle));
{$ENDIF}
    end;
  end;
  if str <> '' then
  begin
    if FLinesAfter > 0 then
       str := str + TextAfter;
    FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
      PPCharArray(@str[1]), 0, 0);
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
        pv.Completed := aData[FTotalIndex].FPos;
        pv.Total := FProgressData[FTotalIndex].FInit.FMaxPos;
        FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSVALUE, @pv);
      end;
{$ENDIF}
    end;
  end;
end;

{ TProgressBar }

constructor TProgressBar.Create(const aTitle: TFarString;
  aMaxPos, aLinesBefore: Integer; aShowPs: Boolean;
  aLinesAfter, aSizeProgress: Integer);
var
  Init: array [0..0] of TProgressInit;
begin
  Init[0].FMaxPos := aMaxPos;
  Init[0].FShowPs := aShowPs;
  Init[0].FLines := aLinesBefore;
  inherited Create(aTitle, Init, aSizeProgress, 1, 0, aLinesAfter);
end;

constructor TProgressBar.Create(const aTitle: TFarString; aEsc: Boolean;
  aMaxPos, aLinesBefore: Integer; aShowPs: Boolean; aLinesAfter: Integer;
  aConfirmTitle, aConfirmText: PFarChar;
  aSizeProgress: Integer);
var
  Init: array [0..0] of TProgressInit;
begin
  Init[0].FMaxPos := aMaxPos;
  Init[0].FShowPs := aShowPs;
  Init[0].FLines := aLinesBefore;
  inherited Create(aTitle, Init, aEsc, aConfirmTitle, aConfirmText,
    aSizeProgress, 1, 0, aLinesAfter);
end;

function TProgressBar.IncProgress(aPos: Integer; const TextBefore,
  TextAfter: TFarString): Boolean;
var
  Data: array [0..0] of TProgressInfo;
begin
  Data[0].FPos := aPos;
  Data[0].FText := TextBefore;
  Result := inherited IncProgress(Data, TextAfter);
end;

function TProgressBar.UpdateProgress(aPos: Integer; const TextBefore,
  TextAfter: TFarString): Boolean;
var
  Data: array [0..0] of TProgressInfo;
begin
  Data[0].FPos := aPos;
  Data[0].FText := TextBefore;
  Result := inherited UpdateProgress(Data, TextAfter);
end;

end.
