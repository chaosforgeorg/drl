{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlplotview;
interface
uses vutil, viotypes, vtextures, drlio, dfdata;

type TPlotView = class( TIOLayer )
  constructor Create( const aMessage : AnsiString; aColor : DWord; const aBackground : Ansistring = '' );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
protected
  FMessage   : AnsiString;
  FFinished  : Boolean;
  FBoost     : Boolean;
  FPosition  : DWord;
  FTime      : DWord;
  FColor     : DWord;
  FSize      : TPoint;
  FBGTexture : TTextureID;
end;

implementation

uses vtig, drlgfxio;

constructor TPlotView.Create( const aMessage : AnsiString; aColor : DWord; const aBackground : Ansistring = '' );
begin
  VTIG_EventClear;
  FSize      := Point( 80, IO.Console.SizeY );
  FFinished  := False;
  FPosition  := 0;
  FTime      := 0;
  FMessage   := aMessage;
  FColor     := aColor;
  FBoost     := False;
  FBGTexture := 0;
  if GraphicsVersion and ( aBackground <> '' ) then
    with (IO as TDRLGFXIO) do
      if Textures.Exists(aBackground)
         then FBGTexture := (IO as TDRLGFXIO).Textures.TextureID[aBackground]
         else Log( LOGERROR, 'Texture not found - "'+aBackground+'"');
end;

procedure TPlotView.Update( aDTime : Integer; aActive : Boolean );
var iRate : DWord;
begin
  iRate := 40;
  if FBoost then iRate := 2;
  FTime += aDTime;
  while (FTime >= iRate) and (FPosition < Length( FMessage )) do
  begin
    FTime -= iRate;
    Inc( FPosition );
  end;
  VTIG_Clear;
  VTIG_SetMaxCharacters( FPosition );
  VTIG_FreeLabel( FMessage, Rectangle( 10, 5, 62, 15 ), FColor );
  IO.RenderUIBackground( FBGTexture, 1 );
  IO.RenderUIBackgroundBlock( PointZero, FSize, 0.5, 2 );

  if VTIG_EventCancel or VTIG_EventConfirm then
     if ( not FBoost ) and ( FPosition < ( Length(FMessage) * 0.8 ) )
        then FBoost := True
        else FFinished := True;
end;

function TPlotView.IsFinished : Boolean;
begin
  Exit( FFinished );
end;

function TPlotView.IsModal : Boolean;
begin
  Exit( True );
end;

end.

