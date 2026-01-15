{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drltextio;
interface

uses vrltools, vtextmap, drlio, dfdata;

type TDRLTextIO = class( TDRLIO )
    constructor Create; reintroduce;
    procedure Reset; override;
    procedure Initialize; override;
    destructor Destroy; override;
    procedure Update( aMSec : DWord ); override;

    procedure WaitForAnimation( aStrict : Boolean = True ); override;
    function AnimationsRunning : Boolean; override;
    function AnimationsBlockingFinished : Boolean; override;
    procedure AnimationWipe; override;
    procedure Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0); override;
    procedure addMissileAnimation( aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aColor : Byte; aPic : Char; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False ); override;
    procedure addMarkAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aColor : Byte; aPic : Char ); override;
    procedure addSoundAnimation( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord ); override;
    procedure Explosion( aDelay : Integer; aWhere : TCoord2D; aData : TExplosionData ); override;

    procedure SetTextMap( aMap : ITextMap );
    procedure SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte ); override;
    procedure SetAutoTarget( aTarget : TCoord2D ); override;

    procedure RunModuleChoice; override;
  protected
    procedure ExplosionMark( aCoord : TCoord2D; aColor : Byte; aDuration : DWord; aDelay : DWord ); override;
    procedure DrawHud; override;
  protected
    FTextMap        : TTextMap;
    FExpl           : TTextExplosionArray;

    FTarget         : TCoord2D;
    FTargetRange    : Byte;
  end;

implementation

uses sysutils,
     viotypes,
     {$IFDEF WINDOWS}
     vtextio, vtextconsole,
     {$ELSE}
     vcursesio, vcursesconsole,
     {$ENDIF}
     vioconsole, vtig, vvision, vutil,
     drlbase, drlanimation,
     dflevel, dfplayer;

constructor TDRLTextIO.Create;
begin
  FTextMap  := nil;
  {$IFDEF WINDOWS}
  FIODriver := TTextIODriver.Create( 80, 25 );
  {$ELSE}
  FIODriver := TCursesIODriver.Create( 80, 25 );
  {$ENDIF}
  if (FIODriver.GetSizeX < 80) or (FIODriver.GetSizeY < 25) then
    raise EIOException.Create('Too small console available, resize your console to 80x25!');
  inherited Create;
end;

procedure TDRLTextIO.Reset;
begin
  inherited Reset;
  FTarget.Create(0,0);
  FTargetRange  := 0;
end;

procedure TDRLTextIO.Initialize;
var iRenderer : TIOConsoleRenderer;
begin
  {$IFDEF WINDOWS}
  iRenderer := TTextConsoleRenderer.Create( 80, 25, [VIO_CON_BGCOLOR, VIO_CON_CURSOR] );
  {$ELSE}
  iRenderer := TCursesConsoleRenderer.Create( 80, 25, [VIO_CON_BGCOLOR, VIO_CON_CURSOR] );
  {$ENDIF}
  inherited Initialize( iRenderer );
  FTextMap       := TTextMap.Create( FConsole, Rectangle( 2,3,MAXX,MAXY ) );
end;

destructor TDRLTextIO.Destroy;
begin
  FreeAndNil( FTextMap );
  inherited Destroy;
end;

procedure TDRLTextIO.Update( aMSec : DWord );
begin
  if FTextMap <> nil then
    FTextMap.Update( aMSec );
  if FTargeting and FLayers.IsEmpty
     then FConsole.ShowCursor;
  inherited Update( aMSec );
  VTIG_EventClear;
end;

procedure TDRLTextIO.WaitForAnimation( aStrict : Boolean = True );
begin
  inherited WaitForAnimation( aStrict );
  if aStrict then
    FTextMap.ClearAnimations;
end;

function TDRLTextIO.AnimationsRunning : Boolean;
begin
  if DRL.State <> DSPlaying then Exit(False);
  Exit( not FTextMap.AnimationsFinished );
end;

function TDRLTextIO.AnimationsBlockingFinished : Boolean;
begin
  if DRL.State <> DSPlaying then Exit(True);
  Exit( FTextMap.AnimationsBlockingFinished );
end;

procedure TDRLTextIO.AnimationWipe;
begin
  FTextMap.ClearAnimations;
end;

procedure TDRLTextIO.Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0 );
var iChr : Char;
begin
  if Option_HighASCII then iChr := Chr(219) else iChr := '#';
  if Setting_Flash then
    FTextMap.AddAnimation( TTextBlinkAnimation.Create( IOGylph( iChr, aColor ), aDuration, aDelay ) );
end;

procedure TDRLTextIO.addMissileAnimation(aDuration: DWord; aDelay: DWord; aSource,
  aTarget: TCoord2D; aColor: Byte; aPic: Char; aDrawDelay: Word;
  aSprite: TSprite; aRay: Boolean);
begin
  if DRL.State <> DSPlaying then Exit;
  if aRay
    then FTextMap.AddAnimation( TTextRayAnimation.Create( DRL.Level, aSource, aTarget, IOGylph( aPic, aColor ), aDuration, aDelay, Player.Vision ) )
    else FTextMap.AddAnimation( TTextBulletAnimation.Create( DRL.Level, aSource, aTarget, IOGylph( aPic, aColor ), aDuration, aDelay, Player.Vision ) );
end;

procedure TDRLTextIO.addMarkAnimation(aDuration: DWord; aDelay: DWord;
  aCoord: TCoord2D; aSprite : TSprite; aColor: Byte; aPic: Char);
