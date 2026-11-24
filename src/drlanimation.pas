{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlanimation;
interface
uses
  classes, sysutils, math,
  vnode, vuid, vutil, vcolor, vmath, vvector, vrltools, vvision, vanimation, vrandom, viotypes, vglquadrenderer,
  dfdata, dflevel, drlparticles, drlio, drlspritemapbase, drlspritemap, drlvisual;

type TAnimation        = vanimation.TAnimation;
     TAnimationManager = vanimation.TAnimations;

{ TGFXAnimation }

// Base for animations drawn through the graphics IO's sprite map.
TGFXAnimation = class(TAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aDuration : DWord; aDelay : DWord; aUID : TUID );
protected
  FSpriteMap : TSpriteMap; // Borrowed from the graphics IO, which owns its animations.
end;

{ TGFXLevelAnimation }

// Base for animations that also draw level content (lighting, beings,
// doodads) through DRL's sprite map.
TGFXLevelAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TDRLSpriteMap; aDuration : DWord; aDelay : DWord; aUID : TUID );
protected
  FLevelMap : TDRLSpriteMap; // The same map as FSpriteMap, typed for level drawing.
end;

{ TGFXMissileAnimation }

TGFXMissileAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aLevel : TLevel; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False; aTrailNID : Word = 0 );
  procedure OnUpdate( aTime : DWord ); override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FLevel     : TLevel;
  FVisualMap : TDRLVisualMap; // Borrowed from the IO, which clears its animations first.
  FSource    : TVec2i;
  FTarget    : TVec2i;
  FPath      : TVisionRay;
  FHeading   : Float;
  FRay       : Boolean;
  FSprite    : TSprite;
  FStepDelay : DWord;
  FStep      : Word;
  FEmitter   : Integer;
end;

{ TMessageAnimation }

{TMessageAnimation = class(TAnimation)
  constructor Create( aMessage : Ansistring );
  procedure OnDraw; override;
private
  FMessage : AnsiString;
end;}

{ TGFXMarkAnimation }

// Drawn while its cell is presented as visible, or always if aVisualMap is nil.
TGFXMarkAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
  procedure OnDraw; override;
private
  FVisualMap : TDRLVisualMap; // Borrowed from the IO, which clears its animations first.
  FSprite    : TSprite;
  FCoord     : TCoord2D;
end;

{ TGFXFXAnimation }

TGFXFXAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
  procedure OnDraw; override;
private
  FSprite : TSprite;
  FCoord  : TCoord2D;
end;

{ TGFXExplodeMarkAnimation }

// Drawn while its cell is presented as visible, or always if aVisualMap is nil.
TGFXExplodeMarkAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aColor : Byte; aSprite : DWord );
  procedure OnDraw; override;
private
  FVisualMap : TDRLVisualMap; // Borrowed from the IO, which clears its animations first.
  FSprite    : DWord;
  FCoord     : TCoord2D;
  FGColor1   : TColor;
  FGColor2   : TColor;
  FGColor3   : TColor;
end;

{ TSoundEventAnimation }

TSoundEventAnimation = class(TAnimation)
  constructor Create( aIO : TDRLIO; aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord );
  procedure OnStart; override;
private
  FIO       : TDRLIO; // Borrowed from IO, which owns its animations.
  FPosition : TCoord2D;
  FSoundID  : DWord;
end;

{ TGFXParticleBurstAnimation }

TGFXParticleBurstAnimation = class(TAnimation)
  constructor Create( aParticles : TParticleStore; aDelay : DWord; aEmitterID : Word; aPosition : TCoord2D;
    aDirection : TDirection; aCount : Word; aDistanceScale, aSpreadScale : Single; const aDecals : TDecalSprites );
  procedure OnStart; override;
private
  FParticles     : TParticleStore;
  FDecals        : TDecalSprites;
  FEmitterID     : Word;
  FPosition      : TCoord2D;
  FDirection     : TDirection;
  FCount         : Word;
  FDistanceScale : Single;
  FSpreadScale   : Single;
end;

{ TGFXBlinkAnimation }

TGFXBlinkAnimation = class(TAnimation)
  constructor Create( aSheet : TGLQuadList; aDriver : TIODriver; aDuration : DWord; aDelay : DWord; aColor : Word );
  procedure OnDraw; override;
private
  FSheet    : TGLQuadList; // Borrowed from the graphics IO, which owns its animations.
  FDriver   : TIODriver;   // Borrowed from the graphics IO.
  FGColor   : TColor;
end;

{ TRumbleEventAnimation }

