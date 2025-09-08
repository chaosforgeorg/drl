{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlbase;
interface

uses vnode, vutil, vuid, viotypes, vrltools, vluasystem, vioevent, vstoreinterface,
     dflevel, dfdata, dfhof, dfitem,
     drlhooks, drlua, drlcommand, drlkeybindings, drlmodule;

type TTargeting = class
  constructor Create;
  procedure Clear;
  procedure ClearPosition;
  procedure Update( aRange : Integer );
  procedure OnTarget( aTarget : TCoord2D; aMove : Boolean );
  destructor Destroy; override;
private
  FList    : TAutoTarget;
  FLastUID : TUID;
  FLastPos : TCoord2D;
  FPrevPos : TCoord2D;
public
  property List : TAutoTarget read FList;
  property PrevPos : TCoord2D read FPrevPos;
end;

type TDRLState = ( DSStart,      DSMenu,    DSLoading,   DSCrashLoading,
                    DSPlaying,    DSSaving,  DSNextLevel,
                    DSQuit,       DSFinished );

type

{ TDRL }

TDRL = class(TVObject)
       constructor Create;
       procedure RunModuleChoice;
       procedure Reset;
       procedure Reconfigure;
       procedure Initialize;
       procedure Load;
       procedure UnLoad;
       function LoadSaveFile : Boolean;
       procedure WriteSaveFile( aCrash : Boolean );
       function SaveExists : Boolean;
       function Action( aInput : TInputKey ) : Boolean;
       procedure Run;
       destructor Destroy; override;
       procedure CallHook( Hook : Byte; const Params : array of Const );
       function  CallHookCheck( Hook : Byte; const Params : array of Const ) : Boolean;
       procedure CallModuleHook( aHook : Byte; const aParams : array of Const );
       procedure SafeCallModuleHook( aHook : Byte; const aParams : array of Const );
       procedure SetState( aNewState : TDRLState );
       procedure ClearPlayerView;
       procedure OpenJHCPage;
       function HandleUnloadCommand( aItem : TItem ) : Boolean;
       function HandleCommand( aCommand : TCommand ) : Boolean;
       function HandleActionCommand( aInput : TInputKey ) : Boolean;
       function HandleActionCommand( aTarget : TCoord2D; aFlag : Byte ) : Boolean;
       function HandleMoveCommand( aInput : TInputKey; aAlt : Boolean ) : Boolean;
       function HandleFireCommand( aAlt : Boolean; aMouse : Boolean; aAuto : Boolean; aPad : Boolean ) : Boolean;
       function HandleUsableCommand( aItem : TItem ) : Boolean;
       function HandleSwapWeaponCommand : Boolean;
       function HandlePickupCommand( aAlt : Boolean ) : Boolean;
     private
       procedure Apply( aResult : TMenuResult );
       procedure ResetAutoTarget;
       function HandleMouseEvent( aEvent : TIOEvent ) : Boolean;
       function HandleKeyEvent( aEvent : TIOEvent ) : Boolean;
       function HandlePadMovement( aEvent : TIOEvent ) : Boolean;
       function HandlePadEvent( aEvent : TIOEvent ) : Boolean;
       function MoveTargetEvent( aCoord : TCoord2D ) : Boolean;
       procedure PreAction;
       procedure CreatePlayer( aResult : TMenuResult );
     private
       FState           : TDRLState;
       FLevel           : TLevel;
       FLastInputTime   : QWord;
       FTargeting       : TTargeting;
       FDamagedLastTurn : Boolean;
       FPlayerView      : TIOLayer;
       FPadMoveActive   : Boolean;
       FPadMoveNext     : QWord;
       FStore           : TStoreInterface;
       FPadMoved        : Boolean;
       FModules         : TDRLModules;

       FCoreHooks       : TFlags;
       FChallengeHooks  : TFlags;
       FSChallengeHooks : TFlags;
       FModuleHooks     : TFlags;

       FDifficulty      : Byte;
       FChallenge       : AnsiString;
       FSChallenge      : AnsiString;
       FArchAngel       : Boolean;
       FDataLoaded      : Boolean;
       FGameWon         : Boolean;
       FCrashSave       : Boolean;
     public
       property GameWon : Boolean read FGameWon write FGameWon;
       property Difficulty : Byte read FDifficulty;
       property Challenge  : Ansistring read FChallenge;
       property SChallenge : Ansistring read FSChallenge;

       property Store : TStoreInterface read FStore;
       property Modules : TDRLModules read FModules;
       property Level : TLevel read FLevel;
       property State : TDRLState read FState;
       property Targeting : TTargeting read FTargeting;
       property DamagedLastTurn : Boolean read FDamagedLastTurn write FDamagedLastTurn;
     end;

var DRL : TDRL;
var Lua : TDRLLua;


implementation

uses  {$IFDEF WINDOWS}Windows,{$ELSE}Unix,{$ENDIF}
     Classes, SysUtils,
     vdebug,
     dfmap, dfbeing,
     drlio, drlgfxio, drltextio, zstream,
     drlspritemap, // remove
     drlplayerview, drlingamemenuview, drlhelpview, drlassemblyview,
     drlpagedview, drlrankupview, drlmainmenuview, drlhudviews, drlmessagesview,
     drlconfiguration, drlhelp, drlconfig, dfplayer;

const PAD_REPEAT_START = 400;
      PAD_REPEAT       = 100;

constructor TTargeting.Create;
begin
  FList    := TAutoTarget.Create( NewCoord2D(0,0) );
end;

procedure TTargeting.Clear;
begin
  FList.Clear( NewCoord2D(0,0) );
  FLastPos.Create(0,0);
  FLastUID := 0;
end;

procedure TTargeting.ClearPosition;
begin
  FLastPos.Create(0,0);
end;

procedure TTargeting.Update( aRange : Integer );
var iBeing : TBeing;
begin
  DRL.Level.UpdateAutoTarget( FList, Player, aRange );
  if (FLastUID <> 0) and DRL.Level.isAlive( FLastUID ) then
  begin
    iBeing := DRL.Level.FindChild( FLastUID ) as TBeing;
    if iBeing <> nil then
      if iBeing.isVisible then
        if Distance( iBeing.Position, Player.Position ) <= aRange then
          FList.PriorityTarget( iBeing.Position );
  end;

  if FLastPos.X*FLastPos.Y <> 0 then
    if FLastUID = 0 then
//    if DRL.Level.isVisible( FLastPos ) then
//      if Distance( FLastPos, Player.Position ) <= aRange then
          FList.PriorityTarget( FLastPos );
end;

procedure TTargeting.OnTarget( aTarget : TCoord2D; aMove : Boolean );
begin
  if FLastPos.X*FLastPos.Y <> 0
    then FPrevPos := FLastPos
    else FPrevPos := aTarget;
  FLastUID := 0;
  if (not aMove) and (DRL.Level.Being[ aTarget ] <> nil) and ( DRL.Level.Flags[ LF_BEINGSVISIBLE ] or DRL.Level.isVisible(aTarget) ) then
    FLastUID := DRL.Level.Being[ aTarget ].UID;
  FLastPos := aTarget;
end;

destructor TTargeting.Destroy;
begin
  FreeAndNil( FList );
  inherited Destroy;
end;

procedure TDRL.CallHook( Hook : Byte; const Params : array of const ) ;
begin
  if (Hook in FModuleHooks) then LuaSystem.ProtectedCall([CoreModuleID,HookNames[Hook]],Params);
  if (FChallenge <> '')  and (Hook in FChallengeHooks) then LuaSystem.ProtectedCall(['chal',FChallenge,HookNames[Hook]],Params);
  if (FSChallenge <> '') and (Hook in FSChallengeHooks) then LuaSystem.ProtectedCall(['chal',FSChallenge,HookNames[Hook]],Params);
  if (Hook in FCoreHooks) then LuaSystem.ProtectedCall(['core',HookNames[Hook]],Params);
end;

function TDRL.CallHookCheck ( Hook : Byte; const Params : array of const ) : Boolean;
begin
  if (Hook in FCoreHooks) then if not LuaSystem.ProtectedCall(['core',HookNames[Hook]],Params) then Exit( False );
  if (FChallenge <> '') and (Hook in FChallengeHooks) then if not LuaSystem.ProtectedCall(['chal',FChallenge,HookNames[Hook]],Params) then Exit( False );
  if (FSChallenge <> '') and (Hook in FSChallengeHooks) then if not LuaSystem.ProtectedCall(['chal',FSChallenge,HookNames[Hook]],Params) then Exit( False );
  if Hook in FModuleHooks then if not LuaSystem.ProtectedCall([CoreModuleID,HookNames[Hook]],Params) then Exit( False );
  Exit( True );
end;

procedure TDRL.CallModuleHook( aHook : Byte; const aParams : array of const ) ;
var iModule : TDRLModule;
begin
  for iModule in FModules.ActiveModules do
    if aHook in iModule.Hooks then
      LuaSystem.ProtectedCall([iModule.ID,HookNames[aHook]],aParams);
end;

procedure TDRL.SafeCallModuleHook( aHook : Byte; const aParams : array of const ) ;
var iModule : TDRLModule;
begin
  for iModule in FModules.ActiveModules do
    if aHook in iModule.Hooks then
    try
      LuaSystem.ProtectedCall([iModule.ID,HookNames[aHook]],aParams);
    except
      on E : Exception do
      begin
        if ModdedGame then
        begin
          ModErrors.Push('Error : Mod "'+iModule.ID+'" failed to execute '+HookNames[aHook]+'!');
          ModErrors.Push('Path  : '+iModule.Path);
          ModErrors.Push( E.Message );
          ModErrors.Push( '' );
        end
        else raise;
      end;
    end;
end;

procedure TDRL.SetState( aNewState: TDRLState );
begin
  if ( FState = aNewState ) then Exit;
  if ( FState = DSPlaying ) then
  begin
    IO.FadeWait;
    if ( aNewState <> DSQuit) then IO.FadeReset;
  end;
  FState := aNewState;
end;

procedure TDRL.ClearPlayerView;
begin
  FPlayerView := nil;
end;

procedure TDRL.OpenJHCPage;
const JHCURL      = 'https://store.steampowered.com/app/3126530/Jupiter_Hell_Classic/';
      JHCSTEAMURL = 'steam://store/3126530';
      JHCID       = 3126530;
var iSteam : Boolean;
    iURL   : Ansistring;
begin
  iSteam := DemoVersion and FStore.IsInitialized;
  if iSteam and FStore.IsOverlayEnabled then
  begin
    FStore.OpenStorePage( JHCID );
    Exit;
  end;
  if iSteam
    then iURL := JHCSTEAMURL
    else iURL := JHCURL;
  {$IFDEF UNIX}
  fpSystem('xdg-open ' + iURL); // Unix-based systems
  {$ENDIF}
  {$IFDEF WINDOWS}
    ShellExecute(0, 'open', PChar(iURL), nil, nil, SW_SHOWNORMAL); // Windows
  {$ENDIF}
end;

procedure TDRL.Load;
var iLua : TDRLLua;
    i    : Integer;
begin
  FreeAndNil( Config );
  IO.LoadStart;
  ColorOverrides := TIntHashMap.Create( );
  Config := TDRLConfig.Create( ConfigurationPath, True );
  IO.Configure( Config, True );
  FCoreHooks := [];
  FModuleHooks := [];
  FChallengeHooks := [];
  FSChallengeHooks := [];
  Cells := TCells.Create;
  Help := THelp.Create;

  SetState( DSLoading );
  iLua := TDRLLua.Create();
  LuaSystem := iLua;
  LuaSystem.CallDefaultResult := True;
//  Modules.RegisterAwards( LuaSystem.Raw );
  FCoreHooks   := LoadHooks( [ 'core' ] ) * GlobalHooks;
  FModuleHooks := LoadHooks( [CoreModuleID] ) * GlobalHooks;

  SafeCallModuleHook( Hook_OnLoad, [] );
  Reconfigure;

  if GraphicsVersion then
    (IO as TDRLGFXIO).Textures.Upload;

  if GodMode and FileExists( WritePath + 'god.lua') then
    Lua.LoadFile( WritePath + 'god.lua');
  HOF.Init;
  FLevel := TLevel.Create;
  if not GraphicsVersion then
    (IO as TDRLTextIO).SetTextMap( FLevel );

  HARDSPRITE_HIGHLIGHT    := Lua.Get( 'HARDSPRITE_HIGHLIGHT' );
  HARDSPRITE_EXPL         := Lua.Get( 'HARDSPRITE_EXPL' );
  HARDSPRITE_SELECT       := Lua.Get( 'HARDSPRITE_SELECT' );
  HARDSPRITE_MARK         := Lua.Get( 'HARDSPRITE_MARK' );
  HARDSPRITE_GRID         := Lua.Get( 'HARDSPRITE_GRID' );
  HARDSPRITE_SHIELD       := Lua.Get( 'HARDSPRITE_SHIELD' );
  HARDSPRITE_SHIELD_COUNT := Lua.Get( 'HARDSPRITE_SHIELD_COUNT' );
  for i := 0 to 3 do
  begin
    HARDSPRITE_DECAL_BLOOD[i]      := 0;
    HARDSPRITE_DECAL_WALL_BLOOD[i] := 0;
  end;

  if Lua.RawDefined( 'HARDSPRITE_DECAL_BLOOD_1' ) then
    for i := 0 to 3 do
      HARDSPRITE_DECAL_BLOOD[i] := Lua.Get( 'HARDSPRITE_DECAL_BLOOD_'+IntToStr(i+1), 0 );

  if Lua.RawDefined( 'HARDSPRITE_DECAL_WALL_BLOOD_1' ) then
    for i := 0 to 3 do
      HARDSPRITE_DECAL_WALL_BLOOD[i] := Lua.Get( 'HARDSPRITE_DECAL_WALL_BLOOD_'+IntToStr(i+1), 0 );

  FDataLoaded := True;
  IO.LoadStop;
end;

procedure TDRL.UnLoad;
begin
  FDataLoaded := False;
  HOF.Done;
  FreeAndNil(LuaSystem);
  FreeAndNil(Help);
  FreeAndNil(FLevel);
  FreeAndNil(ColorOverrides);
  FreeAndNil(Cells);
end;

constructor TDRL.Create;
begin
  FTargeting := TTargeting.Create;
  Reset;
  FStore     := TStoreInterface.Get;
  Log( VersionToString( ArrayToVersion(VERSION_ARRAY) ) );
  Reconfigure;
  if GraphicsVersion
    then IO := TDRLGFXIO.Create
    else IO := TDRLTextIO.Create;

  ModErrors := TStringGArray.Create;

  FModules := TDRLModules.Create;
  FModules.ScanModules;
end;

procedure TDRL.RunModuleChoice;
begin
  IO.RunModuleChoice;
end;


procedure TDRL.Reset;
begin
  FreeAndNil( FLevel );

  SetState( DSStart );
  FTargeting.Clear;
  FDifficulty := 0;
  FChallenge  := '';
  FSChallenge := '';
  FArchAngel  := False;
  FDataLoaded := False;
  FGameWon    := False;
  FCrashSave  := False;

  FLastInputTime   := 0;
  FDamagedLastTurn := False;
  FPadMoveNext     := 0;
  FPadMoved        := False;
  FCoreHooks       := [];;
  FModuleHooks     := [];
  FChallengeHooks  := [];
  FSChallengeHooks := [];
  FLastInputTime   := 0;
  FPlayerView      := nil;
  FPadMoveActive   := False;

  if IO <> nil then IO.Reset;
end;

procedure TDRL.Reconfigure;
begin
  if Assigned( IO ) then
    IO.Reconfigure( Config );
  Setting_AlwaysRandomName := Configuration.GetBoolean( 'always_random_name' );
  Setting_NoIntro          := Configuration.GetBoolean( 'skip_intro' );
  Setting_Flash            := Configuration.GetBoolean( 'flashing_fx' );
  Setting_Glow             := Configuration.GetBoolean( 'glow_fx' );
  Setting_BloodPulse       := Configuration.GetBoolean( 'pulse_fx' );
  Setting_ScreenShake      := Configuration.GetBoolean( 'screen_shake' );
  Setting_RunOverItems     := Configuration.GetBoolean( 'run_over_items' );
  Setting_HideHints        := Configuration.GetBoolean( 'hide_hints' );
  Setting_EmptyConfirm     := Configuration.GetBoolean( 'empty_confirm' );
  Setting_Mouse            := Configuration.GetBoolean( 'enable_mouse' );
  Setting_GamepadRumble    := Configuration.GetBoolean( 'enable_rumble' );
  Setting_MouseEdgePan     := Configuration.GetBoolean( 'mouse_edge_pan' );
  Setting_UnlockAll        := Configuration.GetBoolean( 'unlock_all' );
  Setting_MenuSound        := Configuration.GetBoolean( 'menu_sound' );
  Setting_GroupMessages    := Configuration.GetBoolean( 'group_messages' );
  Setting_ItemDropAnimation:= Configuration.GetBoolean( 'item_drop_animation' );
  Setting_Fade             := Configuration.GetBoolean( 'fade_fx' );
end;

procedure TDRL.Initialize;
begin
  FModules.ActivateModules( CoreModuleID );
  IO.Initialize;
  IO.LoadStart;
  ProgramRealTime := MSecNow();
  IO.Configure( Config );
  IO.Reconfigure( Config );
end;

procedure TDRL.Apply ( aResult : TMenuResult ) ;
begin
  if aResult.Quit   then SetState( DSQuit );
  if not aResult.Loaded then
  begin
    FDifficulty     := aResult.Difficulty;
    FChallenge      := aResult.Challenge;
    FArchAngel      := aResult.ArchAngel;
    FSChallenge     := aResult.SChallenge;
  end;

  LuaSystem.SetValue('DIFFICULTY', FDifficulty);
  LuaSystem.SetValue('CHALLENGE',  FChallenge);
  LuaSystem.SetValue('SCHALLENGE', FSChallenge);
  LuaSystem.SetValue('ARCHANGEL', FArchAngel);

  FChallengeHooks := [];
  FSChallengeHooks := [];
  if FChallenge  <> '' then FChallengeHooks  := LoadHooks( ['chal',FChallenge] ) * GlobalHooks;
  if FSChallenge <> '' then FSChallengeHooks := LoadHooks( ['chal',FSChallenge] ) * GlobalHooks;
end;

procedure TDRL.PreAction;
begin
  FLevel.CalculateVision( Player.Position );
  StatusEffect := Player.Affects.getEffect;
  IO.PreAction;
  IO.Focus( Player.Position );
  Player.UpdateVisual;
  if GraphicsVersion then
    (IO as TDRLGFXIO).UpdateMinimap;
  Player.PreAction;
  FTargeting.Update( Player.Vision );
  IO.SetAutoTarget( FTargeting.List.Current );
  if ( FPlayerView <> nil ) and (not FDamagedLastTurn) and (Player.EnemiesInVision < 1) then
     (FPlayerView as TPlayerView).Retain;
end;

function TDRL.Action( aInput : TInputKey ) : Boolean;
var iDir : TDirection;
begin
  if aInput in [INPUT_RUNWAIT]+INPUT_MULTIMOVE then
  begin
    Player.MultiMove.Stop;
    iDir    := InputDirection( aInput );
    if ModuleOption_MeleeMoveOnKill and ( aInput <> INPUT_RUNWAIT ) then
      if ( Player.TryMove( Player.Position + iDir ) in [ MoveBeing, MoveBlock ] )
        then Exit( HandleMoveCommand( aInput, True ) );

    if Player.EnemiesInVision > 0
      then IO.Msg( 'Can''t multi-move, there are enemies present.',[] )
      else Player.MultiMove.Start( iDir );
    Exit;
  end;

  if aInput in INPUT_MOVE then
    Exit( HandleMoveCommand( aInput, False ) );

  case aInput of
    INPUT_FIRE       : Exit( HandleFireCommand( False, False, Setting_AutoTarget, False ) );
    INPUT_ALTFIRE    : Exit( HandleFireCommand( True, False, Setting_AutoTarget, False ) );
    INPUT_TARGET     : Exit( HandleFireCommand( False, False, False, False ) );
    INPUT_ALTTARGET  : Exit( HandleFireCommand( True, False, False, False ) );
    INPUT_ACTION     : Exit( HandleActionCommand( INPUT_ACTION ) );
    INPUT_LEGACYOPEN : Exit( HandleActionCommand( INPUT_LEGACYOPEN ) );
    INPUT_LEGACYCLOSE: Exit( HandleActionCommand( INPUT_LEGACYCLOSE ) );
//    INPUT_QUICKKEY_0 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, 'chainsaw' ) ) );
    INPUT_QUICKKEY_1 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '1' ) ) );
    INPUT_QUICKKEY_2 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '2' ) ) );
    INPUT_QUICKKEY_3 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '3' ) ) );
    INPUT_QUICKKEY_4 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '4' ) ) );
    INPUT_QUICKKEY_5 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '5' ) ) );
    INPUT_QUICKKEY_6 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '6' ) ) );
    INPUT_QUICKKEY_7 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '7' ) ) );
    INPUT_QUICKKEY_8 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '8' ) ) );
    INPUT_QUICKKEY_9 : Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '9' ) ) );

    INPUT_ACTIVE     : Exit( HandleCommand( TCommand.Create( COMMAND_ACTIVE ) ) );
    INPUT_WAIT       : Exit( HandleCommand( TCommand.Create( COMMAND_WAIT ) ) );
    INPUT_RELOAD     : Exit( HandleCommand( TCommand.Create( COMMAND_RELOAD ) ) );
    INPUT_ALTRELOAD  : Exit( HandleCommand( TCommand.Create( COMMAND_ALTRELOAD ) ) );
    INPUT_PICKUP     : Exit( HandlePickupCommand( False ) );
    INPUT_ALTPICKUP  : Exit( HandlePickupCommand( True ) );

    INPUT_SWAPWEAPON  : Exit( HandleSwapWeaponCommand );
    INPUT_NONE        : Exit;
  end;
  IO.MsgUpDate;
  IO.Msg('Unknown command. Press {^{$input_menu}} for menu and help.' );
  Exit( False );
