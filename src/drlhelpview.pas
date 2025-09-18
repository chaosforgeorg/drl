{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlhelpview;
interface
uses vutil, viotypes, drlio, drlhelp, dfdata;

type THelpView = class( TIOLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
  destructor Destroy; override;
protected
  procedure UpdateRead;
  procedure UpdateMenu;
protected
  FMode    : ( HELPVIEW_MENU, HELPVIEW_READ, HELPVIEW_DONE );
  FCurrent : Byte;
  FSize    : TPoint;
  FRect    : TRectangle;
  FList    : THelpArray;
  FEntries : TStringGArray
end;

implementation

uses sysutils, vtig, vluasystem;

constructor THelpView.Create;
var iTable : TLuaTable;
begin
  VTIG_EventClear;
  VTIG_ResetSelect( 'help_view' );

  FSize    := Point( 80, 25 );
  FMode    := HELPVIEW_MENU;
  FCurrent := 0;

  FList    := THelpArray.Create( False );
  FEntries := TStringGArray.Create;

  if not LuaSystem.Defined([CoreModuleID,'help']) then Exit;
  with LuaSystem.GetTable([CoreModuleID]) do
  try
    for iTable in ITables('help') do
    begin
      FList.Push( Help[iTable.GetValue(1)] );
      FEntries.Push( iTable.GetValue(2) );
    end;
  finally
    Free;
  end;
end;

procedure THelpView.Update( aDTime : Integer; aActive : Boolean );
begin
       if FMode = HELPVIEW_MENU then UpdateMenu
  else if FMode = HELPVIEW_READ then UpdateRead;
end;

function THelpView.IsFinished : Boolean;
begin
  Exit( FMode = HELPVIEW_DONE );
end;

function THelpView.IsModal : Boolean;
begin
  Exit( True );
end;

destructor THelpView.Destroy;
begin
  FreeAndNil( FList );
  FreeAndNil( FEntries );
end;

procedure THelpView.UpdateRead;
var iText : Ansistring;
begin
  VTIG_BeginWindow( FEntries[FCurrent], 'help_view_read', FSize );
  for iText in FList[FCurrent].Text do
    VTIG_Text( iText );
  VTIG_Scrollbar;
  FRect := VTIG_GetWindowRect;
  VTIG_End('{l<{!{$input_up},{$input_down}}> scroll, <{!{$input_ok},{$input_escape}}> return}');
  if VTIG_EventCancel or VTIG_EventConfirm then
    FMode := HELPVIEW_MENU;
end;

procedure THelpView.UpdateMenu;
var i,iSelect : Integer;

begin
  if FList.Size = 0 then
  begin
    FMode := HELPVIEW_DONE;
    Exit;
  end;
  VTIG_BeginWindow( 'Help topics', 'help_view', FSize );
  iSelect := 0;

  for i := 1 to FList.Size-1 do
    if VTIG_Selectable( '      '+FEntries[i] ) then
       iSelect := i;
  if VTIG_Selectable(   '      '+'Quit help' ) then
     FMode := HELPVIEW_DONE;

  VTIG_Ruler;

  if IO.IsGamepad then
  begin
    VTIG_Text('Select help topic above. Quick controls primer:');
    VTIG_Text('');
    VTIG_Text('Movement is done by moving the {!Left Stick} to the desired direction and confirming it with the {!A} button.');
    VTIG_Text('  {!A}     -- move   ( with {!RTrigger} - move targeting reticule )' );
    VTIG_Text('  {!B}     -- pickup item or activate stairs/lever');
    VTIG_Text('           + {!RTrigger} - use item from ground');
    VTIG_Text('           + {!LStick}   - direction action (open/close door)');
    VTIG_Text('  {!X}     -- fire   ( with {!RTrigger} - alt-fire )' );
    VTIG_Text('  {!Y}     -- reload ( with {!RTrigger} - alt-reload )' );
    VTIG_Text('  {!Start} -- character screens (inventory, etc)' );
    VTIG_Text('  ...      -- see "Controller" entry for the rest');
  end
  else
  begin
    VTIG_Text('Select help topic above. Quick (default) keybindings primer:');
    VTIG_Text('');
    VTIG_Text('  {!Escape}    - game menu (Save, Quit, Settings, Help, etc)');
    VTIG_Text('  {!Arrows}    - movement (Home,End,PgUp,PgDown - diagonals)');
    VTIG_Text('  {!W}         - wait (pass turn)');
    VTIG_Text('  {!SPACE}     - action (open,close,press button,descend stairs)');
    VTIG_Text('  {!I},{!E},{!P},{!T}   - inventory, equipment etc (left/right to switch while open)');
    VTIG_Text('  {!F}         - fire weapon (SHIFT for alternative mode)');
    VTIG_Text('  {!R}         - reload weapon (SHIFT for alternative mode)');
    VTIG_Text('  {!G}         - get item (pickup) from floor (SHIFT to use)');
    VTIG_Text('  ...          see "Controls" entry for the rest');
  end;

  FRect := VTIG_GetWindowRect;
  VTIG_End('{l<{!{$input_up},{$input_down}}> select, <{!{$input_ok}}> open, <{!{$input_escape}}> exit}');
  if iSelect > 0 then
  begin
    VTIG_ResetScroll( 'help_view_read' );
    FMode    := HELPVIEW_READ;
    FCurrent := iSelect;
  end;

  if VTIG_EventCancel then
     FMode := HELPVIEW_DONE;
end;

end.