TRumbleEventAnimation = class(TAnimation)
  constructor Create( aDriver : TIODriver; aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
  procedure OnStart; override;
private
  FDriver : TIODriver; // Borrowed from IO, which owns its animations.
  FLow    : Word;
  FHigh   : Word;
  FDur    : DWord;
end;

{ TGFXMoveAnimation }

// Moves a visual thing, which it owns from creation: until it starts, the
// thing stays where it is presented.
TGFXMoveAnimation = class(TGFXLevelAnimation)
  constructor Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aThings : TDRLVisualThings; aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aBeing : Boolean; aPartial : Single = 0.0; aFinishBeforeNext : Boolean = False );
  procedure OnUpdate( aTime : DWord ); override;
  destructor Destroy; override;
protected
  function TryBlend( aAnimation : TAnimation ) : Boolean; override;
private
  FThings        : TDRLVisualThings; // Borrowed from the IO, which clears its animations first.
  FThing         : TDRLVisualThing;
  FLightStart    : Byte;
  FLightEnd      : Byte;
  FPosition      : TVec2f;
  FSource        : TVec2f;
  FTarget        : TVec2f;
  FBeing         : Boolean;
  FMustFinish    : Boolean;
  FMoveStartTime : DWord;
  FMoveDuration  : DWord;
  FReturnTarget  : TVec2f;
  FLightReturn   : Byte;
  FReturnDuration: DWord;
  procedure Interpolate( out aPosition : TVec2f; out aLight : Byte );
public
  function IsBump : Boolean;
end;

TGFXBumpAnimation = class(TGFXMoveAnimation)
  constructor Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aThings : TDRLVisualThings; aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D;
    aBeing : Boolean; aAmount : Single; aBlend : Boolean );
end;

{ TGFXScreenMoveAnimation }

TGFXScreenMoveAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aDuration : DWord; aDelay : DWord; aTo : TCoord2D );
  // Retargets the running camera move; False when a new one is needed.
  class function Update( aDuration : DWord; aDelay : DWord; aTo : TCoord2D ) : Boolean;
  procedure OnStart; override;
  procedure OnUpdate( aTime : DWord ); override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FSource : TVec2i;
  FDest   : TVec2i;
  FTo     : TCoord2D;
protected
  class var CCurrent : TGFXScreenMoveAnimation;
end;

// Draws a cell's top layer frame by frame, covering the presented cell
// from creation until it is destroyed.
TGFXCellAnimation = class(TGFXLevelAnimation)
  constructor Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FVisualMap : TDRLVisualMap; // Borrowed from the IO, which clears its animations first.
  FSprite    : TSprite;
  FCoord     : TCoord2D;
  FValue     : Integer;
  FRotation  : Byte;
end;

// Steps an item's sprite frames; its visual thing draws the result.
TGFXItemAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aUIDs : TUIDStore; aThings : TDRLVisualThings; aDuration : DWord; aDelay : DWord; aUID : TUID; aValue : Integer );
  procedure OnUpdate( aTime : DWord ); override;
  destructor Destroy; override;
private
  FUIDs   : TUIDStore;
  FThings : TDRLVisualThings; // Borrowed from the IO, which clears its animations first.
  FThing  : TDRLVisualThing;
  FSprite : TSprite;
  FValue  : Integer;
end;

// Shows a being's death, raise or transition frames on its visual thing,
// which it owns from creation: until it starts, the being stays as shown.
TGFXKillAnimation = class(TGFXLevelAnimation)
  constructor Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aVisual : TDRLVisualState; aDuration : DWord; aDelay : DWord; aUID : TUID; aKind : TKillAnimation = KillAnimDeath );
  procedure OnUpdate( aTime : DWord ); override;
  destructor Destroy; override;
private
  FLevel      : TLevel;
  FVisual     : TDRLVisualState; // Borrowed from the IO, which clears its animations first.
  FThing      : TDRLVisualThing;
  FSprite     : TSprite;
  FLight      : Byte;
  FCoord      : TCoord2D;
  FSprites    : array[0..3] of Integer;
  FCount      : Integer;
  FKind       : TKillAnimation;
public
  // Cell the being dies in; its corpse is presented when the clip ends.
  property Coord : TCoord2D read FCoord;
end;


{ TGFXScreenShakeAnimation }

TGFXScreenShakeAnimation = class(TGFXAnimation)
  constructor Create( aSpriteMap : TSpriteMap; aRNG : TRNG; aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection );
  class function Update( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection ) : Boolean;
  procedure OnUpdate( aTime : DWord ); override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FStrength   : Single;
  FFrequencyX : Single;
  FFrequencyY : Single;
  FDirection  : TDirection;
protected
  class var CCurrent : TGFXScreenShakeAnimation;
end;


implementation

uses vlog, vdebug,
     dfbeing, dfthing;

{ TGFXAnimation }

