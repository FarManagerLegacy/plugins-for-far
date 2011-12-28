unit UMenu;

{$i CommonDirectives.inc}

interface

uses
  Windows,
  Kol,
{$IFDEF UNICODE}
  {$IFDEF Far3}
  Plugin3,
  {$ELSE}
  PluginW,
  {$ENDIF}
  FarKeysW,
{$ELSE}
  Plugin,
  farkeys,
{$ENDIF}
  UTypes,
  UUtils;

{$DEFINE USEEXT}

type
  TFarMenuProc = function(MenuResult, BreakCode: Integer; var SelPos: Integer): Boolean of object;

{$IFDEF USEEXT}
  PFarMenuItemExArray = ^TFarMenuItemExArray;
  TFarMenuItemExArray = packed array[0..Pred(MaxLongint div SizeOf(TFarMenuItemEx))] of TFarMenuItemEx;
{$ENDIF}

  TFarMenu = class
  private
{$IFDEF USEEXT}
    FItemsEx: PFarMenuItemExArray;
{$ELSE}
    FItems: PFarMenuItemArray;
{$ENDIF}
    FItemsNumber: Integer;
    FBreakKeys: PIntegerArray;
    FX, FY, FMaxHeight: Integer;
    FFlags: Cardinal;
    FTitle, FBottom, FHelpTopic: PFarChar;
    FMenuProc: TFarMenuProc;
    function GetItemText(Index: Integer): PFarChar;
  protected
    property MenuProc: TFarMenuProc read FMenuProc write FMenuProc;
    procedure InitBreakKeys(ABreakKeys: array of Integer);

