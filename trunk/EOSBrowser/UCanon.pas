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
  UFileSystem,
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

    FPanelModesArray: array[0..9] of TPanelMode;
    FColumnTitles: array[0..0] of PFarChar;

    FDirNode: TDirNode;

    FCameraInfo: TCameraInfo;
    FVolumeInfo: TVolumeInfo;
  private
    class procedure LoadLib(const FileName: TFarString);
    class procedure FreeLib;
    class procedure OpenSession(session: EdsBaseRef; Sender: TCanon);
    class procedure CloseSession;
    class function GetCurrentSession: EdsBaseRef;

    procedure RecursiveDownload(dirItem: EdsDirectoryItemRef;
      const DestPath: TFarString; Move: Integer; Silent: Boolean;
      ProgressBar: TProgressBar;
      var overall, skipall, overroall, skiproall: Boolean);
    procedure DownloadFile(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
      Silent: Boolean; ProgressBar: TProgressBar; attrib: Cardinal;
      var overall, skipall, overroall, skiproall, skipfile: Boolean);
    procedure DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
      var skipall, delallfolder: Boolean); overload;
    procedure DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo = nil); overload;
    procedure SetInfoLinesCount(Value: Integer);
    procedure OnCameraDisconnect;
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

    property CurDirectory: TFarString read FCurDirectory;
  end;

procedure GetImageDate(stream: EdsStreamRef; dirItem: EdsDirectoryItemRef;
  var FileTime: TFileTime); overload;
procedure GetImageDate(dirItem: EdsDirectoryItemRef;
  var FileFime: TFileTime); overload;

procedure CheckEdsError(edserr: EdsError);

implementation

uses UDialogs;

{ TFindDataItem }

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
    FProgressBar: TProgressBar;
    FText: TFarString;
  end;

function EdsProgressCallback(inPercent: EdsUInt32; inContext: Pointer;
  var outCancel: EdsBool): EdsError; stdcall;
begin
  with PContextData(inContext)^ do
    if not FProgressBar.UpdateProgress(inPercent, FText) then
      Result := EDS_ERR_OPERATION_CANCELLED
    else
      Result := EDS_ERR_OK;
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
var
  i: Integer;
begin
  inherited Create;
  LoadLib(FileName);
  for i := 0 to 9 do
  with FPanelModesArray[i] do
  begin
    ColumnTypes := 'N';
    ColumnWidths := '0';
  end;
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
var
  i: Integer;
  SetTitles: Boolean;
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
      begin
        FColumnTitles[0] := GetMsg(MCameraName);
        SetTitles := True;
      end
      else if Assigned(FDirNode.Parent) and (FDirNode.Parent.IsRoot) then
      begin
        FColumnTitles[0] := GetMsg(MVolumeName);
        SetTitles := True;
      end
      else
        SetTitles := False;
      if SetTitles then
      begin
        for i := 0 to 9 do
          FPanelModesArray[i].ColumnTitles := @FColumnTitles;
        PanelModesArray := @FPanelModesArray;
        PanelModesNumber := 10;
      end
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

function TCanon.GetFiles(PanelItem: PPluginPanelItem; ItemsNumber, Move: Integer;
  {$IFDEF UNICODE}var{$ENDIF} DestPath: PFarChar; OpMode: Integer): Integer;
var
  UserData: PPanelUserData;
  i: Integer;
  title: PFarChar;
  subtitle: TFarString;
  dirInfo: EdsDirectoryItemInfo;
  ProgressBar: TProgressBar;
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
        ProgressBar := TProgressBar.Create(title, 100, True,
          FInterruptTitle, FInterruptText, cSizeProgress, True, 4)
      end
      else
        ProgressBar := nil;
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
  Silent: Boolean; ProgressBar: TProgressBar; attrib: Cardinal;
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
        with ContextData do
        begin
          FromNameL := Copy(FromName, 1, Length(FromName));
          ToNameL := Copy(ToName, 1, Length(ToName));
          FSF.TruncPathStr(PFarChar(FromNameL), cSizeProgress);
          FSF.TruncPathStr(PFarChar(ToNameL), cSizeProgress);
          if Move <> 0 then
            FText := Format(GetMsg(MMoving), [FromNameL, ToNameL])
          else
            FText := Format(GetMsg(MCopying), [FromNameL, ToNameL]);
          FProgressBar := ProgressBar;
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
  ProgressBar: TProgressBar;
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
    FDirNode.FillPanelItem;
  except
    raise;
  end;
  PanelItem := FDirNode.PanelItem;
  ItemsNumber := FDirNode.ItemsNumber;
  Result := 1;

  {if Length(FFindDataItemArray) = 0 then
  begin
    SetLength(FFindDataItemArray, 1);
    FCurFindDataItem := 0;
    FFindDataItemArray[FCurFindDataItem] := TFindDataItem.Create;
    try
      GetCameraInfo(FFindDataItemArray[FCurFindDataItem]);
    except
      FFindDataItemArray[FCurFindDataItem].Free;
      SetLength(FFindDataItemArray, 0);
      raise;
    end;
  end;
  if (FCurFindDataItem >= 0) and
    (FCurFindDataItem < Length(FFindDataItemArray)) then
  begin
    PanelItem := FFindDataItemArray[FCurFindDataItem].PanelItem;
    ItemsNumber := FFindDataItemArray[FCurFindDataItem].ItemsNumber;
    Result := 1;
  end;}
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
  NewDirNode: TDirNode;
