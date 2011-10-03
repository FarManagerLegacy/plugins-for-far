unit UUtils;

{$i CommonDirectives.inc}

interface

uses
  Windows,
  Kol,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  Plugin,
{$ENDIF}
  UTypes;

const
  cOrder: TFarString = 'Order';
  cDivChar = '|';

type
  TCharArray = array of PFarChar;
  TStringArray = class
  private
    FStringArray: TCharArray;
    FCount: Integer;
    function GetString: TFarString;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Init(const Value: TFarString);
    procedure Clear;

    function Add(Index: Integer; const Value: TFarString): PFarChar;
    procedure Delete(Index: Integer);
    procedure Swap(Index1, Index2: Integer);
    procedure Move(SrcIndex, DstIndex: Integer);

    property AsString: TFarString read GetString;
    property Count: Integer read FCount;
    property StringArray: TCharArray read FStringArray;
  end;

function DeleteRegKey(const delkey: TFarString): Boolean;
function CopyRegKey(const srckey, dstkey: TFarString; recurse: Boolean): Boolean;
function MoveRegKey(const srckey, dstkey: TFarString; copy: Boolean): Boolean;

function KeyExists(const key: TFarString): Boolean;
function ValueExists(const name, key: TFarString): Boolean;

function ReadRegDWORDValue(const name, key: TFarString; default: DWORD): DWORD;
procedure WriteRegDWORDValue(const name, key: TFarString; value: DWORD);

function ReadRegStringValue(const name, key, default: TFarString): TFarString;
procedure WriteRegStringValue(const name, key, value: TFarString);
procedure DeleteRegValue(const name, key: TFarString);
procedure CopyRegValue(const name, srckey, dstkey: TFarString; copy: Boolean);

function ReadRegBoolValue(const name, key: TFarString; default: Boolean): Boolean;
procedure WriteRegBoolValue(const name, key: TFarString; value: Boolean);
function ReadRegIntValue(const name, key: TFarString; default: Integer): Integer;
procedure WriteRegIntValue(const name, key: TFarString; value: Integer);

{$IFNDEF UNICODE}
function DeleteRegKey_(const delkey: TFarString): Boolean;
function CopyRegKey_(const srckey, dstkey: TFarString; recurse: Boolean): Boolean;
function MoveRegKey_(const srckey, dstkey: TFarString; copy: Boolean): Boolean;

function KeyExists_(const key: TFarString): Boolean;
function ValueExists_(const name, key: TFarString): Boolean;
function ReadRegDWORDValue_(const name, key: TFarString; default: DWORD): DWORD;
procedure WriteRegDWORDValue_(const name, key: TFarString; value: DWORD);
function ReadRegStringValue_(const name, key, default: TFarString): TFarString;
procedure WriteRegStringValue_(const name, key, value: TFarString);
procedure DeleteRegValue_(const name, key: TFarString);
procedure CopyRegValue_(const name, srckey, dstkey: TFarString; copy: Boolean);

function OemToCharStr(const str: TFarString): TFarString;
function CharToOemStr(const str: TFarString): TFarString;
{$ENDIF}

{$IFDEF UNICODE}
function CharToWideChar(const str: PAnsiChar; CodePage: UINT = CP_ACP): WideString;
{$ENDIF}

function GetOk(Number: Integer): Integer;

function ShowMessage(const title, text: PFarChar;
  flags: Cardinal = 0): Integer; overload;
function ShowMessage(const title, text: PFarChar; buttons: array of PFarChar;
  flags: Cardinal = 0): Integer; overload;

function NewID: String;

function Format(const fmt: TFarString; params: array of const): TFarString;
function itoa64(Value: Int64): TFarString;
function FormatFileSize(Value: Int64): TFarString;
function Format3(Value: Int64): TFarString;

function AddEndSlash(const path: TFarString): TFarString;

{$IFDEF UNICODE}
function RegEnumValueW(hKey: HKEY; dwIndex: DWORD; lpValueName: PWideChar;
  var lpcbValueName: DWORD; lpReserved: Pointer; lpType: PDWORD;
  lpData: PByte; lpcbData: PDWORD): Longint; stdcall;
{$ENDIF}

