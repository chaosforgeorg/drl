{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlingamemenuview;
interface
uses viotypes,
     dfhof, drlio, drlconfirmview, dfdata, drlhelp, drlbase;

type TInGameMenuView = class( TIOLayer )
  constructor Create( aSession : TDRLSession; aHOF : THOF; aHelp : THelp );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
private
  FSession : TDRLSession; // Borrowed; the view is released before Session.
  FHOF     : THOF;
  FHelp    : THelp;
end;

type TAbandonView = class( TConfirmView )
  constructor Create( aSession : TDRLSession );
  function IsFinished : Boolean; override;
protected
  procedure OnConfirm; override;
  procedure OnCancel; override;
private
  FSession : TDRLSession; // Borrowed; the view is released before Session.
end;

implementation

uses vtig, vutil, vlua,
     drlhelpview, drlsettingsview, drlmessagesview, drlassemblyview;

constructor TInGameMenuView.Create( aSession : TDRLSession; aHOF : THOF; aHelp : THelp );
begin
  FSession := aSession;
  FHOF     := aHOF;
  FHelp    := aHelp;
  VTIG_EventClear;
  VTIG_ResetSelect( 'ingame_menu_abandon' );
  //VTIG_ResetSelect( 'ingame_menu' );
  FFinished := False;
end;

procedure TInGameMenuView.Update( aDTime : Integer; aActive : Boolean );
var iSaveQuit : Boolean;
begin
  iSaveQuit := False; 
  if IsFinished or (FSession.State <> DSPlaying) then Exit;

  VTIG_Begin('ingame_menu', Point( 30, 11 ) );
  if VTIG_Selectable( 'Continue' ) then
  begin
    FFinished := True;
  end;
  if VTIG_Selectable( 'Help' ) then
  begin
    IO.PushLayer( THelpView.Create( IO, FSession.Context.Lua, FHelp, CoreModuleID ) );
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
    IO.PushLayer( TAssemblyView.Create( FSession.Context.Lua, FHOF ) );
    FFinished := True;
  end;
  if VTIG_Selectable( 'Abandon Run' ) then
  begin
    FFinished := True;
    IO.PushLayer( TAbandonView.Create( FSession ) );
  end;
  if VTIG_Selectable( 'Save & Quit' ) then
  begin
    iSaveQuit := True;
    FFinished := True;
  end;
  VTIG_End;

  if VTIG_EventCancel then FFinished := True;
  if iSaveQuit then
  begin
    IO.FadeOut( 0.5 );
    FSession.SetState( DSSaving );
  end;
end;

function TInGameMenuView.IsFinished : Boolean;
begin
  Exit( FFinished or ( FSession.State <> DSPlaying ) );
end;

function TInGameMenuView.IsModal : Boolean;
begin
  Exit( True );
end;

constructor TAbandonView.Create( aSession : TDRLSession );
begin
  FSession := aSession;
  inherited Create;
  FCancel  := 'Continue run';
  FConfirm := 'Abandon run';
  FMessage := FSession.Context.Lua.ProtectedCall([CoreModuleID,'GetQuitMessage'],[]) + #10 +
    '{yAre you sure you want to abandon this run?}';
  FSize    := Point( 50, 10 );
end;

function TAbandonView.IsFinished : Boolean;
begin
  Exit( FFinished or ( FSession.State <> DSPlaying ) );
end;

procedure TAbandonView.OnConfirm;
var iSession : TDRLSession;
begin
  // SetState may redraw and release this finished view.
  iSession := FSession;
  IO.FadeOut(0.5);
  iSession.SetState( DSQuit );
  iSession.Player.Score := -100000;
end;

procedure TAbandonView.OnCancel;
begin
  IO.Msg('Ok, then. Stay and take what''s coming to ya...');
end;

end.

