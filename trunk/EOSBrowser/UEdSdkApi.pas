unit UEdSdkApi;

{$i CommonDirectives.inc}

interface

uses
  Windows, {$IFDEF UNICODE}PluginW,{$ELSE}Plugin,{$ENDIF} UTypes, EDSDKType, EDSDKError;

const
  cEdSdk = 'EDSDK.DLL';

type
  TEdsInitializeSDK = function ( ) : EdsError ; stdcall;
  TEdsTerminateSDK = function ( ) : EdsError ; stdcall; 
  TEdsRetain = function ( inRef : EdsBaseRef ) : EdsUInt32 ; stdcall; 
  TEdsRelease = function ( inRef : EdsBaseRef ) : EdsUInt32 ; stdcall; 
  TEdsGetChildCount = function ( inRef : EdsBaseRef;
                           var outCount : EdsUInt32 ) : EdsError ; stdcall; 
  TEdsGetChildAtIndex = function ( inRef : EdsBaseRef ;
                             inIndex : EdsInt32 ;
                             var outBaseRef : EdsBaseRef ) : EdsError ; stdcall; 
  TEdsGetParent = function ( inRef : EdsBaseRef;
                       var outParentRef : EdsBaseRef ) : EdsError ; stdcall; 
  TEdsGetPropertySize = function ( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             inParam : EdsInt32;
                             var outDataType : EdsDataType;
                             var outSize : EdsUInt32 ) : EdsError ; stdcall; 
  TEdsGetPropertyData = function ( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             inParam : EdsInt32;
                             inPropertySize : EdsUInt32;
//                             var outPropertyData : EdsUInt32 ) : EdsError ; stdcall; 
                             var outPropertyData : Pointer ) : EdsError ; stdcall;
  TEdsSetPropertyData = function ( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             inParam : EdsInt32;
                             inPropertySize : EdsUInt32;
                             InPropertyData : Pointer ) : EdsError; stdcall; 
  TEdsGetPropertyDesc = function ( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             var outPropertyDesc : EdsPropertyDesc ) : EdsError; stdcall; 
  TEdsGetCameraList = function ( var outCameraListRef : EdsCameraListRef ) : EdsError ; stdcall; 
  TEdsGetDeviceInfo = function ( inCameraRef : EdsCameraRef; var outDeviceInfo : EdsDeviceInfo) : EdsError ; stdcall ; 
  TEdsOpenSession = function ( inCameraRef : EdsCameraRef) : EdsError ; stdcall; 
  TEdsCloseSession = function ( inCameraRef : EdsCameraRef ) : EdsError ; stdcall; 
  TEdsSendCommand = function ( inCameraRef : EdsCameraRef;
                         inCommand   : EdsCameraCommand;
                         inParam : EdsInt32 ) : EdsError ; stdcall ; 
  TEdsSendStatusCommand = function ( inCameraRef     : EdsCameraRef;
                               inStatusCommand : EdsCameraStateCommand;
                               inParam : EdsInt32 ) : EdsError ; stdcall ; 
  TEdsSetCapacity = function ( inCameraRef : EdsCameraRef ; inCapacity : EdsCapacity ) : EdsError ; stdcall ; 
  TEdsGetVolumeInfo = function ( inVolumeRef : EdsVolumeRef; var outVolumeInfo : EdsVolumeInfo ) : EdsError ; stdcall ; 
  TEdsFormatVolume = function ( inVolumeRef : EdsVolumeRef ) : EdsError ; stdcall ; 
  TEdsGetDirectoryItemInfo = function ( inDirItemRef : EdsDirectoryItemRef ;
                                  var outDirItemInfo : EdsDirectoryItemInfo ) : EdsError ; stdcall ; 
  TEdsDeleteDirectoryItem = function ( inDirItemRef : EdsDirectoryItemRef ) : EdsError ; stdcall ; 
  TEdsDownload = function  ( inDirItemRef : EdsDirectoryItemRef;
                       inReadSize : EdsUInt32 ;
                       inDestStream : EdsStreamRef ) : EdsError ; stdcall ;
  TEdsDownloadComplete = function ( inDirItemRef : EdsDirectoryItemRef ) : EdsError ; stdcall ; 
  TEdsDownloadCancel = function ( inDirItemRef : EdsDirectoryItemRef ) : EdsError ; stdcall ; 
  TEdsDownloadThumbnail = function ( inDirItemRef : EdsDirectoryItemRef;
                               inDestStream : EdsStreamRef ) : EdsError ; stdcall ; 
  TEdsGetAttribute = function ( inDirItemRef : EdsDirectoryItemRef;
                          var outFileAttribute : EdsFileAttributes ) : EdsError ; stdcall ; 
  TEdsSetAttribute = function ( inDirItemRef : EdsDirectoryItemRef;
                          inFileAttribute : EdsFileAttributes ) : EdsError ; stdcall ; 
  TEdsCreateFileStream = function ( inFileName : PChar ;
                              inCreateDisposition : EdsFileCreateDisposition;
                              inDesiredAccess : EdsAccess ;
                              var outStream : EdsStreamRef ) : EdsError ; stdcall ; 
  TEdsCreateMemoryStream = function ( inBufferSize : EdsUInt32 ; var outStream : EdsStreamRef ) : EdsError ; stdcall ; 
  TEdsCreateFileStreamEx = function ( inFileName : PWideChar ;
                                inCreateDisposition : EdsFileCreateDisposition ;
                                inDesiredAccess : EdsAccess ;
                                var outStream : EdsStreamRef ) : EdsError ; stdcall ; 
  TEdsCreateMemoryStreamFromPointer = function ( inUserBuffer : Pointer;
                                           inBufferSize : EdsUInt32;
                                           var outStream : EdsStreamRef ) : EdsError ; stdcall ; 
  TEdsGetPointer = function ( inStream : EdsStreamRef;
                        var outPointer : Pointer ) : EdsError ; stdcall ; 
  TEdsRead = function ( inStreamRef : EdsStreamRef;
                  inReadSize : EdsUInt32;
                  var outBuffer : Pointer;
                  var outReadSize : EdsUInt32) : EdsError; stdcall; 
  TEdsWrite = function ( inStreamRef : EdsStreamRef;
                   inWriteSize : EdsUInt32;
                   const inBuffer : Pointer;
                   var outWrittenSize : EdsUInt32 ) : EdsError; stdcall; 
  TEdsSeek = function ( inStreamRef  : EdsStreamRef;
                  inSeekOffset : EdsUInt32;
                  inSeekOrigin : EdsSeekOrigin ) : EdsError; stdcall; 
  TEdsGetPosition = function ( inStreamRef : EdsStreamRef;
                         var outPosition : EdsUInt32 ) : EdsError; stdcall; 
  TEdsGetLength = function ( inStreamRef : EdsStreamRef;
                       var outLength : EdsUInt32 ) : EdsError; stdcall; 
  TEdsCopyData = function ( inSrcStreamRef : EdsStreamRef;
                      inWriteSize : EdsUInt32;
                      inDestStreamRef : EdsStreamRef ) : EdsError; stdcall; 
  TEdsSetProgressCallback = function ( inRef : EdsBaseRef;
                                 inProgressCallback : EdsProgressCallback;
                                 inProgressOption : EdsProgressOption;
                                 inContext : EdsUInt32 ) : EdsError; stdcall; 
  TEdsCreateImageRef = function ( inStreamRef : EdsStreamRef;
                            var outImageRef : EdsImageRef ) : EdsError; stdcall; 
  TEdsGetImageInfo = function ( inImageRef : EdsImageRef;
                          inImageSource : EdsImageSource;
                          var outImageInfo : EdsImageInfo ) : EdsError; stdcall; 
  TEdsGetImage = function ( inImageRef : EdsImageRef;
                      inImageSource : EdsImageSource;
                      inImageType : EdsTargetImageType;
                      inSrcRect : EdsRect;
                      inDstSize : EdsSize;
                      inStreamRef : EdsStreamRef ) : EdsError ; stdcall;
  TEdsSaveImage = function ( inImageRef : EdsImageRef;
                       inImageType : EdsTargetImageType;
                       inSaveSetting : EdsSaveImageSetting;
                       var outStreamRef : EdsStreamRef ): EdsError ; stdcall ; 
  TEdsCacheImage = function ( inImageRef : EdsImageRef; inUseCache : EdsBool ) : EdsError; stdcall; 
  TEdsReflectImageProperty = function ( inImageRef : EdsImageRef ) : EdsError; stdcall; 
  TEdsCreateEvfImageRef = function  ( inStreamRef : EdsStreamRef;
				 var outEvfImageRef : EdsEvfImageRef ) : EdsError; stdcall; 
  TEdsDownloadEvfImage = function  ( inCameraRef : EdsCameraRef;
			       inEvfImageRef : EdsEvfImageRef) : EdsError; stdcall; 
  TEdsSetCameraAddedHandler = function ( inCameraAddedHandler : EdsCameraAddedHandler;
                                   inContext : EdsUInt32 ) : EdsError; stdcall; 
  TEdsSetPropertyEventHandler = function (
            inCameraRef : EdsCameraRef;
            inEvent : EdsPropertyEvent;
            inPropertyEventHandler : Pointer;
            inContext : EdsUInt32 ) : EdsError; stdcall; 
  TEdsSetObjectEventHandler = function (
            inCameraRef : EdsCameraRef;
            inEvent : EdsObjectEvent;
            inObjectEventHandler : Pointer;
            inContext : EdsUInt32 ) : EdsError; stdcall; 
  TEdsSetCameraStateEventHandler = function (
            inCameraRef : EdsCameraRef;
            inEvent : EdsStateEvent;
            inStateEventHandler : Pointer;
            inContext : EdsUInt32 ) : EdsError; stdcall;
  TEdsGetEvent = function () : EdsError; stdcall;


