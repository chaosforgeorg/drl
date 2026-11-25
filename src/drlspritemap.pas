{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlspritemap;
interface
uses classes, sysutils, math,
     vutil, vgltypes, vrltools, vgenerics, vvector, vcolor, vspriteengine, vtextures, vuid, vvisualmap, vanimation,
     dfdata, dfbeing, dfitem, dflevel, drlio, drlspritemapbase, drlvisual;

// TODO : remove
const SpriteCellRow = 16;

type TCoord2DArray = specialize TGArray< TCoord2D >;

type TSpritePart = ( F, L, R, T, B, TL, TR, BL, BR, 
                     WT, WB, WTL, WTR, WBL, WBR );
     TSpritePartSet = set of TSpritePart;

type

{ TDRLSpriteMap }

 // Draws the presented terrain of a visual map, the level's things no clip
 // claims, and claimed things through their clips.
 TDRLSpriteMap = class( TSpriteMap )
  // The graphics IO owns the map and everything it borrows, including the
  // animations whose clips claim things.
  constructor Create( aIO : TDRLIO; aTextures : TTextureManager; aCursor : TDRLMouseCursor;
    aAnimations : TAnimations; aFramebuffer : TVec2i );
  // aVisual is the IO's visual map of its level, or nil without one.
  procedure SetVisual( aVisual : TDRLVisualMap );
  // Called by the graphics IO whenever its scaling changes, before rendering.
  procedure Recalculate( aTileScale : Single; aFontMult : Byte; aScaledScreen : TGLVec2i ); overload;
  procedure Update( aTime : DWord; aProjection : TMatrix44; aDarkness : Boolean ); overload;
  procedure Draw; override;
  procedure PushBeingOverlay( aPos : TVec2i; aBeing : TBeing; aLight : Byte );
  procedure PushSpriteDoodad( aCoord : TCoord2D; const aSprite : TSprite; aLight : Integer = -1; aZOffset : Integer = 0 );
  procedure PushSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aTSX : Single = 0; aTSY : Single = 0 );
  procedure SetTarget( aTarget : TCoord2D; aColor : TColor; aSource : TBeing = nil );
  procedure SetAutoTarget( aSource, aTarget : TCoord2D );
  procedure ClearTarget;
  procedure ToggleGrid;
  function VariableLight( aWhere : TCoord2D; aBonus : ShortInt = 0 ) : Byte;
  destructor Destroy; override;
  function GetBeingSprite( aBeing : TBeing ) : TSprite;
  // Pixel position of a presented position in cell units.
  function PixelPosition( const aPosition : TVec2f ) : TVec2i;
  // A thing drawn in its cell as the player perceives it; aBeing or aItem is
  // the live thing, or nil once it has been removed.
  procedure PushPresentedBeing( const aCoord : TCoord2D; aBeing : TBeing; const aSprite : TSprite );
  procedure PushPresentedItem( const aCoord : TCoord2D; aItem : TItem; const aSprite : TSprite; aDTime : Integer = 0 );
  // TParticlePlacement for the level's particle store.
  function ParticlePlacement( aUID : TUID; out aPosition : TVec2f; out aVisible : Boolean ) : Boolean;
private
  FIO             : TDRLIO;
  FTextures       : TTextureManager;
  FCursor         : TDRLMouseCursor;
  FAnimations     : TAnimations;     // Borrowed from the graphics IO.
  FVisualMap      : TDRLVisualMap;   // Borrowed from the graphics IO with its level.
  // The state terrain is drawn from: vlShown and vlTarget in turn near a
  // fading cell, vlTarget otherwise.
  FLayer          : TVisualLayer;
  FLevel          : TLevel;
  FGridActive     : Boolean;
  FFluidX         : Single;
  FFluidY         : Single;
  FFluidTime      : Double;
  FTargeting      : Boolean;
  FTarget         : TCoord2D;
  FTargetList     : TCoord2DArray;
  //FOldTargetList : TCoord2DArray;
  FTargetColor    : TColor;
  FAutoTarget     : TCoord2D;
  FMarker         : TCoord2D;
  FLightMap       : array[0..MAXX] of array[0..MAXY] of Byte;
  // Presented light of each cell, moving towards its current value.
  FCellLight      : array[0..MAXX] of array[0..MAXY] of Single;
  FLightSnap      : Boolean;
