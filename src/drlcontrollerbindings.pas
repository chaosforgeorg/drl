{$INCLUDE drl.inc}
unit drlcontrollerbindings;
interface

uses vioevent, vbindings;

const CONTROLLER_BINDINGS_GAMEPLAY_GROUP = 'controller_bindings_gameplay';
      CONTROLLER_BINDING_INFO_GROUP      = 'controller_gameplay';
      CONTROLLER_CAPTURE_CANCEL_BUTTON   = VPAD_BUTTON_B;
      CONTROLLER_CAPTURE_CANCEL_HOLD_MS  = 1000;

type TControllerAction = (
  CONTROLLER_MOVE,
  CONTROLLER_ACTION,
  CONTROLLER_FIRE,
  CONTROLLER_RELOAD,
  CONTROLLER_MENU,
  CONTROLLER_PLAYER,
  CONTROLLER_ACTIVE,
  CONTROLLER_SWAP,
  CONTROLLER_TARGET_PREV,
  CONTROLLER_TARGET_NEXT,
  CONTROLLER_UP,
  CONTROLLER_DOWN,
  CONTROLLER_LEFT,
  CONTROLLER_RIGHT,
  CONTROLLER_MODIFIER_RUN,
  CONTROLLER_MODIFIER_ALT
);

const CONTROLLER_BINDING_MENU_ACTIONS : set of TControllerAction = [
  CONTROLLER_MOVE,
  CONTROLLER_ACTION,
  CONTROLLER_FIRE,
  CONTROLLER_RELOAD,
  CONTROLLER_MENU,
  CONTROLLER_PLAYER,
  CONTROLLER_ACTIVE,
  CONTROLLER_SWAP,
  CONTROLLER_TARGET_PREV,
  CONTROLLER_TARGET_NEXT,
  CONTROLLER_MODIFIER_RUN,
  CONTROLLER_MODIFIER_ALT
];

type TControllerBindingFlag = (
  CONTROLLER_BINDING_ALLOW_UNBOUND,
  CONTROLLER_BINDING_ALLOW_DPAD_CAPTURE
);
type TControllerBindingFlags = set of TControllerBindingFlag;

type TControllerBindingCatalog = class( TBindingCatalog )
  constructor Create(
    const aInfo           : array of TBindingInfo;
    aFlags                : TControllerBindingFlags;
    const aInvalidWarning : Ansistring
  );
  function GetButton( aAction : TBindingAction ) : TIOPadButton;
  function Valid : Boolean;
  function Validate : Boolean;
  function Swap( aAction : TBindingAction; aButton : TIOPadButton ) : Boolean;
  function CanCapture( aButton : TIOPadButton ) : Boolean;
private
  FActions        : array of TBindingAction;
  FFlags          : TControllerBindingFlags;
  FInvalidWarning : Ansistring;
  function FindAction( aButton : TIOPadButton;
    out aAction : TBindingAction ) : Boolean;
  function GetAllowsUnbound : Boolean;
public
  property AllowsUnbound : Boolean read GetAllowsUnbound;
end;