var
  EdsInitializeSDK: TEdsInitializeSDK;
  EdsTerminateSDK: TEdsTerminateSDK;
  EdsRetain: TEdsRetain;
  EdsRelease: TEdsRelease;
  EdsGetChildCount: TEdsGetChildCount;
  EdsGetChildAtIndex: TEdsGetChildAtIndex;
  EdsGetParent: TEdsGetParent;
  EdsGetPropertySize: TEdsGetPropertySize;
  EdsGetPropertyData: TEdsGetPropertyData;
  EdsSetPropertyData: TEdsSetPropertyData;
  EdsGetPropertyDesc: TEdsGetPropertyDesc;
  EdsGetCameraList: TEdsGetCameraList;
  EdsGetDeviceInfo: TEdsGetDeviceInfo;
  EdsOpenSession: TEdsOpenSession;
  EdsCloseSession: TEdsCloseSession;
  EdsSendCommand: TEdsSendCommand;
  EdsSendStatusCommand: TEdsSendStatusCommand;
  EdsSetCapacity: TEdsSetCapacity;
  EdsGetVolumeInfo: TEdsGetVolumeInfo;
  EdsFormatVolume: TEdsFormatVolume;
  EdsGetDirectoryItemInfo: TEdsGetDirectoryItemInfo;
  EdsDeleteDirectoryItem: TEdsDeleteDirectoryItem;
  EdsDownload: TEdsDownload;
  EdsDownloadComplete: TEdsDownloadComplete;
  EdsDownloadCancel: TEdsDownloadCancel;
  EdsDownloadThumbnail: TEdsDownloadThumbnail;
  EdsGetAttribute: TEdsGetAttribute;
  EdsSetAttribute: TEdsSetAttribute;
  EdsCreateFileStream: TEdsCreateFileStream;
  EdsCreateMemoryStream: TEdsCreateMemoryStream;
  EdsCreateFileStreamEx: TEdsCreateFileStreamEx;
  EdsCreateMemoryStreamFromPointer: TEdsCreateMemoryStreamFromPointer;
  EdsGetPointer: TEdsGetPointer;
  EdsRead: TEdsRead;
  EdsWrite: TEdsWrite;
  EdsSeek: TEdsSeek;
  EdsGetPosition: TEdsGetPosition;
  EdsGetLength: TEdsGetLength;
  EdsCopyData: TEdsCopyData;
  EdsSetProgressCallback: TEdsSetProgressCallback;
  EdsCreateImageRef: TEdsCreateImageRef;
  EdsGetImageInfo: TEdsGetImageInfo;
  EdsGetImage: TEdsGetImage;
  EdsSaveImage: TEdsSaveImage;
  EdsCacheImage: TEdsCacheImage;
  EdsReflectImageProperty: TEdsReflectImageProperty;
  EdsCreateEvfImageRef: TEdsCreateEvfImageRef;
  EdsDownloadEvfImage: TEdsDownloadEvfImage;
  EdsSetCameraAddedHandler: TEdsSetCameraAddedHandler;
  EdsSetPropertyEventHandler: TEdsSetPropertyEventHandler;
  EdsSetObjectEventHandler: TEdsSetObjectEventHandler;
  EdsSetCameraStateEventHandler: TEdsSetCameraStateEventHandler;
  EdsGetEvent: TEdsGetEvent;

