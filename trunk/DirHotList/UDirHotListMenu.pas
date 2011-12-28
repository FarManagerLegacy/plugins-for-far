unit UDirHotListMenu;

{$i CommonDirectives.inc}

interface

uses
  Windows,
{$IFDEF UNICODE}
  {$IFDEF Far3}
  Plugin3,
  {$ELSE}
  PluginW,
  {$ENDIF}
{$ELSE}
  Plugin,
{$ENDIF}
  UTypes,
  UUtils,
  ULang,
  UDialogs,
  UMenu;

type
  TDirHotListMenu = class(TFarRegMenu)
  protected
    function IsGroupItem(Index: Integer): Boolean; override;
    function GetItemName(Index: Integer): TFarString; override;

    function EditMenuItem(Index: Integer; Action: TEditAction): Boolean;
      override;
    function ExecuteMenuItem(Index: Integer): Boolean; override;
    function DeleteMenuItem(Index: Integer): Boolean; override;
    function MoveMenuItem(FromIndex, ToIndex: Integer;
      ToSubKey: TFarString): Boolean; override;
  public
    constructor Create;
  end;

implementation

{ TDirHotListMenu }

constructor TDirHotListMenu.Create;
const
  cDirectoryHotlist: PFarChar = 'DirectoryHotlist';
  cMoveTo: PFarChar = 'MoveTo';
begin
  inherited Create(True, FARAPI.RootKey + cDelim + cDirectoryHotlist,
    GetMsg(MPluginTitle), GetMsg(MFooter), cDirectoryHotlist,
    GetMsg(MMoveTo), GetMsg(MMoveFooter), cMoveTo);
end;

function TDirHotListMenu.DeleteMenuItem(Index: Integer): Boolean;
var
  MessStr: TFarString;
  IsGroup: Boolean;
begin
  IsGroup := IsGroupItem(Index);
  if IsGroup then
    MessStr := GetMsgStr(MConfirmDelGroup)
  else
    MessStr := GetMsgStr(MConfirmDelShortcut);
  MessStr := GetMsgStr(MPluginTitle) + #10 + MessStr + #10 + ItemText[Index];
  Result := FARAPI.Message(FARAPI.ModuleNumber,
    FMSG_ALLINONE + FMSG_WARNING + FMSG_MB_OKCANCEL, nil,
    PPCharArray(@MessStr[1]), 0, 0) = 0;
  if Result then
  begin
    if IsGroup then
      DeleteRegKey(SubKey + cDelim + MenuOrder.StringArray[Index])
    else
      DeleteRegValue(MenuOrder.StringArray[Index], SubKey);
    MenuOrder.Delete(Index);
    WriteRegStringValue(cOrder, SubKey, MenuOrder.AsString);
  end;
end;

function TDirHotListMenu.EditMenuItem(Index: Integer;
  Action: TEditAction): Boolean;
const
  cSizeX = 70;
  cSizeY_G = 8;
  cSizeY_S = 10;
  cLeftSide = 5;

  cHGroup: PFarChar = cHistoryPrefix + 'Group';

  cHDirectory: PFarChar = cHistoryPrefix + 'Directory';
  cHDescription: PFarChar = cHistoryPrefix + 'Description';

  cShortcut: PFarChar = 'NewShortcut';
  cGroup: PFarChar = 'NewGroup';

{$IFDEF UNICODE}
  cGUIDGroup: TGUID = '{6196B533-4279-4AA4-8C14-5D635AFEE407}';
  cGUIDShortcut: TGUID = '{40CF1A65-1725-4E29-9ED5-C486BFB1EBD8}';
{$ENDIF}
var
  TitleId: TLanguageID;
  MenuDlg: TSimpleFarDialog;
  ItemName, ItemData: TFarString;
  p: Integer;
