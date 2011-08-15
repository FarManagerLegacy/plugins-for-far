{******************************************************************************
*                                                                             *
*   PROJECT : EOS Digital Software Development Kit EDSDK                      *
*      NAME : EDSDKType.pas                                                   *
*                                                                             *
*   Description: This is the Sample code to show the usage of EDSDK.          *
*                                                                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*   Written and developed by Camera Design Dept.53                            *
*   Copyright Canon Inc. 2006 All Rights Reserved                             *
*                                                                             *
*******************************************************************************
*   File Update Information:                                                  *
*     DATE      Identify    Comment                                           *
*   -----------------------------------------------------------------------   *
*   06-03-22    F-001        create first version.                            *
*                                                                             *
******************************************************************************}
unit EDSDKType;

interface

//const
//  TRUE  = 1;
//  FALSE = 0;

const EDS_MAX_NAME = 256;
const EDS_TRANSFER_BLOCK_SIZE = 512;
     { When the DirectoryItem is downloaded or uploaded separately for the plural
       block, The size of the block other than the terminal block should be
       assumed to be a multiple in 512 bytes.
     }

type
  { --------------- BASIC TYPE ------------ }
  EdsBool   = Integer;

  EdsChar   = AnsiChar;
  EdsInt8   = Shortint;
  EdsUInt8  = Byte;
  EdsInt16  = Smallint;
  EdsUInt16 = Word;
  EdsInt32  = Integer;
  EdsUInt32 = Cardinal;
  EdsInt64  = Int64;
  EdsUInt64 = Int64;
  EdsFloat  = single;
  EdsDouble = double;

  { ------------- ERROR TYPES ----------- }
  EdsError = EdsUInt32;


{ -----------------------------------------------------------------------------
  EdsBaseRef
              A EdsBaseRef is a reference to an object.
  ------------------------------------------------------------------------------}
  EdsObject = Pointer;
  EdsBaseRef = EdsObject;               // Baseic refernce

  EdsCameraListRef    = EdsBaseRef;     // Reference to a camera list
  PEdsCameraListRef   = ^EdsCameraListRef;

  EdsCameraRef        = EdsBaseRef;     // Reference to a camera

  EdsVolumeRef        = EdsBaseRef;     // Reference to a volume
  EdsDirectoryItemRef = EdsBaseRef;     // Reference to a directory item

  PEdsDirectoryItemRef = ^EdsDirectoryItemRef;

  EdsStreamRef        = EdsBaseRef;     // Reference to a stream
  EdsImageRef         = EdsStreamRef;   // Reference to a image
  EdsEvfImageRef      = EdsBaseRef;   // Reference to a image


{ -----------------------------------------------------------------------------
  Data Type
  ----------------------------------------------------------------------------- }
  type EdsDataType = EdsUInt32;
  type EdsEnumDataType = (                                      {* enumeration *}
                    kEdsDataType_Unknown        = 0,
                    kEdsDataType_Bool           = 1,
                    kEdsDataType_String         = 2,
                    kEdsDataType_Int8           = 3,
                    kEdsDataType_Int16          = 4,
                    kEdsDataType_UInt8          = 6,
                    kEdsDataType_UInt16         = 7,
                    kEdsDataType_Int32          = 8,
                    kEdsDataType_UInt32         = 9,
                    kEdsDataType_Int64          = 10,
                    kEdsDataType_UInt64         = 11,
                    kEdsDataType_Float          = 12,
                    kEdsDataType_Double         = 13,
                    kEdsDataType_ByteBlock      = 14,

                    kEdsDataType_Rational       = 20,
                    kEdsDataType_Point          = 21,
                    kEdsDataType_Rect           = 22,
                    kEdsDataType_Time           = 23,

                    kEdsDataType_Bool_Array     = 30,
                    kEdsDataType_Int8_Array     = 31,
                    kEdsDataType_Int16_Array    = 32,
                    kEdsDataType_Int32_Array    = 33,
                    kEdsDataType_UInt8_Array    = 34,
                    kEdsDataType_UInt16_Array   = 35,
                    kEdsDataType_UInt32_Array   = 36,
                    kEdsDataType_Rational_Array = 37,

                    kEdsDataType_FocusInfo      = 101,
                    kEdsDataType_PictureStyleDesc

  );

