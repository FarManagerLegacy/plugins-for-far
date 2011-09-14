unit UTypes;

{$i CommonDirectives.inc}

interface

uses
{$IFDEF UNICODE}
  PluginW;
{$ELSE}
  Plugin;
{$ENDIF}

var
  FARAPI: TPluginStartupInfo;
  FSF: TFarStandardFunctions;

type
{$IFDEF UNICODE}
  {$IFDEF D12UP} // Delphi 2009+
    TFarString = UnicodeString;
  {$ELSE}
    TFarString = WideString;
  {$ENDIF}
{$ELSE}
  TFarChar = AnsiChar;
  PFarChar = PAnsiChar;

  TFarString = AnsiString;

  {$IFDEF CPUX86_64}
  INT_PTR = PtrInt;
  LONG_PTR = PtrInt;
  DWORD_PTR = PtrUInt;
  SIZE_T = PtrUInt;
  {$ELSE}
  INT_PTR = Integer;
  LONG_PTR = Integer;
  DWORD_PTR = Cardinal;
  SIZE_T = Cardinal;
  {$ENDIF CPUX86_64}
{$ENDIF}

const
  cDelim: TFarString = '\';

function GetMsg(MsgId: Integer): PFarChar;
function GetMsgStr(MsgId: Integer): TFarString;

implementation

function GetMsg(MsgId: Integer): PFarChar;
begin
  Result:= FARAPI.GetMsg(FARAPI.ModuleNumber, Integer(MsgId));
end;

function GetMsgStr(MsgId: Integer): TFarString;
begin
  Result:= FARAPI.GetMsg(FARAPI.ModuleNumber, Integer(MsgId));
end;

end.

