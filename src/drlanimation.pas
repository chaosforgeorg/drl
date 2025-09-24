{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlanimation;
interface
uses
  Classes, SysUtils, math,
  vnode, vutil, vcolor, vmath, vvector, vrltools, vvision, vanimation,
  dfdata;

type TAnimation        = vanimation.TAnimation;
     TAnimationManager = vanimation.TAnimations;

{ TGFXMissileAnimation }

TGFXMissileAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False );
  procedure OnUpdate( aTime : DWord ); override;
  procedure OnDraw; override;
private
  FSource   : TVec2i;
  FTarget   : TVec2i;
  FPath     : TVisionRay;
  FHeading  : Float;
  FRay      : Boolean;
  FSprite   : TSprite;
  FStepDelay: DWord;
  FStep     : Word;
end;

{ TMessageAnimation }

{TMessageAnimation = class(TAnimation)
  constructor Create( aMessage : Ansistring );
  procedure OnDraw; override;
private
  FMessage : AnsiString;
end;}

{ TGFXMarkAnimation }

TGFXMarkAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
  procedure OnDraw; override;
private
  FSprite : TSprite;
  FCoord  : TCoord2D;
end;

{ TGFXExplodeMarkAnimation }

TGFXExplodeMarkAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aColor : Byte );
  procedure OnDraw; override;
private
  FCoord    : TCoord2D;
  FGColor1  : TColor;
  FGColor2  : TColor;
  FGColor3  : TColor;
end;

{ TSoundEventAnimation }

TSoundEventAnimation = class(TAnimation)
  constructor Create( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord );
  procedure OnStart; override;
private
  FPosition : TCoord2D;
  FSoundID  : DWord;
end;

{ TGFXBlinkAnimation }

TGFXBlinkAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aColor : Word );
  procedure OnDraw; override;
private
  FGColor   : TColor;
end;

{ TRumbleEventAnimation }

TRumbleEventAnimation = class(TAnimation)
  constructor Create( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
  procedure OnStart; override;
private
  FLow    : Word;
  FHigh   : Word;
  FDur    : DWord;
end;

{ TGFXMoveAnimation }

TGFXMoveAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aBeing : Boolean; aPartial : Single = 0.0 );
  procedure OnStart; override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FLightStart : Byte;
  FLightEnd   : Byte;
  FSprite     : TSprite;
  FPosition   : TVec2i;
  FSource     : TVec2i;
  FTarget     : TVec2i;
  FBeing      : Boolean;
public
  property LastPosition : TVec2i read FPosition;
end;

TGFXBumpAnimation = class(TGFXMoveAnimation);

{ TGFXScreenMoveAnimation }

TGFXScreenMoveAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aTo : TCoord2D );
  class function Update( aDuration : DWord; aTo : TCoord2D ) : Boolean;
  procedure OnUpdate( aTime : DWord ); override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FSource : TVec2i;
  FDest   : TVec2i;
protected
  class var CCurrent : TGFXScreenMoveAnimation;
end;


TGFXCellAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
  procedure OnStart; override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FSprite : TSprite;
  FCoord  : TCoord2D;
  FValue  : Integer;
end;

TGFXItemAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aValue : Integer );
  procedure OnStart; override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FSprite : TSprite;
  FValue  : Integer;
end;

TGFXKillAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aReverse : Boolean = False );
  procedure OnStart; override;
  procedure OnDraw; override;
  destructor Destroy; override;
private
  FSprite     : TSprite;
  FLight      : Byte;
  FPosition   : TVec2i;
  FCoord      : TCoord2D;
  FSprites    : array[0..3] of Integer;
  FCount      : Integer;
  FReverse    : Boolean;
end;


{ TGFXScreenShakeAnimation }

TGFXScreenShakeAnimation = class(TAnimation)
  constructor Create( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection );
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

uses viotypes, vuid, vlog, vdebug,
     dfbeing, dfthing,
     drlbase, drlgfxio, drlio, drlspritemap;

{ TGFXMissileAnimation }

constructor TGFXMissileAnimation.Create(aDuration : DWord; aDelay : DWord; aSource, aTarget: TCoord2D; aDrawDelay: Word; aSprite : TSprite;
  aRay: Boolean);
var iSize : Word;
begin
  inherited Create( aDuration, aDelay, 0 );
  FPath.Init(DRL.Level,aSource,aTarget);
  FSprite := aSprite;
  FStepDelay := Max( FDuration div Max( ( aSource - aTarget ).LargerLength, 1 ), 1 );
  FRay    := aRay;
  FStep   := 0;
  FPath.Next;
  FPath.Prev := aSource;
  iSize := SpriteMap.GetGridSize;

  FSource.Init( aSource.X*iSize-iSize div 2, aSource.Y*iSize-iSize div 2 );
  FTarget.Init( aTarget.X*iSize-iSize div 2, aTarget.Y*iSize-iSize div 2 );
  FHeading := -arctan2( aTarget.X - aSource.X, aTarget.Y - aSource.Y );
  if FHeading < 0 then FHeading := FHeading + 2*PI;
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
    iLength : Single;
    iStep   : Single;