begin
  if (Action <> eaCreateItem) and
    ((Action = eaCreateGroup) or IsGroupItem(Index)) then
  begin
    if Action = eaCreateGroup then
    begin
      TitleId := MNewGroup;
      ItemName := '';
    end
    else
    begin
      TitleId := MEditGroup;
      ItemName := GetItemName(Index);
    end;
    MenuDlg := TSimpleFarDialog.Create([
        DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY_G, 0, PFarChar(TitleId)),
        DlgItem(DI_TEXT, cLeftSide, 2, -1, -1, 0, PFarChar(MGroup)),
        DlgItem(DI_EDIT, cLeftSide, 3, cSizeX - cLeftSide - 5, 0, DIF_HISTORY,
          PFarChar(ItemName), cHGroup),
        DlgItem(DI_TEXT, cLeftSide - 1, cSizeY_G - 4, cSizeX - cLeftSide, 0,
          DIF_SEPARATOR, ''),
        DlgItem(DI_BUTTON, 0, cSizeY_G - 3, 0, 0, DIF_CENTERGROUP, PFarChar(MOk),
          Pointer(True)),
        DlgItem(DI_BUTTON, 0, cSizeY_G - 3, 0, 0, DIF_CENTERGROUP, PFarChar(MCancel))
      ], -1, -1, cSizeX, cSizeY_G, cGroup {$IFDEF UNICODE}, cGUIDGroup{$ENDIF});
    try
      Result := MenuDlg.Execute = 4;
      if Result then
      begin
        if Action = eaCreateGroup then
        begin
          if Index < 0 then
            Index := 0;
          MenuOrder.Add(Index, NewID);
          WriteRegStringValue(cOrder, SubKey, MenuOrder.AsString);
        end;
        WriteRegStringValue('', SubKey + cDelim +
          MenuOrder.StringArray[Index], MenuDlg.ItemTextData[2]);
      end;
    finally
      MenuDlg.Free;
    end;
  end
  else
  begin
    if Action = eaCreateItem then
    begin
      TitleId := MNewShortcut;
      ItemName := '';
      ItemData := '';
    end
    else
    begin
      TitleId := MEditShortcut;
      ItemName := ReadRegStringValue(MenuOrder.StringArray[Index], SubKey, '');
      p := Pos(TFarString(cDivChar), TFarString(ItemName));
      if p > 0 then
      begin
        ItemData := Copy(ItemName, 1, p - 1);
        Delete(ItemName, 1, p);
      end
      else
        ItemData := ItemName;
    end;
    MenuDlg := TSimpleFarDialog.Create([
        DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY_S, 0, PFarChar(TitleId)),
        DlgItem(DI_TEXT, cLeftSide, 2, -1, -1, 0, PFarChar(MDirectory)),
        DlgItem(DI_EDIT, cLeftSide, 3, cSizeX - cLeftSide - 5, 0, DIF_HISTORY,
          PFarChar(ItemData), cHDirectory),
        DlgItem(DI_TEXT, cLeftSide, 4, -1, -1, 0, PFarChar(MDescription)),
        DlgItem(DI_EDIT, cLeftSide, 5, cSizeX - cLeftSide - 5, 0, DIF_HISTORY,
          PFarChar(ItemName), cHDescription),
        DlgItem(DI_TEXT, cLeftSide - 1, cSizeY_S - 4, cSizeX - cLeftSide, 0,
          DIF_SEPARATOR, ''),
        DlgItem(DI_BUTTON, 0, cSizeY_S - 3, 0, 0, DIF_CENTERGROUP, PFarChar(MOk),
          Pointer(True)),
        DlgItem(DI_BUTTON, 0, cSizeY_S - 3, 0, 0, DIF_CENTERGROUP, PFarChar(MCancel))
      ], -1, -1, cSizeX, cSizeY_S, cShortcut {$IFDEF UNICODE}, cGUIDShortcut{$ENDIF});
    try
      Result := MenuDlg.Execute = 6;
      if Result then
      begin
        if Action = eaCreateItem then
        begin
          if Index < 0 then
            Index := 0;
          MenuOrder.Add(Index, NewID);
          WriteRegStringValue(cOrder, SubKey, MenuOrder.AsString);
        end;
        WriteRegStringValue(MenuOrder.StringArray[Index], SubKey,
          MenuDlg.ItemTextData[2] + cDivChar + MenuDlg.ItemTextData[4]);
      end;
    finally
      MenuDlg.Free;
    end;
  end;