private
  procedure ApplyEffect;
  procedure UpdateLightMap( aTime : DWord );
  function CellLightTarget( aCoord : TCoord2D ) : Single;
  function VCell( const aCoord : TCoord2D ) : TDRLVisualCell; inline;
  // Where a thing is presented, in cell units; False when it is not.
  function PresentedPosition( aUID : TUID; out aPosition : TVec2f ) : Boolean;
  procedure PushTerrain;
  procedure PushCell( aCoord : TCoord2D );
  procedure PushThings( aDTime : Integer );
  function PushFluidTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
  function PushWallDebrisTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
  function GetTerrainSprite( aCoord : TCoord2D; aCell : Byte; out aDeco : Byte ) : TSprite;
  function GetExploredTerrainCell( aCoord : TCoord2D ) : Byte;
  function GetTerrainLight( aCoord : TCoord2D ) : TGLRawQColor;
  function GetTransitionMaterial( const aSprite : TSprite ) : TSpriteTransitionMaterial;
  procedure PushDecals( aDarkness : Boolean );
  // Targeting marks and the grid.
  procedure PushObjects;
  procedure PushMultiSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
  procedure PushFloorTerrainNewLayout( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
  procedure PushSpriteTerrainPart( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aStart, aEnd : TVec2f );
  procedure PushTarget( aSpriteID : DWord; aPosition : TVec2i; aColor : TColor; aSize : Float );
  function GetSprite( aCell, aStyle : Byte ) : TSprite; overload;
  procedure DrawMarker;
public
  property Marker : TCoord2D read FMarker write FMarker;
  property Target : TCoord2D read FTarget;
end;


implementation

uses vmath, viotypes, vvision, vgl3library, vnode,
     dfmap, dfthing, drlcontrollerbindings,
     drlmarkers, drldecals, drlanimation;

function SpritePartSetFill( aPart : TSpritePart ) : TSpritePartSet;
begin
  case aPart of
    L  : Exit( [R] );
    R  : Exit( [L] );
    T  : Exit( [B] );
    B  : Exit( [T] );
    TL : Exit( [B,TR] );
    TR : Exit( [B,TL] );
    BL : Exit( [T,BR] );
    BR : Exit( [T,BL] );
    WT : Exit( [WB] );
    WB : Exit( [WT] );
    WTL: Exit( [WB,WTR] );
    WTR: Exit( [WB,WTL] );
    WBL: Exit( [WT,WBR] );
    WBR: Exit( [WT,WBL] );
  end;
  Exit( [] );
end;

{ TDRLSpriteMap }

constructor TDRLSpriteMap.Create( aIO : TDRLIO; aTextures : TTextureManager; aCursor : TDRLMouseCursor;
  aAnimations : TAnimations; aFramebuffer : TVec2i );
begin
  inherited Create( aIO.Driver, aFramebuffer );
  FIO         := aIO;
  FTextures   := aTextures;
  FCursor     := aCursor;
  FAnimations := aAnimations;
  FVisualMap  := nil;
  FLevel      := nil;
  FLayer      := vlTarget;
  FLightSnap  := True;
  FTargeting := False;
  FTargetList := TCoord2DArray.Create();
  //FOldTargetList := TCoord2DArray.Create();
  FFluidTime := 0;
  FTarget.Create(0,0);
  FGridActive     := False;
  FAutoTarget.Create(0,0);
  FMarker.Create(-1,-1);
end;

procedure TDRLSpriteMap.Recalculate( aTileScale : Single; aFontMult : Byte; aScaledScreen : TGLVec2i );
begin
  inherited Recalculate( aTileScale, aScaledScreen );
  // Camera bounds leave room for the HUD above and below the map.
  FMinShift := Vec2i(0,0);
  FMaxShift := Vec2i(
    Max(FSpriteEngine.Grid.X*MAXX-FDriver.GetSizeX,0),
    Max(FSpriteEngine.Grid.Y*MAXY-FDriver.GetSizeY,0)
  );

  if FDriver.GetSizeY > 20*FSpriteEngine.Grid.Y then
  begin
    FMinShift.Y := -( FDriver.GetSizeY - 20*FSpriteEngine.Grid.Y ) div 2;
    FMaxShift.Y := FMinShift.Y;
  end
  else
  begin
    FMinShift.Y := FMinShift.Y - 18*aFontMult*2;
    FMaxShift.Y := FMaxShift.Y + 18*aFontMult*3;
  end;
end;

procedure TDRLSpriteMap.SetVisual( aVisual : TDRLVisualMap );
begin
  FSpriteEngine.Clear;
  FVisualMap := aVisual;
  FLevel     := nil;
  if aVisual = nil then Exit;
  FLevel     := aVisual.Level;
  FLightSnap := True;
end;

function TDRLSpriteMap.VCell( const aCoord : TCoord2D ) : TDRLVisualCell; inline;
begin
  Exit( FVisualMap.State( aCoord, FLayer ) );
end;

function TDRLSpriteMap.PixelPosition( const aPosition : TVec2f ) : TVec2i;
begin
  Result.Init( Round( aPosition.X * FSpriteEngine.Grid.X ), Round( aPosition.Y * FSpriteEngine.Grid.Y ) );
end;

function TDRLSpriteMap.ParticlePlacement( aUID : TUID; out aPosition : TVec2f; out aVisible : Boolean ) : Boolean;
begin
  aPosition := Vec2f( 0, 0 );
  aVisible  := False;
  if ( FVisualMap = nil ) or not PresentedPosition( aUID, aPosition ) then Exit( False );
  aVisible  := FVisualMap.Visible( NewCoord2D( Round( aPosition.X ) + 1, Round( aPosition.Y ) + 1 ) );
  Exit( True );
end;

procedure TDRLSpriteMap.Update( aTime : DWord; aProjection : TMatrix44; aDarkness : Boolean );
var iUIDs     : TUIDStore;
    iShift    : Single;
    iPixel    : Integer;
    iMark     : TMarker;
    iTarget   : TBeing;
    iPosition : TVec2f;
begin
  inherited Update( aTime, aProjection );
  iUIDs := FLevel.Context.UIDs;

  // Technically this should smooth out fluids -_-
  FFluidTime := FDriver.GetMs*0.0001;
  iShift     := FFluidTime - Floor( FFluidTime );
  iPixel     := Floor( iShift * ( 32*FSpriteEngine.Scale ) );
  iShift     := iPixel / ( 32*FSpriteEngine.Scale );
  FFluidX := 1-iShift;
  FFluidY := iShift;
  ApplyEffect;
  UpdateLightMap( aTime );
  PushTerrain;
  PushDecals( aDarkness );
  PushThings( aTime );
  PushObjects;

  for iMark in FLevel.Markers.Data do
    if iMark.Target = 0 then
    begin
      if FVisualMap.Visible( iMark.Coord ) then
        PushSpriteFX( iMark.Coord, iMark.Sprite, FTimer, -1 );
    end
    else
    begin
      // Marks follow their being as it is presented.
      iTarget := iUIDs[ iMark.Target ] as TBeing;
      if ( iTarget <> nil ) and ( not iTarget.Dying ) and PresentedPosition( iMark.Target, iPosition )
        and FVisualMap.Visible( NewCoord2D( Round( iPosition.X ) + 1, Round( iPosition.Y ) + 1 ) ) then
        PushSpriteFX( PixelPosition( iPosition ), iMark.Sprite, FTimer, -1 );
    end;

  DrawMarker;
end;

procedure TDRLSpriteMap.DrawMarker;
const MarkerSprite : TSprite = (
  Color     : (R:0;G:0;B:0;A:255);
  OverColor : (R:0;G:0;B:0;A:0);
  GlowColor : (R:0;G:0;B:0;A:0);
  Emissive  : (R:0;G:0;B:0;A:0);
  SpriteID  : (0,0,0,0,0,0,0,0);
  SCount    : 1;
  Frames    : 0;
  Frametime : 0;
  Flags     : [ SF_COSPLAY ];
);
begin
  if ( FMarker.X < 0 ) or ( FMarker.Y < 0 ) then Exit;
  if not FLevel.isProperCoord( FMarker ) then Exit;
  MarkerSprite.SpriteID[0] := FIO.EngineSprites.Highlight;
  MarkerSprite.Color := ColorBlack;
  MarkerSprite.Color.A := 127;
  if FIO.ControllerActionHeld( CONTROLLER_MODIFIER_ALT ) or FIO.Targeting then
  begin
    MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100);
    MarkerSprite.Color.G := MarkerSprite.Color.R;
    MarkerSprite.Color.B := MarkerSprite.Color.R;
  end
  else
  begin
    if FLevel.cellFlagSet( FMarker, CF_BLOCKMOVE ) and ( not FLevel.cellFlagSet( FMarker, CF_OPENABLE ) ) then
      MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100)
    else if (FLevel.GetBeing( FMarker ) <> nil) or (not FLevel.isPassable( FMarker ) ) then
    begin
      MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100);
      MarkerSprite.Color.G := MarkerSprite.Color.R;
    end
    else
      MarkerSprite.Color.G := Floor(50*(Sin( FFluidTime*50 )+1)+100);
  end;
  PushSpriteFX( FMarker, MarkerSprite );
end;


procedure TDRLSpriteMap.Draw;
var iPoint   : TPoint;
    iCoord   : TCoord2D;
const TargetSprite : TSprite = (
  Color     : (R:0;G:0;B:0;A:255);
  OverColor : (R:0;G:0;B:0;A:0);
  GlowColor : (R:0;G:0;B:0;A:0);
  Emissive  : (R:0;G:0;B:0;A:0);
  SpriteID  : (0,0,0,0,0,0,0,0);
  SCount    : 1;
  Frames    : 0;
  Frametime : 0;
  Flags     : [ SF_COSPLAY ];
);

begin
  TargetSprite.SpriteID[0] := FIO.EngineSprites.Select;

  if FCursor.Active and FDriver.GetMousePos( iPoint ) then
  begin
    iCoord := DevicePointToCoord( iPoint );
    if FLevel.isProperCoord( iCoord ) then
    begin
      TargetSprite.Color := ColorBlack;
      if FVisualMap.Visible( iCoord ) then
        TargetSprite.Color.G := Floor(100*(Sin( FFluidTime*50 )+1)+50)
      else
        TargetSprite.Color.R := Floor(100*(Sin( FFluidTime*50 )+1)+50);
      PushSpriteFX( iCoord, TargetSprite );
    end;
  end;

  inherited Draw;
end;

const WallSpriteTop = 8.0 / 32.0;

function SpriteTint( const aSprite : TSprite ) : TColor;
begin
  if SF_COSPLAY in aSprite.Flags then Exit( aSprite.Color );
  Result := ColorBlack;
end;

function ConnectedTransitionMask( aMask, aQuadrant : Byte ) : Byte;
var iOwn : Byte;
begin
  iOwn := 3 xor aQuadrant;
  Result := aMask;
  // A diagonal neighbour can contribute only through a shared cardinal neighbour.
  if (aMask and ((1 shl (iOwn xor 1)) or (1 shl (iOwn xor 2)))) = 0 then
    Result := aMask and not (1 shl (iOwn xor 3));
end;

procedure SpritePartBounds( aPart : TSpritePart; aTop : Single; out aStart, aEnd : TVec2f );
begin
  aStart := TVec2f.Create( 0, 0 );
  aEnd   := TVec2f.Create( 1, 1 );
  case aPart of
    L       : aEnd.X   := 0.5;
    R       : aStart.X := 0.5;
    T, WT   : aEnd.Y   := aTop;
    B, WB   : aStart.Y := aTop;
    TL, WTL : aEnd.Init( 0.5, aTop );
    TR, WTR : begin aEnd.Y := aTop; aStart.X := 0.5; end;
    BL, WBL : begin aEnd.X := 0.5; aStart.Y := aTop; end;
    BR, WBR : aStart.Init( 0.5, aTop );
  end;
end;

type TSpriteTerrainPiece = record
  SpriteID : DWord;
  Part     : TSpritePart;
end;
type TSpriteTerrainLayout = array[0..3] of TSpriteTerrainPiece;
// Atlas IDs for the left/right halves of the wall's top and bottom bands.
type TMultiSpritePieces = array[0..3] of DWord;

function MultiSpriteInterior( aSpriteID : DWord ) : DWord;
begin
  Result := aSpriteID - 2*SpriteCellRow + 1;
end;

