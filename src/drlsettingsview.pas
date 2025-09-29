{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlsettingsview;
interface
uses vio, viotypes, vioevent, vconfiguration, drlio, dfdata;

type TSettingsViewState = (
  SETTINGSVIEW_GENERAL,
  SETTINGSVIEW_DISPLAY,
  SETTINGSVIEW_AUDIO,
  SETTINGSVIEW_GAMEPLAY,
  SETTINGSVIEW_INPUT,
  SETTINGSVIEW_KEYMOVEMENT,
  SETTINGSVIEW_KEYACTION,
  SETTINGSVIEW_KEYUI,
  SETTINGSVIEW_KEYMULTIMOVE,
  SETTINGSVIEW_KEYHELPER,
  SETTINGSVIEW_KEYLEGACY,
  SETTINGSVIEW_DONE
);

const SETTINGSVIEW_KEYS : set of TSettingsViewState = [
  SETTINGSVIEW_KEYMOVEMENT,
  SETTINGSVIEW_KEYACTION,
  SETTINGSVIEW_KEYUI,
  SETTINGSVIEW_KEYMULTIMOVE,
  SETTINGSVIEW_KEYHELPER,
  SETTINGSVIEW_KEYLEGACY
];

type TSettingsView = class( TIOLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
  function HandleEvent( const aEvent : TIOEvent ) : Boolean; override;
  destructor Destroy; override;
protected
  procedure Reconfigure;
  procedure Reset( aGroup : TConfigurationGroup );
  function KeyCapture( aValue : PInteger; aSelected : Boolean ) : Boolean;
protected
  FState       : TSettingsViewState;
  FSize        : TIOPoint;
  FWSize       : TIOPoint;
  FCapture     : Boolean;
  FKey         : Word;
  FResInput    : Boolean;
  FResolutions : array of Ansistring;
  FModInput    : Boolean;
  FModValue    : Integer;
  FModules     : array of Ansistring;
  FModCurrent  : Ansistring;
  FWarning     : Ansistring;
  FRestart     : Ansistring;
end;

implementation

uses math, sysutils, vutil, vdebug, vtig, vtigio, vsound,
     drlconfiguration, drlbase;

const CStates : array[ TSettingsViewState ] of record Title, ID : Ansistring; end = (
   ( Title : 'Settings'; ID : 'general' ),
   ( Title : 'Settings (Display)'; ID : 'display' ),
   ( Title : 'Settings (Audio)'; ID : 'audio' ),
   ( Title : 'Settings (Gameplay)'; ID : 'gameplay' ),
   ( Title : 'Settings (Input)'; ID : 'input' ),
   ( Title : 'Settings (Keybindings - Movement)'; ID : 'keybindings_movement' ),
   ( Title : 'Settings (Keybindings - Actions)'; ID : 'keybindings_actions' ),
   ( Title : 'Settings (Keybindings - UI)'; ID : 'keybindings_ui' ),
   ( Title : 'Settings (Keybindings - Multi-move)'; ID : 'keybindings_running' ),
   ( Title : 'Settings (Keybindings - Helper)'; ID : 'keybindings_helper' ),
   ( Title : 'Settings (Keybindings - Legacy)'; ID : 'keybindings_legacy' ),
   ( Title : ''; ID : '' )
);

const CSub : array[ 1..10 ] of record State : TSettingsViewState; Select, Desc : Ansistring; end = (
  ( State : SETTINGSVIEW_DISPLAY;     Select : 'Display';                  Desc : 'Configure video and display options.' ),
  ( State : SETTINGSVIEW_AUDIO;       Select : 'Audio';                    Desc : 'Configure audio, music and sound options.' ),
  ( State : SETTINGSVIEW_GAMEPLAY;    Select : 'Gameplay';                 Desc : 'Configure gameplay options.' ),
  ( State : SETTINGSVIEW_INPUT;       Select : 'Input';                    Desc : 'Configure input options (apart from keybindings).' ),
  ( State : SETTINGSVIEW_KEYMOVEMENT; Select : 'Keybindings - Movement';   Desc : 'Configure keybindings for movement.' ),
  ( State : SETTINGSVIEW_KEYACTION;   Select : 'Keybindings - Actions';    Desc : 'Configure keybindings for in-game actions.' ),
  ( State : SETTINGSVIEW_KEYUI;       Select : 'Keybindings - UI';         Desc : 'Configure keybindings accessing UI elements (inventory, etc.).' ),
  ( State : SETTINGSVIEW_KEYMULTIMOVE;Select : 'Keybindings - Multi-move'; Desc : 'Configure keybindings for repeat movement.' ),
  ( State : SETTINGSVIEW_KEYHELPER;   Select : 'Keybindings - Helper';     Desc : 'Configure extra helper keybindings and quickslot keys.' ),
  ( State : SETTINGSVIEW_KEYLEGACY;   Select : 'Keybindings - Legacy';     Desc : 'Keybindings that are no longer needed, but some may want them back.' )
);

constructor TSettingsView.Create;
var i, iCount : Integer;
begin
  inherited Create;
  VTIG_EventClear;
  VTIG_ResetSelect( 'settings' );
  FSize  := Point( 80, 25 );
  FWSize := Point( 50, 10 );

  FCapture  := False;
  FResInput := False;
  FModInput := False;
  FWarning  := '';
  FRestart  := '';


  if GraphicsVersion then
  begin
    iCount := Min( 17, IO.Driver.DisplayModes.Size );
    SetLength( FResolutions, iCount + 1);
    FResolutions[0] := 'Automatic';
    for i := 1 to iCount do
      with IO.Driver.DisplayModes[i-1] do
        FResolutions[i] := IntToStr( Width ) + 'x' + IntToStr( Height )
  end;

  SetLength( FModules, DRL.Modules.CoreModules.Size + 1 );
  FModCurrent := Configuration.GetString('default_module');
  FModules[0] := 'Ask on launch';
  FModValue := -1;
  for i := 1 to DRL.Modules.CoreModules.Size do
    with DRL.Modules.CoreModules[i-1] do
    begin
      if FModCurrent = ID then
        FModValue := i;
      FModules[i] := Name;
    end;
  if FModCurrent = '' then FModValue := 0;
  if FModValue = -1 then
  begin
    FModValue := DRL.Modules.CoreModules.Size + 1;
    SetLength( FModules, FModValue + 1 );
    FModules[FModValue] := FModCurrent+' (missing)';
  end;
end;

procedure TSettingsView.Update( aDTime : Integer; aActive : Boolean );
var iSelected : Integer;
    iNext     : TSettingsViewState;
    iApply    : Boolean;
    iReset    : Boolean;
    iResult   : Boolean;
    iGroup    : TConfigurationGroup;
    iEntry    : TConfigurationEntry;
    iHover    : TConfigurationEntry;
    iMode     : TIntegerConfigurationEntry;
    i         : Integer;
    iRResult  : ( None, Cancel, Confirm );
begin
  if ( FState = SETTINGSVIEW_DONE ) then Exit;
  if ( FWarning <> '' ) then
  begin
    VTIG_BeginWindow( 'Warning', 'settings_warning', FWSize );
    VTIG_Text(FWarning);
    VTIG_End('{l<{!{$input_escape},{$input_ok}}> continue}');

    if VTIG_EventCancel or VTIG_EventConfirm then
      FWarning := '';
    Exit;
  end;

  if ( FRestart <> '' ) then
  begin
    iRResult := None;
    VTIG_BeginWindow( 'Restart?', 'settings_restart', FWSize );
    VTIG_Text('This is a different core mod then the current one. Restart with new core mod?');
    VTIG_Text( '' );
    if VTIG_Selectable( 'Restart' ) then iRResult := Confirm;
    if VTIG_Selectable( 'Cancel' )  then iRResult := Cancel;
    if VTIG_EventCancel then iRResult := Cancel;

    if iRResult <> None then
    begin
      if iRResult = Confirm then
      begin
        ForceRestart := FRestart;
        FState := SETTINGSVIEW_DONE;
      end;
      FRestart := '';
    end;
    Exit;
  end;

  iNext  := SETTINGSVIEW_DONE;
  iHover := nil;

  if CStates[ FState ].ID <> '' then
    iGroup := Configuration.Group[ CStates[ FState ].ID ];

  iMode := Configuration.CastInteger( 'display_mode' );

  VTIG_BeginWindow( CStates[ FState ].Title, 'settings', FSize );
    VTIG_BeginGroup( 18, True );

    VTIG_BeginGroup( 50 );
      if FState = SETTINGSVIEW_DISPLAY then
        VTIG_Selectable( 'Resolution' );

      if FState = SETTINGSVIEW_GENERAL then
        for i := 1 to High( CSub ) do
          if VTIG_Selectable( CSub[i].Select ) then
            iNext := CSub[i].State;

      if iGroup <> nil then
        for iEntry in iGroup.Entries do
          if iEntry.Name <> '' then
            VTIG_Selectable( iEntry.Name );

      // options

      iReset := VTIG_Selectable( 'Reset to defaults' );
      iApply := VTIG_Selectable( 'Apply settings' );
      iSelected := VTIG_Selected;
    VTIG_EndGroup;

    VTIG_BeginGroup;
      i := 0;
      if FState = SETTINGSVIEW_GENERAL then
      begin
        for i := 1 to High( CSub ) do
          VTIG_Text( '' );
        i := High( CSub );
      end;
      if iGroup <> nil then
      begin
        if FState in SETTINGSVIEW_KEYS then
        begin
          for iEntry in iGroup.Entries do
            if iEntry.Name <> '' then
            begin
              with iEntry as TIntegerConfigurationEntry do
                KeyCapture( Access, iSelected = i );
              if iSelected = i then iHover := iEntry;
              Inc( i );
            end;
        end
        else
        begin
          if FState = SETTINGSVIEW_DISPLAY then
          begin
            if GraphicsVersion then
            begin
              if VTIG_EnumInput( iMode.Access, iSelected = i, @FResInput, FResolutions ) then
              begin
                if iMode.Value = 0 then
                begin
                  Configuration.AccessInteger( 'screen_width' )^  := 0;
                  Configuration.AccessInteger( 'screen_height' )^ := 0;
                end
                else
                with IO.Driver.DisplayModes[ iMode.Value - 1 ] do
                begin
                  Configuration.AccessInteger( 'screen_width' )^  := Width;
                  Configuration.AccessInteger( 'screen_height' )^ := Height;
                end;
                DRL.Reconfigure;
              end;
            end
            else
              VTIG_InputField('Unavailable');

            Inc( i );
          end;

          for iEntry in iGroup.Entries do
            if iEntry.Name <> '' then
            begin
              if iEntry.ID = 'default_module' then
              begin
                if VTIG_EnumInput( @FModValue, iSelected = i, @FModInput, FModules ) then
                  with iEntry as TStringConfigurationEntry do
                  begin
                    if FModValue = 0 then Value := ''
                    else if FModValue >= (DRL.Modules.CoreModules.Size+1)
                      then Value := FModCurrent
                      else Value := DRL.Modules.CoreModules[FModValue-1].ID;
                    if ( DRL.State = DSMenu ) and ( Value <> '' ) and ( Value <> CoreModuleID ) then
                    begin
                      FRestart := Value;
                    end;
                  end;
              end
              else
              if iEntry is TIntegerConfigurationEntry then
              begin
                with iEntry as TIntegerConfigurationEntry do
                begin
                  if Names = nil
                    then iResult := VTIG_IntInput( Access, iSelected = i, Min, Max, Step )
                    else iResult := VTIG_EnumInput( Access, iSelected = i, @FResInput, Names );
                  if iResult then
                  begin
                    if FState = SETTINGSVIEW_AUDIO then
                    begin
                      IO.Audio.Reconfigure;
                      if iEntry.ID = 'sound_volume' then
                         Sound.PlaySample('menu.change');
                    end;
                    if FState = SETTINGSVIEW_DISPLAY then
                    begin
                      DRL.Reconfigure;
                      if (ID = 'tile_multi') and ( Access^ = 2 ) then
                         FWarning := 'Do note that the x1.5 multiplier is an accessability option, created mostly for SteamDeck readability - the pixel art will be distorted in this setting, and small artifacts may appear!';
                    end;
                  end;
                end;
              end
              else if iEntry is TToggleConfigurationEntry then
                 with iEntry as TToggleConfigurationEntry do
                   VTIG_EnabledInput( Access, iSelected = i );
              if iSelected = i then iHover := iEntry;
              Inc( i );
            end;
        end;
      end;
    VTIG_EndGroup;

  VTIG_EndGroup( True );

  if FState = SETTINGSVIEW_GENERAL then
  begin
    if iSelected in [0..High( CSub )-1]
      then VTIG_Text( CSub[iSelected + 1].Desc );
    if iSelected = i   then VTIG_Text( 'Resets ALL configuration values to default values.' );
    if iSelected = i+1 then VTIG_Text( 'Apply changes and exit.' );
  end
  else
  begin
    if iSelected = i   then VTIG_Text( 'Resets values from this screen to default values.' );
    if iSelected = i+1 then VTIG_Text( 'Apply changes and return to previous menu.' );
  end;
  if ( FState = SETTINGSVIEW_DISPLAY ) and ( iSelected = 0 )then
  begin
    if GraphicsVersion
      then VTIG_Text( 'Choose screen resolution. Pick {!Automatic} to use native in fullscreen.' )
      else VTIG_Text( 'Resolution choice unavailable in ASCII mode. You can still reset it to default if needed.' );
  end;


  if iHover <> nil
    then VTIG_Text( iHover.Description );


  if FState in SETTINGSVIEW_KEYS
    then VTIG_End('{l<{!{$input_up},{$input_down}}> select, <{!{$input_ok}}> change/enter, <{!{$input_escape}}> back, <{!{$input_uidrop}}> clear}')
    else VTIG_End('{l<{!{$input_up},{$input_down}}> select, <{!{$input_ok}}> change or enter submenu, <{!{$input_escape}}> back}');

  if iNext <> SETTINGSVIEW_DONE then
  begin
    VTIG_ResetSelect( 'settings' );
    FState := iNext;
  end;

  if VTIG_EventCancel or iApply then
    if FState = SETTINGSVIEW_GENERAL
      then FState := SETTINGSVIEW_DONE
      else begin
        VTIG_ResetSelect( 'settings' );
        FState := SETTINGSVIEW_GENERAL;
      end;

  if iApply then Reconfigure;
  if iReset then
  begin
    if FState = SETTINGSVIEW_GENERAL
      then Reset( nil )
      else Reset( iGroup );
    Reconfigure;
  end;
end;

function TSettingsView.IsFinished : Boolean;
begin
  Exit( FState = SETTINGSVIEW_DONE );
end;

function TSettingsView.IsModal : Boolean;
begin
  Exit( True );
end;

function TSettingsView.HandleEvent( const aEvent : TIOEvent ) : Boolean;
begin
  if FCapture and (aEvent.EType = VEVENT_KEYDOWN) and (aEvent.Key.Code <> 0) then
  begin
    if aEvent.Key.Code = VKEY_ESCAPE
      then FKey := VKEY_ESCAPE
      else FKey := IOKeyEventToIOKeyCode( aEvent.Key );
  end;
  Exit( True );
end;

destructor TSettingsView.Destroy;
begin
  Configuration.Write( SettingsPath );
  inherited Destroy;
end;

function TSettingsView.KeyCapture( aValue : PInteger; aSelected : Boolean ) : Boolean;
begin
  VTIG_InputField( IOKeyCodeToStringShort( aValue^ ) );
  if aSelected then
  begin
    if FCapture then
    begin
      VTIG_Begin( 'capture', Point( 34, 7 ) );
      VTIG_Text('Press the key or chord you want to bind, or <{!Escape}> to cancel...');
      VTIG_End;

      if FKey <> 0 then
      begin
        FCapture := False;
        if FKey <> VKEY_ESCAPE then
          aValue^ := FKey;
        FKey := 0;
      end;
      VTIG_EventClear;
    end
    else
      if VTIG_Event( [VTIG_IE_LEFT, VTIG_IE_RIGHT, VTIG_IE_CONFIRM] ) then
      begin
        FCapture := True;
        FKey     := 0;
        Exit( False );
      end;
    if VTIG_Event( [VTIG_IE_BACKSPACE] ) then
      aValue^ := 0;
  end;
  Exit( False );
end;

procedure TSettingsView.Reset( aGroup : TConfigurationGroup );
var iEntry : TConfigurationEntry;
begin
  if aGroup = nil then
  begin
    for aGroup in Configuration.Groups do
      Reset( aGroup );
    Exit;
  end;

  for iEntry in aGroup.Entries do
    iEntry.Reset;
end;

procedure TSettingsView.Reconfigure;
begin
  DRL.Reconfigure;
end;

end.

