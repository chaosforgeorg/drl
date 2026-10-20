{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drllua;
interface

uses sysutils, classes,
     vluagamestack, vlua, vlualibrary, vrltools, vutil, vdf, viotypes, vnode,
     dfitem, dfbeing, dfthing, dfdata, drlmodule, drlhelp, drlio;

type

{ TDRLLua }

TDRLLua = class(TLua)
       constructor Create( aModules : TDRLModules; const aDataPath : AnsiString ); reintroduce;
       procedure RegisterPlayer(Thing: TThing);
       function HookName( aHook : Byte ) : AnsiString;
       destructor Destroy; override;
       // Load content after Runtime owns Lua and the Session context is bound.
       procedure ReadWad( aIO : TDRLIO; aHelp : THelp; aModErrors : TStringGArray );
       procedure BindNodeContext( aContext : TNodeContext );
     private
       procedure LoadFiles( const aDirectory : AnsiString; aLoader : TVDFLoader; aWildcard : AnsiString = '*' );
     private
       FOpenData    : TVDataFileArray;
       FModules     : TDRLModules;
       FDataPath    : AnsiString;
       FNodeContext : TNodeContext; // Borrowed from the active Session for Lua factories.
     public
       property NodeContext : TNodeContext read FNodeContext;
     end;

// published functions

implementation

uses typinfo, variants,
     vdebug, vluatools, vluadungen, vluaentitynode, vluatype, vtigstyle, vparticleengine,
     dfplayer, dflevel, drlhooks;

function lua_statistics_get_date(L: Plua_State): Integer; cdecl;
var State : TLuaGameStack;
    Curr : TSystemTime;
    DOW  : integer;
begin
  State.Init(L);
  DateTimeToSystemTime(Now(), Curr);
  DOW := DayOfWeek(Now());
  lua_newtable(L);
  // Build the table.
  lua_pushnumber(L, Curr.Millisecond); // Push the value to go in.
  lua_setfield(L, -2, 'millisecond'); // Assign it to the table.
  lua_pushnumber(L, Curr.Second);
  lua_setfield(L, -2, 'second');
  lua_pushnumber(L, Curr.Minute);
  lua_setfield(L, -2, 'minute');
  lua_pushnumber(L, Curr.Hour);
  lua_setfield(L, -2, 'hour');
  lua_pushnumber(L, Curr.Day);
  lua_setfield(L, -2, 'day');
  lua_pushnumber(L, DOW);
  lua_setfield(L, -2, 'dayofweek');
  lua_pushnumber(L, Curr.Month);
  lua_setfield(L, -2, 'month');
  lua_pushnumber(L, Curr.Year);
  lua_setfield(L, -2, 'year');
  Exit(1);
end;

function lua_core_add_to_cell_set(L: Plua_State): Integer; cdecl;
var State : TLuaGameStack;
begin
  State.Init(L);
  case State.ToInteger(1) of
    0 : State.Error('Bad Cellset in Lua!');
    CELLSET_FLOORS  : Include(CellFloors,State.ToInteger(2));
    CELLSET_WALLS   : Include(CellWalls ,State.ToInteger(2));
  end;
  Result := 0;
end;

// ************************************************************************ //
// ************************************************************************ //

function lua_core_set_vision_base_value(L: Plua_State): Integer; cdecl;
var State : TLuaGameStack;
begin
  State.Init(L);
  VisionBaseValue := State.ToInteger(1,8);
  Result := 0;
end;

procedure TDRLLua.ReadWad( aIO : TDRLIO; aHelp : THelp; aModErrors : TStringGArray );
var iProgBase    : DWord;
    iModule      : TDRLModule;
    iData        : TVDataFile;
  function CheckID( const iID : Ansistring ) : Boolean;
  begin
    Exit( ( iID <> 'core' ) and ( iID <> 'drl' ) and ( iID <> 'jhc' ) );
  end;
  procedure SetupBase;
  begin
    VersionEngine         := Get( 'VERSION_ENGINE' );
    VersionEngineSave     := Get( 'VERSION_ENGINE_SAVE' );
    VersionEngineExpected := Get( 'VERSION_ENGINE_EXPECTED' );
    VersionModule         := Get( 'VERSION_MODULE' );
    VersionModuleSave     := Get( 'VERSION_MODULE_SAVE' );
    DemoVersion           := False;
    if RawDefined( 'DEMO' ) then
      DemoVersion := Get( 'DEMO' );

    Log( LOGINFO, 'ENGINE VERSION: '+VersionEngine );
    Log( LOGINFO, 'EXPECTED ENGINE VERSION: '+VersionEngineExpected );
    Log( LOGINFO, 'BASE MODULE VERSION: '+VersionModule );
  end;
  procedure RegisterActiveModules;
  var iIndex : Integer;
  begin
    lua_getglobal( Raw, 'core' );
    lua_createtable( Raw, FModules.ActiveModules.Size, 0 );
    iIndex := 0;
    for iModule in FModules.ActiveModules do
    begin
      Inc( iIndex );
      lua_createtable( Raw, 0, 3 );
      lua_pushstring( Raw, PChar( iModule.ID ) );
      lua_setfield( Raw, -2, 'id' );
      lua_pushstring( Raw, PChar( iModule.Name ) );
      lua_setfield( Raw, -2, 'name' );
      lua_pushboolean( Raw, iModule.IsBaseLoading );
      lua_setfield( Raw, -2, 'base' );
      lua_rawseti( Raw, -2, iIndex );
    end;
    lua_setfield( Raw, -2, 'modules' );
    lua_pop( Raw, 1 );
  end;

begin
  VersionEngine         := '';
  VersionEngineSave     := '';
  VersionEngineExpected := '';
  VersionModule         := '';
  VersionModuleSave     := '';
  DemoVersion           := False;
  aIO.LoadStart;
  iProgBase := aIO.LoadCurrent;
  aIO.LoadProgress(iProgBase);
  SetValue( 'VERSION_MODULE_API', FModules.APIVersion );
  RegisterActiveModules;

  for iModule in FModules.ActiveModules do
  begin
    iData := nil;

    if iModule.Path.EndsWith( '.wad' ) then
    begin
      iData := TVDataFile.Create( iModule.Path );
      iData.DKKey := LoveLace;
      if iData.FileExists( 'main.lua' ) then
      begin
        RegisterModule( iModule.ID, iData );
        if CheckID( iModule.ID ) then
        begin
          if DemoVersion then Halt(0);
          ModdedGame := True;
        end;
        SetValue( 'BASE_MODULE_LOADING', iModule.IsBaseLoading );
        try
          LoadStream( iData,'','main.lua' );
        finally
          SetValue( 'BASE_MODULE_LOADING', False );
        end;
      end;
      iData.RegisterLoader( FILETYPE_RAW, @aHelp.StreamLoader );
      iData.Load('help');
      iData.RegisterLoader( FILETYPE_RAW, @aIO.ASCIILoader );
      iData.Load('ascii');
      aIO.LoadGraphics( iData );
      aIO.Audio.LoadBindingDataFile( iData, 'audio.lua', FDataPath );
      FOpenData.Push( iData );
    end
    else
    begin
      try
        if FileExists( iModule.Path + 'main.lua' ) then
        begin
          if CheckID( iModule.ID ) then
          begin
            if DemoVersion then Continue;
            ModdedGame := True;
          end;
          RegisterModule( iModule.ID, iModule.Path );
          SetValue( 'BASE_MODULE_LOADING', iModule.IsBaseLoading );
          try
            LoadFile( iModule.Path + 'main.lua' );
          finally
            SetValue( 'BASE_MODULE_LOADING', False );
          end;
        end;
        LoadFiles( iModule.Path + 'help', @aHelp.StreamLoader, '*.hlp' );
        LoadFiles( iModule.Path + 'ascii', @aIO.ASCIILoader, '*.asc' );
        aIO.LoadGraphics( iModule.Path + 'graphics' );
        // temporary hack, remove once drllq and drlhq are modules
        aIO.Audio.LoadBindingFile( iModule.Path + 'audio.lua', iModule.Path );
      except
        on E : Exception do
        begin
          if ModdedGame then
          begin
            aModErrors.Push('Error : Mod "'+iModule.ID+'" failed to load!');
            aModErrors.Push('Path  : '+iModule.Path);
            aModErrors.Push( E.Message );
            aModErrors.Push( '' );
          end
          else raise;
        end;
      end;

    end;
    if RawDefined( iModule.ID ) then
      iModule.Hooks := LoadHooks( Self, [ iModule.ID ], ModuleLoadHooks );
    if iModule.IsBase then
      SetupBase;
  end;

  aIO.LoadProgress(iProgBase + 50);
  aIO.Audio.Load;
  aIO.LoadProgress( 100 );

  ModuleOption_KlassAchievements    := Get( ['core','options','klass_achievements'], False );
  ModuleOption_NewMenu              := Get( ['core','options','new_menu'], False );
  ModuleOption_MeleeMoveOnKill      := Get( ['core','options','melee_move_on_kill'], False );
  ModuleOption_FullBeingDescription := Get( ['core','options','full_being_description'], False );
  ModuleOption_PercentHealth        := Get( ['core','options','percent_health'], False );
  ModuleOption_RelicSlot            := Get( ['core','options','relic_slot'], False );
  ModuleOption_NewFloorLayout       := Get( ['core','options','new_floor_layout'], False );
  ModuleOption_ResistCap            := Get( ['core','options','resist_cap'], 95 );

  if ModdedGame then Log( LOGINFO, 'Game is modded.');
end;

procedure TDRLLua.LoadFiles( const aDirectory : AnsiString; aLoader : TVDFLoader; aWildcard : AnsiString = '*' );
var iSearchRec : TSearchRec;
    iStream    : TStream;
begin
  if FindFirst(aDirectory + PathDelim + aWildcard,0,iSearchRec) = 0 then
  repeat
    iStream := TFileStream.Create( aDirectory + PathDelim + iSearchRec.Name, fmOpenRead );
    try
      aLoader( iStream, iSearchRec.Name, iStream.Size );
    finally
      FreeAndNil( iStream );
    end;
  until (FindNext(iSearchRec) <> 0);
end;

procedure TDRLLua.RegisterPlayer(Thing: TThing);
begin
  SetValue('player',Thing);
  RegisterKillsClass( Raw, (Thing as TPlayer).FKills );
end;

destructor TDRLLua.Destroy;
var iData : TVDataFile;
begin
  for iData in FOpenData do
    iData.Free;
  FreeAndNil( FOpenData );
  inherited Destroy;
end;

procedure LogProps( aClass : TClass );
var
  Count, I : Longint;
  PP       : PPropList;
  PD       : PTypeData;
begin
  PD := GetTypeData(aClass.ClassInfo);
  Count := PD^.PropCount;
  GetMem(PP,Count*SizeOf(Pointer));
  GetPropInfos(aClass.ClassInfo,PP);
  Log('Properties : '+aClass.ClassName+' (total count : '+IntToStr(Count)+')');
  for I:=0 to Count-1 do
    Log('Property ('+IntToStr(I)+'): '+PP^[I]^.Name); //('+GetPropInfo(aClass,Name)^.PropType^.Name+')');
  FreeMem(PP);
end;

const lua_statistics_lib : array[0..1] of luaL_Reg = (
    ( name : 'get_date';   func : @lua_statistics_get_date),
    ( name : nil;          func : nil; )
);

function lua_core_resolve_callback( L: Plua_State; aIndex : Integer ) : Integer;
var iName : AnsiString;
    i, n  : Integer;
begin
  iName := lua_tolstring( L, aIndex, nil );
  // search standard hooks first
  for i in AllHooks do
    if HookNames[i] = iName then
      Exit( i );
  // search core.callbacks
  lua_getglobal( L, 'core' );
  lua_getfield( L, -1, 'callbacks' );
  n := lua_objlen( L, -1 );
  for i := 1 to n do
  begin
    lua_rawgeti( L, -1, i );
    if lua_tolstring( L, -1, nil ) = iName then
    begin
      lua_pop( L, 3 );
      Exit( i + 200 );
    end;
    lua_pop( L, 1 );
  end;
  lua_pop( L, 2 );
  luaL_error( L, 'core.callback - unknown callback "%s"!', lua_tolstring( L, aIndex, nil ) );
  Result := -1;
end;

function lua_core_callback(L: Plua_State): Integer; cdecl;
var iState  : TLuaGameStack;
    iObject : TObject;
    iHook   : Integer;
    iTop    : Integer;
    i       : Integer;
    iParams : array of TVarRec;
begin
  iState.Init(L);
  iObject := iState.ToObject( 1 );
  luaL_checktype( L, 2, LUA_TSTRING );
  iHook := lua_core_resolve_callback( L, 2 );
  iTop := lua_gettop( L );
  if iTop > 2 then
  begin
    SetLength( iParams, iTop - 2 );
    for i := 3 to iTop do
    begin
      iParams[i-3].vtype   := vtObject;
      iParams[i-3].vObject := LuaStackRef( L, i );
    end;
    if iObject is TThing then
      ( iObject as TThing ).CallHook( iHook, iParams )
    else if iObject is TLevel then
      ( iObject as TLevel ).CallHook( iHook, iParams )
    else
      luaL_error( L, 'core.callback - object does not support callbacks!' );
    for i := 0 to High( iParams ) do
      TObject( iParams[i].vObject ).Free;
  end
  else
    if iObject is TThing then
      ( iObject as TThing ).CallHook( iHook, [] )
    else if iObject is TLevel then
      ( iObject as TLevel ).CallHook( iHook, [] )
    else
      luaL_error( L, 'core.callback - object does not support callbacks!' );
  Result := 0;
end;

const lua_core_lib : array[0..3] of luaL_Reg = (
    ( name : 'add_to_cell_set';       func : @lua_core_add_to_cell_set),
    ( name : 'set_vision_base_value'; func : @lua_core_set_vision_base_value),
    ( name : 'callback';              func : @lua_core_callback),

    ( name : nil;          func : nil; )
);

procedure TDRLLua.BindNodeContext( aContext : TNodeContext );
begin
  FNodeContext := aContext;
end;

constructor TDRLLua.Create( aModules : TDRLModules; const aDataPath : AnsiString );
var Count : Byte;
begin
  FModules := aModules;
  FDataPath := aDataPath;
  if GodMode
    then inherited Create( Config.Raw )
    else inherited Create( nil );

  FOpenData := TVDataFileArray.Create;

  RegisterTableAuxFunctions( Raw );
  RegisterMathAuxFunctions( Raw );

  RegisterUIDClass( Raw );
  RegisterCoordClass( Raw );
  RegisterAreaClass( Raw );
  RegisterAreaFull( Raw, NewArea( NewCoord2D(1,1), NewCoord2D(MaxX,MaxY) ) );
  RegisterWeightTableClass( Raw );

  SetValue('WINDOWSVERSION', {$IFDEF WINDOWS}1{$ELSE}0{$ENDIF});
  SetValue('GRAPHICSVERSION',GraphicsVersion);
  SetValue('GODMODE',        GodMode);
  SetValue( 'BASE_MODULE_LOADING', False );

  for Count := 0 to 15 do SetValue(ColorNames[Count],Count);

  Register( 'statistics', lua_statistics_lib );

  Register( 'core', lua_core_lib );

  FStack.RegisterEnumValues( TypeInfo(TParticleFlag) );
  FStack.RegisterEnumValues( TypeInfo(TItemType) );
  FStack.RegisterEnumValues( TypeInfo(TBodyTarget) );
  FStack.RegisterEnumValues( TypeInfo(TEqSlot) );
  FStack.RegisterEnumValues( TypeInfo(TStatusEffect) );
  FStack.RegisterEnumValues( TypeInfo(TDamageType) );
  FStack.RegisterEnumValues( TypeInfo(TExplosionFlag) );
  FStack.RegisterEnumValues( TypeInfo(TResistance) );
  FStack.RegisterEnumValues( TypeInfo(TMoveResult) );
  FStack.RegisterEnumValues( TypeInfo(TTIGStyleColorEntry) );
  FStack.RegisterEnumValues( TypeInfo(TTIGStyleFrameEntry) );
  FStack.RegisterEnumValues( TypeInfo(TTIGStylePaddingEntry) );

  TNode.RegisterLuaAPI( Self, 'game_object' );

  TLuaEntityNode.RegisterLuaAPI( Self, 'thing' );
  TThing.RegisterLuaAPI( Self );

  TItem.RegisterLuaAPI( Self );
  TBeing.RegisterLuaAPI( Self );
  TLevel.RegisterLuaAPI( Self );
  TPlayer.RegisterLuaAPI( Self );
  RegisterDungenClass( Raw, 'generator' );

//  LogProps( TThing );
//  LogProps( TItem );
//  LogProps( TBeing );
//  LogProps( TPlayer );
//  LogProps( TLevel );

  RegisterType( TBeing,  'being', 'beings' );
  RegisterType( TPlayer, 'player', 'beings' );
  RegisterType( TItem,   'item',  'items'  );
  RegisterType( TLevel,  'level', 'levels' );

  GetClassInfo( TBeing ).RegisterHooks( BeingHooks, HookNames );
  GetClassInfo( TPlayer ).RegisterHooks( BeingHooks, HookNames );
end;

function TDRLLua.HookName( aHook : Byte ) : AnsiString;
begin
  if aHook < HookAmount then
    Exit( HookNames[aHook] )
  else if aHook > 200 then
  begin
    Exit( Get( ['core','callbacks', aHook - 200] ) )
  end
  else
    raise ELuaException.Create('Invalid hook ID: '+IntToStr( aHook ) );
end;

end.