function PosEx(const SubStr, S: TFarString; Offset: Cardinal = 1): Integer;
procedure FreeAndNil(var Obj);
procedure FreeAndNilKol(var Obj); 
function StringReplace(const S, OldPattern, NewPattern: TFarString;
  ReplaceAll: Boolean): TFarString;
function FarRootKey: TFarString;

{.$DEFINE OUT_LOG}
{$IFDEF RELEASE}
  {$UNDEF OUT_LOG}
{$ENDIF}
{$IFDEF OUT_LOG}
var
  LogFile: TextFile;
{$ENDIF}

implementation

{$IFDEF UNICODE}
function CharToWideChar(const str: PAnsiChar; CodePage: UINT): WideString;
var
  bufsize: Integer;
begin
  bufsize := MultiByteToWideChar(CodePage, MB_PRECOMPOSED, str, -1, nil, 0);
  if bufsize > 1 then
  begin
    SetLength(Result, bufsize - 1);
    MultiByteToWideChar(CodePage, MB_PRECOMPOSED, str, -1, PWideChar(Result),
      bufsize);
  end
  else
    Result := '';
end;
{$ENDIF}

{$IFNDEF UNICODE}
function OemToCharStr(const str: TFarString): TFarString;
begin
  Result := str;
  if Result <> '' then
    OemToCharBuffA(PFarChar(Result), PFarChar(Result), Length(Result));
end;

function CharToOemStr(const str: TFarString): TFarString;
begin
  Result := str;
  if Result <> '' then
    CharToOemBuffA(PFarChar(Result), PFarChar(Result), Length(Result));
end;
{$ENDIF}

function KeyExists(const key: TFarString): Boolean;
{$IFNDEF UNICODE}
begin
  Result := KeyExists_(OemToCharStr(key));
end;

function KeyExists_(const key: TFarString): Boolean;
{$ENDIF}
var
  TempKey: HKEY;
begin
{$IFDEF UNICODE}
  Result := RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS;
{$ELSE}
  Result := RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS;
{$ENDIF}
  RegCloseKey(TempKey);
end;

function ValueExists(const name, key: TFarString): Boolean;
{$IFNDEF UNICODE}
begin
  Result := ValueExists_(OemToCharStr(name), OemToCharStr(key));
end;

function ValueExists_(const name, key: TFarString): Boolean;
{$ENDIF}
var
  TempKey: HKEY;
begin
  Result := False;
{$IFDEF UNICODE}
  if RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS then
{$ELSE}
  if RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS then
{$ENDIF}
  begin
    try
{$IFDEF UNICODE}
      Result := RegQueryValueExW(TempKey, PFarChar(name), nil, nil, nil, nil) =
        ERROR_SUCCESS;
{$ELSE}
      Result := RegQueryValueExA(TempKey, PFarChar(name), nil, nil, nil, nil) =
        ERROR_SUCCESS;
{$ENDIF}
    finally
      RegCloseKey(TempKey);
    end;
  end;
end;

function ReadRegDWORDValue(const name, key: TFarString; default: DWORD): DWORD;
{$IFNDEF UNICODE}
begin
  Result := ReadRegDWORDValue_(OemToCharStr(name), OemToCharStr(key), default);
end;

function ReadRegDWORDValue_(const name, key: TFarString; default: DWORD): DWORD;
{$ENDIF}
var
  TempKey: HKEY;
  bufsize: DWORD;
  datatype: DWORD;
begin
  Result := default;
{$IFDEF UNICODE}
  if RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS then
{$ELSE}
  if RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS then
{$ENDIF}
  begin
    try
      datatype := REG_DWORD;
{$IFDEF UNICODE}
      if RegQueryValueExW(TempKey, PFarChar(name), nil, @datatype, nil,
        @bufsize) = ERROR_SUCCESS then
{$ELSE}
      if RegQueryValueExA(TempKey, PFarChar(name), nil, @datatype, nil,
        @bufsize) = ERROR_SUCCESS then
{$ENDIF}
      begin
        try
{$IFDEF UNICODE}
          if RegQueryValueExW(TempKey, PFarChar(name), nil, @datatype,
              PByte(@Result), @bufsize) = ERROR_SUCCESS then
{$ELSE}
          if RegQueryValueExA(TempKey, PFarChar(name), nil, @datatype,
              PByte(@Result), @bufsize) = ERROR_SUCCESS then
{$ENDIF}
        finally
        end;
      end;
    finally
      RegCloseKey(TempKey);
    end;
  end;
