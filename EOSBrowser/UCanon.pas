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
  UEDialogs;

type
  TBaseRefType = (brtCamera, brtVolume, brtDirItem);

  PPanelUserData = ^TPanelUserData;
  TPanelUserData = record
    BaseRef: EdsBaseRef;
    BaseRefType: TBaseRefType;
  end;

  TFindDataItem = class
    ParentData: PPanelUserData;
    PanelItem: PPluginPanelItem;
    ItemsNumber: Integer;
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
    StorageType: TFarString; // 0 = no card,    1 = CD,    2 = SD
    Access: TFarString; // 0 = Read only   1 = Write only   2 Read/Write
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

    FFindDataItem: array of TFindDataItem;
    FCurFindDataItem: Integer;

    FCurrentSession: EdsBaseRef;

    FCameraInfo: TCameraInfo;
    FVolumeInfo: TVolumeInfo;

  private
    class procedure LoadLib(const FileName: TFarString);
    class procedure FreeLib;
    class function OpenSession(session: EdsBaseRef): Boolean;
    class procedure CloseSession;

    procedure SetFindDataName(var FindData: TFarFindData; FileName: PAnsiChar);

    function RecursiveDownload(dirItem: EdsDirectoryItemRef;
      const DestPath: TFarString; Move: Integer; Silent: Boolean;
      ProgressBar: TProgressBar;
      var overall, skipall, overroall, skiproall: Boolean): EdsError;
    function DownloadFile(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
      Silent: Boolean; ProgressBar: TProgressBar; attrib: Cardinal;
      var overall, skipall, overroall, skiproall, skipfile: Boolean): EdsError;
    function DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
      var skipall, delallfolder, skipfile: Boolean): EdsError; overload;
    function DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo = nil): EdsError; overload;
    function GetCameraInfo(var FindDataItem: TFindDataItem): Boolean;
    function GetVolumeInfo(aParentData: PPanelUserData;
      var FindDataItem: TFindDataItem): Boolean;
    function GetDirectoryInfo(aParentData: PPanelUserData;
      var FindDataItem: TFindDataItem; getDateTime: Boolean): Boolean;
    procedure FreeFindDataItem(FindDataItem: TFindDataItem);
    procedure SetInfoLinesCount(Value: Integer);
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

function GetImageDate(stream: EdsStreamRef; dirItem: EdsDirectoryItemRef;
  var FileTime: TFileTime): EdsError; overload;
function GetImageDate(dirItem: EdsDirectoryItemRef;
  var FileFime: TFileTime): EdsError; overload;

implementation

uses UDialogs;

{ TCanon }

function GetImageDate(stream: EdsStreamRef;
  dirItem: EdsDirectoryItemRef; var FileTime: TFileTime): EdsError;
var
  image: EdsImageRef;
  sysTime: TSystemTime;
  dateTime: EdsTime;
  localFileTime: TFileTime;
  P: Pointer;
begin
  // Получение информации о дате/времени
  Result := EdsDownloadThumbnail(dirItem, stream);
  if Result = EDS_ERR_OK then
  begin
    Result := EdsCreateImageRef(stream, image);
    if Result = EDS_ERR_OK then
    begin
      P := @dateTime;
      Result := EdsGetPropertyData(image,
        kEdsPropID_DateTime, 0, SizeOf(EdsTime),
        Pointer(P^));
      if Result = EDS_ERR_OK then
      begin
        sysTime.wYear := dateTime.year;
        sysTime.wMonth := dateTime.month;
        sysTime.wDay := dateTime.day;
        sysTime.wHour := dateTime.hour;
        sysTime.wMinute := dateTime.minute;
        sysTime.wSecond := dateTime.second;
        sysTime.wMilliseconds := dateTime.millseconds;

        SystemTimeToFileTime(sysTime, localFileTime);
        LocalFileTimeToFileTime(localFileTime, FileTime);
      end;
      EdsRelease(image);
    end;
  end;
end;

function GetImageDate(dirItem: EdsDirectoryItemRef;
  var FileFime: TFileTime): EdsError;
var
  stream: EdsStreamRef;
begin
  Result := EdsCreateMemoryStream(0, stream);
  if Result = EDS_ERR_OK then
  begin
    Result := GetImageDate(stream, dirItem, FileFime);
    EdsRelease(stream);
  end;
