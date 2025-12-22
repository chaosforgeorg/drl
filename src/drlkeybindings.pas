{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlkeybindings;
interface

uses vioevent;

type TInputKey = (
  INPUT_NONE,           // Special value for none

  // Hidden keybindings
  INPUT_ESCAPE,
  INPUT_OK,

  // Movement keybindings
  INPUT_WALKLEFT,
  INPUT_WALKRIGHT,
  INPUT_WALKUP,
  INPUT_WALKDOWN,
  INPUT_WALKUPLEFT,
  INPUT_WALKUPRIGHT,
  INPUT_WALKDOWNLEFT,
  INPUT_WALKDOWNRIGHT,
  INPUT_WAIT,
  INPUT_RUN,

  // Run keybindings
  INPUT_RUNLEFT,
  INPUT_RUNRIGHT,
  INPUT_RUNUP,
  INPUT_RUNDOWN,
  INPUT_RUNUPLEFT,
  INPUT_RUNUPRIGHT,
  INPUT_RUNDOWNLEFT,
  INPUT_RUNDOWNRIGHT,
  INPUT_RUNWAIT,

  // Target keybindings
  INPUT_TARGETLEFT,
  INPUT_TARGETRIGHT,
  INPUT_TARGETUP,
  INPUT_TARGETDOWN,
  INPUT_TARGETUPLEFT,
  INPUT_TARGETUPRIGHT,
  INPUT_TARGETDOWNLEFT,
  INPUT_TARGETDOWNRIGHT,

  // Action keybindings
  INPUT_ACTION,
  INPUT_FIRE,
  INPUT_TARGET,
  INPUT_TARGETNEXT,
  INPUT_RELOAD,
  INPUT_PICKUP,
  INPUT_LOOKMODE,
  INPUT_SWAPWEAPON,
  INPUT_ACTIVE,
  INPUT_UNLOAD,
  INPUT_ALTPICKUP,
  INPUT_ALTFIRE,
  INPUT_ALTTARGET,
  INPUT_ALTRELOAD,

  // UI keybindings
  INPUT_HELP,
  INPUT_INVENTORY,
  INPUT_EQUIPMENT,
  INPUT_TRAITS,
  INPUT_PLAYERINFO,
  INPUT_MESSAGES,
  INPUT_ASSEMBLIES,
  INPUT_MORE,
  INPUT_MORESELF,

  // Helper keybindings
  INPUT_QUICKKEY_1,
  INPUT_QUICKKEY_2,
  INPUT_QUICKKEY_3,
  INPUT_QUICKKEY_4,
  INPUT_QUICKKEY_5,
  INPUT_QUICKKEY_6,
  INPUT_QUICKKEY_7,
  INPUT_QUICKKEY_8,
  INPUT_QUICKKEY_9,
  INPUT_SOUNDTOGGLE,
  INPUT_MUSICTOGGLE,
  INPUT_TOGGLEGRID,
  INPUT_EXAMINENPC,
  INPUT_EXAMINEITEM,

  // Legacy keybindings
  INPUT_LEGACYOPEN,
  INPUT_LEGACYCLOSE,
  INPUT_LEGACYDROP,
  INPUT_LEGACYUSE,
  INPUT_LEGACYSAVE,

  // Compat keys, remove?
  INPUT_QUIT,
  INPUT_HARDQUIT,

  // Compat keys, remove?
  INPUT_MMOVE,
  INPUT_MRIGHT,
  INPUT_MMIDDLE,
  INPUT_MLEFT,
  INPUT_MSCRUP,
  INPUT_MSCRDOWN
);

type TInputKeySet   = set of TInputKey;

type TKeyInfoEntry = record
    ID           : Ansistring;
    Group        : Ansistring;
    Default      : Integer;
    Name         : Ansistring;
    Description  : Ansistring;
end;

const KeyInfo : array[TInputKey] of TKeyInfoEntry = (
    // Special value for none
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: ''),

    // Hidden keybindings
    (ID: 'input_escape';         Group: 'keybindings_hidden';       Default: VKEY_ESCAPE;           Name: 'Escape';           Description: 'Escape'),
    (ID: 'input_ok';             Group: 'keybindings_hidden';       Default: VKEY_ENTER;            Name: 'Ok';               Description: 'Ok'),

    // Movement keybindings
    (ID: 'input_walkleft';       Group: 'keybindings_movement';     Default: VKEY_LEFT;             Name: 'Walk left';        Description: 'Keybind to walk left.'),
    (ID: 'input_walkright';      Group: 'keybindings_movement';     Default: VKEY_RIGHT;            Name: 'Walk right';       Description: 'Keybind to walk right.'),
    (ID: 'input_walkup';         Group: 'keybindings_movement';     Default: VKEY_UP;               Name: 'Walk up';          Description: 'Keybind to walk up.'),
    (ID: 'input_walkdown';       Group: 'keybindings_movement';     Default: VKEY_DOWN;             Name: 'Walk down';        Description: 'Keybind to walk down.'),
    (ID: 'input_walkupleft';     Group: 'keybindings_movement';     Default: VKEY_HOME;             Name: 'Walk up-left';     Description: 'Keybind to walk up and left.'),
    (ID: 'input_walkupright';    Group: 'keybindings_movement';     Default: VKEY_PGUP;             Name: 'Walk up-right';    Description: 'Keybind to walk up and right.'),
    (ID: 'input_walkdownleft';   Group: 'keybindings_movement';     Default: VKEY_END;              Name: 'Walk down-left';   Description: 'Keybind to walk down and left.'),
    (ID: 'input_walkdownright';  Group: 'keybindings_movement';     Default: VKEY_PGDOWN;           Name: 'Walk down-right';  Description: 'Keybind to walk down and right.'),
    (ID: 'input_wait';           Group: 'keybindings_movement';     Default: VKEY_W;                Name: 'Wait a turn';      Description: 'Keybind to wait in place.'),
    (ID: 'input_run';            Group: 'keybindings_movement';     Default: VKEY_COMMA;            Name: 'Repeat move mode'; Description: 'Enter repeat move mode (move until enemy appears or stopped).'),

    // Run keybindings
    (ID: 'input_runleft';       Group: 'keybindings_running';       Default: VKEY_LEFT + IOKeyCodeShiftMask;             Name: 'Multi-move left';        Description: 'Keybind to move left until blocked or enemy spotted.'),
    (ID: 'input_runright';      Group: 'keybindings_running';       Default: VKEY_RIGHT + IOKeyCodeShiftMask;            Name: 'Multi-move right';       Description: 'Keybind to move right until blocked or enemy spotted.'),
    (ID: 'input_runup';         Group: 'keybindings_running';       Default: VKEY_UP + IOKeyCodeShiftMask;               Name: 'Multi-move up';          Description: 'Keybind to move up until blocked or enemy spotted.'),
    (ID: 'input_rundown';       Group: 'keybindings_running';       Default: VKEY_DOWN + IOKeyCodeShiftMask;             Name: 'Multi-move down';        Description: 'Keybind to move down until blocked or enemy spotted.'),
    (ID: 'input_runupleft';     Group: 'keybindings_running';       Default: VKEY_HOME + IOKeyCodeShiftMask;             Name: 'Multi-move up-left';     Description: 'Keybind to move up and left until blocked or enemy spotted.'),
    (ID: 'input_runupright';    Group: 'keybindings_running';       Default: VKEY_PGUP + IOKeyCodeShiftMask;             Name: 'Multi-move up-right';    Description: 'Keybind to move up and right until blocked or enemy spotted.'),
    (ID: 'input_rundownleft';   Group: 'keybindings_running';       Default: VKEY_END + IOKeyCodeShiftMask;              Name: 'Multi-move down-left';   Description: 'Keybind to move down and left until blocked or enemy spotted.'),
    (ID: 'input_rundownright';  Group: 'keybindings_running';       Default: VKEY_PGDOWN + IOKeyCodeShiftMask;           Name: 'Multi-move down-right';  Description: 'Keybind to move down and right until blocked or enemy spotted.'),
    (ID: 'input_runwait';       Group: 'keybindings_running';       Default: VKEY_W + IOKeyCodeShiftMask;           Name: 'Multi-wait';             Description: 'Keybind to wait several turns or until enemy spotted.'),

    // Target keybindings (autoset)
    (ID: 'input_targetleft';       Group: 'keybindings_target';       Default: VKEY_LEFT + IOKeyCodeCtrlMask;             Name: 'Move target left';        Description: 'Keybind to move target left.'),
    (ID: 'input_targetright';      Group: 'keybindings_target';       Default: VKEY_RIGHT + IOKeyCodeCtrlMask;            Name: 'Move target right';       Description: 'Keybind to move target right.'),
    (ID: 'input_targetup';         Group: 'keybindings_target';       Default: VKEY_UP + IOKeyCodeCtrlMask;               Name: 'Move target up';          Description: 'Keybind to move target up.'),
    (ID: 'input_targetdown';       Group: 'keybindings_target';       Default: VKEY_DOWN + IOKeyCodeCtrlMask;             Name: 'Move target down';        Description: 'Keybind to move target down.'),
    (ID: 'input_targetupleft';     Group: 'keybindings_target';       Default: VKEY_HOME + IOKeyCodeCtrlMask;             Name: 'Move target up-left';     Description: 'Keybind to move target up and left.'),
    (ID: 'input_targetupright';    Group: 'keybindings_target';       Default: VKEY_PGUP + IOKeyCodeCtrlMask;             Name: 'Move target up-right';    Description: 'Keybind to move target up and right.'),
    (ID: 'input_targetdownleft';   Group: 'keybindings_target';       Default: VKEY_END + IOKeyCodeCtrlMask;              Name: 'Move target down-left';   Description: 'Keybind to move target down and left.'),
    (ID: 'input_targetdownright';  Group: 'keybindings_target';       Default: VKEY_PGDOWN + IOKeyCodeCtrlMask;           Name: 'Move target down-right';  Description: 'Keybind to move target down and right.'),

    // Action keybindings
    (ID: 'input_action';         Group: 'keybindings_actions';      Default: VKEY_SPACE;            Name: 'Action';           Description: 'Perform action (open/close door, descend stairs, press button).'),
    (ID: 'input_fire';           Group: 'keybindings_actions';      Default: VKEY_F;                Name: 'Fire';             Description: 'Fire your currently wielded weapon at current target.'),
    (ID: 'input_target';         Group: 'keybindings_actions';      Default: VKEY_T;                Name: 'Target';           Description: 'Pick target to fire your currently wielded weapon.'),
    (ID: 'input_targetnext';     Group: 'keybindings_actions';      Default: VKEY_TAB;              Name: 'Target next';      Description: 'Select next target.'),
    (ID: 'input_reload';         Group: 'keybindings_actions';      Default: VKEY_R;                Name: 'Reload';           Description: 'Reload currently held weapon.'),
    (ID: 'input_pickup';         Group: 'keybindings_actions';      Default: VKEY_G;                Name: 'Pickup';           Description: 'Pickup item from ground.'),
    (ID: 'input_lookmode';       Group: 'keybindings_actions';      Default: VKEY_L;                Name: 'Look mode';        Description: 'Look around.'),
    (ID: 'input_swapweapon';     Group: 'keybindings_actions';      Default: VKEY_Z;                Name: 'Swap weapon';      Description: 'Swap your current and prepared weapon.'),
    (ID: 'input_active';         Group: 'keybindings_actions';      Default: VKEY_X;                Name: 'Use active skill'; Description: 'Use active skill.'),
    (ID: 'input_unload';         Group: 'keybindings_actions';      Default: VKEY_U;                Name: 'Unload weapon';    Description: 'Unload weapon from ground (if present) or inventory.'),
    (ID: 'input_altpickup';      Group: 'keybindings_actions';      Default: VKEY_G + IOKeyCodeShiftMask; Name: 'Alternative pickup'; Description: 'Use item from ground if possible.'),
    (ID: 'input_altfire';        Group: 'keybindings_actions';      Default: VKEY_F + IOKeyCodeShiftMask; Name: 'Alternative fire';   Description: 'Use weapons alternative fire mode (if present).'),
    (ID: 'input_alttarget';      Group: 'keybindings_actions';      Default: VKEY_T + IOKeyCodeShiftMask; Name: 'Alternative target'; Description: 'Target and use weapons alternative fire mode (if present).'),
    (ID: 'input_altreload';      Group: 'keybindings_actions';      Default: VKEY_R + IOKeyCodeShiftMask; Name: 'Alternative reload'; Description: 'Use weapons alternative reload (if present).'),

    // UI keybindings
    (ID: 'input_help';           Group: 'keybindings_ui';           Default: VKEY_H;                Name: 'Show help screen'; Description: 'Open up help screen.'),
    (ID: 'input_inventory';      Group: 'keybindings_ui';           Default: VKEY_I;                Name: 'Show inventory screen'; Description: 'Open up inventory screen.'),
    (ID: 'input_equipment';      Group: 'keybindings_ui';           Default: VKEY_E;                Name: 'Show equipment screen'; Description: 'Open up equipment screen.'),
    (ID: 'input_trait';          Group: 'keybindings_ui';           Default: VKEY_Y;                Name: 'Show traits screen'; Description: 'Open up traits screen.'),
    (ID: 'input_playerinfo';     Group: 'keybindings_ui';           Default: VKEY_P;                Name: 'Show player screen'; Description: 'Open up player info screen.'),
    (ID: 'input_messages';       Group: 'keybindings_ui';           Default: VKEY_S;                Name: 'Show messages screen'; Description: 'Show log of previous messages.'),
    (ID: 'input_assemblies';     Group: 'keybindings_ui';           Default: VKEY_A;                Name: 'Show assemblies screen'; Description: 'Open up known assemblies screen.'),
    (ID: 'input_more';           Group: 'keybindings_ui';           Default: VKEY_M;                Name: 'More info on target'; Description: 'Open up target information screen.'),
    (ID: 'input_selfmore';       Group: 'keybindings_ui';           Default: VKEY_M + IOKeyCodeShiftMask; Name: 'More info on self'; Description: 'Open up target information screen for self.'),

    // Helper keybindings
    (ID: 'input_quickkey_1';     Group: 'keybindings_helper';       Default: VKEY_1;                Name: 'Quickkey 1';       Description: 'Mark and use quickslot 1.'),
    (ID: 'input_quickkey_2';     Group: 'keybindings_helper';       Default: VKEY_2;                Name: 'Quickkey 2';       Description: 'Mark and use quickslot 2.'),
    (ID: 'input_quickkey_3';     Group: 'keybindings_helper';       Default: VKEY_3;                Name: 'Quickkey 3';       Description: 'Mark and use quickslot 3.'),
    (ID: 'input_quickkey_4';     Group: 'keybindings_helper';       Default: VKEY_4;                Name: 'Quickkey 4';       Description: 'Mark and use quickslot 4.'),
    (ID: 'input_quickkey_5';     Group: 'keybindings_helper';       Default: VKEY_5;                Name: 'Quickkey 5';       Description: 'Mark and use quickslot 5.'),
    (ID: 'input_quickkey_6';     Group: 'keybindings_helper';       Default: VKEY_6;                Name: 'Quickkey 6';       Description: 'Mark and use quickslot 6.'),
    (ID: 'input_quickkey_7';     Group: 'keybindings_helper';       Default: VKEY_7;                Name: 'Quickkey 7';       Description: 'Mark and use quickslot 7.'),
    (ID: 'input_quickkey_8';     Group: 'keybindings_helper';       Default: VKEY_8;                Name: 'Quickkey 8';       Description: 'Mark and use quickslot 8.'),
    (ID: 'input_quickkey_9';     Group: 'keybindings_helper';       Default: VKEY_9;                Name: 'Quickkey 9';       Description: 'Mark and use quickslot 9.'),
    (ID: 'input_soundtoggle';    Group: 'keybindings_helper';       Default: 0;                     Name: 'Sound toggle';     Description: 'Quickly toggle sound on and off.'),
    (ID: 'input_musictoggle';    Group: 'keybindings_helper';       Default: 0;                     Name: 'Music toggle';     Description: 'Quickly toggle music on and off.'),
    (ID: 'input_togglegrid';     Group: 'keybindings_helper';       Default: 0;                     Name: 'Toggle grid visibility'; Description: 'Toggle visibility of helper grid overlay.'),
    (ID: 'input_examinenpc';     Group: 'keybindings_helper';       Default: 0;                     Name: 'Examine NPCs';     Description: '(blind mode) List in message box all visible NPCs.'),
    (ID: 'input_examineitem';    Group: 'keybindings_helper';       Default: 0;                     Name: 'Examine Items';    Description: '(blind mode) List in message box all visible Items.'),

    // Legacy keybindings
    (ID: 'input_legacyopen';     Group: 'keybindings_legacy';       Default: 0;                     Name: 'Open door';        Description: 'Dedicated open door key. Action key is the default method.'),
    (ID: 'input_legacyclose';    Group: 'keybindings_legacy';       Default: 0;                     Name: 'Close door';       Description: 'Dedicated close door key. Action key is the default method.'),
    (ID: 'input_legacydrop';     Group: 'keybindings_legacy';       Default: 0;                     Name: 'Drop item';        Description: 'Dedicated drop item key, opening inventory to select item to drop.'),
    (ID: 'input_legacyuse';      Group: 'keybindings_legacy';       Default: 0;                     Name: 'Use item';         Description: 'Dedicated use item key, opening inventory to select item to use.'),
    (ID: 'input_legacysave';     Group: 'keybindings_legacy';       Default: 0;                     Name: 'Save game';        Description: 'Dedicated save game key.'),

    // compat keys
    (ID: 'input_legacyquit';     Group: 'keybindings_legacy';       Default: 0;                     Name: 'Quit game';        Description: 'Dedicated quit game key.'),
    (ID: 'input_legacyhardquit'; Group: 'keybindings_legacy';       Default: 0;                     Name: 'Hard quit game';   Description: 'Dedicated hard quit game key (no confirmation).'),

    // compat keys
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: ''),
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: ''),
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: ''),
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: ''),
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: ''),
    (ID: '';                     Group: '';                        Default: 0;                     Name: '';                 Description: '')
);
implementation

end.

