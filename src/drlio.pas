{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlio;
interface
uses {$IFDEF WINDOWS}Windows,{$ENDIF} Classes, SysUtils,
     vio, vrltools, vluaconfig, vglquadrenderer, vmessages, vtextures, vtigstyle,
     vuitypes, vluastate,  viotypes, vioevent, vioconsole, vuielement, vgenerics, vutil,
     dfdata, dfthing, dfbeing, drlspritemap, drlaudio, drlkeybindings, drlloadingview;

const TIG_EV_NONE      = 0;
      //TIG_EV_DROP      = 1;
      TIG_EV_INVENTORY = 2;
      TIG_EV_EQUIPMENT = 3;
      TIG_EV_CHARACTER = 4;
      TIG_EV_TRAITS    = 5;
      TIG_EV_MORE      = 6;
      //TIG_EV_QUICK_0   = 10;
      //TIG_EV_QUICK_1   = 11;
      //TIG_EV_QUICK_2   = 12;
      //TIG_EV_QUICK_3   = 13;
      //TIG_EV_QUICK_4   = 14;
      //TIG_EV_QUICK_5   = 15;
      //TIG_EV_QUICK_6   = 16;
      //TIG_EV_QUICK_7   = 17;
      //TIG_EV_QUICK_8   = 18;
      //TIG_EV_QUICK_9   = 19;

      TIG_EV_RESTART   = 100;

type TCommandSet = set of Byte;
     TKeySet     = set of Byte;

type TASCIIImageMap       = specialize TGObjectHashMap<TUIStringArray>;
type TStringHashMap       = specialize TGHashMap< AnsiString >;

type TDRLIO = class( TIO )
  constructor Create; reintroduce;
  procedure Reset; virtual;
  procedure Initialize; virtual; abstract;
  procedure Initialize( iRenderer : TIOConsoleRenderer );
  procedure Reconfigure( aConfig : TLuaConfig ); virtual;
  procedure Configure( aConfig : TLuaConfig; aReload : Boolean = False ); virtual;
  procedure WaitForLayer( aHideHUD : Boolean ); reintroduce;
  procedure PreUpdate; override;
  destructor Destroy; override;
  procedure Screenshot( aBB : Boolean );

  procedure EventMore;

  procedure LoadStart;
  function LoadCurrent : DWord;
  procedure LoadProgress( aProgress : DWord );
  procedure LoadStop;
  procedure Update( aMSec : DWord ); override;

  function EventToUIInput( const aEvent : TIOEvent ) : Integer; override;
  function CommandEventPending : Boolean;

  procedure SetHint( const aText : AnsiString );

  procedure Focus( aCoord: TCoord2D ); virtual;
  procedure FinishTargeting; virtual;

  procedure LookDescription( aWhere : TCoord2D );

  procedure Msg( const aText : AnsiString );
  procedure Msg( const aText : AnsiString; const aParams : array of const );
  function  MsgGetRecent : TMessageBuffer;
  procedure MsgReset;
  // TODO: Could this be removed as well?
  procedure MsgUpDate;
  procedure ErrorReport( const aText : AnsiString );

  procedure ClearAllMessages;
  procedure ASCIILoader( aStream : TStream; aName : Ansistring; aSize : DWord );

  procedure BloodSlideDown( aDelayTime : Word );

  procedure WaitForAnimation; virtual;
  function AnimationsRunning : Boolean; virtual; abstract;
  procedure AnimationWipe; virtual; abstract;
  procedure Blink( aColor : Byte; aDuration : Word = 100; aDelay : DWord = 0); virtual; abstract;
  procedure addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection ); virtual;
  procedure addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single );
  procedure addMoveAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aBeing : Boolean; aWipeBump : Boolean ); virtual;
  procedure addBumpAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aAmount : Single ); virtual;
  procedure addScreenMoveAnimation( aDuration : DWord; aTo : TCoord2D ); virtual;
  procedure addCellAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer ); virtual;
  procedure addItemAnimation( aDuration : DWord; aDelay : DWord; aItem : TThing; aValue : Integer ); virtual;
  procedure addKillAnimation( aDuration : DWord; aDelay : DWord; aBeing : TThing ); virtual;
  procedure addMissileAnimation( aDuration : DWord; aDelay : DWord; aSource, aTarget : TCoord2D; aColor : Byte; aPic : Char; aDrawDelay : Word; aSprite : TSprite; aRay : Boolean = False ); virtual; abstract;
  procedure addMarkAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aColor : Byte; aPic : Char ); virtual; abstract;
  procedure addSoundAnimation( aDelay : DWord; aPosition : TCoord2D; aSoundID : DWord ); virtual; abstract;
  procedure addRumbleAnimation( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord ); virtual;
  procedure Explosion( aDelay : Integer; aWhere : TCoord2D; aData : TExplosionData ); virtual;
  procedure PulseBlood( aValue : Single ); virtual;

  class procedure RegisterLuaAPI( State : TLuaState );

  function PushLayer( aLayer : TIOLayer ) : TIOLayer; override;
  procedure PreAction;
  procedure Clear; override;
  function OnEvent( const aEvent : TIOEvent ) : Boolean; override;

  function ShiftHeld      : Boolean;  virtual;

  // Gamepad
  function GetPadLTrigger : Boolean;  virtual;
  function GetPadRTrigger : Boolean;  virtual;
  function GetPadLDir     : TCoord2D; virtual;
  function IsGamepad      : Boolean;  virtual;

  // Fade control
  procedure FadeIn( aForce : Boolean = False ); virtual;
  procedure FadeOut( aTime : Single = 0.5; aWait : Boolean = False ); virtual;
  procedure FadeReset; virtual;
  procedure FadeWait; virtual;

  procedure RenderUIBackgroundBlock( aUL, aBR : TIOPoint; aOpacity : Single = 0.85; aZ : Integer = 0 ); virtual;
  procedure RenderUIBackground( aTexture : TTextureID; aZ : Integer = 0 ); virtual;
  procedure FullLook( aBeing : TBeing );
  procedure SetTarget( aTarget : TCoord2D; aColor : Byte; aRange : Byte ); virtual; abstract;
  procedure SetAutoTarget( aTarget : TCoord2D ); virtual;
  function ResolveSub( const aID : Ansistring ) : Ansistring;
  procedure RunModuleChoice; virtual;
protected
  procedure UpdateStyles;
  procedure ExplosionMark( aCoord : TCoord2D; aColor : Byte; aDuration : DWord; aDelay : DWord ); virtual; abstract;
  procedure DrawHud; virtual;
  procedure ColorQuery(nkey,nvalue : Variant);
  function ScreenShotCallback( aEvent : TIOEvent ) : Boolean;
  function BBScreenShotCallback( aEvent : TIOEvent ) : Boolean;
  function Chunkify( const aString : AnsiString; aStart : Integer; aColor : TIOColor ) : TUIChunkBuffer;
