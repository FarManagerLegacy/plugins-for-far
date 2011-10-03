unit UCanon;

{$i CommonDirectives.inc}

interface

{$DEFINE USE_DYNLOAD}

uses
  windows,
  kol,
  err,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  plugin,
{$ENDIF}
{$IFDEF USE_DYNLOAD}
  UEdSdkApi,
{$ELSE}
  EDSDKApi,
{$ENDIF}
  EDSDKError,
  EDSDKType,
  UEdSdkError,
  UTypes,
  UUtils,
  UProgressBar,
  ULang,
  UDirNode,
  UEDialogs;

type
  TBaseRefType = (brtCamera, brtVolume, brtDirItem);

  PPanelUserData = ^TPanelUserData;
  TPanelUserData = record
    BaseRef: EdsBaseRef;
    BaseRefType: TBaseRefType;
  end;

  TCanonDirNode = class(TDirNode)
  private
    procedure GetCameraInfo;
    procedure GetVolumeInfo;
    procedure GetDirectoryInfo(getDateTime: Boolean);
  protected
    procedure FreeUserData(UserData: Pointer); override;
  public
    constructor Create; override;
    procedure FillPanelItem; override;
  end;

  TCameraInfo = record
    CameraName: TFarString;
    BodyID: TFarString;
    FirmwareVersion: TFarString;
    DateTime: TFarString;
    BatteryLevel: TFarString;
    BatteryQuality: TFarString;
  end;

  TVolumeInfo = record
    VolumeName: TFarString;
    StorageType: TFarString; // 0 = no card   1 = CD         2 = SD
    Access: TFarString;      // 0 = Read only 1 = Write only 2 = Read/Write
    MaxCapacity: TFarString;
    FreeSpace: TFarString;
  end;

  TCanon = class
  private
    FCurDirectory: TFarString;
    FPanelTitle: TFarString;
    FInfoLines: PInfoPanelLineArray;
    FInfoLineCount: Integer;

    FPanelModes: array[0..cMaxPanelModes - 1] of TPanelMode;
    FColumnTitles: array[0..1] of PFarChar;

    FDirNode: TDirNode;

    FCameraInfo: TCameraInfo;
    FVolumeInfo: TVolumeInfo;
    FRereadFindData: Boolean;

    FTotalFiles, FCurFile: Cardinal;
    FTotalFilesSize, FCurTotalFilesSize: Int64;
  private
    class procedure LoadLib(const FileName: TFarString);
    class procedure FreeLib;
    class procedure OpenSession(session: EdsBaseRef; Sender: TCanon);
    class procedure CloseSession;
    class function GetCurrentSession: EdsBaseRef;

    procedure RecursiveDownload(dirItem: EdsDirectoryItemRef;
      const DestPath: TFarString; Move: Integer; Silent: Boolean;
      ProgressBar: TMultiProgressBar;
      var overall, skipall, overroall, skiproall: Boolean);
    procedure DownloadFile(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
      Silent: Boolean; ProgressBar: TMultiProgressBar; attrib: Cardinal;
      var overall, skipall, overroall, skiproall, skipfile: Boolean);
    procedure DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
      var skipall, delallfolder: Boolean); overload;
    procedure DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo = nil); overload;
    procedure SetInfoLinesCount(Value: Integer);
    procedure OnCameraDisconnect;
    procedure OnBeforeChangeDirEvent(ADirNode: TDirNode; var Allow: Boolean);
    procedure OnChangeDirEvent(ADirNode: TDirNode);
    function CountFiles(PanelItem: PPluginPanelItem; ItemsNumber, Move: Integer;
      var TotalFiles: Cardinal; var TotalFilesSize: Int64): Boolean;
  public
    constructor Create(const FileName: TFarString);
    destructor Destroy; override;

    procedure GetOpenPluginInfo(var Info: TOpenPluginInfo);
    function GetFindData(var PanelItem: PPluginPanelItem;
      var ItemsNumber: Integer; OpMode: Integer): Integer;
    function SetDirectory(const Dir: PFarChar; OpMode: Integer): Integer;
    function DeleteFiles(PanelItem: PPluginPanelItem; ItemsNumber,
      OpMode: Integer): Integer;
    function GetFiles(PanelItem: PPluginPanelItem; ItemsNumber, Move: Integer;
      {$IFDEF UNICODE}var{$ENDIF} DestPath: PFarChar; OpMode: Integer): Integer;

    property RereadFindData: Boolean read FRereadFindData write FRereadFindData;
    property CurDirectory: TFarString read FCurDirectory;
  end;

procedure GetImageDate(stream: EdsStreamRef; dirItem: EdsDirectoryItemRef;
  var FileTime: TFileTime); overload;
procedure GetImageDate(dirItem: EdsDirectoryItemRef;
  var FileFime: TFileTime); overload;

procedure CheckEdsError(edserr: EdsError);

implementation

uses UDialogs;

procedure GetImageDate(stream: EdsStreamRef; dirItem: EdsDirectoryItemRef;
  var FileTime: TFileTime);
var
  image: EdsImageRef;
  sysTime: TSystemTime;
  dateTime: EdsTime;
  localFileTime: TFileTime;
  P: Pointer;
begin
  // Получение информации о дате/времени
  CheckEdsError(EdsDownloadThumbnail(dirItem, stream));
  CheckEdsError(EdsCreateImageRef(stream, image));
  try
    P := @dateTime;
    CheckEdsError(EdsGetPropertyData(image, kEdsPropID_DateTime, 0,
      SizeOf(EdsTime), Pointer(P^)));
    sysTime.wYear := dateTime.year;
    sysTime.wMonth := dateTime.month;
    sysTime.wDay := dateTime.day;
    sysTime.wHour := dateTime.hour;
    sysTime.wMinute := dateTime.minute;
    sysTime.wSecond := dateTime.second;
    sysTime.wMilliseconds := dateTime.millseconds;

    SystemTimeToFileTime(sysTime, localFileTime);
    LocalFileTimeToFileTime(localFileTime, FileTime);
  finally
    EdsRelease(image);
  end;
end;

procedure GetImageDate(dirItem: EdsDirectoryItemRef; var FileFime: TFileTime);
var
  stream: EdsStreamRef;
begin
  CheckEdsError(EdsCreateMemoryStream(0, stream));
  try
    GetImageDate(stream, dirItem, FileFime);
  finally
    EdsRelease(stream);
  end;
end;

procedure CheckEdsError(edserr: EdsError);
begin
  if edserr <> EDS_ERR_OK then
    raise Exception.CreateCustom(edserr, '');
end;

procedure SetFindDataName(var FindData: TFarFindData; FileName: PAnsiChar);
{$IFDEF UNICODE}
var
  bufsize: Integer;
{$ENDIF}
begin
{$IFDEF UNICODE}
  bufsize := MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, FileName, -1, nil, 0);
  if bufsize > 1 then
  begin
    GetMem(FindData.cFileName, bufsize * 2);
    MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, FileName, -1, FindData.cFileName,
      bufsize);
  end;
{$ELSE}
  StrCopy(FindData.cFileName, FileName);
{$ENDIF}
end;

