{******************************************************************************
*                                                                             *
*   PROJECT : EOS Digital Software Development Kit EDSDK                      *
*      NAME : EDSDKApi.pas                                                    *
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
unit EDSDKApi;

interface

uses
  EDSDKType, EDSDKError;


const
  edsdk = 'EDSDK.DLL';

{
 ******************************************************************************
 ********************* Initialize / Terminate Function ************************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------
  Function : EdsInitializeSDK

  Description :
        Initializes the libraries. 
        When using the EDSDK libraries, you must call this API once before using EDSDK APIs.

  Parameters:
         In: None
        Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
------------------------------------------------------------------------------- }
function EdsInitializeSDK( ) : EdsError ; stdcall; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsTerminateSDK

  Description :
        Terminates use of the libraries. 
        Calling this function releases all resources allocated by the libraries. 

        This function delete all the reference or list objects that
        user has forgotten to delete.

  Parameters:
         In: None
        Out: None

  Returns: 
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
------------------------------------------------------------------------------- }
function EdsTerminateSDK( ) : EdsError ; stdcall; external edsdk;


{
 ******************************************************************************
 *********************** Referense Count Function *****************************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------
  Function : EdsRetain

  Description:
        Increments the reference counter of existing objects. 

  Parameters:
         In: inRef - The reference for the object item.
        Out: None

  Returns: 
        Returns a reference counter if successful. For errors, returns $FFFFFFFF. 
------------------------------------------------------------------------------- }
function  EdsRetain( inRef : EdsBaseRef ) : EdsUInt32 ; stdcall; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsRelease

  Description:
        Decrements the reference counter to an object. 
        When the reference counter reaches 0, the object is released. 

  Parameters:
         In: inRef - The reference of the object item.
        Out: None
  Returns:
        Returns a reference counter if successful. For errors, returns $FFFFFFFF.
----------------------------------------------------------------------------- }
function EdsRelease( inRef : EdsBaseRef ) : EdsUInt32 ; stdcall; external edsdk;


{
 ******************************************************************************
 ************************** Item Tree Handling Function ***********************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------
  Function : EdsGetChildCount

  Description:
       Gets the number of child objects of the designated object. 

  Parameters:
         In: inBaseRef - The reference of the list.
        Out: outCount  - Number of elements in this list.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
------------------------------------------------------------------------------- }
function EdsGetChildCount( inRef : EdsBaseRef;
                           var outCount : EdsUInt32 ) : EdsError ; stdcall; external edsdk;

{ -----------------------------------------------------------------------------
    Function : EdsGetChildAtIndex

    Description:
        Gets an indexed child object of the designated object. 

    Parameters:
          In: inRef      - The reference of the item.
              inIndex    - The index that is passed in, is zero based.
         Out: outBaseRef - The pointer which receives reference of the specified index.

    Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
------------------------------------------------------------------------------ }
function EdsGetChildAtIndex( inRef : EdsBaseRef ;
                             inIndex : EdsInt32 ;
                             var outBaseRef : EdsBaseRef ) : EdsError ; stdcall; external edsdk;

{ -----------------------------------------------------------------------------
    Function : EdsGetParent

    Description:
        Get the parent object.

    Parameters:
         In: inRef        - The reference of the item.
        Out: outParentRef - The pointer which receives reference.

    Returns: 
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
------------------------------------------------------------------------------ }
function EdsGetParent( inRef : EdsBaseRef;
                       var outParentRef : EdsBaseRef ) : EdsError ; stdcall; external edsdk;