protected
  FAudio       : TDRLAudio;
  FMessages    : TMessages;
  FTime        : QWord;
  FLoading     : TLoadingView;
  FMTarget     : TCoord2D;
  FLastTarget  : TCoord2D;
  FKeyCode     : TIOKeyCode;
  FASCII       : TASCIIImageMap;

  FHudEnabled  : Boolean;
  FWaiting     : Boolean;
  FTargeting   : Boolean;
  FNarrowMode  : Boolean;
  FHint        : AnsiString;
  FHintOverlay : AnsiString;
  FHintTarget  : AnsiString;
  FCachedAmmo  : Integer;

  // Textmode only
  FTargetLast     : Boolean;
  FTargetEnabled  : Boolean;

  // String subs
  FKeySubMap      : TStringHashMap;
  FPadSubMap      : TStringHashMap;

  FTIGDefault     : TTIGStyle;
public
  property KeyCode     : TIOKeyCode     read FKeyCode    write FKeyCode;
  property Audio       : TDRLAudio     read FAudio;
  property MTarget     : TCoord2D       read FMTarget    write FMTarget;
  property ASCII       : TASCIIImageMap read FASCII;
  property HintOverlay : AnsiString     read FHintOverlay write FHintOverlay;
  property Targeting   : Boolean        read FTargeting   write FTargeting;
  property Time        : QWord          read FTime;
  property NarrowMode  : Boolean        read FNarrowMode;

  // Textmode only
  property TargetEnabled : Boolean        read FTargetEnabled write FTargetEnabled;
  property TargetLast    : Boolean        read FTargetLast    write FTargetLast;
end;

var IO : TDRLIO;

procedure EmitCrashInfo( const aInfo : AnsiString; aInGame : Boolean  );

implementation

uses math, video, dateutils, variants,
     vsound, vluasystem, vuid, vlog, vdebug, vuiconsole, vmath,
     vsdlio, vglconsole, vtig, vtigio, vvector,
     dflevel, dfplayer, dfitem, dfhof,
     drlconfiguration, drlbase, drlmoreview, drlchoiceview, drlua, drlmodulechoiceview,
     drlhudviews, drlplotview;

function TIGSubCallback( const aID : Ansistring ) : Ansistring;
begin
  Exit( IO.ResolveSub( aID ) );
end;

{
procedure OutPutRestore;
var vx,vy : byte;
begin
  if GraphicsVersion then Exit;
  for vx := 1 to 80 do for vy := 1 to 25 do VideoBuf^[(vx-1)+(vy-1)*ScreenSizeX] := GFXCapture[vy,vx];
end;
}

//type TGFXScreen = array[1..25,1..80] of Word;
//var  GFXCapture : TGFXScreen;


procedure TDRLIO.BloodSlideDown( aDelayTime : Word );
{
const BloodPic : TPictureRec = (Picture : ' '; Color : 16*Red);
var Temp  : TGFXScreen;
    Blood : TGFXScreen;
    vx,vy : byte;
}
begin
  if GraphicsVersion then
    if Player <> nil then
      SpriteMap.NewShift := SpriteMap.ShiftValue( Player.Position );

{
  for vx := 1 to 80 do for vy := 1 to 25 do Temp [vy,vx] := VideoBuf^[(vx-1)+(vy-1)*ScreenSizeX];
  OutputRestore;
  FillWord(Blood,25*80,Word(BloodPic));
  SlideDown(DelayTime,Blood);
  SlideDown(DelayTime,Temp);
}
end;

procedure TDRLIO.WaitForAnimation;
var iTime : DWord;
begin
  if FWaiting then Exit;
  if DRL.State <> DSPlaying then Exit;
  FWaiting := True;
  iTime := IO.Driver.GetMs;
  while AnimationsRunning do
  begin
    IO.Delay(5);
    if ( IO.Driver.GetMs - iTime ) > 2000 then
      begin
        Log(LOGWARN, 'Emergency animation break!' );
        AnimationWipe;
      end;
  end;
  FWaiting := False;
  DRL.Level.RevealBeings;
end;

procedure TDRLIO.addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single; aDirection : TDirection );
begin

end;

procedure TDRLIO.addScreenShakeAnimation( aDuration : DWord; aDelay : DWord; aStrength : Single );
begin
  addScreenShakeAnimation( aDuration, aDelay, aStrength, NewDirection(0) );
end;

procedure TDRLIO.addMoveAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aBeing : Boolean; aWipeBump : Boolean );
begin

end;

procedure TDRLIO.addBumpAnimation( aDuration : DWord; aDelay : DWord; aUID : TUID; aFrom, aTo : TCoord2D; aSprite : TSprite; aAmount : Single );
begin

end;

procedure TDRLIO.addScreenMoveAnimation( aDuration : DWord; aTo : TCoord2D );
begin

end;

procedure TDRLIO.addCellAnimation( aDuration : DWord; aDelay : DWord; aCoord : TCoord2D; aSprite : TSprite; aValue : Integer );
begin

end;

procedure TDRLIO.addItemAnimation( aDuration : DWord; aDelay : DWord; aItem : TThing; aValue : Integer );
begin

end;

procedure TDRLIO.addKillAnimation( aDuration : DWord; aDelay : DWord; aBeing : TThing );
begin

end;

procedure TDRLIO.addRumbleAnimation( aDelay : DWord; aLow, aHigh : Word; aDuration : DWord );
begin
  if (not Setting_GamepadRumble) or (not IsGamepad ) then Exit;
    IO.Driver.Rumble( aLow, aHigh, aDuration );
end;

procedure TDRLIO.Explosion( aDelay : Integer; aWhere: TCoord2D; aData : TExplosionData );
var iCoord    : TCoord2D;
    iDistance : Byte;
    iVisible  : boolean;
    iLevel    : TLevel;
    iSound    : Word;
begin
  iLevel := DRL.Level;
  if not iLevel.isProperCoord( aWhere ) then Exit;

  if aData.SoundID <> '' then
  begin
    iSound := IO.Audio.ResolveSoundID([aData.SoundID+'.explode',aData.SoundID,'explode']);
    if iSound <> 0 then
      IO.addSoundAnimation( aDelay, aWhere, iSound );
  end;

  if aData.Range > 0 then
  begin
    addScreenShakeAnimation( Clamp( 100 * aData.Range, 300, 500 ), aData.Delay, Clampf( 2.0 * aData.Range, 2.0, 5.0 ) );
    addRumbleAnimation( aDelay, Clamp( $2000 * aData.Range, $2000, $E000 ), $6000, Clamp( 100 * aData.Range, 100, 300 ) );
  end;

  for iCoord in NewArea( aWhere, aData.Range ).Clamped( iLevel.Area ) do
    begin
      if not ( efAlwaysVisible in aData.Flags ) then
      begin
        if iLevel.isVisible(iCoord) then iVisible := True else Continue;
        if not iLevel.isEyeContact( iCoord, aWhere ) then Continue;
      end;
      iDistance := Distance(iCoord, aWhere);
      if iDistance > aData.Range then Continue;
      if GraphicsVersion and ( aData.Sprite.SpriteID[0] <> 0 )
        then addMarkAnimation( aData.Sprite.Frametime * aData.Sprite.Frames - 1, aDelay+iDistance*aData.Delay, iCoord, aData.Sprite, 0, ' ' )
        else ExplosionMark( iCoord, aData.Color, 3*aData.Delay, aDelay+iDistance*aData.Delay );
    end;
  if aData.Range >= 10 then iVisible := True;

  if efAfterBlink in aData.Flags then
  begin
    Blink( LightGreen, 50, aDelay+aData.Delay*aData.Range);
    Blink( White, 50,      aDelay+aData.Delay*aData.Range+60);
  end;

  if not iVisible then if aData.Range > 3 then
    IO.Msg( 'You hear an explosion!' );