{ Callback Functions }

type
  PContextData = ^TContextData;
  TContextData = record
    FProgressBar: TMultiProgressBar;
    FText, FText2, FTextAfter: TFarString;
    FFileSize, FFilesSize: Cardinal;
  end;

function EdsProgressCallback(inPercent: EdsUInt32; inContext: Pointer;
  var outCancel: EdsBool): EdsError; stdcall;
var
  ProgressInfo: array[0..1] of TProgressInfo;
begin
  with PContextData(inContext)^ do
  begin
    ProgressInfo[0].FPos := inPercent;
    ProgressInfo[0].FText := FText;
    if FProgressBar.ProgressCount > 1 then
    begin
      ProgressInfo[1].FPos := FFilesSize + FFileSize * inPercent div 100;
      ProgressInfo[1].FText := FText2;
    end;
    if not FProgressBar.UpdateProgress(ProgressInfo, FTextAfter) then
    begin
      outCancel := 1;
      Result := EDS_ERR_OPERATION_CANCELLED;
    end
    else
      Result := EDS_ERR_OK;
  end;
end;

function EdsStateEventHandler(inEvent: EdsStateEvent; inParamter: EdsUInt32;
  inContext: EdsUInt32): EdsError; stdcall;
begin
  TCanon(inContext).OnCameraDisconnect;
  Result := EDS_ERR_OK;
end;

{ TCanon }

type
  TPluginPanelItemArray = array of TPluginPanelItem;

constructor TCanon.Create(const FileName: TFarString);
begin
  inherited Create;
  LoadLib(FileName);
  FInfoLines := nil;
  FInfoLineCount := 0;
  FDirNode := nil;
  // FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_GETPANELSHORTINFO, @FPanelInfo);
end;

function TCanon.DeleteFiles(PanelItem: PPluginPanelItem; ItemsNumber,
  OpMode: Integer): Integer;
var
  text: TFarString;
  UserData: PPanelUserData;
  dirInfo: EdsDirectoryItemInfo;
  skipall, delallfolder: Boolean;
  i: Integer;
begin
  Result := 0;
  try
    if (ItemsNumber > 0) and
      (TPluginPanelItemArray(PanelItem)[0].UserData <> 0) then
    begin
      UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[0].UserData);
      if UserData^.BaseRefType = brtDirItem then
      begin
        if ItemsNumber = 1 then
        begin
          if UserData^.BaseRefType = brtDirItem then
          begin
            CheckEdsError(EdsGetDirectoryItemInfo(UserData^.BaseRef, dirInfo));
            if dirInfo.isFolder = 0 then
              text := GetMsgStr(MDeleteFile)
            else
              text := GetMsgStr(MDeleteFolder);
  {$IFDEF UNICODE}
              text := Format(text, [CharToWideChar(dirInfo.szFileName)]);
  {$ELSE}
              text := Format(text, [dirInfo.szFileName]);
  {$ENDIF}
          end
          else
            Exit;
        end
        else
          text := Format(GetMsg(MDeleteItems), [ItemsNumber,
            GetMsg(TLanguageID(Ord(MOneOk) + GetOk(ItemsNumber)))]);
        if (OpMode and OPM_SILENT <> 0) or
          (ShowMessage(GetMsg(MDeleteTitle), PFarChar(text),
            [GetMsg(MBtnDelete), GetMsg(MBtnCancel)]) = 0) then
        begin
          skipall := False;
          delallfolder := FARAPI.AdvControl(FARAPI.ModuleNumber,
            ACTL_GETCONFIRMATIONS, nil) and FCS_DELETENONEMPTYFOLDERS = 0;
          if ItemsNumber = 1 then
            DeleteDirItem(UserData^.BaseRef, @dirInfo, OpMode, skipall, delallfolder)
          else if (OpMode and OPM_SILENT <> 0) or
              (FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_GETCONFIRMATIONS, nil) and
                FCS_DELETE = 0) or
              (ShowMessage(GetMsg(MDeleteFilesTitle), PFarChar(text),
                [GetMsg(MBtnAll), GetMsg(MBtnCancel)], FMSG_WARNING) = 0) then
            for i := 0 to ItemsNumber - 1 do
            begin
              UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData);
              DeleteDirItem(UserData^.BaseRef, nil, OpMode, skipall, delallfolder);
            end;
          Result := 1;
        end;
      end;
    end;
  except
    on E: Exception do
      if (E.Code = e_Custom) and (E.ErrorCode <> EDS_ERR_OPERATION_CANCELLED) then
        raise;
  end;
end;

destructor TCanon.Destroy;
begin
  if FInfoLineCount > 0 then
  begin
    FreeMem(FInfoLines);
    FInfoLineCount := 0;
  end;
  if Assigned(FDirNode) then
  begin
    FDirNode := FDirNode.RootDir;
    FreeAndNil(FDirNode);
  end;
  FreeLib;
  inherited;
end;

procedure TCanon.GetOpenPluginInfo(var Info: TOpenPluginInfo);
  procedure SetInfoLine(Index: Integer; Text: PFarChar; SetText: Boolean);
  begin
{$IFDEF UNICODE}
    if SetText then
      FInfoLines^[Index].Text := Text
    else
      FInfoLines^[Index].Data := Text;
{$ELSE}
    if SetText then
      StrLCopy(FInfoLines^[Index].Text, Text, 79)
    else
      StrLCopy(FInfoLines^[Index].Data, Text, 79);
{$ENDIF}
  end;
  procedure SetPanelModes(MsgId: TLanguageID;
    const AColumnTypes, AColumnWidths: PFarChar);
  var
    i: Integer;
  begin
    FColumnTitles[0] := GetMsg(MsgId);
    FColumnTitles[1] := nil;
    for i := 0 to cMaxPanelModes - 1 do
      with FPanelModes[i] do
      begin
        ColumnTypes := AColumnTypes;
        ColumnWidths := AColumnWidths;
        ColumnTitles := @FColumnTitles;
      end;
    with Info do
    begin
      PanelModesArray := @FPanelModes;
      PanelModesNumber := cMaxPanelModes;
    end;
  end;
const
  cCameraColumnTypes: PFarChar = 'N';
  cCameraColumnWidths: PFarChar = '0';
  cVolumeColumnTypes: PFarChar = 'N,SC';
  cVolumeColumnWidths: PFarChar = '0,10';