end;

function TDirHotListMenu.ExecuteMenuItem(Index: Integer): Boolean;
var
  ItemData: TFarString;
  p: Integer;
  command: TActlKeyMacro;
begin
  ItemData := ReadRegStringValue(MenuOrder.StringArray[Index], SubKey, '');
  p := Pos(cDivChar, ItemData);
  if p <> 0 then
  begin
    SetLength(ItemData, p - 1);
    p := Pos(':', ItemData);
    if p > 2 then
    begin
      command.Command := MCMD_POSTMACROSTRING;
      p := Length(ItemData);
      while p > 1 do
      begin
        Insert(' ', ItemData, p);
        Dec(p);
      end;
      ItemData := ItemData + ' Enter';
      command.Param.PlainText.SequenceText := PFarChar(ItemData);
      command.Param.PlainText.Flags := KSFLAGS_DISABLEOUTPUT;
      FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_KEYMACRO, @command);
    end
    else
      { TODO : Можно попробовать FSF.ExpandEnvironmentStr для
        раскрытия переменных окружения }
      FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_SETPANELDIR,
        {$IFDEF UNICODE}0,{$ENDIF} Pointer(ItemData));
  end;
  Result := False;
end;

function TDirHotListMenu.GetItemName(Index: Integer): TFarString;
var
  p: Integer;
begin
  if IsGroupItem(Index) then
    Result := ReadRegStringValue('',
      SubKey + cDelim + MenuOrder.StringArray[Index], '')
  else
  begin
    Result := ReadRegStringValue(MenuOrder.StringArray[Index], SubKey, '');
    p := Pos(cDivChar, Result);
    if p > 0 then
      Delete(Result, 1, p);
  end;
end;

function TDirHotListMenu.IsGroupItem(Index: Integer): Boolean;
begin
  Result := ReadRegStringValue('',
    subkey + '\' + MenuOrder.StringArray[Index], '') <> '';
end;

function TDirHotListMenu.MoveMenuItem(FromIndex, ToIndex: Integer;
  ToSubKey: TFarString): Boolean;
var
  ToMenuOrder: TStringArray;
  MessStr: TFarString;
begin
  Result := False;
  if SubKey = ToSubKey then
  begin
    if FromIndex <> ToIndex then
    begin
      MenuOrder.Move(FromIndex, ToIndex);
      WriteRegStringValue(cOrder, SubKey, MenuOrder.AsString);
      Result := True;
    end;
  end
  else
  begin
    if IsGroupItem(FromIndex) then
    begin
      if Pos(TFarString(SubKey + cDelim + MenuOrder.StringArray[FromIndex]), TFarString(ToSubKey)) = 0 then
        Result := MoveRegKey(SubKey + cDelim + MenuOrder.StringArray[FromIndex],
          ToSubKey, False)
      else
      begin
        MessStr := GetMsgStr(MPluginTitle) + #10 + GetMsgStr(MCantMove);
        FARAPI.Message(FARAPI.ModuleNumber,
          FMSG_ALLINONE + FMSG_WARNING + FMSG_MB_OK, nil,
          PPCharArray(@MessStr[1]), 0, 0);
      end;
    end
    else
    begin
      CopyRegValue(MenuOrder.StringArray[FromIndex], SubKey, ToSubKey, False);
      Result := True;
    end;
    if Result then
    begin
      ToMenuOrder := TStringArray.Create;
      try
        ToMenuOrder.Init(ReadRegStringValue(cOrder, ToSubKey, ''));
        ToMenuOrder.Add(ToIndex, MenuOrder.StringArray[FromIndex]);
        WriteRegStringValue(cOrder, ToSubKey, ToMenuOrder.AsString);
      finally
        ToMenuOrder.Free;
      end;
    end;
  end;
end;

end.