function GetMultiSpriteLayout( aSpriteID : DWord; aRotation : Byte; out aLayout : TSpriteTerrainLayout ) : Integer;
var iSpriteID : DWord;
    iPart     : TSpritePart;
    iPS       : TSpritePart;
    iParts    : TSpritePartSet;
    iMaskOut  : TSpritePartSet;
  procedure AddPart( aID : DWord; aPart : TSpritePart );
  begin
    aLayout[Result].SpriteID := aID;
    aLayout[Result].Part := aPart;
    Inc( Result );
  end;
  function BaseCase( aMask : Byte ) : DWord;
  begin
    case aMask of
      %00000010 : Exit( aSpriteID + 1*SpriteCellRow + 2 ); // wall up
      %00001000 : Exit( aSpriteID + 4*SpriteCellRow + 2 ); // wall left
      %00001010 : Exit( aSpriteID + 3*SpriteCellRow + 2 ); // wall left up
      %00010000 : Exit( aSpriteID + 4*SpriteCellRow + 0 ); // wall right
      %00010010 : Exit( aSpriteID + 3*SpriteCellRow + 0 ); // wall right up
      %00011000 : Exit( aSpriteID +                 + 1 ); // wall left right
      %00011010 : Exit( aSpriteID + 2*SpriteCellRow + 1 ); // wall left right up

      %01000000 : Exit( aSpriteID + 1*SpriteCellRow + 1 ); // wall down
      %01000010 : Exit( aSpriteID + 1*SpriteCellRow + 0 ); // wall down up
      %01001000 : Exit( aSpriteID +                 + 2 ); // wall down left
      %01001010 : Exit( aSpriteID + 2*SpriteCellRow + 2 ); // wall down up left
      %01010000 : Exit( aSpriteID +                 + 0 ); // wall down right
      %01010010 : Exit( aSpriteID + 2*SpriteCellRow + 0 ); // wall up down right
      %01011000 : Exit( aSpriteID + 3*SpriteCellRow + 1 ); // wall down right left
      %01011010 : Exit( aSpriteID + 4*SpriteCellRow + 1 ); // wall cross

      %00001011 : Exit( aSpriteID + (-3+2)*SpriteCellRow + 2 ); // wall left+up
      %00010110 : Exit( aSpriteID + (-3+2)*SpriteCellRow + 0 ); // wall right+up
      %01101000 : Exit( aSpriteID + (-3  )*SpriteCellRow + 2 ); // wall left+down
      %11010000 : Exit( aSpriteID + (-3  )*SpriteCellRow + 0 ); // wall right+down

      %00011111 : Exit( aSpriteID + (-3+2)*SpriteCellRow + 1 ); // wall full up
      %11111000 : Exit( aSpriteID + (-3  )*SpriteCellRow + 1 ); // wall full down
      %11010110 : Exit( aSpriteID + (-3+1)*SpriteCellRow + 0 ); // wall full right
      %01101011 : Exit( aSpriteID + (-3+1)*SpriteCellRow + 2 ); // wall full left
      %11111111 : Exit( MultiSpriteInterior( aSpriteID ) ); // wall full
    end;
    Exit( 0 );
  end;
begin
  Result := 0;
  iSpriteID := BaseCase( aRotation );
  if iSpriteID > 0 then
  begin
    AddPart( iSpriteID, F );
    Exit;
  end;
  iSpriteID := 0;
  iPart     := F;
  iParts    := [];
  iMaskOut  := [];
  case aRotation of
    %00000000 :
      begin
        // Special case for column
        AddPart( aSpriteID + SpriteCellRow + 2, WB );
        AddPart( aSpriteID + SpriteCellRow + 1, WT );
        Exit;
      end;
    %01011111 : begin iSpriteID := aSpriteID + 3 * SpriteCellRow + 1; iPart := WB; end;
    %11111010 : begin iSpriteID := aSpriteID + 2 * SpriteCellRow + 1; iPart := WT; end;
    %11011110 : begin iSpriteID := aSpriteID + 2 * SpriteCellRow + 2; iPart := L; end;
    %01111011 : begin iSpriteID := aSpriteID + 2 * SpriteCellRow + 0; iPart := R; end;

    %11111110 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WTL; end;
    %11111011 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WTR; end;
    %11011111 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WBL; end;
    %01111111 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WBR; end;

    %01111110 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WBR,WTL]; iMaskOut := [WBL,WTR]; end;
    %11011011 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WBL,WTR]; iMaskOut := [WBR,WTL]; end;

    %00011011 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 1; iParts := [WB,WTR]; iMaskOut := [WTL]; end; // wall left right up
    %00011110 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 1; iParts := [WB,WTL]; iMaskOut := [WTR]; end; // wall left right up

    %01101010 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 2; iParts := [WT,WBR];      iMaskOut := [WBL]; end; // wall down up left
    %01001011 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 2; iParts := [WTR,WBL,WBR]; iMaskOut := [WTL]; end; // wall down up left

    %11010010 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 0; iParts := [WT,WBL];      iMaskOut := [WBR]; end; // wall up down right
    %01010110 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 0; iParts := [WTL,WBL,WBR]; iMaskOut := [WTR]; end; // wall up down right

    %11011000 : begin iSpriteID := aSpriteID + 3*SpriteCellRow + 1; iParts := [WT,WBL]; iMaskOut := [WBR]; end; // wall down right left
    %01111000 : begin iSpriteID := aSpriteID + 3*SpriteCellRow + 1; iParts := [WT,WBR]; iMaskOut := [WBL]; end; // wall down right left

    %01011110 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WB,WTL]; iMaskOut := [WTR]; end;
    %01111010 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WT,WBR]; iMaskOut := [WBL]; end;
    %01011011 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WB,WTR]; iMaskOut := [WTL]; end;
    %11011010 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WT,WBL]; iMaskOut := [WBR]; end;
  end;
  if iSpriteID = 0 then Exit;

  if iParts = [] then
  begin
    AddPart( iSpriteID, iPart );
    iMaskOut := SpritePartSetFill( iPart );
  end
  else
  begin
    for iPS in iParts do
      AddPart( iSpriteID, iPS );
  end;

  iSpriteID := MultiSpriteInterior( aSpriteID );
  for iPS in iMaskOut do
    AddPart( iSpriteID, iPS );
  Exit;
end;

procedure GetMultiSpritePieces( aSpriteID : DWord; aRotation : Byte; out aPieces : TMultiSpritePieces );
var iLayout     : TSpriteTerrainLayout;
    iCount      : Integer;
    i, iX, iY   : Integer;
    iStart,iEnd : TVec2f;
begin
  for i := 0 to 3 do aPieces[i] := 0;
  iCount := GetMultiSpriteLayout( aSpriteID, aRotation, iLayout );
  for i := 0 to iCount-1 do
  begin
    SpritePartBounds( iLayout[i].Part, WallSpriteTop, iStart, iEnd );
    for iY := 0 to 1 do
      for iX := 0 to 1 do
        if (iX*0.5 >= iStart.X) and (iX*0.5 < iEnd.X) and
           (iY*WallSpriteTop >= iStart.Y) and (iY*WallSpriteTop < iEnd.Y) then
          aPieces[iX+2*iY] := iLayout[i].SpriteID;
  end;
end;

procedure TDRLSpriteMap.PushMultiSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
var iLayout : TSpriteTerrainLayout;
    iSprite : TSprite;
    iCount  : Integer;
    i       : Integer;
    iStart  : TVec2f;
    iEnd    : TVec2f;
begin
  iCount := GetMultiSpriteLayout( aSprite.SpriteID[0], aRotation, iLayout );
  iSprite := aSprite;
  for i := 0 to iCount-1 do
  begin
    iSprite.SpriteID[0] := iLayout[i].SpriteID;
    if iLayout[i].Part = F then PushSpriteTerrain( aCoord, iSprite, aZ )
    else
    begin
      SpritePartBounds( iLayout[i].Part, WallSpriteTop, iStart, iEnd );
      PushSpriteTerrainPart( aCoord, iSprite, aZ, iStart, iEnd );
    end;
  end;
end;

