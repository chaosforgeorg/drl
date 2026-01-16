{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlspritemap;
interface
uses Classes, SysUtils,
     vutil, vgltypes, vrltools, vgenerics, vvector, vcolor, vglquadrenderer, vglprogram,
     vglfullscreentriangle, vnode, vspriteengine, vtextures, vglframebuffer, dfdata, dfbeing;

// TODO : remove
const SpriteCellRow = 16;

const DRL_Z_FX     = 16000;
      DRL_Z_LAYER  = 1000;
      DRL_Z_LINE   = 10;
      DRL_Z_ZERO   = 0;
      DRL_Z_ENVIRO = DRL_Z_LAYER;
      DRL_Z_DECAL  = DRL_Z_LAYER + DRL_Z_LAYER div 2;
      DRL_Z_DOODAD = DRL_Z_LAYER * 2;
      DRL_Z_ITEMS  = DRL_Z_LAYER * 3;
      DRL_Z_BEINGS = DRL_Z_LAYER * 4;
      DRL_Z_LARGE  = DRL_Z_LAYER * 5;

type TDRLMouseCursor = class( TVObject )
  constructor Create;
  procedure SetTextureID( aTexture : TTextureID; aSize : DWord );
  procedure Draw( aPoint : TPoint; aTicks : DWord; aTarget : TGLQuadList );
  procedure Reset;
private
  FTextureID : TTextureID;
  FSize      : DWord;
  FActive    : Boolean;
public
  property Active : Boolean read FActive write FActive;
  property Size   : DWord   read FSize;
end;

type TCoord2DArray = specialize TGArray< TCoord2D >;

type TSpritePart = ( F, T, B, L, R, TL, TR, BL, BR );
     TSpritePartSet = set of TSpritePart;

type

{ TDRLSpriteMap }

 TDRLSpriteMap = class( TVObject )
  constructor Create( aFramebuffer : TVec2i );
  procedure Reset;
  procedure Recalculate;
  procedure Update( aTime : DWord; aProjection : TMatrix44 );
  procedure Draw;
  function DevicePointToCoord( aPoint : TPoint ) : TCoord2D;
  procedure PushSpriteBeing( aPos : TVec2i; const aSprite : TSprite; aLight : Byte );
  procedure PushSpriteItem( aPos : TVec2i; const aSprite : TSprite; aLight : Byte );
  procedure PushSpriteDoodad( aCoord : TCoord2D; const aSprite : TSprite; aLight : Integer = -1; aZOffset : Integer = 0 );
  procedure PushSpriteFX( aCoord : TCoord2D; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 );
  procedure PushSpriteFXRotated( aPos : TVec2i; const aSprite : TSprite; aRotation : Single );
  procedure PushSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aTSX : Single = 0; aTSY : Single = 0 );
  function ShiftValue( aFocus : TCoord2D ) : TVec2i;
  procedure SetTarget( aTarget : TCoord2D; aColor : TColor; aDrawPath : Boolean );
  procedure SetAutoTarget( aTarget : TCoord2D );
  procedure ClearTarget;
  procedure ToggleGrid;
  function VariableLight( aWhere : TCoord2D; aBonus : ShortInt = 0 ) : Byte;
  function GetGridSize : Word;
  function GetCellRotationMask( aCell : TCoord2D ) : Byte;
  function GetCellDoorRotation( aCell : TCoord2D ) : Byte;
  destructor Destroy; override;
  function GetBeingSprite( aBeing : TBeing ) : TSprite;
private
  FGridActive     : Boolean;
  FMaxShift       : TVec2i;
  FMinShift       : TVec2i;
  FFluidX         : Single;
  FFluidY         : Single;
  FTimer          : DWord;
  FFluidTime      : Double;
  FTargeting      : Boolean;
  FTarget         : TCoord2D;
  FTargetList     : TCoord2DArray;
  FTargetColor    : TColor;
  FNewShift       : TVec2i;
  FShift          : TVec2i;
  FOffset         : TVec2i;
  FLastCoord      : TCoord2D;
  FAutoTarget     : TCoord2D;
  FMarker         : TCoord2D;
  FSpriteEngine   : TSpriteEngine;
  FLightMap       : array[0..MAXX] of array[0..MAXY] of Byte;
  FFramebuffer    : TGLFramebuffer;
  FHBFramebuffer  : TGLFramebuffer;
  FVBFramebuffer  : TGLFramebuffer;
  FPostProgram    : TGLProgram;
  FHBlurProgram   : TGLProgram;
  FVBlurProgram   : TGLProgram;
  FFullscreen     : TGLFullscreenTriangle;
  FLutTexture     : Cardinal;
private
  procedure ApplyEffect;
  procedure UpdateLightMap;
  procedure PushTerrain;
  procedure PushDecals;
  procedure PushObjects( aDTime : Integer );
  procedure PushSprite( aPos : TVec2i; const aSprite : TSprite; aLight : Byte; aZ : Integer );
  procedure PushMultiSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
  procedure PushSpriteTerrainPart( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aPart : TSpritePart = F );
  function GetSprite( aSprite : TSprite; aCoord : TCoord2D; aTime : Integer = -1 ) : TSprite;
  function GetSprite( aCell, aStyle : Byte ) : TSprite;
  procedure DrawMarker;
  function GetEmissive( aSprite : TSprite ) : TColor;
public
  property Engine : TSpriteEngine read FSpriteEngine;
  property MaxShift : TVec2i read FMaxShift;
  property MinShift : TVec2i read FMinShift;
  property Shift : TVec2i read FShift;
  property NewShift : TVec2i read FNewShift write FNewShift;
  property Offset : TVec2i read FOffset write FOffset;
  property Marker : TCoord2D read FMarker write FMarker;
  property Target : TCoord2D read FTarget;
end;

var SpriteMap : TDRLSpriteMap = nil;

implementation

uses math, vmath, viotypes, vvision, vgl3library,
     drlio, drlgfxio, drlbase,
     dfmap, dfitem, dfplayer, drlmarkers, drldecals;

function SpritePartSetFill( aPart : TSpritePart ) : TSpritePartSet;
begin
  case aPart of
    T : Exit( [B] );
    B : Exit( [T] );
    L : Exit( [R] );
    R : Exit( [L] );
    TL: Exit( [B,TR] );
    TR: Exit( [B,TL] );
    BL: Exit( [T,BR] );
    BR: Exit( [T,BL] );
  end;
  Exit( [] );
end;

function ColorToGL( aColor : TColor ) : TGLVec3b;
begin
  ColorToGL.X := aColor.R;
  ColorToGL.Y := aColor.G;
  ColorToGL.Z := aColor.B;
end;

{ TDRLMouseCursor }

constructor TDRLMouseCursor.Create;
begin
  inherited Create;
  Reset;
end;

procedure TDRLMouseCursor.SetTextureID ( aTexture : TTextureID; aSize : DWord ) ;
begin
  FTextureID := aTexture;
  FSize      := aSize;
end;

procedure TDRLMouseCursor.Draw( aPoint : TPoint; aTicks : DWord; aTarget : TGLQuadList ) ;
var iColor : TVec4f;
begin
  if ( FSize = 0 ) or ( not FActive ) then Exit;

  iColor.Init( 1.0, ( Sin( aTicks / 100 ) + 1.0 ) / 2 , 0.1, 1.0 );
  aTarget.PushTexturedQuad(
    TVec2i.Create(aPoint.x,aPoint.y),
    TVec2i.Create(aPoint.x+FSize,aPoint.y+FSize),
    iColor,
    TVec2f.Create(0,0), TVec2f.Create(1,1),
    (IO as TDRLGFXIO).Textures[ FTextureID ].GLTexture
    );
end;

procedure TDRLMouseCursor.Reset;
begin
  FActive    := False;
  FSize      := 0;
  FTextureID := 0;
end;

