{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmultimove;
interface
uses classes, vnode, vrltools, vpath, drlkeybindings;

type TMultiMove = class( TVObject )
  constructor Create;
  procedure Stop;
  // A directional run; with aStopOnItems it stops on cells holding items.
  procedure Start( const aDir : TDirection; aStopOnItems : Boolean );
  procedure Start( aPath : TPathfinder );
  function IsRepeat : Boolean;
  function IsPath   : Boolean;
  function CalculateInput( const aPosition : TCoord2D ) : TInputKey;
private
  FActive      : Boolean;
  FCount       : Word;
  FPath        : TPathFinder;
  FDir         : TDirection;
  FStopOnItems : Boolean;
public
  property Active      : Boolean read FActive;
  property StopOnItems : Boolean read FStopOnItems;
end;

implementation

uses dfdata;

// Steps a run or a repeated wait takes before stopping on its own.
const MaxRunSteps  = 100;
      MaxWaitSteps = 20;

{ TRunData }

constructor TMultiMove.Create;
begin
  FCount  := 0;
  FActive := False;
  FPath   := nil;
end;

procedure TMultiMove.Stop;
begin
  FCount  := 0;
  FActive := False;
  FPath   := nil;
end;

procedure TMultiMove.Start( const aDir : TDirection; aStopOnItems : Boolean );
begin
  FActive      := True;
  FCount       := 0;
  FDir         := aDir;
  FStopOnItems := aStopOnItems;
  FPath        := nil;
end;

procedure TMultiMove.Start( aPath : TPathfinder );
begin
  FCount       := 0;
  FActive      := True;
  FPath        := aPath;
  FStopOnItems := False;
  FPath.Start  := FPath.Start.Child;
end;

function TMultiMove.IsRepeat : Boolean;
begin
  Exit( FActive and ( FPath = nil ) );
end;

function TMultiMove.IsPath   : Boolean;
begin
  Exit( Assigned( FPath ) );
end;

function TMultiMove.CalculateInput( const aPosition : TCoord2D ) : TInputKey;
var iDir : TDirection;
begin
  Inc( FCount );
  if Assigned( FPath ) then
  begin
    if (not FPath.Found) or (FPath.Start = nil) or (FPath.Start.Coord = aPosition) then
    begin
      Stop;
      Exit( INPUT_NONE );
    end;
    iDir := NewDirection( aPosition, FPath.Start.Coord );
    FPath.Start := FPath.Start.Child;
  end
  else
  begin
    iDir := FDir;
    if iDir.code = 5 then
    begin
      if FCount >= MaxWaitSteps then Stop;
    end
    else
      if FCount >= MaxRunSteps then Stop;
  end;
  Exit( DirectionToInput( iDir ) );
end;

end.

