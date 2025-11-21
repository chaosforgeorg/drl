{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlua;
interface

uses SysUtils, Classes, vluastate, vluasystem, vlualibrary, vrltools, vutil,
     vdf, viotypes, dfitem, dfbeing, dfthing, dfdata, drlmodule;

var LuaPlayerX : Byte = 2;
    LuaPlayerY : Byte = 2;

type

{ TDRLLua }

TDRLLua = class(TLuaSystem)
       constructor Create; reintroduce;
       procedure OnError(const ErrorString : Ansistring); override;
       procedure RegisterPlayer(Thing: TThing);
       destructor Destroy; override;
     private
       procedure ReadWad;
       procedure LoadFiles( const aDirectory : AnsiString; aLoader : TVDFLoader; aWildcard : AnsiString = '*' );
     private
       FOpenData : TVDataFileArray;
     end;

type

{ TDRLLuaState }

TDRLLuaState = object(TLuaState)
  function ToId( aIndex : Integer) : DWord;
  function ToPosition( aIndex : Integer ) : TCoord2D;
  function ToPosition( aIndex : Integer; aDefault : TCoord2D ) : TCoord2D;
  function ToIOColor( aIndex : Integer ) : TIOColor;
end;

// published functions

implementation

uses typinfo, variants,
     vnode, vdebug, vluatools, vluadungen, vluaentitynode, vmath,
     vtextures, vtigstyle, vvector,
     dfplayer, dflevel, dfmap, drlhooks, drlhelp, dfhof, drlbase, drlio, drlperk,
     drlgfxio, drlspritemap;

var SpriteSheetCounter : Integer = -1;

function lua_core_is_playing(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push( DRL.State = DSPlaying );
  Result := 1;
end;

function lua_statistics_get(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  Player.Statistics.Update;
  // Unused parameter #1 is self
  State.Push( Player.Statistics[ State.ToString( 2 ) ] );
  Result := 1;
end;

function lua_statistics_set(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  // Unused parameter #1 is self
  Player.Statistics.Assign( State.ToString( 2 ), State.ToInteger( 3 ) );
  Result := 0;
end;

function lua_statistics_inc(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  Player.Statistics.Increase( State.ToString( 1 ), State.ToInteger( 2 ) );
  Result := 0;
end;

function lua_statistics_get_date(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
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

function lua_core_register_affect(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
    mID : Integer;
begin
  State.Init(L);
  if High(Affects) = -1 then SetLength(Affects,MAXAFFECT);
  mID := State.ToInteger(1);
  if mID > High(Affects) then
    raise Exception.Create('Maximum number of registered affects reached!');
  with Affects[mID] do
  with LuaSystem.GetTable(['affects',mID]) do
  try
    Name       := getString('name');
    Color      := getInteger('color');
    Color_exp  := getInteger('color_expire');
    AffHooks      := [];
    StatusEff  := TStatusEffect( getInteger('status_effect',0) );
    StatusStr  := getInteger('status_strength',0);
    if isFunction('OnUpdate') then Include(AffHooks, AffectHookOnUpdate);
    if isFunction('OnAdd')    then Include(AffHooks, AffectHookOnAdd);
    if isFunction('OnRemove') then Include(AffHooks, AffectHookOnRemove);
  finally
    Free;
  end;
  Affects[mID].Hooks := LoadHooks( ['affects',mID] );
  Result := 0;
end;

function lua_core_register_perk(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iID    : Integer;
begin
  iState.Init(L);
  iID := iState.ToInteger(1);

  if iID >= High( PerkData ) then
  begin
    SetLength( PerkData, Max( High( PerkData ) * 2, 100 ) );
    PerkDataMax := iID;
  end;
  if iID > PerkDataMax then PerkDataMax := iID;

  with PerkData[iID] do
  begin
    with LuaSystem.GetTable(['perks',iID]) do
    try
      Name      := getString('name','');
      Color     := getInteger('color',0);
      ColorExp  := getInteger('color_expire',0);
      StatusEff := TStatusEffect( getInteger('status_effect',0) );
      StatusStr := getInteger('status_strength',0);
    finally
      Free;
    end;
    Hooks := LoadHooks( ['perks',iID] );
  end;
  Result := 0;
end;

function lua_core_add_to_cell_set(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  case State.ToInteger(1) of
    0 : State.Error('Bad Cellset in Lua!');
    CELLSET_FLOORS  : Include(CellFloors,State.ToInteger(2));
    CELLSET_WALLS   : Include(CellWalls ,State.ToInteger(2));
  end;
  Result := 0;
end;

function lua_core_player_data_count(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push( LongInt(HOF.GetCount( State.ToString( 1 ) )) );
  Result := 1;
end;

function lua_core_player_data_child_count(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push( LongInt(HOF.GetChildCount( State.ToString( 1 ) )) );
  Result := 1;
end;

function lua_core_player_data_get_counted(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push( LongInt(HOF.GetCounted( State.ToString( 1 ), State.ToString( 2 ), State.ToString( 3 ) ) ) );
  Result := 1;
end;

function lua_core_player_data_add_counted(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push( Boolean(HOF.AddCounted( State.ToString( 1 ), State.ToString( 2 ), State.ToString( 3 ), State.ToInteger( 4,1 ) ) ) );
  Result := 1;
end;

function lua_core_play_music(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  IO.Audio.PlayMusic(State.ToString(1));
  Result := 0;
end;

// ************************************************************************ //
// ************************************************************************ //

function lua_core_game_time(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push(Player.Statistics.GameTime);
  Result := 1;
end;

function lua_core_time_ms(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  State.Push( LongInt(IO.Driver.GetMs) );
  Result := 1;
end;

function lua_core_register_cell(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  Cells.RegisterCell(State.ToInteger(1));
  Result := 0;
end;

function lua_core_texture_upload(L: Plua_State): Integer; cdecl;
var State    : TDRLLuaState;
    iTexture : TTexture;
begin
  State.Init(L);
  if not GraphicsVersion then Exit( 0 );
  iTexture := (IO as TDRLGFXIO).Textures.Textures[ State.ToString(1) ];
  if iTexture = nil then State.Error( 'Texture not found: '+State.ToString(1) );
  if State.IsBoolean( 2 ) and State.ToBoolean( 2 ) then iTexture.Blend := True;
  if State.IsBoolean( 3 ) and State.ToBoolean( 3 ) then iTexture.is3D  := True;
  if iTexture.GLTexture = 0
    then iTexture.Upload
    else Log( LOGWARN, 'Texture redefinition: '+State.ToString(1) );
  Result := 0;
end;

function lua_core_register_sprite_sheet(L: Plua_State): Integer; cdecl;
var State     : TDRLLuaState;
    iNormal   : TTexture;
    iCosplay  : TTexture;
    iGlow     : TTexture;
    iEmissive : TTexture;

  function LoadTexture( aIndex : Integer ) : TTexture;
  begin
    if not State.IsString( aIndex ) then Exit( nil );
    LoadTexture := (IO as TDRLGFXIO).Textures.Textures[ State.ToString( aIndex ) ];
    if LoadTexture = nil then State.Error( 'register_sprite_sheet - texture not found : "'+State.ToString( aIndex )+'"!');
    if LoadTexture.GLTexture = 0 then
      LoadTexture.Upload;
    if LoadTexture.Size.X * LoadTexture.Size.Y = 0 then State.Error( 'register_sprite_sheet - texture malformed : "'+State.ToString( aIndex )+'"!');
  end;

begin
  State.Init(L);
  if not GraphicsVersion then
  begin
    Inc( SpriteSheetCounter );
    State.Push( Integer( SpriteSheetCounter * 100000 ) );
    Exit( 1 );
  end;
  iNormal   := LoadTexture( 1 );
  iCosplay  := LoadTexture( 2 );
  iGlow     := LoadTexture( 3 );
  iEmissive := LoadTexture( 4 );
  if iNormal = nil then State.Error( 'Bad parameters passes to register_sprite_sheet!');
  State.Push( Integer( SpriteMap.Engine.Add( iNormal, iCosplay, iEmissive, iGlow, State.ToInteger(5) ) * 100000 ) );
  Result := 1;
end;

function lua_core_set_vision_base_value(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  VisionBaseValue := State.ToInteger(1,8);
  Result := 0;
end;

procedure TDRLLua.ReadWad;
var iProgBase    : DWord;
    iModule      : TDRLModule;
    iData        : TVDataFile;
  function CheckID( const iID : Ansistring ) : Boolean;
  begin
    Exit( ( iID <> 'core' ) and ( iID <> 'drl' ) and ( iID <> 'jhc' ) );
  end;
  procedure SetupBase;
  begin
    VersionModule     := LuaSystem.Get( 'VERSION_MODULE' );
    VersionModuleSave := LuaSystem.Get( 'VERSION_MODULE_SAVE' );
    DemoVersion       := False;
    if LuaSystem.RawDefined( 'DEMO' ) then
      DemoVersion := LuaSystem.Get( 'DEMO' );
  end;

begin
  VersionModule     := '';
  VersionModuleSave := '';
  DemoVersion       := False;
  IO.LoadStart;
  iProgBase := IO.LoadCurrent;
  IO.LoadProgress(iProgBase);

  for iModule in DRL.Modules.ActiveModules do
  begin
    iData := nil;

    if ( not iModule.IsBase ) and ( iModule.BaseVersion <> '' ) then
      if iModule.BaseVersion <> VersionModuleSave then
      begin
        ModErrors.Push('Error   : Mod "'+iModule.ID+'" version mismatch!');
        ModErrors.Push('Expects : '+iModule.BaseVersion);
        ModErrors.Push('');
      end;

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
        LoadStream( iData,'','main.lua' );
      end;
      iData.RegisterLoader( FILETYPE_RAW, @Help.StreamLoader );
      iData.Load('help');
      iData.RegisterLoader( FILETYPE_RAW, @IO.ASCIILoader );
      iData.Load('ascii');
      if GraphicsVersion then
      begin
        iData.RegisterLoader(FILETYPE_IMAGE ,@((IO as TDRLGFXIO).Textures.LoadTextureCallback));
        iData.Load('graphics');
      end;
      IO.Audio.LoadBindingDataFile( iData, 'audio.lua', DataPath );
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
          LoadFile( iModule.Path + 'main.lua' );
        end;
        LoadFiles( iModule.Path + 'help', @Help.StreamLoader, '*.hlp' );
        LoadFiles( iModule.Path + 'ascii', @IO.ASCIILoader, '*.asc' );
        if GraphicsVersion then
          (IO as TDRLGFXIO).Textures.LoadTextureFolder( iModule.Path + 'graphics' );
        // temporary hack, remove once drllq and drlhq are modules
        IO.Audio.LoadBindingFile( iModule.Path + 'audio.lua', iModule.Path );
      except
        on E : Exception do
        begin
          if ModdedGame then
          begin
            ModErrors.Push('Error : Mod "'+iModule.ID+'" failed to load!');
            ModErrors.Push('Path  : '+iModule.Path);
            ModErrors.Push( E.Message );
            ModErrors.Push( '' );
          end
          else raise;
        end;
      end;

    end;
    if LuaSystem.RawDefined( iModule.ID ) then
      iModule.Hooks := LoadHooks( [ iModule.ID ], ModuleHooks );
    if iModule.IsBase then
      SetupBase;
  end;

  IO.LoadProgress(iProgBase + 50);
  IO.Audio.Load;

  ModuleOption_KlassAchievements    := LuaSystem.Get( ['core','options','klass_achievements'], False );
  ModuleOption_NewMenu              := LuaSystem.Get( ['core','options','new_menu'], False );
  ModuleOption_MeleeMoveOnKill      := LuaSystem.Get( ['core','options','melee_move_on_kill'], False );
  ModuleOption_FullBeingDescription := LuaSystem.Get( ['core','options','full_being_description'], False );
  ModuleOption_PercentHealth        := LuaSystem.Get( ['core','options','percent_health'], False );


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

procedure TDRLLua.OnError(const ErrorString : Ansistring);
begin
  if (IO <> nil) and (DRL.State = DSPlaying) then
  begin
    IO.ErrorReport( ErrorString );
  end
  else
    raise ELuaException.Create('LuaError: '+ErrorString);
  Log('LuaError: '+ErrorString);
end;

procedure TDRLLua.RegisterPlayer(Thing: TThing);
begin
  LuaSystem.SetValue('player',Thing);
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

const lua_statistics_lib : array[0..2] of luaL_Reg = (
    ( name : 'inc';        func : @lua_statistics_inc),
    ( name : 'get_date';   func : @lua_statistics_get_date),
    ( name : nil;          func : nil; )
);

const lua_player_data_lib : array[0..4] of luaL_Reg = (
    ( name : 'count';       func : @lua_core_player_data_count),
    ( name : 'child_count'; func : @lua_core_player_data_child_count),
    ( name : 'get_counted'; func : @lua_core_player_data_get_counted),
    ( name : 'add_counted'; func : @lua_core_player_data_add_counted),
    ( name : nil;           func : nil; )
);


const lua_core_lib : array[0..11] of luaL_Reg = (
    ( name : 'add_to_cell_set';func : @lua_core_add_to_cell_set),
    ( name : 'game_time';      func : @lua_core_game_time),
    ( name : 'time_ms';        func : @lua_core_time_ms),
    ( name : 'is_playing';func : @lua_core_is_playing),
    ( name : 'register_cell';   func : @lua_core_register_cell),
    ( name : 'register_affect'; func : @lua_core_register_affect),
    ( name : 'register_perk';   func : @lua_core_register_perk),

    ( name : 'play_music';func : @lua_core_play_music),

    ( name : 'texture_upload';        func : @lua_core_texture_upload),
    ( name : 'register_sprite_sheet'; func : @lua_core_register_sprite_sheet),
    ( name : 'set_vision_base_value'; func : @lua_core_set_vision_base_value),

    ( name : nil;          func : nil; )
);

constructor TDRLLua.Create;
var Count : Byte;
begin
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

  LuaSystem := Self;

  ErrorFunc := @OnError;
  
  SetValue('WINDOWSVERSION', {$IFDEF WINDOWS}1{$ELSE}0{$ENDIF});
  SetValue('VERSION', VERSION_STRING);
  SetValue('VERSION_STRING', VERSION_STRING);
  SetValue('VERSION_BETA',   VERSION_BETA);
  SetValue('GRAPHICSVERSION',GraphicsVersion);

  for Count := 0 to 15 do SetValue(ColorNames[Count],Count);
  TDRLIO.RegisterLuaAPI( State );

  Register( 'statistics', lua_statistics_lib );
  RegisterMetaTable('statistics',@lua_statistics_get, @lua_statistics_set );

  Register( 'player_data', @lua_player_data_lib );
  Register( 'core', lua_core_lib );

  State.RegisterEnumValues( TypeInfo(TItemType) );
  State.RegisterEnumValues( TypeInfo(TBodyTarget) );
  State.RegisterEnumValues( TypeInfo(TEqSlot) );
  State.RegisterEnumValues( TypeInfo(TStatusEffect) );
  State.RegisterEnumValues( TypeInfo(TDamageType) );
  State.RegisterEnumValues( TypeInfo(TAltFire) );
  State.RegisterEnumValues( TypeInfo(TAltReload) );
  State.RegisterEnumValues( TypeInfo(TExplosionFlag) );
  State.RegisterEnumValues( TypeInfo(TResistance) );
  State.RegisterEnumValues( TypeInfo(TMoveResult) );
  State.RegisterEnumValues( TypeInfo(TTIGStyleColorEntry) );
  State.RegisterEnumValues( TypeInfo(TTIGStyleFrameEntry) );
  State.RegisterEnumValues( TypeInfo(TTIGStylePaddingEntry) );

  TNode.RegisterLuaAPI( 'game_object' );

  TLuaEntityNode.RegisterLuaAPI( 'thing' );
  TThing.RegisterLuaAPI();

  TItem.RegisterLuaAPI();
  TBeing.RegisterLuaAPI();
  TLevel.RegisterLuaAPI();
  TPlayer.RegisterLuaAPI();
  RegisterDungenClass( LuaSystem.Raw, 'generator' );

  drlbase.Lua := Self;

//  LogProps( TThing );
//  LogProps( TItem );
//  LogProps( TBeing );
//  LogProps( TPlayer );
//  LogProps( TLevel );

  RegisterType( TBeing,  'being', 'beings' );
  RegisterType( TPlayer, 'player', 'beings' );
  RegisterType( TItem,   'item',  'items'  );
  RegisterType( TLevel,  'level', 'levels' );

  LuaSystem.GetClassInfo( TBeing ).RegisterHooks( BeingHooks, HookNames );
  LuaSystem.GetClassInfo( TPlayer ).RegisterHooks( BeingHooks, HookNames );
  LuaSystem.GetClassInfo( TItem ).RegisterHooks( ItemHooks, HookNames );

  ReadWAD;

end;

{ TDRLLuaState }

function TDRLLuaState.ToId( aIndex: Integer ): DWord;
begin
  if IsNumber( aIndex ) then Exit( ToInteger( aIndex ) );
  ToId := LuaSystem.Defines[ToString( aIndex )];
  if ToId = 0 then Error( 'unknown define ('+ToString( aIndex ) +')!' );
end;

function TDRLLuaState.ToPosition( aIndex : Integer ) : TCoord2D;
begin
  if IsCoord( aIndex ) then
     Exit( ToCoord( aIndex ) )
  else
     Exit( (ToObject( aIndex ) as TThing).Position );
end;

function TDRLLuaState.ToPosition( aIndex : Integer; aDefault : TCoord2D ) : TCoord2D;
begin
  if IsCoord( aIndex ) then
     Exit( ToCoord( aIndex ) )
  else if IsObject( aIndex ) then
     Exit( (ToObject( aIndex ) as TThing).Position )
  else Exit( aDefault );
end;

function TDRLLuaState.ToIOColor( aIndex : Integer ) : TIOColor;
var iC4b : TVec4b;
begin
  Result := 0;
  if IsNumber( aIndex )
    then Exit( ToInteger( aIndex ) )
    else if IsTable( aIndex ) then
    begin
      iC4b := ToVec4b( aIndex );
      Exit( IOColor( iC4b.X, iC4b.Y, iC4b.Z, iC4b.W ) );
    end;
end;

end.

