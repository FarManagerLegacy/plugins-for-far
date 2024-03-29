unit UEDialogs;

{$i CommonDirectives.inc}

interface

{$DEFINE USE_DYNLOAD}

uses
  Windows,
  Kol,
{$IFDEF UNICODE}
  {$IFDEF Far3}
  Plugin3,
  {$ELSE}
  PluginW,
  {$ENDIF}
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
  UEDSDKError,
  UTypes,
  UUtils,
  UDialogs,
  ULang;

type
  TCopyDlg = class(TCustomSimpleFarDialog)
{$IFDEF UNICODE}
  protected
    function InitFialogInfo(var AInfo: TDialogInfo): Integer; override;
{$ENDIF}
  private
    FDestText: PFarChar;
    function GetCreateSubDirs: Boolean;
  public
    constructor Create(const Title, SubTitle, SrcText, DestText: PFarChar);
    function Execute: Integer; override;
    property CreateSubDirs: Boolean read GetCreateSubDirs;
  end;

  TOverDlg = class(TCustomSimpleFarDialog)
{$IFDEF UNICODE}
  protected
    function InitFialogInfo(var AInfo: TDialogInfo): Integer; override;
{$ENDIF}
  public
    constructor Create(const FileName: TFarString; const OverText: PFarChar;
      dirItem: EdsDirectoryItemRef; dirInfo: PEdsDirectoryItemInfo);
    function Execute: Integer; override;
  end;

  TConfigDlg = class(TCustomSimpleFarDialog)
{$IFDEF UNICODE}
  protected
    function InitFialogInfo(var AInfo: TDialogInfo): Integer; override;
{$ENDIF}
  public
    constructor Create;
    function Execute: Integer; override;
  end;

  TConfigData = record
    AddToDiskMenu: Boolean;
{$IFNDEF UNICODE}
    DiskMenuNumberStr: TFarString;
    DiskMenuNumber: Integer;
{$ENDIF}
    Prefix: TFarString;
    LibraryPath: TFarString;
  end;

procedure LoadConfig;
procedure SaveConfig;
procedure ShowError(ErrorCode: EdsError; const ErrorMessage: TFarString);
procedure ShowEdSdkError(ErrorCode: EdsError);

var
  ConfigData: TConfigData;

implementation

uses
  UCanon;

procedure ShowError(ErrorCode: EdsError; const ErrorMessage: TFarString);
begin
  if ErrorCode <> EDS_ERR_OK then
    ShowEdSdkError(ErrorCode)
  else if ErrorMessage <> '' then
    ShowMessage(GetMsg(MError), PFarChar(ErrorMessage),
      FMSG_WARNING + FMSG_MB_OK);
end;

procedure ShowEdSdkError(ErrorCode: EdsError);
begin
  if ErrorCode <> EDS_ERR_OK then
    ShowMessage(GetMsg(MEdSdkError), GetEdSdkError(ErrorCode),
      FMSG_WARNING + FMSG_MB_OK);
end;

{ TOverDlg }

{$IFDEF UNICODE}
function TOverDlg.InitFialogInfo(var AInfo: TDialogInfo): Integer;
const
  cOverDlgGuid: TGUID = '{2B7BFF88-7576-476B-A9E3-B66C94712278}';
begin
  AInfo.Id := cOverDlgGuid;
  Result := 1;
end;
{$ENDIF}