{
 ******************************************************************************
 ******************************* Property Function ****************************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------
  Function : EdsGetPropertySize

  Description:
        Gets the byte size and data type of a designated property from a camera
        object or image object. 

  Parameters:
       In: inRef        - The reference of the item.
           inPropertyID - The ProprtyID
           inParam      - Additional information of property.
                          We use this parameter in order to specify an index
                          in case there are two or more values over the same ID.
      Out: outType     - Pointer to the buffer that is to receive the property type data.
           outSize     - Pointer to the buffer that is to receive the property size.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
------------------------------------------------------------------------------ }
function EdsGetPropertySize( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             inParam : EdsInt32;
                             var outDataType : EdsDataType;
                             var outSize : EdsUInt32 ) : EdsError ; stdcall; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsGetPropertyData

  Description:
        Gets property information from the object designated in inRef. 

  Parameters:
       In: inRef            - The reference of the item.
           inPropertyID     - The ProprtyID
           inParam          - Additional information of property.
                              We use this parameter in order to specify an index
                              in case there are two or more values over the same ID.
            inPropertySize  - The number of bytes of the prepared buffer
                              for receive property-value.
       Out: outPropertyData - The buffer pointer to receive property-value.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetPropertyData( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             inParam : EdsInt32;
                             inPropertySize : EdsUInt32;
//                             var outPropertyData : EdsUInt32 ) : EdsError ; stdcall; external edsdk;
                             var outPropertyData : Pointer ) : EdsError ; stdcall; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsSetPropertyData

  Description:
        Sets property data for the object designated in inRef.

  Parameters:
       In: inRef          - The reference of the item.
           inPropertyID   - The ProprtyID
           inParam        - Additional information of property.
           inPropertySize - The number of bytes of the prepared buffer for set
                            property-value.
           InPropertyData - The buffer pointer to set property-value.
      Out: none

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsSetPropertyData( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             inParam : EdsInt32;
                             inPropertySize : EdsUInt32;
                             InPropertyData : Pointer ) : EdsError; stdcall; external edsdk;

{ -----------------------------------------------------------------------------
  Function : EdsGetPropertyDesc

  Description:
        Gets a list of property data that can be set for the object designated
        in inRef, as well as maximum and minimum values. 
        This API is intended for only some shooting-related properties. 

  Parameters:
       In: inRef           - The reference of the camera.
           inPropertyID    - The Property ID.
           inPropertySize  - The number of bytes of the prepared buffer
                             for receive property-value.
      Out: outPropertyDesc - Array of the value which can be set up.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
        EDS_ERR_INVALID_PARAMETER is returned if a property ID is designated in
        inPropertyID that cannot be used with GetPropertyDesc.
-----------------------------------------------------------------------------}
function EdsGetPropertyDesc( inRef : EdsBaseRef;
                             inPropertyID : EdsPropertyID;
                             var outPropertyDesc : EdsPropertyDesc ) : EdsError; stdcall; external edsdk;

