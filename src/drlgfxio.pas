{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlgfxio;
interface
uses vglquadrenderer, vgltypes, vluaconfig, vioevent, viotypes, vuielement, vimage,
     vrltools, vutil, vtextures, vvector, vbitmapfont, vio,
     drlio, drlspritemap, drlanimation, drlminimap, dfdata, dfthing;

type

{ TDRLGFXIO }

 TDRLGFXIO = class( TDRLIO )
    constructor Create; reintroduce;
    procedure Reset; override;
    procedure Initialize; override;
    procedure Reconfigure( aConfig : TLuaConfig ); override;
    procedure Configure( aConfig : TLuaConfig; aReload : Boolean = False ); override;
    procedure Update( aMSec : DWord ); override;
    function PushLayer( aLayer : TIOLayer ) : TIOLayer; override;
    function OnEvent( const iEvent : TIOEvent ) : Boolean; override;
    procedure UpdateMinimap;
    destructor Destroy; override;

    procedure WaitForAnimation; override;
    function AnimationsRunning : Boolean; override;
    procedure AnimationWipe; override;
    procedure Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0); override;
    procedure addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection ); override;
    procedure addMoveAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aBeing : Boolean; aWipeBump : Boolean ); override;
    procedure addBumpAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aAmount : Single ); override;
    procedure addScreenMoveAnimation( aDuration : DWord; aTo : TCoord2D ); override;
    procedure addCellAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer ); override;
    procedure addItemAnimation( aDuration : DWord; aDelay : DWord; aItem : TThing; aValue : Integer ); override;
    procedure addKillAnimation( aDuration : DWord; aDelay : DWord; aBeing : TThing; aReverse : Boolean = False ); override;
    procedure addMissileAnimation( aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aColor : Byte; aPic : Char; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False ); override;
    procedure addMarkAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aColor : Byte; aPic : Char ); override;
    procedure addSoundAnimation( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord ); override;
    procedure addRumbleAnimation( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord ); override;
    function getUIDPosition( aUID : TUID; var aPosition : TVec2i ) : Boolean;
    procedure PulseBlood( aValue : Single ); override;

    procedure DeviceChanged;
    function DeviceCoordToConsoleCoord( aCoord : TIOPoint ) : TIOPoint; override;
    function ConsoleCoordToDeviceCoord( aCoord : TIOPoint ) : TIOPoint; override;
    procedure RenderUIBackgroundBlock( aUL, aBR : TIOPoint; aOpacity : Single = 0.85; aZ : Integer = 0 ); override;
    procedure RenderUIBackground( aTexture : TTextureID; aZ : Integer = 0 ); override;

    procedure SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte ); override;
    procedure SetAutoTarget( aTarget : TCoord2D ); override;
    procedure Focus( aCoord : TCoord2D ); override;
    procedure FinishTargeting; override;

    // Gamepad
    function GetPadLTrigger : Boolean; override;
    function GetPadRTrigger : Boolean; override;
    function GetPadLDir     : TCoord2D; override;
    function IsGamepad      : Boolean; override;

    // Fade control
    procedure FadeIn( aForce : Boolean = False ); override;
    procedure FadeOut( aTime : Single = 0.5; aWait : Boolean = False ); override;
    procedure FadeReset; override;
    procedure FadeWait; override;

    procedure RunModuleChoice; override;
 protected
    procedure DrawHUD; override;
    function ReadDefaultFont : TBitmapFont;
    procedure ExplosionMark( aCoord : TCoord2D; aColor : Byte; aDuration : DWord; aDelay : DWord ); override;
    function FullScreenCallback( aEvent : TIOEvent ) : Boolean;
    procedure ResetVideoMode;
    procedure RecalculateScaling( aInitialize : Boolean );
    procedure CalculateConsoleParams;
    procedure SetMinimapScale( aScale : Byte );
  private
    FQuadSheet   : TGLQuadList;
    FTextSheet   : TGLQuadList;
    FPostSheet   : TGLQuadList;
    FQuadRenderer: TGLQuadRenderer;
    FProjection  : TMatrix44;

    FFontMult    : Byte;
    FTileMult    : Byte;
    FMiniScale   : Byte;
    FLinespace   : Word;
    FVPadding    : DWord;
    FTileScale   : Single;
    FScaledScreen: TGLVec2i;

    FCellX       : Integer;
    FCellY       : Integer;
    FFontSizeX   : Integer;
    FFontSizeY   : Integer;
    FFullscreen  : Boolean;

    FGPLeft      : TVec2f;
    FGPRight     : TVec2f;
    FGPLeftDir   : TCoord2D;
    FGPCamera    : Single;
    FGPLTrigger  : Boolean;
    FGPRTrigger  : Boolean;
    FGPDetected  : Boolean;

    FBloodValue       : Single;
    FBloodValueTarget : Single;

    FLastMouseTime : QWord;
    FMouseLock     : Boolean;
    FMCursor       : TDRLMouseCursor;
    FMinimap       : TMinimap;

    FAnimations     : TAnimationManager;
    FTextures       : TTextureManager;

    FFadeDirection  : Integer;
    FFadeAlpha      : Single;
    FFadeTime       : Single;
    FFadeTimer      : Single;

    FConsoleSizeX : Integer;
    FConsoleSizeY : Integer;
  public
    property QuadSheet   : TGLQuadList read FQuadSheet;
    property TextSheet   : TGLQuadList read FTextSheet;
    property PostSheet   : TGLQuadList read FPostSheet;
    property FontMult    : Byte        read FFontMult;
    property TileScale   : Single      read FTileScale;
    property ScaledScreen: TGLVec2i    read FScaledScreen;
    property MCursor     : TDRLMouseCursor read FMCursor;
    property Textures    : TTextureManager read FTextures;
  end;

implementation

uses {$IFDEF WINDOWS}windows,{$ENDIF}
     classes, sysutils, math,
     vdebug, vlog, vmath, vdf, vgl3library, vuid, vvision,
     vglimage, vsdlio, vcolor, vglconsole, vioconsole,
     vtig, vtigstyle, vtigio,
     dfplayer, dfitem, dflevel,
     drlbase, drlconfiguration, drlmodule;


procedure TDRLGFXIO.RecalculateScaling( aInitialize : Boolean );
var iWidth        : Integer;
    iHeight       : Integer;
    iOldFontMult  : Integer;
    iOldMiniScale : Integer;