begin
  if ( not DRL.Level.isProperCoord( FPath.GetC ) ) or (not DRL.Level.isVisible( FPath.GetC ) ) then
    Exit;
  if FRay then
  begin
    iLength := FSource.Distance( FTarget );
    iStep := SpriteMap.GetGridSize div 2;
    while iStep < iLength do
    begin
      iStep += 20.0;
      iPos := Lerp( FSource, FTarget, iStep / iLength );
      SpriteMap.PushSpriteFXRotated( iPos, FSprite, FHeading + PI/2)
    end;
    Exit;
  end
  else
  begin
    iPos := Lerp( FSource, FTarget, Minf(FTime / FDuration, 1.0) );
    SpriteMap.PushSpriteFXRotated( iPos, FSprite, FHeading + PI/2)
  end;
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

constructor TGFXMarkAnimation.Create( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite );
begin
  inherited Create( aDuration, aDelay, 0 );
  FCoord  := aCoord;
  FSprite := aSprite;
end;

procedure TGFXMarkAnimation.OnDraw;
begin
  SpriteMap.PushSpriteFX( FCoord, FSprite, FTime )
end;

{ TGFXExplodeMarkAnimation }

constructor TGFXExplodeMarkAnimation.Create( aDuration : DWord; aDelay : DWord; aCoord: TCoord2D; aColor: Byte );
var c1, c2, c3 : Byte;
begin
  inherited Create( Max( aDuration, 1 ), aDelay, 0 );
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
  FCoord    := aCoord;
end;

procedure TGFXExplodeMarkAnimation.OnDraw;
var iMarkSprite : TSprite;
begin
  iMarkSprite.Flags       := [ SF_OVERLAY ];
  iMarkSprite.SpriteID[0] := HARDSPRITE_EXPL;

  case (( FTime * 3 ) div FDuration) of
    0 : iMarkSprite.OverColor    := FGColor1;
    1 : iMarkSprite.OverColor    := FGColor2;
    2 : iMarkSprite.OverColor    := FGColor3;
  else iMarkSprite.OverColor    := FGColor2;
  end;
  SpriteMap.PushSpriteFX( FCoord, iMarkSprite );
end;

{ TSoundEventAnimation }

constructor TSoundEventAnimation.Create( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord );
begin
  inherited Create( 1, aDelay, 0 );
  FPosition := aPosition;
  FSoundID  := aSoundID;
end;

procedure TSoundEventAnimation.OnStart;
begin
  IO.Audio.PlaySound( FSoundID, FPosition );
end;

{ TGFXBlinkAnimation }

constructor TGFXBlinkAnimation.Create( aDuration : DWord; aDelay : DWord; aColor: Word );
begin
  inherited Create( aDuration, aDelay, 0 );
  FGColor   := NewColor( aColor );
end;

procedure TGFXBlinkAnimation.OnDraw;
begin
  if GraphicsVersion then
    (IO as TDRLGFXIO).PostSheet.PushColoredQuad( TVec2i.Create(0,0), TVec2i.Create(IO.Driver.GetSizeX,IO.Driver.GetSizeY), TVec4f.Create(FGColor.R,FGColor.G,FGColor.B,0.7) );
end;

{ TRumbleEventAnimation }

