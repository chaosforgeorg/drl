{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlspritemap;
interface
uses classes, sysutils, math,
     vutil, vgltypes, vrltools, vgenerics, vvector, vcolor, vglquadrenderer, vglprogram,
     vglfullscreentriangle, vnode, vspriteengine, vtextures, vglframebuffer,
     dfdata, dfbeing, dflevel;

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

type TSpritePart = ( F, L, R, T, B, TL, TR, BL, BR, 
                     WT, WB, WTL, WTR, WBL, WBR );
     TSpritePartSet = set of TSpritePart;

type

{ TDRLSpriteMap }

 TDRLSpriteMap = class( TVObject )
  constructor Create( aFramebuffer : TVec2i );
  procedure Reset;
  // Called after module resources are loaded, before level rendering begins.
  procedure WarmUp;
  procedure SetLevel( aLevel : TLevel );
  procedure Recalculate;
  procedure Update( aTime : DWord; aProjection : TMatrix44; aDarkness : Boolean );
  procedure Draw;
  function DevicePointToCoord( aPoint : TPoint ) : TCoord2D;
  procedure PushSpriteBeing( aPos : TVec2i; const aSprite : TSprite; aLight : Byte );
  procedure PushSpriteItem( aPos : TVec2i; const aSprite : TSprite; aLight : Byte );
  procedure PushBeingOverlay( aPos : TVec2i; aBeing : TBeing; aLight : Byte );
  procedure PushSpriteDoodad( aCoord : TCoord2D; const aSprite : TSprite; aLight : Integer = -1; aZOffset : Integer = 0 );
  procedure PushSpriteFX( aCoord : TCoord2D; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ); overload;
  procedure PushSpriteFX( aPos : TVec2i; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ); overload;
  procedure PushSpriteFXRotated( aPos : TVec2i; const aSprite : TSprite; aRotation : Single );
  procedure PushSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aTSX : Single = 0; aTSY : Single = 0 );
  function ShiftValue( aFocus : TCoord2D ) : TVec2i;
  procedure SetTarget( aTarget : TCoord2D; aColor : TColor; aSource : TBeing = nil );
  procedure SetAutoTarget( aSource, aTarget : TCoord2D );
  procedure ClearTarget;
  procedure ToggleGrid;
  function VariableLight( aWhere : TCoord2D; aBonus : ShortInt = 0 ) : Byte;
  function GetGridSize : Word;
  destructor Destroy; override;
  function GetBeingSprite( aBeing : TBeing ) : TSprite;
private
  FLevel          : TLevel;
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
  //FOldTargetList : TCoord2DArray;
  FTargetColor    : TColor;
  FNewShift       : TVec2i;
  FShift          : TVec2i;
  FOffset         : TVec2i;
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
  function PushFluidTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
  function PushWallDebrisTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
  function GetTerrainSprite( aCoord : TCoord2D; aCell : Byte; out aDeco : Byte ) : TSprite;
  function GetExploredTerrainCell( aCoord : TCoord2D ) : Byte;
  function GetTerrainLight( aCoord : TCoord2D ) : TGLRawQColor;
  function GetTransitionMaterial( const aSprite : TSprite ) : TSpriteTransitionMaterial;
  procedure PushDecals( aDarkness : Boolean );
  procedure PushObjects( aDTime : Integer );
  procedure PushSprite( aPos : TVec2i; const aSprite : TSprite; aLight : Byte; aZ : Integer );
  procedure PushMultiSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
  procedure PushFloorTerrainNewLayout( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
  procedure PushSpriteTerrainPart( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aStart, aEnd : TVec2f );
  procedure PushTarget( aSpriteID : DWord; aPosition : TVec2i; aColor : TColor; aSize : Float );
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

uses vmath, viotypes, vvision, vgl3library, vuid,
     drlio, drlgfxio,
     dfmap, dfthing, dfitem, drlcontrollerbindings,
     drlmarkers, drldecals;

function SpritePartSetFill( aPart : TSpritePart ) : TSpritePartSet;
begin
  case aPart of
    L  : Exit( [R] );
    R  : Exit( [L] );
    T  : Exit( [B] );
    B  : Exit( [T] );
    TL : Exit( [B,TR] );
    TR : Exit( [B,TL] );
    BL : Exit( [T,BR] );
    BR : Exit( [T,BL] );
    WT : Exit( [WB] );
    WB : Exit( [WT] );
    WTL: Exit( [WB,WTR] );
    WTR: Exit( [WB,WTL] );
    WBL: Exit( [WT,WBR] );
    WBR: Exit( [WT,WBL] );
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
  //FOldTargetList := TCoord2DArray.Create();
  FFluidTime := 0;
  FLutTexture := 0;
  FTarget.Create(0,0);
  FSpriteEngine := TSpriteEngine.Create( Vec2i( 32, 32 ) );
  FGridActive     := False;
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

procedure TDRLSpriteMap.WarmUp;
begin
  // Terrain can render through postprocessing or directly to the window.
  FSpriteEngine.WarmUp( [FFramebuffer, nil] );
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

procedure TDRLSpriteMap.SetLevel( aLevel : TLevel );
begin
  if FLevel <> aLevel then FSpriteEngine.Clear;
  FLevel := aLevel;
end;

procedure TDRLSpriteMap.Update( aTime : DWord; aProjection : TMatrix44; aDarkness : Boolean );
var iUIDs     : TUIDStore;
    iShift    : Single;
    iPixel    : Integer;
    iIO       : TDRLGFXIO;
    iMark     : TMarker;
    iTarget   : TBeing;
    iPosition : TVec2i;
begin
  iUIDs := FLevel.Context.UIDs;
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
  PushDecals( aDarkness );
  PushObjects( aTime );

  for iMark in FLevel.Markers.Data do
    if iMark.Target = 0 then
    begin
      if FLevel.isVisible( iMark.Coord ) then
        PushSpriteFX( iMark.Coord, iMark.Sprite, FTimer, -1 );
    end
    else
    begin
      iTarget := iUIDs[ iMark.Target ] as TBeing;
      if ( iTarget <> nil ) and ( not iTarget.Dead ) and FLevel.isVisible( iTarget.Position ) then
      begin
        iPosition := Vec2i( iTarget.Position.X-1, iTarget.Position.Y-1 ) * FSpriteEngine.Grid;
        if iTarget.AnimCount > 0 then
          iIO.getUIDPosition( iTarget.UID, iPosition );
        PushSpriteFX( iPosition, iMark.Sprite, FTimer, -1 );
      end;
    end;

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
  if not FLevel.isProperCoord( FMarker ) then Exit;
  MarkerSprite.SpriteID[0] := HARDSPRITE_HIGHLIGHT;
  MarkerSprite.Color := ColorBlack;
  MarkerSprite.Color.A := 127;
  if IO.ControllerActionHeld( CONTROLLER_MODIFIER_ALT ) or IO.Targeting then
  begin
    MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100);
    MarkerSprite.Color.G := MarkerSprite.Color.R;
    MarkerSprite.Color.B := MarkerSprite.Color.R;
  end
  else
  begin
    if FLevel.cellFlagSet( FMarker, CF_BLOCKMOVE ) and ( not FLevel.cellFlagSet( FMarker, CF_OPENABLE ) ) then
      MarkerSprite.Color.R := Floor(50*(Sin( FFluidTime*50 )+1)+100)
    else if (FLevel.GetBeing( FMarker ) <> nil) or (not FLevel.isPassable( FMarker ) ) then
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
  Result := aSprite.Color;
  if Result.A = 0 then Result.A := 255;
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
    if FLevel.isProperCoord( iCoord ) then
    begin
      TargetSprite.Color := ColorBlack;
      if FLevel.isVisible( iCoord ) then
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

