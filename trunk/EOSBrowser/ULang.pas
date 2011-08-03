unit ULang;

{$i CommonDirectives.inc}

interface

uses
{$IFDEF UNICODE}
  PluginW,
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
    
    MCopy,
    MCopyTo,
    MCopyItemsTo,
    MCopying,

    MMove,
    MMoveTo,
    MMoveItemsTo,
    MMoving,

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

    MInterruptedTitle,
    MInterruptedText,

    MFileAlreadyExists,
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
    MEdSdkError
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