const
VCleanVertexShader : Ansistring =
'#version 330 core'+#10+
'layout (location = 0) in vec2 position;'+#10+
#10+
'void main() {'+#10+
'gl_Position = vec4(position.x, position.y, 0.0, 1.0);'+#10+
'}'+#10;
VPostFragmentShader : Ansistring =
'#version 330 core'+#10+
'uniform sampler2D utexture;'+#10+
'uniform sampler3D ulut;'+#10+
'uniform sampler2D ublur;'+#10+
'uniform vec2 screen_size;'+#10+
'uniform int toggle_glow;'+#10+
'out vec4 frag_color;'+#10+
#10+
'void main() {'+#10+
'vec2 uv    = gl_FragCoord.xy / screen_size;'+#10+
'vec3 color = texture( utexture, uv ).xyz;'+#10+
'if ( toggle_glow > 0 ) {'+#10+
'  vec4 blur  = texture( ublur, uv );'+#10+
'  color += blur.xyz * 1.6 * blur.w;'+#10+
'}'+#10+
'vec3 lookup = color.xzy * vec3( 30.0 / 32.0 ) + vec3( 1.0 / 32.0 );'+#10+
'frag_color = vec4( texture( ulut, clamp( lookup, 0.0, 1.0 ) ).xyz, 1.0 );'+#10+
//'frag_color = vec4(color.xyz, 1.0);'+#10+
'}'+#10;

VHorizBlurFragmentShader : Ansistring =
'#version 330 core'+#10+
'uniform sampler2D utexture;'+#10+
'uniform vec2 screen_size;'+#10+
'out vec4 frag_color;'+#10+
#10+
'void main() {'+#10+
'    vec2 uv = gl_FragCoord.xy / screen_size;'+#10+
'    vec3 result = vec3(0.0);'+#10+
'    float weights[5] = float[](0.227027, 0.316216, 0.070270, 0.050987, 0.016216);'+#10+
'    float w = 0.0;'+#10+
'    for (int i = -2; i <= 2; ++i) {'+#10+
'        vec2 offset = vec2(i, 0.0) / screen_size;'+#10+
'        vec4 texel  = texture(utexture, uv + offset);'+#10+
'        if ( i == 0 ) w = texel.w;'+#10+
'        result += texel.xyz * weights[abs(i)];'+#10+
'    }'+#10+
'    frag_color = vec4( result, w );'+#10+
'}'+#10;

VVerticBlurFragmentShader : Ansistring =
'#version 330 core'+#10+
'uniform sampler2D utexture;'+#10+
'uniform vec2 screen_size;'+#10+
'out vec4 frag_color;'+#10+
#10+
'void main() {'+#10+
'    vec2 uv = gl_FragCoord.xy / screen_size;'+#10+
'    vec3 result = vec3(0.0);'+#10+
'    float weights[5] = float[](0.227027, 0.316216, 0.070270, 0.050987, 0.016216);'+#10+
'    float w = 0.0;'+#10+
'    for (int i = -2; i <= 2; ++i) {'+#10+
'        vec2 offset = vec2(0.0, i) / screen_size;'+#10+
'        vec4 texel  = texture(utexture, uv + offset);'+#10+
'        if ( i == 0 ) w = texel.w;'+#10+
'        result += texel.xyz * weights[abs(i)];'+#10+
'    }'+#10+
'    frag_color = vec4( result, w );'+#10+
'}'+#10;

{ TDRLSpriteMap }

constructor TDRLSpriteMap.Create( aFramebuffer : TVec2i );
begin
  FTargeting := False;
  FTargetList := TCoord2DArray.Create();
  FFluidTime := 0;
  FLutTexture := 0;
  FTarget.Create(0,0);
  FSpriteEngine := TSpriteEngine.Create( Vec2i( 32, 32 ) );
  FGridActive     := False;
  FLastCoord.Create(0,0);
  FAutoTarget.Create(0,0);
  FMarker.Create(-1,-1);

  FFramebuffer := TGLFramebuffer.Create;
  FFramebuffer.AddAttachment( RGBA8, False );
  FFramebuffer.AddAttachment( RGBA8, False );
  FFramebuffer.AddDepthBuffer;
  FFramebuffer.Resize( aFramebuffer.X, aFramebuffer.Y );

  FHBFramebuffer := TGLFramebuffer.Create;
  FHBFramebuffer.AddAttachment( RGBA8, False );
  FHBFramebuffer.Resize( aFramebuffer.X, aFramebuffer.Y );

  FVBFramebuffer:= TGLFramebuffer.Create;
  FVBFramebuffer.AddAttachment( RGBA8, False );
  FVBFramebuffer.Resize( aFramebuffer.X, aFramebuffer.Y );

  FPostProgram  := TGLProgram.Create(VCleanVertexShader, VPostFragmentShader);
  FHBlurProgram := TGLProgram.Create(VCleanVertexShader, VHorizBlurFragmentShader);
  FVBlurProgram := TGLProgram.Create(VCleanVertexShader, VVerticBlurFragmentShader);
  FFullscreen   := TGLFullscreenTriangle.Create;
end;

procedure TDRLSpriteMap.Reset;
begin
  FSpriteEngine.Reset;
end;

procedure TDRLSpriteMap.Recalculate;
var iIO : TDRLGFXIO;
begin
  iIO := (IO as TDRLGFXIO);
  FSpriteEngine.SetScale( iIO.TileScale );
  FMinShift := Vec2i(0,0);
  FMaxShift := Vec2i(
    Max(FSpriteEngine.Grid.X*MAXX-iIO.Driver.GetSizeX,0),
    Max(FSpriteEngine.Grid.Y*MAXY-iIO.Driver.GetSizeY,0)
  );

  if IO.Driver.GetSizeY > 20*FSpriteEngine.Grid.Y then
  begin
    FMinShift.Y := -( IO.Driver.GetSizeY - 20*FSpriteEngine.Grid.Y ) div 2;
    FMaxShift.Y := FMinShift.Y;
  end
  else
  begin
    FMinShift.Y := FMinShift.Y - 18*iIO.FontMult*2;
    FMaxShift.Y := FMaxShift.Y + 18*iIO.FontMult*3;
  end;
  FFramebuffer.Resize( iIO.Driver.GetSizeX, iIO.Driver.GetSizeY );
  FHBFramebuffer.Resize( iIO.ScaledScreen.X, iIO.ScaledScreen.Y );
  FVBFramebuffer.Resize( iIO.ScaledScreen.X, iIO.ScaledScreen.Y );

  FPostProgram.Bind;
    FPostProgram.SetUniformi( 'utexture', 0 );
    FPostProgram.SetUniformi( 'ulut', 1 );
    FPostProgram.SetUniformi( 'ublur', 2 );
    if Setting_Glow
      then FPostProgram.SetUniformi( 'toggle_glow', 1 )
      else FPostProgram.SetUniformi( 'toggle_glow', 0 );
    FPostProgram.SetUniformf( 'screen_size', IO.Driver.GetSizeX, IO.Driver.GetSizeY );
  FPostProgram.UnBind;

  FHBlurProgram.Bind;
    FHBlurProgram.SetUniformi( 'utexture', 0 );
    FHBlurProgram.SetUniformf( 'screen_size', iIO.ScaledScreen.X, iIO.ScaledScreen.Y );
  FHBlurProgram.UnBind;

  FVBlurProgram.Bind;
    FVBlurProgram.SetUniformi( 'utexture', 0 );
    FVBlurProgram.SetUniformf( 'screen_size', iIO.ScaledScreen.X, iIO.ScaledScreen.Y );
  FVBlurProgram.UnBind;
  glViewport( 0, 0, iIO.Driver.GetSizeX, iIO.Driver.GetSizeY );
end;

procedure TDRLSpriteMap.Update ( aTime : DWord; aProjection : TMatrix44 ) ;
var iShift : Single;
    iPixel : Integer;
    iIO    : TDRLGFXIO;
    iMark  : TMarker;
begin
  iIO := IO as TDRLGFXIO;
  FShift := FNewShift;
  {$PUSH}
  {$Q-}
  FTimer += aTime;
  {$POP}

  // Technically this should smooth out fluids -_-
  FFluidTime := IO.Driver.GetMs*0.0001;
  iShift     := FFluidTime - Floor( FFluidTime );
  iPixel     := Floor( iShift * ( 32*iIO.TileScale ) );
  iShift     := iPixel / ( 32*iIO.TileScale );
  FFluidX := 1-iShift;
  FFluidY := iShift;
  ApplyEffect;
  UpdateLightMap;
  FSpriteEngine.Update( aProjection );
  PushTerrain;
  PushDecals;
  PushObjects( aTime );

  for iMark in DRL.Level.Markers.Data do
    if DRL.Level.isVisible( iMark.Coord ) then
      PushSpriteFX( iMark.Coord, iMark.Sprite, FTimer, -1 );

  DrawMarker;