begin
  if DRL.State <> DSPlaying then Exit;
  FTextMap.AddAnimation( TTextMarkAnimation.Create( aCoord, IOGylph( aPic, aColor ), aDuration, aDelay ) );
end;

procedure TDRLTextIO.addSoundAnimation(aDelay: DWord; aPosition: TCoord2D; aSoundID: DWord);
begin
  if DRL.State <> DSPlaying then Exit;
  FTextMap.AddAnimation( TSoundEventAnimation.Create( aDelay, aPosition, aSoundID ) )
end;

procedure TDRLTextIO.ExplosionMark( aCoord : TCoord2D; aColor : Byte; aDuration : DWord; aDelay : DWord );
begin
  FTextMap.AddAnimation( TTextExplosionAnimation.Create( aCoord, '*', FExpl, aDelay ) );
end;

procedure TDRLTextIO.SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte );
begin
  FTargetEnabled := True;
  FTarget        := aTarget;
  FTargetRange   := aRange;
  if FLayers.IsEmpty then
    IO.Console.ShowCursor;
  IO.Console.MoveCursor( aTarget.x+1, aTarget.y+2 );
end;

procedure TDRLTextIO.SetAutoTarget( aTarget : TCoord2D );
begin
  inherited SetAutoTarget( aTarget );
  if not FTargetEnabled then
  begin
    if FLayers.IsEmpty then
      IO.Console.ShowCursor;
    IO.Console.MoveCursor( aTarget.x+1, aTarget.y+2 );
  end;
end;

procedure TDRLTextIO.RunModuleChoice;
var iRenderer : TIOConsoleRenderer;
begin
  {$IFDEF WINDOWS}
  iRenderer := TTextConsoleRenderer.Create( 80, 25, [VIO_CON_BGCOLOR, VIO_CON_CURSOR] );
  {$ELSE}
  iRenderer := TCursesConsoleRenderer.Create( 80, 25, [VIO_CON_BGCOLOR, VIO_CON_CURSOR] );
  {$ENDIF}
  inherited Initialize( iRenderer );
  inherited RunModuleChoice;
  inherited Initialize( nil );
  Reset;
end;

procedure TDRLTextIO.DrawHud;
var iColor      : TIOColor;
    iCurrent    : TCoord2D;
    iLevel      : TLevel;
    iTargetLine : TVisionRay;

  procedure Paint ( aCoord : TCoord2D; aColor : TIOColor; aChar : Char = ' ') ;
  var iPos        : TIOPoint;
  begin
    iPos := Point( aCoord.x + 1, aCoord.y + 2 );
    if aChar = ' ' then aChar := IO.Console.GetChar( iPos.X, iPos.Y );
    if StatusEffect = StatusInvert
       then VTIG_FreeChar( aChar, iPos, Black, LightGray )
       else VTIG_FreeChar( aChar, iPos, aColor );
  end;
begin
  FConsole.Clear;
  FTextMap.OnRedraw;

  inherited DrawHud;

  if FTargetEnabled then
  begin
    iLevel := DRL.Level;
    if FTargetLast then
      Paint( Player.TargetPos, Yellow );
    if ( Player.Position <> FTarget ) then
    begin
      iColor := Green;
      iTargetLine.Init( iLevel, Player.Position, FTarget );
      repeat
        iTargetLine.Next;
        iCurrent := iTargetLine.GetC;
        if not iLevel.isProperCoord( iCurrent ) then Break;
        if not iLevel.isVisible( iCurrent ) then iColor := Red;
        if iColor = Green then if iTargetLine.Cnt > FTargetRange then icolor := Yellow;
        if iTargetLine.Done then Paint( iCurrent, iColor, 'X' )
                            else Paint( iCurrent, iColor, '*' );
        if not iLevel.isPassable( iCurrent ) then iColor := Red;
      until (iTargetLine.Done) or (iTargetLine.cnt > 30);
    end;
  end;
end;

procedure TDRLTextIO.SetTextMap( aMap : ITextMap );
begin
  FTextMap.SetMap( aMap );
end;

procedure TDRLTextIO.Explosion( aDelay : Integer; aWhere: TCoord2D; aData : TExplosionData );
begin
  FTextMap.FreezeMarks;
  FExpl := nil;
  SetLength( FExpl, 4 );
  FExpl[0].Time := aData.Delay;
  FExpl[1].Time := aData.Delay;
  FExpl[2].Time := aData.Delay;
  FExpl[3].Time := aData.Delay;
  case aData.Color of
    Blue    : begin FExpl[3].Color := Blue;    FExpl[0].Color := LightBlue;  FExpl[1].Color := White; end;
    Magenta : begin FExpl[3].Color := Magenta; FExpl[0].Color := Red;        FExpl[1].Color := Blue; end;
    Green   : begin FExpl[3].Color := Green;   FExpl[0].Color := LightGreen; FExpl[1].Color := White; end;
    LightRed: begin FExpl[3].Color := LightRed;FExpl[0].Color := Yellow;     FExpl[1].Color := White; end;
     else     begin FExpl[3].Color := Red;     FExpl[0].Color := LightRed;   FExpl[1].Color := Yellow; end;
  end;
  FExpl[2].Color := FExpl[0].Color;
  inherited Explosion( aDelay, aWhere, aData );
  FTextMap.AddAnimation( TTextClearMarkAnimation.Create( aDelay + aData.Range*aData.Delay ) );
end;

end.