end;

procedure WriteRegDWORDValue(const name, key: TFarString; value: DWORD);
{$IFNDEF UNICODE}
begin
  WriteRegDWORDValue_(OemToCharStr(name), OemToCharStr(key), value);
end;

procedure WriteRegDWORDValue_(const name, key: TFarString; value: DWORD);
{$ENDIF}
var
  TempKey: HKEY;
  disp: DWORD;
begin
{$IFDEF UNICODE}
  if RegCreateKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempKey, @disp) = ERROR_SUCCESS then
{$ELSE}
  if RegCreateKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempKey, @disp) = ERROR_SUCCESS then
{$ENDIF}
  begin
    try
{$IFDEF UNICODE}
      RegSetValueExW(TempKey, PFarChar(name), 0, REG_DWORD, PByte(value),
        SizeOf(value));
{$ELSE}
      RegSetValueExA(TempKey, PFarChar(name), 0, REG_DWORD, PByte(value),
        SizeOf(value));
{$ENDIF}
    finally
      RegCloseKey(TempKey);
    end;
  end;
end;

function ReadRegStringValue(const name, key, default: TFarString): TFarString;
{$IFNDEF UNICODE}
begin
  Result := CharToOemStr(ReadRegStringValue_(OemToCharStr(name),
    OemToCharStr(key), OemToCharStr(default)));
end;

function ReadRegStringValue_(const name, key, default: TFarString): TFarString;
{$ENDIF}
var
  TempKey: HKEY;
  buffer: PFarChar;
  bufsize: DWORD;
  datatype: DWORD;
begin
  Result := default;
{$IFDEF UNICODE}
  if RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS then
{$ELSE}
  if RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, KEY_READ,
    TempKey) = ERROR_SUCCESS then
{$ENDIF}
  begin
    try
      datatype := REG_SZ;
{$IFDEF UNICODE}
      if RegQueryValueExW(TempKey, PFarChar(name), nil, @datatype, nil,
        @bufsize) = ERROR_SUCCESS then
{$ELSE}
      if RegQueryValueExA(TempKey, PFarChar(name), nil, @datatype, nil,
        @bufsize) = ERROR_SUCCESS then
{$ENDIF}
      begin
        GetMem(buffer, bufsize);
        try
{$IFDEF UNICODE}
          if RegQueryValueExW(TempKey, PFarChar(name), nil, @datatype,
              PByte(buffer), @bufsize) = ERROR_SUCCESS then
{$ELSE}
          if RegQueryValueExA(TempKey, PFarChar(name), nil, @datatype,
              PByte(buffer), @bufsize) = ERROR_SUCCESS then
{$ENDIF}
            Result := buffer;
        finally
          FreeMem(Buffer);
        end;
      end;
    finally
      RegCloseKey(TempKey);
    end;
  end;
end;

procedure WriteRegStringValue(const name, key, value: TFarString);
{$IFNDEF UNICODE}
begin
  WriteRegStringValue_(OemToCharStr(name), OemToCharStr(key),
    OemToCharStr(value));
end;

procedure WriteRegStringValue_(const name, key, value: TFarString);
{$ENDIF}
var
  TempKey: HKEY;
  disp: DWORD;
begin
{$IFDEF UNICODE}
  if RegCreateKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempKey, @disp) = ERROR_SUCCESS then
{$ELSE}
  if RegCreateKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempKey, @disp) = ERROR_SUCCESS then
{$ENDIF}
  begin
    try
      if Value <> '' then
{$IFDEF UNICODE}
        RegSetValueExW(TempKey, PFarChar(name), 0, REG_SZ, PByte(value),
          (Length(Value) + 1) * 2)
      else
        RegSetValueExW(TempKey, PFarChar(name), 0, REG_SZ, nil, 0);
{$ELSE}
        RegSetValueExA(TempKey, PFarChar(name), 0, REG_SZ, PByte(value),
          Length(Value) + 1)
      else
        RegSetValueExA(TempKey, PFarChar(name), 0, REG_SZ, nil, 0);
{$ENDIF}
    finally
      RegCloseKey(TempKey);
    end;
  end;
