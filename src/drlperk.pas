{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2025-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlperk;
interface
uses classes,
     vutil, vnode, vgenerics, vlua,
     dfdata;

type TPerkData = record
  Name       : Ansistring;
  LabelText  : Ansistring;
  Desc       : Ansistring;
  Hooks      : TFlags;
  Color      : Byte;
  ColorExp   : Byte;
  StatusEff  : TStatusEffect;
  StatusStr  : DWord;
end;

type TPerkDataArray = array of TPerkData;

type TPerkDefinitions = class
  public
    procedure RegisterPerk( aLua : TLua; aID : Integer );
  private
    FData : TPerkDataArray;
  public
    property Data : TPerkDataArray read FData;
end;

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
  constructor Create( aOwner : TNode; aDefinitions : TPerkDefinitions );
  constructor CreateFromStream( aStream : TStream; aOwner : TNode; aDefinitions : TPerkDefinitions ); reintroduce;
  procedure WriteToStream( aStream : TStream ); override;
  function  CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
  function  CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
  function  CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
  function  GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
  function  GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
  function  GetLabel( aID : Integer ) : AnsiString;
  function  GetDescription( aID : Integer ) : AnsiString;
  procedure Add( aPerk : Integer; aDuration : LongInt = -1 );
  function  Remove( aPerk : Integer; aSilent : Boolean = False ) : Boolean;
  procedure OnTick;
  function  IsActive( aPerk : Integer ) : Boolean;
  function  getTime( aPerk : Integer ) : Integer;
  procedure Clear;
  destructor Destroy; override;
private
  FOwner           : TNode;
  FDefinitions     : TPerkDefinitions;
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
  property Definitions : TPerkDefinitions read FDefinitions;
  property List  : TPerkList read FList;
  property Hooks : TFlags    read FHooks;
end;


implementation

uses sysutils, math,
     vuid,
     drlhooks, drllua, dfplayer;

procedure TPerkDefinitions.RegisterPerk( aLua : TLua; aID : Integer );
begin
  if aID >= Length( FData ) then
    SetLength( FData, Max( aID + 1, Max( Length( FData ) * 2, 100 ) ) );
  with FData[aID] do
  begin
    with aLua.GetTable(['perks',aID]) do
    try
      Name      := getString('name','');
      LabelText := getString('label','');
      Desc      := getString('desc','');
      Color     := getInteger('color',0);
      ColorExp  := getInteger('color_expire',0);
      StatusEff := TStatusEffect( getInteger('status_effect',0) );
      StatusStr := getInteger('status_strength',0);
    finally
      Free;
    end;
    Hooks := LoadHooks( aLua, ['perks',aID] );
  end;
end;

constructor TPerks.Create( aOwner : TNode; aDefinitions : TPerkDefinitions );
begin
  inherited Create;
  FOwner := aOwner;
  FDefinitions := aDefinitions;
  FHooks := [];
  FList  := TPerkList.Create;
  FIterDepth := 0;
end;

constructor TPerks.CreateFromStream( aStream : TStream; aOwner : TNode; aDefinitions : TPerkDefinitions );
begin
  inherited CreateFromStream( aStream );
  FOwner := aOwner;
  FDefinitions := aDefinitions;
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
var iUIDs : TUIDStore;
    i     : Integer;
    iUID  : TUID;
begin
  CallHook := False;
  if aHook in FHooks then
  begin
    iUIDs := FOwner.Context.UIDs;
    iUID  := FOwner.UID;
    BeginIteration;
    for i := 0 to FList.Size-1 do
      if aHook in FDefinitions.Data[FList[i].ID].Hooks then
        begin
          CallHook := True;
          FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, TDRLLua( FOwner.Context.Lua ).HookName(aHook) ], ConcatConstArray( [FOwner], aParams ) );
          // A callback may consume the owner and free this perk list.
          // Session-owned levels created before the UID store have UID 0.
          if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
        end;
    EndIteration;
  end;
end;

function TPerks.CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
var iUIDs : TUIDStore;
    i     : Integer;
    iUID  : TUID;