function InitEDSDK(const FileName: PFarChar): Boolean;
procedure FreeEDSDK;

implementation

var
  EDSDKLib: HINST;

function InitEDSDK(const FileName: PFarChar): Boolean;
begin
{$IFDEF UNICODE}
  EDSDKLib := LoadLibraryW(FileName);
{$ELSE}
  EDSDKLib := LoadLibraryA(FileName);
{$ENDIF}
  Result := EDSDKLib <> 0;
  if Result then
  begin
    EdsInitializeSDK := GetProcAddress(EDSDKLib, 'EdsInitializeSDK');
    EdsTerminateSDK := GetProcAddress(EDSDKLib, 'EdsTerminateSDK');
    EdsRetain := GetProcAddress(EDSDKLib, 'EdsRetain');
    EdsRelease := GetProcAddress(EDSDKLib, 'EdsRelease');
    EdsGetChildCount := GetProcAddress(EDSDKLib, 'EdsGetChildCount');
    EdsGetChildAtIndex := GetProcAddress(EDSDKLib, 'EdsGetChildAtIndex');
    EdsGetParent := GetProcAddress(EDSDKLib, 'EdsGetParent');
    EdsGetPropertySize := GetProcAddress(EDSDKLib, 'EdsGetPropertySize');
    EdsGetPropertyData := GetProcAddress(EDSDKLib, 'EdsGetPropertyData');
    EdsSetPropertyData := GetProcAddress(EDSDKLib, 'EdsSetPropertyData');
    EdsGetPropertyDesc := GetProcAddress(EDSDKLib, 'EdsGetPropertyDesc');
    EdsGetCameraList := GetProcAddress(EDSDKLib, 'EdsGetCameraList');
    EdsGetDeviceInfo := GetProcAddress(EDSDKLib, 'EdsGetDeviceInfo');
    EdsOpenSession := GetProcAddress(EDSDKLib, 'EdsOpenSession');
    EdsCloseSession := GetProcAddress(EDSDKLib, 'EdsCloseSession');
    EdsSendCommand := GetProcAddress(EDSDKLib, 'EdsSendCommand');
    EdsSendStatusCommand := GetProcAddress(EDSDKLib, 'EdsSendStatusCommand');
    EdsSetCapacity := GetProcAddress(EDSDKLib, 'EdsSetCapacity');
    EdsGetVolumeInfo := GetProcAddress(EDSDKLib, 'EdsGetVolumeInfo');
    EdsFormatVolume := GetProcAddress(EDSDKLib, 'EdsFormatVolume');
    EdsGetDirectoryItemInfo := GetProcAddress(EDSDKLib, 'EdsGetDirectoryItemInfo');
    EdsDeleteDirectoryItem := GetProcAddress(EDSDKLib, 'EdsDeleteDirectoryItem');
    EdsDownload := GetProcAddress(EDSDKLib, 'EdsDownload');
    EdsDownloadComplete := GetProcAddress(EDSDKLib, 'EdsDownloadComplete');
    EdsDownloadCancel := GetProcAddress(EDSDKLib, 'EdsDownloadCancel');
    EdsDownloadThumbnail := GetProcAddress(EDSDKLib, 'EdsDownloadThumbnail');
    EdsGetAttribute := GetProcAddress(EDSDKLib, 'EdsGetAttribute');
    EdsSetAttribute := GetProcAddress(EDSDKLib, 'EdsSetAttribute');
    EdsCreateFileStream := GetProcAddress(EDSDKLib, 'EdsCreateFileStream');
    EdsCreateMemoryStream := GetProcAddress(EDSDKLib, 'EdsCreateMemoryStream');
    EdsCreateFileStreamEx := GetProcAddress(EDSDKLib, 'EdsCreateFileStreamEx');
    EdsCreateMemoryStreamFromPointer := GetProcAddress(EDSDKLib, 'EdsCreateMemoryStreamFromPointer');
    EdsGetPointer := GetProcAddress(EDSDKLib, 'EdsGetPointer');
    EdsRead := GetProcAddress(EDSDKLib, 'EdsRead');
    EdsWrite := GetProcAddress(EDSDKLib, 'EdsWrite');
    EdsSeek := GetProcAddress(EDSDKLib, 'EdsSeek');
    EdsGetPosition := GetProcAddress(EDSDKLib, 'EdsGetPosition');
    EdsGetLength := GetProcAddress(EDSDKLib, 'EdsGetLength');
    EdsCopyData := GetProcAddress(EDSDKLib, 'EdsCopyData');
    EdsSetProgressCallback := GetProcAddress(EDSDKLib, 'EdsSetProgressCallback');
    EdsCreateImageRef := GetProcAddress(EDSDKLib, 'EdsCreateImageRef');
    EdsGetImageInfo := GetProcAddress(EDSDKLib, 'EdsGetImageInfo');
    EdsGetImage := GetProcAddress(EDSDKLib, 'EdsGetImage');
    EdsSaveImage := GetProcAddress(EDSDKLib, 'EdsSaveImage');
    EdsCacheImage := GetProcAddress(EDSDKLib, 'EdsCacheImage');
    EdsReflectImageProperty := GetProcAddress(EDSDKLib, 'EdsReflectImageProperty');
    EdsCreateEvfImageRef := GetProcAddress(EDSDKLib, 'EdsCreateEvfImageRef');
    EdsDownloadEvfImage := GetProcAddress(EDSDKLib, 'EdsDownloadEvfImage');
    EdsSetCameraAddedHandler := GetProcAddress(EDSDKLib, 'EdsSetCameraAddedHandler');
    EdsSetPropertyEventHandler := GetProcAddress(EDSDKLib, 'EdsSetPropertyEventHandler');
    EdsSetObjectEventHandler := GetProcAddress(EDSDKLib, 'EdsSetObjectEventHandler');
    EdsSetCameraStateEventHandler := GetProcAddress(EDSDKLib, 'EdsSetCameraStateEventHandler');
    EdsGetEvent := GetProcAddress(EDSDKLib, 'EdsGetEvent');

  end;
end;

procedure FreeEDSDK;
begin
  if EDSDKLib <> 0 then
  begin
    FreeLibrary(EDSDKLib);
    EDSDKLib := 0;
  end;
end;

end.
