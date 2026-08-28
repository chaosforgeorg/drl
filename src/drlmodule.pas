{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmodule;
interface
uses vlua, vutil, vnode, vgenerics;

type TDRLModule = class
    ID           : Ansistring;
    Name         : Ansistring;
    Path         : Ansistring;
    BaseRequired : AnsiString;
    BaseVersion  : Ansistring;
    WorkshopID   : AnsiString;
    LoadPriority : Integer;
    SaveVersion  : Integer;
    SaveAgnostic : Boolean;
    IsBase       : Boolean;

    Source       : ( DRLMWAD, DRLMSOURCE, DRLMSTEAM );
    Hooks        : TFlags;
  end;

type TModuleArray = specialize TGObjectArray< TDRLModule >;
     TModuleList  = specialize TGArray< TDRLModule >;
     TModuleHash  = specialize TGHashMap< TDRLModule >;



type

{ TDRLModules }

TDRLModules = class(TVObject)
  constructor Create( const aDataPath : AnsiString;
    const aModulesFile : AnsiString = '' );
  procedure ScanModules;
  function Validate( const aCoreModuleID : Ansistring ) : Ansistring;
  procedure ActivateModules( const aCoreModuleID : Ansistring );
  function GetModuleInfo( const aModuleID : Ansistring ) : TDRLModule;
  destructor Destroy; override;
private
  FModules       : TModuleArray;
  FModuleMap     : TModuleHash;
  FCoreModules   : TModuleList;
  FActiveModules : TModuleList;
  FCoreModule    : TDRLModule;
  FCoreModuleID  : Ansistring;
  FModString     : Ansistring;
  FDataPath      : AnsiString;
  FModulesFile   : AnsiString;
private
  function ReadMetaFromModule( aLua : TLua; aOverride : Boolean;
    const aExpectedID : AnsiString = '';
    aRequired : Boolean = False ) : TDRLModule;
  procedure ReadMetaFromWAD( aLua : TLua; const aPath : Ansistring; aOverride : Boolean = True );
  procedure ReadMetaFromFolder( aLua : TLua; const aPath : Ansistring;
    aOverride : Boolean = True; const aExpectedID : AnsiString = '';
    aRequired : Boolean = False );
  procedure ReadMetaFromSteamFolder( aLua : TLua; const aPath : Ansistring );
  procedure ScanExternalModules( aLua : TLua );
public
  property ActiveModules : TModuleList read FActiveModules;
  property CoreModules   : TModuleList read FCoreModules;
  property CoreModule    : TDRLModule  read FCoreModule;
  property CoreModuleID  : Ansistring  read FCoreModuleID;
  property ModString     : Ansistring  read FModString;
end;

var Modules : TDRLModules;

implementation

uses sysutils, variants, vluatable, vdf, vstoreinterface, dfdata;

function DRLModuleCompare( const A, B : TDRLModule ) : Integer;
begin
  if B.LoadPriority <> A.LoadPriority then
    Exit( B.LoadPriority - A.LoadPriority );
  Exit( CompareStr( A.ID, B.ID ) );
end;

constructor TDRLModules.Create( const aDataPath : AnsiString;
  const aModulesFile : AnsiString );
begin
  FDataPath    := aDataPath;
  FModulesFile := aModulesFile;
  FModules       := TModuleArray.Create( True );
  FModuleMap     := TModuleHash.Create;
  FActiveModules := TModuleList.Create;
  FCoreModules   := TModuleList.Create;
  FCoreModule    := nil;
  FCoreModuleID  := '';
  FModString     := '';
end;

procedure TDRLModules.ScanModules;
var iInfo   : TSearchRec;
    iModule : TDRLModule;
    iLua    : TLua;
    iStore  : TStoreInterface;
    iSMods  : TModArray;
    iSMInfo : TModInfo;
begin
  FModules.Clear;
  FModuleMap.Clear;
  FCoreModules.Clear;
  FActiveModules.Clear;
  FCoreModule := nil;
  iLua := nil;
  try
    iLua := TLua.Create;

    if FindFirst( FDataPath + '*.wad', faAnyFile, iInfo ) = 0 then
    repeat
       if ( iInfo.Name <> 'player.wad' ) and ( iInfo.Name <> 'score.wad' ) then
         ReadMetaFromWAD( iLua, FDataPath + iInfo.Name );
    until FindNext(iInfo) <> 0;
    FindClose(iInfo);

    if FindFirst( FDataPath + 'data' + PathDelim + '*', faDirectory, iInfo ) = 0 then
    begin
      repeat
        if (iInfo.Attr and faDirectory <> 0) and (iInfo.Name <> '.') and (iInfo.Name <> '..') then
          ReadMetaFromFolder( iLua,FDataPath + 'data' + PathDelim + iInfo.Name + PathDelim, Option_ForceRaw );
      until FindNext(iInfo) <> 0;
    end;
    FindClose(iInfo);

    ScanExternalModules( iLua );

    iStore := TStoreInterface.Get;
    if iStore.IsSteam and iStore.IsInitialized then
    begin
      iSMods := iStore.GetMods;
      if iSMods <> nil then
      begin
        Log( 'found %d Steam Workshop mods.', [ iSMods.Size ] );
        for iSMInfo in iSMods do
        begin
          Log( 'found Workshop module %d', [ iSMInfo.ID ] );
          ReadMetaFromSteamFolder( iLua, iSMInfo.Folder+PathDelim );
        end;
      end
      else
      Log( 'no Steam Workshop mods found.' );
    end;

    // Add steam workshop folders support
  finally
    FreeAndNil( iLua );
  end;
  FModules.Sort( @DRLModuleCompare );

  for iModule in FModules do
    if iModule.IsBase then
    begin
      FCoreModules.Push( iModule );
      Log( 'found base module %s (%s)', [ iModule.ID, iModule.Path ] );
    end;

  if FCoreModules.Size = 1 then
     FCoreModuleID := FCoreModules[0].ID;
end;

function TDRLModules.Validate( const aCoreModuleID : Ansistring ) : Ansistring;
var iModule : TDRLModule;
begin
  if aCoreModuleID <> '' then
    for iModule in FCoreModules do
      if iModule.ID = aCoreModuleID then
      begin
        FCoreModuleID := iModule.ID;
        FCoreModule   := iModule;
        Break;
      end;
  Exit( FCoreModuleID );
end;

procedure TDRLModules.ActivateModules( const aCoreModuleID : Ansistring );
var iModule : TDRLModule;
begin
  FCoreModuleID := aCoreModuleID;
  FCoreModule   := nil;
  FModString    := '';
  FActiveModules.Clear;

  for iModule in FModules do
    if ( ( iModule.BaseRequired = aCoreModuleID ) or ( iModule.BaseRequired = '' ) )
    and ( ( not iModule.IsBase ) or ( iModule.ID = aCoreModuleID ) ) then
    begin
      FActiveModules.Push( iModule );
      if iModule.IsBase then FCoreModule := iModule;
      if ( not iModule.IsBase ) and ( not iModule.SaveAgnostic ) then
      begin
        if FModString <> '' then FModString += ' ';
        FModString += iModule.ID;
        if iModule.SaveVersion > 0 then FModString += IntToStr( iModule.SaveVersion );
      end;
      Log( 'activating module %s (%s)', [ iModule.ID, iModule.Path ] );
    end;
  Log( 'mod_string generated "%s"', [ FModString ] );
end;

function TDRLModules.ReadMetaFromModule( aLua : TLua; aOverride : Boolean;
  const aExpectedID : AnsiString = '';
  aRequired : Boolean = False ) : TDRLModule;
var iModule : TDRLModule;
    i       : Integer;
begin
  iModule := TDRLModule.Create;
  try
    iModule.ID := 'unknown';
    with TLuaTable.Create( aLua.NativeState, 'meta' ) do
    try
      iModule.ID           := GetString( 'id' );
      iModule.Name         := GetString( 'name', iModule.ID );
      iModule.BaseVersion  := GetString( 'base_version', '' );
      iModule.Path         := '';
      iModule.BaseRequired := GetString( 'base_required', '' );
      iModule.WorkshopID   := GetString( 'workshop_id', '' );
      iModule.LoadPriority := GetInteger( 'load_priority', 0 );
      iModule.SaveVersion  := GetInteger( 'save_version', 0 );
      iModule.SaveAgnostic := GetBoolean( 'save_agnostic', False );
      iModule.IsBase       := GetBoolean( 'is_base', False );
      iModule.Hooks        := [];
      if ( aExpectedID <> '' ) and ( iModule.ID <> aExpectedID ) then
        raise Exception.CreateFmt(
          'External module mapping "%s" declares module "%s"',
          [ aExpectedID, iModule.ID ]
        );
    finally
      Free;
    end;
  except on e : Exception do
    begin
      Log( LOGERROR, 'error while loading module "%s"...', [iModule.ID] );
      FreeAndNil( iModule );
      if aRequired then raise;
      Exit( nil );
    end;
  end;
  if FModuleMap[ iModule.ID ] <> nil then
  begin
    if not aOverride then
    begin
      Log( LOGINFO, 'module "%s" repeated - ignoring...', [iModule.ID] );
      FreeAndNil( iModule );
      Exit( nil );
    end;
    for i := 0 to FModules.Size - 1 do
      if FModules[i].ID = iModule.ID then
      begin
        FModules[i] := iModule;
        Break;
      end;
    Log( LOGINFO, 'overriding module "%s"!', [iModule.ID] );
  end
  else
  begin
    FModules.Push( iModule );
    Log( LOGINFO, 'registered module "%s".', [iModule.ID] );
  end;
  FModuleMap[ iModule.ID ] := iModule;
  Exit( iModule );
end;

procedure TDRLModules.ReadMetaFromWAD( aLua : TLua; const aPath : Ansistring; aOverride : Boolean = True );
var iData   : TVDataFile;
    iModule : TDRLModule;
begin
  Log( LOGINFO, 'found WAD module "%s"...', [aPath] );
  try
    iData       := TVDataFile.Create( aPath );
    iData.DKKey := LoveLace;
    if iData.FileExists( 'meta.lua' ) then
    begin
      aLua.LoadStream( iData, 'meta.lua' );
      iModule := ReadMetaFromModule( aLua, aOverride );
      if iModule <> nil then
      begin
        iModule.Path   := aPath;
        iModule.Source := DRLMWAD;
      end;
    end;
  finally
    iData.Free;
  end;
end;

procedure TDRLModules.ReadMetaFromFolder( aLua : TLua;
  const aPath : Ansistring; aOverride : Boolean = True;
  const aExpectedID : AnsiString = ''; aRequired : Boolean = False );
var iModule : TDRLModule;
begin
  Log( LOGINFO, 'found module "%s"...', [aPath] );
  if FileExists( aPath + 'meta.lua' ) then
  begin
    if aRequired then aLua.Register( 'meta', Null );
    aLua.LoadFile( aPath + 'meta.lua' );
    iModule := ReadMetaFromModule(
      aLua, aOverride, aExpectedID, aRequired
    );
    if iModule <> nil then
    begin
      iModule.Path   := aPath;
      iModule.Source := DRLMSOURCE;
    end;
  end;
end;

procedure TDRLModules.ScanExternalModules( aLua : TLua );
var iManifestPath : AnsiString;
    iModuleID     : AnsiString;
    iPath         : AnsiString;
    iPathAbsolute : Boolean;
    iPaths        : TLuaTable;
    iPair         : TLuaValuePair;

  procedure MalformedEntry;
  begin
    raise Exception.CreateFmt(
      'Malformed module_paths entry %s', [ iModuleID ]
    );
  end;
begin
  if FModulesFile = '' then
    iManifestPath := FDataPath + 'modules.local.lua'
  else
  begin
    iManifestPath := ExpandFileName( FModulesFile );
    if not FileExists( iManifestPath ) then
      raise Exception.CreateFmt('External module manifest not found: %s', [ iManifestPath ]);
  end;
  if not FileExists( iManifestPath ) then Exit;

  aLua.Register( 'module_paths', Null );
  aLua.LoadFile( iManifestPath );
  iPaths := TLuaTable.Create( aLua.NativeState, 'module_paths' );
  try
    for iPair in iPaths.Pairs do
    begin
      if not iPair.Key.IsString then Continue;
      iModuleID := iPair.Key.ToString;
      if Trim( iModuleID ) = '' then Continue;

      if not iPair.Value.IsString then MalformedEntry;
      iPath := Trim( iPair.Value.ToString );
      if iPath = '' then MalformedEntry;
      iPathAbsolute := (ExtractFileDrive(iPath) <> '') or
        (iPath[1] = PathDelim) or (iPath[1] = '/') or (iPath[1] = '\');
      if not iPathAbsolute then
        iPath := ExtractFilePath( iManifestPath ) + iPath;
      iPath := IncludeTrailingPathDelimiter( ExpandFileName( iPath ) );

      if ( not DirectoryExists( iPath ) )
      or ( not FileExists( iPath + 'meta.lua' ) ) then
        MalformedEntry;
      try
        ReadMetaFromFolder( aLua, iPath, True, iModuleID, True );
      except
        MalformedEntry;
      end;
    end;
  finally
    iPaths.Free;
  end;
end;

procedure TDRLModules.ReadMetaFromSteamFolder( aLua : TLua; const aPath : Ansistring );
var iModule : TDRLModule;
begin
  Log( LOGINFO, 'found Workshop path "%s"...', [aPath] );
  if FileExists( aPath + 'meta.lua' ) then
  begin
    aLua.LoadFile( aPath + 'meta.lua' );
    iModule := ReadMetaFromModule( aLua, False );
    if iModule <> nil then
    begin
      iModule.Path   := aPath;
      iModule.Source := DRLMSTEAM;
      if FileExists( aPath + iModule.ID + '.wad' ) then
      begin
        Log( LOGINFO, 'Workshop module "%s" registered as WAD module.', [iModule.ID] );
        iModule.Path := aPath + iModule.ID + '.wad';
      end;
    end;
  end;
end;

function TDRLModules.GetModuleInfo( const aModuleID : Ansistring ) : TDRLModule;
var iModule : TDRLModule;
begin
  for iModule in FModules do
    if iModule.ID = aModuleID then
      Exit( iModule );
  Exit( nil );
end;

destructor TDRLModules.Destroy;
begin
  FreeAndNil( FActiveModules );
  FreeAndNil( FCoreModules );
  FreeAndNil( FModuleMap );
  FreeAndNil( FModules );
  inherited Destroy;
end;

end.