const WallSpriteTop = 8.0 / 32.0;

function SpriteTint( const aSprite : TSprite ) : TColor;
begin
  if SF_COSPLAY in aSprite.Flags then Exit( aSprite.Color );
  Result := ColorBlack;
end;

function ConnectedTransitionMask( aMask, aQuadrant : Byte ) : Byte;
var iOwn : Byte;
begin
  iOwn := 3 xor aQuadrant;
  Result := aMask;
  // A diagonal neighbour can contribute only through a shared cardinal neighbour.
  if (aMask and ((1 shl (iOwn xor 1)) or (1 shl (iOwn xor 2)))) = 0 then
    Result := aMask and not (1 shl (iOwn xor 3));
end;

procedure SpritePartBounds( aPart : TSpritePart; aTop : Single; out aStart, aEnd : TVec2f );
begin
  aStart := TVec2f.Create( 0, 0 );
  aEnd   := TVec2f.Create( 1, 1 );
  case aPart of
    L       : aEnd.X   := 0.5;
    R       : aStart.X := 0.5;
    T, WT   : aEnd.Y   := aTop;
    B, WB   : aStart.Y := aTop;
    TL, WTL : aEnd.Init( 0.5, aTop );
    TR, WTR : begin aEnd.Y := aTop; aStart.X := 0.5; end;
    BL, WBL : begin aEnd.X := 0.5; aStart.Y := aTop; end;
    BR, WBR : aStart.Init( 0.5, aTop );
  end;
end;

type TSpriteTerrainPiece = record
  SpriteID : DWord;
  Part     : TSpritePart;
end;
type TSpriteTerrainLayout = array[0..3] of TSpriteTerrainPiece;
// Atlas IDs for the left/right halves of the wall's top and bottom bands.
type TMultiSpritePieces = array[0..3] of DWord;

function MultiSpriteInterior( aSpriteID : DWord ) : DWord;
begin
  Result := aSpriteID - 2*SpriteCellRow + 1;
end;

function GetMultiSpriteLayout( aSpriteID : DWord; aRotation : Byte; out aLayout : TSpriteTerrainLayout ) : Integer;
var iSpriteID : DWord;
    iPart     : TSpritePart;
    iPS       : TSpritePart;
    iParts    : TSpritePartSet;
    iMaskOut  : TSpritePartSet;
  procedure AddPart( aID : DWord; aPart : TSpritePart );
  begin
    aLayout[Result].SpriteID := aID;
    aLayout[Result].Part := aPart;
    Inc( Result );
  end;
  function BaseCase( aMask : Byte ) : DWord;
  begin
    case aMask of
      %00000010 : Exit( aSpriteID + 1*SpriteCellRow + 2 ); // wall up
      %00001000 : Exit( aSpriteID + 4*SpriteCellRow + 2 ); // wall left
      %00001010 : Exit( aSpriteID + 3*SpriteCellRow + 2 ); // wall left up
      %00010000 : Exit( aSpriteID + 4*SpriteCellRow + 0 ); // wall right
      %00010010 : Exit( aSpriteID + 3*SpriteCellRow + 0 ); // wall right up
      %00011000 : Exit( aSpriteID +                 + 1 ); // wall left right
      %00011010 : Exit( aSpriteID + 2*SpriteCellRow + 1 ); // wall left right up

      %01000000 : Exit( aSpriteID + 1*SpriteCellRow + 1 ); // wall down
      %01000010 : Exit( aSpriteID + 1*SpriteCellRow + 0 ); // wall down up
      %01001000 : Exit( aSpriteID +                 + 2 ); // wall down left
      %01001010 : Exit( aSpriteID + 2*SpriteCellRow + 2 ); // wall down up left
      %01010000 : Exit( aSpriteID +                 + 0 ); // wall down right
      %01010010 : Exit( aSpriteID + 2*SpriteCellRow + 0 ); // wall up down right
      %01011000 : Exit( aSpriteID + 3*SpriteCellRow + 1 ); // wall down right left
      %01011010 : Exit( aSpriteID + 4*SpriteCellRow + 1 ); // wall cross

      %00001011 : Exit( aSpriteID + (-3+2)*SpriteCellRow + 2 ); // wall left+up
      %00010110 : Exit( aSpriteID + (-3+2)*SpriteCellRow + 0 ); // wall right+up
      %01101000 : Exit( aSpriteID + (-3  )*SpriteCellRow + 2 ); // wall left+down
      %11010000 : Exit( aSpriteID + (-3  )*SpriteCellRow + 0 ); // wall right+down

      %00011111 : Exit( aSpriteID + (-3+2)*SpriteCellRow + 1 ); // wall full up
      %11111000 : Exit( aSpriteID + (-3  )*SpriteCellRow + 1 ); // wall full down
      %11010110 : Exit( aSpriteID + (-3+1)*SpriteCellRow + 0 ); // wall full right
      %01101011 : Exit( aSpriteID + (-3+1)*SpriteCellRow + 2 ); // wall full left
      %11111111 : Exit( MultiSpriteInterior( aSpriteID ) ); // wall full
    end;
    Exit( 0 );
  end;