begin
  iWidth      := FIODriver.GetSizeX;
  iHeight     := FIODriver.GetSizeY;
  iOldFontMult  := FFontMult;
  iOldMiniScale := FMiniScale;
  FFontMult   := Configuration.GetInteger( 'font_multiplier' );
  FTileMult   := Configuration.GetInteger( 'tile_multi' );
  FMiniScale  := Configuration.GetInteger( 'minimap_multi' );

  if FFontMult = 0 then
  begin
    if FFontSizeX = 8 then
    begin
      if (iWidth >= 1920) and (iHeight >= 1080)
        then FFontMult := 3
        else FFontMult := 2;
    end
    else
      if (iWidth >= 1600) and (iHeight >= 900)
        then FFontMult := 2
        else FFontMult := 1;
  end;
  if FTileMult  = 0 then
    if (iWidth >= 1050) and (iHeight >= 1050)
      then FTileMult := 3
      else FTileMult := 1;
  if FMiniScale = 0 then
  begin
    FMiniScale := iWidth div 220;
    FMiniScale := Max( 3, FMiniScale );
    FMiniScale := Min(10, FMiniScale );
  end
  else
  begin
    if FMiniScale = 7 then FMiniScale := 10;
    if FMiniScale = 6 then FMiniScale := 8;
    if FMiniScale = 5 then FMiniScale := 6;
  end;

  FTileScale   := Single(FTileMult - 1);
  if FTileMult = 1 then FTileScale := 1.0;
  if FTileMult = 2 then FTileScale := 1.5;
  FScaledScreen.Init( Round( iWidth / FTileScale ), Round( iHeight / FTileScale ) );

  if aInitialize then Exit;

  if FMiniScale <> iOldMiniScale then
    SetMinimapScale( FMiniScale );

  SpriteMap.Recalculate;
  if Player <> nil then
    SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position );

  if FFontMult <> iOldFontMult then
  begin
    CalculateConsoleParams;
    TGLConsoleRenderer( FConsole ).SetPositionScale( (FIODriver.GetSizeX - FConsoleSizeX*FFontSizeX*FFontMult) div 2, 0, FLineSpace, FFontMult );
  end;
end;

constructor TDRLGFXIO.Create;
var iSDLFlags   : TSDLIOFlags;
    iMode       : TIODisplayMode;
    iWidth      : Integer;
    iHeight     : Integer;
begin
  {$IFDEF WINDOWS}
  if not GodMode then
  begin
    FreeConsole;
    vdebug.DebugWriteln := nil;
  end
  else
  begin
    Logger.AddSink( TConsoleLogSink.Create( LOGDEBUG, True ) );
  end;
  {$ENDIF}
  FFullscreen := Configuration.GetBoolean( 'fullscreen' );
  if ForceWindowed then FFullscreen := False;
  iWidth      := Configuration.GetInteger( 'screen_width' );
  iHeight     := Configuration.GetInteger( 'screen_height' );

  iSDLFlags := [ SDLIO_OpenGL ];
  if FFullscreen then Include( iSDLFlags, SDLIO_Fullscreen );
  FIODriver := TSDLIODriver.Create( iWidth, iHeight, 32, iSDLFlags );

  begin
    Log('Display modes (%d)', [FIODriver.DisplayModes.Size] );
    Log('-------');
    for iMode in FIODriver.DisplayModes do
      Log('%d x %d @%d', [ iMode.Width, iMode.Height, iMode.Refresh ] );
    Log('-------');
  end;

  FTextures  := TTextureManager.Create( Option_Blending );
  SpriteMap  := TDRLSpriteMap.Create( Vec2i( iWidth, iHeight ) );
  TSDLIODriver( FIODriver ).ShowMouse( False );

  FMCursor   := TDRLMouseCursor.Create;
  FQuadSheet := TGLQuadList.Create;
  FTextSheet := TGLQuadList.Create;
  FPostSheet := TGLQuadList.Create;
  FQuadRenderer := TGLQuadRenderer.Create;

  FAnimations := TAnimationManager.Create;
  FMinimap    := TMinimap.Create;
  inherited Create;
end;

procedure TDRLGFXIO.Reset;
begin
  inherited Reset;
  FTextures.Clear;
  FAnimations.Clear;
  FMCursor.Reset;
  SpriteMap.Reset;

  FadeReset;
  FLastMouseTime := 0;
  FMouseLock     := True;
  FGPDetected    := False;

  FLoading := nil;
  IO := Self;

  FVPadding := 0;
  FFontMult := 1;
  FTileMult := 1;
  FBloodValue       := 0;
  FBloodValueTarget := 0;
  FConsoleSizeX     := 80;
  FConsoleSizeY     := 25;

  FQuadSheet.Reset;
  FTextSheet.Reset;
  FPostSheet.Reset;

  FGPRight.Init();
  FGPLeft.Init();
  FGPLeftDir.Create(0,0);
  FGPLTrigger := False;
  FGPRTrigger := False;
  FGPCamera := 0.0;
end;

function TDRLGFXIO.ReadDefaultFont : TBitmapFont;
var iImage       : TImage;
    iFontTexture : TTextureID;
begin
  iImage := LoadImage( 'font.dat' );
  iImage.SubstituteColor( ColorBlack, ColorZero );
  iFontTexture := FTextures.AddImage( 'default_font', iImage, False );
  FTextures[ iFontTexture ].Image.SubstituteColor( ColorBlack, ColorZero );
  FTextures[ iFontTexture ].Upload;
  Exit( TBitmapFont.CreateFromGrid( iFontTexture, 32, 256-32, 32 ) );
end;

procedure TDRLGFXIO.Initialize;
var iCoreData   : TVDataFile;
    iImage      : TImage;
    iFontTexture: TTextureID;
    iFont       : TBitmapFont;
    iRenderer   : TGLConsoleRenderer;
    iStream     : TStream;
    iFontName   : Ansistring;
    iFontFormat : Ansistring;
    iReadRaw    : Boolean;
    iModule     : TDRLModule;
