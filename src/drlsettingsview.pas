{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlsettingsview;
interface
uses vio, viotypes, vioevent, vconfiguration, vbindings, drlio, dfdata,
     drlcontrollerbindings;

type TSettingsViewState = (
  SETTINGSVIEW_GENERAL,
  SETTINGSVIEW_DISPLAY,
  SETTINGSVIEW_AUDIO,
  SETTINGSVIEW_GAMEPLAY,
  SETTINGSVIEW_INPUT,
  SETTINGSVIEW_CONTROLLER,
  SETTINGSVIEW_KEYMOVEMENT,
  SETTINGSVIEW_KEYACTION,
  SETTINGSVIEW_KEYUI,
  SETTINGSVIEW_KEYMULTIMOVE,
  SETTINGSVIEW_KEYHELPER,
  SETTINGSVIEW_KEYLEGACY,
  SETTINGSVIEW_UIKEYBOARD,
  SETTINGSVIEW_UICONTROLLER,
  SETTINGSVIEW_DONE
);

const SETTINGSVIEW_KEYS : set of TSettingsViewState = [
  SETTINGSVIEW_KEYMOVEMENT,
  SETTINGSVIEW_KEYACTION,
  SETTINGSVIEW_KEYUI,
  SETTINGSVIEW_KEYMULTIMOVE,
  SETTINGSVIEW_KEYHELPER,
  SETTINGSVIEW_KEYLEGACY,
  SETTINGSVIEW_UIKEYBOARD
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
  function CaptureControllerBindings : TControllerBindingCatalog;
  procedure ControllerCapture( aBindings : TControllerBindingCatalog;
    aAction : TBindingAction; aSelected : Boolean );
protected
  FState               : TSettingsViewState;
  FSize                : TIOPoint;
  FWSize               : TIOPoint;
  FCapture             : Boolean;
  FKey                 : Word;
  FControllerCapture   : Boolean;
  FControllerAction    : TBindingAction;
  FControllerButton    : TIOPadButton;
  FControllerCandidate : TIOPadButton;
  FControllerCancel    : Boolean;
  FControllerBHold     : Boolean;
  FControllerBStart    : DWord;
  FControllerMessage   : Ansistring;
  FResInput            : Boolean;
  FResolutions         : array of Ansistring;
  FModInput            : Boolean;
  FModValue            : Integer;
  FModules             : array of Ansistring;
  FModCurrent          : Ansistring;
  FWarning             : Ansistring;
  FRestart             : Ansistring;
end;

implementation

uses math, sysutils, vapp, vutil, vdebug, vtig, vtigio,
     drlconfiguration, drlbase, drluibindings;

const CStates : array[ TSettingsViewState ] of record Title, ID : Ansistring; end = (
   ( Title : 'Settings'; ID : 'general' ),
   ( Title : 'Settings (Display)'; ID : 'display' ),
   ( Title : 'Settings (Audio)'; ID : 'audio' ),
   ( Title : 'Settings (Gameplay)'; ID : 'gameplay' ),
   ( Title : 'Settings (Input)'; ID : 'input' ),
   ( Title : 'Settings (Controller)'; ID : CONTROLLER_BINDINGS_GAMEPLAY_GROUP ),
   ( Title : 'Settings (Keybindings - Movement)'; ID : 'keybindings_movement' ),
   ( Title : 'Settings (Keybindings - Actions)'; ID : 'keybindings_actions' ),
   ( Title : 'Settings (Keybindings - UI)'; ID : 'keybindings_ui' ),
   ( Title : 'Settings (Keybindings - Multi-move)'; ID : 'keybindings_running' ),
   ( Title : 'Settings (Keybindings - Helper)'; ID : 'keybindings_helper' ),
   ( Title : 'Settings (Keybindings - Legacy)'; ID : 'keybindings_legacy' ),
   ( Title : 'Settings (UI bindings - Keyboard)'; ID : UI_KEY_BINDING_GROUP ),
   ( Title : 'Settings (UI bindings - Controller)'; ID : UI_PAD_BINDING_GROUP ),
   ( Title : ''; ID : '' )
);

const CSub : array[ 1..13 ] of record State : TSettingsViewState; Select, Desc : Ansistring; end = (
  ( State : SETTINGSVIEW_DISPLAY;     Select : 'Display';                  Desc : 'Configure video and display options.' ),
  ( State : SETTINGSVIEW_AUDIO;       Select : 'Audio';                    Desc : 'Configure audio, music and sound options.' ),
  ( State : SETTINGSVIEW_GAMEPLAY;    Select : 'Gameplay';                 Desc : 'Configure gameplay options.' ),
  ( State : SETTINGSVIEW_INPUT;       Select : 'Input';                    Desc : 'Configure input options (apart from keybindings).' ),
  ( State : SETTINGSVIEW_CONTROLLER;  Select : 'Controller';               Desc : 'Configure controller bindings for gameplay actions.' ),
  ( State : SETTINGSVIEW_KEYMOVEMENT; Select : 'Keybindings - Movement';   Desc : 'Configure keybindings for movement.' ),
  ( State : SETTINGSVIEW_KEYACTION;   Select : 'Keybindings - Actions';    Desc : 'Configure keybindings for in-game actions.' ),
  ( State : SETTINGSVIEW_KEYUI;       Select : 'Keybindings - UI';         Desc : 'Configure keybindings accessing UI elements (inventory, etc.).' ),
  ( State : SETTINGSVIEW_KEYMULTIMOVE;Select : 'Keybindings - Multi-move'; Desc : 'Configure keybindings for repeat movement.' ),
  ( State : SETTINGSVIEW_KEYHELPER;   Select : 'Keybindings - Helper';     Desc : 'Configure extra helper keybindings and quickslot keys.' ),
  ( State : SETTINGSVIEW_KEYLEGACY;   Select : 'Keybindings - Legacy';     Desc : 'Keybindings that are no longer needed, but some may want them back.' ),
  ( State : SETTINGSVIEW_UIKEYBOARD;  Select : 'UI bindings - Keyboard';   Desc : 'Configure keyboard navigation shared by menus and dialogs.' ),
  ( State : SETTINGSVIEW_UICONTROLLER;Select : 'UI bindings - Controller'; Desc : 'Configure controller navigation shared by menus and dialogs.' )
);

constructor TSettingsView.Create;
var i, iCount : Integer;
begin
  inherited Create;
  VTIG_EventClear;
  VTIG_ResetSelect( 'settings' );
  FSize  := Point( 80, 25 );
  FWSize := Point( 50, 10 );

  FCapture             := False;
  FControllerCapture   := False;
  FControllerAction    := Ord( CONTROLLER_MOVE );
  FControllerButton    := VPAD_BUTTON_INVALID;
  FControllerCandidate := VPAD_BUTTON_INVALID;
  FControllerCancel    := False;
  FControllerBHold     := False;
  FControllerBStart    := 0;
  FControllerMessage   := '';
  FResInput            := False;
  FModInput            := False;
  FWarning             := '';
  FRestart             := '';


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
    iAction   : TControllerAction;
    i         : Integer;
    iRResult  : ( None, Cancel, Confirm );
begin
  if FControllerCapture and FControllerBHold
    and IO.PadState.Active( CONTROLLER_CAPTURE_CANCEL_BUTTON )
    and ControllerCaptureCancelHeld( FControllerBStart, IO.Driver.GetMs ) then
  begin
    FControllerBHold := False;
    FControllerCancel := True;
  end;

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
  iGroup := nil;

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

      if FState = SETTINGSVIEW_CONTROLLER then
      begin
        for iAction in TControllerAction do
          if iAction in CONTROLLER_BINDING_MENU_ACTIONS then
            VTIG_Selectable( ControllerBindingInfo[ iAction ].Name );
      end
      else if FState = SETTINGSVIEW_UICONTROLLER then
      begin
        for iEntry in iGroup.Entries do
          if iEntry.Name <> '' then
            VTIG_Selectable( iEntry.Name );
      end
      else
      begin
        if iGroup <> nil then
          for iEntry in iGroup.Entries do
            if iEntry.Name <> '' then
              VTIG_Selectable( iEntry.Name );
      end;

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
        if FState = SETTINGSVIEW_CONTROLLER then
        begin
          for iAction in TControllerAction do
            if iAction in CONTROLLER_BINDING_MENU_ACTIONS then
            begin
              ControllerCapture(
                Configuration.ControllerBindings,
                Ord( iAction ),
                iSelected = i
              );
              if iSelected = i then
                iHover := Configuration.CastInteger(
                  ControllerBindingInfo[ iAction ].ID
                );
              Inc( i );
            end;
        end
        else if FState = SETTINGSVIEW_UICONTROLLER then
        begin
          for iEntry in iGroup.Entries do
            if iEntry.Name <> '' then
            begin
              ControllerCapture(
                Configuration.UIControllerBindings,
                UIPadBindingInfo[ i ].Action,
                iSelected = i
              );
              if iSelected = i then iHover := iEntry;
              Inc( i );
            end;
        end
        else if FState in SETTINGSVIEW_KEYS then
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
                      if iEntry.ID = 'volume_sound' then
                         IO.Audio.PlaySound('menu.change');
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


  if FState = SETTINGSVIEW_UICONTROLLER then
    VTIG_End('{l<{!{$input_up},{$input_down}}> select, <{!{$input_ok}}> rebind, <{!{$input_uidrop}}> clear, <{!{$input_escape}}> back}')
  else if FState = SETTINGSVIEW_CONTROLLER then
    VTIG_End('{l<{!{$input_up},{$input_down}}> select, <{!{$input_ok}}> rebind, <{!{$input_escape}}> back}')
  else if FState in SETTINGSVIEW_KEYS
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
      else if FState in [ SETTINGSVIEW_CONTROLLER, SETTINGSVIEW_UICONTROLLER ]
        then CaptureControllerBindings.ResetValues
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
var iButton        : TIOPadButton;
    iBindings      : TControllerBindingCatalog;
    iNow           : DWord;
    iBHoldComplete : Boolean;
begin
  if FControllerCapture then
  begin
    if ( aEvent.EType = VEVENT_KEYDOWN )
      and ( aEvent.Key.Code = VKEY_ESCAPE ) then
      FControllerCancel := True
    else if ( aEvent.EType = VEVENT_PADDEVICE )
      and ( aEvent.PadDevice.Event = VPAD_REMOVED ) then
      FControllerCancel := True
    else if GetBindableControllerButton( aEvent, iButton ) then
    begin
      iNow := IO.Driver.GetMs;
      if aEvent.EType = VEVENT_PADDOWN then
      begin
        if ( iButton = CONTROLLER_CAPTURE_CANCEL_BUTTON )
          and not FControllerBHold then
        begin
          FControllerBHold  := True;
          FControllerBStart := iNow;
        end;
        if FControllerCandidate = VPAD_BUTTON_INVALID then
        begin
          FControllerCandidate := iButton;
          FControllerMessage := '';
        end;
      end
      else
      begin
        iBHoldComplete := ( iButton = CONTROLLER_CAPTURE_CANCEL_BUTTON )
          and FControllerBHold
          and ControllerCaptureCancelHeld( FControllerBStart, iNow );
        if iButton = CONTROLLER_CAPTURE_CANCEL_BUTTON then
          FControllerBHold := False;

        if iBHoldComplete then
          FControllerCancel := True
        else if iButton = FControllerCandidate then
        begin
          FControllerCandidate := VPAD_BUTTON_INVALID;
          iBindings := CaptureControllerBindings;
          if ( iBindings <> nil ) and iBindings.CanCapture( iButton ) then
            FControllerButton := iButton
          else
            FControllerMessage := 'D-pad directions are fixed.';
        end;
      end;
    end;
    Exit( True );
  end;

  if FCapture and (aEvent.EType = VEVENT_KEYDOWN) and (aEvent.Key.Code <> 0) then
  begin
    if aEvent.Key.Code = VKEY_ESCAPE
      then FKey := VKEY_ESCAPE
      else if FState = SETTINGSVIEW_UIKEYBOARD
        then FKey := aEvent.Key.Code
        else FKey := IOKeyEventToIOKeyCode( aEvent.Key );
  end;
  Exit( True );
end;

destructor TSettingsView.Destroy;
begin
  Configuration.Write( Application.Paths.SettingsPath );
  inherited Destroy;
end;

function TSettingsView.CaptureControllerBindings : TControllerBindingCatalog;
begin
  case FState of
    SETTINGSVIEW_CONTROLLER:
      Exit( Configuration.ControllerBindings );
    SETTINGSVIEW_UICONTROLLER:
      Exit( Configuration.UIControllerBindings );
  end;
  Exit( nil );
end;

procedure TSettingsView.ControllerCapture(
  aBindings : TControllerBindingCatalog;
  aAction   : TBindingAction;
  aSelected : Boolean
);
var iCurrent : TIOPadButton;
begin
  iCurrent := aBindings.GetButton( aAction );
  VTIG_InputField( VPadButtonToDisplayString( iCurrent ) );

  if FControllerCapture and ( FControllerAction = aAction ) then
  begin
    VTIG_Begin( 'controller_capture', Point( 56, 8 ) );
    VTIG_Text( 'Release one controller button to bind.' );
    VTIG_Text( 'Hold {!B} for one second or press {!Escape} to cancel.' );
    if FControllerMessage <> '' then VTIG_Text( FControllerMessage );
    VTIG_End;

    if FControllerCancel then
      FControllerCapture := False
    else if FControllerButton <> VPAD_BUTTON_INVALID then
    begin
      FControllerCapture := False;
      if ( FControllerButton <> iCurrent ) and
         aBindings.Swap( aAction, FControllerButton ) then Reconfigure;
    end;

    if not FControllerCapture then
    begin
      FControllerButton := VPAD_BUTTON_INVALID;
      FControllerCandidate := VPAD_BUTTON_INVALID;
      FControllerCancel := False;
      FControllerBHold := False;
      FControllerBStart := 0;
      FControllerMessage := '';
    end;
    VTIG_EventClear;
    Exit;
  end;

  if not aSelected then Exit;
  if aBindings.AllowsUnbound and VTIG_Event( UI_BINDING_DROP ) then
  begin
    if aBindings.Swap( aAction, VPAD_BUTTON_INVALID ) then Reconfigure;
    Exit;
  end;
  if VTIG_EventConfirm then
  begin
    FControllerCapture := True;
    FControllerAction := aAction;
    FControllerButton := VPAD_BUTTON_INVALID;
    FControllerCandidate := VPAD_BUTTON_INVALID;
    FControllerCancel := False;
    FControllerBHold := False;
    FControllerBStart := 0;
    FControllerMessage := '';
    VTIG_EventClear;
  end;
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
    if VTIG_Event( UI_BINDING_DROP ) then
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
