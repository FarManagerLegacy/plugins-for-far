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
    FMaxPos: Integer;
    FTitle, FConsoleTitle: TFarString;
    FLinesBefore, FLinesAfter: Integer;
    FTitleBuf: array[0..cMaxBuf - 1] of TFarChar;
    FEsc: Boolean;
    FConfirmTitle, FConfirmText: PFarChar;
    FSizeProgress: Integer;
    FShowPs: Boolean;

    function CheckForEsc: Boolean;
  public
    constructor Create(const aTitle: TFarString; aMaxPos: Integer;
      aSizeProgress: Integer = cSizeProgress; aShowPs: Boolean = True;
      aLinesBefore: Integer = 0; aLinesAfter: Integer = 0); overload;
    constructor Create(const aTitle: TFarString; aMaxPos: Integer;
      aEsc: Boolean; aConfirmTitle: PFarChar = nil; aConfirmText: PFarChar = nil;
      aSizeProgress: Integer = cSizeProgress; aShowPs: Boolean = True;
      aLinesBefore: Integer = 0; aLinesAfter: Integer = 0); overload;
    destructor Destroy; override;
    function UpdateProgress(aPos: Integer;
      const TextBefore: TFarString = ''; const TextAfter: TFarString = ''): Boolean;
    function IncProgress(AddPos: Integer = 1;
      const TextBefore: TFarString = ''; const TextAfter: TFarString = ''): Boolean;
    property LinesBefore: Integer read FLinesBefore;
    property LinesAfter: Integer read FLinesAfter;
  end;

  TProgressInit = record
    FMaxPos: Integer;
    FShowPs: Boolean;
    FLines: Integer;
  end;
  TProgressInitArray = array of TProgressInit;
  TProgressInfo = record
    FPos: Integer;
    FText: TFarString;
  end;
  TProgressInfoArray = array of TProgressInfo;
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
    constructor Create(const aTitle: TFarString; const aInit: TProgressInitArray;
      aSizeProgress: Integer = cSizeProgress; aTotalIndex: Integer = -1;
      aLinesAfter: Integer = 0); overload;
    constructor Create(const aTitle: TFarString; const aInit: TProgressInitArray;
      aEsc: Boolean; aConfirmTitle: PFarChar = nil; aConfirmText: PFarChar = nil;
      aSizeProgress: Integer = cSizeProgress; aTotalIndex: Integer = -1;
      aLinesAfter: Integer = 0); overload;
    destructor Destroy; override;
    function UpdateProgress(const aData: TProgressInfoArray;
      const TextAfter: TFarString = ''): Boolean;
    function IncProgress(const aData: TProgressInfoArray;
      const TextAfter: TFarString = ''): Boolean;
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
  aMaxPos, aSizeProgress: Integer;
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
  FMaxPos := aMaxPos;
  FLastPos := 0;
  FEsc := False;
end;

constructor TProgressBar.Create(const aTitle: TFarString; aMaxPos: Integer;
  aEsc: Boolean; aConfirmTitle, aConfirmText: PFarChar;
  aSizeProgress: Integer; aShowPs: Boolean; aLinesBefore, aLinesAfter: Integer);
begin
  Create(aTitle, aMaxPos, aSizeProgress, aShowPs, aLinesBefore, aLinesAfter);
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

function TProgressBar.IncProgress(AddPos: Integer;
  const TextBefore, TextAfter: TFarString): Boolean;
var
  pos: Integer;
begin
  if FLastPos < FMaxPos then
  begin
    pos := FLastPos + AddPos;
    if pos > FMaxPos then
      pos := FMaxPos;
  end
  else
    pos := FMaxPos;
  Result := UpdateProgress(pos, TextBefore, TextAfter);
end;

function TProgressBar.UpdateProgress(aPos: Integer;
  const TextBefore, TextAfter: TFarString): Boolean;
var
  pos, ps: Integer;
  str: TFarString;
  i: Integer;
{$IFDEF UNICODE}
  pv: TProgressValue;
{$ENDIF}
begin
  if aPos <> 0 then
  begin
    if FLastPos > FMaxPos then
      FLastPos := FMaxPos;
    if (FLastPos <> aPos) or
      ((FLinesBefore > 0) and (TextBefore <> '')) or
      ((FLinesAfter > 0) and (TextAfter <> '')) then
    begin
      ps := aPos * 100 div FMaxPos;
      FLastPos := aPos;
      pos := aPos * FSizeProgress div FMaxPos;
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
        pv.Completed := aPos;
        pv.Total := FMaxPos;
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
        pv.Completed := aPos;
        pv.Total := FMaxPos;
        FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_SETPROGRESSVALUE, @pv);
      end;
{$ENDIF}
    end;
  end;
end;

{ TMultiProgressBar }

constructor TMultiProgressBar.Create(const aTitle: TFarString;
  const aInit: TProgressInitArray;
  aSizeProgress, aTotalIndex, aLinesAfter: Integer);
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
  FProgressCount := Length(aInit);
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
  const aInit: TProgressInitArray; aEsc: Boolean; aConfirmTitle,
  aConfirmText: PFarChar; aSizeProgress, aTotalIndex, aLinesAfter: Integer);
begin
  Create(aTitle, aInit, aSizeProgress, aLinesAfter);
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

function TMultiProgressBar.IncProgress(const aData: TProgressInfoArray;
  const TextAfter: TFarString): Boolean;
var
  i: Integer;
begin
  for i := 0 to Length(aData) - 1 do
  begin
    if FProgressData[i].FLastPos < FProgressData[i].FInit.FMaxPos then
    begin
      aData[i].FPos := FProgressData[i].FLastPos + aData[i].FPos;
      if aData[i].FPos > FProgressData[i].FInit.FMaxPos then
        aData[i].FPos := FProgressData[i].FInit.FMaxPos;
    end
    else
      aData[i].FPos := FProgressData[i].FInit.FMaxPos;
  end;
  Result := UpdateProgress(aData, TextAfter);
end;

function TMultiProgressBar.UpdateProgress(const aData: TProgressInfoArray;
  const TextAfter: TFarString): Boolean;
var
  pos, ps: Integer;
  str: TFarString;
  i, j: Integer;
{$IFDEF UNICODE}
  pv: TProgressValue;
{$ENDIF}
begin
  for j := 0 to FProgressCount - 1 do
  begin
    if aData[j].FPos <> 0 then
    begin
      if FProgressData[j].FLastPos > FProgressData[j].FInit.FMaxPos then
        FProgressData[j].FLastPos := FProgressData[j].FInit.FMaxPos;
      {if (FProgressData[j].FLastPos <> aData[j].FPos) or
        ((FLinesBefore > 0) and (TextBefore <> '')) or
        ((FLinesAfter > 0) and (TextAfter <> '')) then}
      begin
        ps := aData[j].FPos * 100 div FProgressData[j].FInit.FMaxPos;
        FProgressData[j].FLastPos := aData[j].FPos;
        pos := aData[j].FPos * FProgressData[j].FSizeProgress div
          FProgressData[j].FInit.FMaxPos;
        str := FTitle + #10;
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
        if FLinesAfter > 0 then
           str := str + TextAfter;
        FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN, nil,
          PPCharArray(@str[1]), 0, 0);
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

end.