begin
  FGPDetected := DRL.Store.IsSteamDeck;
  iModule     := DRL.Modules.CoreModule;
  iReadRaw    := not iModule.Path.EndsWith('.wad');
  if iReadRaw then
  begin
    iFontFormat := ReadFileString( iModule.Path + 'fonts' + DirectorySeparator + 'default' );
  end
  else
  begin
    iCoreData := TVDataFile.Create( iModule.Path );
    iCoreData.DKKey := LoveLace;
    iStream := iCoreData.GetFile( 'default', 'fonts' );
    iFontFormat := ReadFileString( iStream, iCoreData.GetFileSize( 'default', 'fonts' ) );
    FreeAndNil( iStream );
  end;

  SScanf( iFontFormat, '%s %d %d %d %d', [@iFontName, @FFontSizeX, @FFontSizeY, @FConsoleSizeX, @FConsoleSizeY ] );

  if iReadRaw then
    iImage := LoadImage( iModule.Path + 'fonts' + DirectorySeparator + iFontName )
  else
  begin
    iStream := iCoreData.GetFile( iFontName, 'fonts' );
    iImage := LoadImage( iStream, iStream.Size );
    FreeAndNil( iStream );
    FreeAndNil( iCoreData );
  end;
  iFontTexture := FTextures.AddImage( iFontName, iImage, Option_Blending );
  FTextures[ iFontTexture ].Image.SubstituteColor( ColorBlack, ColorZero );
  FTextures[ iFontTexture ].Upload;

  iFont := TBitmapFont.CreateFromGrid( iFontTexture, 32, 256-32, 32 );

  RecalculateScaling( True );

  CalculateConsoleParams;
  iRenderer := TGLConsoleRenderer.Create( iFont, FConsoleSizeX, FConsoleSizeY, FLineSpace, [VIO_CON_CURSOR, VIO_CON_BGCOLOR, VIO_CON_EXTCOLOR ] );
  TGLConsoleRenderer( iRenderer ).GlyphStretch := True;

  TGLConsoleRenderer( iRenderer ).SetPositionScale(
    (FIODriver.GetSizeX - FConsoleSizeX*FFontSizeX*FFontMult) div 2,
    0,
    FLineSpace,
    FFontMult
  );

  inherited Initialize( iRenderer );

  SetMinimapScale( FMiniScale );
end;

procedure TDRLGFXIO.Reconfigure(aConfig: TLuaConfig);
var iWidth   : Integer;
    iHeight  : Integer;
    iOpacity : Integer;
begin
  FadeReset;
  iWidth  := Configuration.GetInteger('screen_width');
  iHeight := Configuration.GetInteger('screen_height');
  iOpacity:= Configuration.GetInteger( 'minimap_opacity' );
  FMinimap.SetOpacity( iOpacity );

  if ( ( iWidth > 0 ) and ( iWidth <> FIODriver.GetSizeX ) ) or
     ( ( iHeight > 0 ) and ( iHeight <> FIODriver.GetSizeY ) ) or
     ( ( not ForceWindowed) and  ( Configuration.GetBoolean('fullscreen') <> FFullscreen ) ) then
  begin
    FFullscreen := Configuration.GetBoolean('fullscreen');
    ResetVideoMode;
  end
  else
    RecalculateScaling( False );
  DeviceChanged;
  TGLConsoleRenderer( FConsole ).HideCursor;
  TSDLIODriver(FIODriver).GamePadSupport := DRL.Store.IsSteamDeck or Configuration.GetBoolean( 'enable_gamepad' );

  inherited Reconfigure(aConfig);
end;

destructor TDRLGFXIO.Destroy;
begin
  FreeAndNil( FMCursor );
  FreeAndNil( FQuadSheet );
  FreeAndNil( FTextSheet );
  FreeAndNil( FPostSheet );
  FreeAndNil( FQuadRenderer );

  FreeAndNil( FMinimap );
  FreeAndNil( FAnimations );

  FreeAndNil( SpriteMap );
  FreeAndNil( FTextures );

  inherited Destroy;
end;

procedure TDRLGFXIO.WaitForAnimation;
begin
  inherited WaitForAnimation;
  FAnimations.Clear;
end;

function TDRLGFXIO.AnimationsRunning : Boolean;
begin
  if DRL.State <> DSPlaying then Exit(False);
  Exit( not FAnimations.Finished );
end;

procedure TDRLGFXIO.AnimationWipe;
begin
  FAnimations.Clear;
end;

procedure TDRLGFXIO.Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0);
begin
  if Setting_Flash then
    FAnimations.AddAnimation( TGFXBlinkAnimation.Create(aDuration,aDelay,aColor) );
end;

procedure TDRLGFXIO.addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection );
begin
  if DRL.State <> DSPlaying then Exit;
  if Setting_ScreenShake then
    if not TGFXScreenShakeAnimation.Update( aDuration, aDelay, aStrength, aDirection ) then
      FAnimations.addAnimation( TGFXScreenShakeAnimation.Create( aDuration, aDelay, aStrength, aDirection ) );
end;

procedure TDRLGFXIO.addMoveAnimation ( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aBeing : Boolean; aWipeBump : Boolean );
var iCount : Integer;
begin
  if DRL.State <> DSPlaying then Exit;
  iCount := 0;
  if aWipeBump then
    with FAnimations do
      if Animations.Size > 0 then
      repeat
        if ( Animations[iCount].UID = aUID ) and ( Animations[iCount] is TGFXBumpAnimation )
          then Animations.Delete( iCount )
          else Inc( iCount );
      until iCount >= Animations.Size;
  FAnimations.AddAnimation(TGFXMoveAnimation.Create(aDuration, aDelay, aUID, aFrom, aTo, aSprite, aBeing ));
end;

procedure TDRLGFXIO.addBumpAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aAmount : Single );
begin
  if DRL.State <> DSPlaying then Exit;
  FAnimations.AddAnimation(TGFXBumpAnimation.Create(aDuration, aDelay, aUID, aFrom, aTo, aSprite, True, aAmount ));
  FAnimations.AddAnimation(TGFXBumpAnimation.Create(aDuration, aDelay, aUID, aTo, aFrom, aSprite, True, -aAmount ));
end;

function TDRLGFXIO.getUIDPosition( aUID : TUID; var aPosition : TVec2i ) : Boolean;
var iAnimation : TAnimation;
begin
  for iAnimation in FAnimations.Animations do
    if ( iAnimation.UID = aUID ) and ( iAnimation.Delay = 0 ) then
      if iAnimation is TGFXMoveAnimation then
      begin
        aPosition := ( iAnimation as TGFXMoveAnimation ).LastPosition;
        Exit( True );
      end;
  Exit( False );
