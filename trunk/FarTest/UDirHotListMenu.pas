unit UDirHotListMenu;

{$i CommonDirectives.inc}

interface

uses
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  Plugin,
{$ENDIF}
  UTypes,
  ULang,
  UDialogs,
  UMenu;

type
  TDirHotListMenu = class(TFarRegMenu)
  protected
    function IsGroupItem(const Id: TFarString): Boolean; override;
    function GetItemName(const Id: TFarString; IsGroup: Boolean): TFarString; override;
    function ExecuteMenuItem: Boolean; override;
    function CreateMenuItem: Boolean; override;
    function CreateMenuGroup(var GroupName: TFarString): Boolean; override;
    function EditMenuItem: Boolean; override;
    function DeleteMenuItem: Boolean; override;
  public
    constructor Create;
  end;

const
  cDirectoryHotlist = 'DirectoryHotlist';

implementation

{ TDirHotListMenu }

constructor TDirHotListMenu.Create;
begin
  inherited Create(True, FARAPI.RootKey + TFarString('\') + cDirectoryHotlist,
    GetMsg(MPluginTitle), GetMsg(MFooter), cDirectoryHotlist);
end;

function TDirHotListMenu.CreateMenuGroup(var GroupName: TFarString): Boolean;
const
  cSizeX = 70;
  cSizeY = 8;
  cLeftSide = 5;
var
  CreateMenuGroupDlg: TSimpleFarDialog;
begin
  CreateMenuGroupDlg := TSimpleFarDialog.Create([
      DlgItem(DI_DOUBLEBOX, -1, -1, cSizeX, cSizeY, 0, PFarChar(MPluginTitle)),
      DlgItem(DI_TEXT, cLeftSide, 2, -1, -1, 0, PFarChar(MPluginTitle)),
      DlgItem(DI_EDIT, cLeftSide, 3, cSizeX - cLeftSide - 5, 0, DIF_HISTORY, ''{, cHistory}),
      DlgItem(DI_TEXT, cLeftSide - 1, cSizeY - 4, cSizeX - cLeftSide, 0, DIF_SEPARATOR, ''),
      DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP, PFarChar(MOk), Pointer(True)),
      DlgItem(DI_BUTTON, 0, cSizeY - 3, 0, 0, DIF_CENTERGROUP, PFarChar(MCancel))
    ], -1, -1, cSizeX, cSizeY, nil);
  try
    Result := CreateMenuGroupDlg.Execute = 4;
    if Result then
      GroupName := CreateMenuGroupDlg.ItemData[2];
  finally
    CreateMenuGroupDlg.Free;
  end;
end;

function TDirHotListMenu.CreateMenuItem: Boolean;
begin

end;

function TDirHotListMenu.DeleteMenuItem: Boolean;
begin

end;

function TDirHotListMenu.EditMenuItem: Boolean;
begin

end;

function TDirHotListMenu.ExecuteMenuItem: Boolean;
begin

end;

function TDirHotListMenu.GetItemName(const Id: TFarString;
  IsGroup: Boolean): TFarString;
begin

end;

function TDirHotListMenu.IsGroupItem(const Id: TFarString): Boolean;
begin

end;

end.
