{$INCLUDE drl.inc}
unit drlgamedata;
interface

uses vlua, vlualibrary,
     dfmap, drlperk, drlparticles;

// Rule switches the loaded modules set in core.options.
type TModuleRules = record
  NewMenu              : Boolean;
  MeleeMoveOnKill      : Boolean;
  FullBeingDescription : Boolean;
  PercentHealth        : Boolean;
  RelicSlot            : Boolean;
  NewFloorLayout       : Boolean;
  ResistCap            : Integer;
end;

type TGameData = class
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterLuaAPI( aLua : TLua );
    class function FromState( L : PLua_State ) : TGameData; static;
    // Reads core.options once all modules are loaded.
    procedure LoadRules( aLua : TLua );
  private
    FCells    : TCells;
    FPerks    : TPerkDefinitions;
    FEmitters : TEmitterData;
    FRules    : TModuleRules;
  public
    property Cells    : TCells           read FCells;
    property Perks    : TPerkDefinitions read FPerks;
    property Emitters : TEmitterData     read FEmitters;
    property Rules    : TModuleRules     read FRules;
end;

implementation

uses vluagamestack;

var GameDataKey : Byte;

constructor TGameData.Create;
begin
  inherited Create;
  FCells    := TCells.Create;
  FPerks    := TPerkDefinitions.Create;
  FEmitters := TEmitterData.Create;
  FRules.ResistCap := 95;
end;

procedure TGameData.LoadRules( aLua : TLua );
begin
  FRules.NewMenu              := aLua.Get( ['core','options','new_menu'], False );
  FRules.MeleeMoveOnKill      := aLua.Get( ['core','options','melee_move_on_kill'], False );
  FRules.FullBeingDescription := aLua.Get( ['core','options','full_being_description'], False );
  FRules.PercentHealth        := aLua.Get( ['core','options','percent_health'], False );
  FRules.RelicSlot            := aLua.Get( ['core','options','relic_slot'], False );
  FRules.NewFloorLayout       := aLua.Get( ['core','options','new_floor_layout'], False );
  FRules.ResistCap            := aLua.Get( ['core','options','resist_cap'], 95 );
end;

destructor TGameData.Destroy;
begin
  FEmitters.Free;
  FPerks.Free;
  FCells.Free;
  inherited Destroy;
end;

class function TGameData.FromState( L : PLua_State ) : TGameData;
begin
  lua_pushlightuserdata( L, @GameDataKey );
  lua_rawget( L, LUA_REGISTRYINDEX );
  Result := TGameData( lua_touserdata( L, -1 ) );
  lua_pop( L, 1 );
  if Result = nil then
    luaL_error( L, 'Game definitions are not available' );
end;

function lua_core_register_cell( L : PLua_State ) : Integer; cdecl;
var iState : TLuaGameStack;
    iData  : TGameData;
    iLua   : TLua;
begin iState.Init( L );
  iData := TGameData.FromState( L );
  iLua  := TLuaContext.FromState( L ).Lua;
  iData.Cells.RegisterCell( iLua, iState.ToInteger( 1 ) );
  Result := 0;
end;

function lua_core_register_perk( L : PLua_State ) : Integer; cdecl;
var iState : TLuaGameStack;
    iData  : TGameData;
    iLua   : TLua;
begin iState.Init( L );
  iData := TGameData.FromState( L );
  iLua  := TLuaContext.FromState( L ).Lua;
  iData.Perks.RegisterPerk( iLua, iState.ToInteger( 1 ) );
  Result := 0;
end;

function lua_core_register_emitter( L : PLua_State ) : Integer; cdecl;
var iState : TLuaGameStack;
    iData  : TGameData;
    iLua   : TLua;
begin iState.Init( L );
  iData := TGameData.FromState( L );
  iLua  := TLuaContext.FromState( L ).Lua;
  iData.Emitters.RegisterEmitter( iLua, iState.ToInteger( 1 ) );
  Result := 0;
end;

const lua_data_lib : array[0..3] of luaL_Reg = (
  ( name : 'register_cell';    func : @lua_core_register_cell ),
  ( name : 'register_perk';    func : @lua_core_register_perk ),
  ( name : 'register_emitter'; func : @lua_core_register_emitter ),
  ( name : nil;               func : nil )
);

procedure TGameData.RegisterLuaAPI( aLua : TLua );
begin
  lua_pushlightuserdata( aLua.Raw, @GameDataKey );
  lua_pushlightuserdata( aLua.Raw, Self );
  lua_rawset( aLua.Raw, LUA_REGISTRYINDEX );
  aLua.Register( 'core', lua_data_lib );
end;

end.
