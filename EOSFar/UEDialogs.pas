unit UEDialogs;

{$i CommonDirectives.inc}

interface

{$DEFINE USE_ESDK}
{$DEFINE USE_DYNLOAD}

uses
  Windows,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  plugin,
{$ENDIF}
{$IFDEF USE_ESDK}
  {$IFDEF USE_DYNLOAD}
  UEdSdkApi,
  {$ELSE}
  EDSDKApi,
  {$ENDIF}
  EDSDKError,
  EDSDKType,
{$ENDIF}
  UTypes,
  UUtils,
  UDialogs,
  ULang;

type
  TOverDlg = class(TSimpleFarDialog)
  public
    constructor Create(const FileName: TFarString;
      dirItem: EdsDirectoryItemRef; dirInfo: PEdsDirectoryItemInfo);
    function Execute: Integer; override;
  end;

  TConfigDlg = class(TSimpleFarDialog)
  public
    constructor Create;
    function Execute: Integer; override;
  end;

  TConfigData = record
    AddToDiskMenu: Boolean;
    DiskMenuNumberStr: TFarString;
    DiskMenuNumber: Integer;
    Prefix: TFarString;
    LibraryPath: TFarString;
  end;

procedure LoadConfig;
procedure SaveConfig;

var
  ConfigData: TConfigData;

implementation

uses
  UCanon, SysUtils;

{ TOverDlg }

constructor TOverDlg.Create(const FileName: TFarString;
  dirItem: EdsDirectoryItemRef; dirInfo: PEdsDirectoryItemInfo);
  function GetFileText(Width: Integer; MsgId: TLanguageID; filetime: TFileTime;
    filesize: Cardinal): TFarString;
  const
    cFmt = '%d %.2d.%.2d.%.4d %.2d:%.2d:%.2d';
  var
    sysTime: TSystemTime;
    i, l: Integer;
  begin
    FileTimeToSystemTime(filetime, sysTime);
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
        DIF_CENTERTEXT, PFarChar(MFileAlreadyExists)),
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
  cEosFar = 'EOSFar';
  cAddToDiskMenu = 'AddToDiskMenu';
  cDiskMenuNumber = 'DiskMenuNumber';
  cPrefix = 'Prefix';
  cLibraryPath = 'LibraryPath';

procedure LoadConfig;
var
  SubKey: TFarString;
begin
  SubKey := FARAPI.RootKey + cDelim + cEosFar;
  with ConfigData do
  begin
    AddToDiskMenu := ReadRegBoolValue(cAddToDiskMenu, SubKey, True);
    DiskMenuNumberStr := ReadRegStringValue(cDiskMenuNumber, SubKey, '0');
    DiskMenuNumber := FSF.atoi(PFarChar(DiskMenuNumberStr));
    Prefix := ReadRegStringValue(cPrefix, SubKey, cEosPrefix);
    LibraryPath := ReadRegStringValue(cLibraryPath, SubKey, '');
  end;
end;

procedure SaveConfig;
var
  SubKey: TFarString;
begin
  SubKey := FARAPI.RootKey + cDelim + cEosFar;
  with ConfigData do
  begin
    WriteRegBoolValue(cAddToDiskMenu, SubKey, AddToDiskMenu);
    WriteRegStringValue(cDiskMenuNumber, SubKey, DiskMenuNumberStr);
    WriteRegStringValue(cPrefix, SubKey, Prefix);
    if LibraryPath <> '' then
      LibraryPath := IncludeTrailingPathDelimiter(LibraryPath);
    WriteRegStringValue(cLibraryPath, SubKey, LibraryPath);
  end;
end;

constructor TConfigDlg.Create;
const
  cSizeX = 74;
  cSizeY = 13;
  cLeftSide = 5;
  cSharp: PFarChar = '#';
begin
  with ConfigData do
    inherited Create([
  {0} DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY, 0,
        PFarChar(MConfigurationTitle)),
  {1} DlgItem(DI_CHECKBOX, cLeftSide, 2, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(MAddToDriveMenu), Pointer(AddToDiskMenu)),
  {2} DlgItem(DI_FIXEDIT, cLeftSide + 2, 3, 1, -1, DIF_MASKEDIT,
        PFarChar(DiskMenuNumberStr), cSharp),
  {3} DlgItem(DI_TEXT, cLeftSide + 4, 3, cSizeX - cLeftSide * 2 - 3, -1, 0,
        PFarChar(MDriveMenuHotkey)),
  {4} DlgItem(DI_TEXT, cLeftSide - 1, 4, -1, 0, DIF_SEPARATOR, ''),
  {5} DlgItem(DI_TEXT, cLeftSide, 5, cSizeX - cLeftSide * 2 - 4, -1, 0,
        PFarChar(MCommandLinePrefix)),
  {6} DlgItem(DI_EDIT, cLeftSide, 6, cSizeX - cLeftSide * 2, -1, 0,
        PFarChar(Prefix)),
  {7} DlgItem(DI_TEXT, cLeftSide, 7, cSizeX - cLeftSide * 2 - 4, -1, 0,
        PFarChar(MLibraryPath)),
  {8} DlgItem(DI_EDIT, cLeftSide, 8, cSizeX - cLeftSide * 2, -1, DIF_EDITPATH,
        PFarChar(LibraryPath)),
  {9} DlgItem(DI_TEXT, cLeftSide - 1, cSizeY - 4, -1, 0, DIF_SEPARATOR, ''),
 {10} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnOk), Pointer(True)),
 {11} DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP,
        PFarChar(MBtnCancel))
      ], -1, -1, cSizeX, cSizeY, nil);
end;

function TConfigDlg.Execute: Integer;
begin
  if inherited Execute = 10 then
  begin
    with ConfigData do
    begin
      AddToDiskMenu := ItemCheckData[1];
      DiskMenuNumberStr := ItemTextData[2];
      DiskMenuNumber := FSF.atoi(PFarChar(DiskMenuNumberStr));
      Prefix := ItemTextData[6];
      LibraryPath := ItemTextData[8];
    end;
    SaveConfig;
    Result := 1;
  end
  else
    Result := 0;
end;

end.