{ -----------------------------------------------------------------------------
  Property ID Definition
  -----------------------------------------------------------------------------}
  type EdsPropertyID = EdsUInt32;
  const
    kEdsPropID_Unknown              = $0000FFFF;

    { Camera Setting Property }
    kEdsPropID_ProductName          = $00000002;     { Product name }
    kEdsPropID_BodyID               = $00000003;     { bodyID }
    kEdsPropID_OwnerName            = $00000004;     { owner name }
    kEdsPropID_MakerName            = $00000005;     { maker name }
    kEdsPropID_DateTime             = $00000006;     { system time (Camera) }
    kEdsPropID_FirmwareVersion      = $00000007;     { Firmware Version }
    kEdsPropID_BatteryLevel         = $00000008;     { Battery status 0- 100% or 'AC' }

    kEdsPropID_CFn                  = $00000009;     { Custom Function settings }
    kEdsPropID_PFn                  = $0000000A;     { Personal Function settings }

    kEdsPropID_SaveTo               = $0000000B;
	kEdsPropID_CurrentStorage       = $0000000c;
	kEdsPropID_CurrentFolder        = $0000000d;
	kEdsPropID_MyMenu		        = $0000000e;

        kEdsPropID_BodyIDEx         = $00000015;     { Product serial number }


    kEdsPropID_UserWhiteBalanceData = $00000201;
    kEdsPropID_UserToneCurveData    = $00000202;
    kEdsPropID_UserPictureStyleData = $00000203;


	kEdsPropID_BatteryQuality         = $00000010;
	kEdsPropID_BatteryShutterCount    = $00000011;
	kEdsPropID_BatteryCalibration     = $00000012;
	kEdsPropID_BatteryName            = $00000013;

	kEdsPropID_HDDirectoryStructure   = $00000020;
	kEdsPropID_WFTStatus              = $00000021;

	kEdsPropID_QuickReviewTime		  = $0000000f;
	kEdsPropID_ShutterCounter         = $00000022;
	kEdsPropID_PhotoStudioMode        = $00000030;
	kEdsPropID_SpecialOption          = $00000031;


	kEdsPropID_DataInputTransmission  = $00000050;
	kEdsPropID_Wft_ProfileLockConfig  = $00000052;
	kEdsPropID_Wft_TransmissionConfig = $00000053;
	kEdsPropID_Wft_TCPIPConfig        = $00000054;
	kEdsPropID_Wft_FTPConfig          = $00000055;
	kEdsPropID_Wft_WirelessConfig     = $00000056;
	kEdsPropID_Wft_WiredConfig        = $00000057;
	kEdsPropID_Wft_SettingsName       = $00000058;
	kEdsPropID_Wft_Info               = $00000059;


    { Image Property }
    kEdsPropID_ImageQuality         = $00000100;     { recording image type ; RAW or JPEG }
    kEdsPropID_JpegQuality          = $00000101;     { Compresison rate of Jpeg( 1 to 10 ) }
    kEdsPropID_Orientation          = $00000102;     { The image orientation }
    kEdsPropID_ICCProfile           = $00000103;     { ICC Profile data }
    kEdsPropID_FocusInfo            = $00000104;     { focus Info }

    kEdsPropID_DigitalExposure      = $00000105;
    kEdsPropID_WhiteBalance         = $00000106;     { light source of WB mode }
    kEdsPropID_ColorTemperature     = $00000107;     { Color Temperature setting }
    kEdsPropID_WhiteBalanceShift    = $00000108;
    kEdsPropID_Contrast             = $00000109;
    kEdsPropID_ColorSaturation      = $0000010A;
    kEdsPropID_ColorTone            = $0000010B;
    kEdsPropID_Sharpness            = $0000010C;
    kEdsPropID_ColorSpace           = $0000010D;
    kEdsPropID_ToneCurve            = $0000010E;

    kEdsPropID_PhotoEffect          = $0000010F;
    kEdsPropID_FilterEffect         = $00000110;
    kEdsPropID_ToningEffect         = $00000111;

    kEdsPropID_ParameterSet         = $00000112;
    kEdsPropID_ColorMatrix          = $00000113;
    kEdsPropID_PictureStyle         = $00000114;
    kEdsPropID_PictureStyleDesc     = $00000115;

    kEdsPropID_PictureStyleCaption  = $00000200;     { PC Setting of PictureStyle at capture }
	kEdsPropID_CustomWBCaption      = $00000204;
    
    { Development Property }
    kEdsPropID_Linear               = $00000300;     { linear On / OFF }
    kEdsPropID_ClickWBPoint         = $00000301;     { coordinates of click for WB }
    kEdsPropID_WBCoeffs             = $00000302;     { WB Control Value }


  	{ Image GPS Properties }
	kEdsPropID_GPSVersionID          = $00000800;
	kEdsPropID_GPSLatitudeRef        = $00000801;
	kEdsPropID_GPSLatitude           = $00000802;
	kEdsPropID_GPSLongitudeRef       = $00000803;
	kEdsPropID_GPSLongitude          = $00000804;
	kEdsPropID_GPSAltitudeRef        = $00000805;
	kEdsPropID_GPSAltitude           = $00000806;
	kEdsPropID_GPSTimeStamp          = $00000807;
	kEdsPropID_GPSSatellites         = $00000808;
	kEdsPropID_GPSMapDatum           = $00000812;
	kEdsPropID_GPSDateStamp          = $0000081D;
	

    { Property Mask }
    kEdsPropID_AtCapture_Flag	    = $80000000;     { Flag for getting property at capture }

    { Capture Property }
    kEdsPropID_AEMode               = $00000400;     { Shooting mode }
    kEdsPropID_DriveMode            = $00000401;     { Drive mode }
    kEdsPropID_ISOSpeed             = $00000402;     { ISO sensitivety }
    kEdsPropID_MeteringMode         = $00000403;     { Metering mode }
    kEdsPropID_AFMode               = $00000404;     { AF mode }
    kEdsPropID_Av                   = $00000405;     { Aperture value }
    kEdsPropID_Tv                   = $00000406;     { Shutter speed  }
    kEdsPropID_ExposureCompensation = $00000407;     { Exposure compensation }
    kEdsPropID_FlashCompensation    = $00000408;
    kEdsPropID_FocalLength          = $00000409;

    kEdsPropID_AvailableShots       = $0000040A;     { Number of available shots }

    kEdsPropID_Bracket              = $0000040B;     { ISO bracket, AEB or FEB }
    kEdsPropID_WhiteBalanceBracket  = $0000040C;     { Whitebalance bracket }

    kEdsPropID_LensName             = $0000040D;
    kEdsPropID_AEBracket            = $0000040E;     { AutoExposure Bracket Value }
    kEdsPropID_FEBracket            = $0000040F;     { FlashExposure Bracket Value }
    kEdsPropID_ISOBracket           = $00000410;     { ISO Bracket Value }

    kEdsPropID_NoiseReduction       = $00000411;

    kEdsPropID_FlashOn              = $00000412;
    kEdsPropID_RedEye               = $00000413;
    kEdsPropID_FlashMode            = $00000414;
	kEdsPropID_TempStatus           = $00000415;
	kEdsPropID_LensStatus           = $00000416;

	{ EVF Properties }
	kEdsPropID_Evf_OutputDevice        = $00000500;
	kEdsPropID_Evf_Mode                = $00000501;
	kEdsPropID_Evf_WhiteBalance        = $00000502;
	kEdsPropID_Evf_ColorTemperature    = $00000503;
	kEdsPropID_Evf_DepthOfFieldPreview = $00000504;
	kEdsPropID_Evf_Sharpness		   = $00000505;
	kEdsPropID_Evf_ClickWBCoeffs       = $00000506;

	{ EVF IMAGE DATA Properties }
	kEdsPropID_Evf_Zoom                = $00000507;
	kEdsPropID_Evf_ZoomPosition        = $00000508;
	kEdsPropID_Evf_FocusAid            = $00000509;
	kEdsPropID_Evf_Histogram           = $0000050A;
	kEdsPropID_Evf_ImagePosition       = $0000050B;
	kEdsPropID_Evf_HistogramStatus     = $0000050C;