{$IFDEF USEEXT}
    procedure InitItemsEx(AItemsEx: array of TFarMenuItemEx); overload;
    procedure InitItemsEx(AItemsEx: array of TFarMenuItemEx;
      ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer); overload;
  {$IFDEF UNICODE}
    procedure InitItemsEx(AItemsEx: array of TFarString); overload;
    procedure InitItemsEx(AItemsEx: array of TFarString;
      ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer); overload;
  {$ELSE}
    procedure InitItemsEx(AItemsEx: array of TFarString;
      UsePtr: Boolean = False); overload;
    procedure InitItemsEx(AItemsEx: array of TFarString;
      ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer;
      UsePtr: Boolean = False); overload;
  {$ENDIF}
    property ItemsEx: PFarMenuItemExArray read FItemsEx;
{$ELSE}
    procedure InitItems(AItems: array of TFarMenuItem); overload;
    procedure InitItems(AItems: array of TFarMenuItem;
      ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer); overload;
    procedure InitItems(AItems: array of TFarString); overload;
    procedure InitItems(AItems: array of TFarString;
      ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer); overload;
    property Items: PFarMenuItemArray read FItems;
{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    function Execute: Integer;
    property Flags: Cardinal read FFlags write FFlags;
    property ItemsNumber: Integer read FItemsNumber;
    property ItemText[Index: Integer]: PFarChar read GetItemText;
  end;

  TSimpleFarMenu = class(TFarMenu)
  public
{$IFDEF USEEXT}
    constructor Create(AItemsEx: array of TFarMenuItemEx;
      ATitle: PFarChar = nil; ABottom: PFarChar = nil; AHelpTopic: PFarChar = nil;
      AX: Integer = -1; AY: Integer = -1; AMaxHeight: Integer = 0);
{$ELSE}
    constructor Create(AItems: array of TFarMenuItem;
      ATitle: PFarChar = nil; ABottom: PFarChar = nil; AHelpTopic: PFarChar = nil;
      AX: Integer = -1; AY: Integer = -1; AMaxHeight: Integer = 0);
{$ENDIF}
  end;

  PFarRegMenuInfo = ^TFarRegMenuInfo;
  TFarRegMenuInfo = record
    Key, Group: TFarString;
    Pos: Integer;
  end;
  TEditAction = (eaEdit, eaCreateItem, eaCreateGroup);
  TFarRegMenu = class(TFarMenu)
  private
    FInsertMode: Boolean;
    FWithGroups: Boolean;
    FMenuOrder: TStringArray;
{$IFDEF UNICODE}
    FMenuText: TStringArray;
{$ENDIF}
    FMenuInfo: PList;
    FCurMenuInfo, FMoveMenuInfo: Integer;
    FSubKey: TFarString;
    FCurGroup: TFarString;

    FTitle, FBottom, FHelpTopic: PFarChar;
    FMoveTitle, FMoveBottom, FMoveHelpTopic: PFarChar;
    FCurTitle: TFarString;
  private
    function AddMenuInfo: PFarRegMenuInfo;
    function DelMenuInfo: PFarRegMenuInfo;
    procedure ReadMenuItems;
    function RegMenuProc(MenuResult, BreakCode: Integer;
      var SelPos: Integer): Boolean;
  protected
    function IsGroupItem(Index: Integer): Boolean; virtual; abstract;
    function GetItemName(Index: Integer): TFarString; virtual; abstract;
    function EditMenuItem(Index: Integer; Action: TEditAction): Boolean;
      virtual; abstract;
    function ExecuteMenuItem(Index: Integer): Boolean; virtual; abstract;
    function DeleteMenuItem(Index: Integer): Boolean; virtual; abstract;
    function MoveMenuItem(FromIndex, ToIndex: Integer;
      ToSubKey: TFarString): Boolean; virtual; abstract;

    property SubKey: TFarString read FSubKey;
    property MenuOrder: TStringArray read FMenuOrder;
  public
    constructor Create(AWithGroups: Boolean; ASubkey: TFarString;
      ATitle: PFarChar = nil; ABottom: PFarChar = nil; AHelpTopic: PFarChar = nil;
      AMoveTitle: PFarChar = nil; AMoveBottom: PFarChar = nil;
      AMoveHelpTopic: PFarChar = nil);
    destructor Destroy; override;
    property InsertMode: Boolean read FInsertMode;
  end;

{$IFDEF USEEXT}
{$IFDEF UNICODE}
function MenuItemEx(AText: PFarChar; AFlags: DWORD = 0;
  AUserData: DWORD_PTR = 0): TFarMenuItemEx;
{$ELSE}
function MenuItemEx(AText: PFarChar; AFlags: DWORD = 0;
  AUserData: DWORD = 0): TFarMenuItemEx;
{$ENDIF}
{$ELSE}
function MenuItem(AText: PFarChar; ASelected: Integer = 0; AChecked: Integer = 0;
  ASeparator: Integer = 0): TFarMenuItem;
{$ENDIF}

implementation

{$IFNDEF UNICODE}
const
  cMenuDataLen = 127;
{$ENDIF}

function MenuItem(AText: PFarChar; ASelected, AChecked, ASeparator: Integer): TFarMenuItem;
begin
  ZeroMemory(@Result, SizeOf(Result));
  with Result do
  begin
{$IFDEF UNICODE}
    if DWORD(AText) < 2000 then
      TextPtr := GetMsg(DWORD(AText))
    else
      TextPtr := AText;
{$ELSE}
    if DWORD(AText) < 2000 then
      StrLCopy(Text, GetMsg(DWORD(AText)), cMenuDataLen)
    else
      StrLCopy(Text, AText, cMenuDataLen);
{$ENDIF}
    Selected := ASelected;
    Checked := AChecked;
    Separator := ASeparator;
  end;
end;

{$IFDEF UNICODE}
function MenuItemEx(AText: PFarChar; AFlags: DWORD;
  AUserData: DWORD_PTR): TFarMenuItemEx;
{$ELSE}
function MenuItemEx(AText: PFarChar; AFlags: DWORD;
  AUserData: DWORD): TFarMenuItemEx;
{$ENDIF}
begin
  ZeroMemory(@Result, SizeOf(Result));
  with Result do
  begin
    Flags := AFlags;
{$IFDEF UNICODE}
    if DWORD(AText) < 2000 then
      TextPtr := GetMsg(DWORD(AText))
    else
      TextPtr := AText;
{$ELSE}
    if Flags and MIF_USETEXTPTR <> 0 then
    begin
      if DWORD(AText) < 2000 then
        Text.TextPtr := GetMsg(DWORD(AText))
      else
        Text.TextPtr := AText;
      end
    else
    begin
      if DWORD(AText) < 2000 then
        StrLCopy(Text.Text, GetMsg(DWORD(AText)), cMenuDataLen)
      else
        StrLCopy(Text.Text, AText, cMenuDataLen);
    end;
{$ENDIF}
    UserData := AUserData;
  end;
end;

{ TFarMenu }

constructor TFarMenu.Create;
begin
  inherited Create;
  FBreakKeys := nil;
  FMenuProc := nil;
  FFlags := FMENU_CHANGECONSOLETITLE + FMENU_WRAPMODE
  {$IFDEF USEEXT} + FMENU_USEEXT{$ENDIF};
  {
  FMENU_AUTOHIGHLIGHT Если указан, то горячие клавиши будут назначены автоматически,
    начиная с первого пункта.
  FMENU_CHANGECONSOLETITLE Если указан, то FAR изменит заголовок консоли в значение,
    указанное в параметре Title (если Title не пуст).
  FMENU_SHOWAMPERSAND При показе меню не использовать амперсанды (&) для определения
    горячих клавиш.
  FMENU_REVERSEAUTOHIGHLIGHT Если указан, то горячие клавиши будут назначены автоматически,
    начиная с последнего пункта.
  FMENU_USEEXT Вместо структуры FarMenuItem использовать структуру FarMenuItemEx.
  FMENU_WRAPMODE Если указан, то попытка перемещения курсора выше первого пункта или
    ниже последнего будет приводить к перемещению соответственно к последнему или
    к первому пункту.
    Этот флаг рекомендуется ставить всегда, когда нет специальных причин его не ставить.
  }
end;

destructor TFarMenu.Destroy;
begin
{$IFDEF USEEXT}
  if Assigned(FItemsEx) then
    FreeMem(FItemsEx);
{$ELSE}
  if Assigned(FItems) then
    FreeMem(FItems);
{$ENDIF}
  FItemsNumber := 0;
  if Assigned(FBreakKeys) then
    FreeMem(FBreakKeys);
  inherited Destroy;
end;

function TFarMenu.Execute: Integer;
var
  MenuResult, BreakCode, SelPos: Integer;
{$IFNDEF USEEXT}
  i: Integer;
  keys: TKeySequence;
  seq: PDWORD;
{$ENDIF}
begin
  if Assigned(MenuProc) then
  begin
    SelPos := 0;
    repeat
{$IFDEF USEEXT}
      if (SelPos >= 0) and (SelPos < FItemsNumber) then
        FItemsEx[SelPos].Flags := FItemsEx[SelPos].Flags or MIF_SELECTED;
      MenuResult := FARAPI.Menu(FARAPI.ModuleNumber, FX, FY, FMaxHeight,
        FFlags, FTitle, FBottom, FHelpTopic, FBreakKeys, @BreakCode,
        PFarMenuItemArray(FItemsEx), FItemsNumber);
      if (SelPos >= 0) and (SelPos < FItemsNumber) then
        FItemsEx[SelPos].Flags := FItemsEx[SelPos].Flags and not MIF_SELECTED;
{$ELSE}
      if SelPos > 0 then
      begin
        keys.Flags := KSFLAGS_DISABLEOUTPUT;
        keys.Count := SelPos;
        GetMem(keys.Sequence, SelPos * SizeOf(DWORD));
        seq := Pointer(keys.Sequence);
        for i := 0 to SelPos - 1 do
        begin
          seq^ := KEY_DOWN;
          Inc(seq);
        end;
        FARAPI.AdvControl(FARAPI.ModuleNumber, ACTL_POSTKEYSEQUENCE, @keys);
        FreeMem(keys.Sequence);
      end;
      MenuResult := FARAPI.Menu(FARAPI.ModuleNumber, FX, FY, FMaxHeight,
        FFlags, FTitle, FBottom, FHelpTopic, FBreakKeys, @BreakCode, FItems,
        FItemsNumber);
{$ENDIF}
    until not MenuProc(MenuResult, BreakCode, SelPos);
    Result := MenuResult;
  end
  else
{$IFDEF USEEXT}
    Result := FARAPI.Menu(FARAPI.ModuleNumber, FX, FY, FMaxHeight, FFlags,
      FTitle, FBottom, FHelpTopic, FBreakKeys, @BreakCode,
      PFarMenuItemArray(FItemsEx), FItemsNumber);
{$ELSE}
    Result := FARAPI.Menu(FARAPI.ModuleNumber, FX, FY, FMaxHeight, FFlags,
      FTitle, FBottom, FHelpTopic, FBreakKeys, @BreakCode, FItems, FItemsNumber);
{$ENDIF}
end;

procedure TFarMenu.InitBreakKeys(ABreakKeys: array of Integer);
var
  i, BreakKeysNumber: Integer;
  Key: PInteger;
begin
  BreakKeysNumber := Length(ABreakKeys);
  GetMem(FBreakKeys, (BreakKeysNumber + 1) * SizeOf(Integer));
  ZeroMemory(FBreakKeys, (BreakKeysNumber + 1) * SizeOf(Integer));
  Key := @FBreakKeys[0];
  for i := 0 to BreakKeysNumber - 1 do
  begin
    Move(ABreakKeys[i], Key^, SizeOf(Integer));
    Inc(PChar(Key), SizeOf(Integer));
  end;
end;

function TFarMenu.GetItemText(Index: Integer): PFarChar;
begin
{$IFDEF USEEXT}
  {$IFDEF UNICODE}
  Result := FItemsEx[Index].TextPtr
  {$ELSE}
  if FItemsEx[Index].Flags and MIF_USETEXTPTR <> 0 then
    Result := FItemsEx[Index].Text.TextPtr
  else
    Result := FItemsEx[Index].Text.Text;
  {$ENDIF}
{$ELSE}
  {$IFDEF UNICODE}
  Result := FItems[Index].TextPtr;
  {$ELSE}
  Result := FItems[Index].Text;
  {$ENDIF}
{$ENDIF}
end;

{$IFDEF USEEXT}
procedure TFarMenu.InitItemsEx(AItemsEx: array of TFarMenuItemEx; ATitle,
  ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer);
begin
  InitItemsEx(AItemsEx);
  FX := AX;
  FY := AY;
  FMaxHeight := AMaxHeight;
  FTitle := ATitle;
  FBottom := ABottom;
  FHelpTopic := AHelpTopic;
end;

procedure TFarMenu.InitItemsEx(AItemsEx: array of TFarMenuItemEx);
var
  i: Integer;
  Item: PFarMenuItemEx;
begin
  if Assigned(FItemsEx) then
    FreeMem(FItemsEx);
  FItemsNumber := Length(AItemsEx);
  GetMem(FItemsEx, FItemsNumber * SizeOf(TFarMenuItemEx));
  Item := @FItemsEx[0];
  for i := 0 to FItemsNumber - 1 do
  begin
    Move(AItemsEx[i], Item^, SizeOf(TFarMenuItemEx));
    Inc(PChar(Item), SizeOf(TFarMenuItemEx));
  end;
end;

{$IFDEF UNICODE}
procedure TFarMenu.InitItemsEx(AItemsEx: array of TFarString; ATitle,
  ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer);
{$ELSE}
procedure TFarMenu.InitItemsEx(AItemsEx: array of TFarString; ATitle,
  ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer;
  UsePtr: Boolean);
{$ENDIF}
begin
{$IFDEF UNICODE}
  InitItemsEx(AItemsEx);
{$ELSE}
  InitItemsEx(AItemsEx, UsePtr);
{$ENDIF}
  FX := AX;
  FY := AY;
  FMaxHeight := AMaxHeight;
  FTitle := ATitle;
  FBottom := ABottom;
  FHelpTopic := AHelpTopic;
end;

{$IFDEF UNICODE}
procedure TFarMenu.InitItemsEx(AItemsEx: array of TFarString);
{$ELSE}
procedure TFarMenu.InitItemsEx(AItemsEx: array of TFarString; UsePtr: Boolean);
{$ENDIF}
var
  i: Integer;
  //Item: PFarMenuItemEx;
begin
  if Assigned(FItemsEx) then
    FreeMem(FItemsEx);
  FItemsNumber := Length(AItemsEx);
  GetMem(FItemsEx, FItemsNumber * SizeOf(TFarMenuItemEx));
  //Item := @FItemsEx[0];
  for i := 0 to FItemsNumber - 1 do
  begin
{$IFDEF UNICODE}
    FItemsEx[i].TextPtr := PFarChar(AItemsEx[i]);
{$ELSE}
    if UsePtr then
      StrLCopy(FItemsEx[i].Text.Text, PFarChar(AItemsEx[i]), cMenuDataLen)
    else
    begin
      FItemsEx[i].Flags := FItemsEx[i].Flags or MIF_USETEXTPTR;
      FItemsEx[i].Text.TextPtr := PFarChar(AItemsEx[i]);
    end;
{$ENDIF}
  end;
end;
{$ELSE}
procedure TFarMenu.InitItems(AItems: array of TFarMenuItem);
var
  i: Integer;
  Item: PFarMenuItem;
begin
  if Assigned(FItems) then
    FreeMem(FItems);
  FItemsNumber := Length(AItems);
  GetMem(FItems, FItemsNumber * SizeOf(TFarMenuItem));
  Item := @FItems[0];
  for i := 0 to FItemsNumber - 1 do
  begin
    Move(AItems[i], Item^, SizeOf(TFarMenuItem));
    Inc(PChar(Item), SizeOf(TFarMenuItem));
  end;
end;

procedure TFarMenu.InitItems(AItems: array of TFarMenuItem;
  ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer);
begin
  InitItems(AItems);
  FX := AX;
  FY := AY;
  FMaxHeight := AMaxHeight;
  FTitle := ATitle;
  FBottom := ABottom;
  FHelpTopic := AHelpTopic;
end;

procedure TFarMenu.InitItems(AItems: array of TFarString);
var
  i: Integer;
  Item: PFarMenuItem;
begin
  if Assigned(FItems) then
    FreeMem(FItems);
  FItemsNumber := Length(AItems);
  GetMem(FItems, FItemsNumber * SizeOf(TFarMenuItem));
  Item := @FItems[0];
  for i := 0 to FItemsNumber - 1 do
  begin
{$IFDEF UNICODE}
    FItems[i].TextPtr := PFarChar(AItems[i]);
{$ELSE}
    StrLCopy(FItems[i].Text, PFarChar(AItems[i]), cMenuDataLen);
{$ENDIF}
    {Move(AItems[i], Item^, SizeOf(TFarMenuItem));
    Inc(PChar(Item), SizeOf(TFarMenuItem));}
  end;
end;

procedure TFarMenu.InitItems(AItems: array of TFarString; ATitle, ABottom,
  AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer);
begin
  InitItems(AItems);
  FX := AX;
  FY := AY;
  FMaxHeight := AMaxHeight;
  FTitle := ATitle;
  FBottom := ABottom;
  FHelpTopic := AHelpTopic;
end;
{$ENDIF}

{ TSimpleFarMenu }

{$IFDEF USEEXT}
constructor TSimpleFarMenu.Create(AItemsEx: array of TFarMenuItemEx;
  ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer);
begin
  inherited Create;
  InitItemsEx(AItemsEx, ATitle, ABottom, AHelpTopic, AX, AY, AMaxHeight);
end;
{$ELSE}
constructor TSimpleFarMenu.Create(AItems: array of TFarMenuItem;
  ATitle, ABottom, AHelpTopic: PFarChar; AX, AY, AMaxHeight: Integer);
begin
  inherited Create;
  InitItems(AItems, ATitle, ABottom, AHelpTopic, AX, AY, AMaxHeight);
end;
{$ENDIF}

{ TFarRegMenu }

const
  cBreakEsc = -1;
  cBreakReturn = 0;
  cBreakF10 = cBreakReturn + 1;
  cBreakAltI = cBreakF10 + 1;
  cBreakIns = cBreakAltI + 1;
  cBreakDel = cBreakIns + 1;
  cBreakF4 = cBreakDel + 1;
  cBreakF7 = cBreakF4 + 1;
  cBreakUp = cBreakF7 + 1;
  cBreakDown = cBreakUp + 1;
  cBreakF6 = cBreakDown + 1;

function TFarRegMenu.AddMenuInfo: PFarRegMenuInfo;
begin
  GetMem(Result, SizeOf(TFarRegMenuInfo));
  ZeroMemory(Result, SizeOf(TFarRegMenuInfo));
  FMenuInfo^.Add(Result);
  Result^.Key := FSubKey;
  Result^.Group := FCurGroup;
  FCurMenuInfo := FMenuInfo^.Count - 1;
end;

constructor TFarRegMenu.Create(AWithGroups: Boolean; ASubkey: TFarString;
   ATitle, ABottom, AHelpTopic, AMoveTitle, AMoveBottom, AMoveHelpTopic: PFarChar);
const
  VK_I = $49;
  //VK_UP = $26;
  //VK_DOWN = $28;
  cEmptyStringArray: array[0..0] of TFarString = ('');
begin
  inherited Create;
  FInsertMode := False;
  FMoveMenuInfo := 0;
  FWithGroups := AWithGroups;
  MenuProc := RegMenuProc;
  InitBreakKeys([
    VK_RETURN,
    VK_F10,
    PKF_ALT * $10000 + VK_I,
    VK_INSERT,
    VK_DELETE,
    VK_F4,
    VK_F7,
    PKF_CONTROL * $10000 + VK_UP,
    PKF_CONTROL * $10000 + VK_DOWN,
    VK_F6
  ]);
  FTitle := ATitle;
  FBottom := ABottom;
  FHelpTopic := AHelpTopic;
  FMoveTitle := AMoveTitle;
  FMoveBottom := AMoveBottom;
  FMoveHelpTopic := AMoveHelpTopic;
  //InitItems(cEmptyStringArray, ATitle, ABottom, AHelpTopic, -1, -1, 0);
  FMenuOrder := TStringArray.Create;
{$IFDEF UNICODE}
  FMenuText := TStringArray.Create;
{$ENDIF}
  FMenuInfo := NewList;
  FSubKey := ASubkey;
  AddMenuInfo;
  ReadMenuItems;
end;

function TFarRegMenu.DelMenuInfo: PFarRegMenuInfo;
begin
  FreeMem(FMenuInfo^.Items[FMenuInfo^.Count - 1]);
  FMenuInfo^.Delete(FMenuInfo^.Count - 1);
  FCurMenuInfo := FMenuInfo^.Count - 1;
  Result := FMenuInfo^.Items[FCurMenuInfo];
  FSubKey := Result^.Key;
  FCurGroup := Result^.Group;
end;

destructor TFarRegMenu.Destroy;
var
  i: Integer;
begin
  for i := 0 to FMenuInfo^.Count - 1 do
    FreeMem(FMenuInfo^.Items[i]);
  Free_And_Nil(FMenuInfo);
{$IFDEF UNICODE}
  FMenuText.Free;
{$ENDIF}
  FMenuOrder.Free;
  inherited;
end;

function TFarRegMenu.RegMenuProc(MenuResult, BreakCode: Integer;
  var SelPos: Integer): Boolean;
var
  ReRead: Boolean;
  ToIndex: Integer;
  ToSubKey: TFarString;
begin
  Result := True;
  ReRead := False;
  SelPos := MenuResult;
  if (BreakCode = cBreakEsc) and (MenuResult >= 0) then
    BreakCode := cBreakReturn;
  if FMoveMenuInfo <> 0 then
  begin
    if ((MenuResult >= 0) and (MenuResult < FMenuOrder.Count)) or
        (BreakCode in [cBreakAltI, cBreakF10]) or (BreakCode = cBreakEsc) then
      case BreakCode of
        cBreakEsc: // Esc
        begin
          SelPos := DelMenuInfo^.Pos;
          ReRead := True;
          if FCurMenuInfo < FMoveMenuInfo then
            FMoveMenuInfo := 0;
        end;
        cBreakReturn: // Enter
          if FWithGroups and IsGroupItem(MenuResult) then
          begin
            FCurGroup := GetItemName(MenuResult);
            PFarRegMenuInfo(FMenuInfo^.Items[FCurMenuInfo])^.Pos := MenuResult;
            FSubKey := FSubKey + cDelim + FMenuOrder.StringArray[MenuResult];
            AddMenuInfo;
            SelPos := 0;
            ReRead := True;
          end;
        cBreakF10: // F10
          begin
            ToSubKey := FSubKey;
            ToIndex := MenuResult;
            repeat
              SelPos := DelMenuInfo^.Pos;
            until FCurMenuInfo < FMoveMenuInfo;
            FMoveMenuInfo := 0;
            ReadMenuItems;
            ReRead := MoveMenuItem(SelPos, ToIndex, ToSubKey);
          end;
        cBreakAltI:
        begin
          FInsertMode := not FInsertMode;
          ReRead := True;
        end;
      end;
  end
  else
  begin
    if ((MenuResult >= 0) and (MenuResult < FMenuOrder.Count)) or
        (BreakCode in [cBreakIns, cBreakF7, cBreakAltI, cBreakF10]) or
        (BreakCode = cBreakEsc) then
      case BreakCode of
        cBreakEsc: // Esc
          if FCurMenuInfo = 0 then
            Result := False
          else
          begin
            SelPos := DelMenuInfo^.Pos;
            ReRead := True;
          end;
        cBreakReturn: // Enter
          if FWithGroups and IsGroupItem(MenuResult) then
          begin
            FCurGroup := GetItemName(MenuResult);
            PFarRegMenuInfo(FMenuInfo^.Items[FCurMenuInfo])^.Pos := MenuResult;
            FSubKey := FSubKey + cDelim + FMenuOrder.StringArray[MenuResult];
            AddMenuInfo;
            SelPos := 0;
            ReRead := True;
          end
          else
            Result := ExecuteMenuItem(MenuResult);
        cBreakF10: // F10
          Result := False;
        cBreakAltI: // Alt+I
        begin
          FInsertMode := not FInsertMode;
          ReRead := True;
        end;
        cBreakIns: // Insert
          ReRead := EditMenuItem(MenuResult, eaCreateItem);
        cBreakDel: // Delete
          ReRead := DeleteMenuItem(MenuResult);
        cBreakF4: // F4
          ReRead := EditMenuItem(MenuResult, eaEdit);
        cBreakF7: // F7
          ReRead := FWithGroups and EditMenuItem(MenuResult, eaCreateGroup);
        cBreakUp: // Ctrl+Up
          if (FMenuOrder.Count > 1) and (MenuResult > 0) then
          begin
            FMenuOrder.Swap(MenuResult, MenuResult - 1);
            WriteRegStringValue(cOrder, FSubKey, FMenuOrder.AsString);
            SelPos := MenuResult - 1;
            ReRead := True;
          end;
        cBreakDown: // Ctrl+Down
          if (FMenuOrder.Count > 1) and (MenuResult < FMenuOrder.Count - 1) then
          begin
            FMenuOrder.Swap(MenuResult, MenuResult + 1);
            WriteRegStringValue(cOrder, FSubKey, FMenuOrder.AsString);
            SelPos := MenuResult + 1;
            ReRead := True;
          end;
        cBreakF6: // F6
          if FWithGroups then
          begin
            PFarRegMenuInfo(FMenuInfo^.Items[FCurMenuInfo])^.Pos := MenuResult;
            FSubKey := PFarRegMenuInfo(FMenuInfo^.Items[0]).Key;
            AddMenuInfo;
            FMoveMenuInfo := FCurMenuInfo;
            SelPos := 0;
            ReRead := True;
          end;
      end;
  end;
  if ReRead and Result then
  begin
    ReadMenuItems;
    if SelPos < 0 then
      SelPos := 0
    else if SelPos = FItemsNumber then
      Dec(SelPos);
  end;
end;

procedure TFarRegMenu.ReadMenuItems;
var
  i: Integer;
  ItemName: TFarString;
  changed: Boolean;
{$IFDEF USEEXT}
  AItemsEx: array of TFarMenuItemEx;
{$ELSE}
  AItems: array of TFarMenuItem;
{$ENDIF}
  ItemsCount: Integer;
begin
  FMenuOrder.Init(ReadRegStringValue(cOrder, FSubKey, ''));
{$IFDEF UNICODE}
  FMenuText.Clear;
{$ENDIF}
  ItemsCount := FMenuOrder.Count;
  if FInsertMode then
    Inc(ItemsCount);
{$IFDEF USEEXT}
  SetLength(AItemsEx, ItemsCount);
  ZeroMemory(AItemsEx, ItemsCount * SizeOf(TFarMenuItemEx));
{$ELSE}
  SetLength(AItems, ItemsCount);
  ZeroMemory(AItems, ItemsCount * SizeOf(TFarMenuItem));
{$ENDIF}
  i := 0;
  changed := False;
  while i < FMenuOrder.Count do
  begin
    if FWithGroups and IsGroupItem(i) then
    begin
{$IFDEF USEEXT}
  {$IFDEF UNICODE}
      AItemsEx[i].TextPtr := FMenuText.Add(-1, GetItemName(i));
  {$ELSE}
      StrLCopy(AItemsEx[i].Text.Text, PFarChar(GetItemName(i)), cMenuDataLen);
  {$ENDIF}
      AItemsEx[i].Flags := 16;
{$ELSE}
  {$IFDEF UNICODE}
      AItems[i].TextPtr := FMenuText.Add(-1, GetItemName(i));
  {$ELSE}
      StrLCopy(AItems[i].Text, PFarChar(GetItemName(i)), cMenuDataLen);
  {$ENDIF}
      AItems[i].Checked := 16;
{$ENDIF}
    end
    else
    begin
      ItemName := GetItemName(i);
      if ItemName = '' then
      begin
        FMenuOrder.Delete(i);
        Dec(ItemsCount);
        changed := True;
        Continue;
      end
      else
      begin
{$IFDEF USEEXT}
  {$IFDEF UNICODE}
        AItemsEx[i].TextPtr := FMenuText.Add(-1, ItemName);;
  {$ELSE}
        StrLCopy(AItemsEx[i].Text.Text, PFarChar(ItemName), cMenuDataLen);
  {$ENDIF}
{$ELSE}
  {$IFDEF UNICODE}
        AItems[i].TextPtr := FMenuText.Add(-1, ItemName);;
  {$ELSE}
        StrLCopy(AItems[i].Text, PFarChar(ItemName), cMenuDataLen);
  {$ENDIF}
{$ENDIF}
      end;
    end;
    Inc(i);
  end;
{$IFDEF USEEXT}
  SetLength(AItemsEx, ItemsCount);
{$ELSE}
  SetLength(AItems, ItemsCount);
{$ENDIF}
  if changed then
    WriteRegStringValue(cOrder, SubKey, MenuOrder.AsString);
  if FMoveMenuInfo > 0 then
    FCurTitle := FMoveTitle
  else
    FCurTitle := FTitle;
  FCurTitle := FCurTitle + ': "';
  if FCurMenuInfo = FMoveMenuInfo then
    FCurTitle := FCurTitle + cDelim
  else
    FCurTitle := FCurTitle + FCurGroup;
  FCurTitle := FCurTitle + '"';
{$IFDEF USEEXT}
  if FMoveMenuInfo > 0 then
    InitItemsEx(AItemsEx, PFarChar(FCurTitle), FMoveBottom, FMoveHelpTopic, -1, -1, 0)
  else
    InitItemsEx(AItemsEx, PFarChar(FCurTitle), FBottom, FHelpTopic, -1, -1, 0);
{$ELSE}
  if FMoveMenuInfo > 0 then
    InitItems(AItems, PFarChar(FCurTitle), FMoveBottom, FMoveHelpTopic, -1, -1, 0)
  else
    InitItems(AItems, PFarChar(FCurTitle), FBottom, FHelpTopic, -1, -1, 0);
{$ENDIF}
end;

end.