end;

procedure TDRLGFXIO.addScreenMoveAnimation(aDuration: DWord; aTo: TCoord2D);
begin
  if DRL.State <> DSPlaying then Exit;
  if not TGFXScreenMoveAnimation.Update( aDuration, aTo ) then
    FAnimations.addAnimation( TGFXScreenMoveAnimation.Create( aDuration, aTo ) );
end;

procedure TDRLGFXIO.addCellAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
begin
  if DRL.State <> DSPlaying then Exit;
  FAnimations.addAnimation( TGFXCellAnimation.Create( aDuration, aDelay, aCoord, aSprite, aValue ) );
end;

procedure TDRLGFXIO.addItemAnimation( aDuration : DWord; aDelay : DWord; aItem : TThing; aValue : Integer );
begin
  if DRL.State <> DSPlaying then Exit;
  FAnimations.addAnimation( TGFXItemAnimation.Create( aDuration, aDelay, aItem.UID, aValue ) );
end;

procedure TDRLGFXIO.addKillAnimation( aDuration : DWord; aDelay : DWord; aBeing : TThing; aReverse : Boolean = False );
begin
  if DRL.State <> DSPlaying then Exit;
  if SF_PAINANIM in aBeing.Sprite.Flags then
    FAnimations.addAnimation( TGFXKillAnimation.Create( aDuration, aDelay, aBeing.UID, aReverse ) );
end;


procedure TDRLGFXIO.addMissileAnimation(aDuration: DWord; aDelay: DWord; aSource,
  aTarget: TCoord2D; aColor: Byte; aPic: Char; aDrawDelay: Word;
  aSprite: TSprite; aRay: Boolean);
begin
  if DRL.State <> DSPlaying then Exit;
  FAnimations.addAnimation(
    TGFXMissileAnimation.Create( aDuration, aDelay, aSource,
      aTarget, aDrawDelay, aSprite, aRay ) );
end;

procedure TDRLGFXIO.addMarkAnimation(aDuration: DWord; aDelay: DWord;
  aCoord: TCoord2D; aSprite : TSprite; aColor: Byte; aPic: Char);
begin
  if DRL.State <> DSPlaying then Exit;
  FAnimations.addAnimation( TGFXMarkAnimation.Create(aDuration, aDelay, aCoord, aSprite ) )
end;

procedure TDRLGFXIO.addSoundAnimation(aDelay: DWord; aPosition: TCoord2D; aSoundID: DWord);
begin
  if DRL.State <> DSPlaying then Exit;
  if aSoundID > 0 then
    FAnimations.addAnimation( TSoundEventAnimation.Create( aDelay, aPosition, aSoundID ) )
end;

procedure TDRLGFXIO.addRumbleAnimation( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
begin
  if DRL.State <> DSPlaying then Exit;
  if (not Setting_GamepadRumble) or (not IsGamepad ) then Exit;
  if aDelay = 0
    then IO.Driver.Rumble( aLow, aHigh, aDuration )
    else FAnimations.addAnimation( TRumbleEventAnimation.Create( aDelay, aLow, aHigh, aDuration ) );
end;

procedure TDRLGFXIO.PulseBlood( aValue : Single );
begin
  if Setting_BloodPulse and ( aValue > FBloodValueTarget ) then
    FBloodValueTarget := aValue;
end;

procedure TDRLGFXIO.ExplosionMark( aCoord : TCoord2D; aColor : Byte; aDuration : DWord; aDelay : DWord );
begin
  FAnimations.AddAnimation( TGFXExplodeMarkAnimation.Create(aDuration,aDelay,aCoord,aColor) )
end;

procedure TDRLGFXIO.SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte );
begin
  SpriteMap.SetTarget( aTarget, NewColor( aColor ), True )
end;

procedure TDRLGFXIO.SetAutoTarget( aTarget : TCoord2D );
var iLevel  : TLevel;
    iSprite : TSprite;
    iCoord  : TCoord2D;
    iFirst  : TCoord2D;
  procedure Trace( aT : TCoord2D; aMain : Boolean );
  var iRay      : TBresenhamRay;
      iBlock    : TCoord2D;
      iFinalize : Boolean;
  begin
    iFinalize := False;
    iRay.Init( aT, Player.Position );
    repeat
      iRay.Next;
      if iRay.Done or ( not iLevel.isProperCoord( iRay.GetC ) ) then Break;
      if iLevel.blocksVision( iRay.GetC ) then
      begin
        iBlock    := iRay.GetC;
        iFinalize := True;
      end
      else
        if iFinalize then Break;
    until False;

    if iFinalize then
    begin
      if aMain
        then begin iSprite.Color := NewColor(0,160,0); iSprite.Frames := HARDSPRITE_SHIELD_COUNT; end
        else begin iSprite.Color := NewColor(64,64,64);iSprite.Frames := 1; end;

      iLevel.Markers.Add( iBlock, iSprite, 0 );
    end;
  end;

begin
  inherited SetAutoTarget( aTarget );
  SpriteMap.SetAutoTarget( aTarget );

  if ( DRL.State <> DSPlaying )    then Exit;
  iLevel := DRL.Level;
  if ( iLevel = nil )              then Exit;
  iLevel.Markers.Wipe(0);
  if ( aTarget = Player.Position ) or ( not iLevel.isProperCoord( aTarget ) ) then Exit;
  FillChar( iSprite, SizeOf( iSprite ), 0 );
  iSprite.SpriteID[0] := HARDSPRITE_SHIELD;
  iSprite.Frames      := HARDSPRITE_SHIELD_COUNT;
  iSprite.FrameTime   := 125;

  Include( iSprite.Flags, SF_COSPLAY );
  if iLevel.isVisible( aTarget ) then
    with DRL.Targeting do
    begin
      iFirst := List.Current;
      repeat
        iCoord := List.Next;
        if ( iCoord <> Player.Position ) and ( iCoord <> aTarget ) then
          Trace( iCoord, False );
      until iCoord = iFirst;
      Trace( aTarget, True );
    end;
end;