const ControllerBindingInfo : array[TControllerAction] of TBindingInfo = (
    ( Action: Ord(CONTROLLER_MOVE)        ; ID: 'controller_gameplay_move'        ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_A)            ; Name: 'Move / wait confirmation'; Description: 'Confirm left-stick movement or wait in place.' ),
    ( Action: Ord(CONTROLLER_ACTION)      ; ID: 'controller_gameplay_action'      ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_B)            ; Name: 'Context action / pickup' ; Description: 'Perform a context action or pick up an item.' ),
    ( Action: Ord(CONTROLLER_FIRE)        ; ID: 'controller_gameplay_fire'        ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_X)            ; Name: 'Fire'                    ; Description: 'Fire the equipped weapon.' ),
    ( Action: Ord(CONTROLLER_RELOAD)      ; ID: 'controller_gameplay_reload'      ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_Y)            ; Name: 'Reload'                  ; Description: 'Reload the equipped weapon.' ),
    ( Action: Ord(CONTROLLER_MENU)        ; ID: 'controller_gameplay_menu'        ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_BACK)         ; Name: 'Game menu'               ; Description: 'Open the game menu.' ),
    ( Action: Ord(CONTROLLER_PLAYER)      ; ID: 'controller_gameplay_player'      ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_START)        ; Name: 'Player screen'           ; Description: 'Open the player screen.' ),
    ( Action: Ord(CONTROLLER_ACTIVE)      ; ID: 'controller_gameplay_active'      ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_LEFTSTICK)    ; Name: 'Active skill'            ; Description: 'Use the active skill.' ),
    ( Action: Ord(CONTROLLER_SWAP)        ; ID: 'controller_gameplay_swap'        ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_RIGHTSTICK)   ; Name: 'Swap weapon'             ; Description: 'Swap the equipped weapon.' ),
    ( Action: Ord(CONTROLLER_TARGET_PREV) ; ID: 'controller_gameplay_target_prev' ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_LEFTSHOULDER) ; Name: 'Previous target'         ; Description: 'Select the previous target.' ),
    ( Action: Ord(CONTROLLER_TARGET_NEXT) ; ID: 'controller_gameplay_target_next' ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_RIGHTSHOULDER); Name: 'Next target'             ; Description: 'Select the next target.' ),
    ( Action: Ord(CONTROLLER_UP)          ; ID: 'controller_gameplay_up'          ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_DPAD_UP)      ; Name: 'Direction up'            ; Description: 'Move the target or selection up.' ),
    ( Action: Ord(CONTROLLER_DOWN)        ; ID: 'controller_gameplay_down'        ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_DPAD_DOWN)    ; Name: 'Direction down'          ; Description: 'Move the target or selection down.' ),
    ( Action: Ord(CONTROLLER_LEFT)        ; ID: 'controller_gameplay_left'        ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_DPAD_LEFT)    ; Name: 'Direction left'          ; Description: 'Move the target or selection left.' ),
    ( Action: Ord(CONTROLLER_RIGHT)       ; ID: 'controller_gameplay_right'       ; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_DPAD_RIGHT)   ; Name: 'Direction right'         ; Description: 'Move the target or selection right.' ),
    ( Action: Ord(CONTROLLER_MODIFIER_RUN); ID: 'controller_gameplay_modifier_run'; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_LEFTTRIGGER)  ; Name: 'Run / quickslot modifier'; Description: 'Modify movement and quickslot actions.' ),
    ( Action: Ord(CONTROLLER_MODIFIER_ALT); ID: 'controller_gameplay_modifier_alt'; Group: CONTROLLER_BINDING_INFO_GROUP; Default: Ord(VPAD_BUTTON_RIGHTTRIGGER) ; Name: 'Aim / alternate modifier'; Description: 'Modify targeting, firing, reloading, and item actions.' )
);

function IsControllerButton( aButton : TIOPadButton ) : Boolean;
function ControllerCaptureCancelHeld( aStartedAt : DWord; aNow : DWord ) : Boolean;
function GetBindableControllerButton( const aEvent : TIOEvent;
  out aButton : TIOPadButton ) : Boolean;

implementation

uses vdebug, vutil;

function IsControllerButton( aButton : TIOPadButton ) : Boolean;
begin
  Exit(
    ( aButton >= VPAD_BUTTON_A )
    and ( aButton <= High( TIOPadButton ) )
    and ( aButton <> VPAD_BUTTON_GUIDE )
  );
end;

constructor TControllerBindingCatalog.Create(
  const aInfo           : array of TBindingInfo;
  aFlags                : TControllerBindingFlags;
  const aInvalidWarning : Ansistring
);
var iInfo : Integer;
begin
  inherited Create( aInfo );
  SetLength( FActions, Length( aInfo ) );
  for iInfo := 0 to High( aInfo ) do
    FActions[iInfo] := aInfo[iInfo].Action;
  FFlags := aFlags;
  FInvalidWarning := aInvalidWarning;
