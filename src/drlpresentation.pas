{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
// The presentation interface the level and its entities use. It sits above
// the entity units so thing clips can name the things they present; units
// below it reach it from their implementation sections.
unit drlpresentation;
interface
uses vrltools,
     dfdata, dfthing, dfitem, dfbeing;

// Sounds and queued visual effects for the level and its entities, on top of
// messages and the presentation RNG. Implemented by IO and borrowed by the
// level; entities reach it through the level, so they present only while on it.
// Things passed to it are things of the level.
type IDRLPresentation = interface( IRLPresentation )
  function ResolveSoundID( const aResolveIDs : array of AnsiString ) : Word;
  procedure PlaySound( aSoundID : Word; aCoord : TCoord2D; aDelay : DWord = 0 );
  // Presentation time until which a pain sprite shows when hit after aDelay.
  function PainUntil( aDelay : Integer ) : QWord;
  procedure Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0 );
  procedure PulseBlood( aValue : Single );
  // Whether the level's decals are drawn; placing them draws visual randomness.
  function ShowsDecals : Boolean;
  function EngineSprites : TEngineSprites;
  // Sound ID an item plays when equipped: 'pickup' or 'reload'.
  function EquipSound : AnsiString;
  // aCells are the cells the explosion reaches, in any order.
  procedure Explosion( aDelay : Integer; aWhere : TCoord2D; const aData : TExplosionData; const aCells : array of TCoord2D );
  // A change made now to the cell is shown, with the neighbours derived
  // from it, once aDelay ms of the current action have been presented.
  procedure HoldCell( const aCoord : TCoord2D; aDelay : Integer );
  // A thing just added appears after aDelay ms.
  procedure HideThing( aThing : TThing; aDelay : Integer );
  // A thing about to be removed, still in the level, disappears after
  // aDelay ms.
  procedure LingerThing( aThing : TThing; aDelay : Integer );
  procedure addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection ); overload;
  procedure addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single ); overload;
  procedure addMoveAnimation( aDuration : DWord; aDelay : DWord; aThing : TThing; aFrom, aTo : TCoord2D; aWipeBump : Boolean; aFinishBeforeNext : Boolean = False );
  procedure addBumpAnimation( aDuration : DWord; aDelay : DWord; aBeing : TBeing; aFrom, aTo : TCoord2D; aAmount : Single );
  procedure addScreenMoveAnimation( aDuration : DWord; aTo : TCoord2D; aDelay : DWord = 0 );
  procedure addCellAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
  procedure addItemAnimation( aDuration : DWord; aDelay : DWord; aItem : TItem; aValue : Integer );
  procedure addKillAnimation( aDuration : DWord; aDelay : DWord; aBeing : TBeing; aKind : TKillAnimation = KillAnimDeath );
  procedure addMissileAnimation( aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aColor : Byte; aPic : Char; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False; aTrailNID : Word = 0 );
  procedure addMarkAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aColor : Byte; aPic : Char );
  procedure addFXAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
  procedure addParticleBurstAnimation( aDelay : DWord; aEmitterID : Word; aPosition : TCoord2D;
    aDirection : TDirection; aCount : Word; aDistanceScale, aSpreadScale : Single );
  procedure addSoundAnimation( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord );
  procedure addRumbleAnimation( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
end;

implementation

end.
