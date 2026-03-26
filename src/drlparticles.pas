{$INCLUDE drl.inc}
unit drlparticles;
interface
uses Classes, SysUtils, vvector, vnode, vcolor, vutil, vrltools, vparticleengine, vlualibrary;

type
  TEmitterBinding = record
    NID       : Word;
    UID       : TUID;
    PoolIndex : Integer;
  end;

{ TParticleStore }

  TParticleStore = class( TVObject )
    constructor Create;
    procedure Initialize( aEngine : TParticleEngine );
    procedure Update( aDeltaSec : Single );
    procedure Clear;
    procedure ClearParticles;
    destructor Destroy; override;

    // Template-based API
    function  AddEmitter( aNID : Word; aUID : TUID; aWorldPos : TVec3f ) : Boolean;
    function  RemoveEmitter( aNID : Word; aUID : TUID ) : Boolean;
    function  Kill( aUID : TUID ) : Boolean;
    function  Wipe( aUID : TUID ) : Boolean;

    // Direct emitter API (no binding, caller manages lifetime)
    function  AddEmitterDirect( aNID : Word; aWorldPos : TVec3f ) : Integer;

    // Save/Load
    procedure WriteToStream( aStream : TStream );
    procedure ReadFromStream( aStream : TStream );

    // Data registration (called from Lua during module load)
    procedure RegisterEmitter( aNID : Word );

  private
    FEngine         : TParticleEngine;
    FEmitterData    : array of TParticleEmitterData;
    FBindings       : array of TEmitterBinding;
    FBindingCount   : Integer;

    function  GetEmitterData( aNID : Word ) : PParticleEmitterData;
    function  FindBinding( aNID : Word; aUID : TUID ) : Integer;
    procedure RemoveBinding( aIndex : Integer );
    procedure UpdateBoundEmitters;
  public
    property Engine : TParticleEngine read FEngine;
  end;

implementation

uses Math, vluasystem, vluatable, vluaentitynode, vuid,
     dfdata, dfthing, dflevel, drldecals, drlbase, drlspritemap;

function FlagsToParticleFlags( const aFlags : TFlags ) : TParticleFlags;
var i : Byte;
begin
  Result := [];
  for i in aFlags do
    if i <= Ord( High( TParticleFlag ) ) then
      Include( Result, TParticleFlag( i ) );
end;

procedure DecalCallback( const aPosition : TVec3f; aDecalSprite : DWord );
var iPos : TVec2i;
begin
  iPos.X := Round( aPosition.X );
  iPos.Y := Round( aPosition.Y );
  if ( SpriteMap <> nil ) and ( DRL <> nil ) then
    DRL.Level.Decals.Add( iPos, aDecalSprite );
end;

{ TParticleStore }

constructor TParticleStore.Create;
begin
  inherited Create;
  FEngine := nil;
  FBindingCount := 0;
end;

procedure TParticleStore.Initialize( aEngine : TParticleEngine );
begin
  FEngine := aEngine;
  if FEngine <> nil then
    FEngine.DecalCallback := @DecalCallback;
end;

procedure TParticleStore.Update( aDeltaSec : Single );
begin
  if FEngine = nil then Exit;
  UpdateBoundEmitters;
  FEngine.Update( aDeltaSec );
end;

procedure TParticleStore.Clear;
begin
  if FEngine <> nil then
    FEngine.Clear;
  FBindingCount := 0;
end;

procedure TParticleStore.ClearParticles;
begin
  if FEngine <> nil then
    FEngine.ClearParticles;
end;

destructor TParticleStore.Destroy;
begin
  FEngine := nil;
  inherited Destroy;
end;

// Emitter data loading

procedure TParticleStore.RegisterEmitter( aNID : Word );
var iTable  : TLuaTable;
    iShape  : AnsiString;
    iE      : PParticleEmitterData;
    iWhite  : TColorRange;