end;

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
  FCurrentSession := nil;
  FInfoLines := nil;
  FInfoLineCount := 0;
  // FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_GETPANELSHORTINFO, @FPanelInfo);
end;

function TCanon.DeleteFiles(PanelItem: PPluginPanelItem; ItemsNumber,
  OpMode: Integer): Integer;
var
  text: TFarString;
  UserData: PPanelUserData;
  edserr: EdsError;
  dirInfo: EdsDirectoryItemInfo;
  skipall, delallfolder, skipfile: Boolean;
  i: Integer;
begin
  Result := 0;
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
          edserr := EdsGetDirectoryItemInfo(UserData^.BaseRef, dirInfo);
          if edserr = EDS_ERR_OK then
          begin
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
        skipfile := False;
        edserr := EDS_ERR_OPERATION_CANCELLED;
        if ItemsNumber = 1 then
        begin
          edserr := DeleteDirItem(UserData^.BaseRef, @dirInfo, OpMode, skipall,
            delallfolder, skipfile);
        end
        else if (OpMode and OPM_SILENT <> 0) or
            (FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_GETCONFIRMATIONS, nil) and
              FCS_DELETE = 0) or
            (ShowMessage(GetMsg(MDeleteFilesTitle), PFarChar(text),
              [GetMsg(MBtnAll), GetMsg(MBtnCancel)], FMSG_WARNING) = 0) then
          for i := 0 to ItemsNumber - 1 do
          begin
            UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData);
            edserr := DeleteDirItem(UserData^.BaseRef, nil, OpMode, skipall,
              delallfolder, skipfile);
          end;
        if edserr = EDS_ERR_OK then
          Result := 1;
      end;
    end;
  end;
end;

destructor TCanon.Destroy;
var
  i: Integer;
begin
  if FInfoLineCount > 0 then
  begin
    FreeMem(FInfoLines);
    FInfoLineCount := 0;
  end;
  if Length(FFindDataItem) > 0 then
  begin
    for i := Length(FFindDataItem) - 1 downto 0 do
      FreeFindDataItem(FFindDataItem[i]);
    SetLength(FFindDataItem, 0);
  end;
  FreeLib;
  inherited;
end;

procedure TCanon.FreeFindDataItem(FindDataItem: TFindDataItem);
var
  i: Integer;
  BaseRef: EdsBaseRef;
begin
  with FindDataItem do
  begin
    if ItemsNumber > 0 then
    begin
      for i := 0 to ItemsNumber - 1 do
      begin
        BaseRef := PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData)^.BaseRef;
        if BaseRef = FCurrentSession then
        begin
          CloseSession;
          FCurrentSession := nil;
        end;
        EdsRelease(BaseRef);
{$IFDEF UNICODE}
        if Assigned(TPluginPanelItemArray(PanelItem)[i].FindData.cFileName) then
          FreeMem(TPluginPanelItemArray(PanelItem)[i].FindData.cFileName);
{$ENDIF}
        FreeMem(PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData));
      end;
      FreeMem(PanelItem);
    end;
    Free;
{$IFDEF OUT_LOG}
    WriteLn(LogFile, 'FreeFindDataItem');
{$ENDIF}
  end;
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

    if FCurDirectory <> '' then
    begin
      FPanelTitle := GetMsgStr(MPalelTitle) + ':' + FCurDirectory;
      PanelTitle := PFarChar(FPanelTitle);
    end
    else
      PanelTitle := GetMsg(MPalelTitle);

    if (FCurFindDataItem >= 0) and (FCurFindDataItem < Length(FFindDataItem)) then
    begin
      if FCurFindDataItem = 0 then
      begin
        FColumnTitles[0] := GetMsg(MCameraName);
        SetTitles := True;
      end
      else if FFindDataItem[FCurFindDataItem].ParentData^.BaseRefType = brtCamera then
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
      if FCurFindDataItem > 0 then
        case FFindDataItem[FCurFindDataItem].ParentData^.BaseRefType of
          brtCamera:
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
          brtVolume:
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
  edserr: EdsError;
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
    begin
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
        edserr := EDS_ERR_DIR_NOT_FOUND
      else
        edserr := EDS_ERR_OK;
      if edserr = EDS_ERR_OK then
      begin
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
              edserr := EdsGetDirectoryItemInfo(UserData^.BaseRef, dirInfo);
              skipfile := False;
              if edserr = EDS_ERR_OK then
              begin
                if dirInfo.isFolder = 0 then
                  edserr := DownloadFile(UserData^.BaseRef, @dirInfo, NewDestPath,
                    Move, silent, ProgressBar,
                    TPluginPanelItemArray(PanelItem)[i].FindData.dwFileAttributes,
                    overall, skipall, overroall, skiproall, skipfile)
                else
{$IFDEF UNICODE}
                  edserr := RecursiveDownload(UserData^.BaseRef,
                    AddEndSlash(NewDestPath) + CharToWideChar(dirInfo.szFileName),
                    Move, silent, ProgressBar, overall, skipall, overroall, skiproall);
{$ELSE}
                  edserr := RecursiveDownload(UserData^.BaseRef,
                    AddEndSlash(NewDestPath) + dirInfo.szFileName,
                    Move, silent, ProgressBar, overall, skipall, overroall, skiproall);
{$ENDIF}


              end;
              if edserr <> EDS_ERR_OK then
                Break
              else if not skipfile then
                TPluginPanelItemArray(PanelItem)[i].Flags :=
                  TPluginPanelItemArray(PanelItem)[i].Flags and not PPIF_SELECTED;
            end;
          end;
        finally
          if Assigned(ProgressBar) then
            ProgressBar.Free;
        end;
      end;
      if edserr = EDS_ERR_OK then
        Result := 1
      else if edserr = EDS_ERR_OPERATION_CANCELLED then
        Result := -1
      else
        ShowEdSdkError(edserr);
    end;
  end;