procedure TDRLGFXIO.Focus( aCoord : TCoord2D );
var iDiff     : TCoord2D;
const RangeX = 9;
      RangeY = 7;
begin
  inherited Focus( aCoord );
  if FTargeting and (not FMCursor.Active) and ( aCoord <> Player.Position ) then
  begin
    iDiff := aCoord - Player.Position;
    if iDiff.X > RangeX then iDiff.X -= RangeX else if iDiff.X < -RangeX then iDiff.X += RangeX else iDiff.X := 0;
    if iDiff.Y > RangeY then iDiff.Y -= RangeY else if iDiff.Y < -RangeY then iDiff.Y += RangeY else iDiff.Y := 0;
    if ( iDiff.X <> 0 ) or ( iDiff.Y <> 0 ) then
    begin
      SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position + iDiff );
    end;
  end;
end;

procedure TDRLGFXIO.FinishTargeting;
begin
  inherited FinishTargeting;
  SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position );
end;

function TDRLGFXIO.GetPadLTrigger : Boolean;
begin
  Exit( FGPLTrigger );
end;

function TDRLGFXIO.GetPadRTrigger : Boolean;
begin
  Exit( FGPRTrigger );
end;

function TDRLGFXIO.GetPadLDir     : TCoord2D;
begin
  Exit( FGPLeftDir );
end;

function TDRLGFXIO.IsGamepad      : Boolean;
begin
  Exit( FGPDetected );
end;

procedure TDRLGFXIO.FadeIn( aForce : Boolean = False );
begin
  if not Setting_Fade then
  begin
    FadeReset;
    Exit;
  end;
  FFadeTimer     := 0.0;
  FFadeTime      := 0.5;
  FFadeDirection := 1;
  if aForce then FFadeAlpha := 0.0;
end;

procedure TDRLGFXIO.FadeOut( aTime : Single = 0.5; aWait : Boolean = False );
begin
  if not Setting_Fade then
  begin
    FadeReset;
    Exit;
  end;
  FFadeTimer     := 0.0;
  FFadeTime      := aTime;
  FFadeDirection := -1;
  if aWait then
  begin
    FadeWait;
    FadeReset;
  end;
end;

procedure TDRLGFXIO.FadeReset;
begin
  FFadeTimer     := 0.0;
  FFadeDirection := 0;
  FFadeAlpha     := 1.0;
  FFadeTime      := 0.5;
end;

procedure TDRLGFXIO.FadeWait;
var iTime : DWord;
begin
  if FFadeDirection < 0 then
  begin
    iTime := IO.Driver.GetMs;
    while ( FFadeAlpha > 0.0 ) and ( IO.Driver.GetMs - iTime < 3000 ) do
      IO.Delay(5);
  end;
end;

procedure TDRLGFXIO.Configure( aConfig : TLuaConfig; aReload : Boolean = False );
begin
  inherited Configure( aConfig, aReload );

  FIODriver.RegisterInterrupt( IOKeyCode( VKEY_ENTER, [ VKMOD_ALT ] ), @FullScreenCallback );
  FIODriver.RegisterInterrupt( IOKeyCode( VKEY_F12, [ VKMOD_CTRL ] ), @FullScreenCallback );
  DeviceChanged;
end;

procedure TDRLGFXIO.Update( aMSec : DWord );
var iMousePoint : TIOPoint;
    iMousePos   : TVec2i;
    iMax        : TVec2i;
    iActive     : TVec2i;
    iValue      : TVec2f;
    iSizeY      : DWord;
    iSizeX      : DWord;
    iMinus      : Integer;
    iAbsolute   : TIORect;
    iP1, iP2    : TIOPoint;
    iMouse      : Boolean;
    iBloodValue : Single;
    iBloodTarget: Single;