end;

function TDRL.HandleActionCommand( aInput : TInputKey ) : Boolean;
var iItem   : TItem;
    iID     : AnsiString;
    iFlag   : Byte;
    iCount  : Byte;
    iScan   : TCoord2D;
    iTarget : TCoord2D;
begin
  iFlag := 0;

  if aInput = INPUT_ACTION then
  begin
    if Level.cellFlagSet( Player.Position, CF_STAIRS ) then
      Exit( HandleCommand( TCommand.Create( COMMAND_ENTER ) ) )
    else
    begin
      iItem := Level.Item[ Player.Position ];
      if ( iItem <> nil ) and ( iItem.isLever ) then
        Exit( HandleCommand( TCommand.Create( COMMAND_USE, iItem ) ) );
    end;
  end;

  if ( aInput = INPUT_LEGACYOPEN ) then
  begin
    iID := 'open';
    iFlag := CF_OPENABLE;
  end;

  if ( aInput = INPUT_LEGACYCLOSE ) then
  begin
    iID := 'close';
    iFlag := CF_CLOSABLE;
  end;

  iCount := 0;
  if iFlag = 0 then
  begin
    for iScan in NewArea( Player.Position, 1 ).Clamped( Level.Area ) do
      if ( iScan <> Player.Position ) and ( Level.cellFlagSet(iScan, CF_OPENABLE) or Level.cellFlagSet(iScan, CF_CLOSABLE) ) then
      begin
        Inc(iCount);
        iTarget := iScan;
      end;
  end
  else
    for iScan in NewArea( Player.Position, 1 ).Clamped( Level.Area ) do
      if Level.cellFlagSet( iScan, iFlag ) and Level.isEmpty( iScan ,[EF_NOITEMS,EF_NOBEINGS] ) then
      begin
        Inc(iCount);
        iTarget := iScan;
      end;

  if iCount = 0 then
  begin
    if iID = ''
      then IO.Msg( 'There''s nothing you can act upon here.' )
      else IO.Msg( 'There''s no door you can %s here.', [ iID ] );
    Exit( False );
  end;

  if iCount > 1 then
  begin
    if iID = ''
      then IO.PushLayer( TActionDirView.Create( 'Action', iFlag ) )
      else IO.PushLayer( TActionDirView.Create( Capitalized(iID)+' door', iFlag ) );
    Exit( False );
  end;

  Exit( HandleActionCommand( iTarget, iFlag ) );