begin
  if aNID = 0 then Exit;
  if aNID >= Length( FEmitterData ) then
    SetLength( FEmitterData, aNID + 1 );
  iTable := LuaSystem.GetTable( ['emitters', Integer(aNID)] );
  try
    iE := @FEmitterData[aNID];
    FillChar( iE^, SizeOf( TParticleEmitterData ), 0 );

    // Shape
    iShape := iTable.GetString( 'shape', 'point' );
    if iShape = 'sphere' then iE^.Shape := ES_SPHERE
    else if iShape = 'base_ring' then iE^.Shape := ES_BASE_RING
    else if iShape = 'base_ellipse' then iE^.Shape := ES_BASE_ELLIPSE
    else iE^.Shape := ES_POINT;

    if not iTable.IsNil( 'shape_params' ) then
      iE^.ShapeParams := iTable.GetVec3f( 'shape_params' );

    if not iTable.IsNil( 'offset' ) then
      iE^.PositionOffset := iTable.GetVec3f( 'offset' );

    // Direction
    if not iTable.IsNil( 'direction' ) then
      iE^.Direction := iTable.GetVec3f( 'direction' )
    else
      iE^.Direction := Vec3f( 0, -1, 0 );

    iE^.SpreadAngle := iTable.GetFloat( 'spread_angle', 0 );

    // Ranges
    iE^.SpeedRange    := iTable.GetFloatRange( 'speed', NewFloatRange( 0, 0 ) );
    iE^.LifetimeRange := iTable.GetFloatRange( 'lifetime', NewFloatRange( 1, 1 ) );
    iE^.ScaleRange    := iTable.GetFloatRange( 'scale', NewFloatRange( 1, 1 ) );
    iE^.RotationRange := iTable.GetFloatRange( 'rotation', NewFloatRange( 0, 0 ) );
    iE^.RotSpeedRange := iTable.GetFloatRange( 'rot_speed', NewFloatRange( 0, 0 ) );
    iE^.AccelRange    := iTable.GetVec3fRange( 'accel',
      NewVec3fRange( Vec3f( 0, 0, 0 ), Vec3f( 0, 0, 0 ) ) );

    // Color ranges
    iWhite := NewColorRange( NewColor( 255, 255, 255 ), NewColor( 255, 255, 255 ) );
    iE^.ColorStartRange := iTable.GetColorRange( 'color_start', iWhite );
    iE^.ColorEndRange   := iTable.GetColorRange( 'color_end', iE^.ColorStartRange );

    // Sprite
    iE^.SpriteID := DWord( iTable.GetInteger( 'sprite', 0 ) );
    iE^.SubID := Byte( iTable.GetInteger( 'sub_id', 0 ) );
    iE^.AnimFrames := Byte( iTable.GetInteger( 'anim_frames', 1 ) );
    iE^.AnimFrameTime := iTable.GetFloat( 'anim_frame_time', 0.25 );
    iE^.DecalSprite := DWord( iTable.GetInteger( 'decal_sprite', 0 ) );

    // Particle flags
    iE^.ParticleFlags := FlagsToParticleFlags( iTable.GetFlags( 'flags', [] ) );

    // Emission parameters
    iE^.Rate := iTable.GetFloat( 'rate', 0 );
    iE^.BurstCount := Word( iTable.GetInteger( 'burst_count', 0 ) );
    iE^.Duration := iTable.GetFloat( 'duration', 0 );
    iE^.MaxParticles := Word( iTable.GetInteger( 'max_particles', 50 ) );

    // Emitter flags
    if iTable.GetBoolean( 'looping', False ) then
      Include( iE^.Flags, EF_LOOPING );
    if iTable.GetBoolean( 'attached', False ) then
      Include( iE^.Flags, EF_ATTACHED );

  finally
    iTable.Free;
  end;
end;

function TParticleStore.GetEmitterData( aNID : Word ) : PParticleEmitterData;
begin
  if ( aNID = 0 ) or ( aNID >= Length( FEmitterData ) ) then
    Exit( nil );
  Result := @FEmitterData[aNID];
end;

// Binding management

function TParticleStore.FindBinding( aNID : Word; aUID : TUID ) : Integer;
var i : Integer;
begin
  for i := 0 to FBindingCount - 1 do
    if ( FBindings[i].NID = aNID ) and ( FBindings[i].UID = aUID ) then
      Exit( i );
  Result := -1;
end;

procedure TParticleStore.RemoveBinding( aIndex : Integer );
begin
  Dec( FBindingCount );
  if aIndex < FBindingCount then
    FBindings[aIndex] := FBindings[FBindingCount];
end;

// Template-based API

function TParticleStore.AddEmitter( aNID : Word; aUID : TUID; aWorldPos : TVec3f ) : Boolean;
var iData : PParticleEmitterData;
begin
  Result := False;
  if aNID = 0 then Exit;
  if FindBinding( aNID, aUID ) >= 0 then Exit( True );
  if FBindingCount >= Length( FBindings ) then
    SetLength( FBindings, FBindingCount + 16 );
  FBindings[FBindingCount].NID := aNID;
  FBindings[FBindingCount].UID := aUID;
  if FEngine <> nil then
  begin
    iData := GetEmitterData( aNID );
    if iData <> nil then
      FBindings[FBindingCount].PoolIndex := FEngine.EmitStart( iData, aWorldPos )
    else
      FBindings[FBindingCount].PoolIndex := -1;
  end
  else
    FBindings[FBindingCount].PoolIndex := -1;
  Inc( FBindingCount );
  Result := True;
