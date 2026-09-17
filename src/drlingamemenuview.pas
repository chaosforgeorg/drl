{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlingamemenuview;
interface
uses viotypes,
     dfhof, drlio, drlconfirmview, dfdata, drlhelp;

type TInGameMenuView = class( TIOLayer )
  constructor Create( aHOF : THOF; aHelp : THelp );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
private
  FHOF  : THOF;
  FHelp : THelp;
end;

type TAbandonView = class( TConfirmView )
  constructor Create;
protected
  procedure OnConfirm; override;
  procedure OnCancel; override;
end;

implementation

uses vtig, vutil, vlua,
     dfplayer, drlbase, drlhelpview, drlsettingsview, drlmessagesview, drlassemblyview;

constructor TInGameMenuView.Create( aHOF : THOF; aHelp : THelp );
begin
  FHOF  := aHOF;
  FHelp := aHelp;
  VTIG_EventClear;
  VTIG_ResetSelect( 'ingame_menu_abandon' );
  //VTIG_ResetSelect( 'ingame_menu' );
  FFinished := False;
end;

procedure TInGameMenuView.Update( aDTime : Integer; aActive : Boolean );
begin
  if IsFinished or (DRL.State <> DSPlaying) then Exit;

  VTIG_Begin('ingame_menu', Point( 30, 11 ) );
  if VTIG_Selectable( 'Continue' ) then
  begin
    FFinished := True;
  end;
  if VTIG_Selectable( 'Help' ) then
  begin
    IO.PushLayer( THelpView.Create( IO, IO.Session.Context.Lua, FHelp, CoreModuleID ) );
    FFinished := True;
  end;
  if VTIG_Selectable( 'Settings' ) then
  begin
    IO.PushLayer( TSettingsView.Create );
    FFinished := True;
  end;
  if VTIG_Selectable( 'Message history' ) then
  begin
    IO.PushLayer( TMessagesView.Create( IO, IO.MsgGetRecent ) );
    FFinished := True;
  end;
  if VTIG_Selectable( 'Assemblies' ) then
  begin
    IO.PushLayer( TAssemblyView.Create( IO.Session.Context.Lua, FHOF ) );
    FFinished := True;
  end;
  if VTIG_Selectable( 'Abandon Run' ) then
  begin
    FFinished := True;
    IO.PushLayer( TAbandonView.Create );
  end;
  if VTIG_Selectable( 'Save & Quit' ) then
  begin
    FFinished := True;
    IO.FadeOut(0.5);
    DRL.SetState( DSSaving );
  end;
  VTIG_End;

  if VTIG_EventCancel then FFinished := True;
end;

function TInGameMenuView.IsFinished : Boolean;
begin
  Exit( FFinished or ( DRL.State <> DSPlaying ) );
end;

function TInGameMenuView.IsModal : Boolean;
begin
  Exit( True );
end;

constructor TAbandonView.Create;
begin
  inherited Create;
  FCancel  := 'Continue run';
  FConfirm := 'Abandon run';
  FMessage := IO.Session.Context.Lua.ProtectedCall([CoreModuleID,'GetQuitMessage'],[]) + #10 +
    '{yAre you sure you want to abandon this run?}';
  FSize    := Point( 50, 10 );
end;

procedure TAbandonView.OnConfirm;
begin
  IO.FadeOut(0.5);
  DRL.SetState( DSQuit );
  Player.Score := -100000;
end;

procedure TAbandonView.OnCancel;
begin
  IO.Msg('Ok, then. Stay and take what''s coming to ya...');
end;

end.