begin
  Result := True;
  if aHook in FHooks then
  begin
    iUIDs := FOwner.Context.UIDs;
    iUID  := FOwner.UID;
    BeginIteration;
    for i := 0 to FList.Size-1 do
      if aHook in FDefinitions.Data[FList[i].ID].Hooks then
      begin
        Result := FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[aHook] ], ConcatConstArray( [FOwner], aParams ) );
        // A check may destroy its owner; stop before touching the freed list.
        if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit( False );
        if not Result then Break;
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
      if aHook in FDefinitions.Data[FList[i].ID].Hooks then
        if FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) ) then
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
      if aHook in FDefinitions.Data[FList[i].ID].Hooks then
        GetBonus += FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
end;

function  TPerks.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
var i : Integer;
begin
  GetBonusMul := 1.0;
  if aHook in FHooks then
    for i := 0 to FList.Size-1 do
      if aHook in FDefinitions.Data[FList[i].ID].Hooks then
        GetBonusMul *= FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
end;

function TPerks.GetDescription( aID : Integer ) : AnsiString;
begin
  if Hook_getDescription in FDefinitions.Data[aID].Hooks then
    Exit( FOwner.Context.Lua.ProtectedCall( [ 'perks', aID, HookNames[Hook_getDescription] ], [ FOwner ] ) );
  Exit( FDefinitions.Data[aID].Desc );
end;

function TPerks.GetLabel( aID : Integer ) : AnsiString;
begin
  if Hook_getLabel in FDefinitions.Data[aID].Hooks then
    Exit( FOwner.Context.Lua.ProtectedCall( [ 'perks', aID, HookNames[Hook_getLabel] ], [ FOwner ] ) );
  Exit( FDefinitions.Data[aID].LabelText );
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
  if Hook_OnAdd in FDefinitions.Data[aPerk].Hooks then
    FOwner.Context.Lua.ProtectedCall( [ 'perks', aPerk, 'OnAdd' ], [FOwner] );
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
var iUIDs  : TUIDStore;
    i      : Integer;
    iUID   : TUID;
    iTime  : LongInt;
begin
  if FList.Size = 0 then Exit;
  iUIDs := FOwner.Context.UIDs;
  iUID  := FOwner.UID;
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
          if Hook_OnTick10 in FDefinitions.Data[ID].Hooks then
          begin
            FOwner.Context.Lua.ProtectedCall( [ 'perks', ID, 'OnTick10' ], [ FOwner, iTime div 10 ] );
            // Perk owners include levels and items nested in inventories.
            if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
          end;
    end;
  EndIteration;
  // Flushing deferred removals can destroy the owner and this perk list.
  if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
  i := 0;
  while i < FList.Size do
    if FList[i].Time = 0
      then
      begin
        Expire( i, False );
        if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
      end
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
      FHooks += FDefinitions.Data[FList[i].ID].Hooks;
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
var iUIDs   : TUIDStore;
    i       : Integer;
    iIdx    : Integer;
    iPerk   : Integer;
    iSilent : Boolean;
    iUID    : TUID;
begin
  iUIDs := FOwner.Context.UIDs;
  iUID  := FOwner.UID;
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
    begin
      ExpireNow( iIdx, iSilent );
      if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
    end;
  end;
end;

procedure TPerks.ExpireNow( aIndex : Integer; aSilent : Boolean );
var iPerk : Integer;
begin
  iPerk := FList[ aIndex ].ID;
  FList.Delete( aIndex );
  UpdateHooks;
  if Hook_OnRemove in FDefinitions.Data[iPerk].Hooks then
    FOwner.Context.Lua.ProtectedCall( [ 'perks', iPerk, 'OnRemove' ], [FOwner, aSilent] );
end;

procedure TPerks.Expire( aIndex : Integer; aSilent : Boolean );
begin
  if FIterDepth > 0
    then ExpireQueue( FList[ aIndex ].ID, aSilent )
    else ExpireNow( aIndex, aSilent );
end;

procedure TPerks.Clear;
var iUIDs : TUIDStore;
    i     : Integer;
    iUID  : TUID;
begin
  iUIDs := FOwner.Context.UIDs;
  iUID  := FOwner.UID;
  if FList.Size > 0 then
  begin
    BeginIteration;
    for i := 0 to FList.Size - 1 do
      if Hook_OnRemove in FDefinitions.Data[FList[i].ID].Hooks then
      begin
        FOwner.Context.Lua.ProtectedCall( [ 'perks', FList[i].ID, 'OnRemove' ], [FOwner, True] );
        if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
      end;
    EndIteration;
    if ( iUID <> 0 ) and ( iUIDs.Get( iUID ) = nil ) then Exit;
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

