unit UFileSystem;

{$i CommonDirectives.inc}

interface

uses
  windows,
  kol,
  err,
{$IFDEF UNICODE}
  PluginW,
{$ELSE}
  plugin,
{$ENDIF}
  UUtils,
  UTypes;

type
  TFindDataItem = class(TObject)
  private
    FPanelItem: PPluginPanelItem;
    FItemsNumber: Integer;
    procedure SetItemsNumber(const Value: Integer);
  protected
    procedure FreeUserData(UserData: Pointer); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DeleteItem(Index: Integer); overload;
    procedure DeleteItem(const FileName: PFarChar); overload;
    procedure ClearItems;

    property PanelItem: PPluginPanelItem read FPanelItem;
    property ItemsNumber: Integer read FItemsNumber write SetItemsNumber;
  end;

  TDirNode = class;
  TBeforeChangeDirEvent = procedure(ADirNode: TDirNode;
    var Allow: Boolean) of object;
  TChangeDirEvent = procedure(ADirNode: TDirNode) of object;
  TDirNodeClass = class of TDirNode;
  
  TDirNode = class(TFindDataItem)
  private
    FParent: TDirNode;    // Родительский каталог (nil для корневого каталога)
    FSubDir: PList;       // Список подкаталогов
    FDirName: TFarString; // Наименование каталога
    FUserData: DWORD_PTR; // Пользовательские данные из PluginPanelItem

    FBeforeChangeDir: TBeforeChangeDirEvent;
    FChangeDir: TChangeDirEvent;

    function GetRootDir: TDirNode;
    function GetSubDirCount: Integer;
    function GetSubDir(Index: Integer): TDirNode;
    function GetIndexAsSubDir: Integer;

    function GetIsRoot: Boolean;
    function GetIsLeaf: Boolean;
    function GetDepth: Integer;

    function CreateSubDir(AUserData: DWORD_PTR; AClass: TDirNodeClass;
      const ADirName: TFarString = ''): TDirNode;
    function InternalChDir(const Dir: TFarString): TDirNode;
    function GetFullDirName: TFarString;
  protected
    procedure AddSubDir(Index: Integer; SubDir: TDirNode); virtual;
    procedure RemoveSubDir(SubDir: TDirNode); virtual;
    procedure DeleteSubDir(Index: Integer); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure FillPanelItem; virtual; abstract;

    function ChDir(const Dir: TFarString): TDirNode;

    procedure MoveTo(NewParent: TDirNode; Index: Integer = -1); overload;
    procedure MoveTo(Index: Integer); overload;

    function IndexOf(SubDir: TDirNode): Integer;

    property Parent: TDirNode read FParent;
    property RootDir: TDirNode read GetRootDir;
    property SubDirCount: Integer read GetSubDirCount;
    property SubDir[Index: Integer]: TDirNode read GetSubDir;
    property IndexAsSubDir: Integer read GetIndexAsSubDir;
    procedure FreeSubDir;

    property IsRoot: Boolean read GetIsRoot;
    property IsLeaf: Boolean read GetIsLeaf;
    property Depth: Integer read GetDepth;

    property DirName: TFarString read FDirName;
    property FullDirName: TFarString read GetFullDirName;

    property UserData: DWORD_PTR read FUserData;

    property OnBeforeChangeDir: TBeforeChangeDirEvent read FBeforeChangeDir
      write FBeforeChangeDir;
    property OnChangeDir: TChangeDirEvent read FChangeDir write FChangeDir;
  end;

implementation

{ TFindDataItem }

type
  TPluginPanelItems = array of TPluginPanelItem;

procedure TFindDataItem.DeleteItem(Index: Integer);
begin
  with TPluginPanelItems(FPanelItem)[Index] do
  begin
    if UserData <> 0 then
      FreeUserData(Pointer(UserData));
{$IFDEF UNICODE}
     if Assigned(FindData.cFileName) then
        FreeMem(FindData.cFileName);
{$ENDIF}
  end;
  Dec(FItemsNumber);
  if Index < ItemsNumber then
    MoveMemory(@TPluginPanelItems(FPanelItem)[Index],
      @TPluginPanelItems(FPanelItem)[Index + 1],
      (ItemsNumber - Index) * SizeOf(TPluginPanelItem));
end;

