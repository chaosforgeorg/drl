{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlhelp;
interface
uses classes, vnode, dfdata, viotypes, vgenerics;

type THelpEntry = class(TVObject)
  constructor Create;
  destructor Destroy; override;
private
  FID    : Ansistring;
  FDesc  : Ansistring;
  FText  : TIOStringArray;
public
  property ID   : Ansistring     read FID;
  property Desc : Ansistring     read FDesc;
  property Text : TIOStringArray read FText;
end;

type THelpArray = specialize TGObjectArray< THelpEntry >;
     TGHashMap  = specialize TGHashMap< THelpEntry >;

type THelp = class(TVObject)
  constructor Create;
  procedure StreamLoader( aStream : TStream; aName : Ansistring; aSize : DWord );
  function Get( const aID : Ansistring ) : THelpEntry;
  destructor Destroy; override;
private
  FData : THelpArray;
  FMap  : TGHashMap;
public
  property Data[ const aID : Ansistring ] : THelpEntry read Get; default;
end;

var Help : THelp;

implementation

uses SysUtils, vutil, vtig;

constructor THelpEntry.Create;
begin
  FText := nil;
end;

destructor THelpEntry.Destroy;
begin
  FreeAndNil( FText );
end;

constructor THelp.Create;
begin
  FData := THelpArray.Create( True );
  FMap  := TGHashMap.Create;
end;

{$HINTS OFF}
procedure THelp.StreamLoader( aStream : TStream; aName : Ansistring; aSize : DWord);
var iEntry : THelpEntry;
begin
  Log( 'Registering help file '+aName+'...' );
  iEntry := THelpEntry.Create;
  iEntry.FText  := TIOStringArray.Create;
  while aStream.Position < aSize do
    iEntry.FText.Push( ReadLineFromStream( aStream, aSize ) );
  iEntry.FDesc  := VTIG_StripTags( iEntry.FText[0] );
  iEntry.FID    := ChangeFileExt( aName, '' );
  FData.Push( iEntry );
  FMap[ iEntry.FID ] := iEntry;
end;
{$HINTS ON}

function THelp.Get( const aID : Ansistring ) : THelpEntry;
begin
  Exit( FMap.Get( aID, nil ) );
end;

destructor THelp.Destroy;
begin
  FreeAndNil( FData );
  FreeAndNil( FMap );
end;

end.
