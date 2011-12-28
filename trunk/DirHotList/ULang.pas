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

    MOk,
    MCancel,

    MFooter,
    MMoveFooter,

    MNewShortcut,
    MEditShortcut,
    MDirectory,
    MDescription,

    MNewGroup,
    MEditGroup,
    MGroup,
    MMoveTo,
    MCantMove,

    MConfirmDelShortcut,
    MConfirmDelGroup
  );

const
  cHistoryPrefix = 'DHL_';

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
