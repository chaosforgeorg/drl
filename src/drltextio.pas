{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drltextio;
interface

uses vrltools, vtextmap, vioevent, vio, viotypes, vluamapnode, vlua,
     drlio, dfdata, dflevel, drlconfig, drlconfiguration, drlmodule;

// TDRLTextIO
//
// Architectural boundary: owns the concrete text rendering and animation
// backend. Gameplay policy belongs outside this adapter.
type TDRLTextIO = class( TDRLIO, ITextMap )
    // Creates the console driver the constructor takes ownership of.
    class function CreateDriver : TIODriver;
    constructor Create( aDriver : TIODriver; aSettings : TDRLConfiguration; aConfig : TDRLConfig ); reintroduce;
    procedure Reset; override;
    procedure PaceMultiMove; override;
    procedure Initialize( aCoreModule : TDRLModule ); override;
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
    procedure Explosion( aDelay : Integer; aWhere : TCoord2D; const aData : TExplosionData; const aCells : array of TCoord2D ); override;

    procedure VisualChanged; override;
    function GetGylph( const aCoord : TCoord2D ) : TIOGylph;
    procedure SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte ); override;
    procedure SetAutoTarget( aTarget : TCoord2D ); override;
    procedure RegisterLuaAPI( aLua : TLua ); override;

  protected
    procedure RunLauncherLayer( aLayer : TIOLayer ); override;
    procedure ExplosionMark( aCoord : TCoord2D; const aData : TExplosionData; aDelay : DWord; aSeen : Boolean ); override;
    procedure DrawHud; override;
  protected
    FTextMap        : TTextMap;
    FExpl           : TTextExplosionArray;

    FTarget         : TCoord2D;
    FTargetRange    : Byte;
    // Sprite sheets have no textures in text mode; only their IDs are issued.
    FSpriteSheets   : Integer;
  private
    // Glyph of the presented thing the player senses in each cell, with its
    // unresolved color; #0 where none. Rebuilt after each presentation update.
    FThingGlyphs    : array[1..MAXX,1..MAXY] of TIOGylph;
    procedure UpdateThingGlyphs;
  end;

implementation

uses sysutils,
     vioconsole, vtig, vvision, vutil, vlualibrary, vluagamestack, vvisualmap,
     drlanimation, drlvisual,
     dfbeing, dfitem;

// How a being sensed only by Intuition is drawn.
const IntuitionChar  = '*';
      IntuitionColor = LightMagenta;
      // Milliseconds each multi-move step shows for.
      MultiMoveDelay = 20;

class function TDRLTextIO.CreateDriver : TIODriver;
begin
  Result := CreateTerminalDriver( 80, 25 );
end;

constructor TDRLTextIO.Create( aDriver : TIODriver; aSettings : TDRLConfiguration; aConfig : TDRLConfig );
begin
  FIODriver     := aDriver;
  FTextMap      := nil;
  FSpriteSheets := -1;
  inherited Create( aSettings, aConfig );
end;

procedure TDRLTextIO.Reset;
begin
  inherited Reset;
  FTarget.Create(0,0);
  FTargetRange  := 0;
end;

procedure TDRLTextIO.PaceMultiMove;
begin
  Delay( MultiMoveDelay );
end;

procedure TDRLTextIO.Initialize( aCoreModule : TDRLModule );
begin
  inherited Initialize( CreateTerminalRenderer( 80, 25 ) );
  FTextMap       := TTextMap.Create( FConsole, Rectangle( 2,3,MAXX,MAXY ) );
end;

destructor TDRLTextIO.Destroy;
begin
  FreeAndNil( FTextMap );
  inherited Destroy;
end;

{$HINTS OFF} // To supress Hint: Parameter "x" not found

function lua_ui_texture_upload(L: Plua_State): Integer; cdecl;
begin
  Result := 0;
end;

{$HINTS ON}

function lua_ui_register_sprite_sheet(L: Plua_State): Integer; cdecl;
var iState : TLuaGameStack;
    iIO    : TDRLTextIO;
begin
  iState.Init(L);
  iIO := TDRLTextIO( lua_touserdata( L, lua_upvalueindex( 1 ) ) );
  Inc( iIO.FSpriteSheets );
  iState.Push( Integer( iIO.FSpriteSheets * 100000 ) );
  Result := 1;
end;

const lua_ui_text_lib : array[0..2] of luaL_Reg = (
      ( name : 'texture_upload';        func : @lua_ui_texture_upload),
      ( name : 'register_sprite_sheet'; func : @lua_ui_register_sprite_sheet),
      ( name : nil;                     func : nil; )
);

procedure TDRLTextIO.RegisterLuaAPI( aLua : TLua );
begin
  inherited RegisterLuaAPI( aLua );
  lua_pushlightuserdata( aLua.Raw, Self );
  aLua.Register( 'ui', lua_ui_text_lib, 1 );
end;