begin
  Result := 0;
  iSpriteID := BaseCase( aRotation );
  if iSpriteID > 0 then
  begin
    AddPart( iSpriteID, F );
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
        AddPart( aSpriteID + SpriteCellRow + 2, WB );
        AddPart( aSpriteID + SpriteCellRow + 1, WT );
        Exit;
      end;
    %01011111 : begin iSpriteID := aSpriteID + 3 * SpriteCellRow + 1; iPart := WB; end;
    %11111010 : begin iSpriteID := aSpriteID + 2 * SpriteCellRow + 1; iPart := WT; end;
    %11011110 : begin iSpriteID := aSpriteID + 2 * SpriteCellRow + 2; iPart := L; end;
    %01111011 : begin iSpriteID := aSpriteID + 2 * SpriteCellRow + 0; iPart := R; end;

    %11111110 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WTL; end;
    %11111011 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WTR; end;
    %11011111 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WBL; end;
    %01111111 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iPart := WBR; end;

    %01111110 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WBR,WTL]; iMaskOut := [WBL,WTR]; end;
    %11011011 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WBL,WTR]; iMaskOut := [WBR,WTL]; end;

    %00011011 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 1; iParts := [WB,WTR]; iMaskOut := [WTL]; end; // wall left right up
    %00011110 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 1; iParts := [WB,WTL]; iMaskOut := [WTR]; end; // wall left right up

    %01101010 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 2; iParts := [WT,WBR];      iMaskOut := [WBL]; end; // wall down up left
    %01001011 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 2; iParts := [WTR,WBL,WBR]; iMaskOut := [WTL]; end; // wall down up left

    %11010010 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 0; iParts := [WT,WBL];      iMaskOut := [WBR]; end; // wall up down right
    %01010110 : begin iSpriteID := aSpriteID + 2*SpriteCellRow + 0; iParts := [WTL,WBL,WBR]; iMaskOut := [WTR]; end; // wall up down right

    %11011000 : begin iSpriteID := aSpriteID + 3*SpriteCellRow + 1; iParts := [WT,WBL]; iMaskOut := [WBR]; end; // wall down right left
    %01111000 : begin iSpriteID := aSpriteID + 3*SpriteCellRow + 1; iParts := [WT,WBR]; iMaskOut := [WBL]; end; // wall down right left

    %01011110 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WB,WTL]; iMaskOut := [WTR]; end;
    %01111010 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WT,WBR]; iMaskOut := [WBL]; end;
    %01011011 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WB,WTR]; iMaskOut := [WTL]; end;
    %11011010 : begin iSpriteID := aSpriteID + 4 * SpriteCellRow + 1; iParts := [WT,WBL]; iMaskOut := [WBR]; end;
  end;
  if iSpriteID = 0 then Exit;

  if iParts = [] then
  begin
    AddPart( iSpriteID, iPart );
    iMaskOut := SpritePartSetFill( iPart );
  end
  else
  begin
    for iPS in iParts do
      AddPart( iSpriteID, iPS );
  end;

  iSpriteID := MultiSpriteInterior( aSpriteID );
  for iPS in iMaskOut do
    AddPart( iSpriteID, iPS );
  Exit;
end;

procedure GetMultiSpritePieces( aSpriteID : DWord; aRotation : Byte; out aPieces : TMultiSpritePieces );
var iLayout     : TSpriteTerrainLayout;
    iCount      : Integer;
    i, iX, iY   : Integer;
    iStart,iEnd : TVec2f;
begin
  for i := 0 to 3 do aPieces[i] := 0;
  iCount := GetMultiSpriteLayout( aSpriteID, aRotation, iLayout );
  for i := 0 to iCount-1 do
  begin
    SpritePartBounds( iLayout[i].Part, WallSpriteTop, iStart, iEnd );
    for iY := 0 to 1 do
      for iX := 0 to 1 do
        if (iX*0.5 >= iStart.X) and (iX*0.5 < iEnd.X) and
           (iY*WallSpriteTop >= iStart.Y) and (iY*WallSpriteTop < iEnd.Y) then
          aPieces[iX+2*iY] := iLayout[i].SpriteID;
  end;
end;

procedure TDRLSpriteMap.PushMultiSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
var iLayout : TSpriteTerrainLayout;
    iSprite : TSprite;
    iCount  : Integer;
    i       : Integer;
    iStart  : TVec2f;
    iEnd    : TVec2f;
begin
  iCount := GetMultiSpriteLayout( aSprite.SpriteID[0], aRotation, iLayout );
  iSprite := aSprite;
  for i := 0 to iCount-1 do
  begin
    iSprite.SpriteID[0] := iLayout[i].SpriteID;
    if iLayout[i].Part = F then PushSpriteTerrain( aCoord, iSprite, aZ )
    else
    begin
      SpritePartBounds( iLayout[i].Part, WallSpriteTop, iStart, iEnd );
      PushSpriteTerrainPart( aCoord, iSprite, aZ, iStart, iEnd );
    end;
  end;
end;

procedure TDRLSpriteMap.PushFloorTerrainNewLayout( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aRotation : Byte );
var iSprite : TSprite;

  procedure Push( aOffset : DWord; aPart : TSpritePart = F );
  var iStart, iEnd : TVec2f;
  begin
    iSprite.SpriteID[0] := aSprite.SpriteID[0] + aOffset;
    SpritePartBounds( aPart, 0.5, iStart, iEnd );
    PushSpriteTerrainPart( aCoord, iSprite, aZ, iStart, iEnd );
  end;

begin
  iSprite := aSprite;
  case aRotation and %00001111 of
    %00000001 : Push( 2, T ); // top
    %00000010 : Push( 2, B ); // bottom
    %00000011 : Push( 2 ); // top bottom
    %00000100 : Push( 3, L ); // left
    %00000101 : Push( 4    ); // top left
    %00000110 : Push( 5    ); // bottom left
    %00000111 : Push( 8    ); // top bottom left
    %00001000 : Push( 3, R ); // right
    %00001001 : Push( 6    ); // top right
    %00001010 : Push( 7    ); // bottom right
    %00001011 : Push( 9    ); // top bottom right
    %00001100 : Push( 3 ); // left right
    %00001101 : Push( 10   ); // top left right
    %00001110 : Push( 11   ); // bottom left right
    %00001111 : Push( 12   ); // top bottom left right
  end;

  if aRotation and %10000000 <> 0 then Push( 1, BR );
  if aRotation and %01000000 <> 0 then Push( 1, TR );
  if aRotation and %00100000 <> 0 then Push( 1, BL );
  if aRotation and %00010000 <> 0 then Push( 1, TL );