end;

function TDRL.HandleActionCommand( aTarget : TCoord2D; aFlag : Byte ) : Boolean;
begin
  if Level.isProperCoord( aTarget ) then
  begin
    if ( (aFlag <> 0) and Level.cellFlagSet( aTarget, aFlag ) ) or
        ( (aFlag = 0) and ( Level.cellFlagSet( aTarget, CF_CLOSABLE ) or Level.cellFlagSet( aTarget, CF_OPENABLE ) ) ) then
    begin
      if not Level.isEmpty( aTarget ,[EF_NOITEMS,EF_NOBEINGS] ) then
      begin
        IO.Msg( 'There''s something in the way!' );
        Exit( False );
      end;
      // SUCCESS
      Exit( HandleCommand( TCommand.Create( COMMAND_ACTION, aTarget ) ) );
    end;
    IO.Msg( 'You can''t do that!' );
  end;
  Exit( False );
end;

function TDRL.HandleMoveCommand( aInput : TInputKey; aAlt : Boolean ) : Boolean;
var iDir        : TDirection;
    iTarget     : TCoord2D;
    iMoveResult : TMoveResult;
    iItem       : TItem;
    iBeing      : TBeing;
begin
  if Player.Flags[ BF_SESSILE ] then
  begin
    IO.Msg( 'You can''t!' );
    Exit( False );
  end;

  iDir := InputDirection( aInput );
  iTarget := Player.Position + iDir;
  iMoveResult := Player.TryMove( iTarget );

  if Player.MultiMove.IsRepeat and (
       ( iMoveResult <> MoveOk ) or
       Level.cellFlagSet( iTarget, CF_NORUN ) or
       (not Level.isEmpty(iTarget,[EF_NOTELE]))
     ) then
  begin
    Player.MultiMove.Stop;
    Exit( False );
  end;

  case iMoveResult of
     MoveBlock :
       begin
         if not Level.isProperCoord( iTarget ) then Exit( False );
         iItem := Level.Item[ iTarget ];
         if Assigned( iItem ) and iItem.HasHook( Hook_OnAct ) then
           Exit( HandleCommand( TCommand.Create( COMMAND_ACTION, iTarget ) ) );
         if Option_Blindmode then IO.Msg( 'You bump into a wall.' );
         Exit( False );
       end;
     MoveBeing :
       begin
         if not Level.isProperCoord( iTarget ) then Exit( False );
         iBeing := Level.Being[ iTarget ];
         if iBeing.Flags[ BF_FRIENDLY ]
           then Exit( HandleCommand( TCommand.Create( COMMAND_SWAPPOSITION, iTarget ) ) )
           else Exit( HandleCommand( TCommand.Create( COMMAND_MELEE, iTarget, ModuleOption_MeleeMoveOnKill and (not aAlt) ) ) );
       end;
     MoveDoor  : Exit( HandleCommand( TCommand.Create( COMMAND_ACTION, iTarget ) ) );
     MoveOk    : Exit( HandleCommand( TCommand.Create( COMMAND_MOVE, iTarget ) ) );
  end;
  Exit( False );