procedure TDRLTextIO.Update( aMSec : DWord );
begin
  if FTextMap <> nil then
    FTextMap.Update( aMSec );
  UpdatePresentation( aMSec );
  UpdateThingGlyphs;
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
  if not ( FRunStatus.State in [ DSPlaying, DSEnding ] ) then Exit(False);
  Exit( ( not FTextMap.AnimationsFinished ) or PresentationBusy );
end;

function TDRLTextIO.AnimationsBlockingFinished : Boolean;
begin
  if not ( FRunStatus.State in [ DSPlaying, DSEnding ] ) then Exit(True);
  Exit( FTextMap.AnimationsBlockingFinished );
end;

procedure TDRLTextIO.ClearAnimations;
begin
  FTextMap.ClearAnimations;
  inherited ClearAnimations;
end;

procedure TDRLTextIO.Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0 );
var iChr : Char;
begin
  if FOptions.HighASCII then iChr := Chr(219) else iChr := '#';
  if FSettings.Flash then
    FTextMap.AddAnimation( TTextBlinkAnimation.Create( IOGylph( iChr, aColor ), aDuration, aDelay ) );
end;

procedure TDRLTextIO.addMissileAnimation(aDuration: DWord; aDelay: DWord; aSource,
  aTarget: TCoord2D; aColor: Byte; aPic: Char; aDrawDelay: Word;
  aSprite: TSprite; aRay: Boolean; aTrailNID : Word);
begin
  if not ( FRunStatus.State in [ DSPlaying, DSEnding ] ) then Exit;
  if aRay
    then FTextMap.AddAnimation( TTextRayAnimation.Create( Level, aSource, aTarget, IOGylph( aPic, aColor ), aDuration, aDelay, Player.Vision ) )
    else FTextMap.AddAnimation( TTextBulletAnimation.Create( Level, aSource, aTarget, IOGylph( aPic, aColor ), aDuration, aDelay, Player.Vision ) );
end;

procedure TDRLTextIO.addMarkAnimation(aDuration: DWord; aDelay: DWord;
  aCoord: TCoord2D; aSprite : TSprite; aColor: Byte; aPic: Char);
begin
  if not ( FRunStatus.State in [ DSPlaying, DSEnding ] ) then Exit;
  FTextMap.AddAnimation( TTextMarkAnimation.Create( aCoord, IOGylph( aPic, aColor ), aDuration, aDelay ) );
end;

procedure TDRLTextIO.addSoundAnimation(aDelay: DWord; aPosition: TCoord2D; aSoundID: DWord);
begin
  if not ( FRunStatus.State in [ DSPlaying, DSEnding ] ) then Exit;
  FTextMap.AddAnimation( TSoundEventAnimation.Create( Self, aDelay, aPosition, aSoundID ) )
end;

procedure TDRLTextIO.ExplosionMark( aCoord : TCoord2D; const aData : TExplosionData; aDelay : DWord; aSeen : Boolean );
begin
  if aSeen then
    FTextMap.AddAnimation( TTextExplosionAnimation.Create( aCoord, '*', FExpl, aDelay ) );
end;

procedure TDRLTextIO.SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte );
begin
  FTargetEnabled := True;
  FTarget        := aTarget;
  FTargetRange   := aRange;
  if FLayers.IsEmpty then
    FConsole.ShowCursor;
  FConsole.MoveCursor( aTarget.x+1, aTarget.y+2 );
end;

procedure TDRLTextIO.SetAutoTarget( aTarget : TCoord2D );
begin
  inherited SetAutoTarget( aTarget );
  if not FTargetEnabled then
  begin
    if FLayers.IsEmpty then
      FConsole.ShowCursor;
    FConsole.MoveCursor( aTarget.x+1, aTarget.y+2 );
  end;
end;

procedure TDRLTextIO.RunLauncherLayer( aLayer : TIOLayer );
begin
  inherited Initialize( CreateTerminalRenderer( 80, 25 ) );
  inherited RunLauncherLayer( aLayer );
  inherited Initialize( TIOConsoleRenderer( nil ) );
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
    if aChar = ' ' then aChar := FConsole.GetChar( iPos.X, iPos.Y );
    iPos := Point( iPos.X - 1, iPos.Y - 1 );
    if FEffect = StatusInvert
       then VTIG_FreeChar( aChar, iPos, Black, LightGray )
       else VTIG_FreeChar( aChar, iPos, aColor );
  end;
begin
  FConsole.Clear;
  FTextMap.OnRedraw;

  inherited DrawHud;

  if FTargetEnabled then
  begin
    iLevel := Level;
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

procedure TDRLTextIO.UpdateThingGlyphs;
var iLevel   : TLevel;
    iMap     : TDRLVisualMap;
    iVisual  : TDRLVisualThing;
    iCoord   : TCoord2D;
    iBeings  : Boolean;
    iPresent : Boolean;
    iVisible : Boolean;
    iBeing   : TBeing;
    iItem    : TItem;
    i        : Integer;

  procedure Put( aASCII : Char; aColor : TIOColor );
  begin
    FThingGlyphs[ iCoord.X, iCoord.Y ].Init( aASCII, aColor );
  end;