begin
  Result := 0;
  if Assigned(FDirNode) then
  begin
    NewDirNode := FDirNode.ChDir(Dir);
    if Assigned(NewDirNode) then
    begin
      FDirNode := NewDirNode;
      FCurDirectory := FDirNode.FullDirName;
      Result := 1;
    end;
  end;
end;
(*  function ChDirDown(NewDir: PFarChar; var NewFindDataItem: Integer;
    var NewDirectory: TFarString): Boolean;
  var
    i, CurFindDataItem: Integer;
    UserData: PPanelUserData;
    volumeInfo: EdsVolumeInfo;
  begin
    Result := False;
    UserData := nil;
    with FFindDataItemArray[NewFindDataItem] do
      if ItemsNumber > 0 then
      begin
        for i := 0 to ItemsNumber - 1 do
          if FSF.LStricmp(TPluginPanelItemArray(PanelItem)[i].FindData.cFileName,
            NewDir) = 0 then
          begin
            NewDir := TPluginPanelItemArray(PanelItem)[i].FindData.cFileName;
            UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData);
            Break;
          end;
      end;
    if Assigned(UserData) then
    begin
      for i := NewFindDataItem + 1 to Length(FFindDataItemArray) - 1 do
        if UserData^.BaseRef = FFindDataItemArray[i].ParentData^.BaseRef then
        begin
          NewFindDataItem := i;
          Result := True;
          Break;
        end;
      if not Result then
      begin
        CurFindDataItem := Length(FFindDataItemArray);
        SetLength(FFindDataItemArray, CurFindDataItem + 1);
        FFindDataItemArray[CurFindDataItem] := TFindDataItem.Create;
        try
          case UserData^.BaseRefType of
            brtCamera:
            begin
              if GetCurrentSession <> UserData^.BaseRef then
              begin
                CloseSession;
                OpenSession(UserData^.BaseRef, Self);
                with FCameraInfo do
                begin
                  CameraName := NewDir;
                  BodyID := GetProperty(UserData^.BaseRef, kEdsPropID_BodyIdEx,
                    FormatBodyId);
                  FirmwareVersion := GetProperty(UserData^.BaseRef, kEdsPropID_FirmwareVersion);
                  DateTime := GetProperty(UserData^.BaseRef, kEdsPropID_DateTime);
                  BatteryLevel := GetProperty(UserData^.BaseRef,
                    kEdsPropID_BatteryLevel, @FormatBatteryLevel);
                  BatteryQuality := GetProperty(UserData^.BaseRef,
                    kEdsPropID_BatteryQuality, @FormatBatteryQuality);
                end;
              end;
              GetVolumeInfo(UserData, FFindDataItemArray[CurFindDataItem]);
            end;
            brtVolume:
            with FVolumeInfo do
            begin
              if EdsGetVolumeInfo(UserData^.BaseRef, volumeInfo) = EDS_ERR_OK then
              begin
                VolumeName := NewDir;
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
              GetDirectoryInfo(UserData, FFindDataItemArray[CurFindDataItem], True);
            end;
            brtDirItem:
              GetDirectoryInfo(UserData, FFindDataItemArray[CurFindDataItem], True);
          end;
          NewFindDataItem := CurFindDataItem;
          Result := True;
        except
          FFindDataItemArray[CurFindDataItem].Free;
          SetLength(FFindDataItemArray, CurFindDataItem);
          raise;
        end;
      end;
      if Result then
      begin
        if NewDirectory <> '' then
          NewDirectory := NewDirectory + cDelim;
        NewDirectory := NewDirectory + NewDir;
      end;
    end;
  end;
  function ChDirUp(var NewFindDataItem: Integer;
    var NewDirectory: TFarString): Boolean;
  var
    UserData: PPanelUserData;
    i, j: Integer;
  begin
    Result := False;
    UserData := FFindDataItemArray[NewFindDataItem].ParentData;
    for i := NewFindDataItem - 1 downto 0 do
      with FFindDataItemArray[i] do
      begin
        for j := 0 to ItemsNumber - 1 do
        begin
          if UserData^.BaseRef =
            PPanelUserData(TPluginPanelItemArray(PanelItem)[j].UserData)^.BaseRef then
          begin
            NewFindDataItem := i;
            Result := True;
            Break;
          end;
        end;
        if Result then
        begin
          j := DelimiterLast(NewDirectory, cDelim);
          if (j > 0) and (j < Length(NewDirectory)) then
            NewDirectory := Copy(NewDirectory, 1, j - 1)
          else
          begin
            NewDirectory := '';
            for j := Length(FFindDataItemArray) - 1 to 1 do
              FFindDataItemArray[j].Free;
            SetLength(FFindDataItemArray, 1);
            CloseSession;
          end;
          Break;
        end;
      end;
  end;