constructor TOverDlg.Create(const FileName: TFarString; const OverText: PFarChar;
  dirItem: EdsDirectoryItemRef; dirInfo: PEdsDirectoryItemInfo);
  function GetFileText(Width: Integer; MsgId: TLanguageID; filetime: TFileTime;
    filesize: Cardinal): TFarString;
  const
    cFmt = '%d %.2d.%.2d.%.4d %.2d:%.2d:%.2d';
  var
    sysTime: TSystemTime;
    localFileTime: TFileTime;
    i, l: Integer;
  begin
    FileTimeToLocalFileTime(filetime, localFileTime);
    FileTimeToSystemTime(localFileTime, sysTime);
    l := Length(GetMsgStr(MsgId) + Format(cFmt, [filesize,
      sysTime.wDay, sysTime.wMonth, sysTime.wYear,
      sysTime.wHour, sysTime.wMinute, sysTime.wSecond]));
    SetLength(Result, Width - l);
    for i := 1 to Width - l do
      Result[i] := ' ';
    Result := GetMsgStr(MsgId) + Result + Format(cFmt, [filesize,
      sysTime.wDay, sysTime.wMonth, sysTime.wYear,
      sysTime.wHour, sysTime.wMinute, sysTime.wSecond])
  end;
const
  cSizeX = 72;
  cSizeY = 13;
  cLeftSide = 5;
var
  NewFileName: TFarString;
  filetime: TFileTime;
  filesize: DWORD;
  hFile: THandle;
  NewText, OldText: TFarString;
begin
  if Assigned(dirItem) then
    GetImageDate(dirItem, filetime)
  else
    ZeroMemory(@filetime, SizeOf(filetime));
  if Assigned(dirInfo) then
    filesize := dirInfo^.size
  else
    filesize := 0;
  NewText := GetFileText(cSizeX - cLeftSide * 2, MNew, filetime, filesize);
{$IFDEF UNICODE}
  hFile := CreateFileW(
{$ELSE}
  hFile := CreateFileA(
{$ENDIF}
    PFarChar(FileName), 0,
    FILE_SHARE_DELETE	or FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    GetFileTime(hFile, nil, nil, @filetime);
    filesize := GetFileSize(hFile, nil);
    CloseHandle(hFile);
  end
  else
  begin
    ZeroMemory(@filetime, SizeOf(filetime));
    filesize := 0;
  end;
  OldText := GetFileText(cSizeX - cLeftSide * 2, MExisting, filetime, filesize);
  NewFileName := '' + FileName;
  inherited Create([
  {0} DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY, 0, PFarChar(MWarning)),
  {1} DlgItem(DI_TEXT, cLeftSide, 2, cSizeX - cLeftSide * 2, -1,
        DIF_CENTERTEXT, OverText),
  {2} DlgItem(DI_TEXT, cLeftSide, 3, cSizeX - cLeftSide * 2, -1,
        0, FSF.TruncPathStr(PFarChar(NewFileName), cSizeX - cLeftSide * 2)),
  {3} DlgItem(DI_TEXT, cLeftSide - 1, 4, -1, 0, DIF_SEPARATOR, ''),
  {4} DlgItem(DI_TEXT, cLeftSide, 5, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(NewText)),
  {5} DlgItem(DI_TEXT, cLeftSide, 6, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(OldText)),
  {6} DlgItem(DI_TEXT, cLeftSide - 1, 7, -1, 0, DIF_SEPARATOR, ''),
  {7} DlgItem(DI_CHECKBOX, cLeftSide, 8, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(MRememberChoice)),
  {8} DlgItem(DI_TEXT, cLeftSide - 1, cSizeY - 4, -1, 0, DIF_SEPARATOR, ''),
  {9} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnOverwrite), Pointer(True)),
 {10} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnSkip)),
 {11} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnCancel))
    ], -1, -1, cSizeX, cSizeY, nil);
  Flags := FDLG_WARNING;
end;

function TOverDlg.Execute: Integer;
begin
  Result := inherited Execute;
  if Result < 0 then
    Result := 4
  else
  begin
    Result := (Result - 9) * 2;
    if (Result < 4) and ItemCheckData[7] then
      Result := Result + 1;
  end;
end;

{ TConfigDlg }

const
  cEosPrefix = 'EOS';
  cEOSBrowser = 'EOSBrowser';
  cAddToDiskMenu = 'AddToDiskMenu';
{$IFNDEF UNICODE}
  cDiskMenuNumber = 'DiskMenuNumber';
{$ENDIF}
  cPrefix = 'Prefix';
  cLibraryPath = 'LibraryPath';

