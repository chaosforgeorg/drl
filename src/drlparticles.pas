{$INCLUDE drl.inc}
unit drlparticles;
interface
uses classes, sysutils,
     vlua, vvector, vobject, vcolor, vutil, vrltools, vparticleengine, vlualibrary, vuid;

type
  // Module data, borrowed by each level's particle store.
  TEmitterData = class( TVObject )
    procedure RegisterEmitter( aLua : TLua; aNID : Word );
    destructor Destroy; override;
    function GetEmitterData( aNID : Word ) : PParticleEmitterData;
  private
    // Individual allocations keep active emitter pointers stable as IDs are added.
    FEmitterData : array of PParticleEmitterData;
  end;

  TEmitterBinding = record
    NID       : Word;
    UID       : TUID;
    PoolIndex : Integer;
  end;

{ TParticleStore }

  TParticleStore = class( TVObject )
    constructor Create( aUIDs : TUIDStore );
    procedure BindUIDs( aUIDs : TUIDStore );
    procedure Initialize( aEmitters : TEmitterData; aEngine : TParticleEngine );
    procedure Update( aDeltaSec : Single );
    procedure Reset;
    // Clear floor effects, retaining bindings and emitter timing for surviving entities.
    procedure Clear;
    destructor Destroy; override;

    // Template-based API
    function  AddEmitter( aNID : Word; aUID : TUID; aWorldPos : TVec3f ) : Boolean;
    function  RemoveEmitter( aNID : Word; aUID : TUID ) : Boolean;
    function  Kill( aUID : TUID ) : Boolean;

    // Direct emitter API (no binding, caller manages lifetime)
    function  AddEmitterDirect( aNID : Word; aWorldPos : TVec3f ) : Integer;
    procedure SpawnBurst( aNID : Word; aWorldPos : TVec3f; aDirection : TVec2f;
      aCount : Word; const aDecalSprites : array of DWord; aDistanceScale, aArcScale : TFloatRange;
      aSpreadScale : Single );

    // Save/Load
    procedure WriteToStream( aStream : TStream );
    procedure ReadFromStream( aStream : TStream );

  private
    FUIDs           : TUIDStore;
    FEngine         : TParticleEngine;
    FEmitters       : TEmitterData;
    FBindings       : array of TEmitterBinding;
    FBindingCount   : Integer;

    function  FindBinding( aNID : Word; aUID : TUID ) : Integer;
    procedure RemoveBinding( aIndex : Integer );
    procedure UpdateBindings( aUpdatePositions : Boolean );
  public
    property Engine : TParticleEngine read FEngine;
  end;

implementation

uses math,
     vluatable,
     dfdata, dfthing, drlio, drlspritemap;

function FlagsToParticleFlags( const aFlags : TFlags ) : TParticleFlags;
var i : Byte;
begin
  Result := [];
  for i in aFlags do
    if i <= Ord( High( TParticleFlag ) ) then
      Include( Result, TParticleFlag( i ) );
end;

{ TParticleStore }

constructor TParticleStore.Create( aUIDs : TUIDStore );
begin
  inherited Create;
  FUIDs := aUIDs;
  FEngine := nil;
  FBindingCount := 0;
end;

procedure TParticleStore.BindUIDs( aUIDs : TUIDStore );
begin
  // Bindings belong to the old UID store and cannot be transferred to new IDs.
  Reset;
  FUIDs := aUIDs;
end;

procedure TParticleStore.Initialize( aEmitters : TEmitterData; aEngine : TParticleEngine );
begin
  if FEngine <> nil then FEngine.DecalCallback := nil;
  FEmitters := aEmitters;
  FEngine := aEngine;
end;

procedure TParticleStore.Update( aDeltaSec : Single );
begin
  if FEngine = nil then Exit;
  UpdateBindings( True );
  FEngine.Update( aDeltaSec );
end;

procedure TParticleStore.Reset;
begin
  if FEngine <> nil then
    FEngine.Clear;
  FBindingCount := 0;
end;

procedure TParticleStore.Clear;
var iEmitters : array of Integer;
    i         : Integer;
begin
  UpdateBindings( False );
  if FEngine = nil then Exit;
  SetLength( iEmitters, FBindingCount );
  for i := 0 to FBindingCount - 1 do
    iEmitters[i] := FBindings[i].PoolIndex;
  FEngine.Clear( iEmitters );
end;

destructor TParticleStore.Destroy;
begin
  Reset;
  Initialize( nil, nil );
  inherited Destroy;
end;

// Emitter data loading

destructor TEmitterData.Destroy;
var iData : PParticleEmitterData;
begin
  for iData in FEmitterData do
    if iData <> nil then Dispose( iData );
  inherited Destroy;
end;

procedure TEmitterData.RegisterEmitter( aLua : TLua; aNID : Word );
var iTable  : TLuaTable;
    iShape  : AnsiString;
    iE      : PParticleEmitterData;
    iData   : TParticleEmitterData;
    iWhite  : TColorRange;
begin
  iTable := aLua.GetTable( [ 'emitters', aNID ] );
  try
    iE := @iData;
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
    iE^.AnimFrameTime := iTable.GetFloat( 'anim_ftime', 0.25 );
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

  // Publish only a fully parsed definition; re-registration preserves its address.
  if aNID >= Length( FEmitterData ) then
    SetLength( FEmitterData, Max( aNID + 1, Max( Length( FEmitterData ) * 2, 16 ) ) );
  if FEmitterData[aNID] = nil then New( FEmitterData[aNID] );
  FEmitterData[aNID]^ := iData;