end;

function ReadRegBoolValue(const name, key: TFarString; default: Boolean): Boolean;
var
  DefaultStr: TFarString;
begin
  if default then
    DefaultStr := '1'
  else
    DefaultStr := '0';
  Result := FSF.atoi(PFarChar(ReadRegStringValue(name, key, DefaultStr))) <> 0;
end;

procedure WriteRegBoolValue(const name, key: TFarString; value: Boolean);
var
  ValueStr: TFarString;
begin
  if value then
    ValueStr := '1'
  else
    ValueStr := '0';
  WriteRegStringValue(name, key, ValueStr);
end;

function ReadRegIntValue(const name, key: TFarString; default: Integer): Integer;
var
  DefaultStr: array [0..32] of TFarChar;
begin
  FSF.itoa(default, DefaultStr, 10);
  Result := FSF.atoi(PFarChar(ReadRegStringValue(name, key, DefaultStr)));
end;

procedure WriteRegIntValue(const name, key: TFarString; value: Integer);
var
  ValueStr: array [0..32] of TFarChar;
begin
  FSF.itoa(value, ValueStr, 10);
  WriteRegStringValue(name, key, ValueStr);
end;

procedure DeleteRegValue(const name, key: TFarString);
{$IFNDEF UNICODE}
begin
  DeleteRegValue_(OemToCharStr(name), OemToCharStr(key));
end;

procedure DeleteRegValue_(const name, key: TFarString);
{$ENDIF}
var
  TempKey: HKEY;
  disp: DWORD;
begin
{$IFDEF UNICODE}
  if RegCreateKeyExW(HKEY_CURRENT_USER, PFarChar(key), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempKey, @disp) = ERROR_SUCCESS then
{$ELSE}
  if RegCreateKeyExA(HKEY_CURRENT_USER, PFarChar(key), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempKey, @disp) = ERROR_SUCCESS then
{$ENDIF}
  begin
    try
{$IFDEF UNICODE}
      RegDeleteValueW(TempKey, PFarChar(name));
{$ELSE}
      RegDeleteValueA(TempKey, PFarChar(name));
{$ENDIF}
    finally
      RegCloseKey(TempKey);
    end;
  end;
end;

procedure CopyRegValue(const name, srckey, dstkey: TFarString; copy: Boolean);
{$IFNDEF UNICODE}
begin
  CopyRegValue_(OemToCharStr(name), OemToCharStr(srckey), OemToCharStr(dstkey),
    copy);
end;

procedure CopyRegValue_(const name, srckey, dstkey: TFarString; copy: Boolean);
{$ENDIF}
begin
{$IFDEF UNICODE}
  WriteRegStringValue(name, dstkey, ReadRegStringValue(name, srckey, ''));
  if not copy then
    DeleteRegValue(name, srckey);
{$ELSE}
  WriteRegStringValue_(name, dstkey, ReadRegStringValue_(name, srckey, ''));
  if not copy then
    DeleteRegValue_(name, srckey);
{$ENDIF}
end;

function DeleteRegKey(const delkey: TFarString): Boolean;
{$IFNDEF UNICODE}
begin
  Result := DeleteRegKey_(OemToCharStr(delkey));
end;

function DeleteRegKey_(const delkey: TFarString): Boolean;
{$ENDIF}
var
  TempKey: HKEY;
  keyindex: Cardinal;
  keysize: Cardinal;
  key: array[0 .. MAX_PATH - 1] of TFarChar;
begin
  Result := True;
{$IFDEF UNICODE}
  if RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(delkey), 0, KEY_READ, TempKey) =
    ERROR_SUCCESS then
{$ELSE}
  if RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(delkey), 0, KEY_READ, TempKey) =
    ERROR_SUCCESS then
{$ENDIF}
  begin
    try
      keysize := MAX_PATH;
      keyindex := 0;
{$IFDEF UNICODE}
      while RegEnumKeyExW(TempKey, keyindex, key, keysize, nil, nil, nil, nil) = ERROR_SUCCESS do
{$ELSE}
      while RegEnumKeyExA(TempKey, keyindex, key, keysize, nil, nil, nil, nil) = ERROR_SUCCESS do
{$ENDIF}
      begin
        if not DeleteRegKey(delkey + cDelim + key) then
        begin
          Result := False;
          Break;
        end;
        keysize := MAX_PATH;
      end;
    finally
      RegCloseKey(TempKey);
    end;
    if Result then
{$IFDEF UNICODE}
      Result := RegDeleteKeyW(HKEY_CURRENT_USER, PFarChar(delkey)) = ERROR_SUCCESS;
{$ELSE}
      Result := RegDeleteKeyA(HKEY_CURRENT_USER, PFarChar(delkey)) = ERROR_SUCCESS;
{$ENDIF}
  end
  else
    Result := False;