end;

procedure TDRLSpriteMap.PushSpriteTerrainPart( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aStart, aEnd : TVec2f );
var iColors   : TGLRawQColor;
    iLight    : TGLRawQColor;
    iPosition : TVec2i;
    iPa, iPb  : TVec2i;
    iLayer    : TSpriteDataSet;
    iEmissive : TColor;
  function BilinearLight( aPos : TVec2f ) : Byte;
  var iX1, iX2 : Single;
  begin
    iX1 := ( 1 - aPos.X ) * iLight.Data[0].X + aPos.X * iLight.Data[3].X;
    iX2 := ( 1 - aPos.X ) * iLight.Data[1].X + aPos.X * iLight.Data[2].X;
    Exit( Round( ( 1 - aPos.Y ) * iX1 + aPos.Y * iX2 ) );
  end;
begin
  iLayer := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iLight := GetTerrainLight( aCoord );
  iColors.Data[0] := TVec3b.CreateAll( BilinearLight( aStart ) );
  iColors.Data[1] := TVec3b.CreateAll( BilinearLight( TVec2f.Create( aStart.X, aEnd.Y ) ) );
  iColors.Data[2] := TVec3b.CreateAll( BilinearLight( aEnd ) );
  iColors.Data[3] := TVec3b.CreateAll( BilinearLight( TVec2f.Create( aEnd.X, aStart.Y ) ) );

  iPosition := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  iPa := iPosition + Vec2i( Round( aStart.X * FSpriteEngine.Grid.X ), Round( aStart.Y * FSpriteEngine.Grid.Y ) );
  iPb := iPosition + Vec2i( Round( aEnd.X * FSpriteEngine.Grid.X ), Round( aEnd.Y * FSpriteEngine.Grid.Y ) );
  iEmissive := aSprite.Emissive;
  if iEmissive.A = 0 then iEmissive := aSprite.Color;
  iLayer.PushPart( aSprite.SpriteID[0] mod 100000, iPa, iPb, @iColors, SpriteTint( aSprite ),
    ColorZero, iEmissive, aZ, aStart, aEnd );
end;

procedure TDRLSpriteMap.PushTarget( aSpriteID : DWord; aPosition : TVec2i; aColor : TColor; aSize : Float );
var iColors   : TGLRawQColor;
    iLayer    : TSpriteDataSet;
    iSpriteID : DWord;
    iHalf     : TVec2i;
    iGrid     : TVec2i;
    iExtra    : TVec2i;
  procedure PushPart( aPa, aPb : TVec2i; aStart, aEnd : TVec2f );
  begin
    iLayer.PushPart( iSpriteID, aPa, aPb, @iColors, aColor, ColorZero, aColor, DRL_Z_FX, aStart, aEnd );
  end;
begin
  iLayer    := FSpriteEngine.Layers[ aSpriteID div 100000 ];
  iSpriteID := aSpriteID mod 100000;

  if Abs( aSize - 1.0 ) < 0.001 then
  begin
    iLayer.PushXY( iSpriteID, 1, aPosition, ColorWhite, aColor, ColorZero, aColor, DRL_Z_FX );
    Exit;
  end;

  iColors.FillAll( 255 );
  iGrid  := FSpriteEngine.Grid;
  iHalf  := TVec2i.Create( iGrid.X div 2, iGrid.Y div 2 );
  iExtra := TVec2i.Create( Round( iGrid.X * ( aSize - 1.0 ) ), Round( iGrid.Y * ( aSize - 1.0 ) ) );

  PushPart(
    aPosition + TVec2i.Create( -iExtra.X div 2, -iExtra.Y ),
    aPosition + TVec2i.Create( iHalf.X - iExtra.X div 2, iHalf.Y - iExtra.Y ),
    TVec2f.Create( 0.0, 0.0 ), TVec2f.Create( 0.5, 0.5 )
  );
  PushPart(
    aPosition + TVec2i.Create( iHalf.X + iExtra.X div 2, -iExtra.Y ),
    aPosition + TVec2i.Create( iGrid.X + iExtra.X div 2, iHalf.Y - iExtra.Y ),
    TVec2f.Create( 0.5, 0.0 ), TVec2f.Create( 1.0, 0.5 )
  );
  PushPart(
    aPosition + TVec2i.Create( -iExtra.X div 2, iHalf.Y ),
    aPosition + TVec2i.Create( iHalf.X - iExtra.X div 2, iGrid.Y ),
    TVec2f.Create( 0.0, 0.5 ), TVec2f.Create( 0.5, 1.0 )
  );
  PushPart(
    aPosition + TVec2i.Create( iHalf.X + iExtra.X div 2, iHalf.Y ),
    aPosition + TVec2i.Create( iGrid.X + iExtra.X div 2, iGrid.Y ),
    TVec2f.Create( 0.5, 0.5 ), TVec2f.Create( 1.0, 1.0 )
  );
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

procedure TDRLSpriteMap.PushBeingOverlay( aPos : TVec2i; aBeing : TBeing; aLight : Byte );
var iOverlay : TThing;
    iSprite  : TSprite;
    z        : Integer;
begin
  if aBeing = nil then Exit;
  iOverlay := aBeing.GetVisualOverlay;
  if iOverlay = nil then Exit;

  iSprite := aBeing.Sprite;
  iSprite.SpriteID[0] := iOverlay.Sprite.SpriteID[0];

  if ( aBeing.OverlayUntil > IO.Time ) and ( SF_PAINANIM in iSprite.Flags ) then
  begin
    if SF_LARGE in iSprite.Flags then
      iSprite.SpriteID[0] += DRL_COLS * 2 * iSprite.Frames
    else
      iSprite.SpriteID[0] += DRL_COLS * iSprite.Frames;
  end
  else iSprite := GetSprite( iSprite, aBeing.Position );

  z := ( aPos.Y div FSpriteEngine.Grid.Y ) * DRL_Z_LINE;
  if SF_LARGE in iSprite.Flags then
    z += DRL_Z_LARGE
  else
    z += DRL_Z_BEINGS;
  PushSprite( aPos, iSprite, aLight, z + 1 );
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
  PushSpriteFX( Vec2i( (aCoord.X-1) * FSpriteEngine.Grid.X, (aCoord.Y-1) * FSpriteEngine.Grid.Y ), aSprite, aTime, aZOffset );
end;