end;

type
  PContextData = ^TContextData;
  TContextData = record
    FProgressBar: TProgressBar;
    FText: TFarString;
  end;

function ProgressFunc(inPercent: EdsUInt32; inContext: Pointer;
  var outCancel: EdsBool): EdsError; stdcall;
begin
  with PContextData(inContext)^ do
    if not FProgressBar.UpdateProgress(inPercent, FText) then
      Result := EDS_ERR_OPERATION_CANCELLED
    else
      Result := EDS_ERR_OK;
end;

function TCanon.DownloadFile(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
  Silent: Boolean; ProgressBar: TProgressBar; attrib: Cardinal;
  var overall, skipall, overroall, skiproall, skipfile: Boolean): EdsError;
var
  stream: EdsStreamRef;
  image: EdsImageRef;
  localFileTime, filetime: TFileTime;
  hFile: THandle;
  edserr: EdsError;

  dateTime: EdsTime;
  sysTime: TSystemTime;
  P: Pointer;
  ContextData: TContextData;
  FromName, ToName: TFarString;
  FromNameL, ToNameL: TFarString;
  attr: Cardinal;
begin
  Result := EDS_ERR_OK;
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
            Result := EDS_ERR_OPERATION_CANCELLED;
        end;
      finally
        Free;
      end;
    if Result <> EDS_ERR_OPERATION_CANCELLED then
    begin
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
              begin
                Result := EDS_ERR_OPERATION_CANCELLED;
                Exit;
              end;
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
  end;

  if Result = EDS_ERR_OK then
  begin
{$IFDEF UNICODE}
    Result := EdsCreateFileStreamEx(PFarChar(ToName),
      kEdsFileCreateDisposition_CreateAlways, kEdsAccess_ReadWrite, stream);
{$ELSE}
    Result := EdsCreateFileStream(PFarChar(ToName),
      kEdsFileCreateDisposition_CreateAlways, kEdsAccess_ReadWrite, stream);
{$ENDIF}
    if Result = EDS_ERR_OK then
    begin
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
        Result := EdsSetProgressCallback(stream, @ProgressFunc,
          kEdsProgressOption_Periodically, EdsUInt32(@ContextData));
      end;
      if Result = EDS_ERR_OK then
      begin
        Result := EdsDownload(dirItem, dirInfo.size, stream);
        if Result = EDS_ERR_OK then
        begin
          Result := EdsDownloadComplete(dirItem);

          if Result = EDS_ERR_OK then
          begin
            edserr := EdsCreateImageRef(stream, image);
            if edserr = EDS_ERR_OK then
            begin
              P := @dateTime;
              edserr := EdsGetPropertyData(image, kEdsPropID_DateTime, 0,
                SizeOf(EdsTime), Pointer(P^));
              if edserr = EDS_ERR_OK then
              begin
                sysTime.wYear := dateTime.year;
                sysTime.wMonth := dateTime.month;
                sysTime.wDay := dateTime.day;
                sysTime.wHour := dateTime.hour;
                sysTime.wMinute := dateTime.minute;
                sysTime.wSecond := dateTime.second;
                sysTime.wMilliseconds := dateTime.millseconds;

                SystemTimeToFileTime(sysTime, localFileTime);
                LocalFileTimeToFileTime(localFileTime, FileTime);
              end;
              EdsRelease(image);
            end;
          end;
        end;
      end;
      EdsRelease(stream);
      if Result = EDS_ERR_OK then
      begin
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
          Result := DeleteDirItem(dirItem, dirInfo);
      end
      else if Result = EDS_ERR_OPERATION_CANCELLED then
      begin
        if FileExists(ToName) then
{$IFDEF UNICODE}
          DeleteFileW(PFarChar(ToName));
{$ELSE}
          DeleteFileA(PFarChar(ToName));
{$ENDIF}
      end;
    end;
  end;
