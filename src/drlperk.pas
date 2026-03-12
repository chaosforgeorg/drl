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
  Short      : Ansistring;
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

type TPerkExpiring = record
  ID     : Integer;
  Silent : Boolean;
end;

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
  procedure Clear;
  destructor Destroy; override;
private
  FOwner           : TNode;
  FHooks           : TFlags;
  FList            : TPerkList;
  FIterDepth       : Integer;
  FExpireQueue     : array of TPerkExpiring;
  procedure BeginIteration;
  procedure EndIteration;
  procedure ExpireQueue( aPerk : Integer; aSilent : Boolean );
  procedure FlushQueue;
  procedure ExpireNow( aIndex : Integer; aSilent : Boolean );
  procedure UpdateHooks;
  procedure Expire( aIndex : Integer; aSilent : Boolean );
public
  property List  : TPerkList read FList;
  property Hooks : TFlags    read FHooks;
end;


implementation

uses sysutils, vluasystem, vuid, drlhooks, drlbase, dfplayer;

constructor TPerks.Create( aOwner : TNode );
begin
  inherited Create;
  FOwner := aOwner;
  FHooks := [];
  FList  := TPerkList.Create;
  FIterDepth := 0;
end;

constructor TPerks.CreateFromStream( aStream : TStream; aOwner : TNode );
begin
  inherited CreateFromStream( aStream );
  FOwner := aOwner;
  FList  := TPerkList.CreateFromStream( aStream );
  FIterDepth := 0;
  UpdateHooks;
end;

procedure TPerks.BeginIteration;
begin
  Inc( FIterDepth );
end;

procedure TPerks.EndIteration;
begin
  if FIterDepth = 0 then Exit;
  Dec( FIterDepth );
  if FIterDepth = 0 then
    FlushQueue;
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
  begin
    BeginIteration;
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        begin
          CallHook := True;
          LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, Lua.HookName(aHook) ], ConcatConstArray( [FOwner], aParams ) );
        end;
    EndIteration;
  end;
end;

function  TPerks.CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  Result := True;
  if aHook in FHooks then
  begin
    BeginIteration;
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        if not LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[aHook] ], ConcatConstArray( [FOwner], aParams ) ) then
        begin
          Result := False;
          Break;
        end;
    EndIteration;
  end;
end;

function  TPerks.CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  Result := False;
  if aHook in FHooks then
  begin
    BeginIteration;
    for i := 0 to FList.Size-1 do
      if aHook in PerkData[FList[i].ID].Hooks then
        if LuaSystem.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) ) then
        begin
          Result := True;
          Break;
        end;
    EndIteration;
  end;
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
        if FList.Data^[i].Time < 0 then Exit; // permanent
        if aDuration < 0
          then FList.Data^[i].Time := aDuration   // upgrade to permanent
          else FList.Data^[i].Time += aDuration;  // extend timed
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
var i      : Integer;
    iUID   : TUID;
    iTime  : LongInt;
begin
  if FList.Size = 0 then Exit;
  iUID := FOwner.UID;
  BeginIteration;
  for i := 0 to FList.Size - 1 do
    with FList[i] do
    begin
      if Time > 0 then
      begin
        Dec( FList.Data^[i].Time );
        iTime := Time;
      end
      else if Time < 0 then
        iTime := Player.Statistics.GameTime
      else
        Continue;
      if Hook_OnTick10 in FHooks then
        if iTime mod 10 = 0 then
          if Hook_OnTick10 in PerkData[ID].Hooks then
          begin
            LuaSystem.ProtectedCall( [ 'perks', ID, 'OnTick10' ], [ FOwner, iTime div 10 ] );
            if not DRL.Level.isAlive( iUID ) then Exit;
          end;
    end;
  EndIteration;
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

procedure TPerks.ExpireQueue( aPerk : Integer; aSilent : Boolean );
var i      : Integer;
    iCount : Integer;
begin
  for i := 0 to Length( FExpireQueue ) - 1 do
    if FExpireQueue[i].ID = aPerk then
    begin
      FExpireQueue[i].Silent := FExpireQueue[i].Silent and aSilent;
      Exit;
    end;

  iCount := Length( FExpireQueue );
  SetLength( FExpireQueue, iCount + 1 );
  FExpireQueue[iCount].ID := aPerk;
  FExpireQueue[iCount].Silent := aSilent;
end;

procedure TPerks.FlushQueue;
var i       : Integer;
    iIdx    : Integer;
    iPerk   : Integer;
    iSilent : Boolean;
begin
  while Length( FExpireQueue ) > 0 do
  begin
    iPerk   := FExpireQueue[0].ID;
    iSilent := FExpireQueue[0].Silent;

    for i := 1 to Length( FExpireQueue ) - 1 do
      FExpireQueue[i - 1] := FExpireQueue[i];
    SetLength( FExpireQueue, Length( FExpireQueue ) - 1 );

    iIdx := -1;
    for i := 0 to FList.Size - 1 do
      if FList[i].ID = iPerk then
      begin
        iIdx := i;
        Break;
      end;

    if iIdx >= 0 then
      ExpireNow( iIdx, iSilent );
  end;
end;

procedure TPerks.ExpireNow( aIndex : Integer; aSilent : Boolean );
var iPerk : Integer;
begin
  iPerk := FList[ aIndex ].ID;
  FList.Delete( aIndex );
  UpdateHooks;
  if Hook_OnRemove in PerkData[iPerk].Hooks then
    LuaSystem.ProtectedCall( [ 'perks', iPerk, 'OnRemove' ], [FOwner, aSilent] );
end;

procedure TPerks.Expire( aIndex : Integer; aSilent : Boolean );
begin
  if FIterDepth > 0
    then ExpireQueue( FList[ aIndex ].ID, aSilent )
    else ExpireNow( aIndex, aSilent );
end;

procedure TPerks.Clear;
var i : Integer;
begin
  if FList.Size > 0 then
  begin
    BeginIteration;
    for i := 0 to FList.Size - 1 do
      if Hook_OnRemove in PerkData[FList[i].ID].Hooks then
        LuaSystem.ProtectedCall( [ 'perks', FList[i].ID, 'OnRemove' ], [FOwner, True] );
    EndIteration;
    FList.Clear;
  end;
  FHooks := [];
end;

destructor TPerks.Destroy;
begin
  FreeAndNil( FList );
  inherited Destroy;
end;

end.

