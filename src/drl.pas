{$INCLUDE drl.inc}
{
-------------------------------------------------------
DRL.PAS -- Main Program
Copyright (c) 2002-2025 by Kornel Kisielewicz
-------------------------------------------------------
}
{
[todo] move default value functionality to prototype structures
[todo] blueprints are only for type and range checking
[todo] blueprints can (should?) be turned off if not loading module, or in godmode?
[todo] however, we'd loose the option to run functions if not turned on?
[todo] container structures have meta information __blueprint and __prototype for default
[todo] the upper needs to be handled by core.unregister!
[todo] warning-only mode?
[todo] dryrun possibility of the wad file! for modders and stats generation

[todo] Copy configs from DataPath to ConfigurationPath if not present
[todo] Set proper paths on unix, create directories if needed
}

program drl;

uses
  SysUtils,
  {$IFDEF HEAPTRACE}heaptrc,{$ENDIF}
  vapp, drlapplication;

{$IFDEF WINDOWS}
{$R drl.rc}
{$ENDIF}

begin
  Application := TDRLApplication.Create;
  try
    Application.Title := 'DRL';
    Application.Initialize;
    if not Application.Terminated then
      Application.Run;
  finally
    FreeAndNil(Application);
  end;
end.