procedure TDRLSpriteMap.PushFloorTerrainNewLayout( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
var iSprite : TSprite;

  procedure Push( aOffset : DWord; aPart : TSpritePart = F );
  var iStart, iEnd : TVec2f;
  begin
    iSprite.SpriteID[0] := aSprite.SpriteID[0] + aOffset;
    SpritePartBounds( aPart, 0.5, iStart, iEnd );
    PushSpriteTerrainPart( aCoord, iSprite, aZ, iStart, iEnd );
  end;

begin
  iSprite := aSprite;
  case aRotation and %00001111 of
    %00000001 : Push( 2, T ); // top
    %00000010 : Push( 2, B ); // bottom
    %00000011 : Push( 2 ); // top bottom
    %00000100 : Push( 3, L ); // left
    %00000101 : Push( 4    ); // top left
    %00000110 : Push( 5    ); // bottom left
    %00000111 : Push( 8    ); // top bottom left
    %00001000 : Push( 3, R ); // right
    %00001001 : Push( 6    ); // top right
    %00001010 : Push( 7    ); // bottom right
    %00001011 : Push( 9    ); // top bottom right
    %00001100 : Push( 3 ); // left right
    %00001101 : Push( 10   ); // top left right
    %00001110 : Push( 11   ); // bottom left right
    %00001111 : Push( 12   ); // top bottom left right
  end;

  if aRotation and %10000000 <> 0 then Push( 1, BR );
  if aRotation and %01000000 <> 0 then Push( 1, TR );
  if aRotation and %00100000 <> 0 then Push( 1, BL );
  if aRotation and %00010000 <> 0 then Push( 1, TL );
end;

procedure TDRLSpriteMap.PushSpriteTerrainPart( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aStart, aEnd : TVec2f );
var iColors   : TGLRawQColor;
    iLight    : TGLRawQColor;
    iPosition : TVec2i;
    iPa, iPb  : TVec2i;
    iLayer    : TSpriteDataSet;
    iEmissive : TColor;
  function BilinearLight( aPos : TVec2f ) : Byte;
  var iX1, iX2 : Single;
  begin
    iX1 := ( 1 - aPos.X ) * iLight.Data[0].X + aPos.X * iLight.Data[3].X;
    iX2 := ( 1 - aPos.X ) * iLight.Data[1].X + aPos.X * iLight.Data[2].X;
    Exit( Round( ( 1 - aPos.Y ) * iX1 + aPos.Y * iX2 ) );
  end;
begin
  iLayer := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iLight := GetTerrainLight( aCoord );
  iColors.Data[0] := TVec3b.CreateAll( BilinearLight( aStart ) );
  iColors.Data[1] := TVec3b.CreateAll( BilinearLight( TVec2f.Create( aStart.X, aEnd.Y ) ) );
  iColors.Data[2] := TVec3b.CreateAll( BilinearLight( aEnd ) );
  iColors.Data[3] := TVec3b.CreateAll( BilinearLight( TVec2f.Create( aEnd.X, aStart.Y ) ) );

  iPosition := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  iPa := iPosition + Vec2i( Round( aStart.X * FSpriteEngine.Grid.X ), Round( aStart.Y * FSpriteEngine.Grid.Y ) );
  iPb := iPosition + Vec2i( Round( aEnd.X * FSpriteEngine.Grid.X ), Round( aEnd.Y * FSpriteEngine.Grid.Y ) );
  iEmissive := aSprite.Emissive;
  if iEmissive.A = 0 then iEmissive := aSprite.Color;
  iLayer.PushPart( aSprite.SpriteID[0] mod 100000, iPa, iPb, @iColors, SpriteTint( aSprite ),
    ColorZero, iEmissive, aZ, aStart, aEnd );
end;

procedure TDRLSpriteMap.PushTarget( aSpriteID : DWord; aPosition : TVec2i; aColor : TColor; aSize : Float );
var iColors   : TGLRawQColor;
    iLayer    : TSpriteDataSet;
    iSpriteID : DWord;
    iHalf     : TVec2i;
    iGrid     : TVec2i;
    iExtra    : TVec2i;
  procedure PushPart( aPa, aPb : TVec2i; aStart, aEnd : TVec2f );
  begin
    iLayer.PushPart( iSpriteID, aPa, aPb, @iColors, aColor, ColorZero, aColor, DRL_Z_FX, aStart, aEnd );
  end;
begin
  iLayer    := FSpriteEngine.Layers[ aSpriteID div 100000 ];
  iSpriteID := aSpriteID mod 100000;

  if Abs( aSize - 1.0 ) < 0.001 then
  begin
    iLayer.PushXY( iSpriteID, 1, aPosition, ColorWhite, aColor, ColorZero, aColor, DRL_Z_FX );
    Exit;
  end;

  iColors.FillAll( 255 );
  iGrid  := FSpriteEngine.Grid;
  iHalf  := TVec2i.Create( iGrid.X div 2, iGrid.Y div 2 );
  iExtra := TVec2i.Create( Round( iGrid.X * ( aSize - 1.0 ) ), Round( iGrid.Y * ( aSize - 1.0 ) ) );

  PushPart(
    aPosition + TVec2i.Create( -iExtra.X div 2, -iExtra.Y ),
    aPosition + TVec2i.Create( iHalf.X - iExtra.X div 2, iHalf.Y - iExtra.Y ),
    TVec2f.Create( 0.0, 0.0 ), TVec2f.Create( 0.5, 0.5 )
  );
  PushPart(
    aPosition + TVec2i.Create( iHalf.X + iExtra.X div 2, -iExtra.Y ),
    aPosition + TVec2i.Create( iGrid.X + iExtra.X div 2, iHalf.Y - iExtra.Y ),
    TVec2f.Create( 0.5, 0.0 ), TVec2f.Create( 1.0, 0.5 )
  );
  PushPart(
    aPosition + TVec2i.Create( -iExtra.X div 2, iHalf.Y ),
    aPosition + TVec2i.Create( iHalf.X - iExtra.X div 2, iGrid.Y ),
    TVec2f.Create( 0.0, 0.5 ), TVec2f.Create( 0.5, 1.0 )
  );
  PushPart(
    aPosition + TVec2i.Create( iHalf.X + iExtra.X div 2, iHalf.Y ),
    aPosition + TVec2i.Create( iGrid.X + iExtra.X div 2, iGrid.Y ),
    TVec2f.Create( 0.5, 0.5 ), TVec2f.Create( 1.0, 1.0 )
  );
end;

procedure TDRLSpriteMap.PushBeingOverlay( aPos : TVec2i; aBeing : TBeing; aLight : Byte );
var iOverlay : TThing;
    iSprite  : TSprite;
    z        : Integer;
begin
  if aBeing = nil then Exit;
  iOverlay := aBeing.GetVisualOverlay;
  if iOverlay = nil then Exit;

  iSprite := aBeing.Sprite;
  iSprite.SpriteID[0] := iOverlay.Sprite.SpriteID[0];

  if ( aBeing.OverlayUntil > FIO.Time ) and ( SF_PAINANIM in iSprite.Flags ) then
  begin
    if SF_LARGE in iSprite.Flags then
      iSprite.SpriteID[0] += DRL_COLS * 2 * iSprite.Frames
    else
      iSprite.SpriteID[0] += DRL_COLS * iSprite.Frames;
  end
  else iSprite := GetSprite( iSprite, aBeing.Position );

  z := ( aPos.Y div FSpriteEngine.Grid.Y ) * DRL_Z_LINE;
  if SF_LARGE in iSprite.Flags then
    z += DRL_Z_LARGE
  else
    z += DRL_Z_BEINGS;
  PushSprite( aPos, iSprite, aLight, z + 1 );
end;

procedure TDRLSpriteMap.PushSpriteDoodad( aCoord : TCoord2D; const aSprite: TSprite; aLight: Integer; aZOffset : Integer );
var iLight  : Byte;
    iSprite : TSprite;
    iZ      : DWord;
begin
  iSprite := GetSprite( aSprite, aCoord );
  if aLight = -1 then
    iLight := VariableLight( aCoord )
  else
    iLight := Byte( aLight );
  if SF_COSPLAY in iSprite.Flags then
    iSprite.Color := ScaleColor( iSprite.Color, Byte(iLight) );
  iZ := aCoord.Y * DRL_Z_LINE + aZOffset;
  PushSprite( Vec2i( (aCoord.X-1)*FSpriteEngine.Grid.X, (aCoord.Y-1)*FSpriteEngine.Grid.Y ), iSprite, iLight, iZ + DRL_Z_DOODAD );
  if ( SF_HIGHSPRITE in aSprite.Flags ) and ( aCoord.y > 0 ) then
  begin
    iSprite := aSprite;
    iSprite.SpriteID[0] := iSprite.SpriteID[0] - DRL_COLS;
    Exclude( iSprite.Flags, SF_HIGHSPRITE );
    PushSpriteDoodad( NewCoord2D( aCoord.x, aCoord.y-1 ), iSprite, aLight, aZOffset );
  end;
end;

procedure TDRLSpriteMap.PushSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aTSX : Single; aTSY : Single );
var iColors   : TGLRawQColor;
    iPosition : TVec2i;
    iLayer    : TSpriteDataSet;
begin
  iLayer := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iColors := GetTerrainLight( aCoord );
  iPosition := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  iLayer.PushXY( aSprite.SpriteID[0] mod 100000, 1, iPosition, @iColors, SpriteTint( aSprite ),
    ColorZero, GetEmissive( aSprite ), aTSX, aTSY, aZ );
end;

procedure TDRLSpriteMap.SetTarget( aTarget : TCoord2D; aColor : TColor; aSource : TBeing = nil );
var iTargetLine  : TAssistedRay;
    iCurrent    : TCoord2D;
    iTargetRange : Byte;
begin
  FTargeting   := True;
  FTarget      := aTarget;
  FTargetColor := aColor;

  FTargetList.Clear;
  //FOldTargetList.Clear;

  if ( aSource <> nil ) and ( aSource.Position <> FTarget ) then
  begin
    iTargetRange := Distance( aSource.Position, FTarget );
    iTargetLine.Init( FLevel, aSource.Position, FTarget, iTargetRange, aSource.Vision, aSource.GetVisionMap );
    repeat
      iTargetLine.Next;
      iCurrent := iTargetLine.Current;

      if not iTargetLine.Done then
        FTargetList.Push( iCurrent );
    until (iTargetLine.Done) or (iTargetLine.Steps > 30);

    { TVisionRay comparison path, left here for later targeting tests.
    iTargetLine.Init( FLevel, aSource.Position, FTarget );
    repeat
      iTargetLine.Next;
      iCurrent := iTargetLine.Current;

      if not iTargetLine.Done then
        FOldTargetList.Push( iCurrent );
    until (iTargetLine.Done) or (iTargetLine.Steps > 30);
    }
  end;
  FTargetList.Push( FTarget );