begin
  with Info do
  begin
    StructSize := SizeOf(Info);
    Format := PFarChar(ConfigData.Prefix);
    Flags := OPIF_ADDDOTS;
    CurDir := PFarChar(CurDirectory);

    if CurDirectory <> '' then
    begin
      FPanelTitle := GetMsgStr(MPalelTitle) + ':' + FCurDirectory;
      PanelTitle := PFarChar(FPanelTitle);
    end
    else
      PanelTitle := GetMsg(MPalelTitle);

    if Assigned(FDirNode) then
    begin
      if FDirNode.IsRoot then
        SetPanelModes(MCameraName, cCameraColumnTypes, cCameraColumnWidths)
      else if FDirNode.Depth = 1 then
        SetPanelModes(MVolumeName, cVolumeColumnTypes, cVolumeColumnWidths)
      else
        Flags := Flags + OPIF_USEFILTER + OPIF_USESORTGROUPS + OPIF_USEHIGHLIGHTING;
      if not FDirNode.IsRoot then
        case FDirNode.Depth of
          1:
          begin
            Info.InfoLinesNumber := 7;
            SetInfoLinesCount(Info.InfoLinesNumber);
            FInfoLines^[0].Separator := 1;
            SetInfoLine(0, GetMsg(MCameraInfo), True);
            SetInfoLine(1, GetMsg(MCameraName), True);
            SetInfoLine(1, PFarChar(FCameraInfo.CameraName), False);
            SetInfoLine(2, GetMsg(MSerialNumber), True);
            SetInfoLine(2, PFarChar(FCameraInfo.BodyID), False);
            SetInfoLine(3, GetMsg(MFirmwareVersion), True);
            SetInfoLine(3, PFarChar(FCameraInfo.FirmwareVersion), False);
            SetInfoLine(4, GetMsg(MBodyDateTime), True);
            SetInfoLine(4, PFarChar(FCameraInfo.DateTime), False);
            SetInfoLine(5, GetMsg(MBatteryLevel), True);
            SetInfoLine(5, PFarChar(FCameraInfo.BatteryLevel), False);
            SetInfoLine(6, GetMsg(MBatteryQuality), True);
            SetInfoLine(6, PFarChar(FCameraInfo.BatteryQuality), False);
          end;
          2:
          begin
            Info.InfoLinesNumber := 6;
            SetInfoLinesCount(Info.InfoLinesNumber);
            FInfoLines^[0].Separator := 1;
            SetInfoLine(0, GetMsg(MVolumeInfo), True);
            SetInfoLine(1, GetMsg(MVolumeName), True);
            SetInfoLine(1, PFarChar(FVolumeInfo.VolumeName), False);
            SetInfoLine(2, GetMsg(MStorageType), True);
            SetInfoLine(2, PFarChar(FVolumeInfo.StorageType), False);
            SetInfoLine(3, GetMsg(MAccess), True);
            SetInfoLine(3, PFarChar(FVolumeInfo.Access), False);
            SetInfoLine(4, GetMsg(MMaxCapacity), True);
            SetInfoLine(4, PFarChar(FVolumeInfo.MaxCapacity), False);
            SetInfoLine(5, GetMsg(MFreeSpace), True);
            SetInfoLine(5, PFarChar(FVolumeInfo.FreeSpace), False);
          end
          else
            Info.InfoLinesNumber := 0;
        end;
      InfoLines := FInfoLines;
    end;
  end;
end;

function TCanon.CountFiles(PanelItem: PPluginPanelItem; ItemsNumber, Move: Integer;
  var TotalFiles: Cardinal; var TotalFilesSize: Int64): Boolean;
  ////////////////////////////////////////////////////////
  procedure CountChildFiles(dirItem: EdsDirectoryItemRef);
  var
    i: Integer;
    count: EdsUInt32;
    childRef: EdsDirectoryItemRef;
    childInfo: EdsDirectoryItemInfo;
  begin
    CheckEdsError(EdsGetChildCount(dirItem, count));
    if count > 0 then
      for i := 0 to count - 1 do
      begin
        CheckEdsError(EdsGetChildAtIndex(dirItem, i, childRef));
        CheckEdsError(EdsGetDirectoryItemInfo(childRef, childInfo));
        try
          if childInfo.isFolder <> 0 then
            CountChildFiles(childRef)
          else
          begin
            Inc(TotalFiles);
            Inc(TotalFilesSize, childInfo.size);
          end;
        finally
          EdsRelease(childRef);
        end;
      end;
  end;
var
  i: Integer;
  SaveScreen: THandle;
  str: TFarString;
begin
  Result := True;
  TotalFiles := 0;
  TotalFilesSize := 0;
  SaveScreen := FARAPI.SaveScreen(0, 0, -1, -1);
  try
    try
      for i := 0 to ItemsNumber - 1 do
        with TPluginPanelItemArray(PanelItem)[i] do
        begin
          if FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
          begin
            if Move = 0 then
              str := GetMsgStr(MCopy)
            else
              str := GetMsgStr(MMove);
            str := str + #10 + GetMsgStr(MScanning) + #10 +
              Copy(FindData.cFileName + StrRepeat(' ', 50), 1, 50);
            FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE + FMSG_LEFTALIGN,
              nil, PPCharArray(@str[1]), 0, 0);
            CountChildFiles(PPanelUserData(UserData)^.BaseRef)
          end
          else
          begin
            Inc(TotalFiles);
{$IFDEF UNICODE}
            Inc(TotalFilesSize, FindData.nFileSize);
{$ELSE}
            Inc(TotalFilesSize, FindData.nFileSizeLow);
{$ENDIF}
          end;
        end;
    except
      Result := False;
    end;
  finally
    FARAPI.RestoreScreen(SaveScreen);
  end;
end;

function TCanon.GetFiles(PanelItem: PPluginPanelItem; ItemsNumber, Move: Integer;
  {$IFDEF UNICODE}var{$ENDIF} DestPath: PFarChar; OpMode: Integer): Integer;
const
  cCopyShowTotal = 'CopyShowTotal';
  cInterface = 'Interface';
var
  UserData: PPanelUserData;
  i: Integer;
  title: PFarChar;
  subtitle: TFarString;
  dirInfo: EdsDirectoryItemInfo;
  ProgressBar: TMultiProgressBar;
  Init: array[0..1] of TProgressInit;
  silent: Boolean;
  overall, skipall, overroall, skiproall, skipfile: Boolean;
  NewDestPath: array [0..MAX_PATH - 1] of TFarCHar;
  FInterruptTitle, FInterruptText: PFarChar;