end;

function CopyRegKey(const srckey, dstkey: TFarString; recurse: Boolean): Boolean;
{$IFNDEF UNICODE}
begin
  Result := CopyRegKey_(OemToCharStr(srckey), OemToCharStr(dstkey), recurse);
end;

function CopyRegKey_(const srckey, dstkey: TFarString; recurse: Boolean): Boolean;
{$ENDIF}
const
  MAX_VALUE_NAME = 255;
var
  TempWriteKey, TempReadKey: HKEY;
  buffer: PByte;
  bufsize, datatype, disp: DWORD;
  valueindex, keyindex: Cardinal;
  valuesize, keysize: Cardinal;
  value: array[0..MAX_VALUE_NAME-1] of TFarChar;
  key: array[0..MAX_PATH-1] of TFarChar;
begin
  Result := True;
{$IFDEF UNICODE}
  if RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(srckey), 0, KEY_READ,
    TempReadKey) = ERROR_SUCCESS then
{$ELSE}
  if RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(srckey), 0, KEY_READ,
    TempReadKey) = ERROR_SUCCESS then
{$ENDIF}
  try
{$IFDEF UNICODE}
    if RegCreateKeyExW(HKEY_CURRENT_USER, PFarChar(dstkey), 0, nil,
      REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempWriteKey, @disp) =
      ERROR_SUCCESS then
{$ELSE}
    if RegCreateKeyExA(HKEY_CURRENT_USER, PFarChar(dstkey), 0, nil,
      REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, TempWriteKey, @disp) =
      ERROR_SUCCESS then
{$ENDIF}
    begin
      try
        valueindex := 0;
        valuesize := MAX_VALUE_NAME;
{$IFDEF UNICODE}
        while RegEnumValueW(TempReadKey, valueindex, value, valuesize, nil, nil,
          nil, nil) = ERROR_SUCCESS do
{$ELSE}
        while RegEnumValueA(TempReadKey, valueindex, value, valuesize, nil, nil,
          nil, nil) = ERROR_SUCCESS do
{$ENDIF}
        begin
          bufsize := 0;
{$IFDEF UNICODE}
          if RegQueryValueExW(TempReadKey, value, nil, @datatype, nil, @bufsize) =
            ERROR_SUCCESS then
{$ELSE}
          if RegQueryValueExA(TempReadKey, value, nil, @datatype, nil, @bufsize) =
            ERROR_SUCCESS then
{$ENDIF}
          begin
            GetMem(buffer, bufsize);
            try
{$IFDEF UNICODE}
              if RegQueryValueExW(TempReadKey, value, nil, @datatype, buffer,
                  @bufsize) = ERROR_SUCCESS then
                RegSetValueExW(TempWriteKey, value, 0, datatype, buffer, bufsize)
{$ELSE}
              if RegQueryValueExA(TempReadKey, value, nil, @datatype, buffer,
                  @bufsize) = ERROR_SUCCESS then
                RegSetValueExA(TempWriteKey, value, 0, datatype, buffer, bufsize)
{$ENDIF}
              else
              begin
                Result := False;
                Break;
              end;
            finally
              FreeMem(buffer);
            end;
          end;
          valuesize := MAX_VALUE_NAME;
          Inc(valueindex);
        end;
      finally
        RegCloseKey(TempWriteKey);
      end;

      if recurse and Result then
      begin
        keysize := MAX_PATH;
        keyindex := 0;
{$IFDEF UNICODE}
        while RegEnumKeyExW(TempReadKey, keyindex, key, keysize, nil, nil, nil,
          nil) = ERROR_SUCCESS do
{$ELSE}
        while RegEnumKeyExA(TempReadKey, keyindex, key, keysize, nil, nil, nil,
          nil) = ERROR_SUCCESS do
{$ENDIF}
        begin
          if not CopyRegKey(srckey + cDelim + key,
            dstkey + cDelim + key, True) then
          begin
            Result := False;
            Break;
          end;
          Inc(keyindex);
          keysize := MAX_PATH;
        end;
      end;
    end
    else
      Result := False;
  finally
    RegCloseKey(TempReadKey);
  end
  else
    Result := False;