end;

function TDRL.HandleFireCommand( aAlt : Boolean; aMouse : Boolean; aAuto : Boolean; aPad : Boolean ) : Boolean;
var iTarget     : TCoord2D;
    iItem       : TItem;
    iFireTitle  : AnsiString;
    iChainFire  : Byte;
    iAltFire    : TAltFire;
    iLimitRange : Boolean;
    iRange      : Byte;
    iCommand    : Byte;
    iEmpty      : Boolean;
begin
  IO.MsgUpdate;
  iLimitRange := False;
  iFireTitle  := '';
  iChainFire  := Player.ChainFire;
  if iChainFire > 0 then aAuto := False;
  Player.ChainFire := 0;

  iItem := Player.Inv.Slot[ efWeapon ];
  if (iItem = nil) or (not iItem.isWeapon) then
  begin
    IO.Msg( 'You have no weapon.' );
    Exit( False );
  end;
  if not aAlt then
  begin
    if (not aMouse) and (not aAuto) and iItem.isMelee then
    begin
      IO.PushLayer( TMeleeDirView.Create );
      Exit( False );
    end;

    if (not iItem.isRanged) then
    begin
      IO.Msg( 'You have no ranged weapon.' );
      Exit( False );
    end;
  end
  else
  begin
    if iItem.AltFire = ALT_NONE then
    begin
      IO.Msg( 'This weapon has no alternate fire mode' );
      Exit( False );
    end;
    if iItem.AltFire in [ ALT_TARGETSCRIPT, ALT_SCRIPT ] then
      aAuto := False;
  end;
  if not iItem.CallHookCheck( Hook_OnFire, [Player,aAlt] ) then Exit( False );

  if aAlt then
  begin
    if iItem.isMelee and ( iItem.AltFire = ALT_THROW ) then
    begin
      if aMouse then
        iTarget  := IO.MTarget
      else if aAuto then
        iTarget := FTargeting.List.Current
      else
      begin
        iRange      := iItem.Range;
        iLimitRange := MF_EXACT in Missiles[ iItem.Missile ].Flags;
        iFireTitle  := 'Choose throw target:';
      end;
    end;
  end;

  if iItem.isRanged then
  begin
    iEmpty := False;
    if not iItem.Flags[ IF_NOAMMO ] then
    begin
           if iItem.Ammo = 0              then begin IO.Msg( 'Your weapon is empty.' ); iEmpty := True; end
      else if iItem.Ammo < iItem.ShotCost then begin IO.Msg( 'You don''t have enough ammo to fire the %s!', [iItem.Name] ); iEmpty := True; end;
    end;

    if iEmpty then
    begin
      if Setting_EmptyConfirm then
        IO.PushLayer( TMoreLayer.Create( False ) );
      Exit( False );
    end;

    iRange := iItem.Range;
    if iRange = 0 then iRange := Player.Vision;

    iLimitRange := (not iItem.Flags[ IF_SHOTGUN ]) and (MF_EXACT in Missiles[ iItem.Missile ].Flags);
    if aMouse or aAuto then
    begin
      if aMouse
        then iTarget := IO.MTarget
        else iTarget := FTargeting.List.Current;

      if iLimitRange then
        if Distance( Player.Position, iTarget ) > iRange then
          Exit( Player.Fail( 'Out of range!', [] ) );
    end
    else
    begin
      iAltFire    := ALT_NONE;
      if aAlt then iAltFire := iItem.AltFire;
      iFireTitle := 'Choose fire target:';
      case iAltFire of
        ALT_SCRIPT       : begin iFireTitle := ''; iTarget := Player.Position; end;
        ALT_TARGETSCRIPT : iFireTitle := 'Fire target ({L'+LuaSystem.Get([ 'items', iItem.ID, 'altfirename' ],'')+'}):';
        ALT_AIMED        : iFireTitle := 'Fire target ({Laimed}):';
        ALT_SINGLE       : iFireTitle := 'Fire target ({Lsingle}):';
      end;
      if iAltFire = ALT_CHAIN then
      begin
        case iChainFire of
          0      : iFireTitle := 'Chain fire ({Ginitial}):';
          1      : iFireTitle := 'Chain fire ({Ywarming}):';
          2..255 : iFireTitle := 'Chain fire ({Rfull}):';
        end;
      end
    end
  end;

  iCommand := COMMAND_FIRE;
  if aAlt then iCommand := COMMAND_ALTFIRE;

  if iFireTitle <> '' then
  begin
    if iRange = 0 then iRange := Player.Vision;
    if iRange <> Player.Vision then
      FTargeting.Update( iRange );
    IO.PushLayer( TTargetModeView.Create( iItem, iCommand, iFireTitle, iRange+1, iLimitRange, FTargeting.List, iChainFire ) );
    Exit( False );
  end;

  if aAuto then
  begin
    if FTargeting.List.Current = Player.Position then
    begin
      IO.Msg( 'No valid target.' );
      ResetAutoTarget;
      Exit( False );
    end;
    FTargeting.OnTarget( iTarget, False );
  end;

  Exit( HandleCommand( TCommand.Create( iCommand, iTarget, iItem ) ) )
end;

function TDRL.HandleUsableCommand( aItem : TItem ) : Boolean;
var iRange      : Integer;
    iLimitRange : Boolean;
begin
  iRange := aItem.Range;
  if iRange = 0 then iRange := Player.Vision;
  if iRange <> Player.Vision then
    FTargeting.Update( iRange );
  iLimitRange := MF_EXACT in Missiles[ aItem.Missile ].Flags;
  IO.PushLayer( TTargetModeView.Create( aItem, COMMAND_USE, 'Choose target:', iRange+1, iLimitRange, FTargeting.List, 0 ) );
  Exit( False );
