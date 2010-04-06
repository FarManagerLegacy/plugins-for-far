unit UDialogs;

{$i CommonDirectives.inc}

interface

uses
  Windows,
  Kol,
{$IFDEF UNICODE}
  PluginW,
  FarKeysW,
{$ELSE}
  Plugin,
  farkeys,
{$ENDIF}
  UTypes;

type
  TFarDlgProc = function(Msg, Param1: Integer; Param2: LONG_PTR): LONG_PTR of object;

  TFarDialog = class
  private
    FItems: PFarDialogItemArray;
    FItemsNumber: Integer;
    FX1, FY1, FX2, FY2: Integer;
    FHelpTopic: PFarChar;
    FDlgProc: TFarDlgProc;
    FFlags: Cardinal;
    FDlg: THandle;
  protected
    property DlgProc: TFarDlgProc read FDlgProc write FDlgProc;
    procedure InitItems(AItems: array of TFarDialogItem); overload;
    procedure InitItems(AItems: array of TFarDialogItem;
      AX1, AY1, AX2, AY2: Integer; AHelpTopic: PFarChar); overload;

    function SendMsg(Msg, Param1: Integer; Param2: LONG_PTR): LONG_PTR; overload;
    function SendMsg(Msg, Param1: Integer; Param2: Pointer): LONG_PTR; overload;
    function GetText(ItemID: Integer): TFarString;
    procedure SetText(ItemID: Integer; const Value: TFarString);
    function GetChecked(ItemID:Integer): Boolean;
    procedure SetChecked(ItemID: Integer; Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function Execute: Integer;
    property Flags: Cardinal read FFlags write FFlags;
    property ItemsNumber: Integer read FItemsNumber;
  end;

  TSimpleFarDialog = class(TFarDialog)
  private
    FItemsData: array of TFarString;
    function SimpleDialogProc(Msg, Param1: Integer; Param2: LONG_PTR): LONG_PTR;
    function GetItemData(Index: Integer): TFarString;
  public
    constructor Create(AItems: array of TFarDialogItem;
      AX1, AY1, AX2, AY2: Integer; AHelpTopic: PFarChar);
    property ItemData[Index: Integer]: TFarString read GetItemData;
  end;

function DlgItem(AItemType: Integer; X, Y, W, H: Integer; AFlags: DWORD;
  AData: PFarChar = nil; AParam: Pointer = nil): TFarDialogItem;

implementation

{
  AParam:
    הכÿ DI_BUTTON - DefaultButton (0/1)
    הכÿ פכאדא DIF_HISTORY - Param.History
    הÿÿ פכאדא DIF_MASKEDIT - Param.Mask
}
function DlgItem(AItemType: Integer; X, Y, W, H: Integer; AFlags: DWORD;
  AData: PFarChar = nil; AParam: Pointer = nil): TFarDialogItem;
{$IFNDEF UNICODE}
const
  cEditDataLen = 511;
{$ENDIF}
begin
  ZeroMemory(@Result, SizeOf(Result));
  with Result do
  begin
    ItemType := AItemType;
    X1 := X;
    Y1 := Y;
    if ItemType = DI_DOUBLEBOX then
    begin
      if X1 = -1 then
        X1 := 3;
      if Y1 = -1 then
        Y1 := 1;
      if W >= 0 then
        W := W - 2
    end;
    if W >= 0 then
      X2 := X + W - 1;
    if H >= 0 then
      Y2 := Y + H - 1;
    Flags := AFlags;
    if ItemType = DI_COMBOBOX then
      Param.ListItems := nil
    else if ItemType = DI_BUTTON then
      DefaultButton := Integer(AParam)
    else
      if Flags and DIF_HISTORY <> 0 then
        Param.History := AParam
      else if Flags and DIF_MASKEDIT <> 0 then
        Param.Mask := AParam;
{$IFDEF UNICODE}
    if DWORD(AData) < 2000 then
      PtrData := GetMsg(DWORD(AData))
    else
      PtrData := AData;
{$ELSE}
    if DWORD(AData) < 2000 then
      StrLCopy(Data.Data, GetMsg(DWORD(AData)), cEditDataLen)
    else
      StrLCopy(Data.Data, AData, cEditDataLen);
{$ENDIF}
  end;
end;

function FarDlgProc(hDlg: THandle; Msg, Param1: Integer;
  Param2: LONG_PTR): LONG_PTR; stdcall;
var
  FarDialog: TFarDialog;
begin
  if Msg = DN_INITDIALOG then
  begin
    FARAPI.SendDlgMessage(hDlg, DM_SETDLGDATA, 0, Param2);
    LONG_PTR(FarDialog) := Param2;
    FarDialog.FDlg := hDlg;
  end
  else
    LONG_PTR(FarDialog) := FARAPI.SendDlgMessage(hDlg, DM_GETDLGDATA, 0, 0);
  if Assigned(FarDialog.DlgProc) then
    Result := FarDialog.DlgProc(Msg, Param1, Param2)
  else
    Result := FARAPI.DefDlgProc(FarDialog.FDlg, Msg, Param1, Param2);
end;

{ TFarDialog }

constructor TFarDialog.Create;
begin
  inherited Create;
  FDlgProc := nil;
  FItems := nil;
  FItemsNumber := 0;
  FHelpTopic := nil;
end;

destructor TFarDialog.Destroy;
begin
  if Assigned(FItems) then
  begin
    FreeMem(FItems);
    FItems := nil;
  end;
  FItemsNumber := 0;
  inherited Destroy;
end;

function TFarDialog.Execute: Integer;
{$IFDEF UNICODE}
var
  hDlg: THandle;
{$ENDIF}
begin
{$IFDEF UNICODE}
  hDlg := FARAPI.DialogInit(FARAPI.ModuleNumber, FX1, FY1, FX2, FY2, FHelpTopic,
    FItems, FItemsNumber, 0, Flags, FarDlgProc, Integer(Self));
  if hDlg <> INVALID_HANDLE_VALUE then
  begin
    Result := FARAPI.DialogRun(hDlg);
    FARAPI.DialogFree(hDlg);
  end
  else
    Result := -1;
{$ELSE}
  Result := FARAPI.DialogEx(FARAPI.ModuleNumber, FX1, FY1, FX2, FY2, FHelpTopic,
    FItems, FItemsNumber, 0, Flags, FarDlgProc, Integer(Self))
{$ENDIF}
end;

function TFarDialog.GetChecked(ItemID: Integer): Boolean;
begin
  Result := SendMsg(DM_GETCHECK, ItemID, 0) = BSTATE_CHECKED;
end;

function TFarDialog.GetText(ItemID: Integer): TFarString;
var
  l: Integer;
  ItemData: TFarDialogItemData;
begin
  Result := '';
  l := SendMsg(DM_GETTEXTLENGTH, ItemID, 0);
  if l > 0 then
  begin
    SetLength(Result, l);
    ItemData.PtrLength := l;
    ItemData.PtrData := PFarChar(Result);
    SendMsg(DM_GETTEXT, ItemID, @ItemData);
  end;
end;

procedure TFarDialog.InitItems(AItems: array of TFarDialogItem);
var
  i: Integer;
  Item: PFarDialogItem;
begin
  FItemsNumber := Length(AItems);
  GetMem(FItems, FItemsNumber * SizeOf(TFarDialogItem));
  Item := @FItems[0];
  for i := 0 to FItemsNumber - 1 do
  begin
    Move(AItems[I], Item^, SizeOf(TFarDialogItem));
    Inc(PChar(Item), SizeOf(TFarDialogItem));
  end;
end;

procedure TFarDialog.InitItems(AItems: array of TFarDialogItem; AX1, AY1,
  AX2, AY2: Integer; AHelpTopic: PFarChar);
begin
  InitItems(AItems);
  FX1 := AX1;
  FY1 := AY1;
  FX2 := AX2;
  FY2 := AY2;
  FHelpTopic := AHelpTopic;
end;

function TFarDialog.SendMsg(Msg, Param1: Integer; Param2: LONG_PTR): LONG_PTR;
begin
  Result := FARAPI.SendDlgMessage(FDlg, Msg, Param1, Param2);
end;

function TFarDialog.SendMsg(Msg, Param1: Integer; Param2: Pointer): LONG_PTR;
begin
  Result := FARAPI.SendDlgMessage(FDlg, Msg, Param1, LONG_PTR(Param2));
end;

procedure TFarDialog.SetChecked(ItemID: Integer; Value: Boolean);
begin
  if Value then
    SendMsg(DM_SETCHECK, ItemID, LONG_PTR(BSTATE_CHECKED))
  else
    SendMsg(DM_SETCHECK, ItemID, LONG_PTR(BSTATE_UNCHECKED));
end;

procedure TFarDialog.SetText(ItemID: Integer; const Value: TFarString);
var
  ItemData: TFarDialogItemData;
begin
  ItemData.PtrLength := Length(Value);
  ItemData.PtrData := PFarChar(Value);
  SendMsg(DM_SETTEXT, ItemID, @ItemData);
end;

{ TSimpleFarDialog }

constructor TSimpleFarDialog.Create(AItems: array of TFarDialogItem;
  AX1, AY1, AX2, AY2: Integer; AHelpTopic: PFarChar);
begin
  inherited Create;
  DlgProc := SimpleDialogProc;
  InitItems(AItems, AX1, AY1, AX2, AY2, AHelpTopic);
  SetLength(FItemsData, ItemsNumber);
end;

function TSimpleFarDialog.GetItemData(Index: Integer): TFarString;
begin
  Result := FItemsData[Index];
end;

function TSimpleFarDialog.SimpleDialogProc(Msg, Param1: Integer;
  Param2: LONG_PTR): LONG_PTR;
var
  i: Integer;
  l: Cardinal;
{$IFDEF UNICODE}
  l1: Cardinal;
{$ENDIF}
  Item: PFarDialogItem;
begin
  l := 0;
  Item := nil;
  if (Msg = DN_CLOSE) and (Param1 >= 0) then
    for i := 0 to ItemsNumber - 1 do
    begin
{$IFDEF UNICODE}
      l1 := SendMsg(DM_GETDLGITEM, i, 0);
      if l1 > l then
      begin
        if l > 0 then
          FreeMem(Item);
        GetMem(Item, l1);
        l := l1;
      end;
{$ELSE}
      if l = 0 then
      begin
        l := SizeOf(TFarDialogItem);
        GetMem(Item, l);
      end;
{$ENDIF}
      if (SendMsg(DM_GETDLGITEM, i, Item) <> 0) and
          ((Item^.ItemType = DI_EDIT) or (Item^.ItemType = DI_FIXEDIT)) then
        FItemsData[i] := GetText(i);
    end;
  if l > 0 then
    FreeMem(Item);
  Result := FARAPI.DefDlgProc(FDlg, Msg, Param1, Param2)
end;

end.
