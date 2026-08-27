{$INCLUDE drl.inc}
unit drluibindings;
interface
uses vbindings, vioevent, vtigio;

const UI_KEY_BINDING_GROUP = 'ui_bindings_keyboard';
      UI_PAD_BINDING_GROUP = 'ui_bindings_controller';

      UI_BINDING_DROP = 1;
      UI_BINDING_SWAP = 8;

const UIKeyBindingInfo : array[0..12] of TBindingInfo = (
  ( Action: VTIG_IE_UP;        ID: 'ui_keyboard_up';        Group: UI_KEY_BINDING_GROUP; Default: VKEY_UP;     Name: 'Up';        Description: 'Move the UI selection or view up.' ),
  ( Action: VTIG_IE_DOWN;      ID: 'ui_keyboard_down';      Group: UI_KEY_BINDING_GROUP; Default: VKEY_DOWN;   Name: 'Down';      Description: 'Move the UI selection or view down.' ),
  ( Action: VTIG_IE_LEFT;      ID: 'ui_keyboard_left';      Group: UI_KEY_BINDING_GROUP; Default: VKEY_LEFT;   Name: 'Left';      Description: 'Move the UI selection or tab left.' ),
  ( Action: VTIG_IE_RIGHT;     ID: 'ui_keyboard_right';     Group: UI_KEY_BINDING_GROUP; Default: VKEY_RIGHT;  Name: 'Right';     Description: 'Move the UI selection or tab right.' ),
  ( Action: VTIG_IE_HOME;      ID: 'ui_keyboard_home';      Group: UI_KEY_BINDING_GROUP; Default: VKEY_HOME;   Name: 'Home';      Description: 'Move to the start of a UI list or view.' ),
  ( Action: VTIG_IE_END;       ID: 'ui_keyboard_end';       Group: UI_KEY_BINDING_GROUP; Default: VKEY_END;    Name: 'End';       Description: 'Move to the end of a UI list or view.' ),
  ( Action: VTIG_IE_PGUP;      ID: 'ui_keyboard_page_up';   Group: UI_KEY_BINDING_GROUP; Default: VKEY_PGUP;   Name: 'Page up';   Description: 'Move a UI view up by one page.' ),
  ( Action: VTIG_IE_PGDOWN;    ID: 'ui_keyboard_page_down'; Group: UI_KEY_BINDING_GROUP; Default: VKEY_PGDOWN; Name: 'Page down'; Description: 'Move a UI view down by one page.' ),
  ( Action: VTIG_IE_CANCEL;    ID: 'ui_keyboard_cancel';    Group: UI_KEY_BINDING_GROUP; Default: VKEY_ESCAPE; Name: 'Cancel';    Description: 'Cancel or leave the current UI.' ),
  ( Action: VTIG_IE_CONFIRM;   ID: 'ui_keyboard_confirm';   Group: UI_KEY_BINDING_GROUP; Default: VKEY_ENTER;  Name: 'Confirm';   Description: 'Confirm the current UI selection.' ),
  ( Action: VTIG_IE_SELECT;    ID: 'ui_keyboard_select';    Group: UI_KEY_BINDING_GROUP; Default: VKEY_SPACE;  Name: 'Select';    Description: 'Select the current UI entry.' ),
  ( Action: UI_BINDING_DROP;   ID: 'ui_keyboard_drop';      Group: UI_KEY_BINDING_GROUP; Default: VKEY_BACK;   Name: 'Drop item'; Description: 'Drop the selected inventory or equipment item.' ),
  ( Action: UI_BINDING_SWAP;   ID: 'ui_keyboard_swap';      Group: UI_KEY_BINDING_GROUP; Default: VKEY_TAB;    Name: 'Swap item'; Description: 'Swap the selected equipment slot.' )
);

const UIPadBindingInfo : array[0..7] of TBindingInfo = (
  ( Action: VTIG_IE_UP;        ID: 'ui_controller_up';      Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_DPAD_UP);    Name: 'Up';        Description: 'Move the UI selection or view up.' ),
  ( Action: VTIG_IE_DOWN;      ID: 'ui_controller_down';    Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_DPAD_DOWN);  Name: 'Down';      Description: 'Move the UI selection or view down.' ),
  ( Action: VTIG_IE_LEFT;      ID: 'ui_controller_left';    Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_DPAD_LEFT);  Name: 'Left';      Description: 'Move the UI selection or tab left.' ),
  ( Action: VTIG_IE_RIGHT;     ID: 'ui_controller_right';   Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_DPAD_RIGHT); Name: 'Right';     Description: 'Move the UI selection or tab right.' ),
  ( Action: VTIG_IE_CANCEL;    ID: 'ui_controller_cancel';  Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_B);          Name: 'Cancel';    Description: 'Cancel or leave the current UI.' ),
  ( Action: VTIG_IE_CONFIRM;   ID: 'ui_controller_confirm'; Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_A);          Name: 'Confirm';   Description: 'Confirm the current UI selection.' ),
  ( Action: UI_BINDING_DROP;   ID: 'ui_controller_drop';    Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_Y);          Name: 'Drop item'; Description: 'Drop the selected inventory or equipment item.' ),
  ( Action: UI_BINDING_SWAP;   ID: 'ui_controller_swap';    Group: UI_PAD_BINDING_GROUP; Default: Ord(VPAD_BUTTON_X);          Name: 'Swap item'; Description: 'Swap the selected equipment slot.' )
);

implementation

end.
