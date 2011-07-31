unit UExport;

{$i CommonDirectives.inc}

interface

uses
  Windows,
  err,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  plugin,
{$ENDIF}
  UTypes,
  UUtils,
  ULang,
  UCanon,
  UEDialogs;

implementation

uses UDialogs;

{.$DEFINE OUT_LOG}
{$IFDEF RELEASE}
  {$UNDEF OUT_LOG}
{$ENDIF}
{$IFDEF OUT_LOG}
var
  LogFile: TextFile;
{$ENDIF}

(*
  Функция SetStartupInfo вызывается один раз, перед всеми другими функциями.
  Она передает плагину информацию, необходимую для дальнейшей работы.
*)
{$IFDEF UNICODE}
procedure SetStartupInfoW(var psi: TPluginStartupInfo); stdcall;
{$ELSE}
procedure SetStartupInfo(var psi: TPluginStartupInfo); stdcall;
{$ENDIF}
var
  i: Integer;
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'SetStartupInfo');
{$ENDIF}
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
  LoadConfig;
end;

(*
  Функция GetPluginInfo вызывается для получения основной информации о плагине.
*)
var
  PluginMenuStrings: array[0..0] of PFarChar;
  DiskMenuNumbers: array[0..0] of Integer;

{$IFDEF UNICODE}
procedure GetPluginInfoW(var pi: TPluginInfo); stdcall;
{$ELSE}
procedure GetPluginInfo(var pi: TPluginInfo); stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'GetPluginInfo');
{$ENDIF}
  pi.StructSize := SizeOf(pi);

  PluginMenuStrings[0] := GetMsg(MPluginTitle);

  pi.PluginMenuStrings := @PluginMenuStrings;
  pi.PluginMenuStringsNumber := 1;

  pi.PluginConfigStrings := @PluginMenuStrings;
  pi.PluginConfigStringsNumber := 1;

  if ConfigData.AddToDiskMenu then
  begin
    pi.DiskMenuStrings := @PluginMenuStrings;
    DiskMenuNumbers[0] := ConfigData.DiskMenuNumber;
    pi.DiskMenuNumbers := @DiskMenuNumbers;
    pi.DiskMenuStringsNumber := 1;
  end
  else
    pi.DiskMenuStringsNumber := 0;

  pi.CommandPrefix := PFarChar(ConfigData.Prefix); //PChar(prefix);
end;

(*
  Функция OpenPlugin вызывается при создании новой копии плагина.
*)
{$IFDEF UNICODE}
function OpenPluginW(OpenFrom: Integer; Item: INT_PTR): THandle; stdcall;
{$ELSE}
function OpenPlugin(OpenFrom: Integer; Item: Integer): THandle; stdcall;
{$ENDIF}
var
  Canon: TCanon;
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'OpenPlugin');
{$ENDIF}
  Result := INVALID_HANDLE_VALUE;
  try
    Canon := TCanon.Create(ConfigData.LibraryPath + 'EDSDK.dll');
    Result := THandle(Canon);
  except
    on E: Exception do
      ShowMessage(GetMsg(MError),
        PFarChar(GetMsgStr(MInitError) + #10 + E.Message),
        FMSG_WARNING or FMSG_MB_OK);
  end;
end;

(*
  Функция GetOpenPluginInfo вызывается для получения информации
  об открытом плагине.
*)
{$IFDEF UNICODE}
procedure GetOpenPluginInfoW(hPlugin: THandle; var Info: TOpenPluginInfo); stdcall;
{$ELSE}
procedure GetOpenPluginInfo(hPlugin: THandle; var Info: TOpenPluginInfo); stdcall;
{$ENDIF}
begin
(*{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'GetOpenPluginInfo');
{$ENDIF}*)
  if hPlugin <> 0 then
    TCanon(hPlugin).GetOpenPluginInfo(Info);
end;

(*
  Функция ClosePlugin вызывается при выгрузке плагина.
*)
{$IFDEF UNICODE}
procedure ClosePluginW(hPlugin: THandle); stdcall;
{$ELSE}
procedure ClosePlugin(hPlugin: THandle); stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'ClosePlugin');
{$ENDIF}
  if hPlugin <> 0 then
    TCanon(hPlugin).Free;
end;

(*
  Функция Configure вызывается при создании диалога конфигурации плагина.
*)
{$IFDEF UNICODE}
function ConfigureW(number: Integer): Integer; stdcall;
{$ELSE}
function Configure(number: Integer): Integer; stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'Configure');
{$ENDIF}
  with TConfigDlg.Create do
  try
    Result := Execute;
  finally
    Free;
  end;
end;

