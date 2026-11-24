{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
// The presented level: what the renderers draw instead of the live level.
// Gameplay resolves an action at once; holds placed with the presentation
// delay of each change keep it hidden until its effect arrives on screen,
// and fades then show it. Without holds or fades the presented level equals
// the live one, so nothing needs to be flushed back into sync.
unit drlvisual;
interface
uses vutil, vrltools, viotypes, vvisualmap, vvisualthings,
     dfdata, dflevel;

const
  // Cell flags of TDRLVisualCell.
  VCF_VISIBLE  = 1;
  VCF_EXPLORED = 2;
  VCF_BLOOD    = 4;
  // Light changes reach their new level within this time.
  VisualLightFadeTime = 150;

type TDRLVisualCell = packed record
  Bottom   : Byte;
  Top      : Byte;
  Style    : Byte;
  FStyle   : Byte;
  Deco     : Byte;
  Floor    : Byte;
  Rotation : Byte;
  Flags    : Byte;
end;

type TDRLVisualMapBase = specialize TGVisualMap<TDRLVisualCell>;

{ TDRLVisualMap }

// Terrain, vision and blood marks of the presented level.
TDRLVisualMap = class( TDRLVisualMapBase )
  constructor Create( aLevel : TLevel );
  procedure Update( aTime : DWord ); override;
  procedure Synchronize; override;
  function Visible( const aCoord : TCoord2D ) : Boolean;
  function Explored( const aCoord : TCoord2D ) : Boolean;
  // A clip that draws a cell's top layer itself covers it while it exists;
  // covered cells switch without fading.
  procedure Cover( const aCoord : TCoord2D );
  procedure Uncover( const aCoord : TCoord2D );
  function Covered( const aCoord : TCoord2D ) : Boolean;
protected
  function Sample( const aCoord : TCoord2D; const aTarget : TDRLVisualCell ) : TDRLVisualCell; override;
  function FadeTime( const aCoord : TCoord2D; const aFrom, aTo : TDRLVisualCell ) : DWord; override;
private
  FLevel      : TLevel; // Borrowed from the IO, which drops this map before the level.
  FCovers     : array of Byte;
  FVisionHold : QWord;
  function BlocksVision( const aCell : TDRLVisualCell ) : Boolean;
  function CoverIndex( const aCoord : TCoord2D ) : Integer; inline;
end;

{ TDRLVisualThing }

TDRLVisualThing = class( TVisualThing )
public
  // Last state of the world thing, kept for drawing after it is gone.
  Sprite   : TSprite;
  Gylph    : TIOGylph;
  IsBeing  : Boolean;
  // Written by owning clips: a light level overriding the presented cell's
  // (-1 for none) and a frame replacing the thing's sprite.
  Light    : Integer;
  HasFrame : Boolean;
  Frame    : TSprite;
  constructor Create( aUID : TUID );
end;

{ TDRLVisualThings }

TDRLVisualThings = class( TVisualThings )
  function Get( aUID : TUID ) : TDRLVisualThing;
  function Acquire( aUID : TUID; const aCoord : TCoord2D ) : TDRLVisualThing;
protected
  function CreateThing( aUID : TUID ) : TVisualThing; override;
end;

{ TDRLVisualState }

// Owned by the IO for its current level; clips borrow it and are cleared
// before it is destroyed.
TDRLVisualState = class
  constructor Create( aLevel : TLevel );
  destructor Destroy; override;
  // Advances presentation time, then follows the level.
  procedure Update( aTime : DWord );
  // Ends holds and fades; clips must have been cleared.
  procedure Synchronize;
  procedure HoldCell( const aCoord : TCoord2D; aDelay : DWord );
  procedure HoldThing( aUID : TUID; aDelay : DWord );
  // Something presented still differs from the level.
  function Busy : Boolean;
  // The shown being or item presented in aCoord, if any; valid since the
  // last Update.
  function BeingAt( const aCoord : TCoord2D ) : TDRLVisualThing;
  function ItemAt( const aCoord : TCoord2D ) : TDRLVisualThing;
private
  FLevel   : TLevel; // Borrowed from the IO.
  FMap     : TDRLVisualMap;
  FThings  : TDRLVisualThings;
  FBeingAt : array of TDRLVisualThing;
  FItemAt  : array of TDRLVisualThing;
  procedure SyncThings;
  function Index( const aCoord : TCoord2D ) : Integer; inline;
public
  property Level  : TLevel           read FLevel;
  property Map    : TDRLVisualMap    read FMap;
  property Things : TDRLVisualThings read FThings;
end;

implementation

uses sysutils, math,
     vnode,
     dfthing, dfbeing;

{ TDRLVisualMap }

constructor TDRLVisualMap.Create( aLevel : TLevel );
begin
  inherited Create( aLevel.Area );
  FLevel := aLevel;
  SetLength( FCovers, ( Area.B.X - Area.A.X + 1 ) * ( Area.B.Y - Area.A.Y + 1 ) );
  FillChar( FCovers[0], Length( FCovers ), 0 );
  FVisionHold := 0;
  Synchronize;
end;

function TDRLVisualMap.CoverIndex( const aCoord : TCoord2D ) : Integer; inline;
begin
  Exit( ( aCoord.Y - Area.A.Y ) * ( Area.B.X - Area.A.X + 1 ) + ( aCoord.X - Area.A.X ) );
end;

procedure TDRLVisualMap.Cover( const aCoord : TCoord2D );
begin
  if Contains( aCoord ) then Inc( FCovers[ CoverIndex( aCoord ) ] );
end;

procedure TDRLVisualMap.Uncover( const aCoord : TCoord2D );
begin
  if not Contains( aCoord ) then Exit;
  Assert( FCovers[ CoverIndex( aCoord ) ] > 0, 'Visual cell uncovered more often than covered' );
  Dec( FCovers[ CoverIndex( aCoord ) ] );
end;

function TDRLVisualMap.Covered( const aCoord : TCoord2D ) : Boolean;
begin
  Exit( Contains( aCoord ) and ( FCovers[ CoverIndex( aCoord ) ] > 0 ) );
end;

function TDRLVisualMap.Visible( const aCoord : TCoord2D ) : Boolean;
begin
  Exit( Contains( aCoord ) and ( State( aCoord, vlTarget ).Flags and VCF_VISIBLE <> 0 ) );
end;

function TDRLVisualMap.Explored( const aCoord : TCoord2D ) : Boolean;
begin
  Exit( Contains( aCoord ) and ( State( aCoord, vlTarget ).Flags and VCF_EXPLORED <> 0 ) );
end;

function TDRLVisualMap.BlocksVision( const aCell : TDRLVisualCell ) : Boolean;
begin
  if CF_BLOCKLOS in FLevel.Data.Cells[ aCell.Bottom ].Flags then Exit( True );
  Exit( ( aCell.Top <> 0 ) and ( CF_BLOCKLOS in FLevel.Data.Cells[ aCell.Top ].Flags ) );
end;

procedure TDRLVisualMap.Update( aTime : DWord );
var iCoord : TCoord2D;
    iCell  : PVisualCell;
begin
  // Vision computed after an action sees through walls whose destruction
  // is still held; newly seen cells wait for the latest such wall.
  FVisionHold := 0;
  for iCoord in Area do
  begin
    iCell := Cell( iCoord );
    if ( iCell^.HoldUntil > FTime + aTime ) and ( iCell^.HoldUntil > FVisionHold ) then
      if BlocksVision( iCell^.Target ) <> BlocksVision( Sample( iCoord, iCell^.Target ) ) then
        FVisionHold := iCell^.HoldUntil;
  end;
  inherited Update( aTime );
end;

procedure TDRLVisualMap.Synchronize;
begin
  FVisionHold := 0;
  inherited Synchronize;
end;

function TDRLVisualMap.Sample( const aCoord : TCoord2D; const aTarget : TDRLVisualCell ) : TDRLVisualCell;
const Revealed = VCF_VISIBLE or VCF_EXPLORED;
begin
  Result.Bottom   := FLevel.CellBottom[ aCoord ];
  Result.Top      := FLevel.CellTop[ aCoord ];
  Result.Style    := FLevel.CStyle[ aCoord ];
  Result.FStyle   := FLevel.FlrStyle[ aCoord ];
  Result.Deco     := FLevel.Deco[ aCoord ];
  Result.Floor    := FLevel.Floor[ aCoord ];
  Result.Rotation := FLevel.Rotation[ aCoord ];
  Result.Flags    := 0;
  if FLevel.isVisible( aCoord )                then Result.Flags := Result.Flags or VCF_VISIBLE;
  if FLevel.CellExplored( aCoord )             then Result.Flags := Result.Flags or VCF_EXPLORED;
  if FLevel.LightFlag[ aCoord, LFBLOOD ]       then Result.Flags := Result.Flags or VCF_BLOOD;
  // Losing sight is shown at once; gaining it waits for the vision hold.
  if FTime < FVisionHold then
    Result.Flags := ( Result.Flags and not Revealed ) or
      ( Result.Flags and aTarget.Flags and Revealed );
end;

function TDRLVisualMap.FadeTime( const aCoord : TCoord2D; const aFrom, aTo : TDRLVisualCell ) : DWord;
  function LayerFade( aFrom, aTo : Byte; aOptional : Boolean ) : DWord;
  begin
    if aFrom = aTo then Exit( 0 );
    Result := 0;
    if ( aFrom <> 0 ) or not aOptional then Result := FLevel.Data.Cells[ aFrom ].Fade;
    if ( aTo <> 0 ) or not aOptional then Result := Max( Result, FLevel.Data.Cells[ aTo ].Fade );
  end;
begin
  // Only what the player can see fades; vision and blood marks switch.
  if ( aFrom.Flags and aTo.Flags and VCF_EXPLORED ) = 0 then Exit( 0 );
  if Covered( aCoord ) then Exit( 0 );
  Result := Max( LayerFade( aFrom.Bottom, aTo.Bottom, False ), LayerFade( aFrom.Top, aTo.Top, True ) );
  if ( Result = 0 ) and ( ( aFrom.Bottom <> aTo.Bottom ) or ( aFrom.Top <> aTo.Top ) ) then Exit( 0 );
  // Changes derived from neighbours or styles take the cell's own fade.
  if ( aFrom.Style <> aTo.Style ) or ( aFrom.FStyle <> aTo.FStyle ) or ( aFrom.Deco <> aTo.Deco ) or
     ( aFrom.Floor <> aTo.Floor ) or ( aFrom.Rotation <> aTo.Rotation ) then
    Result := Max( Result, FLevel.Data.Cells[ aTo.Bottom ].Fade );
end;

{ TDRLVisualThing }

constructor TDRLVisualThing.Create( aUID : TUID );
begin
  inherited Create( aUID );
  Sprite   := Default( TSprite );
  Gylph.ASCII := ' ';
  Gylph.Color := 0;
  IsBeing  := False;
  Light    := -1;
  HasFrame := False;
  Frame    := Default( TSprite );
end;

{ TDRLVisualThings }

function TDRLVisualThings.CreateThing( aUID : TUID ) : TVisualThing;
begin
  Exit( TDRLVisualThing.Create( aUID ) );
end;

function TDRLVisualThings.Get( aUID : TUID ) : TDRLVisualThing;
begin
  Exit( TDRLVisualThing( Find( aUID ) ) );
end;

function TDRLVisualThings.Acquire( aUID : TUID; const aCoord : TCoord2D ) : TDRLVisualThing;
begin
  Exit( TDRLVisualThing( inherited Acquire( aUID, aCoord ) ) );
end;

{ TDRLVisualState }

constructor TDRLVisualState.Create( aLevel : TLevel );
begin
  inherited Create;
  FLevel  := aLevel;
  FMap    := TDRLVisualMap.Create( aLevel );
  FThings := TDRLVisualThings.Create;
  SetLength( FBeingAt, ( FMap.Area.B.X - FMap.Area.A.X + 1 ) * ( FMap.Area.B.Y - FMap.Area.A.Y + 1 ) );
  SetLength( FItemAt, Length( FBeingAt ) );
  SyncThings;
end;

function TDRLVisualState.Index( const aCoord : TCoord2D ) : Integer; inline;
begin
  Exit( ( aCoord.Y - FMap.Area.A.Y ) * ( FMap.Area.B.X - FMap.Area.A.X + 1 ) + ( aCoord.X - FMap.Area.A.X ) );
end;

function TDRLVisualState.BeingAt( const aCoord : TCoord2D ) : TDRLVisualThing;
begin
  if not FMap.Contains( aCoord ) then Exit( nil );
  Exit( FBeingAt[ Index( aCoord ) ] );
end;

function TDRLVisualState.ItemAt( const aCoord : TCoord2D ) : TDRLVisualThing;
begin
  if not FMap.Contains( aCoord ) then Exit( nil );
  Exit( FItemAt[ Index( aCoord ) ] );
end;

destructor TDRLVisualState.Destroy;
begin
  FreeAndNil( FThings );
  FreeAndNil( FMap );
  inherited Destroy;
end;

procedure TDRLVisualState.SyncThings;
var iNode    : TNode;
    iThing   : TThing;
    iVisual  : TDRLVisualThing;
    iFollows : Boolean;
    i        : Integer;
begin
  FThings.BeginSync( FMap.Time );
  for iNode in FLevel do
    if iNode is TThing then
    begin
      iThing := TThing( iNode );
      // A killed being is shown only by its death clip.
      if ( iThing is TBeing ) and TBeing( iThing ).Killed then Continue;
      iVisual := TDRLVisualThing( FThings.Report( iThing.UID, iThing.Position, iFollows ) );
      iVisual.IsBeing := iThing is TBeing;
      iVisual.Sprite  := iThing.Sprite;
      iVisual.Gylph   := iThing.Gylph;
    end;
  FThings.EndSync;

  FillChar( FBeingAt[0], Length( FBeingAt ) * SizeOf( TDRLVisualThing ), 0 );
  FillChar( FItemAt[0], Length( FItemAt ) * SizeOf( TDRLVisualThing ), 0 );
  for i := 0 to FThings.Count - 1 do
  begin
    iVisual := TDRLVisualThing( FThings.Things[i] );
    if ( not iVisual.Shown ) or ( not FMap.Contains( iVisual.Coord ) ) then Continue;
    if iVisual.IsBeing
      then FBeingAt[ Index( iVisual.Coord ) ] := iVisual
      else FItemAt[ Index( iVisual.Coord ) ] := iVisual;
  end;
end;

procedure TDRLVisualState.Update( aTime : DWord );
begin
  FMap.Update( aTime );
  SyncThings;
end;

procedure TDRLVisualState.Synchronize;
begin
  FMap.Synchronize;
  FThings.Clear;
  SyncThings;
end;

procedure TDRLVisualState.HoldCell( const aCoord : TCoord2D; aDelay : DWord );
begin
  FMap.Hold( aCoord, aDelay );
end;

procedure TDRLVisualState.HoldThing( aUID : TUID; aDelay : DWord );
begin
  FThings.Hold( aUID, FMap.Time + aDelay );
end;

function TDRLVisualState.Busy : Boolean;
begin
  Exit( FMap.Busy or FThings.Busy );
end;

end.