end;

procedure TDRLIO.PulseBlood( aValue : Single );
begin

end;

{
procedure TDRLIO.SlideDown(DelayTime : word; var NewScreen : TGFXScreen);
var Pos  : array[1..80] of Byte;
    cn,t, vx,vy : byte;
  procedure MoveColumn(x : byte);
  var y : byte;
  begin
    if pos[x]+1 > 25 then Exit;
    for y := 24 downto pos[x]+1 do
      VideoBuf^[(x-1)+y*LongInt(ScreenSizeX)] := VideoBuf^[(x-1)+(y-1)*LongInt(ScreenSizeX)];
    VideoBuf^[(x-1)+pos[x]*LongInt(ScreenSizeX)] := NewScreen[pos[x]+1,x];
    Inc(pos[x]);
  end;

begin
  if GraphicsVersion then Exit;
  for cn := 1 to 80  do Pos[cn] := 0;
  for cn := 1 to 160 do MoveColumn(Random(80)+1);
  t := 1;
  repeat
    Inc(t);
    IO.Delay(DelayTime);
    for cn := 1 to 80 do MoveColumn(cn);
  until t = 25;
  for vx := 1 to 80 do for vy := 1 to 25 do VideoBuf^[(vx-1)+(vy-1)*ScreenSizeX] := NewScreen[vy,vx];

end;
}
procedure TDRLIO.UpdateStyles;
begin
  TIGStyleColored   := VTIGDefaultStyle;
  TIGStyleColored.Color[ VTIG_TEXT_COLOR ] := VTIGDefaultStyle.Color[ VTIG_FOOTER_COLOR ];
  TIGStyleColored.Color[ VTIG_BOLD_COLOR ] := VTIGDefaultStyle.Color[ VTIG_TITLE_COLOR ];

  TIGStyleFrameless := VTIGDefaultStyle;
  TIGStyleFrameless.Frame[ VTIG_BORDER_FRAME ] := '';

  TIGStylePadless   := VTIGDefaultStyle;
  TIGStylePadless.Padding[ VTIG_WINDOW_PADDING ] := Point(0,0);
end;

{ TDRLIO }

constructor TDRLIO.Create;
begin
  FLoading := nil;
  FAudio    := TDRLAudio.Create;
  FMessages := TMessages.Create( 2, 77, @IO.EventMore, Option_MessageBuffer );
  FMessages.GroupMultiple := Setting_GroupMessages;
  FASCII    := TASCIIImageMap.Create( True );

  FIODriver.SetTitle('DRL','DRL');

  FKeySubMap := TStringHashMap.Create;
  FPadSubMap := TStringHashMap.Create;
  FTIGDefault := VTIGDefaultStyle;
  inherited Create( FIODriver, nil, nil );
  Reset;
end;

procedure TDRLIO.Reset;
begin
  Clear;
  IO := Self;
  VTIG_Shutdown;
  VTIGDefaultStyle := FTIGDefault;
  FLoading := nil;
  FTime := 0;
  FASCII.Clear;
  FAudio.Reset;
  FWaiting     := False;
  FHudEnabled  := False;
  FTargeting   := False;
  FNarrowMode  := False;
  FHint        := '';
  FHintOverlay := '';

  FTargetEnabled := False;
  FTargetLast    := False;
  FCachedAmmo    := -1;
  FLastTarget.Create(0,0);
end;

procedure TDRLIO.Initialize( iRenderer : TIOConsoleRenderer );
begin
  inherited Initialize( iRenderer, nil, True );
  if iRenderer = nil then Exit;
  VTIG_SetSubCallback( @TIGSubCallback );
  UpdateStyles;
  iRenderer.Clear;
  iRenderer.HideCursor;
  FUIRoot.UpdateOnRender := False;
  FullUpdate;
end;

function TDRLIO.PushLayer( aLayer : TIOLayer ) : TIOLayer;
begin
  FHintOverlay := '';
  FConsole.HideCursor;
  Exit( inherited PushLayer( aLayer ) );
end;

procedure TDRLIO.PreAction;
begin
  FCachedAmmo := -1;
  FLastTarget.Create(0,0);
end;

procedure TDRLIO.Clear;
begin
  FCachedAmmo := -1;
  inherited Clear;
end;

function TDRLIO.OnEvent( const aEvent : TIOEvent ) : Boolean;
var iInput : TInputKey;
    iKey   : TIOKeyCode;
begin
  if ( aEvent.EType in [ VEVENT_MOUSEMOVE, VEVENT_MOUSEDOWN, VEVENT_MOUSEUP ] ) then
    if not Setting_Mouse then
      Exit( False );

  if ( aEvent.EType = VEVENT_KEYDOWN ) or ( aEvent.EType = VEVENT_KEYUP ) and ( not aEvent.Key.Repeated ) then
  begin
    case aEvent.Key.Code of
      VKEY_F1     : if ModdedGame then VTIG_GetIOState.EventState.SetState( TIG_EV_RESTART, aEvent.Key.Pressed and ( VKMOD_CTRL in aEvent.Key.ModState ) );
    end;
    iKey := IOKeyEventToIOKeyCode( aEvent.Key );
    if (iKey mod 256) <> 0 then
    begin
      iInput := TInputKey( Config.Commands[ iKey ] );
      case iInput of
        INPUT_INVENTORY  : VTIG_GetIOState.EventState.SetState( TIG_EV_INVENTORY, aEvent.Key.Pressed );
        INPUT_EQUIPMENT  : VTIG_GetIOState.EventState.SetState( TIG_EV_EQUIPMENT, aEvent.Key.Pressed );
        INPUT_TRAITS     : VTIG_GetIOState.EventState.SetState( TIG_EV_TRAITS,    aEvent.Key.Pressed );
        INPUT_PLAYERINFO : VTIG_GetIOState.EventState.SetState( TIG_EV_CHARACTER, aEvent.Key.Pressed );
        INPUT_MORE       : VTIG_GetIOState.EventState.SetState( TIG_EV_MORE,      aEvent.Key.Pressed );
      end;
    end;
  end;

  Exit( inherited OnEvent( aEvent ) );
