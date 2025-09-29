{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmodulechoiceview;
interface
uses viotypes, vutil, drlio, dfdata;

type TModuleChoiceView = class( TIOLayer )
  constructor Create;
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
protected
  FFinished : Boolean;
end;

implementation

uses vtig, drlbase, drlmodule;

constructor TModuleChoiceView.Create;
begin
  FFinished := False;
end;

procedure TModuleChoiceView.Update( aDTime : Integer; aActive : Boolean );
var iResult : Ansistring;
    iModule : TDRLModule;
begin
  iResult := '';
  VTIG_Clear;
  IO.Root.Console.HideCursor;
  VTIG_BeginWindow( 'DRL module choice', 'core_module_choice', Point( 40, -1 ) );
  VTIG_Text( 'Select core module to run' );
  VTIG_Ruler;
  for iModule in DRL.Modules.CoreModules do
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

function TModuleChoiceView.IsFinished : Boolean;
begin
  Exit( FFinished );
end;

function TModuleChoiceView.IsModal : Boolean;
begin
  Exit( True );
end;

end.

