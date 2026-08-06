{$INCLUDE drl.inc}
unit drlcontrollerbindings;
interface

uses vconfiguration, vioevent, vluaconfig;

const CONTROLLER_BINDINGS_GAMEPLAY_GROUP = 'controller_bindings_gameplay';

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

type TControllerBindingInfo = record
    ID          : AnsiString;
    Group       : AnsiString;
    Default     : TIOPadButton;
    Name        : AnsiString;
    Description : AnsiString;
end;

const ControllerBindingInfo : array[TControllerAction] of TControllerBindingInfo = (
    (ID: 'controller_gameplay_move';         Group: 'controller_gameplay'; Default: VPAD_BUTTON_A;             Name: 'Move / wait confirmation'; Description: 'Confirm left-stick movement or wait in place.'),
    (ID: 'controller_gameplay_action';       Group: 'controller_gameplay'; Default: VPAD_BUTTON_B;             Name: 'Context action / pickup';  Description: 'Perform a context action or pick up an item.'),
    (ID: 'controller_gameplay_fire';         Group: 'controller_gameplay'; Default: VPAD_BUTTON_X;             Name: 'Fire';                     Description: 'Fire the equipped weapon.'),
    (ID: 'controller_gameplay_reload';       Group: 'controller_gameplay'; Default: VPAD_BUTTON_Y;             Name: 'Reload';                   Description: 'Reload the equipped weapon.'),
    (ID: 'controller_gameplay_menu';         Group: 'controller_gameplay'; Default: VPAD_BUTTON_BACK;          Name: 'Game menu';                Description: 'Open the game menu.'),
    (ID: 'controller_gameplay_player';       Group: 'controller_gameplay'; Default: VPAD_BUTTON_START;         Name: 'Player screen';            Description: 'Open the player screen.'),
    (ID: 'controller_gameplay_active';       Group: 'controller_gameplay'; Default: VPAD_BUTTON_LEFTSTICK;     Name: 'Active skill';             Description: 'Use the active skill.'),
    (ID: 'controller_gameplay_swap';         Group: 'controller_gameplay'; Default: VPAD_BUTTON_RIGHTSTICK;    Name: 'Swap weapon';              Description: 'Swap the equipped weapon.'),
    (ID: 'controller_gameplay_target_prev';  Group: 'controller_gameplay'; Default: VPAD_BUTTON_LEFTSHOULDER;  Name: 'Previous target';          Description: 'Select the previous target.'),
    (ID: 'controller_gameplay_target_next';  Group: 'controller_gameplay'; Default: VPAD_BUTTON_RIGHTSHOULDER; Name: 'Next target';              Description: 'Select the next target.'),
    (ID: 'controller_gameplay_up';           Group: 'controller_gameplay'; Default: VPAD_BUTTON_DPAD_UP;       Name: 'Direction up';             Description: 'Move the target or selection up.'),
    (ID: 'controller_gameplay_down';         Group: 'controller_gameplay'; Default: VPAD_BUTTON_DPAD_DOWN;     Name: 'Direction down';           Description: 'Move the target or selection down.'),
    (ID: 'controller_gameplay_left';         Group: 'controller_gameplay'; Default: VPAD_BUTTON_DPAD_LEFT;     Name: 'Direction left';           Description: 'Move the target or selection left.'),
    (ID: 'controller_gameplay_right';        Group: 'controller_gameplay'; Default: VPAD_BUTTON_DPAD_RIGHT;    Name: 'Direction right';          Description: 'Move the target or selection right.'),
    (ID: 'controller_gameplay_modifier_run'; Group: 'controller_gameplay'; Default: VPAD_BUTTON_LEFTTRIGGER;   Name: 'Run / quickslot modifier'; Description: 'Modify movement and quickslot actions.'),
    (ID: 'controller_gameplay_modifier_alt'; Group: 'controller_gameplay'; Default: VPAD_BUTTON_RIGHTTRIGGER;  Name: 'Aim / alternate modifier'; Description: 'Modify targeting, firing, reloading, and item actions.')
);

procedure RegisterControllerBindings( aGroup : TConfigurationGroup );
function IsControllerButton( aButton : TIOPadButton ) : Boolean;
function ControllerBindingsValid( aConfiguration : TConfigurationManager ) : Boolean;
procedure ResetControllerBindings( aConfiguration : TConfigurationManager );
function ValidateControllerBindings( aConfiguration : TConfigurationManager ) : Boolean;
function GetControllerButton(
  aConfiguration : TConfigurationManager;
  aAction        : TControllerAction
) : TIOPadButton;
function FindControllerAction(
  aConfiguration : TConfigurationManager;
  aButton        : TIOPadButton;
  out aAction    : TControllerAction
) : Boolean;
function SwapControllerBinding(
  aConfiguration : TConfigurationManager;
  aAction        : TControllerAction;
  aButton        : TIOPadButton
) : Boolean;
procedure ApplyControllerBindings(
  aConfiguration : TConfigurationManager;
  aConfig        : TLuaConfig
);