end;

function TDRL.HandleUnloadCommand( aItem : TItem ) : Boolean;
var iID         : AnsiString;
    iItemTypes  : TItemTypeSet;
begin
  iItemTypes := [ ItemType_Ranged, ItemType_AmmoPack ];
  if Player.Flags[ BF_SCAVENGER ] then
    iItemTypes := [ ItemType_Ranged, ItemType_AmmoPack, ItemType_Melee, ItemType_Armor, ItemType_Boots ];
  if ( aItem = nil ) then
    aItem := Level.Item[ Player.Position ];
  if ( aItem = nil ) or ( not (aItem.IType in iItemTypes) ) then
  begin
    FPlayerView := IO.PushLayer( TPlayerView.CreateCommand( COMMAND_UNLOAD, Player.Flags[ BF_SCAVENGER ] ) );
    Exit( True );
  end;

  if aItem.isAmmoPack then
  begin
    IO.PushLayer( TUnloadConfirmView.Create( aItem ) );
    Exit( True );
  end;

  if (not aItem.isAmmoPack) and Player.Flags[ BF_SCAVENGER ] and
    ((not aItem.isRanged) or (aItem.Ammo = 0) or aItem.Flags[ IF_NOUNLOAD ] or aItem.Flags[ IF_RECHARGE ] or aItem.Flags[ IF_NOAMMO ]) and
    (aItem.Flags[ IF_EXOTIC ] or aItem.Flags[ IF_UNIQUE ] or aItem.Flags[ IF_ASSEMBLED ] or aItem.Flags[ IF_MODIFIED ]) then
  begin
    iID := LuaSystem.ProtectedCall( [ CoreModuleID,'GetDisassembleId'], [ aItem ] );
    if iID <> '' then
    begin
      IO.PushLayer( TUnloadConfirmView.Create(aItem,iID) );
      Exit;
    end;
  end;

  if not( aItem.IType in [ ItemType_Ranged, ItemType_AmmoPack ] )  then
     Exit( False );

  Exit( HandleCommand( TCommand.Create( COMMAND_UNLOAD, aItem, iID ) ) );
end;

function TDRL.HandleSwapWeaponCommand : Boolean;
begin
  if ( Player.Inv.Slot[ efWeapon ] <> nil )  and ( Player.Inv.Slot[ efWeapon ].Flags[ IF_CURSED ] ) then begin IO.Msg('You can''t!'); Exit( False ); end;
  if ( Player.Inv.Slot[ efWeapon2 ] <> nil ) and ( Player.Inv.Slot[ efWeapon2 ].isAmmoPack )        then begin IO.Msg('Nothing to swap!'); Exit( False ); end;
  Exit( HandleCommand( TCommand.Create( COMMAND_SWAPWEAPON ) ) );
end;

function TDRL.HandlePickupCommand( aAlt : Boolean ) : Boolean;
var iItem : TItem;
begin
  if not aAlt then Exit( HandleCommand( TCommand.Create( COMMAND_PICKUP ) ) );
  iItem := Level.Item[ Player.Position ];
  if ( iItem = nil ) or (not (iItem.isPickupable or iItem.isUsable or iItem.isWearable) ) then
  begin
    IO.Msg( 'There''s nothing to use on the ground!' );
    Exit( False );
  end;
  if iItem.IType = ITEMTYPE_URANGED
    then Exit( DRL.HandleUsableCommand( iItem ) );
  Exit( HandleCommand( TCommand.Create( COMMAND_USE, iItem ) ) );
end;

function TDRL.HandleCommand( aCommand : TCommand ) : Boolean;
begin
  if not ( aCommand.Command in [ COMMAND_FIRE, COMMAND_ALTFIRE, COMMAND_RELOAD ] ) then
    FTargeting.ClearPosition;

  if aCommand.Command = COMMAND_NONE then
    Exit( False );
  IO.MsgUpDate;
try
  Player.HandleCommand( aCommand );
except
  on e : Exception do
  begin
    if CRASHMODE then raise;
    ErrorLogOpen('CRITICAL','Player action exception!');
    ErrorLogWriteln('Error message : '+e.Message);
    ErrorLogClose;
    IO.ErrorReport(e.Message);
    CRASHMODE := True;
  end;
end;
  if State <> DSPlaying then Exit( False );
  Player.PostAction;
  if State <> DSPlaying then Exit( False );
  IO.Focus( Player.Position );
  FDamagedLastTurn := False;
  while (Player.SCount < 5000) and (State = DSPlaying) do
  begin
    FLevel.CalculateVision( Player.Position );
    FLevel.Tick;
    if Player.MultiMove.Active then
      IO.WaitForAnimation;
    if not Player.PlayerTick then Exit( True );
  end;
  PreAction;
  Exit( True );
end;

procedure TDRL.ResetAutoTarget;
begin
  FTargeting.Clear;
  FTargeting.Update( Player.Vision );
  IO.SetAutoTarget( FTargeting.List.Current );
end;

function TDRL.HandleMouseEvent( aEvent : TIOEvent ) : Boolean;
var iAlt     : Boolean;
    iButton  : TIOMouseButton;
begin
  if not Setting_Mouse then Exit( False );
  IO.MTarget := SpriteMap.DevicePointToCoord( aEvent.Mouse.Pos );
  if DRL.Level.isProperCoord( IO.MTarget ) then
  begin
    iButton  := aEvent.Mouse.Button;
    iAlt     := False;
    if iButton in [ VMB_BUTTON_LEFT, VMB_BUTTON_RIGHT ] then
      iAlt := VKMOD_ALT in IO.Driver.GetModKeyState;

    if iButton = VMB_BUTTON_MIDDLE then
      if IO.MTarget = Player.Position
        then Exit( HandleSwapWeaponCommand )
        else begin
//          FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_EQUIPMENT ) );
//          Exit( True );
        end;

    if iButton = VMB_BUTTON_LEFT then
    begin
      if IO.MTarget = Player.Position then
      begin
        if iAlt then
        begin
          FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_INVENTORY ) );
          Exit( True );
        end
        else
        if Level.cellFlagSet( Player.Position, CF_STAIRS ) then
          Exit( HandleCommand( TCommand.Create( COMMAND_ENTER ) ) )
        else
          if Level.Item[ Player.Position ] <> nil then
            if Level.Item[ Player.Position ].isLever then
              Exit( HandleCommand( TCommand.Create( COMMAND_USE, Level.Item[ Player.Position ] ) ) )
            else
              Exit( HandleCommand( TCommand.Create( COMMAND_PICKUP ) ) )
          else
            begin
              FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_INVENTORY ) );
              Exit( True );
            end
      end
      else
      if Distance( Player.Position, IO.MTarget ) = 1
        then Exit( HandleMoveCommand( DirectionToInput( NewDirection( Player.Position, IO.MTarget ) ), IO.ShiftHeld ) )
        else if Level.isExplored( IO.MTarget ) then
        begin
          if not Player.RunPath( IO.MTarget ) then
          begin
            IO.Msg('Can''t get there!');
            Exit;
          end;
        end
        else
        begin
          IO.Msg('You don''t know how to get there!');
          Exit;
        end;
    end;

    if iButton = VMB_BUTTON_RIGHT then
    begin
      if (IO.MTarget = Player.Position) or
        ((Player.Inv.Slot[ efWeapon ] <> nil) and (Player.Inv.Slot[ efWeapon ].isRanged) and (not (Player.Inv.Slot[efWeapon].GetFlag(IF_NOAMMO))) and (Player.Inv.Slot[ efWeapon ].Ammo = 0))  then
      begin
        if iAlt
          then Exit( HandleCommand( TCommand.Create( COMMAND_ALTRELOAD ) ) )
          else Exit( HandleCommand( TCommand.Create( COMMAND_RELOAD ) ) );
      end
      else if (Player.Inv.Slot[ efWeapon ] <> nil) and (Player.Inv.Slot[ efWeapon ].isRanged) then
      begin
        if iAlt
          then Exit( HandleFireCommand( True, True, False, False ) )
          else Exit( HandleFireCommand( False, True, False, False ) );
      end
      else Exit( HandleCommand( TCommand.Create( COMMAND_MELEE,
        Player.Position + NewDirectionSmooth( Player.Position, IO.MTarget )
      ) ) );
    end;

    if iButton in [ VMB_WHEEL_UP, VMB_WHEEL_DOWN ] then
      IO.PushLayer( TScrollSwapLayer.Create );
  end;
  Exit( False );
