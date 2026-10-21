{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlconfig;
interface

uses classes, sysutils, vluaconfig, vgenerics;

type TColorOverrides = specialize TGHashMap< Integer >;

{ TDRLConfig }

type TDRLConfig = class(TLuaConfig)
  constructor Create( const aFileName : AnsiString; aReload : Boolean );
  destructor Destroy; override;
private
  FColorOverrides   : TColorOverrides;
  FSoundEngine      : AnsiString;
  FHighASCII        : Boolean;
  procedure ReadColorOverride( aKey, aValue : Variant );
public
  property ColorOverrides   : TColorOverrides read FColorOverrides;
  // Resolved sound engine: 'FMOD', 'SDL' or 'NONE'.
  property SoundEngine      : AnsiString      read FSoundEngine;
  // Presentation options read by IO.
  property HighASCII        : Boolean         read FHighASCII;
end;


implementation

uses dfdata;


{ TDRLConfig }

constructor TDRLConfig.Create( const aFileName : AnsiString; aReload : Boolean );
begin
  inherited Create;
  FColorOverrides := TColorOverrides.Create;

  LoadMain( aFileName );

  Option_Graphics         := Configure('Graphics',Option_Graphics);
  FSoundEngine            := Configure('SoundEngine','DEFAULT');

  FHighASCII              := Configure('AllowHighAscii',{$IFDEF WINDOWS}True{$ELSE}False{$ENDIF});

  if ForceNoAudio then FSoundEngine := 'NONE';
  if FSoundEngine = 'DEFAULT' then
     FSoundEngine := {$IFDEF WINDOWS}'FMOD'{$ELSE}'SDL'{$ENDIF};
  if (FSoundEngine <> 'FMOD') and (FSoundEngine <> 'SDL') then
     FSoundEngine := 'NONE';

  // synchro
  if ForceConsole or ForceGraphics then
  begin
    if ForceConsole
      then Option_Graphics := 'CONSOLE'
      else Option_Graphics := 'TILES';
    GraphicsVersion := not ForceConsole;
  end
  else
  begin
    if (Option_Graphics <> 'TILES') and (Option_Graphics <> 'CONSOLE') then
      Option_Graphics := 'TILES';
    if Option_Graphics = 'TILES'
      then GraphicsVersion := True
      else GraphicsVersion := False;
  end;

  if aReload then EntryFeed( 'Colors', @ReadColorOverride );
end;

procedure TDRLConfig.ReadColorOverride( aKey, aValue : Variant );
begin
  FColorOverrides[aKey] := aValue;
end;

destructor TDRLConfig.Destroy;
begin
  FreeAndNil( FColorOverrides );
  inherited Destroy;
end;

end.