end;

procedure TDRLSpriteMap.DrawMarker;
const MarkerSprite : TSprite = (
  Color     : (R:0;G:0;B:0;A:255);
  OverColor : (R:0;G:0;B:0;A:0);
  GlowColor : (R:0;G:0;B:0;A:0);
  Emissive  : (R:0;G:0;B:0;A:0);
  SpriteID  : (0,0,0,0,0,0,0,0);
  SCount    : 1;
  Frames    : 0;
  Frametime : 0;
  Flags     : [ SF_COSPLAY ];
);
begin
  if ( FMarker.X < 0 ) or ( FMarker.Y < 0 ) then Exit;
  if not DRL.Level.isProperCoord( FMarker ) then Exit;
  MarkerSprite.SpriteID[0] := HARDSPRITE_HIGHLIGHT;
  MarkerSprite.Color := ColorBlack;
  MarkerSprite.Color.A := 127;
  if IO.GetPadRTrigger or IO.Targeting then
  begin
    MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100);
    MarkerSprite.Color.G := MarkerSprite.Color.R;
    MarkerSprite.Color.B := MarkerSprite.Color.R;
  end
  else
  begin
    if DRL.Level.cellFlagSet( FMarker, CF_BLOCKMOVE ) and ( not DRL.Level.cellFlagSet( FMarker, CF_OPENABLE ) ) then
      MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100)
    else if (DRL.Level.GetBeing( FMarker ) <> nil) or (not DRL.Level.isPassable( FMarker ) ) then
    begin
      MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100);
      MarkerSprite.Color.G := MarkerSprite.Color.R;
    end
    else
      MarkerSprite.Color.G := Floor(50*(Sin( FFluidTime*50 )+1)+100);
  end;
  SpriteMap.PushSpriteFX( FMarker, MarkerSprite );
end;

function TDRLSpriteMap.GetEmissive( aSprite : TSprite ) : TColor;
begin
  if aSprite.Emissive.A <> 0 then Exit( aSprite.Emissive );
  Exit( aSprite.Color );
end;

procedure TDRLSpriteMap.Draw;
var iPoint   : TPoint;
    iCoord   : TCoord2D;
    iIO      : TDRLGFXIO;
const TargetSprite : TSprite = (
  Color     : (R:0;G:0;B:0;A:255);
  OverColor : (R:0;G:0;B:0;A:0);
  GlowColor : (R:0;G:0;B:0;A:0);
  Emissive  : (R:0;G:0;B:0;A:0);
  SpriteID  : (0,0,0,0,0,0,0,0);
  SCount    : 1;
  Frames    : 0;
  Frametime : 0;
  Flags     : [ SF_COSPLAY ];
);

begin
  TargetSprite.SpriteID[0] := HARDSPRITE_SELECT;
  iIO := IO as TDRLGFXIO;
  FSpriteEngine.Position := FShift + FOffset;

  if iIO.MCursor.Active and iIO.Driver.GetMousePos( iPoint ) then
  begin
    iCoord := DevicePointToCoord( iPoint );
    if DRL.Level.isProperCoord( iCoord ) then
    begin
      if (FLastCoord <> iCoord) and (not IO.AnimationsRunning) then
      begin
        if not IO.IsModal then
          if DRL.Level.isVisible(iCoord) and ( DRL.Level.Being[ iCoord ] <> nil )
            then IO.HintOverlay := DRL.Level.GetTargetDescription(iCoord)
            else IO.HintOverlay := DRL.Level.GetLookDescription(iCoord);
        FLastCoord := iCoord;
      end;

      TargetSprite.Color := ColorBlack;
      if DRL.Level.isVisible( iCoord ) then
        TargetSprite.Color.G := Floor(100*(Sin( FFluidTime*50 )+1)+50)
      else
        TargetSprite.Color.R := Floor(100*(Sin( FFluidTime*50 )+1)+50);
      SpriteMap.PushSpriteFX( iCoord, TargetSprite );
    end;
  end;

  if ( FLutTexture <> 0 ) or ( Setting_Glow ) then
  begin
    FFramebuffer.BindAndClear;
    FSpriteEngine.Draw;
    FFramebuffer.UnBind;

    if Setting_Glow then
    begin
      glDisable( GL_BLEND );

      FHBlurProgram.Bind;
        glActiveTexture( GL_TEXTURE0 );
        glBindTexture( GL_TEXTURE_2D, FFramebuffer.GetTextureID(1) );
        FHBFramebuffer.BindAndClear;
        FFullscreen.Render;
        FHBFramebuffer.UnBind;
        glBindTexture( GL_TEXTURE_2D, 0 );
      FHBlurProgram.UnBind;

      FVBlurProgram.Bind;
        glActiveTexture( GL_TEXTURE0 );
        glBindTexture( GL_TEXTURE_2D, FHBFramebuffer.GetTextureID(0) );
        FVBFramebuffer.BindAndClear;
        FFullscreen.Render;
        FVBFramebuffer.UnBind;
        glBindTexture( GL_TEXTURE_2D, 0 );
      FVBlurProgram.UnBind;

      glEnable( GL_BLEND );

      glViewport( 0, 0, iIO.Driver.GetSizeX, iIO.Driver.GetSizeY );
    end;

    FPostProgram.Bind;
      glActiveTexture( GL_TEXTURE0 );
      glBindTexture( GL_TEXTURE_2D, FFramebuffer.GetTextureID(0) );
      glActiveTexture( GL_TEXTURE1 );
      glBindTexture( GL_TEXTURE_3D, FLutTexture );
      glActiveTexture( GL_TEXTURE2 );
      glBindTexture( GL_TEXTURE_2D, FVBFramebuffer.GetTextureID(0) );

      FFullscreen.Render;

      glActiveTexture( GL_TEXTURE0 );
      glBindTexture( GL_TEXTURE_2D, 0 );
      glActiveTexture( GL_TEXTURE1 );
      glBindTexture( GL_TEXTURE_3D, 0 );
      glActiveTexture( GL_TEXTURE2 );
      glBindTexture( GL_TEXTURE_2D, 0 );
      glActiveTexture( GL_TEXTURE0 );
    FPostProgram.UnBind;
  end
  else
    FSpriteEngine.Draw;
end;

function TDRLSpriteMap.DevicePointToCoord ( aPoint : TPoint ) : TCoord2D;
begin
  Result.x := Floor((aPoint.x + FShift.X) / FSpriteEngine.Grid.X)+1;
  Result.y := Floor((aPoint.y + FShift.Y) / FSpriteEngine.Grid.Y)+1;
end;

procedure TDRLSpriteMap.PushSpriteFXRotated ( aPos : TVec2i;
  const aSprite : TSprite; aRotation : Single ) ;
var iSprite   : TSprite;
    iCoord    : TGLRawQCoord;
    iTex      : TGLRawQTexCoord;
    iColor    : TGLRawQColor;
    iTP       : TGLVec2f;
    iSizeH    : Word;
    iLayer    : TSpriteDataSet;
    iSpriteID : DWord;
  function Rotated( pX, pY : Float ) : TVec2i;
  begin
    Rotated.x := Round( pX * cos( aRotation ) - pY * sin( aRotation ) + aPos.X );
    Rotated.y := Round( pY * cos( aRotation ) + pX * sin( aRotation ) + aPos.Y );
  end;