end;

function MoveRegKey(const srckey, dstkey: TFarString; copy: Boolean): Boolean;
{$IFNDEF UNICODE}
begin
  Result := MoveRegKey_(OemToCharStr(srckey), OemToCharStr(dstkey), copy);
end;

function MoveRegKey_(const srckey, dstkey: TFarString; copy: Boolean): Boolean;
{$ENDIF}
var
  TempKey: HKEY;
begin
  Result := False;
{$IFDEF UNICODE}
  if RegOpenKeyExW(HKEY_CURRENT_USER, PFarChar(dstkey), 0, KEY_READ,
      TempKey) = ERROR_SUCCESS then
{$ELSE}
  if RegOpenKeyExA(HKEY_CURRENT_USER, PFarChar(dstkey), 0, KEY_READ,
      TempKey) = ERROR_SUCCESS then
{$ENDIF}
    RegCloseKey(TempKey)
  else
  begin
    Result := CopyRegKey(srckey, dstkey, True);
    if not copy and Result then
      Result := DeleteRegKey(srckey);
  end;
end;

function CoCreateGuid(out guid: TGUID): HResult; stdcall; external 'ole32.dll' name 'CoCreateGuid';

function CreateGUID(out Guid: TGUID): HResult;
begin
  Result := CoCreateGuid(Guid);
end;

function StringFromCLSID(const clsid: TGUID; out psz: PWideChar): HResult; stdcall;
  external 'ole32.dll' name 'StringFromCLSID';

procedure CoTaskMemFree(pv: Pointer); stdcall;
  external 'ole32.dll' name 'CoTaskMemFree';

function GUIDToString(const GUID: TGUID): string;
var
  P: PWideChar;
begin
  if not Succeeded(StringFromCLSID(GUID, P)) then
    Result := ''
  else
  begin
    Result := P;
    CoTaskMemFree(P);
  end;
end;

function GetOk(Number: Integer): Integer;
begin
  Number := Number mod 100;
  if (Number > 10) and (Number < 20) then
    Result := 3
  else
    case Number mod 10 of
      1: Result := 0;
      2..4: Result := 1;
      else Result := 2;
    end;
end;

function ShowMessage(const title, text: PFarChar;
  flags: Cardinal): Integer;
begin
  Result := ShowMessage(title, text, [], flags);
end;

function ShowMessage(const title, text: PFarChar; buttons: array of PFarChar;
  flags: Cardinal): Integer;
var
  str: TFarString;
  i, ButtonsNumber: Integer;
begin
  str := TFarString(title) + #10 + text;
  ButtonsNumber := Length(buttons);
  for i := 0 to ButtonsNumber - 1 do
    str := str + #10 + buttons[i];
  Result := FARAPI.Message(FARAPI.ModuleNumber, FMSG_ALLINONE or flags, nil,
    PPCharArray(@str[1]), 0, ButtonsNumber);
end;

function NewID: String;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  Result := GUIDToString(GUID);
end;

function Format(const fmt: TFarString; params: array of const): TFarString;
var
  Buffer: array[0..1023] of TFarChar;
  ElsArray, El: PDWORD;
  I: Integer;
  P: PDWORD;
begin
  ElsArray := nil;
  if High(params) >= 0 then
    GetMem(ElsArray, (High(params) + 1) * sizeof(Pointer));
  El := ElsArray;
  for I := 0 to High(params) do
  begin
    P := @params[I];
    P := Pointer(P^);
    El^ := DWORD(P);
    Inc(El);
  end;
{$IFDEF UNICODE}
  wvsprintfW(PFarChar(@Buffer[0]), PFarChar(fmt), Pointer(ElsArray));
{$ELSE}
  wvsprintfA(PFarChar(@Buffer[0]), PFarChar(fmt), Pointer(ElsArray));
{$ENDIF}
  Result := Buffer;
  if ElsArray <> nil then
    FreeMem(ElsArray);