(*
  Функция GetFindData вызывается для получения списка файлов
  из текущего каталога эмулируемой файловой системы.
*)
{$IFDEF UNICODE}
function GetFindDataW(hPlugin: THandle; var PanelItem: PPluginPanelItem;
  var ItemsNumber: Integer; OpMode: Integer): Integer; stdcall;
{$ELSE}
function GetFindData(hPlugin: THandle; var PanelItem: PPluginPanelItem;
  var ItemsNumber: Integer; OpMode: Integer): Integer; stdcall;
{$ENDIF}
begin
  if hPlugin <> 0 then
    Result := TCanon(hPlugin).GetFindData(PanelItem, ItemsNumber, OpMode)
  else
    Result := 0;
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'GetFindData', ',', OpMode, '=', Result);
{$ENDIF}
end;

(*
  Функция FreeFindData освобождает память под данные,
  запрошенную функцией GetFindData.
*)
(* // Память будет освобождать класс
{$IFDEF UNICODE}
procedure FreeFindDataW(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber: Integer); stdcall;
{$ELSE}
procedure FreeFindData(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber: Integer); stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'FreeFindData');
{$ENDIF}
end;*)

(*
  Функция SetDirectory вызывается для смены каталога
  в эмулируемой файловой системе.
*)
{$IFDEF UNICODE}
function SetDirectoryW(hPlugin: THandle; Dir: PFarChar;
  OpMode: Integer): Integer; stdcall;
{$ELSE}
function SetDirectory(hPlugin: THandle; Dir: PFarChar;
  OpMode: Integer): Integer; stdcall;
{$ENDIF}
begin
  if hPlugin <> 0 then
    Result := TCanon(hPlugin).SetDirectory(Dir, OpMode)
  else
    Result := 0;
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'SetDirectory', ',', TFarString(Dir), ',', OpMode, '=', Result);
{$ENDIF}
end;

(*
  Функция DeleteFiles вызывается для удаления файлов
  из эмулируемой файловой системы.
*)
{$IFDEF UNICODE}
function DeleteFilesW(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber, OpMode: Integer): Integer; stdcall;
{$ELSE}
function DeleteFiles(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber, OpMode: Integer): Integer; stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'DeleteFiles', ',', OpMode);
{$ENDIF}
  if hPlugin <> 0 then
    Result := TCanon(hPlugin).DeleteFiles(PanelItem, ItemsNumber, OpMode)
  else
    Result := 0;
end;

(*
  Функция GetFiles вызывает для получения файлов
  из эмулируемой файловой системы.
*)
{$IFDEF UNICODE}
function GetFilesW(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber, Move: Integer; var DestPath: PFarChar; OpMode: Integer): Integer; stdcall;
{$ELSE}
function GetFiles(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber, Move: Integer; DestPath: PFarChar; OpMode: Integer): Integer; stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'GetFiles', ',', OpMode);
{$ENDIF}
  if hPlugin <> 0 then
    Result := TCanon(hPlugin).GetFiles(PanelItem, ItemsNumber, Move, DestPath,
      OpMode)
  else
    Result := 0;
end;

(*
  Функция MakeDirectory вызывается для создания нового каталога
  в эмулируемой файловой системе.
*)
// Создание каталогов в эмулируемой файловой системе запрещено
(*{$IFDEF UNICODE}
function MakeDirectoryW(hPlugin: THandle; var Name: PFarChar;
  OpMode: Integer): Integer; stdcall;
{$ELSE}
function MakeDirectory(hPlugin: THandle; var Name: PFarChar;
  OpMode: Integer): Integer; stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'MakeDirectory', ',', OpMode);
{$ENDIF}
  Result := 0;
end;*)

(*
  Функция PutFiles вызывается для перемещения файлов на панель
  эмулируемой файловой системы.
*)
// Запись файлов в эмулируемой файловой системе запрещена
(*{$IFDEF UNICODE}
function PutFilesW(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber, Move: Integer; SrcPath: PFarChar; OpMode: Integer): Integer; stdcall;
{$ELSE}
function PutFiles(hPlugin: THandle; PanelItem: PPluginPanelItem;
  ItemsNumber, Move, OpMode: Integer): Integer; stdcall;
{$ENDIF}
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'PutFiles', ',', OpMode);
{$ENDIF}
  Result := 0;
end;*)

exports
{$IFDEF UNICODE}
  SetStartupInfoW,
  GetPluginInfoW,
  ConfigureW,
  OpenPluginW,
  GetOpenPluginInfoW,
  ClosePluginW,
  GetFindDataW,
  SetDirectoryW,
  DeleteFilesW,
  GetFilesW;
  {
  FreeFindDataW,
  MakeDirectoryW,
  PutFilesW;
  }
{$ELSE}
  SetStartupInfo,
  GetPluginInfo,
  Configure,
  OpenPlugin,
  GetOpenPluginInfo,
  ClosePlugin,
  GetFindData,
  SetDirectory,
  DeleteFiles,
  GetFiles;
  {
  FreeFindData,
  MakeDirectory,
  PutFiles
  }
{$ENDIF}

{$IFDEF OUT_LOG}
initialization

  AssignFile(LogFile, 'EOSFAR.LOG');
  Rewrite(LogFile);

finalization
  Close(LogFile);
{$ENDIF}

end.
