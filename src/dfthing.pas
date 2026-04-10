{$INCLUDE drl.inc}
{
----------------------------------------------------
DFTHING.PAS -- Basic Thing object for DRL
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfthing;
interface
uses SysUtils, Classes, vluaentitynode, vutil, vrltools, vluatable,
     vvector, dfdata, drlhooks, drlperk;

type String16 = string[16];

{ TThing }
type TThing = class( TLuaEntityNode )
  constructor Create( const aID : AnsiString );
  constructor CreateFromStream( aStream : TStream ); override;
  function PlaySound( const aSoundID : string; aDelay : Integer = 0 ) : Boolean;
  function PlaySound( const aSoundID : string; aPosition : TCoord2D; aDelay : Integer = 0 ) : Boolean;
  function HasHook( aHook : Word ) : Boolean; override;
  function CallHook( aHook : Byte; const aParams : array of Const ) : Boolean; virtual;
  function CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean; virtual;
  function CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean; virtual;
  function GetBonus( aHook : Byte; const aParams : array of Const ) : Integer; virtual;
  function GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single; virtual;
  function GetSprite : TSprite; virtual;
  function GetDrawPosition : TVec2i;
  function GetPerkList : TPerkList;
  function GetTraitString( aInvMode : Boolean = False ) : AnsiString;
  procedure Tick; virtual;
  procedure WriteToStream( aStream : TStream ); override;
  destructor Destroy; override;
  class procedure RegisterLuaAPI();
protected
  procedure LuaLoad( aTable : TLuaTable ); virtual;
protected
  FHP           : Integer;
  FArmor        : Integer;
  FSprite       : TSprite;
  FMelSprite    : TSprite;
  FSoundID      : String16;
  FAnimCount    : Word;
  FDrawPosition : TVec2i;
  FPerks        : TPerks;
  {$TYPEINFO ON}
public
  property SoundID      : String16 read FSoundID          write FSoundID;
  property Sprite       : TSprite  read GetSprite         write FSprite;
  property MelSprite    : TSprite  read FMelSprite        write FMelSprite;
  property AnimCount    : Word     read FAnimCount        write FAnimCount;
  property DrawPosition : TVec2i   read FDrawPosition     write FDrawPosition;
published
  property SpriteID   : DWord    read FSprite.SpriteID[0] write FSprite.SpriteID[0];
  property HP         : Integer  read FHP                 write FHP;
  property Armor      : Integer  read FArmor              write FArmor;
end;

implementation

uses typinfo, variants,
     vluasystem, vdebug, vtig,
     drlbase, drlio, drlua, drlspritemap;

constructor TThing.Create( const aID : AnsiString );
begin
  inherited Create( aID );
  FAnimCount    := 0;
  FDrawPosition := Vec2i( 0, 0 );
  FPerks        := nil;
end;

procedure TThing.LuaLoad( aTable : TLuaTable );
var iColorID : AnsiString;
begin
  FAnimCount   := 0;
  FPerks       := nil;
  FGylph.ASCII := aTable.getChar('ascii');
  FGylph.Color := aTable.getInteger('color');
  FSoundID     := aTable.getString('sound_id','');
  Name         := aTable.getString('name');
  FHP          := aTable.getInteger('hp',0);
  FArmor       := aTable.getInteger('armor',0);

  FillChar( FSprite, SizeOf( FSprite ), 0 );
  ReadSprite( aTable, FSprite );
  FillChar( FMelSprite, SizeOf( FMelSprite ), 0 );
  ReadSprite( aTable, 'melsprite', FMelSprite );

  iColorID := FID;
  if aTable.IsString('color_id') then iColorID := aTable.getString('color_id');

  if ColorOverrides.Exists(iColorID) then
    FGylph.Color := ColorOverrides[iColorID];

  FHooks += LoadCallbacks( aTable );
end;

function TThing.PlaySound( const aSoundID : string; aDelay : Integer = 0 ) : Boolean;
begin
  Exit( PlaySound( aSoundID, FPosition, aDelay ) );
end;

function TThing.PlaySound( const aSoundID : string; aPosition : TCoord2D; aDelay : Integer = 0 ) : Boolean;
var iSoundID : Word;
begin
  if FSoundID = ''
    then iSoundID := IO.Audio.ResolveSoundID( [ FID+'.'+aSoundID, aSoundID ] )
    else iSoundID := IO.Audio.ResolveSoundID( [ FID+'.'+aSoundID, FSoundID+'.'+aSoundID, aSoundID ] );

  if iSoundID = 0 then Exit( False );
  IO.Audio.PlaySound( iSoundID, aPosition, aDelay );
  Exit( True );
end;

function TThing.HasHook( aHook : Word ) : Boolean;
begin
  if inherited HasHook( aHook ) then Exit( True );
  if ( FPerks <> nil ) and ( aHook in FPerks.Hooks ) then Exit( True );
  Exit( False );
end;

function TThing.CallHook ( aHook : Byte; const aParams : array of const ) : Boolean;
var iState : TDRLState;
begin
  CallHook := False;
  if aHook in FHooks         then begin CallHook := True; iState := DRL.State; LuaSystem.ProtectedRunHook(Self, Lua.HookName(aHook), aParams ); if DRL.State <> iState then Exit; end;
  if FPerks <> nil then if FPerks.CallHook( aHook, aParams ) then CallHook := True;
  if aHook in ChainedHooks   then begin CallHook := True; DRL.Level.CallHook( aHook, ConcatConstArray( [ Self ], aParams ) ); end;
end;

function TThing.CallHookCheck ( aHook : Byte; const aParams : array of const ) : Boolean;
begin
  if aHook in ChainedHooks then if not DRL.Level.CallHookCheck( aHook, ConcatConstArray( [ Self ], aParams ) ) then Exit( False );
  if aHook in FHooks then if not LuaSystem.ProtectedRunHook(Self, HookNames[aHook], aParams ) then Exit( False );
  if FPerks <> nil then if not FPerks.CallHookCheck( aHook, aParams ) then Exit( False );
  Exit( True );
end;

function TThing.CallHookCan ( aHook : Byte; const aParams : array of const ) : Boolean;
begin
  if aHook in FHooks then if LuaSystem.ProtectedRunHook(Self, HookNames[aHook], aParams ) then Exit( True );
  if FPerks <> nil   then if FPerks.CallHookCan( aHook, aParams ) then Exit( True );
  Exit( False );
end;

function TThing.GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
begin
  GetBonus := 0;
  if FPerks <> nil then GetBonus += FPerks.GetBonus( aHook, aParams );
end;

function TThing.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
begin
  GetBonusMul := 1.0;
  if FPerks <> nil then GetBonusMul := FPerks.GetBonusMul( aHook, aParams );
end;

function TThing.GetSprite: TSprite;
begin
  Exit(FSprite);
end;

function TThing.GetDrawPosition : TVec2i;
var iSize : Word;
begin
  if ( FDrawPosition.X <> 0 ) or ( FDrawPosition.Y <> 0 ) then
    Exit( FDrawPosition );
  iSize := SpriteMap.GetGridSize;
  Result.Init( ( FPosition.X - 1 ) * iSize, ( FPosition.Y - 1 ) * iSize );
end;

function TThing.GetPerkList : TPerkList;
begin
  if FPerks = nil then Exit( nil );
  Exit( FPerks.List );
end;

function TThing.GetTraitString( aInvMode : Boolean = False ) : AnsiString;
var iPerks : TPerkList;
    i      : Integer;
    iColor : Byte;
    iText  : AnsiString;
begin
  Result := '';
  iPerks := GetPerkList;
  if ( iPerks = nil ) or ( iPerks.Size = 0 ) then Exit;
  for i := 0 to iPerks.Size - 1 do
    with PerkData[ iPerks[i].ID ] do
    begin
      if aInvMode then iText := Name else iText := Short;
      if iText = '' then Continue;
      if ( iPerks[i].Time > 0 ) and ( iPerks[i].Time <= 50 )
        then iColor := ColorExp
        else iColor := Color;
      Result += '{' + VTIG_ColorChar( iColor ) + iText + '}';
      if aInvMode then Result += ', ' else Result += ' ';
    end;
  if Result <> '' then
    if aInvMode
      then SetLength( Result, Length(Result) - 2 )
      else SetLength( Result, Length(Result) - 1 );
end;

procedure TThing.Tick;
begin
  if FPerks <> nil then
    FPerks.OnTick;
end;

procedure TThing.WriteToStream( aStream : TStream );
begin
  inherited WriteToStream( aStream );
  aStream.Write( FSprite,  SizeOf( FSprite ) );
  aStream.Write( FSoundID, SizeOf( FSoundID ) );
  aStream.Write( FHP,      SizeOf( FHP ) );
  aStream.Write( FArmor,   SizeOf( FArmor ) );

  if FPerks <> nil then
  begin
    aStream.WriteByte( 1 );
    FPerks.WriteToStream( aStream );
  end
  else
    aStream.WriteByte( 0 );
end;

constructor TThing.CreateFromStream( aStream: TStream );
begin
  inherited CreateFromStream( aStream );
  aStream.Read( FSprite,  SizeOf( FSprite ) );
  aStream.Read( FSoundID, SizeOf( FSoundID ) );
  aStream.Read( FHP,      SizeOf( FHP ) );
  aStream.Read( FArmor,   SizeOf( FArmor ) );

  FPerks := nil;
  if aStream.ReadByte > 0 then
    FPerks := TPerks.CreateFromStream( aStream, Self );
  FAnimCount := 0;
end;

destructor TThing.Destroy;
begin
  DRL.Particles.Wipe( UID );
  FreeAndNil( FPerks );
  inherited Destroy;
end;

function lua_thing_add_perk(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  if iThing = nil then Exit( 0 );
  if iThing.FPerks = nil then iThing.FPerks := TPerks.Create( iThing );
  iThing.FPerks.Add( iState.ToId(2), iState.ToInteger(3,-1) );
  Result := 0;
end;

function lua_thing_get_perk_time(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  if iThing.FPerks <> nil
    then iState.Push( iThing.FPerks.getTime( iState.ToId(2) ) )
    else iState.Push( 0 );
  Result := 1;
end;

function lua_thing_remove_perk(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  if iThing.FPerks <> nil 
    then iState.Push( iThing.FPerks.Remove( iState.ToId(2), iState.ToBoolean( 3, False ) ) )
    else iState.Push( False );
  Result := 1;
end;

function lua_thing_is_perk(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  iState.Push( ( iThing.FPerks <> nil ) and ( iThing.FPerks.IsActive( iState.ToId( 2 ) ) ) );
  Result := 1;
end;

function lua_thing_play_sound(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  if iState.IsCoord(3)
    then iThing.PlaySound( iState.ToString(2), iState.ToPosition(3), iState.ToInteger(4,0) )
    else iThing.PlaySound( iState.ToString(2), iState.ToInteger(3,0) );
  Result := 0;
end;

function lua_thing_add_emitter(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  iState.Push( DRL.Particles.AddEmitter( iState.ToId(2), iThing.UID,
    Vec3f( ( iThing.Position.X - 1 ) * 32 + 16, ( iThing.Position.Y - 1 ) * 32 + 16, 0 ) ) );
  Result := 1;
end;

function lua_thing_remove_emitter(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iThing : TThing;
begin
  iState.Init(L);
  iThing := iState.ToObject(1) as TThing;
  iState.Push( DRL.Particles.RemoveEmitter( iState.ToId(2), iThing.UID ) );
  Result := 1;
end;

const lua_thing_lib : array[0..7] of luaL_Reg = (
  ( name : 'add_perk';        func : @lua_thing_add_perk),
  ( name : 'get_perk_time';   func : @lua_thing_get_perk_time),
  ( name : 'remove_perk';     func : @lua_thing_remove_perk),
  ( name : 'is_perk';         func : @lua_thing_is_perk),
  ( name : 'play_sound';      func : @lua_thing_play_sound),
  ( name : 'add_emitter';     func : @lua_thing_add_emitter),
  ( name : 'remove_emitter';  func : @lua_thing_remove_emitter),
  ( name : nil;               func : nil; )
);

class procedure TThing.RegisterLuaAPI();
begin
  LuaSystem.Register( 'thing', lua_thing_lib );
end;

end.