end;

function TDRLIO.ShiftHeld : Boolean;
begin
  Exit( VKMOD_SHIFT in FIODriver.GetModKeyState );
end;

function TDRLIO.GetPadLTrigger : Boolean;
begin
  Exit( False );
end;

function TDRLIO.GetPadRTrigger : Boolean;
begin
  Exit( False );
end;

function TDRLIO.GetPadLDir     : TCoord2D;
begin
  Result.Create(0,0);
end;

function TDRLIO.IsGamepad      : Boolean;
begin
  Exit( False );
end;

procedure TDRLIO.FadeIn( aForce : Boolean = False );
begin
  // noop
end;

procedure TDRLIO.FadeOut( aTime : Single = 0.5; aWait : Boolean = False );
begin
  // noop
end;

procedure TDRLIO.FadeReset;
begin
  // noop
end;

procedure TDRLIO.FadeWait;
begin
  // noop
end;


procedure TDRLIO.RenderUIBackgroundBlock( aUL, aBR : TIOPoint; aOpacity : Single = 0.85; aZ : Integer = 0 );
begin
  // noop
end;

procedure TDRLIO.RenderUIBackground( aTexture : TTextureID; aZ : Integer = 0 );
begin
  // noop
end;

procedure TDRLIO.FullLook( aBeing : TBeing );
begin
  if ( aBeing = nil ) or ( not aBeing.isVisible ) then Exit;
  FConsole.HideCursor;
  PushLayer( TMoreView.Create( aBeing ) );
end;

procedure TDRLIO.SetAutoTarget( aTarget : TCoord2D );
begin
  FHintTarget := DRL.Level.GetTargetDescription( aTarget );
end;

function TDRLIO.ResolveSub( const aID : Ansistring ) : Ansistring;
begin
  if IsGamepad
    then Exit( FPadSubMap.Get(aID, '') )
    else Exit( FKeySubMap.Get(aID, '') );
end;

procedure TDRLIO.Reconfigure( aConfig : TLuaConfig );
var iInput : TInputKey;
    procedure CtrlAssign( aWhat : TInputKey; aFrom : TInputKey );
    var iKey : TIOKeyCode;
    begin
      iKey := aConfig.Commands[ Configuration.GetInteger(KeyInfo[aFrom].ID) ];
      if ( iKey and IOKeyCodeCtrlMask ) = 0
        then aConfig.Commands[ iKey + IOKeyCodeCtrlMask ] := Word(aWhat)
        else Log( LogWarn, 'Movement key assigned with Ctrl prevents targeting move assignemnt!' );
    end;
    function GetString( aWhat : TInputKey ) : Ansistring;
    var iKey : TIOKeyCode;
    begin
      iKey := Configuration.GetInteger(KeyInfo[aWhat].ID);
      Exit( IOKeyCodeToStringShort( iKey ) );
    end;
begin
  FAudio.Reconfigure;
  aConfig.ResetCommands;
  if aConfig.TableExists('Keytable') then
    aConfig.LoadKeybindings('Keytable');

  for iInput in TInputKey do
    if KeyInfo[iInput].ID <> '' then
      aConfig.Commands[ Configuration.GetInteger(KeyInfo[iInput].ID) ] := Word(iInput);

  CtrlAssign( INPUT_TARGETLEFT,      INPUT_WALKLEFT );
  CtrlAssign( INPUT_TARGETRIGHT,     INPUT_WALKRIGHT );
  CtrlAssign( INPUT_TARGETUP,        INPUT_WALKUP );
  CtrlAssign( INPUT_TARGETDOWN,      INPUT_WALKDOWN );
  CtrlAssign( INPUT_TARGETUPLEFT,    INPUT_WALKUPLEFT );
  CtrlAssign( INPUT_TARGETUPRIGHT,   INPUT_WALKUPRIGHT );
  CtrlAssign( INPUT_TARGETDOWNLEFT,  INPUT_WALKDOWNLEFT );
  CtrlAssign( INPUT_TARGETDOWNRIGHT, INPUT_WALKDOWNRIGHT );

  FKeySubMap.Clear;
  FKeySubMap['input_ok']        := 'Enter';
  FKeySubMap['input_escape']    := 'Escape';
  FKeySubMap['input_uidrop']    := 'Backspace';
  FKeySubMap['input_uialtdrop'] := 'SHIFT+Backspace';
  FKeySubMap['input_uiswap']    := 'Tab';
  FKeySubMap['input_left']      := 'Left';
  FKeySubMap['input_right']     := 'Right';
  FKeySubMap['input_up']        := 'Up';
  FKeySubMap['input_down']      := 'Down';
  FKeySubMap['input_pgup']      := 'PgUp';
  FKeySubMap['input_pgdn']      := 'PgDn';
  FKeySubMap['input_help']      := GetString( INPUT_HELP );
  FKeySubMap['input_fire']      := GetString( INPUT_FIRE );
  FKeySubMap['input_reload']    := GetString( INPUT_RELOAD );
  FKeySubMap['input_pickup']    := GetString( INPUT_PICKUP );
  FKeySubMap['input_action']    := GetString( INPUT_ACTION );
  FKeySubMap['input_menu']      := 'Escape';
  FKeySubMap['input_inventory'] := GetString( INPUT_INVENTORY );

  FPadSubMap.Clear;
  FPadSubMap['input_ok']        := 'A';
  FPadSubMap['input_escape']    := 'B';
  FPadSubMap['input_uidrop']    := 'Y';
  FPadSubMap['input_uialtdrop'] := 'RTrigger+Y';
  FPadSubMap['input_uiswap']    := 'X';
  FPadSubMap['input_left']      := 'Left';
  FPadSubMap['input_right']     := 'Right';
  FPadSubMap['input_up']        := 'Up';
  FPadSubMap['input_down']      := 'Down';
  FPadSubMap['input_help']      := 'Back';
  FPadSubMap['input_menu']      := 'Back';
  FPadSubMap['input_fire']      := 'X';
  FPadSubMap['input_reload']    := 'Y';
  FPadSubMap['input_pickup']    := 'B';
  FPadSubMap['input_action']    := 'B';
  FPadSubMap['input_pgup']      := 'PgUp';
  FPadSubMap['input_pgdn']      := 'PgDn';
  FPadSubMap['input_inventory'] := 'Start';
end;

procedure TDRLIO.Configure ( aConfig : TLuaConfig; aReload : Boolean ) ;
begin
  // TODO : configurable

  if GodMode then
    RegisterDebugConsole( VKEY_F1 );
  FIODriver.RegisterInterrupt( VKEY_F9, @ScreenShotCallback );
  FIODriver.RegisterInterrupt( VKEY_F10, @BBScreenShotCallback );

  if Option_MessageBuffer < 20 then Option_MessageBuffer := 20;
  FAudio.Configure( aConfig, aReload );

  if aReload then
    aConfig.EntryFeed('Colors', @ColorQuery );
  if Option_MessageColoring then
    aConfig.EntryFeed( 'Messages', @FMessages.AddHighlightCallback );