begin
  FillChar( FThingGlyphs, SizeOf( FThingGlyphs ), 0 );
  if FVisual = nil then Exit;
  iLevel := Level;
  iMap   := FVisual.Map;
  // Later passes draw over earlier ones: beings over items, and things in
  // the level over things only clips or holds still present. A thing the
  // player does not sense leaves what is below it.
  for iBeings in Boolean do
    for iPresent in Boolean do
      for i := 0 to FVisual.Things.Count - 1 do
      begin
        iVisual := TDRLVisualThing( FVisual.Things.Things[i] );
        if ( not iVisual.Shown ) or ( iVisual.IsBeing <> iBeings ) or
           ( iVisual.Present <> iPresent ) or ( not iMap.Contains( iVisual.Coord ) ) then Continue;
        iCoord   := iVisual.Coord;
        iVisible := iMap.Visible( iCoord );
        // The live thing, while it exists, decides how it may be sensed.
        if iBeings then
        begin
          iBeing := iLevel.Context.UIDs.Get( iVisual.UID ) as TBeing;
          if iVisible or ( ( iBeing <> nil ) and iLevel.BeingExplored( iCoord, iBeing ) ) then
            Put( iVisual.Gylph.ASCII, iVisual.Gylph.Color )
          else if ( iBeing <> nil ) and iLevel.BeingIntuited( iCoord, iBeing ) then
            Put( IntuitionChar, IntuitionColor );
        end
        else
        begin
          iItem := iLevel.Context.UIDs.Get( iVisual.UID ) as TItem;
          if iVisible or ( ( iItem <> nil ) and iLevel.ItemVisible( iCoord, iItem ) ) then
            Put( iVisual.Gylph.ASCII, iVisual.Gylph.Color )
          else if ( ( iItem <> nil ) and iLevel.ItemExplored( iCoord, iItem ) ) or
                  ( ( iItem = nil ) and iMap.Explored( iCoord ) ) then
            Put( iVisual.Gylph.ASCII, DarkGray );
        end;
      end;
end;

procedure TDRLTextIO.VisualChanged;
begin
  // Glyphs are read from the visual state.
  if FVisual <> nil
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
        MULTIPORTAL : case (( Player.Statistics.GameTime div 10 ) mod 3) of
                        0 : aAtr := LIGHTMAGENTA;
                        1 : aAtr := MAGENTA;
                        2 : aAtr := WHITE;
                      end;
      end;
    end;
    {$IFDEF CORNERMAP}
    if iLevel.Corner( aCoord ) then aAtr := Yellow;
    {$ENDIF CORNERMAP}
    if FEffect <> StatusNormal then
      case FEffect of
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
    iPic      : Char;
    iCell     : DWord;
    iStyle    : Integer;
    iVisible  : Boolean;
    iExplored : Boolean;
    iBlood    : Boolean;
    iThing    : TIOGylph;
    iMap      : TDRLVisualMap;
    iState    : TDRLVisualCell;
begin
  iLevel   := Level;
  iMap     := FVisual.Map;
  iVisible := iMap.Visible( aCoord );

  // Things, then terrain, both from the presented level.
  if iMap.Contains( aCoord ) then
  begin
    iThing := FThingGlyphs[ aCoord.X, aCoord.Y ];
    if iThing.ASCII <> #0 then
      Exit( IOGylph( iThing.ASCII, GetColor( iThing.Color, aCoord, True ) ) );
  end;

  // A fading cell switches glyphs halfway through.
  if iMap.Progress( aCoord ) >= 0.5
    then iState := iMap.State( aCoord, vlTarget )
    else iState := iMap.State( aCoord, vlShown );
  iExplored := iState.Flags and VCF_EXPLORED <> 0;
  if iState.Top <> 0
    then iCell := iState.Top
    else iCell := iState.Bottom;

  iColor   := LightGray;
  iChar    := ' ';
  if FOptions.HighASCII
    then iPic := iLevel.Data.Cells[ iCell ].PicChr
    else iPic := iLevel.Data.Cells[ iCell ].PicLow;
  with iLevel.Data.Cells[ iCell ] do
  if iPic <> ' ' then
  begin
    if iVisible or iExplored then
      iChar := iPic;
    if iVisible then
    begin
      iBlood := ( iState.Flags and VCF_BLOOD <> 0 ) and (BloodColor <> 0);
      if iBlood
         then iColor := BloodColor
         else
         begin
           iStyle := iState.Style;
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

procedure TDRLTextIO.Explosion( aDelay : Integer; aWhere: TCoord2D; const aData : TExplosionData; const aCells : array of TCoord2D );
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
  inherited Explosion( aDelay, aWhere, aData, aCells );
  FTextMap.AddAnimation( TTextClearMarkAnimation.Create( aDelay + aData.Range*aData.Delay ) );
end;

end.