end;

function TDRL.HandlePadMovement( aEvent : TIOEvent ) : Boolean;
var iTarget : TCoord2D;
    iCell   : Integer;
begin
  if ( aEvent.EType <> VEVENT_PADDOWN ) then
  begin
    FPadMoveActive := False;
    Exit( False );
  end;

  Assert( aEvent.Pad.Button = VPAD_BUTTON_A );

  if ( aEvent.EType = VEVENT_PADUP ) then
  begin
    FPadMoveActive := False;
    Exit( False );
  end;

  if IO.GetPadRTrigger then
  begin // Move target mode
    if IO.GetPadLDir.NotZero then
      Exit( MoveTargetEvent( FTargeting.List.Current + IO.GetPadLDir ) );
    if (FTargeting.List.Current <> Player.Position) and (Level.Being[FTargeting.List.Current] <> nil) then
      IO.FullLook( Level.Being[FTargeting.List.Current] );
    Exit( False );
  end;

  if aEvent.Pad.Pressed then // normal mode
  begin
    if IO.GetPadLDir.NotZero
      then begin FPadMoved := True; Result := HandleMoveCommand( DirectionToInput( NewDirection( IO.GetPadLDir ) ), IO.GetPadLTrigger ); end
      else Result := HandleCommand( TCommand.Create( COMMAND_WAIT ) );
    FPadMoveNext := IO.Time + PAD_REPEAT_START;
  end
  else // repeat mode
  begin
    if IO.GetPadLDir.NotZero then
    begin
      iTarget := Player.Position + IO.GetPadLDir;
      if Level.isProperCoord( iTarget ) then
      begin
        iCell := Level.getCell( iTarget );
        if not ( ( CellHook_OnHazardQuery in Cells[ iCell ].Hooks ) and  Level.CallHook( CellHook_OnHazardQuery, iCell, Player ) ) then
          Result := HandleMoveCommand( DirectionToInput( NewDirection( IO.GetPadLDir ) ), IO.GetPadLTrigger );
      end;
    end;
    FPadMoveNext := IO.Time + PAD_REPEAT;
  end;
  FPadMoveActive := ( State = DSPlaying ) and ( Player.EnemiesInVision = 0 ) and ( aEvent.Pad.Pressed or (not FDamagedLastTurn) );
  Exit( Result );
end;

function TDRL.HandlePadEvent( aEvent : TIOEvent ) : Boolean;
var iItem : TItem;
begin
  if ( aEvent.EType = VEVENT_PADDEVICE ) then
  begin
    FPadMoveActive := False;
    Exit( False );
  end;

  if ( aEvent.Pad.Button = VPAD_BUTTON_A ) then
    Exit( HandlePadMovement( aEvent ) );

  if aEvent.EType <> VEVENT_PADDOWN then
    Exit( False );

  case aEvent.Pad.Button of
    VPAD_BUTTON_B : if IO.GetPadLDir.NotZero
                      then Exit( HandleActionCommand( Player.Position + IO.GetPadLDir, 0 ) )
                      else begin
                        if Level.cellFlagSet( Player.Position, CF_STAIRS ) then
                          Exit( HandleCommand( TCommand.Create( COMMAND_ENTER ) ) );
                        iItem := Level.Item[ Player.Position ];
                        if ( iItem <> nil ) and ( iItem.isLever ) then
                          Exit( HandleCommand( TCommand.Create( COMMAND_USE, iItem ) ) );
                        Exit( HandlePickupCommand( IO.GetPadRTrigger ) )
                      end;
    VPAD_BUTTON_X : Exit( HandleFireCommand( IO.GetPadRTrigger, False, True, True ) );
    VPAD_BUTTON_Y : Exit( HandleCommand( TCommand.Create( Iif( IO.GetPadRTrigger, COMMAND_ALTRELOAD, COMMAND_RELOAD ) ) ) );
    VPAD_BUTTON_BACK          : begin ResetAutoTarget; IO.PushLayer( TInGameMenuView.Create ); Exit; end;
    VPAD_BUTTON_GUIDE:;
    VPAD_BUTTON_START         : begin
      if IO.GetPadRTrigger
        then FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_EQUIPMENT ) )
        else FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_INVENTORY ) );
      Exit( False );
    end;
    VPAD_BUTTON_LEFTSTICK  : Exit( HandleCommand( TCommand.Create( COMMAND_ACTIVE ) ) );
    VPAD_BUTTON_RIGHTSTICK : if IO.GetPadRTrigger
                                then Exit( HandleUnloadCommand( nil ) )
                                else Exit( HandleSwapWeaponCommand );
    VPAD_BUTTON_LEFTSHOULDER  : begin IO.SetAutoTarget( FTargeting.List.Prev ); Exit( False ); end;
    VPAD_BUTTON_RIGHTSHOULDER : begin IO.SetAutoTarget( FTargeting.List.Next ); Exit( False ); end;
    VPAD_BUTTON_DPAD_UP    : if IO.GetPadLTrigger
      then Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '1' ) ) )
      else if FPadMoved then Exit( MoveTargetEvent( FTargeting.List.Current + NewCoord2D( 0,-1 ) ) );
    VPAD_BUTTON_DPAD_DOWN  : if IO.GetPadLTrigger
      then Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '4' ) ) )
      else if FPadMoved then Exit( MoveTargetEvent( FTargeting.List.Current + NewCoord2D( 0, 1 ) ) );
    VPAD_BUTTON_DPAD_LEFT  : if IO.GetPadLTrigger
      then Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '2' ) ) )
      else if FPadMoved then Exit( MoveTargetEvent( FTargeting.List.Current + NewCoord2D(-1, 0 ) ) );
    VPAD_BUTTON_DPAD_RIGHT : if IO.GetPadLTrigger
      then Exit( HandleCommand( TCommand.Create( COMMAND_QUICKKEY, '3' ) ) )
      else if FPadMoved then Exit( MoveTargetEvent( FTargeting.List.Current + NewCoord2D( 1, 0 ) ) );
  end;
  Exit( False );
end;

function TDRL.HandleKeyEvent( aEvent : TIOEvent ) : Boolean;
var iInput : TInputKey;
begin
  if aEvent.Key.Code = 0 then Exit( False );
  IO.KeyCode := IOKeyEventToIOKeyCode( aEvent.Key );
  iInput     := TInputKey( Config.Commands[ IO.KeyCode ] );

  // Handle key-repeat
  if aEvent.Key.Repeated then
    if ( not ( iInput in [ INPUT_WAIT ] + INPUT_MOVE ) ) or
       ( IO.Time - FLastInputTime < Player.VisualTime( Player.getMoveCost, AnimationSpeedMove - 2 ) ) or (Player.EnemiesInVision > 0) then
      Exit( False );
  FLastInputTime := IO.Time;

  if ( Byte(iInput) = 255 ) then // GodMode Keys
  begin
    Config.RunKey( IO.KeyCode );
    Exit( HandleCommand( TCommand.Create( COMMAND_SKIP ) ) );
  end;
  if iInput <> INPUT_NONE then
  begin
    // Handle commands that should be handled by the UI

    if iInput in INPUT_TARGETMOVE then
    begin
      MoveTargetEvent( FTargeting.List.Current + InputDirection( iInput ) );
      Exit;
    end;

    case iInput of
