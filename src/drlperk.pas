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

// Position of a running loop over the perk list; Expire keeps it valid.
type TPerkCursor = record
  Next : Integer;
  Last : Integer;
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
  procedure OnTick( aTime : LongInt );
  function  IsActive( aPerk : Integer ) : Boolean;
  function  getTime( aPerk : Integer ) : Integer;
  procedure Clear;
  destructor Destroy; override;
private
  FOwner           : TNode;
  FDefinitions     : TPerkDefinitions;
  FHooks           : TFlags;
  FList            : TPerkList;
  FCursors         : array of TPerkCursor;
  FCursorCount     : Integer;
  function  BeginIteration : Integer;
  procedure EndIteration;
  function  NextEntry( aCursor : Integer; out aIndex : Integer ) : Boolean; inline;
  procedure UpdateHooks;
  procedure Expire( aIndex : Integer; aSilent : Boolean );
public
  property Definitions : TPerkDefinitions read FDefinitions;
  property List  : TPerkList read FList;
  property Hooks : TFlags    read FHooks;
end;


implementation

uses sysutils, math,
     drlhooks, drllua, dfbeing;

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
  FCursorCount := 0;
end;

constructor TPerks.CreateFromStream( aStream : TStream; aOwner : TNode; aDefinitions : TPerkDefinitions );
begin
  inherited CreateFromStream( aStream );
  FOwner := aOwner;
  FDefinitions := aDefinitions;
  FList  := TPerkList.CreateFromStream( aStream );
  FCursorCount := 0;
  UpdateHooks;
end;

// Loops visit the entries present when they begin; Expire adjusts every
// active cursor, so callbacks may remove perks at any depth.
function TPerks.BeginIteration : Integer;
begin
  if FCursorCount = Length( FCursors ) then
    SetLength( FCursors, Max( 4, Length( FCursors ) * 2 ) );
  FCursors[FCursorCount].Next := 0;
  FCursors[FCursorCount].Last := FList.Size - 1;
  Result := FCursorCount;
  Inc( FCursorCount );
end;

procedure TPerks.EndIteration;
begin
  Dec( FCursorCount );
end;

function TPerks.NextEntry( aCursor : Integer; out aIndex : Integer ) : Boolean;
begin
  with FCursors[aCursor] do
  begin
    if Next > Last then Exit( False );
    aIndex := Next;
    Inc( Next );
  end;
  Exit( True );
end;

procedure TPerks.WriteToStream( aStream : TStream );
begin
  inherited WriteToStream( aStream );
  FList.WriteToStream( aStream );
end;

function TPerks.CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
var i       : Integer;
    iCursor : Integer;
    iTarget : TNode;
begin
  CallHook := False;
  if aHook in FHooks then
  begin
    iTarget := nil;
    if aHook = Hook_OnDamage then
      iTarget := TNode( aParams[0].VObject );
    iCursor := BeginIteration;
    try
      while NextEntry( iCursor, i ) do
        if aHook in FDefinitions.Data[FList[i].ID].Hooks then
        begin
          CallHook := True;
          FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, TDRLLua( FOwner.Context.Lua ).HookName(aHook) ], ConcatConstArray( [FOwner], aParams ) );
          // A callback may kill the owner, or the damaged target.
          if FOwner.Dead then Break;
          if ( iTarget <> nil ) and iTarget.Dead then Break;
        end;
    finally
      EndIteration;
    end;
  end;
end;

function TPerks.CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
var i       : Integer;
    iCursor : Integer;
begin
  Result := True;
  if aHook in FHooks then
  begin
    iCursor := BeginIteration;
    try
      while NextEntry( iCursor, i ) do
        if aHook in FDefinitions.Data[FList[i].ID].Hooks then
        begin
          Result := FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[aHook] ], ConcatConstArray( [FOwner], aParams ) );
          if FOwner.Dead then Result := False;
          if not Result then Break;
        end;
    finally
      EndIteration;
    end;
  end;
end;

function  TPerks.CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
var i       : Integer;
    iCursor : Integer;
begin
  Result := False;
  if aHook in FHooks then
  begin
    iCursor := BeginIteration;
    try
      while NextEntry( iCursor, i ) do
        if aHook in FDefinitions.Data[FList[i].ID].Hooks then
          if FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) ) then
          begin
            Result := True;
            Break;
          end;
    finally
      EndIteration;
    end;
  end;
