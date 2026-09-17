{$INCLUDE drl.inc}
unit drlgamedata;
interface

uses vlua, vlualibrary,
     dfmap, drlperk, drlparticles;

type TGameData = class
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterLuaAPI( aLua : TLua );
    class procedure UnregisterLuaAPI( aLua : TLua ); static;
    class function FromState( L : PLua_State ) : TGameData; static;
  private
    FCells    : TCells;
    FPerks    : TPerkDefinitions;
    FEmitters : TEmitterData;
  public
    property Cells    : TCells           read FCells;
    property Perks    : TPerkDefinitions read FPerks;
    property Emitters : TEmitterData     read FEmitters;
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

class procedure TGameData.UnregisterLuaAPI( aLua : TLua );
begin
  // Definitions are freed before Lua; god mode also keeps the interpreter alive.
  // Revoke its borrowed pointer so retained callbacks cannot access freed data.
  lua_pushlightuserdata( aLua.Raw, @GameDataKey );
  lua_pushnil( aLua.Raw );
  lua_rawset( aLua.Raw, LUA_REGISTRYINDEX );
end;

end.
