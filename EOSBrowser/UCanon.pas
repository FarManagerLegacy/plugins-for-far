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

  TCanon = class
  private
    FCurDirectory: TFarString;
    FPanelTitle: TFarString;
    // FPanelInfo: TPanelInfo;

    FPanelModesArray: array[0..9] of TPanelMode;
    FColumnTitles: array[0..0] of PFarChar;

    FFindDataItem: array of TFindDataItem;
    FCurFindDataItem: Integer;

    FCurrentSession: EdsBaseRef;

  private
    function _AddRef: Integer;
    function _Release: Integer;

    procedure SetFindDataName(var FindData: TFarFindData; FileName: PChar);

    function RecursiveDownload(dirItem: EdsDirectoryItemRef;
      const DestPath: TFarString; Move: Integer; Silent: Boolean;
      ProgressBar: TProgressBar; var overall, skipall: Boolean): EdsError;
    function DownloadFile(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
      Silent: Boolean; ProgressBar: TProgressBar;
      var overall, skipall: Boolean): EdsError;
    function DeleteDirItem(dirItem: EdsDirectoryItemRef;
      dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
      var skipall, delallfolder: Boolean): EdsError;
    function GetCameraInfo(var FindDataItem: TFindDataItem): Boolean;
    function GetVolumeInfo(aParentData: PPanelUserData;
      var FindDataItem: TFindDataItem): Boolean;
    function GetDirectoryInfo(aParentData: PPanelUserData;
      var FindDataItem: TFindDataItem; getDateTime: Boolean): Boolean;
    procedure FreeFindDataItem(FindDataItem: TFindDataItem);
  public
    constructor Create(const FileName: TFarString);
    destructor Destroy; override;

    procedure GetOpenPluginInfo(var Info: TOpenPluginInfo);
    function GetFindData(var PanelItem: PPluginPanelItem;
      var ItemsNumber: Integer; OpMode: Integer): Integer;
    function SetDirectory(Dir: PFarChar; OpMode: Integer): Integer;
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
  P: Pointer;
  sysTime: TSystemTime;
  dateTime: EdsTime;
  localFileTime: TFileTime;
begin
  // Получение информации о дате/времени
  P := @dateTime;
  Result := EdsDownloadThumbnail(dirItem, stream);
  if Result = EDS_ERR_OK then
  begin
    Result := EdsCreateImageRef(stream, image);
    if Result = EDS_ERR_OK then
    begin
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

var
  _RefCount: Integer;
  IsConnect: Boolean;

constructor TCanon.Create(const FileName: TFarString);
var
  i: Integer;
  edserr: EdsError;
begin
  inherited Create;
  if not IsConnect then
  begin
{$IFDEF USE_DYNLOAD}
    if not InitEDSDK(PFarChar(FileName)) then
      raise Exception.Create(err.e_Abort, GetMsg(MLibNotFound));
{$ENDIF}
    edserr := EdsInitializeSDK;
    if edserr <> EDS_ERR_OK then
      raise Exception.Create(err.e_Abort, '')
    else
      IsConnect := True;
  end;
  _AddRef;
  for i := 0 to 9 do
  with FPanelModesArray[i] do
  begin
    ColumnTypes := 'N';
    ColumnWidths := '0';
  end;
  FCurrentSession := nil;
  // FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_GETPANELSHORTINFO, @FPanelInfo);
end;

function TCanon.DeleteFiles(PanelItem: PPluginPanelItem; ItemsNumber,
  OpMode: Integer): Integer;
var
  text: TFarString;
  UserData: PPanelUserData;
  edserr: EdsError;
  dirInfo: EdsDirectoryItemInfo;
  skipall, delallfolder: Boolean;
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
        if (ItemsNumber = 1) or
          ((OpMode and OPM_SILENT <> 0) or
            (FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_GETCONFIRMATIONS, nil) and
              FCS_DELETE = 0) or
            (ShowMessage(GetMsg(MDeleteFilesTitle), PFarChar(text),
              [GetMsg(MBtnAll), GetMsg(MBtnCancel)], FMSG_WARNING) = 0)) then
        begin
          skipall := False;
          delallfolder := FARAPI.AdvControl(FARAPI.ModuleNumber,
            ACTL_GETCONFIRMATIONS, nil) and FCS_DELETENONEMPTYFOLDERS = 0;
          edserr := DeleteDirItem(UserData^.BaseRef, nil, OpMode, skipall,
            delallfolder);
          if edserr = EDS_ERR_OK then
            Result := 1;
        end;
      end;
    end;
  end;
