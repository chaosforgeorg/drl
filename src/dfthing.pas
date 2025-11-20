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
     dfdata, drlhooks, drlperk;

type String16 = string[16];

{ TThing }
type TThing = class( TLuaEntityNode )
  constructor Create( const aID : AnsiString );
  constructor CreateFromStream( Stream : TStream ); override;
  function PlaySound( const aSoundID : string; aDelay : Integer = 0 ) : Boolean;
  function PlaySound( const aSoundID : string; aPosition : TCoord2D; aDelay : Integer = 0 ) : Boolean;
  function CallHook( aHook : Byte; const aParams : array of Const ) : Boolean; virtual;
  function CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean; virtual;
  function CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean; virtual;
  function GetSprite : TSprite; virtual;
  procedure WriteToStream( Stream : TStream ); override;
protected
  procedure LuaLoad( Table : TLuaTable ); virtual;
protected
  FHP        : Integer;
  FArmor     : Integer;
  FSprite    : TSprite;
  FSoundID   : String16;
  FAnimCount : Word;
  {$TYPEINFO ON}
public
  property SoundID    : String16 read FSoundID          write FSoundID;
  property Sprite     : TSprite  read GetSprite         write FSprite;
  property AnimCount  : Word     read FAnimCount        write FAnimCount;
published
  property SpriteID   : DWord    read FSprite.SpriteID[0] write FSprite.SpriteID[0];
  property HP         : Integer  read FHP                 write FHP;
  property Armor      : Integer  read FArmor              write FArmor;
end;

implementation

uses typinfo, variants,
     vluasystem, vdebug,
     drlbase, drlio;

constructor TThing.Create( const aID : AnsiString );
begin
  inherited Create( aID );
  FAnimCount := 0;
end;

procedure TThing.LuaLoad(Table: TLuaTable);
var iColorID : AnsiString;
begin
  FAnimCount   := 0;
  FGylph.ASCII := Table.getChar('ascii');
  FGylph.Color := Table.getInteger('color');
  FSoundID     := Table.getString('sound_id','');
  Name         := Table.getString('name');
  FHP          := Table.getInteger('hp',0);
  FArmor       := Table.getInteger('armor',0);

  FillChar( FSprite, SizeOf( FSprite ), 0 );
  ReadSprite( Table, FSprite );

  iColorID := FID;
  if Table.IsString('color_id') then iColorID := Table.getString('color_id');

  if ColorOverrides.Exists(iColorID) then
    FGylph.Color := ColorOverrides[iColorID];
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

function TThing.CallHook ( aHook : Byte; const aParams : array of const ) : Boolean;
begin
  CallHook := False;
  if aHook in FHooks         then begin CallHook := True; LuaSystem.ProtectedRunHook(Self, HookNames[aHook], aParams ); end;
  if aHook in ChainedHooks   then begin CallHook := True; DRL.Level.CallHook( aHook, ConcatConstArray( [ Self ], aParams ) ); end;
end;

function TThing.CallHookCheck ( aHook : Byte; const aParams : array of const ) : Boolean;
begin
  if aHook in ChainedHooks then if not DRL.Level.CallHookCheck( aHook, ConcatConstArray( [ Self ], aParams ) ) then Exit( False );
  if aHook in FHooks then if not LuaSystem.ProtectedRunHook(Self, HookNames[aHook], aParams ) then Exit( False );
  Exit( True );
end;

function TThing.CallHookCan ( aHook : Byte; const aParams : array of const ) : Boolean;
begin
  if aHook in FHooks then if LuaSystem.ProtectedRunHook(Self, HookNames[aHook], aParams ) then Exit( True );
  Exit( False );
end;

function TThing.GetSprite: TSprite;
begin
  Exit(FSprite);
end;

procedure TThing.WriteToStream( Stream: TStream );
begin
  inherited WriteToStream( Stream );
  Stream.Write( FSprite,  SizeOf( FSprite ) );
  Stream.Write( FSoundID, SizeOf( FSoundID ) );
  Stream.Write( FHP,      SizeOf( FHP ) );
  Stream.Write( FArmor,   SizeOf( FArmor ) );
end;

constructor TThing.CreateFromStream( Stream: TStream );
begin
  inherited CreateFromStream( Stream );
  Stream.Read( FSprite,  SizeOf( FSprite ) );
  Stream.Read( FSoundID, SizeOf( FSoundID ) );
  Stream.Read( FHP,      SizeOf( FHP ) );
  Stream.Read( FArmor,   SizeOf( FArmor ) );

  FAnimCount := 0;
end;

end.