implementation

uses vdebug, vutil;

procedure RegisterControllerBindings( aGroup : TConfigurationGroup );
var iAction : TControllerAction;
begin
  for iAction in TControllerAction do
    aGroup.AddInteger(
      ControllerBindingInfo[ iAction ].ID,
      Ord( ControllerBindingInfo[ iAction ].Default )
    )
      .SetName( ControllerBindingInfo[ iAction ].Name )
      .SetDescription( ControllerBindingInfo[ iAction ].Description )
      ;
end;

function IsControllerButton( aButton : TIOPadButton ) : Boolean;
begin
  Exit(
    ( aButton >= VPAD_BUTTON_A )
    and ( aButton <= High( TIOPadButton ) )
    and ( aButton <> VPAD_BUTTON_GUIDE )
  );
end;

function GetControllerButton(
  aConfiguration : TConfigurationManager;
  aAction        : TControllerAction
) : TIOPadButton;
var iValue : Integer;
begin
  iValue := aConfiguration.GetInteger( ControllerBindingInfo[ aAction ].ID );
  if ( iValue < Ord( Low( TIOPadButton ) ) )
    or ( iValue > Ord( High( TIOPadButton ) ) ) then
    Exit( VPAD_BUTTON_INVALID );
  Result := TIOPadButton( iValue );
end;

function FindControllerAction(
  aConfiguration : TConfigurationManager;
  aButton        : TIOPadButton;
  out aAction    : TControllerAction
) : Boolean;
var iAction : TControllerAction;
begin
  if not IsControllerButton( aButton ) then
    Exit( False );
  for iAction in TControllerAction do
    if GetControllerButton( aConfiguration, iAction ) = aButton then
    begin
      aAction := iAction;
      Exit( True );
    end;
  Exit( False );
end;

function ControllerBindingsValid( aConfiguration : TConfigurationManager ) : Boolean;
var iAction : TControllerAction;
    iButton : TIOPadButton;
    iSeen   : array[TIOPadButton] of Boolean;
begin
  for iButton := Low( TIOPadButton ) to High( TIOPadButton ) do
    iSeen[ iButton ] := False;
  for iAction in TControllerAction do
  begin
    iButton := GetControllerButton( aConfiguration, iAction );
    if not IsControllerButton( iButton ) or iSeen[ iButton ] then
      Exit( False );
    iSeen[ iButton ] := True;
  end;
  Exit( True );
end;

procedure ResetControllerBindings( aConfiguration : TConfigurationManager );
var iAction : TControllerAction;
begin
  for iAction in TControllerAction do
    aConfiguration.CastInteger( ControllerBindingInfo[ iAction ].ID ).Reset;
end;

function ValidateControllerBindings( aConfiguration : TConfigurationManager ) : Boolean;
begin
  Result := ControllerBindingsValid( aConfiguration );
  if Result then
    Exit;
  Log(
    LOGWARN,
    'Malformed gameplay controller bindings; resetting the complete controller binding group.'
  );
  ResetControllerBindings( aConfiguration );
end;

function SwapControllerBinding(
  aConfiguration : TConfigurationManager;
  aAction        : TControllerAction;
  aButton        : TIOPadButton
) : Boolean;
var iOldButton      : TIOPadButton;
    iPreviousAction : TControllerAction;
begin
  if not IsControllerButton( aButton )
    or not ControllerBindingsValid( aConfiguration ) then
    Exit( False );

  iOldButton := GetControllerButton( aConfiguration, aAction );
  if iOldButton = aButton then
    Exit( True );
  if FindControllerAction( aConfiguration, aButton, iPreviousAction ) then
    aConfiguration.AccessInteger(
      ControllerBindingInfo[ iPreviousAction ].ID
    )^ := Ord( iOldButton );
  aConfiguration.AccessInteger(
    ControllerBindingInfo[ aAction ].ID
  )^ := Ord( aButton );
  Exit( True );
end;

procedure ApplyControllerBindings( aConfiguration : TConfigurationManager; aConfig : TLuaConfig );
var iAction : TControllerAction;
begin
  ValidateControllerBindings( aConfiguration );
  aConfig.ResetPadCommands;
  for iAction in TControllerAction do
    aConfig.PadCommands[
      GetControllerButton( aConfiguration, iAction )
    ] := Byte( iAction );
end;

end.