{-----------------------------------------------------------------------------
  Camera Commands --- Send command and State command
------------------------------------------------------------------------------}
  type
    EdsCameraCommand = EdsUInt32;
    EdsCameraStateCommand = EdsUInt32;

{ -------------------------
  Send Commands
  ------------------------ }
  const
    kEdsCameraCommand_TakePicture         = $00000000;  { Requests the camera to shoot }
    kEdsCameraCommand_ExtendShutDownTimer = $00000001;  { Requests to extend the time for the auto shut-off timer. }
    kEdsCameraCommand_PassThrough         = $00001000;  { Sends specific commands to a camera. Only internal use. }


{ -------------------------
  Camera State Command
  ------------------------ }
  const
    kEdsCameraState_UILock              = $00000000;    { Locks the UI }
    kEdsCameraState_UIUnLock            = $00000001;    { Unlocks the UI }
    kEdsCameraState_EnterDirectTransfer = $00000002;    { Puts the camera in direct transfer mode }
    kEdsCameraState_ExitDirectTransfer  = $00000003;    { Ends direct transfer mode }



{ -----------------------------------------------------------------------------
  Camera Events
  ----------------------------------------------------------------------------- }
  type EdsPropertyEvent = EdsUInt32;
  const
    { Notifies all property events. }
    kEdsPropertyEvent_All = $00000100;

    { Notifies that a camera property value has been changed. 
      The changed property can be retrieved from event data. 
      The changed value can be retrieved by means of EdsGetPropertyData. 
      In the case of type 1 protocol standard cameras, 
      notification of changed properties can only be issued for custom functions (CFn). 
      If the property type is 0x0000FFFF, the changed property cannot be identified. 
      Thus, retrieve all required properties repeatedly. }
    kEdsPropertyEvent_PropertyChanged = $00000101;

    { Notifies of changes in the list of camera properties with configurable values. 
      The list of configurable values for property IDs indicated in event data 
      can be retrieved by means of EdsGetPropertyDesc. 
      For type 1 protocol standard cameras, the property ID is identified as "Unknown"
      during notification. 
      Thus, you must retrieve a list of configurable values for all properties and
      retrieve the property values repeatedly. 
      ( For details on properties for which you can retrieve a list of configurable
        properties, see the description of EdsGetPropertyDesc ). }
    kEdsPropertyEvent_PropertyDescChanged = $00000102;