//      INPUT_ESCAPE     : begin if GodMode then DRL.SetState( DSQuit ); Exit; end;
      INPUT_TARGETNEXT : begin IO.SetAutoTarget( FTargeting.List.Next ); Exit; end;
      INPUT_ESCAPE     : begin ResetAutoTarget; IO.PushLayer( TInGameMenuView.Create ); Exit; end;
      INPUT_QUIT       : begin IO.PushLayer( TAbandonView.Create ); Exit; end;
      INPUT_HELP       : begin IO.PushLayer( THelpView.Create ); Exit; end;
      INPUT_LOOKMODE   : begin IO.PushLayer( TLookModeView.Create ); Exit; end;
      INPUT_PLAYERINFO : begin FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_CHARACTER ) ); Exit; end;
      INPUT_INVENTORY  : begin FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_INVENTORY ) ); Exit; end;
      INPUT_EQUIPMENT  : begin FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_EQUIPMENT ) ); Exit; end;
      INPUT_ASSEMBLIES : begin IO.PushLayer( TAssemblyView.Create ); Exit; end;
      INPUT_MORE       : if Level.Being[FTargeting.List.Current] <> nil then begin IO.FullLook( Level.Being[FTargeting.List.Current] ); Exit; end;
      INPUT_LEGACYUSE  : begin FPlayerView := IO.PushLayer( TPlayerView.CreateCommand( COMMAND_USE ) ); Exit; end;
      INPUT_LEGACYDROP : begin FPlayerView := IO.PushLayer( TPlayerView.CreateCommand( COMMAND_DROP ) ); Exit; end;
      INPUT_UNLOAD     : begin HandleUnloadCommand( nil ); Exit; end;

      INPUT_MESSAGES   : begin IO.PushLayer( TMessagesView.Create( IO.MsgGetRecent ) ); Exit; end;

      INPUT_HARDQUIT   : begin
        Option_MenuReturn := False;
        DRL.SetState( DSQuit );
        Player.Score := -100000;
        Exit;
      end;

      INPUT_LEGACYSAVE: begin DRL.SetState( DSSaving ); Exit; end;
      INPUT_TRAITS    : begin FPlayerView := IO.PushLayer( TPlayerView.Create( PLAYERVIEW_TRAITS ) ); Exit; end;
      INPUT_RUN       : begin
        Player.MultiMove.Stop;
        if Player.EnemiesInVision > 0
          then IO.Msg( 'Can''t multi-move, there are enemies present.',[] )
          else IO.PushLayer( TRunModeView.create );
        Exit;
      end;

      INPUT_EXAMINENPC   : begin Player.ExamineNPC; Exit; end;
      INPUT_EXAMINEITEM  : begin Player.ExamineItem; Exit; end;
      INPUT_TOGGLEGRID   : begin if GraphicsVersion then SpriteMap.ToggleGrid; Exit; end;
      INPUT_SOUNDTOGGLE  : begin SoundOff := not SoundOff; Exit; end;
      INPUT_MUSICTOGGLE  : begin
                               MusicOff := not MusicOff;
                               if MusicOff then IO.Audio.PlayMusic('')
                                           else IO.Audio.PlayMusic(Iif( FLevel.Music_ID <> '', FLevel.Music_ID, FLevel.ID ));
                               Exit;
                             end;
    end;
    Exit( Action( iInput ) );
  end
    else
    begin
      IO.MsgUpDate;
      IO.Msg('Unknown command. Press {^{$input_menu}} for menu and help.' );
    end;

  Exit( False );
end;

function TDRL.MoveTargetEvent( aCoord : TCoord2D ) : Boolean;
begin
  if FLevel.isProperCoord( aCoord ) then
  begin
    Player.TargetPos := aCoord;
    FTargeting.OnTarget( aCoord, True );
    FTargeting.Update( Player.Vision );
    IO.SetAutoTarget( FTargeting.List.Current );
    Exit( True );
  end;
  Exit( False );
end;


procedure TDRL.Run;
var iRank       : THOFRank;
    iResult     : TMenuResult;
    iEvent      : TIOEvent;
    iInput      : TInputKey;
    iFullLoad   : Boolean;
    iChalAbbr   : Ansistring;
    iScript     : Ansistring;
    iReport     : TPagedReport;
    iEnterNuke  : Boolean;
begin
  iResult    := TMenuResult.Create;
  DRL.Load;

  IO.PushLayer( TMainMenuView.Create );
  IO.WaitForLayer( True );
  if FState <> DSQuit then
repeat
  if not FDataLoaded then
    DRL.Load;
  IO.LoadStop;

  StatusEffect   := StatusNormal;
  FDifficulty    := 2;
  FArchAngel     := False;
  FChallenge     := '';
  FSChallenge    := '';
  FGameWon       := False;
  NoPlayerRecord := False;
  NoScoreRecord  := False;

  IO.ClearAllMessages;

  IO.Audio.PlayMusic('start');
  SetState( DSMenu );
  iResult.Reset; // TODO : could reuse for same game!

  IO.PushLayer( TMainMenuView.Create( MAINMENU_MENU, iResult ) );
  IO.WaitForLayer( True );
  Apply( iResult );
  if State = DSQuit then Break;

  if iResult.Loaded then
  begin
    if FCrashSave
      then SetState( DSCrashLoading )
      else SetState( DSLoading );
  end
  else
  begin
    CreatePlayer( iResult );
  end;

  LuaSystem.SetValue('level', Level );

  if (not (State in [DSLoading, DSCrashLoading])) then
    CallHookCheck( Hook_OnIntro, [Setting_NoIntro] );

  if (not(State in [DSLoading, DSCrashLoading])) then
  begin
    CallHook( Hook_OnCreateEpisode, [] );
  end;
  CallHook( Hook_OnLoaded, [(State in [DSLoading, DSCrashLoading])] );

  GameRealTime := MSecNow();
  try
  repeat
    iEnterNuke := False;
    if State <> DSLoading then
    begin
      iEnterNuke := False;
      if (Player.NukeActivated > 0) then
      begin
        Player.Score := Player.Score + 1000;
        Player.Statistics.Increase('levels_nuked');
        Player.NukeActivated := 0;
        iEnterNuke := True;
      end;

      Player.Statistics.Update;
      Player.NextLevelIndex;

      with LuaSystem.GetTable(['player','episode',Player.Level_Index]) do
      try
        FLevel.Init(getInteger('style',0),
                   getString('name',''),
                   Player.Level_Index,
                   getInteger('danger',0));
        if IsString('sname') then FLevel.SName := getString('sname');
        if IsString('abbr')  then FLevel.Abbr  := getString('abbr');
        iScript := getString('script','');
      finally
        Free;
      end;

      if iScript <> ''
        then
          FLevel.ScriptLevel(iScript)
        else
        begin
          IO.Msg('You enter %s.',[ FLevel.Name ] );
          CallHookCheck(Hook_OnGenerate,[]);
          FLevel.AfterGeneration( True );
        end;
    end;
    iFullLoad := State = DSLoading;

    FLevel.CalculateVision( Player.Position );
    SetState( DSPlaying );
    IO.BloodSlideDown(20);
    IO.FadeIn( True );
    IO.Audio.PlayMusic( Iif( FLevel.Music_ID <> '', FLevel.Music_ID, FLevel.ID ) );

    if iEnterNuke then
    begin
      IO.Msg('You hear a gigantic explosion above!');
      IO.addScreenShakeAnimation( 1000, 100, 7 );
      IO.addRumbleAnimation( 0, $8000, $4000, 300 );
    end;

    if not iFullLoad then
    begin
      FLevel.PreEnter;
      FLevel.Tick;
    end;
    FTargeting.Clear;
    PreAction;

    while ( State = DSPlaying ) do
    begin
      if Player.ChainFire > 0 then
      begin
        Action( INPUT_ALTFIRE );
        Continue;
      end;

      if ( Player.MultiMove.Active ) then
      begin
        iInput := Player.GetMultiMoveInput;
        if iInput <> INPUT_NONE then
          Action( iInput );
        Continue;
      end;

      while ( not IO.Driver.EventPending ) and ( State = DSPlaying ) do
      begin
        if FPadMoveActive and ( IO.Time >= FPadMoveNext ) then
        begin
          iEvent.EType       := VEVENT_PADDOWN;
          iEvent.Pad.Button  := VPAD_BUTTON_A;
          iEvent.Pad.Pressed := False; // To mark repeat!
          HandlePadEvent( iEvent );
          Continue;
        end;
        IO.FullUpdate;
        IO.Driver.Sleep(10);
      end;
      if State <> DSPlaying then Break;

      if not IO.Driver.PollEvent( iEvent ) then continue;
      if IO.OnEvent( iEvent ) or IO.Root.OnEvent( iEvent ) then Continue;

      if (iEvent.EType = VEVENT_SYSTEM) and (iEvent.System.Code = VIO_SYSEVENT_QUIT) then
      begin
        if Option_LockClose
           then Action( INPUT_QUIT )
           else Action( INPUT_HARDQUIT );
        Continue;
      end;

      if ( State <> DSPlaying ) then Break;

      if iEvent.EType = VEVENT_MOUSEDOWN then HandleMouseEvent( iEvent );
      if iEvent.EType = VEVENT_KEYDOWN   then HandleKeyEvent( iEvent );
      if iEvent.EType in [ VEVENT_PADDOWN, VEVENT_PADUP, VEVENT_PADDEVICE] then
        HandlePadEvent( iEvent );
    end;

    if State = DSNextLevel then
    begin
      FLevel.Leave;
    end;

    if State <> DSSaving then
    begin
      Player.Score := Player.Score + 1000;
      if FGameWon and (State <> DSNextLevel) then Player.WriteMemorial;
      FLevel.Clear;
    end;
    IO.SetHint('');
  until (State <> DSNextLevel);
  except on e : Exception do
  begin
    EmitCrashInfo( e.Message, True );
    EXCEPTEMMITED := True;
    if Option_SaveOnCrash and ((Player.Statistics['crash_count'] = 0) or{thelaptop: Vengeance is MINE} (FDifficulty < DIFF_NIGHTMARE)) then
    begin
      if Player.Level_Index <> 1 then Player.NextLevelIndex;
      Player.Statistics.Increase('crash_count');
      WriteSaveFile( True );
    end;
    raise;
  end;
  end;

  IO.FadeReset;

  if State = DSSaving then
    WriteSaveFile( False );

  if State = DSFinished then
  begin
    if FGameWon then
    begin
      IO.Audio.PlayMusic('victory');
      CallHookCheck(Hook_OnWinGame,[]);
    end
    else IO.Audio.PlayMusic('bunny');
  end;

  if State = DSFinished then
  begin
    if HOF.RankCheck( iRank ) then
    begin
      IO.PushLayer( TRankUpView.Create( iRank ) );
      IO.WaitForLayer( True );
    end;
    if Player.Score >= -1000 then
    begin
      iReport := TPagedReport.Create('Post mortem', False );
      iReport.Add( MortemData, 'mortem.txt' );
      MortemData := nil; // handled by iReport
      IO.PushLayer( TPagedView.Create( iReport ) );
      IO.WaitForLayer( True );
    end;
    iChalAbbr := '';
    if FChallenge <> '' then iChalAbbr := LuaSystem.Get(['chal',FChallenge,'abbr']);
    IO.PushLayer( TPagedView.Create( HOF.GetPagedScoreReport, iChalAbbr ) );
    IO.WaitForLayer( True );
  end;
  CallHook(Hook_OnUnLoad,[]);

  IO.BloodSlideDown(20);
  FreeAndNil(Player);