begin
  iSprite   := GetSprite( aSprite, ZeroCoord2D );
  iLayer    := FSpriteEngine.Layers[ iSprite.SpriteID[0] div 100000 ];
  iSpriteID := iSprite.SpriteID[0] mod 100000;

  iSizeH := FSpriteEngine.Grid.X div 2;

  iCoord.Data[ 0 ] := Rotated( -iSizeH, -iSizeH );
  iCoord.Data[ 1 ] := Rotated( -iSizeH, +iSizeH );
  iCoord.Data[ 2 ] := Rotated( +iSizeH, +iSizeH );
  iCoord.Data[ 3 ] := Rotated( +iSizeH, -iSizeH );

  iTP := TVec2f.CreateModDiv( (iSpriteID-1), iLayer.RowSize );

  iTex.init(
    iTP * iLayer.TexUnit,
    iTP.Shifted(1) * iLayer.TexUnit
  );

  with iLayer do
  begin
    iColor.FillAll( 255 );
    if SF_OVERLAY in iSprite.Flags then iColor.SetAll( ColorToGL( iSprite.OverColor ) );
    Push( @iCoord, @iTex, @iColor, iSprite.Color, iSprite.GlowColor, GetEmissive( iSprite ), DRL_Z_FX );
  end;
end;

procedure TDRLSpriteMap.PushSprite( aPos : TVec2i; const aSprite : TSprite; aLight : Byte; aZ : Integer ) ;
var iSize     : Byte;
    iLayer    : TSpriteDataSet;
    iSpriteID : DWord;
    iCosColor : TColor;
begin
  iLayer    := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iSpriteID := aSprite.SpriteID[0] mod 100000;

  iSize := 1;
  if SF_LARGE in aSprite.Flags then
  begin
    iSize := 2;
    aPos.X := aPos.X - FSpriteEngine.Grid.X div 2;
    aPos.Y := aPos.Y - FSpriteEngine.Grid.Y;
  end;
  with iLayer do
  begin
// TODO: facing
    iCosColor := ColorBlack;
    if SF_COSPLAY in aSprite.Flags then
      iCosColor := aSprite.Color;

    if SF_OVERLAY in aSprite.Flags
      then PushXY( iSpriteID, iSize, aPos, aSprite.OverColor, iCosColor, aSprite.GlowColor, GetEmissive( aSprite ), aZ )
      else PushXY( iSpriteID, iSize, aPos, NewColor( aLight, aLight, aLight ), iCosColor, aSprite.GlowColor, GetEmissive( aSprite ), aZ );

    if ( not Setting_Glow ) and ( aSprite.GlowColor.A > 0 ) then
    begin
      iCosColor := aSprite.GlowColor;
      iCosColor.A := 4;
      PushXY( iSpriteID, iSize, aPos, ColorWhite, ColorZero, iCosColor, ColorZero, aZ-1, 1.0 + (1.0/8.0) )
    end;
  end;
end;

procedure TDRLSpriteMap.PushMultiSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
var iSprite   : TSprite;
    iSpriteID : DWord;
    iPart     : TSpritePart;
    iPS       : TSpritePart;
    iParts    : TSpritePartSet;
    iMaskOut  : TSpritePartSet;
  function BaseCase( aMask : Byte ) : DWord;
  begin
    case aMask of
      %00000010 : Exit( aSprite.SpriteID[0] + 1*SpriteCellRow + 2 ); // wall up
      %00001000 : Exit( aSprite.SpriteID[0] + 4*SpriteCellRow + 2 ); // wall left
      %00001010 : Exit( aSprite.SpriteID[0] + 3*SpriteCellRow + 2 ); // wall left up
      %00010000 : Exit( aSprite.SpriteID[0] + 4*SpriteCellRow + 0 ); // wall right
      %00010010 : Exit( aSprite.SpriteID[0] + 3*SpriteCellRow + 0 ); // wall right up
      %00011000 : Exit( aSprite.SpriteID[0] +                 + 1 ); // wall left right
      %00011010 : Exit( aSprite.SpriteID[0] + 2*SpriteCellRow + 1 ); // wall left right up

      %01000000 : Exit( aSprite.SpriteID[0] + 1*SpriteCellRow + 1 ); // wall down
      %01000010 : Exit( aSprite.SpriteID[0] + 1*SpriteCellRow + 0 ); // wall down up
      %01001000 : Exit( aSprite.SpriteID[0] +                 + 2 ); // wall down left
      %01001010 : Exit( aSprite.SpriteID[0] + 2*SpriteCellRow + 2 ); // wall down up left
      %01010000 : Exit( aSprite.SpriteID[0] +                 + 0 ); // wall down right
      %01010010 : Exit( aSprite.SpriteID[0] + 2*SpriteCellRow + 0 ); // wall up down right
      %01011000 : Exit( aSprite.SpriteID[0] + 3*SpriteCellRow + 1 ); // wall down right left
      %01011010 : Exit( aSprite.SpriteID[0] + 4*SpriteCellRow + 1 ); // wall cross

      %00001011 : Exit( aSprite.SpriteID[0] + (-3+2)*SpriteCellRow + 2 ); // wall left+up
      %00010110 : Exit( aSprite.SpriteID[0] + (-3+2)*SpriteCellRow + 0 ); // wall right+up
      %01101000 : Exit( aSprite.SpriteID[0] + (-3  )*SpriteCellRow + 2 ); // wall left+down
      %11010000 : Exit( aSprite.SpriteID[0] + (-3  )*SpriteCellRow + 0 ); // wall right+down

      %00011111 : Exit( aSprite.SpriteID[0] + (-3+2)*SpriteCellRow + 1 ); // wall full up
      %11111000 : Exit( aSprite.SpriteID[0] + (-3  )*SpriteCellRow + 1 ); // wall full down
      %11010110 : Exit( aSprite.SpriteID[0] + (-3+1)*SpriteCellRow + 0 ); // wall full right
      %01101011 : Exit( aSprite.SpriteID[0] + (-3+1)*SpriteCellRow + 2 ); // wall full left
      %11111111 : Exit( aSprite.SpriteID[0] + (-3+1)*SpriteCellRow + 1 ); // wall full
    end;
    Exit( 0 );
  end;
begin
  iSprite := aSprite;
  iSpriteID := BaseCase( aRotation );
  if iSpriteID > 0 then
  begin
    iSprite.SpriteID[0] := iSpriteID;
    PushSpriteTerrain( aCoord, iSprite, aZ );
    Exit;
  end;
  iSpriteID := 0;
  iPart     := F;
  iParts    := [];
  iMaskOut  := [];
  case aRotation of
    %00000000 :
      begin
        // Special case for column
        iSprite.SpriteID[0] := aSprite.SpriteID[0] + 1*SpriteCellRow + 2;
        PushSpriteTerrainPart( aCoord, iSprite, aZ, B );
        iSprite.SpriteID[0] := aSprite.SpriteID[0] + 1*SpriteCellRow + 1;
        PushSpriteTerrainPart( aCoord, iSprite, aZ, T );
        Exit;
      end;
    %01011111 : begin iSpriteID := aSprite.SpriteID[0] + 3 * SpriteCellRow + 1; iPart := B; end;
    %11111010 : begin iSpriteID := aSprite.SpriteID[0] + 2 * SpriteCellRow + 1; iPart := T; end;
    %11011110 : begin iSpriteID := aSprite.SpriteID[0] + 2 * SpriteCellRow + 2; iPart := L; end;
    %01111011 : begin iSpriteID := aSprite.SpriteID[0] + 2 * SpriteCellRow + 0; iPart := R; end;

    %11111110 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iPart := TL; end;
    %11111011 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iPart := TR; end;
    %11011111 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iPart := BL; end;
    %01111111 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iPart := BR; end;

    %01111110 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iParts := [BR,TL]; iMaskOut := [BL,TR]; end;
    %11011011 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iParts := [BL,TR]; iMaskOut := [BR,TL]; end;

    %00011011 : begin iSpriteID := aSprite.SpriteID[0] + 2*SpriteCellRow + 1; iParts := [B,TR]; iMaskOut := [TL]; end; // wall left right up
    %00011110 : begin iSpriteID := aSprite.SpriteID[0] + 2*SpriteCellRow + 1; iParts := [B,TL]; iMaskOut := [TR]; end; // wall left right up

    %01101010 : begin iSpriteID := aSprite.SpriteID[0] + 2*SpriteCellRow + 2; iParts := [R,TL]; iMaskOut := [BL]; end; // wall down up left
    %01001011 : begin iSpriteID := aSprite.SpriteID[0] + 2*SpriteCellRow + 2; iParts := [R,BL]; iMaskOut := [TL]; end; // wall down up left

    %11010010 : begin iSpriteID := aSprite.SpriteID[0] + 2*SpriteCellRow + 0; iParts := [L,TR]; iMaskOut := [BR]; end; // wall up down right
    %01010110 : begin iSpriteID := aSprite.SpriteID[0] + 2*SpriteCellRow + 0; iParts := [L,BR]; iMaskOut := [TR]; end; // wall up down right

    %11011000 : begin iSpriteID := aSprite.SpriteID[0] + 3*SpriteCellRow + 1; iParts := [T,BL]; iMaskOut := [BR]; end; // wall down right left
    %01111000 : begin iSpriteID := aSprite.SpriteID[0] + 3*SpriteCellRow + 1; iParts := [T,BR]; iMaskOut := [BL]; end; // wall down right left

    %01011110 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iParts := [B,TL]; iMaskOut := [TR]; end;
    %01111010 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iParts := [T,BR]; iMaskOut := [BL]; end;
    %01011011 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iParts := [B,TR]; iMaskOut := [TL]; end;
    %11011010 : begin iSpriteID := aSprite.SpriteID[0] + 4 * SpriteCellRow + 1; iParts := [T,BL]; iMaskOut := [BR]; end;
  end;
  if iSpriteID = 0 then Exit;

  iSprite.SpriteID[0] := iSpriteID;
  if iParts = [] then
  begin
    PushSpriteTerrainPart( aCoord, iSprite, aZ, iPart );
    iMaskOut := SpritePartSetFill( iPart );
  end
  else
  begin
    for iPS in iParts do
      PushSpriteTerrainPart( aCoord, iSprite, aZ, iPS );
  end;

  iSprite.SpriteID[0] := aSprite.SpriteID[0] + (-3+1)*SpriteCellRow + 1;
  for iPS in iMaskOut do
    PushSpriteTerrainPart( aCoord, iSprite, aZ, iPS );
  Exit;