{ -----------------------------------------------------------------------------
  Object Events
 ----------------------------------------------------------------------------- }
  type EdsObjectEvent = EdsUInt32;
  const
    { Notifies all object events. }
    kEdsObjectEvent_ALL = $00000200;

    { Notifies that the volume object (memory card) state (VolumeInfo)
      has been changed. 
      Changed objects are indicated by event data. 
      The changed value can be retrieved by means of EdsGetVolumeInfo. 
      Notification of this event is not issued for type 1 protocol standard cameras. }
    kEdsObjectEvent_VolumeInfoChanged   = $00000201;

    { Notifies if the designated volume on a camera has been formatted.
      If notification of this event is received, get sub-items of the designated
      volume again as needed. 
      Changed volume objects can be retrieved from event data. 
      Objects cannot be identified on cameras earlier than the D30
      if files are added or deleted. 
      Thus, these events are subject to notification. }
    kEdsObjectEvent_VolumeUpdateItems   = $00000202;

    { Notifies if many images are deleted in a designated folder on a camera.
      If notification of this event is received, get sub-items of the designated
      folder again as needed. 
      Changed folders (specifically, directory item objects) can be retrieved
      from event data. }
    kEdsObjectEvent_FolderUpdateItems   = $00000203;

    { Notifies of the creation of objects such as new folders or files
      on a camera compact flash card or the like. 
      This event is generated if the camera has been set to store captured
      images simultaneously on the camera and a computer,
      for example, but not if the camera is set to store images
      on the computer alone. 
      Newly created objects are indicated by event data. 
      Because objects are not indicated for type 1 protocol standard cameras,
      (that is, objects are indicated as NULL),
      you must again retrieve child objects under the camera object to 
      identify the new objects. }
    kEdsObjectEvent_DirItemCreated      = $00000204;

    { Notifies of the deletion of objects such as folders or files on a camera
      compact flash card or the like. 
      Deleted objects are indicated in event data. 
      Because objects are not indicated for type 1 protocol standard cameras, 
      you must again retrieve child objects under the camera object to
      identify deleted objects. }
    kEdsObjectEvent_DirItemRemoved      = $00000205;

    { Notifies that information of DirItem objects has been changed.
      Changed objects are indicated by event data. 
      The changed value can be retrieved by means of EdsGetDirectoryItemInfo. 
      Notification of this event is not issued for type 1 protocol standard cameras. }
    kEdsObjectEvent_DirItemInfoChanged  = $00000206;

    { Notifies that header information has been updated, as for rotation information
      of image files on the camera. 
      If this event is received, get the file header information again, as needed.
      This function is for type 2 protocol standard cameras only. }
    kEdsObjectEvent_DirItemContentChanged = $00000207;

    { Notifies that there are objects on a camera to be transferred to a computer. 
      This event is generated after remote release from a computer or local release
      from a camera. 
      If this event is received, objects indicated in the event data must be downloaded.
      Furthermore, if the application does not require the objects, instead
      of downloading them,
      execute EdsDownloadCancel and release resources held by the camera. 
      The order of downloading from type 1 protocol standard cameras must be the order
      in which the events are received. }
    kEdsObjectEvent_DirItemRequestTransfer = $00000208;

    { Notifies if the camera's direct transfer button is pressed. 
      If this event is received, objects indicated in the event data must be downloaded. 
      Furthermore, if the application does not require the objects, instead of
      downloading them, 
      execute EdsDownloadCancel and release resources held by the camera.
      Notification of this event is not issued for type 1 protocol standard cameras. }
    kEdsObjectEvent_DirItemRequestTransferDT = $00000209;

    { Notifies of requests from a camera to cancel object transfer 
      if the button to cancel direct transfer is pressed on the camera. 
      If the parameter is 0, it means that cancellation of transfer is requested for
      objects still not downloaded,
      with these objects indicated by kEdsObjectEvent_DirItemRequestTransferDT. 
      Notification of this event is not issued for type 1 protocol standard cameras. }
    kEdsObjectEvent_DirItemCancelTransferDT = $0000020A;


	kEdsObjectEvent_VolumeAdded                 = $0000020c;
	kEdsObjectEvent_VolumeRemoved               = $0000020d;

{ -----------------------------------------------------------------------------
  State Events
 ----------------------------------------------------------------------------- }
  type EdsStateEvent = EdsUInt32;
  const
    { Notifies all state events. }
    kEdsStateEvent_ALL                  = $00000300;

    { Indicates that a camera is no longer connected to a computer, 
      whether it was disconnected by unplugging a cord, opening
      the compact flash compartment, 
      turning the camera off, auto shut-off, or by other means. }
    kEdsStateEvent_ShutDown             = $00000301;

    { Notifies of whether or not there are objects waiting to be transferred to
      a host computer.  This is useful when ensuring all shot images have been
      transferred when the application is closed. 
      Notification of this event is not issued for type 1 protocol standard cameras. }
    kEdsStateEvent_JobStatusChanged     = $00000302;

    { Notifies that the camera will shut down after a specific period. 
      Generated only if auto shut-off is set.
      Exactly when notification is issued (that is, the number of
      seconds until shutdown) varies depending on the camera model. 
      To continue operation without having the camera shut down,
      use EdsSendCommand to extend the auto shut-off timer.
      The time in seconds until the camera shuts down is returned
      as the initial value. }
    kEdsStateEvent_WillSoonShutDown     = $00000303;

    { As the counterpart event to kEdsStateEvent_WillSoonShutDown,
      this event notifies of updates to the number of seconds until
      a camera shuts down. 
      After the update, the period until shutdown is model-dependent. }
    kEdsCameraEvent_ShutDownTimerUpdate = $00000304;

    { Notifies that a requested release has failed, due to focus
      failure or similar factors. }
    kEdsCameraEvent_CaptureError        = $00000305;

    { Notifies of internal SDK errors. 
      If this error event is received, the issuing device will probably
      not be able to continue working properly, so cancel the remote connection. }
    kEdsCameraEvent_InternalError       = $00000306;


	kEdsStateEvent_AfResult                     = $00000309;

	kEdsStateEvent_BulbExposureTime             = $00000310;

{-----------------------------------------------------------------------------
 Stream Seek Origins
----------------------------------------------------------------------------- }
  type EdsSeekOrigin = (
        kEdsSeek_Cur = 0 ,  { Seek from Current Point }
        kEdsSeek_Begin ,    { Seek from Start Point }
        kEdsSeek_End        { Seek from End Point }
  );

