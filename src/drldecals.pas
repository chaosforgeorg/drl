{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drldecals;
interface
uses classes, vnode, vgenerics, vvector, dfdata;

type TDecal = record
  Sprite   : DWord;
  Position : TVec2i;
end;

type TDecalArray = specialize TGRingBuffer< TDecal >;

type TDecalStore = class( TVObject )
  constructor Create;
  constructor CreateFromStream( aStream: TStream ); override;
  procedure WriteToStream( aStream: TStream ); override;
  procedure Add( aPosition : TVec2i; aSprite : DWord );
  procedure Clear;
  destructor Destroy; override;
protected
  FData  : TDecalArray;
  FTotal : QWord;
public
  property Data : TDecalArray read FData;
  // Decals added so far; Data[i] is decal number Total - Data.Size + i.
  // Not saved: after loading it counts the loaded decals.
  property Total : QWord read FTotal;
end;

implementation

uses sysutils;

constructor TDecalStore.Create;
begin
  FData  := TDecalArray.Create( 4096 );
  FTotal := 0;
end;

constructor TDecalStore.CreateFromStream( aStream: TStream );
begin
  FData  := TDecalArray.CreateFromStream( aStream );
  FTotal := FData.Size;
end;

procedure TDecalStore.WriteToStream( aStream: TStream );
begin
  FData.WriteToStream( aStream );
end;

procedure TDecalStore.Add( aPosition : TVec2i; aSprite : DWord );
var iDecal : TDecal;
begin
  iDecal.Sprite   := aSprite;
  iDecal.Position := aPosition;
  FData.PushBack( iDecal );
  Inc( FTotal );
end;

procedure TDecalStore.Clear;
begin
  FData.Clear;
end;

destructor TDecalStore.Destroy;
begin
  FreeAndNil( FData );
end;

end.