procedure LoadConfig;
var
  SubKey: TFarString;
begin
  SubKey := FARAPI.RootKey + cDelim + cEOSBrowser;
  with ConfigData do
  begin
    AddToDiskMenu := ReadRegBoolValue(cAddToDiskMenu, SubKey, True);
{$IFNDEF UNICODE}
    DiskMenuNumberStr := ReadRegStringValue(cDiskMenuNumber, SubKey, '0');
    DiskMenuNumber := FSF.atoi(PFarChar(DiskMenuNumberStr));
{$ENDIF}
    Prefix := ReadRegStringValue(cPrefix, SubKey, cEosPrefix);
    LibraryPath := ReadRegStringValue(cLibraryPath, SubKey, '');
  end;
end;

procedure SaveConfig;
var
  SubKey: TFarString;
begin
  SubKey := FARAPI.RootKey + cDelim + cEOSBrowser;
  with ConfigData do
  begin
    WriteRegBoolValue(cAddToDiskMenu, SubKey, AddToDiskMenu);
{$IFNDEF UNICODE}
    WriteRegStringValue(cDiskMenuNumber, SubKey, DiskMenuNumberStr);
{$ENDIF}
    WriteRegStringValue(cPrefix, SubKey, Prefix);
    if LibraryPath <> '' then
      LibraryPath := IncludeTrailingPathDelimiter(LibraryPath);
    WriteRegStringValue(cLibraryPath, SubKey, LibraryPath);
  end;
end;

{$IFDEF UNICODE}
function TConfigDlg.InitFialogInfo(var AInfo: TDialogInfo): Integer;
const
  cConfigDlgGuid: TGUID = '{483D99E4-4B09-4C97-BA0E-DC362CBE5B9B}';
begin
  AInfo.Id := cConfigDlgGuid;
  Result := 1;
end;
{$ENDIF}

constructor TConfigDlg.Create;
const
  cSizeX = 74;
{$IFDEF UNICODE}
  cSizeY = 11;
{$ELSE}
  cSizeY = 13;
  cSharp: PFarChar = '#';
{$ENDIF}
  cLeftSide = 5;
begin
  with ConfigData do
    inherited Create([
  {0} DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY, 0,
        PFarChar(MConfigurationTitle)),
  {1} DlgItem(DI_CHECKBOX, cLeftSide, 2, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(MAddToDriveMenu), Pointer(AddToDiskMenu)),
{$IFNDEF UNICODE}
  {2} DlgItem(DI_FIXEDIT, cLeftSide + 2, 3, 1, -1, DIF_MASKEDIT,
        PFarChar(DiskMenuNumberStr), cSharp),
  {3} DlgItem(DI_TEXT, cLeftSide + 4, 3, cSizeX - cLeftSide * 2 - 3, -1, 0,
        PFarChar(MDriveMenuHotkey)),
  {4} DlgItem(DI_TEXT, cLeftSide - 1, 4, -1, 0, DIF_SEPARATOR, ''),
{$ENDIF}
  {2-5} DlgItem(DI_TEXT, cLeftSide, cSizeY - 8, cSizeX - cLeftSide * 2 - 4, -1, 0,
        PFarChar(MCommandLinePrefix)),
  {3-6} DlgItem(DI_EDIT, cLeftSide, cSizeY - 7, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(Prefix)),
  {4-7} DlgItem(DI_TEXT, cLeftSide, cSizeY - 6, cSizeX - cLeftSide * 2 - 4, -1, 0,
        PFarChar(MLibraryPath)),
  {5-8} DlgItem(DI_EDIT, cLeftSide, cSizeY - 5, cSizeX - cLeftSide * 2, -1,
        {$IFDEF UNICODE}DIF_EDITPATH{$ELSE}0{$ENDIF},
        PFarChar(LibraryPath)),
  {6-9} DlgItem(DI_TEXT, cLeftSide - 1, cSizeY - 4, -1, 0, DIF_SEPARATOR, ''),
 {7-10} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnOk), Pointer(True)),
 {8-11} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnCancel))
      ], -1, -1, cSizeX, cSizeY, nil);