end;

function TControllerBindingCatalog.GetAllowsUnbound : Boolean;
begin
  Exit( CONTROLLER_BINDING_ALLOW_UNBOUND in FFlags );
end;

function TControllerBindingCatalog.GetButton(
  aAction : TBindingAction
) : TIOPadButton;
var iValue : Integer;
begin
  iValue := ConfigurationValue( aAction );
  if ( iValue < Ord( Low( TIOPadButton ) ) ) or
     ( iValue > Ord( High( TIOPadButton ) ) ) then
    Exit( VPAD_BUTTON_INVALID );
  Result := TIOPadButton( iValue );
end;

function TControllerBindingCatalog.FindAction(
  aButton     : TIOPadButton;
  out aAction : TBindingAction
) : Boolean;
var iAction : TBindingAction;
begin
  if not IsControllerButton( aButton ) then Exit( False );
  for iAction in FActions do
    if GetButton( iAction ) = aButton then
    begin
      aAction := iAction;
      Exit( True );
    end;
  Exit( False );
end;

function TControllerBindingCatalog.Valid : Boolean;
var iAction : TBindingAction;
    iButton : TIOPadButton;
    iSeen   : array[TIOPadButton] of Boolean;
begin
  for iButton := Low( TIOPadButton ) to High( TIOPadButton ) do
    iSeen[iButton] := False;
  for iAction in FActions do
  begin
    iButton := GetButton( iAction );
    if AllowsUnbound and ( iButton = VPAD_BUTTON_INVALID ) then Continue;
    if not IsControllerButton( iButton ) or iSeen[iButton] then Exit( False );
    iSeen[iButton] := True;
  end;
  Exit( True );
end;

function TControllerBindingCatalog.Validate : Boolean;
begin
  Result := Valid;
  if Result then Exit;
  Log( LOGWARN, FInvalidWarning );
  ResetValues;
end;

function TControllerBindingCatalog.Swap(
  aAction : TBindingAction;
  aButton : TIOPadButton
) : Boolean;
var iOldButton      : TIOPadButton;
    iPreviousAction : TBindingAction;
begin
  if ( ( aButton = VPAD_BUTTON_INVALID ) and not AllowsUnbound ) or
     ( ( aButton <> VPAD_BUTTON_INVALID ) and not IsControllerButton( aButton ) ) or
     not Valid then Exit( False );

  iOldButton := GetButton( aAction );
  if iOldButton = aButton then Exit( True );
  if FindAction( aButton, iPreviousAction ) then
    SetConfigurationValue( iPreviousAction, Ord( iOldButton ) );
  SetConfigurationValue( aAction, Ord( aButton ) );
  Exit( True );
end;

function TControllerBindingCatalog.CanCapture(
  aButton : TIOPadButton
) : Boolean;
begin
  if not IsControllerButton( aButton ) then Exit( False );
  if not ( CONTROLLER_BINDING_ALLOW_DPAD_CAPTURE in FFlags ) and
     ( aButton in [
       VPAD_BUTTON_DPAD_UP,
       VPAD_BUTTON_DPAD_DOWN,
       VPAD_BUTTON_DPAD_LEFT,
       VPAD_BUTTON_DPAD_RIGHT
     ] ) then Exit( False );
  Exit( True );
end;

function ControllerCaptureCancelHeld( aStartedAt : DWord;
  aNow : DWord ) : Boolean;
begin
  Exit( aNow - aStartedAt >= CONTROLLER_CAPTURE_CANCEL_HOLD_MS );
end;

function GetBindableControllerButton(
  const aEvent : TIOEvent;
  out aButton  : TIOPadButton
) : Boolean;
begin
  aButton := VPAD_BUTTON_INVALID;
  if not ( aEvent.EType in [ VEVENT_PADDOWN, VEVENT_PADUP ] ) or
     not IsControllerButton( aEvent.Pad.Button ) then Exit( False );
  aButton := aEvent.Pad.Button;
  Exit( True );
end;

end.