begin
  Result := 0;
  if (ItemsNumber > 0) and
    (TPluginPanelItemArray(PanelItem)[0].UserData <> 0) then
  begin
    UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[0].UserData);
    if UserData^.BaseRefType = brtDirItem then
    try
      silent := OpMode and OPM_SILENT <> 0;
      title := nil;
      if not silent then
      begin
        if Move = 0 then
        begin
          title := GetMsg(MCopy);
          if ItemsNumber = 1 then
            subtitle := GetMsg(MCopyTo)
          else
            subtitle := GetMsg(MCopyItemsTo);
        end
        else
        begin
          title := GetMsg(MMove);
          if ItemsNumber = 1 then
            subtitle := GetMsg(MMoveTo)
          else
            subtitle := GetMsg(MMoveItemsTo);
        end;
        if ItemsNumber = 1 then
          subtitle := Format(subtitle,
            [TPluginPanelItemArray(PanelItem)[0].FindData.cFileName])
        else
          subtitle := Format(subtitle,
            [ItemsNumber, GetMsg(TLanguageID(Ord(MOneOk) + GetOk(ItemsNumber)))]);

        if FARAPI.InputBox(title, PFarChar(subtitle), 'Copy',{<-Системное имя истории копирования}
            DestPath, NewDestPath, MAX_PATH, nil,
            {$IFDEF UNICODE}FIB_EDITPATH or{$ENDIF} FIB_BUTTONS) = 0 then
          Exit;
      end
      else
{$IFDEF UNICODE}
        WStrLCopy(NewDestPath, DestPath, MAX_PATH);
{$ELSE}
        StrLCopy(NewDestPath, DestPath, MAX_PATH);
{$ENDIF}
      if not DirectoryExists(NewDestPath) and not ForceDirectories(NewDestPath) then
        raise Exception.CreateCustom(EDS_ERR_DIR_NOT_FOUND, '');
      ProgressBar := nil;
      if not silent then
      begin
        if FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_GETCONFIRMATIONS, nil) and
          FCS_INTERRUPTOPERATION <> 0 then
        begin
          FInterruptTitle := GetMsg(MInterruptTitle);
          FInterruptText := GetMsg(MInterruptText);
        end
        else
        begin
          FInterruptTitle := nil;
          FInterruptText := nil;
        end;
        Init[0].FMaxPos := 100;
        Init[0].FShowPs := True;
        Init[0].FLines := 4;
        if (ReadRegDWORDValue(cCopyShowTotal, FarRootKey + cDelim + cInterface,
            0) <> 0) and
          CountFiles(PanelItem, ItemsNumber, Move, FTotalFiles, FTotalFilesSize) then
        begin
          Init[1].FMaxPos := FTotalFilesSize;
          Init[1].FShowPs := True;
          Init[1].FLines := 1;
          FCurFile := 0;
          FCurTotalFilesSize := 0;
          ProgressBar := TMultiProgressBar.Create(title, Init, True,
            FInterruptTitle, FInterruptText, cSizeProgress, 2, -1, 2);
        end
        else
          ProgressBar := TMultiProgressBar.Create(title, Init, True,
            FInterruptTitle, FInterruptText, cSizeProgress, 1)
      end;
      try
        if Move <> 0 then
          overall := FARAPI.AdvControl(FARAPI.ModuleNumber,
            ACTL_GETCONFIRMATIONS, nil) and FCS_MOVEOVERWRITE = 0
        else
          overall := FARAPI.AdvControl(FARAPI.ModuleNumber,
            ACTL_GETCONFIRMATIONS, nil) and FCS_COPYOVERWRITE = 0;
{$IFDEF UNICODE}
        overroall := FARAPI.AdvControl(FARAPI.ModuleNumber,
            ACTL_GETCONFIRMATIONS, nil) and FCS_OVERWRITEDELETEROFILES = 0;
{$ELSE}
        overroall := False;
{$ENDIF}
        skipall := False;
        skiproall := False;
        for i := 0 to ItemsNumber - 1 do
        begin
          UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData);
          if UserData^.BaseRefType = brtDirItem then
          begin
            CheckEdsError(EdsGetDirectoryItemInfo(UserData^.BaseRef, dirInfo));
            skipfile := False;
            if dirInfo.isFolder = 0 then
              DownloadFile(UserData^.BaseRef, @dirInfo, NewDestPath,
                Move, silent, ProgressBar,
                TPluginPanelItemArray(PanelItem)[i].FindData.dwFileAttributes,
                overall, skipall, overroall, skiproall, skipfile)
            else
{$IFDEF UNICODE}
              RecursiveDownload(UserData^.BaseRef,
                AddEndSlash(NewDestPath) + CharToWideChar(dirInfo.szFileName),
                Move, silent, ProgressBar, overall, skipall, overroall, skiproall);
{$ELSE}
              RecursiveDownload(UserData^.BaseRef,
                AddEndSlash(NewDestPath) + dirInfo.szFileName,
                Move, silent, ProgressBar, overall, skipall, overroall, skiproall);
{$ENDIF}
            if not skipfile then
              TPluginPanelItemArray(PanelItem)[i].Flags :=
                TPluginPanelItemArray(PanelItem)[i].Flags and not PPIF_SELECTED;
          end;
        end;
      finally
        if Assigned(ProgressBar) then
          ProgressBar.Free;
      end;
      if OpMode = 0 then
        // Если возвращать 1 при копировании, то сбрасывается выделение с
        // пропущенных файлов
        Result := -1
      else
        Result := 1;
    except
      on E: Exception do
        if (E.Code = e_Custom) and (E.ErrorCode = EDS_ERR_OPERATION_CANCELLED) then
          Result := -1
        else
          raise;
    end;
  end;
end;

procedure TCanon.DownloadFile(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
  Silent: Boolean; ProgressBar: TMultiProgressBar; attrib: Cardinal;
  var overall, skipall, overroall, skiproall, skipfile: Boolean);
var
  stream: EdsStreamRef;
  image: EdsImageRef;
  localFileTime, filetime: TFileTime;
  hFile: THandle;

  dateTime: EdsTime;
  sysTime: TSystemTime;
  P: Pointer;
  ContextData: TContextData;
  FromName, ToName: TFarString;
  FromNameL, ToNameL: TFarString;
  attr: Cardinal;