end;

destructor TCanon.Destroy;
var
  i: Integer;
begin
  if Length(FFindDataItem) > 0 then
  begin
    for i := Length(FFindDataItem) - 1 to 0 do
      FreeFindDataItem(FFindDataItem[i]);
    SetLength(FFindDataItem, 0);
  end;
  if (_Release = 0) and IsConnect then
  begin
    EdsTerminateSDK;
{$IFDEF USE_DYNLOAD}
    FreeEDSDK;
{$ENDIF}
    IsConnect := False;
  end;
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
          EdsCloseSession(BaseRef);
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
  end;
end;

procedure TCanon.GetOpenPluginInfo(var Info: TOpenPluginInfo);
var
  i: Integer;
  SetTitles: Boolean;
begin
  with Info do
  begin
    StructSize := SizeOf(Info);
    //Format := 'EOS';
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
  overall, skipall: Boolean;
  NewDestPath: array [0..MAX_PATH - 1] of TFarCHar;
begin
  Result := 0;
  if (ItemsNumber > 0) and
    (TPluginPanelItemArray(PanelItem)[0].UserData <> 0) then
  begin
    UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[0].UserData);
    if UserData^.BaseRefType = brtDirItem then
    begin
      silent := OpMode and OPM_SILENT <> 0;
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

        if FARAPI.InputBox(title, PFarChar(subtitle), 'Copy', DestPath, NewDestPath,
            MAX_PATH, nil,
            {$IFDEF UNICODE}FIB_EDITPATH or{$ENDIF} FIB_BUTTONS) = 0 then
          Exit;
      end;
      if not DirectoryExists(NewDestPath) and not ForceDirectories(NewDestPath) then
        edserr := EDS_ERR_DIR_NOT_FOUND
      else
        edserr := EDS_ERR_OK;
      if edserr = EDS_ERR_OK then
      begin
        if not silent then
          ProgressBar := TProgressBar.Create(title, 100, 4)
        else
          ProgressBar := nil;
        try
          if Move <> 0 then
            overall := FARAPI.AdvControl(FARAPI.ModuleNumber,
              ACTL_GETCONFIRMATIONS, nil) and FCS_MOVEOVERWRITE = 0
          else
            overall := FARAPI.AdvControl(FARAPI.ModuleNumber,
              ACTL_GETCONFIRMATIONS, nil) and FCS_COPYOVERWRITE = 0;
          skipall := False;
          for i := 0 to ItemsNumber - 1 do
          begin
            UserData := PPanelUserData(TPluginPanelItemArray(PanelItem)[i].UserData);
            if UserData^.BaseRefType = brtDirItem then
            begin
              edserr := EdsGetDirectoryItemInfo(UserData^.BaseRef, dirInfo);
              if edserr = EDS_ERR_OK then
              begin
                if dirInfo.isFolder = 0 then
                  edserr := DownloadFile(UserData^.BaseRef, @dirInfo, NewDestPath,
                    Move, silent, ProgressBar, overall, skipall)
                else
{$IFDEF UNICODE}
                  edserr := RecursiveDownload(UserData^.BaseRef,
                    AddEndSlash(NewDestPath) + CharToWideChar(dirInfo.szFileName),
                    Move, silent, ProgressBar, overall, skipall);
{$ELSE}
                  edserr := RecursiveDownload(UserData^.BaseRef,
                    AddEndSlash(NewDestPath) + dirInfo.szFileName,
                    Move, silent, ProgressBar, overall, skipall);
{$ENDIF}


              end;
              if edserr <> EDS_ERR_OK then
                Break
              else
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
        Result := -1;
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
    if not FProgressBar.UpdateProgress(inPercent, True, FText) and
      ((FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_GETCONFIRMATIONS, nil) and
        FCS_INTERRUPTOPERATION = 0) or
      (ShowMessage(GetMsg(MInterruptedTitle), GetMsg(MInterruptedText),
        FMSG_WARNING + FMSG_MB_YESNO) = 0)) then
      Result := EDS_ERR_OPERATION_CANCELLED
    else
      Result := EDS_ERR_OK;
