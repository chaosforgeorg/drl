{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drltextio;
interface

uses vrltools, vtextmap, vioevent, viotypes, vluamapnode,
     drlio, dfdata, dflevel;

// TDRLTextIO
//
// Architectural boundary: owns the concrete text rendering and animation
// backend. Gameplay policy belongs outside this adapter.
type TDRLTextIO = class( TDRLIO, ITextMap )
    constructor Create; reintroduce;
    procedure Reset; override;
    procedure Initialize; override;
    destructor Destroy; override;
    procedure Update( aMSec : DWord ); override;
    function OnEvent( const aEvent : TIOEvent ) : Boolean; override;

    function AnimationsRunning : Boolean; override;
    function AnimationsBlockingFinished : Boolean; override;
    procedure ClearAnimations; override;
    procedure Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0); override;
    procedure addMissileAnimation( aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aColor : Byte; aPic : Char; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False; aTrailNID : Word = 0 ); override;
    procedure addMarkAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aColor : Byte; aPic : Char ); override;
    procedure addSoundAnimation( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord ); override;
    procedure Explosion( aDelay : Integer; aWhere : TCoord2D; aData : TExplosionData ); override;

    procedure SetLevel( aLevel : TLuaMapNode ); override;
    function GetGylph( const aCoord : TCoord2D ) : TIOGylph;
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
     {$IFDEF WINDOWS}
     vtextio, vtextconsole,
     {$ELSE}
     vcursesio, vcursesconsole,
     {$ENDIF}
     vioconsole, vtig, vvision, vutil,
     drlbase, drlanimation,
     dfplayer, dfbeing, dfitem;

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

function TDRLTextIO.OnEvent( const aEvent : TIOEvent ) : Boolean;
var iWide : WideString;
begin
  if ( aEvent.EType = VEVENT_KEYDOWN ) and ( aEvent.Key.ASCII <> #0 ) then
  begin
    iWide := UTF8Decode( UTF8String( aEvent.Key.ASCII ) );
    VTIG_GetIOState.EventState.AppendText( PWideChar( iWide ) );
  end;
  Exit( inherited OnEvent( aEvent ) );
end;

function TDRLTextIO.AnimationsRunning : Boolean;
begin
  if Session.State <> DSPlaying then Exit(False);
  Exit( not FTextMap.AnimationsFinished );
end;

function TDRLTextIO.AnimationsBlockingFinished : Boolean;
begin
  if Session.State <> DSPlaying then Exit(True);
  Exit( FTextMap.AnimationsBlockingFinished );
end;

procedure TDRLTextIO.ClearAnimations;
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
  aSprite: TSprite; aRay: Boolean; aTrailNID : Word);
begin
  if Session.State <> DSPlaying then Exit;
  if aRay
    then FTextMap.AddAnimation( TTextRayAnimation.Create( Session.Level, aSource, aTarget, IOGylph( aPic, aColor ), aDuration, aDelay, Player.Vision ) )
    else FTextMap.AddAnimation( TTextBulletAnimation.Create( Session.Level, aSource, aTarget, IOGylph( aPic, aColor ), aDuration, aDelay, Player.Vision ) );
end;

procedure TDRLTextIO.addMarkAnimation(aDuration: DWord; aDelay: DWord;
  aCoord: TCoord2D; aSprite : TSprite; aColor: Byte; aPic: Char);
begin
  if Session.State <> DSPlaying then Exit;
  FTextMap.AddAnimation( TTextMarkAnimation.Create( aCoord, IOGylph( aPic, aColor ), aDuration, aDelay ) );
end;

procedure TDRLTextIO.addSoundAnimation(aDelay: DWord; aPosition: TCoord2D; aSoundID: DWord);
begin
  if Session.State <> DSPlaying then Exit;
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
    iTargetLine : TAssistedRay;
    iTargetRange: Byte;

  procedure Paint ( aCoord : TCoord2D; aColor : TIOColor; aChar : Char = ' ') ;
  var iPos        : TIOPoint;
  begin
    iPos := Point( aCoord.x + 1, aCoord.y + 2 );
    if aChar = ' ' then aChar := IO.Console.GetChar( iPos.X, iPos.Y );
    iPos := Point( iPos.X - 1, iPos.Y - 1 );
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
    iLevel := Session.Level;
    if ( Player.Position <> FTarget ) then
    begin
      iColor := Green;
      iTargetRange := Distance( Player.Position, FTarget );
      iTargetLine.Init( iLevel, Player.Position, FTarget, iTargetRange, Player.Vision, Player.GetVisionMap );
      repeat
        iTargetLine.Next;
        iCurrent := iTargetLine.Current;
        if not iLevel.isProperCoord( iCurrent ) then Break;
        if not iLevel.isVisible( iCurrent ) then iColor := Red;
        if iColor = Green then if iTargetLine.Steps > FTargetRange then icolor := Yellow;
        if iTargetLine.Done then Paint( iCurrent, iColor, 'X' )
                            else Paint( iCurrent, iColor, '*' );
        if not iLevel.isShotPassable( iCurrent ) then iColor := Red;
      until (iTargetLine.Done) or (iTargetLine.Steps > 30);
    end;
  end;
