{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
// The presented terrain: what the renderers draw instead of the live cells.
// Gameplay resolves an action at once; holds placed with the presentation
// delay of each change keep it hidden until its effect arrives on screen,
// and fades then show it. Without holds or fades it equals the live level,
// so nothing needs to be flushed back into sync. Things need no such state:
// clips present the few that differ from the level.
unit drlvisual;
interface
uses vrltools, vvisualmap,
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

// Terrain, vision and blood marks of the presented level. Owned by the IO
// while it has both a level and a player; clips borrow it and are cleared
// before it is destroyed.
TDRLVisualMap = class( TDRLVisualMapBase )
  constructor Create( aLevel : TLevel );
  function Visible( const aCoord : TCoord2D ) : Boolean;
  function Explored( const aCoord : TCoord2D ) : Boolean;
  // A clip that draws a cell's top layer itself covers it while it exists;
  // covered cells switch without fading.
  procedure Cover( const aCoord : TCoord2D );
  procedure Uncover( const aCoord : TCoord2D );
  function Covered( const aCoord : TCoord2D ) : Boolean;
protected
  function SourceChanged : Boolean; override;
  procedure BeginCompare; override;
  function Sample( const aCoord : TCoord2D; const aTarget : TDRLVisualCell ) : TDRLVisualCell; override;
  function FadeTime( const aCoord : TCoord2D; const aFrom, aTo : TDRLVisualCell ) : DWord; override;
private
  FLevel      : TLevel; // Borrowed from the IO, which drops this map before the level.
  FCovers     : array of Byte;
  FVisionHold : QWord;
  // Level.Revision and player flags CellExplored reads, as last compared.
  FRevision   : DWord;
  FPlayer     : Byte;
  function BlocksVision( const aCell : TDRLVisualCell ) : Boolean;
  function CoverIndex( const aCoord : TCoord2D ) : Integer; inline;
public
  property Level : TLevel read FLevel;
end;

implementation

uses math;

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

function TDRLVisualMap.SourceChanged : Boolean;
var iPlayer : Byte;
begin
  // The player's flags are set through the generic flag API, so they are
  // compared rather than counted.
  iPlayer := 0;
  if FLevel.Player.Flags[ BF_DARKNESS ]   then iPlayer := iPlayer or 1;
  if FLevel.Player.Flags[ BF_STAIRSENSE ] then iPlayer := iPlayer or 2;
  Result := ( FLevel.Revision <> FRevision ) or ( iPlayer <> FPlayer );
  FRevision := FLevel.Revision;
  FPlayer   := iPlayer;
end;

procedure TDRLVisualMap.BeginCompare;
var iCoord : TCoord2D;
    iCell  : PVisualCell;
begin
  // Vision computed after an action sees through walls whose destruction
  // is still held; newly seen cells wait for the latest such wall. Its end
  // is when that wall's hold ends, at which cells are compared again.
  FVisionHold := 0;
  for iCoord in Area do
  begin
    iCell := Cell( iCoord );
    if ( iCell^.HoldUntil > FTime ) and ( iCell^.HoldUntil > FVisionHold ) then
      if BlocksVision( iCell^.Target ) <> BlocksVision( Sample( iCoord, iCell^.Target ) ) then
        FVisionHold := iCell^.HoldUntil;
  end;
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

end.
