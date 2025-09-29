{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlchoiceview;
interface
uses viotypes, vgenerics, vutil, dfdata;

type TChoiceViewChoice = record
  Name    : AnsiString;
  Enabled : Boolean;
  Value   : Variant;
  Desc    : AnsiString;
end;

type TChoiceArray = specialize TGArray< TChoiceViewChoice >;

type TChoiceView = class( TIOLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
  procedure Add( const aEntry : TChoiceViewChoice );
  destructor Destroy; override;
protected
  FSize     : TPoint;
  FFinished : Boolean;
  FTitle    : AnsiString;
  FHeader   : AnsiString;
  FChoices  : TChoiceArray;
  FCancel   : Variant;
  FFirst    : Boolean;
  FEscape   : Boolean;
  FDelay    : Integer;
public
  property Title  : AnsiString read FTitle  write FTitle;
  property Header : AnsiString read FHeader write FHeader;
  property Cancel : Variant    read FCancel write FCancel;
  property Escape : Boolean    read FEscape write FEscape;
  property Delay  : Integer    read FDelay  write FDelay;
protected
  class var FResult : Variant;
public
  class property Result : Variant read FResult;
end;

implementation

uses sysutils, vdebug, vtig, drlbase;

constructor TChoiceView.Create;
begin
  VTIG_EventClear;
  VTIG_Reset( 'choice_menu' );
  VTIG_ResetSelect( 'choice_menu' );
  FSize     := Point( 50, -1 );
  FFinished := False;
  FTitle    := '';
  FHeader   := '';
  FCancel   := 0;
  FDelay    := 0;
  FEscape   := True;
  FChoices  := TChoiceArray.Create;
end;

procedure TChoiceView.Update( aDTime : Integer; aActive : Boolean );
var i : Byte;
begin
  if IsFinished then Exit;
  if FDelay > 0 then FDelay -= aDTime;
  if FTitle <> ''
    then VTIG_BeginWindow( FTitle, 'choice_menu', FSize )
    else VTIG_Begin('choice_menu', FSize );
  if FHeader <> '' then
  begin
    VTIG_Text( FHeader );
    VTIG_Text( '' );
  end;
  for i := 0 to FChoices.Size - 1 do
    if VTIG_Selectable( FChoices[i].Name, ( FDelay <= 0 ) and FChoices[i].Enabled ) then
        begin
          FFinished := True;
          FResult   := FChoices[i].Value;
        end;
  if FChoices[0].Desc <> '' then
  begin
    VTIG_Ruler;
    VTIG_Text( FChoices[VTIG_Selected].Desc );
  end;
  VTIG_End;

  if FEscape and VTIG_EventCancel then
  begin
    FFinished := True;
    FResult   := FCancel;
  end;
end;

function TChoiceView.IsFinished : Boolean;
begin
  Exit( FFinished or ( DRL.State <> DSPlaying ) );
end;

function TChoiceView.IsModal : Boolean;
begin
  Exit( True );
end;

procedure TChoiceView.Add( const aEntry : TChoiceViewChoice );
begin
  FChoices.Push( aEntry );
end;

destructor TChoiceView.Destroy;
begin
  FreeAndNil( FChoices );
  inherited Destroy;
end;

end.