procedure TDRLSpriteMap.PushSpriteFX( aPos : TVec2i; const aSprite : TSprite; aTime : Integer = -1; aZOffset : Integer = 0 ) ;
begin
  PushSprite( aPos, GetSprite( aSprite, ZeroCoord2D, aTime ), 255, DRL_Z_FX + aZOffset );
end;

procedure TDRLSpriteMap.PushSpriteTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer; aTSX : Single; aTSY : Single );
var iColors   : TGLRawQColor;
    iPosition : TVec2i;
    iLayer    : TSpriteDataSet;
begin
  iLayer := FSpriteEngine.Layers[ aSprite.SpriteID[0] div 100000 ];
  iColors := GetTerrainLight( aCoord );
  iPosition := Vec2i( aCoord.X-1, aCoord.Y-1 ) * FSpriteEngine.Grid;
  iLayer.PushXY( aSprite.SpriteID[0] mod 100000, 1, iPosition, @iColors, SpriteTint( aSprite ),
    ColorZero, GetEmissive( aSprite ), aTSX, aTSY, aZ );
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

procedure TDRLSpriteMap.SetTarget( aTarget : TCoord2D; aColor : TColor; aSource : TBeing = nil );
var iTargetLine  : TAssistedRay;
    iCurrent    : TCoord2D;
    iTargetRange : Byte;
begin
  FTargeting   := True;
  FTarget      := aTarget;
  FTargetColor := aColor;

  FTargetList.Clear;
  //FOldTargetList.Clear;

  if ( aSource <> nil ) and ( aSource.Position <> FTarget ) then
  begin
    iTargetRange := Distance( aSource.Position, FTarget );
    iTargetLine.Init( FLevel, aSource.Position, FTarget, iTargetRange, aSource.Vision, aSource.GetVisionMap );
    repeat
      iTargetLine.Next;
      iCurrent := iTargetLine.Current;

      if not iTargetLine.Done then
        FTargetList.Push( iCurrent );
    until (iTargetLine.Done) or (iTargetLine.Steps > 30);

    { TVisionRay comparison path, left here for later targeting tests.
    iTargetLine.Init( FLevel, aSource.Position, FTarget );
    repeat
      iTargetLine.Next;
      iCurrent := iTargetLine.Current;

      if not iTargetLine.Done then
        FOldTargetList.Push( iCurrent );
    until (iTargetLine.Done) or (iTargetLine.Steps > 30);
    }
  end;
  FTargetList.Push( FTarget );
end;

procedure TDRLSpriteMap.SetAutoTarget( aSource, aTarget : TCoord2D );
begin
  if aTarget = aSource
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
  //FreeAndNil( FOldTargetList );
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
    if not FLevel.isExplored( c ) then Exit( 0 );
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

function TDRLSpriteMap.GetExploredTerrainCell( aCoord : TCoord2D ) : Byte;
begin
  if not FLevel.isProperCoord( aCoord ) then Exit( 0 );
  if not FLevel.CellExplored( aCoord ) then Exit( 0 );
  Result := FLevel.CellBottom[aCoord];
end;

function TDRLSpriteMap.GetTerrainLight( aCoord : TCoord2D ) : TGLRawQColor;
begin
  Result.Data[0] := TVec3b.CreateAll( FLightMap[aCoord.X-1,aCoord.Y-1] );
  Result.Data[1] := TVec3b.CreateAll( FLightMap[aCoord.X-1,aCoord.Y] );
  Result.Data[2] := TVec3b.CreateAll( FLightMap[aCoord.X,aCoord.Y] );
  Result.Data[3] := TVec3b.CreateAll( FLightMap[aCoord.X,aCoord.Y-1] );
end;

function TDRLSpriteMap.GetTransitionMaterial( const aSprite : TSprite ) : TSpriteTransitionMaterial;
begin
  Result.SpriteID := aSprite.SpriteID[0] mod 100000;
  Result.Color := SpriteTint( aSprite );
  // Terrain ignores the tint alpha; normalize it for surface identity too.
  Result.Color.A := 255;
  Result.Emissive := GetEmissive( aSprite );
  Result.Shift := TVec2f.Create( 0, 0 );
end;

function TDRLSpriteMap.GetTerrainSprite( aCoord : TCoord2D; aCell : Byte; out aDeco : Byte ) : TSprite;
var iCell  : TCell;
    iColor : TColor;
begin
  Result := GetSprite( aCell, FLevel.CStyle[aCoord] );
  aDeco := FLevel.Deco[aCoord];
  if (aDeco > 0) and (SF_FULLDECO in Result.Flags) then
  begin
    iCell := FLevel.Data.Cells[aCell];
    if iCell.Deco[aDeco].SpriteID[0] = 0 then Exit;
    if SF_COSPLAY in Result.Flags then
    begin
      iColor := Result.Color;
      Result := iCell.Deco[aDeco];
      Result.Color := iColor;
      Include( Result.Flags, SF_COSPLAY );
    end
    else
      Result := iCell.Deco[aDeco];
    aDeco := 0;
  end;
end;

function TDRLSpriteMap.PushFluidTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
const FluidMixWidth = 8.0;
var iSurfaces  : array[0..2,0..2] of TSpriteTransitionMaterial;
    iEligible  : array[0..2,0..2] of Boolean;
    iDifferent : Boolean;
    iPatches   : array[0..3] of TSpriteTransitionMaterials;
    iMasks     : array[0..3] of Byte;
    iLight     : TGLRawQColor;
    iNeighbour : TCoord2D;
    iSprite    : TSprite;
    iLayer     : TSpriteDataSet;
    iLayerID   : DWord;
    iBottom    : Byte;
    iDeco      : Byte;
    iMask      : Byte;
    iX, iY     : Integer;
    iQX, iQY   : Integer;
    iQ, iSlot  : Integer;

    function Material( const aSurface : TSprite ) : TSpriteTransitionMaterial;
    begin
      Assert( aSurface.SpriteID[0] div 100000 = iLayerID, 'Mixing fluids must share a spritesheet' );
      Result := GetTransitionMaterial( aSurface );
      if SF_FLOW in aSurface.Flags then
        Result.Shift := TVec2f.Create( FFluidX, FFluidY );
    end;