begin
{$IFDEF UNICODE}
  FromName := CharToWideChar(dirInfo.szFileName);
  ToName := AddEndSlash(DestPath) + CharToWideChar(dirInfo^.szFileName);
{$ELSE}
  FromName := dirInfo.szFileName;
  ToName := AddEndSlash(DestPath) + dirInfo^.szFileName;
{$ENDIF}
  if not Silent and FileExists(ToName) then
  begin
    if skipall then
    begin
      skipfile := True;
      Exit;
    end
    else if not overall then
      with TOverDlg.Create(ToName, GetMsg(MFileAlreadyExists), dirItem, dirInfo) do
      try
        case Execute of
          //0: // Overwrite
          1: // All
            overall := True;
          2: // Skip
          begin
            skipfile := True;
            Exit;
          end;
          3: // Skip All
          begin
            skipall := True;
            skipfile := True;
            Exit;
          end;
          4: // Cancel
            raise Exception.CreateCustom(EDS_ERR_OPERATION_CANCELLED, '');
        end;
      finally
        Free;
      end;
{$IFDEF UNICODE}
    attr := GetFileAttributesW(PFarChar(ToName));
{$ELSE}
    attr := GetFileAttributesA(PFarChar(ToName));
{$ENDIF}
    if attr and FILE_ATTRIBUTE_READONLY <> 0 then
    begin
      if skiproall then
      begin
        skipfile := True;
        Exit;
      end
      else if not overroall then
        with TOverDlg.Create(ToName, GetMsg(MFileReadOnly), dirItem, dirInfo) do
        try
          case Execute of
            //0: // Overwrite
            1: // All
              overroall := True;
            2: // Skip
            begin
              skipfile := True;
              Exit;
            end;
            3: // Skip All
            begin
              skiproall := True;
              skipfile := True;
              Exit;
            end;
            4: // Cancel
              raise Exception.CreateCustom(EDS_ERR_OPERATION_CANCELLED, '');
          end;
        finally
          Free;
        end;
      attr := attr and not FILE_ATTRIBUTE_READONLY;
{$IFDEF UNICODE}
      SetFileAttributesW(PFarChar(ToName), attr);
{$ELSE}
      SetFileAttributesA(PFarChar(ToName), attr);
{$ENDIF}
    end;
  end;
{$IFDEF UNICODE}
  CheckEdsError(EdsCreateFileStreamEx(PFarChar(ToName),
    kEdsFileCreateDisposition_CreateAlways, kEdsAccess_ReadWrite, stream));
{$ELSE}
  CheckEdsError(EdsCreateFileStream(PFarChar(ToName),
    kEdsFileCreateDisposition_CreateAlways, kEdsAccess_ReadWrite, stream));
{$ENDIF}
  try
    try
      if not Silent then
      begin
        FromNameL := Copy(FromName, 1, Length(FromName));
        ToNameL := Copy(ToName, 1, Length(ToName));
        FSF.TruncPathStr(PFarChar(FromNameL), cSizeProgress);
        FSF.TruncPathStr(PFarChar(ToNameL), cSizeProgress);
        with ContextData do
        begin
          FProgressBar := ProgressBar;
          if Move <> 0 then
            FText := Format(GetMsg(MMoving), [FromNameL, ToNameL])
          else
            FText := Format(GetMsg(MCopying), [FromNameL, ToNameL]);
          if ProgressBar.ProgressCount = 1 then
            FTextAfter := ''
          else
          begin
            FFileSize := dirInfo^.size;
            FFilesSize := FCurTotalFilesSize;
            FText2 := #1 + ' ' +
              Format(GetMsg(MTotal), [Format3(FTotalFilesSize)]) + ' ';
            FTextAfter := #1#10 + ' ' +
              Format(GetMsg(MFilesProcessed), [FCurFile, FTotalFiles]) + ' ';
            Inc(FCurFile);
            Inc(FCurTotalFilesSize, FFileSize);
          end;
        end;
        CheckEdsError(EdsSetProgressCallback(stream, @EdsProgressCallback,
          kEdsProgressOption_Periodically, EdsUInt32(@ContextData)));
      end;
      CheckEdsError(EdsDownload(dirItem, dirInfo.size, stream));
      CheckEdsError(EdsDownloadComplete(dirItem));

      CheckEdsError(EdsCreateImageRef(stream, image));
      try
        P := @dateTime;
        CheckEdsError(EdsGetPropertyData(image, kEdsPropID_DateTime, 0,
          SizeOf(EdsTime), Pointer(P^)));
        sysTime.wYear := dateTime.year;
        sysTime.wMonth := dateTime.month;
        sysTime.wDay := dateTime.day;
        sysTime.wHour := dateTime.hour;
        sysTime.wMinute := dateTime.minute;
        sysTime.wSecond := dateTime.second;
        sysTime.wMilliseconds := dateTime.millseconds;

        SystemTimeToFileTime(sysTime, localFileTime);
        LocalFileTimeToFileTime(localFileTime, FileTime);
      finally
        EdsRelease(image);
      end;
    finally
      EdsRelease(stream);
    end;
  except
    on E: Exception do
    begin
      if (E.Code = e_Custom) and (E.ErrorCode = EDS_ERR_OPERATION_CANCELLED) and
          FileExists(ToName) then
{$IFDEF UNICODE}
        DeleteFileW(PFarChar(ToName));
{$ELSE}
        DeleteFileA(PFarChar(ToName));
{$ENDIF}
      raise;
    end;
  end;
{$IFDEF UNICODE}
  hFile := CreateFileW(PFarChar(ToName), GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
{$ELSE}
  hFile := CreateFileA(PFarChar(ToName), GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
{$ENDIF}
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    // Менять только время изменения
    SetFileTime(hFile, nil, nil, @filetime);
    CloseHandle(hFile);
  end;
{$IFDEF UNICODE}
  SetFileAttributesW(PFarChar(ToName), attrib);
{$ELSE}
  SetFileAttributesA(PFarChar(ToName), attrib);
{$ENDIF}
  if Move <> 0 then
    DeleteDirItem(dirItem, dirInfo);
end;

procedure TCanon.RecursiveDownload(dirItem: EdsDirectoryItemRef;
  const DestPath: TFarString; Move: Integer; Silent: Boolean;
  ProgressBar: TMultiProgressBar;
  var overall, skipall, overroall, skiproall: Boolean);
var
  count, i: EdsUInt32;
  childRef: EdsDirectoryItemRef;
  childInfo: EdsDirectoryItemInfo;
  skipfile: Boolean;
  fileAttr: EdsFileAttributes;
  dwFileAttributes: Cardinal;
begin
  if not DirectoryExists(DestPath) then
  begin
{$IFDEF UNICODE}
    if not CreateDirectoryW(PFarChar(DestPath), nil) then
{$ELSE}
    if not CreateDirectoryA(PFarChar(DestPath), nil) then
{$ENDIF}
      raise Exception.CreateCustom(EDS_ERR_DIR_NOT_FOUND, '');
  end;
  CheckEdsError(EdsGetChildCount(dirItem, count));
  if count > 0 then
    for i := 0 to count - 1 do
    begin
      CheckEdsError(EdsGetChildAtIndex(dirItem, i, childRef));
      CheckEdsError(EdsGetDirectoryItemInfo(childRef, childInfo));
      try
        if childInfo.isFolder <> 0 then
{$IFDEF UNICODE}
          RecursiveDownload(childRef,
            AddEndSlash(DestPath) + CharToWideChar(childInfo.szFileName),
            0, {Move,} silent, ProgressBar, overall, skipall, overroall, skiproall)
{$ELSE}
          RecursiveDownload(childRef,
            AddEndSlash(DestPath) + childInfo.szFileName,
            0, {Move,} silent, ProgressBar, overall, skipall, overroall, skiproall)
{$ENDIF}
        else
        begin
          if EdsGetAttribute(childRef, fileAttr) = EDS_ERR_OK then
          begin
            dwFileAttributes := 0;
            if Ord(fileAttr) and Ord(kEdsFileAttribute_Normal) <> 0 then
              dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_NORMAL;
            if Ord(fileAttr) and Ord(kEdsFileAttribute_ReadOnly) <> 0 then
              dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_READONLY;
            if Ord(fileAttr) and Ord(kEdsFileAttribute_Hidden) <> 0 then
              dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_HIDDEN;
            if Ord(fileAttr) and Ord(kEdsFileAttribute_System) <> 0 then
              dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_SYSTEM;
            if Ord(fileAttr) and Ord(kEdsFileAttribute_Archive) <> 0 then
              dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_ARCHIVE;
          end
          else
            dwFileAttributes := FILE_ATTRIBUTE_ARCHIVE;
          DownloadFile(childRef, @childInfo, DestPath,
            0, {Move,} silent, ProgressBar, dwFileAttributes,
            overall, skipall, overroall, skiproall, skipfile);
        end;
      finally
        EdsRelease(childRef);
      end;
    end;
  if Move <> 0 then
    DeleteDirItem(dirItem);
end;

procedure TCanon.DeleteDirItem(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo);
var
  skip: Boolean;
begin
  skip := True;
  DeleteDirItem(dirItem, dirInfo, OPM_SILENT, skip, skip);
end;

procedure TCanon.DeleteDirItem(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
  var skipall, delallfolder: Boolean);
var
  text: PFarChar;
  MessStr: TFarString;
  retry: Boolean;
  dirInfo_: EdsDirectoryItemInfo;
  count: EdsUInt32;
  FileName: TFarString;
begin
  if not Assigned(dirInfo) then
  begin
    CheckEdsError(EdsGetDirectoryItemInfo(dirItem, dirInfo_));
    dirInfo := @dirInfo_;
  end;
{$IFDEF UNICODE}
  FileName := CharToWideChar(dirInfo.szFileName);
{$ELSE}
  FileName := dirInfo.szFileName;
{$ENDIF}
  repeat
    retry := False;
    if (OpMode and OPM_SILENT = 0) and
      (dirInfo^.isFolder <> 0) and not delallfolder then
    begin
      CheckEdsError(EdsGetChildCount(dirItem, count));
      if count <> 0 then
      begin
        MessStr := GetMsgStr(MFolderDeleted) + #10 + FileName;
        case ShowMessage(GetMsg(MDeleteFolderTitle), PFarChar(MessStr),
            [GetMsg(MBtnDelete), GetMsg(MBtnAll), GetMsg(MBtnSkip),
              GetMsg(MBtnCancel)], FMSG_WARNING) of
          //0: ; // delete
          1: delallfolder := True; // all
          2: Exit;
          3: raise Exception.CreateCustom(EDS_ERR_OPERATION_CANCELLED, '');
        end;
      end;
    end;
    if EdsDeleteDirectoryItem(dirItem) = EDS_ERR_OK then
      FDirNode.DeleteItem(PFarChar(FileName))
    else
    begin
      if not skipall then
      begin
        if dirInfo^.isFolder <> 0 then
          text := GetMsg(MCannotDelFolder)
        else
          text := GetMsg(MCannotDelFile);
{$IFDEF UNICODE}
        MessStr := Format(text, [CharToWideChar(dirInfo^.szFileName)]);
{$ELSE}
        MessStr := Format(text, [dirInfo^.szFileName]);
{$ENDIF}
        case ShowMessage(GetMsg(MError), PFarChar(MessStr),
            [GetMsg(MBtnRetry), GetMsg(MBtnSkip), GetMsg(MBtnSkipAll),
              GetMsg(MBtnCancel)],
            FMSG_WARNING) of
          0: // Retry
            retry := True;
          // 1: // Skip
          2: // SkipAll
            skipall := True;
          3: // Cancel
            raise Exception.CreateCustom(EDS_ERR_OPERATION_CANCELLED, '');
        end;
      end;
    end;
  until not retry;
end;

function TCanon.GetFindData(var PanelItem: PPluginPanelItem;
  var ItemsNumber: Integer; OpMode: Integer): Integer;
begin
  if not Assigned(FDirNode) then
    try
      FDirNode := TCanonDirNode.Create;
      FDirNode.OnBeforeChangeDir := OnBeforeChangeDirEvent;
      FDirNode.OnChangeDir := OnChangeDirEvent;
      FDirNode.FillPanelItem;
    except
      raise;
    end
  else if RereadFindData then
  begin
    RereadFindData := False;
    FDirNode.FreeSubDir;
    FDirNode.ClearItems;
    FDirNode.FillPanelItem;
    OnChangeDirEvent(FDirNode);
  end;
  PanelItem := FDirNode.PanelItem;
  ItemsNumber := FDirNode.ItemsNumber;
  Result := 1;
end;

type
  TFormatFunction = function(const Value): TFarString;

function FormatBodyId(const Value): TFarString;
begin
{$IFDEF UNICODE}
  Result := Format('%u', [Str2Int(CharToWideChar(PAnsiChar(@Value)))]);
{$ELSE}
  Result := Format('%u', [Str2Int(PAnsiChar(@Value))]);
{$ENDIF}
end;

function FormatBatteryLevel(const Value): TFarString;
begin
  if EdsUInt32(Value) = $ffffffff then
    Result := GetMsgStr(MACPower)
  else
    Result := Format('%d%%', [EdsUInt32(Value)]);
end;

function FormatBatteryQuality(const Value): TFarString;
begin
  case EdsUInt32(Value) of
    3: Result := GetMsgStr(MNoDegradation);
    2: Result := GetMsgStr(MSlightDegradation);
    1: Result := GetMsgStr(MDegradedHalf);
    0: Result := GetMsgStr(MDegradedLow);
    else
      Result := '';
  end;
end;

function TCanon.SetDirectory(const Dir: PFarChar; OpMode: Integer): Integer;
var
  NewDirNode: TDirNode;
  PanelInfo: TPanelInfo;
begin
  Result := 0;
  if Assigned(FDirNode) and
    // Для OPM_FIND or OPM_SILENT отрабатывать из корневого каталога
    ((OpMode and (OPM_FIND or OPM_SILENT) = 0) or not FDirNode.IsRoot) then
  begin
    NewDirNode := FDirNode.ChDir(Dir);
    if Assigned(NewDirNode) then
    begin
      FDirNode := NewDirNode;
      FCurDirectory := FDirNode.FullDirName;
      Result := 1;
    end;
  end;
  if OpMode and (OPM_FIND or OPM_SILENT) = 0 then
    if Result <> 0 then
    begin
{$IFDEF UNICODE}
      FARAPI.Control(PANEL_PASSIVE, FCTL_GETPANELINFO, 0, @PanelInfo);
      if PanelInfo.PanelType = PTYPE_INFOPANEL then
        FARAPI.Control(PANEL_PASSIVE, FCTL_UPDATEPANEL, 0, nil);
{$ELSE}
      FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_GETANOTHERPANELINFO, @PanelInfo);
      if PanelInfo.PanelType = PTYPE_INFOPANEL then
        FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_UPDATEANOTHERPANEL, nil);
{$ENDIF}
    end
    else
      ShowMessage(GetMsg(MError), GetMsg(MPathNotFound), FMSG_WARNING + FMSG_MB_OK);
