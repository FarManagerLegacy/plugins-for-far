unit UExports;

{$i CommonDirectives.inc}

interface

uses
  Windows,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  Plugin,
{$ENDIF}
  UTypes,
  UDialogs,
  UMenu,
  UDirHotListMenu,
  ULang;
  
implementation

(*
Функция SetStartupInfo вызывается один раз, перед всеми
другими функциями. Она передается плагину информацию,
необходимую для дальнейшей работы.
*)
{$IFDEF UNICODE}
procedure SetStartupInfoW(var psi: TPluginStartupInfo); stdcall;
{$ELSE}
procedure SetStartupInfo(var psi: TPluginStartupInfo); stdcall;
{$ENDIF}
var
  i: Integer;
begin
  i := psi.StructSize;
  if i > SizeOf(FARAPI) then
    i := SizeOf(FARAPI);
  Move(psi, FARAPI, i);
  FARAPI.StructSize := i;

  i := psi.FSF.StructSize;
  if i > SizeOf(FSF) then
    i := SizeOf(FSF);
  Move(psi.FSF^, FSF, i);
  FARAPI.FSF := @FSF;
  FARAPI.FSF.StructSize := i;
end;

(*
Функция GetPluginInfo вызывается для получения основной
  (general) информации о плагине
*)
var
  PluginMenuStrings: array[0..0] of PFarChar;

{$IFDEF UNICODE}
procedure GetPluginInfoW(var pi: TPluginInfo); stdcall;
{$ELSE}
procedure GetPluginInfo(var pi: TPluginInfo); stdcall;
{$ENDIF}
begin
  pi.StructSize:= SizeOf(pi);

  PluginMenuStrings[0]:= GetMsg(MPluginTitle);
  pi.PluginMenuStrings := @PluginMenuStrings;
  pi.PluginMenuStringsNumber := 1;

  //pi.PluginConfigStrings := @PluginMenuStrings;
  pi.PluginConfigStringsNumber := 0;

  //pi.CommandPrefix := PChar(prefix);
end;

(*
  Функция OpenPlugin вызывается при создании новой копии плагина.
*)
{$IFDEF UNICODE}
function OpenPluginW(OpenFrom: integer; Item: integer): THandle; stdcall;
{$ELSE}
function OpenPlugin(OpenFrom: integer; Item: integer): THandle; stdcall;
{$ENDIF}
var
  DirHotListMenu: TDirHotListMenu;
begin
  DirHotListMenu := TDirHotListMenu.Create;;
  try
    DirHotListMenu.Execute;
  finally
    DirHotListMenu.Free;
  end;
  Result := INVALID_HANDLE_VALUE;
end;

(*
  Функция Configure вызывается при создании диалога конфигурации плагина.
*)
(*{$IFDEF UNICODE}
function ConfigureW(number: Integer): Integer; stdcall;
{$ELSE}
function Configure(number: Integer): Integer; stdcall;
{$ENDIF}
begin
  Result := 1;
end;*)

(*
// Exported Functions

void   WINAPI _export ClosePluginW(HANDLE hPlugin);
int    WINAPI _export CompareW(HANDLE hPlugin,const struct PluginPanelItem *Item1,const struct PluginPanelItem *Item2,unsigned int Mode);
int    WINAPI _export ConfigureW(int ItemNumber);
int    WINAPI _export DeleteFilesW(HANDLE hPlugin,struct PluginPanelItem *PanelItem,int ItemsNumber,int OpMode);
void   WINAPI _export ExitFARW(void);
void   WINAPI _export FreeFindDataW(HANDLE hPlugin,struct PluginPanelItem *PanelItem,int ItemsNumber);
void   WINAPI _export FreeVirtualFindDataW(HANDLE hPlugin,struct PluginPanelItem *PanelItem,int ItemsNumber);
int    WINAPI _export GetFilesW(HANDLE hPlugin,struct PluginPanelItem *PanelItem,int ItemsNumber,int Move,const wchar_t **DestPath,int OpMode);
int    WINAPI _export GetFindDataW(HANDLE hPlugin,struct PluginPanelItem **pPanelItem,int *pItemsNumber,int OpMode);
int    WINAPI _export GetMinFarVersionW(void);
void   WINAPI _export GetOpenPluginInfoW(HANDLE hPlugin,struct OpenPluginInfo *Info);
void   WINAPI _export GetPluginInfoW(struct PluginInfo *Info);
int    WINAPI _export GetVirtualFindDataW(HANDLE hPlugin,struct PluginPanelItem **pPanelItem,int *pItemsNumber,const wchar_t *Path);
int    WINAPI _export MakeDirectoryW(HANDLE hPlugin,const wchar_t **Name,int OpMode);
HANDLE WINAPI _export OpenFilePluginW(const wchar_t *Name,const unsigned char *Data,int DataSize,int OpMode);
HANDLE WINAPI _export OpenPluginW(int OpenFrom,INT_PTR Item);
int    WINAPI _export ProcessDialogEventW(int Event,void *Param);
int    WINAPI _export ProcessEditorEventW(int Event,void *Param);
int    WINAPI _export ProcessEditorInputW(const INPUT_RECORD *Rec);
int    WINAPI _export ProcessEventW(HANDLE hPlugin,int Event,void *Param);
int    WINAPI _export ProcessHostFileW(HANDLE hPlugin,struct PluginPanelItem *PanelItem,int ItemsNumber,int OpMode);
int    WINAPI _export ProcessKeyW(HANDLE hPlugin,int Key,unsigned int ControlState);
int    WINAPI _export ProcessSynchroEventW(int Event,void *Param);
int    WINAPI _export ProcessViewerEventW(int Event,void *Param);
int    WINAPI _export PutFilesW(HANDLE hPlugin,struct PluginPanelItem *PanelItem,int ItemsNumber,int Move,int OpMode);
int    WINAPI _export SetDirectoryW(HANDLE hPlugin,const wchar_t *Dir,int OpMode);
int    WINAPI _export SetFindListW(HANDLE hPlugin,const struct PluginPanelItem *PanelItem,int ItemsNumber);
void   WINAPI _export SetStartupInfoW(const struct PluginStartupInfo *Info);
*)

exports
{$IFDEF UNICODE}
  SetStartupInfoW,
  GetPluginInfoW,
  //ConfigureW,
  OpenPluginW;
{$ELSE}
  SetStartupInfo,
  GetPluginInfo,
  //Configure,
  OpenPlugin;
{$ENDIF}

end.