end;

procedure TDRLSpriteMap.SetAutoTarget( aSource, aTarget : TCoord2D );
begin
  if aTarget = aSource
    then FAutoTarget.Create(0,0)
    else FAutoTarget := aTarget;
end;

procedure TDRLSpriteMap.ClearTarget;
begin
  FTargeting := False;
end;

procedure TDRLSpriteMap.ToggleGrid;
begin
  FGridActive     := not FGridActive;
end;

destructor TDRLSpriteMap.Destroy;
begin
  FreeAndNil( FTargetList );
  //FreeAndNil( FOldTargetList );
  inherited Destroy;
end;

procedure TDRLSpriteMap.ApplyEffect;
begin
  case FIO.StatusEffect of
    StatusRed    : FLutTexture := FTextures['lut_berserk'].GLTexture;
    StatusGreen  : FLutTexture := FTextures['lut_enviro'].GLTexture;
    StatusBlue   : FLutTexture := FTextures['lut_stealth'].GLTexture;
    StatusInvert : FLutTexture := FTextures['lut_iddqd'].GLTexture;
    StatusMagenta: FLutTexture := FTextures['lut_rage'].GLTexture;
    else
    begin
      if FGlow
        then FLutTexture := FTextures['lut_clear'].GLTexture
        else FLutTexture := 0;
    end;
  end;
end;

function TDRLSpriteMap.CellLightTarget( aCoord : TCoord2D ) : Single;
begin
  if not FVisualMap.Explored( aCoord ) then Exit( 0 );
  if not FVisualMap.Visible( aCoord ) then Exit( 70 );
  Exit( Min( 100 + FLevel.Vision.getLight( aCoord ) * 20, 255 ) );
end;

procedure TDRLSpriteMap.UpdateLightMap( aTime : DWord );
var Y,X   : DWord;
    iStep : Single;
    iGoal : Single;
  function Get( X, Y : Byte ) : Byte;
  begin
    if ( X < 1 ) or ( Y < 1 ) or ( X > MAXX ) or ( Y > MAXY ) then Exit( 0 );
    Exit( Round( FCellLight[X,Y] ) );
  end;

begin
  // Presented light moves to its value at a fixed rate, so vision changes fade.
  iStep := 255.0 * aTime / VisualLightFadeTime;
  for X := 1 to MAXX do
    for Y := 1 to MAXY do
    begin
      iGoal := CellLightTarget( NewCoord2D( X, Y ) );
      if FLightSnap then
        FCellLight[X,Y] := iGoal
      else if FCellLight[X,Y] < iGoal then
        FCellLight[X,Y] := Minf( FCellLight[X,Y] + iStep, iGoal )
      else
        FCellLight[X,Y] := Maxf( FCellLight[X,Y] - iStep, iGoal );
    end;
  FLightSnap := False;

  for X := 0 to MAXX do
    for Y := 0 to MAXY do
      if (X*Y = 0) or (X = MAXX) or (Y = MAXY) then
        FLightMap[X,Y] := 0
      else
      begin
        FLightMap[X,Y] := ( Get(X,Y) + Get(X,Y+1) + Get(X+1,Y) + Get(X+1,Y+1) ) div 4;
      end;
end;

function TDRLSpriteMap.GetExploredTerrainCell( aCoord : TCoord2D ) : Byte;
var iCell : TDRLVisualCell;
begin
  if not FLevel.isProperCoord( aCoord ) then Exit( 0 );
  iCell := VCell( aCoord );
  if iCell.Flags and VCF_EXPLORED = 0 then Exit( 0 );
  Result := iCell.Bottom;
end;

function TDRLSpriteMap.GetTerrainLight( aCoord : TCoord2D ) : TGLRawQColor;
begin
  Result.Data[0] := TVec3b.CreateAll( FLightMap[aCoord.X-1,aCoord.Y-1] );
  Result.Data[1] := TVec3b.CreateAll( FLightMap[aCoord.X-1,aCoord.Y] );
  Result.Data[2] := TVec3b.CreateAll( FLightMap[aCoord.X,aCoord.Y] );
  Result.Data[3] := TVec3b.CreateAll( FLightMap[aCoord.X,aCoord.Y-1] );
end;

function TDRLSpriteMap.GetTransitionMaterial( const aSprite : TSprite ) : TSpriteTransitionMaterial;
begin
  Result.SpriteID := aSprite.SpriteID[0] mod 100000;
  Result.Color := SpriteTint( aSprite );
  // Terrain ignores the tint alpha; normalize it for surface identity too.
  Result.Color.A := 255;
  Result.Emissive := GetEmissive( aSprite );
  Result.Shift := TVec2f.Create( 0, 0 );
end;

function TDRLSpriteMap.GetTerrainSprite( aCoord : TCoord2D; aCell : Byte; out aDeco : Byte ) : TSprite;
var iCell  : TCell;
    iColor : TColor;
    iState : TDRLVisualCell;
begin
  iState := VCell( aCoord );
  Result := GetSprite( aCell, iState.Style );
  aDeco := iState.Deco;
  if (aDeco > 0) and (SF_FULLDECO in Result.Flags) then
  begin
    iCell := FLevel.Data.Cells[aCell];
    if iCell.Deco[aDeco].SpriteID[0] = 0 then Exit;
    if SF_COSPLAY in Result.Flags then
    begin
      iColor := Result.Color;
      Result := iCell.Deco[aDeco];
      Result.Color := iColor;
      Include( Result.Flags, SF_COSPLAY );
    end
    else
      Result := iCell.Deco[aDeco];
    aDeco := 0;
  end;
end;

function TDRLSpriteMap.PushFluidTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
const FluidMixWidth = 8.0;
var iSurfaces  : array[0..2,0..2] of TSpriteTransitionMaterial;
    iEligible  : array[0..2,0..2] of Boolean;
    iDifferent : Boolean;
    iPatches   : array[0..3] of TSpriteTransitionMaterials;
    iMasks     : array[0..3] of Byte;
    iLight     : TGLRawQColor;
    iNeighbour : TCoord2D;
    iSprite    : TSprite;
    iLayer     : TSpriteDataSet;
    iLayerID   : DWord;
    iBottom    : Byte;
    iDeco      : Byte;
    iMask      : Byte;
    iX, iY     : Integer;
    iQX, iQY   : Integer;
    iQ, iSlot  : Integer;

    function Material( const aSurface : TSprite ) : TSpriteTransitionMaterial;
    begin
      Assert( aSurface.SpriteID[0] div 100000 = iLayerID, 'Mixing fluids must share a spritesheet' );
      Result := GetTransitionMaterial( aSurface );
      if SF_FLOW in aSurface.Flags then
        Result.Shift := TVec2f.Create( FFluidX, FFluidY );
    end;

begin
  Result := False;
  iLayerID := aSprite.SpriteID[0] div 100000;
  FillChar( iEligible, SizeOf( iEligible ), 0 );
  iDifferent := False;
  iSurfaces[1,1] := Material( aSprite );
  iEligible[1,1] := True;
  // One small value snapshot per tile; all four patches reuse these neighbours.
  for iY := 0 to 2 do
    for iX := 0 to 2 do
    begin
      if (iX = 1) and (iY = 1) then Continue;
      iNeighbour.Create( aCoord.X+iX-1, aCoord.Y+iY-1 );
      iBottom := GetExploredTerrainCell( iNeighbour );
      if iBottom = 0 then Continue;
      if not (CF_LIQUID in FLevel.Data.Cells[iBottom].Flags) then Continue;
      iSprite := GetTerrainSprite( iNeighbour, iBottom, iDeco );
      if not (SF_FLUID in iSprite.Flags) then Continue;
      iSurfaces[iX,iY] := Material( iSprite );
      if not iDifferent then
        iDifferent := iSurfaces[iX,iY].Compare( iSurfaces[1,1] ) <> 0;
      iEligible[iX,iY] := True;
    end;

  // Uniform neighbourhoods need neither patch masks nor transition geometry.
  if not iDifferent then Exit;

  for iQ := 0 to 3 do
  begin
    iQX := iQ and 1;
    iQY := iQ shr 1;
    iMask := 0;
    for iSlot := 0 to 3 do
    begin
      iX := iQX + (iSlot and 1);
      iY := iQY + (iSlot shr 1);
      // Initialize excluded slots as well; only the mask gives them weight.
      iPatches[iQ][iSlot] := iSurfaces[1,1];
      if not iEligible[iX,iY] then Continue;
      iPatches[iQ][iSlot] := iSurfaces[iX,iY];
      iMask := iMask or (1 shl iSlot);
    end;
    iMask := ConnectedTransitionMask( iMask, iQ );
    iMasks[iQ] := iMask;
    for iSlot := 0 to 3 do
      if ((iMask and (1 shl iSlot)) <> 0) and
         (iPatches[iQ][iSlot].Compare( iSurfaces[1,1] ) <> 0) then Result := True;
  end;
  if not Result then Exit;

  iLight := GetTerrainLight( aCoord );
  iLayer := FSpriteEngine.Layers[iLayerID];
  for iQ := 0 to 3 do
    iLayer.PushTransition( aCoord, iQ, iMasks[iQ], iPatches[iQ], iLight, aZ, FluidMixWidth );