end;

procedure TCanon.SetInfoLinesCount(Value: Integer);
begin
  if Value > FInfoLineCount then
  begin
    if FInfoLineCount > 0 then
      FreeMem(FInfoLines);
    GetMem(FInfoLines, Value * SizeOf(TInfoPanelLine));
  end;
  ZeroMemory(FInfoLines, Value * SizeOf(TInfoPanelLine));
  FInfoLineCount := Value;
end;

var
  _RefCount, _SessionRefCount: Integer;
  IsConnect: Boolean;
  CurrentSession: EdsBaseRef;

class procedure TCanon.LoadLib(const FileName: TFarString);
begin
  if not IsConnect then
  begin
{$IFDEF USE_DYNLOAD}
    if not InitEDSDK(PFarChar(FileName)) then
      raise Exception.CreateCustom(EDS_ERR_OK,
        GetMsgStr(MInitError) + #10 + GetMsg(MLibNotFound));
{$ENDIF}
    CheckEdsError(EdsInitializeSDK);
    IsConnect := True;
  end;
  Inc(_RefCount);
end;

class procedure TCanon.FreeLib;
begin
  if _RefCount > 0 then
    Dec(_RefCount);
  if (_RefCount = 0) and IsConnect then
  begin
    EdsTerminateSDK;
{$IFDEF USE_DYNLOAD}
    FreeEDSDK;
{$ENDIF}
    IsConnect := False;
  end;
end;

class procedure TCanon.CloseSession;
begin
  if Assigned(CurrentSession) then
  begin
    if _SessionRefCount > 0 then
      Dec(_SessionRefCount);
    if _SessionRefCount = 0 then
    begin
      EdsCloseSession(CurrentSession);
      CurrentSession := nil;
    end;
  end;
end;

class procedure TCanon.OpenSession(session: EdsBaseRef; Sender: TCanon);
begin
  if Assigned(CurrentSession) then
  begin
    if CurrentSession = session then
      Inc(_SessionRefCount)
    else
      raise Exception.CreateCustom(EDS_ERR_OK, GetMsgStr(MOneSessionAllowed));
  end
  else
  begin
    CheckEdsError(EdsOpenSession(session));
    CurrentSession := session;
    {EdsSetCameraStateEventHandler(session, kEdsStateEvent_All,
      @EdsStateEventHandler, EdsUInt32(Sender));}
    {EdsSetCameraStateEventHandler(session, kEdsStateEvent_ShutDown,
      @EdsStateEventHandler, EdsUInt32(Sender));}
    Inc(_SessionRefCount);
  end;
end;

class function TCanon.GetCurrentSession: EdsBaseRef;
begin
  Result := CurrentSession;
end;

procedure TCanon.OnCameraDisconnect;
begin
  //
end;

procedure TCanon.OnBeforeChangeDirEvent(ADirNode: TDirNode;
  var Allow: Boolean);
begin
  if ADirNode.UserData <> 0 then
    with PPanelUserData(ADirNode.UserData)^ do
    begin
      case BaseRefType of
        brtCamera:
          if GetCurrentSession <> BaseRef then
          begin
            CloseSession;
            OpenSession(BaseRef, Self);
          end;
      end;
    end
  else if ADirNode.IsRoot then
    CloseSession;
end;

procedure TCanon.OnChangeDirEvent(ADirNode: TDirNode);
  function GetProperty(camera: EdsCameraRef; PropertyId: EdsPropertyID;
    ff: TFormatFunction = nil): TFarString;
  const
    cDateTimeFmt = '%02d.%02d.%04d %02d:%02d:%02d';
  var
    str: array[0..63] of EdsChar;
    data: EdsUInt32;
    datetime: EdsTime;
    p: Pointer;
    datatype, size: EdsUInt32;
  begin
    Result := '';
    if EdsGetPropertySize(camera, PropertyId, 0, datatype, size) = EDS_ERR_OK then
    try
      if EdsEnumDataType(datatype) = kEdsDataType_String then
      begin
        p := @str;
        CheckEdsError(
          EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)));
        if Assigned(ff) then
          Result := ff(str)
        else
{$IFDEF UNICODE}
          Result := CharToWideChar(str);
{$ELSE}
          Result := str;
{$ENDIF}
      end
      else if EdsEnumDataType(datatype) = kEdsDataType_Time then
      begin
        P := @datetime;
        CheckEdsError(
          EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)));
        if Assigned(ff) then
          Result := ff(datetime)
        else
          Result := Format(cDateTimeFmt, [
            datetime.day, datetime.month, datetime.year,
            datetime.hour, datetime.minute, datetime.second]);
      end
      else if EdsEnumDataType(datatype) in [kEdsDataType_Int32] then
      begin
        p := @data;
        CheckEdsError(
          EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)));
        if Assigned(ff) then
          Result := ff(data)
        else
          Result := Format('%d', [data]);
      end
      else if EdsEnumDataType(datatype) in [kEdsDataType_UInt32] then
      begin
        p := @data;
        CheckEdsError(EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)));
        if Assigned(ff) then
          Result := ff(data)
        else
          Result := Format('%u', [data]);
      end;
    except
      Result := GetMsgStr(MPropertyUnavailable);
    end
    else
      Result := GetMsgStr(MPropertyUnavailable);
  end;