until not Option_MenuReturn;
  FreeAndNil( iResult );
end;

procedure TDRL.CreatePlayer ( aResult : TMenuResult ) ;
var iTraitID : AnsiString;
    iTrait   : Byte;
begin
  FreeAndNil( UIDs );
  UIDs := TUIDStore.Create;
  Player := TPlayer.Create;
  FLevel.Place( Player, NewCoord2D(4,4) );
  Player.Klass := aResult.Klass;

  if Option_AlwaysName <> '' then
    Player.Name := Option_AlwaysName
  else
    if (Setting_AlwaysRandomName) or (aResult.Name = '')
      then Player.Name := LuaSystem.ProtectedCall([CoreModuleID,'GetRandomName'],[])
      else Player.Name := aResult.Name;

  LuaSystem.ProtectedCall(['klasses',Player.Klass,'OnPick'], [ Player ] );
  iTraitID := LuaSystem.Get(['klasses',Player.Klass,'core_trait'],'' );
  if iTraitID <> '' then
  begin
    iTrait := LuaSystem.Get(['traits',iTraitID,'nid']);
    Player.Traits.Upgrade( 0, iTrait );
  end;
  CallHook(Hook_OnCreatePlayer,[]);
  Player.Traits.Upgrade( Player.Klass, aResult.Trait );
  Player.UpdateVisual;
end;

function TDRL.LoadSaveFile: Boolean;
var iStream    : TStream;
    iRecreate  : Boolean;
    iModule    : Ansistring;
begin
  SaveVersionModule := '';
  SaveModString     := '';
  iRecreate := False;
  try
    try
      iStream := TGZFileStream.Create( ModuleUserPath + 'save',gzOpenRead );
      //      Stream := TDebugStream.Create( Stream );
      iModule           := iStream.ReadAnsiString;
      if (iModule <> CoreModuleID) then Exit( False );
      SaveVersionModule := iStream.ReadAnsiString;
      SaveModString     := iStream.ReadAnsiString;
      if ( SaveVersionModule <> VersionModuleSave ) or ( SaveModString <> DRL.Modules.ModString ) then
      begin
        Exit( False );
      end;
      SaveVersionModule := '';
      SaveModString     := '';

      FreeAndNil( UIDs );
      UIDs             := TUIDStore.CreateFromStream( iStream );
      FGameWon         := iStream.ReadByte <> 0;
      FDifficulty      := iStream.ReadByte;
      FChallenge       := iStream.ReadAnsiString;
      FArchAngel       := iStream.ReadByte <> 0;
      FSChallenge      := iStream.ReadAnsiString;

      Player := TPlayer.CreateFromStream( iStream );
      FCrashSave := iStream.ReadByte <> 0;

      if not FCrashSave then
      begin
        FreeAndNil( FLevel );
        iRecreate := True;
        FLevel := TLevel.CreateFromStream( iStream );
        FLevel.Place( Player, Player.Position );
        LuaSystem.SetValue('level', FLevel );
        LuaSystem.ProtectedCall( [ 'generator', 'on_load' ], [] );
      end;
    finally
      iStream.Destroy;
    end;
    DeleteFile( ModuleUserPath + 'save' );

    IO.Msg('Game loaded.');

    if Player.Dead then
      raise EException.Create('Player in save file is dead anyway.');
    LoadSaveFile := True;
    FPadMoved    := True;
  except
    on e : Exception do
    begin
      Log('Save file corrupted! Error while loading : '+ e.message );
      DeleteFile( ModuleUserPath + 'save' );
      LoadSaveFile := False;
      if iRecreate then
      begin
        FreeAndNil( FLevel );
        FLevel := TLevel.Create;
      end;
    end;
  end;
  if not GraphicsVersion then
    (IO as TDRLTextIO).SetTextMap( FLevel );
end;

// TODO: cleanup and remove
function CopyFileSimple( const aSrc, aDest: Ansistring ): Boolean;
var aInS, aOutS: TFileStream;
begin
  Result := False;
  try
    aInS  := TFileStream.Create(aSrc,  fmOpenRead or fmShareDenyWrite);
    try
      aOutS := TFileStream.Create(aDest, fmCreate);
      try
        aOutS.CopyFrom(aInS, 0);
        Result := True;
      finally
        aOutS.Free;
      end;
    finally
      aInS.Free;
    end;
  except
  end;
end;


procedure TDRL.WriteSaveFile( aCrash : Boolean );
var Stream : TStream;
begin
  LuaSystem.ProtectedCall( [ 'generator', 'on_save' ], [] );

  Player.Statistics.OnSaveFile;

  Stream := TGZFileStream.Create( ModuleUserPath + 'save',gzOpenWrite );
  //      Stream := TDebugStream.Create( Stream );

  Stream.WriteAnsiString( CoreModuleID );
  Stream.WriteAnsiString( VersionModuleSave );
  Stream.WriteAnsiString( FModules.ModString );
  UIDs.WriteToStream( Stream );
  if FGameWon   then Stream.WriteByte( 1 ) else Stream.WriteByte( 0 );
  Stream.WriteByte( FDifficulty );
  Stream.WriteAnsiString( FChallenge );
  if FArchAngel then Stream.WriteByte( 1 ) else Stream.WriteByte( 0 );
  Stream.WriteAnsiString( FSChallenge );

  Player.WriteToStream(Stream);
  Player.Detach;
  if aCrash
    then Stream.WriteByte( 1 )
    else Stream.WriteByte( 0 );

  if not aCrash then
    FLevel.WriteToStream( Stream );

  FreeAndNil( Stream );
  FLevel.Clear;
  if ForceShop then
    CopyFileSimple( ModuleUserPath + 'save', ModuleUserPath + 'savedemo' );
end;

function TDRL.SaveExists : Boolean;
begin
  Exit( FileExists( ModuleUserPath + 'save' ) );
end;

destructor TDRL.Destroy;
begin
  UnLoad;
  FreeAndNil( ModErrors );
  FreeAndNil( FModules );
  FreeAndNil( Config );
  FreeAndNil( FTargeting );
  FreeAndNil( IO );
  FreeAndNil( UIDs );
  Log('DRL destroyed.');
  inherited Destroy;
end;

end.