begin
  Result := False;
  iLayerID := aSprite.SpriteID[0] div 100000;
  FillChar( iEligible, SizeOf( iEligible ), 0 );
  iDifferent := False;
  iSurfaces[1,1] := Material( aSprite );
  iEligible[1,1] := True;
  // One small value snapshot per tile; all four patches reuse these neighbours.
  for iY := 0 to 2 do
    for iX := 0 to 2 do
    begin
      if (iX = 1) and (iY = 1) then Continue;
      iNeighbour.Create( aCoord.X+iX-1, aCoord.Y+iY-1 );
      iBottom := GetExploredTerrainCell( iNeighbour );
      if iBottom = 0 then Continue;
      if not (CF_LIQUID in FLevel.Data.Cells[iBottom].Flags) then Continue;
      iSprite := GetTerrainSprite( iNeighbour, iBottom, iDeco );
      if not (SF_FLUID in iSprite.Flags) then Continue;
      iSurfaces[iX,iY] := Material( iSprite );
      if not iDifferent then
        iDifferent := iSurfaces[iX,iY].Compare( iSurfaces[1,1] ) <> 0;
      iEligible[iX,iY] := True;
    end;

  // Uniform neighbourhoods need neither patch masks nor transition geometry.
  if not iDifferent then Exit;

  for iQ := 0 to 3 do
  begin
    iQX := iQ and 1;
    iQY := iQ shr 1;
    iMask := 0;
    for iSlot := 0 to 3 do
    begin
      iX := iQX + (iSlot and 1);
      iY := iQY + (iSlot shr 1);
      // Initialize excluded slots as well; only the mask gives them weight.
      iPatches[iQ][iSlot] := iSurfaces[1,1];
      if not iEligible[iX,iY] then Continue;
      iPatches[iQ][iSlot] := iSurfaces[iX,iY];
      iMask := iMask or (1 shl iSlot);
    end;
    iMask := ConnectedTransitionMask( iMask, iQ );
    iMasks[iQ] := iMask;
    for iSlot := 0 to 3 do
      if ((iMask and (1 shl iSlot)) <> 0) and
         (iPatches[iQ][iSlot].Compare( iSurfaces[1,1] ) <> 0) then Result := True;
  end;
  if not Result then Exit;

  iLight := GetTerrainLight( aCoord );
  iLayer := FSpriteEngine.Layers[iLayerID];
  for iQ := 0 to 3 do
    iLayer.PushTransition( aCoord, iQ, iMasks[iQ], iPatches[iQ], iLight, aZ, FluidMixWidth );
end;

function TDRLSpriteMap.PushWallDebrisTerrain( aCoord : TCoord2D; const aSprite : TSprite; aZ : Integer ) : Boolean;
const WallDebrisMixWidth = 4.0;
type TSurfaceKind = (skNone, skWall, skDebris);
     TSurface = record
       Kind     : TSurfaceKind;
       Material : TSpriteTransitionMaterial;
       Rotation : Byte;
       Pieces   : TMultiSpritePieces;
     end;
var iSurfaces  : array[0..2,0..2] of TSurface;
    iLight     : TGLRawQColor;
    iLayer     : TSpriteDataSet;
    iLayerID   : DWord;
    iNeighbour : TCoord2D;
    iSprite    : TSprite;
    iOwnKind   : TSurfaceKind;
    iCell      : Byte;
    iDeco      : Byte;
    iMask      : Byte;
    iX, iY     : Integer;
    iQ, iSlot  : Integer;
    iQX, iQY   : Integer;
    iBand      : Integer;

  function SurfaceKind( aCell : Byte; const aSurface : TSprite ) : TSurfaceKind;
  begin
    if not (SF_MULTI in aSurface.Flags) then Exit( skNone );
    // Wall debris uses the wall layout with a floor beneath its transparent pixels.
    if SF_FLOOR in aSurface.Flags then Exit( skDebris );
    if CF_STICKWALL in FLevel.Data.Cells[aCell].Flags then Exit( skWall );
    Result := skNone;
  end;

  procedure ResolveNeighbourPieces( var aSurface : TSurface );
  var iPiece : Integer;
  begin
    if aSurface.Kind = skWall then
    begin
      // Extend the wall's interior into debris without repeating its bright rim.
      for iPiece := 0 to 3 do
        aSurface.Pieces[iPiece] := MultiSpriteInterior( aSurface.Material.SpriteID );
    end
    else
      GetMultiSpritePieces( aSurface.Material.SpriteID, aSurface.Rotation, aSurface.Pieces );
  end;

  function PieceMaterial( const aSurface : TSurface; aPiece : Integer ) : TSpriteTransitionMaterial;
  begin
    Result := aSurface.Material;
    Result.SpriteID := aSurface.Pieces[aPiece];
  end;

  procedure PushPatch( aQuadrant, aBand : Integer; aMask : Byte );
  var iMaterials  : TSpriteTransitionMaterials;
      iMaterial   : TSpriteTransitionMaterial;
      iQX, iQY    : Integer;
      iX, iY      : Integer;
      iSlot       : Integer;
      iPiece      : Integer;
      iStart,iEnd : TVec2f;
  begin
    iQX := aQuadrant and 1;
    iQY := aQuadrant shr 1;
    iPiece := iQX + 2*aBand;
    iMaterial := PieceMaterial( iSurfaces[1,1], iPiece );
    for iSlot := 0 to 3 do
    begin
      iX := iQX + (iSlot and 1);
      iY := iQY + (iSlot shr 1);
      iMaterials[iSlot] := iMaterial;
      // Different wall styles must not acquire wall-to-wall transitions.
      if ((aMask and (1 shl iSlot)) <> 0) and (iSurfaces[iX,iY].Kind <> iOwnKind) then
        iMaterials[iSlot] := PieceMaterial( iSurfaces[iX,iY], iPiece );
    end;
    iStart := TVec2f.Create( iQX*0.5, iQY*0.5 );
    iEnd := TVec2f.Create( (iQX+1)*0.5, (iQY+1)*0.5 );
    // Wall tops end at 8/32, inside the upper transition quadrants.
    if iQY = 0 then
      if aBand = 0 then iEnd.Y := WallSpriteTop else iStart.Y := WallSpriteTop;
    iLayer.PushTransitionPart( aCoord, aQuadrant, aMask, iMaterials, iLight, aZ,
      WallDebrisMixWidth, iStart, iEnd );
  end;

