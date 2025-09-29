{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmarkers;
interface
uses classes, vutil, vnode, vrltools, vgenerics, dfdata;

type TMarker = class( TVObject )
  constructor Create;
  constructor CreateFromStream( aStream: TStream ); override;
  procedure WriteToStream( aStream: TStream ); override;
private
  FSprite : TSprite;
  FCoord  : TCoord2D;
  FOwner  : TUID;
public
  property Sprite : TSprite  read FSprite;
  property Coord  : TCoord2D read FCoord;
  property Owner  : TUID     read FOwner;
end;

type TMarkerArray = specialize TGObjectArray< TMarker >;

type TMarkerStore = class( TVObject )
  constructor Create;
  constructor CreateFromStream( aStream: TStream ); override;
  procedure WriteToStream( aStream: TStream ); override;
  procedure Add( aCoord : TCoord2D; aSprite : TSprite; aOwner : TUID );
  procedure Wipe( aUID : TUID );
  procedure Wipe( aUID : TUID; aCoord : TCoord2D );
  procedure Clear;
  destructor Destroy; override;
protected
  FData : TMarkerArray;
public
  property Data : TMarkerArray read FData;
end;

implementation

uses sysutils;

constructor TMarker.Create;
begin
  FillChar( FSprite, SizeOf( FSprite ), 0 );
  FCoord.Create(-1,-1);
  FOwner := 0;
end;

constructor TMarker.CreateFromStream( aStream: TStream );
begin
  aStream.Read( FSprite, SizeOf( FSprite ) );
  aStream.Read( FCoord, SizeOf( FCoord ) );
  aStream.Read( FOwner, SizeOf( FOwner ) );
end;

procedure TMarker.WriteToStream( aStream: TStream );
begin
  aStream.Write( FSprite, SizeOf( FSprite ) );
  aStream.Write( FCoord, SizeOf( FCoord ) );
  aStream.Write( FOwner, SizeOf( FOwner ) );
end;

constructor TMarkerStore.Create;
begin
  FData := TMarkerArray.Create( True );
end;

constructor TMarkerStore.CreateFromStream( aStream: TStream );
begin
  FData := TMarkerArray.CreateFromStream( aStream );
end;

procedure TMarkerStore.WriteToStream( aStream: TStream );
begin
  FData.WriteToStream( aStream );
end;

procedure TMarkerStore.Add( aCoord : TCoord2D; aSprite : TSprite; aOwner : TUID );
var iMarker : TMarker;
begin
  iMarker := TMarker.Create;
  iMarker.FSprite := aSprite;
  iMarker.FCoord  := aCoord;
  iMarker.FOwner  := aOwner;
  FData.Push( iMarker );
end;

procedure TMarkerStore.Wipe( aUID : TUID );
var i : Integer;
begin
  i := 0;
  while i < FData.Size do
  begin
    if FData[i].FOwner = aUID
      then FData.Delete(i)
      else Inc( i );
  end;
end;

procedure TMarkerStore.Wipe( aUID : TUID; aCoord : TCoord2D );
var i : Integer;
begin
  i := 0;
  while i < FData.Size do
  begin
    if ( FData[i].FOwner = aUID ) and ( FData[i].Coord = aCoord )
      then FData.Delete(i)
      else Inc( i );
  end;
end;

procedure TMarkerStore.Clear;
begin
  FData.Clear;
end;

destructor TMarkerStore.Destroy;
begin
  FreeAndNil( FData );
end;


end.