{-----------------------------------------------------------------------------
 File and Propaties Access
-----------------------------------------------------------------------------}
  type EdsAccess = EdsUInt32;
  const
        kEdsAccess_Read  = 0;     { Enables subsequent open operations on the object to
                                    request read access. }
        kEdsAccess_Write = 1;     { Enables subsequent open operations on the object to
                                    request write access. }
        kEdsAccess_ReadWrite = 2; { Enables subsequent open operations on the object to
                                    request read and write access. }
        kEdsAccess_Error = $FFFFFFFF;



{-----------------------------------------------------------------------------
 File Create Disposition
-----------------------------------------------------------------------------}
  type EdsFileCreateDisposition = (
    kEdsFileCreateDisposition_CreateNew = 0,        { Creates a new file. The function fails
                                                      if the specified file already exists. }

    kEdsFileCreateDisposition_CreateAlways,         { Creates a new file. If the file exists,
                                                      the function overwrites the file and clears
                                                      the existing attributes. }

    kEdsFileCreateDisposition_OpenExisting,         { Opens the file. The function fails
                                                      if the file does not exist. }

    kEdsFileCreateDisposition_OpenAlways,           { Opens the file, if it exists.
                                                      If the file does not exist,
                                                      the function creates the file. }

    kEdsFileCreateDisposition_TruncateExsisting     { Opens the file. Once opened, the file is
                                                      truncated so that its size is zero bytes.
                                                      The function fails if the file does not exist. }
  );

{-----------------------------------------------------------------------------
 Target Image Type
-----------------------------------------------------------------------------}
  type EdsImageType = (
    kEdsImageType_Unknown           = $00000000,    { Folder, for unknown image type }
    kEdsImageType_Jpeg              = $00000001,    { JPEG }
    kEdsImageType_CRW               = $00000002,    { .CRW }
    kEdsImageType_RAW               = $00000004,    { 1D, 1Ds raw-tif }
    kEdsImageType_CR2               = $00000006     { .CR2 }
  );

  type EdsTargetImageType = (
    kEdsTargetImageType_Unkown      = $00000000,    { Folder, for unknown image type }
    kEdsTargetImageType_Jpeg        = $00000001,    { JPEG }
    kEdsTargetImageType_TIFF        = $00000007,    { 8bit TIFF }
    kEdsTargetImageType_TIFF16      = $00000008,    { 16bit TIFF }
    kEdsTargetImageType_RGB         = $00000009,    { 8bit RGB chunky }
    kEdsTargetImageType_RGB16       = $0000000A     { 16bit RGB chunky }

  );

  type EdsImageSize = EdsUInt32;
  const
    kEdsImageSize_Large         = 0;
    kEdsImageSize_Middle        = 1;
    kEdsImageSize_Small         = 2;
    kEdsImageSize_Middle1       = 5;
    kEdsImageSize_Middle2       = 6;
    kEdsImageSize_Unknown       = $FFFFFFFF;


  type EdsCompressQuality = EdsUInt32;
  const
    kEdsCompressQuality_Normal    = 2;
    kEdsCompressQuality_Fine      = 3;
    kEdsCompressQuality_Lossless  = 4;
    kEdsCompressQuality_SuperFine = 5;
    kEdsCompressQuality_Unknown   = $FFFFFFFF;

{-----------------------------------------------------------------------------
 Image Source

    kEdsImageSrc_FullView
        Name : Full size image
        Size : full size of the target camera
        Image type : JPG, TIFF, RAW

    kEdsImageSrc_Thumbnail
        Name : Thumbnail image
        Size : DCF size (160 x 120 pixel) of the target camera
        Image type : JPG, TIFF, RAW
    kEdsImageSrc_Preview
        Name : Preview display image
        Size :
        Image type : JPG, TIFF, RAW

    kEdsImageSrc_RAWThumbnail
        Name : RAW Thumbnail image
        Size :
        Image type : RAW

    kEdsImageSrc_RAWFullView
        Name : RAW full size image
        Size :
        Image type : RAW

-----------------------------------------------------------------------------}
  type EdsImageSource = Integer;
  const
    kEdsImageSrc_FullView  = 0;
    kEdsImageSrc_Thumbnail = 1;
    kEdsImageSrc_Preview   = 2;
    kEdsImageSrc_RAWThumbnail = 3;
    kEdsImageSrc_RAWFullView  = 4;

{-----------------------------------------------------------------------------
 Progress Option
-----------------------------------------------------------------------------}
  type EdsProgressOption = (
    kEdsProgressOption_NoReport,        { no callback.                   }
    kEdsProgressOption_Done,            { performs callback only at once }
                                        { at the time of an end.         }
    kEdsProgressOption_Periodically     { performs callback periodically }
  );

{-----------------------------------------------------------------------------
 File Attribute
-----------------------------------------------------------------------------}
  type EdsFileAttributes = (
    kEdsFileAttribute_Normal   = $00000000,
    kEdsFileAttribute_ReadOnly = $00000001,
    kEdsFileAttribute_Hidden   = $00000002,
    kEdsFileAttribute_System   = $00000004,
    kEdsFileAttribute_Archive  = $00000020
  );