end;

function TDRLSpriteMap.PushWallDebrisTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
const WallDebrisMixWidth = 4.0;
type TSurfaceKind = (skNone, skWall, skDebris);
     TSurface = record
       Kind     : TSurfaceKind;
       Material : TSpriteTransitionMaterial;
       Rotation : Byte;
       Pieces   : TMultiSpritePieces;
     end;
var iSurfaces  : array[0..2,0..2] of TSurface;
    iLight     : TGLRawQColor;
    iLayer     : TSpriteDataSet;
    iLayerID   : DWord;
    iNeighbour : TCoord2D;
    iSprite    : TSprite;
    iOwnKind   : TSurfaceKind;
    iCell      : Byte;
    iDeco      : Byte;
    iMask      : Byte;
    iX, iY     : Integer;
    iQ, iSlot  : Integer;
    iQX, iQY   : Integer;
    iBand      : Integer;

  function SurfaceKind( aCell : Byte; const aSurface : TSprite ) : TSurfaceKind;
  begin
    if not (SF_MULTI in aSurface.Flags) then Exit( skNone );
    // Wall debris uses the wall layout with a floor beneath its transparent pixels.
    if SF_FLOOR in aSurface.Flags then Exit( skDebris );
    if CF_STICKWALL in FLevel.Data.Cells[aCell].Flags then Exit( skWall );
    Result := skNone;
  end;

  procedure ResolveNeighbourPieces( var aSurface : TSurface );
  var iPiece : Integer;
  begin
    if aSurface.Kind = skWall then
    begin
      // Extend the wall's interior into debris without repeating its bright rim.
      for iPiece := 0 to 3 do
        aSurface.Pieces[iPiece] := MultiSpriteInterior( aSurface.Material.SpriteID );
    end
    else
      GetMultiSpritePieces( aSurface.Material.SpriteID, aSurface.Rotation, aSurface.Pieces );
  end;

  function PieceMaterial( const aSurface : TSurface; aPiece : Integer ) : TSpriteTransitionMaterial;
  begin
    Result := aSurface.Material;
    Result.SpriteID := aSurface.Pieces[aPiece];
  end;

  procedure PushPatch( aQuadrant, aBand : Integer; aMask : Byte );
  var iMaterials  : TSpriteTransitionMaterials;
      iMaterial   : TSpriteTransitionMaterial;
      iQX, iQY    : Integer;
      iX, iY      : Integer;
      iSlot       : Integer;
      iPiece      : Integer;
      iStart,iEnd : TVec2f;
  begin
    iQX := aQuadrant and 1;
    iQY := aQuadrant shr 1;
    iPiece := iQX + 2*aBand;
    iMaterial := PieceMaterial( iSurfaces[1,1], iPiece );
    for iSlot := 0 to 3 do
    begin
      iX := iQX + (iSlot and 1);
      iY := iQY + (iSlot shr 1);
      iMaterials[iSlot] := iMaterial;
      // Different wall styles must not acquire wall-to-wall transitions.
      if ((aMask and (1 shl iSlot)) <> 0) and (iSurfaces[iX,iY].Kind <> iOwnKind) then
        iMaterials[iSlot] := PieceMaterial( iSurfaces[iX,iY], iPiece );
    end;
    iStart := TVec2f.Create( iQX*0.5, iQY*0.5 );
    iEnd := TVec2f.Create( (iQX+1)*0.5, (iQY+1)*0.5 );
    // Wall tops end at 8/32, inside the upper transition quadrants.
    if iQY = 0 then
      if aBand = 0 then iEnd.Y := WallSpriteTop else iStart.Y := WallSpriteTop;
    iLayer.PushTransitionPart( aCoord, aQuadrant, aMask, iMaterials, iLight, aZ,
      WallDebrisMixWidth, iStart, iEnd );
  end;

begin
  Result := False;
  iOwnKind := SurfaceKind( VCell( aCoord ).Bottom, aSprite );
  if iOwnKind = skNone then Exit;
  iLayerID := aSprite.SpriteID[0] div 100000;
  iLayer := FSpriteEngine.Layers[iLayerID];
  if not iLayer.SupportsTransitions then Exit;
  FillChar( iSurfaces, SizeOf( iSurfaces ), 0 );
  iSurfaces[1,1].Kind := iOwnKind;
  iSurfaces[1,1].Material := GetTransitionMaterial( aSprite );
  iSurfaces[1,1].Rotation := VCell( aCoord ).Rotation;
  for iY := 0 to 2 do
    for iX := 0 to 2 do
    begin
      if (iX = 1) and (iY = 1) then Continue;
      iNeighbour.Create( aCoord.X+iX-1, aCoord.Y+iY-1 );
      iCell := GetExploredTerrainCell( iNeighbour );
      if iCell = 0 then Continue;
      iSprite := GetTerrainSprite( iNeighbour, iCell, iDeco );
      if iSprite.SpriteID[0] div 100000 <> iLayerID then Continue;
      iSurfaces[iX,iY].Kind := SurfaceKind( iCell, iSprite );
      if (iSurfaces[iX,iY].Kind = skNone) or (iSurfaces[iX,iY].Kind = iOwnKind) then Continue;
      iSurfaces[iX,iY].Material := GetTransitionMaterial( iSprite );
      iSurfaces[iX,iY].Rotation := VCell( iNeighbour ).Rotation;
      if (iX = 1) or (iY = 1) then Result := True;
    end;
  // Only tiles sharing an edge with the opposite kind need transition geometry.
  if not Result then Exit;

  GetMultiSpritePieces( iSurfaces[1,1].Material.SpriteID, iSurfaces[1,1].Rotation, iSurfaces[1,1].Pieces );
  for iY := 0 to 2 do
    for iX := 0 to 2 do
      if (iSurfaces[iX,iY].Kind <> skNone) and (iSurfaces[iX,iY].Kind <> iOwnKind) then
        ResolveNeighbourPieces( iSurfaces[iX,iY] );

  iLight := GetTerrainLight( aCoord );
  for iQ := 0 to 3 do
  begin
    iQX := iQ and 1;
    iQY := iQ shr 1;
    iMask := 0;
    for iSlot := 0 to 3 do
      if iSurfaces[iQX+(iSlot and 1),iQY+(iSlot shr 1)].Kind <> skNone then
        iMask := iMask or (1 shl iSlot);
    iMask := ConnectedTransitionMask( iMask, iQ );
    for iBand := iQY to 1 do
      PushPatch( iQ, iBand, iMask );
  end;
end;

procedure TDRLSpriteMap.PushTerrain;
var iDMinX    : Word;
    iDMaxX    : Word;
    iY,iX     : DWord;
    iCoord    : TCoord2D;
    iProgress : Single;
begin
  iDMinX := FShift.X div FSpriteEngine.Grid.X + 1;
  iDMaxX := Min(FShift.X div FSpriteEngine.Grid.X + (FDriver.GetSizeX div FSpriteEngine.Grid.X + 1),MAXX);

  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    begin
      iCoord.Create(iX,iY);
      // A tile drawn from a fading neighbourhood is drawn from both states,
      // each on its share of game pixels.
      if FVisualMap.NeighbourhoodFade( iCoord, iProgress ) then
      begin
        FLayer := vlShown;
        FSpriteEngine.SetDither( sdOutgoing, iProgress );
        PushCell( iCoord );
        FLayer := vlTarget;
        FSpriteEngine.SetDither( sdIncoming, iProgress );
        PushCell( iCoord );
        FSpriteEngine.SetDither( sdNone );
      end
      else
        PushCell( iCoord );
    end;
end;

procedure TDRLSpriteMap.PushCell( aCoord : TCoord2D );
var iBottom    : Word;
    iTop       : Word;
    iZ         : Integer;
    iSpr       : TSprite;
    iFSpr      : TSprite;
    iState     : TDRLVisualCell;
    iDeco      : Byte;
    iFloor     : Byte;
    iCell      : TCell;
    iColor     : TColor;
    iMixFluids : Boolean;
    iMixedWall : Boolean;
    iNewLayout : Boolean;