end;

procedure TDRLIO.WaitForLayer( aHideHUD : Boolean );
begin
  if aHideHUD then FHudEnabled := False;
  inherited WaitForLayer;
  if aHideHUD then FHudEnabled := True;
end;

procedure TDRLIO.PreUpdate;
begin
  if FHudEnabled then DrawHud;
  inherited PreUpdate;
end;

destructor TDRLIO.Destroy;
begin
  FreeAndNil( FAudio );
  FreeAndNil( FMessages );
  FreeAndNil( FASCII );
  FreeAndNil( FKeySubMap );
  FreeAndNil( FPadSubMap );
  IO := nil;
  inherited Destroy;
end;

procedure TDRLIO.Screenshot ( aBB : Boolean );
var iFName : AnsiString;
    iName  : AnsiString;
    iExt   : AnsiString;
    iCount : DWord;
    iCon   : TUIConsole;
begin
  if GraphicsVersion
     then iExt := '.png'
     else iExt := '.txt';

  iName := 'DRL';
  if Player <> nil then iName := Player.Name;
  if not DirectoryExists( ModuleUserPath + 'screenshot' ) then CreateDir( ModuleUserPath + 'screenshot' );
  iFName := ModuleUserPath + 'screenshot'+PathDelim+ToProperFilename('['+FormatDateTime(Option_TimeStamp,Now)+'] '+iName)+iExt;
  iCount := 1;
  while FileExists(iFName) do
  begin
    iFName := ModuleUserPath + 'screenshot'+PathDelim+ToProperFilename('['+FormatDateTime(Option_TimeStamp,Now)+'] '+iName)+'-'+IntToStr(iCount)+iExt;
    Inc(iCount);
  end;

  Log('Writing screenshot...: '+iFName);
  if not GraphicsVersion then
  begin
    iCon.Init( FConsole );
    if aBB then iCon.ScreenShot(iFName,1)
           else iCon.ScreenShot(iFName);
  end
  else
  begin
    TSDLIODriver(FIODriver).ScreenShot(iFName);
  end;
    {  if aBB then UI.Msg('BB Screenshot created.')
             else UI.Msg('Screenshot created.');}
end;

procedure TDRLIO.DrawHud;
var iCon        : TUIConsole;
    iWeapon     : TItem;
    i, iP       : Integer;
    iColor      : TUIColor;
    iHPP        : Integer;
    iPos        : TIOPoint;
    iBottom     : Integer;
    iDesc       : Ansistring;
    iCNormal    : DWord;
    iCBold      : DWord;
    iCurrent    : DWord;
    iOffset     : Integer;
    iBoss       : TBeing;

  function ArmorColor( aValue : Integer ) : TUIColor;
  begin
    case aValue of
     -100.. 25  : Exit(LightRed);
      26 .. 49  : Exit(Yellow);
      50 ..1000 : Exit(LightGray);
      else Exit(LightGray);
    end;
  end;
  function NameColor( aValue : Integer ) : TUIColor;
  begin
    case aValue of
     -100.. 25  : Exit(LightRed);
      26 .. 49  : Exit(Yellow);
      50 ..1000 : Exit(LightBlue);
      else Exit(LightGray);
    end;
  end;
  function WeaponColor( aWeapon : TItem ) : TUIColor;
  begin
    if aWeapon.IType = ITEMTYPE_MELEE then Exit(lightgray);
    if ( aWeapon.Ammo = 0 ) and not ( aWeapon.Flags[ IF_NOAMMO ] ) then Exit(LightRed);
    Exit(LightGray);
  end;
  function ExpString : AnsiString;
  begin
    if Player.ExpLevel >= MaxPlayerLevel - 1 then Exit('MAX');
    Exit(IntToStr(Clamp(Floor(((Player.Exp-ExpTable[Player.ExpLevel]) / (ExpTable[Player.ExpLevel+1]-ExpTable[Player.ExpLevel]))*100),0,99))+'%');
  end;