constructor TGFXAnimation.Create( aSpriteMap : TSpriteMap; aDuration : DWord; aDelay : DWord; aUID : TUID );
begin
  inherited Create( aDuration, aDelay, aUID );
  FSpriteMap := aSpriteMap;
end;

{ TGFXLevelAnimation }

constructor TGFXLevelAnimation.Create( aSpriteMap : TDRLSpriteMap; aDuration : DWord; aDelay : DWord; aUID : TUID );
begin
  inherited Create( aSpriteMap, aDuration, aDelay, aUID );
  FLevelMap := aSpriteMap;
end;

{ TGFXMissileAnimation }

constructor TGFXMissileAnimation.Create( aSpriteMap : TSpriteMap; aLevel : TLevel; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aSource, aTarget: TCoord2D; aDrawDelay: Word; aSprite : TSprite;
  aRay : Boolean; aTrailNID : Word );
var iSize : Word;
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FLevel := aLevel;
  FVisualMap := aVisualMap;
  FPath.Init( FLevel, aSource, aTarget );
  FSprite := aSprite;
  FStepDelay := Max( FDuration div Max( ( aSource - aTarget ).LargerLength, 1 ), 1 );
  FRay    := aRay;
  FStep   := 0;
  FEmitter := -1;
  FPath.Next;
  iSize := FSpriteMap.GetGridSize;

  FSource.Init( aSource.X*iSize-iSize div 2, aSource.Y*iSize-iSize div 2 );
  FTarget.Init( aTarget.X*iSize-iSize div 2, aTarget.Y*iSize-iSize div 2 );
  FHeading := -arctan2( aTarget.X - aSource.X, aTarget.Y - aSource.Y );
  if FHeading < 0 then FHeading := FHeading + 2*PI;

  if ( aTrailNID > 0 ) and ( not aRay ) then
    FEmitter := FLevel.Particles.AddEmitterDirect( aTrailNID,
      Vec3f( FSource.X / FSpriteMap.Engine.Scale, FSource.Y / FSpriteMap.Engine.Scale, 0 ) );
end;

destructor TGFXMissileAnimation.Destroy;
begin
  if ( FEmitter >= 0 ) and ( FLevel.Particles.Engine <> nil ) then
    FLevel.Particles.Engine.EmitStop( FEmitter );
  inherited Destroy;
end;

procedure TGFXMissileAnimation.OnUpdate( aTime : DWord );
var iOldStep : Word;
begin
  inherited OnUpdate( aTime );
  iOldStep := FStep;
  if not FRay then
  begin
    FStep    := FTime div FStepDelay;
    if FStep > iOldStep then
    for iOldStep := iOldStep+1 to FStep do
    begin
      FPath.Next;
      if FPath.Done then Break;
    end;
  end;
end;

procedure TGFXMissileAnimation.OnDraw;
var iPos    : TVec2i;
    iCoord  : TCoord2D;
    iSize   : Word;
    iLength : Single;
    iStep   : Single;
begin
  if not FRay then
    iPos := Lerp( FSource, FTarget, Minf(FTime / FDuration, 1.0) );

  if ( not FRay ) and ( FEmitter >= 0 ) then
  begin
    FLevel.Particles.Engine.EmitSetPosition( FEmitter,
      Vec3f( iPos.X / FSpriteMap.Engine.Scale, iPos.Y / FSpriteMap.Engine.Scale, 0 ) );
    FLevel.Particles.Engine.EmitSetSpriteRotation( FEmitter, ( FHeading + PI / 2 ) * 180 / PI );
  end;

  if FRay then
  begin
    iSize   := FSpriteMap.GetGridSize;
    iLength := FSource.Distance( FTarget );
    iStep   := iSize div 2;
    while iStep < iLength do
    begin
      iStep += 20.0;
      iPos := Lerp( FSource, FTarget, iStep / iLength );
      iCoord.Create( iPos.X div iSize + 1, iPos.Y div iSize + 1 );
      if FVisualMap.Visible( iCoord ) then
        FSpriteMap.PushSpriteFXRotated( iPos, FSprite, FHeading + PI/2 );
    end;
    Exit;
  end;

  if not FVisualMap.Visible( FPath.Current ) then
    Exit;
  FSpriteMap.PushSpriteFXRotated( iPos, FSprite, FHeading + PI/2 );
end;

{ TMessageAnimation }

{constructor TMessageAnimation.Create(aMessage: Ansistring);
begin
  inherited Create;
  FMessage := aMessage;
end;

procedure TMessageAnimation.Draw;
begin
  if (not FExpired) and (not UI.isMsgWaiting) then ;
  begin
    UI.Msg(FMessage);
    FExpired := True;
  end;
end;}