end;

function  TPerks.GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
var i       : Integer;
    iCursor : Integer;
begin
  GetBonus := 0;
  if aHook in FHooks then
  begin
    iCursor := BeginIteration;
    try
      while NextEntry( iCursor, i ) do
        if aHook in FDefinitions.Data[FList[i].ID].Hooks then
          GetBonus += FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
    finally
      EndIteration;
    end;
  end;
end;

function  TPerks.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
var i       : Integer;
    iCursor : Integer;
begin
  GetBonusMul := 1.0;
  if aHook in FHooks then
  begin
    iCursor := BeginIteration;
    try
      while NextEntry( iCursor, i ) do
        if aHook in FDefinitions.Data[FList[i].ID].Hooks then
          GetBonusMul *= FOwner.Context.Lua.ProtectedCall( [ 'perks',FList[i].ID, HookNames[ aHook ] ], ConcatConstArray( [FOwner], aParams ) );
    finally
      EndIteration;
    end;
  end;
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

procedure TPerks.OnTick( aTime : LongInt );
var iBeing  : TBeing;
    i       : Integer;
    iCursor : Integer;
    iTime   : LongInt;
    iID     : Integer;

  function OwnerGone : Boolean;
  begin
    Exit( FOwner.Dead or ( ( iBeing <> nil ) and iBeing.Dying ) );
  end;

begin
  if FList.Size = 0 then Exit;
  iBeing := nil;
  if FOwner is TBeing then iBeing := TBeing( FOwner );
  if OwnerGone then Exit;
  iCursor := BeginIteration;
  try
    while NextEntry( iCursor, i ) do
    begin
      if FList[i].Time > 0 then
      begin
        Dec( FList.Data^[i].Time );
        iTime := FList[i].Time;
      end
      else if FList[i].Time < 0 then
        iTime := aTime
      else
        Continue;
      iID := FList[i].ID;
      if Hook_OnTick10 in FHooks then
        if iTime mod 10 = 0 then
          if Hook_OnTick10 in FDefinitions.Data[iID].Hooks then
          begin
            FOwner.Context.Lua.ProtectedCall( [ 'perks', iID, 'OnTick10' ], [ FOwner, iTime div 10 ] );
            if OwnerGone then Break;
          end;
    end;
  finally
    EndIteration;
  end;
  // A tick callback can kill the owner.
  if OwnerGone then Exit;
  iCursor := BeginIteration;
  try
    while NextEntry( iCursor, i ) do
      if FList[i].Time = 0 then
      begin
        Expire( i, False );
        if OwnerGone then Break;
      end;
  finally
    EndIteration;
  end;
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

// Removal takes effect at once, also during iteration: active cursors
// skip the deleted entry, and OnRemove runs after the perk is gone.
procedure TPerks.Expire( aIndex : Integer; aSilent : Boolean );
var i     : Integer;
    iPerk : Integer;
begin
  iPerk := FList[ aIndex ].ID;
  FList.Delete( aIndex );
  for i := 0 to FCursorCount - 1 do
    with FCursors[i] do
    begin
      if aIndex < Next then Dec( Next );
      if aIndex <= Last then Dec( Last );
    end;
  UpdateHooks;
  // A dead owner runs no further perk callbacks.
  if FOwner.Dead then Exit;
  if Hook_OnRemove in FDefinitions.Data[iPerk].Hooks then
    FOwner.Context.Lua.ProtectedCall( [ 'perks', iPerk, 'OnRemove' ], [FOwner, aSilent] );
end;

// Removes the perks present on entry; perks their OnRemove callbacks add
// are dropped without callbacks.
procedure TPerks.Clear;
var i       : Integer;
    iCursor : Integer;
begin
  if FList.Size > 0 then
  begin
    iCursor := BeginIteration;
    try
      while NextEntry( iCursor, i ) do
        Expire( i, True );
    finally
      EndIteration;
    end;
    FList.Clear;
    for i := 0 to FCursorCount - 1 do
    begin
      FCursors[i].Next := 0;
      FCursors[i].Last := -1;
    end;
  end;
  FHooks := [];
end;

destructor TPerks.Destroy;
begin
  FreeAndNil( FList );
  inherited Destroy;
end;

end.