constructor TFindDataItem.Create;
begin
  inherited Create;
  FItemsNumber := 0;
end;

procedure TFindDataItem.DeleteItem(const FileName: PFarChar);
var
  i: Integer;
begin
  for i := 0 to ItemsNumber - 1 do
{$IFDEF UNICODE}
    if WStrComp(TPluginPanelItems(PanelItem)[i].FindData.cFileName, FileName) = 0 then
{$ELSE}
    if StrComp(TPluginPanelItems(PanelItem)[i].FindData.cFileName, FileName) = 0 then
{$ENDIF}
    begin
      DeleteItem(i);
      Break;
    end;
end;

destructor TFindDataItem.Destroy;
begin
  ClearItems;
  inherited;
end;

procedure TFindDataItem.SetItemsNumber(const Value: Integer);
begin
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'GetFreeFindDataItem');
{$ENDIF}
  FItemsNumber := Value;
  GetMem(FPanelItem, FItemsNumber * SizeOf(TPluginPanelItem));
  ZeroMemory(FPanelItem, FItemsNumber * SizeOf(TPluginPanelItem));
end;

procedure TFindDataItem.ClearItems;
var
  i: Integer;
begin
  if ItemsNumber > 0 then
  begin
    for i := 0 to ItemsNumber - 1 do
      with TPluginPanelItems(FPanelItem)[i] do
      begin
        if UserData <> 0 then
          FreeUserData(Pointer(UserData));
{$IFDEF UNICODE}
      if Assigned(FindData.cFileName) then
        FreeMem(FindData.cFileName);
{$ENDIF}
      end;
    FreeMem(PanelItem);
    FItemsNumber := 0;
  end;
{$IFDEF OUT_LOG}
  WriteLn(LogFile, 'FreeFindDataItem');
{$ENDIF}
end;

procedure TFindDataItem.FreeUserData(UserData: Pointer);
begin
end;

{ TDirNode }

procedure TDirNode.AddSubDir(Index: Integer; SubDir: TDirNode);
begin
  if Index < 0 then
    FSubDir.Add(SubDir)
  else
    FSubDir.Insert(Index, SubDir);
end;

constructor TDirNode.Create;
begin
  inherited Create;
  FParent := nil;
  FDirName := '';
  FSubDir := nil;
end;

procedure TDirNode.DeleteSubDir(Index: Integer);
begin
  FSubDir.Delete(Index);
end;

destructor TDirNode.Destroy;
begin
  FreeSubDir;
  inherited;
end;

function TDirNode.GetSubDirCount: Integer;
begin
  Result := FSubDir.Count;
end;

function TDirNode.GetSubDir(Index: Integer): TDirNode;
begin
  Result := FSubDir.Items[Index];
end;

function TDirNode.GetDepth: Integer;
var
  Ancestor: TDirNode;
begin
  Ancestor := Parent;
  Result := 0;

  while Assigned(Ancestor) do
  begin
    Inc(Result);
    Ancestor := Ancestor.Parent;
  end;
end;

function TDirNode.GetIndexAsSubDir: Integer;
begin
  if not Assigned(Parent) then
    Result := -1
  else
    Result := Parent.IndexOf(Self);
end;

function TDirNode.GetIsLeaf: Boolean;
begin
  Result := FSubDir.Count = 0;
end;

function TDirNode.GetIsRoot: Boolean;
begin
  Result := not Assigned(FParent); 
end;

function TDirNode.GetRootDir: TDirNode;
begin
  if IsRoot then
    Result := Self
  else
    Result := Parent.RootDir;
end;

function TDirNode.IndexOf(SubDir: TDirNode): Integer;
begin
  Result := FSubDir.IndexOf(SubDir);
end;

procedure TDirNode.MoveTo(NewParent: TDirNode; Index: Integer);
begin
  if not Assigned(Parent) and not Assigned(NewParent) then
    Exit;

  if Parent = NewParent then
  begin
    if Index <> IndexAsSubDir then
    begin
      Parent.FSubDir.Remove(Self);
      if Index < 0 then
        Parent.FSubDir.Add(Self)
      else
        Parent.FSubDir.Insert(Index, Self);
    end;
  end
  else
  begin
    if Assigned(Parent) then
      Parent.RemoveSubDir(Self);

    FParent := NewParent;

    if Assigned(Parent) then
      Parent.AddSubDir(Index, Self);
  end;