end;

function itoa64(Value: Int64): TFarString;
var
  buf: array[0..63] of TFarChar;
begin
  FSF.itoa64(Value, buf, 10);
  Result := buf;
end;

function FormatFileSize(Value: Int64): TFarString;
var
  Suffix: TFarString;
begin
  {if Value < 1024 * 1024 then
    Suffix := 'B'
  else
  begin
    Value := Value div 1024;}
    if Value < 1024 * 1024 then
      Suffix := 'KB'
    else
    begin
      Value := Value div 1024;
      if Value < 1024 * 1024 then
        Suffix := 'MB'
      else
      begin
        Value := Value div 1024;
        Suffix := 'GB';
      end;
    end;
  {end;}
  Result := Format('%u %s', [Cardinal(Value), Suffix]);
end;

function Format3(Value: Int64): TFarString;
var
  intvalue: Integer;
begin
  Result := '';
  while Value > 1000 do
  begin
    intvalue := Value mod 1000;
    Result := ' ' + Format('%03d', [intvalue]) + Result;
    Value := Value div 1000;
  end;
  intvalue := Value;
  Result := Format('%d', [intvalue]) + Result;
end;

function AddEndSlash(const path: TFarString): TFarString;
begin
  Result := Path;
  if (Result <> '') and
      (Result[Length(path)] <> '\') and (Result[Length(path)] <> '/') then
    Result := Result + cDelim;
end;

{ TStringArray }

function TStringArray.Add(Index: Integer; const Value: TFarString): PFarChar;
begin
  if (Index >= FCount) or (Index < 0) then
    Index := FCount;
  Inc(FCount);
  SetLength(FStringArray, FCount);
  if (FCount > 1) and (Index < FCount - 1) then
    MoveMemory(@FStringArray[Index + 1], @FStringArray[Index],
      (FCount - Index - 1) * SizeOf(PFarChar));
{$IFDEF UNICODE}
  GetMem(FStringArray[Index], (Length(Value) + 1) * 2);
  WStrCopy(FStringArray[Index], PFarChar(Value));
{$ELSE}
  GetMem(FStringArray[Index], Length(Value) + 1);
  StrCopy(FStringArray[Index], PFarChar(Value));
{$ENDIF}
  Result := FStringArray[Index];
end;

procedure TStringArray.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    FreeMem(FStringArray[i]);
  SetLength(FStringArray, 0);
  FCount := 0;
end;

constructor TStringArray.Create;
begin
  inherited Create;
  FCount := 0;
end;

procedure TStringArray.Delete(Index: Integer);
begin
  if Index < FCount then
  begin
    FreeMem(FStringArray[Index]);
    if Index < FCount - 1 then
      MoveMemory(@FStringArray[Index], @FStringArray[Index + 1],
        (FCount - Index) * SizeOf(PFarChar));
    Dec(FCount);
    SetLength(FStringArray, FCount);
  end;
end;

destructor TStringArray.Destroy;
begin
  Clear;
  inherited;
end;

function PosEx(const SubStr, S: TFarString; Offset: Cardinal): Integer;
var
  I,X: Integer;
  Len, LenSubStr: Integer;
begin
  if Offset = 1 then
    Result := Pos(SubStr, S)
  else
  begin
    I := Offset;
    LenSubStr := Length(SubStr);
    Len := Length(S) - LenSubStr + 1;
    while I <= Len do
    begin
      if S[I] = SubStr[1] then
      begin
        X := 1;
        while (X < LenSubStr) and (S[I + X] = SubStr[X + 1]) do
          Inc(X);
        if (X = LenSubStr) then
        begin
          Result := I;
          exit;
        end;
      end;
      Inc(I);
    end;
    Result := 0;
  end;
end;

procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;

procedure FreeAndNilKol(var Obj);
var
  Temp: PObj;
begin
  Temp := PObj(Obj);
  Pointer(Obj) := nil;
  Temp^.Free;
end;

function StringReplace(const S, OldPattern, NewPattern: TFarString;
  ReplaceAll: Boolean): TFarString;
var
  SearchStr, Patt, NewStr: TFarString;
  Offset: Integer;
begin
  begin
    SearchStr := S;
    Patt := OldPattern;
  end;
  NewStr := S;
  Result := '';
  while SearchStr <> '' do
  begin
    Offset := Pos(Patt, SearchStr);
    if Offset = 0 then
    begin
      Result := Result + NewStr;
      Break;
    end;
    Result := Result + Copy(NewStr, 1, Offset - 1) + NewPattern;
    NewStr := Copy(NewStr, Offset + Length(OldPattern), MaxInt);
    if ReplaceAll then
    begin
      Result := Result + NewStr;
      Break;
    end;
    SearchStr := Copy(SearchStr, Offset + Length(Patt), MaxInt);
  end;
end;

function FarRootKey: TFarString;
begin
  Result := Copy(FARAPI.RootKey, 1, DelimiterLast(FARAPI.RootKey, cDelim) - 1);
end;

function TStringArray.GetString: TFarString;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FCount - 1 do
    Result := Result + FStringArray[i] + cDivChar;
end;

procedure TStringArray.Init(const Value: TFarString);
var
  p, p1: Integer;
  procedure SetString;
  var
    tstr: TFarString;
  begin
    if p = 0 then
      p := Length(Value) + 1;
    tstr := Copy(Value, p1, p - p1);
    if tstr <> '' then
    begin
      Inc(FCount);
      SetLength(FStringArray, FCount);
{$IFDEF UNICODE}
      GetMem(FStringArray[FCount - 1], (p - p1 + 1) * 2);
      WStrCopy(FStringArray[FCount - 1], PFarChar(tstr));
{$ELSE}
      GetMem(FStringArray[FCount - 1], p - p1 + 1);
      StrCopy(FStringArray[FCount - 1], PFarChar(tstr));
{$ENDIF}
    end;
  end;
begin
  if FCount > 0 then
    Clear;
  p1 := 1;
  p := Pos(cDivChar, Value);
  while p <> 0 do
  begin
    SetString;
    p1 := p + 1;
    p := PosEx(cDivChar, Value, p1);
  end;
  SetString;
end;

procedure TStringArray.Move(SrcIndex, DstIndex: Integer);
var
  p: PFarChar;
begin
  if SrcIndex <> DstIndex then
  begin
    if SrcIndex < DstIndex then
    begin
      if DstIndex = FCount then
      begin
        Dec(DstIndex);
        if SrcIndex = DstIndex then
          Exit;
      end;
      if DstIndex - SrcIndex = 1 then
        Swap(DstIndex, SrcIndex)
      else
      begin
        p := FStringArray[SrcIndex];
        MoveMemory(@FStringArray[SrcIndex], @FStringArray[SrcIndex + 1],
          (DstIndex - SrcIndex) * SizeOf(PFarChar));
        FStringArray[DstIndex] := p;
      end;
    end
    else
    begin
      if SrcIndex = FCount then
      begin
        Dec(SrcIndex);
        if SrcIndex = DstIndex then
          Exit;
      end;
      if SrcIndex - DstIndex = 1 then
        Swap(DstIndex, SrcIndex)
      else
      begin
        p := FStringArray[SrcIndex];
        MoveMemory(@FStringArray[DstIndex + 1], @FStringArray[DstIndex],
          (SrcIndex - DstIndex) * SizeOf(PFarChar));
        FStringArray[DstIndex] := p;
      end;
    end;
  end;
end;

procedure TStringArray.Swap(Index1, Index2: Integer);
var
  p: PFarChar;
begin
  if (Index1 < FCount) and (Index2 < FCount) then
  begin
    p := FStringArray[Index1];
    FStringArray[Index1] := FStringArray[Index2];
    FStringArray[Index2] := p;
  end;
end;

{$IFDEF UNICODE}
function RegEnumValueW; external advapi32 name 'RegEnumValueW';
{$ENDIF}

{$IFDEF OUT_LOG}
initialization

  AssignFile(LogFile, 'EOSBrowser.LOG');
  Rewrite(LogFile);

finalization
  Close(LogFile);
{$ENDIF}

end.
