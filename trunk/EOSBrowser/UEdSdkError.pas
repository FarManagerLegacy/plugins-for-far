unit UEdSdkError;

{$i CommonDirectives.inc}

interface

uses
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  plugin,
{$ENDIF}
  UTypes,
  EDSDKType,
  EDSDKError;

function GetEdSdkError(EdsErrorCode: EdsError): PFarChar;

implementation

const
  sUNKNOWN_ERROR = 'Unknown error';
  sEDS_ERR_OK = 'No error';
  sEDS_ERR_UNIMPLEMENTED = 'Not implemented';
  sEDS_ERR_INTERNAL_ERROR = 'Internal error';
  sEDS_ERR_MEM_ALLOC_FAILED = 'Memory allocation error';
  sEDS_ERR_MEM_FREE_FAILED = 'Memory release error';
  sEDS_ERR_OPERATION_CANCELLED = 'Operation canceled';
  sEDS_ERR_INCOMPATIBLE_VERSION = 'Version error';
  sEDS_ERR_NOT_SUPPORTED = 'Not supported';
  sEDS_ERR_UNEXPECTED_EXCEPTION = 'Unexpected exception';
  sEDS_ERR_PROTECTION_VIOLATION = 'Protection violation';
  sEDS_ERR_MISSING_SUBCOMPONENT = 'Missing subcomponent';
  sEDS_ERR_SELECTION_UNAVAILABLE = 'Selection unavailable';
  sEDS_ERR_FILE_IO_ERROR = 'IO error';
  sEDS_ERR_FILE_TOO_MANY_OPEN = 'Too many files open';
  sEDS_ERR_FILE_NOT_FOUND = 'File does not exist';
  sEDS_ERR_FILE_OPEN_ERROR = 'Open error';
  sEDS_ERR_FILE_CLOSE_ERROR = 'Close error';
  sEDS_ERR_FILE_SEEK_ERROR = 'Seek error';
  sEDS_ERR_FILE_TELL_ERROR = 'Tell error';
  sEDS_ERR_FILE_READ_ERROR = 'Read error';
  sEDS_ERR_FILE_WRITE_ERROR = 'Write error';
  sEDS_ERR_FILE_PERMISSION_ERROR = 'Permission error';
  sEDS_ERR_FILE_DISK_FULL_ERROR = 'Disk full';
  sEDS_ERR_FILE_ALREADY_EXISTS = 'File already exists';
  sEDS_ERR_FILE_FORMAT_UNRECOGNIZED = 'Format error';
  sEDS_ERR_FILE_DATA_CORRUPT = 'Invalid data';
  sEDS_ERR_FILE_NAMING_NA = 'File naming error';
  sEDS_ERR_DIR_NOT_FOUND = 'Directory does not exist';
  sEDS_ERR_DIR_IO_ERROR = 'I/O error';
  sEDS_ERR_DIR_ENTRY_NOT_FOUND = 'No file in directory';
  sEDS_ERR_DIR_ENTRY_EXISTS = 'File in directory';
  sEDS_ERR_DIR_NOT_EMPTY = 'Directory full';
  sEDS_ERR_PROPERTIES_UNAVAILABLE = 'Property (and additional property information) unavailable';
  sEDS_ERR_PROPERTIES_MISMATCH = 'Property mismatch';
  sEDS_ERR_PROPERTIES_NOT_LOADED = 'Property not loaded';
  sEDS_ERR_DEVICE_NOT_FOUND = 'Device not found';
  sEDS_ERR_DEVICE_BUSY = 'Device busy';
  sEDS_ERR_DEVICE_INVALID = 'Device error';
  sEDS_ERR_DEVICE_EMERGENCY = 'Device emergency';
  sEDS_ERR_DEVICE_MEMORY_FULL = 'Device memory full';
  sEDS_ERR_DEVICE_INTERNAL_ERROR = 'Internal device error';
  sEDS_ERR_DEVICE_INVALID_PARAMETER = 'Device parameter invalid';
  sEDS_ERR_DEVICE_NO_DISK = 'No disk';
  sEDS_ERR_DEVICE_DISK_ERROR = 'Disk error';
  sEDS_ERR_DEVICE_CF_GATE_CHANGED = 'The CF gate has been changed';
  sEDS_ERR_DEVICE_DIAL_CHANGED = 'The dial has been changed';
  sEDS_ERR_DEVICE_NOT_INSTALLED = 'Device not installed';
  sEDS_ERR_DEVICE_STAY_AWAKE = 'Device connected in awake mode';
  sEDS_ERR_DEVICE_NOT_RELEASED = 'Device not released';
  sEDS_ERR_STREAM_IO_ERROR = 'Stream I/O error';
  sEDS_ERR_STREAM_NOT_OPEN = 'Stream open error';
  sEDS_ERR_STREAM_ALREADY_OPEN = 'Stream already open';
  sEDS_ERR_STREAM_OPEN_ERROR = 'Failed to open stream';
  sEDS_ERR_STREAM_CLOSE_ERROR = 'Failed to close stream';
  sEDS_ERR_STREAM_SEEK_ERROR = 'Stream seek error';
  sEDS_ERR_STREAM_TELL_ERROR = 'Stream tell error';
  sEDS_ERR_STREAM_READ_ERROR = 'Failed to read stream';
  sEDS_ERR_STREAM_WRITE_ERROR = 'Failed to write stream';
  sEDS_ERR_STREAM_PERMISSION_ERROR = 'Permission error';
  sEDS_ERR_STREAM_COULDNT_BEGIN_THREAD = 'Could not start reading thumbnail';
  sEDS_ERR_STREAM_BAD_OPTIONS = 'Invalid stream option';
  sEDS_ERR_STREAM_END_OF_STREAM = 'Invalid stream termination';
  sEDS_ERR_COMM_PORT_IS_IN_USE = 'Port in use';
  sEDS_ERR_COMM_DISCONNECTED = 'Port disconnected';
  sEDS_ERR_COMM_DEVICE_INCOMPATIBLE = 'Incompatible device';
  sEDS_ERR_COMM_BUFFER_FULL = 'Buffer full';
  sEDS_ERR_COMM_USB_BUS_ERR = 'USB bus error';
  sEDS_ERR_USB_DEVICE_LOCK_ERROR = 'Failed to lock the UI';
  sEDS_ERR_USB_DEVICE_UNLOCK_ERROR = 'Failed to unlock the UI';
  sEDS_ERR_STI_UNKNOWN_ERROR = 'Unknown STI';
  sEDS_ERR_STI_INTERNAL_ERROR = 'Internal STI error';
  sEDS_ERR_STI_DEVICE_CREATE_ERROR = 'Device creation error';
  sEDS_ERR_STI_DEVICE_RELEASE_ERROR = 'Device release error';
  sEDS_ERR_DEVICE_NOT_LAUNCHED = 'Device startup failed';
  sEDS_ERR_ENUM_NA = 'Enumeration terminated (there was no suitable enumeration item)';
  sEDS_ERR_INVALID_FN_CALL = 'Called in a mode when the function could not be used';
  sEDS_ERR_HANDLE_NOT_FOUND = 'Handle not found';
  sEDS_ERR_INVALID_ID = 'Invalid ID';
  sEDS_ERR_WAIT_TIMEOUT_ERROR = 'Timeout';
  sEDS_ERR_LAST_GENERIC_ERROR_PLUS_ONE = 'Not used.';
  sEDS_ERR_SESSION_NOT_OPEN = 'Session open error';
  sEDS_ERR_INVALID_TRANSACTIONID = 'Invalid transaction ID';
  sEDS_ERR_INCOMPLETE_TRANSFER = 'Transfer problem';
  sEDS_ERR_INVALID_STRAGEID = 'Storage error';
  sEDS_ERR_DEVICEPROP_NOT_SUPPORTED = 'Unsupported device property';
  sEDS_ERR_INVALID_OBJECTFORMATCODE = 'Invalid object format code';
  sEDS_ERR_SELF_TEST_FAILED = 'Failed self-diagnosis';
  sEDS_ERR_PARTIAL_DELETION = 'Failed in partial deletion';
  sEDS_ERR_SPECIFICATION_BY_FORMAT_UNSUPPORTED = 'Unsupported format specification';
  sEDS_ERR_NO_VALID_OBJECTINFO = 'Invalid object information';
  sEDS_ERR_INVALID_CODE_FORMAT = 'Invalid code format';
  sEDS_ERR_UNKNOWN_VENDER_CODE = 'Unknown vendor code';
  sEDS_ERR_CAPTURE_ALREADY_TERMINATED = 'Capture already terminated';
  sEDS_ERR_INVALID_PARENTOBJECT = 'Invalid parent object';
  sEDS_ERR_INVALID_DEVICEPROP_FORMAT = 'Invalid property format';
  sEDS_ERR_INVALID_DEVICEPROP_VALUE = 'Invalid property value';
  sEDS_ERR_SESSION_ALREADY_OPEN = 'Session already open';
  sEDS_ERR_TRANSACTION_CANCELLED = 'Transaction canceled';
  sEDS_ERR_SPECIFICATION_OF_DESTINATION_UNSUPPORTED = 'Unsupported destination specification';
  sEDS_ERR_UNKNOWN_COMMAND = 'Unknown command';
  sEDS_ERR_OPERATION_REFUSED = 'Operation refused';
  sEDS_ERR_LENS_COVER_CLOSE = 'Lens cover closed';
  sEDS_ERR_OBJECT_NOTREADY = 'Image data set not ready for live view';
  sEDS_ERR_TAKE_PICTURE_AF_NG = 'Focus failed';
  sEDS_ERR_TAKE_PICTURE_RESERVED = 'Reserved';
  sEDS_ERR_TAKE_PICTURE_MIRROR_UP_NG = 'Currently configuring mirror up';
  sEDS_ERR_TAKE_PICTURE_SENSOR_CLEANING_NG = 'Currently cleaning sensor';
  sEDS_ERR_TAKE_PICTURE_SILENCE_NG = 'Currently performing silent operations';
  sEDS_ERR_TAKE_PICTURE_NO_CARD_NG = 'Card not installed';
  sEDS_ERR_TAKE_PICTURE_CARD_NG = 'Error writing to card';
  sEDS_ERR_TAKE_PICTURE_CARD_PROTECT_NG = 'Card write protected';