end;

function TEmitterData.GetEmitterData( aNID : Word ) : PParticleEmitterData;
begin
  if ( aNID = 0 ) or ( aNID >= Length( FEmitterData ) ) then
    Exit( nil );
  Result := FEmitterData[aNID];
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
    iData := FEmitters.GetEmitterData( aNID );
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
  iData := FEmitters.GetEmitterData( aNID );
  if iData = nil then Exit;
  Result := FEngine.EmitStart( iData, aWorldPos );
end;

procedure TParticleStore.SpawnBurst( aNID : Word; aWorldPos : TVec3f; aDirection : TVec2f;
  aCount : Word; const aDecalSprites : array of DWord; aDistanceScale, aArcScale : TFloatRange;
  aSpreadScale : Single );
var iData              : PParticleEmitterData;
    iBurstData         : TParticleEmitterData;
    iDirection         : TVec3f;
    iParticleDirection : TVec3f;
    iArc               : Single;
    iLength            : Single;
    iParticle          : Word;
    iScale             : Single;
    iSpeed             : Single;
begin
  if ( aNID = 0 ) or ( aCount = 0 ) or ( FEngine = nil ) then Exit;
  iData := FEmitters.GetEmitterData( aNID );
  if iData = nil then Exit;

  iDirection := iData^.Direction;
  iLength := Sqrt( Sqr( aDirection.X ) + Sqr( aDirection.Y ) );
  if iLength > 0 then
  begin
    iDirection.X := aDirection.X / iLength;
    iDirection.Y := aDirection.Y / iLength;
  end
  else
  begin
    iDirection.X := 0;
    iDirection.Y := 0;
  end;

  for iParticle := 1 to aCount do
  begin
    iBurstData := iData^;
    iArc := aArcScale.Random( IO.VisualRNG );
    iScale := aDistanceScale.Random( IO.VisualRNG );
    iSpeed := iData^.SpeedRange.Random( IO.VisualRNG );
    iBurstData.PositionOffset.Z := iData^.PositionOffset.Z * iArc;
    iBurstData.AccelRange.Min.Z := iData^.AccelRange.Min.Z * iArc;
    iBurstData.AccelRange.Max.Z := iData^.AccelRange.Max.Z * iArc;
    iBurstData.SpreadAngle := iData^.SpreadAngle * aSpreadScale;
    iBurstData.SpeedRange := NewFloatRange( iSpeed * iScale, iSpeed * iScale );
    iParticleDirection := iDirection;
    if iScale > 0 then
      iParticleDirection.Z := iDirection.Z * iArc / iScale;
    if Length( aDecalSprites ) > 0 then
      iBurstData.DecalSprite := aDecalSprites[ IO.VisualRNG.RLongInt( Length( aDecalSprites ) ) ];
    FEngine.SpawnBurst( @iBurstData, aWorldPos, iParticleDirection, 1 );
  end;
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

procedure TParticleStore.UpdateBindings( aUpdatePositions : Boolean );
var i     : Integer;
    iNode : TVObject;
    iDraw : TVec2i;
begin
  for i := FBindingCount - 1 downto 0 do
  begin
    if ( FEngine <> nil ) and ( FBindings[i].PoolIndex >= 0 ) and
      ( not FEngine.IsEmitterUsed( FBindings[i].PoolIndex ) ) then
    begin
      RemoveBinding( i );
      Continue;
    end;
    iNode := FUIDs.Get( FBindings[i].UID );
    if iNode = nil then
    begin
      // Destruction is observed before rendering; things do not know about particles.
      if ( FEngine <> nil ) and ( FBindings[i].PoolIndex >= 0 ) then
        FEngine.EmitKill( FBindings[i].PoolIndex );
      RemoveBinding( i );
    end
    else if aUpdatePositions and ( iNode is TThing ) and ( FBindings[i].PoolIndex >= 0 ) then
    begin
      FEngine.EmitSetVisible( FBindings[i].PoolIndex, TThing( iNode ).isVisible );
      iDraw := TThing( iNode ).GetDrawPosition;
      FEngine.EmitSetPosition( FBindings[i].PoolIndex,
        Vec3f( iDraw.X / SpriteMap.Engine.Scale + 16.0, iDraw.Y / SpriteMap.Engine.Scale + 16.0, 0 ) );
    end;
  end;
end;

// Save/Load

procedure TParticleStore.WriteToStream( aStream : TStream );
begin
  UpdateBindings( False );
  aStream.WriteWord( FBindingCount );
  if FBindingCount > 0 then
    aStream.Write( FBindings[0], FBindingCount * SizeOf( TEmitterBinding ) );
end;

procedure TParticleStore.ReadFromStream( aStream : TStream );
var iCount : Word;
    i      : Integer;
    iData  : PParticleEmitterData;
begin
  Reset;
  iCount := aStream.ReadWord;
  if iCount = 0 then Exit;
  SetLength( FBindings, iCount );
  aStream.Read( FBindings[0], iCount * SizeOf( TEmitterBinding ) );
  FBindingCount := iCount;
  for i := 0 to FBindingCount - 1 do
    FBindings[i].PoolIndex := -1;
  UpdateBindings( False );
  if FEngine = nil then Exit;
  for i := 0 to FBindingCount - 1 do
  begin
    iData := FEmitters.GetEmitterData( FBindings[i].NID );
    if iData <> nil then
      FBindings[i].PoolIndex := FEngine.EmitStart( iData, Vec3f( 0, 0, 0 ) );
  end;
end;

end.