var
  volumeInfo: EdsVolumeInfo;
begin
  if ADirNode.UserData <> 0 then
  begin
    with PPanelUserData(ADirNode.UserData)^ do
      case BaseRefType of
        brtCamera:
        with FCameraInfo do
        begin
          CameraName := ADirNode.DirName;
          BodyID := GetProperty(BaseRef, kEdsPropID_BodyIdEx,
            FormatBodyId);
          FirmwareVersion := GetProperty(BaseRef, kEdsPropID_FirmwareVersion);
          DateTime := GetProperty(BaseRef, kEdsPropID_DateTime);
          BatteryLevel := GetProperty(BaseRef,
            kEdsPropID_BatteryLevel, @FormatBatteryLevel);
          BatteryQuality := GetProperty(BaseRef,
            kEdsPropID_BatteryQuality, @FormatBatteryQuality);
        end;
        brtVolume:
        with FVolumeInfo do
        begin
          if EdsGetVolumeInfo(BaseRef, volumeInfo) = EDS_ERR_OK then
          begin
            VolumeName := ADirNode.DirName;
            case volumeInfo.storageType of
              0: StorageType := GetMsgStr(MNoCard);
              1: StorageType := GetMsgStr(M_CF);
              2: StorageType := GetMsgStr(M_SD);
              else StorageType := '';
            end;
            case volumeInfo.access of
              0: Access := GetMsgStr(MReadOnly);
              1: Access := GetMsgStr(MWriteOnly);
              2: Access := GetMsgStr(MReadWrite);
              $FFFFFFFF: Access := GetMsgStr(MAccessError);
              else Access := '';
            end;
            MaxCapacity := FormatFileSize(volumeInfo.maxCapacity);
            FreeSpace := FormatFileSize(volumeInfo.freeSpaceInBytes);
          end
          else
          begin
            VolumeName := '';
            StorageType := '';
            Access := '';
            MaxCapacity := '';
            FreeSpace := '';
          end;
        end;
      end;
  end;
end;

{ TCanonDirNode }

constructor TCanonDirNode.Create;
begin
  inherited;
end;