end;

function TCanon.DownloadFile(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo; DestPath: TFarString; Move: Integer;
  Silent: Boolean; ProgressBar: TProgressBar;
  var overall, skipall: Boolean): EdsError;
var
  stream: EdsStreamRef;
  image: EdsImageRef;
  localFileTime, filetime: TFileTime;
  hFile: THandle;
  edserr: EdsError;

  dateTime: EdsTime;
  sysTime: TSystemTime;
  P: Pointer;
  skipall_delete: Boolean;
  ContextData: TContextData;
  FromName, ToName: TFarString;
begin
  Result := EDS_ERR_OK;
  skipall_delete := True;
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
      Exit
    else if not overall then
      with TOverDlg.Create(ToName, dirItem, dirInfo) do
      try
        case Execute of
          //0: // Overwrite
          1: // All
            overall := True;
          2: // Skip
            Exit;
          3: // Skip All
          begin
            skipall := True;
            Exit;
          end;
          4: // Cancel
            Result := EDS_ERR_OPERATION_CANCELLED;
        end;
      finally
        Free;
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
          if Move <> 0 then
            FText := Format(GetMsg(MMoving), [FromName, ToName])
          else
            FText := Format(GetMsg(MCopying), [FromName, ToName]);
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
        if Move <> 0 then
          Result := DeleteDirItem(dirItem, dirInfo, OPM_SILENT, skipall_delete,
            skipall_delete);
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
  ProgressBar: TProgressBar; var overall, skipall: Boolean): EdsError;
var
  count, i: EdsUInt32;
  childRef: EdsDirectoryItemRef;
  childInfo: EdsDirectoryItemInfo;
  skipall_delete: Boolean;
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
              Move, silent, ProgressBar, overall, skipall)
{$ELSE}
            Result := RecursiveDownload(childRef,
              AddEndSlash(DestPath) + childInfo.szFileName,
              Move, silent, ProgressBar, overall, skipall)
{$ENDIF}
          else
            Result := DownloadFile(childRef, @childInfo, DestPath,
              Move, silent, ProgressBar, overall, skipall);
        end;
        EdsRelease(childRef);
        if Result <> EDS_ERR_OK then
          Break;
      end;
    end;
  if (Move <> 0) and (Result = EDS_ERR_OK) then
  begin
    skipall_delete := True;
    Result := DeleteDirItem(dirItem, nil, OPM_SILENT, skipall_delete,
      skipall_delete);
  end;
end;

function TCanon.DeleteDirItem(dirItem: EdsDirectoryItemRef;
  dirInfo: PEdsDirectoryItemInfo; OpMode: Integer;
  var skipall, delallfolder: Boolean): EdsError;
var
  text: PFarChar;
  MessStr: TFarString;
  retry: Boolean;
  dirInfo_: EdsDirectoryItemInfo;
  count: EdsUInt32;
  skip: Boolean;
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
    skip := False;
    if (OpMode and OPM_SILENT = 0) and
      (dirInfo^.isFolder <> 0) and
      not delallfolder then
    begin
      Result := EdsGetChildCount(dirItem, count);
      if count <> 0 then
      begin
        MessStr := GetMsgStr(MFolderDeleted) + #10 +
          {$IFDEF UNICODE}
            CharToWideChar(dirInfo_.szFileName);
          {$ELSE}
            dirInfo_.szFileName;
          {$ENDIF}
        case ShowMessage(GetMsg(MDeleteFolderTitle), PFarChar(MessStr),
            [GetMsg(MBtnDelete), GetMsg(MBtnAll), GetMsg(MBtnSkip),
              GetMsg(MBtnCancel)], FMSG_WARNING) of
          //0: ; // delete
          1: delallfolder := True; // all
          2: skip := True; // skip
          3: Result := EDS_ERR_OPERATION_CANCELLED; //cancel
        end;
      end;
    end;
    if not skip and (Result <> EDS_ERR_OK) then
      Result := EdsDeleteDirectoryItem(dirItem);
    //Result := EDS_ERR_UNIMPLEMENTED;
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

function TCanon._AddRef: Integer;
begin
  Inc(_RefCount);
  Result := _RefCount;
end;

