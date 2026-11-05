{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlconfig;
interface

uses classes, sysutils, vluaconfig;

{ TDRLConfig }

type TDRLConfig = class(TLuaConfig)
  constructor Create( const aFileName : AnsiString );
private
  FSoundEngine : AnsiString;
  FHighASCII   : Boolean;
public
  // Resolved sound engine: 'FMOD', 'SDL' or 'NONE'.
  property SoundEngine : AnsiString read FSoundEngine;
  // Presentation option read by IO.
  property HighASCII   : Boolean    read FHighASCII;
end;


implementation

uses dfdata;


{ TDRLConfig }

constructor TDRLConfig.Create( const aFileName : AnsiString );
begin
  inherited Create;

  LoadMain( aFileName );

  Option_Graphics         := Configure('Graphics',Option_Graphics);
  FSoundEngine            := Configure('SoundEngine','DEFAULT');

  FHighASCII              := Configure('AllowHighAscii',{$IFDEF WINDOWS}True{$ELSE}False{$ENDIF});

  if ForceNoAudio then FSoundEngine := 'NONE';
  if FSoundEngine = 'DEFAULT' then
     FSoundEngine := 'FMOD';
  if (FSoundEngine <> 'FMOD') and (FSoundEngine <> 'SDL') then
     FSoundEngine := 'NONE';

  // synchro
  GraphicsVersion := DisplayLaunch.GraphicsMode( Option_Graphics <> 'CONSOLE' );
  if GraphicsVersion
    then Option_Graphics := 'TILES'
    else Option_Graphics := 'CONSOLE';
end;

end.