end;

procedure TDRLSpriteMap.PushSpriteTerrainPart( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aPart : TSpritePart = F );
var iColors   : TGLRawQColor;
    iGridF    : TVec2f;
    iPosition : TVec2i;
    iPa, iPb  : TVec2i;
    iLayer    : TSpriteDataSet;
    iSpriteID : DWord;
    iLight    : array[0..3] of Byte;
    iStart    : TVec2f;
    iEnd      : TVec2f;
    iPStart   : TVec2f;
    iPEnd     : TVec2f;
    iEmissive : TColor;
  procedure Push( aLayer : TSpriteDataSet; aCosColor : TColor );
  begin
    aLayer.PushPart( iSpriteID, iPa, iPb, @iColors, aCosColor, ColorZero, iEmissive, aZ, iStart, iEnd );
  end;

  function BilinearLight( aPos : TVec2f ) : Byte;
  var iX1, iX2 : Single;
  begin
    iX1 := ( 1 - aPos.X ) * iLight[0] + aPos.X * iLight[3];
    iX2 := ( 1 - aPos.X ) * iLight[1] + aPos.X * iLight[2];
    Exit( Round( ( 1 - aPos.Y ) * iX1 + aPos.Y * iX2 ) );
  end;
const TOP : Single = 8.0 / 32.0;
begin
  iLayer    := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iSpriteID := aSprite.SpriteID[0] mod 100000;

  iLight[0] := FLightMap[aCoord.X-1,aCoord.Y-1];
  iLight[1] := FLightMap[aCoord.X-1,aCoord.Y  ];
  iLight[2] := FLightMap[aCoord.X  ,aCoord.Y  ];
  iLight[3] := FLightMap[aCoord.X  ,aCoord.Y-1];

  iStart    := TVec2f.Create(0,0);
  iEnd      := TVec2f.Create(1,1);

  case aPart of
    T : iEnd.Y := TOP;
    B : iStart.Y := TOP;
    L : iEnd.X := 0.5;
    R : iStart.X := 0.5;
    TL : iEnd.Init( 0.5, TOP );
    TR : begin iEnd.Y := TOP; iStart.X := 0.5; end;
    BL : begin iEnd.X := 0.5; iStart.Y := TOP; end;
    BR : iStart.Init( 0.5, TOP );
  end;

  iColors.Data[0] := TVec3b.CreateAll( BilinearLight( iStart ) );
  iColors.Data[1] := TVec3b.CreateAll(BilinearLight( TVec2f.Create( iStart.X, iEnd.Y ) ) );
  iColors.Data[2] := TVec3b.CreateAll(BilinearLight( iEnd ) );
  iColors.Data[3] := TVec3b.CreateAll(BilinearLight( TVec2f.Create( iEnd.X, iStart.Y ) ) );

  iGridF    := TVec2f.Create( FSpriteEngine.Grid.X, FSpriteEngine.Grid.Y );
  iPosition := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  iPStart   := iGridF * iStart;
  iPEnd     := iGridF * iEnd;
  iPa       := iPosition + TVec2i.Create( Round( iPStart.X ), Round( iPStart.Y ) );
  iPb       := iPosition + TVec2i.Create( Round( iPEnd.X ), Round( iPEnd.Y ) );

  iEmissive := aSprite.Emissive;
  if iEmissive.A = 0 then iEmissive := aSprite.Color;
  if ( SF_COSPLAY in aSprite.Flags )
    then Push( iLayer, aSprite.Color )
    else Push( iLayer, ColorBlack );
end;


procedure TDRLSpriteMap.PushSpriteBeing( aPos : TVec2i; const aSprite : TSprite; aLight : Byte ) ;
var z : Integer;
begin
  z := ( aPos.Y div FSpriteEngine.Grid.Y ) * DRL_Z_LINE;
  if SF_LARGE in aSprite.Flags then
    z += DRL_Z_LARGE
  else
    z += DRL_Z_BEINGS;
  PushSprite( aPos, aSprite, aLight, z );
end;

procedure TDRLSpriteMap.PushSpriteItem( aPos : TVec2i; const aSprite : TSprite; aLight : Byte ) ;
begin
  PushSprite( aPos, aSprite, aLight, ( aPos.Y div FSpriteEngine.Grid.Y ) * DRL_Z_LINE + DRL_Z_ITEMS + 500);
end;

procedure TDRLSpriteMap.PushSpriteDoodad( aCoord : TCoord2D; const aSprite: TSprite; aLight: Integer; aZOffset : Integer );
var iLight  : Byte;
    iSprite : TSprite;
    iZ      : DWord;
begin
  iSprite := GetSprite( aSprite, aCoord );
  if aLight = -1 then
    iLight := VariableLight( aCoord )
  else
    iLight := Byte( aLight );
  if SF_COSPLAY in iSprite.Flags then
    iSprite.Color := ScaleColor( iSprite.Color, Byte(iLight) );
  iZ := aCoord.Y * DRL_Z_LINE + aZOffset;
  PushSprite( Vec2i( (aCoord.X-1)*FSpriteEngine.Grid.X, (aCoord.Y-1)*FSpriteEngine.Grid.Y ), iSprite, iLight, iZ + DRL_Z_DOODAD );
  if ( SF_HIGHSPRITE in aSprite.Flags ) and ( aCoord.y > 0 ) then
  begin
    iSprite := aSprite;
    iSprite.SpriteID[0] := iSprite.SpriteID[0] - DRL_COLS;
    Exclude( iSprite.Flags, SF_HIGHSPRITE );
    PushSpriteDoodad( NewCoord2D( aCoord.x, aCoord.y-1 ), iSprite, aLight, aZOffset );
  end;
end;

procedure TDRLSpriteMap.PushSpriteFX( aCoord : TCoord2D; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ) ;
begin
  PushSprite( Vec2i( (aCoord.X-1) * FSpriteEngine.Grid.X, (aCoord.Y-1) * FSpriteEngine.Grid.Y ), GetSprite( aSprite, ZeroCoord2D, aTime ), 255, DRL_Z_FX + aZOffset );
end;

procedure TDRLSpriteMap.PushSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aTSX : Single; aTSY : Single ) ;
var i         : Byte;
    iColors   : TGLRawQColor;
    ip        : TVec2i;
    iLayer    : TSpriteDataSet;
    iSpriteID : DWord;
    iLight    : array[0..3] of Byte;