{-----------------------------------------------------------------------------
 Battery level
-----------------------------------------------------------------------------}
  type EdsBatteryLevel = EdsUInt32;
  const
    kEdsBatteryLevel_Empty  =  1;
    kEdsBatteryLevel_Low    = 30;
    kEdsBatteryLevel_Half   = 50;
    kEdsBatteryLevel_Normal = 80;
    kEdsBatteryLevel_AC     = $FFFFFFFF;

{*-----------------------------------------------------------------------------
 Save To
-----------------------------------------------------------------------------}
  type EdsSaveTo = (
    kEdsSaveTo_Camera =  1,
    kEdsSaveTo_Host   =  2,
    kEdsSaveTo_Both   =  kEdsSaveTo_Camera + kEdsSaveTo_Host
  );

{-----------------------------------------------------------------------------
 StorageType
-----------------------------------------------------------------------------}
  type EdsStorageType = (
    kEdsStorageType_Non = 0,
    kEdsStorageType_CF  = 1,
    kEdsStorageType_SD  = 2

  );


{-----------------------------------------------------------------------------
 White Balance
-----------------------------------------------------------------------------}
  type EdsWhiteBalance = (
    kEdsWhiteBalance_Click          = -1,

    kEdsWhiteBalance_Auto           =  0,
    kEdsWhiteBalance_Daylight       =  1,
    kEdsWhiteBalance_Cloudy         =  2,
    kEdsWhiteBalance_Tangsten       =  3,
    kEdsWhiteBalance_Fluorescent    =  4,
    kEdsWhiteBalance_Strobe         =  5,
    kEdsWhiteBalance_WhitePaper     =  6,
    kEdsWhiteBalance_Shade          =  8,
    kEdsWhiteBalance_ColorTemp      =  9,
    kEdsWhiteBalance_PCSet1         = 10,
    kEdsWhiteBalance_PCSet2         = 11,
    kEdsWhiteBalance_PCSet3         = 12,

    KEdsWhiteBalance_Pasted         = -2
  );

{-----------------------------------------------------------------------------
 Photo Effect
 -----------------------------------------------------------------------------}
  type EdsEnumPhotoEffect = (
    kEdsPhotoEffect_Off        = 0,
    kEdsPhotoEffect_Monochrome = 5
  );

{-----------------------------------------------------------------------------
 Color Matrix
-----------------------------------------------------------------------------}
  type EdsEnumColorMatrix = (
    kEdsColorMatrix_Custom,
    kEdsColorMatrix_1,
    kEdsColorMatrix_2,
    kEdsColorMatrix_3,
    kEdsColorMatrix_4,
    kEdsColorMatrix_5,
    kEdsColorMatrix_6,
    kEdsColorMatrix_7
  );

{-----------------------------------------------------------------------------
 Filter Effect
-----------------------------------------------------------------------------}
  type EdsEnumFilterEffect = (
    kEdsFilterEffect_None,
    kEdsFilterEffect_Yellow,
    kEdsFilterEffect_Orange,
    kEdsFilterEffect_Red,
    kEdsFilterEffect_Green
  );

{-----------------------------------------------------------------------------
 Toning Effect
-----------------------------------------------------------------------------}
  type EdsEnumToningEffect = (
    kEdsTonigEffect_None,
    kEdsTonigEffect_Sepia,
    kEdsTonigEffect_Blue,
    kEdsTonigEffect_Purple,
    kEdsTonigEffect_Green
  );

{-----------------------------------------------------------------------------
 Color Space
-----------------------------------------------------------------------------}
  type EdsColorSpace = EdsUInt32;
  const
    kEdsColorSpace_sRGB       = 1;
    kEdsColorSpace_AdobeRGB   = 2;
    kEdsColorSpace_Unknown    = $FFFFFFFF;

{-----------------------------------------------------------------------------
 PictureStyle
-----------------------------------------------------------------------------}
  type EdsPictureStyle = (
    kEdsPictureStyle_Standard   = $0081,
    kEdsPictureStyle_Portrait   = $0082,
    kEdsPictureStyle_Landscape  = $0083,
    kEdsPictureStyle_Neutral    = $0084,
    kEdsPictureStyle_Faithful   = $0085,
    kEdsPictureStyle_Monochrome = $0086,
    kEdsPictureStyle_User1      = $0021,
    kEdsPictureStyle_User2      = $0022,
    kEdsPictureStyle_User3      = $0023,
    kEdsPictureStyle_PC1        = $0041,
    kEdsPictureStyle_PC2        = $0042,
    kEdsPictureStyle_PC3        = $0043
  );

{-----------------------------------------------------------------------------
 Transfer Option
-----------------------------------------------------------------------------}
  type EdsTransferOption = (
    kEdsTransferOption_ByDirectTransfer = 1,
    kEdsTransferOption_ByRelease        = 2,
    kEdsTransferOption_ToDesktop        = $00000100
  );