begin
  if not Assigned( FQuadRenderer ) then Exit;

  if (FMCursor <> nil) and FMCursor.Active and (FTime - FLastMouseTime > 3000) then
  begin
    FMCursor.Active := False;
    if not isModal then
      FHintOverlay := '';
  end;

  iMouse := Setting_Mouse and (FMCursor <> nil) and (FMCursor.Active) and FIODriver.GetMousePos( iMousePoint );

  if iMouse and (not FMouseLock) and (not isModal) and (Setting_MouseEdgePan) and (FGPCamera = 0.0) then
  begin
    iMousePos := Vec2i( iMousePoint.X, iMousePoint.Y );
    iMax      := Vec2i( FIODriver.GetSizeX, FIODriver.GetSizeY );
    iActive   := Vec2i( iMax.X div 8, iMax.Y div 8 );
    iValue    := Vec2f;
    if iMousePos.X < iActive.X        then iValue.X :=-((iActive.X -        iMousePos.X) / iActive.X);
    if iMousePos.X > iMax.X-iActive.X then iValue.X := ((iActive.X -(iMax.X-iMousePos.X)) /iActive.X);
    if iMousePos.Y < iActive.Y        then iValue.Y :=-((iActive.Y -        iMousePos.Y) / iActive.Y) / 2;
    if iMousePos.Y > iMax.Y-iActive.Y then iValue.Y := ((iActive.Y -(iMax.Y-iMousePos.Y)) /iActive.Y) / 2;

    if (iValue.X <> 0) or (iValue.Y <> 0) then
    begin
      SpriteMap.NewShift := Clamp( SpriteMap.Shift + vvector.Ceil( iValue.Scaled( aMSec ) ), SpriteMap.MinShift, SpriteMap.MaxShift );
      FMouseLock :=
        ((SpriteMap.NewShift.X = SpriteMap.MinShift.X) or (SpriteMap.NewShift.X = SpriteMap.MaxShift.X))
     and ((SpriteMap.NewShift.Y = SpriteMap.MinShift.Y) or (SpriteMap.NewShift.Y = SpriteMap.MaxShift.Y));
    end;
  end;

  // Lean mode
  {
  if (not isModal) and (( FGPRight.X <> 0.0 ) or (FGPRight.Y <> 0.0 )) then
  begin
    FGPCamera := Minf( FGPCamera + aMSec * 0.005, Maxf( Abs(FGPRight.X), Abs(FGPRight.Y) ) );
    iActive := SpriteMap.ShiftValue( Player.Position );
    iMax    := Vec2i( FIODriver.GetSizeX div 2, FIODriver.GetSizeX div 2 );
    SpriteMap.NewShift := Clamp( iActive + Round(FGPRight * Vec2f(iMax).Scaled(FGPCamera)) , SpriteMap.MinShift, SpriteMap.MaxShift );
  end
  else if FGPCamera > 0.0 then
  begin
    SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position );
    FGPCamera := 0.0;
  end;
  }
  // Pan mode
  if (FTargeting or ( not isModal)) and (( FGPRight.X <> 0.0 ) or (FGPRight.Y <> 0.0 )) then
  begin
    SpriteMap.NewShift := Clamp( SpriteMap.Shift + vvector.Ceil( FGPRight.Scaled( aMSec ) ), SpriteMap.MinShift, SpriteMap.MaxShift );
  end;

  if (FTargeting or ( not isModal)) and (( FGPLeftDir.X <> 0 ) or (FGPLeftDir.Y <> 0 )) then
  begin
    if FTargeting
      then SpriteMap.Marker := SpriteMap.Target + FGPLeftDir
      else if FGPRTrigger
        then SpriteMap.Marker := DRL.Targeting.List.Current + FGPLeftDir
        else SpriteMap.Marker := Player.Position + FGPLeftDir;
  end
  else
    SpriteMap.Marker := NewCoord2D(-1,-1);

  FAnimations.Update( aMSec );

  iSizeY    := FIODriver.GetSizeY-2*FVPadding;
  iSizeX    := FIODriver.GetSizeX;
  glViewport( 0, FVPadding, iSizeX, iSizeY );

  glEnable( GL_TEXTURE_2D );
  glDisable( GL_DEPTH_TEST );
  glEnable( GL_BLEND );
  glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
  FProjection := GLCreateOrtho( 0, iSizeX, iSizeY, 0, -16384, 16384 );

  if (DRL <> nil) and (DRL.State = DSPlaying) then
  begin
    if FTIGConsoleView = nil then
       FConsole.HideCursor;
    //if not UI.AnimationsRunning then SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position );

    SpriteMap.Update( aMSec, FProjection );
    FAnimations.Draw;
    glEnable( GL_DEPTH_TEST );
    SpriteMap.Draw;
    glDisable( GL_DEPTH_TEST );
  end;

  if FHudEnabled then
  begin
    FMinimap.Render( FQuadSheet );

    iAbsolute := vutil.Rectangle( 1,1,FConsoleSizeX,FConsoleSizeY );
    iP1 := ConsoleCoordToDeviceCoord( iAbsolute.Pos );
    iP2 := ConsoleCoordToDeviceCoord( vutil.Point( iAbsolute.x2+1, iAbsolute.y+2 ) );
    QuadSheet.PushColoredQuad( TGLVec2i.Create( iP1.x, iP1.y ), TGLVec2i.Create( iP2.x, iP2.y ), TGLVec4f.Create( 0,0,0,0.8 ) );

    iMinus := 1;
    if StatusEffect = StatusInvert then
      iMinus := 2;
    iP1 := ConsoleCoordToDeviceCoord( vutil.Point( iAbsolute.x, iAbsolute.y2-iMinus ) );
    iP2 := ConsoleCoordToDeviceCoord( vutil.Point( iAbsolute.x2+1, iAbsolute.y2+2 ) );
    QuadSheet.PushColoredQuad( TGLVec2i.Create( iP1.x, iP1.y ), TGLVec2i.Create( iP2.x, iP2.y ), TGLVec4f.Create( 0,0,0,0.8 ) );
  end;

  FQuadRenderer.Update( FProjection );
  FQuadRenderer.Render( FQuadSheet );
  inherited Update( aMSec );

  if Setting_BloodPulse then
  begin
    iBloodTarget := FBloodValueTarget;
    if (DRL <> nil) and (DRL.State = DSPlaying) then
    begin
      iBloodValue := 0;

      if Player.HP < (Player.HPMax div 3) then
        iBloodValue += ( 0.8 - ( Player.HP / (Player.HPMax div 2) ) ) + Sin( (FTime / 1000)*5 ) * 0.2;

      if iBloodValue > 0.0 then
        iBloodTarget := Maxf( iBloodValue, FBloodValueTarget );
    end;

    if iBloodTarget > FBloodValue then
      FBloodValue += Minf( ( iBloodTarget - FBloodValue ), aMSec / 500 )
    else if iBloodTarget < FBloodValue then
      FBloodValue -= Minf( ( FBloodValue - iBloodTarget ), aMSec / 500 );

    if FBloodValueTarget > 0 then
      FBloodValueTarget -= Minf( FBloodValueTarget, aMSec / 500 );

    if (DRL <> nil) and (DRL.State = DSPlaying) and (FBloodValue > 0.02) then
    begin
      FPostSheet.PushTexturedQuad(
        GLVec2i(1,1), GLVec2i( FIODriver.GetSizeX, FIODriver.GetSizeY ),
        GLVec4f(1,1,1,Clampf( FBloodValue, 0.0, 1.0 )),
        GLVec2f(), GLVec2f(1,1), FTextures['low_life_glow'].GLTexture );
    end;
  end;

  if FFadeDirection <> 0 then
  begin
    FFadeTimer += ( 0.001 * aMSec );
    FFadeAlpha := SmoothFade( FFadeTimer, FFadeTime, FFadeDirection > 0 );
    if FFadeTimer > FFadeTime then
    begin
      if FFadeDirection > 0 then FFadeAlpha := 1.0 else FFadeAlpha := 0.0;
      FFadeDirection := 0;
    end;
  end;

  if FFadeAlpha < 1.0 then
  begin
    FPostSheet.PushColoredQuad(
      GLVec2i(1,1), GLVec2i( FIODriver.GetSizeX, FIODriver.GetSizeY ),
      GLVec4f(0,0,0,Clampf( 1.0-FFadeAlpha, 0.0, 1.0 )), 16001 );
  end;

  if  FTextSheet <> nil             then FQuadRenderer.Render( FTextSheet );
  if (FPostSheet <> nil) and iMouse then FMCursor.Draw( iMousePoint, FLastUpdate, FPostSheet );
  if  FPostSheet <> nil             then FQuadRenderer.Render( FPostSheet );
end;

procedure TDRLGFXIO.ResetVideoMode;
var iSDLFlags   : TSDLIOFlags;
    iWidth      : Integer;
    iHeight     : Integer;