begin
  iLayer    := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iSpriteID := aSprite.SpriteID[0] mod 100000;

  iLight[0] := FLightMap[aCoord.X-1,aCoord.Y-1];
  iLight[1] := FLightMap[aCoord.X-1,aCoord.Y  ];
  iLight[2] := FLightMap[aCoord.X  ,aCoord.Y  ];
  iLight[3] := FLightMap[aCoord.X  ,aCoord.Y-1];

  for i := 0 to 3 do
    iColors.Data[i] := TVec3b.CreateAll( iLight[i] );

  ip := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  with iLayer do
  begin
    if ( SF_COSPLAY in aSprite.Flags )
      then PushXY( iSpriteID, 1, ip, @iColors, aSprite.Color, ColorZero, GetEmissive( aSprite ), aTSX, aTSY, aZ )
      else PushXY( iSpriteID, 1, ip, @iColors, ColorBlack, ColorZero, GetEmissive( aSprite ), aTSX, aTSY, aZ );
  end;
end;

function TDRLSpriteMap.ShiftValue ( aFocus : TCoord2D ) : TVec2i;
const YFactor = 6;
begin
  if ( FMaxShift.X - FMinShift.X ) > 2 * IO.Driver.GetSizeX
    then ShiftValue.X := S3Interpolate(FMinShift.X,FMaxShift.X, (aFocus.X-2)/(MAXX-3))
    else ShiftValue.X := S5Interpolate(FMinShift.X,FMaxShift.X, (aFocus.X-2)/(MAXX-3));
  if FMaxShift.Y - FMinShift.Y > 4* FSpriteEngine.Grid.Y then
  begin
    if aFocus.Y < YFactor then
      ShiftValue.Y := FMinShift.Y
    else if aFocus.Y > MAXY-YFactor then
      ShiftValue.Y := FMaxShift.Y
    else
      ShiftValue.Y := S3Interpolate(FMinShift.Y,FMaxShift.Y,(aFocus.Y-YFactor)/(MAXY-10));

  end
  else
    ShiftValue.Y := S3Interpolate(FMinShift.Y,FMaxShift.Y,(aFocus.Y-2)/(MAXY-3));
end;

procedure TDRLSpriteMap.SetTarget ( aTarget : TCoord2D; aColor : TColor; aDrawPath : Boolean ) ;
var iTargetLine : TVisionRay;
    iCurrent    : TCoord2D;
begin
  FTargeting   := True;
  FTarget      := aTarget;
  FTargetColor := aColor;

  FTargetList.Clear;

  if (Player.Position <> FTarget) and (aDrawPath) then
  begin
    iTargetLine.Init( DRL.Level, Player.Position, FTarget );
    repeat
      iTargetLine.Next;
      iCurrent := iTargetLine.GetC;

      if not iTargetLine.Done then
        FTargetList.Push( iCurrent );
    until (iTargetLine.Done) or (iTargetLine.cnt > 30);
  end;
  FTargetList.Push( FTarget );
end;

procedure TDRLSpriteMap.SetAutoTarget( aTarget : TCoord2D );
begin
  if aTarget = Player.Position
    then FAutoTarget.Create(0,0)
    else FAutoTarget := aTarget;
end;

procedure TDRLSpriteMap.ClearTarget;
begin
  FTargeting := False;
end;

procedure TDRLSpriteMap.ToggleGrid;
begin
  FGridActive     := not FGridActive;
end;

destructor TDRLSpriteMap.Destroy;
begin
  FreeAndNil( FSpriteEngine );
  FreeAndNil( FTargetList );
  FreeAndNil( FFramebuffer );
  FreeAndNil( FHBFramebuffer );
  FreeAndNil( FVBFramebuffer );
  FreeAndNil( FPostProgram );
  FreeAndNil( FHBlurProgram );
  FreeAndNil( FVBlurProgram );
  FreeAndNil( FFullscreen );
  inherited Destroy;
end;

procedure TDRLSpriteMap.ApplyEffect;
begin
  case StatusEffect of
    StatusRed    : FLutTexture := (IO as TDRLGFXIO).Textures['lut_berserk'].GLTexture;
    StatusGreen  : FLutTexture := (IO as TDRLGFXIO).Textures['lut_enviro'].GLTexture;
    StatusBlue   : FLutTexture := (IO as TDRLGFXIO).Textures['lut_stealth'].GLTexture;
    StatusInvert : FLutTexture := (IO as TDRLGFXIO).Textures['lut_iddqd'].GLTexture;
    StatusMagenta: FLutTexture := (IO as TDRLGFXIO).Textures['lut_rage'].GLTexture;
    else
    begin
      if Setting_Glow
        then FLutTexture := (IO as TDRLGFXIO).Textures['lut_clear'].GLTexture
        else FLutTexture := 0;
    end;
  end;
end;

procedure TDRLSpriteMap.UpdateLightMap;
var Y,X : DWord;
  function Get( X, Y : Byte ) : Byte;
  var c : TCoord2D;
  begin
    c.Create( X, Y );
    if not DRL.Level.isExplored( c ) then Exit( 0 );
    Exit( VariableLight(c) );
  end;

begin
  for X := 0 to MAXX do
    for Y := 0 to MAXY do
      if (X*Y = 0) or (X = MAXX) or (Y = MAXY) then
        FLightMap[X,Y] := 0
      else
      begin
        FLightMap[X,Y] := ( Get(X,Y) + Get(X,Y+1) + Get(X+1,Y) + Get(X+1,Y+1) ) div 4;
      end;
end;

function TDRLSpriteMap.GetCellRotationMask( aCell : TCoord2D): Byte;
var iT,iB,iL,iR : Boolean;
  function IsWall( aCoord : TCoord2D ) : Boolean; inline;
  begin
    if not DRL.Level.isProperCoord( aCoord ) then Exit(True);
    if ((CF_STICKWALL in Cells[DRL.Level.CellBottom[ aCoord ]].Flags) or
      ((DRL.Level.CellTop[ aCoord ] <> 0) and
      (CF_STICKWALL in Cells[DRL.Level.CellTop[ aCoord ]].Flags))) then Exit( True );
    Exit( False );
  end;
  function AddIf( aBool : Boolean; aValue : Byte ) : Byte; inline;
  begin
    if aBool then Exit( aValue ) else Exit( 0 );
  end;
begin
  iT := IsWall( aCell.ifInc(  0, -1 ) );
  iB := IsWall( aCell.ifInc(  0,  1 ) );
  iL := IsWall( aCell.ifInc( -1,  0 ) );
  iR := IsWall( aCell.ifInc(  1,  0 ) );
  GetCellRotationMask :=
    AddIf( ( iT and iL ) and IsWall( aCell.ifInc( -1,-1) ),  1 ) +
    AddIf( iT, 2 ) +
    AddIf( ( iT and iR ) and IsWall( aCell.ifInc(  1,-1) ),  4 ) +
    AddIf( iL, 8 ) +

    AddIf( iR, 16 ) +
    AddIf( ( iB and iL ) and IsWall( aCell.ifInc( -1,1) ),  32 ) +
    AddIf( iB, 64 ) +
    AddIf( ( iB and iR ) and IsWall( aCell.ifInc(  1,1) ),  128 );
end;

function TDRLSpriteMap.GetCellDoorRotation( aCell : TCoord2D ) : Byte;
  function IsWall( aCoord : TCoord2D ) : Boolean; inline;
  begin
    if not DRL.Level.isProperCoord( aCoord ) then Exit( True );
    if ((CF_STICKWALL in Cells[DRL.Level.CellBottom[ aCoord ]].Flags) or
      ((DRL.Level.CellTop[ aCoord ] <> 0) and
      (CF_STICKWALL in Cells[DRL.Level.CellTop[ aCoord ]].Flags))) then Exit( True );
    Exit( False );
  end;
begin
  GetCellDoorRotation := 0;
  if IsWall( aCell.ifInc( 0, -1 ) ) and IsWall( aCell.ifInc( 0, 1 ) ) then
    GetCellDoorRotation := 1;
end;