const
  cUpDir = '..';
var
  p, p1: Integer;
  NewDirectory, CurDir: TFarString;
  err_ok: Boolean;
  CurFindDataItem: Integer;
  PanelInfo: TPanelInfo;
begin
  Result := 0;
  if Dir = cDelim then
  begin
    if FCurFindDataItem <> 0 then
    begin
      FCurFindDataItem := 0;
      FCurDirectory := '';
    end;
    Result := 1;
  end
  else if (FCurFindDataItem >= 0) and
    (FCurFindDataItem < Length(FFindDataItemArray)) then
  begin
    if Dir = cUpDir then
    begin
      if ChDirUp(FCurFindDataItem, FCurDirectory) then
        Result := 1;
    end
    else
    begin
      if Pos(cDelim, Dir) = 0 then
      begin
        if ChDirDown(Dir, FCurFindDataItem, FCurDirectory) then
          Result := 1;
      end
      else
      begin
        if Dir[0] = cDelim then
        begin
          NewDirectory := '';
          CurFindDataItem := 0;
          p1 := 2;
        end
        else
        begin
          p1 := 1;
          NewDirectory := FCurDirectory;
          CurFindDataItem := FCurFindDataItem;
        end;
        p := PosEx(cDelim, Dir, p1);
        err_ok := True;
        while err_ok and (p > 0) do
        begin
          CurDir := Copy(Dir, p1, p - p1);
          if CurDir = cUpDir then
            err_ok := ChDirUp(CurFindDataItem, NewDirectory)
          else if CurDir <> '' then
            err_ok := ChDirDown(PFarChar(CurDir), CurFindDataItem, NewDirectory);
          p1 := p + 1;
          p := PosEx(cDelim, Dir, p1);
        end;
        if err_ok then
        begin
          CurDir := Copy(Dir, p1, Length(Dir) - p1 + 1);
          if CurDir = cUpDir then
            err_ok := ChDirUp(CurFindDataItem, NewDirectory)
          else if CurDir <> '' then
            err_ok := ChDirDown(PFarChar(CurDir), CurFindDataItem, NewDirectory);
        end;
        if err_ok then
        begin
          FCurDirectory := NewDirectory;
          FCurFindDataItem := CurFindDataItem;
          Result := 1;
        end;
      end;
    end;
  end;
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
  else if OpMode and (OPM_FIND or OPM_SILENT) = 0 then
    ShowMessage(GetMsg(MError), GetMsg(MPathNotFound), FMSG_WARNING + FMSG_MB_OK);
end;*)

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
      @EdsStateEventHandler, Cardinal(Sender));}
    EdsSetCameraStateEventHandler(session, kEdsStateEvent_ShutDown,
      @EdsStateEventHandler, Cardinal(Sender));
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
          UserData := Cardinal(PanelUserData);
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
        ProgressBar := TProgressBar.Create(GetMsg(MReading), count, True,
          FInterruptTitle, FInterruptText)
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
            UserData := Cardinal(PanelUserData);
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
          UserData := Cardinal(PanelUserData);
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
