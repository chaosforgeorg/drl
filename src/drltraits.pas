{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drltraits;
interface
uses classes, sysutils, vlua, vnode, dfdata;

const   MAXTRAITS  = 80;
        MAXKLASS   = 10;

// Trait progression; trait behavior runs through the trait runtime perks.
type TTraits = class( TVObject )
  constructor Create( aOwner : TNode );
  constructor CreateFromStream( aStream : TStream; aOwner : TNode ); reintroduce;
  procedure WriteToStream( aStream : TStream ); override;
  function GetHistory : AnsiString;
  procedure Upgrade ( aKlass : Byte; aTrait : Byte ) ;
  procedure Grant( aTrait : Byte );
  function CanPick( aKlass : Byte; aTrait : Byte; aCharLevel : Byte ): Boolean;
  class function CanPickInitially( aLua : TLua; aTrait : Byte; aKlassID : Byte ) : Boolean; static;
protected
  function Get( aTrait : Byte ) : Byte;
  procedure CallOnPick( aTrait : Byte );
protected
  FOwner    : TNode;
  FBlocked  : array[1..MAXTRAITS]      of Boolean;
  FOrder    : array[1..MaxPlayerLevel] of Byte;
  FValues   : array[1..MAXTRAITS]      of Byte;
  FCount    : Byte;
  FMaster   : Byte;
public
  property Values[ aIndex : Byte ] : Byte read Get; default;
  property Master : Byte read FMaster;
end;

implementation

function TTraits.CanPick( aKlass : Byte; aTrait : Byte; aCharLevel : Byte ): Boolean;
var iOther, iValue : DWord;
    iVariant : Variant;
    iTable   : TLuaTable;
    iReqLevel : Integer;
begin
  if FBlocked[ aTrait ] then Exit( False );

  with FOwner.Context.Lua.GetTable(['klasses',aKlass,'trait',aTrait]) do
  try
    if (aCharLevel < 12) and (Self.FValues[ aTrait ] >= getInteger( 'max', 1 )) then Exit( False );
    iReqLevel := getInteger( 'reqlevel', 0 );
    if iReqLevel > 0 then iReqLevel += Self.FValues[ aTrait ] * 3;
    if aCharLevel < iReqLevel then Exit( False );

    if IsTable('blocks') then
    begin
      with GetTable('blocks') do
      try
        for iVariant in VariantValues do
          if Self.FValues[ Word(iVariant) ] >= 1 then Exit( False );
      finally
        Free;
      end;
    end;

    if IsTable('requires') then
    for iTable in ITables('requires') do
    begin
      iOther := iTable.GetValue( 1 );
      iValue := iTable.GetValue( 2 );
      if Self.FValues[ iOther ] < iValue then Exit( False );
    end;
  finally
    Free;
  end;
  Exit( True );
end;

procedure TTraits.Upgrade ( aKlass : Byte; aTrait : Byte ) ;
var i            : Byte;
    iMax, iMax12 : DWord;
    iMaster      : Boolean;
    iVariant     : Variant;
begin
  Inc( FValues[ aTrait ] );

  with FOwner.Context.Lua.GetTable(['klasses',aKlass,'trait',aTrait]) do
  try
    iMax    := getInteger( 'max', 1 );
    iMax12  := getInteger( 'max_12', iMax );
    iMaster := getBoolean( 'master', False );
  finally
    Free;
  end;

  if FValues[ aTrait ] >= iMax12 then
    FBlocked[ aTrait ] := True;

  if iMaster then
  begin
    for i := 1 to MAXTRAITS do
      if FOwner.Context.Lua.Get(['klasses',aKlass,'trait',i,'master'], False ) then
        FBlocked[ i ] := True;
    FBlocked[ aTrait ] := FValues[ aTrait ] >= iMax;
    FMaster := aTrait;
  end;

  CallOnPick( aTrait );

  if (FValues[ aTrait ] = 1) and FOwner.Context.Lua.Defined(['klasses',aKlass,'trait',aTrait,'blocks']) then
  begin
    with FOwner.Context.Lua.GetTable(['klasses',aKlass,'trait',aTrait,'blocks']) do
    try
      for iVariant in VariantValues do
        FBlocked[ Word(iVariant) ] := True;
    finally
      Free;
    end;
  end;

  Inc( FCount );
  FOrder[ FCount ] := aTrait;
end;

// Grants a rank outside klass progression; it is not recorded as a pick.
procedure TTraits.Grant( aTrait : Byte );
begin
  Inc( FValues[ aTrait ] );
  FBlocked[ aTrait ] := True;
  CallOnPick( aTrait );
end;

class function TTraits.CanPickInitially( aLua : TLua; aTrait : Byte; aKlassID : Byte ): Boolean;
begin
  CanPickInitially := True;

  // #5 ReqLevel
  with aLua.GetTable(['klasses',aKlassID,'trait',aTrait]) do
  try
    if IsTable('requires') or (GetInteger('reqlevel',0) > 1) then CanPickInitially := False;
  finally
    Free;
  end;
end;

function TTraits.Get( aTrait : Byte ) : Byte;
begin
  Exit( FValues[ aTrait ] );
end;

// OnPick runs once per rank gained and is optional.
procedure TTraits.CallOnPick( aTrait : Byte );
begin
  if FOwner.Context.Lua.Defined( [ 'traits',aTrait,'OnPick' ] ) then
    FOwner.Context.Lua.ProtectedCall( [ 'traits',aTrait,'OnPick' ], [ FOwner, FValues[ aTrait ] ] );
end;

constructor TTraits.Create( aOwner : TNode );
var iCount : Byte;
begin
  inherited Create;
  FOwner := aOwner;
  for iCount := 1 to High(FBlocked) do FBlocked[iCount] := False;
  for iCount := 1 to High(FValues)  do FValues[iCount] := 0;
  for iCount := 1 to High(FOrder)   do FOrder[iCount] := 0;
  FCount  := 0;
  FMaster := 0;
end;

constructor TTraits.CreateFromStream( aStream : TStream; aOwner : TNode );
begin
  inherited CreateFromStream( aStream );
  FOwner := aOwner;
  aStream.Read( FValues,   SizeOf( FValues ) );
  aStream.Read( FBlocked,  SizeOf( FBlocked ) );
  aStream.Read( FOrder,    SizeOf( FOrder ) );
  aStream.Read( FCount,    SizeOf( FCount ) );
  aStream.Read( FMaster,   SizeOf( FMaster ) );
end;

procedure TTraits.WriteToStream( aStream : TStream );
begin
  inherited WriteToStream( aStream );
  aStream.Write( FValues,   SizeOf( FValues ) );
  aStream.Write( FBlocked,  SizeOf( FBlocked ) );
  aStream.Write( FOrder,    SizeOf( FOrder ) );
  aStream.Write( FCount,    SizeOf( FCount ) );
  aStream.Write( FMaster,   SizeOf( FMaster ) );
end;

function TTraits.GetHistory: AnsiString;
var iCount : Byte;
begin
  GetHistory := '';
  for iCount := 1 to High(FOrder) do
    if (FOrder[iCount] > 0) and (FOrder[iCount] <= High(FValues)) then
      GetHistory += FOwner.Context.Lua.Get(['traits',FOrder[iCount],'abbr'], False )+'->';
end;

end.