begin
  iSDLFlags := [ SDLIO_OpenGL ];
  iWidth    := Configuration.GetInteger('screen_width');
  iHeight   := Configuration.GetInteger('screen_height');
  if FFullscreen then Include( iSDLFlags, SDLIO_Fullscreen );
  TSDLIODriver(FIODriver).ResetVideoMode( iWidth, iHeight, 32, iSDLFlags );
  RecalculateScaling( True );
  CalculateConsoleParams;
  TGLConsoleRenderer( FConsole ).SetPositionScale( (FIODriver.GetSizeX - FConsoleSizeX*FFontSizeX*FFontMult) div 2, 0, FLineSpace, FFontMult );
  TGLConsoleRenderer( FConsole ).HideCursor;
  SetMinimapScale(FMiniScale);
  DeviceChanged;
  SpriteMap.Recalculate;
  if Player <> nil then
    SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position );
end;

function TDRLGFXIO.FullScreenCallback ( aEvent : TIOEvent ) : Boolean;
begin
  FFullscreen := not TSDLIODriver(FIODriver).FullScreen;
  ResetVideoMode;
  Exit( True );
end;

procedure TDRLGFXIO.CalculateConsoleParams;
begin
  FLineSpace := Max((FIODriver.GetSizeY - FConsoleSizeY*FFontSizeY*FFontMult - 2*FVPadding) div FConsoleSizeY div FFontMult,0);
end;

function TDRLGFXIO.OnEvent( const iEvent : TIOEvent ) : Boolean;
var iValue : Integer;
begin
  if ( iEvent.EType = VEVENT_PADAXIS ) then
  begin
    iValue := iEvent.PadAxis.Value;
    if iValue > 32000  then iValue := 32000;
    if iValue < -32000 then iValue := -32000;
    if ( iValue < 5000 ) and ( iValue > -5000 ) then iValue := 0;
    case iEvent.PadAxis.Axis of
      VPAD_AXIS_RIGHT_X : FGPRight.X := iValue / 32000;
      VPAD_AXIS_RIGHT_Y : FGPRight.Y := iValue / 32000;
      VPAD_AXIS_LEFT_X  : FGPLeft.X  := iValue / 32000;
      VPAD_AXIS_LEFT_Y  : FGPLeft.Y  := iValue / 32000;
      VPAD_AXIS_TRIGGERLEFT  : FGPLTrigger := iValue > 10000;
      VPAD_AXIS_TRIGGERRIGHT : FGPRTrigger := iValue > 10000;
    end;

    if iEvent.PadAxis.Axis in [ VPAD_AXIS_LEFT_X, VPAD_AXIS_LEFT_Y] then
      FGPLeftDir := AxisToDirection( FGPLeft );
  end;

  if ( iEvent.EType = VEVENT_PADDEVICE ) then
  begin
    FGPRight.Init();
    FGPLeft.Init();
    FGPLeftDir.Create(0,0);
    FGPLTrigger := False;
    FGPRTrigger := False;
  end;

  if ( iEvent.EType = VEVENT_PADDOWN ) then FGPDetected := True;
  if ( iEvent.EType = VEVENT_KEYDOWN ) then FGPDetected := False;

  if iEvent.EType in [ VEVENT_MOUSEMOVE, VEVENT_MOUSEDOWN ] then
  begin
    if ( FMCursor <> nil ) then FMCursor.Active := Setting_Mouse;
    FLastMouseTime := FTime;
    FMouseLock     := False;

    if ( iEvent.EType = VEVENT_MOUSEMOVE ) and ( VMB_BUTTON_MIDDLE in iEvent.MouseMove.ButtonState ) then
        if ( DRL.State = DSPlaying ) and ( not isModal ) then
        begin
          SpriteMap.NewShift := Clamp(
            Vec2i(
              SpriteMap.NewShift.X - iEvent.MouseMove.RelPos.X,
              SpriteMap.NewShift.Y - iEvent.MouseMove.RelPos.Y
            )
            , SpriteMap.MinShift, SpriteMap.MaxShift );

          //SDL_WarpMouseInWindow( SDLIO.NativeWindow,
          //  iEvent.MouseMove.Pos.X - iEvent.MouseMove.RelPos.X,
          //  iEvent.MouseMove.Pos.Y - iEvent.MouseMove.RelPos.Y
          //);
          // Immediately remove the synthetic event
          //while ( SDL_PeepEvents( @iDiscardEvent, 1, SDL_GETEVENT, SDL_MOUSEMOTION, SDL_MOUSEMOTION) > 0 ) do;
        end;
  end;

  if ( iEvent.EType = VEVENT_PADDOWN ) or ( iEvent.EType = VEVENT_PADUP ) then
    case iEvent.Pad.Button of
      VPAD_BUTTON_DPAD_UP     : begin VTIG_GetIOState.EventState.SetState( VTIG_IE_1, FGPLTrigger and iEvent.Pad.Pressed ); if FGPLTrigger and iEvent.Pad.Pressed then Exit( isModal ) end;
      VPAD_BUTTON_DPAD_DOWN   : begin VTIG_GetIOState.EventState.SetState( VTIG_IE_4, FGPLTrigger and iEvent.Pad.Pressed ); if FGPLTrigger and iEvent.Pad.Pressed then Exit( isModal ) end;
      VPAD_BUTTON_DPAD_LEFT   : begin VTIG_GetIOState.EventState.SetState( VTIG_IE_2, FGPLTrigger and iEvent.Pad.Pressed ); if FGPLTrigger and iEvent.Pad.Pressed then Exit( isModal ) end;
      VPAD_BUTTON_DPAD_RIGHT  : begin VTIG_GetIOState.EventState.SetState( VTIG_IE_3, FGPLTrigger and iEvent.Pad.Pressed ); if FGPLTrigger and iEvent.Pad.Pressed then Exit( isModal ) end;
    end;

  Exit( inherited OnEvent( iEvent ) )
end;

procedure TDRLGFXIO.DrawHUD;
var i     : Byte;
    iItem : TItem;
    iPosX : Integer;
    iPosY : Integer;