{-----------------------------------------------------------------------------
 AE Mode
-----------------------------------------------------------------------------}
  type EdsAEMode = EdsUInt32;
  const
    kEdsAEMode_Program          = 0;
    kEdsAEMode_Tv               = 1;
    kEdsAEMode_Av               = 2;
    kEdsAEMode_Mamual           = 3;
    kEdsAEMode_Bulb             = 4;
    kEdsAEMode_A_DEP            = 5;
    kEdsAEMode_DEP              = 6;
    kEdsAEMode_Custom           = 7;
    kEdsAEMode_Lock             = 8;
    kEdsAEMode_Green            = 9;
    kEdsAEMode_NigntPortrait    = 10;
    kEdsAEMode_Sports           = 11;
    kEdsAEMode_Portrait         = 12;
    kEdsAEMode_Landscape        = 13;
    kEdsAEMode_Closeup          = 14;
    kEdsAEMode_FlashOff         = 15;
    kEdsAEMode_Unknown          = $FFFFFFFF;

{-----------------------------------------------------------------------------
 Bracket
-----------------------------------------------------------------------------}
  type EdsBracket = EdsUInt32;
  const
    kEdsBracket_AEB             = $01;
    kEdsBracket_ISOB            = $02;
    kEdsBracket_WBB             = $04;
    kEdsBracket_FEB             = $08;
    kEdsBracket_Unknown         = $FFFFFFFF;


{
******************************************************************************
 Definition of base Structures
******************************************************************************
}
{-----------------------------------------------------------------------------
 Point
-----------------------------------------------------------------------------}
  type EdsPoint = record
    x : EdsInt32;
    y : EdsInt32;
  end;
  PEdsPoint = ^EdsPoint;

  type EdsSize = record
    width  : EdsInt32;
    height : EdsInt32;
  end;
  PEdsSize = ^EdsSize;

{-----------------------------------------------------------------------------
 Rectangle
-----------------------------------------------------------------------------}
  type EdsRect = record
    point : EdsPoint;
    size  : EdsSize;
  end;
  PEdsRect = ^EdsRect;

{-----------------------------------------------------------------------------
 Rational
-----------------------------------------------------------------------------}
  type EdsRational = record
    numerator   :EdsInt32;
    denominator :EdsUInt32;
  end;
  PEdsRational = ^EdsRational;

{-----------------------------------------------------------------------------
 Time
-----------------------------------------------------------------------------}
  type EdsTime = record
    year        : EdsUInt32;
    month       : EdsUInt32;
    day         : EdsUInt32;
    hour        : EdsUInt32;
    minute      : EdsUInt32;
    second      : EdsUInt32;
    millseconds : EdsUInt32;
  end;
  PEdsTime = ^EdsTime;

{******************************************************************************
 Definition of Structures ( Record )
******************************************************************************}

{-----------------------------------------------------------------------------
 Device Info
    szPortName : port name
    DeviceDescription : device name ex. 'EOS 20D PTP'
    deviceSubType : Canon legacy protocal camera = 0, Canon PTP cameras = 1
-----------------------------------------------------------------------------}
  type EdsDeviceInfo = record
    szPortName : array[ 0..EDS_MAX_NAME-1 ] of EdsChar;
    szDeviceDescription : array[ 0..EDS_MAX_NAME-1 ] of EdsChar;
    deviceSubType : EdsUInt32;
  	  reserved: EdsUInt32; // New
  end;

  PEdsDeviceInfo = ^EdsDeviceInfo;

{-----------------------------------------------------------------------------
 Volume Info
    storageType : Value defined by Enum EdsStorageType
                    0 = no card,    1 = CD,    2 = SD
    access : Value defined by Enum EdsAccess
                    0 = Read only   2 = Write only   3 Read/Write
    maxCapacity : Maximum size (in bytes)
    freeSpaceInBytes : Available capacity (in bytes)
    szVolumeLabel : Volume name (an ASCII string) Ex. 'A:' or another drive name
-----------------------------------------------------------------------------}
  type EdsVolumeInfo = record
    storageType      : EdsUInt32;
    access           : EdsAccess;
    maxCapacity      : EdsUInt64;
    freeSpaceInBytes : EdsUInt64;
    szVolumeLabel    : array[0..EDS_MAX_NAME-1 ] of EdsChar;
  end;

  PEdsVolumeInfo = ^EdsVolumeInfo;

{-----------------------------------------------------------------------------
 DirectoryItem Info
    size : file size. For folders, the file size is indicated as 0. 
    isFolder : If a folder: True.  If not a folder: False
    groupID  : A non-zero integer.
               The same group ID is assigned to files that belong to the same group,
               such as RAW+JPEG files or RAW+sound files.

               Note: Valid for type 2 protocol standard cameras.

    option   : An option when a direct transfer request is received
               (a kEdsObjectEvent_DirItemRequestTransferDT event).
               kEdsTransferOptionToDesktop is set when [Wallpaper] in the
               direct transfer is executed by means of camera operations.
               Prohibit it under other timing conditions.

               Note: Valid for type 2 protocol standard cameras.

    szFileName : Returns the directory name or file name if successful. Ex: "_MG_0060.JPG"
-----------------------------------------------------------------------------}
  type EdsDirectoryItemInfo = record
    size : EdsUInt32;
    isFolder   : EdsBool;
    groupID    : EdsUInt32;               { EOS 30D later }
    option     : EdsUInt32;               { EOS 30D later EdsEnumTransferOption }
    szFileName : array[0.. EDS_MAX_NAME-1 ] of EdsChar;
      format     : EdsUInt32; // New
  end;

  PEdsDirectoryItemInfo = ^EdsDirectoryItemInfo;

