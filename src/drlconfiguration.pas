{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlconfiguration;
interface
uses vconfiguration, vbindings, drlcontrollerbindings;

type TDRLConfiguration = class( TConfigurationManager )
  constructor Create;
  destructor Destroy; override;
private
  FKeyBindings          : TBindingCatalog;
  FControllerBindings   : TControllerBindingCatalog;
  FUIKeyBindings        : TBindingCatalog;
  FUIControllerBindings : TControllerBindingCatalog;
public
  property KeyBindings          : TBindingCatalog read FKeyBindings;
  property ControllerBindings   : TControllerBindingCatalog read FControllerBindings;
  property UIKeyBindings        : TBindingCatalog read FUIKeyBindings;
  property UIControllerBindings : TControllerBindingCatalog read FUIControllerBindings;
end;

var Configuration : TDRLConfiguration;

implementation

uses SysUtils, drlkeybindings, drluibindings;

constructor TDRLConfiguration.Create;
var iGroup : TConfigurationGroup;
    iID    : Ansistring;
const CInputGroups : array[1..8] of Ansistring = (
  'keybindings_hidden',
  'keybindings_movement',
  'keybindings_actions',
  'keybindings_ui',
  'keybindings_running',
  'keybindings_target',
  'keybindings_helper',
  'keybindings_legacy'
);
begin
  inherited Create;
  FKeyBindings := TBindingCatalog.Create(KeyInfo);
  FControllerBindings := TControllerBindingCatalog.Create(
    ControllerBindingInfo,
    [],
    'Malformed gameplay controller bindings; resetting the complete controller binding group.'
  );
  FUIKeyBindings := TBindingCatalog.Create( UIKeyBindingInfo );
  FUIControllerBindings := TControllerBindingCatalog.Create(
    UIPadBindingInfo,
    [
      CONTROLLER_BINDING_ALLOW_UNBOUND,
      CONTROLLER_BINDING_ALLOW_DPAD_CAPTURE
    ],
    'Malformed UI controller bindings; resetting the complete UI controller binding group.'
  );

  iGroup := AddGroup( 'meta' );
  iGroup.AddInteger( 'config_version', 0 );

  iGroup := AddGroup( 'general' );
  iGroup.AddToggle( 'first_run', True );
  iGroup.AddToggle( 'skip_intro', False )
    .SetName('Skip intro')
    .SetDescription('Setting to {!Enabled} will skip the plot intro text before playing.')
    ;
  iGroup.AddString( 'default_module', '' )
    .SetName('Default module')
    .SetDescription('Select module to skip module selection screen on launch, or {!Ask} to ask at launch.')
    ;

  iGroup := AddGroup( 'display' );
  iGroup.AddInteger( 'display_mode', 0 );
  iGroup.AddInteger( 'screen_width', 0 );
  iGroup.AddInteger( 'screen_height', 0 );

  iGroup.AddToggle( 'fullscreen', True )
    .SetName('Fullscreen')
    .SetDescription('Set to {!Disabled} to make the game launch in windowed mode.')
    ;

  iGroup.AddInteger( 'font_multiplier', 0 )
    .SetRange(0,4)
    .SetNames(['Automatic','x1','x2','x3','x4'])
    .SetName('Font size multiplier')
    .SetDescription('Control font size multiplier. Set to {!Automatic} to pick one based on resolution.')
    ;

  iGroup.AddInteger( 'tile_multi', 0 )
    .SetRange(0,5)
    .SetNames(['Automatic','x1','x1.5(fuzzy)','x2','x3','x4'])
    .SetName('Tile size multiplier')
    .SetDescription('Control tile size multiplier. Set to {!Automatic} to pick one based on resolution.')
    ;

  iGroup.AddInteger( 'minimap_multi', 0 )
    .SetRange(0,7)
    .SetNames(['Automatic','x1','x2','x3','x4','x6','x8','x10'])
    .SetName('Minimap size multiplier')
    .SetDescription('Control minimap size multiplier. Set to {!Automatic} to pick one based on resolution.')
    ;
  iGroup.AddInteger( 'minimap_opacity', 2 )
    .SetRange(0,5)
    .SetName('Minimap opacity')
    .SetDescription('Control minimap opacity. Set to {!0} to disable minimap.')
    ;
  iGroup.AddToggle( 'screen_shake', True )
    .SetName('Screen shake effect')
    .SetDescription('Setting to {!Disabled} will disable screen shake FX.')
    ;
  iGroup.AddToggle( 'flashing_fx', True )
    .SetName('Screen flashing')
    .SetDescription('Setting to {!Disabled} will disable screen flash FX.')
    ;
  iGroup.AddToggle( 'pulse_fx', True )
    .SetName('Blood pulse')
    .SetDescription('Setting to {!Disabled} will disable pulsing blood vignette.')
    ;
  iGroup.AddToggle( 'glow_fx', True )
    .SetName('Emissive glow')
    .SetDescription('Setting to {!Disabled} will disable glow FX and improve performance.')
    ;
  iGroup.AddToggle( 'fade_fx', True )
    .SetName('Fading effects')
    .SetDescription('Setting to {!Disabled} will disable on level change/exit fading.')
    ;
  iGroup.AddToggle( 'item_drop_animation', True )
    .SetName('Item drop animation')
    .SetDescription('Setting to {!Disabled} will disable the drop bump animation.')
    ;

  iGroup := AddGroup( 'audio' );
  iGroup.AddInteger( 'volume_sound', 70 )
    .SetRange(0,100,5)
    .SetName('Sound volume')
    .SetDescription('Control sound volume. Set to {!0} to turn off sounds.')
    ;
  iGroup.AddInteger( 'volume_music', 30 )
    .SetRange(0,100,5)
    .SetName('Music volume')
    .SetDescription('Control music volume. Set to {!0} to turn off music.')
    ;
  iGroup.AddToggle( 'menu_sound', True )
    .SetName('Menu sounds')
    .SetDescription('Set to {!Disabled} to disable the chunky menu sounds.')
    ;
  iGroup.AddToggle( 'heartbeat_sound', True )
    .SetName('Heartbeat')
    .SetDescription('Set to {!Disabled} to disable the low health heartbeat sound.')
    ;
  iGroup.AddToggle( 'wait_sound', True )
    .SetName('Wait sound')
    .SetDescription('Set to {!Disabled} to disable the wait action sound.')
    ;

  iGroup := AddGroup( 'gameplay' );
  iGroup.AddToggle( 'always_random_name', False )
    .SetName('Always random name')
    .SetDescription( 'Setting to {!Enabled} will skip name entry and always supply a random name.')
    ;
  iGroup.AddToggle( 'hide_hints', False )
    .SetName('Hide hints')
    .SetDescription('Setting to {!Enabled} will hide the hints in the top right corner.')
    ;
  iGroup.AddToggle( 'run_over_items', False )
    .SetName('Run over items')
    .SetDescription('Setting to {!Enabled} will make the run command not stop on items.')
    ;
  iGroup.AddToggle( 'group_messages', True )
    .SetName('Group messages')
    .SetDescription('Group repeated messages into (x{^3}) combos to save on doing "more...".')
    ;
  iGroup.AddToggle( 'unlock_all', False )
    .SetName('Unlock all unlocks')
    .SetDescription('For returning players so they don''t have to unlock everything again. Otherwise a cheat!')
    ;

  iGroup := AddGroup( 'input' );
  iGroup.AddToggle( 'empty_confirm', False )
    .SetName('Confirm firing empty weapon')
    .SetDescription('Setting to {!Enabled} will make the game wait for confirmation if trying to fire an empty weapon')
    ;
  iGroup.AddToggle( 'enable_mouse', True )
    .SetName('Mouse control')
    .SetDescription('Setting to {!Disabled} will turn off interaction and visuals of the mouse.')
    ;
  iGroup.AddToggle( 'mouse_edge_pan', False )
    .SetName('Screen edge mouse scroll')
    .SetDescription('Setting to {!Enabled} will make the screen scroll if the mouse is at the edge.')
    ;
  iGroup.AddToggle( 'enable_gamepad', True )
    .SetName('Gamepad control')
    .SetDescription('Setting to {!Disabled} will turn off interaction and visuals of the gamepad.')
    ;
  iGroup.AddToggle( 'enable_rumble', True )
    .SetName('Gamepad rumble')
    .SetDescription('Setting to {!Disabled} will turn off gamepad rumble effects.')
    ;

  iGroup := AddGroup( CONTROLLER_BINDINGS_GAMEPLAY_GROUP );
  FControllerBindings.RegisterGroup(iGroup, CONTROLLER_BINDING_INFO_GROUP);

  FUIKeyBindings.RegisterGroup(
    AddGroup( UI_KEY_BINDING_GROUP ), UI_KEY_BINDING_GROUP );
  FUIControllerBindings.RegisterGroup(
    AddGroup( UI_PAD_BINDING_GROUP ), UI_PAD_BINDING_GROUP );

  for iID in CInputGroups do
    FKeyBindings.RegisterGroup(AddGroup(iID), iID);

  FKeyBindings.ValidateRegistration;
  FControllerBindings.ValidateRegistration;
  FUIKeyBindings.ValidateRegistration;
  FUIControllerBindings.ValidateRegistration;
end;

destructor TDRLConfiguration.Destroy;
begin
  FreeAndNil(FUIControllerBindings);
  FreeAndNil(FUIKeyBindings);
  FreeAndNil(FControllerBindings);
  FreeAndNil(FKeyBindings);
  inherited Destroy;
end;

end.