begin
  Result := False;
  iOwnKind := SurfaceKind( FLevel.CellBottom[aCoord], aSprite );
  if iOwnKind = skNone then Exit;
  iLayerID := aSprite.SpriteID[0] div 100000;
  iLayer := FSpriteEngine.Layers[iLayerID];
  if not iLayer.SupportsTransitions then Exit;
  FillChar( iSurfaces, SizeOf( iSurfaces ), 0 );
  iSurfaces[1,1].Kind := iOwnKind;
  iSurfaces[1,1].Material := GetTransitionMaterial( aSprite );
  iSurfaces[1,1].Rotation := FLevel.Rotation[aCoord];
  for iY := 0 to 2 do
    for iX := 0 to 2 do
    begin
      if (iX = 1) and (iY = 1) then Continue;
      iNeighbour.Create( aCoord.X+iX-1, aCoord.Y+iY-1 );
      iCell := GetExploredTerrainCell( iNeighbour );
      if iCell = 0 then Continue;
      iSprite := GetTerrainSprite( iNeighbour, iCell, iDeco );
      if iSprite.SpriteID[0] div 100000 <> iLayerID then Continue;
      iSurfaces[iX,iY].Kind := SurfaceKind( iCell, iSprite );
      if (iSurfaces[iX,iY].Kind = skNone) or (iSurfaces[iX,iY].Kind = iOwnKind) then Continue;
      iSurfaces[iX,iY].Material := GetTransitionMaterial( iSprite );
      iSurfaces[iX,iY].Rotation := FLevel.Rotation[iNeighbour];
      if (iX = 1) or (iY = 1) then Result := True;
    end;
  // Only tiles sharing an edge with the opposite kind need transition geometry.
  if not Result then Exit;

  GetMultiSpritePieces( iSurfaces[1,1].Material.SpriteID, iSurfaces[1,1].Rotation, iSurfaces[1,1].Pieces );
  for iY := 0 to 2 do
    for iX := 0 to 2 do
      if (iSurfaces[iX,iY].Kind <> skNone) and (iSurfaces[iX,iY].Kind <> iOwnKind) then
        ResolveNeighbourPieces( iSurfaces[iX,iY] );

  iLight := GetTerrainLight( aCoord );
  for iQ := 0 to 3 do
  begin
    iQX := iQ and 1;
    iQY := iQ shr 1;
    iMask := 0;
    for iSlot := 0 to 3 do
      if iSurfaces[iQX+(iSlot and 1),iQY+(iSlot shr 1)].Kind <> skNone then
        iMask := iMask or (1 shl iSlot);
    iMask := ConnectedTransitionMask( iMask, iQ );
    for iBand := iQY to 1 do
      PushPatch( iQ, iBand, iMask );
  end;
end;

procedure TDRLSpriteMap.PushTerrain;
var iDMinX     : Word;
    iDMaxX     : Word;
    iBottom    : Word;
    iZ         : Integer;
    iY,iX      : DWord;
    iSpr       : TSprite;
    iFSpr      : TSprite;
    iCoord     : TCoord2D;
    iDeco      : Byte;
    iFloor     : Byte;
    iCell      : TCell;
    iColor     : TColor;
    iMixFluids : Boolean;
    iMixedWall : Boolean;