end;

procedure TDRLTextIO.SetLevel( aLevel : TLuaMapNode );
begin
  inherited SetLevel( aLevel );
  if aLevel <> nil
    then FTextMap.SetMap( Self )
    else FTextMap.SetMap( nil );
end;

function TDRLTextIO.GetGylph( const aCoord : TCoord2D ) : TIOGylph;
var iLevel : TLevel;
  function GetColor( aAtr : Byte; aCoord : TCoord2D; aHighlight : Boolean = False ) : TIOColor;
  var iAlternate : Boolean;
  begin
    if aAtr > 16 then
    begin
      iAlternate := ((aCoord.x+aCoord.y) mod 2) = 0;
      case aAtr of
        COLOR_WATER : if iAlternate then aAtr := BLUE     else aAtr := LIGHTBLUE;
        COLOR_ACID  : if iAlternate then aAtr := GREEN    else aAtr := LIGHTGREEN;
        COLOR_LAVA  : if iAlternate then aAtr := YELLOW   else aAtr := RED;
        COLOR_BLOOD : if iAlternate then aAtr := LIGHTRED else aAtr := RED;
        COLOR_MUD   : if iAlternate then aAtr := YELLOW   else aAtr := BROWN;
        MULTIPORTAL : case (( FSession.Player.Statistics.GameTime div 10 ) mod 3) of
                        0 : aAtr := LIGHTMAGENTA;
                        1 : aAtr := MAGENTA;
                        2 : aAtr := WHITE;
                      end;
      end;
    end;
    {$IFDEF CORNERMAP}
    if iLevel.Corner( aCoord ) then aAtr := Yellow;
    {$ENDIF CORNERMAP}
    if StatusEffect <> StatusNormal then
      case StatusEffect of
        StatusRed     : if aHighlight then aAtr := LightRed     else aAtr := Red;
        StatusGreen   : if aHighlight then aAtr := LightGreen   else aAtr := Green;
        StatusBlue    : if aHighlight then aAtr := LightBlue    else aAtr := Blue;
        StatusCyan    : if aHighlight then aAtr := LightCyan    else aAtr := Cyan;
        StatusMagenta : if aHighlight then aAtr := LightMagenta else aAtr := Magenta;
        StatusYellow  : if aHighlight then aAtr := Yellow       else aAtr := Brown;
        StatusGray    : if aHighlight then aAtr := LightGray    else aAtr := DarkGray;
        StatusWhite   : if aHighlight then aAtr := White        else aAtr := DarkGray;
        StatusInvert  : if aHighlight then aAtr := 16*LightGray else aAtr := 16*LightGray+DarkGray;
      end;
    Exit( aAtr );
  end;
var iColor    : TIOColor;
    iChar     : Char;
    iCell     : DWord;
    iStyle    : Integer;
    iVisible  : Boolean;
    iExplored : Boolean;
    iBlood    : Boolean;
    iItem     : TItem;
    iBeing    : TBeing;
begin
  iLevel   := TLevel( FLevel );
  iBeing   := iLevel.Being[ aCoord ];

  if iLevel.BeingVisible( aCoord, iBeing ) or iLevel.BeingExplored( aCoord, iBeing) then
    Exit( IOGylph( iBeing.Picture, GetColor( iBeing.Color, aCoord, True ) ) );

  if iLevel.BeingIntuited( aCoord, iBeing ) then
    Exit( IOGylph( Option_IntuitionChar, GetColor( Option_IntuitionColor, aCoord, True ) ) );

  iItem    := iLevel.Item[ aCoord ];

  if iLevel.ItemVisible( aCoord, iItem ) then
    Exit( IOGylph( iItem.Picture, GetColor( iItem.Color, aCoord, True ) ) );

  if iLevel.ItemExplored( aCoord, iItem ) then
    Exit( IOGylph( iItem.Picture, GetColor( DarkGray, aCoord, True ) ) );

  iVisible  := iLevel.isVisible( aCoord );
  iExplored := iLevel.CellExplored( aCoord );
  iCell     := iLevel.Cell[ aCoord ];

  iColor   := LightGray;
  iChar    := ' ';
  with iLevel.Data.Cells[ iCell ] do
  if PicChr <> ' ' then
  begin
    if iVisible or iExplored then
      if Option_HighASCII
        then iChar := PicChr
        else iChar := PicLow;
    if iVisible then
    begin
      iBlood := iLevel.LightFlag[ aCoord, LFBLOOD ] and (BloodColor <> 0);
      if iBlood
         then iColor := BloodColor
         else
         begin
           iStyle := iLevel.CStyle[ aCoord ];
           iColor := LightColor[ iStyle ];
           if iColor = 0 then
             iColor := LightColor[ 0 ];
         end;
    end
    else if iExplored then iColor := DarkColor;
  end;
  Result.ASCII := iChar;
  Result.Color := GetColor( iColor, aCoord, CF_HIGHLIGHT in iLevel.Data.Cells[ iCell ].Flags );
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
