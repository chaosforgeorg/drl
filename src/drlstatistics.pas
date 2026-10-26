{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlstatistics;
interface
uses classes, vutil, vnode, dfdata, dfbeing;

type TStatistics = class(TVObject)
  constructor Create;
  constructor CreateFromStream( aStream : TStream ); override;
  procedure WriteToStream( aStream : TStream ); override;
  procedure Increase( const aStatisticID: AnsiString; aAmount : Integer = 1 );
  procedure Assign( const aStatisticID: AnsiString; aValue : Integer );
  procedure StartTimer;
  procedure Update( aPlayer : TBeing );
  procedure OnDamage( aPlayer : TBeing; aAmount : Integer );
  procedure OnLevelEnter;
  procedure OnSaveFile;
  procedure OnTick;
  function Get( const aKey : AnsiString ) : Integer;
  destructor Destroy; override;
private
  FMap           : TIntHashMap;
  FGameTime      : LongInt;
  FRealTime      : Comp;
  FRealTimeStart : Comp;
public
  property Items[ const aKey : AnsiString ] : Integer read Get; default;
  property GameTime : LongInt read FGameTime;
end;

implementation

uses sysutils, vgenerics, vmath, dfplayer;

{ TStatistics }

constructor TStatistics.CreateFromStream( aStream : TStream );
begin
  inherited CreateFromStream( aStream );
  FMap := TIntHashMap.CreateFromStream( aStream );
  aStream.Read( FGameTime, SizeOf( FGameTime ) );
  aStream.Read( FRealTime, SizeOf( FRealTime ) );
end;

procedure TStatistics.WriteToStream( aStream : TStream );
begin
  inherited WriteToStream( aStream );
  FMap.WriteToStream( aStream );
  aStream.Write( FGameTime, SizeOf( FGameTime ) );
  aStream.Write( FRealTime, SizeOf( FRealTime ) );
end;

constructor TStatistics.Create;
begin
  inherited Create;
  FMap        := TIntHashMap.Create( HashMap_NoRaise );
  FGameTime   := 0;
  FRealTime   := 0;
  FMap['min_health'] := 100;
end;

procedure TStatistics.Increase( const aStatisticID: AnsiString; aAmount: Integer = 1);
begin
  FMap[ aStatisticID ] := FMap[ aStatisticID ] + aAmount;
end;

procedure TStatistics.Assign( const aStatisticID: AnsiString; aValue : Integer );
begin
  FMap[ aStatisticID ] := aValue;
end;

procedure TStatistics.StartTimer;
begin
  FRealTimeStart := MSecNow();
end;

procedure TStatistics.Update( aPlayer : TBeing );
var iRealTime : Comp;
begin
  iRealTime := FRealTime + MSecNow() - FRealTimeStart;
  FMap['real_time']       := Round(iRealTime / 1000);
  FMap['real_time_ms']    := Round(iRealTime);
  FMap['game_time']       := FGameTime;
  with aPlayer as TPlayer do
  begin
    FMap['kills']           := FKills.Count;
    FMap['max_kills']       := FKills.MaxCount;
    FMap['unique_kills']    := FKillCount;
    FMap['max_unique_kills']:= FKillMax;
    FMap['kills_non_damage']:= Max( FMap['kills_non_damage'], FKills.NoDamageSequence );
  end;
end;

procedure TStatistics.OnDamage( aPlayer : TBeing; aAmount : Integer );
begin
  if aAmount < 0 then Exit;
  aAmount := Min( aAmount, 200 );
  with aPlayer as TPlayer do
  begin
    FMap['damage_taken']     := FMap['damage_taken']    + aAmount;
    FMap['damage_on_level']  := FMap['damage_on_level'] + aAmount;
    FMap['min_health']       := Min( FMap['min_health'], Max( HP - aAmount, 0 ) );
    FMap['kills_non_damage'] := Max( FMap['kills_non_damage'], FKills.BestNoDamageSequence );
  end;
end;

procedure TStatistics.OnLevelEnter;
begin
  FMap['damage_on_level'] := 0;
  FMap['entry_time'] := FGameTime;
end;

procedure TStatistics.OnSaveFile;
begin
  FRealTime += MSecNow() - FRealTimeStart;
  FMap[ 'save_count' ] := FMap[ 'save_count' ] + 1;
end;

procedure TStatistics.OnTick;
begin
  Inc( FGameTime );
end;

function TStatistics.Get( const aKey : AnsiString ) : Integer;
begin
  Exit( FMap[ aKey ] );
end;

destructor TStatistics.Destroy;
begin
  FreeAndNil( FMap );
  inherited Destroy;
end;

end.

