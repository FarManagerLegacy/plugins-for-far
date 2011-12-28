unit ULang;

{$i CommonDirectives.inc}

interface

uses
{$IFDEF UNICODE}
  {$IFDEF Far3}
  Plugin3,
  {$ELSE}
  PluginW,
  {$ENDIF}
{$ELSE}
  Plugin,
{$ENDIF}
  UTypes;

type
  TLanguageID = (
    MPluginTitle,

    MInformation,
    MComfirmation,
    MError,
    MWarning,

    MPalelTitle,
    MCameraName,
    MVolumeName,

    MPathNotFound,
    MReading,
    
    MCopy,
    MCopyTo,
    MCopyItemsTo,
    MCopying,

    MMove,
    MMoveTo,
    MMoveItemsTo,
    MMoving,

    MCreateSubDirs,

    MScanning,
    MTotal,
    MFilesProcessed,

    MDeleteTitle,
    MDeleteFilesTitle,
    MDeleteFolder,
    MDeleteFile,
    MDeleteItems,

    MDeleteFolderTitle,
    MFolderDeleted,

    MOneOk,
    MTwoOk,
    MFiveOk,

    MInterruptTitle,
    MInterruptText,

    MFileAlreadyExists,
    MFileReadOnly,
    MNew,
    MExisting,
    MRememberChoice,

    MCannotDelFile,
    MCannotDelFolder,

    MBtnOk,
    MBtnOverwrite,
    MBtnAll,
    MBtnRetry,
    MBtnSkip,
    MBtnSkipAll,
    MBtnCancel,
    MBtnDelete,

    MConfigurationTitle,
    MAddToDriveMenu,
    MDriveMenuHotkey,
    MCommandLinePrefix,
    MLibraryPath,

    MInitError,
    MLibNotFound,
    MEdSdkError,
    MOneSessionAllowed,

    MCameraInfo,
    MSerialNumber,
    MFirmwareVersion,
    MBodyDateTime,
    MBatteryLevel,
    MACPower,
    MBatteryQuality,
    MNoDegradation,
    MSlightDegradation,
    MDegradedHalf,
    MDegradedLow,

    MVolumeInfo,
    MStorageType,
    MNoCard,
    M_CF,
    M_SD,

    MAccess,
    MReadOnly,
    MWriteOnly,
    MReadWrite,
    MAccessError,

    MMaxCapacity,
    MFreeSpace,

    MPropertyUnavailable
  );

function GetMsg(MsgId: TLanguageID): PFarChar;
function GetMsgStr(MsgId: TLanguageID): TFarString;

implementation

function GetMsg(MsgId: TLanguageID): PFarChar;
begin
  Result := UTypes.GetMsg(Integer(MsgId));
end;

function GetMsgStr(MsgId: TLanguageID): TFarString;
begin
  Result := UTypes.GetMsgStr(Integer(MsgId));
end;

end.