function TCanon._Release: Integer;
begin
  if _RefCount > 0 then
    Dec(_RefCount);
  Result := _RefCount;
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
begin
  Result := False;
  stream := nil;
  with FindDataItem do
  begin
    ParentData := aParentData;
    edserr := EdsGetChildCount(ParentData^.BaseRef, count);
    if edserr = EDS_ERR_OK then
      if count > 0 then
      begin
        ItemsNumber := count;
        GetMem(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
        ZeroMemory(PanelItem, ItemsNumber * SizeOf(TPluginPanelItem));
        if getDateTime and (count > 10) then
          ProgressBar := TProgressBar.Create('Reading', count - 1)
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
                  begin
                    if Ord(fileAttr) and Ord(kEdsFileAttribute_Normal) <> 0 then
                      FindData.dwFileAttributes := FindData.dwFileAttributes or
                        FILE_ATTRIBUTE_NORMAL;
                    if Ord(fileAttr) and Ord(kEdsFileAttribute_ReadOnly) <> 0 then
                      FindData.dwFileAttributes := FindData.dwFileAttributes or
                        FILE_ATTRIBUTE_READONLY;
                    if Ord(fileAttr) and Ord(kEdsFileAttribute_Hidden) <> 0 then
                      FindData.dwFileAttributes := FindData.dwFileAttributes or
                        FILE_ATTRIBUTE_HIDDEN;
                    if Ord(fileAttr) and Ord(kEdsFileAttribute_System) <> 0 then
                      FindData.dwFileAttributes := FindData.dwFileAttributes or
                        FILE_ATTRIBUTE_SYSTEM;
                    if Ord(fileAttr) and Ord(kEdsFileAttribute_Archive) <> 0 then
                      FindData.dwFileAttributes := FindData.dwFileAttributes or
                        FILE_ATTRIBUTE_ARCHIVE;
                  end;
                  GetMem(PanelUserData, SizeOf(TPanelUserData));
                  PanelUserData^.BaseRef := dirItem;
                  PanelUserData^.BaseRefType := brtDirItem;
                  UserData := Cardinal(PanelUserData);
                  Result := True;
                end;
            end;
            if Assigned(ProgressBar) then
              ProgressBar.UpdateProgress(i);
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
      end
      else
        Result := True;
  end;
end;

procedure TCanon.SetFindDataName(var FindData: TFarFindData; FileName: PChar);
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

function TCanon.SetDirectory(Dir: PFarChar; OpMode: Integer): Integer;
  function ChDirDown(NewDir: PFarChar; var NewFindDataItem: Integer;
    var NewDirectory: TFarString): Boolean;
  var
    i, CurFindDataItem: Integer;
    UserData: PPanelUserData;
    edserr: EdsError;
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
            if FCurrentSession <> UserData^.BaseRef then
            begin
              if Assigned(FCurrentSession) then
                EdsCloseSession(FCurrentSession);
              edserr := EdsOpenSession(UserData^.BaseRef);
              if edserr = EDS_ERR_OK then
                FCurrentSession := UserData^.BaseRef;
            end
            else
              edserr := EDS_ERR_OK;
            if edserr = EDS_ERR_OK then
              Result := GetVolumeInfo(UserData, FFindDataItem[CurFindDataItem]);
          end;
          brtVolume, brtDirItem:
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
            NewDirectory := '';
          Break;
        end;
      end;
  end;
var
  p, p1: Integer;
  NewDirectory, CurDir: TFarString;
  err_ok: Boolean;
  CurFindDataItem: Integer;
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
    if Dir = '..' then
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
          if CurDir = '..' then
            err_ok := ChDirUp(CurFindDataItem, NewDirectory)
          else if CurDir <> '' then
            err_ok := ChDirDown(PFarChar(CurDir), CurFindDataItem, NewDirectory);
          p1 := p + 1;
          p := PosEx(cDelim, Dir, p1);
        end;
        if err_ok then
        begin
          CurDir := Copy(Dir, p1, Length(Dir) - p1 + 1);
          if CurDir = '..' then
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
  if (Result = 0) and (OpMode and (OPM_FIND or OPM_SILENT) = 0) then
  begin
    ShowMessage(GetMsg(MError), GetMsg(MPathNotFound),
      FMSG_WARNING + FMSG_MB_OK);
  end;
end;

initialization

  _RefCount := 0;
  IsConnect := False;

end.