begin
  iState := VCell( aCoord );
  if iState.Flags and VCF_EXPLORED = 0 then Exit;
  iMixFluids := not FLevel.Flags[ LF_SHARPFLUID ];
  iNewLayout := FLevel.Data.Rules.NewFloorLayout;
  iZ         := aCoord.Y * DRL_Z_LINE;
  iBottom := iState.Bottom;
  if iBottom <> 0 then
  begin
    iSpr := GetTerrainSprite( aCoord, iBottom, iDeco );
    iMixedWall := (SF_MULTI in iSpr.Flags) and PushWallDebrisTerrain( aCoord, iSpr, iZ );
    if not iMixedWall and not (iMixFluids and (CF_LIQUID in FLevel.Data.Cells[iBottom].Flags) and
      (SF_FLUID in iSpr.Flags) and PushFluidTerrain( aCoord, iSpr, iZ )) then
      if SF_FLOW in iSpr.Flags
        then PushSpriteTerrain( aCoord, iSpr, iZ, FFluidX, FFluidY )
        else
        begin
          if SF_MULTI in iSpr.Flags then
            PushMultiSpriteTerrain( aCoord, iSpr, iZ, iState.Rotation )
          else
            PushSpriteTerrain( aCoord, iSpr, iZ );
        end;
    if (SF_FLUID in iSpr.Flags) and (iState.Rotation <> 0) then
    begin
      iFloor := iState.Floor;
      if iFloor <> 0 then
      begin
        iFSpr := GetSprite( iFloor, iState.FStyle );
        if SF_HASALTEDGE in iFSpr.Flags then
          if SF_USEALTEDGE in iSpr.Flags then
            iFSpr.SpriteID[0] += DRL_COLS;
        if SF_HASALTEDGE2 in iFSpr.Flags then
          if SF_USEALTEDGE2 in iSpr.Flags then
            iFSpr.SpriteID[0] += 2*DRL_COLS;
        if iNewLayout
          then PushFloorTerrainNewLayout( aCoord, iFSpr, iZ + DRL_Z_ENVIRO, iState.Rotation )
          else
          begin
            iFSpr.SpriteID[0] += iState.Rotation;
            PushSpriteTerrain( aCoord, iFSpr, iZ + DRL_Z_ENVIRO );
          end;
      end;
    end;
    if iDeco <> 0 then
    begin
      iCell := FLevel.Data.Cells[ iBottom ];
      if iCell.Deco[ iDeco ].SpriteID[0] <> 0 then
      begin
        if SF_COSPLAY in iSpr.Flags then
        begin
          iColor     := iSpr.Color;
          iSpr       := GetSprite( iCell.Deco[ iDeco ], aCoord );
          iSpr.Color := iColor;
          Include( iSpr.Flags, SF_COSPLAY );
        end
        else
          iSpr := GetSprite( iCell.Deco[ iDeco ], aCoord );
        PushSpriteTerrain( aCoord, iSpr, iZ + DRL_Z_ENVIRO + 1 );
      end;
    end;
    if (SF_FLOOR in iSpr.Flags) or iMixedWall then
    begin
      iFloor := iState.Floor;
      if iFloor <> 0 then
      begin
        iSpr := GetSprite( iFloor, iState.FStyle );
        PushSpriteTerrain( aCoord, iSpr, iZ - 1 );
      end;
    end;
  end;

  // The top layer; a clip drawing it covers the cell.
  iTop := iState.Top;
  if ( iTop = 0 ) or FVisualMap.Covered( aCoord ) then Exit;
  if CF_STAIRS in FLevel.Data.Cells[iTop].Flags then
    PushSpriteDoodad( aCoord, FLevel.Data.Cells[iTop].Sprite[0], 255 )
  else
  begin
    iSpr := GetSprite( iTop, iState.Style );
    if ( SF_DOORHACK in iSpr.Flags ) and ( iState.Rotation > 0 ) then
    begin
      iSpr.SpriteID[0] := iSpr.SpriteID[ iSpr.SCount div 2 ];
      Include( iSpr.Flags, SF_HIGHSPRITE );
    end;
    PushSpriteDoodad( aCoord, iSpr );
    iDeco := iState.Deco;
    if iDeco <> 0 then
    begin
      iCell := FLevel.Data.Cells[ iTop ];
      if iCell.Deco[ iDeco ].SpriteID[0] <> 0 then
        PushSpriteDoodad( aCoord, iCell.Deco[ iDeco ], -1, 1 );
    end;
  end;
end;

procedure TDRLSpriteMap.PushPresentedBeing( const aCoord : TCoord2D; aBeing : TBeing; const aSprite : TSprite );
var iPosition : TVec2i;
    iLight    : Integer;
begin
  iPosition := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  if FVisualMap.Visible( aCoord ) then iLight := VariableLight( aCoord, 30 )
  else if ( aBeing <> nil ) and FLevel.BeingExplored( aCoord, aBeing ) then iLight := 40
  else
  begin
    if ( aBeing <> nil ) and FLevel.BeingIntuited( aCoord, aBeing ) then
      with FSpriteEngine.Layers[ FIO.EngineSprites.Mark div 100000 ] do
        Push( FIO.EngineSprites.Mark mod 100000, aCoord, ColorWhite, NewColor( Magenta ), ColorZero, NewColor( Magenta ), DRL_Z_FX-1 );
    Exit;
  end;
  if aBeing <> nil then
  begin
    PushSprite( iPosition, GetBeingSprite( aBeing ), iLight, aCoord.Y * DRL_Z_LINE + DRL_Z_BEINGS );
    PushBeingOverlay( iPosition, aBeing, iLight );
  end
  else
    PushSprite( iPosition, GetSprite( aSprite, aCoord ), iLight, aCoord.Y * DRL_Z_LINE + DRL_Z_BEINGS );
end;

procedure TDRLSpriteMap.PushPresentedItem( const aCoord : TCoord2D; aItem : TItem; const aSprite : TSprite; aDTime : Integer );
var iVisible : Boolean;
    iLight   : Integer;
    iOff     : Integer;
    iD       : Single;
    iRange   : Single;
begin
  // Sight of the cell comes from the presented level; other ways of seeing
  // the item from the live one.
  iVisible := FVisualMap.Visible( aCoord );
  if not iVisible then
    iVisible := ( aItem <> nil ) and ( not FLevel.isVisible( aCoord ) ) and FLevel.ItemVisible( aCoord, aItem );
  if not ( iVisible or FVisualMap.Explored( aCoord ) ) then Exit;
  iOff := 0;
  if ( aItem <> nil ) and ( aItem.Appear > 0 ) then
  begin
    if ( aItem.Appear < 500 ) and FIO.Settings.ItemDropAnimation then
    begin
      iRange := 6.0 * FSpriteEngine.Scale;
      aItem.Appear := Min( aItem.Appear + aDTime, 500 );
      iD := aItem.Appear / 500;
      iOff := Round( -iRange + iRange * ( 1.0 - Exp( -5.0 * iD ) * Cos( 4.0 * Pi * iD ) ) );
    end
    else aItem.Appear := 0;
  end;
  iLight := 70;
  if iVisible then
  begin
    iLight := 255;
    if ( aItem <> nil ) and aItem.isFeature then iLight := VariableLight( aCoord );
  end;
  PushSprite( Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid + Vec2i( 0, iOff ), GetSprite( aSprite, aCoord ),
    iLight, aCoord.Y * DRL_Z_LINE + DRL_Z_ITEMS );
end;

function TDRLSpriteMap.PresentedPosition( aUID : TUID; out aPosition : TVec2f ) : Boolean;
var iClip  : TGFXThingAnimation;
    iThing : TThing;
begin
  aPosition := Vec2f( 0, 0 );
  iClip := ThingAnimation( FAnimations, aUID );
  if iClip <> nil then Exit( iClip.Position( aPosition ) );
  iThing := FLevel.Context.UIDs.Get( aUID ) as TThing;
  if ( iThing = nil ) or ( iThing.Parent <> FLevel ) or ( ( iThing is TBeing ) and TBeing( iThing ).Killed ) then
    Exit( False );
  aPosition := Vec2f( iThing.Position.X - 1, iThing.Position.Y - 1 );
  Exit( True );
end;

procedure TDRLSpriteMap.PushThings( aDTime : Integer );
var iNode      : TNode;
    iThing     : TThing;
    iAnimation : TAnimation;
    iClip      : TGFXThingAnimation;