begin
  iCNormal := DarkGray;
  iCBold   := LightGray;
  if FNarrowMode then
  begin
    iCNormal := VTIGDefaultStyle.Color[ VTIG_TEXT_COLOR ];
    iCBold   := VTIGDefaultStyle.Color[ VTIG_BOLD_COLOR ];
  end;

  iCon.Init( FConsole );
  if GraphicsVersion then
    iCon.Clear;

  if Player <> nil then
  begin
    iPos    := Point( 1,FConsole.SizeY-3 );
    iBottom := FConsole.SizeY-1;
    if GraphicsVersion then
    begin
      if FNarrowMode then
      begin
        iPos    := Point( 1,FConsole.SizeY-3 );
        iBottom := FConsole.SizeY-4;
      end
      else
      begin
        iPos    := Point( 1,FConsole.SizeY-2 );
        iBottom := FConsole.SizeY-3;
      end;
    end;
    iHPP    := Round((Player.HP/Player.HPMax)*100);

    VTIG_FreeLabel( 'A:',                                 iPos + Point(28,0), iCNormal );
    VTIG_FreeLabel( Player.Name,                          iPos + Point(1,0),  NameColor(iHPP) );
    VTIG_FreeLabel( 'Health:      Exp:   /      W:',      iPos + Point(1,1),  iCNormal );
    VTIG_FreeLabel( IntToStr(iHPP)+'%',                   iPos + Point(9,1),  Red );
    VTIG_FreeLabel( TwoInt(Player.ExpLevel),              iPos + Point(19,1), iCBold );
    VTIG_FreeLabel( ExpString,                            iPos + Point(22,1), iCBold );

    iWeapon := Player.Inv.Slot[efWeapon];
    if iWeapon = nil
      then VTIG_FreeLabel( 'none',                                iPos + Point(31,1), iCBold )
      else
      begin
        if iWeapon.isRanged and ( not iWeapon.Flags[ IF_NOAMMO ] ) and ( not iWeapon.Flags[ IF_RECHARGE ] ) then
        begin
          if FCachedAmmo = -1 then
            FCachedAmmo := Player.Inv.CountAmount( iWeapon.AmmoID );
          iDesc := Player.Inv.Slot[efWeapon].Description;
          if Length( iDesc ) > 42 then iDesc := Copy(iDesc, 1, 42 );
          VTIG_FreeLabel( iDesc, iPos + Point(31,1), WeaponColor(Player.Inv.Slot[efWeapon]) );
          VTIG_FreeLabel( ' ({0})', iPos + Point(31+Length(iDesc),1), [ FCachedAmmo ], iCNormal );
        end
        else
          VTIG_FreeLabel( Player.Inv.Slot[efWeapon].Description, iPos + Point(31,1), WeaponColor(Player.Inv.Slot[efWeapon]) );
      end;

    if Player.Inv.Slot[efTorso] = nil
      then VTIG_FreeLabel( 'none',                                iPos + Point(31,0), iCBold )
      else VTIG_FreeLabel( Player.Inv.Slot[efTorso].Description,  iPos + Point(31,0), ArmorColor(Player.Inv.Slot[efTorso].Durability) );

    iColor := Red;
    if DRL.Level.Empty
      then iColor := Blue
      else if DRL.Level.Flags[ LF_ENRAGE ]
        then iColor := LightMagenta;

    VTIG_FreeLabel( DRL.Level.Name, Point( -2-Length( DRL.Level.Name), iBottom ), iColor );

    iP := 0;
    for i := 1 to MAXAFFECT do
      if Player.Affects.IsActive(i) then
      begin
        if Player.Affects.IsExpiring(i)
          then iColor := Affects[i].Color_exp
          else iColor := Affects[i].Color;
        VTIG_FreeLabel( Affects[i].name, Point( iPos.X+iP+1, iBottom ), iColor );
        iP += Length( Affects[i].name ) + 1;
      end;
  end;

  iOffset := -2;

  if FHintOverlay <> ''
    then VTIG_FreeLabel( ' '+FHintOverlay+' ', Point( iOffset-Length( FHintOverlay ), 2 ), Yellow )
    else if ( (FHint <> '') and ( not GraphicsVersion ) )
      then VTIG_FreeLabel( ' '+FHint+' ', Point( iOffset-Length( FHint ), 2 ), Yellow )
      else if (FHintTarget <> '') and Setting_AutoTarget
        then VTIG_FreeLabel( ' '+FHintTarget+' ', Point( iOffset-Length( FHintTarget ), 2 ), Brown );

  if GraphicsVersion and ( FHint <> '' ) then
    VTIG_FreeLabel( ' '+FHint+' ', Point( 20, 4 ), Yellow );

  if ( DRL.Level <> nil ) and ( DRL.Level.Boss <> 0 ) then
  begin
    iBoss := UIDs.Get( DRL.Level.Boss ) as TBeing;
    if iBoss <> nil then
    begin
      VTIG_FreeLabel( iBoss.Name, Point( 40 - Ceil(Length( iBoss.Name ) / 2), 3 ), iCBold );
      iOffset := Round(iBoss.HPMax / 5);
      i       := Round(iBoss.HP / 5);
      if (i = 0) and (iBoss.HP > 0) then i := 1;
      VTIG_FreeLabel( '[{R'+StringOfChar('#',i)+'}{r'+StringOfChar('-',iOffset-i)+'}]', Point( 40 - Ceil(iOffset / 2), 4 ), iCBold );
    end;
  end;

  iOffset := 2;
  for i := 1 to 2 do
  begin
    if i > FMessages.Size then Continue;
    VTIG_HighColor := i <= FMessages.Active;
    iCurrent := iCNormal;
    if FNarrowMode and ( i <= FMessages.Active ) then
      iCurrent := iCBold;
    VTIG_FreeLabel( FMessages.Content[ -i ], Point(iOffset,2-i), iCurrent );
    VTIG_HighColor := False;
  end;
end;

procedure TDRLIO.SetHint ( const aText : AnsiString ) ;
begin
  FHint       := aText;
end;

procedure TDRLIO.ColorQuery(nkey,nvalue : Variant);
begin
    ColorOverrides[nkey] := nvalue;
end;

function TDRLIO.ScreenShotCallback ( aEvent : TIOEvent ) : Boolean;
begin
  ScreenShot( False );
  Exit(True);
end;

function TDRLIO.BBScreenShotCallback ( aEvent : TIOEvent ) : Boolean;
begin
  ScreenShot( True );
  Exit(True);
end;

function TDRLIO.Chunkify( const aString : AnsiString; aStart : Integer; aColor : TIOColor ) : TUIChunkBuffer;
var iCon       : TUIConsole;
    iChunkList : TUIChunkList;
    iPosition  : TUIPoint;
    iColor     : TUIColor;
begin
  iCon.Init( IO.Console );
  iPosition  := Point(aStart,0);
  iColor     := aColor;
  iChunkList := nil;
  iCon.ChunkifyEx( iChunkList, iPosition, iColor, aString, iColor, Point(78,2) );
  Exit( iCon.LinifyChunkList( iChunkList ) );
end;

procedure TDRLIO.ASCIILoader ( aStream : TStream; aName : Ansistring; aSize : DWord ) ;
var iNewImage   : TUIStringArray;
    iIdent      : Ansistring;
begin
  iIdent  := LowerCase(LeftStr(aName,Length(aName)-4));
  Log('Registering ascii file '+aName+' as '+iIdent+'...');
  iNewImage  := TUIStringArray.Create;
  while (aStream.Position < aSize) and (iNewImage.Size < 25) do
    iNewImage.Push( ReadLineFromStream( aStream, aSize ) );
  FASCII.Items[iIdent] := iNewImage;
end;

procedure TDRLIO.EventMore;
begin
  if Option_MorePrompt then
  begin
    IO.PushLayer( TMoreLayer.Create( True ) );
    IO.WaitForLayer( False );
  end;
end;

procedure TDRLIO.LoadStart;
begin
  if FLoading = nil then
    FLoading := PushLayer( TLoadingView.Create( 100 ) ) as TLoadingView;
end;

function TDRLIO.LoadCurrent : DWord;
begin
  if Assigned( FLoading ) then Exit( FLoading.Current );
  Exit( 0 );
end;

procedure TDRLIO.LoadProgress ( aProgress : DWord ) ;
begin
  if Assigned( FLoading ) then FLoading.Current := aProgress;
  FullUpdate;
end;

procedure TDRLIO.LoadStop;
begin
  if Assigned( FLoading ) then
  begin
    FLoading.Finished := True;
    FLoading := nil;
  end;
end;

procedure TDRLIO.Update( aMSec : DWord );
begin
  if Assigned( Sound ) then
    Sound.Update;
  if Assigned( DRL ) then
    DRL.Store.Update;

  if GetPadRTrigger and (DRL <> nil) and (DRL.State = DSPlaying)
    and (FTargeting or ( not isModal)) and ( FLastTarget <> DRL.Targeting.List.Current ) then
    begin
      FLastTarget := DRL.Targeting.List.Current;
      if (FLastTarget.X * FLastTarget.Y <> 0) and (FLastTarget <> Player.Position) then
        LookDescription(FLastTarget);
    end;

  if not GetPadRTrigger and (FLastTarget.X * FLastTarget.Y <> 0) then
  begin
    FHintOverlay := '';
    FLastTarget.Create(0,0);
  end;

  FTime += aMSec;
  FAudio.Update( aMSec );

  inherited Update( aMSec );
 // if aMSec > 200 then
 //   VTIG_EventClear;
end;