{-----------------------------------------------------------------------------
 Image Info
    width : image width in pixel
    height : image height in pixel
    numOfComponents : number of color components
    componentDepth  : resolution 8bit or 16bit
    effectiveRect   : effective image area
                      This means the area excluding the black bands on the top
                      and bottom of the thumbnail image.
-----------------------------------------------------------------------------}
  type EdsImageInfo = record
    width  : EdsUInt32;                 { image width  }
    height : EdsUInt32;                 { image height }

    numOfComponents : EdsUInt32;        { number of color components in image. }
    componentDepth  : EdsUInt32;        { bits per sample.  8 or 16. }

    effectiveRect   : EdsRect;          { Effective rectangles except
                                          a black line of the image.
                                          A black line might be in the top and bottom
                                          of the thumbnail image. }
    reserved1 : EdsUInt32;
    reserved2 : EdsUInt32;
  end;

  PEdsImageInfo = ^EdsImageInfo;

{-----------------------------------------------------------------------------
 Save Option Info
    JPEGQuality : Image quality for JPEG compression ---1 (rough) to 10 (fine)
    iccProfileSize : Byte size of embedded ICC profile
    iccProfile : Pointer to the ICC profile data
-----------------------------------------------------------------------------}
  type EdsSaveImageSetting = record
    JPEGQuality : EdsCompressQuality;
    iccProfileStream : EdsStreamRef;
    reserved : EdsUInt32;
  end;

  PEdsSaveImageSetting = ^EdsSaveImageSetting ;

{-----------------------------------------------------------------------------
 Property Desc
-----------------------------------------------------------------------------}
  type EdsPropertyDesc = record
    form : EdsInt32;
    access : EdsInt32; // EdsAccess;
    numElements : EdsInt32;
    propDesc : array[0..127] of EdsInt32;
  end;

  PEdsPropertyDesc = ^EdsPropertyDesc;

{-----------------------------------------------------------------------------
 Picture Style Desc
-----------------------------------------------------------------------------}
  type EdsPictureStyleDesc = record
    contrast        : EdsInt32;
    sharpness       : EdsUInt32;
    saturation      : EdsInt32;
    colorTone       : EdsInt32;
    filterEffect    : EdsUInt32;
    toningEffect    : EdsUInt32;
  end;

  PEdsPictureStyleDesc = ^EdsPictureStyleDesc;


{-----------------------------------------------------------------------------
 Focus Info
-----------------------------------------------------------------------------}
  type EdsFocusPoint = record
    valid           : EdsUInt32;        { if the frame is valid.      }
    	selected      : EdsUInt32; // New
    justFocus       : EdsUInt32;        { if the frame is just focus. }
    rect            : EdsRect;          { rectangle of focus point.   }
    reserved        : EdsUInt32;        { reserved                    }
  end;

  PEdsFocusPoint = ^EdsFocusPoint;


  type EdsFocusInfo = record
    imageRect       : EdsRect;          { rectangle of the image.     }
    pointNumber     : EdsUInt32;        { number of point.            }
    focusPoint      : array[0..127] of EdsFocusPoint; { each frame's description. }
      executeMode   : EdsUInt32; // New
  end;

  PEdsFocusInfo = ^EdsFocusInfo;

{-----------------------------------------------------------------------------
 User WhiteBalance ( PC set1,2,3 )/ User ToneCurve / User PictureStyle dataset
-----------------------------------------------------------------------------}
  type EdsUsersetData = record
    valid     : EdsUInt32;
    dataSize  : EdsUInt32;
    szCaption : array[0..31] of EdsChar;
    data      : array[0..1] of EdsUInt8;
  end;

  PEdsUsersetData = ^EdsUsersetData;

{-----------------------------------------------------------------------------
 Capacity
    numberOfFreeClusters : Available number of clusters on the HDD;
    bytesPerSector : Cluster length (valid only when reset)
    reset : true  = Designate the available capacity for the entire HDD.
            false = Designate the difference from the previous notification.
                    However, the value does not include the capacity corresponding
                    to transferred images. 
-----------------------------------------------------------------------------}
  type EdsCapacity = record
    numberOfFreeClusters : EdsInt32;    { free clusters }
    bytesPerSector : EdsInt32;          { sectors per cluster }
    reset          : EdsBool;
  end;

  PEdsCapacity = ^EdsCapacity;

{******************************************************************************
 Camera Detect Evnet Handler
******************************************************************************}
type EdsCameraAddedHandler = function( inContext : Pointer ) : EdsError; stdcall;


{******************************************************************************
 Callback Functions
******************************************************************************}
type EdsProgressCallback = function( inPercent : EdsUInt32;
                                     inContext : Pointer;
                                     var outCancel : EdsBool ) : EdsError ; stdcall;

{******************************************************************************
 Evnet Handler
******************************************************************************}
type EdsPropertyEventHandler = function( inEvent : EdsPropertyEvent;
                                         inPropertyID : EdsPropertyID;
                                         inParam : EdsUInt32;
                                         inContext : EdsUInt32 ) : EdsError ; stdcall;


type EdsObjectEventHandler = function( inEvent : EdsObjectEvent;
                                       inRef : EdsBaseRef;
                                       inContext : Pointer ) : EdsError ; stdcall;

type EdsStateEventHandler = function( inEvent : EdsStateEvent;
                                      inParamter : EdsUInt32;
                                      inContext : EdsUInt32 ) : EdsError ; stdcall;

implementation

end.