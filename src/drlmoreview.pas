{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmoreview;
interface
uses vutil, viotypes, drlio, dfdata, dfbeing, dfitem, drlhooks;

type TMoreBeingView = class( TIOLayer )
  constructor Create( aBeing : TBeing );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
  destructor Destroy; override;
protected
  procedure ReadTexts;
protected
  FFinished : Boolean;
  FSize     : TPoint;
  FBeing    : TBeing;
  FDesc     : Ansistring;
  FASCII    : Ansistring;
  FTexts    : array[0..6] of TStringGArray;
end;

type TMoreItemView = class( TIOLayer )
  constructor Create( aItem : TItem );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
  destructor Destroy; override;
protected
  procedure ReadTexts;
protected
  FFinished : Boolean;
  FSize     : TPoint;
  FItem     : TItem;
  FTitle    : Ansistring;
  FDesc     : Ansistring;
  FTexts    : array[0..2] of TStringGArray;
end;

implementation

uses sysutils, vluasystem, vtig, dfplayer, drlbase, drlperk;

constructor TMoreBeingView.Create( aBeing : TBeing );
var i : Integer;
begin
  VTIG_ResetScroll( 'more_being_view' );
  VTIG_EventClear;
  FFinished := False;
  FBeing    := aBeing;
  FDesc     := LuaSystem.Get(['beings',FBeing.ID,'desc']);
  FASCII    := '';
  if not ModuleOption_FullBeingDescription then
    if FBeing.ID = 'soldier'
      then FASCII := Player.ASCIIMoreCode
      else FASCII := FBeing.ID;
  FSize      := Point( 80, 25 );
  for i := Low( FTexts ) to High( FTexts ) do
    FTexts[i] := nil;
  if ModuleOption_FullBeingDescription then
  begin
    FSize      := Point( 60, 25 );
    ReadTexts;
  end;
end;

procedure TMoreBeingView.ReadTexts;
var iTot, iTor : Integer;
    iRes       : TResistance;
    iCount, i  : Integer;
    iPerks     : TPerkList;
    iName      : Ansistring;
  procedure DescribeItem( aItem : TItem );
  var iBox    : Ansistring;
      iPos, i : Integer;
  begin
    if aItem = nil then Exit;
    FTexts[iCount] := TStringGArray.Create;
    FTexts[iCount].Push( '{!'+aItem.Description+'}' );
    iBox := aItem.DescriptionBox( True );
    iPos := 1;
    if Length( iBox ) > 0 then
    begin
      for i := 1 to Length( iBox ) do
        if iBox[i] = #10 then
        begin
          FTexts[iCount].Push( Copy(iBox, iPos, i - iPos) );
          iPos := i + 1;
        end;
      if iPos <= Length( iBox ) then FTexts[iCount].Push( Copy( iBox, iPos, Length( iBox ) - iPos + 1) );
    end;
    Inc( iCount );
  end;

begin
  FTexts[0] := TStringGArray.Create;
  FTexts[0].Push( Format( 'Health     : {!{R%d}/%d}',[ FBeing.HP, FBeing.HPMax ] ) );
  FTexts[0].Push( Format( 'Armor      : {!%d}',[ FBeing.Armor ] ) );
  FTexts[0].Push( Format( 'Speed      : {!%d%%}',[ FBeing.Speed ] ) );
  FTexts[0].Push( Format( 'Accuracy   : {!%d}',[ FBeing.Accuracy ] ) );
  FTexts[0].Push( Format( 'Strength   : {!%d} (xd3 damage)',[ (FBeing.Strength + 1) ] ) );
  FTexts[0].Push( Format( 'Experience : {!%d}',[ FBeing.ExpValue ] ) );
  FTexts[0].Push( Format( 'Vision     : {!%d}',[ FBeing.Vision ] ) );

  FTexts[1] := TStringGArray.Create;
  for iRes := Low(TResistance) to High(TResistance) do
  begin
    iTot  := FBeing.getTotalResistance(ResIDs[iRes],TARGET_INTERNAL);
    iTor  := FBeing.getTotalResistance(ResIDs[iRes],TARGET_TORSO);
    if (iTot <> 0) or (iTor <> 0) then
    begin
      if (iTot <> iTor)
        then FTexts[1].Push( Padded(ResNames[iRes],7)+' : '+ResistStr(iTot)+', torso '+ResistStr(iTor) )
        else FTexts[1].Push( Padded(ResNames[iRes],7)+' : '+ResistStr(iTot) );
    end;
  end;
  iCount := 2;
  iPerks := FBeing.GetPerkList;
  if ( iPerks <> nil ) and ( iPerks.Size > 0 ) then
  begin
    for i := 0 to iPerks.Size - 1 do
      with PerkData[ iPerks[i].ID ] do
      if ( Desc <> '' ) and ( ColorExp <> 0 ) then
      begin
        if FTexts[iCount] = nil then
        begin
          FTexts[iCount] :=  TStringGArray.Create;
          FTexts[iCount].Push( '{!Status effects}' );
        end;
        iName := Name;
        if iName = '' then iName := Short;
        if iPerks[i].Time > 0
          then FTexts[iCount].Push( '  {' + VTIG_ColorChar( Color ) + iName + '} ({!' + FloatToStr( iPerks[i].Time / 10 ) + '}s) - ' + Desc )
          else FTexts[iCount].Push( '  {' + VTIG_ColorChar( Color ) + iName + '} - ' + Desc );
      end;
    if FTexts[iCount] <> nil then Inc( iCount );
  end;

  if ( iPerks <> nil ) and ( iPerks.Size > 0 ) then
  begin
    for i := 0 to iPerks.Size - 1 do
      with PerkData[ iPerks[i].ID ] do
      if ( Desc <> '' ) and ( ColorExp = 0 ) then
      begin
        if FTexts[iCount] = nil then
        begin
          FTexts[iCount] :=  TStringGArray.Create;
          FTexts[iCount].Push( '{!Permanents}' );
        end;
        FTexts[iCount].Push( '  {' + VTIG_ColorChar( Color ) + Name + '} - ' + Desc );
      end;
    if FTexts[iCount] <> nil then Inc( iCount );
  end;

  if FBeing.Inv <> nil then
  begin
    DescribeItem( FBeing.Inv.Slot[ efWeapon ] );
    DescribeItem( FBeing.Inv.Slot[ efTorso ] );
  end;
end;

procedure TMoreBeingView.Update( aDTime : Integer; aActive : Boolean );
var iString : Ansistring;
    iCount  : Integer;
begin
  if not ModuleOption_FullBeingDescription then
  begin
    VTIG_PushStyle(@TIGStylePadless);
    VTIG_BeginWindow(FBeing.name, 'more_being_view', FSize );
    VTIG_PopStyle();
    iCount := 0;
    if IO.Ascii.Exists(FASCII) then
      for iString in IO.Ascii[FASCII] do
      begin
        VTIG_FreeLabel( iString, Point( 2, iCount ) );
        Inc( iCount );
      end
    else
      VTIG_FreeLabel( 'Picture'#10'N/A', Point( 10, 10 ), LightRed );

    VTIG_BeginWindow(FBeing.name, Point( 38, -1 ), Point( 40,11 ) );
    VTIG_Text( FDesc );
    VTIG_End;
    VTIG_End('{l<{!{$input_escape}},{!{$input_ok}}> exit}');
  end
  else
  begin
    VTIG_BeginWindow(FBeing.name, 'more_being_view', FSize );
    VTIG_Text( FDesc );
    VTIG_Ruler;
    for iString in FTexts[0] do
      VTIG_Text( iString );
    if FTexts[1].Size > 0 then
    begin
      VTIG_Ruler;
      VTIG_Text( '{!Resistances}' );
      for iString in FTexts[1] do
        VTIG_Text( iString );
    end;
    for iCount := 2 to High( FTexts ) do
      if FTexts[iCount] <> nil then
      begin
        VTIG_Ruler;
        for iString in FTexts[iCount] do
          VTIG_Text( iString );
      end;
    VTIG_Scrollbar;
    VTIG_End('{l<{!{$input_up},{$input_down}}> scroll, <{!{$input_ok},{$input_escape}}> return}');
  end;

  if VTIG_EventCancel or VTIG_EventConfirm or VTIG_Event( TIG_EV_MORE ) then
    FFinished := True;
end;


function TMoreBeingView.IsFinished : Boolean;
begin
  Exit( FFinished or ( DRL.State <> DSPlaying ) );
end;

function TMoreBeingView.IsModal : Boolean;
begin
  Exit( True );
end;

destructor TMoreBeingView.Destroy;
var i : Integer;
begin
  for i := Low( FTexts ) to High( FTexts ) do
    if FTexts[i] <> nil then
      FreeAndNil( FTexts[i] );
end;

{ TMoreItemView }

constructor TMoreItemView.Create( aItem : TItem );
var i : Integer;
begin
  VTIG_ResetScroll( 'more_item_view' );
  VTIG_EventClear;
  FFinished := False;
  FItem     := aItem;
  FDesc     := LuaSystem.Get(['items',FItem.ID,'desc']);
  FSize     := Point( 60, 25 );
  FTitle    := '{'+VTIG_ColorChar( FItem.MenuColor ) + FItem.Description + '}';
  for i := Low( FTexts ) to High( FTexts ) do
    FTexts[i] := nil;
  ReadTexts;
end;

procedure TMoreItemView.ReadTexts;
var iPerks     : TPerkList;
    iHasFire   : Boolean;
    i          : Integer;
    iStatQueue : TStringGArray;
  procedure AddStat( const aName : Ansistring; const aValue : Ansistring );
  begin
    iStatQueue.Push( Padded( aName, 13 ) + ': {!' + aValue + '}' );
  end;
  procedure FlushStats;
  var iLine : Ansistring;
      iIdx  : Integer;
  begin
    iIdx := 0;
    while iIdx + 1 < iStatQueue.Size do
    begin
      iLine := Padded( iStatQueue[iIdx], 29 ) + ' ' + iStatQueue[iIdx + 1];
      FTexts[0].Push( iLine );
      iIdx += 2;
    end;
    if iIdx < iStatQueue.Size then
      FTexts[0].Push( iStatQueue[iIdx] );
    iStatQueue.Clear;
  end;
begin
  // Stats
  FTexts[0] := TStringGArray.Create;
  iStatQueue := TStringGArray.Create;
  
  case FItem.IType of
    ITEMTYPE_ARMOR, ITEMTYPE_BOOTS :
    begin
      AddStat( 'Durability', IntToStr(FItem.MaxDurability) );
      AddStat( 'Swap time', Seconds(FItem.SwapTime) );
    end;
    ITEMTYPE_URANGED :
    begin
      AddStat( 'Damage type', DamageTypeName(FItem.DamageType) );
      AddStat( 'Expl.radius', IntToStr(FItem.Radius) );
    end;
    ITEMTYPE_RANGED, ITEMTYPE_NRANGED :
    begin
      AddStat( 'Fire time', Seconds(FItem.UseTime) );
      AddStat( 'Reload time', Seconds(FItem.ReloadTime) );
      AddStat( 'Swap time', Seconds(FItem.SwapTime) );
      AddStat( 'Accuracy', BonusStr(FItem.Acc) );
      AddStat( 'Damage type', DamageTypeName(FItem.DamageType) );
      AddStat( 'Shots', IntToStr(FItem.Shots) );
      AddStat( 'Shot cost', IntToStr(FItem.ShotCost) );
      AddStat( 'Expl.radius', IntToStr(FItem.Radius) );
      AddStat( 'Dmg. falloff', IntToStr(FItem.Falloff)+'%' );
      AddStat( 'Cone size', IntToStr(FItem.Spread) );
      AddStat( 'Max range', IntToStr(FItem.Range) );
      if FItem.HasHook( Hook_OnAltFire ) then
        AddStat( 'Alt. fire', FItem.GetAltFireName );
      if FItem.HasHook( Hook_OnAltReload ) then
        AddStat( 'Alt. reload', FItem.GetAltReloadName );
    end;
    ITEMTYPE_MELEE :
    begin
      AddStat( 'Attack time', Seconds(FItem.UseTime) );
      AddStat( 'Swap time', Seconds(FItem.SwapTime) );
      AddStat( 'Accuracy', BonusStr(FItem.Acc) );
      AddStat( 'Damage type', DamageTypeName(FItem.DamageType) );
      if FItem.HasHook( Hook_OnAltFire ) then
        AddStat( 'Alt. fire', FItem.GetAltFireName );
    end;
  end;

  // Common stats
  AddStat( 'Move speed', Percent(FItem.MoveMod) );
  AddStat( 'Knockback', Percent(FItem.KnockMod) );
  AddStat( 'Dodge rate', Percent(FItem.DodgeMod) );

  FlushStats;
  
  // Resistances
  if FItem.GetResistance('bullet') <> 0 then
    AddStat( 'Bullet res.', BonusStr(FItem.GetResistance('bullet')) );
  if FItem.GetResistance('melee') <> 0 then
    AddStat( 'Melee res.', BonusStr(FItem.GetResistance('melee')) );
  if FItem.GetResistance('shrapnel') <> 0 then
    AddStat( 'Shrapnel res', BonusStr(FItem.GetResistance('shrapnel')) );
  if FItem.GetResistance('acid') <> 0 then
    AddStat( 'Acid res.', BonusStr(FItem.GetResistance('acid')) );
  if FItem.GetResistance('fire') <> 0 then
    AddStat( 'Fire res.', BonusStr(FItem.GetResistance('fire')) );
  if FItem.GetResistance('plasma') <> 0 then
    AddStat( 'Plasma res.', BonusStr(FItem.GetResistance('plasma')) );
  if FItem.GetResistance('cold') <> 0 then
    AddStat( 'Cold res.', BonusStr(FItem.GetResistance('cold')) );
  if FItem.GetResistance('poison') <> 0 then
    AddStat( 'Poison res.', BonusStr(FItem.GetResistance('poison')) );
  
  if iStatQueue.Size > 0 then
  begin
    FTexts[0].Push( '' ); // Empty line before resistances
    FlushStats;
  end;
  
  FreeAndNil( iStatQueue );

  iPerks := FItem.GetPerkList;
  if ( iPerks <> nil ) and ( iPerks.Size > 0 ) then
  begin
    iHasFire := False;
    // Alt-fire perk (shown separately with description)
    if FItem.HasHook( Hook_OnAltFire ) then
      for i := 0 to iPerks.Size - 1 do
        with PerkData[ iPerks[i].ID ] do
          if Hook_OnAltFire in Hooks then
          begin
            FTexts[0].Push( '' );
            FTexts[0].Push( 'Alt. fire    : {!' + Desc + '}' );
            iHasFire := True;
            break;
          end;

    // Alt-reload perk (shown separately with description)
    if FItem.HasHook( Hook_OnAltReload ) then
      for i := 0 to iPerks.Size - 1 do
        with PerkData[ iPerks[i].ID ] do
          if Hook_OnAltReload in Hooks then
          begin
            if not iHasFire then FTexts[0].Push( '' );
            FTexts[0].Push( 'Alt. reload  : {!' + Desc + '}' );
            break;
          end;

    FTexts[1] := TStringGArray.Create;
    for i := 0 to iPerks.Size - 1 do
      with PerkData[ iPerks[i].ID ] do
        if ( Name <> '' ) and ( Desc <> '' ) then
          FTexts[1].Push( '{' + VTIG_ColorChar( Color ) + Name + '} - ' + Desc );
  end;
end;

procedure TMoreItemView.Update( aDTime : Integer; aActive : Boolean );
var iString : Ansistring;
begin
  VTIG_BeginWindow(FTitle, 'more_item_view', FSize );
  VTIG_Text( FDesc );
  VTIG_Ruler;
  if FTexts[0] <> nil then
    for iString in FTexts[0] do
      VTIG_Text( iString );
  if FTexts[1] <> nil then
  begin
    VTIG_Ruler;
    for iString in FTexts[1] do
      VTIG_Text( iString );
  end;
  VTIG_Scrollbar;
  VTIG_End('{l<{!{$input_up},{$input_down}}> scroll, <{!{$input_ok},{$input_escape}}> return}');

  if VTIG_EventCancel or VTIG_EventConfirm or VTIG_Event( TIG_EV_MORE ) then
  begin
    VTIG_EventClear;
    FFinished := True;
  end;
end;

function TMoreItemView.IsFinished : Boolean;
begin
  Exit( FFinished or ( DRL.State <> DSPlaying ) );
end;

function TMoreItemView.IsModal : Boolean;
begin
  Exit( True );
end;

destructor TMoreItemView.Destroy;
var i : Integer;
begin
  for i := Low( FTexts ) to High( FTexts ) do
    if FTexts[i] <> nil then
      FreeAndNil( FTexts[i] );
end;

end.