function TDRLIO.EventToUIInput( const aEvent : TIOEvent ) : Integer;
begin
  if ( aEvent.EType = VEVENT_SYSTEM ) and ( aEvent.System.Code = VIO_SYSEVENT_QUIT ) then
    if Option_LockClose
       then Exit( Integer( INPUT_QUIT ) )
       else Exit( Integer( INPUT_HARDQUIT ) );
  if (aEvent.EType = VEVENT_MOUSEMOVE) then
  begin
    if not Setting_Mouse then Exit( Integer( INPUT_NONE ) );
    FMTarget := SpriteMap.DevicePointToCoord( aEvent.MouseMove.Pos );
    if DRL.Level <> nil then
      if DRL.Level.isProperCoord( FMTarget ) then
        Exit( Integer( INPUT_MMOVE ) );
  end;
  if aEvent.EType = VEVENT_MOUSEDOWN then
  begin
    if not Setting_Mouse then Exit( Integer( INPUT_NONE ) );
    FMTarget := SpriteMap.DevicePointToCoord( aEvent.Mouse.Pos );
    if DRL.Level <> nil then
      if DRL.Level.isProperCoord( FMTarget ) then
      begin
        case aEvent.Mouse.Button of
          VMB_BUTTON_LEFT     : Exit( Integer( INPUT_MLEFT ) );
          VMB_BUTTON_MIDDLE   : Exit( Integer( INPUT_MMIDDLE ) );
          VMB_BUTTON_RIGHT    : Exit( Integer( INPUT_MRIGHT ) );
          VMB_WHEEL_UP        : Exit( Integer( INPUT_MSCRUP ) );
          VMB_WHEEL_DOWN      : Exit( Integer( INPUT_MSCRDOWN ) );
        end;
      end;
  end;
  if aEvent.EType = VEVENT_KEYDOWN then
  begin
    FKeyCode := IOKeyEventToIOKeyCode( aEvent.Key );
    if (FKeyCode mod 256) <> 0
      then Exit( Config.Commands[ FKeyCode ] );
  end;
  Exit( inherited EventToUIInput( aEvent ) );
end;

function TDRLIO.CommandEventPending : Boolean;
var iEvent : TIOEvent;
begin
  repeat
    if not FIODriver.PeekEvent( iEvent ) then Exit( False );
    if ( not Setting_Mouse ) and ( iEvent.EType in [ VEVENT_MOUSEMOVE, VEVENT_MOUSEUP, VEVENT_MOUSEDOWN ] ) then
    begin
      FIODriver.PollEvent( iEvent );
      Continue;
    end;
    if not ( iEvent.EType in [ VEVENT_KEYDOWN, VEVENT_MOUSEDOWN, VEVENT_PADDOWN ] ) then
    begin
      FIODriver.PollEvent( iEvent );
      OnEvent( iEvent );
      Root.OnEvent( iEvent );
      Continue;
    end;
    Break;
  until False;
  Exit( iEvent.EType in [ VEVENT_KEYDOWN, VEVENT_MOUSEDOWN, VEVENT_PADDOWN ] );
end;

procedure TDRLIO.Focus(aCoord: TCoord2D);
begin
  FConsole.MoveCursor(aCoord.x+1,aCoord.y+2);
end;

procedure TDRLIO.FinishTargeting;
begin
  MsgUpDate;
  FConsole.HideCursor;
  FTargeting := False;
  if SpriteMap <> nil then SpriteMap.ClearTarget;
  FTargetEnabled := False;
end;

procedure TDRLIO.LookDescription(aWhere: TCoord2D);
var LookDesc : string;
begin
  LookDesc := DRL.Level.GetLookDescription( aWhere );
  if Option_BlindMode then LookDesc += ' | '+BlindCoord( aWhere - Player.Position );
  if DRL.Level.isVisible(aWhere) and (DRL.Level.Being[aWhere] <> nil) then
    if isGamepad
      then LookDesc += ' | <{LA}> more'
      else LookDesc += ' | <{Lm}>ore';
  FHintOverlay := LookDesc;
end;

procedure TDRLIO.Msg( const aText : AnsiString );
begin
  if FMessages <> nil then FMessages.Add(aText);
end;

procedure TDRLIO.Msg( const aText : AnsiString; const aParams : array of const );
begin
  Msg( Format( aText, aParams ) );
end;

function TDRLIO.MsgGetRecent : TMessageBuffer;
begin
  Exit( FMessages.Content );
end;

procedure TDRLIO.MsgReset;
begin
  FMessages.Reset;
  FMessages.Update;
end;

procedure TDRLIO.MsgUpDate;
begin
  FMessages.Update;
  FHintOverlay := '';
end;

procedure TDRLIO.ErrorReport(const aText: AnsiString);
begin
  Msg('{RError:} '+aText);
  PushLayer( TMoreLayer.Create( False ) );
  WaitForLayer( False );
  Msg('{yError written to error.log, please report!}');
end;

procedure TDRLIO.ClearAllMessages;
begin
  FMessages.Clear;
end;

(**************************** LUA UI *****************************)

