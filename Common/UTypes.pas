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
  TFarString = WideString;
{$ELSE}
  TFarChar = Char;
  PFarChar = PAnsiChar;

  TFarString = AnsiString;

  INT_PTR = Integer;
  LONG_PTR = Integer;
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

