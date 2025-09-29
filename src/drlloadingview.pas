{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlloadingview;
interface
uses vutil, viotypes, dfdata;
       
type TLoadingView = class( TIOLayer )
  constructor Create( aMax : DWord );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
protected
  FMax      : DWord;
  FCurrent  : DWord;
  FFinished : Boolean;
public
  property Finished : Boolean read FFinished write FFinished;
  property Max      : DWord   read FMax      write FMax;
  property Current  : DWord   read FCurrent  write FCurrent;
end;

implementation

uses sysutils, math, vtig, drlio, drlgfxio, vgltypes;

constructor TLoadingView.Create( aMax : DWord );
begin
  FMax     := aMax;
  FCurrent := 0;
  VTIG_EventClear;
end;

procedure TLoadingView.Update( aDTime : Integer; aActive : Boolean );
var iSize     : TGLVec2i;
    iStep     : TGLVec2i;
    iV1,iV2   : TGLVec2i;
    iPoint    : TGLVec2i;
    iMaxChar  : DWord;
    iProgChar : DWord;
begin
  if FCurrent > FMax then FCurrent := FMax;
  if FMax = 0 then Exit;
  if GraphicsVersion then
  begin
    with IO as TDRLGFXIO do
    begin
      iSize.Init( Driver.GetSizeX, Driver.GetSizeY );
      iStep.Init( iSize.X div 15, iSize.Y div 15 );
      iPoint.Init( iSize.X div 400, iSize.X div 400 );
      iV1.Init(           iStep.X, iStep.Y * 7 );
      iV2.Init( iSize.X - iStep.X, iStep.Y * 8 );
      QuadSheet.PushColoredQuad( iV1, iV2, TGLVec4f.Create( 1,0,0,1 ) );
      iV1 := iV1 + iPoint;
      iV2 := iV2 - iPoint;
      QuadSheet.PushColoredQuad( iV1, iV2, TGLVec4f.Create( 0,0,0,1 ) );
      iV1 := iV1 + iPoint.Scaled(2);
      iV2 := iV2 - iPoint.Scaled(2);
      iV2.X := Round( ( iV2.X - iV1.X ) * (FCurrent / FMax) ) + iV1.X;
      QuadSheet.PushColoredQuad( iV1, iV2, TGLVec4f.Create( 1,0.9,0,1 ) );
    end;
  end
  else
  begin
    if FCurrent = 0 then
    begin
      // Don't ask. Simply don't ask. Either FPC video unit or Windows 11 console
      // is so broken that without this part, the loading screen gets printed
      // incorrectly. Why? No fucking clue.
      Sleep(100);
      Exit;
    end;
    iMaxChar  := 60;
    iProgChar := Min( Round(( FCurrent / FMax ) * iMaxChar), iMaxChar );
    VTIG_FreeLabel( 'L O A D I N G . . .', Point(10,12), Yellow );
    VTIG_FreeLabel( '['+StringOfChar( ' ',iMaxChar )+']', Point(10,13), Yellow );
    VTIG_FreeLabel( StringOfChar( '=',iProgChar ), Point(11,13), LightRed );
  end;
end;

function TLoadingView.IsFinished : Boolean;
begin
  Exit( FFinished );
end;

function TLoadingView.IsModal : Boolean;
begin
  Exit( False );
end;

end.

