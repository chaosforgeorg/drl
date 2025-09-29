{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlrankupview;
interface
uses vutil, viotypes, dfdata;

type TRankUpView = class( TIOLayer )
  constructor Create( aRank : THOFRank );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
protected
  FFinished : Boolean;
  FSize     : TPoint;
  FLines    : array of Ansistring;
end;

implementation

uses sysutils, vluasystem, vtig;

constructor TRankUpView.Create( aRank : THOFRank );
var i, i2 : Integer;
    iSize : Integer;
    iUnl  : Integer;
    iRank : Ansistring;
    iDesc : Ansistring;
begin
  VTIG_EventClear;
  FSize      := Point( 80, 25 );
  iSize := 0;
  SetLength( FLines, 200 );
  for i := 0 to High( aRank.Data ) do
    if aRank.Data[i].Value <> 0 then
    begin
      iRank := LuaSystem.Get(['ranks',aRank.Data[i].ID,aRank.Data[i].Value+1,'name'],'');
      iDesc := LuaSystem.Get(['ranks',aRank.Data[i].ID,'award'],'');
      FLines[iSize] := Format( iDesc, [iRank] );
      Inc( iSize );
      iUnl := LuaSystem.GetTableSize(['ranks',aRank.Data[i].ID,aRank.Data[i].Value+1,'unlocks']);
      if iUnl > 0 then
      begin
        FLines[iSize] := 'This unlocks the following features:';
        Inc( iSize );
        for i2 := 1 to iUnl do
        begin
          FLines[iSize] := ' * '+LuaSystem.Get(['ranks',aRank.Data[i].ID,aRank.Data[i].Value+1,'unlocks',i2]);
          Inc( iSize );
        end;
        FLines[iSize] := '';
        Inc( iSize );
      end;
    end;

  SetLength( FLines, iSize );
end;

procedure TRankUpView.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
begin
  VTIG_BeginWindow('Congratulations!', 'rank_up_view', FSize );

  for i := 0 to High( FLines ) do
    VTIG_FreeLabel( FLines[i], Point( 4, 6+i ) );

  VTIG_FreeLabel( 'Press <{!{$input_ok}}>...', Point( 12, 8+High( FLines ) ) );

  VTIG_End('{l<{!{$input_ok},{$input_escape}}> continue}');
  if VTIG_EventCancel or VTIG_EventConfirm then
    FFinished := True;
end;


function TRankUpView.IsFinished : Boolean;
begin
  Exit( FFinished );
end;

function TRankUpView.IsModal : Boolean;
begin
  Exit( True );
end;

end.