function lua_ui_set_hint(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  if not Setting_HideHints then
    IO.SetHint( State.ToString( 1 ) );
  Result := 0;
end;

{$HINTS OFF} // To supress Hint: Parameter "x" not found

function lua_ui_blood_slide(L: Plua_State): Integer; cdecl;
begin
  IO.BloodSlideDown(20);
  Result := 0;
end;

{$HINTS ON}

function lua_ui_blink(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  IO.Blink( State.ToInteger(1), State.ToInteger(2), State.ToInteger(3));
  Result := 0;
end;

function lua_ui_plot_screen(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
begin
  iState.Init(L);
  IO.PushLayer( TPlotView.Create( iState.ToString(1), iState.ToIOColor(2), iState.ToString(3,'') ) );
  IO.WaitForLayer( True );
  Result := 0;
end;

function lua_ui_msg(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  IO.Msg(State.ToString(1));
  Result := 0;
end;

function lua_ui_msg_clear(L: Plua_State): Integer; cdecl;
begin
  IO.MsgReset();
  Result := 0;
end;

function lua_ui_msg_enter(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  if State.StackSize = 0 then Exit(0);
  IO.Msg(State.ToString(1));
  IO.PushLayer( TMoreLayer.Create( False ) );
  IO.WaitForLayer( False );
  IO.MsgUpDate;
  Result := 0;
end;

function lua_ui_msg_history(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
    Idx   : Integer;
    Msg   : AnsiString;
begin
  State.Init(L);
  if State.StackSize = 0 then Exit(0);
  Idx := State.ToInteger(1)+1;
  if Idx > IO.MsgGetRecent.Size then
    State.PushNil
  else
  begin
    Msg := IO.MsgGetRecent[-Idx];
    if Msg <> '' then
      State.Push( Msg )
    else
      State.PushNil;
  end;
  Result := 1;
end;

function lua_ui_strip_encoding(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
begin
  State.Init(L);
  if State.StackSize = 0 then Exit(0);
  State.Push( VTIG_StripTags( State.ToString(1) ) );
  Result := 1;
end;

function lua_ui_choice(L: Plua_State): Integer; cdecl;
var State     : TDRLLuaState;
    iView     : TChoiceView;
    i, iCount : Integer;
    iEntry    : TChoiceViewChoice;
begin
  State.Init(L);
  if State.StackSize < 1 then Exit(0);
  if not State.IsTable( 1 ) then State.Error('Table expected as parameter 1!');

  with TLuaTable.Create( L, 1 ) do
    try
      iView := TChoiceView.Create;
      if IsString('title')      then iView.Title  := GetString( 'title' );
      if IsString('header')     then iView.Header := GetString( 'header' );
      if IsNumber('delay')      then iView.Delay  := GetInteger( 'delay' );
      if not IsNil('cancel')    then iView.Cancel := GetValue( 'cancel' );
      if not IsNil('escape')    then iView.Escape := GetBoolean( 'escape' );
      if not IsTable('entries') then State.Error('Choice call without entries!');
      iCount := GetTableSize('entries');
      for i := 1 to iCount do
        with GetTable(['entries',i]) do
        try
          iEntry.Name    := GetString( 'name', 'ERROR' );
          iEntry.Desc    := GetString( 'desc', '' );
          iEntry.Enabled := GetBoolean( 'enabled', True );
          iEntry.Value   := i;
          if not IsNil('value') then iEntry.Value := GetValue( 'value' );
          iView.Add( iEntry );
        finally
          Free;
        end;
    finally
      Free;
    end;
  IO.PushLayer( iView );
  repeat
    IO.FullUpdate;
    IO.HandleEvents;
  until not IO.IsTopLayer( iView );
  State.PushVariant(TChoiceView.Result);
  Result := 1;
end;

function lua_ui_set_style_color(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iEntry : TTIGStyleColorEntry;
begin
  iState.Init(L);
  if iState.StackSize < 2 then Exit(0);
  iEntry := TTIGStyleColorEntry( iState.ToInteger(1) );
  VTIGDefaultStyle.Color[iEntry] := iState.ToIOColor( 2 );
  Result := 0;
end;

function lua_ui_set_style_frame(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iEntry : TTIGStyleFrameEntry;
begin
  iState.Init(L);
  if iState.StackSize < 2 then Exit(0);
  iEntry := TTIGStyleFrameEntry( iState.ToInteger(1) );
  VTIGDefaultStyle.Frame[iEntry] := iState.ToString(2);
  Result := 0;
end;

function lua_ui_set_style_padding(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iEntry : TTIGStylePaddingEntry;
begin
  iState.Init(L);
  if iState.StackSize < 2 then Exit(0);
  iEntry := TTIGStylePaddingEntry( iState.ToInteger(1) );
  VTIGDefaultStyle.Padding[iEntry] := iState.ToPoint(2);
  Result := 0;
end;

function lua_ui_set_narrow_mode(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
begin
  iState.Init(L);
  IO.FNarrowMode := iState.ToBoolean(1);
  Result := 0;
end;

function lua_ui_update_styles(L: Plua_State): Integer; cdecl;
begin
  IO.UpdateStyles;
  Result := 0;
end;

function lua_ui_is_pad(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
begin
  iState.Init(L);
  iState.Push( IO.IsGamepad );
  Result := 1;
end;

function lua_ui_get_rank(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
begin
  iState.Init(L);
  iState.Push( HOF.GetRank( iState.ToString( 1 ) ) );
  Result := 1;
end;

function lua_ui_save_and_quit(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
begin
  iState.Init(L);
  ForceShop := iState.ToBoolean(1);
  IO.FadeOut(0.5);
  DRL.SetState( DSSaving );
  Result := 0;
end;


const lua_ui_lib : array[0..18] of luaL_Reg = (
      ( name : 'msg';           func : @lua_ui_msg ),
      ( name : 'msg_clear';     func : @lua_ui_msg_clear ),
      ( name : 'msg_enter';     func : @lua_ui_msg_enter ),
      ( name : 'msg_history';   func : @lua_ui_msg_history ),
      ( name : 'choice';        func : @lua_ui_choice ),
      ( name : 'blood_slide';   func : @lua_ui_blood_slide),
      ( name : 'blink';         func : @lua_ui_blink),
      ( name : 'plot_screen';   func : @lua_ui_plot_screen),
      ( name : 'set_hint';      func : @lua_ui_set_hint ),
      ( name : 'strip_encoding';func : @lua_ui_strip_encoding ),
      ( name : 'set_style_color';   func : @lua_ui_set_style_color ),
      ( name : 'set_style_frame';   func : @lua_ui_set_style_frame ),
      ( name : 'set_style_padding'; func : @lua_ui_set_style_padding ),
      ( name : 'set_narrow_mode';   func : @lua_ui_set_narrow_mode ),
      ( name : 'update_styles';     func : @lua_ui_update_styles ),
      ( name : 'is_pad';            func : @lua_ui_is_pad ),
      ( name : 'get_rank';          func : @lua_ui_get_rank ),
      ( name : 'save_and_quit';     func : @lua_ui_save_and_quit ),
      ( name : nil;          func : nil; )
);

procedure TDRLIO.RunModuleChoice;
begin
  PushLayer( TModuleChoiceView.Create );
  WaitForLayer( True );
end;

class procedure TDRLIO.RegisterLuaAPI( State : TLuaState );
begin
  State.Register( 'ui', lua_ui_lib );
end;

procedure EmitCrashInfo ( const aInfo : AnsiString; aInGame : Boolean ) ;
function Iff(expr : Boolean; const str : AnsiString) : AnsiString;
begin
  if expr then exit(str) else exit('');
end;
var iErrorMessage : AnsiString;
begin
  {$IFDEF WINDOWS}
  if GraphicsVersion then
  begin
    iErrorMessage := 'DRL crashed!'#10#10'Reason : '+aInfo+#10#10
     +'If this reason doesn''t seem your fault, please submit a bug report at http://forum.chaosforge.org/'#10
     +'Be sure to include the last entries in your error.log that will get created once you hit OK.'
     +Iff(aInGame and Option_SaveOnCrash,#10'DRL will also attempt to save your game, so you may continue on the next level.');
    MessageBox( 0, PChar(iErrorMessage),
     'DRL - Fatal Error!', MB_OK or MB_ICONERROR );
  end
  else
  {$ENDIF}
  begin
    DoneVideo;
    Writeln;
    Writeln;
    Writeln;
    Writeln('Abnormal program termination!');
    Writeln;
    Writeln('Reason : ',aInfo);
    Writeln;
    Writeln('If this reason doesn''t seem your fault, please submit a bug report at' );
    Writeln('http://forum.chaosforge.org/, be sure to include the last entries in');
    Writeln('your error.log that will get created once you hit Enter.');
    if aInGame and Option_SaveOnCrash then
    begin
      Writeln( 'DRL will also attempt to save your game, so you may continue on' );
      Writeln( 'the next level.' );
    end;
    Readln;
  end;
end;

end.

