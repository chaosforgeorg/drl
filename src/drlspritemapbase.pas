{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlspritemapbase;
interface
uses classes, sysutils, math,
     vutil, vobject, vgltypes, vrltools, vvector, vcolor, vglquadrenderer, vglprogram,
     vglfullscreentriangle, vspriteengine, vtextures, vglframebuffer, viotypes,
     dfdata;

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
  constructor Create( aTextures : TTextureManager );
  procedure SetTextureID( aTexture : TTextureID; aSize : DWord );
  procedure Draw( aPoint : TPoint; aTicks : DWord; aTarget : TGLQuadList );
  procedure Reset;
private
  FTextures  : TTextureManager; // Borrowed from the graphics IO, which owns the cursor.
  FTextureID : TTextureID;
  FSize      : DWord;
  FActive    : Boolean;
public
  property Active : Boolean read FActive write FActive;
  property Size   : DWord   read FSize;
end;

// TSpriteMap
//
// The level-independent part of the sprite map: the sprite engine, camera,
// post-processing and sprite pushes. Kept free of levels, beings and IO so
// it can later move to Valkyrie together with TSprite.
type TSpriteMap = class( TVObject )
  constructor Create( aDriver : TIODriver; aFramebuffer : TVec2i );
  procedure Reset;
  // Called after module resources are loaded, before level rendering begins.
  procedure WarmUp;
  // Called whenever the scaling changes, before rendering.
  procedure Recalculate( aTileScale : Single; aScaledScreen : TGLVec2i ); overload;
  procedure Update( aTime : DWord; aProjection : TMatrix44 ); overload;
  procedure Draw; virtual;
  function DevicePointToCoord( aPoint : TPoint ) : TCoord2D;
  procedure PushSpriteBeing( aPos : TVec2i; const aSprite : TSprite; aLight : Byte );
  procedure PushSpriteItem( aPos : TVec2i; const aSprite : TSprite; aLight : Byte );
  procedure PushSpriteFX( aCoord : TCoord2D; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ); overload;
  procedure PushSpriteFX( aPos : TVec2i; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ); overload;
  procedure PushSpriteFXRotated( aPos : TVec2i; const aSprite : TSprite; aRotation : Single );
  function ShiftValue( aFocus : TCoord2D ) : TVec2i;
  function GetGridSize : Word;
  destructor Destroy; override;
protected
  FDriver         : TIODriver; // Borrowed from the graphics IO, which owns the map.
  FMaxShift       : TVec2i;
  FMinShift       : TVec2i;
  FTimer          : DWord;
  FNewShift       : TVec2i;
  FShift          : TVec2i;
  FOffset         : TVec2i;
  FSpriteEngine   : TSpriteEngine;
  FFramebuffer    : TGLFramebuffer;
  FHBFramebuffer  : TGLFramebuffer;
  FVBFramebuffer  : TGLFramebuffer;
  FPostProgram    : TGLProgram;
  FHBlurProgram   : TGLProgram;
  FVBlurProgram   : TGLProgram;
  FFullscreen     : TGLFullscreenTriangle;
  FLutTexture     : Cardinal;
protected
  procedure PushSprite( aPos : TVec2i; const aSprite : TSprite; aLight : Byte; aZ : Integer );
  function GetSprite( aSprite : TSprite; aCoord : TCoord2D; aTime : Integer = -1 ) : TSprite; overload;
  function GetEmissive( aSprite : TSprite ) : TColor;
public
  property Engine : TSpriteEngine read FSpriteEngine;
  property MaxShift : TVec2i read FMaxShift;
  property MinShift : TVec2i read FMinShift;
  property Shift : TVec2i read FShift;
  property NewShift : TVec2i read FNewShift write FNewShift;
  property Offset : TVec2i read FOffset write FOffset;
end;

implementation

uses vmath, vgl3library;

function ColorToGL( aColor : TColor ) : TGLVec3b;
begin
  ColorToGL.X := aColor.R;
  ColorToGL.Y := aColor.G;
  ColorToGL.Z := aColor.B;
end;

{ TDRLMouseCursor }

constructor TDRLMouseCursor.Create( aTextures : TTextureManager );
begin
  inherited Create;
  FTextures := aTextures;
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
    FTextures[ FTextureID ].GLTexture
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
{ TSpriteMap }

constructor TSpriteMap.Create( aDriver : TIODriver; aFramebuffer : TVec2i );
begin
  FDriver     := aDriver;
  FLutTexture := 0;
  FSpriteEngine := TSpriteEngine.Create( Vec2i( 32, 32 ) );

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

procedure TSpriteMap.Reset;
begin
  FSpriteEngine.Reset;
end;

procedure TSpriteMap.WarmUp;
begin
  // Terrain can render through postprocessing or directly to the window.
  FSpriteEngine.WarmUp( [FFramebuffer, nil] );
end;

procedure TSpriteMap.Recalculate( aTileScale : Single; aScaledScreen : TGLVec2i );
begin
  FSpriteEngine.SetScale( aTileScale );
  FFramebuffer.Resize( FDriver.GetSizeX, FDriver.GetSizeY );
  FHBFramebuffer.Resize( aScaledScreen.X, aScaledScreen.Y );
  FVBFramebuffer.Resize( aScaledScreen.X, aScaledScreen.Y );

  FPostProgram.Bind;
    FPostProgram.SetUniformi( 'utexture', 0 );
    FPostProgram.SetUniformi( 'ulut', 1 );
    FPostProgram.SetUniformi( 'ublur', 2 );
    if Setting_Glow
      then FPostProgram.SetUniformi( 'toggle_glow', 1 )
      else FPostProgram.SetUniformi( 'toggle_glow', 0 );
    FPostProgram.SetUniformf( 'screen_size', FDriver.GetSizeX, FDriver.GetSizeY );
  FPostProgram.UnBind;

  FHBlurProgram.Bind;
    FHBlurProgram.SetUniformi( 'utexture', 0 );
    FHBlurProgram.SetUniformf( 'screen_size', aScaledScreen.X, aScaledScreen.Y );
  FHBlurProgram.UnBind;

  FVBlurProgram.Bind;
    FVBlurProgram.SetUniformi( 'utexture', 0 );
    FVBlurProgram.SetUniformf( 'screen_size', aScaledScreen.X, aScaledScreen.Y );
  FVBlurProgram.UnBind;
  glViewport( 0, 0, FDriver.GetSizeX, FDriver.GetSizeY );
end;

procedure TSpriteMap.Update( aTime : DWord; aProjection : TMatrix44 );
begin
  FShift := FNewShift;
  {$PUSH}
  {$Q-}
  FTimer += aTime;
  {$POP}
  FSpriteEngine.Update( aProjection );
end;

procedure TSpriteMap.Draw;
begin
  FSpriteEngine.Position := FShift + FOffset;

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

      glViewport( 0, 0, FDriver.GetSizeX, FDriver.GetSizeY );
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

function TSpriteMap.DevicePointToCoord ( aPoint : TPoint ) : TCoord2D;
begin
  Result.x := Floor((aPoint.x + FShift.X) / FSpriteEngine.Grid.X)+1;
  Result.y := Floor((aPoint.y + FShift.Y) / FSpriteEngine.Grid.Y)+1;
end;

function TSpriteMap.GetEmissive( aSprite : TSprite ) : TColor;
begin
  if aSprite.Emissive.A <> 0 then Exit( aSprite.Emissive );
  Result := aSprite.Color;
  if Result.A = 0 then Result.A := 255;
end;

procedure TSpriteMap.PushSpriteFXRotated ( aPos : TVec2i;
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

procedure TSpriteMap.PushSprite( aPos : TVec2i; const aSprite : TSprite; aLight : Byte; aZ : Integer ) ;
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

procedure TSpriteMap.PushSpriteBeing( aPos : TVec2i; const aSprite : TSprite; aLight : Byte ) ;
var z : Integer;
begin
  z := ( aPos.Y div FSpriteEngine.Grid.Y ) * DRL_Z_LINE;
  if SF_LARGE in aSprite.Flags then
    z += DRL_Z_LARGE
  else
    z += DRL_Z_BEINGS;
  PushSprite( aPos, aSprite, aLight, z );
end;

procedure TSpriteMap.PushSpriteItem( aPos : TVec2i; const aSprite : TSprite; aLight : Byte ) ;
begin
  PushSprite( aPos, aSprite, aLight, ( aPos.Y div FSpriteEngine.Grid.Y ) * DRL_Z_LINE + DRL_Z_ITEMS + 500);
end;

procedure TSpriteMap.PushSpriteFX( aCoord : TCoord2D; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ) ;
begin
  PushSpriteFX( Vec2i( (aCoord.X-1) * FSpriteEngine.Grid.X, (aCoord.Y-1) * FSpriteEngine.Grid.Y ), aSprite, aTime, aZOffset );
end;

procedure TSpriteMap.PushSpriteFX( aPos : TVec2i; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ) ;
begin
  PushSprite( aPos, GetSprite( aSprite, ZeroCoord2D, aTime ), 255, DRL_Z_FX + aZOffset );
end;

function TSpriteMap.ShiftValue ( aFocus : TCoord2D ) : TVec2i;
const YFactor = 6;
begin
  if ( FMaxShift.X - FMinShift.X ) > 2 * FDriver.GetSizeX
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

function TSpriteMap.GetSprite( aSprite : TSprite; aCoord : TCoord2D; aTime : Integer = -1 ) : TSprite;
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
    if ( SF_RANDFRAME in Result.Flags ) and ( aCoord <> ZeroCoord2D ) then
    begin
      iSeed := DWord( QWord(aCoord.X) * 73856093 ) xor DWord( QWord(aCoord.Y) * 19349663 );
      iFrame := ( iFrame + ( iSeed mod DWord(Result.Frames) ) ) mod Result.Frames;
    end;
    if SF_LARGE in Result.Flags then
      Result.SpriteID[0] += DRL_COLS * 2 * iFrame
    else
      Result.SpriteID[0] += DRL_COLS * iFrame;
  end;
end;

function TSpriteMap.GetGridSize: Word;
begin
  Exit( FSpriteEngine.Grid.X );
end;

destructor TSpriteMap.Destroy;
begin
  FreeAndNil( FSpriteEngine );
  FreeAndNil( FFramebuffer );
  FreeAndNil( FHBFramebuffer );
  FreeAndNil( FVBFramebuffer );
  FreeAndNil( FPostProgram );
  FreeAndNil( FHBlurProgram );
  FreeAndNil( FVBlurProgram );
  FreeAndNil( FFullscreen );
  inherited Destroy;
end;

end.
