{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmoreview;
interface
uses vutil, viotypes, drlio, dfdata, dfbeing;

type TMoreView = class( TIOLayer )
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
  FTexts    : array[0..5] of TStringGArray;
end;

implementation

uses sysutils, vluasystem, vtig, dfplayer, dfitem, drlbase;

constructor TMoreView.Create( aBeing : TBeing );
var i : Integer;
begin
  VTIG_ResetScroll( 'more_view' );
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

procedure TMoreView.ReadTexts;
var iTot, iTor : Integer;
    iRes       : TResistance;
  procedure DescribeItem( aItem : TItem; var aStr : TStringGArray );
  var iBox    : Ansistring;
      iPos, i : Integer;
  begin
    if aItem = nil then Exit;
    aStr := TStringGArray.Create;
    aStr.Push( '{!'+aItem.Description+'}' );
    iBox := aItem.DescriptionBox( True );
    iPos := 1;
    if Length( iBox ) > 0 then
    begin
      for i := 1 to Length( iBox ) do
        if iBox[i] = #10 then
        begin
          aStr.Push( Copy(iBox, iPos, i - iPos) );
          iPos := i + 1;
        end;
      if iPos <= Length( iBox ) then aStr.Push( Copy( iBox, iPos, Length( iBox ) - iPos + 1) );
    end;
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
        then FTexts[1].Push( Format( Padded(ResNames[iRes],7)+' : {!%d%%}, torso {!%d%%}',[ iTot, iTor ] ) )
        else FTexts[1].Push( Format( Padded(ResNames[iRes],7)+' : {!%d%%}',[ iTot ] ) );
    end;
  end;
  if FBeing.Inv <> nil then
  begin
    DescribeItem( FBeing.Inv.Slot[ efWeapon ], FTexts[2] );
    DescribeItem( FBeing.Inv.Slot[ efTorso ],  FTexts[3] );
  end;
end;

procedure TMoreView.Update( aDTime : Integer; aActive : Boolean );
var iString : Ansistring;
    iCount  : Integer;
begin
  if not ModuleOption_FullBeingDescription then
  begin
    VTIG_PushStyle(@TIGStylePadless);
    VTIG_BeginWindow(FBeing.name, 'more_view', FSize );
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
    VTIG_BeginWindow(FBeing.name, 'more_view', FSize );
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
    if FTexts[2] <> nil then
    begin
      VTIG_Ruler;
      for iString in FTexts[2] do
        VTIG_Text( iString );
    end;
    if FTexts[3] <> nil then
    begin
      VTIG_Ruler;
      for iString in FTexts[3] do
        VTIG_Text( iString );
    end;
    VTIG_Scrollbar;
    VTIG_End('{l<{!{$input_up},{$input_down}}> scroll, <{!{$input_ok},{$input_escape}}> return}');
  end;

  if VTIG_EventCancel or VTIG_EventConfirm or VTIG_Event( TIG_EV_MORE ) then
    FFinished := True;
end;


function TMoreView.IsFinished : Boolean;
begin
  Exit( FFinished or ( DRL.State <> DSPlaying ) );
end;

function TMoreView.IsModal : Boolean;
begin
  Exit( True );
end;

destructor TMoreView.Destroy;
var i : Integer;
begin
  for i := Low( FTexts ) to High( FTexts ) do
    if FTexts[i] <> nil then
      FreeAndNil( FTexts[i] );
end;

end.