{ TGFXMarkAnimation }

constructor TGFXMarkAnimation.Create( aSpriteMap : TSpriteMap; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FVisualMap := aVisualMap;
  FCoord     := aCoord;
  FSprite    := aSprite;
end;

procedure TGFXMarkAnimation.OnDraw;
begin
  if ( FVisualMap <> nil ) and ( not FVisualMap.Visible( FCoord ) ) then Exit;
  FSpriteMap.PushSpriteFX( FCoord, FSprite, FTime )
end;

{ TGFXFXAnimation }

constructor TGFXFXAnimation.Create( aSpriteMap : TSpriteMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FCoord    := aCoord;
  FSprite   := aSprite;
  FBlocking := False;
end;

procedure TGFXFXAnimation.OnDraw;
var iSprite  : TSprite;
    iSegment : Integer;
begin
  iSprite  := FSprite;
  iSegment := ( FTime * FSprite.Frames ) div FDuration;
  if iSegment >= FSprite.Frames then iSegment := FSprite.Frames - 1;
  iSprite.SpriteID[0] += iSegment * DRL_COLS;
  iSprite.Frames      := 0;
  FSpriteMap.PushSpriteFX( FCoord, iSprite );
end;

{ TGFXExplodeMarkAnimation }

constructor TGFXExplodeMarkAnimation.Create( aSpriteMap : TSpriteMap; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aCoord: TCoord2D; aColor: Byte; aSprite : DWord );
var c1, c2, c3 : Byte;
begin
  inherited Create( aSpriteMap, Max( aDuration, 1 ), aDelay, 0 );
  case aColor of
    LightBlue: begin C1 := LightBlue;C2 := Cyan;       C3 := LightBlue;  end;
    Blue     : begin C1 := Blue;     C2 := LightBlue;  C3 := LightBlue;  end;
    Magenta  : begin C1 := Magenta;  C2 := Red;        C3 := Blue;   end;
    Green    : begin C1 := Green;    C2 := LightGreen; C3 := LightGreen;  end;
    LightRed : begin C1 := LightRed; C2 := Yellow;     C3 := White;  end;
    Yellow   : begin C1 := Brown;    C2 := Yellow;     C3 := White;  end;
  else         begin C1 := Red;      C2 := LightRed;   C3 := Yellow; end;
  end;
  FGColor1 := vcolor.NewColor(c1);
  FGColor2 := vcolor.NewColor(c2);
  FGColor3 := vcolor.NewColor(c3);
  FVisualMap := aVisualMap;
  FCoord     := aCoord;
  FSprite    := aSprite;
end;

procedure TGFXExplodeMarkAnimation.OnDraw;
var iMarkSprite : TSprite;
begin
  if ( FVisualMap <> nil ) and ( not FVisualMap.Visible( FCoord ) ) then Exit;
  iMarkSprite.Flags       := [ SF_OVERLAY ];
  iMarkSprite.SpriteID[0] := FSprite;

  case (( FTime * 3 ) div FDuration) of
    0 : iMarkSprite.OverColor    := FGColor1;
    1 : iMarkSprite.OverColor    := FGColor2;
    2 : iMarkSprite.OverColor    := FGColor3;
  else iMarkSprite.OverColor    := FGColor2;
  end;
  FSpriteMap.PushSpriteFX( FCoord, iMarkSprite );
end;

{ TSoundEventAnimation }

constructor TSoundEventAnimation.Create( aIO : TDRLIO; aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord );
begin
  inherited Create( 1, aDelay, 0 );
  FIO       := aIO;
  FPosition := aPosition;
  FSoundID  := aSoundID;
  FBlocking := False;
end;

procedure TSoundEventAnimation.OnStart;
begin
  FIO.PlaySound( FSoundID, FPosition );
end;

{ TGFXParticleBurstAnimation }

constructor TGFXParticleBurstAnimation.Create( aParticles : TParticleStore; aDelay : DWord; aEmitterID : Word;
  aPosition : TCoord2D; aDirection : TDirection; aCount : Word;
  aDistanceScale, aSpreadScale : Single; const aDecals : TDecalSprites );
begin
  inherited Create( 1, aDelay, 0 );
  FParticles     := aParticles;
  FDecals        := aDecals;
  FEmitterID     := aEmitterID;
  FPosition      := aPosition;
  FDirection     := aDirection;
  FCount         := aCount;
  FDistanceScale := aDistanceScale;
  FSpreadScale   := aSpreadScale;
  FBlocking      := False;
end;

procedure TGFXParticleBurstAnimation.OnStart;
var iDirection : TVec2f;
begin
  iDirection.Init( FDirection.X, FDirection.Y );
  FParticles.SpawnBurst( FEmitterID,
    Vec3f( ( FPosition.X - 1 ) * 32 + 16, ( FPosition.Y - 1 ) * 32 + 16, 0 ),
    iDirection, FCount, FDecals,
    NewFloatRange( 0.25 * FDistanceScale, FDistanceScale ),
    NewFloatRange( 0.5, 1.0 ), FSpreadScale );
end;

{ TGFXBlinkAnimation }

constructor TGFXBlinkAnimation.Create( aSheet : TGLQuadList; aDriver : TIODriver; aDuration : DWord; aDelay : DWord; aColor : Word );
begin
  inherited Create( aDuration, aDelay, 0 );
  FSheet    := aSheet;
  FDriver   := aDriver;
  FGColor   := NewColor( aColor );
  FBlocking := False;
end;

procedure TGFXBlinkAnimation.OnDraw;
begin
  FSheet.PushColoredQuad( TVec2i.Create(0,0), TVec2i.Create(FDriver.GetSizeX,FDriver.GetSizeY), TVec4f.Create(FGColor.R,FGColor.G,FGColor.B,0.7) );
end;

{ TRumbleEventAnimation }

constructor TRumbleEventAnimation.Create( aDriver : TIODriver; aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
begin
  inherited Create( 1, aDelay, 0 );
  FDriver   := aDriver;
  FLow      := aLow;
  FHigh     := aHigh;
  FDur      := aDuration;
  FBlocking := False;
end;

procedure TRumbleEventAnimation.OnStart;
begin
  FDriver.Rumble( FLow, FHigh, FDur );
end;


{ TGFXMoveAnimation }

constructor TGFXMoveAnimation.Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aThings : TDRLVisualThings; aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D;
  aBeing : Boolean; aPartial : Single; aFinishBeforeNext : Boolean ) ;
var iBeing : TThing;
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FUID           := aUID;
  FThings        := aThings;
  FBeing         := aBeing;
  FMustFinish    := aFinishBeforeNext;
  FMoveStartTime := 0;
  FMoveDuration  := aDuration;
  FReturnDuration:= 0;
  FLightStart    := 255;
  FLightEnd      := 255;

  if aBeing then
  begin
    FLightStart := Iif( aLevel.isVisible(aFrom), FLevelMap.VariableLight( aFrom, 30 ), 0 );
    FLightEnd   := Iif( aLevel.isVisible(aTo),   FLevelMap.VariableLight( aTo, 30 ), 0 );

    iBeing := aLevel.Context.UIDs.Get( FUID ) as TThing;

    if aLevel.Flags[ LF_BEINGSVISIBLE ] or iBeing.Flags[ BF_VISIBLE ] then
    begin
      FLightStart := Max( FLightStart, 40 );
      FLightEnd   := Max( FLightEnd, 40 );
    end;
  end;

  FSource.Init( aFrom.X - 1, aFrom.Y - 1 );
  FTarget.Init( aTo.X - 1, aTo.Y - 1 );
  if aPartial > 0.0 then
    FTarget := Lerp( FSource, FTarget, aPartial );
  if aPartial < 0.0 then
    FSource := Lerp( FSource, FTarget, 1.0+aPartial );
  FPosition := FSource;
  FThing := FThings.Acquire( FUID, aFrom );
end;

function TGFXMoveAnimation.TryBlend( aAnimation : TAnimation ) : Boolean;
var iMove     : TGFXMoveAnimation;
    iDistance : Single;
    iSpeed    : Single;
    iDuration : DWord;
    iReturning: Boolean;
begin
  if not ( aAnimation is TGFXMoveAnimation ) then Exit( False );
  iMove := TGFXMoveAnimation( aAnimation );
  if FMustFinish or iMove.FMustFinish then Exit( False );
  // Preserve the entry path and fade-in when a being moves into view.
  if FBeing and ( FLightStart = 0 ) then Exit( False );
  iDistance := iMove.FSource.Distance( iMove.FTarget );
  if iDistance = 0.0 then Exit( False );

  iReturning := IsBump and ( FTime - FMoveStartTime >= FMoveDuration );
  iSpeed := iDistance / iMove.FMoveDuration;
  if iReturning then
    iSpeed := FTarget.Distance( FReturnTarget ) / FReturnDuration;
  if iSpeed = 0.0 then Exit( False );

  Interpolate( FPosition, FLightStart );
  FSource := FPosition;
  iDuration := Max( 1, Ceil( FSource.Distance( iMove.FTarget ) / iSpeed ) );
  // Ordinary movement retains its single-move duration cap.
  if ( not iReturning ) or ( not iMove.IsBump ) then
    iDuration := Min( iDuration, iMove.FMoveDuration );
  FTarget := iMove.FTarget;
  FLightEnd := iMove.FLightEnd;
  FReturnTarget := iMove.FReturnTarget;
  FLightReturn := iMove.FLightReturn;
  FReturnDuration := iMove.FReturnDuration;
  FBlocking := iMove.FBlocking;
  // Keep the clip's clock running so OnStart and entity ownership stay intact.
  FMoveStartTime := FTime;
  FMoveDuration := iDuration;
  FDuration := FTime + FMoveDuration + FReturnDuration;
  Exit( True );
end;

function TGFXMoveAnimation.IsBump : Boolean;
begin
  Exit( FReturnDuration > 0 );
end;

procedure TGFXMoveAnimation.Interpolate( out aPosition : TVec2f; out aLight : Byte );
var iValue : Single;
    iTime  : DWord;
begin
  iTime := FTime - FMoveStartTime;
  if IsBump and ( iTime >= FMoveDuration ) then
  begin
    iValue := Clampf( ( iTime - FMoveDuration ) / FReturnDuration, 0, 1 );
    aPosition := Lerp( FTarget, FReturnTarget, iValue );
    aLight := Lerp( FLightEnd, FLightReturn, iValue );
  end
  else
  begin
    iValue := Clampf( iTime / FMoveDuration, 0, 1 );
    aPosition := Lerp( FSource, FTarget, iValue );
    aLight := Lerp( FLightStart, FLightEnd, iValue );
  end;
end;

constructor TGFXBumpAnimation.Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aThings : TDRLVisualThings; aDuration : DWord; aDelay : DWord; aUID : TUID;
  aFrom, aTo : TCoord2D; aBeing : Boolean; aAmount : Single; aBlend : Boolean );
begin
  inherited Create( aSpriteMap, aLevel, aThings, aDuration, aDelay, aUID, aFrom, aTo, aBeing, aAmount );
  FReturnTarget := FSource;
  FLightReturn := FLightStart;
  FReturnDuration := aDuration;
  FDuration := aDuration * 2;
  FBlocking := not aBlend;
end;

procedure TGFXMoveAnimation.OnUpdate( aTime : DWord );
var iLight : Byte;
begin
  inherited OnUpdate( aTime );
  if not Started then Exit;
  Interpolate( FPosition, iLight );
  FThing.Position := FPosition;
  if FBeing
    then FThing.Light := iLight
    else FThing.Light := -1;
end;

destructor TGFXMoveAnimation.Destroy;
begin
  if Started then FThing.Light := -1;
  FThings.Release( FThing );
  inherited Destroy;
end;

{ TGFXScreenMoveAnimation }

constructor TGFXScreenMoveAnimation.Create( aSpriteMap : TSpriteMap; aDuration : DWord; aDelay : DWord; aTo: TCoord2D );
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FTo       := aTo;
  FSource   := FSpriteMap.Shift;
  FDest     := FSpriteMap.ShiftValue(aTo);
  CCurrent  := Self;
end;

class function TGFXScreenMoveAnimation.Update( aDuration : DWord; aDelay : DWord; aTo : TCoord2D ) : Boolean;
begin
  // Delayed moves are not merged; each follows whatever runs before it.
  if ( CCurrent = nil ) or ( aDelay > 0 ) or ( CCurrent.Delay > 0 ) then Exit( False );
  CCurrent.OnUpdate( 0 );
  CCurrent.FSource   := CCurrent.FSpriteMap.NewShift;
  CCurrent.FTo       := aTo;
  CCurrent.FDest     := CCurrent.FSpriteMap.ShiftValue( aTo );
  CCurrent.FTime     := 0;
  CCurrent.FDuration := Max( aDuration, Round( Sqrt( CCurrent.FSource.Distance( CCurrent.FDest ) ) ) );;
  Exit( True );
end;

procedure TGFXScreenMoveAnimation.OnStart;
begin
  // The camera starts from where earlier moves have left it.
  FSource   := FSpriteMap.NewShift;
  FDest     := FSpriteMap.ShiftValue( FTo );
  FDuration := Max( FDuration, Round( Sqrt( FSource.Distance( FDest ) ) ) );
end;

procedure TGFXScreenMoveAnimation.OnUpdate( aTime : DWord );
begin
  inherited OnUpdate( aTime );
  if Started then
    FSpriteMap.NewShift := Lerp( FSource, FDest, Minf(FTime/FDuration,1.0) );
end;

procedure TGFXScreenMoveAnimation.OnDraw;
begin
end;

destructor TGFXScreenMoveAnimation.Destroy;
begin
  if CCurrent = Self then
  begin
    FSpriteMap.NewShift := FDest;
    CCurrent := nil;
  end;
  inherited Destroy;
end;

constructor TGFXCellAnimation.Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aVisualMap : TDRLVisualMap; aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FVisualMap := aVisualMap;
  FCoord     := aCoord;
  FSprite    := aSprite;
  FValue     := aValue;
  FRotation  := aLevel.Rotation[ FCoord ];
  FVisualMap.Cover( FCoord );
end;

procedure TGFXCellAnimation.OnDraw;
var iSprite  : TSprite;
    iSegment : Integer;
begin
  iSprite := FSprite;
  iSegment := ( FTime * FValue ) div FDuration;
  if ( iSegment <> FValue ) then
    iSegment += Sgn( FValue );
  if SF_DOORHACK in FSprite.Flags then
  begin
    if FRotation > 0 then
    begin
      iSegment := Abs( iSegment ) + 4;
      Include( iSprite.Flags, SF_HIGHSPRITE );
    end;
  end;
  if iSprite.SCount > 1 then
  begin
    iSegment := Abs( iSegment );
    iSprite.SpriteID[0] := iSprite.SpriteID[ iSegment ];
  end
  else
    iSprite.SpriteID[0] += ( FValue - iSegment ) * DRL_COLS;
  FLevelMap.PushSpriteDoodad( FCoord, iSprite );
end;

destructor TGFXCellAnimation.Destroy;
begin
  FVisualMap.Uncover( FCoord );
  inherited Destroy;
end;

constructor TGFXItemAnimation.Create( aSpriteMap : TSpriteMap; aUIDs : TUIDStore; aThings : TDRLVisualThings; aDuration : DWord; aDelay : DWord; aUID : TUID; aValue : Integer );
var iThing : TThing;
begin
  inherited Create( aSpriteMap, aDuration, aDelay, aUID );
  FUIDs   := aUIDs;
  FThings := aThings;
  FValue  := aValue;
  iThing  := FUIDs.Get( FUID ) as TThing;
  FThing  := nil;
  if iThing = nil then Exit;
  FSprite := iThing.Sprite;
  FThing  := FThings.Acquire( FUID, iThing.Position );
end;

procedure TGFXItemAnimation.OnUpdate( aTime : DWord );
var iThing    : TThing;
    iSprite   : TSprite;
    iSegment  : Integer;
begin
  inherited OnUpdate( aTime );
  if not Started then Exit;
  iThing := FUIDs.Get( FUID ) as TThing;
  if iThing = nil then Exit;
  iSprite  := FSprite;
  iSegment := ( FTime * FValue ) div FDuration;
  if ( iSegment <> FValue ) then
    iSegment += Sgn( FValue );
  if iSprite.SCount > 1 then
  begin
    iSegment := Abs( iSegment );
    iSprite.SpriteID[0] := iSprite.SpriteID[ iSegment ];
  end
  else
    iSprite.SpriteID[0] += ( FValue - iSegment ) * DRL_COLS;
  iThing.Sprite := iSprite;
  if FThing <> nil then FThing.Sprite := iSprite;
end;

destructor TGFXItemAnimation.Destroy;
begin
  if FThing <> nil then FThings.Release( FThing );
  inherited Destroy;
end;

constructor TGFXKillAnimation.Create( aSpriteMap : TDRLSpriteMap; aLevel : TLevel; aVisual : TDRLVisualState; aDuration : DWord; aDelay : DWord; aUID : TUID; aKind : TKillAnimation = KillAnimDeath );
var iBeing      : TBeing;
    iCols       : Integer;
    iPlayerHack : Integer;
begin
  inherited Create( aSpriteMap, aDuration, aDelay, aUID );
  FLevel  := aLevel;
  FVisual := aVisual;
  FKind   := aKind;
  FThing  := nil;
  iBeing  := FLevel.Context.UIDs.Get( FUID ) as TBeing;
  if iBeing = nil then Exit;
  FCount      := 2;
  // TODO: remove hack!
  if ( aKind = KillAnimDeath ) and ( iBeing.GetLuaProtoValue('corpse') = 0 ) then FCount := 3;
  FSprite     := iBeing.Sprite;
  FCoord      := iBeing.Position;

  // TODO : remove hack!
  iPlayerHack := 0;
  if iBeing.IsPlayer then
  begin
    iPlayerHack := 1;
    if iBeing.SpriteMod > 0 then iPlayerHack := 2;
  end;
  FLight      := Iif( FLevel.isVisible(iBeing.Position), FLevelMap.VariableLight( iBeing.Position, 30 ), 0 );

  iCols := DRL_COLS;
  if SF_LARGE in FSprite.Flags then iCols *= 2;

  if aKind = KillAnimRaise then
  begin
    FSprites[0] := FSprite.SpriteID[0] + (FSprite.Frames + 1)* iCols;
    FSprites[1] := FSprite.SpriteID[0] + (FSprite.Frames + 0) * iCols;
  end
  else
  begin
    FSprites[0] := FSprite.SpriteID[0] + FSprite.Frames * iCols;
    if ( iPlayerHack > 0 ) then
      FSprites[1] := ( FSprite.SpriteID[0] - FSprite.SpriteID[0] mod 1000 ) + DRL_COLS * 24 + iPlayerHack
    else
      FSprites[1] := FSprite.SpriteID[0] + (FSprite.Frames + 1) * iCols;
    if FCount > 2 then
      FSprites[2] := FSprite.SpriteID[0] + (FSprite.Frames + 2) * iCols;
  end;

  FThing := FVisual.Things.Acquire( FUID, FCoord );
  // A transition also hides the remains left at its position until it ends.
  if FKind = KillAnimTransition then FVisual.Map.Cover( FCoord );
end;

procedure TGFXKillAnimation.OnUpdate( aTime : DWord );
var iBeing    : TBeing;
    iSegment  : Integer;
begin
  inherited OnUpdate( aTime );
  if ( FThing = nil ) or not Started then Exit;
  iBeing := FLevel.Context.UIDs.Get( FUID ) as TBeing;
  if ( iBeing <> nil ) and not iBeing.Killed
    then FThing.Position := Vec2f( iBeing.Position.X - 1, iBeing.Position.Y - 1 )
    else FThing.Position := Vec2f( FCoord.X - 1, FCoord.Y - 1 );
  iSegment := Min( ( FTime * FCount ) div FDuration, FCount - 1 );
  FThing.Frame := FSprite;
  FThing.Frame.SpriteID[0] := FSprites[iSegment];
  FThing.HasFrame := True;
  FThing.Light    := FLight;
end;

destructor TGFXKillAnimation.Destroy;
begin
  if FThing <> nil then
  begin
    FThing.HasFrame := False;
    FThing.Light    := -1;
    FVisual.Things.Release( FThing );
    if FKind = KillAnimTransition then FVisual.Map.Uncover( FCoord );
  end;
  inherited Destroy;
end;
constructor TGFXScreenShakeAnimation.Create( aSpriteMap : TSpriteMap; aRNG : TRNG; aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection );
begin
  inherited Create( aSpriteMap, aDuration, aDelay, 0 );
  FStrength   := aStrength;
  FFrequencyX := 0.05 + 0.8 * aRNG.RFloat;
  FFrequencyY := 0.05 + 0.8 * aRNG.RFloat;
  FDirection  := aDirection;
  FBlocking   := False;
end;

class function TGFXScreenShakeAnimation.Update( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection ) : Boolean;
begin
  if CCurrent = nil then Exit( False );
  CCurrent.FStrength := Maxf( CCurrent.FStrength, aStrength );
  CCurrent.FDelay    := Min( CCurrent.FDelay, aDelay );
  CCurrent.FDuration := Max( CCurrent.FDuration, aDuration );
  if CCurrent.FDirection.code <> 0 then
    CCurrent.FDirection := aDirection;
  Exit( True );
end;

procedure TGFXScreenShakeAnimation.OnUpdate( aTime : DWord );
var iFactor : Single;
    iFade   : Single;
    iOffset : TVec2i;
    iMaxX   : Single;
    iMaxY   : Single;
begin
  inherited OnUpdate( aTime );
  iOffset := Vec2i(0,0);
  if FTime < FDuration then
  begin
    iFactor := Minf( FTime / FDuration, 1.0 );
    iFade   := 1.0 - iFactor * iFactor;
    iMaxX   := FStrength * iFade * 2.0; // X-bias
    iMaxY   := FStrength * iFade;

    if FDirection.code = 0 then
    begin
      iOffset.X := Round(iMaxX * Sin( FTime * FFrequencyX * 2 * Pi ) );
      iOffset.Y := Round(iMaxY * Cos( FTime * FFrequencyY * 2 * Pi ) );
    end
    else
    begin
      iOffset.X := Round( FDirection.X * iMaxY * Sin( FTime * FFrequencyX * 2 * Pi ) );
      iOffset.Y := Round( FDirection.Y * iMaxY * Sin( FTime * FFrequencyX * 2 * Pi ) );
    end;
  end;
  FSpriteMap.Offset := iOffset;
end;

procedure TGFXScreenShakeAnimation.OnDraw;
begin
end;

destructor TGFXScreenShakeAnimation.Destroy;
begin
  FSpriteMap.Offset := Vec2i(0,0);
  inherited Destroy;
end;


end.