end;

procedure TDirNode.MoveTo(Index: Integer);
begin
  MoveTo(Parent, Index);
end;

procedure TDirNode.RemoveSubDir(SubDir: TDirNode);
begin
  FSubDir.Remove(SubDir);
end;

function TDirNode.ChDir(const Dir: TFarString): TDirNode;
var
  NewDir: TFarString;
begin
  NewDir := ExcludeTrailingPathDelimiter(StringReplace(Dir, '/', cDelim, True));
  if Pos(FullDirName, NewDir) = 1 then
    Delete(NewDir, 1, Length(FullDirName) + 1);
  Result := InternalChDir(NewDir);
end;

function TDirNode.InternalChDir(const Dir: TFarString): TDirNode;
  function TestBeforeChange(ADirNode: TDirNode): Boolean;
  begin
    Result := True;
    if Assigned(FBeforeChangeDir) then
      FBeforeChangeDir(ADirNode, Result);
  end;
  function ChDirRoot: TDirNode;
  begin
    if IsRoot then
      Result := Self
    else
    begin
      Result := nil;
      if TestBeforeChange(RootDir) then
      begin
        Result := RootDir;
        if Assigned(FChangeDir) then
          FChangeDir(Result);
      end;
    end;
  end;
  function ChDirUp: TDirNode;
  begin
    Result := nil;
    if TestBeforeChange(Parent) then
    begin
      Result := Parent;
      if Assigned(FChangeDir) then
        FChangeDir(Result);
    end;
  end;
  function ChDirDown(const NewDir: TFarString): TDirNode;
  var
    i: Integer;
  begin
    Result := nil;
    if not Assigned(FSubDir) then
    begin
      FSubDir := NewList;
      for i := 0 to ItemsNumber - 1 do
        with TPluginPanelItems(FPanelItem)[i] do
        if FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
          AddSubDir(-1, CreateSubDir(UserData, TDirNodeClass(ClassType),
            FindData.cFileName));
    end;
    for i := 0 to SubDirCount - 1 do
      if FSF.LStricmp(PFarChar(NewDir), PFarChar(SubDir[i].DirName)) = 0 then
      begin
        if TestBeforeChange(SubDir[i]) then
        begin
          Result := SubDir[i];
          if Assigned(FChangeDir) then
            FChangeDir(Result);
        end;
        Break;
      end;
  end;
const
  cUpDir = '..';
var
  p: Integer;
  NewDirNode: TDirNode;
begin
  Result := nil;
  if Dir = '' then
    Result := Self
  else if Dir = cUpDir then
    Result := ChDirUp
  else if Dir[1] = cDelim then
  begin
    NewDirNode := ChDirRoot;
    if Assigned(NewDirNode) and (Dir <> cDelim) then
      Result := NewDirNode.InternalChDir(Copy(Dir, 2, Length(Dir) - 1));
  end
  else
  begin
    p := Pos(cDelim, Dir);
    if p = 0 then
      Result := ChDirDown(Dir)
    else
    begin
      NewDirNode := ChDirDown(Copy(Dir, 1, p - 1));
      if Assigned(NewDirNode) then
        Result := NewDirNode.InternalChDir(Copy(Dir, p + 1, Length(Dir) - p));
    end;
  end;
end;

function TDirNode.CreateSubDir(AUserData: DWORD_PTR; AClass: TDirNodeClass;
  const ADirName: TFarString): TDirNode;
begin
  Result := AClass.Create;
  Result.FParent := Self;
  Result.FDirName := ADirName;
  Result.FSubDir := nil;
  Result.FUserData := AUserData;
  Result.FBeforeChangeDir := FBeforeChangeDir;
  Result.FChangeDir := FChangeDir;
  Result.FillPanelItem;
end;

function TDirNode.GetFullDirName: TFarString;
begin
  Result := DirName;
  if Assigned(Parent) and not Parent.IsRoot then
    Result := Parent.GetFullDirName + cDelim + Result;
end;

procedure TDirNode.FreeSubDir;
var
  i: Integer;
begin
  if Assigned(FSubDir) then
  begin
    for i := 0 to FSubDir.Count - 1 do
      TDirNode(FSubDir.Items[i]).Free;
    FreeAndNilKol(FSubDir);
  end;
end;

end.