constructor TRumbleEventAnimation.Create( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
begin
  inherited Create( 1, aDelay, 0 );
  FLow      := aLow;
  FHigh     := aHigh;
  FDur      := aDuration;
end;

procedure TRumbleEventAnimation.OnStart;
begin
  IO.Driver.Rumble( FLow, FHigh, FDur );
end;


{ TGFXMoveAnimation }

constructor TGFXMoveAnimation.Create ( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D;
  aSprite : TSprite; aBeing : Boolean; aPartial : Single ) ;
var iSize  : Word;
begin
  inherited Create( aDuration, aDelay, 0 );
  FUID        := aUID;
  FSprite     := aSprite;
  FBeing      := aBeing;
  FLightStart := 255;
  FLightEnd   := 255;

  if aBeing then
  begin
    FLightStart := Iif( DRL.Level.isVisible(aFrom), SpriteMap.VariableLight( aFrom, 30 ), 0 );
    FLightEnd   := Iif( DRL.Level.isVisible(aTo),   SpriteMap.VariableLight( aTo, 30 ), 0 );

    if DRL.Level.Flags[ LF_BEINGSVISIBLE ] then
    begin
      FLightStart := Max( FLightStart, 40 );
      FLightEnd   := Max( FLightEnd, 40 );
    end;
  end;

  iSize := SpriteMap.GetGridSize;
  FSource.Init( (aFrom.X - 1)*iSize,(aFrom.Y - 1)*iSize);
  FTarget.Init( (aTo.X   - 1)*iSize,(aTo.Y   - 1)*iSize);
  if aPartial > 0.0 then
    FTarget := Lerp( FSource, FTarget, aPartial );
  if aPartial < 0.0 then
    FSource := Lerp( FSource, FTarget, 1.0+aPartial );
  FPosition := FSource;
end;

procedure TGFXMoveAnimation.OnStart;
var iThing : TThing;
begin
  iThing := UIDs.Get( FUID ) as TThing;
  if iThing <> nil then iThing.AnimCount := iThing.AnimCount + 1;
end;

procedure TGFXMoveAnimation.OnDraw;
var iValue : Single;
    iLight : Byte;
    iBeing : TBeing;
begin
  iValue    := Clampf( FTime / FDuration, 0, 1 );
  iLight    := Lerp( FLightStart, FLightEnd, iValue );
  FPosition := Lerp( FSource, FTarget, iValue );
  if FBeing
    then
    begin
      iBeing := UIDs.Get( FUID ) as TBeing;
      if iBeing <> nil
        then SpriteMap.PushSpriteBeing( FPosition, SpriteMap.GetBeingSprite( iBeing ), iLight )
        else SpriteMap.PushSpriteBeing( FPosition, FSprite, iLight );
    end
    else SpriteMap.PushSpriteItem( FPosition, FSprite, iLight );
end;

destructor TGFXMoveAnimation.Destroy;
var iThing : TThing;
begin
  iThing := UIDs.Get( FUID ) as TThing;
  if Started and ( iThing <> nil ) then iThing.AnimCount := Max( 0, iThing.AnimCount - 1 );
  inherited Destroy;
end;

{ TGFXScreenMoveAnimation }

constructor TGFXScreenMoveAnimation.Create( aDuration : DWord; aTo: TCoord2D );
begin
  inherited Create( aDuration, 0, 0 );
  FSource   := SpriteMap.Shift;
  FDest     := SpriteMap.ShiftValue(aTo);
  FDuration := Max( FDuration, Round( Sqrt( FSource.Distance( FDest ) ) ) );
  CCurrent  := Self;
end;

class function TGFXScreenMoveAnimation.Update( aDuration : DWord; aTo : TCoord2D ) : Boolean;
begin
  if CCurrent = nil then Exit( False );
  CCurrent.OnUpdate( 0 );
  CCurrent.FSource   := SpriteMap.NewShift;
  CCurrent.FDest     := SpriteMap.ShiftValue( aTo );
  CCurrent.FTime     := 0;
  CCurrent.FDuration := Max( aDuration, Round( Sqrt( CCurrent.FSource.Distance( CCurrent.FDest ) ) ) );;
  Exit( True );
end;

procedure TGFXScreenMoveAnimation.OnUpdate( aTime : DWord );
begin
  inherited OnUpdate( aTime );
  SpriteMap.NewShift := Lerp( FSource, FDest, Minf(FTime/FDuration,1.0) );
end;

procedure TGFXScreenMoveAnimation.OnDraw;
begin
end;

destructor TGFXScreenMoveAnimation.Destroy;
begin
  SpriteMap.NewShift := FDest;
  CCurrent := nil;
  inherited Destroy;
end;

constructor TGFXCellAnimation.Create( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
begin
  inherited Create( aDuration, aDelay, 0 );
  FCoord := aCoord;
  FSprite := aSprite;
  FValue  := aValue;
end;

procedure TGFXCellAnimation.OnStart;
begin
  DRL.Level.LightFlag[ FCoord, LFANIMATING ] := True;
end;

procedure TGFXCellAnimation.OnDraw;
var iSprite  : TSprite;
    iSegment : Integer;
begin
  iSprite := FSprite;
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
  SpriteMap.PushSpriteDoodad( FCoord, iSprite );
end;

destructor TGFXCellAnimation.Destroy;
begin
  DRL.Level.LightFlag[ FCoord, LFANIMATING ] := False;
  inherited Destroy;
end;

constructor TGFXItemAnimation.Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aValue : Integer );
var iThing : TThing;
begin
  inherited Create( aDuration, aDelay, aUID );
  iThing  := UIDs.Get( FUID ) as TThing;
  FValue  := aValue;
  if iThing = nil then Exit;
  FSprite := iThing.Sprite;
end;

procedure TGFXItemAnimation.OnStart;
var iThing : TThing;
begin
  iThing := UIDs.Get( FUID ) as TThing;
  if iThing <> nil then iThing.AnimCount := iThing.AnimCount + 1;
end;

procedure TGFXItemAnimation.OnDraw;
var iThing    : TThing;
    iSprite   : TSprite;
    iSegment  : Integer;
    iPosition : TVec2i;
begin
  iThing := UIDs.Get( FUID ) as TThing;
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
  iPosition.Init( (iThing.Position.X - 1)*SpriteMap.GetGridSize,(iThing.Position.Y - 1)*SpriteMap.GetGridSize);
  SpriteMap.PushSpriteItem( iPosition, iThing.Sprite, 255 );
end;

destructor TGFXItemAnimation.Destroy;
var iThing : TThing;
begin
  iThing := UIDs.Get( FUID ) as TThing;
  if iThing <> nil then iThing.AnimCount := Max( 0, iThing.AnimCount - 1 );
  inherited Destroy;
end;

constructor TGFXKillAnimation.Create( aDuration : DWord; aDelay : DWord; aUID : TUID; aReverse : Boolean = False );
var iBeing      : TBeing;
    iCols       : Integer;
    iPlayerHack : Integer;
begin
  inherited Create( aDuration, aDelay, aUID );
  FReverse := aReverse;
  iBeing   := UIDs.Get( FUID ) as TBeing;
  if iBeing = nil then Exit;
  FCount      := 2;
  // TODO: remove hack!
  if iBeing.GetLuaProtoValue('corpse') = 0 then FCount := 3;
  FSprite     := iBeing.Sprite;
  FCoord      := iBeing.Position;

  // TODO : remove hack!
  iPlayerHack := 0;
  if iBeing.IsPlayer then
  begin
    iPlayerHack := 1;
    if iBeing.SpriteMod > 0 then iPlayerHack := 2;
  end;
  FPosition.Init( (iBeing.Position.X - 1)*SpriteMap.GetGridSize,(iBeing.Position.Y - 1)*SpriteMap.GetGridSize);
  FLight      := Iif( DRL.Level.isVisible(iBeing.Position), SpriteMap.VariableLight( iBeing.Position, 30 ), 0 );

  iCols := DRL_COLS;
  if SF_LARGE in FSprite.Flags then iCols *= 2;

  if aReverse then
  begin
    FCount := 2;
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
end;

procedure TGFXKillAnimation.OnStart;
var iBeing : TBeing;
begin
  iBeing := UIDs.Get( FUID ) as TBeing;
  if iBeing <> nil then iBeing.AnimCount := iBeing.AnimCount + 1;
  DRL.Level.LightFlag[ FCoord, LFCORPSING ] := True;
end;

procedure TGFXKillAnimation.OnDraw;
var iBeing    : TBeing;
    iSprite   : TSprite;
    iSegment  : Integer;
    iPosition : TVec2i;
begin
  iSprite   := FSprite;
  iPosition := FPosition;
  iBeing    := UIDs.Get( FUID ) as TBeing;
  if iBeing <> nil then
    iPosition.Init( (iBeing.Position.X - 1)*SpriteMap.GetGridSize,(iBeing.Position.Y - 1)*SpriteMap.GetGridSize);
  iSegment := Min( ( FTime * FCount ) div FDuration, FCount - 1 );
  iSprite.SpriteID[0] := FSprites[iSegment];
  SpriteMap.PushSpriteBeing( iPosition, iSprite, FLight );
end;

destructor TGFXKillAnimation.Destroy;
var iBeing : TBeing;
begin
  // NOTE : we explicitly don't enable drawing of the dead enemy again
  if FReverse then
  begin
    iBeing := UIDs.Get( FUID ) as TBeing;
    if iBeing <> nil then iBeing.AnimCount := Max( 0, iBeing.AnimCount - 1 );
  end;
  DRL.Level.LightFlag[ FCoord, LFCORPSING ] := False;
  inherited Destroy;
end;
constructor TGFXScreenShakeAnimation.Create( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection );
begin
  inherited Create( aDuration, aDelay, 0 );
  FStrength   := aStrength;
  FFrequencyX := 0.05 + 0.8*Random;
  FFrequencyY := 0.05 + 0.8*Random;
  FDirection  := aDirection;
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
  if Assigned( SpriteMap ) then SpriteMap.Offset := iOffset;
end;

procedure TGFXScreenShakeAnimation.OnDraw;
begin
end;

destructor TGFXScreenShakeAnimation.Destroy;
begin
  if Assigned( SpriteMap ) then SpriteMap.Offset := Vec2i(0,0);
  inherited Destroy;
end;


end.