procedure TDRLSpriteMap.PushTerrain;
var iDMinX  : Word;
    iDMaxX  : Word;
    iBottom : Word;
    iZ      : Integer;
    iY,iX   : DWord;
    iSpr    : TSprite;
    iFSpr   : TSprite;
    iCoord  : TCoord2D;
    iStyle  : Byte;
    iDeco   : Byte;
    iCell   : TCell;
    iColor  : TColor;

    function Mix( L, C : Byte ) : Byte;
    begin
      Exit( Clamp( Floor( ( L / 255 ) * C ) * 255, 0, 255 ) );
    end;

begin
  iDMinX := FShift.X div FSpriteEngine.Grid.X + 1;
  iDMaxX := Min(FShift.X div FSpriteEngine.Grid.X + (IO.Driver.GetSizeX div FSpriteEngine.Grid.X + 1),MAXX);

  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    begin
      iCoord.Create(iX,iY);
      if not DRL.Level.CellExplored(iCoord) then Continue;
      iBottom := DRL.Level.CellBottom[iCoord];
      if iBottom <> 0 then
      begin
        iZ     := iY * DRL_Z_LINE;
        iStyle := DRL.Level.CStyle[ iCoord ];
        iSpr   := GetSprite( iBottom, iStyle );
        iDeco  := DRL.Level.Deco[iCoord];
        if ( iDeco > 0 ) and ( SF_FULLDECO in iSpr.Flags ) then
          if Cells[ iBottom ].Deco[ iDeco ].SpriteID[0] <> 0 then
          begin
            if SF_COSPLAY in iSpr.Flags then
            begin
              iColor     := iSpr.Color;
              iSpr       := Cells[ iBottom ].Deco[ iDeco ];
              iSpr.Color := iColor;
              Include( iSpr.Flags, SF_COSPLAY );
            end
            else
              iSpr := Cells[ iBottom ].Deco[ iDeco ];
            iDeco      := 0;
          end;
        if SF_FLOW in iSpr.Flags
          then PushSpriteTerrain( iCoord, iSpr, iZ, FFluidX, FFluidY )
          else
          begin
            if SF_MULTI in iSpr.Flags then
              PushMultiSpriteTerrain( iCoord, iSpr, iZ, DRL.Level.Rotation[ iCoord ] )
            else
              PushSpriteTerrain( iCoord, iSpr, iZ );
          end;
        if (SF_FLUID in iSpr.Flags) and (DRL.Level.Rotation[ iCoord ] <> 0) then
        begin
          iFSpr := GetSprite( DRL.Level.FloorCell, DRL.Level.FloorStyle );
          if SF_HASALTEDGE in iFSpr.Flags then
            if SF_USEALTEDGE in iSpr.Flags then
              iFSpr.SpriteID[0] += DRL_COLS;
          iFSpr.SpriteID[0] += DRL.Level.Rotation[iCoord];
          PushSpriteTerrain( iCoord, iFSpr, iZ + DRL_Z_ENVIRO );
        end;
        if DRL.Level.LightFlag[ iCoord, LFBLOOD ] and (Cells[iBottom].BloodSprite.SpriteID[0] <> 0) then
          PushSpriteDoodad( iCoord, Cells[iBottom].BloodSprite );
        if iDeco <> 0 then
        begin
          iCell := Cells[ iBottom ];
          if iCell.Deco[ iDeco ].SpriteID[0] <> 0 then
          begin
            if SF_COSPLAY in iSpr.Flags then
            begin
              iColor     := iSpr.Color;
              iSpr       := GetSprite( iCell.Deco[ iDeco ], iCoord );
              iSpr.Color := iColor;
              Include( iSpr.Flags, SF_COSPLAY );
            end
            else
              iSpr := GetSprite( iCell.Deco[ iDeco ], iCoord );
            PushSpriteTerrain( iCoord, iSpr, iZ + DRL_Z_ENVIRO + 1 );
          end;
        end;
        if (SF_FLOOR in iSpr.Flags) then
        begin
          iSpr := GetSprite( DRL.Level.FloorCell, DRL.Level.FloorStyle );
          PushSpriteTerrain( iCoord, iSpr, iZ - 1 );
        end;
      end;
    end;
end;

procedure TDRLSpriteMap.PushObjects( aDTime : Integer );
var iDMinX   : Word;
    iDMaxX   : Word;
    iY,iX    : DWord;
    iTop, iL : DWord;
    iV       : TVec2i;
    iZ       : Integer;
    iCoord   : TCoord2D;
    iBeing   : TBeing;
    iItem    : TItem;
    iColor   : TColor;
    iDeco    : Byte;
    iCell    : TCell;
    iVisible : Boolean;
    iD       : Single;
    iRange   : Single;
    iOff     : Integer;
    iSprite  : TSprite;
begin
  iDMinX := FShift.X div FSpriteEngine.Grid.X + 1;
  iDMaxX := Min(FShift.X div FSpriteEngine.Grid.X + (IO.Driver.GetSizeX div FSpriteEngine.Grid.X + 1),MAXX);

  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    begin
      iCoord.Create(iX,iY);
      iZ   := iY * DRL_Z_LINE;
      iTop := DRL.Level.CellTop[iCoord];
      if (iTop <> 0) and DRL.Level.CellExplored(iCoord) and ( not DRL.Level.LightFlag[ iCoord, LFANIMATING ] ) then
      begin
        if CF_STAIRS in Cells[iTop].Flags then
          PushSpriteDoodad( iCoord, Cells[iTop].Sprite[0], 255 )
        else
        begin
          if not ( ( CF_CORPSE in Cells[iTop].Flags ) and ( DRL.Level.LightFlag[ iCoord, LFCORPSING ] ) ) then
          begin
            iSprite := GetSprite( iTop, DRL.Level.CStyle[iCoord] );
            if ( SF_DOORHACK in iSprite.Flags ) and ( DRL.Level.Rotation[iCoord] > 0 ) then
            begin
              iSprite.SpriteID[0] := iSprite.SpriteID[ iSprite.SCount div 2 ];
              Include( iSprite.Flags, SF_HIGHSPRITE );
            end;
            PushSpriteDoodad( iCoord, iSprite );
          end;
          iDeco := DRL.Level.Deco[iCoord];
          if iDeco <> 0 then
          begin
            iCell := Cells[ iTop ];
            if iCell.Deco[ iDeco ].SpriteID[0] <> 0 then
              PushSpriteDoodad( iCoord, iCell.Deco[ iDeco ], -1, 1 );
          end;

        end;
      end;

      iItem    := DRL.Level.Item[ iCoord ];
      iVisible := DRL.Level.ItemVisible( iCoord, iItem );
      if iVisible or DRL.Level.ItemExplored(iCoord, iItem) then
        if (iItem.AnimCount = 0) then
        begin
          iSprite := GetSprite( iItem.Sprite, iCoord );
          iOff := 0;
          if iItem.Appear > 0 then
          begin
            if ( iItem.Appear < 500 ) and Setting_ItemDropAnimation then
            begin
              iRange := 6.0 * FSpriteEngine.Scale;
              iItem.Appear := Min( iItem.Appear + aDTime, 500 );
              iD := iItem.Appear / 500;
              iOff := Round( -iRange + iRange * ( 1.0 - Exp( -5.0 * iD ) * Cos( 4.0 * Pi * iD ) ) );
            end
            else iItem.Appear := 0;
          end;
          iL := 70;
          if iVisible then
          begin
            iL := 255;
            if iItem.isFeature then iL := VariableLight( iCoord );
          end;
          PushSprite( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid + Vec2i( 0, iOff ), iSprite, iL, iZ + DRL_Z_ITEMS );
        end;
    end;

  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    begin
      iCoord.Create(iX,iY);
      iZ     := iY * DRL_Z_LINE;
      iBeing := DRL.Level.Being[iCoord];
      if (iBeing <> nil) and (iBeing.AnimCount = 0) then
        if DRL.Level.BeingVisible(iCoord, iBeing) then
          PushSprite( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid, GetBeingSprite( iBeing ), VariableLight( iCoord, 30 ), iZ + DRL_Z_BEINGS )
        else if DRL.Level.BeingExplored(iCoord, iBeing) then
          PushSprite( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid, GetBeingSprite( iBeing ), 40, iZ + DRL_Z_BEINGS )
        else if DRL.Level.BeingIntuited(iCoord, iBeing) then
        begin
          with FSpriteEngine.Layers[ HARDSPRITE_MARK div 100000 ] do
            Push( HARDSPRITE_MARK mod 100000, iCoord, ColorWhite, NewColor( Magenta ), ColorZero, NewColor( Magenta ), DRL_Z_FX-1 );
        end;
    end;

  if FTargeting then
    begin
      iColor := NewColor( 0, 128, 0 );
      if FTargetList.Size > 0 then
      for iL := 0 to FTargetList.Size-1 do
      begin
        if (not DRL.Level.isVisible( FTargetList[iL] )) or
           (not DRL.Level.isEmpty( FTargetList[iL], [ EF_NOBLOCK, EF_NOVISION ] )) then
          iColor := NewColor( 128, 0, 0 );
        with FSpriteEngine.Layers[ HARDSPRITE_SELECT div 100000 ] do
          Push( HARDSPRITE_SELECT mod 100000, FTargetList[iL], ColorWhite, iColor, ColorZero, iColor, DRL_Z_FX );
      end;
      if FTargetList.Size > 0 then
        with FSpriteEngine.Layers[ HARDSPRITE_MARK div 100000 ] do
          Push( HARDSPRITE_MARK mod 100000, FTarget, ColorWhite, FTargetColor, ColorZero, FTargetColor, DRL_Z_FX );
    end
  else
    if Setting_AutoTarget and ( FAutoTarget.X * FAutoTarget.Y <> 0 ) then
    begin
      iBeing := DRL.Level.Being[FAutoTarget];
      iV     := Vec2i( FAutoTarget.X-1, FAutoTarget.Y-1 ) * FSpriteEngine.Grid;
      if ( iBeing <> nil ) and ( iBeing.AnimCount > 0 ) then
         (IO as TDRLGFXIO).getUIDPosition( iBeing.UID, iV );
      with FSpriteEngine.Layers[ HARDSPRITE_SELECT div 100000 ] do
        PushXY( HARDSPRITE_SELECT mod 100000, 1, iV, ColorWhite, NewColor( Yellow ), ColorZero, NewColor( Yellow ), DRL_Z_FX );
    end;

  if FGridActive then
  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    with FSpriteEngine.Layers[ HARDSPRITE_GRID div 100000 ] do
      Push( HARDSPRITE_GRID mod 100000, NewCoord2D( iX, iY ), NewColor( 50, 50, 50, 50 ), ColorBlack, ColorZero, ColorBlack, DRL_Z_ITEMS );