end;

function TCanon.RecursiveDownload(dirItem: EdsDirectoryItemRef;
  const DestPath: TFarString; Move: Integer; Silent: Boolean;
  ProgressBar: TProgressBar;
  var overall, skipall, overroall, skiproall: Boolean): EdsError;
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
    begin
      Result := EDS_ERR_DIR_NOT_FOUND;
      Exit;
    end;
  end;
  Result := EdsGetChildCount(dirItem, count);
  if (Result = EDS_ERR_OK) and (count > 0) then
    for i := 0 to count - 1 do
    begin
      Result := EdsGetChildAtIndex(dirItem, i, childRef);
      if Result = EDS_ERR_OK then
      begin
        Result := EdsGetDirectoryItemInfo(childRef, childInfo);
        if Result = EDS_ERR_OK then
        begin
          if childInfo.isFolder <> 0 then
{$IFDEF UNICODE}
            Result := RecursiveDownload(childRef,
              AddEndSlash(DestPath) + CharToWideChar(childInfo.szFileName),
              Move, silent, ProgressBar, overall, skipall, overroall, skiproall)
{$ELSE}
            Result := RecursiveDownload(childRef,
              AddEndSlash(DestPath) + childInfo.szFileName,
              Move, silent, ProgressBar, overall, skipall, overroall, skiproall)
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
            Result := DownloadFile(childRef, @childInfo, DestPath,
              Move, silent, ProgressBar, dwFileAttributes,
              overall, skipall, overroall, skiproall, skipfile);
          end;
        end;
        EdsRelease(childRef);
        if Result <> EDS_ERR_OK then
          Break;
      end;
    end;
  if (Move <> 0) and (Result = EDS_ERR_OK) then
    Result := DeleteDirItem(dirItem);
end;

function TCanon.DeleteDirItem(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo): EdsError;
var
  skip: Boolean;
begin
  skip := True;
  Result := DeleteDirItem(dirItem, dirInfo, OPM_SILENT, skip, skip, skip);
end;

function TCanon.DeleteDirItem(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
  var skipall, delallfolder, skipfile: Boolean): EdsError;
var
  text: PFarChar;
  MessStr: TFarString;
  retry: Boolean;
  dirInfo_: EdsDirectoryItemInfo;
  count: EdsUInt32;
begin
  if not Assigned(dirInfo) then
  begin
    Result := EdsGetDirectoryItemInfo(dirItem, dirInfo_);
    if Result = EDS_ERR_OK then
      dirInfo := @dirInfo_
    else
      Exit;
  end;
  repeat
    Result := EDS_ERR_OK;
    retry := False;
    skipfile := False;
    if (OpMode and OPM_SILENT = 0) and
      (dirInfo^.isFolder <> 0) and
      not delallfolder then
    begin
      Result := EdsGetChildCount(dirItem, count);
      if count <> 0 then
      begin
        MessStr := GetMsgStr(MFolderDeleted) + #10 +
          {$IFDEF UNICODE}
            CharToWideChar(dirInfo^.szFileName);
          {$ELSE}
            dirInfo_.szFileName;
          {$ENDIF}
        case ShowMessage(GetMsg(MDeleteFolderTitle), PFarChar(MessStr),
            [GetMsg(MBtnDelete), GetMsg(MBtnAll), GetMsg(MBtnSkip),
              GetMsg(MBtnCancel)], FMSG_WARNING) of
          //0: ; // delete
          1: delallfolder := True; // all
          2:
          begin
            skipfile := True; // skip
            Exit;
          end;
          3:
          begin
            Result := EDS_ERR_OPERATION_CANCELLED; //cancel
            Exit;
          end;
        end;
      end;
    end;
    if Result = EDS_ERR_OK then
      Result := EdsDeleteDirectoryItem(dirItem);
    if Result <> EDS_ERR_OK then
    begin
      if skipall then
        Result := EDS_ERR_OK
      else
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
          begin
            Result := EDS_ERR_OK;
            retry := True;
          end;
          1: Result := EDS_ERR_OK; // Skip
          2: // SkipAll
          begin
            Result := EDS_ERR_OK;
            skipall := True;
          end;
          3: ; // Cancel
        end;
      end;
    end;
  until not retry;