procedure TCanonDirNode.FillPanelItem;
begin
  if IsRoot then
    GetCameraInfo
  else if Depth = 1 then
    GetVolumeInfo
  else
    GetDirectoryInfo(True);
end;

procedure TCanonDirNode.FreeUserData(UserData: Pointer);
begin
  if Assigned(UserData) then
    FreeMem(UserData);
end;

procedure TCanonDirNode.GetCameraInfo;
var
  cameraList: EdsCameraListRef;
  deviceInfo: EdsDeviceInfo;
  camera: EdsCameraRef;
  count: EdsUInt32;
  i: Integer;
  PanelUserData: PPanelUserData;
begin
  cameraList := nil;
  count := 0;
  { get list of camera }
  CheckEdsError(EdsGetCameraList(cameraList));
  { get number of camera }
  CheckEdsError(EdsGetChildCount(cameraList, count));
  if count > 0 then
  begin
    ItemsNumber := count;
    try
      for i := 0 to count - 1 do
      begin
        camera := nil;
        CheckEdsError(EdsGetChildAtIndex(cameraList, i, camera));
        CheckEdsError(EdsGetDeviceInfo(camera, deviceInfo));
        with TPluginPanelItemArray(PanelItem)[i] do
        begin
          SetFindDataName(FindData, deviceInfo.szDeviceDescription);
          FindData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY;
          GetMem(PanelUserData, SizeOf(TPanelUserData));
          PanelUserData^.BaseRef := camera;
          PanelUserData^.BaseRefType := brtCamera;
          UserData := DWORD_PTR(PanelUserData);
        end;
      end;
    except
      ClearItems;
      raise;
    end;
  end
end;

procedure TCanonDirNode.GetDirectoryInfo(getDateTime: Boolean);
var
  dirItem, dirItem1: EdsDirectoryItemRef;
  dirItemInfo: EdsDirectoryItemInfo;

  fileAttr: EdsFileAttributes;

  count: EdsUInt32;

  stream: EdsStreamRef;

  ProgressBar: TProgressBar;
  i: Integer;
  PanelUserData: PPanelUserData;
  FInterruptTitle, FInterruptText: PFarChar;
  ParentData: PPanelUserData;
begin
  stream := nil;
  ParentData := PPanelUserData(UserData);
  CheckEdsError(EdsGetChildCount(ParentData^.BaseRef, count));
  if count > 0 then
  begin
    ItemsNumber := count;
    try
      if getDateTime and (count > 10) then
      begin
        if FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_GETCONFIRMATIONS, nil) and
          FCS_INTERRUPTOPERATION <> 0 then
        begin
          FInterruptTitle := GetMsg(MInterruptTitle);
          FInterruptText := GetMsg(MInterruptText);
        end
        else
        begin
          FInterruptTitle := nil;
          FInterruptText := nil;
        end;
        ProgressBar := TProgressBar.Create(GetMsg(MReading), True, count, 0,
          True, 0, FInterruptTitle, FInterruptText)
      end
      else
        ProgressBar := nil;
      try
        for i := 0 to count - 1 do
        begin
          CheckEdsError(EdsGetChildAtIndex(ParentData^.BaseRef, i, dirItem));
          CheckEdsError(EdsGetDirectoryItemInfo(dirItem, dirItemInfo));
          with TPluginPanelItemArray(PanelItem)[i] do
          begin
            SetFindDataName(FindData, dirItemInfo.szFileName);
            if dirItemInfo.isFolder <> 0 then
              FindData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY
            else
            begin
{$IFDEF UNICODE}
              FindData.nFileSize := dirItemInfo.size;
{$ELSE}
              // FindData.nFileSizeHigh := 0;
              FindData.nFileSizeLow := dirItemInfo.size;
{$ENDIF}
              if getDateTime then
              begin
                if Assigned(stream) then
                  CheckEdsError(EdsSeek(stream, 0, kEdsSeek_Begin))
                else
                  CheckEdsError(EdsCreateMemoryStream(0, stream));
                GetImageDate(stream, dirItem, FindData.ftCreationTime);
                FindData.ftLastAccessTime := FindData.ftCreationTime;
                FindData.ftLastWriteTime := FindData.ftCreationTime;
              end;
              dirItem1 := dirItem;
              // Почему то портится содержимое 1-го параметра
              CheckEdsError(EdsGetAttribute(dirItem1, fileAttr));
              with FindData do
              begin
                if Ord(fileAttr) and Ord(kEdsFileAttribute_Normal) <> 0 then
                  dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_NORMAL;
                if Ord(fileAttr) and Ord(kEdsFileAttribute_ReadOnly) <> 0 then
                  dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_READONLY;
                if Ord(fileAttr) and Ord(kEdsFileAttribute_Hidden) <> 0 then
                  dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_HIDDEN;
                if Ord(fileAttr) and Ord(kEdsFileAttribute_System) <> 0 then
                  dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_SYSTEM;
                if Ord(fileAttr) and Ord(kEdsFileAttribute_Archive) <> 0 then
                  dwFileAttributes := dwFileAttributes or FILE_ATTRIBUTE_ARCHIVE;
              end;
            end;
            GetMem(PanelUserData, SizeOf(TPanelUserData));
            PanelUserData^.BaseRef := dirItem;
            PanelUserData^.BaseRefType := brtDirItem;
            UserData := DWORD_PTR(PanelUserData);
          end;
          if Assigned(ProgressBar) and not ProgressBar.UpdateProgress(i + 1) then
            Break;
        end;
      finally
        if Assigned(stream) then
          EdsRelease(stream);
        if Assigned(ProgressBar) then
          ProgressBar.Free;
      end;
    except
      ClearItems;
      raise;
    end;
  end;
end;

procedure TCanonDirNode.GetVolumeInfo;
var
  volume: EdsVolumeRef;
  volumeInfo: EdsVolumeInfo;
  count: EdsUInt32;
  i: Integer;
  PanelUserData: PPanelUserData;
  ParentData: PPanelUserData;
begin
  ParentData := PPanelUserData(UserData);
  CheckEdsError(EdsGetChildCount(ParentData^.BaseRef, count));
  if count > 0 then
  begin
    ItemsNumber := count;
    try
      for i := 0 to count - 1 do
      begin
        volume := nil;
        CheckEdsError(EdsGetChildAtIndex(ParentData^.BaseRef, i, volume));
        CheckEdsError(EdsGetVolumeInfo(volume, volumeInfo));
        with TPluginPanelItemArray(PanelItem)[i] do
        begin
          SetFindDataName(FindData, volumeInfo.szVolumeLabel);
          FindData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY;
          GetMem(PanelUserData, SizeOf(TPanelUserData));
          PanelUserData^.BaseRef := volume;
          PanelUserData^.BaseRefType := brtVolume;
          UserData := DWORD_PTR(PanelUserData);
        end;
      end;
    except
      ClearItems;
      raise;
    end;
  end;
end;

initialization

  _RefCount := 0;
  IsConnect := False;
  _SessionRefCount := 0;
  CurrentSession := nil;

end.