begin
  // Things a clip claims are drawn through that clip.
  for iAnimation in FAnimations.Animations do
    if iAnimation is TGFXThingAnimation then
    begin
      iClip := TGFXThingAnimation( iAnimation );
      if ThingAnimation( FAnimations, iClip.Thing ) = iClip then iClip.PushThing;
    end;
  // The other things of the level; a killed being is shown only by its
  // death clip.
  for iNode in FLevel do
    if iNode is TThing then
    begin
      iThing := TThing( iNode );
      if not FLevel.isProperCoord( iThing.Position ) then Continue;
      if ( iThing is TBeing ) and TBeing( iThing ).Killed then Continue;
      if ThingAnimation( FAnimations, iThing.UID ) <> nil then Continue;
      if iThing is TBeing then
        PushPresentedBeing( iThing.Position, TBeing( iThing ), iThing.Sprite )
      else if iThing is TItem then
        PushPresentedItem( iThing.Position, TItem( iThing ), iThing.Sprite, aDTime );
    end;
end;

procedure TDRLSpriteMap.PushObjects;
var iDMinX   : Word;
    iDMaxX   : Word;
    iY,iX    : DWord;
    iL       : DWord;
    iV       : TVec2i;
    iBeing   : TBeing;
    iClip    : TGFXThingAnimation;
    iPos     : TVec2f;
    iColor   : TColor;
begin
  iDMinX := FShift.X div FSpriteEngine.Grid.X + 1;
  iDMaxX := Min(FShift.X div FSpriteEngine.Grid.X + (FDriver.GetSizeX div FSpriteEngine.Grid.X + 1),MAXX);

  if FTargeting then
    begin
      iColor := NewColor( 0, 128, 0 );
      if FTargetList.Size > 0 then
      for iL := 0 to FTargetList.Size-1 do
      begin
        if (not FLevel.isVisible( FTargetList[iL] )) or
           (not FLevel.isShotPassable( FTargetList[iL] )) then
          iColor := NewColor( 128, 0, 0 );
        with FSpriteEngine.Layers[ FIO.EngineSprites.Select div 100000 ] do
          Push( FIO.EngineSprites.Select mod 100000, FTargetList[iL], ColorWhite, iColor, ColorZero, iColor, DRL_Z_FX );
      end;
      {
      iColor := NewColor( 0, 96, 192 );
      if FOldTargetList.Size > 0 then
      for iL := 0 to FOldTargetList.Size-1 do
      begin
        if (not FLevel.isVisible( FOldTargetList[iL] )) or
           (not FLevel.isShotPassable( FOldTargetList[iL] )) then
          iColor := NewColor( 128, 0, 128 );
        with FSpriteEngine.Layers[ FIO.EngineSprites.Mark div 100000 ] do
          Push( FIO.EngineSprites.Mark mod 100000, FOldTargetList[iL], ColorWhite, iColor, ColorZero, iColor, DRL_Z_FX+1 );
      end;
      }
      if FTargetList.Size > 0 then
        with FSpriteEngine.Layers[ FIO.EngineSprites.Mark div 100000 ] do
          Push( FIO.EngineSprites.Mark mod 100000, FTarget, ColorWhite, FTargetColor, ColorZero, FTargetColor, DRL_Z_FX );
    end
  else
    if FAutoTarget.X * FAutoTarget.Y <> 0 then
    begin
      iBeing  := FLevel.Being[FAutoTarget];
      iV      := Vec2i( FAutoTarget.X-1, FAutoTarget.Y-1 ) * FSpriteEngine.Grid;
      iClip := nil;
      // The target follows its being as it is presented.
      if iBeing <> nil then
      begin
        iClip := ThingAnimation( FAnimations, iBeing.UID );
        if PresentedPosition( iBeing.UID, iPos ) then iV := PixelPosition( iPos );
      end;
      if ( iBeing <> nil ) and ( iBeing.isVisible or ( ( iClip <> nil ) and not ( iClip is TGFXAppearAnimation ) ) )
        then PushTarget( FIO.EngineSprites.Select, iV, NewColor( Yellow ), 1.0 + iBeing.TargetSize * 0.1 )
        else PushTarget( FIO.EngineSprites.Select, iV, NewColor( Yellow ), 1.0 );
    end;

  if FGridActive then
  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    with FSpriteEngine.Layers[ FIO.EngineSprites.Grid div 100000 ] do
      Push( FIO.EngineSprites.Grid mod 100000, NewCoord2D( iX, iY ), NewColor( 50, 50, 50, 50 ), ColorBlack, ColorZero, ColorBlack, DRL_Z_ITEMS );

end;

procedure TDRLSpriteMap.PushDecals( aDarkness : Boolean );
var iData  : TDecalArray;
    iDecal : TDecal;
    iPos   : TVec2i;
    iCoord : TCoord2D;
    iLight : Byte;
//    iLQuad : TGLRawQColor;
  function GetLight( aPos : TVec2i ) : Byte;
  var iCoord   : TCoord2D;
  var iX1, iX2 : Single;
      iFPos     : TVec2f;
  begin
    iCoord.X := aPos.X div 32;
    iCoord.Y := aPos.Y div 32;
    iFPos.Init( ( aPos.X mod 32 ) / 32.0, ( aPos.Y mod 32 ) / 32.0 );
    iX1 := ( 1 - iFPos.X ) * FLightMap[ iCoord.X-1,iCoord.Y-1 ] + iFPos.X * FLightMap[ iCoord.X  ,iCoord.Y-1 ];
    iX2 := ( 1 - iFPos.X ) * FLightMap[ iCoord.X-1,iCoord.Y   ] + iFPos.X * FLightMap[ iCoord.X  ,iCoord.Y   ];
    Exit( Round( ( 1 - iFPos.Y ) * iX1 + iFPos.Y * iX2 ) );
  end;

  begin
  iData := FLevel.Decals.Data;
  for iDecal in iData do
  begin
    iCoord := NewCoord2D( ( iDecal.Position.X + 16 ) div 32, ( iDecal.Position.Y + 16 ) div 32 );
    if ( not FLevel.isProperCoord( iCoord ) ) or ( aDarkness and ( not FVisualMap.Visible( iCoord ) ) ) or ( not FVisualMap.Explored( iCoord ) ) then
      Continue;

    iPos.Init( Floor( ( iDecal.Position.X - 32 ) * FSpriteEngine.Scale ), Floor( ( iDecal.Position.Y - 32 ) * FSpriteEngine.Scale ) );
    iLight := GetLight( Vec2i( iDecal.Position.X + 16, iDecal.Position.Y + 16 ) );

//  iColors.Data[0] := BilinearLight( iStart );
//  iColors.Data[1] := BilinearLight( TVec2f.Create( iStart.X, iEnd.Y ) );
//  iColors.Data[2] := BilinearLight( iEnd );
//  iColors.Data[3] := BilinearLight( TVec2f.Create( iEnd.X, iStart.Y ) );
//    iLQuad.Data[0] := TVec3b.Create( iLight, iLight, iLight );
//    iLQuad.Data[1] := TVec3b.Create( iLight, iLight, iLight );
//    iLQuad.Data[2] := TVec3b.Create( iLight, iLight, iLight );
//    iLQuad.Data[3] := TVec3b.Create( iLight, iLight, iLight );

    with FSpriteEngine.Layers[ iDecal.Sprite div 100000 ] do
      PushXY( iDecal.Sprite mod 100000, 1, iPos, NewColor( iLight, iLight, iLight ), ColorZero, ColorBlack, ColorZero, DRL_Z_DECAL )
  end;
end;

function TDRLSpriteMap.VariableLight( aWhere: TCoord2D; aBonus : ShortInt = 0 ): Byte;
begin
  if not FLevel.isProperCoord( aWhere ) then Exit( 70 );
  if not FVisualMap.Visible( aWhere ) then aBonus := 0;
  // Unexplored cells only reach this through things revealed some other way.
  Exit( Min( Max( Round( FCellLight[aWhere.X,aWhere.Y] ), 70 ) + aBonus, 255 ) );
end;

function TDRLSpriteMap.GetBeingSprite( aBeing : TBeing ) : TSprite;
begin
  Assert( Assigned( aBeing ) );
  Result := aBeing.Sprite;
  if (aBeing.OverlayUntil > FIO.Time) and (SF_PAINANIM in Result.Flags) then
  begin
    if SF_LARGE in Result.Flags then
      Result.SpriteID[0] += DRL_COLS * 2 * Result.Frames
    else
      Result.SpriteID[0] += DRL_COLS * Result.Frames;
  end
  else Exit( GetSprite( Result, aBeing.Position ) );
end;

function TDRLSpriteMap.GetSprite( aCell, aStyle : Byte ) : TSprite;
var iCell  : TCell;
begin
  iCell   := FLevel.Data.Cells[ aCell ];
  if iCell.Sprite[ aStyle ].SpriteID[0] <> 0 then
    Exit( iCell.Sprite[ aStyle ] );
  Exit( iCell.Sprite[ 0 ] );
end;

end.