end;

function TCanon.GetCameraInfo(var FindDataItem: TFindDataItem): Boolean;
var
  cameraList: EdsCameraListRef;
  deviceInfo: EdsDeviceInfo;
  camera: EdsCameraRef;
  count: EdsUInt32;
  edserr: EdsError;
  i: Integer;
  PanelUserData: PPanelUserData;
begin
  Result := False;
  with FindDataItem do
  begin
    cameraList := nil;
    count := 0;

    { get list of camera }
    edserr := EdsGetCameraList(cameraList);

    if edserr = EDS_ERR_OK then
    begin
      { get number of camera }
      edserr := EdsGetChildCount(cameraList, count);
      if edserr = EDS_ERR_OK then
        if count > 0 then
        begin
          ItemsNumber := count;
          GetMem(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
          ZeroMemory(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
          for i := 0 to count - 1 do
          begin
            camera := nil;
            EdsGetChildAtIndex(cameraList, i, camera);
            if Assigned(camera) then
            begin
              edserr := EdsGetDeviceInfo(camera, deviceInfo);
              if edserr = EDS_ERR_OK then
              begin
                with TPluginPanelItemArray(PanelItem)[i] do
                begin
                  //Flags := PPIF_USERDATA;
                  SetFindDataName(FindData, deviceInfo.szDeviceDescription);
                  FindData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY;
                  GetMem(PanelUserData, SizeOf(TPanelUserData));
                  PanelUserData^.BaseRef := camera;
                  PanelUserData^.BaseRefType := brtCamera;
                  UserData := Cardinal(PanelUserData);
                  Result := True;
                end;
              end;
            end;
          end;
        end
        else
          Result := True;
    end;
  end;
end;

function TCanon.GetDirectoryInfo(aParentData: PPanelUserData;
  var FindDataItem: TFindDataItem; getDateTime: Boolean): Boolean;
var
  dirItem: EdsDirectoryItemRef;
  dirItem1: EdsDirectoryItemRef;
  dirItemInfo: EdsDirectoryItemInfo;

  fileAttr: EdsFileAttributes;

  count: EdsUInt32;
  edserr: EdsError;

  stream: EdsStreamRef;

  ProgressBar: TProgressBar;
  i: Integer;
  PanelUserData: PPanelUserData;
  FInterruptTitle, FInterruptText: PFarChar;
begin
  Result := False;
  stream := nil;
  with FindDataItem do
  begin
    ParentData := aParentData;
    edserr := EdsGetChildCount(ParentData^.BaseRef, count);
    if edserr = EDS_ERR_OK then
    begin
      if count > 0 then
      begin
        ItemsNumber := count;
        GetMem(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
        ZeroMemory(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
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
            EdsGetChildAtIndex(ParentData^.BaseRef, i, dirItem);
            if Assigned(dirItem) then
            begin
              edserr := EdsGetDirectoryItemInfo(dirItem, dirItemInfo);
              if edserr = EDS_ERR_OK then
                with TPluginPanelItemArray(PanelItem)[i] do
                begin
                  //Flags := PPIF_USERDATA;
                  SetFindDataName(FindData, dirItemInfo.szFileName);
                  if dirItemInfo.isFolder <> 0 then
                  begin
                    FindData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY;
                  end
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
                        edserr := EdsSeek(stream, 0, kEdsSeek_Begin)
                      else
                        edserr := EdsCreateMemoryStream(0, stream);
                      if edserr = EDS_ERR_OK then
                      begin
                        edserr := GetImageDate(stream, dirItem,
                          FindData.ftCreationTime);
                        if edserr = EDS_ERR_OK then
                        begin
                          FindData.ftLastAccessTime := FindData.ftCreationTime;
                          FindData.ftLastWriteTime := FindData.ftCreationTime;
                        end;
                      end;
                    end;
                  end;
                  dirItem1 := dirItem;
                  edserr := EdsGetAttribute(dirItem1, fileAttr);
                  if edserr = EDS_ERR_OK then
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
                  GetMem(PanelUserData, SizeOf(TPanelUserData));
                  PanelUserData^.BaseRef := dirItem;
                  PanelUserData^.BaseRefType := brtDirItem;
                  UserData := Cardinal(PanelUserData);
                  Result := True;
                end;
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
      end
      else
        Result := True;
    end
    else
      ShowEdSdkError(edserr);
  end;
end;

function TCanon.GetVolumeInfo(aParentData: PPanelUserData;
  var FindDataItem: TFindDataItem): Boolean;
var
  volume: EdsVolumeRef;
  volumeInfo: EdsVolumeInfo;
  count: EdsUInt32;
  edserr: EdsError;
  i: Integer;
  PanelUserData: PPanelUserData;
begin
  Result := False;
  with FindDataItem do
  begin
    ParentData := aParentData;
    edserr := EdsGetChildCount(ParentData^.BaseRef, count);
    if edserr = EDS_ERR_OK  then
      if count > 0 then
      begin
        ItemsNumber := count;
        GetMem(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
        ZeroMemory(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
        for i := 0 to count - 1 do
        begin
          volume := nil;
          EdsGetChildAtIndex(ParentData^.BaseRef, i, volume);
          if Assigned(volume) then
          begin
            edserr := EdsGetVolumeInfo(volume, volumeInfo);
            if edserr = EDS_ERR_OK then
            begin
              with TPluginPanelItemArray(PanelItem)[i] do
              begin
                //Flags := PPIF_USERDATA;
                SetFindDataName(FindData, volumeInfo.szVolumeLabel);
                FindData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY;
                GetMem(PanelUserData, SizeOf(TPanelUserData));
                PanelUserData^.BaseRef := volume;
                PanelUserData^.BaseRefType := brtVolume;
                UserData := Cardinal(PanelUserData);
                Result := True;
              end;
            end;
          end;
        end;
      end
      else
        Result := True;
  end;
end;

procedure TCanon.SetFindDataName(var FindData: TFarFindData; FileName: PAnsiChar);
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

function TCanon.GetFindData(var PanelItem: PPluginPanelItem;
  var ItemsNumber: Integer; OpMode: Integer): Integer;
begin
  Result := 0;
  if Length(FFindDataItem) = 0 then
  begin
    SetLength(FFindDataItem, 1);
    FCurFindDataItem := 0;
    FFindDataItem[FCurFindDataItem] := TFindDataItem.Create;
    if not GetCameraInfo(FFindDataItem[FCurFindDataItem]) then
    begin
      FFindDataItem[FCurFindDataItem].Free;
      SetLength(FFindDataItem, 0);
    end;
  end;
  if (FCurFindDataItem >= 0) and (FCurFindDataItem < Length(FFindDataItem)) then
  begin
    PanelItem := FFindDataItem[FCurFindDataItem].PanelItem;
    ItemsNumber := FFindDataItem[FCurFindDataItem].ItemsNumber;
    Result := 1;
  end;
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
  function ChDirDown(NewDir: PFarChar; var NewFindDataItem: Integer;
    var NewDirectory: TFarString): Boolean;
  var
    i, CurFindDataItem: Integer;
    UserData: PPanelUserData;
    edserr: EdsError;
    volumeInfo: EdsVolumeInfo;
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
    edserr: EdsError;
  begin
    Result := '';
    edserr := EdsGetPropertySize(camera, PropertyId, 0, datatype, size);
    if edserr = EDS_ERR_OK then
    begin
      if EdsEnumDataType(datatype) = kEdsDataType_String then
      begin
        p := @str;
        if EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)) = EDS_ERR_OK then
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
        if EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)) = EDS_ERR_OK then
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
        if EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)) = EDS_ERR_OK then
          if Assigned(ff) then
            Result := ff(data)
          else
            Result := Format('%d', [data]);
      end
      else if EdsEnumDataType(datatype) in [kEdsDataType_UInt32] then
      begin
        p := @data;
        if EdsGetPropertyData(camera, PropertyId, 0, size, Pointer(P^)) = EDS_ERR_OK then
          if Assigned(ff) then
            Result := ff(data)
          else
            Result := Format('%u', [data]);
      end;
    end
    else
      Result := GetMsgStr(MPropertyUnavailable);
  end;
  begin
    Result := False;
    UserData := nil;
    with FFindDataItem[NewFindDataItem] do
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
      edserr := EDS_ERR_OK;
      for i := NewFindDataItem + 1 to Length(FFindDataItem) - 1 do
        if UserData^.BaseRef = FFindDataItem[i].ParentData^.BaseRef then
        begin
          NewFindDataItem := i;
          Result := True;
          Break;
        end;
      if not Result then
      begin
        CurFindDataItem := Length(FFindDataItem);
        SetLength(FFindDataItem, CurFindDataItem + 1);
        FFindDataItem[CurFindDataItem] := TFindDataItem.Create;
        case UserData^.BaseRefType of
          brtCamera:
          begin
            Result := True;
            if FCurrentSession <> UserData^.BaseRef then
            begin
              if Assigned(FCurrentSession) then
                CloseSession;
              Result := OpenSession(UserData^.BaseRef);
              if Result then
              begin
                FCurrentSession := UserData^.BaseRef;
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
                  // GetProperty(UserData^.BaseRef, kEdsPropID_ProductName);
                end;
              end;
            end
            else
              edserr := EDS_ERR_OK;
            if Result and (edserr = EDS_ERR_OK) then
              Result := GetVolumeInfo(UserData, FFindDataItem[CurFindDataItem]);
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
            Result := GetDirectoryInfo(UserData, FFindDataItem[CurFindDataItem],
              True);
          end;
          brtDirItem:
            Result := GetDirectoryInfo(UserData, FFindDataItem[CurFindDataItem],
              True);
        end;
        if Result then
          NewFindDataItem := CurFindDataItem
        else
        begin
          FFindDataItem[CurFindDataItem].Free;
          SetLength(FFindDataItem, CurFindDataItem);
        end;
      end;
      if Result then
      begin
        if NewDirectory <> '' then
          NewDirectory := NewDirectory + cDelim;
        NewDirectory := NewDirectory + NewDir;
      end
      else
        ShowEdSdkError(edserr);
    end;
  end;
  function ChDirUp(var NewFindDataItem: Integer;
    var NewDirectory: TFarString): Boolean;
  var
    UserData: PPanelUserData;
    i, j: Integer;
  begin
    Result := False;
    UserData := FFindDataItem[NewFindDataItem].ParentData;
    for i := NewFindDataItem - 1 downto 0 do
      with FFindDataItem[i] do
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
            for j := Length(FFindDataItem) - 1 to 1 do
              FreeFindDataItem(FFindDataItem[j]);
            SetLength(FFindDataItem, 1);
            if Assigned(FCurrentSession) then
            begin
              CloseSession;
              FCurrentSession := nil;
            end;
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
  else if (FCurFindDataItem >= 0) and (FCurFindDataItem < Length(FFindDataItem)) then
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
var
  edserr: EdsError;
begin
  if not IsConnect then
  begin
{$IFDEF USE_DYNLOAD}
    if not InitEDSDK(PFarChar(FileName)) then
      raise Exception.Create(err.e_Abort, GetMsg(MLibNotFound));
{$ENDIF}
    edserr := EdsInitializeSDK;
    if edserr <> EDS_ERR_OK then
      raise Exception.Create(err.e_Abort, GetEdSdkError(edserr))
    else
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

class function TCanon.OpenSession(session: EdsBaseRef): Boolean;
var
  edserr: EdsError;
begin
  if Assigned(CurrentSession) then
  begin
    Result := (CurrentSession = session);
    if Result then
      Inc(_SessionRefCount)
    else
      ShowMessage(GetMsg(MError), GetMsg(MOneSessionAllowed),
        FMSG_WARNING + FMSG_MB_OK);
  end
  else
  begin
    edserr := EdsOpenSession(session);
    Result := edserr = EDS_ERR_OK;
    if Result then
    begin
      CurrentSession := session;
      Inc(_SessionRefCount);
    end
    else
      ShowEdSdkError(edserr);
  end;
end;

initialization

  _RefCount := 0;
  IsConnect := False;
  _SessionRefCount := 0;
  CurrentSession := nil;

end.