end;

function TConfigDlg.Execute: Integer;
begin
{$IFDEF UNICODE}
  if inherited Execute = 7 then
{$ELSE}
  if inherited Execute = 10 then
{$ENDIF}
  begin
    with ConfigData do
    begin
      AddToDiskMenu := ItemCheckData[1];
{$IFDEF UNICODE}
      Prefix := ItemTextData[3];
      LibraryPath := ItemTextData[5];
{$ELSE}
      DiskMenuNumberStr := ItemTextData[2];
      DiskMenuNumber := FSF.atoi(PFarChar(DiskMenuNumberStr));
      Prefix := ItemTextData[6];
      LibraryPath := ItemTextData[8];
{$ENDIF}
    end;
    SaveConfig;
    Result := 1;
  end
  else
    Result := 0;
end;

{ TCopyDlg }

const
  cCreateSubDirs = 'CreateSubDirs';

{$IFDEF UNICODE}
function TCopyDlg.InitFialogInfo(var AInfo: TDialogInfo): Integer;
const
  cCopyDlgGuid: TGUID = '{07A34660-5DB0-4887-9B97-FC9293F9D422}';
begin
  AInfo.Id := cCopyDlgGuid;
  Result := 1;
end;
{$ENDIF}

function TCopyDlg.GetCreateSubDirs: Boolean;
begin
  Result := ItemCheckData[4];
end;

constructor TCopyDlg.Create(const Title, SubTitle, SrcText, DestText: PFarChar);
const
  cSizeX = 76;
  cSizeY = 10;
  cLeftSide = 5;
  cCopy: PFarChar = 'Copy'; // <-��������� ��� ������� �����������
var
  CreateSubDirs: Boolean;
begin
  CreateSubDirs := ReadRegBoolValue(cCreateSubDirs,
    FARAPI.RootKey + cDelim + cEOSBrowser, False);
  inherited Create([
  {0} DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY, 0, PFarChar(Title)),
  {1} DlgItem(DI_TEXT, cLeftSide, 2, cSizeX - cLeftSide * 2, -1,
        0, SubTitle),
  {2} DlgItem(DI_EDIT, cLeftSide, 3, cSizeX - cLeftSide * 2, -1,
        DIF_HISTORY{$IFDEF UNICODE} or DIF_EDITPATH{$ENDIF},
        SrcText, cCopy),
  {3} DlgItem(DI_TEXT, cLeftSide - 1, 4, -1, 0, DIF_SEPARATOR, ''),
  {4} DlgItem(DI_CHECKBOX, cLeftSide, 5, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(MCreateSubDirs), Pointer(CreateSubDirs)),
  {5} DlgItem(DI_TEXT, cLeftSide - 1, cSizeY - 4, -1, 0, DIF_SEPARATOR, ''),
  {6} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnOk), Pointer(True)),
  {7} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnCancel))
  ], -1, -1, cSizeX, cSizeY, nil);
  FDestText := DestText;
end;

function TCopyDlg.Execute: Integer;
begin
  if inherited Execute = 6 then
  begin
{$IFDEF UNICODE}
    WStrLCopy(FDestText, PFarChar(ItemTextData[2]), MAX_PATH);
{$ELSE}
    StrLCopy(FDestText, PFarChar(ItemTextData[2]), MAX_PATH);
{$ENDIF}
    WriteRegBoolValue(cCreateSubDirs, FARAPI.RootKey + cDelim + cEOSBrowser,
      CreateSubDirs);
    Result := 1;
  end
  else
    Result := 0;
end;

end.
