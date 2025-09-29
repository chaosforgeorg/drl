{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmessagesview;
interface
uses vutil, viotypes, vmessages, drlio, dfdata;

type TMessagesView = class( TIOLayer )
  constructor Create( aContent : TMessageBuffer );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
protected
  FContent  : TMessageBuffer;
  FSize     : TPoint;
  FFinished : Boolean;
  FFirst    : Boolean;
end;

implementation

uses sysutils, vtig;

constructor TMessagesView.Create( aContent : TMessageBuffer );
begin
  VTIG_EventClear;
  FSize      := Point( 80, 25 );
  FContent   := aContent;
  FFinished  := False;
  FFirst     := True;
end;

procedure TMessagesView.Update( aDTime : Integer; aActive : Boolean );
var i : Integer;
begin
  VTIG_PushStyle( @TIGStylePadless );
  VTIG_BeginWindow('Past messages', 'messages_view', FSize );
  VTIG_PopStyle();
  if FContent.Size > 0 then
    for i := 0 to FContent.Size-1 do
      if FContent[i] <> '' then
        VTIG_Text( FContent[i] );
  VTIG_Scrollbar( FFirst );

  if IO.IsGamepad
    then VTIG_End('{l<{!{$input_up},{$input_down}}> scroll, <{!{$input_ok},{$input_escape}}> continue}')
    else VTIG_End('{l<{!{$input_up},{$input_down},{$input_pgup},{$input_pgdn}}> scroll, <{!{$input_ok},{$input_escape}}> continue}');

  if FFirst then
  begin
    FFirst := False;
    Update( aDTime, aActive );
    Exit;
  end;

  if VTIG_EventCancel or VTIG_EventConfirm then
    FFinished := True;
end;


function TMessagesView.IsFinished : Boolean;
begin
  Exit( FFinished );
end;

function TMessagesView.IsModal : Boolean;
begin
  Exit( True );
end;

end.