type
  TErrorInfo = record
    EdsErrorCode: EdsError;
    EdsErrorMessage: PFarChar;
  end;

const
  cMaxError = 111;
  cErrorMessage: array[0..cMaxError - 1] of TErrorInfo = (
    (EdsErrorCode: EDS_ERR_OK; EdsErrorMessage: sEDS_ERR_OK),
    (EdsErrorCode: EDS_ERR_UNIMPLEMENTED; EdsErrorMessage: sEDS_ERR_UNIMPLEMENTED),
    (EdsErrorCode: EDS_ERR_INTERNAL_ERROR; EdsErrorMessage: sEDS_ERR_INTERNAL_ERROR),
    (EdsErrorCode: EDS_ERR_MEM_ALLOC_FAILED; EdsErrorMessage: sEDS_ERR_MEM_ALLOC_FAILED),
    (EdsErrorCode: EDS_ERR_MEM_FREE_FAILED; EdsErrorMessage: sEDS_ERR_MEM_FREE_FAILED),
    (EdsErrorCode: EDS_ERR_OPERATION_CANCELLED; EdsErrorMessage: sEDS_ERR_OPERATION_CANCELLED),
    (EdsErrorCode: EDS_ERR_INCOMPATIBLE_VERSION; EdsErrorMessage: sEDS_ERR_INCOMPATIBLE_VERSION),
    (EdsErrorCode: EDS_ERR_NOT_SUPPORTED; EdsErrorMessage: sEDS_ERR_NOT_SUPPORTED),
    (EdsErrorCode: EDS_ERR_UNEXPECTED_EXCEPTION; EdsErrorMessage: sEDS_ERR_UNEXPECTED_EXCEPTION),
    (EdsErrorCode: EDS_ERR_PROTECTION_VIOLATION; EdsErrorMessage: sEDS_ERR_PROTECTION_VIOLATION),
    (EdsErrorCode: EDS_ERR_MISSING_SUBCOMPONENT; EdsErrorMessage: sEDS_ERR_MISSING_SUBCOMPONENT),
    (EdsErrorCode: EDS_ERR_SELECTION_UNAVAILABLE; EdsErrorMessage: sEDS_ERR_SELECTION_UNAVAILABLE),
    (EdsErrorCode: EDS_ERR_FILE_IO_ERROR; EdsErrorMessage: sEDS_ERR_FILE_IO_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_TOO_MANY_OPEN; EdsErrorMessage: sEDS_ERR_FILE_TOO_MANY_OPEN),
    (EdsErrorCode: EDS_ERR_FILE_NOT_FOUND; EdsErrorMessage: sEDS_ERR_FILE_NOT_FOUND),
    (EdsErrorCode: EDS_ERR_FILE_OPEN_ERROR; EdsErrorMessage: sEDS_ERR_FILE_OPEN_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_CLOSE_ERROR; EdsErrorMessage: sEDS_ERR_FILE_CLOSE_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_SEEK_ERROR; EdsErrorMessage: sEDS_ERR_FILE_SEEK_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_TELL_ERROR; EdsErrorMessage: sEDS_ERR_FILE_TELL_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_READ_ERROR; EdsErrorMessage: sEDS_ERR_FILE_READ_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_WRITE_ERROR; EdsErrorMessage: sEDS_ERR_FILE_WRITE_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_PERMISSION_ERROR; EdsErrorMessage: sEDS_ERR_FILE_PERMISSION_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_DISK_FULL_ERROR; EdsErrorMessage: sEDS_ERR_FILE_DISK_FULL_ERROR),
    (EdsErrorCode: EDS_ERR_FILE_ALREADY_EXISTS; EdsErrorMessage: sEDS_ERR_FILE_ALREADY_EXISTS),
    (EdsErrorCode: EDS_ERR_FILE_FORMAT_UNRECOGNIZED; EdsErrorMessage: sEDS_ERR_FILE_FORMAT_UNRECOGNIZED),
    (EdsErrorCode: EDS_ERR_FILE_DATA_CORRUPT; EdsErrorMessage: sEDS_ERR_FILE_DATA_CORRUPT),
    (EdsErrorCode: EDS_ERR_FILE_NAMING_NA; EdsErrorMessage: sEDS_ERR_FILE_NAMING_NA),
    (EdsErrorCode: EDS_ERR_DIR_NOT_FOUND; EdsErrorMessage: sEDS_ERR_DIR_NOT_FOUND),
    (EdsErrorCode: EDS_ERR_DIR_IO_ERROR; EdsErrorMessage: sEDS_ERR_DIR_IO_ERROR),
    (EdsErrorCode: EDS_ERR_DIR_ENTRY_NOT_FOUND; EdsErrorMessage: sEDS_ERR_DIR_ENTRY_NOT_FOUND),
    (EdsErrorCode: EDS_ERR_DIR_ENTRY_EXISTS; EdsErrorMessage: sEDS_ERR_DIR_ENTRY_EXISTS),
    (EdsErrorCode: EDS_ERR_DIR_NOT_EMPTY; EdsErrorMessage: sEDS_ERR_DIR_NOT_EMPTY),
    (EdsErrorCode: EDS_ERR_PROPERTIES_UNAVAILABLE; EdsErrorMessage: sEDS_ERR_PROPERTIES_UNAVAILABLE),
    (EdsErrorCode: EDS_ERR_PROPERTIES_MISMATCH; EdsErrorMessage: sEDS_ERR_PROPERTIES_MISMATCH),
    (EdsErrorCode: EDS_ERR_PROPERTIES_NOT_LOADED; EdsErrorMessage: sEDS_ERR_PROPERTIES_NOT_LOADED),
    (EdsErrorCode: EDS_ERR_DEVICE_NOT_FOUND; EdsErrorMessage: sEDS_ERR_DEVICE_NOT_FOUND),
    (EdsErrorCode: EDS_ERR_DEVICE_BUSY; EdsErrorMessage: sEDS_ERR_DEVICE_BUSY),
    (EdsErrorCode: EDS_ERR_DEVICE_INVALID; EdsErrorMessage: sEDS_ERR_DEVICE_INVALID),
    (EdsErrorCode: EDS_ERR_DEVICE_EMERGENCY; EdsErrorMessage: sEDS_ERR_DEVICE_EMERGENCY),
    (EdsErrorCode: EDS_ERR_DEVICE_MEMORY_FULL; EdsErrorMessage: sEDS_ERR_DEVICE_MEMORY_FULL),
    (EdsErrorCode: EDS_ERR_DEVICE_INTERNAL_ERROR; EdsErrorMessage: sEDS_ERR_DEVICE_INTERNAL_ERROR),
    (EdsErrorCode: EDS_ERR_DEVICE_INVALID_PARAMETER; EdsErrorMessage: sEDS_ERR_DEVICE_INVALID_PARAMETER),
    (EdsErrorCode: EDS_ERR_DEVICE_NO_DISK; EdsErrorMessage: sEDS_ERR_DEVICE_NO_DISK),
    (EdsErrorCode: EDS_ERR_DEVICE_DISK_ERROR; EdsErrorMessage: sEDS_ERR_DEVICE_DISK_ERROR),
    (EdsErrorCode: EDS_ERR_DEVICE_CF_GATE_CHANGED; EdsErrorMessage: sEDS_ERR_DEVICE_CF_GATE_CHANGED),
    (EdsErrorCode: EDS_ERR_DEVICE_DIAL_CHANGED; EdsErrorMessage: sEDS_ERR_DEVICE_DIAL_CHANGED),
    (EdsErrorCode: EDS_ERR_DEVICE_NOT_INSTALLED; EdsErrorMessage: sEDS_ERR_DEVICE_NOT_INSTALLED),
    (EdsErrorCode: EDS_ERR_DEVICE_STAY_AWAKE; EdsErrorMessage: sEDS_ERR_DEVICE_STAY_AWAKE),
    (EdsErrorCode: EDS_ERR_DEVICE_NOT_RELEASED; EdsErrorMessage: sEDS_ERR_DEVICE_NOT_RELEASED),
    (EdsErrorCode: EDS_ERR_STREAM_IO_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_IO_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_NOT_OPEN; EdsErrorMessage: sEDS_ERR_STREAM_NOT_OPEN),
    (EdsErrorCode: EDS_ERR_STREAM_ALREADY_OPEN; EdsErrorMessage: sEDS_ERR_STREAM_ALREADY_OPEN),
    (EdsErrorCode: EDS_ERR_STREAM_OPEN_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_OPEN_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_CLOSE_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_CLOSE_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_SEEK_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_SEEK_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_TELL_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_TELL_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_READ_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_READ_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_WRITE_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_WRITE_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_PERMISSION_ERROR; EdsErrorMessage: sEDS_ERR_STREAM_PERMISSION_ERROR),
    (EdsErrorCode: EDS_ERR_STREAM_COULDNT_BEGIN_THREAD; EdsErrorMessage: sEDS_ERR_STREAM_COULDNT_BEGIN_THREAD),
    (EdsErrorCode: EDS_ERR_STREAM_BAD_OPTIONS; EdsErrorMessage: sEDS_ERR_STREAM_BAD_OPTIONS),
    (EdsErrorCode: EDS_ERR_STREAM_END_OF_STREAM; EdsErrorMessage: sEDS_ERR_STREAM_END_OF_STREAM),
    (EdsErrorCode: EDS_ERR_COMM_PORT_IS_IN_USE; EdsErrorMessage: sEDS_ERR_COMM_PORT_IS_IN_USE),
    (EdsErrorCode: EDS_ERR_COMM_DISCONNECTED; EdsErrorMessage: sEDS_ERR_COMM_DISCONNECTED),
    (EdsErrorCode: EDS_ERR_COMM_DEVICE_INCOMPATIBLE; EdsErrorMessage: sEDS_ERR_COMM_DEVICE_INCOMPATIBLE),
    (EdsErrorCode: EDS_ERR_COMM_BUFFER_FULL; EdsErrorMessage: sEDS_ERR_COMM_BUFFER_FULL),
    (EdsErrorCode: EDS_ERR_COMM_USB_BUS_ERR; EdsErrorMessage: sEDS_ERR_COMM_USB_BUS_ERR),
    (EdsErrorCode: EDS_ERR_USB_DEVICE_LOCK_ERROR; EdsErrorMessage: sEDS_ERR_USB_DEVICE_LOCK_ERROR),
    (EdsErrorCode: EDS_ERR_USB_DEVICE_UNLOCK_ERROR; EdsErrorMessage: sEDS_ERR_USB_DEVICE_UNLOCK_ERROR),
    (EdsErrorCode: EDS_ERR_STI_UNKNOWN_ERROR; EdsErrorMessage: sEDS_ERR_STI_UNKNOWN_ERROR),
    (EdsErrorCode: EDS_ERR_STI_INTERNAL_ERROR; EdsErrorMessage: sEDS_ERR_STI_INTERNAL_ERROR),
    (EdsErrorCode: EDS_ERR_STI_DEVICE_CREATE_ERROR; EdsErrorMessage: sEDS_ERR_STI_DEVICE_CREATE_ERROR),
    (EdsErrorCode: EDS_ERR_STI_DEVICE_RELEASE_ERROR; EdsErrorMessage: sEDS_ERR_STI_DEVICE_RELEASE_ERROR),
    (EdsErrorCode: EDS_ERR_DEVICE_NOT_LAUNCHED; EdsErrorMessage: sEDS_ERR_DEVICE_NOT_LAUNCHED),
    (EdsErrorCode: EDS_ERR_ENUM_NA; EdsErrorMessage: sEDS_ERR_ENUM_NA),
    (EdsErrorCode: EDS_ERR_INVALID_FN_CALL; EdsErrorMessage: sEDS_ERR_INVALID_FN_CALL),
    (EdsErrorCode: EDS_ERR_HANDLE_NOT_FOUND; EdsErrorMessage: sEDS_ERR_HANDLE_NOT_FOUND),
    (EdsErrorCode: EDS_ERR_INVALID_ID; EdsErrorMessage: sEDS_ERR_INVALID_ID),
    (EdsErrorCode: EDS_ERR_WAIT_TIMEOUT_ERROR; EdsErrorMessage: sEDS_ERR_WAIT_TIMEOUT_ERROR),
    (EdsErrorCode: EDS_ERR_LAST_GENERIC_ERROR_PLUS_ONE; EdsErrorMessage: sEDS_ERR_LAST_GENERIC_ERROR_PLUS_ONE),
    (EdsErrorCode: EDS_ERR_SESSION_NOT_OPEN; EdsErrorMessage: sEDS_ERR_SESSION_NOT_OPEN),
    (EdsErrorCode: EDS_ERR_INVALID_TRANSACTIONID; EdsErrorMessage: sEDS_ERR_INVALID_TRANSACTIONID),
    (EdsErrorCode: EDS_ERR_INCOMPLETE_TRANSFER; EdsErrorMessage: sEDS_ERR_INCOMPLETE_TRANSFER),
    (EdsErrorCode: EDS_ERR_INVALID_STRAGEID; EdsErrorMessage: sEDS_ERR_INVALID_STRAGEID),
    (EdsErrorCode: EDS_ERR_DEVICEPROP_NOT_SUPPORTED; EdsErrorMessage: sEDS_ERR_DEVICEPROP_NOT_SUPPORTED),
    (EdsErrorCode: EDS_ERR_INVALID_OBJECTFORMATCODE; EdsErrorMessage: sEDS_ERR_INVALID_OBJECTFORMATCODE),
    (EdsErrorCode: EDS_ERR_SELF_TEST_FAILED; EdsErrorMessage: sEDS_ERR_SELF_TEST_FAILED),
    (EdsErrorCode: EDS_ERR_PARTIAL_DELETION; EdsErrorMessage: sEDS_ERR_PARTIAL_DELETION),
    (EdsErrorCode: EDS_ERR_SPECIFICATION_BY_FORMAT_UNSUPPORTED; EdsErrorMessage: sEDS_ERR_SPECIFICATION_BY_FORMAT_UNSUPPORTED),
    (EdsErrorCode: EDS_ERR_NO_VALID_OBJECTINFO; EdsErrorMessage: sEDS_ERR_NO_VALID_OBJECTINFO),
    (EdsErrorCode: EDS_ERR_INVALID_CODE_FORMAT; EdsErrorMessage: sEDS_ERR_INVALID_CODE_FORMAT),
    (EdsErrorCode: EDS_ERR_UNKNOWN_VENDER_CODE; EdsErrorMessage: sEDS_ERR_UNKNOWN_VENDER_CODE),
    (EdsErrorCode: EDS_ERR_CAPTURE_ALREADY_TERMINATED; EdsErrorMessage: sEDS_ERR_CAPTURE_ALREADY_TERMINATED),
    (EdsErrorCode: EDS_ERR_INVALID_PARENTOBJECT; EdsErrorMessage: sEDS_ERR_INVALID_PARENTOBJECT),
    (EdsErrorCode: EDS_ERR_INVALID_DEVICEPROP_FORMAT; EdsErrorMessage: sEDS_ERR_INVALID_DEVICEPROP_FORMAT),
    (EdsErrorCode: EDS_ERR_INVALID_DEVICEPROP_VALUE; EdsErrorMessage: sEDS_ERR_INVALID_DEVICEPROP_VALUE),
    (EdsErrorCode: EDS_ERR_SESSION_ALREADY_OPEN; EdsErrorMessage: sEDS_ERR_SESSION_ALREADY_OPEN),
    (EdsErrorCode: EDS_ERR_TRANSACTION_CANCELLED; EdsErrorMessage: sEDS_ERR_TRANSACTION_CANCELLED),
    (EdsErrorCode: EDS_ERR_SPECIFICATION_OF_DESTINATION_UNSUPPORTED; EdsErrorMessage: sEDS_ERR_SPECIFICATION_OF_DESTINATION_UNSUPPORTED),
    (EdsErrorCode: EDS_ERR_UNKNOWN_COMMAND; EdsErrorMessage: sEDS_ERR_UNKNOWN_COMMAND),
    (EdsErrorCode: EDS_ERR_OPERATION_REFUSED; EdsErrorMessage: sEDS_ERR_OPERATION_REFUSED),
    (EdsErrorCode: EDS_ERR_LENS_COVER_CLOSE; EdsErrorMessage: sEDS_ERR_LENS_COVER_CLOSE),
    (EdsErrorCode: EDS_ERR_OBJECT_NOTREADY; EdsErrorMessage: sEDS_ERR_OBJECT_NOTREADY),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_AF_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_AF_NG),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_RESERVED; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_RESERVED),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_MIRROR_UP_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_MIRROR_UP_NG),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_SENSOR_CLEANING_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_SENSOR_CLEANING_NG),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_SILENCE_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_SILENCE_NG),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_NO_CARD_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_NO_CARD_NG),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_CARD_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_CARD_NG),
    (EdsErrorCode: EDS_ERR_TAKE_PICTURE_CARD_PROTECT_NG; EdsErrorMessage: sEDS_ERR_TAKE_PICTURE_CARD_PROTECT_NG)
  );

function GetEdSdkError(EdsErrorCode: EdsError): PFarChar;
var
  i: EdsError;
begin
  for i := 0 to cMaxError - 1 do
    if cErrorMessage[i].EdsErrorCode = EdsErrorCode then
    begin
      Result := cErrorMessage[i].EdsErrorMessage;
      Exit;
    end;
  Result := sUNKNOWN_ERROR;
end;

end.