begin
  inherited DrawHUD;
  if Player = nil then Exit;

  if IsGamepad and FGPLTrigger and ( not isModal ) then
  begin
    iPosY := 4;
    iPosX := 2;
    if Player.Position.X < 20 then
      iPosX := 40;
    for i := 1 to 4 do
    begin
      iItem := nil;
      with Player.FQuickSlots[ i ] do
      begin
             if UID <> 0 then iItem := UIDs[ UID ] as TItem
        else if ID <> '' then iItem := Player.Inv.Find( ID );
      end;
      if iItem <> nil then
      begin
        VTIG_FreeLabel( '[{!{0}}] {1}', vutil.Point(iPosX,iPosY), [ PadQSlotChar[ i ], iItem.description ], iItem.MenuColor );
        Inc( iPosY );
      end;
    end;
  end;
end;

function TDRLGFXIO.PushLayer(  aLayer : TIOLayer ) : TIOLayer;
begin
  if FMCursor <> nil then
  begin
    if ( FMCursor.Size = 0 ) and ( FTextures.Exists('cursor') ) then
      FMCursor.SetTextureID( FTextures.TextureID['cursor'], 32 );
    FMCursor.Active := Setting_Mouse;
  end;
  Result := inherited PushLayer( aLayer );
end;

procedure TDRLGFXIO.UpdateMinimap;
begin
  FMinimap.Redraw;
end;

procedure TDRLGFXIO.SetMinimapScale ( aScale : Byte ) ;
begin
  FMinimap.SetScale( aScale );
  FMinimap.SetPosition( Vec2i(
    FIODriver.GetSizeX - aScale*(MAXX+2) - 10,
    FIODriver.GetSizeY - aScale*(MAXY+2) - ( 10 + FFontMult*20*3 )
  ) );
  FMinimap.Redraw;
end;

procedure TDRLGFXIO.DeviceChanged;
begin
  FadeReset;
  FUIRoot.DeviceChanged;
  FCellX := (FConsole.GetDeviceArea.Dim.X) div (FConsole.SizeX);
  FCellY := (FConsole.GetDeviceArea.Dim.Y) div (FConsole.SizeY);
end;

function TDRLGFXIO.DeviceCoordToConsoleCoord( aCoord : TIOPoint ) : TIOPoint;
begin
  aCoord := aCoord - FConsole.GetDeviceArea.Pos;
  aCoord.x := ( aCoord.x div FCellX );
  aCoord.y := ( aCoord.y div FCellY );
  Exit( PointUnit + aCoord );
end;

function TDRLGFXIO.ConsoleCoordToDeviceCoord( aCoord : TIOPoint ) : TIOPoint;
begin
  aCoord := aCoord - PointUnit;
  aCoord.x := ( aCoord.x * FCellX );
  aCoord.y := ( aCoord.y * FCellY );
  Exit( FConsole.GetDeviceArea.Pos + aCoord );
end;

procedure TDRLGFXIO.RenderUIBackgroundBlock( aUL, aBR : TIOPoint; aOpacity : Single = 0.85; aZ : Integer = 0 );
var iP1,iP2 : TIOPoint;
begin
  iP1 := ConsoleCoordToDeviceCoord( aUL + PointUnit );
  iP2 := ConsoleCoordToDeviceCoord( aBR + PointUnit );
  QuadSheet.PushColoredQuad( TGLVec2i.Create( iP1.x, iP1.y ), TGLVec2i.Create( iP2.x, iP2.y ), TGLVec4f.Create( 0,0,0,aOpacity ), aZ );
end;

procedure TDRLGFXIO.RenderUIBackground( aTexture : TTextureID; aZ : Integer = 0 );
var iImage          : TImage;
    iMin, iMax      : TGLVec2f;
    iSize, iSz, iTC : TGLVec2f;
begin
  if aTexture = 0 then Exit;
  iImage := FTextures.Texture[ aTexture ].Image;
  iTC.Init( iImage.RawX / iImage.SizeX, iImage.RawY / iImage.SizeY );

  iSize.Init( Driver.GetSizeX, Driver.GetSizeY );
  iMin.Init( 0,0 );
  iMax := iSize - GLVec2f( 1, 1 );

  if (iImage.RawX / iImage.RawY) > (iSize.X / iSize.Y) then
  begin
    iSz.X  := iImage.RawX * (IO.Driver.GetSizeY / iImage.RawY);
    iMin.X := ( IO.Driver.GetSizeX - iSz.X ) / 2;
    iMax.X := iMin.X + iSz.X;
  end
  else
  begin
    iSz.Y  := iImage.RawY * (IO.Driver.GetSizeX / iImage.RawX);
    iMin.Y := ( IO.Driver.GetSizeY - iSz.Y ) / 2;
    iMax.Y := iMin.Y + iSz.Y;
  end;

  QuadSheet.PushTexturedQuad(
    GLVec2i(Floor(iMin.X), Floor(iMin.Y)),
    GLVec2i(Floor(iMax.X), Floor(iMax.Y)),
    GLVec2f(0,0),iTC,
    FTextures.Texture[ aTexture ].GLTexture,
    aZ
  );
end;

procedure TDRLGFXIO.RunModuleChoice;
var iRenderer : TGLConsoleRenderer;
    iTIGStyle : TTIGStyle;
begin
  RecalculateScaling( True );
  FConsoleSizeY := 25;
  FFontSizeY    := 19;
  FConsoleSizeX := 80;
  FFontSizeX    := 10;
  CalculateConsoleParams;
  iTIGStyle := VTIGDefaultStyle;
  iRenderer := TGLConsoleRenderer.Create( ReadDefaultFont, 80, 25, 0, [VIO_CON_CURSOR, VIO_CON_BGCOLOR, VIO_CON_EXTCOLOR ] );
  iRenderer.SetPositionScale( (FIODriver.GetSizeX - 80*10*FFontMult) div 2, 0, FLineSpace, FFontMult );
  iRenderer.GlyphStretch := True;
  TSDLIODriver(FIODriver).GamePadSupport := DRL.Store.IsSteamDeck or Configuration.GetBoolean( 'enable_gamepad' );
  inherited Initialize( iRenderer );
  DeviceChanged;
  iTIGStyle.Color[ VTIG_SELECTED_BACKGROUND_COLOR ] := DarkGray;
  VTIG_PushStyle( @iTIGStyle );
  inherited RunModuleChoice;
  VTIG_PopStyle;
  inherited Initialize( nil );
  Reset;
end;


end.