{
 ******************************************************************************
 ******************** Device List and Device Operation Function ***************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------
  Function : EdsGetCameraList

  Description:
        Get the camera list objects

  Parameters:
       In: None
      Out: outCameraListRef - the camera-list.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetCameraList( var outCameraListRef : EdsCameraListRef ) : EdsError ; stdcall; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsGetDeviceInfo

  Description:
        Get information as the device of the camera of the port number etc.
        Device information can be acquired before OpenSession is done. 

  Parameters:
       In: inCameraRef   - The reference of the camera.
      Out: outDeviceInfo - Information as device of camera.
                             See EdsDeviceInfo structure in EDSDKType.pas

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetDeviceInfo( inCameraRef : EdsCameraRef; var outDeviceInfo : EdsDeviceInfo) : EdsError ; stdcall ; external edsdk;


{
 ******************************************************************************
 ************************* Camera Operation Function **************************
 ******************************************************************************
}
{-----------------------------------------------------------------------------
  Function : EdsOpenSession

  Description:
       Establishes a logical connection with a remote camera. 

  Parameters:
       In: inCameraRef - The reference of the camera 
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsOpenSession( inCameraRef : EdsCameraRef) : EdsError ; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsCloseSession

  Description:
       Closes a logical connection with a remote camera.

  Parameters:
       In:    inCameraRef - The reference of the camera 
      Out:    None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsCloseSession( inCameraRef : EdsCameraRef ) : EdsError ; stdcall; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsSendCommand

  Description:
       Send the specified command to to the camera.

  Parameters:
       In: inCameraRef - The reference of the camera which will receive the command.
           inCommand   - Specifies the command to be sent.
           inParam     - Specifies additional command-specific information.
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsSendCommand( inCameraRef : EdsCameraRef;
                         inCommand   : EdsCameraCommand;
                         inParam : EdsInt32 ) : EdsError ; stdcall ; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsSendStatusCommand

  Description:
       Sets the remote camera state or mode.

  Parameters:
       In: inCameraRef     - The reference of the camera which will receive the 
                             command.
           inStatusCommand - Designate the particular mode ID to set the camera to.
           inParam         - Specifies additional command-specific information.
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsSendStatusCommand( inCameraRef     : EdsCameraRef;
                               inStatusCommand : EdsCameraStateCommand;
                               inParam : EdsInt32 ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsSetCapacity

  Description:
      Sets the remaining HDD capacity on the host computer (excluding the
      portion from image transfer), as calculated by subtracting the portion
      from the previous time.
      Set a reset flag initially and designate the cluster length and number of
      free clusters. 

  Parameters:
       In: inCameraRef - The reference of the camera which will receive the 
                         command.
           inCapacity  - Designate information regarding the host computer's hard
                         drive capacity. 
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsSetCapacity( inCameraRef : EdsCameraRef ; inCapacity : EdsCapacity ) : EdsError ; stdcall ; external edsdk;


{
 ******************************************************************************
 ************************* Volume Operation Function **************************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------
  Function : EdsGetVolumeInfo

  Description:
        Gets volume information for a memory card in the camera. 

  Parameters:
       In: EdsVolumeRef  - The reference of the volume to get volume information.
      Out: outDeviceInfo - Information of  the volume.
                             See EdsVolumeInfo structure in EDSDKType.h

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetVolumeInfo( inVolumeRef : EdsVolumeRef; var outVolumeInfo : EdsVolumeInfo ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsFormatVolume

  Description:
      Formats volumes of memory cards in a camera. 

  Parameters:
       In: inVolumeRef - reference of volume .
      Out: none

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsFormatVolume( inVolumeRef : EdsVolumeRef ) : EdsError ; stdcall ; external edsdk;

{
 ******************************************************************************
 ********************* Directory Item Operation Function **********************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------

  Function : EdsGetDirectoryItemInfo

  Description:
        Gets information about the directory or file objects on
        the memory card (volume) in a remote camera. 

  Parameters:
       In: inDirItemRef   - The reference of the directory item.
      Out: outDirItemInfo - Information of the directory item.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetDirectoryItemInfo( inDirItemRef : EdsDirectoryItemRef ;
                                  var outDirItemInfo : EdsDirectoryItemInfo ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------

  Function : EdsDeleteDirectoryItem

  Description:
        Deletes a camera folder or file. 
        If folders with subdirectories are designated, all files are deleted
        except protected files. 
        EdsDirectoryItem objects deleted by means of this API are implicitly
        released by the EDSDK.
        Thus, there is no need to release them by means of EdsRelease. 

  Parameters:
       In: inDirItemRef - The reference of the directory item.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsDeleteDirectoryItem( inDirItemRef : EdsDirectoryItemRef ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsDownload

  Description:
        Downloads a file on a remote camera (in the camera memory or on a memory
        card) to the host computer.
        The downloaded file is sent directly to a file stream created in advance.
        When dividing the file being retrieved, call this API repeatedly.
        Also in this case, make the data block size a multiple of 512 (bytes),
        excluding the final block. 

  Parameters:
       In: inDirItemRef - The reference of the directory item.
           inReadSize   - Size to read
           inDestStream - The reference of the stream to target.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsDownload ( inDirItemRef : EdsDirectoryItemRef; 
                       inReadSize : EdsUInt32 ;
                       inDestStream : EdsStreamRef ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsDownloadComplete

  Description:
        Must be called when downloading of directory items is complete.
        Executing this API makes the camera recognize that file transmission is complete. 
        This operation need not be executed when using EdsDownloadThumbnail. 

  Parameters:
       In: inDirItemRef - The reference of the directory item.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsDownloadComplete( inDirItemRef : EdsDirectoryItemRef ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------

  Function : EdsDownloadCancel

  Description:
        Must be executed when downloading of a directory item is canceled.
        Calling this API makes the camera cancel file transmission.
        It also releases resources. 
        This operation need not be executed when using EdsDownloadThumbnail.

  Parameters:
       In: inDirItemRef - The reference of the directory item.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsDownloadCancel( inDirItemRef : EdsDirectoryItemRef ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------
  Function : EdsDownloadThumbnail

  Description:
        Extracts and downloads thumbnail information from image files in a camera. 
        Thumbnail information in the camera's image files is downloaded to the host
        computer.  Downloaded thumbnails are sent directly to a file stream created
        in advance. 

  Parameters:
       In: inDirItemRef - The reference of the directory item.
           inDestStream - The reference of the stream to target.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsDownloadThumbnail( inDirItemRef : EdsDirectoryItemRef;
                               inDestStream : EdsStreamRef ) : EdsError ; stdcall ; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsGetAttribute

  Description:
        Gets attributes of files on a camera.

  Parameters:
       In: inDirItemRef - The reference of the directory item.
      Out: outFileAttribute  - Valueables to be stored  file sttributes


  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetAttribute( inDirItemRef : EdsDirectoryItemRef;
                          var outFileAttribute : EdsFileAttributes ) : EdsError ; stdcall ; external edsdk;

{-----------------------------------------------------------------------------
  Function:   EdsSetAttribute

  Description:
        Changes attributes of files on a camera.

  Parameters:
       In: inDirItemRef     - The reference of the directory item.
           inFileAttribute  - File attributes flag to be set


  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsSetAttribute( inDirItemRef : EdsDirectoryItemRef;
                          inFileAttribute : EdsFileAttributes ) : EdsError ; stdcall ; external edsdk;


{
 ******************************************************************************
 ************************ Stream Operation Function ***************************
 ******************************************************************************
}
{ -----------------------------------------------------------------------------

  Function : EdsCreateFileStream

  Description:
        Creates a new file on a host computer (or opens an existing file) and
        creates a file stream for access to the file. 
        If a new file is designated before executing this API, the file is
        actually created following the timing of writing by means of EdsWrite or
        the like with respect to an open stream.

  Parameters:
       In: inFileName          - Pointer to a null-terminated string that specifies
                                 the file name.
           inCreateDisposition - Action to take on files that exist, 
                                 and which action to take when files do not exist.  
           inDesiredAccess     - Access to the stream (reading, writing, or both).
      Out: outStream           - The reference of the stream.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsCreateFileStream( inFileName : PChar ;
                              inCreateDisposition : EdsFileCreateDisposition;
                              inDesiredAccess : EdsAccess ;
                              var outStream : EdsStreamRef ) : EdsError ; stdcall ; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsCreateMemoryStream

  Description:
        Creates a stream in the memory of a host computer. 
        In the case of writing in excess of the allocated buffer size,
        the memory is automatically extended.

  Parameters:
       In: inBufferSize - Number of bytes of the memory to allocate.
      Out: outStream    - The reference of the stream.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsCreateMemoryStream( inBufferSize : EdsUInt32 ; var outStream : EdsStreamRef ) : EdsError ; stdcall ; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsCreateFileStreamEx

  Description:
        An extended version of EdsCreateFileStream. 
        Use this function when working with Unicode file names.

  Parameters:
       In: inFileName          - Pointer to wide strings
           inCreateDisposition - Action to take on files that exist, 
                                 and which action to take when files do not exist.  
           inDesiredAccess     - Access to the stream (reading, writing, or both).
      Out: outStream           - reference of the stream.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsCreateFileStreamEx( inFileName : PWideChar ;
                                inCreateDisposition : EdsFileCreateDisposition ;
                                inDesiredAccess : EdsAccess ;
                                var outStream : EdsStreamRef ) : EdsError ; stdcall ; external edsdk;


{ -----------------------------------------------------------------------------

  Function : EdsCreateMemoryStreamFromPointer

  Description:
       Creates a stream from the memory buffer you prepare.
       Unlike the buffer size of streams created by means of EdsCreateMemoryStream,
       the buffer size you prepare for streams created this way does not expand.

  Parameters:
       In: inUserBuffer - Pointer to the buffer you have prepared
           inBufferSize - Number of bytes of the memory to allocate.
      Out: outStream    - The reference of the stream.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsCreateMemoryStreamFromPointer( inUserBuffer : Pointer;
                                           inBufferSize : EdsUInt32;
                                           var outStream : EdsStreamRef ) : EdsError ; stdcall ; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsGetPointer

  Description:
        Gets the pointer to the start address of memory managed by the memory stream. 
        As the EDSDK automatically resizes the buffer, the memory stream provides
        you with the same access methods as for the file stream.
        If access is attempted that is excessive with regard to the buffer size
        for the stream, data before the required buffer size is allocated is
        copied internally, and new writing occurs.
        Thus, the buffer pointer might be switched on an unknown timing.
        Caution in use is therefore advised. 

  Parameters:
       In:    inStream - object to memory stream
      Out:    outPointer - Pointer to valueable stored the pointer

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsGetPointer( inStream : EdsStreamRef;
                        var outPointer : Pointer ) : EdsError ; stdcall ; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsRead

  Description:
      Reads data the size of inReadSize into the outBuffer buffer, starting at
      the current read or write position of the stream.
      The size of data actually read can be designated in outReadSize. 

  Parameters:
       In: inStreamRef - The reference of the stream or image.
           inReadSize  - Number of bytes to read.
      Out: outBuffer   - Pointer to the user-supplied buffer that is to receive
                            the data read from the stream. 
           outReadSize - Actual read number of bytes.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsRead( inStreamRef : EdsStreamRef;
                  inReadSize : EdsUInt32;
                  var outBuffer : Pointer;
                  var outReadSize : EdsUInt32) : EdsError; stdcall; external edsdk;

{-----------------------------------------------------------------------------
  Function : EdsWrite

  Description:
      Writes data of a designated buffer to the current read or write position of the stream. 

  Parameters:
       In: inStreamRef  - The reference of the stream or image.
           inWriteSize  - Number of bytes to write.
           inBuffer     - Pointer to the user-supplied buffer that contains 
                          the data to be written to the stream.
      Out: outWrittenSize - Actual written-in number of bytes.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsWrite( inStreamRef : EdsStreamRef;
                   inWriteSize : EdsUInt32;
                   const inBuffer : Pointer;
                   var outWrittenSize : EdsUInt32 ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsSeek

  Description:
     Moves the read or write position of the stream (that is, the file position indicator).

  Parameters:
       In: inStreamRef  - The reference of the stream or image. 
           inSeekOffset - Number of bytes to move the pointer. 
           inSeekOrigin - Pointer movement mode. Must be one of the following values.

                  kEdsSeek_Cur     Move the stream pointer inSeekOffset bytes 
                                   from the current position in the stream.
                  kEdsSeek_Begin   Move the stream pointer inSeekOffset bytes
                                   forward from the beginning of the stream. 
                  kEdsSeek_End     Move the stream pointer inSeekOffset bytes
                                   from the end of the stream. 

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsSeek( inStreamRef  : EdsStreamRef;
                  inSeekOffset : EdsUInt32;
                  inSeekOrigin : EdsSeekOrigin ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsGetPosition

  Description:
        Gets the current read or write position of the stream (that is, the file position indicator). 

  Parameters:
       In: inStreamRef - The reference of the stream or image.
      Out: outPosition - Current stream pointer.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsGetPosition( inStreamRef : EdsStreamRef;
                         var outPosition : EdsUInt32 ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------

  Function : EdsGetLength

  Description:
      Get the length of the stream in bytes.

  Parameters:
       In: inStreamRef - The reference of the stream or image.
      Out: outLength   - Length of the stream.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsGetLength( inStreamRef : EdsStreamRef;
                       var outLength : EdsUInt32 ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsCopyData

  Description:
        Copies data from the copy source stream to the copy destination stream.
        The read or write position of the data to copy is determined from the
        current file read or write position of the respective stream. 
        After this API is executed, the read or write positions of the copy
        source and copy destination streams are moved an amount corresponding to
        inWriteSize in the positive direction. 


  Parameters:
       In: inSrcStreamRef  - The reference of the source stream.
           inWriteSize     - number of bytes to copy.
           inDestStreamRef - The reference of the destination stream.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsCopyData( inSrcStreamRef : EdsStreamRef;
                      inWriteSize : EdsUInt32;
                      inDestStreamRef : EdsStreamRef ) : EdsError; stdcall; external edsdk;

{
 ******************************************************************************
 ************************* Setup Operation Function ***************************
 ******************************************************************************
}
{-----------------------------------------------------------------------------
  Function : EdsSetProgressCallback

  Description:
        Register a progress callback function. 
        An event is received as notification of progress during processing
        that takes a relatively long time, such as downloading files from a
        remote camera.
        If you register the callback function, the EDSDK calls the callback
        function during execution or on completion of the following APIs

        This timing can be used in updating on-screen progress bars, for example. 
            APIs : EdsCopyData, EdsDownload, EdsGetImage

  Parameters:
       In: inRef              - The reference of the stream or image.
           inProgressCallback - Pointer to a progress callback function.
           inProgressOption   - Option about progress is specified.
                                this must be set one of the following values.

                        kEdsProgressOption_Done 
                                When processing is completed,a callback function
                                is called only at once.
                        kEdsProgressOption_Periodically
                                A callback function is performed periodically.

            inContext         - Specifies an application-defined value to be sent to
                                the callback function pointed to by CallBack parameter.
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsSetProgressCallback( inRef : EdsBaseRef;
                                 inProgressCallback : EdsProgressCallback;
                                 inProgressOption : EdsProgressOption;
                                 inContext : EdsUInt32 ) : EdsError; stdcall; external edsdk;


{
 ******************************************************************************
 ************************* Image Operation Function ***************************
 ******************************************************************************
}
{-----------------------------------------------------------------------------
  Function : EdsCreateImageRef

  Description:
        Creates an image object from an image file. 
        Without modification, stream objects cannot be worked with as images.
        Thus, when extracting images from image files, you must use this API 
        to create image objects. 
        The image object created this way can be used to get image information
        (such as the height and width, number of color components, and resolution),
        thumbnail image data, and the image data itself. 

  Parameters:
        In: inStreamRef - The reference of the stream.
       Out: outImageRef - The reference of the image.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsCreateImageRef( inStreamRef : EdsStreamRef;
                            var outImageRef : EdsImageRef ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsGetImageInfo

  Description:
        Gets image information from a designated image object. 
        Here, image information means the image width and height, number of
        color components, resolution, and effective image area. 
        See EdsImageInfo definition of EDSDKType.pas

  Parameters:
        In: inImageRef    - The reference of the image.
            inImageSource - Specfies kind of image - thumbnail, preview, fullview
       Out: outImageInfo  - Infomaiton of the image.

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
----------------------------------------------------------------------------- }
function EdsGetImageInfo( inImageRef : EdsImageRef;
                          inImageSource : EdsImageSource;
                          var outImageInfo : EdsImageInfo ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsGetImage

  Description:
        Gets designated image data from an image file, in the form of a
        designated rectangle. 
        Returns uncompressed results for JPEGs and processed results in the
        designated pixel order (RGB, Top-down BGR, and so on) for RAW images.
        Additionally, by designating the input/output rectangle, it is
        possible to get reduced, enlarged, or partial images.
        However, because images corresponding to the designated output
        rectangle are always returned by the SDK, the SDK does not take the
        aspect ratio into account.
        To maintain the aspect ratio, you must keep the aspect ratio in mind
        when designating the rectangle. 

  Parameters:
       In: inImageRef    : The reference of image object
           inImageSource : Specfies kind of image - thumbnail, preview, fullview
           inImageType   : Specifies image type ID number
           inSrcRect     : Rectangle of the source image
           inDstSize     : Designate the rectangle size for output. 
      Out: outStreamRef  : The reference of memory stream

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsGetImage( inImageRef : EdsImageRef;
                      inImageSource : EdsImageSource;
                      inImageType : EdsTargetImageType;
                      inSrcRect : EdsRect;
                      inDstSize : EdsSize;
                      inStreamRef : EdsStreamRef ) : EdsError ; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsSaveImage

  Description:
        Saves as a designated image type after RAW processing. 
        When saving with JPEG compression, the JPEG quality setting applies
        with respect to EdsOptionRef. 

  Parameters:
       In: inImageRef   : The reference of image
           inImageType  : Specifies image format ID number
           inSaveOption : Specifies save option < including JPEG quality >
      Out: outStreamRef : The reference of file stream

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsSaveImage( inImageRef : EdsImageRef;
                       inImageType : EdsTargetImageType;
                       inSaveSetting : EdsSaveImageSetting;
                       var outStreamRef : EdsStreamRef ): EdsError ; stdcall ; external edsdk;
                       

{-----------------------------------------------------------------------------
  Function : EdsCacheImage

  Description:
        Switches a setting on and off for creation of an image cache in the
        SDK for a designated image object during extraction (processing) of
        the image data.
        Creating the cache increases the processing speed, starting from the
        second time. 

  Parameters:
       In: inImageRef - The reference of the image.
           inUseCache - Whether cache image data , If TRUE, cache image.
                        If FALSE, the cached image data will released.
      Out: none

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsCacheImage( inImageRef : EdsImageRef; inUseCache : EdsBool ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------
  Function : EdsReflectImageProperty

  Description:
        Incorporates image object property changes (effected by means of
        EdsSetPropertyData) in the stream. 

  Parameters:
       In: inImageRef  - The reference of the image.
      Out: none

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsReflectImageProperty( inImageRef : EdsImageRef ) : EdsError; stdcall; external edsdk;


{-----------------------------------------------------------------------------

  Function:   EdsCreateEvfImageRef         
  Description:
       Creates an object used to get the live view image data set. 

  Parameters:
      In:     inStreamRef - The stream reference which opened to get EVF JPEG image.
      Out:    outEvfImageRef - The EVFData reference.

  Returns:    Any of the sdk errors.
-----------------------------------------------------------------------------}
function EdsCreateEvfImageRef ( inStreamRef : EdsStreamRef;
				 var outEvfImageRef : EdsEvfImageRef ) : EdsError; stdcall; external edsdk;



{-----------------------------------------------------------------------------

  Function:   EdsDownloadEvfImage         
  Description:
		Downloads the live view image data set for a camera currently in live view mode.
		Live view can be started by using the property ID:kEdsPropertyID_Evf_OutputDevice and
		data:EdsOutputDevice_PC to call EdsSetPropertyData.
		In addition to image data, information such as zoom, focus position, and histogram data
		is included in the image data set. Image data is saved in a stream maintained by EdsEvfImageRef.
		EdsGetPropertyData can be used to get information such as the zoom, focus position, etc.
		Although the information of the zoom and focus position can be obtained from EdsEvfImageRef,
		settings are applied to EdsCameraRef.

  Parameters:
      In:     inCameraRef - The Camera reference.
      In:     inEvfImageRef - The EVFData reference.

  Returns:    Any of the sdk errors.
-----------------------------------------------------------------------------}
function EdsDownloadEvfImage ( inCameraRef : EdsCameraRef;
			       inEvfImageRef : EdsEvfImageRef) : EdsError; stdcall; external edsdk;

{
 ******************************************************************************
 *********************** Event Handler Setup Function *************************
 ******************************************************************************
}
{-----------------------------------------------------------------------------
  Function : EdsSetCameraAddedHandler

  Description:
        This function registers the callback function called when a camera is
        connected physically.

  Parameters:
       In: inCameraAddedHandler - Pointer to a callback function
                                  called when a camera is connected physically
           inContext            - Specifies an application-defined value to be sent to
                                  the callback function pointed to by CallBack parameter.
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function EdsSetCameraAddedHandler( inCameraAddedHandler : EdsCameraAddedHandler;
                                   inContext : EdsUInt32 ) : EdsError; stdcall; external edsdk;

{-----------------------------------------------------------------------------

  Function : EdsSetPropertyEventHandler
             EdsSetObjectEventHandler
             EdsSetCamerStateEventHandler

  Description:
       This function registers the callback function called when an event occurs
       to the camera.

    <>EdsSetPropertyEventHandler
            Registers a callback function for receiving status change notification
            events for property states on a camera.

    <>EdsSetObjectEventHandler
            Registers a callback function for receiving status change notification
            events for objects on a remote camera.
            Here, object means volumes representing memory cards, files and
            directories, and shot images stored in memory, in particular. 

    <>EdsSetCamerStateEventHandler
            Registers a callback function for receiving status change notification
            events for camera objects.

  Parameters:
       In: inCameraRef    - The reference of the camera.
           inEvent        - Event ID number ( PropertyEvent, ObjectEvent, StateEvent )
           inEventHandler - Pointer to a callback function
                            called when an event occurs to the camera.
           inContext      - Specifies an application-defined value to be sent to
                            the callback function pointed to by CallBack parameter.
      Out: None

  Returns:
        Returns EDS_ERR_OK if successful. In other cases, see EDSDKError.pas.
-----------------------------------------------------------------------------}
function  EdsSetPropertyEventHandler(
            inCameraRef : EdsCameraRef; 
            inEvent : EdsPropertyEvent;
            inPropertyEventHandler : Pointer;
            inContext : EdsUInt32 ) : EdsError; stdcall; external edsdk;

function  EdsSetObjectEventHandler(
            inCameraRef : EdsCameraRef;
            inEvent : EdsObjectEvent;
            inObjectEventHandler : Pointer;
            inContext : EdsUInt32 ) : EdsError; stdcall; external edsdk;

function  EdsSetCameraStateEventHandler(
            inCameraRef : EdsCameraRef;
            inEvent : EdsStateEvent;
            inStateEventHandler : Pointer;
            inContext : EdsUInt32 ) : EdsError; stdcall; external edsdk;

{-----------------------------------------------------------------------------

  Function:   EdsGetEvent

  Description:
      This function acquires an event.
      In console application, please call this function regularly to acquire
      the event from a camera.

  Parameters:
       In:    None
      Out:    None

  Returns:    Any of the sdk errors.
-----------------------------------------------------------------------------*}
function EdsGetEvent() : EdsError; stdcall; external edsdk;


implementation

end.