end;

procedure TDRLSpriteMap.PushDecals;
var iData  : TDecalArray;
    iDecal : TDecal;
    iPos   : TVec2i;
    iCoord : TCoord2D;
    iLight : Byte;
    iDark  : Boolean;
//    iLQuad : TGLRawQColor;
  function GetLight( aPos : TVec2i ) : Byte;
  var iCoord   : TCoord2D;
  var iX1, iX2 : Single;
      iFPos     : TVec2f;
  begin
    iCoord.X := aPos.X div 32;
    iCoord.Y := aPos.Y div 32;
    iFPos.Init( ( aPos.X mod 32 ) / 32.0, ( aPos.Y mod 32 ) / 32.0 );
    iX1 := ( 1 - iFPos.X ) * FLightMap[ iCoord.X-1,iCoord.Y-1 ] + iFPos.X * FLightMap[ iCoord.X  ,iCoord.Y-1 ];
    iX2 := ( 1 - iFPos.X ) * FLightMap[ iCoord.X-1,iCoord.Y   ] + iFPos.X * FLightMap[ iCoord.X  ,iCoord.Y   ];
    Exit( Round( ( 1 - iFPos.Y ) * iX1 + iFPos.Y * iX2 ) );
  end;

  begin
  iData := DRL.Level.Decals.Data;
  iDark := Player.Flags[ BF_DARKNESS ];
  for iDecal in iData do
  begin
    iCoord := NewCoord2D( ( iDecal.Position.X + 16 ) div 32, ( iDecal.Position.Y + 16 ) div 32 );
    with DRL.Level do
      if ( not isProperCoord( iCoord ) ) or ( iDark and ( not isVisible( iCoord ) ) ) or ( not isExplored( iCoord ) ) then
          Continue;

    iPos.Init( Floor( ( iDecal.Position.X - 32 ) * FSpriteEngine.Scale ), Floor( ( iDecal.Position.Y - 32 ) * FSpriteEngine.Scale ) );
    iLight := GetLight( Vec2i( iDecal.Position.X + 16, iDecal.Position.Y + 16 ) );

//  iColors.Data[0] := BilinearLight( iStart );
//  iColors.Data[1] := BilinearLight( TVec2f.Create( iStart.X, iEnd.Y ) );
//  iColors.Data[2] := BilinearLight( iEnd );
//  iColors.Data[3] := BilinearLight( TVec2f.Create( iEnd.X, iStart.Y ) );
//    iLQuad.Data[0] := TVec3b.Create( iLight, iLight, iLight );
//    iLQuad.Data[1] := TVec3b.Create( iLight, iLight, iLight );
//    iLQuad.Data[2] := TVec3b.Create( iLight, iLight, iLight );
//    iLQuad.Data[3] := TVec3b.Create( iLight, iLight, iLight );

    with FSpriteEngine.Layers[ iDecal.Sprite div 100000 ] do
      PushXY( iDecal.Sprite mod 100000, 1, iPos, NewColor( iLight, iLight, iLight ), ColorZero, ColorBlack, ColorZero, DRL_Z_DECAL )
  end;
end;

function TDRLSpriteMap.VariableLight( aWhere: TCoord2D; aBonus : ShortInt = 0 ): Byte;
begin
  if not DRL.Level.isVisible( aWhere ) then Exit( 70 ); //20
  Exit( Min( 100+aBonus+DRL.Level.Vision.getLight(aWhere)*20, 255 ) );
end;

function TDRLSpriteMap.GetBeingSprite( aBeing : TBeing ) : TSprite;
begin
  Assert( Assigned( aBeing ) );
  Result := aBeing.Sprite;
  if (aBeing.OverlayUntil > IO.Time) and (SF_PAINANIM in Result.Flags) then
  begin
    if SF_LARGE in Result.Flags then
      Result.SpriteID[0] += DRL_COLS * 2 * Result.Frames
    else
      Result.SpriteID[0] += DRL_COLS * Result.Frames;
  end
  else Exit( GetSprite( Result, aBeing.Position ) );
end;

function TDRLSpriteMap.GetSprite( aSprite : TSprite; aCoord : TCoord2D; aTime : Integer = -1 ) : TSprite;
var iFrame : DWord;
    iTime  : DWord;
    iSeed  : DWord;
begin
  Result := aSprite;
  if ( Result.Frames > 0 ) and ( Result.FrameTime > 0 ) then
  begin
    if aTime >= 0
      then iTime := aTime
      else iTime := FTimer;
    iFrame := ( ( iTime div Result.Frametime ) mod Result.Frames );
    // Randomize start frame based on position if SF_RANDFRAME is set
    if ( SF_RANDFRAME in Result.Flags ) and ( aCoord <> ZeroCoord2D ) then
    begin
      iSeed := ( aCoord.X * 73856093 ) xor ( aCoord.Y * 19349663 );
      iFrame := ( iFrame + iSeed ) mod Result.Frames;
    end;
    if SF_LARGE in Result.Flags then
      Result.SpriteID[0] += DRL_COLS * 2 * iFrame
    else
      Result.SpriteID[0] += DRL_COLS * iFrame;
  end;
end;

function TDRLSpriteMap.GetSprite( aCell, aStyle : Byte ) : TSprite;
var iCell  : TCell;
begin
  iCell   := Cells[ aCell ];
  if iCell.Sprite[ aStyle ].SpriteID[0] <> 0 then
    Exit( iCell.Sprite[ aStyle ] );
  Exit( iCell.Sprite[ 0 ] );
end;

function TDRLSpriteMap.GetGridSize: Word;
begin
  Exit( FSpriteEngine.Grid.X );
end;

end.

