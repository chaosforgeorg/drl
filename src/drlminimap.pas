{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlminimap;
interface
uses vrltools, vcolor, vvector, vimage, vglquadrenderer,
     dflevel;

type TMinimap = class
  constructor Create;
  procedure Redraw( aLevel : TLevel );
  procedure Render( aTarget : TGLQuadList );
  procedure SetScale( aScale : Byte );
  procedure SetOpacity( aOpacity : Byte );
  procedure SetPosition( aPos : TVec2i );
  destructor Destroy; override;
private
  function GetColor( aLevel : TLevel; aCoord : TCoord2D ) : TColor;
private
  FImage   : TImage;
  FTexture : DWord;
  FOpacity : Integer;
  FScale   : Integer;
  FGLPos   : TVec2i;
end;

implementation

uses math, sysutils,
     viotypes, vglimage,
     dfdata, dfitem, dfbeing, dfmap;

constructor TMinimap.Create;
begin
  FOpacity  := 2;
  FScale    := 0;
  FTexture  := 0;
  FGLPos    := TVec2i.Create( 0, 0 );
  FImage    := TImage.Create( 128, 32 );
  FImage.Fill( NewColor( 0,0,0,0 ) );
end;

procedure TMinimap.Redraw( aLevel : TLevel );
var iX, iY : DWord;
begin
  for iX := 0 to MAXX+1 do
    for iY := 0 to MAXY+1 do
      FImage.ColorXY[iX,iY] := GetColor( aLevel, NewCoord2D( iX, iY ) );
  if FTexture = 0
    then FTexture := UploadImage( FImage, False )
    else ReUploadImage( FTexture, FImage, False );
end;

procedure TMinimap.Render( aTarget : TGLQuadList );
const UnitTex : TVec2f = ( Data : ( 1, 1 ) );
      ZeroTex : TVec2f = ( Data : ( 0, 0 ) );
begin
  aTarget.PushTexturedQuad(
    FGLPos,
    FGLPos + Vec2i( FScale*128, FScale*32 ), ZeroTex, UnitTex, FTexture );
end;

procedure TMinimap.SetScale( aScale : Byte );
begin
  FScale := aScale;
end;

procedure TMinimap.SetOpacity( aOpacity : Byte );
begin
  FOpacity := aOpacity;
end;

procedure TMinimap.SetPosition( aPos : TVec2i );
begin
  FGLPos := aPos;
end;

destructor TMinimap.Destroy;
begin
  UnUploadImage( FTexture );
  FreeAndNil( FImage );
  inherited Destroy;
end;

function TMinimap.GetColor( aLevel : TLevel; aCoord : TCoord2D ) : TColor;
const DefColor : TColor = ( R : 0; G : 0; B : 0; A : 100 );
var iColor : Byte;
    iItem  : TItem;
    iBeing : TBeing;
    iOMult : Byte;
begin
  with aLevel do
  begin
    if not isProperCoord( aCoord ) then Exit( DefColor );
    iOMult := 1;
    iColor := Black;
    iBeing := Being[ aCoord ];
    iItem  := Item[ aCoord ];

    if BeingVisible( aCoord, iBeing ) or BeingExplored( aCoord, iBeing ) or BeingIntuited( aCoord, iBeing ) then
    begin
      iOMult := 2;
      if iBeing.isPlayer
        then iColor := LightGreen
        else if iBeing.Flags[ BF_FRIENDLY ]
          then iColor := Green
          else iColor := LightRed;
    end
    else if ItemVisible( aCoord, iItem ) or ItemExplored( aCoord, iItem ) then
    begin
      if iItem.Flags[ IF_HIGHLIGHT ]
        then iColor := LightCyan
        else iColor := LightBlue;
    end
    else if CellExplored( aCoord ) then
    begin
      if not isVisible( aCoord ) then
      begin
        with aLevel.Data.Cells[ getCell(aCoord) ] do
        if CF_BLOCKMOVE in Flags then
          iColor := DarkGray
        else
        if CF_STAIRS in Flags then
        begin
          iColor := Yellow;
          iOMult := 2;
        end;
      end
      else
        with aLevel.Data.Cells[ getCell(aCoord) ] do
        if CF_LIQUID in Flags then
          iColor := Blue
        else
        if CF_STAIRS in Flags then
        begin
          iColor := Yellow;
          iOMult := 2;
        end
        else
        if CF_BLOCKMOVE in Flags then
          iColor := LightGray
        else
          iColor := DarkGray;
    end;

    if iColor = Black then
    begin
      Result   := DefColor;
      Result.A := FOpacity * 25;
      Exit;
    end;
    Result := NewColor( iColor );
    Result.A := Min( FOpacity * 50 * iOMult, 250 );
  end;
end;


end.