end;

function TParticleStore.AddEmitterDirect( aNID : Word; aWorldPos : TVec3f ) : Integer;
var iData : PParticleEmitterData;
begin
  Result := -1;
  if ( aNID = 0 ) or ( FEngine = nil ) then Exit;
  iData := GetEmitterData( aNID );
  if iData = nil then Exit;
  Result := FEngine.EmitStart( iData, aWorldPos );
end;

function TParticleStore.RemoveEmitter( aNID : Word; aUID : TUID ) : Boolean;
var iIdx : Integer;
begin
  Result := False;
  iIdx := FindBinding( aNID, aUID );
  if iIdx < 0 then Exit;
  if ( FEngine <> nil ) and ( FBindings[iIdx].PoolIndex >= 0 ) then
    FEngine.EmitStop( FBindings[iIdx].PoolIndex );
  RemoveBinding( iIdx );
  Result := True;
end;

function TParticleStore.Kill( aUID : TUID ) : Boolean;
var i : Integer;
begin
  Result := False;
  for i := FBindingCount - 1 downto 0 do
    if FBindings[i].UID = aUID then
    begin
      if ( FEngine <> nil ) and ( FBindings[i].PoolIndex >= 0 ) then
        FEngine.EmitStop( FBindings[i].PoolIndex );
      RemoveBinding( i );
      Result := True;
    end;
end;

function TParticleStore.Wipe( aUID : TUID ) : Boolean;
var i : Integer;
begin
  Result := False;
  for i := FBindingCount - 1 downto 0 do
    if FBindings[i].UID = aUID then
    begin
      if ( FEngine <> nil ) and ( FBindings[i].PoolIndex >= 0 ) then
        FEngine.EmitKill( FBindings[i].PoolIndex );
      RemoveBinding( i );
      Result := True;
    end;
end;

procedure TParticleStore.UpdateBoundEmitters;
var i      : Integer;
    iNode  : TNode;
    iDraw  : TVec2i;
begin
  if FEngine = nil then Exit;
  for i := FBindingCount - 1 downto 0 do
  begin
    // Check if emitter slot was auto-freed (burst/duration expired)
    if ( FBindings[i].PoolIndex >= 0 ) and ( not FEngine.IsEmitterUsed( FBindings[i].PoolIndex ) ) then
    begin
      RemoveBinding( i );
      Continue;
    end;
    iNode := UIDs.Get( FBindings[i].UID );
    if iNode = nil then
    begin
      if FBindings[i].PoolIndex >= 0 then
        FEngine.EmitStop( FBindings[i].PoolIndex );
      RemoveBinding( i );
    end
    else if ( iNode is TThing ) and ( FBindings[i].PoolIndex >= 0 ) then
    begin
      iDraw  := TThing( iNode ).GetDrawPosition;
      FEngine.EmitSetPosition( FBindings[i].PoolIndex,
        Vec3f( iDraw.X / SpriteMap.Engine.Scale + 16.0, iDraw.Y / SpriteMap.Engine.Scale + 16.0, 0 ) );
    end;
  end;
end;

// Save/Load

procedure TParticleStore.WriteToStream( aStream : TStream );
begin
  aStream.WriteWord( FBindingCount );
  if FBindingCount > 0 then
    aStream.Write( FBindings[0], FBindingCount * SizeOf( TEmitterBinding ) );
end;

procedure TParticleStore.ReadFromStream( aStream : TStream );
var iCount : Word;
    i      : Integer;
begin
  iCount := aStream.ReadWord;
  if iCount = 0 then Exit;
  if iCount > Length( FBindings ) then
    SetLength( FBindings, iCount );
  aStream.Read( FBindings[0], iCount * SizeOf( TEmitterBinding ) );
  FBindingCount := iCount;
  // Re-create emitters for loaded bindings
  if FEngine <> nil then
    for i := 0 to FBindingCount - 1 do
      if FBindings[i].NID > 0 then
        FBindings[i].PoolIndex := FEngine.EmitStart( GetEmitterData( FBindings[i].NID ), Vec3f( 0, 0, 0 ) );
end;



end.
