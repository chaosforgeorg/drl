{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmodulechoiceview;
interface
uses viotypes, vutil, drlio, dfdata, drlmodule;

type TModuleChoiceView = class( TIOLayer )
  constructor Create( aModules : TModuleList );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsModal : Boolean; override;
protected
  FModules : TModuleList;
end;

type TModuleAPIWarningView = class( TIOLayer )
  constructor Create( aModules : TModuleList; aContinue : PBoolean );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsModal : Boolean; override;
protected
  FModules  : TModuleList;
  FContinue : PBoolean;
end;

implementation

uses vtig;

constructor TModuleChoiceView.Create( aModules : TModuleList );
begin
  FModules  := aModules;
  FFinished := False;
end;

procedure TModuleChoiceView.Update( aDTime : Integer; aActive : Boolean );
var iResult : Ansistring;
    iModule : TDRLModule;
begin
  iResult := '';
  VTIG_Clear;
  IO.Console.HideCursor;
  VTIG_BeginWindow( 'DRL module choice', 'core_module_choice', Point( 40, -1 ) );
  VTIG_Text( 'Select core module to run' );
  VTIG_Ruler;
  for iModule in FModules do
     if VTIG_Selectable( iModule.Name ) then
       iResult := iModule.ID;
  VTIG_Ruler;
  VTIG_Text( 'You can set your default core module in Settings!' );
  VTIG_End;
  if iResult <> '' then
  begin
    CoreModuleID := iResult;
    FFinished := True;
  end;
end;

function TModuleChoiceView.IsModal : Boolean;
begin
  Exit( True );
end;

constructor TModuleAPIWarningView.Create( aModules : TModuleList; aContinue : PBoolean );
begin
  FFinished := False;
  FModules  := aModules;
  FContinue := aContinue;
  FContinue^ := False;
end;

procedure TModuleAPIWarningView.Update( aDTime : Integer; aActive : Boolean );
var iModule : TDRLModule;
    iAPI    : Ansistring;
begin
  VTIG_Clear;
  IO.Console.HideCursor;
  VTIG_BeginWindow( 'Outdated mods', 'module_api_warning', Point( 60, -1 ) );
  VTIG_Text( 'The following mods are built against an older API and might crash or not function properly:' );
  VTIG_Text('');
  for iModule in FModules do
  begin
    iAPI := iModule.APIVersion;
    if iAPI = '' then iAPI := 'unknown';
    VTIG_Text( iModule.Name + ' ({^' + iAPI + '})', Red );
  end;
  VTIG_Ruler;
  if VTIG_Selectable( 'Continue' ) then
  begin
    FContinue^ := True;
    FFinished  := True;
  end;
  if VTIG_Selectable( 'Exit' ) then
    FFinished := True;
  VTIG_End;
end;

function TModuleAPIWarningView.IsModal : Boolean;
begin
  Exit( True );
end;

end.
