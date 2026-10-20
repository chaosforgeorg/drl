{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmodule;
interface
uses vluastate, vutil, vnode, vgenerics, vstoreinterface;

type TDRLModule = class
    ID           : Ansistring;
    Name         : Ansistring;
    Path         : Ansistring;
    BaseRequired : AnsiString;
    APIVersion   : Ansistring;
    WorkshopID   : AnsiString;
    LoadPriority : Integer;
    SaveVersion  : Integer;
    SaveAgnostic : Boolean;
    IsBase       : Boolean;
    HasScript    : Boolean; // Has main.lua; data-only modules don't use the Lua API.

    Source       : ( DRLMWAD, DRLMSOURCE, DRLMSTEAM );
    Hooks        : TFlags;
    function IsBaseLoading : Boolean;
  end;

type TModuleArray = specialize TGObjectArray< TDRLModule >;
     TModuleList  = specialize TGArray< TDRLModule >;
     TModuleHash  = specialize TGHashMap< TDRLModule >;



type

{ TDRLModules }

TDRLModules = class(TVObject)
  // aFolderOverride lets a module folder replace a WAD module of the same ID.
  constructor Create( const aDataPath : AnsiString; aFolderOverride : Boolean;
    const aModulesFile : AnsiString = '' );
  // aStore lists subscribed Steam Workshop modules; borrowed for the scan.
  procedure ScanModules( aStore : TStoreInterface );
  function Validate( const aCoreModuleID : Ansistring ) : Ansistring;
  procedure ActivateModules( const aCoreModuleID : Ansistring );
  function GetModuleInfo( const aModuleID : Ansistring ) : TDRLModule;
  destructor Destroy; override;
private
  FModules         : TModuleArray;
  FModuleMap       : TModuleHash;
  FCoreModules     : TModuleList;
  FActiveModules   : TModuleList;
  FOutdatedModules : TModuleList;
  FCoreModule      : TDRLModule;
  FCoreModuleID    : Ansistring;
  FModString       : Ansistring;
  FAPIVersion      : Ansistring;
  FDataPath        : AnsiString;
  FModulesFile     : AnsiString;
  FFolderOverride  : Boolean;
private
  function ReadMetaFromModule( aLua : TLuaState; aOverride : Boolean;
    const aExpectedID : AnsiString = '';
    aRequired : Boolean = False ) : TDRLModule;
  procedure ReadMetaFromWAD( aLua : TLuaState; const aPath : Ansistring; aOverride : Boolean = True );
  procedure ReadMetaFromFolder( aLua : TLuaState; const aPath : Ansistring;
    aOverride : Boolean = True; const aExpectedID : AnsiString = '';
    aRequired : Boolean = False );
  procedure ReadMetaFromSteamFolder( aLua : TLuaState; const aPath : Ansistring );
  procedure ScanExternalModules( aLua : TLuaState );
public
  property ActiveModules   : TModuleList read FActiveModules;
  // Active non-base scripted modules whose api_version is missing or older than APIVersion.
  property OutdatedModules : TModuleList read FOutdatedModules;
  property CoreModules     : TModuleList read FCoreModules;
  property CoreModule      : TDRLModule  read FCoreModule;
  property CoreModuleID    : Ansistring  read FCoreModuleID;
  property ModString       : Ansistring  read FModString;
  // Module API version declared by the core module's meta.
  property APIVersion      : Ansistring  read FAPIVersion;
end;

implementation

uses sysutils, variants, vluatable, vdf, dfdata;

function TDRLModule.IsBaseLoading : Boolean;
begin
  Exit( ( ID = 'core' ) or IsBase );
end;

// Compares "x.y.za" style versions segment by segment: numbers numerically,
// then any letter suffix ( "4" < "4a" < "4b" ). Missing segments count as 0.
function CompareVersions( const aLeft, aRight : Ansistring ) : Integer;
var iLeftPos     : Integer;
    iRightPos    : Integer;
    iLeftNumber  : Integer;
    iRightNumber : Integer;
    iLeftSuffix  : Ansistring;
    iRightSuffix : Ansistring;

  procedure ReadSegment( const aVersion : Ansistring; var aPos : Integer;
    out aNumber : Integer; out aSuffix : Ansistring );
  begin
    aNumber := 0;
    aSuffix := '';
    while ( aPos <= Length( aVersion ) ) and ( aVersion[aPos] in ['0'..'9'] ) do
    begin
      aNumber := aNumber * 10 + Ord( aVersion[aPos] ) - Ord( '0' );
      Inc( aPos );
    end;
    while ( aPos <= Length( aVersion ) ) and ( aVersion[aPos] <> '.' ) do
    begin
      aSuffix += aVersion[aPos];
      Inc( aPos );
    end;
    Inc( aPos );
  end;

begin
  iLeftPos  := 1;
  iRightPos := 1;
  while ( iLeftPos <= Length( aLeft ) ) or ( iRightPos <= Length( aRight ) ) do
  begin
    ReadSegment( aLeft,  iLeftPos,  iLeftNumber,  iLeftSuffix );
    ReadSegment( aRight, iRightPos, iRightNumber, iRightSuffix );
    if iLeftNumber <> iRightNumber then
      Exit( iLeftNumber - iRightNumber );
    Result := CompareStr( iLeftSuffix, iRightSuffix );
    if Result <> 0 then Exit;
  end;
  Exit( 0 );
end;

function DRLModuleCompare( const A, B : TDRLModule ) : Integer;
begin
  if B.LoadPriority <> A.LoadPriority then
    Exit( B.LoadPriority - A.LoadPriority );
  Exit( CompareStr( A.ID, B.ID ) );
end;

constructor TDRLModules.Create( const aDataPath : AnsiString; aFolderOverride : Boolean;
  const aModulesFile : AnsiString );
begin
  FDataPath       := aDataPath;
  FModulesFile    := aModulesFile;
  FFolderOverride := aFolderOverride;
  FModules       := TModuleArray.Create( True );
  FModuleMap     := TModuleHash.Create;
  FActiveModules   := TModuleList.Create;
  FOutdatedModules := TModuleList.Create;
  FCoreModules     := TModuleList.Create;
  FCoreModule      := nil;
  FCoreModuleID    := '';
  FModString       := '';
  FAPIVersion      := '';
end;

procedure TDRLModules.ScanModules( aStore : TStoreInterface );
var iInfo   : TSearchRec;
    iModule : TDRLModule;
    iLua    : TLuaState;
    iSMods  : TModArray;
    iSMInfo : TModInfo;
begin
  FModules.Clear;
  FModuleMap.Clear;
  FCoreModules.Clear;
  FActiveModules.Clear;
  FOutdatedModules.Clear;
  FCoreModule := nil;
  FAPIVersion := '';
  iLua := nil;
  try
    iLua := TLuaState.Create;

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
          ReadMetaFromFolder( iLua,FDataPath + 'data' + PathDelim + iInfo.Name + PathDelim, FFolderOverride );
      until FindNext(iInfo) <> 0;
    end;
    FindClose(iInfo);

    ScanExternalModules( iLua );

    if aStore.IsSteam and aStore.IsInitialized then
    begin
      iSMods := aStore.GetMods;
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
  FAPIVersion   := '';
  FActiveModules.Clear;
  FOutdatedModules.Clear;

  if FModuleMap[ 'core' ] <> nil then
    FAPIVersion := FModuleMap[ 'core' ].APIVersion;

  for iModule in FModules do
    if ( ( iModule.BaseRequired = aCoreModuleID ) or ( iModule.BaseRequired = '' ) )
    and ( ( not iModule.IsBase ) or ( iModule.ID = aCoreModuleID ) ) then
    begin
      FActiveModules.Push( iModule );
      if iModule.IsBase then FCoreModule := iModule;
      if ( not iModule.IsBaseLoading ) and iModule.HasScript
      and ( ( iModule.APIVersion = '' ) or ( CompareVersions( iModule.APIVersion, FAPIVersion ) < 0 ) ) then
        FOutdatedModules.Push( iModule );
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

function TDRLModules.ReadMetaFromModule( aLua : TLuaState; aOverride : Boolean;
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
      iModule.APIVersion   := GetString( 'api_version', '' );
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

procedure TDRLModules.ReadMetaFromWAD( aLua : TLuaState; const aPath : Ansistring; aOverride : Boolean = True );
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
        iModule.Path      := aPath;
        iModule.Source    := DRLMWAD;
        iModule.HasScript := iData.FileExists( 'main.lua' );
      end;
    end;
  finally
    iData.Free;
  end;
end;

procedure TDRLModules.ReadMetaFromFolder( aLua : TLuaState;
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
      iModule.Path      := aPath;
      iModule.Source    := DRLMSOURCE;
      iModule.HasScript := FileExists( aPath + 'main.lua' );
    end;
  end;
end;

procedure TDRLModules.ScanExternalModules( aLua : TLuaState );
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

procedure TDRLModules.ReadMetaFromSteamFolder( aLua : TLuaState; const aPath : Ansistring );
var iModule : TDRLModule;
    iData   : TVDataFile;
begin
  Log( LOGINFO, 'found Workshop path "%s"...', [aPath] );
  if FileExists( aPath + 'meta.lua' ) then
  begin
    aLua.LoadFile( aPath + 'meta.lua' );
    iModule := ReadMetaFromModule( aLua, False );
    if iModule <> nil then
    begin
      iModule.Path      := aPath;
      iModule.Source    := DRLMSTEAM;
      iModule.HasScript := FileExists( aPath + 'main.lua' );
      if FileExists( aPath + iModule.ID + '.wad' ) then
      begin
        Log( LOGINFO, 'Workshop module "%s" registered as WAD module.', [iModule.ID] );
        iModule.Path := aPath + iModule.ID + '.wad';
        iData := TVDataFile.Create( iModule.Path );
        try
          iData.DKKey := LoveLace;
          iModule.HasScript := iData.FileExists( 'main.lua' );
        finally
          iData.Free;
        end;
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
  FreeAndNil( FOutdatedModules );
  FreeAndNil( FCoreModules );
  FreeAndNil( FModuleMap );
  FreeAndNil( FModules );
  inherited Destroy;
end;

end.
