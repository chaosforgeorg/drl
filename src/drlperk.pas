{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2025-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlperk;
interface
uses classes, vutil, vnode, vgenerics, dfdata;

type TPerkData = record
  Name       : Ansistring;
  Desc       : Ansistring;
  Hooks      : TFlags;
  Color      : Byte;
  ColorExp   : Byte;
  StatusEff  : TStatusEffect;
  StatusStr  : DWord;
end;

var PerkData    : array of TPerkData;
    PerkDataMax : Integer = 0;

type TPerk = record
  ID    : Integer;
  Time  : Integer;
end;

type TPerkList = specialize TGArray< TPerk >;

type TPerks = class( TVObject )
  constructor Create( aOwner : TNode );
  constructor CreateFromStream( aStream : TStream; aOwner : TNode ); reintroduce;
  procedure WriteToStream( aStream : TStream ); override;
  function  CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
  function  CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
  function  CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
  function  GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
  function  GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
  procedure Add( aPerk : Integer; aDuration : LongInt = -1 );
  function  Remove( aPerk : Integer; aSilent : Boolean = False ) : Boolean;
  procedure OnTick;
  function  IsActive( aPerk : Integer ) : Boolean;
  function  getTime( aPerk : Integer ) : Integer;
  destructor Destroy; override;
private
  FOwner : TNode;
  FHooks : TFlags;
  FList  : TPerkList;
  procedure UpdateHooks;
  procedure Expire( aIndex : Integer; aSilent : Boolean );
public
  property List : TPerkList read FList;
end;


implementation

uses sysutils, vluasystem, drlhooks;

constructor TPerks.Create( aOwner : TNode );
begin
  inherited Create;
  FOwner := aOwner;
  FHooks := [];
  FList  := TPerkList.Create;
end;

constructor TPerks.CreateFromStream( aStream : TStream; aOwner : TNode );
begin
  inherited CreateFromStream( aStream );
  FOwner := aOwner;
  FList  := TPerkList.CreateFromStream( aStream );
  UpdateHooks;
end;

procedure TPerks.WriteToStream( aStream : TStream );
begin
  inherited WriteToStream( aStream );
  FList.WriteToStream( aStream );
end;

function TPerks.CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  CallHook := False;
  if aHook in FHooks then
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
      begin
        CallHook := True;
        LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
      end;
end;

function  TPerks.CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  if aHook in FHooks then
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        if not LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) ) then
          Exit( False );
  Exit( True );
end;

function  TPerks.CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  if aHook in FHooks then
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        if LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) ) then
          Exit( True );
  Exit( False );
end;

function  TPerks.GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
var i : Integer;
begin
  GetBonus := 0;
  if aHook in FHooks then
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        GetBonus += LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
end;

function  TPerks.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
var i : Integer;
begin
  GetBonusMul := 1.0;
  if aHook in FHooks then
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        GetBonusMul *= LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
end;

procedure TPerks.Add( aPerk : Integer; aDuration : LongInt );
var i     : Integer;
    iPerk : TPerk;
begin
  if aDuration = 0 then Exit;
  if FList.Size > 0 then
    for i := 0 to FList.Size - 1 do
      if FList[i].ID = aPerk then
      begin
        if aDuration > 0 then FList[i].Time += aDuration;
        Exit;
      end;
  iPerk.ID   := aPerk;
  iPerk.Time := aDuration;
  FList.Push( iPerk );
  UpdateHooks;
  if Hook_OnAdd in PerkData[aPerk].Hooks then
    LuaSystem.ProtectedCall( [ 'perks', aPerk, 'OnAdd' ], [FOwner] );
end;

function  TPerks.Remove( aPerk : Integer; aSilent : Boolean ) : Boolean;
var i : Integer;
begin
  if FList.Size > 0 then
    for i := 0 to FList.Size - 1 do
      if FList[i].ID = aPerk then
      begin
        Expire( i, aSilent );
        Exit( True );
      end;
  Exit( False );
end;

procedure TPerks.OnTick;
var i : Integer;
begin
  if FList.Size > 0 then
    for i := 0 to FList.Size - 1 do
      with FList[i] do
        if Time > 0 then
        begin
          Dec( FList.Data^[i].Time );
          if Hook_OnTick in FHooks then
            if Hook_OnTick in PerkData[ID].Hooks then
              LuaSystem.ProtectedCall( [ 'perks', ID, 'OnTick' ], [ FOwner, Time ] );
          if Hook_OnTick10 in FHooks then
            if Time mod 10 = 0 then
              if Hook_OnTick10 in PerkData[ID].Hooks then
                LuaSystem.ProtectedCall( [ 'perks', ID, 'OnTick10' ], [ FOwner, Time div 10 ] );
        end;
  i := 0;
  while i < FList.Size do
    if FList[i].Time = 0
      then Expire( i, False )
      else Inc(i);
end;

function  TPerks.IsActive( aPerk : Integer ) : Boolean;
var i : Integer;
begin
  if FList.Size > 0 then
    for i := 0 to FList.Size - 1 do
      if FList[i].ID = aPerk then
        Exit( True );
  Exit( False );
end;

function  TPerks.getTime( aPerk : Integer ) : LongInt;
var i : Integer;
begin
  if FList.Size > 0 then
    for i := 0 to FList.Size - 1 do
      if FList[i].ID = aPerk then
        Exit( FList[i].Time );
  Exit( 0 );
end;

procedure TPerks.UpdateHooks;
var i : Integer;
begin
  FHooks := [];
  if FList.Size > 0 then
    for i := 0 to FList.Size - 1 do
      FHooks += PerkData[FList[i].ID].Hooks;
end;

procedure TPerks.Expire( aIndex : Integer; aSilent : Boolean );
var iPerk : Integer;
begin
  iPerk := FList[ aIndex ].ID;
  FList.Delete( aIndex );
  UpdateHooks;
  if Hook_OnRemove in PerkData[iPerk].Hooks then
    LuaSystem.ProtectedCall( [ 'perks', iPerk, 'OnRemove' ], [FOwner, aSilent] );
end;

destructor TPerks.Destroy;
begin
  FreeAndNil( FList );
  inherited Destroy;
end;

end.