begin
  iMixFluids := not FLevel.Flags[ LF_SHARPFLUID ];
  iDMinX := FShift.X div FSpriteEngine.Grid.X + 1;
  iDMaxX := Min(FShift.X div FSpriteEngine.Grid.X + (IO.Driver.GetSizeX div FSpriteEngine.Grid.X + 1),MAXX);

  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    begin
      iCoord.Create(iX,iY);
      if not FLevel.CellExplored(iCoord) then Continue;
      iBottom := FLevel.CellBottom[iCoord];
      if iBottom <> 0 then
      begin
        iZ     := iY * DRL_Z_LINE;
        iSpr := GetTerrainSprite( iCoord, iBottom, iDeco );
        iMixedWall := (SF_MULTI in iSpr.Flags) and PushWallDebrisTerrain( iCoord, iSpr, iZ );
        if not iMixedWall and not (iMixFluids and (CF_LIQUID in FLevel.Data.Cells[iBottom].Flags) and
          (SF_FLUID in iSpr.Flags) and PushFluidTerrain( iCoord, iSpr, iZ )) then
          if SF_FLOW in iSpr.Flags
            then PushSpriteTerrain( iCoord, iSpr, iZ, FFluidX, FFluidY )
            else
            begin
              if SF_MULTI in iSpr.Flags then
                PushMultiSpriteTerrain( iCoord, iSpr, iZ, FLevel.Rotation[ iCoord ] )
              else
                PushSpriteTerrain( iCoord, iSpr, iZ );
            end;
        if (SF_FLUID in iSpr.Flags) and (FLevel.Rotation[ iCoord ] <> 0) then
        begin
          iFloor := FLevel.Floor[ iCoord ];
          if iFloor <> 0 then
          begin
            iFSpr := GetSprite( iFloor, FLevel.FlrStyle[ iCoord ] );
            if SF_HASALTEDGE in iFSpr.Flags then
              if SF_USEALTEDGE in iSpr.Flags then
                iFSpr.SpriteID[0] += DRL_COLS;
            if SF_HASALTEDGE2 in iFSpr.Flags then
              if SF_USEALTEDGE2 in iSpr.Flags then
                iFSpr.SpriteID[0] += 2*DRL_COLS;
            if ModuleOption_NewFloorLayout 
              then PushFloorTerrainNewLayout( iCoord, iFSpr, iZ + DRL_Z_ENVIRO, FLevel.Rotation[iCoord] )
              else
              begin
                iFSpr.SpriteID[0] += FLevel.Rotation[iCoord];
                PushSpriteTerrain( iCoord, iFSpr, iZ + DRL_Z_ENVIRO );
              end;
          end;
        end;
        if FLevel.LightFlag[ iCoord, LFBLOOD ] and (FLevel.Data.Cells[iBottom].BloodSprite.SpriteID[0] <> 0) then
          PushSpriteDoodad( iCoord, FLevel.Data.Cells[iBottom].BloodSprite );
        if iDeco <> 0 then
        begin
          iCell := FLevel.Data.Cells[ iBottom ];
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
        if (SF_FLOOR in iSpr.Flags) or iMixedWall then
        begin
          iFloor := FLevel.Floor[ iCoord ];
          if iFloor <> 0 then
          begin
            iSpr := GetSprite( iFloor, FLevel.FlrStyle[ iCoord ] );
            PushSpriteTerrain( iCoord, iSpr, iZ - 1 );
          end;
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
      iTop := FLevel.CellTop[iCoord];
      if (iTop <> 0) and FLevel.CellExplored(iCoord) and ( not FLevel.LightFlag[ iCoord, LFANIMATING ] ) then
      begin
        if CF_STAIRS in FLevel.Data.Cells[iTop].Flags then
          PushSpriteDoodad( iCoord, FLevel.Data.Cells[iTop].Sprite[0], 255 )
        else
        begin
          if not ( ( CF_CORPSE in FLevel.Data.Cells[iTop].Flags ) and ( FLevel.LightFlag[ iCoord, LFCORPSING ] ) ) then
          begin
            iSprite := GetSprite( iTop, FLevel.CStyle[iCoord] );
            if ( SF_DOORHACK in iSprite.Flags ) and ( FLevel.Rotation[iCoord] > 0 ) then
            begin
              iSprite.SpriteID[0] := iSprite.SpriteID[ iSprite.SCount div 2 ];
              Include( iSprite.Flags, SF_HIGHSPRITE );
            end;
            PushSpriteDoodad( iCoord, iSprite );
          end;
          iDeco := FLevel.Deco[iCoord];
          if iDeco <> 0 then
          begin
            iCell := FLevel.Data.Cells[ iTop ];
            if iCell.Deco[ iDeco ].SpriteID[0] <> 0 then
              PushSpriteDoodad( iCoord, iCell.Deco[ iDeco ], -1, 1 );
          end;

        end;
      end;

      iItem    := FLevel.Item[ iCoord ];
      iVisible := FLevel.ItemVisible( iCoord, iItem );
      if iVisible or FLevel.ItemExplored(iCoord, iItem) then
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
      iBeing := FLevel.Being[iCoord];
      if (iBeing <> nil) and (iBeing.AnimCount = 0) then
        if FLevel.BeingVisible(iCoord, iBeing) then
        begin
          PushSprite( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid, GetBeingSprite( iBeing ), VariableLight( iCoord, 30 ), iZ + DRL_Z_BEINGS );
          PushBeingOverlay( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid, iBeing, VariableLight( iCoord, 30 ) );
        end
        else if FLevel.BeingExplored(iCoord, iBeing) then
        begin
          PushSprite( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid, GetBeingSprite( iBeing ), 40, iZ + DRL_Z_BEINGS );
          PushBeingOverlay( Vec2i( iX-1, iY-1 ) * FSpriteEngine.Grid, iBeing, 40 );
        end
        else if FLevel.BeingIntuited(iCoord, iBeing) then
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
        if (not FLevel.isVisible( FTargetList[iL] )) or
           (not FLevel.isShotPassable( FTargetList[iL] )) then
          iColor := NewColor( 128, 0, 0 );
        with FSpriteEngine.Layers[ HARDSPRITE_SELECT div 100000 ] do
          Push( HARDSPRITE_SELECT mod 100000, FTargetList[iL], ColorWhite, iColor, ColorZero, iColor, DRL_Z_FX );
      end;
      {
      iColor := NewColor( 0, 96, 192 );
      if FOldTargetList.Size > 0 then
      for iL := 0 to FOldTargetList.Size-1 do
      begin
        if (not FLevel.isVisible( FOldTargetList[iL] )) or
           (not FLevel.isShotPassable( FOldTargetList[iL] )) then
          iColor := NewColor( 128, 0, 128 );
        with FSpriteEngine.Layers[ HARDSPRITE_MARK div 100000 ] do
          Push( HARDSPRITE_MARK mod 100000, FOldTargetList[iL], ColorWhite, iColor, ColorZero, iColor, DRL_Z_FX+1 );
      end;
      }
      if FTargetList.Size > 0 then
        with FSpriteEngine.Layers[ HARDSPRITE_MARK div 100000 ] do
          Push( HARDSPRITE_MARK mod 100000, FTarget, ColorWhite, FTargetColor, ColorZero, FTargetColor, DRL_Z_FX );
    end
  else
    if Setting_AutoTarget and ( FAutoTarget.X * FAutoTarget.Y <> 0 ) then
    begin
      iBeing := FLevel.Being[FAutoTarget];
      iV     := Vec2i( FAutoTarget.X-1, FAutoTarget.Y-1 ) * FSpriteEngine.Grid;
      if ( iBeing <> nil ) and ( iBeing.AnimCount > 0 ) then
         (IO as TDRLGFXIO).getUIDPosition( iBeing.UID, iV );
      if ( iBeing <> nil ) and ( iBeing.isVisible or ( iBeing.AnimCount > 0 ) ) 
        then PushTarget( HARDSPRITE_SELECT, iV, NewColor( Yellow ), 1.0 + iBeing.TargetSize * 0.1 )
        else PushTarget( HARDSPRITE_SELECT, iV, NewColor( Yellow ), 1.0 );
    end;

  if FGridActive then
  for iY := 1 to MAXY do
    for iX := iDMinX to iDMaxX do
    with FSpriteEngine.Layers[ HARDSPRITE_GRID div 100000 ] do
      Push( HARDSPRITE_GRID mod 100000, NewCoord2D( iX, iY ), NewColor( 50, 50, 50, 50 ), ColorBlack, ColorZero, ColorBlack, DRL_Z_ITEMS );

end;

procedure TDRLSpriteMap.PushDecals( aDarkness : Boolean );
var iData  : TDecalArray;
    iDecal : TDecal;
    iPos   : TVec2i;
    iCoord : TCoord2D;
    iLight : Byte;
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
  iData := FLevel.Decals.Data;
  for iDecal in iData do
  begin
    iCoord := NewCoord2D( ( iDecal.Position.X + 16 ) div 32, ( iDecal.Position.Y + 16 ) div 32 );
    with FLevel do
      if ( not isProperCoord( iCoord ) ) or ( aDarkness and ( not isVisible( iCoord ) ) ) or ( not isExplored( iCoord ) ) then
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
  if not FLevel.isVisible( aWhere ) then Exit( 70 ); //20
  Exit( Min( 100+aBonus+FLevel.Vision.getLight(aWhere)*20, 255 ) );
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

function TDRLSpriteMap.GetSprite( aCell, aStyle : Byte ) : TSprite;
var iCell  : TCell;
begin
  iCell   := FLevel.Data.Cells[ aCell ];
  if iCell.Sprite[ aStyle ].SpriteID[0] <> 0 then
    Exit( iCell.Sprite[ aStyle ] );
  Exit( iCell.Sprite[ 0 ] );
end;

function TDRLSpriteMap.GetGridSize: Word;
begin
  Exit( FSpriteEngine.Grid.X );
end;

end.
